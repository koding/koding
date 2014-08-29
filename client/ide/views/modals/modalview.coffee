class IDE.ModalView extends KDBlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry 'ide-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

  show: ->
    {container} = @getOptions()
    @overlay    = new KDOverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'ide-modal-overlay'

    container.addSubView @overlay
    container.addSubView this

  destroy: ->
    @overlay.destroy()
    super
