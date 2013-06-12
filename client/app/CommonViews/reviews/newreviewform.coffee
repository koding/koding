class NewReviewForm extends NewCommentForm

  constructor:(options, data)->

    options.itemTypeString = 'review'
    options.cssClass       = 'item-add-review-box'

    super options,data

  commentInputReceivedEnter:(instance,event)->
    KD.requireMembership
      callback : =>
        review = @commentInput.getValue()
        @commentInput.setValue ''
        @commentInput.blur()
        @commentInput.$().blur()
        @getDelegate().emit 'ReviewSubmitted', review
      onFailMsg : "Login required to post a review!"
      tryAgain  : yes
      groupName : @getDelegate().getData().group