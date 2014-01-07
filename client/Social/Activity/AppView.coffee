class ActivityAppView extends KDScrollView


  headerHeight = 0


  constructor:(options = {}, data)->

    options.cssClass   = "content-page activity"
    options.domId      = "content-page-activity"

    super options, data

    # FIXME: disable live updates - SY
    @appStorage = KD.getSingleton("appStorageController").storage 'Activity', '1.0.1'
    @appStorage.setValue 'liveUpdates', off


  viewAppended:->

    {entryPoint}      = KD.config
    windowController  = KD.singleton 'windowController'

    @feedWrapper      = new ActivityListContainer
    @inputWidget      = new ActivityInputWidget

    @referalBox       = new ReferalBox
    @topicsBox        = new ActiveTopics
    @usersBox         = new ActiveUsers
    @tickerBox        = new ActivityTicker

    @mainBlock        = new KDCustomHTMLView tagName : "main" #"activity-left-block"
    @sideBlock        = new KDCustomHTMLView tagName : "aside"   #"activity-right-block"

    @mainController   = KD.getSingleton("mainController")
    @mainController.on "AccountChanged", @bound "decorate"
    @mainController.on "JoinedGroup", => @inputWidget.show()

    @feedWrapper.ready =>
      @activityHeader  = @feedWrapper.controller.activityHeader
      {@filterWarning} = @feedWrapper
      {feedFilterNav}  = @activityHeader
      feedFilterNav.unsetClass 'multiple-choice on-off'

    @tickerBox.once 'viewAppended', =>
      topOffset = @tickerBox.$().position().top
      windowController.on 'ScrollHappened', =>
        if document.body.scrollTop > topOffset
        then @tickerBox.setClass 'fixed'
        else @tickerBox.unsetClass 'fixed'

    @decorate()

    @setLazyLoader 200

    @addSubView @mainBlock
    @addSubView @sideBlock

    @mainBlock.addSubView @inputWidget
    @mainBlock.addSubView @feedWrapper

    @sideBlock.addSubView @referalBox  if KD.isLoggedIn()
    @sideBlock.addSubView @topicsBox
    @sideBlock.addSubView @usersBox
    @sideBlock.addSubView @tickerBox

  decorate:->
    @unsetClass "guest"
    {entryPoint, roles} = KD.config
    @setClass "guest" unless "member" in roles
    # if KD.isLoggedIn()
    @setClass 'loggedin'
    if entryPoint?.type is 'group' and 'member' not in roles
    then @inputWidget.hide()
    else @inputWidget.show()
    # else
    #   @unsetClass 'loggedin'
    #   @inputWidget.hide()
    @_windowDidResize()

  setTopicTag: (slug) ->
    return  if not slug or slug is ""
    KD.remote.api.JTag.one {slug}, null, (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]

  unsetTopicTag: ->
    @inputWidget.input.setDefaultTokens tags: []


class ActivityListContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = "activity-content feeder-tabs"

    super options, data

    @controller = new ActivityListController
      delegate          : @
      itemClass         : ActivityListItemView
      showHeader        : yes
      # wrapper           : no
      # scrollView        : no

    @listWrapper = @controller.getView()
    @filterWarning = new FilterWarning

    @controller.ready => @emit "ready"

  setSize:(newHeight)->
    # @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  pistachio:->
    """
      {{> @filterWarning}}
      {{> @listWrapper}}
    """

class FilterWarning extends JView

  constructor:->
    super cssClass : 'filter-warning hidden'

    @warning   = new KDCustomHTMLView
    @goBack    = new KDButtonView
      cssClass : 'goback-button'
      # todo - add group context here!
      callback : => KD.singletons.router.handleRoute '/Activity'

  pistachio:->
    """
    {{> @warning}}
    {{> @goBack}}
    """

  showWarning:({text, type})->
    partialText = switch type
      when "search" then "Results for <strong>\"#{text}\"</strong>"
      else "You are now looking at activities tagged with <strong>##{text}</strong>"

    @warning.updatePartial "#{partialText}"

    @show()

class ReferalBox extends JView


  constructor: (options = {}, data) ->

    options.cssClass = 'referal-box'

    super options, data

    @close = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        @destroy()
      cssClass   : 'hide'
      partial    : 'hide this'

    @modalLink = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      click      : @bound 'showReferrerModal'
      partial    : 'show more...'

    @progressBar = new KDProgressBarView
      title       : '0 GB / 16 GB'
      determinate : yes



  viewAppended:->

    super

    @progressBar.updateBar 0
    vmc = KD.getSingleton "vmController"
    vmc.fetchDefaultVmName (name) =>
      vmc.fetchDiskUsage name, (usage) =>
        return  unless usage.max

        usagePercent = usage.max / (16*1e9) * 90
        used         = KD.utils.formatBytesToHumanReadable usage.max

        @progressBar.updateBar usagePercent + 10, null, "#{used} / 16 GB"


  showReferrerModal: (event)->
    KD.utils.stopDOMEvent event

    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showReferrerModal",
      # linkView    : getYourReferrerCode
      top         : 50
      left        : 35
      arrowMargin : 110


  pistachio:->
    """
    {{> @close}}
    <figure></figure>
    <p>
    Invite your friends and get 250mb
    up to <strong>16GB</strong> for free! {{> @modalLink}}
    </p>
    {{> @progressBar}}
    """

