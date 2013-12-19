class ChatItem extends JView

  constructor: (options, data) ->

    options.cssClass = "chat-item"

    super options, data

    # TODO: THERE MUST BE AN ACCOUNT
    #       OTHERWISE MESSAGES WILL BE POSTED AS A SYSTEM MESSAGE...
    #       TEST CASE IS, JOIN NEW SESSION
    account = @getData() or { nickname: "teamwork" }

    if account.nickname is "teamwork"
      @avatar    = new KDCustomHTMLView
        cssClass : "tw-bot-avatar"
    else
      @avatar    = new AvatarView
        size     :
          width  : 30
          height : 30
      , account

    {user}       = @getOptions()
    ownMessage   = user.nickname is KD.nick()

    @messageList = new KDView
      cssClass   : "items-container"

    @messageList.addSubView @header = new KDCustomHTMLView
      cssClass   : "username"
      partial    : if ownMessage then "Me" else
                   if user.nickname is "teamwork" then "Teamwork Bot"
                   else "#{user.nickname}"

    @header.addSubView @timeAgo = new KDTimeAgoView
      cssClass   : "time-ago"
    , new Date @getOptions().time

    @messageList.addSubView new KDCustomHTMLView
      partial    : KD.utils.xssEncode(@getOptions().body).replace(/NEW_LINE/g, "<br />")

    @setClass "mine" if ownMessage

  pistachio: ->
    """
      {{> @avatar}}
      {{> @messageList}}
    """
