class DiscussionActivityOpinionView extends KDView

  constructor:(options, data)->

    super

    @setClass "activity-opinion-container opinion-container kdlistview-activity-opinions"

    @addSubView header = new KDView
      cssClass : "show-more-comments in"

    header.addSubView linkToContentDisplay = new KDCustomHTMLView
      tagName : "a"
      partial : "Show all "+data.repliesCount+" replies to this discussion"
      attributes:
        href: "#"
      click :->
        appManager.tell "Activity", "createContentDisplay", data

    @createSubViews data

  createSubViews:(data)->
    @opinionList = new KDListView
      type          : "comments"
      subItemClass  : DiscussionActivityOpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList

    @addSubView @opinionList
    if data.replies
      for reply, i in data.replies when reply? and 'object' is typeof reply
        @opinionList.addItem reply
