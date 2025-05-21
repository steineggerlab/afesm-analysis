import re
import click

def parse_cigar(cigar_string):
    """
    Parse a CIGAR string and return a list of (operation, length) tuples.

    Args:
    cigar_string (str): The CIGAR string to parse.

    Returns:
    List[Tuple[str, int]]: A list of tuples where each tuple contains an operation and its length.
    """
    cigar_tuples = re.findall(r'(\d+)([MIDNSHP=X])', cigar_string)
    cigar_tuples = [(op, int(length)) for length, op in cigar_tuples]
    return cigar_tuples

def compute_coverage(cigar_tuples, qlen):
    """
    Compute the query coverage from a parsed CIGAR string.

    Args:
    cigar_tuples (List[Tuple[str, int]]): The parsed CIGAR string as a list of (operation, length) tuples.
    qlen (int): The length of the query sequence.

    Returns:
    float: The query coverage.
    """
    aligned_query_bases = sum(length for op, length in cigar_tuples if op in ('M', '=', 'X'))
    qcov = aligned_query_bases / qlen
    return qcov

@click.command()
@click.option('--input_file', type=click.Path(exists=True), default='final_search.m8', help="Input file containing alignment lines.")
@click.option('--output_pass', type=click.Path(), default='final_search_match.m8', help="Output file for lines that pass the filtering criteria.")
@click.option('--output_fail', type=click.Path(), default='final_search_nomatch.m8', help="Output file for lines that do not pass the filtering criteria.")
@click.option('--qcov_threshold', type=float, default=0.6, help="Threshold for qcov (default: 0.6).")
def filter_alignments(input_file, output_pass, output_fail, qcov_threshold):
    """
    Filter alignments based on (max(qtmscore, ttmscore) > 0.5 OR rmsd < 3.0) and qcov > 0.6, 
    and write the results to separate files.

    Args:
    input_file (str): The input file containing alignment lines.
    output_pass (str): The output file for lines that pass the filtering criteria.
    output_fail (str): The output file for lines that do not pass the filtering criteria.
    qcov_threshold (float): The qcov threshold for filtering.
    """
    with open(input_file, 'r') as infile, open(output_pass, 'w') as passfile, open(output_fail, 'w') as failfile:
        for line in infile:
            fields = line.strip().split()
            if len(fields) < 8:
                failfile.write(line)
                continue

            query, target, qlen, tlen, qtmscore, ttmscore, rmsd, cigar = (
                fields[0], fields[1], int(fields[2]), int(fields[3]), 
                float(fields[4]), float(fields[5]), float(fields[6]), fields[7]
            )

            # Check the first filter condition: (max(qtmscore, ttmscore) > 0.5 OR rmsd < 3.0)
            if max(qtmscore, ttmscore) > 0.5 or rmsd < 3.0:
                # Parse the CIGAR string and compute qcov
                cigar_tuples = parse_cigar(cigar)
                qcov = compute_coverage(cigar_tuples, qlen)

                # Check the second filter condition: qcov > qcov_threshold
                if qcov > qcov_threshold:
                    passfile.write(line)
                else:
                    failfile.write(line)
            else:
                failfile.write(line)

if __name__ == "__main__":
    filter_alignments()