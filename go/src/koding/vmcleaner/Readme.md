# vmcleaner

vmcleaner sends emails to users who are inactive for more than specified days, in an attempt to get them to come back; when multiple tries fails, it deletes the user's vm and takes other cost and volume reduction measures.

## Notes
* See `warnings.go` for the implemention of warnings.
* `jUsers#lastLoginDate` is used to track when the user has last visited.
* Paid, blocked users are exempt from all emails.
* Users with no vms are exempt from "vm deletion warning" emails.
