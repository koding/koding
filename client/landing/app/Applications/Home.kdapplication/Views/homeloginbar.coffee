class HomeLoginBar extends JView

  constructor:(options = {}, data)->

    options.cssClass   = "home-links"
    options.entryPoint = KD.config.profileEntryPoint or KD.config.groupEntryPoint

    super options, data

    entryPoint = @getOptions().entryPoint or ''

    handler = (event)->
      route = this.$()[0].getAttribute 'href'
      route = "/#{entryPoint}#{route}" if entryPoint isnt ''
      @utils.stopDOMEvent event
      @getSingleton('router').handleRoute route

    @register     = new CustomLinkView
      tagName     : "a"
      cssClass    : "register"
      title       : "Register an Account"
      icon        : {}
      attributes  :
        href      : "/Register"
      click       : handler

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
      click       : handler

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
        log "request access"

    @join         = new CustomLinkView
      tagName     : "a"
      title       : "Join group"
      icon        : {}
      cssClass    : "join green hidden"
      attributes  :
        href      : "#"
      click       : (event)=>
        @utils.stopDOMEvent event
        log "join group"

    groupsController = @getSingleton "groupsController"
    {roles} = KD.config
    # if 'member' in roles or 'admin' in roles

    if entryPoint isnt ''
      KD.remote.cacheable entryPoint, (err, models)=>
        if err then callback err
        else if models?
          [group] = models
          if group.privacy is "public"
            @request.hide()
            @access.hide()
            @join.show()
          else if "private"
            KD.remote.api.JMembershipPolicy.byGroupSlug entryPoint, (err, policy)=>
              if err then console.warn err
              else if policy.approvalEnabled
                @request.hide()
                @join.hide()
                @access.show()
    else
      if KD.isLoggedIn()
        @hide()

  viewAppended:->
    super
    @$('.overlay').remove()

  pistachio:->
    """
    <div class='overlay'></div>
    <ul>
      <li>{{> @browse}}</li>
      <li>{{> @request}}{{> @access}}{{> @join}}</li>
      <li>{{> @register}}</li>
      <li>{{> @login}}</li>
    </ul>
    """
