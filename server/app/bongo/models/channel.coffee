class JChannel extends bongo.Model
  
  channels = {}
  
  createId = require 'hat'
  
  @share()
  
  @set
    sharedMethods:
      static: ['fetch','reset','publish']
    indexes:
      publicChannelId: 'unique'
    schema:
      publicChannelId : String
      secretChannelId : String
      subscribers     :
        type          : [String]
        default       : -> []
  
  @fetchPrivateSecretChannelId =(publicChannelId, callback)->
    @one {publicChannelId}, (err, channel)=>
      if err
        callback err
      else if channel?
        callback null, channel.secretChannelId
      else
        secretChannelId = createId()
        channel = new @ {
          publicChannelId
          secretChannelId
        }
        channel.save (err)->
          if err
            callback err
          else
            callback null, secretChannelId
  
  @parseChannel=(channelName, callback)->
    channelName.replace /(?:(.*)(?:_private$))|(.*)/,
      (name, channelId, generalChannel)-> callback channelId, generalChannel

  @fetch = bongo.secure (client, publicChannelId, callback)->
    @parseChannel publicChannelId, (channelId, generalChannel)=>
      if channelId
        # if client.is channelId
        @fetchPrivateSecretChannelId publicChannelId, (err, secretChannelId)->
          if err
            callback err
          else
            callback null, secretChannelId
        # else
        #   callback new KodingError 'Access denied!'
      else if generalChannel
        callback null, 'general channel', generalChannel
  
  @publish =(publicChannelId, event, rest...)->
    @fetchPrivateSecretChannelId publicChannelId, (err, secretChannelId)->
      bongo.mq?.trigger secretChannelId, event, rest
  
  @reset =(publicChannelId, callback)->
    @one {publicChannelId}, (err, channel)=>
      if err
        callback err
      else if channel?
        {secretChannelId} = channel
        @remove {publicChannelId}, (err)->
          if err
            callback err
          else
            bongo.mq?.trigger secretChannelId, 'change.channel', null
            callback null
      else callback null
      