class NewCommentForm extends KDView

  constructor: (options = {}, data) ->

    options.type       or= "new-comment"
    options.cssClass     = KD.utils.curry "item-add-comment-box", options.cssClass
    options.showAvatar  ?= yes

    super options, data

    @input          = new KDHitEnterInputView
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
      callback      : @bound "enter"

    @input.on "blur", @bound "commentInputReceivedBlur"

    @input.on "focus", =>

      KD.mixpanel "Comment activity, focus"
      @getDelegate().emit "commentInputReceivedFocus"


  submit: ->

    @emit "Submit", @input.getValue()


  enter: ->

    kallback = =>

      @submit()

      KD.mixpanel "Comment activity, click", @input.getValue().length

      @input.setValue ""
      @input.resize()
      @input.setBlur()

    KD.requireMembership
      callback  : kallback
      onFailMsg : "Login required to post a comment!"
      tryAgain  : yes
      groupName : KD.getGroup().slug


  makeCommentFieldActive: ->

    @getDelegate().emit "commentInputReceivedFocus"
    (KD.getSingleton "windowController").setKeyView @input


  otherCommentInputReceivedFocus:(instance) ->

    if instance isnt @input
      commentForm = @input.getDelegate()
      commentForm.resetCommentField() if $.trim(@input.getValue()) is ""


  commentInputReceivedBlur: ->

    @resetCommentField()  if @input.getValue() is ""


  resetCommentField: ->

    @getDelegate().emit "CommentViewShouldReset"


  viewAppended: ->

    if @getOption "showAvatar"
      @addSubView new AvatarStaticView
        size    :
          width : 42
          height: 42
      , KD.whoami()

    @addSubView @input
