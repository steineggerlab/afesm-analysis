import csv

def parse_clusters(file_path):
    clusters = {}
    
    with open(file_path, 'r') as file:
        reader = csv.reader(file, delimiter='\t')
        
        for row in reader:
            cluster_rep = row[0]
            cluster_member = row[1]
            
            # Initialize the cluster representative if not already in dictionary
            if cluster_rep not in clusters:
                clusters[cluster_rep] = []
                
            # Append cluster member to the representative's list
            clusters[cluster_rep].append(cluster_member)
    
    return clusters

def filter_clusters(clusters):
    filtered_clusters = {}
    
    for rep, members in clusters.items():
        # Check if all members start with "MGYP"
        if all(member.startswith("MGYP") for member in members):
            filtered_clusters[rep] = members
            
    return filtered_clusters

def main():
    input_file = 'final_clust_cluster.tsv'
    
    # Parse the clustering results file
    clusters = parse_clusters(input_file)
    
    # Filter clusters where all members start with "MGYP"
    filtered_clusters = filter_clusters(clusters)
    
    # Print the filtered clusters
    for rep, members in filtered_clusters.items():
        for member in members:
            print(f"{rep}\t{member}")

if __name__ == "__main__":
    main()