whoami = require './whoami'

module.exports = isMyNotification = (notification) ->

  return no  unless notification

  { accountId } = notification.channelMessage

  return accountId is whoami().socialApiId
