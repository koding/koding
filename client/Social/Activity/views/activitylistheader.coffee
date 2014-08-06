class ActivityListHeader extends JView

  __count = 0


  constructor:->

    super

    mainController = KD.getSingleton "mainController"

    @appStorage = new AppStorage 'Activity', '1.0'
    @_newItemsCount = 0

    @showNewItemsInTitle = no

    @showNewItemsLink = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      cssClass   : 'new-updates'
      tooltip    :
        title    : 'Click to see the new posts!'
      partial    : '0'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        @updateShowNewItemsLink yes

    @showNewItemsLink.hide()

    @liveUpdateToggle = new KDToggleButton
      style           : "live-updates"
      iconOnly        : yes
      defaultState    : "lazy"
      tooltip         :
        title         : 'Live updates'
      states          : [
        title         : "lazy"
        iconClass     : "broken"
        callback      : (callback)=>
          @updateShowNewItemsLink yes
          @toggleLiveUpdates yes, callback
      ,
        title         : "live"
        iconClass     : "live"
        callback      : (callback)=> @toggleLiveUpdates no, callback
      ]

    @feedFilterNav = new KDMultipleChoice
      labels       : ["Public", "Followed"]
      titles       : ["Click to see the posts on public feed", "Click to see only the posts you follow"]
      cssClass     : 'feed-type-selection'
      defaultValue : "Public"
      callback     : (selection)->
        @emit 'FilterChanged', selection


    if KD.checkFlag "super-admin"
      @lowQualitySwitch = new KDOnOffSwitch
        cssClass     : 'hidden'
        defaultValue : off
        inputLabel   : "Show trolls: "
        size         : "tiny"
        callback     : (state) =>
          @appStorage.setValue 'showLowQualityContent', state, =>
          KD.getSingleton('activityController').flags.showExempt = state
          KD.getSingleton('activityController').emit 'Refresh'

    else
      @lowQualitySwitch = new KDCustomHTMLView

    @appStorage.fetchStorage (storage)=>
      state             = @appStorage.getValue("liveUpdates") or off
      lowQualityContent = @appStorage.getValue "showLowQualityContent"
      {flags}           = KD.getSingleton "activityController"
      flags.liveUpdates = state
      flags.showExempt  = lowQualityContent or off
      @liveUpdateToggle.tooltip.setTitle "Live updates #{if state then 'on' else 'off'}"
      @liveUpdateToggle.setState if state then 'live' else 'lazy'
      @lowQualitySwitch.setValue? lowQualityContent or off

  toggleLiveUpdates:(state, callback)->
    @_togglePollForUpdates state
    @appStorage.setValue 'liveUpdates', state, ->
    @updateShowNewItemsLink()
    activityController = KD.getSingleton('activityController')
    @liveUpdateToggle.tooltip.setTitle "Live updates #{if state then 'on' else 'off'}"
    activityController.flags = liveUpdates : state
    activityController.emit "LiveStatusUpdateStateChanged", state
    callback()

  _checkForUpdates: do (lastTs = null, lastCount = null, alreadyWarned = no) ->
    itFailed = ->
      unless alreadyWarned
        console.warn 'seems like live updates stopped coming'
        KD.logToExternal 'realtime failure detected'
        alreadyWarned = yes
    ->
      return console.error "unimplemented fature"
      # KD.remote.api.CActivity.fetchLastActivityTimestamp (err, ts) =>
      #   itFailed()  if ts? and lastTs isnt ts and lastCount is __count
      #   lastTs = ts; lastCount = __count

  _togglePollForUpdates: do (i = null) -> (state) ->
    if state then i = setInterval (@bound '_checkForUpdates'), 60 * 1000 # 1 minute
    else clearInterval i

  pistachio:(newCount)->
    if KD.isLoggedIn()
      "{{> @lowQualitySwitch}} {{> @showNewItemsLink}} {{> @liveUpdateToggle}} {{> @feedFilterNav}}"
    else ""

  newActivityArrived:->
    __count++
    @_newItemsCount++
    @updateShowNewItemsLink()

  updateShowNewItemsLink:(showNewItems = no)->
    if @_newItemsCount > 0
      if @liveUpdateToggle.getState().title is 'live' or showNewItems is yes
        @emit "UnhideHiddenNewItems"
        @_newItemsCount = 0
        @showNewItemsLink.hide()
      else
        @showNewItemsLink.updatePartial "#{@_newItemsCount} new item#{if @_newItemsCount > 1 then 's' else ''}"
        @showNewItemsLink.show()
    else
      @showNewItemsLink.hide()

  getNewItemsCount: ->
    return @_newItemsCount
