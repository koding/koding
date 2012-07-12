class Notifying
  
  {ObjectRef} = bongo
  {Relationship} = jraphical
  
  @getNotificationEmail =-> 'hi@koding.com'
  
  @getNotificationSubject =-> 'You have pending notifications.'
  
  @getNotificationTextBody =(event, contents)-> 
    """
    event name: #{event};
    contents: #{JSON.stringify(contents)};
    """
  
  setNotifiers:(events, listener)->
    events.forEach (event)=> @on event, listener.bind null, event
  
  notifyAll:(receivers, event, contents)->
    receivers.forEach (receiver)=>
      @notify receiver, event, contents
  
  notify:(receiver, event, contents)->
    actor = contents[contents.actorType]
    {origin} = contents
    if actor? and not receiver.getId().equals actor.id # don't notify the person who triggered the action
      receiver?.fetchPrivateChannel? (channel)=>
        channel.emit 'notification', {event, contents}
    relationship = new Relationship contents.relationship
    CBucket.addActivities relationship, origin, actor, (err)->
    if receiver instanceof JAccount
      JUser.one username: receiver.getAt('profile.nickname'), (err, user)->
        console.log 
        Emailer.send {
          From      : Notifying.getNotificationEmail()
          To        : user.getAt('email')
          Subject   : Notifying.getNotificationSubject event, contents
          TextBody  : Notifying.getNotificationTextBody event, contents
        }, -> 
          console.log 'ARRRRGUMENTS', arguments

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