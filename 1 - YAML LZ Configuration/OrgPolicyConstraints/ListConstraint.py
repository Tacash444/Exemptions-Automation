from Constraint import Constraint
from AccessDecisionEnum import AccessDecisionEnum

class ListConstraint(Constraint):
    def __init__(self, name, accessDecision, allowAll=False, values=None):
        super().__init__(name)
        self.accessDecision = accessDecision.value
        self.allowAll = allowAll
        
        # Default to empty list if nothing is passed and it's not "all"
        self.values = values if values is not None else []

    def valuesListToString(self):
        prefix = "\n      - "
        return prefix + (prefix.join(map(str, self.values)))
    
    def toString(self):
        basicString = f"{self.name}:\n  rules:\n  - {self.accessDecision}\n"
        if self.allowAll:
            return f"{basicString}      all: true"
        else:
            return f"{basicString}      values:{self.valuesListToString()}"
        