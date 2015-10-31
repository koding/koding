LoginViewInlineForm      = require './../login/loginviewinlineform'
LoginInputView           = require './../login/logininputview'
LoginInputViewWithLoader = require './../login/logininputwithloader'

module.exports = class TeamsSignupForm extends LoginViewInlineForm

  constructor:->

    super

    team        = KD.utils.getTeamData()
    email       = team.invitation?.email


    @email = new LoginInputViewWithLoader
      inputOptions   :
        name         : 'email'
        placeholder  : 'Email address'
        defaultValue : email  if email
        attributes   : testpath : 'register-form-email'
        validate     :
          rules      :
            email    : yes
          messages   :
            email    : 'Please type a valid email address.'

    @companyName = new LoginInputView
      inputOptions    :
        name          : 'companyName'
        placeholder   : 'Name your team'
        attributes    : testpath : 'company-name'
        validate      :
          # event       : 'blur'
          rules       :
            required  : yes
          messages    :
            required  : "Please enter a team name."

    # make the placeholders go away
    @email.inputReceivedKeyup()        if email

    @button = new KDButtonView
      title       : 'Sign up'
      icon        : yes
      style       : 'TeamsModal-button TeamsModal-button--green'
      attributes  : testpath : 'signup-company-button'
      type        : 'submit'


  pistachio:->
    """
    <div class='email'>{{> @email}}</div>
    <div class='company-name'>{{> @companyName}}</div>
    <div class='submit'>{{> @button}}</div>
    """