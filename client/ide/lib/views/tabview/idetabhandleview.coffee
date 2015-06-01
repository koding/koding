kd              = require 'kd'
KDTabHandleView = kd.TabHandleView


module.exports = class IDETabHandleView extends KDTabHandleView

  constructor: (options = {}, data) ->

    options.bind  = 'dragstart'

    super options, data


  dragStart: (event) ->

    ## FF hack.
    event.originalEvent.dataTransfer.setData 'text/plain', ''

    kd.singletons.appManager.tell 'IDE', 'setTargetTabView', @getDelegate()
