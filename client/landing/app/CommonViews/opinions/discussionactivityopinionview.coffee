class DiscussionActivityOpinionView extends KDView

  constructor:(options, data)->
    super
    @setClass "activity-opinion-container opinion-container kdlistview-activity-opinions"
    @createSubViews data

  createSubViews:(data)->

    @opinionList = new KDListView
      type          : "comments"
      subItemClass  : DiscussionActivityOpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList

    @addSubView @opinionList
    if data.opinions
      for opinion, i in data.opinions when opinion? and 'object' is typeof opinion
        @opinionList.addItem opinion unless i > 1

    @addSubView @opinionHeader = new OpinionViewHeader delegate: @opinionList, data