koding = require '../bongo'
KONFIG  = require 'koding-config-manager'
url     = require 'url'

validateEmail = (email) ->
  re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  return re.test email

# www.regextester.com/22
ipv4Regex = ///^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$///
isV4Format = (ip) -> ipv4Regex.test ip


isTeamPage = (req) ->
  hostname = req?.headers?['x-host']
  return no  unless hostname

  hostname = "http://#{hostname}" unless /^http/.test hostname
  { hostname } = url.parse hostname

  # special case for QA team, sometimes they test on ips
  return no  if isV4Format hostname

  labels = hostname.split '.'
  subdomains = labels.slice 0, labels.length - 2

  return no  unless subdomain = subdomains.pop()

  envMatch = no

  for name in ['default', 'dev', 'sandbox', 'latest', 'prod']
    if name is subdomain
      envMatch = yes
      break

  return yes  unless envMatch

  return if subdomain = subdomains.pop()
  then yes
  else no

isInAppRoute = (name) ->
  [firstLetter] = name
  return false  if /^[0-9]/.test firstLetter # user nicknames can start with numbers
  return true   if firstLetter.toUpperCase() is firstLetter
  return false

isMainDomain = (req) ->
  { headers } = req
  return no  unless headers

  mainDomains = [
    KONFIG.domains.base
    KONFIG.domains.main
    "dev.#{KONFIG.domains.base}"
    "prod.#{KONFIG.domains.base}"
    "latest.#{KONFIG.domains.base}"
    "sandbox.#{KONFIG.domains.base}"
  ]

  return headers.host in mainDomains

module.exports = {
  validateEmail
  isV4Format
  isTeamPage
  isInAppRoute
  isMainDomain
}
