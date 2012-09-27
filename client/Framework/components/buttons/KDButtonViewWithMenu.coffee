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
    {style,buttonMenuClass,menu,contextClass,contextControllerClass,itemClass} = @getOptions()

    @buttonMenu = new (buttonMenuClass or JButtonMenu)
      cssClass : style
      ghost    : @$('.chevron').clone()
      event    : event
      delegate : @
    , if "function" is typeof menu then menu() else menu

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