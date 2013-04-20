class GroupsInvitationRequestsView extends GroupsRequestView

  controllerNames = ['pendingList','sentList','resolvedList']

  constructor:(options, data)->

    options.cssClass = 'groups-invitation-request-view'

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

    @inviteByEmail = new KDFormViewWithFields
      callback            : (err)=>
        @sendInviteByEmail()
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
      callback            : => @sendInviteByUsername()
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
    @batchInvites = new KDFormViewWithFields
      cssClass             : 'invite-tools'
      fields               :
        Count              :
          label            : '# of Invites'
          type             : 'text'
          defaultValue     : 10
          placeholder      : 'how many users do you want to invite?'
          cssClass         : 'inline'
          validate         :
            rules          :
              regExp       : /\d+/i
            messages       :
              regExp       : 'numbers only please'
          nextElementFlat  :
            'Send invites' :
              itemClass    : KDButtonView
              title        : 'Send invitation batch'
              loader       :
                color      : '#444444'
                diameter   : 12
              callback     : =>
                @emit 'BatchInvitationsAreSent', +@batchInvites.getFormData().Count
    , group

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
              groupedRequests.resolved ?= []
            else
              groupedRequests[request.status] ?= []

          requestGroup.push request

        {pending, sent, resolved} = groupedRequests

        # clear out any items that may be there already:
        @getControllers().forEach (controller)-> controller.removeAllItems()

        # populate the lists:
        @pendingListController.instantiateListItems pending     if pending?
        @sentListController.instantiateListItems sent           if sent?
        @resolvedListController.instantiateListItems resolved   if resolved?

    return this

  prepareSentList:->
    @sentListController = new InvitationRequestListController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations sent'

    @forwardEvent @sentListController, 'ShowMoreRequested', 'Sent'

    @sentRequestList = @sentListController.getView()
    return @sentRequestList

  prepareRequestList:->
    @pendingListController = new InvitationRequestListController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationRequestListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations pending'

    @pendingList = @pendingListController.getView()

    listView = @pendingListController.getListView()

    @forwardEvent listView, 'RequestIsApproved'
    @forwardEvent listView, 'RequestIsDeclined'

    @forwardEvent @pendingListController, 'ShowMoreRequested', 'Pending'

    return @pendingList

  prepareResolvedList:->
    @resolvedListController = new InvitationRequestListController
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No requests resolved'

    @forwardEvent @resolvedListController, 'ShowMoreRequested', 'Resolved'

    @resolvedList = @resolvedListController.getView()
    return @resolvedList

  sendInviteByEmail:->
    email = @inviteByEmail.getFormData().recipient
    @getData().inviteByEmail email, (err)=>
      @inviteByEmail.inputs['Send'].hideLoader()
      if err then @showErrorMessage err
      else 
        new KDNotificationView title:'Invitation sent!'
        @refresh()

  sendInviteByUsername:->
    username = @inviteByUsername.getFormData().recipient
    @getData().inviteByUsername username, (err)=>
      @inviteByUsername.inputs['Send'].hideLoader()
      if err then @showErrorMessage err
      else
        new KDNotificationView title:'Invitation sent!'
        @refresh()

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
      <section class="formline batch">
        <h2>Send out invites from waitlist</h2>
        {{> @batchInvites}}
      </section>
    </div>
    <div class="formline">
      <section class="formline pending">
        <h2>Pending requests</h2>
        {{> @pendingList}}
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