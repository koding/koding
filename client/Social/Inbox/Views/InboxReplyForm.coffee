class InboxReplyForm extends CommentInputForm

  constructor: (options = {}, data) ->

    options.type     = "reply"
    options.cssClass = KD.utils.curry "reply-to-thread-box", options.cssClass

    super options, data


  viewAppended: ->

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
      callback  : @bound "commentInputReceivedEnter"

    @attachListeners()
