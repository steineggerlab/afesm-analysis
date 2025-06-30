#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#include <algorithm>
#include <set>
#include <string>
#include <iterator>
#include <cctype>
#include <chrono>

// Function to trim white-space characters from both ends of a string
std::string trim(const std::string& str) {
    std::string s = str;
    // Remove spaces, tabs, and other white-space characters at the beginning
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));

    // Remove spaces, tabs, and other white-space characters at the end
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());

    // Return the trimmed string
    return s;
}

// Function to find the Lowest Common Ancestor (LCA) from a set of paths
std::string find_lca(const std::vector<std::string>& paths) {
    // Vector to store the common ancestor
    std::vector<std::string> common_ancestor;
    // stringstream to help split the first path into its components
    std::stringstream ss(paths[0]);
    std::string item;

    // Split the first path into its components
    while (std::getline(ss, item, ':')) {
        common_ancestor.push_back(item);
    }

    // Loop over the remaining paths to find the common ancestor
    for (size_t i = 1; i < paths.size(); i++) {
        std::vector<std::string> path_parts;
        std::stringstream ss(paths[i]);

        // Skip specific paths before splitting into components
        if (paths[i] == "root:Mixed" || paths[i] == "root" || paths[i] == "root:Mixed:Null" || paths[i] == "root:Null") {
            continue; // Skip this iteration
        }

        // Split each remaining path into its components
        while (std::getline(ss, item, ':')) {
            path_parts.push_back(item);
        }

        // Find the minimum length to avoid index out of range errors
        size_t common_length = std::min(common_ancestor.size(), path_parts.size());

        // Resize the common_ancestor vector to this minimum length
        common_ancestor.resize(common_length);
        for (size_t j = 0; j < common_length; j++) {
            // If any component is different, resize common_ancestor
            if (common_ancestor[j] != path_parts[j]) {
                common_ancestor.resize(j);
                break;
            }
        }
    }

    // Concatenate the components back to form the LCA string
    std::ostringstream result;
    result << paths.size() << "\t";
    result << common_ancestor.size() << "\t";
    for (size_t i = 0; i < common_ancestor.size(); i++) {
        result << common_ancestor[i];
        if (i != common_ancestor.size() - 1) {
            result << ":";
        }
    }
    return result.str();
}

int main(int argc, char* argv[]) {
    // Record the start time
    auto start = std::chrono::high_resolution_clock::now();

    // Check if the correct number of arguments are provided
    if (argc != 5) {
        std::cerr << "Usage: " << argv[0] << " <input file> <rep_idx> <mem_idx> <output file>" << std::endl;
        return 1;
    }

    // Parse command line arguments
    std::string inputFileName = argv[1];
    int rep_idx = std::stoi(argv[2]);
    int mem_idx = std::stoi(argv[3]);
    std::string outputFileName = argv[4];

    // Open input and output files
    std::ifstream inFile(inputFileName);
    std::ofstream outFile(outputFileName);

    // Check if the files are open
    if (!inFile.is_open() || !outFile.is_open()) {
        std::cerr << "Error opening files!" << std::endl;
        return 1;
    }

    std::map<std::string, std::vector<std::string>> dataMap; // A data map to map paths to an id
    std::string line; // Read the input line by line

    // Read the input file line by line
    while (std::getline(inFile, line)) {
        // stringstream to help split the line into columns
        std::stringstream ss(line);

        // Vector to store the columns
        std::vector<std::string> columns;   

        // String to store split columns 
        std::string column;

        // Split the line into columns
        while (std::getline(ss, column, '\t')) {
            columns.push_back(column);
        }  

        // Perform the necessary operations on columns
        std::string trimmed_biome = trim(columns[mem_idx]);
        dataMap[columns[rep_idx]].push_back(trimmed_biome);
        
    }

    // Close the input file
    inFile.close();

    // Iterate through the map, find the LCA, and store it in the output file along with the id
    for (const auto& entry : dataMap) {
        if (entry.second.size() > 1) {     // Find the LCA if there are multiple paths
            std::string lca = find_lca(entry.second);
            outFile << entry.first << "\t" << lca << std::endl;
        } else { // Otherwise
            int count = std::count(entry.second[0].begin(), entry.second[0].end(), ':');
            std::stringstream temp;
            temp << "1" << "\t" << count + 1 << "\t" << entry.second[0];

            std::string lca = temp.str();
            outFile << entry.first << "\t" << lca << std::endl;
        }        
    }

    // Close the output file
    outFile.close();

    // End message
    std::cout << "LCA produced: " << outputFileName << std::endl;

    // Record the end time
    auto stop = std::chrono::high_resolution_clock::now();
    
    // Calculate and display the elapsed time
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
    std::cout << "Time taken by function: " << duration.count() << " microseconds" << std::endl;

    return 0;
}
