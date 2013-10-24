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

    @offset = 3
    listView.on "AllCommentsLinkWasClicked", (@reviewHeader)=>

      return if @_hasBackgrounActivity

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {meta} = listView.getData()

      listView.emit "BackgroundActivityStarted"
      @_hasBackgrounActivity = yes
      @_removedBefore = no
      loadComments = 10
      @fetchRelativeReviews @offset, loadComments, meta.createdAt
      @offset += loadComments

    listView.on "ReviewSubmitted", (review)->
      model = listView.getData()
      listView.emit "BackgroundActivityStarted"
      model.review review, (err, review)=>
        # listView.emit "AllCommentsLinkWasClicked"
        if not KD.getSingleton('activityController').flags?.liveUpdates
          listView.addItem review
          listView.emit "OwnCommentHasArrived"
        listView.emit "BackgroundActivityFinished"

  fetchAllReviews:(skipCount=3, callback = noop)->

    listView = @getListView()
    listView.emit "BackgroundActivityStarted"
    message = @getListView().getData()
    message.restReviews skipCount, (err, reivews)=>
      listView.emit "BackgroundActivityFinished"
      # listView.emit "AllCommentsWereAdded"
      callback err, reivews

  fetchRelativeReviews:(_offset = 0, _limit = 10, _after)->
    listView = @getListView()
    message = @getListView().getData()
    listView.setOption 'lastToFirst', no
    message.fetchRelativeReviews offset: _offset, limit:_limit, after:_after, (err, reivews)=>

      if not @_removedBefore
        # @removeAllItems()
        @_removedBefore = yes

      @instantiateListItems reivews, yes

      listView = @getListView()
      listView.emit "BackgroundActivityFinished"

      {allItemsLink} = @reviewHeader
      {repliesCount} = allItemsLink.getData()
      allItemsLink.setData
        repliesCount: repliesCount-_limit
      allItemsLink.render()

      if _offset + _limit >= @reviewHeader.oldCount
        listView.emit "AllCommentsWereAdded"

      @_hasBackgrounActivity = no
      listView.setOption 'lastToFirst', yes

  replaceAllReviews:(reivews)->
    @removeAllItems()
    @instantiateListItems reivews
