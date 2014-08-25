class CommentListViewController extends KDListViewController

  constructor: (options = {}, data) ->

    options.viewOptions or=
      type                : 'comments'
      dataPath            : 'id'
      itemClass           : CommentListItemView
      itemOptions         :
        activity          : data

    super options, data

    commentView = @getDelegate()

    @getListView().on 'ItemWasAdded', (item) ->
      commentView.forwardEvent item, 'MentionStarted'
      commentView.forwardEvent item, 'MentionHappened'
      commentView.forwardEvent item, 'MouseEnterHappenedOnMention'
      commentView.forwardEvent item, 'MouseLeaveHappenedOnMention'


  instantiateListItems: (items) ->

    super items.sort (a, b) -> a.createdAt - b.createdAt


  addItem: (item, index) ->

    super item, index


  loadView: (mainView) ->

    super mainView

    {replies} = @getData()
    @instantiateListItems replies  if replies.length


  setScrollView: (mainView) ->

    mainView.addSubView @customScrollView or @scrollView
    @scrollView.addSubView @getListView()
    @showLazyLoader no  if @getOption 'startWithLazyLoader'

    @scrollView.on 'LazyLoadThresholdReached', @bound 'showLazyLoader'
