class KDButtonViewWithMenu extends KDButtonView
  constructor:->
    super

  setDomElement:()->
    @domElement = $ """
      <div class='kdbuttonwithmenu-wrapper'>
        <button class='kdbutton clean-gray with-icon with-menu' id='#{@getId()}'>
          <span class='icon hidden'></span>
        </button>
        <span class='chevron-arrow-separator'></span>
        <span class='chevron-arrow'></span>
      </div>
      """
  
  setIconOnly:()->
    @$().addClass('icon-only').removeClass('with-icon')
    $icons = @$('span.icon,span.chevron-arrow')
    @$().html $icons

  click:(event)->
    if $(event.target).is(".chevron-arrow")
      @contextMenu event
      return no
    @getCallback().call @,event

  contextMenu:(event)->
    @createContextMenu event
    no

  createContextMenu:(event)->
    {style,buttonMenuClass,menu,contextClass,contextControllerClass,subItemClass} = @getOptions()

    @buttonMenu = new (buttonMenuClass or KDButtonMenu)
      cssClass : style
      ghost    : @$('.chevron-arrow').clone()
      event    : event
      delegate : @
    
    menu = if "function" is typeof menu then menu() else menu
    
    menu.forEach (menuTreeData)=>
      @buttonMenu.addSubView view = new (contextClass or KDContextMenuTreeView)
        delegate : @

      controller = new (contextControllerClass or KDContextMenuTreeViewController) {
        subItemClass
        view
      }
      , menuTreeData

      # @listenTo 
      #   KDEventTypes : "itemsAdded"
      #   listenedToInstance : controller
      #   callback : ()=> @buttonMenu.positionContextMenu()

    KDView.appendToDOMBody @buttonMenu
    
  # overriden methods because of domElement change
  setTitle:(title)->
    @$('button').append title

  setButtonStyle:(newStyle)->
    {styles} = @constructor
    for style in styles
      @$().removeClass style
      @$('button').removeClass style
    @$('button').addClass newStyle
    @$().addClass newStyle

  setIconOnly:()->
    @$('button').addClass('icon-only').removeClass('with-icon')
    $icon = @$('span.icon')
    @$('button').html $icon

  disable:()->
    @$('button').attr "disabled",yes
  enable:()->
    @$('button').attr "disabled",no