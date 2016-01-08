module.exports = {
  getters : require './getters'

  actions :
    channel  : require './actions/channel'

  stores  : [
    require './stores/channelnotificationsettingsstore'
  ]
}
