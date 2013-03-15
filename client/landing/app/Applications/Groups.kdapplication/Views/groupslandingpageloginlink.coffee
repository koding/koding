
class GroupsLandingPageButton extends KDButtonView

  constructor:(options = {}, data)->
    options.cssClass ?= 'landing-button clean-gray'

    log options
    super

  setState:(@state)->

    log arguments

    options = @getOptions()

    if state.isMember
      @setTitle 'Go to group'
      options.href = "#{options.baseHref}/Activity"
      options.section = 'Activity'

    else if state.approvalEnabled
      @setTitle 'Request access'
      options.section = 'Join'
      options.href = "#{options.baseHref}/Join"

    else if not state.isLoggedIn

      @setTitle 'Login'
      options.section = 'Login'
      options.href = "#{options.baseHref}/Login"

    else
      @setTitle 'Return to Koding'
      options.href = 'https://koding.com'

    @setCallback =>

      @mc = @getSingleton 'mainController'

      section         = options.section
      groupEntryPoint = options.groupEntryPoint

      route =  "/#{groupEntryPoint}/#{section}"

      switch section
        when 'Join', 'Login'
          @mc.loginScreen.animateToForm 'login'
          @mc.loginScreen.addClass 'landed'
          @mc.loginScreen.headBannerShowGoBackGroup 'Pet Shop Boys'
          $('#group-landing').css 'height', 0
          # $('#group-landing').css 'opacity', 0

        when 'Activity'
          @mc.loginScreen.hide()
          KD.getSingleton('router').handleRoute route
          $('#group-landing').css 'height', 0

    # # FIXME GG
    # $('.group-login-buttons').css 'opacity', 1

class GroupsLandingPageLoginLink extends CustomLinkView

  constructor:(options, data)->
    {groupEntryPoint} = options
    options.cssClass  = 'bigLink'
    options.baseHref  = "/#{groupEntryPoint}"
    options.title    ?= ''
    super

  click:(event)->
    event.preventDefault()
    options = @getOptions()
    @emit 'LoginLinkRedirect',
      href              : options.attributes.href
      groupEntryPoint   : options.groupEntryPoint
      section           : options.section

  setState:(@state)->
    data = @getData()
    options = @getOptions()

    if state.isMember
      data.title = 'Go to group'
      options.attributes.href = "#{options.baseHref}/Activity"
      options.section = 'Activity'

    else if state.approvalEnabled
      data.title = 'Request access'
      options.section = 'Join'
      options.attributes.href = "#{options.baseHref}/Join"

    else
      data.title = 'Return to Koding'
      options.attributes.href = 'https://koding.com'

    @template.update()
    @getDomElement().attr 'href', options.attributes.href

    # FIXME GG
    $('.group-login-buttons').css 'opacity', 1
