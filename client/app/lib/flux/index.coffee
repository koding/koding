module.exports =
  actions:
    user: require './actions/user'
  stores: [
    require './stores/usersstore'
  ]
