class TeamworkChatItem extends ChatItem

  createAvatar: ->
    if @getData().nickname is "teamwork"
      @avatar    = new KDCustomHTMLView
        tagName  : "a"
        cssClass : "avatarview tw-bot-avatar"
    else
      super