kd = require 'kd'
actionTypes = require './actiontypes'

markAsDone = (step) ->
  kd.singletons.reactor.dispatch actionTypes.MARK_WELCOME_STEP_AS_DONE, { step }

module.exports = {
  markAsDone
}