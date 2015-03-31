whoami = require './whoami'

module.exports = isMyNotification = (notification = {}) ->

  { accountId } = notification.channelMessage

  return accountId is whoami().socialApiId

