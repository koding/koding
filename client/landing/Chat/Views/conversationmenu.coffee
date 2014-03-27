class ConversationMenuButton extends KDButtonView

  constructor:(options, data)->

    options = $.extend
      cssClass  : 'clean-gray conversation-menu'
      iconClass : 'cog'
      icon      : yes
    , options

    super options, data

  click:->
    contextMenu   = new KDContextMenu
      delegate    : @
      menuWidth   : 200
      y           : @getY() + 21
      x           : @getX() - 170
      arrow       :
        margin    : 172
        placement : "top"
    , 'Leave Conversation' :
        callback           : =>
          chatController = KD.getSingleton 'chatController'
          chatController.leave @getData(), => @emit 'DestroyConversation'
      # 'Add more friends'   :
      #   children           :
      #     customView       : new ConversationStarter