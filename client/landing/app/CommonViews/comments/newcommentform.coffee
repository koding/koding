class NewCommentForm extends KDView

  constructor:(options, data)->

    options = $.extend
      type      : "new-comment"
      cssClass  : "item-add-comment-box"
    ,options

    super options,data

  viewAppended:()->
    {profile} = KD.whoami()
    host = "http://#{location.host}/"
    fallbackUrl = "url(http://www.gravatar.com/avatar/#{profile.hash}?size=30&d=#{encodeURIComponent(host + '/images/defaultavatar/default.avatar.30.png')})"

    @addSubView commenterAvatar = new KDCustomHTMLView
      tagName : "span"
      partial : "<a href='#' style='background-image:#{fallbackUrl};'></a>"

    @addSubView commentFormWrapper = new KDView
      cssClass    : "item-add-comment-form"

    commentFormWrapper.addSubView @commentInput   = new KDHitEnterInputView
      type        : "textarea"
      delegate    : @
      placeholder : "Type your comment and hit enter..."
      # autogrow    : yes
      validate    :
        # event       : "keyup"
        rules       :
          required    : yes
        messages    :
          required    : "Please type a comment..."
      callback    : @commentInputReceivedEnter

    @attachListeners()

  attachListeners:->
    @listenTo
      KDEventTypes:       "Focus"
      listenedToInstance: @commentInput
      callback:           @commentInputReceivedFocus
    @listenTo
      KDEventTypes:       "Blur"
      listenedToInstance: @commentInput
      callback:           @commentInputReceivedBlur

  commentPosted:()->
    @commentInput.setValue ""
    @resetCommentField()

  makeCommentFieldActive:()->
    @getDelegate().handleEvent type : "DecorateActiveCommentView"
    (@getSingleton "windowController").setKeyView @commentInput

  resetCommentField:()->
    @getDelegate().handleEvent type : "CommentViewShouldReset"

  otherCommentInputReceivedFocus:(instance)->
    if instance isnt @commentInput
      commentForm = @commentInput.getDelegate()
      commentForm.resetCommentField() if $.trim(@commentInput.getValue()) is ""

  commentInputReceivedFocus:()->

    @makeCommentFieldActive()
    list = @getDelegate()
    listLength = list.items.length
    # list.emit "BackgroundActivityStarted"
    if list.items.length > 0
      firstCommentTimestamp = list.items[0].getData().meta.createdAt
      fromUnixTime = Date.parse firstCommentTimestamp
    else
      fromUnixTime = Date.parse 1e7

    callback = (err,comments)=>
      @makeCommentFieldActive()

    list.propagateEvent KDEventType : "CommentInputReceivedFocus",{fromUnixTime,callback}
    no

  commentInputReceivedBlur:()->
    if @commentInput.getValue() is ""
      @resetCommentField()
    no

  commentInputReceivedEnter:(instance,event)=>
    if KD.isLoggedIn()
      reply = @commentInput.getValue()
      @commentInput.setValue ''
      @commentInput.blur()
      @commentInput.$().blur()
      @getDelegate().propagateEvent KDEventType: 'CommentSubmitted', reply
    else
      new KDNotificationView
        type      : "growl"
        title     : "please login to post a comment!"
        duration  : 1500
