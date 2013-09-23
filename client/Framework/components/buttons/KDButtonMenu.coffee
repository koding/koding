class JButtonMenu extends JContextMenu

  constructor:(options = {}, data)->

    options.cssClass        = @utils.curry "kdbuttonmenu", options.cssClass
    # options.type            = "buttonmenu"
    options.listViewClass or= JContextMenuTreeView
    # options.offset        or= {}
    # options.offset.top    or= 0
    # options.offset.left   or= 0

    super options, data

  viewAppended:->
    super
    @setPartial "<div class='chevron-ghost-wrapper'><span class='chevron-ghost'></span></div>"
    @positionContextMenu()

  positionContextMenu:->

    # options       = @getOptions()
    button        = @getDelegate()
    mainHeight    = $(window).height()
    buttonHeight  = button.getHeight()
    buttonWidth   = button.getWidth()
    top           = button.getY() + buttonHeight
    menuHeight    = @getHeight()
    menuWidth     = @getWidth()

    ghostCss = if top + menuHeight > mainHeight
      top = button.getY() - menuHeight
      @setClass "top-menu"
      top     : "100%"
      height  : buttonHeight
    else
      top     : -(buttonHeight + 1)
      height  : buttonHeight

    @$(".chevron-ghost-wrapper").css ghostCss

    @$().css
      top       : top
      left      : button.getX() + buttonWidth - menuWidth

    # left here for reference to be able to put menu left or right for button menus
    # it needs some work decided to be left as TBDL - SY

    # @$().css
    #   top       : top + options.offset.top
    #   left      : button.getX() + buttonWidth - menuWidth + options.offset.left
