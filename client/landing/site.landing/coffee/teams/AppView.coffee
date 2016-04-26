kd              = require 'kd'
utils           = require './../core/utils'
MainHeaderView  = require './../core/mainheaderview'
JView           = require './../core/jview'
TeamsSignupForm = require './teamssignupform'

track = (action) ->

  category = 'TeamSignup'
  label    = 'SignupForm'
  utils.analytics.track action, { category, label }

module.exports = class TeamsView extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : [
        { title : 'Features', href : '/Features',               name : 'features' }
        { title : 'Docs',     href : '/Docs',                   name : 'docs' }
        { title : 'Pricing',  href : '/Pricing',                name : 'pricing' }
        { title : 'Blog',     href : 'http://blog.koding.com',  name : 'blog' }
        { title : 'Login',    href : '/Teams',                  name : 'login' }
      ]

    @form = new TeamsSignupForm
      cssClass : 'login-form'
      callback : (formData) ->

        track 'submitted signup form', { category: 'TeamSignUp' }

        finalize = (email) ->
          utils.storeNewTeamData 'signup', formData
          kd.singletons.router.handleRoute '/Team/Domain'

          unless email
            utils.storeNewTeamData 'profile', null
            return

          utils.getProfile email,
            error   : ->
              utils.storeNewTeamData 'profile', null
            success : (profile) ->
              utils.storeNewTeamData 'profile', profile

        { email } = formData
        utils.validateEmail { email },
          success : ->
            track 'entered an unregistered email'
            formData.alreadyMember = no
            finalize()

          error : ->
            track 'entered a registered email'
            formData.alreadyMember = yes
            finalize email


  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--create">
      <h4>Let's sign you up!</h4>
      <h5>Let us know what your email is so we can start the process.</h5>
      {{> @form}}
    </div>
    '''
