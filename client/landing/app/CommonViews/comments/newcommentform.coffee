class NewCommentForm extends KDView

  constructor:(options = {}, data)->

    options.type           or= "new-comment"
    options.cssClass       or= "item-add-comment-box"
    options.itemTypeString or= 'comment'

    super options, data

  viewAppended:->
    {profile} = KD.whoami()
    host = "//#{location.host}/"
    defaultAvatarUrl = encodeURIComponent(host + '/images/defaultavatar/default.avatar.30.png')
    fallbackUrl = if profile.hash
    then "url(//www.gravatar.com/avatar/#{profile.hash}?size=30&d=#{defaultAvatarUrl})"
    else "url(#{defaultAvatarUrl})"

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
      callback      : @bound "commentInputReceivedEnter"

    @attachListeners()

  attachListeners:->
    @commentInput.on "blur", @bound "commentInputReceivedBlur"

  commentPosted:->
    @commentInput.setValue ""
    @resetCommentField()

  makeCommentFieldActive:->
    @getDelegate().emit "DecorateActiveCommentView"
    (@getSingleton "windowController").setKeyView @commentInput

  resetCommentField:->
    @getDelegate().emit "CommentViewShouldReset"

  otherCommentInputReceivedFocus:(instance)->
    if instance isnt @commentInput
      commentForm = @commentInput.getDelegate()
      commentForm.resetCommentField() if $.trim(@commentInput.getValue()) is ""

  commentInputReceivedBlur:->
    @resetCommentField()  if @commentInput.getValue() is ""

  commentInputReceivedEnter:(instance,event)->
    KD.requireMembership
      callback  : =>
        reply = @commentInput.getValue()
        @commentInput.setValue ''
        @commentInput.blur()
        @commentInput.$().blur()
        @getDelegate().emit 'CommentSubmitted', reply
      onFailMsg : "Login required to post a comment!"
      tryAgain  : yes
      groupName : @getDelegate().getData().group
