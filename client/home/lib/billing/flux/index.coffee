module.exports =
  stores: [
    require './cardformvalues/stores/HomeTeamBillingFormValuesStore'
  ]
  register: (reactor) -> reactor.register @stores

