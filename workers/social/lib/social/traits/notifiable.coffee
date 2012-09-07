module.exports = class Notifiable
  
  hat = require 'hat'
  
  getPrivateChannelName:-> "private-notifiable-#{@constructor.name}-#{hat()}"
  
  fetchPrivateChannel:(callback)->
    require('bongo').fetchChannel @getPrivateChannelName(), callback
  
  sendNotification:(event, contents)->
    @fetchPrivateChannel? (channel)=>
      channel.emit 'notification', {event, contents}