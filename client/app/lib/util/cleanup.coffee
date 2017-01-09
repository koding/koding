_ = require 'lodash'
kookies = require 'kookies'

toBeDeleted = [
  'clientIPAddress' # an old cookie set by koding backend.
  'kdproxy-preferred-domain' # old koding cookie
  'connect.sid'     # express cookie - infact this is session cookie, here for just in case.
  # 'pnctest'       # set by PubNub for testing. it is set on every load, so not necessary to remove.
  '__ssid'          # google map
  'gsScrollPos'     # session cookie, wont be cleaned, not necessary

  # 'koding-teams'     # set by koding client, should be moved to session storage.

  # hubspot
  '__hstc'
  '__hssrc'
  '__hssc'
  'hsPagesViewedThisSession'
  'hubspotutk'
  'hubspot.hub.id'
  'hsfirstvisit'
  'hubspotauth'
  'hubspotauthcms'
  'hubspotauthremember'
  'hubspotutktzo'
  '_hs_opt_out'
  '__hluid'

  # kissmetrics
  'km_ai'
  'km_lv'
  'km_ni'
  'km_uq'
  'km_vs'
  'kvcd'

  # font?
  'ajs_anonymous_id'
  'ajs_group_id'
  'ajs_user_id'

  # olark
  'hblid'
  'wcsid'
  'olfsk'
  '_okbk'
  '_ok'
  '_oklv'
  '_okla'
  '_okgid'
  '_okac'
  '_okck'

  'olsfk'  # unknown origin
  'hbild'  # unknown origin
]

startsWith = [
  '_hp2_id'         # heap analytics - we dont use anymore.
  '_hp2_ses_props'  # heap analytics - we dont use anymore.
  '_ob_pub'  # unknow origin
]

hostname = location.host
subDomain = hostname.substring(hostname.indexOf('.'), hostname.length)
dotlessSubDomain = subDomain.substring(1, subDomain.length)
subSubDomain = dotlessSubDomain.substring(dotlessSubDomain.indexOf('.'), dotlessSubDomain.length)
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
