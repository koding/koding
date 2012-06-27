class Notifying
  
  notify:(receiver, event, contents)->
    receiver.fetchPrivateChannel
  
  notifyOriginWhen:(events...)->
    @fetchOrigin (err, origin)=>
      if err then console.log 'Origin not found!'
      else events.forEach (event)=> @on event, @notify.bind @, origin, event
  