class GroupsInvitationRequestsTabPaneView extends KDView

  requestLimit: 10

  constructor:(options={}, data)->
    options.itemClass          or= GroupsInvitationListItemView
    options.resolvedStatuses   or= ['pending', 'approved', 'declined']
    options.unresolvedStatuses or= 'pending'

    super options, data

    @setStatusesByResolvedSwitch @getDelegate().resolvedState ? no

    @controller = new InvitationRequestListController
      itemClass           : options.itemClass
      lazyLoadThreshold   : 0.90
      startWithLazyLoader : yes

    @listView   = @controller.getView()
    @addSubView @listView

  addListeners:->
    @on 'teasersLoaded', (count)=>
      @controller.hideNoItemWidget()  if count > 0
      @fetchAndPopulate()  unless @controller.scrollView.hasScrollBars()

    @controller.on 'LazyLoadThresholdReached', =>
      return @controller.hideLazyLoader()  if @controller.noItemLeft
      @fetchAndPopulate()

  fetchRequests:(callback)->
    status   = @options.statuses
    status   = $in: status                 if Array.isArray status
    selector = timestamp: $lt: @timestamp  if @timestamp

    options  =
      targetOptions :
        selector    : { status }
        limit       : @requestLimit
        sort        : { requestedAt: -1 }
      options       :
        sort        : { timestamp: -1 }

    @getData().fetchInvitationRequests selector, options, callback

  fetchAndPopulate:->
    @controller.showLazyLoader no

    @fetchRequests (err, requests)=>
      @controller.hideLazyLoader()
      if err or requests.length is 0
        warn err  if err
        return @controller.emit 'noItemsFound'

      @timestamp = requests.last.timestamp_
      @controller.instantiateListItems requests
      @emit 'teasersLoaded', requests.length  if requests.length is @requestLimit

  viewAppended:->
    super()
    @addListeners()
    @fetchAndPopulate()

  refresh:->
    @controller.removeAllItems()
    @timestamp = null
    @fetchAndPopulate()

  setStatusesByResolvedSwitch:(@resolvedState)->
    @options.statuses = if @resolvedState\
                        then @options.resolvedStatuses\
                        else @options.unresolvedStatuses


class GroupsMembershipRequestsTabPaneView extends GroupsInvitationRequestsTabPaneView

  constructor:(options={}, data)->
    options.itemClass       or= GroupsInvitationRequestListItemView
    options.noItemFound     or= 'No requests found.'
    options.noMoreItemFound or= 'No more requests found.'

    super options, data


class GroupsSentInvitationsTabPaneView extends GroupsInvitationRequestsTabPaneView

  constructor:(options={}, data)->
    options.resolvedStatuses   or= ['sent', 'accepted', 'ignored']
    options.unresolvedStatuses or= 'sent'
    options.noItemFound        or= 'No sent invitations found.'
    options.noMoreItemFound    or= 'No more sent invitations found.'

    super options, data
