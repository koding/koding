
class GroupsInvitationRequestsView extends GroupsRequestView

  constructor:->
    super

    group = @getData()

    @timestamp = new Date 0
    @fetchSomeRequests 'invitation', (err, requests)=>
      if err then console.error err
      else
        sent = []
        pending = []
        for request in requests
          if request.status is 'sent'
            sent.push request
          else
            pending.push request
        @requestListController.instantiateListItems pending.reverse()
        @sentRequestListController.instantiateListItems sent.reverse()

    @prepareSentList()
    @prepareRequestList()

    @currentState = new KDView cssClass: 'formline'

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

  prepareSentList:->
    @sentRequestListController = new KDListViewController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationRequestListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations sent'

    @sentRequestList = @sentRequestListController.getListView()
    return @sentRequestList

  prepareRequestList:->
    @requestListController = new KDListViewController
      viewOptions       :
        cssClass        : 'request-list'
      itemClass         : GroupsInvitationRequestListItemView
      showDefaultItem   : yes
      defaultItem       :
        options         :
          cssClass      : 'default-item'
          partial       : 'No invitations pending'

    @requestList = @requestListController.getListView()

    @requestList.on 'RequestIsApproved', (invitationRequest)=>
      @emit 'RequestIsApproved', invitationRequest

    @requestList.on 'RequestIsDeclined', (invitationRequest)=>
      @emit 'RequestIsDeclined', invitationRequest

    return @requestList

  pistachio:->
    """
    <section class="formline status-quo">
      <h2>Status quo</h2>
      {{> @currentState}}
    </section>
    <div class="formline">
    <section class="formline batch">
      <h2>Invite members by batch</h2>
      {{> @batchInvites}}
    </section>
    <section class="formline email">
      <h2>Invite member by email</h2>
      {{> @inviteMember}}
    </section>
    </div>
    <div class="formline">
    <section class="formline sent">
      <h2>Sent invitations</h2>
      {{> @sentRequestList}}
    </section>
    <section class="formline pending">
      <h2>Pending requests</h2>
      {{> @requestList}}
    </section>
    </div>
    """