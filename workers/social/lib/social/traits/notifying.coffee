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
    JEmailNotificationGG  = require '../models/emailnotification'
    JAccount = require '../models/account'
    CBucket  = require '../models/bucket'
    JUser    = require '../models/user'

    actor = contents[contents.actorType]
    {origin} = contents

    # console.log "HERE I AM", arguments

    createActivity = =>
      if contents.relationship?
        relationship = new Relationship contents.relationship
        CBucket.addActivities relationship, origin, actor, (err)->
          console.err err if err

    sendNotification = =>
      # console.log 'sendNotification'
      if receiver instanceof JAccount
        JEmailNotificationGG.create {actor, receiver, event, contents}, \
        (err)->
          console.error err if err

    if actor? and not receiver.getId().equals actor.id
      receiver?.sendNotification? event, contents
      do createActivity
      do sendNotification

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
