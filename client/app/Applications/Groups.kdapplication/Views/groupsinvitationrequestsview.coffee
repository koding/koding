class GroupsInvitationRequestsView extends GroupsRequestView

  controllerNames = ['penRequestsList','penInvitationsList','resRequestsList','resInvitationsList']

  constructor:(options, data)->
    options.cssClass = 'groups-invitation-request-view'

    super

    group = @getData()

    @timestamp = new Date 0

    @preparePendingRequestsList()
    @preparePendingInvitationsList()
    @prepareResolvedRequestsList()
    @prepareResolvedInvitationsList()

    @currentState = new KDView cssClass: 'formline'

    @invitationTypeFilter =
      options.invitationTypeFilter ? ['basic approval','invitation']

    @statusFilter =
      options.statusFilter ? ['pending','sent','approved', 'declined', 'accepted', 'ignored']

    @inviteByEmail = new KDFormViewWithFields
      callback            : => @emit 'InviteByEmail', @inviteByEmail
      fields              :
        recipient         :
          type            : 'text'
          name            : 'recipient'
          cssClass        : 'inline'
          placeholder     : 'Enter an email address...'
          validate        :
            rules         :
              required    : yes
              email       : yes
            messages      :
              required    : 'An email address is required!'
              email       : 'That does not not seem to be a valid email address!'
          nextElementFlat :
            'Send'        :
              itemClass   : KDButtonView
              type        : 'submit'
              loader      :
                color     : '#444444'
                diameter  : 12
    @inviteByEmail.on 'FormValidationFailed', => @inviteByEmail.inputs['Send'].hideLoader()

    @inviteByUsername = new KDFormViewWithFields
      callback            : => @emit 'InviteByUsername', @inviteByUsername
      fields              :
        recipient         :
          type            : 'text'
          name            : 'recipient'
          cssClass        : 'inline'
          placeholder     : 'Enter a username...'
          validate        :
            rules         :
              required    : yes
            messages      :
              required    : 'A username is required!'
          nextElementFlat :
            'Send'        :
              itemClass   : KDButtonView
              type        : 'submit'
              loader      :
                color     : '#444444'
                diameter  : 12
    @inviteByUsername.on 'FormValidationFailed', => @inviteByUsername.inputs['Send'].hideLoader()

    @prepareBulkInvitations()
    
    @batchApprove = new KDFormViewWithFields
      callback             : => @emit 'BatchApproveRequests', @batchApprove, +@batchApprove.getFormData().Count
      cssClass             : 'invite-tools'
      fields               :
        Count              :
          label            : '# of requests'
          type             : 'text'
          defaultValue     : 10
          placeholder      : 'how many requests do you want to approve?'
          cssClass         : 'inline'
          validate         :
            rules          :
              regExp       : /\d+/i
            messages       :
              regExp       : 'numbers only please'
          nextElementFlat  :
            'Approve' :
              itemClass    : KDButtonView
              type         : 'submit'
              loader       :
                color      : '#444444'
                diameter   : 12
    , group
    @batchApprove.on 'FormValidationFailed', => @batchApprove.inputs['Approve'].hideLoader()

    @batchInvite = new KDFormViewWithFields
      callback             : => @emit 'BatchInvite', @batchInvite
      cssClass             : 'invite-tools'
      fields               :
        Emails             :
          type             : 'textarea'
          placeholder      : ''
          cssClass         : 'inline'
          validate         :
            rules          :
              required     : yes
            messages       :
              required     : 'At least one email address required!'
          nextElementFlat  :
            'Invite' :
              itemClass    : KDButtonView
              type         : 'submit'
              loader       :
                color      : '#444444'
                diameter   : 12
    , group
    @batchInvite.on 'FormValidationFailed', => @batchInvite.inputs['Invite'].hideLoader()

    @refresh()

    @utils.defer =>
      @parent.on 'NewInvitationActionArrived', =>
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
              groupedRequests.resRequests ?= []
            else if request.status in ['accepted','ignored']
              groupedRequests.resInvitations ?= []
            else
              groupedRequests[request.status] ?= []
          requestGroup.push request

        {pending, sent, resRequests, resInvitations} = groupedRequests

        # clear out any items that may be there already:
        @getControllers().forEach (controller)-> controller.removeAllItems()

        # populate the lists:
        @penRequestsListController.instantiateListItems pending           if pending?
        @penInvitationsListController.instantiateListItems sent           if sent?
        @resRequestsListController.instantiateListItems resRequests       if resRequests?
        @resInvitationsListController.instantiateListItems resInvitations if resInvitations?

    return this

  preparePendingInvitationsList:->
    @penInvitationsListController = new InvitationRequestListController
      viewOptions       :
        cssClass        : 'request-list'
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations sent'

    @forwardEvent @penInvitationsListController, 'ShowMoreRequested', 'PendingInvitations'

    @pendingInvitationsList = @penInvitationsListController.getView()
    return @pendingInvitationsList

  preparePendingRequestsList:->
    @penRequestsListController = new InvitationRequestListController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationRequestListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No requests pending'

    @pendingRequestsList = @penRequestsListController.getView()

    listView = @penRequestsListController.getListView()
    @forwardEvent listView, 'RequestIsApproved'
    @forwardEvent listView, 'RequestIsDeclined'

    @forwardEvent @penRequestsListController, 'ShowMoreRequested', 'PendingRequests'

    return @pendingRequestsList

  prepareResolvedRequestsList:->
    @resRequestsListController = new InvitationRequestListController
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No requests resolved'

    @forwardEvent @resRequestsListController, 'ShowMoreRequested', 'ResolvedRequests'

    @resolvedRequestsList = @resRequestsListController.getView()
    return @resolvedRequestsList

  prepareResolvedInvitationsList:->
    @resInvitationsListController = new InvitationRequestListController
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations resolved'

    @forwardEvent @resInvitationsListController, 'ShowMoreRequested', 'ResolvedRequests'

    @resolvedInvitationsList = @resInvitationsListController.getView()
    return @resolvedInvitationsList

  showErrorMessage:(err)->
    warn err
    new KDNotificationView 
      title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
      duration : 2000

  pistachio:->
    """
    <section class="formline status-quo">
      <h2>Status quo</h2>
      {{> @currentState}}
    </section>
    <div class="formline">
      <section class="formline batch">
        <h2>Batch approve requests</h2>
        {{> @batchApprove}}
      </section>
      <section class="formline no-padding">
        <section class="formline email">
          <h2>Invite by email</h2>
          {{> @inviteByEmail}}
        </section>
        <section class="formline username">
          <h2>Invite by username</h2>
          {{> @inviteByUsername}}
        </section>
      </section>
    </div>
    <div class="formline">
      <section class="formline pending">
        <h2>Pending requests</h2>
        {{> @pendingRequestsList}}
      </section>
      <section class="formline sent">
        <h2>Sent invitations</h2>
        {{> @pendingInvitationsList}}
      </section>
    </div>
    <div class="formline">
      <section class="formline resolved">
        <h2>Resolved requests</h2>
        {{> @resolvedRequestsList}}
      </section>
      <section class="formline resolved">
        <h2>Resolved invitations</h2>
        {{> @resolvedInvitationsList}}
      </section>
    </div>
    """