LoginViewInlineForm      = require './../login/loginviewinlineform'
LoginInputView           = require './../login/logininputview'
LoginInputViewWithLoader = require './../login/logininputwithloader'

module.exports = class TeamSignupForm extends LoginViewInlineForm

  constructor:->

    super

    team        = KD.utils.getTeamData()
    email       = team.signup?.email
    companyName = team.signup?.companyName


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
        placeholder   : 'Company Name'
        defaultValue  : companyName  if companyName
        attributes    : testpath : 'company-name'
        validate      :
          event       : 'blur'
          rules       :
            required  : yes
          messages    :
            required  : "Please enter a your company name."

    # make the placeholders go away
    @companyName.inputReceivedKeyup()  if companyName
    @email.inputReceivedKeyup()        if email

    @button = new KDButtonView
      title       : 'Sign up'
      style       : 'solid medium green'
      attributes  : testpath : 'signup-company-button'
      type        : 'submit'


  pistachio:->
    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl company-name'>{{> @companyName}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    """