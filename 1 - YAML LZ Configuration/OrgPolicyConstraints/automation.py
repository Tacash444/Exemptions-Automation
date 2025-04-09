def createYamlFileAtPath(path, filename, exemptionContent):
    yamlFile = f"{path}\\{filename}.yaml"

    with open(yamlFile, 'w') as file:
        file.write(exemptionContent)

def createConstraintAtPath(path, filename, constraint):
    createYamlFileAtPath(path, filename, str(constraint))

