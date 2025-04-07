from Constraint import Constraint

class BooleanConstraint(Constraint):
    def __init__(self, name):
        super().__init__(name)
    
    def toString(self):
        return (f"{self.name}:\n" +
                "  rules:\n" + 
                "   - enforce: true")