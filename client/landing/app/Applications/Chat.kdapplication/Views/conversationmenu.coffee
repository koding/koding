class ConversationMenuButton extends KDButtonView

  constructor:(options, data)->

    options = $.extend
      cssClass  : 'clean-gray conversation-menu'
      icon      : yes
      iconClass : 'cog'
    , options

    super options, data

  click:->
    contextMenu   = new JContextMenu
      menuWidth   : 200
      delegate    : @
      x           : @getX() - 170
      y           : @getY() + 21
      arrow       :
        placement : "top"
        margin    : 172
    ,
      'Leave Conversation' :
        callback           : (source, event)=>

          content = """ When you leave conversation you will not
                        receive any messages. And you will also loose
                        current messages in this conversation.
                        Do you want to continue?"""

          modal = new KDModalView
            title          : "Do you want to leave this conversation?"
            content        : "<div class='modalformline'><p>#{content}</p></div>"
            height         : "auto"
            overlay        : yes
            buttons        :
              'Leave'      :
                style      : "modal-clean-red"
                callback   : =>
                  {conversation} = @getData()
                  conversation.leave (err)=>
                    warn err  if err
                    @emit 'DestroyConversation'
                    modal.destroy()

              Cancel       :
                style      : "modal-clean-gray"
                callback   : ->
                  modal.destroy()
