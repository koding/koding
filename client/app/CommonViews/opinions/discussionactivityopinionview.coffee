class DiscussionActivityOpinionView extends KDView

  constructor:(options, data)->
    super
    @setClass "activity-opinion-container opinion-container kdlistview-activity-opinions"
    data.watch "repliesCount",(count)->
      log "changed!"
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

    if data.repliesCount > 0
      header.addSubView linkToContentDisplay = new KDCustomHTMLView
        tagName     : "a"
        cssClass    : "discussion-view-more"
        partial     : "View "+data.repliesCount+" answers"
        attributes  :
          href      : "#"
        click :->
          # appManager.tell "Activity", "createContentDisplay", data

    @addSubView spacer = new KDCustomHTMLView
      cssClass      : "discussion-spacer"
