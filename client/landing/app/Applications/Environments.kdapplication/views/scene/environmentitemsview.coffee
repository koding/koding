class EnvironmentItem extends KDDiaObject

  constructor:(options={}, data)->

    options.cssClass = KD.utils.curry "environments-item", options.cssClass
    options.jointItemClass = EnvironmentItemJoint
    options.draggable = no
    options.showStatusIndicator ?= yes
    options.bind = KD.utils.curry "contextmenu", options.bind
    options.colorTag ?= "#a2a2a2"
    data.activated   ?= yes

    super options, data

  addStatusIndicator : ->
    @addSubView @statusIndicator = new KDCustomHTMLView
      cssClass    : "status-indicator"
      click       : => @toggleStatus()

  toggleStatus : ->
    @toggleClass "passivated"
    @data.activated = !@data.activated

  contextMenu : (event) ->
    KD.utils.stopDOMEvent event

    if @contextMenuItems()
      @ctxMenu = new JContextMenu
        menuWidth   : 200
        delegate    : @
        x           : event.pageX + 15
        y           : event.pageY - 23
        arrow       :
          placement : "left"
          margin    : 19
        lazyLoad    : yes
      ,
        @contextMenuItems()

      @ctxMenu.on 'ContextMenuItemReceivedClick', (item) =>
        {action}  = item.getData()
        @ctxMenu.destroy()
        @["cm#{action}"]?()

      @colorSelection?.on "ColorChanged", (color) => @setColorTag color


  # - Context Menu Actions - #

  cmdelete : -> @confirmDestroy?()
  cmunfocus: -> @parent.emit 'UnhighlightDias'


  setColorTag : (color) ->
    @getElement().style.borderLeftColor = color
    @options.colorTag                   = color

  viewAppended : ->
    super
    @setClass 'activated'  if @getData().activated?
    if not @getData().activated
      KD.utils.defer =>
        @setClass 'passivated'
    @addStatusIndicator() if @getOption "showStatusIndicator"

    @setColorTag @getOption('colorTag')

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{#(description)}}
      </div>
    """
