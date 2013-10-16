class ChatPane extends JView

  constructor: (options = {}, data) ->

    floatingCssClass = if options.floating then "floating" else ""
    options.cssClass = KD.utils.curry "workspace-chat", floatingCssClass

    super options, data

    @unreadCount = 0
    @workspace   = @getDelegate()
    @chatRef     = @workspace.workspaceRef.child "chat"

    @dock        = new KDView
      cssClass   : "dock"
      click      : =>
        @dock.unsetClass "pulsing"
        @toggleClass "active"
        @toggle.toggleClass "active"
        @unreadCount = 0
        @title.updatePartial "Chat"

    @title       = new KDCustomHTMLView
      tagName    : "span"
      partial    : "Chat"

    @toggle      = new KDView cssClass : "toggle"
    @messages    = new KDView cssClass : "messages"
    @input       = new KDHitEnterInputView
      type       : "text"
      callback   : =>
        {nickname, firstName, lastName} = KD.whoami().profile
        message  =
          user   : { nickname, firstName, lastName }
          time   : Date.now()
          body   : @input.getValue()

        @chatRef.child(message.time).set message
        @input.setValue ""
        @input.setFocus()
        @workspace.setHistory "<strong>#{nickname}:</strong> #{message.body}"

    @dock.addSubView @toggle
    @dock.addSubView @title

    @chatRef.on "child_added", (snapshot) =>
      unless @isVisible() or @getOptions().floating
        @title.updatePartial "Chat (#{++@unreadCount})"
        @dock.setClass "pulsing"

      @utils.wait 300, => @addNew snapshot.val() # to prevent a possible race condition

  isVisible: -> return @hasClass "active"

  addNew: (details) ->
    ownerNickname = details.user.nickname
    if @lastChatItemOwner is ownerNickname
      @lastChatItem.messageList.addSubView new KDCustomHTMLView
        partial : Encoder.XSSEncode details.body
      @updateDate details.time
      return  @scrollToTop()

    @lastChatItem      = new ChatItem details, @workspace.users[ownerNickname]
    @lastChatItemOwner = ownerNickname
    @messages.addSubView @lastChatItem
    @updateDate details.time
    @scrollToTop()

  updateDate: (timestamp) ->
    @lastChatItem.timeAgo.setData new Date timestamp

  scrollToTop: ->
    $messages = @messages.$()
    $messages.scrollTop $messages[0].scrollHeight

  pistachio: ->
    """
      {{> @dock}}
      {{> @messages}}
      <div class="input-container">
        {{> @input}}
      </div>
    """
