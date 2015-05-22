kd                = require 'kd'
KDTabHandleView   = kd.TabHandleView


module.exports = class IDETabHandleView extends KDTabHandleView

  bindEvents: ->

    super

    options = @getOptions()

    if options.droppable

      $elm = @getDomElement()

      $elm.bind 'dragstart', (event) => @handleDragStart event
      $elm.bind 'dragenter', (event) =>
        kd.log 'dragenter now'


  handleDragStart: (event) ->

    { dataTransfer } = event.originalEvent

    ## FF hack.
    dataTransfer.setData '', ''

    { appManager } = kd.singletons
    appManager.tell 'IDE', 'saveDriftingTabView', @getDelegate()
