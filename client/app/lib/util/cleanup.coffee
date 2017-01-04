_ = require 'lodash'
kookies = require 'kookies'

toBeDeleted = [
  'clientIPAddress' # an old cookie set by koding backend.
  'connect.sid'     # express cookie - infact this is session cookie, here for just in case.
  'pnctest'         # set by PubNub for testing.
  'hubspotutk'      # hubspot
  'hsfirstvisit'    # hubspot
  '__ssid'          # google map

  # 'ajs_anonymous_id' # font?
  # 'ajs_group_id'     # font?
  # 'ajs_user_id'      # font?
  # 'koding-teams'     # set by koding client, should be moved to session storage.

]

hostname = location.host
subDomain = hostname.substring(hostname.indexOf("."), hostname.length)
dotlessSubDomain = subDomain.substring(1, subDomain.length)
subSubDomain = dotlessSubDomain.substring(dotlessSubDomain.indexOf("."), dotlessSubDomain.length)
dotlessSubSubDomain = subSubDomain.substring(1, subSubDomain.length)

perms =
  secures: [ { secure: no }, { secure: yes }, null ]
  paths: [ { path: '/' }, null ]
  domains: [ { domain: hostname }, { domain: subDomain }, { domain: subSubDomain }, { domain: dotlessSubSubDomain }, null ]

options = []

for secure in perms.secures
  for path in perms.paths
    for domain in perms.domains
      options.push _.extend secure, path, domain

module.exports = ->
  for key in toBeDeleted
    for option in options
      if kookies.expire key, option
        console.log "#{key} deleted"
