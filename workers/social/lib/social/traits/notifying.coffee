jraphical = require 'jraphical'

module.exports = class Notifying

  {ObjectRef} = require 'bongo'
  {Relationship} = jraphical

  setNotifiers:(events, listener)->
    events.forEach (event)=> @on event, listener.bind null, event

  notifyAll:(receivers, event, contents)->
    receivers.forEach (receiver)=>
      @notify receiver, event, contents

  notify:(receiver, event, contents)->
    JAccount = require '../models/account'
    CBucket  = require '../models/bucket'
    JEmail   = require '../models/email'
    JUser    = require '../models/user'

    actor = contents[contents.actorType]
    {origin} = contents

    if actor? and not receiver.getId().equals actor.id
      receiver?.sendNotification? event, contents

      relationship = new Relationship contents.relationship
      CBucket.addActivities relationship, origin, actor, (err)->
        if receiver instanceof JAccount
          JEmail.createNotificationEmail {actor, receiver, event, contents}, \
          (err)->
            console.error err if err

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
