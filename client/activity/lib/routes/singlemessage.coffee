{ message: messageActions } = require('activity/flux').actions
ResultStates   = require 'activity/util/resultStates'

module.exports = class SingleMessageRoute

  constructor: ->

    @path = ':postId'


  onEnter: (nextState) ->

    postId = nextState.params.postId.toUpperCase()
    return null  if ResultStates[postId]
    messageActions.changeSelectedMessage nextState.params.postId

  onLeave: -> messageActions.changeSelectedMessage null
