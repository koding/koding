KodingError = require '../../error'


updateMachine = (options, callback) ->

  JMachine = require './machine'
  { selector, alwaysOn, usage, userPlan } = options

  JMachine.one selector, (err, machine) ->

    if err? or not machine?
      err ?= new KodingError 'Machine object not found.'
      return callback err

    fieldsToUpdate = {}

    if alwaysOn?
      fieldsToUpdate['meta.alwaysOn'] = alwaysOn

    machine.update { $set: fieldsToUpdate }, (err) ->
      callback err


getLimitConfig = (group) ->

  return {
    limit     : group._activeLimit ? 'unlimited'
    overrides : group.getAt 'config.limitOverrides'
  }


module.exports = { updateMachine, getLimitConfig }
