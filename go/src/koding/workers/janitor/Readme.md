# janitor

janitor is a worker responsible for cleaning up unused user resources. It sends emails to users who are inactive for more than specified days, in an attempt to get them to come back; when multiple tries fails, it deletes the user's vm and takes other cost and volume reduction measures.

## Tests

bash `./tests.sh`

## Indexes

The following indexes are required for this worker. The order of fields
in queries and indexes have to match for query to use that index, so
order matters below.

```
db.jUsers.createIndex({"inactive.warning": 1}, {background:true})

db.jUsers.createIndex(
  {"inactive.modifiedAt": 1, "lastLoginDate": 1, "inactive.warning" : 1, "inactive.assigned":1},
  {background:true}
)
```

## Notes
* See `warnings.go` for the implemention of warnings.
* `jUsers#lastLoginDate` is used to track when the user has last visited.
* Paid, blocked & unconfirmed users are exempt from all emails.
* Blocked & unconfirmed users will get their vm deleted.
* Users with no vms are exempt from "vm deletion warning" emails.
