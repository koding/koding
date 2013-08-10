class ActivityListHeader extends JView

  __count = 0


  constructor:->

    super

    mainController = KD.getSingleton "mainController"

    @appStorage = new AppStorage 'Activity', '1.0'
    @_newItemsCount = 0

    @showNewItemsInTitle = no

    @showNewItemsLink = new KDCustomHTMLView
      cssClass    : "new-updates"
      partial     : "<span>0</span> new items. <a href='#' title='Show new activities'>Update</a>"
      click       : => @updateShowNewItemsLink yes

    @headerTitle = new KDCustomHTMLView
      partial     : "Latest Activity"
      tagName: "span"

    @showNewItemsLink.hide()

    @liveUpdateButton = new KDOnOffSwitch
      defaultValue : off
      title        : "Live Updates: "
      size         : "tiny"
      callback     : (state) =>
        @_togglePollForUpdates state
        @appStorage.setValue 'liveUpdates', state, ->
        @updateShowNewItemsLink()
        KD.getSingleton('activityController').flags = liveUpdates : state
        KD.getSingleton('activityController').emit "LiveStatusUpdateStateChanged", state


    mainController.on 'AccountChanged', => @decorateLiveUpdateButton()

    @decorateLiveUpdateButton()

    if KD.checkFlag "super-admin"
      @lowQualitySwitch = new KDOnOffSwitch
        defaultValue : off
        title        : "Show trolls: "
        size         : "tiny"
        callback     : (state) =>
          @appStorage.setValue 'showLowQualityContent', state, =>
          KD.getSingleton('activityController').flags.showExempt = state
          KD.getSingleton('activityController').emit 'Refresh'

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
      state             = @appStorage.getValue("liveUpdates") or off
      lowQualityContent = @appStorage.getValue "showLowQualityContent"
      {flags}           = KD.getSingleton "activityController"
      flags.liveUpdates = state
      flags.showExempt  = lowQualityContent or off
      @liveUpdateButton.setValue state
      @lowQualitySwitch.setValue? lowQualityContent or off

  _checkForUpdates: do (lastTs = null, lastCount = null, alreadyWarned = no) ->
    itFailed = ->
      unless alreadyWarned
        console.warn 'seems like live updates stopped coming'
        KD.logToExternal 'realtime failure detected'
        alreadyWarned = yes
    ->
      KD.remote.api.CActivity.fetchLastActivityTimestamp (err, ts) =>
        itFailed()  if ts? and lastTs isnt ts and lastCount is __count
        lastTs = ts; lastCount = __count

  _togglePollForUpdates: do (i = null) -> (state) ->
    if state then i = setInterval (@bound '_checkForUpdates'), 60 * 1000 # 1 minute
    else clearInterval i

  pistachio:(newCount)->
    "<div class='header-wrapper'>{{> @headerTitle}} {{> @lowQualitySwitch}} {{> @liveUpdateButton}} {{> @showNewItemsLink}}{{> @refreshLink}}</div>"

  newActivityArrived:->
    __count++
    @_newItemsCount++
    @updateShowNewItemsLink()

  decorateLiveUpdateButton:->
    @liveUpdateButton.show()

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
