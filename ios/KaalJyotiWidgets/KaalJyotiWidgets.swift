// Kaal Jyoti — home-screen widgets (Daily Panchang + Live Transit).
//
// This file belongs to a Widget Extension target named
// "KaalJyotiWidgets" (see docs/os-widgets-setup.md for the two manual
// Xcode steps: create the target, then attach the shared App Group to
// BOTH Runner and the extension).
//
// No ephemeris runs here: the Flutter app precomputes everything and
// writes plain strings + a 12-hour transit timeline (JSON) into the
// App Group UserDefaults via the home_widget plugin. WidgetKit then
// renders scheduled entries without ever waking the app.

import SwiftUI
import WidgetKit

/// Must match OsWidgetService.appGroupId (Dart) and the App Group in
/// both Runner.entitlements and KaalJyotiWidgetsExtension.entitlements.
private let appGroup = "group.com.kaaljyoti"

private func store() -> UserDefaults? { UserDefaults(suiteName: appGroup) }

private func str(_ key: String, _ fallback: String = "—") -> String {
    store()?.string(forKey: key) ?? fallback
}

// MARK: - Shared look (light/dark adaptive)

private func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
}

/// Warm paper in light mode, warm near-black in dark mode.
private let paper = adaptive(
    UIColor(red: 0.973, green: 0.953, blue: 0.910, alpha: 1),
    UIColor(red: 0.110, green: 0.098, blue: 0.086, alpha: 1))
private let ink = adaptive(
    UIColor(red: 0.165, green: 0.129, blue: 0.094, alpha: 1),
    UIColor(red: 0.930, green: 0.900, blue: 0.850, alpha: 1))
private let inkSoft = adaptive(
    UIColor(red: 0.541, green: 0.478, blue: 0.400, alpha: 1),
    UIColor(red: 0.640, green: 0.590, blue: 0.520, alpha: 1))
private let maroon = adaptive(
    UIColor(red: 0.482, green: 0.176, blue: 0.149, alpha: 1),
    UIColor(red: 0.910, green: 0.510, blue: 0.440, alpha: 1))

// MARK: - Panchang widget

struct PanchangEntry: TimelineEntry {
    let date: Date
    let title: String
    let place: String
    let tithi: String
    let nakshatra: String
    let sun: String
    let rahu: String
    let abhijit: String
    let disha: String
}

struct PanchangProvider: TimelineProvider {
    private func current(at date: Date) -> PanchangEntry {
        PanchangEntry(
            date: date,
            title: str("pw_title", "Panchang"),
            place: str("pw_place", ""),
            tithi: str("pw_tithi", "Open the app once"),
            nakshatra: str("pw_nakshatra", ""),
            sun: str("pw_sun", ""),
            rahu: str("pw_rahu", ""),
            abhijit: str("pw_abhijit", ""),
            disha: str("pw_disha", "")
        )
    }

    func placeholder(in context: Context) -> PanchangEntry { current(at: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (PanchangEntry) -> Void) {
        completion(current(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PanchangEntry>) -> Void) {
        // One entry now; ask WidgetKit to reload when the tithi rolls
        // over (pw_refresh_at, written by the app) or in 6 h, whichever
        // comes first — the reload re-reads the shared store.
        let entry = current(at: Date())
        var refresh = Date().addingTimeInterval(6 * 3600)
        // pw_refresh_at is epoch milliseconds (string).
        if let s = store()?.string(forKey: "pw_refresh_at"), let ms = Double(s) {
            let t = Date(timeIntervalSince1970: ms / 1000)
            if t > Date() { refresh = min(refresh, t) }
        }
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct PanchangWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PanchangEntry

    private var isLarge: Bool { family == .systemLarge }
    private var body13: CGFloat { isLarge ? 16 : 12 }
    private var body11: CGFloat { isLarge ? 14 : 11 }

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 8 : 3) {
            HStack {
                Text(entry.title)
                    .font(.system(size: isLarge ? 17 : 13, weight: .bold))
                    .foregroundColor(maroon)
                    .lineLimit(1)
                if family != .systemSmall {
                    Spacer()
                    Text(entry.place)
                        .font(.system(size: isLarge ? 13 : 10))
                        .foregroundColor(inkSoft)
                        .lineLimit(1)
                }
            }
            // Small fixed gap under the title — the content sits just
            // below it, filling the card rather than floating at the
            // bottom (a trailing Spacer absorbs any leftover space).
            Spacer().frame(height: isLarge ? 4 : 3)
            switch family {
            case .systemSmall:
                Text(entry.tithi).font(.system(size: 11)).foregroundColor(ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(entry.nakshatra).font(.system(size: 11)).foregroundColor(ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(entry.abhijit).font(.system(size: 10)).foregroundColor(inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(entry.disha).font(.system(size: 10)).foregroundColor(inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(entry.rahu).font(.system(size: 10, weight: .medium)).foregroundColor(maroon)
                    .lineLimit(1).minimumScaleFactor(0.8)
            default:
                Text(entry.tithi).font(.system(size: body13)).foregroundColor(ink).lineLimit(isLarge ? 2 : 1)
                Text(entry.nakshatra).font(.system(size: body13)).foregroundColor(ink).lineLimit(isLarge ? 2 : 1)
                Text(entry.sun).font(.system(size: body11)).foregroundColor(inkSoft).lineLimit(1)
                Text(entry.abhijit).font(.system(size: body11)).foregroundColor(inkSoft).lineLimit(1)
                Text(entry.disha).font(.system(size: body11)).foregroundColor(inkSoft).lineLimit(1)
                Text(entry.rahu).font(.system(size: body11, weight: .medium)).foregroundColor(maroon).lineLimit(1)
                if isLarge {
                    Spacer(minLength: 2)
                    Text(entry.place)
                        .font(.system(size: 12))
                        .foregroundColor(inkSoft)
                        .lineLimit(1)
                }
            }
            // Absorb remaining height so content stays top-aligned. The
            // large family already bottom-pins its place line above.
            if !isLarge { Spacer(minLength: 0) }
        }
        .padding(12)
        .containerBackgroundCompat(paper)
    }
}

struct PanchangWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PanchangWidget", provider: PanchangProvider()) { entry in
            PanchangWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Panchang")
        .description("Tithi, nakshatra, Abhijit Muhurta, Disha Shool and Rahu Kaal for your city.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Transit widget

struct TransitEntry: TimelineEntry {
    let date: Date
    let asc: String
    let line: String
    /// Chart data (see OsWidgetService): ascendant sign 1–12 (0 = no
    /// chart data), 12 sign-indexed planet groups, and the app's chart
    /// style setting ("north" | "south").
    let ascSign: Int
    let signs: [[String]]
    let style: String
}

/// "Su,Ma®||Mo|…" → 12 sign-indexed planet groups ([] on mismatch).
private func parseSigns(_ s: String?) -> [[String]] {
    guard let s = s else { return [] }
    let groups = s.components(separatedBy: "|")
    guard groups.count == 12 else { return [] }
    return groups.map { $0.isEmpty ? [] : $0.components(separatedBy: ",") }
}

struct TransitProvider: TimelineProvider {
    private func fallbackEntry(at date: Date) -> TransitEntry {
        TransitEntry(
            date: date,
            asc: str("tw_asc", "Open the app once"),
            line: str("tw_line", ""),
            ascSign: 0,
            signs: [],
            style: str("tw_style", "north")
        )
    }

    func placeholder(in context: Context) -> TransitEntry { fallbackEntry(at: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (TransitEntry) -> Void) {
        completion(fallbackEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransitEntry>) -> Void) {
        // The app writes a 12-hour timeline (30-min steps) so the
        // rising lagna stays current without waking anything. Future
        // entries become WidgetKit entries; ask for a reload after the
        // last one.
        var entries: [TransitEntry] = []
        if let json = store()?.string(forKey: "tw_timeline"),
           let data = json.data(using: .utf8),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
            let style = str("tw_style", "north")
            for item in list {
                // Timestamps are epoch milliseconds (see OsWidgetService).
                guard let ts = item["t"], let ms = Double(ts),
                      let asc = item["asc"], let line = item["line"] else { continue }
                let signs = parseSigns(item["s"])
                entries.append(TransitEntry(
                    date: Date(timeIntervalSince1970: ms / 1000),
                    asc: asc, line: line,
                    ascSign: signs.isEmpty ? 0 : (Int(item["a"] ?? "") ?? 0),
                    signs: signs,
                    style: style))
            }
            // WidgetKit ignores past entries except the latest one.
            let now = Date()
            let past = entries.filter { $0.date <= now }
            let future = entries.filter { $0.date > now }
            entries = (past.suffix(1) + future).map { $0 }
        }
        if entries.isEmpty { entries = [fallbackEntry(at: Date())] }
        let refresh = entries.last!.date.addingTimeInterval(1800)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

/// One parsed graha from the sky line ("Su Pis", "Ma Pis®", …).
private struct Graha: Identifiable {
    let id: Int
    let planet: String
    let sign: String
    let retro: Bool
}

/// "Su Pis · Mo Tau · Ma Pis® · …" → structured tokens. Returns []
/// if the line isn't in the expected shape (e.g. fallback message).
private func parseGrahas(_ line: String) -> [Graha] {
    let tokens = line.components(separatedBy: " · ").filter { !$0.isEmpty }
    var out: [Graha] = []
    for (i, raw) in tokens.enumerated() {
        var t = raw.trimmingCharacters(in: .whitespaces)
        let retro = t.hasSuffix("®")
        if retro { t.removeLast() }
        let parts = t.split(separator: " ")
        guard parts.count == 2 else { return [] }
        out.append(Graha(id: i, planet: String(parts[0]),
                         sign: String(parts[1]), retro: retro))
    }
    return out
}

/// A single "Su  Pis ℞" cell: planet emphasized, sign plain,
/// retrograde marker muted.
private struct GrahaCell: View {
    let graha: Graha
    let size: CGFloat

    var body: some View {
        HStack(spacing: 3) {
            Text(graha.planet)
                .font(.system(size: size, weight: .bold))
                .foregroundColor(maroon)
            Text(graha.sign)
                .font(.system(size: size))
                .foregroundColor(ink)
            if graha.retro {
                Text("℞")
                    .font(.system(size: size - 1))
                    .foregroundColor(inkSoft)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

// MARK: - Transit chart (native port of the app's chart painters)

/// North-chart house geometry, ported from north_chart_painter.dart —
/// normalized (0…1) centroid, inner vertex and content rect per house
/// (index 0 = house 1, counter-clockwise, house 1 = top diamond).
private struct NorthHouse {
    let centroid: CGPoint
    let vertex: CGPoint
    let content: CGRect
}

private let northHouses: [NorthHouse] = [
    NorthHouse(centroid: CGPoint(x: 0.50, y: 0.25), vertex: CGPoint(x: 0.50, y: 0.50), content: CGRect(x: 0.38, y: 0.14, width: 0.24, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 0.25, y: 1.0/12), vertex: CGPoint(x: 0.25, y: 0.25), content: CGRect(x: 0.145, y: 0.025, width: 0.21, height: 0.11)),
    NorthHouse(centroid: CGPoint(x: 1.0/12, y: 0.25), vertex: CGPoint(x: 0.25, y: 0.25), content: CGRect(x: 0.02, y: 0.14, width: 0.115, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 0.25, y: 0.50), vertex: CGPoint(x: 0.50, y: 0.50), content: CGRect(x: 0.13, y: 0.39, width: 0.24, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 1.0/12, y: 0.75), vertex: CGPoint(x: 0.25, y: 0.75), content: CGRect(x: 0.02, y: 0.64, width: 0.115, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 0.25, y: 11.0/12), vertex: CGPoint(x: 0.25, y: 0.75), content: CGRect(x: 0.145, y: 0.865, width: 0.21, height: 0.11)),
    NorthHouse(centroid: CGPoint(x: 0.50, y: 0.75), vertex: CGPoint(x: 0.50, y: 0.50), content: CGRect(x: 0.38, y: 0.64, width: 0.24, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 0.75, y: 11.0/12), vertex: CGPoint(x: 0.75, y: 0.75), content: CGRect(x: 0.645, y: 0.865, width: 0.21, height: 0.11)),
    NorthHouse(centroid: CGPoint(x: 11.0/12, y: 0.75), vertex: CGPoint(x: 0.75, y: 0.75), content: CGRect(x: 0.865, y: 0.64, width: 0.115, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 0.75, y: 0.50), vertex: CGPoint(x: 0.50, y: 0.50), content: CGRect(x: 0.63, y: 0.39, width: 0.24, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 11.0/12, y: 0.25), vertex: CGPoint(x: 0.75, y: 0.25), content: CGRect(x: 0.865, y: 0.14, width: 0.115, height: 0.22)),
    NorthHouse(centroid: CGPoint(x: 0.75, y: 1.0/12), vertex: CGPoint(x: 0.75, y: 0.25), content: CGRect(x: 0.645, y: 0.025, width: 0.21, height: 0.11)),
]

/// Fixed South-chart (row, col) per sign 1–12 (Aries…Pisces), matching
/// SouthChartPainter.cells: Pisces top-left, zodiac clockwise.
private let southCells: [(Int, Int)] = [
    (0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (3, 3),
    (3, 2), (3, 1), (3, 0), (2, 0), (1, 0), (0, 0),
]

@available(iOSApplicationExtension 15.0, *)
struct TransitChartView: View {
    let ascSign: Int      // 1–12
    let signs: [[String]] // 12 sign-indexed planet groups
    let style: String     // "north" | "south"

    var body: some View {
        Canvas { context, size in
            if style == "south" {
                drawSouth(context, size)
            } else {
                drawNorth(context, size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func pt(_ p: CGPoint, _ r: CGRect) -> CGPoint {
        CGPoint(x: r.minX + r.width * p.x, y: r.minY + r.height * p.y)
    }

    /// Wraps a house's planet tokens into lines and draws them centered
    /// in [rect], shrinking the font until the block fits.
    private func drawTokens(_ context: GraphicsContext, _ tokens: [String],
                            in rect: CGRect, base: CGFloat) {
        guard !tokens.isEmpty else { return }
        let perLine = rect.width > rect.height ? 2 : 1
        var lines: [String] = []
        var i = 0
        while i < tokens.count {
            lines.append(tokens[i..<min(i + perLine, tokens.count)].joined(separator: " "))
            i += perLine
        }
        var font = min(base * 0.062, 11)
        // Fit: measure the widest line, scale down once if needed.
        func measure(_ f: CGFloat) -> (CGFloat, CGFloat) {
            var w: CGFloat = 0, h: CGFloat = 0
            for l in lines {
                let m = context.resolve(Text(l).font(.system(size: f, weight: .medium)))
                    .measure(in: CGSize(width: 1000, height: 1000))
                w = max(w, m.width); h += m.height
            }
            return (w, h)
        }
        let (w, h) = measure(font)
        let scale = min(1, rect.width / max(w, 1), rect.height / max(h, 1))
        font = max(5, font * scale)
        let (_, totalH) = measure(font)
        var y = rect.midY - totalH / 2
        for l in lines {
            let resolved = context.resolve(
                Text(l).font(.system(size: font, weight: .medium)).foregroundColor(ink))
            let m = resolved.measure(in: CGSize(width: 1000, height: 1000))
            context.draw(resolved, at: CGPoint(x: rect.midX, y: y + m.height / 2))
            y += m.height
        }
    }

    private func drawNorth(_ context: GraphicsContext, _ size: CGSize) {
        let base = min(size.width, size.height)
        let stroke = max(1, base * 0.006)
        let r = CGRect(origin: .zero, size: size).insetBy(dx: stroke / 2, dy: stroke / 2)

        // Lagna house (top diamond) tint.
        var tint = Path()
        tint.move(to: pt(CGPoint(x: 0.5, y: 0), r))
        tint.addLine(to: pt(CGPoint(x: 0.75, y: 0.25), r))
        tint.addLine(to: pt(CGPoint(x: 0.5, y: 0.5), r))
        tint.addLine(to: pt(CGPoint(x: 0.25, y: 0.25), r))
        tint.closeSubpath()
        context.fill(tint, with: .color(maroon.opacity(0.06)))

        // Frame, diagonals, inner diamond.
        var frame = Path()
        frame.addRect(r)
        frame.move(to: CGPoint(x: r.minX, y: r.minY))
        frame.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        frame.move(to: CGPoint(x: r.maxX, y: r.minY))
        frame.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        frame.move(to: CGPoint(x: r.midX, y: r.minY))
        frame.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        frame.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        frame.addLine(to: CGPoint(x: r.minX, y: r.midY))
        frame.closeSubpath()
        context.stroke(frame, with: .color(ink), lineWidth: stroke)

        for n in 1...12 {
            let h = northHouses[n - 1]
            let signNumber = ((ascSign - 1 + n - 1) % 12) + 1
            // Sign number tucked toward the inner corner (lerp 0.25).
            let sp = CGPoint(
                x: h.vertex.x + 0.25 * (h.centroid.x - h.vertex.x),
                y: h.vertex.y + 0.25 * (h.centroid.y - h.vertex.y))
            let signText = context.resolve(
                Text("\(signNumber)")
                    .font(.system(size: max(6, base * 0.045)))
                    .foregroundColor(n == 1 ? maroon : inkSoft))
            context.draw(signText, at: pt(sp, r))

            let content = CGRect(
                x: r.minX + r.width * h.content.minX,
                y: r.minY + r.height * h.content.minY,
                width: r.width * h.content.width,
                height: r.height * h.content.height)
            var tokens = signs[signNumber - 1]
            if n == 1 { tokens = ["As"] + tokens }
            drawTokens(context, tokens, in: content, base: base)
        }
    }

    private func drawSouth(_ context: GraphicsContext, _ size: CGSize) {
        let base = min(size.width, size.height)
        let stroke = max(1, base * 0.006)
        let r = CGRect(origin: .zero, size: size).insetBy(dx: stroke / 2, dy: stroke / 2)
        let cw = r.width / 4, ch = r.height / 4

        func cellRect(_ row: Int, _ col: Int) -> CGRect {
            CGRect(x: r.minX + CGFloat(col) * cw, y: r.minY + CGFloat(row) * ch,
                   width: cw, height: ch)
        }

        // Ring cells + lagna tint & corner strike.
        var grid = Path()
        for s in 1...12 {
            let (row, col) = southCells[s - 1]
            let cell = cellRect(row, col)
            grid.addRect(cell)
            if s == ascSign {
                context.fill(Path(cell), with: .color(maroon.opacity(0.06)))
                var strike = Path()
                strike.move(to: CGPoint(x: cell.minX, y: cell.minY + ch * 0.3))
                strike.addLine(to: CGPoint(x: cell.minX + cw * 0.3, y: cell.minY))
                context.stroke(strike, with: .color(maroon), lineWidth: stroke * 1.5)
            }
        }
        context.stroke(grid, with: .color(ink), lineWidth: stroke)

        for s in 1...12 {
            let (row, col) = southCells[s - 1]
            let cell = cellRect(row, col).insetBy(dx: cw * 0.06, dy: ch * 0.08)
            var tokens = signs[s - 1]
            if s == ascSign { tokens = ["As"] + tokens }
            drawTokens(context, tokens, in: cell, base: base)
        }
    }
}

struct TransitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TransitEntry

    private var isLarge: Bool { family == .systemLarge }
    private var grahas: [Graha] { parseGrahas(entry.line) }

    /// Chart requires per-entry data (older app builds don't write it),
    /// the Canvas API, and the large family — only there does it have
    /// room to breathe; small/medium stay text-only.
    private var hasChart: Bool {
        guard entry.ascSign >= 1, entry.signs.count == 12,
              family == .systemLarge else { return false }
        if #available(iOSApplicationExtension 15.0, *) { return true }
        return false
    }

    private func grid(columns: Int, size: CGFloat, spacing: CGFloat) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), alignment: .leading),
                         count: columns)
        return LazyVGrid(columns: cols, alignment: .leading, spacing: spacing) {
            ForEach(grahas) { GrahaCell(graha: $0, size: size) }
        }
    }

    @ViewBuilder
    private var chart: some View {
        if #available(iOSApplicationExtension 15.0, *) {
            TransitChartView(ascSign: entry.ascSign, signs: entry.signs,
                             style: entry.style)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 6 : 4) {
            HStack {
                Text("Live Transit")
                    .font(.system(size: isLarge ? 15 : 11, weight: .semibold))
                    .foregroundColor(inkSoft)
                    .textCase(.uppercase)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.system(size: isLarge ? 12 : 10))
                    .foregroundColor(inkSoft)
            }
            Text(entry.asc)
                .font(.system(size: isLarge ? 16 : 13, weight: .bold))
                .foregroundColor(maroon)
                .lineLimit(family == .systemSmall ? 2 : 1)
                .minimumScaleFactor(0.7)
            if grahas.isEmpty && !hasChart {
                // Fallback (unparseable / "Open the app once" state).
                Text(entry.line)
                    .font(.system(size: 12))
                    .foregroundColor(ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            } else {
                switch family {
                case .systemSmall:
                    Spacer(minLength: 2)
                    grid(columns: 2, size: 10, spacing: 3)
                    Spacer(minLength: 2)
                case .systemLarge:
                    if hasChart {
                        // Chart only — it already carries every
                        // placement, so no graha grid alongside.
                        Spacer(minLength: 4)
                        HStack {
                            Spacer(minLength: 0)
                            chart
                            Spacer(minLength: 0)
                        }
                        Spacer(minLength: 4)
                    } else {
                        Spacer(minLength: 2)
                        grid(columns: 3, size: 16, spacing: 12)
                        Spacer(minLength: 2)
                    }
                default:
                    Spacer(minLength: 2)
                    grid(columns: 3, size: 13, spacing: 6)
                    Spacer(minLength: 2)
                }
            }
        }
        .padding(12)
        .containerBackgroundCompat(paper)
    }
}

struct TransitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TransitWidget", provider: TransitProvider()) { entry in
            TransitWidgetView(entry: entry)
        }
        .configurationDisplayName("Live Transit")
        .description("The current sky: rising lagna and every graha's sign.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Bundle & compat

@main
struct KaalJyotiWidgetBundle: WidgetBundle {
    var body: some Widget {
        PanchangWidget()
        TransitWidget()
    }
}

extension View {
    /// iOS 17 requires containerBackground; earlier versions use a
    /// plain background.
    @ViewBuilder
    func containerBackgroundCompat(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}
