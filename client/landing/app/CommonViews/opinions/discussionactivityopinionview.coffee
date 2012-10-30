class DiscussionActivityOpinionView extends KDView

  constructor:(options, data)->
    super
    @setClass "activity-opinion-container opinion-container kdlistview-activity-opinions"
    @createSubViews data

  createSubViews:(data)->

    @opinionList = new KDListView
      type          : "comments"
      itemClass  : DiscussionActivityOpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList

    # the snapshot opinion list gets populated with 2 items at max initially
    # it may grow in size later on, when the user populates the data object
    # through loading items in the content display. this is intentional.
    @addSubView @opinionList
    if data.opinions
      for opinion, i in data.opinions when opinion? and 'object' is typeof opinion
        @opinionList.addItem opinion unless i > 1

    @addSubView @opinionHeader = new OpinionViewHeader delegate: @opinionList, data
