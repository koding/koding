class ChatPane extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "workspace-chat"

    super options, data

    @workspace = @getDelegate()
    @chatRef   = @workspace.workspaceRef.child "chat"

    @dock      = new KDView
      partial  : "Chat"
      cssClass : "dock"
      click    : =>
        @toggleClass "active"
        @toggle.toggleClass "active"

    @dock.addSubView @toggle = new KDView
      cssClass : "toggle"

    @wrapper   = new KDView
      cssClass : "wrapper"

    @messages  = new KDView
      cssClass : "messages"

    @input     = new KDHitEnterInputView
      type     : "text"
      callback : =>
        {nickname, firstName, lastName} = KD.whoami().profile
        message =
          user : { nickname, firstName, lastName }
          time : Date.now()
          body : @input.getValue()

        @chatRef.child(message.time).set message
        @input.setValue ""
        @input.setFocus()

    @wrapper.addSubView @messages
    @wrapper.addSubView @input

    @chatRef.on "child_added", (snapshot) =>
      @utils.wait 300, => @addNew snapshot.val() # to prevent a possible race condition

  addNew: (details) ->
    ownerNickname = details.user.nickname
    if @lastChatItemOwner is ownerNickname
      @lastChatItem.messageList.addSubView new KDCustomHTMLView
        partial : details.body
      return  @scrollToTop()

    @lastChatItem      = new ChatItem details, @workspace.users[ownerNickname]
    @lastChatItemOwner = ownerNickname
    @messages.addSubView @lastChatItem
    @scrollToTop()

  scrollToTop: ->
    $messages = @messages.$()
    $messages.scrollTop $messages[0].scrollHeight

  pistachio: ->
    """
      {{> @dock}}
      {{> @wrapper}}
    """

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
