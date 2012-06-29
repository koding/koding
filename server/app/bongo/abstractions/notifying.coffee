class Notifying
  
  notify:(receiver, event, contents)->
    console.log receiver
    receiver?.fetchPrivateChannel? (err, channel)=>
      unless err
        channel.trigger 'notification', event, contents
  
  notifyOriginWhen:(events...)->
    @fetchOrigin (err, origin)=>
      if err then console.log 'Origin not found!'
      else events.forEach (event)=> @on event, @notify.bind @, origin, event

  notifyFollowersWhen:(events...)->