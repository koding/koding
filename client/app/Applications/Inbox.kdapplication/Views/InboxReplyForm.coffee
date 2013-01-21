class InboxReplyForm extends NewCommentForm
  constructor:(options,data)->
    options = $.extend
      type      : "reply"
      cssClass  : "reply-to-thread-box"
    ,options
    super options,data

  viewAppended:()->
    {profile} = KD.whoami()
    @addSubView @commentInput = new KDInputView
      type          : "textarea"
      placeholder   : "Click here to reply..."
      # autogrow      : yes
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Reply field is empty..."

    @addSubView @sendButton = new KDButtonView
      title     : "Send"
      style     : "clean-gray inside-button"
      callback  : @commentInputReceivedEnter

    @attachListeners()
