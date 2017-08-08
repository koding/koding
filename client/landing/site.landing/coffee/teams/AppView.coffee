kd              = require 'kd'
utils           = require './../core/utils'
MainHeaderView  = require './../core/mainheaderview'

TeamsSignupForm = require './teamssignupform'

track = (action, properties = {}) ->

  properties.category = 'TeamSignup'
  properties.label    = 'SignupForm'
  utils.analytics.track action, properties

module.exports = class TeamsView extends kd.TabPaneView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'Team', options.cssClass

    super options, data

    { mainController } = kd.singletons
    { group }          = kd.config
    isEnterprise       = /type\=enterprise/.test location.search
    withDemo           = /demo\=on/.test location.search

    @header = new MainHeaderView { cssClass : 'team', navItems : [] }


    @form = new TeamsSignupForm
      cssClass : 'login-form'
      callback : (formData) ->

        { email, phone } = formData

        track 'started team signup', { contact: email }


        if isEnterprise and withDemo
          track 'started team signup enterprise with demo request', { contact: email, phone }
        else if isEnterprise
          track 'started team signup enterprise without demo request', { contact: email }


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

        utils.validateEmail { email },
          success : ->
            track 'entered an unregistered email'
            formData.alreadyMember = no
            finalize()

          error : ->
            track 'entered a registered email'
            formData.alreadyMember = yes
            finalize email

    @form.phone.show()  if isEnterprise and withDemo

  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--create">
      <h4>Let's sign you up!</h4>
      <h5>Let us know what your email and your team name are so we can start the process.</h5>
      {{> @form}}
    </div>
    <div class="ufo-bg"></div>
    <div class="ground-bg"></div>
    <div class="footer-bg"></div>
    '''
