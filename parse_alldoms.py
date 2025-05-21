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

def compute_coverage(cigar_tuples, qlen, tlen):
    """
    Compute the query coverage and target coverage from a parsed CIGAR string.

    Args:
    cigar_tuples (List[Tuple[str, int]]): The parsed CIGAR string as a list of (operation, length) tuples.
    qlen (int): The length of the query sequence.
    tlen (int): The length of the target sequence.

    Returns:
    Tuple[float, float]: The query coverage and target coverage.
    """
    aligned_query_bases = sum(length for op, length in cigar_tuples if op in ('M', '=', 'X'))
    aligned_target_bases = sum(length for op, length in cigar_tuples if op in ('M', '=', 'X', 'D'))

    qcov = aligned_query_bases / qlen
    tcov = aligned_target_bases / tlen
    return qcov, tcov

@click.command()
@click.option('--input_file', type=click.Path(exists=True), default='alldoms_results.m8', help="Input file containing alignment lines.")
@click.option('--output_pass', type=click.Path(), default='alldoms_match.m8', help="Output file for lines that pass the filtering criteria.")
@click.option('--output_fail', type=click.Path(), default='alldoms_nomatch.m8', help="Output file for lines that do not pass the filtering criteria.")
@click.option('--qtmscore_threshold', type=float, default=0.56, help="Threshold for qtmscore (default: 0.56).")
@click.option('--qcov_threshold', type=float, default=0.6, help="Threshold for qcov (default: 0.6).")
@click.option('--tcov_threshold', type=float, default=0.6, help="Threshold for tcov (default: 0.6).")
def filter_alignments(input_file, output_pass, output_fail, qtmscore_threshold, qcov_threshold, tcov_threshold):
    """
    Filter alignments based on qtmscore, qcov, and tcov, and write the results to separate files.

    Args:
    input_file (str): The input file containing alignment lines.
    output_pass (str): The output file for lines that pass the filtering criteria.
    output_fail (str): The output file for lines that do not pass the filtering criteria.
    qtmscore_threshold (float): The qtmscore threshold for filtering.
    qcov_threshold (float): The qcov threshold for filtering.
    tcov_threshold (float): The tcov threshold for filtering.
    """
    with open(input_file, 'r') as infile, open(output_pass, 'w') as passfile, open(output_fail, 'w') as failfile:
        for line in infile:
            fields = line.strip().split()
            if len(fields) < 6:
                failfile.write(line)
                continue

            query, target, qlen, tlen, qtmscore, cigar = fields[0], fields[1], int(fields[2]), int(fields[3]), float(fields[4]), fields[5]

            if qtmscore > qtmscore_threshold:
                cigar_tuples = parse_cigar(cigar)
                qcov, tcov = compute_coverage(cigar_tuples, qlen, tlen)

                if qcov > qcov_threshold and tcov > tcov_threshold:
                    passfile.write(line)
                else:
                    failfile.write(line)
            else:
                failfile.write(line)

if __name__ == "__main__":
    filter_alignments()