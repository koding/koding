kd = require 'kd'
actionTypes = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

FormValuesStore = require './stores/HomeTeamBillingFormValuesStore'

module.exports =
  stores: [ FormValuesStore ]

  actions:
    setValue: (type, value) -> dispatch { type, value }

  getters:
    values: [FormValuesStore.getterPath]

  register: (reactor) -> reactor.registerStores @stores


