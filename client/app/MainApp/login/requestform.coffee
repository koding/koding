class RequestInlineForm extends LoginViewInlineForm

  constructor:->

    super
    @email = new LoginInputView
      inputOptions    :
        name          : "email"
        placeholder   : "Enter an email address"
        validate      :
          rules       :
            required  : yes
            email     : yes
          messages    :
            required  : "Please enter your username or email."
            email     : "That doesn't seem like a valid email."

    @button = new KDButtonView
      title       : "REQUEST"
      style       : "koding-orange"
      type        : 'submit'
      loader      :
        color     : "#ffffff"
        diameter  : 21
    
  pistachio:->

    """
    <div>{{> @email}}</div>
    <div>{{> @button}}</div>
    """