name: Constraint Request
description: Request exemption for Organization Policy Constraints.
title: "[Constraint Request]: "
labels: ["constraint-request"]
assignees: []

body:
  - type: markdown
    attributes:
      value: |
        Please fill out this form carefully.

  - type: input
    attributes:
      label: Constraint Name
      description: The exact name of the constraint
      placeholder: e.g., constraints/compute.disableGuestAttributesAccess
    validations:
      required: true

  - type: textarea
    attributes:
      label: Reason
      description: Describe the reason clearly.
    validations:
      required: true
