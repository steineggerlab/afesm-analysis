#!/usr/bin/env python3

import argparse
import csv
import html
import math
from pathlib import Path

import fitz


GROUP_ORDER = ["rescued", "unrescued"]
GROUP_COLORS = {
    "rescued": "#1f77b4",
    "unrescued": "#d95f02",
}


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
        "q1": q1,
        "median": median,
        "q3": q3,
        "whisker_low": whisker_low,
        "whisker_high": whisker_high,
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

    if total < 2:
        return 1.0

    sigma_sq = (n1 * n2 / 12.0) * ((total + 1) - tie_term / (total * (total - 1)))
    if sigma_sq <= 0:
        return 1.0

    sigma = math.sqrt(sigma_sq)
    continuity = 0.5 if u != mu else 0.0
    z = (abs(u - mu) - continuity) / sigma
    pvalue = math.erfc(z / math.sqrt(2.0))
    return min(max(pvalue, 0.0), 1.0)


def format_pvalue(pvalue):
    if pvalue < 1e-4:
        return f"{pvalue:.1e}"
    return f"{pvalue:.4f}"


def svg_text(x, y, text, size=12, anchor="start", weight="normal", fill="#111111", rotate=None):
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
    if tick_mode == "int_sparse":
        return f"{int(round(value))}"
    if tick_mode == "percent1":
        return f"{value:.1f}"
    return f"{value:.2f}"


def estimate_bandwidth(values):
    n = len(values)
    if n < 2:
        return 0.1
    mean = sum(values) / n
    var = sum((v - mean) ** 2 for v in values) / (n - 1)
    sd = math.sqrt(max(var, 0.0))
    q1 = percentile(values, 0.25)
    q3 = percentile(values, 0.75)
    iqr = q3 - q1
    scale = min(sd, iqr / 1.34) if iqr > 0 and sd > 0 else max(sd, iqr / 1.34)
    if scale <= 0:
        scale = max(abs(max(values) - min(values)) / 10.0, 0.05)
    return max(1.06 * scale * (n ** (-0.2)), 0.03)


def density_profile(values, y_min, y_max, samples=140):
    bandwidth = estimate_bandwidth(values)
    ordered = sorted(values)
    ys = [y_min + (y_max - y_min) * i / (samples - 1) for i in range(samples)]
    inv = 1.0 / (len(ordered) * bandwidth * math.sqrt(2.0 * math.pi))
    densities = []
    for y in ys:
        total = 0.0
        for value in ordered:
            z = (y - value) / bandwidth
            total += math.exp(-0.5 * z * z)
        densities.append(total * inv)
    max_density = max(densities) if densities else 1.0
    return ys, densities, max_density


def violin_path(center_x, half_width_max, ys, densities, max_density, y_min, y_max, plot_top, plot_bottom):
    if max_density <= 0:
        return ""

    right = []
    left = []
    for y_val, density in zip(ys, densities):
        y = value_to_y(y_val, y_min, y_max, plot_top, plot_bottom)
        half = half_width_max * density / max_density
        right.append((center_x + half, y))
        left.append((center_x - half, y))

    path = []
    first_x, first_y = right[0]
    path.append(f"M {first_x:.2f} {first_y:.2f}")
    for x, y in right[1:]:
        path.append(f"L {x:.2f} {y:.2f}")
    for x, y in reversed(left):
        path.append(f"L {x:.2f} {y:.2f}")
    path.append("Z")
    return " ".join(path)


def dotted_horizontal_segments(x1, x2, y, dot_radius=1.7, gap=10.0, fill="#8b0000"):
    elements = []
    x = x1
    while x <= x2:
        elements.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{dot_radius:.2f}" fill="{fill}"/>')
        x += gap
    return elements


def draw_panel(
    panel,
    title,
    ylabel,
    rescued_values,
    unrescued_values,
    tick_mode="float2",
    clamp_zero=False,
    reference_value=None,
    reference_label=None,
    style=None,
    panel_label=None,
):
    if style is None:
        style = {}

    all_values = rescued_values + unrescued_values
    y_min = min(all_values)
    y_max = max(all_values)
    padding = (y_max - y_min) * 0.08
    if padding == 0:
        padding = 0.1 if y_max == 0 else abs(y_max) * 0.08
    y_min -= padding
    y_max += padding
    if clamp_zero and y_min < 0:
        y_min = 0.0

    rescued_stats = box_stats(rescued_values)
    unrescued_stats = box_stats(unrescued_values)

    left = panel["x"]
    top = panel["y"]
    width = panel["w"]
    height = panel["h"]
    plot_left = left + style.get("plot_left_pad", 68)
    plot_right = left + width - style.get("plot_right_pad", 20)
    plot_top = top + style.get("plot_top_pad", 34)
    plot_bottom = top + height - style.get("plot_bottom_pad", 42)
    title_font_size = style.get("title_font_size", 16)
    panel_label_font_size = style.get("panel_label_font_size", 16)
    tick_font_size = style.get("tick_font_size", 11)
    group_font_size = style.get("group_font_size", 12)
    group_label_y_offset = style.get("group_label_y_offset", 28)
    ylabel_font_size = style.get("ylabel_font_size", 13)
    stats_box_width = style.get("stats_box_width", 108)
    stats_box_height = style.get("stats_box_height", 40)
    stats_font_size = style.get("stats_font_size", 11)
    tick_label_x_pad = style.get("tick_label_x_pad", 10)
    tick_label_y_pad = style.get("tick_label_y_pad", 5)

    centers = [
        plot_left + (plot_right - plot_left) * 0.30,
        plot_left + (plot_right - plot_left) * 0.72,
    ]
    violin_half_width = (plot_right - plot_left) * 0.16
    box_width = (plot_right - plot_left) * 0.12

    elements = []
    elements.append(f'<rect x="{left:.2f}" y="{top:.2f}" width="{width:.2f}" height="{height:.2f}" fill="white"/>')
    if panel_label is not None:
        elements.append(svg_text(left + 8, top + 20, panel_label, size=panel_label_font_size, weight="bold"))
    elements.append(svg_text(left + width / 2.0, top + 20, title, size=title_font_size, anchor="middle", weight="bold"))

    tick_values = []
    if tick_mode == "int":
        start = int(math.floor(y_min))
        end = int(math.ceil(y_max))
        if clamp_zero and start < 0:
            start = 0
        tick_values = list(range(start, end + 1))
        if not tick_values:
            tick_values = [0]
    else:
        tick_values = [y_min + (y_max - y_min) * frac for frac in (0.0, 0.25, 0.5, 0.75, 1.0)]

    for tick_value in tick_values:
        tick_y = value_to_y(tick_value, y_min, y_max, plot_top, plot_bottom)
        elements.append(
            f'<line x1="{plot_left:.2f}" y1="{tick_y:.2f}" x2="{plot_right:.2f}" y2="{tick_y:.2f}" '
            f'stroke="#e3e3e3" stroke-width="1"/>'
        )
        elements.append(
            svg_text(
                plot_left - tick_label_x_pad,
                tick_y + tick_label_y_pad,
                format_tick(tick_value, tick_mode),
                size=tick_font_size,
                anchor="end",
                fill="#444444",
            )
        )

    elements.append(
        f'<line x1="{plot_left:.2f}" y1="{plot_top:.2f}" x2="{plot_left:.2f}" y2="{plot_bottom:.2f}" '
        f'stroke="#444444" stroke-width="1.2"/>'
    )
    elements.append(
        f'<line x1="{plot_left:.2f}" y1="{plot_bottom:.2f}" x2="{plot_right:.2f}" y2="{plot_bottom:.2f}" '
        f'stroke="#444444" stroke-width="1.2"/>'
    )

    if reference_value is not None and y_min <= reference_value <= y_max:
        ref_y = value_to_y(reference_value, y_min, y_max, plot_top, plot_bottom)
        elements.extend(dotted_horizontal_segments(plot_left, plot_right, ref_y))
        if reference_label is not None:
            elements.append(
                f'<rect x="{plot_right - 52:.2f}" y="{ref_y - 13:.2f}" width="48" height="16" '
                f'fill="white" fill-opacity="0.92" stroke="none"/>'
            )
            elements.append(
                svg_text(plot_right - 6, ref_y + 4, reference_label, size=10, anchor="end", weight="bold", fill="#8b0000")
            )

    datasets = {
        "rescued": rescued_values,
        "unrescued": unrescued_values,
    }
    stats_map = {
        "rescued": rescued_stats,
        "unrescued": unrescued_stats,
    }

    for center, group in zip(centers, GROUP_ORDER):
        color = GROUP_COLORS[group]
        values = datasets[group]
        stats = stats_map[group]
        ys, densities, max_density = density_profile(values, y_min, y_max)
        path = violin_path(center, violin_half_width, ys, densities, max_density, y_min, y_max, plot_top, plot_bottom)
        if path:
            elements.append(
                f'<path d="{path}" fill="{color}" fill-opacity="0.26" stroke="{color}" stroke-opacity="0.55" stroke-width="1.1"/>'
            )

        q1_y = value_to_y(stats["q1"], y_min, y_max, plot_top, plot_bottom)
        median_y = value_to_y(stats["median"], y_min, y_max, plot_top, plot_bottom)
        q3_y = value_to_y(stats["q3"], y_min, y_max, plot_top, plot_bottom)
        low_y = value_to_y(stats["whisker_low"], y_min, y_max, plot_top, plot_bottom)
        high_y = value_to_y(stats["whisker_high"], y_min, y_max, plot_top, plot_bottom)
        left_x = center - box_width / 2.0

        elements.append(
            f'<line x1="{center:.2f}" y1="{low_y:.2f}" x2="{center:.2f}" y2="{q1_y:.2f}" '
            f'stroke="#333333" stroke-width="1.2"/>'
        )
        elements.append(
            f'<line x1="{center:.2f}" y1="{q3_y:.2f}" x2="{center:.2f}" y2="{high_y:.2f}" '
            f'stroke="#333333" stroke-width="1.2"/>'
        )
        elements.append(
            f'<line x1="{center - box_width * 0.35:.2f}" y1="{low_y:.2f}" x2="{center + box_width * 0.35:.2f}" y2="{low_y:.2f}" '
            f'stroke="#333333" stroke-width="1.2"/>'
        )
        elements.append(
            f'<line x1="{center - box_width * 0.35:.2f}" y1="{high_y:.2f}" x2="{center + box_width * 0.35:.2f}" y2="{high_y:.2f}" '
            f'stroke="#333333" stroke-width="1.2"/>'
        )
        elements.append(
            f'<rect x="{left_x:.2f}" y="{q3_y:.2f}" width="{box_width:.2f}" height="{q1_y - q3_y:.2f}" '
            f'fill="{color}" fill-opacity="0.82" stroke="#333333" stroke-width="1.1"/>'
        )
        elements.append(
            f'<line x1="{left_x:.2f}" y1="{median_y:.2f}" x2="{left_x + box_width:.2f}" y2="{median_y:.2f}" '
            f'stroke="#111111" stroke-width="1.8"/>'
        )
        elements.append(svg_text(center, plot_bottom + group_label_y_offset, group, size=group_font_size, anchor="middle"))

    elements.append(svg_text(left + 18, top + height / 2.0, ylabel, size=ylabel_font_size, anchor="middle", rotate=-90))
    pvalue = mann_whitney_pvalue(rescued_values, unrescued_values)
    elements.append(
        f'<rect x="{left + 6:.2f}" y="{top + 30:.2f}" width="{stats_box_width}" height="{stats_box_height}" '
        f'fill="white" fill-opacity="0.90" stroke="none"/>'
    )
    elements.append(svg_text(left + 12, top + 46, f"MWU p={format_pvalue(pvalue)}", size=stats_font_size))
    elements.append(svg_text(left + 12, top + 61, f"N={len(rescued_values)}/{len(unrescued_values)}", size=stats_font_size))
    return "\n".join(elements)


def load_master_table(path):
    rows = []
    with path.open() as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {
            "domain_id",
            "group",
            "num_residues",
            "mean_iupred",
            "msa_depth",
            "msa_match_status",
        }
        missing = required.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")

        for row in reader:
            row["num_residues"] = int(row["num_residues"])
            row["mean_iupred"] = float(row["mean_iupred"])
            if row["msa_depth"] == "NA" or row["msa_depth"] == "":
                row["msa_depth"] = None
                row["log10_msa_depth"] = None
            else:
                depth = float(row["msa_depth"])
                row["msa_depth"] = depth
                row["log10_msa_depth"] = math.log10(depth)
            rows.append(row)
    return rows


def load_neff_table(path):
    neff_by_domain = {}
    with path.open() as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {"domain_id", "neff"}
        missing = required.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"Missing required columns in Neff table: {sorted(missing)}")

        for row in reader:
            domain_id = row["domain_id"]
            neff_raw = row["neff"].strip()
            if not neff_raw:
                neff_by_domain[domain_id] = None
                continue
            neff = float(neff_raw)
            neff_by_domain[domain_id] = neff if neff > 0 else None
    return neff_by_domain


def attach_neff(rows, neff_by_domain):
    for row in rows:
        neff = neff_by_domain.get(row["domain_id"])
        row["neff"] = neff
        row["log10_neff"] = math.log10(neff) if neff is not None else None


def values_by_group(rows, column, matched_only=False):
    result = {group: [] for group in GROUP_ORDER}
    for row in rows:
        if matched_only and row["msa_match_status"] != "matched":
            continue
        value = row[column]
        if value is None:
            continue
        result[row["group"]].append(value)
    return result


def panel_layout(layout):
    if layout == "2x2":
        width = 980
        height = 640
        margin_x = 24
        margin_y = 18
        panel_gap_x = 18
        panel_gap_y = 24
        panel_width = (width - (2 * margin_x) - panel_gap_x) / 2.0
        panel_height = (height - (2 * margin_y) - panel_gap_y) / 2.0
        panels = [
            {"x": margin_x, "y": margin_y, "w": panel_width, "h": panel_height},
            {"x": margin_x + panel_width + panel_gap_x, "y": margin_y, "w": panel_width, "h": panel_height},
            {"x": margin_x, "y": margin_y + panel_height + panel_gap_y, "w": panel_width, "h": panel_height},
            {
                "x": margin_x + panel_width + panel_gap_x,
                "y": margin_y + panel_height + panel_gap_y,
                "w": panel_width,
                "h": panel_height,
            },
        ]
        style = {}
        return width, height, panels, style

    if layout == "1x4":
        width = 1420
        height = 330
        margin_x = 18
        margin_y = 18
        panel_gap_x = 12
        panel_width = (width - (2 * margin_x) - (3 * panel_gap_x)) / 4.0
        panel_height = 286
        panels = []
        for idx in range(4):
            panels.append(
                {
                    "x": margin_x + idx * (panel_width + panel_gap_x),
                    "y": margin_y,
                    "w": panel_width,
                    "h": panel_height,
                }
            )
        style = {}
        return width, height, panels, style

    if layout == "1x4_compact":
        width = 1280
        height = 330
        margin_x = 16
        margin_y = 18
        panel_gap_x = 8
        panel_width = (width - (2 * margin_x) - (3 * panel_gap_x)) / 4.0
        panel_height = 286
        panels = []
        for idx in range(4):
            panels.append(
                {
                    "x": margin_x + idx * (panel_width + panel_gap_x),
                    "y": margin_y,
                    "w": panel_width,
                    "h": panel_height,
                }
            )
        style = {
            "plot_left_pad": 72,
            "plot_right_pad": 16,
            "tick_font_size": 13,
            "group_font_size": 15,
            "group_label_y_offset": 30,
        }
        return width, height, panels, style

    raise ValueError(f"Unsupported layout: {layout}")


def render_svg(rows, output_svg, neff_cutoff, layout):
    width, height, panels, style = panel_layout(layout)

    disorder_mean = values_by_group(rows, "mean_iupred")
    domain_length = values_by_group(rows, "num_residues")
    msa_log = values_by_group(rows, "log10_msa_depth", matched_only=True)
    neff_log = values_by_group(rows, "log10_neff")

    body = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="white"/>',
        draw_panel(
            panels[0],
            "Mean IUPred3",
            "Mean IUPred3",
            disorder_mean["rescued"],
            disorder_mean["unrescued"],
            tick_mode="float2",
            clamp_zero=True,
            reference_value=0.5,
            reference_label="0.5",
            style=style,
            panel_label="a",
        ),
        draw_panel(
            panels[1],
            "log10(MSA depth)",
            "log10(MSA depth)",
            msa_log["rescued"],
            msa_log["unrescued"],
            tick_mode="int",
            clamp_zero=True,
            reference_value=math.log10(30.0),
            reference_label="30",
            style=style,
            panel_label="b",
        ),
        draw_panel(
            panels[2],
            "log10(Neff)",
            "log10(Neff)",
            neff_log["rescued"],
            neff_log["unrescued"],
            tick_mode="float2",
            clamp_zero=True,
            reference_value=None,
            reference_label=None,
            style=style,
            panel_label="c",
        ),
        draw_panel(
            panels[3],
            "Domain length",
            "Domain length (aa)",
            domain_length["rescued"],
            domain_length["unrescued"],
            tick_mode="int_sparse",
            clamp_zero=True,
            style=style,
            panel_label="d",
        ),
        "</svg>",
    ]

    output_svg.write_text("\n".join(body))


def svg_to_png_and_pdf(svg_path, png_path, pdf_path):
    svg_bytes = svg_path.read_bytes()
    doc = fitz.open(stream=svg_bytes, filetype="svg")
    page = doc[0]
    pix = page.get_pixmap(dpi=300, alpha=False)
    pix.save(str(png_path))

    pdf = fitz.open()
    width_pt = pix.width * 72.0 / 300.0
    height_pt = pix.height * 72.0 / 300.0
    out_page = pdf.new_page(width=width_pt, height=height_pt)
    out_page.insert_image(out_page.rect, pixmap=pix)
    pdf.save(str(pdf_path))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("master_table", type=Path)
    parser.add_argument("neff_table", type=Path)
    parser.add_argument("output_prefix", type=Path)
    parser.add_argument(
        "--layout",
        choices=("2x2", "1x4", "1x4_compact"),
        default="2x2",
        help="Figure layout. '2x2' is compact for A4; '1x4' is a horizontal strip; '1x4_compact' narrows the strip and enlarges axis/group labels.",
    )
    parser.add_argument(
        "--neff-cutoff",
        type=float,
        default=32.0,
        help="Reference cutoff to draw on the Neff panel in raw Neff units. Use 0 to suppress the line.",
    )
    args = parser.parse_args()

    rows = load_master_table(args.master_table)
    neff_by_domain = load_neff_table(args.neff_table)
    attach_neff(rows, neff_by_domain)
    args.output_prefix.parent.mkdir(parents=True, exist_ok=True)

    svg_path = args.output_prefix.with_suffix(".svg")
    png_path = args.output_prefix.with_suffix(".png")
    pdf_path = args.output_prefix.with_suffix(".pdf")

    render_svg(rows, svg_path, args.neff_cutoff, args.layout)
    svg_to_png_and_pdf(svg_path, png_path, pdf_path)


if __name__ == "__main__":
    main()
