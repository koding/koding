kd              = require 'kd.js'
utils           = require './../../core/utils'
JView           = require './../../core/jview'
CustomLinkView  = require './../../core/customlinkview'
MainHeaderView  = require './../../core/mainheaderview'
LoginInlineForm = require './../../login/loginform'

track = (action) ->

  category = 'Team'
  label    = 'LoginForm'
  utils.analytics.track action, { category, label }


module.exports = class TeamLoginTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Features',    href : '/Features',                name : 'features' }
      ]

    @logo = utils.getGroupLogo()

    # keep the prop name @form it is used in AppView to focus to the form if there is any - SY
    @form = new LoginInlineForm
      cssClass : 'login-form clearfix'
      testPath : 'login-form'
      callback : (formData) =>
        track 'submitted login form'
        mainController.on 'LoginFailed', => @form.button.hideLoader()
        mainController.login formData, (err) =>
          track 'failed to login'  if err
          @form.button.hideLoader()
          @form.tfcode.show()
          @form.tfcode.setFocus()

    @form.button.unsetClass 'solid medium green'
    @form.button.setClass 'TeamsModal-button TeamsModal-button--green'

    if location.search isnt '' and location.search.search('username=') > 0
      username = location.search.split('username=').last.replace(/\&.+/, '') # trim the rest params if any
      @form.username.input.setValue decodeURIComponent username  # decode in case it is an email
      @form.username.inputReceivedKeyup()

    @inviteDesc = new kd.CustomHTMLView
      tagName : 'p'
      partial : "<p>To be able to login to <a href='/'>#{kd.config.groupName}.koding.com</a>, you need to be invited by team administrators.</p>"

    domains = group.allowedDomains

    return  if not domains or not domains.first

    @inviteDesc.updatePartial if domains.length > 1
      domainsPartial = utils.getAllowedDomainsPartial domains
      "If you have an email address from one of these domains #{domainsPartial}, you can <a href='/Team/Join'>join here</a>."
    else "If you have a <i>#{domains.first}</i> email address, you can <a href='/Team/Join'>join here</a>."


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--login">
      {{> @logo}}
      <h4><span>Sign in to</span> #{kd.config.group.title}</h4>
      {{> @form}}
    </div>
    <section>
      {{> @inviteDesc}}
      <p>Trying to create a team? <a href="//#{utils.getMainDomain()}/Teams" target="_self">Sign up on the home page</a> to get started.</p>
    </section>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a>
    </footer>
    """
