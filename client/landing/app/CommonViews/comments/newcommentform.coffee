class NewCommentForm extends KDView

  constructor:(options = {}, data)->

    options.type           or= "new-comment"
    options.cssClass       or= "item-add-comment-box"
    options.itemTypeString or= 'comment'

    super options, data

  viewAppended:()->
    {profile} = KD.whoami()
    host = "//#{location.host}/"
    fallbackUrl = "url(//www.gravatar.com/avatar/#{profile.hash}?size=30&d=#{encodeURIComponent(host + '/images/defaultavatar/default.avatar.30.png')})"

    @addSubView commenterAvatar = new KDCustomHTMLView
      tagName : "span"
      partial : "<a href='#' style='background-image:#{fallbackUrl};'></a>"

    @addSubView commentFormWrapper = new KDView
      cssClass    : "item-add-comment-form"

    {itemTypeString} = @getOptions()

    commentFormWrapper.addSubView @commentInput   = new KDHitEnterInputView
      type          : "textarea"
      delegate      : @
      placeholder   : "Type your #{itemTypeString} and hit enter..."
      autogrow      : yes
      validate      :
        rules       :
          required  : yes
          maxLength : 2000
        messages    :
          required  : "Please type a #{itemTypeString}..."
      callback      : @commentInputReceivedEnter

    @attachListeners()

  attachListeners:->
    @commentInput.on "focus", @bound "commentInputReceivedFocus"
    @commentInput.on "blur", @bound "commentInputReceivedBlur"

  commentPosted:()->
    @commentInput.setValue ""
    @resetCommentField()

  makeCommentFieldActive:()->
    @getDelegate().emit "DecorateActiveCommentView"
    (@getSingleton "windowController").setKeyView @commentInput

  resetCommentField:()->
    @getDelegate().emit "CommentViewShouldReset"

  otherCommentInputReceivedFocus:(instance)->
    if instance isnt @commentInput
      commentForm = @commentInput.getDelegate()
      commentForm.resetCommentField() if $.trim(@commentInput.getValue()) is ""

  commentInputReceivedFocus:()->

    @makeCommentFieldActive()
    list = @getDelegate()
    listLength = list.items.length

    if list.items.length > 0
      firstCommentTimestamp = list.items[0].getData().meta.createdAt
      fromUnixTime          = Date.parse firstCommentTimestamp
    else
      fromUnixTime = Date.parse 1e7

    callback = => @makeCommentFieldActive()

  commentInputReceivedBlur:()->
    @resetCommentField()  if @commentInput.getValue() is ""

  commentInputReceivedEnter:(instance,event)=>
    if KD.isLoggedIn()
      reply = @commentInput.getValue()
      @commentInput.setValue ''
      @commentInput.blur()
      @commentInput.$().blur()
      @getDelegate().emit 'CommentSubmitted', reply
    else
      new KDNotificationView
        type      : "growl"
        title     : "please login to post a comment!"
        duration  : 1500
