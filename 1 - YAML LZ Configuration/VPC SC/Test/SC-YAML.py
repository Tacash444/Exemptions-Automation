from typing import List, Optional
from string import Template


# Helper to convert Python list to YAML list string
def format_list_for_yaml(lst: List[str]) -> str:
    return "[" + ", ".join(f'"{item}"' for item in lst) + "]"


def generate_vpc_sc_ingress_yaml(
    perimeters: List[str],
    identities: Optional[List[str]] = None,
    role_names: Optional[List[str]] = None,
    resources: Optional[List[str]] = None,
    services: Optional[List[str]] = None,
    methods: Optional[List[str]] = None,
    permissions: Optional[List[str]] = [],
    identity_type: Optional[str] = None,
    output_file: str = "policy.yaml"
):
    # Normalize values: convert None or empty lists to ["*"]
    identities = identities if identities else ["*"]
    role_names = role_names if role_names else ["*"]
    resources = resources if resources else ["*"]
    identity_type = identity_type if identity_type else "ANY_IDENTITY"
    perimeters = perimeters if perimeters else ["*"]


    #Normalize block that represents operations



    operations_block = ""
    if services:
        operations_block = """\n  operations:"""
        for service in services:
            methods_list = list(filter(lambda item: service.split(".")[0] == 
                item.split(".")[0], methods))
            permissions_list = list(filter(lambda item: service.split(".")[0] == 
                item.split(".")[0], permissions))

            operations_block = operations_block + """\n  - serviceName: """ + '"' + service + '"\n    methodSelectors:'
            operations_block = operations_block + """\n      methods: """
            operations_block = operations_block + (format_list_for_yaml(methods_list) if methods_list else '["*"]')
            operations_block = operations_block + """\n      permissions: """
            operations_block = operations_block + (format_list_for_yaml(permissions_list) if permissions_list else '["*"]')
            
            

            


    # YAML template with placeholders
    yaml_template = Template(
        """from:
  identityType: $identity_type
  identities: $identities
  sources:
    - accessLevel: "*"
    - resource: "*"
to:$operations_block
  roles: $roles
  resources: $resources
perimeters: $perimeters
"""
    )

    # Prepare substitutions
    substitutions = {
        "identity_type": identity_type,
        "identities": format_list_for_yaml(identities),
        "resources": format_list_for_yaml(resources),
        "roles": format_list_for_yaml(role_names),
        "perimeters": format_list_for_yaml(perimeters),
        "service": services,
        "operations_block" : operations_block
    }

    # Generate YAML content
    yaml_result = yaml_template.substitute(substitutions)

    # Write YAML to output file
    with open(output_file, "w") as f:
        f.write(yaml_result)

    print(f"Ingress YAML policy written to {output_file}")


# Example usage
generate_vpc_sc_ingress_yaml(
    services=["storage.googleapis.com", "bigquery.googleapis.com", "sheets.googleapis.com"],
    methods=["storage.objects.get", "storage.buckets.get", "bigquery.buckets.get"],
    perimeters=["restricted-perimeter"],
    output_file="vpc_sc_ingress.yaml"
)