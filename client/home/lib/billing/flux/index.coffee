module.exports =
  stores: [
    require './cardformvalues/stores/HomeTeamBillingFormValuesStore'
  ]
  register: (reactor) -> reactor.registerStores @stores

