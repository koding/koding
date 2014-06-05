class CommentSettingsButton extends KDButtonViewWithMenu

  constructor: (options = {}, data) ->

    options.cssClass       = 'comment-menu'
    options.itemChildClass = ActivityItemMenuItem
    options.icon           = yes
    options.iconOnly       = yes
    options.style          = 'resurrection'
    options.callback       = @bound 'contextMenu'
    style                  = 'resurrection'

    super options, data

  setDomElement:(cssClass = '')->
    @domElement = $ """
      <button class='kdbutton #{cssClass} with-icon with-menu' id='#{@getId()}'>
        <span class='icon'></span>
      </button>
      """
    @$button = @domElement

    return @domElement
