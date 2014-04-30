class NewCommentForm extends KDView

  constructor:(options = {}, data)->

    options.type           or= "new-comment"
    options.cssClass       or= "item-add-comment-box"
    options.itemTypeString or= 'comment'
    options.editable       or= no

    super options, data

    {itemTypeString} = @getOptions()
    data = @getData()

    @input = new KDHitEnterInputView
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

    @commentFormWrapper.addSubView @input

  viewAppended:->
    {editable} = @getOptions()
    unless editable
      @addSubView commenterAvatar = new AvatarStaticView
        size    :
          width : 42
          height: 42
      , KD.whoami()

    @addSubView @commentFormWrapper

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
        {editable} = @getOptions()
        reply = @input.getValue()
        @input.setValue ''
        @input.resize()
        @input.blur()
        @input.$().blur()
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

    @input.setValue Encoder.htmlDecode data.body
    @input.on "EscapePerformed", @bound "cancel"

  cancel: ->
    @getDelegate().emit "CommentUpdateCancelled"

  viewAppended: ->
    super
    KD.utils.defer =>
      @input.setFocus()
      @input.resize()
