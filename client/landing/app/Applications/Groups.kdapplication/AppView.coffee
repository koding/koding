class GroupsMainView extends KDView

  constructor:(options,data)->
    options = $.extend
      ownScrollBars : yes
    ,options
    super options,data

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Groups"
    header.setSearchInput()


# class GroupsApprovalRequestsView extends GroupsRequestView

#   constructor:->
#     super

#     group = @getData()

#     @timestamp = new Date 0

#     @currentState = new KDView
#       partial : 'chris sez'

#     @batchInvites = new KDView
#       partial : 'chris sez again'

#     @requestListController = new KDListViewController
#       viewOptions     :
#         cssClass      : 'requests-list'
#       itemClass       : GroupApprovalRequestListItemView

#     @pendingRequestsView = @requestListController.getListView()

#     @pendingRequestsView.on 'RequestIsApproved', (invitationRequest)=>
#       @emit 'RequestIsApproved', invitationRequest

#     @pendingRequestsView.on 'RequestIsDeclined', (invitationRequest)=>
#       @emit 'RequestIsDeclined', invitationRequest

#     @refresh()

#   refresh:->
#     @requestListController.removeAllItems()
#     @fetchSomeRequests 'basic approval', (err, requests)=>
#       if err then console.error err
#       else
#         @requestListController.instantiateListItems requests.reverse()

#   pistachio:->
#     """
#     <section class="formline">
#       <h2>Status quo</h2>
#       {{> @currentState}}
#     </section>
#     <div class="formline">
#     <section class="formline batch">
#       <h2>Invite members by batch</h2>
#       {{> @batchInvites}}
#     </section>
#     </div>
#     <div class="formline">
#     <section class="formline pending">
#       <h2>Pending approval</h2>
#       {{> @pendingRequestsView}}
#     </section>
#     </div>
#     """
