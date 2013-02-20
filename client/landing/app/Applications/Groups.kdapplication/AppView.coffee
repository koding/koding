class GroupsMainView extends KDView

  constructor:(options,data)->
    options = $.extend
      ownScrollBars : yes
    ,options
    super options,data

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Groups"
    header.setSearchInput()

class GroupsWebhookView extends JView

  constructor:->
    super
    @setClass 'webhook'
    @editLink = new CustomLinkView
      href    : '#'
      title   : 'Edit webhook'
      click   : (event)=>
        event.preventDefault()
        @emit 'WebhookEditRequested'

  pistachio:->
    "{.endpoint{#(webhookEndpoint)}}{{> @editLink}}"

class GroupsEditableWebhookView extends JView

  constructor:->
    super

    @setClass 'editable-webhook'

    @webhookEndpointLabel = new KDLabelView title: "Webhook endpoint"

    @webhookEndpoint = new KDInputView
      label       : @webhookEndpointLabel
      name        : "title"
      placeholder : "https://example.com/verify"

    @saveButton = new KDButtonView
      title     : "Save"
      style     : "cupid-green"
      callback  : =>
        @emit 'WebhookChanged', webhookEndpoint: @webhookEndpoint.getValue()

  setFocus:->
    @webhookEndpoint.focus()
    return this

  setValue:(webhookEndpoint)->
    @webhookEndpoint.setValue webhookEndpoint

  pistachio:->
    """
    {{> @webhookEndpointLabel}}
    {{> @webhookEndpoint}}
    {{> @saveButton}}
    """

class GroupsMembershipPolicyLanguageEditor extends JView

  constructor:->
    super
    @setClass 'policylanguage-editor'
    policy = @getData()

    @editorLabel = new KDLabelView
      title : 'Custom Policy Language'

    @editor = new KDInputView
      label         : @editorLabel
      type          : 'textarea'
      defaultValue  : policy.explanation
      keydown       : => @saveButton.enable()

    @cancelButton = new KDButtonView
      title     : "Cancel"
      cssClass  : "clean-gray"
      callback  : =>
        @hide()
        @emit 'EditorClosed'

    @saveButton = new KDButtonView
      title     : "Save"
      cssClass  : "cupid-green"
      callback  : =>
        @saveButton.disable()
        @emit 'PolicyLanguageChanged', explanation: @editor.getValue()

  pistachio:->
    """
    {{> @editorLabel}}{{> @editor}}{{> @saveButton}}{{> @cancelButton}}
    """

class GroupsMembershipPolicyView extends JView

  constructor:(options, data)->
    super
    policy = @getData()

    {invitationsEnabled, webhookEndpoint, approvalEnabled} = policy
    webhookExists = !!(webhookEndpoint and webhookEndpoint.length)

    @enableInvitations = new KDOnOffSwitch
      defaultValue  : invitationsEnabled
      callback      : (state) =>
        @emit 'MembershipPolicyChanged', invitationsEnabled: state

    @enableAccessRequests = new KDOnOffSwitch
      defaultValue  : approvalEnabled
      callback      : (state) =>
        @emit 'MembershipPolicyChanged', approvalEnabled: state

    @enableWebhooks = new KDOnOffSwitch
      defaultValue  : webhookExists
      callback      : (state) =>
        @webhook.hide()
        @webhookEditor[if state then 'show' else 'hide']()
        if state then @webhookEditor.setFocus()
        else @emit 'MembershipPolicyChanged', webhookEndpoint: null

    @webhook = new GroupsWebhookView
      cssClass: unless webhookExists then 'hidden'
    , policy

    @webhookEditor = new GroupsEditableWebhookView
      cssClass: 'hidden'
    , policy

    @on 'MembershipPolicyChangeSaved', =>
      console.log 'saved'
      # @webhookEditor.saveButton.loader.hide()

    @webhook.on 'WebhookEditRequested', =>
      @webhook.hide()
      @webhookEditor.show()

    @webhookEditor.on 'WebhookChanged', (data)=>
      @emit 'MembershipPolicyChanged', data
      {webhookEndpoint} = data
      webhookExists = !!webhookEndpoint
      policy.webhookEndpoint = webhookEndpoint
      policy.emit 'update'
      @webhookEditor.hide()
      @webhook[if webhookExists then 'show' else 'hide']()
      @enableWebhooks.setValue webhookExists

    @enableInvitations.setValue invitationsEnabled

    if webhookExists
      @webhookEditor.setValue webhookEndpoint
      @webhook.show()

    policyLanguageExists = policy.explanation

    @showPolicyLanguageLink = new CustomLinkView
      cssClass  : "edit-link #{if policyLanguageExists then 'hidden' else ''}"
      title     : 'Edit'
      href      : './edit'
      click     :(event)=>
        event.preventDefault()
        @showPolicyLanguageLink.hide()
        @policyLanguageEditor.show()

    @policyLanguageEditor = new GroupsMembershipPolicyLanguageEditor
      cssClass      : unless policyLanguageExists then 'hidden'
    , policy

    @policyLanguageEditor.on 'EditorClosed',=>
      @showPolicyLanguageLink.show()

    @policyLanguageEditor.on 'PolicyLanguageChanged', (data)=>
      @emit 'MembershipPolicyChanged', data
      {explanation} = data
      explanationExists = !!explanation
      policy.explanation = explanation
      policy.emit 'update'


  pistachio:->
    """
    {{> @enableAccessRequests}}
    <section class="formline">
      <h2>Users may request access</h2>
      <div class="formline">
        <p>If you disable this feature, users will not be able to request
        access to this group</p>
      </div>
    </section>
      {{> @enableInvitations}}
    <section class="formline">
      <h2>Invitations</h2>
      <div class="formline">
        <p>By enabling invitations, you will be able to send invitations to
        potential group members by their email address, you'll be able to grant
        invitations to your members which they can give to their friends, and
        you'll be able to create keyword-based multi-user invitations which
        can be shared with many people at once.</p>
        <p>If you choose not to enable invitations, a more basic request
        approval functionilty will be exposed.<p>
      </div>
    </section>
      {{> @enableWebhooks}}
    <section class="formline">
      <h2>Webhooks</h2>
      <div class="formline">
        <p>If you enable webhooks, then we will post some data to your webhooks
        when someone requests access to the group.  The business logic at your
        endpoint will be responsible for validating and approving the request</p>
        <p>Webhooks and invitations may be used together.</p>
      </div>
      {{> @webhook}}
      {{> @webhookEditor}}
    </section>
      {{> @showPolicyLanguageLink}}
    <section class="formline">
      <h2>Policy language</h2>
      <div class="formline">
        <p>It's possible to compose custom policy language (copy) to help your
        users better understand how they may become members of your group.</p>
        <p>If you wish, you may enter custom language below (markdown is OK):</p>
      </div>
      {{> @policyLanguageEditor}}
    </section>
    """

class GroupsInvitationRequestListItemView extends KDListItemView
  constructor:(options, data)->
    options.cssClass = 'invitation-request formline clearfix'

    super

    invitationRequest = @getData()

    @avatar = new AvatarStaticView
      size :
        width : 40
        height : 40

    KD.remote.cacheable @getData().koding.username, (err,account)=>
      @avatar.setData account
      @avatar.render()

    @inviteButton = new KDButtonView
      cssClass  : 'clean-gray fr'
      title     : 'Send invitation'
      callback  : =>
        @getDelegate().emit 'InvitationIsSent', invitationRequest

    @getData().on 'update', => @updateStatus()

    @updateStatus()

  updateStatus:->
    isSent = @getData().sent
    @[if isSent then 'setClass' else 'unsetClass'] 'invitation-sent'
    @inviteButton.disable()  if isSent

  viewAppended: JView::viewAppended

  pistachio:->
    """
    <div class="fl">
      <span class="avatar">{{> @avatar}}</span>
      <div class="request">
        <div class="username">{{#(koding.username)}}</div>
        <div class="requested-at">Requested on {{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
        <div class="is-sent">Status is <span class='status'>{{(#(status) is 'sent' and '✓ Sent') or 'Requested'}}</span></div>
      </div>
    </div>
    {{> @inviteButton}}
    """

class GroupApprovalRequestListItemView extends GroupsInvitationRequestListItemView

  constructor:->
    super

    invitationRequest = @getData()

    @approveButton = new KDButtonView
      cssClass  : 'cupid-green'
      title     : 'Approve'
      callback  : =>
        @getDelegate().emit 'RequestIsApproved', invitationRequest
    
    @declineButton = new KDButtonView
      cssClass  : 'clean-red'
      title     : 'Decline'
      callback  : =>
        @getDelegate().emit 'RequestIsDeclined', invitationRequest

  hideButtons:->
    @approveButton.hide()
    @declineButton.hide()

  showButtons:->
    @approveButton.show()
    @declineButton.show()

  initializeButtons:->

    invitationRequest = @getData()

    if invitationRequest.status in ['approved','declined']
      @hideButtons()
    else
      @showButtons()


  viewAppended:->
    super
    @initializeButtons()
    @getData().on 'update', @bound 'initializeButtons'

  getStatusText:(status)->
    switch status
      when 'approved' then '✓ Approved'
      when 'pending'  then '… Pending'
      when 'declined' then '✗ Declined'

  pistachio:->
    """
    <div class="fl">
      <span class="avatar">{{> @avatar}}</span>
      <div class="request">
        <div class="username">{{#(koding.username)}}</div>
        <div class="requested-at">Requested on {{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
        <div class="is-sent">Status is <span class='status'>{{@getStatusText #(status)}}</span></div>
      </div>
    </div>
    <div class="fr">{{> @approveButton}} {{> @declineButton}}</div>
    """


class GroupsRequestView extends JView

  prepareBulkInvitations:->
    group = @getData()
    group.countPendingInvitationRequests (err, count)=>
      if err then console.error error
      else
        [toBe, people] = if count is 1 then ['is','person'] else ['are','people']
        @currentState.updatePartial """
          There #{toBe} currently #{count} #{people} waiting for an invitation
          """

  fetchSomeRequests:(invitationType='invitation', callback)->

    group = @getData()

    selector  = { timestamp: $gte: @timestamp }
    options   =
      targetOptions : { selector: { invitationType } }
      sort          : { timestamp: -1 }
      limit         : 20

    group.fetchInvitationRequests selector, options, callback

class GroupsApprovalRequestsView extends GroupsRequestView

  constructor:->
    super

    group = @getData()

    @timestamp = new Date 0

    @currentState = new KDView
      partial : 'chris sez'

    @batchInvites = new KDView
      partial : 'chris sez again'

    @requestListController = new KDListViewController
      viewOptions     :
        cssClass      : 'requests-list'
      itemClass       : GroupApprovalRequestListItemView

    @pendingRequestsView = @requestListController.getListView()

    @pendingRequestsView.on 'RequestIsApproved', (invitationRequest)=>
      @emit 'RequestIsApproved', invitationRequest

    @pendingRequestsView.on 'RequestIsDeclined', (invitationRequest)=>
      @emit 'RequestIsDeclined', invitationRequest

    @fetchSomeRequests 'basic approval', (err, requests)=>
      if err then console.error err
      else
        @requestListController.instantiateListItems requests.reverse()

    @chris = new KDView
      partial: 'chris'
      click:=> group; debugger

  pistachio:->
    """
    <section class="formline">
      <h2>Status quo</h2>
      {{> @currentState}}
    </section>
    <div class="formline">
    <section class="formline batch">
      <h2>Invite members by batch</h2>
      {{> @batchInvites}}
    </section>
    </div>
    <div class="formline">
    <section class="formline pending">
      <h2>Pending approval</h2>
      {{> @pendingRequestsView}}
    </section>
    {{> @chris}}
    </div>
    """

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
    @requestList.on 'InvitationIsSent', (invitationRequest)=>
      @emit 'InvitationIsSent', invitationRequest

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
      <h2>Sent Invitations</h2>
      {{> @sentRequestList}}
    </section>
    <section class="formline pending">
      <h2>Pending Invitations</h2>
      {{> @requestList}}
    </section>
    </div>
    """

class GroupsMemberPermissionsView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "groups-member-permissions-view"

    super

    groupData       = @getData()

    @listController = new KDListViewController
      itemClass     : GroupsMemberPermissionsListItemView
    @listWrapper    = @listController.getView()

    @loader         = new KDLoaderView
      cssClass      : 'loader'
    @loaderText     = new KDView
      partial       : 'Loading Member Permissions…'
      cssClass      : ' loader-text'

    @listController.getListView().on 'ItemWasAdded', (view)=>
      view.on 'RolesChanged', @bound 'memberRolesChange'

    list = @listController.getListView()
    list.getOptions().group = groupData
    groupData.fetchRoles (err, roles)=>
      if err then warn err
      else
        list.getOptions().roles = roles
        groupData.fetchUserRoles (err, userRoles)=>
          if err then warn err
          else
            userRolesHash = {}
            for userRole in userRoles
              userRolesHash[userRole.targetId] = userRole.as

            list.getOptions().userRoles = userRolesHash
            groupData.fetchMembers (err, members)=>
              if err then warn err
              else
                @listController.instantiateListItems members
                @loader.hide()
                @loaderText.hide()

  memberRolesChange:(member, roles)->
    @getData().changeMemberRoles member.getId(), roles, (err)-> console.log {arguments}

  viewAppended:->
    super
    @loader.show()
    @loaderText.show()

  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    {{> @listWrapper}}
    """

class GroupsMemberPermissionsListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = 'formline clearfix'
    options.type     = 'member-item'

    super options, data

    data               = @getData()
    list               = @getDelegate()
    {roles, userRoles} = list.getOptions()
    @avatar            = new AvatarStaticView {}, data
    @profileLink       = new ProfileTextView {}, data
    @usersRole         = userRoles[data.getId()]

    @userRole          = new KDCustomHTMLView
      partial          : "Roles: "+@usersRole
      cssClass         : 'ib role'

    @editLink          = new CustomLinkView
      title            : 'Edit'
      cssClass         : 'fr edit-link'
      icon             :
        cssClass       : 'edit'
      click            : @bound 'showEditMemberRolesView'

    @saveLink          = new CustomLinkView
      title            : 'Save'
      cssClass         : 'fr hidden save-link'
      icon             :
        cssClass       : 'save'
      click            : =>
        @emit 'RolesChanged', @getData(), @editView.getSelectedRoles()
        @hideEditMemberRolesView()
        log "save"

    @cancelLink        = new CustomLinkView
      title            : 'Cancel'
      cssClass         : 'fr hidden cancel-link'
      icon             :
        cssClass       : 'delete'
      click            : @bound 'hideEditMemberRolesView'

    @editContainer     = new KDView
      cssClass         : 'edit-container hidden'

    list.on "EditMemberRolesViewShown", (listItem)=>
      if listItem isnt @
        @hideEditMemberRolesView()

  showEditMemberRolesView:->

    list           = @getDelegate()
    @editView       = new GroupsMemberRolesEditView delegate : @
    @editView.setMember @getData()
    editorsRoles   = list.getOptions().editorsRoles
    {group, roles} = list.getOptions()
    list.emit "EditMemberRolesViewShown", @

    @editLink.hide()
    @cancelLink.show()
    @saveLink.show()  unless KD.whoami().getId() is @getData().getId()
    @editContainer.show()
    @editContainer.addSubView @editView

    unless editorsRoles
      group.fetchMyRoles (err, editorsRoles)=>
        if err
          log err
        else
          list.getOptions().editorsRoles = editorsRoles
          @editView.setRoles editorsRoles, roles
          @editView.addViews()
    else
      @editView.setRoles editorsRoles, roles
      @editView.addViews()

  hideEditMemberRolesView:->

    @editLink.show()
    @cancelLink.hide()
    @saveLink.hide()
    @editContainer.hide()
    @editContainer.destroySubViews()

  viewAppended:JView::viewAppended

  pistachio:->
    """
    <section>
      <span class="avatar">{{> @avatar}}</span>
      {{> @editLink}}
      {{> @saveLink}}
      {{> @cancelLink}}
      {{> @profileLink}}
      {{> @userRole}}
    </section>
    {{> @editContainer}}
    """

class GroupsMemberRolesEditView extends JView

  constructor:(options = {}, data)->

    super

    @loader   = new KDLoaderView
      size    :
        width : 22

  setRoles:(editorsRoles, allRoles)->
    allRoles = allRoles.reduce (acc, role)->
      acc.push role.title  unless role.title in ['owner', 'guest']
      return acc
    , []

    @roles      = {
      usersRole    : @getDelegate().usersRole
      allRoles
      editorsRoles
    }

  setMember:(@member)->

  getSelectedRoles:->
    [@radioGroup.getValue()]

  addViews:->

    @loader.hide()

    isMe = KD.whoami().getId() is @member.getId()

    @radioGroup = new KDInputRadioGroup
      name          : 'user-role'
      defaultValue  : @roles.usersRole
      radios        : @roles.allRoles.map (role)->
        value       : role
        title       : role.capitalize()
      disabled      : isMe

    @addSubView @radioGroup, '.radios'

    @addSubView (new KDButtonView
      title    : "Make Owner"
      cssClass : 'modal-clean-gray'
      callback : -> log "Transfer Ownership"
      disabled : isMe
    ), '.buttons'

    @addSubView (new KDButtonView
      title    : "Kick"
      cssClass : 'modal-clean-red'
      callback : -> log "Kick user"
      disabled : isMe
    ), '.buttons'

    @$('.buttons').removeClass 'hidden'


  pistachio:->
    """
    {{> @loader}}
    <div class='radios'/>
    <div class='buttons hidden'/>
    """

  viewAppended:->

    super

    @loader.show()

class GroupsMembershipPolicyTabView extends KDView
  constructor:(options,data)->
    super options,data

    @setClass 'Membership Policy'

    @loader           = new KDLoaderView
      cssClass        : 'loader'
    @loaderText       = new KDView
      partial         : 'Loading Membership Policy…'
      cssClass        : ' loader-text'

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()
    @loader.show()
    @loaderText.show()

    # {{> @tabView}}
  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    """

