kd = require 'kd'

module.exports =

  componentDidMount: ->

    eventEmitter = 'This mixin requires EventEmitter mixin first!'
    throw eventEmitter  unless @on and @off and @emit

    kd.singletons.windowController.registerWindowResizeListener this


  componentWillUnmount: ->

    # this is to tell the windowController to unbind resize listener
    @emit 'KDObjectWillBeDestroyed'
