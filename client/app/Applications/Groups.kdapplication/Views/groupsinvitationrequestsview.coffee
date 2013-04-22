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

    @inviteByEmailButton = new KDButtonView
      title    : 'Invite by Email'
      cssClass : 'clean-gray'
      callback : => @showInviteByEmailModal()
    @inviteByUsernameButton = new KDButtonView
      title    : 'Invite by Username'
      cssClass : 'clean-gray'
      callback : => @showInviteByUsernameModal()
    @batchInviteButton = new KDButtonView
      title    : 'Batch Invite'
      cssClass : 'clean-gray'
      callback : => @showBatchInviteModal()
    @batchApproveButton = new KDButtonView
      title    : 'Batch Approve Requests'
      cssClass : 'clean-gray'
      callback : => @showBatchApproveModal()

    @prepareBulkInvitations()
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

  showInviteByEmailModal:->
    modal = @inviteByEmail = new KDModalViewWithForms
      title                  : 'Invite by Email'
      overlay                : yes
      width                  : 300
      height                 : 'auto'
      tabs                   :
        forms                :
          invite             :
            callback         : => @emit 'InviteByEmail', modal.modalTabs.forms.invite
            buttons          :
              Send           :
                itemClass    : KDButtonView
                type         : 'submit'
                loader       :
                  color      : '#444444'
                  diameter   : 12
              Cancel         :
                style        : 'modal-cancel'
                callback     : (event)=> modal.destroy()
            fields           :
              recipient      :
                label        : 'Email address'
                type         : 'text'
                name         : 'recipient'
                placeholder  : 'Enter an email address...'
                validate     :
                  rules      :
                    required : yes
                    email    : yes
                  messages   :
                    required : 'An email address is required!'
                    email    : 'That does not not seem to be a valid email address!'

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

  showInviteByUsernameModal:->
    modal = @inviteByUsername = new KDModalViewWithForms
      title                  : 'Invite by Username'
      overlay                : yes
      width                  : 300
      height                 : 'auto'
      tabs                   :
        forms                :
          invite             :
            callback         : => @emit 'InviteByUsername', modal.modalTabs.forms.invite
            buttons          :
              Send           :
                itemClass    : KDButtonView
                type         : 'submit'
                loader       :
                  color      : '#444444'
                  diameter   : 12
              Cancel         :
                style        : 'modal-cancel'
                callback     : (event)=> modal.destroy()
            fields           :
              recipient      :
                label        : 'Username'
                type         : 'text'
                name         : 'recipient'
                placeholder  : 'Enter a user name...'
                validate     :
                  rules      :
                    required : yes
                  messages   :
                    required : 'A user name is required!'

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

  showBatchInviteModal:->
    modal = @batchInvite = new KDModalViewWithForms
      title                  : 'Batch Invite by Email'
      overlay                : yes
      width                  : 300
      height                 : 'auto'
      tabs                   :
        forms                :
          invite             :
            callback         : => @emit 'BatchInvite', modal.modalTabs.forms.invite
            buttons          :
              Send          :
                itemClass    : KDButtonView
                type         : 'submit'
                loader       :
                  color      : '#444444'
                  diameter   : 12
              Cancel         :
                style        : 'modal-cancel'
                callback     : (event)=> modal.destroy()
            fields           :
              emails         :
                label        : 'Emails'
                type         : 'textarea'
                placeholder  : 'Enter each email address on a new line...'
                validate     :
                  rules      :
                    required : yes
                  messages   :
                    required : 'At least one email address required!'

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

  showBatchApproveModal:->
    modal = @batchApprove = new KDModalViewWithForms
      title                  : 'Batch Approve Requests'
      overlay                : yes
      width                  : 300
      height                 : 'auto'
      tabs                   :
        forms                :
          invite             :
            callback         : => 
              form = modal.modalTabs.forms.invite
              @emit 'BatchApproveRequests', form, +form.getFormData().count
            buttons          :
              Send          :
                itemClass    : KDButtonView
                type         : 'submit'
                loader       :
                  color      : '#444444'
                  diameter   : 12
              Cancel         :
                style        : 'modal-cancel'
                callback     : (event)=> modal.destroy()
            fields           :
              count          :
                label        : '# of requests'
                type         : 'text'
                defaultValue : 10
                placeholder  : 'how many requests do you want to approve?'
                validate     :
                  rules      :
                    regExp   : /\d+/i
                  messages   :
                    regExp   : 'numbers only please'

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

  showErrorMessage:(err)->
    warn err
    new KDNotificationView 
      title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
      duration : 2000

  pistachio:->
    """
    <div class="button-bar">
      {{> @batchApproveButton}} {{> @batchInviteButton}} {{> @inviteByEmailButton}} {{> @inviteByUsernameButton}}
    </div>
    <section class="formline status-quo">
      <h2>Status quo</h2>
      {{> @currentState}}
    </section>
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