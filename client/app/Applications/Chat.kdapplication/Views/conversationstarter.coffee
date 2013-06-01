class ConversationStarterButton extends KDButtonView

  constructor:(options, data)->

    options = $.extend
      cssClass  : 'clean-gray conversation-starter'
      icon      : yes
      iconClass : 'plus-black'
    , options

    super options, data

  click:->
    contextMenu = new JContextMenu
      menuWidth   : 200
      delegate    : @
      x           : @getX() - 206
      y           : @getY() - 6
      arrow       :
        placement : "right"
        margin    : 6
      lazyLoad    : yes