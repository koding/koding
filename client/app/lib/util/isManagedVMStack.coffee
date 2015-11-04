# This module is intended to provide a single place to edit in case
# Managed VMs stack implementation is changed in the future.

MANAGED_VMS = 'Managed VMs'

module.exports = (stack) -> stack.title is MANAGED_VMS
