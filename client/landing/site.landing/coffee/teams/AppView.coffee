kd = require 'kd.js'
MainHeaderView  = require './../core/mainheaderview'
JView           = require './../core/jview'
TeamsSignupForm = require './teamssignupform'

module.exports = class TeamsView extends JView


  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Blog',        href : 'http://blog.koding.com',   name : 'blog' }
        { title : 'Features',    href : '/Features',                name : 'features' }
      ]

    @form = new TeamsSignupForm
      cssClass : 'login-form'
      callback : (formData) ->

        track 'submitted signup form', { category: 'TeamSignUp' }

        finalize = (email) ->
          kd.utils.storeNewTeamData 'signup', formData
          kd.singletons.router.handleRoute '/Team/Domain'

          return  unless email

          kd.utils.getProfile email,
            error   : ->
            success : (profile) ->
              formData.profile = profile  if profile
              kd.utils.storeNewTeamData 'signup', formData

        { email } = formData
        kd.utils.validateEmail { email },
          success : ->
            track 'entered an unregistered email'
            formData.alreadyMember = no
            finalize()

          error : ->
            track 'entered a registered email'
            formData.alreadyMember = yes
            finalize email


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--create">
      <h4>Create a team</h4>
      {{> @form}}
    </div>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a>
    </footer>
    """


track = (action) ->

  category = 'TeamSignup'
  label    = 'SignupForm'
  kd.utils.analytics.track action, { category, label }
