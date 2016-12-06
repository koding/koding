kd              = require 'kd'
utils           = require './../../core/utils'
TeamJoinTabForm = require './../forms/teamjointabform'
LoginInputView  = require './../../login/logininputview'


module.exports = class TeamJoinBySignupForm extends TeamJoinTabForm

  constructor: (options = {}, data) ->

    teamData = utils.getTeamData()

    options.buttonTitle or= 'Sign up & join'
    options.email       or= teamData.invitation?.email

    super options, data

    @email = new LoginInputView
      inputOptions      :
        name            : 'email'
        label           : 'Email address'
        placeholder     : 'Enter your work email'
        defaultValue    : @getOption 'email'
        attributes      :
          autocomplete  : 'email'
        validate        :
          rules         : { email: yes }
          messages      : { email: 'Please type a valid email address.' }
          events        :
            regExp      : 'keyup'

    @username = new LoginInputView
      inputOptions       :
        label            : 'Your Username'
        placeholder      : 'Pick a username'
        name             : 'username'
        validate         :
          rules          :
            required     : yes
            rangeLength  : [4, 25]
            regExp       : /^[a-z\d]+([-][a-z\d]+)*$/i
          messages       :
            required     : 'Please enter a username.'
            regExp       : 'For username only lowercase letters and numbers are allowed!'
            rangeLength  : 'Username should be between 4 and 25 characters!'
          events         :
            regExp       : 'keyup'

    @passwordStrength = ps = new kd.CustomHTMLView
      tagName  : 'figure'
      cssClass : 'PasswordStrength'
      partial  : '<span></span>'

    # make this a reusable component - SY
    oldPass   = null
    @password = new LoginInputView
      inputOptions    :
        type          : 'password'
        name          : 'password'
        label         : 'Your Password'
        placeholder   : 'Set a password'
        attributes    :
          autocomplete : 'password'
        validate      :
          container   : this
          rules       :
            required  : yes
            minLength : 8
          messages    :
            required  : 'Please enter a password.'
            minLength : 'Passwords should be at least 8 characters.'
        keyup         : (event) ->
          pass     = @getValue()
          strength = ['bad', 'weak', 'moderate', 'good', 'excellent']

          return  if pass is oldPass
          if pass is ''
            ps.unsetClass strength.join ' '
            oldPass = null
            return

          utils.checkPasswordStrength pass, (err, report) ->
            oldPass = pass

            return if pass isnt report.password  # to avoid late responded ajax calls

            ps.unsetClass strength.join ' '
            ps.setClass strength[report.score]

    @button     = @getButton @getOption 'buttonTitle'
    @buttonLink = @getButtonLink 'Already have an account?', '#', (event) =>
      kd.utils.stopDOMEvent event
      return  unless event.target.tagName is 'A'
      @emit 'FormNeedsToBeChanged', yes, yes

    @on 'FormValidationFailed', @button.bound 'hideLoader'
    @on 'FormSubmitFailed',     @button.bound 'hideLoader'


  submit: (formData) ->

    teamData = utils.getTeamData()
    teamData.signup ?= {}
    teamData.signup.alreadyMember = no

    super formData


  pistachio: ->

    '''
    {{> @email}}
    {{> @username}}
    {{> @password}}
    {{> @passwordStrength}}
    {{> @button}}
    {{> @buttonLink}}
    '''
