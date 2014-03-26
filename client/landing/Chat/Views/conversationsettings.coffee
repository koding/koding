class ConversationSettingsButton extends KDButtonView

  constructor:(options, data)->

    options = $.extend
      cssClass  : 'clean-gray conversation-settings'
      icon      : yes
      iconClass : 'cog'
    , options

    super options, data

  click:->
    conversationSettings = new ConversationSettings
    contextMenu   = new KDContextMenu
      menuWidth   : 200
      delegate    : @
      x           : @getX() - 148
      y           : @getY() + 26
      arrow       :
        placement : "top"
        margin    : 150
      lazyLoad    : yes
    , customView  : conversationSettings

    conversationSettings.on 'ConversationStarted', contextMenu.bound 'destroy'

class ConversationSettings extends JView

  constructor:->
    super
      cssClass : "conversation-settings"

  pistachio:-> """ Settings will be here """