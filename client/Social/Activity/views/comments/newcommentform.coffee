class NewCommentForm extends KDView

  constructor:(options = {}, data)->

    options.type           or= "new-comment"
    options.cssClass       or= "item-add-comment-box"
    options.itemTypeString or= 'comment'

    super options, data

  viewAppended:->

    @addSubView commenterAvatar = new AvatarStaticView
      size    :
        width : 43
        height: 43
    , KD.whoami()

    @addSubView commentFormWrapper = new KDView
      cssClass    : "item-add-comment-form"

    {itemTypeString} = @getOptions()

    commentFormWrapper.addSubView @commentInput = new KDHitEnterInputView
      type          : "textarea"
      delegate      : this
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
    @commentInput.on "focus", =>
      @getDelegate().emit "commentInputReceivedFocus"

  makeCommentFieldActive:->
    @getDelegate().emit "commentInputReceivedFocus"
    (KD.getSingleton "windowController").setKeyView @commentInput

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
        @commentInput.resize()
        @commentInput.blur()
        @commentInput.$().blur()
        @getDelegate().emit 'CommentSubmitted', reply
      onFailMsg : "Login required to post a comment!"
      tryAgain  : yes
      groupName : @getDelegate().getData().group