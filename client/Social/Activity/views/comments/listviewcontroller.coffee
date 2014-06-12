class CommentListViewController extends KDListViewController

  constructor: (options = {}, data) ->

    options.viewOptions =
      type              : 'comments'
      itemClass         : CommentListItemView
      itemOptions       :
        delegate        : this
        activity        : data

    super options, data


  instantiateListItems: (items) ->

    super items.sort (a, b) -> a.meta.createdAt - b.meta.createdAt


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
