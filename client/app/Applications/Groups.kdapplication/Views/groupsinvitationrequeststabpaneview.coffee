class GroupsInvitationRequestsTabPaneView extends KDView

  requestLimit: 10

  constructor:(options={}, data)->
    options.itemClass          or= GroupsInvitationListItemView
    options.resolvedStatuses   or= ['pending', 'approved', 'declined']
    options.unresolvedStatuses or= 'pending'

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

  addListeners:->
    @on 'teasersLoaded', =>
      @fetchAndPopulate()  unless @controller.scrollView.hasScrollBars()

    @controller.on 'LazyLoadThresholdReached', =>
      return @controller.hideLazyLoader()  if @controller.noItemLeft
      @fetchAndPopulate()

    @on 'SearchInputChanged', (@searchValue)=> @refresh()

  fetchAndPopulate:->
    @controller.showLazyLoader no

    @getData().fetchOrSearchInvitationRequests @options.statuses, @timestamp,\
      @requestLimit, @searchValue, (err, requests)=>
        @controller.hideLazyLoader()
        if err or requests.length is 0
          warn err  if err
          return @controller.emit 'noItemsFound'

        @controller.hideNoItemWidget()  if requests.length > 0
        @timestamp = requests.last.timestamp_
        @controller.instantiateListItems requests
        @emit 'teasersLoaded'  if requests.length is @requestLimit

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
