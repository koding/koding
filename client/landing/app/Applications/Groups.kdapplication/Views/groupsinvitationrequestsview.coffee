class GroupsInvitationRequestsView extends GroupsRequestView

  controllerNames = ['requestList','sentList','resolvedList']

  constructor:(options, data)->
    super

    group = @getData()

    @timestamp = new Date 0

    @prepareSentList()
    @prepareRequestList()
    @prepareResolvedList()

    @currentState = new KDView cssClass: 'formline'

    @invitationTypeFilter =
      options.invitationTypeFilter ? ['basic approval','invitation']
    
    @statusFilter =
      options.statusFilter ? ['pending','sent','approved', 'declined']

    @inviteMember = new KDFormViewWithFields
      fields            :
        recipient       :
          label         : "Send to"
          type          : "text"
          name          : "recipient"
          placeholder   : "Enter an email address..."
          validate      :
            rules       :
              required  : yes
              email     : yes
            messages    :
              required  : "An email address is required!"
              email     : "That does not not seem to be a valid email address!"
      buttons           :
        'Send invite'   :
          loader        :
            color       : "#444444"
            diameter    : 12
          callback      : -> console.log 'send', arguments


    @prepareBulkInvitations()
    @batchInvites = new KDFormViewWithFields
      cssClass          : 'invite-tools'
      buttons           :
        'Send invites'  :
          title         : 'Send invitation batch'
          callback      : =>
            @emit 'BatchInvitationsAreSent', +@batchInvites.getFormData().Count
      fields            :
        Count           :
          label         : "# of Invites"
          type          : "text"
          defaultValue  : 10
          placeholder   : "how many users do you want to Invite?"
          validate      :
            rules       :
              regExp    : /\d+/i
            messages    :
              regExp    : "numbers only please"
        Status          :
          label         : "Server response"
          type          : "hidden"
          nextElement   :
            statusInfo  :
              itemClass : KDView
              partial   : '...'
              cssClass  : 'information-line'
    , group

    @refresh()

  getControllers:->
    (@["#{controllerName}Controller"] for controllerName in controllerNames)

  refresh:->
    
    @fetchSomeRequests @invitationTypeFilter, @statusFilter, (err, requests)=>
      if err then console.error err
      else
        
        groupedRequests = {}
        
        requests.reverse().forEach (request)->
          
          requestGroup = 
            if request.status in ['approved','declined']
              groupedRequests.resolved ?= []
            else
              groupedRequests[request.status] ?= []
          
          requestGroup.push request
        
        {pending, sent, resolved} = groupedRequests

        # clear out any items that may be there already:
        @getControllers().forEach controller.bound 'removeAllItems'

        # populate the lists:
        @requestListController.instantiateListItems pending     if pending?
        @sentListController.instantiateListItems sent           if sent?
        @resolvedListController.instantiateListItems resolved   if resolved?

    return this

  prepareSentList:->
    @sentListController = new InvitationRequestListController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationRequestListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations sent'

    @sentRequestList = @sentListController.getView()
    return @sentRequestList

  prepareRequestList:->
    @requestListController = new InvitationRequestListController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationRequestListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations pending'

    @requestList = @requestListController.getView()

    listView = @requestListController.getListView()

    @forwardEvent listView, 'RequestIsApproved'
    @forwardEvent listView, 'RequestIsDeclined'

    return @requestList

  prepareResolvedList:->
    @resolvedListController = new InvitationRequestListController
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No requests resolved'

    @resolvedList = @resolvedListController.getView()
    return @resolvedList

  pistachio:->
    """
    <section class="formline status-quo">
      <h2>Status quo</h2>
      {{> @currentState}}
    </section>
    <div class="formline">
      <section class="formline email">
        <h2>Invite member by email</h2>
        {{> @inviteMember}}
      </section>
      <section class="formline batch">
        <h2>Invite members by batch</h2>
        {{> @batchInvites}}
      </section>
    </div>
    <div class="formline">
      <section class="formline pending">
        <h2>Pending requests</h2>
        {{> @requestList}}
      </section>
      <section class="formline sent">
        <h2>Sent invitations</h2>
        {{> @sentRequestList}}
      </section>
    </div>
    <div class="formline">
      <section class="formline resolved">
        <h2>Resolved requests</h2>
        {{> @resolvedList}}
      </section>
    </div>
    """