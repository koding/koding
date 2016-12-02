kd                       = require 'kd'
utils                    = require './../core/utils'
LoginViewInlineForm      = require './../login/loginviewinlineform'
LoginInputView           = require './../login/logininputview'

module.exports = class TeamsSignupForm extends LoginViewInlineForm

  constructor: ->

    super

    team        = utils.getTeamData()
    email       = team.invitation?.email ? team.signup?.email
    companyName = team.signup?.companyName

    @email = new LoginInputView
      inputOptions   :
        name         : 'email'
        label        : 'Email Address'
        placeholder  : 'Enter your work email'
        defaultValue : email  if email
        attributes   :
          testpath   : 'register-form-email'
          autocomplete : 'email'
        validate     :
          rules      :
            email    : yes
          messages   :
            email    : 'Please type a valid email address.'

    @companyName = new LoginInputView
      inputOptions   :
        name         : 'companyName'
        label        : 'Team Name'
        placeholder  : 'Name your team (i.e. your company name)'
        defaultValue : companyName  if companyName
        attributes   :
          testpath   : 'company-name'
          autocomplete : 'org'
        validate     :
          rules      :
            required : yes
          messages   :
            required : 'Please enter a team name.'

    @phone = new LoginInputView
      cssClass       : 'hidden'
      inputOptions   :
        name         : 'phone'
        label        : 'Phone number'
        placeholder  : 'Enter your phone number'
        attributes   :
          autocomplete : 'phone'

    @button = new kd.ButtonView
      title       : 'Next'
      icon        : yes
      style       : 'TeamsModal-button'
      attributes  : { testpath : 'signup-company-button' }
      type        : 'submit'


  pistachio: ->
    """
    <div class='email'>{{> @email }}</div>
    <div class='phone'>{{> @phone }}</div>
    <div class='company-name'>{{> @companyName }}</div>
    <div class='submit'>{{> @button }}</div>
    """
