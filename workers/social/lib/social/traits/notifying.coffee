module.exports = class Notifying

  setNotifiers:(events, listener) ->
    events.forEach (event) => @on event, listener.bind null, event

  notifyAll:(receivers, event, contents) ->
    receivers.forEach (receiver) =>
      @notify receiver, event, contents

  notify:(receiver, event, contents, callback) ->
    callback ?= (err) ->
      console.err err if err

    actor = contents[contents.actorType]
    { origin, recipient } = contents
    recipient or= null

    if actor? and not receiver.getId().equals actor.id
      receiver?.sendNotification? event, contents

  notifyOriginWhen:(events...) ->
    @setNotifiers events, (event, contents) =>
      @notify contents.origin, event, contents

  notifyFollowersWhen:(events...) ->
    @setNotifiers events, (event, contents) =>
      { origin } = contents
      @fetchFollowers (err, followers) =>
        if err then console.log 'Could not fetch followers.'
        else
          receivers = followers.filter (follower) ->
            follower? and not follower.equals? origin
          @notifyAll receivers, event, contents
