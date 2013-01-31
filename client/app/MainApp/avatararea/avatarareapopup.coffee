class AvatarPopup extends KDView
  constructor:->
    super
    @sidebar = @getDelegate()

    @sidebar.on "NavigationPanelWillCollapse", => @hide()

    @on 'ReceivedClickElsewhere', => @hide()

    @_windowController = @getSingleton('windowController')
    @listenWindowResize()

  show:->
    @utils.killWait @loaderTimeout
    @_windowDidResize()
    @_windowController.addLayer @
    @getSingleton('mainController').emit "AvatarPopupIsActive"
    @setClass "active"
    @

  hide:->
    @getSingleton('mainController').emit "AvatarPopupIsInactive"
    @unsetClass "active"
    @

  viewAppended:->
    @setClass "avatararea-popup"
    @addSubView @avatarPopupTab = new KDView cssClass : 'tab', partial : '<span class="avatararea-popup-close"></span>'
    @setPopupListener()
    @addSubView @avatarPopupContent = new KDView cssClass : 'content'

  setPopupListener:->
    @avatarPopupTab.on 'click', (event)=>
      @hide()

  _windowDidResize:=>
    if @listController
      {scrollView}    = @listController
      windowHeight    = $(window).height()
      avatarTopOffset = @$().offset().top
      @listController.scrollView.$().css maxHeight : windowHeight - avatarTopOffset - 50

