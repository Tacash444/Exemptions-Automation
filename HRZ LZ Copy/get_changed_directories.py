import sys
import os
from itertools import product

allowed = ["0", "1", "2", "3", "4", "hrz-configs"]
config = "hrz-configs"

def starts_with_allowed(string, allowed_list):
    for allowed_str in allowed_list:
        if string.startswith(allowed_str):
            return True
    return False


def get_parent_child_subunit_combinations(path, exclude_name="research"):
    subunit_combinations = []
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if d != exclude_name]
        parent = os.path.basename(root)  # Get the parent directory name
        if parent != os.path.basename(path):  # Exclude the root directory
            for child in dirs:
                subunit_combinations.append(f"{parent}-{child}")
    return subunit_combinations


def get_all_pf_config(state):
    path = f"{config}/data/projects"
    trimmed_state = state.split("-")[-1] 

    if trimmed_state == "research":
        research_workloads = []
        for root, dirs, files in os.walk(path):
            if os.path.basename(root) == "research":  
                research_workloads.extend(dirs)
        states = research_workloads 
    else:
        subunits = []
        for root, dirs, files in os.walk(path):
            # Exclude the 'research' directory
            dirs[:] = [f"{d}-{trimmed_state[:3]}" for d in dirs]
            subunits.extend(dirs)
        states = subunits
    
    
    return states
    


def main(string):
    lst = []

    for directory in string.split(","):
        lst.append(directory.split("/")[0])

    for directory in lst:
        if (directory != lst[0]) or not starts_with_allowed(directory, allowed):
            return "$-1"

    if string.split(",")[0].startswith(f"{config}/data/projects"):
        env = string.split(',')[0].split('/')[4]

        if env == "research":
            return f"{string.split(',')[0].split('/')[5]}$3-project-factory-{env}"

        return f"{string.split(',')[0].split('/')[3]}-{env[:3]}$3-project-factory-{env}"

    if string.split(",")[0].startswith(f"{config}/data/2-networking"):
        file = string.split(',')[0]

        if "research" in file:
            return f"$2-networking-research"

        return f"$2-networking-integration"
            
    if string.split(",")[0].startswith(f"{config}/data"):
        return f"${string.split(',')[0].split('/')[2]}"

    if lst[0].startswith("3-project-factory"):
        return f"{','.join(get_all_pf_config(lst[0]))}${lst[0]}"
    return f"${lst[0]}"
    

if __name__ == '__main__':
    string = sys.argv[1]

    print(main(string))
