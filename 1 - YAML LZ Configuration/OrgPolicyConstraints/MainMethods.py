import os
#The methods that create the files. 

def createYamlFileAtPath(path, filename, exemptionContent):
    yamlFile = os.path.join(path, f"{filename}.yaml")
    
    with open(yamlFile, 'w') as file:
        file.write(exemptionContent)

def createConstraintAtPath(path, filename, constraint):
    createYamlFileAtPath(path, filename, str(constraint))

