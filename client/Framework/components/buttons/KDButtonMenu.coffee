class JButtonMenu extends JContextMenu

  constructor:(options = {}, data)->

    options.cssClass = @utils.curryCssClass "kdbuttonmenu", options.cssClass

    super options, data

  viewAppended:->
    super
    @setPartial "<div class='chevron-ghost-wrapper'><span class='chevron-ghost'></span></div>"
    @positionContextMenu()

  positionContextMenu:()->

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