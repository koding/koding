class ReviewListViewController extends KDListViewController
  constructor:->
    super
    @_hasBackgrounActivity = no
    @startListeners()

  instantiateListItems:(items, keepDeletedReviews = no)->

    newItems = []

    for review, i in items

      nextReview = items[i+1]

      skipReview = no
      if nextReview? and review.deletedAt
        if Date.parse(nextReview.meta.createdAt) > Date.parse(review.deletedAt)
          skipReview = yes

      if not nextReview and review.deletedAt
        skipReview = yes

      skipReview = no if keepDeletedReviews

      unless skipReview
        reviewView = @getListView().addItem review
        newItems.push reviewView

    return newItems

  startListeners:->
    listView = @getListView()

    listView.on 'ItemWasAdded', (view, index)=>
      view.on 'CommentIsDeleted', ->
        listView.emit "CommentIsDeleted"

    listView.on "AllCommentsLinkWasClicked", (reivewHeader)=>

      return if @_hasBackgrounActivity

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {meta} = listView.getData()

      listView.emit "BackgroundActivityStarted"
      @_hasBackgrounActivity = yes
      @_removedBefore = no
      @fetchRelativeReviews -1, meta.createdAt

    listView.registerListener
      KDEventTypes  : "ReviewSubmitted"
      listener      : @
      callback      : (pubInst, review)->
        model = listView.getData()
        listView.emit "BackgroundActivityStarted"
        model.review review, (err, review)=>
          # listView.emit "AllCommentsLinkWasClicked"
          if not @getSingleton('activityController').flags?.liveUpdates
            listView.addItem review
            listView.emit "OwnCommentHasArrived"
          listView.emit "BackgroundActivityFinished"

  fetchAllReviews:(skipCount=3, callback = noop)=>

    listView = @getListView()
    listView.emit "BackgroundActivityStarted"
    message = @getListView().getData()
    message.restReviews skipCount, (err, reivews)=>
      listView.emit "BackgroundActivityFinished"
      listView.emit "AllCommentsWereAdded"
      callback err, reivews

  fetchRelativeReviews:(_limit = 10, _after)=>
    listView = @getListView()
    message = @getListView().getData()
    message.fetchRelativeReviews limit:_limit, after:_after, (err, reivews)=>

      if not @_removedBefore
        @removeAllItems()
        @_removedBefore = yes

      @instantiateListItems reivews, yes

      listView = @getListView()
      listView.emit "BackgroundActivityFinished"
      listView.emit "AllCommentsWereAdded"
      @_hasBackgrounActivity = no

  replaceAllReviews:(reivews)->
    @removeAllItems()
    @instantiateListItems reivews
