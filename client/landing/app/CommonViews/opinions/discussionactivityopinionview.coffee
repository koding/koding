class DiscussionActivityOpinionView extends KDView

  constructor:(options, data)->

    super

    @setClass "activity-opinion-container opinion-container"
    @createSubViews data

  createSubViews:(data)->
    @opinionList = new KDListView
      type          : "opinions"
      subItemClass  : DiscussionActivityOpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList

    @addSubView @opinionList
    if data.replies
      for reply, i in data.replies when reply? and 'object' is typeof reply
        @opinionList.addItem reply
