remote  = require('app/remote').getInstance()
globals = require 'globals'


module.exports = (machine, rules) ->

  jMachine = remote.revive machine.toJS()

  for user in jMachine.users when user.id is globals.userId
    for rule in rules
      return no  unless user[rule]
    return yes

  return no
