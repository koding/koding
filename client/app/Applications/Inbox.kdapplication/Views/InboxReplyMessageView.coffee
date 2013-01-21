class InboxReplyMessageView extends KDView
  constructor:()->
    super
    @listenWindowResize()

  _windowDidResize:()=>
    @resize()

  formSubmit:(formData)=>
    privateMessage = @getData().getData()
    privateMessage.addPrivateMessageReply (type: 'reply'), formData.body

    @messageInput.setValue ''

    # (@getSingleton "site").account.addQuestion callback: ()=>
    #   @propagateEvent (KDEventType:"ActionComplete")
    # , formData

  viewAppended:()->
    privateMessage  = @getData().getData()

    @setHeight "auto"
    @addSubView header = new KDHeaderView type : "big", title : "Reply Message"

    @form = form = new KDFormView
      callback : @formSubmit
      cssClass : "settings-form clearfix"

    recipientLabel = new KDLabelView
      title : "Recipient:"

    messageLabel = new KDLabelView
      title : "Message:"

    @messageInput = message = new Inbox_MessageInput
      delegate: @
      name    : "body"
      type    : "textarea"
      label   : messageLabel
      validate  :
        rules     :
          minLength : 1
        messages  :
          minLength : "Please type a message"

    message.setHeight "150px"

    button = new KDButtonView
      title : "Send message"
      style : "cupid-green"

    form.addSubView messageLabel
    form.addSubView message
    form.addSubView button

    @addSubView @listScrollView = listScrollView = new KDScrollView()
    listScrollView.addSubView showMoreLink = new InboxReplyList_ShowMoreLink delegate: privateMessage
    listScrollView.addSubView replyListView    = new InboxRepliesView {}, KDDataPath: 'Data.replies', KDDataSource: @getData().getData()

    listScrollView.listenTo
      KDEventTypes        : [ eventType : "click" ]
      listenedToInstance  : showMoreLink
      callback            : (pubInst, event) ->
        replyListView.showAllReplies(pubInst, event)

    @addSubView form
    @setHeight @getDelegate().getHeight()-41

    listScrollView.setHeight @getHeight()-221
    form.setHeight 221

  resize:(pubInst, event) ->
    @listScrollView.setHeight @getHeight()-221
    @setHeight @getDelegate().getHeight()-41
    @form.setHeight 221


class InboxReplyList_ShowMoreLink extends KDCustomHTMLView
  constructor:(options, data)->
    if options?.delegate
      @setDelegate options.delegate
    super "a"

  viewAppended:()->
    repliesMore = @getDelegate().replies.length - 20
    if repliesMore > 0
      @setClass "view-more-apps"
      @setPartial "<img src='./images/loader.fb.gif' class='loading'/><span class='link'>#{repliesMore} replies more...</span>"

  click: ->
    @destroy()
    yes

class Inbox_MessageInput extends KDInputView
  focus:(event)->
    (@getSingleton "windowController").setKeyView @

  click: ->
    (@getSingleton "windowController").setKeyView @

  keyUp:(event)->
    if event.keyCode is 13
      @getDelegate().form.submit()
