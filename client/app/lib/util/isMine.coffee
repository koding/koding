whoami = require './whoami'

module.exports = (target) ->
  if target?.bongo_?.constructorName is 'JAccount'
    whoami().profile.nickname is target.profile.nickname
  else if target?.originId?
    whoami()._id is target.originId
