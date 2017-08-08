kd              = require 'kd'
utils           = require './../../core/utils'

MainHeaderView  = require './../../core/mainheaderview'
LoginInlineForm = require './../../login/loginform'
Encoder         = require 'htmlencode'

track = (action, properties = {}) ->

  properties.category = 'Team'
  properties.label    = 'LoginForm'
  utils.analytics.track action, properties


module.exports = class TeamLoginTab extends kd.TabPaneView



  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    { group } = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @logo = utils.getGroupLogo()


    # keep the prop name @form it is used in AppView to focus to the form if there is any - SY
    @form = new LoginInlineForm
      cssClass : 'login-form clearfix'
      testPath : 'login-form'
      callback : (formData) =>
        track 'submitted login form'
        mainController.on 'LoginFailed', => @form.button.hideLoader()

        formData.redirectTo = utils.getLoginRedirectPath '/Team'

        mainController.login formData, (err) =>
          track 'failed to login'  if err
          @form.button.hideLoader()
          @form.tfcode.show()
          @form.tfcode.setFocus()

    if group.config?.gitlab?.enabled
      @form.gitlabLogin.show()

    if group.config?.github?.enabled
      @form.githubLogin.show()

    ['button', 'gitlabButton', 'githubButton'].forEach (button) =>
      @form[button].unsetClass 'solid medium green'
      @form[button].setClass 'TeamsModal-button'

    if location.search isnt '' and location.search.search('username=') > 0
      username = location.search.split('username=').last.replace(/\&.+/, '') # trim the rest params if any
      @form.username.input.setValue decodeURIComponent username  # decode in case it is an email

    @inviteDesc = new kd.CustomHTMLView
      tagName : 'p'
      partial : "<p>To be able to login to <a href='/'>#{kd.config.groupName}.#{kd.config.domains.main}</a>, you need to be invited by team administrators.</p>"

    domains = group.allowedDomains

    return  if not domains or not domains.first

    partial =
    if /\*/.test kd.config.group.allowedDomains
      "If you don't have a Koding account <a href='/Invitation'>sign up here</a> so you can join #{kd.config.groupName}!"
    else if domains.length > 1
      domainsPartial = utils.getAllowedDomainsPartial domains
      "If you have an email address from one of these domains #{domainsPartial}, you can <a href='/Team/Join'>join here</a>."
    else
      "If you have a <i>#{domains.first}</i> email address, you can <a href='/Team/Join'>join here</a>."

    @inviteDesc.updatePartial partial


  pistachio: ->

    # this is to make sure that already created teams with problematic names
    # are not causing any problems as well. ~Umut
    title   = Encoder.htmlEncode Encoder.htmlDecode kd.config.group.title
    hasLogo = not @logo.hasClass 'hidden'

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--login #{if hasLogo then 'with-avatar' else ''}">
      {{> @logo}}
      <h4><span>Sign in to</span> #{title}</h4>
      {{> @form}}
    </div>
    <section class="additional-info">
      {{> @inviteDesc}}
      <p>Trying to create a team? <a href="/Teams/Create" target="_self">Sign up on the home page</a> to get started.</p>
      <p>Forgot your password? <a href='/Team/Recover'>Click here</a> to reset.</p>
    </section>
    """
