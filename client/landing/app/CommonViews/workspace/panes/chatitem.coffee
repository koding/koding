class ChatItem extends JView

  constructor: (options, data) ->

    options.cssClass = "chat-item"

    super options, data

    account      = @getData()
    @avatar      = new AvatarView
      size       :
        width    : 30
        height   : 30
    , account

    {user}       = @getOptions()
    ownMessage   = user.nickname is KD.nick()

    @messageList = new KDView
      cssClass   : "items-container"

    @messageList.addSubView @header = new KDCustomHTMLView
      cssClass   : "username"
      partial    : if ownMessage then "Me" else "#{user.nickname}"

    @header.addSubView @timeAgo = new KDTimeAgoView
      cssClass   : "time-ago"
    , new Date @getOptions().time

    @messageList.addSubView new KDCustomHTMLView
      partial    : Encoder.XSSEncode @getOptions().body

    @setClass "mine" if ownMessage

  pistachio: ->
    """
      {{> @avatar}}
      {{> @messageList}}
    """
