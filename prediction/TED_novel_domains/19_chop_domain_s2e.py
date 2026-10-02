import base64
import struct
import sys

def extract_accession(header):
    return header.split()[0]

def return_fasta_dict(file_path, header_transform):
    with open(file_path, 'r') as file:
        lines = file.read().strip().split("\n")
    # print(header_transform)
    seq_dict = {header_transform(lines[i].strip(">").split(" ")[0]): lines[i + 1].upper() for i in range(0, len(lines), 2)}
    # print(seq_dict)
    return seq_dict

def return_coordinates_dict(file_path, header_transform):
    with open(file_path, 'r') as file:
        lines = file.read().strip().split("\n")
    coords_dict = {}
    for i in range(0, len(lines), 2):
        header = header_transform(lines[i].strip(">").split(" ")[0])
        csv_data = lines[i + 1].strip()
        coords = [float(val) for val in csv_data.split(',')]
        
        # Ensure the number of coordinates is a multiple of 3
        if len(coords) % 3 != 0:
            print(f"Error: number of coordinates for header {header} is not a multiple of 3")
            continue

        coords_dict[header] = coords
    return coords_dict

def main():
    if len(sys.argv) != 4:
        print("Usage: script.py <input_prefix> <pfam_coords_input> <output_prefix>")
        sys.exit(1)

    # Read input arguments
    input_prefix = sys.argv[1]
    pfam_coords_input = sys.argv[2]
    output_prefix = sys.argv[3]

    # Construct file paths
    fasta_af_path = f"{input_prefix}.fasta"
    fasta_af_ss_path = f"{input_prefix}_ss.fasta"
    coords_path = f"{input_prefix}_ca.fasta"

    # Load input data
    pfam_seeds_fl_af = return_fasta_dict(fasta_af_path, extract_accession)
    pfam_seeds_fl_af_ss = return_fasta_dict(fasta_af_ss_path, extract_accession)
    pfam_coords = return_coordinates_dict(coords_path, extract_accession)

    retained_seqs_af = {}
    retained_seqs_af_ss = {}
    retained_coords = {}

    with open(pfam_coords_input, 'r') as pfam_cords:
        for line in pfam_cords:
            try:
                # print(line)
                seq_id, cords_and_pfs = line.strip().split("\t")
                # cords_and_pfs = line.strip()
            except ValueError:
                print(line)
                raise

            if seq_id not in pfam_seeds_fl_af or seq_id not in pfam_seeds_fl_af_ss or seq_id not in pfam_coords:
                # print("he")
                # print("pfam_seeds_fl_af", pfam_seeds_fl_af)
                # print("pfam_seeds_fl_af_ss", pfam_seeds_fl_af_ss)
                # print("pfam_coords", pfam_coords)
                continue

            cords_and_pfs = cords_and_pfs.split(",")
            # print(seq_id, len(cords_and_pfs))
            coords = []
            for i in range(0, len(cords_and_pfs), 3):
                coords.append(int(cords_and_pfs[i]))
                coords.append(int(cords_and_pfs[i+1]))
            coords.sort()
            start, end, _ = coords[0], coords[-1], cords_and_pfs[len(cords_and_pfs)-1]
            key = f"{seq_id}_{start}_{end}_{_}"
            retained_seqs_af[key] = pfam_seeds_fl_af[seq_id][start-1:end]
            retained_seqs_af_ss[key] = pfam_seeds_fl_af_ss[seq_id][start-1:end]
            
            # Adjust slicing for x,y,z format in base64 encoded binary floats
            total_len = len(pfam_coords[seq_id]) // 3
            x_slice = pfam_coords[seq_id][(start-1):end]
            y_slice = pfam_coords[seq_id][total_len + (start-1):total_len + end]
            z_slice = pfam_coords[seq_id][2*total_len + (start-1):2*total_len + end]
            retained_coords[key] = x_slice + y_slice + z_slice

    # Output file paths
    with open(f"{output_prefix}.tsv", 'w') as outfile1, \
         open(f"{output_prefix}_ss.tsv", 'w') as outfile2, \
         open(f"{output_prefix}_h.tsv", 'w') as outfile3, \
         open(f"{output_prefix}_ca.tsv", 'w') as outfile4:
        i = 0
        for seq_id, seq in retained_seqs_af.items():
            outfile1.write(f"{i}\t{seq}\n")
            outfile2.write(f"{i}\t{retained_seqs_af_ss[seq_id]}\n")
            outfile3.write(f"{i}\t{seq_id}\n")
            coords_str = ",".join(map(str, retained_coords[seq_id]))
            outfile4.write(f"{i}\t{coords_str}\n")
            i += 1

if __name__ == "__main__":
    main()



# awk '{ split($1, arr, "-"); print arr[2]"\t"$2 }' TED_n_hits_625k_only_boundaries_modified.tsv