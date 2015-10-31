JView           = require './../../core/jview'
LoginInputView  = require './../../login/logininputview'


module.exports = class TeamUsernameTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix login-form'

    super options, data

    @label = new KDLabelView
      title : 'Occasionally Koding can share relevant announcements with me.'
      for   : 'newsletter'

    @checkbox = new KDInputView
      defaultValue : on
      type         : 'checkbox'
      name         : 'newsletter'
      label        : @label

    team        = KD.utils.getTeamData()
    emailPrefix = email.split('@').first  if email = team.signup?.email
    username    = emailPrefix  if emailPrefix?.length > 3

    @username = new LoginInputView
      inputOptions       :
        placeholder      : 'pick a username'
        name             : 'username'
        defaultValue     : username  if username
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
            # required     : 'blur'
            rangeLength  : 'blur'
            regExp       : 'keyup'

    @passwordStrength = ps = new KDCustomHTMLView
      tagName  : 'figure'
      cssClass : 'PasswordStrength'
      partial  : '<span></span>'

    # make this a reusable component - SY
    oldPass   = null
    @password = new LoginInputView
      inputOptions    :
        type          : 'password'
        name          : 'password'
        placeholder   : 'set a password'
        validate      :
          # event       : 'blur'
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

    @backLink = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link back'
      partial  : '<i></i> <a href="/Team/Domain">Back</a>'

    @button = new KDButtonView
      title      : 'Done!'
      style      : 'TeamsModal-button TeamsModal-button--green'
      attributes : testpath : 'register-button'
      type       : 'submit'


  pistachio: ->

    # <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
    """
    {{> @username}}
    {{> @password}}
    {{> @passwordStrength}}
    <p class='dim'></p>
    <div class='TeamsModal-button-separator'></div>
    {{> @button}}
    {{> @backLink}}
    """