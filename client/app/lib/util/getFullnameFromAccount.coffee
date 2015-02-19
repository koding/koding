htmlencode = require 'htmlencode'
whoami = require './whoami'

module.exports = (account, justName=no) ->
  account or= whoami()
  if account.type is 'unregistered'
    name = "a guest"
  else if justName
    name = account.profile.firstName
  else
    name = "#{account.profile.firstName} #{account.profile.lastName}"
  return htmlencode.htmlEncode name.trim() or 'a Koding user'
