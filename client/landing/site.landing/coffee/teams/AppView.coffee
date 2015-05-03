CustomLinkView = require './../core/customlinkview'
MainHeaderView = require './../core/mainheaderview'
JView          = require './../core/jview'
FooterView     = require './../home/footerview'
TeamSignupForm = require './teamsignupform'


module.exports = class TeamsView extends JView

  constructor:(options = {}, data)->

    super options, data

    { mainController, router } = KD.singletons

    @header = new MainHeaderView
      navItems : [
        { title : 'Blog',            href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Success Stories', href : '/Features',                name : 'success' }
        { title : 'SIGN IN',         href : '/Team/Login',              name : 'buttonized white login',  attributes : testpath : 'login-link' }
      ]
    @form   = new TeamSignupForm cssClass : 'SignupForm--middle login-form'
    @footer = new FooterView


  pistachio: ->

    """
    {{> @header }}
    <section class='main-wrapper'>
      <h1>Koding for Teams</h1>
      <h2>Onboard, develop, deploy, test and work together with your team right away, without a setup!</h2>
      {{> @form}}
      <figure></figure>
    </section>
    {{> @footer}}
    """
