class GroupsMembershipPolicyDetailView extends JView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    super options, data

    @setClass 'policy-view-wrapper'

    group = @getData()
    group.fetchMembershipPolicy (err, policy)=>
      if err
        new KDNotificationView { title: err.message, duration: 1000 }
      else
        @on 'MembershipPolicyChanged', (formData)->
          KD.getSingleton('appManager').tell 'Groups',
            'updateMembershipPolicy', group, policy, formData

        @createSubViews policy

  createSubViews:(policy)->

    {webhookEndpoint, approvalEnabled, dataCollectionEnabled} = policy
    webhookExists = !!(webhookEndpoint and webhookEndpoint.length)

    # @enableInvitations = new KDOnOffSwitch
    #   defaultValue  : invitationsEnabled
    #   callback      : (state) =>
    #     @emit 'MembershipPolicyChanged', invitationsEnabled: state

    @enableAccessRequests = new KodingSwitch
      defaultValue  : approvalEnabled
      callback      : (state) =>
        @emit 'MembershipPolicyChanged', approvalEnabled: state

    @enableDataCollection = new KodingSwitch
      defaultValue  : dataCollectionEnabled
      callback      : (state)=>
        if state
          @enableDataCollection.setValue no
          return new KDNotificationView title : "Currently disabled!"
        @emit 'MembershipPolicyChanged', dataCollectionEnabled: state
        @formGenerator[if state then 'show' else 'hide']()

    @enableWebhooks = new KodingSwitch
      defaultValue  : webhookExists
      callback      : (state) =>
        if state
          @enableWebhooks.setValue no
          return new KDNotificationView title : "Currently disabled!"
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
      console.log 'saved', @getData()
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

    if webhookExists
      @webhookEditor.setValue webhookEndpoint
      @webhook.show()

    policyLanguageExists = policy.explanation

    @showPolicyLanguageLink = new KDButtonView
      style     : "solid green"
      cssClass  : "edit-link #{if policyLanguageExists then 'hidden' else ''}"
      title     : 'Edit'
      callback  :=>
        return new KDNotificationView title : "Currently disabled!"
        # Following two lines makes enable editing policy language.
        # @showPolicyLanguageLink.hide()
        # @policyLanguageEditor.show()

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

    @formGenerator = new GroupsFormGeneratorView
      cssClass : unless dataCollectionEnabled then 'hidden'
      delegate : @
    , policy

    @subViewsCreated = yes
    JView::viewAppended.call this

  pistachio:->
    if @subViewsCreated
      """
      <div class="policy-overlay"></div>
      <p class="coming-soon"><span class="icon"></span>Coming Soon</p>
      {{> @enableAccessRequests}}
      <section class="formline">
        <h2>Users may request access</h2>
        <div class="formline">
          <p>If you disable this feature, users will not be able to request
          access to this group.  Turn this off to globally disable new
          invitations and approval requests.</p>
        </div>
      </section>
      {{> @enableDataCollection}}
      <section class="formline">
        <h2>Enable data collection</h2>
        <div class="formline">
          <p>This will allow you to collect additional data from users who
          request access to your group.</p>
        </div>

        {{> @formGenerator}}
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
      <section class="formline clearfix">
        <h2>Policy language</h2>
        <div class="formline">
          <p>It's possible to compose custom policy language (copy) to help your
          users better understand how they may become members of your group.</p>
          <p>The screenshot on the right shows where this text will be presented to the user.</p>
          <p>If you wish, you may click 'Edit' to the left and then enter custom language below (markdown is OK):</p>
        </div>
        {{> @policyLanguageEditor}}
      </section>
      """
