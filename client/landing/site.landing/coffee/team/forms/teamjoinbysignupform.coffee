JView           = require './../../core/jview'
TeamJoinTabForm = require './../forms/teamjointabform'

module.exports = class TeamJoinBySignupForm extends TeamJoinTabForm

  constructor: ->

    super

    teamData = KD.utils.getTeamData()

    @email = new KDInputView
      name         : 'email'
      placeholder  : 'your email address'
      defaultValue : teamData.invitation?.email
      validate     :
        rules      : { email: yes }
        messages   : { email: 'Please type a valid email address.' }

    @username = new KDInputView
      placeholder      : 'pick a username'
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
          required     : 'blur'
          rangeLength  : 'blur'
          regExp       : 'keyup'

    @passwordStrength = ps = new KDCustomHTMLView
      tagName  : 'figure'
      cssClass : 'PasswordStrength'
      partial  : '<span></span>'

    # make this a reusable component - SY
    oldPass   = null
    @password = new KDInputView
      type          : 'password'
      name          : 'password'
      placeholder   : 'set a password'
      validate      :
        event       : 'blur'
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

        KD.utils.checkPasswordStrength pass, (err, report) ->
          oldPass = pass

          return if pass isnt report.password  # to avoid late responded ajax calls

          ps.unsetClass strength.join ' '
          ps.setClass strength[report.score]

    @button     = @getButton 'Sign up & join'
    @buttonLink = @getButtonLink "Have an account? <a href='#'>Log in now</a>", (event) =>
      KD.utils.stopDOMEvent event
      return  unless event.target.tagName is 'A'
      @emit 'FormNeedsToBeChanged', yes, yes


  submit: (formData) ->

    teamData = KD.utils.getTeamData()
    teamData.signup.alreadyMember = no

    super formData


  pistachio: ->

    """
    <div class='login-input-view email'><span>Email</span>{{> @email}}</div>
    <div class='login-input-view'><span>Username</span>{{> @username}}</div>
    <div class='login-input-view password'><span>Password</span>{{> @password}}{{> @passwordStrength}}</div>
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    {{> @buttonLink}}
    """
