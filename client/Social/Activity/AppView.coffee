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
        # sanity check
        topOffset = @tickerBox.$().position().top  if topOffset < 200
        if document.documentElement.scrollTop > topOffset
        then @tickerBox.setClass 'fixed'
        else @tickerBox.unsetClass 'fixed'

    @decorate()

    @setLazyLoader 200

    @addSubView @mainBlock
    @addSubView @sideBlock

    topWidgetPlaceholder  = new KDCustomHTMLView
    leftWidgetPlaceholder = new KDCustomHTMLView

    @mainBlock.addSubView topWidgetPlaceholder
    @mainBlock.addSubView @inputWidget
    @mainBlock.addSubView @feedWrapper

    @sideBlock.addSubView @referalBox  if KD.isLoggedIn()
    @sideBlock.addSubView leftWidgetPlaceholder
    @sideBlock.addSubView @topicsBox
    @sideBlock.addSubView @usersBox
    @sideBlock.addSubView @tickerBox

    KD.getSingleton("widgetController").showWidgets [
      { view: topWidgetPlaceholder,  key: "ActivityTop"  }
      { view: leftWidgetPlaceholder, key: "ActivityLeft" }
    ]

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

    @modalLink = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      click      : @bound 'showReferrerModal'
      partial    : 'show more...'

    @redeemPointsModal = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      click      : (e)=>
        @showRedeemReferralPointModal()
        e.stopPropagation()

    KD.getSingleton("vmController").on "ReferralCountUpdated", =>
      @updateReferralCountPartial()
      @updateSizeBar()

    @updateReferralCountPartial()

    @progressBar = new KDProgressBarView
      title       : '0 GB / 16 GB'
      determinate : yes

    @showMore = new KDCustomHTMLView
      tagName : "a"
      partial : "show more..."

  click : ->
    @showReferrerModal()

  showRedeemReferralPointModal:->
    KD.mixpanel "Referer Redeem Point modal, click"

    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showRedeemReferralPointModal"

  updateReferralCountPartial:->
    KD.remote.api.JReferral.fetchRedeemableReferrals { type: "disk" }, (err, referals)=>
      if referals and referals.length > 0
        text =  """
          Congrats, your bonus is waiting for you!
          You have #{referals.length} referrals!
        """
        @redeemPointsModal.updatePartial text


  viewAppended:->

    super
    @updateSizeBar()

  updateSizeBar:->
    @progressBar.updateBar 0
    vmc = KD.getSingleton "vmController"
    vmc.fetchDefaultVmName (name) =>
      vmc.fetchVmInfo name, (err , vmInfo) =>
        return  if err or not vmInfo?.diskSizeInMB
        max          = vmInfo?.diskSizeInMB or 4096
        max          = max*1024*1024
        usagePercent = max / (16*1e9) * 90
        used         = KD.utils.formatBytesToHumanReadable max

        @progressBar.updateBar usagePercent + 10, null, "#{used} / 16 GB"


  showReferrerModal: (event)->
    KD.utils.stopDOMEvent event
    KD.mixpanel "Referer modal, click"

    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showReferrerModal"

  pistachio:->
    """
    <span class="title">Get free disk space!</span>
    <p>
      Invite your friends and get 250MB up to 16GB for free!
      {{> @showMore}}
      {{> @redeemPointsModal}}
    </p>
    {{> @progressBar}}
    """

