actionTypes = require '../actiontypes'
toImmutable = require 'app/util/toImmutable'
immutable = require 'immutable'

GROUP_PLANS = [
  {
    name: 'team_free'
    label: 'Koding Free'
    description: 'Free for up to 4 developers'
    price: '0.00'
  }
  {
    name: 'team_base'
    label: '$29.99 Per Developer'
    description: 'For teams of more than 4 developers'
    price: '29.99'
  }
]

module.exports =

  getInitialState: -> toImmutable GROUP_PLANS


