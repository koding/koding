kd = require 'kd'
actions = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

setSelectedMachine = (label) ->
  dispatch actions.UPDATE_SELECTED_MACHINE_SUCCESS, { label }


module.exports = {
  setSelectedMachine
}
