class HomeLoginBar extends JView

  constructor:(options = {}, data)->

    options.cssClass = "home-links"

    super options, data

    if KD.config.profileEntryPoint? or KD.config.groupEntryPoint?
      entryPoint = KD.config.profileEntryPoint or KD.config.groupEntryPoint
    else entryPoint = ''

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

  pistachio:-> "{{> @browse}}{{> @request}}{{> @register}}{{> @login}}"
