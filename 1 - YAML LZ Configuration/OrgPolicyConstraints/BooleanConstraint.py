from Constraint import Constraint
from ConstraintType import ConstraintType
class BooleanConstraint(Constraint):
    def __init__(self, name):
        super().__init__(name, ConstraintType.Boolean)
    
    def toYamlString():
        print(f"{super().name}:\n" +
                "rules:\n" + 
                "- enforce: true")