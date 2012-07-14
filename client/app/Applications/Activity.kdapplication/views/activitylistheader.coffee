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
      click       : => 
        @emit "UnhideHiddenNewItems"
        @_newItemsCount = 0
        @updateShowNewItemsLink()

    @showNewItemsLink.hide()
    @addSubView @showNewItemsLink
    
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
