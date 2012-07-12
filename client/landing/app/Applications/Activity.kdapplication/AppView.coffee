class ActivitySplitView extends KDSplitView

  # until mixins are here
  viewAppended : ()->
    ContentPageSplitBelowHeader::viewAppended.apply @,arguments

  toggleFirstPanel: ()-> 
    ContentPageSplitBelowHeader::toggleFirstPanel.apply @,arguments

  setRightColumnClass: ()-> 
    ContentPageSplitBelowHeader::setRightColumnClass.apply @,arguments

  _windowDidResize:()=> 
    super
    welcomeHeaderHeight = @$().siblings('h1').outerHeight()
    # updateWidgetHeight  = @$().siblings('.activity-update-widget-wrapper').outerHeight()  # split margin top

    @$().css
      marginTop : 77 # updateWidgetHeight
      height    : @parent.getHeight() - welcomeHeaderHeight - 77

class ActivityInnerNavigation extends CommonInnerNavigation
  viewAppended:()->
    
    feedController = @setListController
      type : "feed"
      subItemClass : ListGroupFeedItem
    , @feedMenuData
    @addSubView feedController.getView()
    feedController.selectItem feedController.getItemsOrdered()[0]

    filterController = @setListController
      type : "showme"
      subItemClass : ListGroupShowMeItem
    , @showMenuData
    @addSubView filterController.getView()
    filterController.selectItem filterController.getItemsOrdered()[0]
    
    @addSubView helpBox = new HelpBox
      subtitle    : "About Your Activity Feed" 
      tooltip     :
        title     : "<p class=\"bigtwipsy\">The Activity feed displays posts from the people and topics you follow on Koding. It's also the central place for sharing updates, code, links, discussions and questions with the community. </p>"
        placement : "above"
        offset    : 0
        delayIn   : 300
        html      : yes
        animate   : yes

  feedMenuData :
    title : "FEED"
    items : [
        # { title : "Followed", type : "follow" }
        { title : "Public",   type : "public" }
      ]

  showMenuData :
    title : "SHOW ME"
    items : [
        { title : "Everything" }
        { title : "Status Updates",   type : "CStatusActivity" }
        { title : "Code Snippets",    type : "CCodeSnipActivity" }
        { title : "Q&A",              type : "qa",         disabledForBeta : yes }
        { title : "Discussions",      type : "discussion", disabledForBeta : yes }
        { title : "Links",            type : "link",       disabledForBeta : yes }
        # { title : "Code Shares",      type : "codeshare", disabledForBeta : yes }
        # { title : "Commits",          type : "commit", disabledForBeta : yes }
        # { title : "Projects",         type : "newproject", disabledForBeta : yes }
      ]


class ListGroupFeedItem extends CommonInnerNavigationListItem

class ListGroupShowMeItem extends ListGroupFeedItem
  click: (event) =>
    unless @getData().disabledForBeta
      @_navigateTo @getData().type
    else
      new KDNotificationView
        title : "Coming Soon!"
        duration : 1000

      
  _navigateTo: (type) ->
    @handleEvent type: 'ActivityNavigation', show: type

class ActivityListHeader extends KDView
  constructor:->
    super
    @_newItemsCount = 0
    
  viewAppended:->
    @setPartial @partial 0

    @showNewItemsLink = new KDCustomHTMLView
      tagName     : "div"
      partial     : "<span>0</span> new items. <a href='#'>Update</a>"
      attributes  :
        href      : "#"
        title     : "Show new activities"
    @showNewItemsLink.hide()
    @addSubView @showNewItemsLink
    
    @listenTo 
      KDEventTypes : "click"
      listenedToInstance : @showNewItemsLink
      callback : => @showNewItemsInList()

  partial:(newCount)->
    "<p>Latest Activity</p>"
    
  newActivityArrived:->
    @_newItemsCount++
    @updateShowNewItemsLink()
  
  updateShowNewItemsLink:->
    if @_newItemsCount > 0
      @showNewItemsLink.$('span').text @_newItemsCount
      @showNewItemsLink.show()
    else
      @showNewItemsLink.hide()
      
  showNewItemsInList:->
    @propagateEvent KDEventType : "UnhideHiddenNewItems"
    @_newItemsCount = 0
    @updateShowNewItemsLink()
