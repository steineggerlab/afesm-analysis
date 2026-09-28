#!/usr/bin/env python3
"""Generate a clean, minimalistic supplementary table SVG for DeepFRI results."""

import html

ROWS = [
    ("MGYP000601388902_02", "Cellular component", "Cytoplasm", "GO:0005737", "0.86"),
    ("MGYP000793087123_01", "Biological process", "Organic substance metabolic process", "GO:0071704", "0.82"),
    ("MGYP001824741318_02", "Molecular function", "Organic cyclic compound binding", "GO:0097159", "0.87"),
    ("MGYP001824741318_02", "Biological process", "Nitrogen compound metabolic process", "GO:0006807", "0.98"),
    ("MGYP001824741318_02", "Molecular function", "Heterocyclic compound binding", "GO:1901363", "0.87"),
    ("MGYP001824741318_02", "Biological process", "Cellular nitrogen compound metabolic process", "GO:0034641", "0.96"),
    ("MGYP001824741318_02", "Molecular function", "Structural constituent of ribosome", "GO:0003735", "0.81"),
    ("MGYP001824741318_02", "Biological process", "Macromolecule metabolic process", "GO:0043170", "0.96"),
    ("MGYP001824741318_02", "Biological process", "Organic substance metabolic process", "GO:0071704", "0.92"),
    ("MGYP001824741318_02", "Biological process", "Organonitrogen compound biosynthetic process", "GO:1901566", "0.91"),
    ("MGYP001824741318_02", "Biological process", "Cellular amide metabolic process", "GO:0043603", "0.88"),
    ("MGYP001824741318_02", "Biological process", "Primary metabolic process", "GO:0044238", "0.88"),
    ("MGYP001824741318_02", "Biological process", "Gene expression", "GO:0010467", "0.88"),
    ("MGYP001824741318_02", "Biological process", "Translation", "GO:0006412", "0.81"),
    ("MGYP002515535607_03", "Molecular function", "Isomerase activity", "GO:0016853", "0.88"),
]

HEADERS = ["Domain ID", "GO namespace", "GO term", "GO ID", "Confidence"]

# Layout
COL_WIDTHS = [240, 180, 380, 120, 100]
ROW_HEIGHT = 30
HEADER_HEIGHT = 34
FONT_SIZE = 14
HEADER_FONT_SIZE = 14
PADDING_LEFT = 12
MARGIN_TOP = 30
MARGIN_LEFT = 20

total_width = MARGIN_LEFT * 2 + sum(COL_WIDTHS)
total_height = MARGIN_TOP + HEADER_HEIGHT + ROW_HEIGHT * len(ROWS) + 10

svg = []
svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{total_height}" '
           f'viewBox="0 0 {total_width} {total_height}">')
svg.append(f'<rect width="{total_width}" height="{total_height}" fill="white"/>')

y = MARGIN_TOP

# Header background
svg.append(f'<rect x="{MARGIN_LEFT}" y="{y}" width="{sum(COL_WIDTHS)}" '
           f'height="{HEADER_HEIGHT}" fill="white"/>')

# Header text
x = MARGIN_LEFT
for header, w in zip(HEADERS, COL_WIDTHS):
    svg.append(f'<text x="{x + PADDING_LEFT}" y="{y + HEADER_HEIGHT - 10}" '
               f'font-family="Arial, Helvetica, sans-serif" font-size="{HEADER_FONT_SIZE}" '
               f'font-weight="bold" fill="#000000">{html.escape(header)}</text>')
    x += w

y += HEADER_HEIGHT

# Line under header
svg.append(f'<line x1="{MARGIN_LEFT}" y1="{y}" x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{y}" '
           f'stroke="#000000" stroke-width="1.5"/>')

# Data rows
prev_domain = None
for i, (domain_id, namespace, go_name, go_id, confidence) in enumerate(ROWS):
    # Alternating row shading
    bg = "#f9f9f9" if i % 2 == 1 else "white"
    svg.append(f'<rect x="{MARGIN_LEFT}" y="{y}" width="{sum(COL_WIDTHS)}" '
               f'height="{ROW_HEIGHT}" fill="{bg}"/>')

    # Thin line between different domains
    if prev_domain is not None and domain_id != prev_domain:
        svg.append(f'<line x1="{MARGIN_LEFT}" y1="{y}" '
                   f'x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{y}" '
                   f'stroke="#000000" stroke-width="0.5"/>')

    # Show domain ID only on first row of each domain
    display_domain = domain_id if domain_id != prev_domain else ""

    cells = [display_domain, namespace, go_name, go_id, confidence]
    x = MARGIN_LEFT
    for cell, w in zip(cells, COL_WIDTHS):
        svg.append(f'<text x="{x + PADDING_LEFT}" y="{y + ROW_HEIGHT - 9}" '
                   f'font-family="Arial, Helvetica, sans-serif" font-size="{FONT_SIZE}" '
                   f'font-weight="normal" fill="#000000">{html.escape(str(cell))}</text>')
        x += w

    prev_domain = domain_id
    y += ROW_HEIGHT

# Bottom line
svg.append(f'<line x1="{MARGIN_LEFT}" y1="{y}" x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{y}" '
           f'stroke="#000000" stroke-width="1.5"/>')

# Top line
svg.append(f'<line x1="{MARGIN_LEFT}" y1="{MARGIN_TOP}" '
           f'x2="{MARGIN_LEFT + sum(COL_WIDTHS)}" y2="{MARGIN_TOP}" '
           f'stroke="#000000" stroke-width="1.5"/>')

svg.append('</svg>')

out_path = "/workspace/yewon1/afesm/afesm_revision_natcom/writing/deepfri_novel_domains_supptable5.svg"
with open(out_path, "w") as f:
    f.write("\n".join(svg))
print(f"Written to {out_path}")
