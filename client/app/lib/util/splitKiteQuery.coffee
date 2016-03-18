# // KontrolQuery is a structure of message sent to Kontrol. It is used for
# // querying kites based on the incoming field parameters. Missing fields are
# // not counted during the query (for example if the "version" field is empty,
# // any kite with different version is going to be matched).
# // Order of the fields is from general to specific.
# type KontrolQuery struct {
#     Username    string `json:"username"`
#     Environment string `json:"environment"`
#     Name        string `json:"name"`
#     Version     string `json:"version"`
#     Region      string `json:"region"`
#     Hostname    string `json:"hostname"`
#     ID          string `json:"id"`
# }
#
# Structure taken from github.com/koding/kite/protocol/protocol.go

module.exports = (query = '') ->

  keys = [ 'username', 'environment', 'name',
           'version', 'region', 'hostname', 'id' ]

  query = query.replace /^\//, ''
  if (splitted = query.split '/').length is 7
    res = {}
    for s, i in splitted then res[keys[i]] = s
    return res
