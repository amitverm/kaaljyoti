// ============================================================================
// filter_compiler.ts — shared between combination-search and request-matching
// ============================================================================
// Compiles a client-supplied filter tree into a parameterized SQL boolean
// expression over the precomputed search tables (chart_index, chart_yogas,
// life_events). Each atomic filter becomes an EXISTS subquery correlated to
// the mahakosh_charts alias; groups combine children with AND / OR / NOT.
//
// This module is PLAIN TypeScript — no Deno, no Supabase imports — so it
// stays portable (unit-testable anywhere, reusable outside edge functions).
//
// Security model:
//   * Every user-controlled value is emitted as a $n parameter, never
//     interpolated into SQL text.
//   * Enum-ish values (planet) are validated against a whitelist; codes and
//     tags against a conservative regex; integers against their legal ranges.
//   * Tree depth / node count are capped to prevent pathological queries.
//
// Filter tree shape (same shape stored in research_requests.criteria):
//   { op: 'AND' | 'OR' | 'NOT', children: FilterNode[] }
//   { type: 'planet_in_sign',      planet: 'Saturn', sign: 6 }
//   { type: 'planet_in_house',     planet: 'Mars',   house: 7 }
//   { type: 'planet_in_nakshatra', planet: 'Moon',   nakshatra: 3 }
//   { type: 'yoga_present',        yoga_code: 'gajakesari' }
//   { type: 'life_event',          tag: 'marriage' }
//
// v1 note on dasha correlation: "life event tag X occurred during dasha
// condition Y" style queries are composed by the CLIENT as planet/nakshatra
// filters (the dasha lord's natal placement) plus a life_event tag filter.
// Actual dasha-at-date computation happens client-side in v1; a server-side
// dasha index table can be added later without changing this tree shape.
// ============================================================================

export interface GroupNode {
  op: "AND" | "OR" | "NOT";
  children: FilterNode[];
}

export type LeafType =
  | "planet_in_sign"
  | "planet_in_house"
  | "planet_in_nakshatra"
  | "yoga_present"
  | "life_event"
  | "birth_range";

export interface LeafNode {
  type: LeafType;
  planet?: string;
  sign?: number;
  house?: number;
  nakshatra?: number;
  yoga_code?: string;
  tag?: string;
  /** birth_range bounds — all optional, at least one required.
   *  Dates are local calendar dates 'YYYY-MM-DD'; times are local
   *  time-of-day 'HH:MM' (24h). Local = birth_utc + utc_offset_min. */
  date_from?: string;
  date_to?: string;
  time_from?: string;
  time_to?: string;
}

export type FilterNode = GroupNode | LeafNode;

export interface CompiledFilter {
  /** SQL boolean expression referencing the chart alias, e.g. "(EXISTS (...) AND ...)". */
  sql: string;
  /** Positional parameter values, aligned with $startIndex..$n in `sql`. */
  params: unknown[];
}

/** Thrown for any malformed / abusive input tree. Map to HTTP 400. */
export class FilterValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "FilterValidationError";
  }
}

// --- abuse limits -----------------------------------------------------------
export const MAX_DEPTH = 6; // nesting levels of AND/OR/NOT
export const MAX_LEAVES = 24; // atomic conditions per query
export const MAX_NODES = 64; // total nodes (groups + leaves)
export const MAX_CHILDREN = 16; // fan-out per group

// Lowercase: matches how the app writes chart_index rows
// (Planet.name from the Dart enum) and what its filters send.
const PLANETS = new Set([
  "sun",
  "moon",
  "mars",
  "mercury",
  "jupiter",
  "venus",
  "saturn",
  "rahu",
  "ketu",
  "ascendant",
]);

// yoga codes: lowercase snake-ish identifiers (app-generated).
const CODE_RE = /^[a-z0-9][a-z0-9_\-]{0,63}$/;

// Life-event tags are FREE TEXT from contributed charts (the event's
// title or category label — 'Marriage', 'Heart transplant', or anything
// the contributor typed, in any script). Validated only for sanity
// (non-empty, bounded, no control chars); matching is case-insensitive
// substring, so the value ends up inside an ILIKE pattern parameter.
const MAX_TAG_LENGTH = 64;
const CONTROL_RE = /[\u0000-\u001f\u007f]/;

function requireTag(value: unknown): string {
  if (typeof value !== "string") {
    throw new FilterValidationError("tag must be a string");
  }
  const tag = value.trim();
  if (tag.length === 0 || tag.length > MAX_TAG_LENGTH || CONTROL_RE.test(tag)) {
    throw new FilterValidationError(
      `tag must be 1-${MAX_TAG_LENGTH} characters of plain text`,
    );
  }
  return tag;
}

/** Escape LIKE/ILIKE wildcards so user text matches literally. */
function likePattern(text: string): string {
  return "%" + text.replace(/[\\%_]/g, (m) => "\\" + m) + "%";
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

function optDate(value: unknown, name: string): string | undefined {
  if (value === undefined || value === null || value === "") return undefined;
  if (typeof value !== "string" || !DATE_RE.test(value)) {
    throw new FilterValidationError(`${name} must be 'YYYY-MM-DD'`);
  }
  return value;
}

function optTime(value: unknown, name: string): string | undefined {
  if (value === undefined || value === null || value === "") return undefined;
  if (typeof value !== "string" || !TIME_RE.test(value)) {
    throw new FilterValidationError(`${name} must be 'HH:MM' (24h)`);
  }
  return value;
}

function requireInt(value: unknown, name: string, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    throw new FilterValidationError(`${name} must be an integer in [${min}, ${max}]`);
  }
  return value;
}

function requirePlanet(value: unknown): string {
  // Case-insensitive input, normalized to the stored lowercase form.
  if (typeof value === "string") value = value.toLowerCase();
  if (typeof value !== "string" || !PLANETS.has(value)) {
    throw new FilterValidationError(
      `planet must be one of: ${[...PLANETS].join(", ")}`,
    );
  }
  return value;
}

function requireCode(value: unknown, name: string): string {
  if (typeof value !== "string" || !CODE_RE.test(value)) {
    throw new FilterValidationError(
      `${name} must match ${CODE_RE} (lowercase letters, digits, '_', '-')`,
    );
  }
  return value;
}

/**
 * Compile a filter tree to a parameterized SQL boolean expression.
 *
 * @param root        The filter tree (validated here — never trust the caller).
 * @param chartAlias  SQL alias of the mahakosh_charts row being tested.
 * @param startIndex  First positional parameter number to use ($startIndex...),
 *                    so the caller can prepend/append its own parameters.
 */
export function compileFilter(
  root: unknown,
  chartAlias = "c",
  startIndex = 1,
): CompiledFilter {
  // Alias is developer-supplied, but sanity-check it anyway since it is
  // interpolated into SQL text.
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(chartAlias)) {
    throw new FilterValidationError("invalid chart alias");
  }

  const params: unknown[] = [];
  let nodeCount = 0;
  let leafCount = 0;

  /** Push a parameter value, returning its $n placeholder. */
  const bind = (value: unknown): string => {
    params.push(value);
    return `$${startIndex + params.length - 1}`;
  };

  const walk = (node: unknown, depth: number): string => {
    if (depth > MAX_DEPTH) {
      throw new FilterValidationError(`filter tree deeper than ${MAX_DEPTH} levels`);
    }
    if (++nodeCount > MAX_NODES) {
      throw new FilterValidationError(`filter tree has more than ${MAX_NODES} nodes`);
    }
    if (node === null || typeof node !== "object" || Array.isArray(node)) {
      throw new FilterValidationError("each filter node must be an object");
    }

    const n = node as Record<string, unknown>;

    // ---- group node ----------------------------------------------------
    if ("op" in n) {
      const op = n.op;
      if (op !== "AND" && op !== "OR" && op !== "NOT") {
        throw new FilterValidationError(`unknown op '${String(op)}'`);
      }
      const children = n.children;
      if (!Array.isArray(children) || children.length === 0) {
        throw new FilterValidationError(`'${op}' requires a non-empty children array`);
      }
      if (children.length > MAX_CHILDREN) {
        throw new FilterValidationError(`'${op}' has more than ${MAX_CHILDREN} children`);
      }
      if (op === "NOT") {
        if (children.length !== 1) {
          throw new FilterValidationError("'NOT' requires exactly one child");
        }
        return `(NOT ${walk(children[0], depth + 1)})`;
      }
      const parts = children.map((child) => walk(child, depth + 1));
      return `(${parts.join(` ${op} `)})`;
    }

    // ---- leaf node -------------------------------------------------------
    if (++leafCount > MAX_LEAVES) {
      throw new FilterValidationError(`more than ${MAX_LEAVES} atomic filters`);
    }

    switch (n.type) {
      case "planet_in_sign": {
        const planet = bind(requirePlanet(n.planet));
        const sign = bind(requireInt(n.sign, "sign", 0, 11));
        return `EXISTS (SELECT 1 FROM public.chart_index ci
                        WHERE ci.chart_id = ${chartAlias}.id
                          AND ci.planet = ${planet} AND ci.sign = ${sign})`;
      }
      case "planet_in_house": {
        const planet = bind(requirePlanet(n.planet));
        const house = bind(requireInt(n.house, "house", 1, 12));
        return `EXISTS (SELECT 1 FROM public.chart_index ci
                        WHERE ci.chart_id = ${chartAlias}.id
                          AND ci.planet = ${planet} AND ci.house = ${house})`;
      }
      case "planet_in_nakshatra": {
        const planet = bind(requirePlanet(n.planet));
        const nakshatra = bind(requireInt(n.nakshatra, "nakshatra", 0, 26));
        return `EXISTS (SELECT 1 FROM public.chart_index ci
                        WHERE ci.chart_id = ${chartAlias}.id
                          AND ci.planet = ${planet} AND ci.nakshatra = ${nakshatra})`;
      }
      case "yoga_present": {
        const yoga = bind(requireCode(n.yoga_code, "yoga_code"));
        return `EXISTS (SELECT 1 FROM public.chart_yogas cy
                        WHERE cy.chart_id = ${chartAlias}.id
                          AND cy.yoga_code = ${yoga})`;
      }
      case "life_event": {
        // Free-text match: contributed tags are event titles / category
        // labels ('Marriage', 'Heart transplant'), so exact compare on a
        // snake_code would never hit. ILIKE substring, wildcards escaped.
        const tag = bind(likePattern(requireTag(n.tag)));
        return `EXISTS (SELECT 1 FROM public.life_events le
                        WHERE le.chart_id = ${chartAlias}.id
                          AND le.tag ILIKE ${tag})`;
      }
      case "birth_range": {
        // Filters on the chart's LOCAL birth date / time-of-day.
        // Legacy charts without stored birth details never match.
        const dateFrom = optDate(n.date_from, "date_from");
        const dateTo = optDate(n.date_to, "date_to");
        const timeFrom = optTime(n.time_from, "time_from");
        const timeTo = optTime(n.time_to, "time_to");
        if (!dateFrom && !dateTo && !timeFrom && !timeTo) {
          throw new FilterValidationError(
            "birth_range requires at least one of date_from/date_to/time_from/time_to",
          );
        }
        const local =
          `(${chartAlias}.birth_utc + make_interval(mins => coalesce(${chartAlias}.utc_offset_min, 0)))`;
        const conds = [`${chartAlias}.birth_utc IS NOT NULL`];
        if (dateFrom) conds.push(`${local}::date >= ${bind(dateFrom)}::date`);
        if (dateTo) conds.push(`${local}::date <= ${bind(dateTo)}::date`);
        if (timeFrom && timeTo) {
          if (timeFrom <= timeTo) {
            conds.push(`${local}::time >= ${bind(timeFrom)}::time`);
            conds.push(`${local}::time <= ${bind(timeTo)}::time`);
          } else {
            // Overnight window, e.g. 22:00 → 04:00.
            conds.push(
              `(${local}::time >= ${bind(timeFrom)}::time OR ${local}::time <= ${bind(timeTo)}::time)`,
            );
          }
        } else if (timeFrom) {
          conds.push(`${local}::time >= ${bind(timeFrom)}::time`);
        } else if (timeTo) {
          conds.push(`${local}::time <= ${bind(timeTo)}::time`);
        }
        return `(${conds.join(" AND ")})`;
      }
      default:
        throw new FilterValidationError(
          `unknown filter type '${String(n.type)}' (and no 'op' present)`,
        );
    }
  };

  return { sql: walk(root, 1), params };
}
