class ActivityListHeader extends JView
  
  constructor:->
    
    super
    
    @_newItemsCount = 0
    
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

    if KD.checkFlag "super-admin"
      @lowQualitySwitch = new KDRySwitch
        defaultValue : off
        callback     : (state) => 
          appManager.fetchStorage 'Activity', '1.0', (err, storage)->
            storage.setOption 'showLowQualityContent', state, (err)->
              console.log err if err
      appManager.fetchStorage 'Activity', '1.0', (err, storage)=>
        @lowQualitySwitch.setValue storage.getAt('bucket.showLowQualityContent') ? off
    else
      @lowQualitySwitch = new KDCustomHTMLView
    
  pistachio:(newCount)->
    "<span>Latest Activity</span>{{> @lowQualitySwitch}}{{> @showNewItemsLink}}"
    
  newActivityArrived:->
    @_newItemsCount++
    @updateShowNewItemsLink()
  
  updateShowNewItemsLink:->
    if @_newItemsCount > 0
      @showNewItemsLink.$('span').text @_newItemsCount
      @showNewItemsLink.show()
    else
      @showNewItemsLink.hide()
