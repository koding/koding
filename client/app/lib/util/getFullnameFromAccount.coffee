htmlencode = require 'htmlencode'
whoami = require './whoami'

module.exports = (account = whoami(), justName = no) ->

  name = if account.type is 'unregistered'
    'a guest'
  else if justName or not account.profile.lastName
    account.profile.firstName
  else
    "#{account.profile.firstName} #{account.profile.lastName}"

  return htmlencode.htmlEncode name.trim() or 'a Koding user'
