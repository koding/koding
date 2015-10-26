module.exports = {
  getters : require './getters'

  actions :
    user    : require './actions/user'
    channel : require './actions/channel'

  stores  : [
    require './stores/participantidsstore'
    require './stores/searchquerystore'
    require './stores/visibilitystore'
    require './stores/selectedindexstore'
  ]
}

