class EnvironmentItem extends KDDiaObject

  JView.mixin @prototype

  constructor:(options={}, data)->

    options.cssClass       = KD.utils.curry "environments-item", options.cssClass
    options.bind           = KD.utils.curry "contextmenu", options.bind
    options.jointItemClass = EnvironmentItemJoint
    options.draggable      = no
    options.colorTag      ?= "#1AAF5D"

    super options, data

    @chevron   = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "chevron"
      click    : @bound "contextMenu"

  contextMenuItems:->

    colorSelection = new ColorSelection
      selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    items =
      Delete      :
        disabled  : KD.isGuest()
        separator : yes
        action    : 'delete'
      customView  : colorSelection

    return items

  contextMenu:(event)->

    KD.utils.stopDOMEvent event

    menuItems = @contextMenuItems()
    return  unless menuItems

    ctxMenu = new KDContextMenu
      menuWidth   : 187
      delegate    : this
      x           : event.pageX
      y           : event.pageY
      lazyLoad    : yes
    ,
      menuItems

    ctxMenu.on 'ContextMenuItemReceivedClick', (item) =>
      {action, callback} = item.getData()
      ctxMenu.destroy()  if callback? or @["cm#{action}"]?
      @["cm#{action}"]?()

  # - Context Menu Actions - #

  cmdelete : -> @confirmDestroy?()
  cmunfocus: -> @parent.emit 'UnhighlightDias'

  setColorTag : (color, save = yes) ->

    @options.colorTag = color
    @saveColorTag color  if save
    @parent.emit 'UpdateScene'

  saveColorTag:(color)->

    return unless @parent?.appStorage

    colorTags = (@parent.appStorage.getValue 'colorTags') or {}
    name      = @constructor.name
    uid       = @getData().uid
    colorTags["#{name}-#{uid}"] = color

    @parent.appStorage.setValue 'colorTags', colorTags

  loadColorTag:->

    return unless @parent?.appStorage

    colorTags = (@parent.appStorage.getValue 'colorTags') or {}
    name      = @constructor.name
    uid       = @getData().uid
    color     = colorTags["#{name}-#{uid}"]

    @setColorTag color  if color

  viewAppended:->
    JView::viewAppended.call this

    @setColorTag @getOption('colorTag'), no
    @parent.appStorage?.ready @bound 'loadColorTag'

  pistachio:->
    """
      <div class='details'>
        <span class='toggle'></span>
        {h3{#(title)}}
        {{> @chevron}}
      </div>
    """
