module.exports =
  getters   : require './getters'
  actions   :
    message     : require './actions/message'
    thread      : require './actions/thread'
    channel     : require './actions/channel'
    suggestions : require './actions/suggestions'