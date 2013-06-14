class ActivityListHeader extends JView

  constructor:->

    super

    @appStorage = new AppStorage 'Activity', '1.0'
    @_newItemsCount = 0

    @showNewItemsLink = new KDCustomHTMLView
      cssClass    : "new-updates"
      partial     : "<span>0</span> new items. <a href='#' title='Show new activities'>Update</a>"
      click       : =>
        @updateShowNewItemsLink yes

    @showNewItemsLink.hide()

    @liveUpdateButton = new KDOnOffSwitch
      defaultValue : off
      title        : "Live Updates: "
      size         : "tiny"
      callback     : (state) =>
        @appStorage.setValue 'liveUpdates', state, =>
        @updateShowNewItemsLink()
        KD.getSingleton('activityController').flags = liveUpdates : state
        KD.getSingleton('activityController').emit "LiveStatusUpdateStateChanged", state

    KD.getSingleton('mainController').on 'AccountChanged', @bound 'decorateLiveUpdateButton'
    @decorateLiveUpdateButton()

    if KD.checkFlag "super-admin"
      @lowQualitySwitch = new KDOnOffSwitch
        defaultValue : off
        title        : "Show trolls: "
        size         : "tiny"
        callback     : (state) =>
          @appStorage.setValue 'showLowQualityContent', state, =>

      @refreshLink = new KDCustomHTMLView
        tagName  : 'a'
        cssClass : 'fr'
        partial  : 'Refresh'
        click    : (event)=>
          KD.getSingleton('activityController').emit 'Refresh'

    else
      @lowQualitySwitch = new KDCustomHTMLView
      @refreshLink      = new KDCustomHTMLView
        tagName: "span"

    @appStorage.fetchStorage (storage)=>
      state = @appStorage.getValue('liveUpdates') or off
      @liveUpdateButton.setValue state
      KD.getSingleton('activityController').flags = liveUpdates : state
      @lowQualitySwitch.setValue? @appStorage.getValue('showLowQualityContent') or off

  pistachio:(newCount)->
    "<div class='header-wrapper'><span>Latest Activity</span>{{> @lowQualitySwitch}}{{> @liveUpdateButton}} {{> @showNewItemsLink}}{{> @refreshLink}}</div>"

  newActivityArrived:->
    @_newItemsCount++
    @updateShowNewItemsLink()

  decorateLiveUpdateButton:->
    if KD.isLoggedIn() then @liveUpdateButton.show()
    else @liveUpdateButton.hide()

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

  getNewItemsCount: ->
    return @_newItemsCount
