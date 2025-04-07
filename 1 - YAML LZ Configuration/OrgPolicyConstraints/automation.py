from ListConstraint import ListConstraint
from BooleanConstraint import BooleanConstraint
from AccessDecisionEnum import AccessDecisionEnum

bc = BooleanConstraint("ainotebooks.restrictPublicIp")
lc = ListConstraint("resourcemanager.accessBoundaries", AccessDecisionEnum.ALLOW, False, ["under:organizations/986108084926"]) 

