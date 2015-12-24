{ message: messageActions } = require('activity/flux').actions
ResultStates = require 'activity/constants/resultStates'

module.exports = class SingleMessageRoute

  constructor: ->

    @path = ':postId'


  onEnter: (nextState) ->

    messageActions.changeSelectedMessage nextState.params.postId


  onLeave: -> messageActions.changeSelectedMessage null

