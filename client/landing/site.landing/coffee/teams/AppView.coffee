CustomLinkView  = require './../core/customlinkview'
MainHeaderView  = require './../core/mainheaderview'
JView           = require './../core/jview'
FooterView      = require './../home/footerview'
TeamsSignupForm = require './teamssignupform'
TeamsLaunchForm = require './teamslaunchform'


module.exports = class TeamsView extends JView

  constructor:(options = {}, data)->

    super options, data

    { mainController, router } = KD.singletons

    @header = new MainHeaderView
      navItems : [
        { title : 'Blog',            href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Teams',           href : '/Teams',                   name : 'teams' }
        { title : 'Success Stories', href : '/Features',                name : 'success' }
        { title : 'SIGN IN',         href : '/Team/Login',              name : 'buttonized white login',  attributes : testpath : 'login-link' }
      ]

    if KD.config.hasTeamAccess
      @title = new KDCustomHTMLView
        tagName : 'h1'
        partial : "Koding for Teams!"

      @subTitle = new KDCustomHTMLView
        tagName : 'h2'
        partial : 'Onboard, develop, deploy, test and work together with your team right away, without a setup!'

      @form = new TeamsSignupForm
        cssClass : 'TeamsModal--middle login-form'
        callback : (formData) ->
          go = ->
            KD.utils.storeNewTeamData 'signup', formData
            KD.singletons.router.handleRoute '/Team/domain'

          { email } = formData
          KD.utils.validateEmail { email },
            success : -> formData.alreadyMember = no; go()
            error   : -> formData.alreadyMember = yes; go()
    else
      @title = new KDCustomHTMLView
        tagName : 'h1'
        partial : "Introducing Koding for Teams!"

      @subTitle = new KDCustomHTMLView
        tagName  : 'h2'
        partial  : "Your own Koding for your <span><i>company</i><i>university</i><i>class</i><i>project</i></span>"

      @form = new TeamsLaunchForm
        cssClass : 'TeamsModal--middle login-form pre-launch'
        callback : (formData) ->



  pistachio: ->

    """
    {{> @header }}
    <section class='main-wrapper'>
      {{> @title}}
      {{> @subTitle}}
      {{> @form}}
      <figure></figure>
    </section>
    """
