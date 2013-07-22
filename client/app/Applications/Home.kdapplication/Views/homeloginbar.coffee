class HomeLoginBar extends JView

  requiresLogin = (callback)->
    KD.requireMembership {callback, tryAgain: yes}

  constructor:(options = {}, data)->

    {entryPoint} = KD.config
    options.cssClass   = "home-links"

    super options, data

    @appManager = KD.getSingleton('appManager')

    handler = (event)->
      route = this.$()[0].getAttribute 'href'
      @utils.stopDOMEvent event
      KD.getSingleton('router').handleRoute route, {entryPoint}

    @register     = new CustomLinkView
      tagName     : "a"
      cssClass    : "register"
      title       : "Have an invite code? Register!"
      icon        : {}
      attributes  :
        href      : "/Register"
      click       : (event)=>
        handler.call @register, event
        KD.track "Login", "Register"

    @request      = new CustomLinkView
      tagName     : "a"
      cssClass    : "join green button"
      title       : "Request an Invite"
      icon        : {}
      attributes  :
        href      : "/Join"
      click       : (event)=>
        KD.track "Login", "RequestInvite"
        @utils.stopDOMEvent event
        {entryPoint} = KD.config
        if entryPoint
          requiresLogin =>
            @appManager.tell 'Groups', "showRequestAccessModal", @group, @policy, (err)=>
              unless err
                @request.hide()
                @requested.show()
        else
          KD.getSingleton('router').handleRoute "/Join", {entryPoint}

    @login        = new CustomLinkView
      tagName     : "a"
      title       : "Already a user? Sign In!"
      icon        : {}
      cssClass    : "login"
      attributes  :
        href      : "/Login"
      click       : (event)=>
        KD.track "Login", "AlreadyUser", @group.slug
        @utils.stopDOMEvent event
        KD.getSingleton('router').handleRoute "/Login"

    @access       = new CustomLinkView
      tagName     : "a"
      title       : "Request access"
      icon        : {}
      cssClass    : "request green hidden button"
      attributes  :
        href      : "#"
      click       : (event)=>
        KD.track "Login", "GroupAccessRequest", @group.slug
        @utils.stopDOMEvent event
        requiresLogin =>
          @appManager.tell 'Groups', "showRequestAccessModal", @group, @policy, (err)=>
            unless err
              @access.hide()
              @requested.show()
              @listenToApproval()

    @join         = new CustomLinkView
      tagName     : "a"
      title       : "Join Group"
      icon        : {}
      cssClass    : "join green hidden button"
      attributes  :
        href      : "#"
      click       : (event)=>
        KD.track "Login", "GroupJoinRequest", @group.slug
        @utils.stopDOMEvent event
        requiresLogin => @appManager.tell 'Groups', "joinGroup", @group

    @requested    = new CustomLinkView
      tagName     : "a"
      title       : "Request pending"
      icon        : {}
      cssClass    : "request-pending green hidden button"
      attributes  :
        href      : "#"
      click       : (event)=>
        @utils.stopDOMEvent event
        requiresLogin =>
          modal = new KDModalView
            title          : 'Request pending'
            content        : "<div class='modalformline'>You already requested access to this group, however the admin has not approved it yet.</div>"
            height         : 'auto'
            overlay        : yes
            buttons        :
              Dismiss      :
                style      : 'modal-clean-green'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : ->
                  modal.destroy()
                  KD.track "Login", "GroupJoinRequestDismiss", @group.slug

              Cancel       :
                title      : 'Cancel Request'
                style      : 'modal-clean-red'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @appManager.tell 'Groups', 'cancelGroupRequest', @group, (err)=>
                    modal.buttons.Cancel.hideLoader()
                    @handleBackendResponse err, 'Successfully cancelled request!'
                    modal.destroy()
                    @requested.hide()
                    if @policy.approvalEnabled
                    then @access.show()
                    else @request.show()
                    KD.track "Login", "GroupJoinRequestCancel", @group.slug unless err

    @invited      = new CustomLinkView
      tagName     : "a"
      title       : "Invited"
      icon        : {}
      cssClass    : "invitation-pending green hidden button"
      attributes  :
        href      : "#"
      click       : (event)=>
        @utils.stopDOMEvent event
        requiresLogin =>
          modal = new KDModalView
            title          : 'Invitation pending'
            content        : "<div class='modalformline'>You are invited to join this group.</div>"
            height         : 'auto'
            overlay        : yes
            buttons        :
              Accept       :
                style      : 'modal-clean-green'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @appManager.tell 'Groups', 'acceptInvitation', @group, (err)=>
                    modal.buttons.Accept.hideLoader()
                    @handleBackendResponse err, 'Successfully accepted invitation!'
                    unless err
                      modal.destroy()
                      @hide()
                      KD.track "Login", "GroupInviteRequestAccept", @group.slug

              Ignore       :
                style      : 'modal-clean-red'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @appManager.tell 'Groups', 'ignoreInvitation', @group, (err)=>
                    modal.buttons.Ignore.hideLoader()
                    @handleBackendResponse err, 'Successfully ignored invitation!'
                    unless err
                      @invited.hide()
                      if @policy.approvalEnabled
                        @access.show()
                      else
                        @request.show()
                      modal.destroy()
                      KD.track "Login", "GroupInviteRequestIgnore", @group.slug
              Cancel       :
                style      : "modal-cancel"
                callback   : -> modal.destroy()

    @decorateButtons()
    KD.getSingleton('mainController').on 'AccountChanged', @bound 'decorateButtons'
    KD.getSingleton('mainController').on 'JoinedGroup', @bound 'hide'

  handleBackendResponse:(err, successMsg)->
    if err
      warn err
      return new KDNotificationView
        title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
        duration : 2000

    new KDNotificationView
      title    : successMsg
      duration : 2000

  decorateButtons:->

    {entryPoint} = KD.config
    entryPoint or=
      slug       : "koding"
      type       : "group"

    if entryPoint?.type is 'profile'
      if KD.isLoggedIn() then @hide()
      else @request.hide()
      return

    if 'member' not in KD.config.roles
      if KD.isLoggedIn()
        @login.hide()
        @register.hide()

      KD.remote.cacheable entryPoint.slug, (err, models)=>
        if err then callback err
        else if models?
          [@group] = models
          if @group.privacy is "public"
            @request.hide()
            @access.hide()
            @join.show()
          else if @group.privacy is "private"
            KD.remote.api.JMembershipPolicy.byGroupSlug entryPoint.slug, (err, policy)=>
              @policy = policy
              if err then console.warn err
              else if policy.approvalEnabled
                @request.hide()
                @join.hide()
                @access.show()

              return  unless KD.isLoggedIn()

              @group.on 'MemberAdded', @emit.bind this, 'MemberAdded'

              KD.whoami().getInvitationRequestByGroup @group, $in:['sent', 'pending'], (err, [request])=>
                return console.warn err if err
                return unless request
                @access.hide()
                @request.hide()
                if request.status is 'sent'
                  @invited.show()
                else
                  @listenToApproval()
                  @requested.show()
    else
      @hide()

  listenToApproval:->
    @once 'MemberAdded', @listenToApprovalCallback ?= =>
      @group.fetchMyRoles (err, roles)=>
        return warn err  if err
        if 'member' not in roles
          return @once 'MemberAdded', @listenToApprovalCallback
        KD.getSingleton('mainController').accountChanged KD.whoami()

  viewAppended:->
    super
    @utils.wait 1000, @setClass.bind this, 'in'
    @$('.overlay').remove()

  pistachio:->
    """
    <div class='overlay'></div>
    <ul>
      <li>{{> @request}}{{> @access}}{{> @join}}{{> @invited}}{{> @requested}}</li>
      <li>
        {{> @register}}
        {{> @login}}
      </li>
    </ul>
    """
