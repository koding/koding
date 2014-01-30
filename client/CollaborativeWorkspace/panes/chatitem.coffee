class ChatItem extends JView

  constructor: (options, data) ->

    options.cssClass = KD.utils.curry "tw-chat-item", options.cssClass

    super options, data

    @createAvatar()

    {user, time, body} = @getOptions()
    ownMessage         = user.nickname is KD.nick()

    @messageList = new KDView
      cssClass   : "items-container"

    @messageList.addSubView @header = new KDCustomHTMLView
      cssClass   : "username"
      partial    : if ownMessage then "Me" else @getUsername()

    @header.addSubView @timeAgo = new KDTimeAgoView
      cssClass   : "time-ago"
    , new Date time

    body = body.split("\n").map (text) =>
      "<p class='tw-chat-para'>#{text}</p>"

    @messageList.addSubView @message = new KDCustomHTMLView
      cssClass   : "tw-chat-body"
      partial    : body

    @setClass "mine" if ownMessage

  getUsername: ->
    return "#{@getOptions().user.nickname}"

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