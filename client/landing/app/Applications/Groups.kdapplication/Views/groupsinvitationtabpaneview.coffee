class GroupsInvitationTabPaneView extends KDView

  requestLimit: 10

  constructor:(options={}, data)->
    super options, data

    @setStatusesByResolvedSwitch @getDelegate().resolvedState ? no

    @controller = new InvitationRequestListController
      delegate            : this
      itemClass           : options.itemClass
      noItemFound         : options.noItemFound
      lazyLoadThreshold   : 0.90
      startWithLazyLoader : yes

    @listView   = @controller.getView()
    @addSubView @listView

    @controller.on 'UpdatePendingCount', @updatePendingCount.bind this
    @listView.on 'invitationStatusChanged', =>
      @parent.tabHandle.markDirty()

  addListeners:->
    @on 'teasersLoaded', =>
      @fetchAndPopulate()  unless @controller.scrollView.hasScrollBars()

    @controller.on 'LazyLoadThresholdReached', =>
      return @controller.hideLazyLoader()  if @controller.noItemLeft
      @fetchAndPopulate()

    @on 'SearchInputChanged', (@searchValue)=> @refresh()

  viewAppended:->
    super()
    @addListeners()
    @fetchAndPopulate()

  refresh:->
    @controller.removeAllItems()
    @timestamp = null
    @fetchAndPopulate()
    @updatePendingCount @parent

  setStatusesByResolvedSwitch:(@resolvedState)->
  updatePendingCount:(pane)->
  fetchAndPopulate:->


class GroupsInvitationRequestsTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.itemClass          or= GroupsInvitationListItemView
    options.resolvedStatuses   or= ['pending', 'approved', 'declined']
    options.unresolvedStatuses or= 'pending'

    super options, data

  fetchAndPopulate:->
    @controller.showLazyLoader no

    @getData().fetchOrSearchInvitationRequests @options.statuses, @timestamp,\
      @requestLimit, @searchValue, (err, requests)=>
        requests = requests.filter (req)-> req isnt null
        @controller.hideLazyLoader()
        if err or requests.length is 0
          warn err  if err
          return @controller.emit 'noItemsFound'

        @timestamp = requests.last.requestedAt
        @controller.instantiateListItems requests
        @emit 'teasersLoaded'  if requests.length is @requestLimit

  updatePendingCount:(pane)->
    pane  ?= @parent
    status = @options.unresolvedStatuses
    status = $in: status  if Array.isArray status
    KD.remote.api.JInvitationRequest.count {status}, (err, count)->
      pane.getHandle().updatePendingCount count  unless err

  setStatusesByResolvedSwitch:(@resolvedState)->
    @options.statuses = if @resolvedState\
                        then @options.resolvedStatuses\
                        else @options.unresolvedStatuses


class GroupsMembershipRequestsTabPaneView extends GroupsInvitationRequestsTabPaneView

  constructor:(options={}, data)->
    options.noItemFound     or= 'No requests found.'
    options.noMoreItemFound or= 'No more requests found.'

    super options, data

    @getData().on 'NewInvitationRequest', =>
      @emit 'NewInvitationActionArrived'
      @parent.tabHandle.markDirty()


class GroupsSentInvitationsTabPaneView extends GroupsInvitationRequestsTabPaneView

  constructor:(options={}, data)->
    options.resolvedStatuses   or= ['sent', 'accepted', 'ignored']
    options.unresolvedStatuses or= 'sent'
    options.noItemFound        or= 'No sent invitations found.'
    options.noMoreItemFound    or= 'No more sent invitations found.'

    super options, data


class GroupsInvitationCodesTabPaneView extends GroupsInvitationTabPaneView

  constructor:(options={}, data)->
    options.itemClass       or= GroupsInvitationCodeListItemView
    options.noItemFound     or= 'No invitation codes found.'
    options.noMoreItemFound or= 'No more invitation codes found.'

    super options, data

  fetchAndPopulate:->
    @controller.showLazyLoader no

    status = 'active'  unless @resolvedState

    KD.remote.api.JInvitation.fetchOrSearchMultiuse status, @timestamp,\
      @requestLimit, @searchValue, (err, codes)=>
        @controller.hideLazyLoader()
        if err or codes.length is 0
          warn err  if err
          return @controller.emit 'noItemsFound'

        @timestamp = codes.last._id
        @controller.instantiateListItems codes
        @emit 'teasersLoaded'  if codes.length is @requestLimit

  updatePendingCount:(pane)->
    pane  ?= @parent
    KD.remote.api.JInvitation.countMultiuse status:'active', (err, count)->
      pane.getHandle().updatePendingCount count  unless err
