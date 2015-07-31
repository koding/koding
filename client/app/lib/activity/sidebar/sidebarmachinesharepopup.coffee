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
sinkrow          = require 'sinkrow'


module.exports = class SidebarMachineSharePopup extends KDModalView


  constructor: (options = {}, data) ->

    options.width    = 250
    options.height   = 'auto'
    options.cssClass = 'activity-modal share-modal'
    options.sticky  ?= no

    super options, data

    {@isApproved} = options
    @setClass 'approved'  if @isApproved

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

    queue = [
      ->
        if denyMachine
        then machine.jMachine.deny (err) ->
          return showError err  if err
          queue.next()
        else queue.next()
      =>
        return queue.next()  unless channelId

        {channel} = kd.singletons.socialapi

        method = if isApproved then 'leave' else 'rejectInvite'

        channel[method] {channelId}, (err) ->
          showError err
          queue.next()
      ->
        if denyMachine
          envDataProvider.getIDEFromUId(machine.uid)?.quit()
        queue.next()
      ->
        envDataProvider.fetch ->
          kd.singletons.mainView.activitySidebar.redrawMachineList()
          queue.next()
      =>
        @destroy()
        queue.next()
    ]

    sinkrow.daisy queue


  destroy: ->

    @overlay?.destroy()

    super


  TITLES =
    'shared machine' : 'wants to share their VM with you.'
    'collaboration'  : 'wants to collaborate with you on their VM.'
    'approved'       : 'Shared with you by'
