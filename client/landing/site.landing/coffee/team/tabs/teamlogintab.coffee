kd              = require 'kd'
utils           = require './../../core/utils'
JView           = require './../../core/jview'
MainHeaderView  = require './../../core/mainheaderview'
LoginInlineForm = require './../../login/loginform'
Encoder         = require 'htmlencode'

track = (action) ->

  category = 'Team'
  label    = 'LoginForm'
  utils.analytics.track action, { category, label }


module.exports = class TeamLoginTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

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

    ['button', 'gitlabButton'].forEach (button) =>
      @form[button].unsetClass 'solid medium green'
      @form[button].setClass 'TeamsModal-button TeamsModal-button--green TeamsModal-button--full'

    if location.search isnt '' and location.search.search('username=') > 0
      username = location.search.split('username=').last.replace(/\&.+/, '') # trim the rest params if any
      @form.username.input.setValue decodeURIComponent username  # decode in case it is an email
      @form.username.inputReceivedKeyup()

    @inviteDesc = new kd.CustomHTMLView
      tagName : 'p'
      partial : "<p>To be able to login to <a href='/'>#{kd.config.groupName}.#{kd.config.domains.main}</a>, you need to be invited by team administrators.</p>"

    domains = group.allowedDomains

    return  if not domains or not domains.first

    partial =
    if /\*/.test kd.config.group.allowedDomains
      "If you don't have a Koding account <a href='/Team/Join'>sign up here</a> so you can join #{kd.config.groupName}!"
    else if domains.length > 1
      domainsPartial = utils.getAllowedDomainsPartial domains
      "If you have an email address from one of these domains #{domainsPartial}, you can <a href='/Team/Join'>join here</a>."
    else
      "If you have a <i>#{domains.first}</i> email address, you can <a href='/Team/Join'>join here</a>."

    @inviteDesc.updatePartial partial


  pistachio: ->

    # this is to make sure that already created teams with problematic names
    # are not causing any problems as well. ~Umut
    title = Encoder.htmlEncode Encoder.htmlDecode kd.config.group.title

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--login">
      {{> @logo}}
      <h4><span>Sign in to</span> #{title}</h4>
      {{> @form}}
    </div>
    <section>
      {{> @inviteDesc}}
      <p>Trying to create a team? <a href="/Teams/Create" target="_self">Sign up on the home page</a> to get started.</p>
      <p>Forgot your password? <a href='/Team/Recover'>Click here</a> to reset.</p>
    </section>
    <footer>
      <a href="https://www.koding.com/legal/teams-user-policy" target="_blank">Acceptable user policy</a><a href="https://www.koding.com/legal/teams-copyright" target="_blank">Copyright/DMCA guidelines</a><a href="https://www.koding.com/legal/teams-terms-of-service" target="_blank">Terms of service</a><a href="https://www.koding.com/legal/teams-privacy" target="_blank">Privacy policy</a>
    </footer>
    """
