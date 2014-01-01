class ContentDisplayControllerMember extends KDViewController

  constructor:(options={}, data)->

    options = $.extend
      view : mainView = new KDView
        cssClass : 'member content-display'
        type     : 'profile'
    , options
    super options, data

  loadView:(mainView)->
    member = @getData()
    {lazy} = mainView

    mainView.once 'KDObjectWillBeDestroyed', ->
      KD.singleton('appManager').tell 'Activity', 'resetProfileLastTo'

    # FIX THIS GG

    # @updateWidget = new ActivityUpdateWidget
    #   cssClass: 'activity-update-widget-wrapper-folded'

    # @updateWidgetController = new ActivityUpdateWidgetController
    #   view : @updateWidget

    # mainView.addSubView @updateWidget
    # cdc = KD.singleton('display')
    # if not cdc._updateController
    #   cdc._updateController = {}
    #   cdc._updateController.updateWidget = new ActivityUpdateWidget
    #     cssClass: 'activity-update-widget-wrapper-folded'

    #   cdc._updateController.updateWidgetController = new ActivityUpdateWidgetController
    #     view : cdc._updateController.updateWidget

    # mainView.addSubView cdc._updateController.updateWidget

    @addProfileView member

    if lazy
      viewClass = if KD.isLoggedIn() then KDCustomHTMLView else HomeLoginBar
      mainView.addSubView @homeLoginBar = new viewClass
        domId : "home-login-bar"
      @homeLoginBar.hide()  if KD.isLoggedIn()

    @addActivityView member

  addProfileView:(member)->
    options      =
      cssClass   : "profilearea clearfix"
      delegate   : @getView()

    if KD.isMine member
      options.cssClass = KD.utils.curry "own-profile", options.cssClass
    else
      options.bind = "mouseenter" unless KD.isMine member

    return @getView().addSubView memberProfile = new ProfileView options, member

  # mouseEnterOnFeed:->
  #
  #   clearTimeout @intentTimer
  #   @intentTimer = setTimeout =>
  #     @getView().$('.profilearea').css "overflow", "hidden"
  #     @getView().setClass "small-header"
  #     @utils.wait 300,=>
  #       KD.getSingleton('windowController').notifyWindowResizeListeners()
  #   , 500
  #
  # mouseEnterOnHeader:->
  #
  #   clearTimeout @intentTimer
  #   @intentTimer = setTimeout =>
  #     @getView().unsetClass "small-header"
  #     @utils.wait 300,=>
  #       KD.getSingleton('windowController').notifyWindowResizeListeners()
  #       @getView().$('.profilearea').css "overflow", "visible"
  #   , 500

  addActivityView:(account)->
    @getView().$('div.lazy').remove()
    windowController = KD.getSingleton('windowController')

    KD.getSingleton("appManager").tell 'Activity', 'feederBridge', {
      itemClass             : ActivityListItemView
      listControllerClass   : MemberActivityListController
      listCssClass          : "activity-related"
      limitPerPage          : 8
      useHeaderNav          : yes
      delegate              : @getDelegate()
      creator               : account
      filter                :
        statuses            :
          title             : "Status Updates"
          noItemFoundText   : "#{KD.utils.getFullnameFromAccount account} has not shared any posts yet."
          dataSource        : (selector, options = {}, callback)=>
            options.originId = account.getId()
            KD.getSingleton("appManager").tell 'Activity', 'fetchActivitiesProfilePage', options, callback
      sort                  :
        'modifiedAt'        :
          title             : "Latest activity"
          direction         : -1
    }, (controller)=>
      @feedController = controller
      @getView().addSubView controller.getView()
      @getView().setCss minHeight : windowController.winHeight
      @emit 'ready'

class MemberActivityListController extends ActivityListController
  addItem: (activity, index, animation)->
    if activity.originId is @getOptions().creator.getId()
      super activity, index, animation
