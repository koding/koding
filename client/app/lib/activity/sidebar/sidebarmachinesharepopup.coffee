kd               = require 'kd'
KDModalView      = kd.ModalView
KDCustomHTMLView = kd.CustomHTMLView
KDView           = kd.View
KDButtonView     = kd.ButtonView
KDOverlayView    = kd.OverlayView
AvatarView       = require 'app/commonviews/avatarviews/avatarview'
showError        = require 'app/util/showError'
remote           = require('app/remote').getInstance()
envDataProvider  = require 'app/userenvironmentdataprovider'
envHelpers       = require 'ide/collaboration/helpers/environment'
nick             = require 'app/util/nick'


module.exports = class SidebarMachineSharePopup extends KDModalView


  constructor: (options = {}, data) ->

    options.width    = 250
    options.height   = 'auto'
    options.cssClass = 'activity-modal share-modal'
    options.sticky  ?= no

    super options, data

    if @getData().isApproved()
      @isApproved = yes
      @setClass 'approved'

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

    text       = 'wants to share their VM with you.'
    titleFirst = no

    if @isApproved
      text       = 'Shared with you by'
      titleFirst = yes

    @createAvatarView @getData().getOwner()
    @createTitle text, titleFirst
    @createButtons()


  createTitle: (text, prepend) ->

    view = new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'title'
      partial  : text

    @addSubView view, null, prepend


  createButtons: ->

    title = 'REJECT'

    if @isApproved
      title = if @getOptions().channelId then 'LEAVE SESSION' else 'LEAVE SHARED VM'

    @addSubView @denyButton = new KDButtonView
      cssClass : 'solid medium red'
      title    : title
      loader   : yes
      callback : @bound 'deny'

    unless @isApproved

      @addSubView @approveButton = new KDButtonView
        cssClass : 'solid green medium'
        title    : 'ACCEPT'
        loader   : yes
        callback : @bound 'approve'


  createAvatarView: (nickname) ->

    @addSubView userView = new KDCustomHTMLView
      cssClass : 'user-view'

    userView.addSubView new AvatarView
      origin : nickname
      size   : width: 30, height: 30

    userView.addSubView userDetails = new KDCustomHTMLView
      cssClass : 'user-details'


    # FIXME: cacheable is actually not cacheable, must be fixed before deploy.
    remote.cacheable nickname, (err, accounts) =>

      return showError err  if err

      { nickname, firstName, lastName } = accounts.first.profile

      userDetails.updatePartial "
        <div class='fullname'>#{firstName} #{lastName}</div>
        <div class='nickname'>@#{nickname}</div>
      "


  approve: ->

    machine = @getData()

    @approveButton.showLoader()
    machine.jMachine.approve (err) =>
      return showError err  if err
      { router, mainView } = kd.singletons

      { channelId } = @getOptions()
      kd.singletons.socialapi.channel.acceptInvite { channelId }, (err) =>
        return showError err  if err

        doNavigation = =>
          if machine.isPermanent()
            route = "/IDE/#{machine.uid}/my-workspace" # permanent shared route
          else # collaboration route
            route = "/IDE/#{@getOptions().channelId}"

          # route to permanent shared url to open the ide
          router.handleRoute route

          # defer sidebar redrawing to properly select workspace
          kd.utils.defer =>
            mainView.activitySidebar.redrawMachineList()
            @destroy()

        envDataProvider.fetch =>
          # if there is an ide instance this means user landed to ide with direct url
          ideApp = envDataProvider.getIDEFromUId machine.uid

          if ideApp
            ideApp.quit()
            # i needed to wait 737ms to do the navigation. actually i don't want
            # to burn more ATP for this case because it's the only case if user
            # navigates to that url manually by knowing the machine uid and stuff
            kd.utils.wait 737, => doNavigation()
          else
            doNavigation()


  deny: ->

    machine = @getData()

    @denyButton.showLoader()
    machine.jMachine.deny (err) =>
      return showError err  if err

      if machine.isPermanent() then @handleDeny()
      else # remove user from chat and unshare machine for collaboration
        { channelId } = @getOptions()
        kd.singletons.socialapi.channel.rejectInvite { channelId }, (err) =>
          return showError err  if err

          envHelpers.setMachineUser machine, [ nick() ], no, (err) =>
            return showError err  if err
            @handleDeny()


  handleDeny: ->

    # fetch the data and redraw the sidebar to remove the denied machine.
    envDataProvider.fetch =>
      kd.singletons.mainView.activitySidebar.redrawMachineList()

      if @isApproved # quit IDE if exists
        envDataProvider.getIDEFromUId(@getData().uid)?.quit()

      @destroy()


  destroy: ->

    @overlay?.destroy()

    super
