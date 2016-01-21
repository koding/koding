kd               = require 'kd'
nick             = require 'app/util/nick'
async            = require 'async'
KDView           = kd.View
remote           = require('app/remote').getInstance()
whoami           = require '../../util/whoami'
Machine          = require 'app/providers/machine'
showError        = require 'app/util/showError'
envHelpers       = require 'ide/collaboration/helpers/environment'
AvatarView       = require 'app/commonviews/avatarviews/avatarview'
KDModalView      = kd.ModalView
KDButtonView     = kd.ButtonView
KDOverlayView    = kd.OverlayView
envDataProvider  = require 'app/userenvironmentdataprovider'
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class SidebarMachineSharePopup extends KDModalView


  constructor: (options = {}, data) ->

    options.width    = 250
    options.height   = 'auto'
    options.cssClass = 'activity-modal share-modal'
    options.sticky  ?= no

    super options, data

    { @isApproved } = options
    @setClass 'approved'  if @isApproved

    @createArrow()
    @createElements()

    if options.sticky
      @createOverlay()
      kd.singletons.router.once 'RouteInfoHandled', @bound 'destroy'
    else
      kd.singletons.windowController.addLayer this
      @on 'ReceivedClickElsewhere', @bound 'destroy'

    kd.singletons.notificationController.on 'MachineShareActionTaken', @bound 'destroy'


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
    @createTitle()
    @createButtons()


  createTitle: ->

    prepend = @isApproved

    titleKey = if @isApproved
    then 'approved'
    else @getOption 'type'

    view = new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'title'
      partial  : TITLES[titleKey]

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
    wasApproved = machine.isApproved()

    kd.singletons.machineShareManager.unset machine.uid

    @approveButton.showLoader()

    machine.jMachine.approve (err) =>

      return showError err  if err

      {router, mainView} = kd.singletons

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

      callback = =>

        return @destroy()  if wasApproved

        envDataProvider.fetch =>
          doNavigation()

      { channelId } = @getOptions()

      if channelId
        kd.singletons.socialapi.channel.acceptInvite { channelId }, (err) =>
          return showError err  if err
          callback()
      else
        callback()


  deny: ->

    machine = @getData()

    kd.singletons.machineShareManager.unset machine.uid

    @denyButton.showLoader()

    {type, isApproved, channelId} = @getOptions()
    isPermanent = machine.isPermanent()

    denyMachine = switch type
      when 'shared machine' then isPermanent
      when 'collaboration' then not isPermanent

    async.series([
      (callback) ->
        if denyMachine
          machine.jMachine.deny (err) ->
            showError err  if err
            callback()
        else
          callback()

      (callback) ->
        return callback()  unless channelId

        { channel } = kd.singletons.socialapi
        method      = if isApproved then 'leave' else 'rejectInvite'

        channel[method] {channelId}, (err) ->
          showError err
          callback()

      (callback) ->

        if denyMachine
          envDataProvider.getIDEFromUId(machine.uid)?.quit()

        callback()

      (callback) ->

        envDataProvider.fetch ->
          kd.singletons.mainView.activitySidebar.redrawMachineList()
          callback()

      (callback) =>

        @destroy()
        callback()
    ])


  destroy: ->

    @overlay?.destroy()

    super


  TITLES =
    'shared machine' : 'wants to share their VM with you. <span class="footnote">* Rejecting this will destroy any existing collaboration sessions with this machine.</span>'
    'collaboration'  : 'wants to collaborate with you on their VM.'
    'approved'       : 'Shared with you by'
