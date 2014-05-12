class CommentListViewController extends KDListViewController

  constructor: (options = {}, data) ->

    super options, data

    @_hasBackgrounActivity = no
    @startListeners()


  loadView: (mainView) ->

    { scrollView
      startWithLazyLoader
      noItemFoundWidget
    } = @getOptions()

    {windowController} = KD.singletons

    if scrollView
      mainView.addSubView @customScrollView or @scrollView
      @scrollView.addSubView @getListView()
      @showLazyLoader no  if startWithLazyLoader

      @scrollView.on 'LazyLoadThresholdReached', @bound "showLazyLoader"

    @putNoItemView()  if noItemFoundWidget

    @instantiateListItems @getListView().getData()?.replies or []

    windowController.on "ReceivedMouseUpElsewhere", @bound 'mouseUpHappened'


  instantiateListItems: (items) ->

    super items.sort (a, b) -> a.meta.createdAt - b.meta.createdAt


  startListeners: ->

    listView = @getListView()

    listView.on 'ItemWasAdded', (view, index) ->

      view.on 'CommentIsDeleted', ->
        listView.emit "CommentIsDeleted"

    listView.on "AllCommentsLinkWasClicked", (commentHeader) =>

      return if @_hasBackgrounActivity

      # some problems when logged out server doesnt responds
      @utils.wait 5000, -> listView.emit "BackgroundActivityFinished"

      {meta} = listView.getData()

      listView.emit "BackgroundActivityStarted"
      @_hasBackgrounActivity = yes
      @_removedBefore = no
      @fetchRelativeComments 10, meta.createdAt


  fetchCommentsByRange: (from, to, callback) ->

    [to, callback] = [callback, to] unless callback

    query   = {from, to}
    message = @getListView().getData()

    message.commentsByRange query, (err, comments) =>

      @getListView().emit "BackgroundActivityFinished"
      callback err, comments


  fetchAllComments: (skipCount = 3, callback = noop) ->

    listView = @getListView()
    listView.emit "BackgroundActivityStarted"

    message = @getListView().getData()
    message.restComments skipCount, (err, comments) ->
      listView.emit "BackgroundActivityFinished"
      listView.emit "AllCommentsWereAdded"
      callback err, comments


  fetchRelativeComments: (limit = 10, after, continuous = yes, sort = 1) ->

    listView = @getListView()
    message  = listView.getData()
    message.fetchRelativeComments {limit, after, sort}, (err, comments) =>

      if not @_removedBefore
        @removeAllItems()
        @_removedBefore = yes

      @instantiateListItems comments[limit - 10...], yes

      if comments.length is limit
        startTime = comments[comments.length - 1].createdAt
        @fetchRelativeComments ++limit, startTime, continuous, sort  if continuous
      else
        listView = @getListView()
        listView.emit "BackgroundActivityFinished"
        listView.emit "AllCommentsWereAdded"
        @_hasBackgrounActivity = no


  replaceAllComments: (comments) ->

    @removeAllItems()
    @instantiateListItems comments


  reply: (body, callback = noop) ->

    listView = @getListView()
    activity = listView.getData()

    listView.emit "BackgroundActivityStarted"

    KD.singleton("appManager").tell "Activity", "reply", {activity, body}, (err, reply) =>

      return KD.showError err  if err

      if not KD.getSingleton('activityController').flags?.liveUpdates
        listView.addItem reply
        listView.emit "OwnCommentHasArrived"
      else
        listView.emit "OwnCommentWasSubmitted"
      listView.emit "BackgroundActivityFinished"

    KD.mixpanel "Comment activity, success"
    KD.getSingleton("badgeController").checkBadge
      property: "comments", relType: "commenter", source: "JNewStatusUpdate", targetSelf: 1
