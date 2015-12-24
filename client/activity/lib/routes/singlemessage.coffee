{ message: messageActions } = require('activity/flux').actions
ResultStates = require 'activity/constants/resultStates'

module.exports = class SingleMessageRoute

  constructor: ->

    @path = ':postId'


  onEnter: (nextState) ->

    postId = nextState.params.postId.toUpperCase()

    # when the route is '/Channels/:channelName/Liked' SingleMessageRoute triggers
    # first and it takes 'Liked' as a :postId. So check it if :postId is a resultState
    # then it returns null to prevent render problems.
    return null  if ResultStates[postId]
    messageActions.changeSelectedMessage nextState.params.postId

  onLeave: -> messageActions.changeSelectedMessage null
