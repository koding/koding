class JTreeView extends KDListView

  constructor:(options = {},data)->

    options.animated or= no
    super options, data
    @setClass "jtreeview expanded"

  toggle:(callback)->

    if @expanded then @collapse callback else @expand callback

  expand:(callback)->

    if @getOptions().animated
      @$().slideDown 150, =>
        @setClass "expanded"
        callback?()
    else
      @show()
      @setClass "expanded"
      callback?()

  collapse:(callback)->

    if @getOptions().animated
      @$().slideUp 100, =>
        @unsetClass "expanded"
        callback?()
    else
      @hide()
      @unsetClass "expanded"
      callback?()

  mouseDown:->

    @getSingleton("windowController").setKeyView @
    no

  keyDown:(event)->

    @propagateEvent KDEventType : "KeyDownOnTreeView", event

  destroy:->

    @getSingleton("windowController").revertKeyView @
