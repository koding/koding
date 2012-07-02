class Notifiable
  
  hat = require 'hat'
  
  getPrivateChannelName:-> "private-notifiable-#{@constructor.name}-#{hat()}"
  
  fetchPrivateChannel:(callback)->
    bongo.fetchChannel @getPrivateChannelName(), callback