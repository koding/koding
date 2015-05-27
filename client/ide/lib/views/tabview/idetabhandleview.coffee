kd              = require 'kd'
KDTabHandleView = kd.TabHandleView


module.exports = class IDETabHandleView extends KDTabHandleView

  bindEvents: ->

    super

    options = @getOptions()

    if options.droppable

      @getDomElement().bind 'dragstart', (event) => @handleDragStart event


  handleDragStart: (event) ->

    { dataTransfer } = event.originalEvent

    ## FF hack.
    dataTransfer.setData 'text/plain', ''

    { appManager } = kd.singletons
    appManager.tell 'IDE', 'saveDriftingTabView', @getDelegate()
