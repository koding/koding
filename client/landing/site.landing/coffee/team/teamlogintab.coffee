JView           = require './../core/jview'
CustomLinkView  = require './../core/customlinkview'
MainHeaderView  = require './../core/mainheaderview'
LoginInlineForm = require './../login/loginform'

module.exports = class TeamLoginTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'login'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Features',    href : '/Features',                name : 'features' }
      ]

    @logo = new KDCustomHTMLView tagName : 'figure'

    # set this once uploader ready - SY
    # @logo.setCss 'background-image', KD.config.group.backgroundImage

    # keep the prop name @form it is used in AppView to focus to the form if there is any - SY
    @form = new LoginInlineForm
      cssClass : 'login-form clearfix'
      testPath : 'login-form'
      callback : (formData) =>
        mainController.on 'LoginFailed', => @form.button.hideLoader()
        mainController.login formData

    @form.button.unsetClass 'solid medium green'
    @form.button.setClass 'TeamsModal-button TeamsModal-button--green'

    if location.search isnt '' and location.search.search('username=') > 0
      username = location.search.split('username=').last.replace(/\&.+/, '')
      @form.username.input.setValue username
      @form.username.inputReceivedKeyup()



    @invitationLink = new CustomLinkView
      cssClass    : 'invitation-link'
      title       : 'Ask for an invite'
      testPath    : 'landing-recover-password'
      href        : '/Recover'

  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--login">
      {{> @logo}}
      <h4><span>Sign in to</span> #{KD.config.group.title}</h4>
      {{> @form}}
    </div>
    <section>
      <p>
      To be able to login to #{KD.config.groupName}.koding.com, you need to be invited by team administrators.
      </p>
      <p>
      Trying to create a team? <a href="/Teams">Sign up on the home page</a> to get started.
      </p>
    </section>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a>
    </footer>
    """