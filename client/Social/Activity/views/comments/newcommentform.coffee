class NewCommentForm extends KDView

  constructor:(options = {}, data)->

    options.type           or= "new-comment"
    options.cssClass       or= "item-add-comment-box"
    options.itemTypeString or= 'comment'
    options.editable       or= no

    super options, data

    {itemTypeString} = @getOptions()
    data = @getData()

    @commentInput = new KDHitEnterInputView
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

    @commentFormWrapper = new KDView
      cssClass    : "item-add-comment-form"

    @commentFormWrapper.addSubView @commentInput

  viewAppended:->
    {editable} = @getOptions()
    unless editable
      @addSubView commenterAvatar = new AvatarStaticView
        size    :
          width : 35
          height: 35
      , KD.whoami()

    @addSubView @commentFormWrapper

    @attachListeners()

  attachListeners:->
    @commentInput.on "blur", @bound "commentInputReceivedBlur"
    @commentInput.on "focus", =>
      KD.mixpanel "Comment activity, focus"
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
        {editable} = @getOptions()
        reply = @commentInput.getValue()
        @commentInput.setValue ''
        @commentInput.resize()
        @commentInput.blur()
        @commentInput.$().blur()
        unless editable then @getDelegate().emit 'CommentSubmitted', reply
        else @getDelegate().emit 'CommentUpdated', reply

        KD.mixpanel "Comment activity, click", reply.length
      onFailMsg : "Login required to post a comment!"
      tryAgain  : yes
      groupName : @getDelegate().getData().group

class EditCommentForm extends NewCommentForm

  constructor:(options = {}, data)->
    options.editable = yes
    super options, data

    @commentFormWrapper.addSubView new KDCustomHTMLView
      cssClass  : "cancel-description"
      pistachio : "Press Esc to cancel"

    @commentInput.setValue Encoder.htmlDecode data.body
    @commentInput.on "EscapePerformed", @bound "cancel"

  cancel: ->
    @getDelegate().emit "CommentUpdateCancelled"

  viewAppended: ->
    super
    KD.utils.defer =>
      @commentInput.setFocus()
      @commentInput.resize()
