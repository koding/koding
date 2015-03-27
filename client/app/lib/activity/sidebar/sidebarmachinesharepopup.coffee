kd = require 'kd'
KDModalView = kd.ModalView
KDCustomHTMLView = kd.CustomHTMLView
KDView = kd.View
KDButtonView = kd.ButtonView
KDOverlayView = kd.OverlayView
AvatarView = require 'app/commonviews/avatarviews/avatarview'
showError = require 'app/util/showError'
remote = require('app/remote').getInstance()
envDataProvider = require 'app/userenvironmentdataprovider'


module.exports = class SidebarMachineSharePopup extends KDModalView


  constructor: (options = {}, data) ->

    options.width    = 250
    options.height   = 'auto'
    options.cssClass = 'activity-modal share-modal'
    options.sticky  ?= no

    super options, data

    @createArrow()
    @createElements()

    if options.sticky
      @createOverlay()
      kd.singletons.router.once 'RouteInfoHandled', @bound 'destroy'
    else
      kd.singletons.windowController.addLayer this
      @on 'ReceivedClickElsewhere', @bound 'destroy'


  createArrow: ->

    _addSubview = KDView::addSubView.bind this

    _addSubview new KDCustomHTMLView
      cssClass  : 'modal-arrow'
      position  : top : 20


  createOverlay: ->

    @overlay = new KDOverlayView
      isRemovable : no
      cssClass    : 'env-modal-overlay approve-overlay'


  createElements: ->

    @createAvatarView @getData().getOwner()
    @createTitle 'wants to share this VM with you'
    @createButtons()


  createTitle: (text) ->

    @addSubView new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'title'
      partial  : text


  createButtons: ->

    @addSubView @denyButton = new KDButtonView
      cssClass : 'solid medium red'
      title    : 'REJECT'
      loader   : yes
      callback : @bound 'denyShare'

    @addSubView @approveButton = new KDButtonView
      cssClass : 'solid green medium'
      title    : 'ACCEPT'
      loader   : yes
      callback : @bound 'approveShare'


  createAvatarView: (nickname) ->

    @addSubView userView = new KDCustomHTMLView
      cssClass : 'user-view'

    userView.addSubView new AvatarView
      origin : nickname
      size   : width: 30, height: 30

    userView.addSubView userDetails = new KDCustomHTMLView
      cssClass : 'user-details'


    remote.cacheable nickname, (err, accounts) =>

      return showError err  if err

      { nickname, firstName, lastName } = accounts.first.profile

      userDetails.updatePartial "
        <div class='fullname'>#{firstName} #{lastName}</div>
        <div class='nickname'>@#{nickname}</div>
      "


  approveShare: ->

    { jMachine } = @getData()

    @approveButton.showLoader()
    jMachine.approve (err) =>
      return showError err  if err

      kd.singletons.router.handleRoute "/IDE/#{jMachine.uid}/my-workspace"
      @destroy()


  denyShare: ->

    @denyButton.showLoader()
    @getData().jMachine.deny (err) =>
      return showError err  if err

      @destroy()
      envDataProvider.fetch =>
        kd.singletons.mainView.activitySidebar.redrawMachineList()

  destroy: ->

    @overlay?.destroy()

    super
