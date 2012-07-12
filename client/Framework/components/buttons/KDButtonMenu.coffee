class KDButtonMenu extends KDContextMenu
  constructor:(options,data)->
    options = options ? {}
    # options.parent = "body"
    super options,data
    @setClass "kdbuttonmenu"
    @setPartial "<div class='chevron-arrow-ghost-wrapper'><span class='chevron-arrow-ghost'></span></div>"

  positionContextMenu:()->
    button        = @getDelegate()
    mainHeight    = $(window).height()
    buttonHeight  = button.$().outerHeight()
    buttonWidth   = button.$().outerWidth()
    top           = button.getY() + buttonHeight
    menuHeight    = @$().outerHeight()
    menuWidth     = @$().outerWidth()

    if top + menuHeight > mainHeight
      top = button.getY() - menuHeight
      @setClass "top-menu"
      ghostCss = 
        top     : "100%"
        height  : buttonHeight
    else
      ghostCss = 
        top     : -(buttonHeight + 1)
        height  : buttonHeight

    @$(".chevron-arrow-ghost-wrapper").css ghostCss
    
    @$().css
      top       : top
      left      : button.getX() + buttonWidth - menuWidth

class JButtonMenu extends JContextMenu

  constructor:->

    super
    @setClass "kdbuttonmenu"
    @setPartial "<div class='chevron-arrow-ghost-wrapper'><span class='chevron-arrow-ghost'></span></div>"

  positionContextMenu:()->

    button        = @getDelegate()
    mainHeight    = $(window).height()
    buttonHeight  = button.$().outerHeight()
    buttonWidth   = button.$().outerWidth()
    top           = button.getY() + buttonHeight
    menuHeight    = @$().outerHeight()
    menuWidth     = @$().outerWidth()

    if top + menuHeight > mainHeight
      top = button.getY() - menuHeight
      @setClass "top-menu"
      ghostCss = 
        top     : "100%"
        height  : buttonHeight
    else
      ghostCss = 
        top     : -(buttonHeight + 1)
        height  : buttonHeight

    @$(".chevron-arrow-ghost-wrapper").css ghostCss
    
    @$().css
      top       : top
      left      : button.getX() + buttonWidth - menuWidth