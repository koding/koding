class EnvironmentItem extends KDDiaObject

  constructor:(options={}, data)->

    options.cssClass       = KD.utils.curry "environments-item", \
                             options.cssClass
    options.bind           = KD.utils.curry "contextmenu", options.bind
    options.jointItemClass = EnvironmentItemJoint
    options.draggable      = no
    options.colorTag       ?= "#a2a2a2"

    super options, data

  contextMenuItems:->

    colorSelection = new ColorSelection
      selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    items =
      'Delete'    :
        separator : yes
        action    : 'delete'
      'Unfocus'   :
        separator : yes
        action    : 'unfocus'
      customView  : colorSelection

    return items

  contextMenu:(event)->

    KD.utils.stopDOMEvent event

    menuItems = @contextMenuItems()
    return  unless menuItems

    ctxMenu = new JContextMenu
      menuWidth   : 200
      delegate    : @
      x           : event.pageX + 15
      y           : event.pageY - 23
      arrow       :
        placement : "left"
        margin    : 19
      lazyLoad    : yes
    ,
      menuItems

    ctxMenu.on 'ContextMenuItemReceivedClick', (item) =>
      {action} = item.getData()
      ctxMenu.destroy()  if @["cm#{action}"]?
      @["cm#{action}"]?()

  # - Context Menu Actions - #

  cmdelete : -> @confirmDestroy?()
  cmunfocus: -> @parent.emit 'UnhighlightDias'

  setColorTag : (color) ->
    @getElement().style.borderLeftColor = color
    @options.colorTag                   = color

  viewAppended : ->
    super
    @setColorTag @getOption('colorTag')

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """
