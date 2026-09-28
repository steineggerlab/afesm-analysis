#!/usr/bin/env python3
"""Generate minimalistic SVG table for biome LCB comparison.
Same style as deepfri_novel_domains_supptable5.svg."""

import html

FONT_DIR = "/usr/share/fonts/truetype/dejavu"

# Two sub-tables combined into one
# Table A: Novel fold clusters vs ESM-only background
# Table B: Novel MDP clusters vs ESM-only MDP background

HEADERS_A = ["LCB", "Novel fold clusters\n(n = 45)", "ESM-only background\n(n = 3.54M)"]
ROWS_A = [
    ("Unlabeled", "57.7%", "80.1%"),
    ("Root", "24.4%", "17.4%"),
    ("Marine", "15.6%", "1.0%"),
    ("Aquatic (other)", "0.0%", "0.9%"),
    ("Host-associated", "2.2%", "0.6%"),
]

HEADERS_B = ["LCB", "MDPs with novel\nT-level pairs (n = 11,941)", "ESM-only MDPs\n(n = 393,793)"]
ROWS_B = [
    ("Unlabeled", "42.5%", "57.8%"),
    ("Root", "53.2%", "38.3%"),
    ("Host-associated", "2.2%", "1.7%"),
    ("Environmental:Aquatic", "0.8%", "1.9%"),
    ("Marine", "0.7%", "1.0%"),
]

COL_WIDTHS = [200, 220, 220]
ROW_HEIGHT = 28
HEADER_HEIGHT = 42
SECTION_HEIGHT = 30
FONT_SIZE = 13
HEADER_FONT_SIZE = 13
PADDING_LEFT = 12
MARGIN_TOP = 20
MARGIN_LEFT = 20
GAP = 20

total_width = MARGIN_LEFT * 2 + sum(COL_WIDTHS)
total_height = (MARGIN_TOP + SECTION_HEIGHT + HEADER_HEIGHT + ROW_HEIGHT * len(ROWS_A) +
                GAP + SECTION_HEIGHT + HEADER_HEIGHT + ROW_HEIGHT * len(ROWS_B) + 10)

svg = []
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{total_height}" '
           f'viewBox="0 0 {total_width} {total_height}">')
svg.append(f'<rect width="{total_width}" height="{total_height}" fill="white"/>')

def draw_table(y_start, section_label, headers, rows):
    y = y_start

    # Section label
    svg.append(f'<text x="{MARGIN_LEFT + PADDING_LEFT}" y="{y + SECTION_HEIGHT - 8}" '
               f'font-family="Arial,Helvetica,sans-serif" font-size="14" font-weight="bold" '
               f'fill="#000">{html.escape(section_label)}</text>')
    y += SECTION_HEIGHT

    # Top border
    svg.append(f'<line x1="{MARGIN_LEFT}" y1="{y}" x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{y}" '
               f'stroke="#000" stroke-width="1.5"/>')

    # Header
    x = MARGIN_LEFT
    for h, w in zip(headers, COL_WIDTHS):
        lines = h.split("\n")
        for li, line in enumerate(lines):
            svg.append(f'<text x="{x + PADDING_LEFT}" y="{y + 18 + li * 16}" '
                       f'font-family="Arial,Helvetica,sans-serif" font-size="{HEADER_FONT_SIZE}" '
                       f'font-weight="bold" fill="#000">{html.escape(line)}</text>')
        x += w
    y += HEADER_HEIGHT

    # Line under header
    svg.append(f'<line x1="{MARGIN_LEFT}" y1="{y}" x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{y}" '
               f'stroke="#000" stroke-width="1.5"/>')

    # Data rows
    for i, row in enumerate(rows):
        bg = "#f9f9f9" if i % 2 == 1 else "white"
        svg.append(f'<rect x="{MARGIN_LEFT}" y="{y}" width="{sum(COL_WIDTHS)}" '
                   f'height="{ROW_HEIGHT}" fill="{bg}"/>')
        x = MARGIN_LEFT
        for cell, w in zip(row, COL_WIDTHS):
            svg.append(f'<text x="{x + PADDING_LEFT}" y="{y + ROW_HEIGHT - 9}" '
                       f'font-family="Arial,Helvetica,sans-serif" font-size="{FONT_SIZE}" '
                       f'fill="#000">{html.escape(str(cell))}</text>')
            x += w
        y += ROW_HEIGHT

    # Bottom border
    svg.append(f'<line x1="{MARGIN_LEFT}" y1="{y}" x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{y}" '
               f'stroke="#000" stroke-width="1.5"/>')

    return y

y = MARGIN_TOP
y = draw_table(y, "a  Novel fold clusters", HEADERS_A, ROWS_A)
y += GAP
y = draw_table(y, "b  Novel MDP clusters", HEADERS_B, ROWS_B)

svg.append('</svg>')

outpath = "writing/biome_lcb_supptable.svg"
with open(outpath, "w") as f:
    f.write("\n".join(svg))
print(f"Written: {outpath}")
