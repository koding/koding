class GroupsInvitationTabPaneView extends KDView

  requestLimit: 10

  constructor:(options={}, data)->
    options.showResolved  ?= no

    super options, data

    @controller = new InvitationRequestListController
      delegate            : this
      itemClass           : options.itemClass
      noItemFound         : options.noItemFound
      lazyLoadThreshold   : 0.90
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    :
          loaderOptions   :
            shape         : 'spiral'
            color         : '#a4a4a4'
          size            :
            width         : 40
            height        : 40

    @addSubView @listView = @controller.getView()

    @controller.on 'UpdatePendingCount',      @updatePendingCount.bind this
    @listView.on   'InvitationStatusChanged', =>
      @getDelegate().tabHandle?.markDirty()

  addListeners:->
    @on 'teasersLoaded', =>
      @fetchAndPopulate()  unless @controller.scrollView.hasScrollBars()

    @controller.on 'LazyLoadThresholdReached', =>
      return @controller.hideLazyLoader()  if @controller.noItemLeft
      @fetchAndPopulate()

    @on 'SearchInputChanged', (@searchValue)=> @refresh()

    groupController = KD.getSingleton("groupsController")
    groupController.on "MemberJoinedGroup", (data) =>
      @refresh()

  viewAppended:->
    super()
    @addListeners()
    @fetchAndPopulate()

  refresh:->
    @controller.removeAllItems()
    @timestamp = null
    @fetchAndPopulate()
    @updatePendingCount @parent

  setShowResolved:(showResolved)-> @options.showResolved = showResolved

  updatePendingCount:(pane)->
    pane ?= @parent
    @getData().countInvitationsFromGraph @options.type,\
      {status: @options.unresolvedStatus}, (err, count)->
        pane.getHandle().updatePendingCount count  unless err

  fetchAndPopulate:->
    @controller.showLazyLoader no

    options = {@timestamp , @requestLimit, search: @searchValue, }
    options.showResolved = @getOptions().showResolved
    options.type = @getOptions().type

    @getData().fetchInvitationsByStatus options, (err, results)=>
      @controller.hideLazyLoader()
      results = results.filter (res)-> res isnt null
      if err or results.length is 0
        warn err  if err
        return @controller.emit 'noItemsFound'

      @timestamp = results.last[@options.timestampField]
      @controller.instantiateListItems results
      @emit 'teasersLoaded'  if results.length is @requestLimit


class GroupsMembershipRequestsTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.noItemFound      = 'No requests found.'
    options.noMoreItemFound  = 'No more requests found.'
    options.unresolvedStatus = 'pending'
    options.type             = 'InvitationRequest'
    options.timestampField   = 'requestedAt'

    super options, data

    @getData().on 'NewInvitationRequest', =>
      @emit 'NewInvitationActionArrived'
      @parent.tabHandle.markDirty()


class GroupsSentInvitationsTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.noItemFound      = 'No sent invitations found.'
    options.noMoreItemFound  = 'No more sent invitations found.'
    options.unresolvedStatus = 'sent'
    options.type             = 'Invitation'
    options.timestampField   = 'createdAt'

    super options, data


class GroupsInvitationCodesTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.itemClass        = GroupsInvitationCodeListItemView
    options.noItemFound      = 'No invitation codes found.'
    options.noMoreItemFound  = 'No more invitation codes found.'
    options.unresolvedStatus = 'active'
    options.type             = 'InvitationCode'
    options.timestampField   = 'createdAt'

    super options, data
