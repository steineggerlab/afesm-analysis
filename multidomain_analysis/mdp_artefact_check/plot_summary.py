#!/usr/bin/env python3

import csv
import html
import math
from collections import defaultdict
from pathlib import Path


GROUP_ORDER = ["novel", "non_novel"]
GROUP_LABELS = {
    "novel": "novel",
    "non_novel": "non-novel",
}
GROUP_COLORS = {
    "novel": "#1f77b4",
    "non_novel": "#d95f02",
}

ROOT = Path(__file__).resolve().parent
SUMMARY_TSV = ROOT / "mdp_per_protein_summary.tsv"
SVG_OUT = ROOT / "mdp_novel_vs_non_hlevel5203_fullset_summary.svg"
FIGURE_SUMMARY_OUT = ROOT / "figure_metrics_summary.tsv"

PANELS = [
    {
        "key": "total_domains",
        "title": "Domains per MDP",
        "ylabel": "Domains per MDP",
        "tick_mode": "int",
        "clamp_zero": False,
    },
    {
        "key": "mean_all_domain_length",
        "title": "Mean Domain Length",
        "ylabel": "Mean domain length (aa)",
        "tick_mode": "int",
        "clamp_zero": True,
    },
]


def percentile(values, pct):
    if not values:
        raise ValueError("Cannot compute percentile of empty list")
    if len(values) == 1:
        return values[0]
    ordered = sorted(values)
    pos = (len(ordered) - 1) * pct
    lower = math.floor(pos)
    upper = math.ceil(pos)
    if lower == upper:
        return ordered[lower]
    weight = pos - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def box_stats(values):
    ordered = sorted(values)
    q1 = percentile(ordered, 0.25)
    median = percentile(ordered, 0.5)
    q3 = percentile(ordered, 0.75)
    iqr = q3 - q1
    low_bound = q1 - 1.5 * iqr
    high_bound = q3 + 1.5 * iqr
    whisker_low = next(v for v in ordered if v >= low_bound)
    whisker_high = next(v for v in reversed(ordered) if v <= high_bound)
    return {
        "min": ordered[0],
        "q1": q1,
        "median": median,
        "q3": q3,
        "whisker_low": whisker_low,
        "whisker_high": whisker_high,
        "max": ordered[-1],
        "mean": sum(ordered) / len(ordered),
        "n": len(ordered),
    }


def mann_whitney_pvalue(xs, ys):
    xs = [float(v) for v in xs]
    ys = [float(v) for v in ys]
    n1 = len(xs)
    n2 = len(ys)
    if n1 == 0 or n2 == 0:
        raise ValueError("Both groups need at least one value")

    combined = [(v, 0) for v in xs] + [(v, 1) for v in ys]
    combined.sort(key=lambda item: item[0])

    rank_sum_1 = 0.0
    tie_term = 0.0
    i = 0
    rank = 1
    total = n1 + n2

    while i < total:
        j = i + 1
        while j < total and combined[j][0] == combined[i][0]:
            j += 1
        tie_count = j - i
        avg_rank = (rank + (rank + tie_count - 1)) / 2.0
        for k in range(i, j):
            if combined[k][1] == 0:
                rank_sum_1 += avg_rank
        if tie_count > 1:
            tie_term += tie_count ** 3 - tie_count
        rank += tie_count
        i = j

    u1 = rank_sum_1 - (n1 * (n1 + 1)) / 2.0
    u2 = n1 * n2 - u1
    u = min(u1, u2)
    mu = n1 * n2 / 2.0
    sigma_sq = (n1 * n2 / 12.0) * ((total + 1) - tie_term / (total * (total - 1)))
    if sigma_sq <= 0:
        return 1.0
    sigma = math.sqrt(sigma_sq)
    continuity = 0.5 if u != mu else 0.0
    z = (abs(u - mu) - continuity) / sigma
    pvalue = math.erfc(z / math.sqrt(2.0))
    return min(max(pvalue, 0.0), 1.0)


def format_pvalue(pvalue):
    if pvalue == 0.0:
        return "<1e-300"
    if pvalue < 1e-4:
        return f"{pvalue:.1e}"
    return f"{pvalue:.4f}"


def svg_text(
    x,
    y,
    text,
    size=12,
    anchor="start",
    weight="normal",
    fill="#111111",
    rotate=None,
):
    transform = ""
    if rotate is not None:
        transform = f' transform="rotate({rotate} {x:.2f} {y:.2f})"'
    return (
        f'<text x="{x:.2f}" y="{y:.2f}" font-family="Arial, Helvetica, sans-serif" '
        f'font-size="{size}" text-anchor="{anchor}" font-weight="{weight}" fill="{fill}"{transform}>'
        f"{html.escape(text)}</text>"
    )


def value_to_y(value, y_min, y_max, plot_top, plot_bottom):
    if y_max == y_min:
        return (plot_top + plot_bottom) / 2.0
    frac = (value - y_min) / (y_max - y_min)
    return plot_bottom - frac * (plot_bottom - plot_top)


def format_tick(value, tick_mode):
    if tick_mode == "int":
        return f"{int(round(value))}"
    return f"{value:.2f}"


def draw_panel(panel, panel_label, title, ylabel, novel_values, non_values, tick_mode="float2", clamp_zero=False):
    novel_stats = box_stats(novel_values)
    non_stats = box_stats(non_values)
    pvalue = mann_whitney_pvalue(novel_values, non_values)
    all_stats = [novel_stats, non_stats]
    y_min = min(stat["whisker_low"] for stat in all_stats)
    y_max = max(stat["whisker_high"] for stat in all_stats)
    padding = (y_max - y_min) * 0.08
    if padding == 0:
        padding = 1.0 if y_max == 0 else abs(y_max) * 0.08
    y_min -= padding
    y_max += padding
    if clamp_zero and y_min < 0:
        y_min = 0.0

    left = panel["x"]
    top = panel["y"]
    width = panel["w"]
    height = panel["h"]
    plot_left = left + 72
    plot_right = left + width - 16
    plot_top = top + 34
    plot_bottom = top + height - 42

    elements = []
    elements.append(f'<rect x="{left:.2f}" y="{top:.2f}" width="{width:.2f}" height="{height:.2f}" fill="white"/>')
    elements.append(svg_text(left + 8, top + 20, panel_label, size=16, anchor="start", weight="bold"))
    elements.append(svg_text(left + width / 2.0, top + 20, title, size=16, anchor="middle", weight="bold"))

    for tick_frac in (0.0, 0.25, 0.5, 0.75, 1.0):
        tick_value = y_min + (y_max - y_min) * tick_frac
        tick_y = value_to_y(tick_value, y_min, y_max, plot_top, plot_bottom)
        elements.append(
            f'<line x1="{plot_left:.2f}" y1="{tick_y:.2f}" x2="{plot_right:.2f}" y2="{tick_y:.2f}" '
            f'stroke="#e1e1e1" stroke-width="1"/>'
        )
        elements.append(
            svg_text(
                plot_left - 10,
                tick_y + 5,
                format_tick(tick_value, tick_mode),
                size=13,
                anchor="end",
                fill="#444444",
            )
        )

    elements.append(f'<line x1="{plot_left:.2f}" y1="{plot_top:.2f}" x2="{plot_left:.2f}" y2="{plot_bottom:.2f}" stroke="#444444" stroke-width="1.2"/>')
    elements.append(f'<line x1="{plot_left:.2f}" y1="{plot_bottom:.2f}" x2="{plot_right:.2f}" y2="{plot_bottom:.2f}" stroke="#444444" stroke-width="1.2"/>')

    centers = [
        plot_left + (plot_right - plot_left) * 0.28,
        plot_left + (plot_right - plot_left) * 0.72,
    ]
    box_width = (plot_right - plot_left) * 0.15

    stats_by_group = {
        "novel": novel_stats,
        "non_novel": non_stats,
    }

    for center, group in zip(centers, GROUP_ORDER):
        stats = stats_by_group[group]
        color = GROUP_COLORS[group]
        q1_y = value_to_y(stats["q1"], y_min, y_max, plot_top, plot_bottom)
        median_y = value_to_y(stats["median"], y_min, y_max, plot_top, plot_bottom)
        q3_y = value_to_y(stats["q3"], y_min, y_max, plot_top, plot_bottom)
        low_y = value_to_y(stats["whisker_low"], y_min, y_max, plot_top, plot_bottom)
        high_y = value_to_y(stats["whisker_high"], y_min, y_max, plot_top, plot_bottom)
        left_x = center - box_width / 2.0

        if abs(q1_y - q3_y) < 2:
            rect_y = q3_y - 1.0
            rect_h = 2.0
        else:
            rect_y = q3_y
            rect_h = q1_y - q3_y

        elements.append(f'<line x1="{center:.2f}" y1="{low_y:.2f}" x2="{center:.2f}" y2="{q1_y:.2f}" stroke="#333333" stroke-width="1.2"/>')
        elements.append(f'<line x1="{center:.2f}" y1="{q3_y:.2f}" x2="{center:.2f}" y2="{high_y:.2f}" stroke="#333333" stroke-width="1.2"/>')
        elements.append(f'<line x1="{center - box_width * 0.28:.2f}" y1="{low_y:.2f}" x2="{center + box_width * 0.28:.2f}" y2="{low_y:.2f}" stroke="#333333" stroke-width="1.2"/>')
        elements.append(f'<line x1="{center - box_width * 0.28:.2f}" y1="{high_y:.2f}" x2="{center + box_width * 0.28:.2f}" y2="{high_y:.2f}" stroke="#333333" stroke-width="1.2"/>')
        elements.append(
            f'<rect x="{left_x:.2f}" y="{rect_y:.2f}" width="{box_width:.2f}" height="{rect_h:.2f}" '
            f'fill="{color}" fill-opacity="0.70" stroke="#333333" stroke-width="1.2"/>'
        )
        elements.append(f'<line x1="{left_x:.2f}" y1="{median_y:.2f}" x2="{left_x + box_width:.2f}" y2="{median_y:.2f}" stroke="#111111" stroke-width="1.8"/>')
        mean_y = value_to_y(stats["mean"], y_min, y_max, plot_top, plot_bottom)
        elements.append(
            f'<circle cx="{center:.2f}" cy="{mean_y:.2f}" r="3.6" fill="#111111" stroke="white" stroke-width="0.8"/>'
        )
        elements.append(svg_text(center, plot_bottom + 30, GROUP_LABELS[group], size=15, anchor="middle"))
        elements.append(svg_text(center, plot_bottom + 46, f"N={stats['n']:,}", size=12, anchor="middle", fill="#444444"))

    elements.append(svg_text(left + 18, top + height / 2.0, ylabel, size=13, anchor="middle", rotate=-90))
    return "\n".join(elements), novel_stats, non_stats, pvalue


def load_values():
    values = defaultdict(list)
    with SUMMARY_TSV.open() as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            set_label = row["set_label"]
            for panel in PANELS:
                values[(set_label, panel["key"])].append(float(row[panel["key"]]))
    return values


def write_figure_summary(rows):
    with FIGURE_SUMMARY_OUT.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(
            [
                "metric",
                "set_label",
                "n",
                "min",
                "q1",
                "median",
                "q3",
                "whisker_low",
                "whisker_high",
                "max",
                "mean",
                "mwu_pvalue",
            ]
        )
        for row in rows:
            writer.writerow(row)


def main():
    values = load_values()

    width = 860
    height = 330
    svg_parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="white"/>',
    ]

    panel_width = 400.0
    panel_height = 286.0
    x_positions = [16.0, 438.0]
    y_pos = 18.0
    figure_summary_rows = []
    panel_letters = ["a", "b"]

    for panel, x, letter in zip(PANELS, x_positions, panel_letters):
        panel_svg, novel_stats, non_stats, pvalue = draw_panel(
            {"x": x, "y": y_pos, "w": panel_width, "h": panel_height},
            letter,
            panel["title"],
            panel["ylabel"],
            values[("novel", panel["key"])],
            values[("non_novel", panel["key"])],
            tick_mode=panel["tick_mode"],
            clamp_zero=panel["clamp_zero"],
        )
        svg_parts.append(panel_svg)
        for set_label, stats in [("novel", novel_stats), ("non_novel", non_stats)]:
            figure_summary_rows.append(
                [
                    panel["key"],
                    set_label,
                    stats["n"],
                    f"{stats['min']:.10f}",
                    f"{stats['q1']:.10f}",
                    f"{stats['median']:.10f}",
                    f"{stats['q3']:.10f}",
                    f"{stats['whisker_low']:.10f}",
                    f"{stats['whisker_high']:.10f}",
                    f"{stats['max']:.10f}",
                    f"{stats['mean']:.10f}",
                    f"{pvalue:.10e}",
                ]
            )

    svg_parts.append("</svg>")
    SVG_OUT.write_text("\n".join(svg_parts), encoding="utf-8")
    write_figure_summary(figure_summary_rows)
    print(SVG_OUT)
    print(FIGURE_SUMMARY_OUT)


if __name__ == "__main__":
    main()
