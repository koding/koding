class AvatarPopup extends KDView

  constructor:->
    super

    @sidebar = @getDelegate()
    @sidebar.on "NavigationPanelWillCollapse", => @hide()

    @on 'ReceivedClickElsewhere', => @hide()

    mainController = KD.getSingleton("mainController")
    mainController.on "accountChanged.to.loggedIn", @bound 'accountChanged'

    @_windowController = KD.getSingleton('windowController')
    @listenWindowResize()

  show:->
    @utils.killWait @loaderTimeout
    @_windowDidResize()
    @_windowController.addLayer this
    KD.getSingleton('mainController').emit "AvatarPopupIsActive"
    @setClass "active"
    return this

  hide:->
    KD.getSingleton('mainController').emit "AvatarPopupIsInactive"
    @unsetClass "active"
    return this

  viewAppended:->

    @setClass "avatararea-popup"
    @addSubView @avatarPopupTab = new KDView cssClass : 'tab', partial : '<span class="avatararea-popup-close"></span>'
    @setPopupListener()

    @addSubView @avatarPopupContent = new KDView cssClass : 'content hidden'
    @addSubView @notLoggedInWarning = new KDView
      height   : "auto"
      cssClass : "content sublink"
      partial  : @notLoggedInMessage or "Login required."

    @accountChanged()  if KD.isLoggedIn()

  setPopupListener:->
    @avatarPopupTab.on 'click', (event)=> @hide()

  _windowDidResize:->
    if @listController
      {scrollView}    = @listController
      windowHeight    = $(window).height()
      avatarTopOffset = @$().offset().top
      @listController.scrollView.$().css maxHeight : windowHeight - avatarTopOffset - 80

  accountChanged:->
    @notLoggedInWarning.hide()
    @avatarPopupContent.show()
