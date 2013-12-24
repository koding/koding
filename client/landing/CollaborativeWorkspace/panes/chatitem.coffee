class ChatItem extends JView

  constructor: (options, data) ->

    options.cssClass = KD.utils.curry "chat-item", options.cssClass

    super options, data

    @createAvatar()

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

  createAvatar: ->
    @avatar      = new AvatarView
      size       :
        width    : 30
        height   : 30
    , @getData()

  pistachio: ->
    """
      {{> @avatar}}
      {{> @messageList}}
    """