JView               = require './../../core/jview'
CustomLinkView      = require './../../core/customlinkview'
MainHeaderView      = require './../../core/mainheaderview'
TeamRegisterTabForm = require './../forms/teamregistertabform'

module.exports = class TeamRegisterTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Features',    href : '/Features',                name : 'features' }
      ]

    @logo = KD.utils.getGroupLogo()

    # keep the prop name @form it is used in AppView to focus to the form if there is any - SY
    @form = new TeamRegisterTabForm
      cssClass : 'login-form clearfix'
      testPath : 'login-form'
      callback : (formData) =>
        console.log formData

    @form.button.setTitle 'Join'

  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--login">
      {{> @logo}}
      <h4><span>Join to</span> #{KD.config.group.title}</h4>
      {{> @form}}
    </div>
    <section>
      <p>Already a member? Go back to team's <a href="/">login page</a>.</p>
      <p>Trying to create a team? <a href="/Teams">Sign up on the home page</a> to get started.</p>
    </section>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a>
    </footer>
    """