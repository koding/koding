class InboxReplyForm extends NewCommentForm
  constructor:(options,data)->
    options = $.extend
      type      : "reply"
      cssClass  : "reply-to-thread-box"
    ,options
    super options,data

  viewAppended:()->
    {profile} = @getSingleton('mainController').getVisitor().currentDelegate
    @addSubView @commentInput = new KDHitEnterInputView
      type          : "textarea"
      delegate      : @
      placeholder   : "Click here to reply..."
      # autogrow      : yes
      validate      :
        rules       : 
          required  : yes 
        messages    :
          required  : "Reply field is empty..."
      callback      : @commentInputReceivedEnter

    @attachListeners()
