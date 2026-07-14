package com.kaaljyoti

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.text.style.StyleSpan
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/**
 * Live Transit widget. Prefers the freshest entry of the precomputed
 * 12-hour timeline (tw_timeline JSON) so the rising lagna stays
 * roughly current between app opens; falls back to the last direct
 * snapshot (tw_asc / tw_line). Entries additionally carry chart data
 * ("a" = ascendant sign 1-12, "s" = 12 '|'-separated sign groups) from
 * which a North/South chart bitmap is drawn natively — the widget
 * cannot run Flutter, so the geometry of the app's chart painters is
 * ported here.
 */
class TransitWidgetProvider : AppWidgetProvider() {

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        // Re-render on resize so the chart appears/disappears with the
        // available height.
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        var asc = data.getString("tw_asc", "Open the app once") ?: ""
        var line = data.getString("tw_line", "") ?: ""
        var updated = data.getString("tw_updated", "") ?: ""
        val style = data.getString("tw_style", "north") ?: "north"
        var ascSign = 0
        var signs: List<List<String>> = emptyList()

        // Pick the latest timeline entry that is not in the future.
        // Timestamps are epoch milliseconds (see OsWidgetService).
        try {
            val json = data.getString("tw_timeline", null)
            if (json != null) {
                val entries = JSONArray(json)
                val now = System.currentTimeMillis()
                for (i in 0 until entries.length()) {
                    val e = entries.getJSONObject(i)
                    val t = e.getString("t").toLongOrNull() ?: continue
                    if (t <= now) {
                        asc = e.getString("asc")
                        line = e.getString("line")
                        updated = SimpleDateFormat("HH:mm", Locale.US).format(t)
                        ascSign = e.optString("a").toIntOrNull() ?: 0
                        signs = parseSigns(e.optString("s"))
                    }
                }
            }
        } catch (_: Exception) {
            // Fall back to the direct snapshot strings.
        }

        // "Su Gem · Mo Tau · Ma Pis® · …" → 9 styled grid cells (bold
        // maroon abbr, plain sign, muted ®) matching the iOS grid.
        // Null when the line isn't in the expected shape.
        val gridCells = buildGridCells(context, line)
        val gridIds = intArrayOf(
            R.id.tw_g0, R.id.tw_g1, R.id.tw_g2, R.id.tw_g3, R.id.tw_g4,
            R.id.tw_g5, R.id.tw_g6, R.id.tw_g7, R.id.tw_g8,
        )

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_transit)
            views.setTextViewText(R.id.tw_asc, asc)
            views.setTextViewText(R.id.tw_line, line)
            views.setTextViewText(R.id.tw_updated, "as of $updated")

            // Chart only on "large" widgets (4+ rows; minHeight follows
            // the 70n-30 dp convention → 4 rows ≈ 250dp) and only when
            // the entry carries chart data. The chart REPLACES the
            // graha text — it already shows every placement. Otherwise
            // show the 3×3 grid (or the plain line if unparseable).
            val minH = appWidgetManager.getAppWidgetOptions(id)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val chartMode = ascSign in 1..12 && signs.size == 12 && minH >= 230
            if (chartMode) {
                val px = (220 * context.resources.displayMetrics.density).toInt()
                views.setImageViewBitmap(
                    R.id.tw_chart,
                    drawChart(context, ascSign, signs, style, px)
                )
            }
            views.setViewVisibility(
                R.id.tw_chart,
                if (chartMode) android.view.View.VISIBLE else android.view.View.GONE
            )
            views.setViewVisibility(
                R.id.tw_grid,
                if (!chartMode && gridCells != null) android.view.View.VISIBLE
                else android.view.View.GONE
            )
            views.setViewVisibility(
                R.id.tw_line,
                if (!chartMode && gridCells == null) android.view.View.VISIBLE
                else android.view.View.GONE
            )
            if (gridCells != null) {
                for (i in gridIds.indices) {
                    views.setTextViewText(gridIds[i], gridCells[i])
                }
            }

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.tw_root, pending)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** "Su Gem · Mo Tau · Ma Pis® · …" → 9 styled cells for the graha
     *  grid, or null if the line isn't in that shape (e.g. the "Open
     *  the app once" fallback). Style matches the iOS GrahaCell: bold
     *  maroon abbreviation, plain ink sign, muted smaller ®. */
    private fun buildGridCells(
        context: Context,
        line: String
    ): List<CharSequence>? {
        val ink = context.getColor(R.color.widget_ink)
        val inkSoft = context.getColor(R.color.widget_ink_soft)
        val maroon = context.getColor(R.color.widget_maroon)
        val tokens = line.split(" · ").filter { it.isNotEmpty() }
        if (tokens.size != 9) return null
        val cells = mutableListOf<CharSequence>()
        for (raw in tokens) {
            val retro = raw.endsWith("®")
            val t = if (retro) raw.dropLast(1) else raw
            val parts = t.trim().split(" ")
            if (parts.size != 2) return null
            val text = "${parts[0]} ${parts[1]}${if (retro) " ®" else ""}"
            val span = SpannableString(text)
            val flags = Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
            span.setSpan(StyleSpan(android.graphics.Typeface.BOLD),
                0, parts[0].length, flags)
            span.setSpan(ForegroundColorSpan(maroon), 0, parts[0].length, flags)
            span.setSpan(ForegroundColorSpan(ink),
                parts[0].length, parts[0].length + 1 + parts[1].length, flags)
            if (retro) {
                span.setSpan(ForegroundColorSpan(inkSoft),
                    text.length - 1, text.length, flags)
                span.setSpan(RelativeSizeSpan(0.8f),
                    text.length - 1, text.length, flags)
            }
            cells.add(span)
        }
        return cells
    }

    /** "Su,Ma®||Mo|…" → 12 sign-indexed planet groups ([] on mismatch). */
    private fun parseSigns(s: String?): List<List<String>> {
        if (s.isNullOrEmpty()) return emptyList()
        val groups = s.split("|")
        if (groups.size != 12) return emptyList()
        return groups.map { if (it.isEmpty()) emptyList() else it.split(",") }
    }

    // ---- Native chart drawing (ported from the app's chart painters) ----

    /** North-chart house geometry: centroid, inner vertex, content rect
     *  (normalized 0..1), index 0 = house 1, counter-clockwise. */
    private data class House(
        val cx: Float, val cy: Float,   // centroid
        val vx: Float, val vy: Float,   // inner vertex
        val l: Float, val t: Float, val w: Float, val h: Float // content
    )

    private val northHouses = listOf(
        House(0.50f, 0.25f, 0.50f, 0.50f, 0.38f, 0.14f, 0.24f, 0.22f),
        House(0.25f, 1f / 12, 0.25f, 0.25f, 0.145f, 0.025f, 0.21f, 0.11f),
        House(1f / 12, 0.25f, 0.25f, 0.25f, 0.02f, 0.14f, 0.115f, 0.22f),
        House(0.25f, 0.50f, 0.50f, 0.50f, 0.13f, 0.39f, 0.24f, 0.22f),
        House(1f / 12, 0.75f, 0.25f, 0.75f, 0.02f, 0.64f, 0.115f, 0.22f),
        House(0.25f, 11f / 12, 0.25f, 0.75f, 0.145f, 0.865f, 0.21f, 0.11f),
        House(0.50f, 0.75f, 0.50f, 0.50f, 0.38f, 0.64f, 0.24f, 0.22f),
        House(0.75f, 11f / 12, 0.75f, 0.75f, 0.645f, 0.865f, 0.21f, 0.11f),
        House(11f / 12, 0.75f, 0.75f, 0.75f, 0.865f, 0.64f, 0.115f, 0.22f),
        House(0.75f, 0.50f, 0.50f, 0.50f, 0.63f, 0.39f, 0.24f, 0.22f),
        House(11f / 12, 0.25f, 0.75f, 0.25f, 0.865f, 0.14f, 0.115f, 0.22f),
        House(0.75f, 1f / 12, 0.75f, 0.25f, 0.645f, 0.025f, 0.21f, 0.11f),
    )

    /** Fixed South-chart (row, col) per sign 1-12 (Aries…Pisces):
     *  Pisces top-left, zodiac clockwise (matches SouthChartPainter). */
    private val southCells = listOf(
        0 to 1, 0 to 2, 0 to 3, 1 to 3, 2 to 3, 3 to 3,
        3 to 2, 3 to 1, 3 to 0, 2 to 0, 1 to 0, 0 to 0,
    )

    private fun drawChart(
        context: Context,
        ascSign: Int,
        signs: List<List<String>>,
        style: String,
        sizePx: Int
    ): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val ink = context.getColor(R.color.widget_ink)
        val inkSoft = context.getColor(R.color.widget_ink_soft)
        val maroon = context.getColor(R.color.widget_maroon)

        val base = sizePx.toFloat()
        val strokeW = max(1f, base * 0.008f)
        val r = RectF(strokeW / 2, strokeW / 2, base - strokeW / 2, base - strokeW / 2)

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ink
            this.style = Paint.Style.STROKE
            strokeWidth = strokeW
        }
        val tintFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = maroon
            alpha = 15 // ≈0.06
            this.style = Paint.Style.FILL
        }
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ink
            textAlign = Paint.Align.CENTER
        }

        fun x(f: Float) = r.left + r.width() * f
        fun y(f: Float) = r.top + r.height() * f

        /** Wrap tokens into lines and draw centered in [rect], shrinking
         *  the text until the block fits. */
        fun drawTokens(tokens: List<String>, rect: RectF) {
            if (tokens.isEmpty()) return
            val perLine = if (rect.width() > rect.height()) 2 else 1
            val lines = tokens.chunked(perLine).map { it.joinToString(" ") }
            var fs = min(base * 0.062f, 11 * context.resources.displayMetrics.density)
            text.textSize = fs
            var maxW = 0f
            for (l in lines) maxW = max(maxW, text.measureText(l))
            val lineH = text.fontMetrics.let { it.descent - it.ascent }
            val scale = min(
                1f,
                min(rect.width() / max(maxW, 1f), rect.height() / max(lineH * lines.size, 1f))
            )
            fs = max(base * 0.03f, fs * scale)
            text.textSize = fs
            val fm = text.fontMetrics
            val lh = fm.descent - fm.ascent
            var ty = rect.centerY() - lh * lines.size / 2 - fm.ascent
            for (l in lines) {
                canvas.drawText(l, rect.centerX(), ty, text)
                ty += lh
            }
        }

        if (style == "south") {
            fun cell(row: Int, col: Int) = RectF(
                r.left + col * r.width() / 4, r.top + row * r.height() / 4,
                r.left + (col + 1) * r.width() / 4, r.top + (row + 1) * r.height() / 4
            )
            for (s in 1..12) {
                val (row, col) = southCells[s - 1]
                val c = cell(row, col)
                if (s == ascSign) {
                    canvas.drawRect(c, tintFill)
                    val strike = Paint(stroke).apply {
                        color = maroon; strokeWidth = strokeW * 1.5f
                    }
                    canvas.drawLine(
                        c.left, c.top + c.height() * 0.3f,
                        c.left + c.width() * 0.3f, c.top, strike
                    )
                }
                canvas.drawRect(c, stroke)
            }
            for (s in 1..12) {
                val (row, col) = southCells[s - 1]
                val c = cell(row, col)
                c.inset(c.width() * 0.06f, c.height() * 0.08f)
                val tokens =
                    if (s == ascSign) listOf("As") + signs[s - 1] else signs[s - 1]
                drawTokens(tokens, c)
            }
        } else {
            // Lagna house (top diamond) tint.
            val tint = Path().apply {
                moveTo(x(0.5f), y(0f)); lineTo(x(0.75f), y(0.25f))
                lineTo(x(0.5f), y(0.5f)); lineTo(x(0.25f), y(0.25f)); close()
            }
            canvas.drawPath(tint, tintFill)
            // Frame, diagonals, inner diamond.
            canvas.drawRect(r, stroke)
            canvas.drawLine(r.left, r.top, r.right, r.bottom, stroke)
            canvas.drawLine(r.right, r.top, r.left, r.bottom, stroke)
            val diamond = Path().apply {
                moveTo(r.centerX(), r.top); lineTo(r.right, r.centerY())
                lineTo(r.centerX(), r.bottom); lineTo(r.left, r.centerY()); close()
            }
            canvas.drawPath(diamond, stroke)

            for (n in 1..12) {
                val h = northHouses[n - 1]
                val signNumber = ((ascSign - 1 + n - 1) % 12) + 1
                // Sign number tucked toward the inner corner (lerp 0.25).
                text.textSize = max(6f, base * 0.045f)
                text.color = if (n == 1) maroon else inkSoft
                val sx = h.vx + 0.25f * (h.cx - h.vx)
                val sy = h.vy + 0.25f * (h.cy - h.vy)
                val fm = text.fontMetrics
                canvas.drawText(
                    "$signNumber", x(sx), y(sy) - (fm.ascent + fm.descent) / 2, text
                )
                text.color = ink
                val content = RectF(
                    x(h.l), y(h.t), x(h.l + h.w), y(h.t + h.h)
                )
                val tokens =
                    if (n == 1) listOf("As") + signs[signNumber - 1]
                    else signs[signNumber - 1]
                drawTokens(tokens, content)
            }
        }
        return bmp
    }
}
