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

  setIconOnly:->
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
      # offset            :
      #   left            : 152
      #   top             : 0
    , if "function" is typeof o.menu then o.menu() else

      # this allows for "sorted" menus that can have elements added to then
      # dynamically at runtime. it also allows to adding elements at certain
      # positions  with Array.splice (whereas Objects properties can't be enumerated)

      if o.menu instanceof Array
        menuArrayToObj = {}
        for menuObject in o.menu
          for own menuObjectProperty,menuObjectValue of menuObject
            menuArrayToObj[menuObjectProperty]=menuObjectValue if menuObjectProperty? and menuObjectValue?

        # leave original o.menu array intact so it can be modified
        # and re-converted on each method call

        menuArrayToObj
      else o.menu

    @buttonMenu.on "ContextMenuItemReceivedClick", => @buttonMenu.destroy()

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

  setIconOnly:->
    @$button.addClass('icon-only').removeClass('with-icon')
    $icon = @$('span.icon')
    @$button.html $icon

  disable:->
    @$button.attr "disabled",yes
  enable:->
    @$button.attr "disabled",no