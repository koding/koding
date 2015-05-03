CustomLinkView  = require './../core/customlinkview'
MainHeaderView  = require './../core/mainheaderview'
LoginInlineForm = require './../login/loginform'
JView           = require './../core/jview'

module.exports = class TeamView extends JView

  constructor:(options = {}, data)->

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

    @loginForm = new LoginInlineForm
      cssClass : 'login-form'
      testPath : 'login-form'
      callback : (formData) =>
        mainController.on 'LoginFailed', => @loginForm.button.hideLoader()
        mainController.login formData

    @loginForm.button.unsetClass 'solid medium green'
    @loginForm.button.setClass 'SignupForm-button SignupForm-button--green'

    @invitationLink = new CustomLinkView
      cssClass    : 'invitation-link'
      title       : 'Ask for an invite'
      testPath    : 'landing-recover-password'
      href        : '/Recover'


  pistachio: ->

    """
    {{> @header }}
    <div class="SignupForm">
      {{> @logo}}
      <h4>Sign in to #{KD.config.group.title}</h4>
      {{> @loginForm}}
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