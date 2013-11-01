jraphical = require 'jraphical'

module.exports = class Notifying

  {ObjectRef} = require 'bongo'
  {Relationship} = jraphical

  setNotifiers:(events, listener)->
    events.forEach (event)=> @on event, listener.bind null, event

  notifyAll:(receivers, event, contents)->
    receivers.forEach (receiver)=>
      @notify receiver, event, contents

  notify:(receiver, event, contents, callback)->
    callback ?= (err) ->
      console.err err if err

    JMailNotification  = require '../models/emailnotification'
    JAccount = require '../models/account'
    CBucket  = require '../models/bucket'
    JUser    = require '../models/user'

    actor = contents[contents.actorType]
    {origin, recipient} = contents
    recipient or= null

    createActivity = =>
      if contents.relationship?
        relationship = new Relationship contents.relationship
        CBucket.addActivities relationship, origin, actor, recipient, callback

    sendNotification = =>
      if receiver instanceof JAccount and receiver.type isnt 'unregistered'
        JMailNotification.create {actor, receiver, event, contents}, (err)->
          console.error err if err

      if receiver instanceof JAccount and receiver.type isnt 'unregistered'
        JMailNotification.create {actor, receiver, event, contents}, (err)->
          console.error err if err

    if actor? and not receiver.getId().equals actor.id
      receiver?.sendNotification? event, contents

      # do not create activity for koding group
      # do not send mail notification for koding group
      # return if koding
      subject = contents.subject
      return  if subject and subject.constructorName is 'JGroup' and subject.slug is "koding"

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

  notifyGroupWhen:(events...)->
    JGroup = require '../models/group'
    @setNotifiers events, (event, contents)->
      {group} = contents
      JGroup.broadcast group, event, contents
