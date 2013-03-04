class NewReviewForm extends NewCommentForm

  constructor:(options, data)->

    options.itemTypeString = 'review'
    options.cssClass       = 'item-add-review-box'

    super options,data

  commentInputReceivedEnter:(instance,event)=>
    if KD.isLoggedIn()
      review = @commentInput.getValue()
      @commentInput.setValue ''
      @commentInput.blur()
      @commentInput.$().blur()
      @getDelegate().emit 'ReviewSubmitted', review
    else
      new KDNotificationView
        type      : "growl"
        title     : "please login to post a review!"
        duration  : 1500
