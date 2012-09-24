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

    @addSubView header = new KDView
      cssClass : "show-more-discussion"

    header.addSubView @linkToContentDisplay = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "discussion-view-more"
      partial     : "No answers yet"
      attributes  :
        href      : "#"
      click :->
        # this is superfluos as long as we have the catch-all click event
        # appManager.tell "Activity", "createContentDisplay", data

    if data.repliesCount > 0
      @updateCount data.repliesCount

    @addSubView spacer = new KDCustomHTMLView
      cssClass      : "discussion-spacer"

  updateCount:(count)=>
    unless count is 0
      @linkToContentDisplay.updatePartial "View #{count} answers"
    else
      @linkToContentDisplay.updatePartial "No answers yet"

