import os
import sys

def compute_avg_plddt(pdb_file):
    """Calculate the average pLDDT from a PDB file."""
    plddt_values = []
    with open(pdb_file, 'r') as f:
        for line in f:
            if line.startswith("ATOM"):  # Only process ATOM lines
                try:
                    plddt = float(line[60:66].strip())  # Extract pLDDT column (assuming PDB format)
                    plddt_values.append(plddt)
                except ValueError:
                    continue
    if plddt_values:
        return sum(plddt_values) / len(plddt_values)
    return None

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 19_plddt.py dir/ outputfile")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.isdir(input_dir):
        print(f"Error: {input_dir} is not a valid directory.")
        sys.exit(1)

    results = []

    for filename in os.listdir(input_dir):
        if filename.endswith(".pdb"):  # Process only PDB files
            pdb_path = os.path.join(input_dir, filename)
            avg_plddt = compute_avg_plddt(pdb_path)
            if avg_plddt is not None:
                results.append((filename, avg_plddt))

    # Write results to the output file
    with open(output_file, 'w') as out:
        for filename, avg_plddt in results:
            out.write(f"{filename}\t{avg_plddt:.2f}\n")

    print(f"Average pLDDT values have been written to {output_file}")

if __name__ == "__main__":
    main()