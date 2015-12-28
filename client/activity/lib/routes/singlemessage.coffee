{ message: messageActions } = require('activity/flux').actions

module.exports = class SingleMessageRoute

  constructor: ->

    @path = ':postId'


  onEnter: (nextState) ->

    messageActions.changeSelectedMessage nextState.params.postId


  onLeave: -> messageActions.changeSelectedMessage null

