class Notifying
  
  {ObjectRef} = bongo
  {Relationship} = jraphical
  
  setNotifiers:(events, listener)->
    events.forEach (event)=> @on event, listener.bind null, event
  
  notifyAll:(receivers, event, contents)->
    receivers.forEach (receiver)=>
      @notify receiver, event, contents
  
  notify:(receiver, event, contents)->
    actor = contents[contents.actorType]
    {origin} = contents
    if actor? and not receiver.getId().equals actor.id
      receiver?.fetchPrivateChannel? (channel)=>
        channel.emit 'notification', {event, contents}
    relationship = new Relationship contents.relationship
    CBucket.addActivities relationship, origin, actor, (err)->
      debugger
      console.log 'There was an error adding bucket activities', err if err
      
  notifyOriginWhen:(events...)->
    @setNotifiers events, (event, contents)=>
      @notify contents.origin, event, contents

  notifyFollowersWhen:(events...)->
    @setNotifiers events, (event, contents)=>
      {origin} = contents
      @fetchFollowers (err, followers)=>
        if err then console.log 'Could not fetch followers.'
        else
          receivers = followers.filter (follower)->
            follower? and not follower.equals? origin
          @notifyAll receivers, event, contents