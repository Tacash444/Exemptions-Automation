#General constraint class. Class should not be instantiated.

class Constraint:
    def __init__(self, name):
        self.name = name

    def toString(self):
        return self.name
