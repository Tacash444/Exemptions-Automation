from typing import List, Optional

def generate_policy_file(
    identities: List[str],
    role_name: str,
    perimeters: List[str],
    resources: Optional[List[str]] = None,
    service: Optional[str] = None,
    method: Optional[str] = None,
    identity_type: Optional[str] = None,
    output_file: str = "policy.txt"
):
    if not identities:
        raise ValueError("The 'identities' parameter must not be empty.")
    if not perimeters:
        raise ValueError("The 'perimeters' parameter must not be empty.")

    # Template with optional identity_type and service/method blocks
    template = """from: 
{identity_type_block}    identities:
    - {identities}
{sources_block}  to: 
    operations:
{operations_block}    roles:
{roles_block}perimeters:
 - {perimeters}"""

    # Build optional identity_type, resource, and operations blocks
    identity_type_block = ""
    sources_block = ""
    operations_block = ""
    roles_block = ""

    if identity_type:
        identity_type_block = f"    identityType: {identity_type}\n"

    if resources:
        resource_lines = "\n    - ".join(resources)
        sources_block = f"  sources:\n    - resource: {resource_lines}\n"
        roles_block = f"    - {role_name}\n    resources:\n    - {resource_lines}\n"
    else:
        roles_block = f"    - {role_name}\n"

    if service and method:
        operations_block = f"    - serviceName: {service}\n      methodSelectors:\n      - method: {method}\n"

    result = (
        template
        .replace("{identity_type_block}", identity_type_block)
        .replace("{identities}", "\n    - ".join(identities))
        .replace("{sources_block}", sources_block)
        .replace("{operations_block}", operations_block)
        .replace("{roles_block}", roles_block)
        .replace("{perimeters}", "\n - ".join(perimeters))
    )

    with open(output_file, "w") as f:
        f.write(result)

    print(f"Policy written to {output_file}")

generate_policy_file(["service@gmail.com"], "admin", ["dmz"])