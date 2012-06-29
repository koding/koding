class Notifying
  
  {ObjectRef} = bongo
  
  notify:(receiver, event, contents)->
    contents.subject = ObjectRef(@).data
    receiver?.fetchPrivateChannel? (channel)=>
      channel.emit 'notification', {event, contents}
  
  notifyOriginWhen:(events...)->
    @fetchOrigin (err, origin)=>
      if err then console.log 'Origin not found!'
      else events.forEach (event)=> @on event, @notify.bind @, origin, event

  notifyFollowersWhen:(events...)->