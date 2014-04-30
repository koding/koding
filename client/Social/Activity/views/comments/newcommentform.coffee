class NewCommentForm extends KDView

  constructor:(options = {}, data)->

    options.type     or= "new-comment"
    options.cssClass or= "item-add-comment-box"
    options.editable or= no

    super options, data

    @input = new KDHitEnterInputView
      type          : "textarea"
      delegate      : this
      placeholder   : "Type your comment and hit enter..."
      autogrow      : yes
      validate      :
        rules       :
          required  : yes
          maxLength : 2000
        messages    :
          required  : "Please type a comment..."
      callback      : @bound "commentInputReceivedEnter"


  submit: ->

    @getDelegate().emit 'CommentSubmitted', @input.getValue()


  viewAppended:->
    {editable} = @getOptions()
    unless editable
      @addSubView new AvatarStaticView
        size    :
          width : 42
          height: 42
      , KD.whoami()

    @addSubView @input

    @attachListeners()

  attachListeners:->
    @input.on "blur", @bound "commentInputReceivedBlur"
    @input.on "focus", =>
      KD.mixpanel "Comment activity, focus"
      @getDelegate().emit "commentInputReceivedFocus"

  makeCommentFieldActive:->
    @getDelegate().emit "commentInputReceivedFocus"
    (KD.getSingleton "windowController").setKeyView @input

  resetCommentField:->
    @getDelegate().emit "CommentViewShouldReset"

  otherCommentInputReceivedFocus:(instance)->
    if instance isnt @input
      commentForm = @input.getDelegate()
      commentForm.resetCommentField() if $.trim(@input.getValue()) is ""

  commentInputReceivedBlur:->
    @resetCommentField()  if @input.getValue() is ""

  commentInputReceivedEnter:(instance,event)->
    KD.requireMembership
      callback  : =>
        @input.setValue ''
        @input.resize()
        @input.blur()
        @input.$().blur()

        @submit()

        KD.mixpanel "Comment activity, click", @input.getValue().length
      onFailMsg : "Login required to post a comment!"
      tryAgain  : yes
      groupName : @getDelegate().getData().group
