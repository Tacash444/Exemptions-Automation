#General enum to make sure allow decisions can be specified easily.

from enum import Enum

class AccessDecisionEnum(Enum):
    ALLOW = "allow"
    DENY = "deny"
