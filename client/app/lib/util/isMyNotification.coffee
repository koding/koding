whoami = require './whoami'

module.exports = (notification = {}) ->

  { accountId } = notification.channelMessage

  return accountId is whoami().socialApiId

