kd = require 'kd'
ResourceStateController = require './controllers/resourcestatecontroller'
BaseModalView = require 'app/commonviews/basemodalview'

module.exports = class ResourceStateModal extends BaseModalView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'resource-state-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

    @off 'childAppended'

    { initial } = @getOptions()
    @controller = new ResourceStateController { container: this, initial }, @getData()
    @controller.on 'PaneDidShow', @bound 'setPositions'
    @controller.on 'ClosingRequested', @bound 'destroy'
    @forwardEvent @controller, 'OperationCompleted'
    @forwardEvent @controller, 'MachineTurnOnStarted'
    @controller.loadData()

    @show()


  show: ->

    if @parent
      super
      @overlay.show()
    else
      { container } = @getOptions()
      @overlay      = new kd.OverlayView
        appendToDomBody : no
        isRemovable     : no
        cssClass        : 'env-modal-overlay'

      container.addSubView @overlay
      container.addSubView this

      @overlay.on 'click', if onClose = @getOption 'onClose'
      then onClose
      else @bound 'doBlockingAnimation'

    @emit 'shown'
    @setPositions()


  hide: (skipOverlay) ->

    return super()  unless skipOverlay
    kd.View::hide.call this


  setPositions: ->

    return  if @hasClass 'hidden'

    { container } = @getOptions()
    { top, left } = container.getDomElement().offset()

    offset = @getDomElement().offset()

    style     =
      top     : Math.round((container.getHeight() - @getHeight()) / 2 + top)
      left    : Math.round((container.getWidth()  - @getWidth()) / 2 + left)
      opacity : 1

    if style.top is 0 and style.left is -300
      return

    @setStyle style


  _windowDidResize: ->
    @setPositions()


  updateStatus: (event, task) ->

    @controller.updateStatus event, task


  destroy: ->

    @overlay.destroy()
    @controller.destroy()

    super
