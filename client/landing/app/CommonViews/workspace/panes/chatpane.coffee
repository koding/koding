class ChatPane extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "workspace-chat"

    super options, data

    @workspace = @getDelegate()
    @ref       = @workspace.workspaceRef.child "chat"

    @dock      = new KDView
      partial  : "Chat"
      cssClass : "dock"
      click    : =>
        @toggleClass "active"

    @wrapper   = new KDView
      cssClass : "wrapper"

    @messages  = new KDView
      cssClass : "messages"

    @input     = new KDHitEnterInputView
      type     : "text"
      callback : =>
        message =
          user : KD.nick()
          time : Date.now()
          body : @input.getValue()

        @ref.child(message.time).set message
        @input.setValue ""
        @input.setFocus()

    @wrapper.addSubView @messages
    @wrapper.addSubView @input

    @ref.on "child_added", (snapshot) => @addNew snapshot.val()

  addNew: (details) ->
    @messages.addSubView new KDCustomHTMLView
      partial : "#{details.user}: #{details.body}"

  pistachio: ->
    """
      {{> @dock}}
      {{> @wrapper}}
    """