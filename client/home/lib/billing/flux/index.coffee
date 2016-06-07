module.exports =
  stores: [
    require './cardformvalues/stores/HomeTeamBillingFormValuesStore'
    require './cardformvalues/stores/HomeTeamBillingFormErrorsStore'
  ]
  register: (reactor) -> reactor.registerStores @stores

