LoginViewInlineForm      = require './../login/loginviewinlineform'
LoginInputView           = require './../login/logininputview'
LoginInputViewWithLoader = require './../login/logininputwithloader'

module.exports = class TeamSignupForm extends LoginViewInlineForm

  constructor:->

    super

    @email = new LoginInputViewWithLoader
      inputOptions         :
        name               : 'email'
        placeholder        : 'Email address'
        attributes         :
          testpath         : 'register-form-email'
        validate           : KD.utils.getEmailValidator
          container        : this
        decorateValidation : no
        # focus             : => @email.icon.unsetTooltip()
        # keydown           : (event) => @submitForm event  if event.which is ENTER
        # blur              : => @fetchGravatarInfo @email.input.getValue()
        # change            : => @emailIsAvailable = no

    @companyName = new LoginInputView
      inputOptions    :
        name          : 'companyName'
        placeholder   : 'Company Name'
        attributes    : testpath : 'company-name'
        validate      :
          event       : 'blur'
          rules       :
            required  : yes
          messages    :
            required  : "Please enter a your company name."

    @button = new KDButtonView
      title       : 'Sign up'
      style       : 'solid medium green'
      attributes  : testpath : 'signup-company-button'
      type        : 'submit'
      loader      : yes


  activate: ->
    @username.setFocus()


  resetDecoration:->
    @username.resetDecoration()
    @password.resetDecoration()


  pistachio:->
    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl company-name'>{{> @companyName}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    """
