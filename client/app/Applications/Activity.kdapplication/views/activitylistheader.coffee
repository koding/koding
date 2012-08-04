class ActivityListHeader extends JView

  constructor:->

    super

    @appStorage = new AppStorage 'Activity', '1.0'
    @_newItemsCount = 0

    @showNewItemsLink = new KDCustomHTMLView
      tagName     : "div"
      partial     : "<span>0</span> new items. <a href='#'>Update</a>"
      attributes  :
        href      : "#"
        title     : "Show new activities"
      click       : =>
        @updateShowNewItemsLink yes

    @showNewItemsLink.hide()

    @liveUpdateButton = new KDRySwitch
      defaultValue : off
      title        : "Live Updates: "
      size         : "tiny"
      callback     : (state) =>
        @appStorage.setValue 'liveUpdates', state, =>
        @updateShowNewItemsLink()

    if KD.checkFlag "super-admin"
      @lowQualitySwitch = new KDRySwitch
        defaultValue : off
        title        : "Show trolls: "
        size         : "tiny"
        callback     : (state) =>
          @appStorage.setValue 'showLowQualityContent', state, =>
    else
      @lowQualitySwitch = new KDCustomHTMLView

    @appStorage.fetchStorage (storage)=>
      @liveUpdateButton.setValue @appStorage.getValue 'liveUpdates', off
      @lowQualitySwitch.setValue? @appStorage.getValue 'showLowQualityContent', off

  pistachio:(newCount)->
    "<span>Latest Activity</span>{{> @lowQualitySwitch}}{{> @liveUpdateButton}}{{> @showNewItemsLink}}"

  newActivityArrived:->
    @_newItemsCount++
    @updateShowNewItemsLink()

  updateShowNewItemsLink:(showNewItems = no)->
    if @_newItemsCount > 0
      if @liveUpdateButton.getValue() is yes or showNewItems is yes
        @emit "UnhideHiddenNewItems"
        @_newItemsCount = 0
        @showNewItemsLink.hide()
      else
        @showNewItemsLink.$('span').text @_newItemsCount
        @showNewItemsLink.show()
    else
      @showNewItemsLink.hide()
