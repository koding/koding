LoginViewInlineForm      = require './../login/loginviewinlineform'
LoginInputView           = require './../login/logininputview'
LoginInputViewWithLoader = require './../login/logininputwithloader'

module.exports = class TeamsLaunchForm extends LoginViewInlineForm

  constructor: ->

    super

    @email = new LoginInputViewWithLoader
      inputOptions   :
        name         : 'email'
        placeholder  : 'Email address'
        validate     :
          rules      :
            email    : yes
          messages   :
            email    : 'Please type a valid email address.'

    @button = new KDButtonView
      title       : 'Sign up for early access'
      style       : 'solid medium green'
      attributes  : testpath : 'signup-company-button'
      type        : 'submit'


  pistachio:->
    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    """
