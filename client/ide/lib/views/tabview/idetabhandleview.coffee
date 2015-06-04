kd              = require 'kd'
KDTabHandleView = kd.TabHandleView


module.exports = class IDETabHandleView extends KDTabHandleView

  constructor: (options = {}, data) ->

    options.droppable ?= yes
    options.bind       = 'dragstart'

    super options, data


  dragStart: (event) ->

    ## workaround for FF and ChromeApp
    event.originalEvent.dataTransfer.setData 'text/plain', ' '

    kd.singletons.appManager.tell 'IDE', 'setTargetTabView', @getDelegate()
