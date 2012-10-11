module.exports = class Notifiable
  
  hat = require 'hat'
  
  getPrivateChannelName:-> "private-notifiable-#{@constructor.name}-#{hat()}"
  
  sendNotification:(event, contents)->
    @emit 'notificationArrived', {event, contents} 
