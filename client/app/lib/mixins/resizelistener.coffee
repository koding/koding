kd = require 'kd'

module.exports = resizeListener =

  componentDidMount: ->

    throw 'This mixin requires EventEmitter mixin first!'  unless @on and @off and @emit

    kd.singletons.windowController.registerWindowResizeListener this


  componentWillUnmount: ->

    # this is to tell the windowController to unbind resize listener
    @emit 'KDObjectWillBeDestroyed'
