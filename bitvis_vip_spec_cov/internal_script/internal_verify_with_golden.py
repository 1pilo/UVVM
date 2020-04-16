import os
import sys


def get_file_list(path = "."):
    filelist = []
    for filename in os.listdir(path):
        if filename[0:3] == "sc_":
            if filename.endswith(".csv"):
                filelist.append(filename)
        elif filename[0:7] == "output_":
            if filename.endswith(".txt"):
                filelist.append(filename)
    return filelist


def main():
     # Get file lists
    filelist = get_file_list(".")
    golden_file_list = get_file_list("../internal_script/golden/")
    
    failing_verify_file = []
    num_checked_files = 0

    for filename in filelist:
        golden_file = "../internal_script/golden/" + filename

        if os.path.isfile(golden_file):
            num_checked_files += 1
            
            # Read golden file
            with open(golden_file, 'r') as file:
                golden_lines = file.readlines()

            # Read verify file 
            with open(filename, 'r') as file:
                verify_lines = file.readlines()

            # Compare files
            error_found = False
            for idx, line in enumerate(golden_lines):
                if golden_lines[idx] != verify_lines[idx]:
                    failing_verify_file.append(filename)
                    error_found = True

            # Remove OK files
            if not(error_found):
                os.remove(filename)   

        else:
            print("ERROR! Golden do not have file : %s" %(filename))             
            failing_verify_file.append(filename)
        


    # Present statistics
    print("Number of golden files found : %d" %(len(golden_file_list)))
    print("Number of verify files found : %d" %(len(filelist)))
    print("Number of verified files with errors : %d" %(len(failing_verify_file)))

    # Check that all files have been verified
    num_missing_files = abs(len(filelist) - len(golden_file_list))
    if num_missing_files > 0:
        print("WARNING! Number of files do not match - %d != %d" %(len(filelist), len(golden_file_list)))

    # List files with errors
    if failing_verify_file:
        print("Mismatch found in the following file(s) : ")
        for file in failing_verify_file:
            print(file)


    # Return the number of errors to caller
    sys.exit(len(failing_verify_file) + num_missing_files)

if __name__ == "__main__":
    main()

