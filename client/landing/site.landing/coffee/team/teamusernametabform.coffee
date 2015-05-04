JView             = require './../core/jview'

module.exports = class TeamUsernameTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @label = new KDLabelView
      title : 'Occasionally Koding can share relevant announcements with me.'
      for   : 'newsletter'

    @checkbox = new KDInputView
      defaultValue : on
      type         : 'checkbox'
      name         : 'newsletter'
      label        : @label

    @username = new KDInputView
      placeholder : 'username'

    @passwordStrength = ps = new KDCustomHTMLView
      tagName  : 'figure'
      cssClass : 'PasswordStrength'
      partial  : '<span></span>'

    # make this a reusable component - SY
    oldPass   = null
    @password = new KDInputView
      type          : 'password'
      placeholder   : '*********'
      validate      :
        event       : 'blur'
        container   : this
        rules       :
          required  : yes
          minLength : 8
        messages    :
          required  : "Please enter a password."
          minLength : "Passwords should be at least 8 characters."
      keyup         : (event) ->
        pass     = @getValue()
        strength = ['bad', 'weak', 'moderate', 'good', 'excellent']

        return  if pass is oldPass
        return  ps.unsetClass strength.join ' '  if pass is ''

        KD.utils.checkPasswordStrength pass, (err, report) ->
          oldPass = pass

          return if pass isnt report.password  #to avoid late responded ajax calls

          ps.unsetClass strength.join ' '
          ps.setClass strength[report.score]



    @button = new KDButtonView
      title       : 'Continue to environmental setup'
      style       : 'SignupForm-button SignupForm-button--green'
      attributes  : testpath  : 'register-button'
      loader      : yes
      callback    : =>
        console.log 'go to invites:'
        KD.singletons.router.handleRoute '/Team/invite'


  pistachio: ->

    """
    <div class='login-input-view'><span>Username</span>{{> @username}}</div>
    <div class='login-input-view'><span>Password</span>{{> @password}}{{> @passwordStrength}}</div>
    <p class='dim'>Your username  is how you will appear to other people on your team. Pick something others will recignize.</p>
    <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
    {{> @button}}
    """