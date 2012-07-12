
class Notifying
  
  {ObjectRef} = bongo
  
  setNotifiers =(events, receiver)->
    events.forEach (event)=> @on event, @notify.bind @, receiver, event
  
  notify:(receiver, event, contents)->
    receiver?.fetchPrivateChannel? (channel)=>
      channel.emit 'notification', {event, contents}
  
  notifyOriginWhen:(events...)->
    @fetchOrigin (err, origin)=>
      if err then console.log 'Origin not found!'
      else  setNotifiers.call @, events, origin

  notifyFollowersWhen:(events...)->
    @fetchFollowers (err, followers)=>
      if err then console.log 'An unknown condition has occurred.'
      else
        for follower in followers when follower?
          setNotifiers.call @, events, follower