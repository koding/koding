class HomeLoginBar extends JView

  requiresLogin = (callback)->
    KD.requireLogin {callback, tryAgain: yes}

  constructor:(options = {}, data)->

    {entryPoint} = KD.config
    options.cssClass   = "home-links"

    super options, data

    handler = (event)->
      route = this.$()[0].getAttribute 'href'
      @utils.stopDOMEvent event
      @getSingleton('router').handleRoute route, {entryPoint}

    @register     = new CustomLinkView
      tagName     : "a"
      cssClass    : "register"
      title       : "Register an Account"
      icon        : {}
      attributes  :
        href      : "/Register"
      click       : (event)=> handler.call @register, event

    @browse       = new CustomLinkView
      tagName     : "a"
      cssClass    : "browse orange"
      title       : "Learn more..."
      icon        : {}
      attributes  :
        href      : ""
      click       : (event)=>
        @utils.stopDOMEvent event
        @getSingleton('mainViewController').emit "browseRequested"

    @request      = new CustomLinkView
      tagName     : "a"
      cssClass    : "join green"
      title       : "Request an Invite"
      icon        : {}
      attributes  :
        href      : "/Join"
      click       : (event)=>
        @utils.stopDOMEvent event
        {entryPoint} = KD.config
        if entryPoint
          requiresLogin =>
            @getSingleton('mainController').emit "groupAccessRequested", @group, @policy, (err)=>
              unless err
                @request.hide()
                @requested.show()
        else
          @getSingleton('router').handleRoute "/Join", {entryPoint}

    @login        = new CustomLinkView
      tagName     : "a"
      title       : "Login"
      icon        : {}
      cssClass    : "login"
      attributes  :
        href      : "/Login"
      click       : (event)=>
        @utils.stopDOMEvent event
        @getSingleton('router').handleRoute "/Login"

    @access       = new CustomLinkView
      tagName     : "a"
      title       : "Request access"
      icon        : {}
      cssClass    : "request green hidden"
      attributes  :
        href      : "#"
      click       : (event)=>
        @utils.stopDOMEvent event
        requiresLogin =>
          @getSingleton('mainController').emit "groupAccessRequested", @group, @policy, (err)=>
            unless err
              @access.hide()
              @requested.show()

    @join         = new CustomLinkView
      tagName     : "a"
      title       : "Join Group"
      icon        : {}
      cssClass    : "join green hidden"
      attributes  :
        href      : "#"
      click       : (event)=>
        @utils.stopDOMEvent event
        requiresLogin => @getSingleton('mainController').emit "groupJoinRequested", @group

    @requested    = new CustomLinkView
      tagName     : "a"
      title       : "Request pending"
      icon        : {}
      cssClass    : "request-pending green hidden"
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
              Okay         :
                style      : 'modal-clean-green'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : -> modal.destroy()
              Cancel       :
                title      : 'Cancel Request'
                style      : 'modal-clean-red'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @getSingleton('mainController').emit 'groupRequestCancelled', @group, (err)=>
                    modal.buttons.Cancel.hideLoader()
                    @handleBackendResponse err, 'Successfully cancelled request!'
                    modal.destroy()
                    @requested.hide()
                    if @policy.approvalEnabled
                      @access.show()
                    else
                      @request.show()
              Dismiss      :
                style      : "modal-cancel"
                callback   : -> modal.destroy()

    @invited      = new CustomLinkView
      tagName     : "a"
      title       : "Invited"
      icon        : {}
      cssClass    : "invitation-pending green hidden"
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
                  @getSingleton('mainController').emit 'groupInvitationAccepted', @group, (err)=>
                    modal.buttons.Accept.hideLoader()
                    @handleBackendResponse err, 'Successfully accepted invitation!'
                    unless err
                      modal.destroy()
                      @hide()
              Ignore       :
                style      : 'modal-clean-red'
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @getSingleton('mainController').emit 'groupInvitationIgnored', @group, (err)=>
                    modal.buttons.Ignore.hideLoader()
                    @handleBackendResponse err, 'Successfully ignored invitation!'
                    unless err
                      @invited.hide()
                      if @policy.approvalEnabled
                        @access.show()
                      else
                        @request.show()
                      modal.destroy()
              Cancel       :
                style      : "modal-cancel"
                callback   : -> modal.destroy()

    @decorateButtons()
    @getSingleton('mainController').on 'AccountChanged', @bound 'decorateButtons'
    @getSingleton('mainController').on 'JoinedGroup', @bound 'hide'

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

              KD.whoami().getInvitationRequestByGroup @group, $in:['sent', 'pending'], (err, [request])=>
                return console.warn err if err
                return unless request
                @access.hide()
                @request.hide()
                if request.status is 'sent'
                  @invited.show()
                else
                  @requested.show()
    else
      @hide()

  viewAppended:->
    super
    @utils.wait 1000, @setClass.bind this, 'in'
    @$('.overlay').remove()

  pistachio:->
    """
    <div class='overlay'></div>
    <ul>
      <li>{{> @browse}}</li>
      <li>{{> @request}}{{> @access}}{{> @join}}{{> @invited}}{{> @requested}}</li>
      <li>{{> @register}}</li>
      <li>{{> @login}}</li>
    </ul>
    """
