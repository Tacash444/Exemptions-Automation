import os
import yaml
import ipaddress

MAX_PREFIX = 16
BASE_ADDRESS = "10.0.0.0/8"
DIRECTORY = './hrz-configs/data/2-networking/factories'
DENIED_ADDRESSES = ["10.0.0.0/16", "10.1.0.0/16",
                    "10.2.0.0/16", "10.3.0.0/16", "10.4.0.0/16"]


def find_ip_cidr_ranges():
    ip_cidr_ranges = DENIED_ADDRESSES

    for root, dirs, files in os.walk(DIRECTORY):
        if "subnets" in dirs:
            subnets_dir = os.path.join(root, "subnets")
            for file_name in os.listdir(subnets_dir):
                if file_name.endswith(".yaml") or file_name.endswith(".yml"):
                    file_path = os.path.join(subnets_dir, file_name)
                    with open(file_path, 'r') as file:
                        try:
                            yaml_data = yaml.safe_load(file)
                            if isinstance(yaml_data, dict):
                                if "ip_cidr_range" in yaml_data:
                                    ip_cidr_ranges.append(
                                        yaml_data["ip_cidr_range"])
                                if "secondary_ip_ranges" in yaml_data:
                                    for range_name, cidr in yaml_data["secondary_ip_ranges"].items():
                                        ip_cidr_ranges.append(cidr)
                        except yaml.YAMLError as e:
                            print(f"Error parsing {file_path}: {e}")

    return ip_cidr_ranges


def generate_available_cidrs(prefix, count):
    existing_addresses = find_ip_cidr_ranges()
    base_ip = ipaddress.ip_network(BASE_ADDRESS)
    available_subnets = []

    for subnet in base_ip.subnets(new_prefix=prefix):
        if all(not subnet.overlaps(ipaddress.ip_network(addr)) for addr in existing_addresses):
            available_subnets.append(str(subnet))
            if len(available_subnets) == count:
                break

    return available_subnets


def create_yaml_gke(ip_cidrs):
    return {"secondary_ip_ranges": {
            "pods": ip_cidrs[1],
            "services": ip_cidrs[2]
            }}


def create_yaml_in_subunit(request, ip_cidr):
    unit = request["projectId"].split("-")[1]
    sub_unit = request["projectId"].split("-")[2]
    env = request["projectId"].split("-")[3]
    project = request["projectId"].split("-")[4]

    subnets_dir = os.path.join(
        DIRECTORY, unit, sub_unit, request["environment"], "subnets")
    os.makedirs(subnets_dir, exist_ok=True)

    file_path = os.path.join(
        subnets_dir, f"{project}-{request['num']}-subnet.yaml")

    yaml_content = {
        "region": "me-west1",
        "ip_cidr_range": ip_cidr[0],
        "iam_bindings_additive": {
            f"owner_{project}_{request['num']}_group_binding": {
                "role": "roles/compute.networkAdmin",
                "member": f"group:{request['projectId']}-admins@horizon285.com"
            }
        }
    }

    if request["proxy_subnet"]:
        yaml_content.update({"proxy_only": True})
    elif request["psc_subnet"]:
        yaml_content.update({"psc": True})
    elif request["gke_subnet"]:
        yaml_content.update(create_yaml_gke(ip_cidr))

    return file_path, yaml_content


def create_yaml_in_shared(request, ip_cidr):
    subnets_dir = os.path.join(
        DIRECTORY, request["vpc_dir"], "subnets")
    os.makedirs(subnets_dir, exist_ok=True)

    file_path = os.path.join(
        subnets_dir, f"{request['name']}-{request['num']}-subnet.yaml")

    if request.get('permission_group'):
        yaml_content = {
            "region": "me-west1",
            "ip_cidr_range": ip_cidr[0],
            "iam_bindings_additive": {
                f"owner_{request['name']}_{request['num']}_group_binding": {
                    "role": "roles/compute.networkAdmin",
                    "member": f"group:{request['permission_group']}@horizon285.com"
                }
            }
        }
    else:
        yaml_content = {
            "region": "me-west1",
            "ip_cidr_range": ip_cidr[0],
        }

    if request["proxy_subnet"]:
        yaml_content.update({"proxy_only": True})
    elif request["psc_subnet"]:
        yaml_content.update({"psc": True})
    elif request["gke_subnet"]:
        yaml_content.update(create_yaml_gke(ip_cidr))

    return file_path, yaml_content


def create_yaml_file(request, ip_cidr):
    if request["environment"] == "shared":
        file_path, yaml_content = create_yaml_in_shared(request, ip_cidr)
    else:
        file_path, yaml_content = create_yaml_in_subunit(request, ip_cidr)

    try:
        with open(file_path, 'w') as file:
            yaml.safe_dump(yaml_content, file)
        with open(file_path, 'r') as file:
            print(yaml.safe_load(file))
        return file_path
    except:
        return ""


def main(request):
    if request["gke_subnet"]:
        base_ip = generate_available_cidrs(request["prefix"], 1)
        DENIED_ADDRESSES.append(base_ip[0])
        secondary = generate_available_cidrs(20, 2)
        ips = base_ip + secondary
    else:
        ips = generate_available_cidrs(request["prefix"], 1)

    if ips != []:
        print("Available CIDR:", ips)
    else:
        return "No available CIDR found for the given prefix length and taken addresses."

    try:
        create_yaml_file(request, ips)
        return "successfully added new subnet yaml"
    except Exception as e:
        raise e


request_subunit = {
    "prefix": 24,
    "environment": "research",
    "projectId": "hrz-starfish-mam-res-tstwork-3",
    "num": 4,
    "gke_subnet": False,
    "psc_subnet": False,
    "proxy_subnet": False

}

request_shared = {
    "prefix": 24,
    "environment": "shared",
    "name": "tst-sub",
    "vpc_dir": "global-shared/network/research",
    "num": 1,
    "permission_group": None,
    "gke_subnet": False,
    "psc_subnet": False,
    "proxy_subnet": True
}


if __name__ == "__main__":
    print(main(request_shared))
