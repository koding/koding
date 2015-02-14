kookies = require 'kookies'

newKodingLaunchDate = do ->
  d = new Date()
  d.setUTCFullYear 2014
  d.setUTCMonth 7
  d.setUTCDate 30
  d.setUTCHours 17
  d.setUTCMinutes 0
  d

module.exports = ({ meta:{ createdAt }}) ->

  if (new Date createdAt) > newKodingLaunchDate
    kookies.set 'koding082014', 'koding082014'
