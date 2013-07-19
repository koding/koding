class ChatItem extends JView

  constructor: (options, data) ->

    options.cssClass = "chat-item"

    super options, data

    account = @getData()
    @avatar = new AvatarView
      size        :
        width     : 30
        height    : 30
    , account

    {user}     = @getOptions()
    @username  = new KDCustomHTMLView
      cssClass : "username"
      partial  : "#{user.firstName} #{user.lastName}"

    @messageList = new KDView
      cssClass   : "items-container"

    @messageList.addSubView new KDCustomHTMLView
      partial : @getOptions().body

  pistachio: ->
    """
      {{> @avatar}}
      {{> @username}}
      {{> @messageList}}
    """
