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

    @emit "KeyDownOnTreeView", event

  destroy:->

    @getSingleton("windowController").revertKeyView @

  appendItemAtIndex:(itemInstance,index,animation)->

    itemInstance.setParent @

    added = yes
    if index <= 0
      @$().prepend itemInstance.$()
    else if index > 0
      if @items[index-1]?.$().hasClass('has-sub-items')
        @items[index-1].$().next().after itemInstance.$()
      else if @items[index-1]?
        @items[index-1].$().after itemInstance.$()
      else
        warn "Out of bound"
        added = no

    if @parentIsInDom and added
      itemInstance.emit 'viewAppended'

    null
