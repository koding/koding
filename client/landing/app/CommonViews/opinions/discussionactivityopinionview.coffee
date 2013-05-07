class DiscussionActivityOpinionView extends KDView

  constructor:(options, data)->
    super
    @setClass "activity-opinion-container opinion-container kdlistview-activity-opinions"
    @createSubViews data

  createSubViews:(data)->

    @opinionList = new KDListView
      type          : "comments"
      itemClass     : DiscussionActivityOpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList

    @getData().on 'update', =>
      opinionsData = @getData().opinions
      items = @opinionList.items
      if opinionsData?.length and items.length < 2
        opinions = opinionsData[0..1]
        for opinion in opinions
          for item in items when opinion isnt item.getData()
            @opinionList.addItem opinion


    # the snapshot opinion list gets populated with 2 items at max initially
    # it may grow in size later on, when the user populates the data object
    # through loading items in the content display. this is intentional.
    @addSubView @opinionList
    if data.opinions
      for opinion, i in data.opinions when opinion? and 'object' is typeof opinion
        @opinionList.addItem opinion unless i > 1

    @addSubView @opinionHeader = new OpinionViewHeader delegate: @opinionList, data

  viewAppended:->
    super
    if @getData().fake
      @hide()
