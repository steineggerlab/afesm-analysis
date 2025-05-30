import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

data = pd.read_csv('final_table_metagenome.tsv', sep='\t')

data['classification_grouped'] = data['classification'].apply(
    lambda x: 'CATH_MATCH' if x == 'CATH_MATCH' else 'NO_CATH_MATCH'
)

data_filtered = data

sns.set_theme(style="whitegrid", context="notebook")

fig, axes = plt.subplots(3, 3, figsize=(18, 18))
fig.tight_layout(pad=2.0)

# Pie Chart 1: Proportion of entries with pLDDT < 70 and >= 70
plddt_counts = data['pLDDT'].apply(lambda x: '<70' if x < 70 else '>=70').value_counts()
axes[0, 0].pie(plddt_counts, labels=plddt_counts.index, autopct='%1.1f%%', colors=['#348ABD', '#A60628'])
axes[0, 0].set_title("pLDDT")

# Pie Chart 2: num_helix_strand < 6 and >= 6
helix_counts = data['num_helix_strand'].apply(lambda x: '<6' if x < 6 else '>=6').value_counts()
axes[0, 1].pie(helix_counts, labels=helix_counts.index, autopct='%1.1f%%', colors=['#348ABD', '#A60628'])
axes[0, 1].set_title("Secondary Structure Elements")

# Pie Chart 3: Globularity categories (G and NG)
globularity_counts = data['globularity'].value_counts()  # Directly count occurrences of 'G' and 'NG'
axes[0, 2].pie(
    globularity_counts, 
    labels=globularity_counts.index, 
    autopct='%1.1f%%', 
    colors=['#348ABD', '#A60628']  # Optional: ensure consistent color scheme
)
axes[0, 2].set_title("Globularity")

# Middle Left: Distribution of pLDDT by grouped classifications
sns.histplot(data=data_filtered, x="pLDDT", hue="classification_grouped", ax=axes[1, 0], kde=True, bins=30, palette="tab10")
axes[1, 0].set_title("pLDDT")
axes[1, 0].set_xlabel("pLDDT")
axes[1, 0].legend(labels=['CATH_MATCH', 'NO_CATH_MATCH'], title="Classification", fontsize='small', loc="upper left")

# Middle Center: Distribution of pLDDT80 by grouped classifications
sns.histplot(data=data_filtered, x="pLDDT80", hue="classification_grouped", ax=axes[1, 1], kde=True, bins=30, palette="tab10")
axes[1, 1].set_title("pLDDT80")
axes[1, 1].set_xlabel("pLDDT80")
axes[1, 1].legend(labels=['CATH_MATCH', 'NO_CATH_MATCH'], title="Classification", fontsize='small', loc="upper left")

# Middle Right: Categories in 'classification' with log scale
classification_counts = data_filtered['classification'].value_counts()

category_order = classification_counts.index.tolist()

sns.barplot(
    x=classification_counts.index, 
    y=classification_counts.values, 
    ax=axes[1, 2], 
    order=category_order
)
axes[1, 2].set_title("Domain classification")
axes[1, 2].set_xlabel("Classification")
axes[1, 2].set_ylabel("Count (Log Scale)")
axes[1, 2].set_yscale('log')  # Apply log scale to y-axis

axes[1, 2].set_xticklabels(
    classification_counts.index, 
    rotation=45, 
    ha='right',  # Horizontal alignment
)

# Bottom Left: Hexbin plot for pLDDT vs length
hb = axes[2, 0].hexbin(
    data_filtered['length'], 
    data_filtered['pLDDT'], 
    gridsize=50, 
    cmap="viridis", 
    mincnt=1
)
axes[2, 0].set_title("pLDDT vs domain length")
axes[2, 0].set_xlabel("Length")
axes[2, 0].set_ylabel("pLDDT")

# Add color bar for density
cb = fig.colorbar(hb, ax=axes[2, 0], orientation="vertical")
cb.set_label('Data Density')

# Bottom Center: Box plot of pLDDT by consensus
sns.boxplot(data=data_filtered, x="consensus", y="pLDDT", ax=axes[2, 1])
axes[2, 1].set_title("pLDDT by consensus")
axes[2, 1].set_xlabel("Consensus")
axes[2, 1].set_ylabel("pLDDT")

# Bottom Right: Scatter plot for packing_density vs nrg
sns.scatterplot(
    data=data_filtered, 
    x="nrg", 
    y="packing_density",  # Column 14 (packing_density) is correctly used
    hue="classification", 
    ax=axes[2, 2], 
    alpha=0.6,  # Slight transparency to reduce overlap
    edgecolor=None,  # Avoid edges for better density display
    palette="tab10", 
    s=5  # Very small dots in the plot
)

# Add reference lines
axes[2, 2].axvline(x=0.356, color="blue", linestyle="--", label="NRG = 0.356")
axes[2, 2].axhline(y=10.333, color="red", linestyle="--", label="PD = 10.333")

axes[2, 2].set_title("Packing Density vs Normed Radius of Gyration", fontsize=12)
axes[2, 2].set_xlabel("Normed Radius of Gyration", fontsize=10)
axes[2, 2].set_ylabel("Packing Density", fontsize=10)

axes[2, 2].legend(
    title="Classification", 
    fontsize='xx-small',  # Much smaller font for legend text
    title_fontsize='x-small',  # Smaller title font size
    loc="upper right", 
    markerscale=2  # Normal-sized markers in the legend
)

plt.tight_layout(pad=2.0)  # Adjust the padding
plt.savefig("final_figure_metagenome.png", dpi=300, bbox_inches="tight")
plt.savefig("final_figure_metagenome.svg", dpi=300, bbox_inches="tight")