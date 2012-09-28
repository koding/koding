class KDButtonViewWithMenu extends KDButtonView

  setDomElement:(cssClass = '')->
    @domElement = $ """
      <div class='kdbuttonwithmenu-wrapper #{cssClass}'>
        <button class='kdbutton #{cssClass} with-icon with-menu' id='#{@getId()}'>
          <span class='icon hidden'></span>
        </button>
        <span class='chevron-separator'></span>
        <span class='chevron'></span>
      </div>
      """
    @$button = @$('button').first()

    return @domElement

  setIconOnly:()->
    @$().addClass('icon-only').removeClass('with-icon')
    $icons = @$('span.icon,span.chevron')
    @$().html $icons

  click:(event)->
    if $(event.target).is(".chevron")
      @contextMenu event
      return no
    @getCallback().call @, event

  contextMenu:(event)->
    @createContextMenu event
    no

  createContextMenu:(event)->

    o = @getOptions()
    @buttonMenu = new (o.buttonMenuClass or JButtonMenu)
      cssClass          : o.style
      ghost             : @$('.chevron').clone()
      event             : event
      delegate          : @
      treeItemClass     : o.treeItemClass
      itemChildClass    : o.itemChildClass
      itemChildOptions  : o.itemChildOptions
    , if "function" is typeof o.menu then o.menu() else o.menu

  # overriden methods because of domElement change
  setTitle:(title)->
    @$button.append title

  setButtonStyle:(newStyle)->
    {styles} = @constructor
    for style in styles
      @$().removeClass style
      @$button.removeClass style
    @$button.addClass newStyle
    @$().addClass newStyle

  setIconOnly:()->
    @$button.addClass('icon-only').removeClass('with-icon')
    $icon = @$('span.icon')
    @$button.html $icon

  disable:()->
    @$button.attr "disabled",yes
  enable:()->
    @$button.attr "disabled",no