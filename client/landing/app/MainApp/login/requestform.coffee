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

    @thanks = new KDCustomHTMLView
      tagName     : 'p'
      cssClass    : 'request-thanks'
      partial     : """
        <h5>Thanks for signing up!</h5>
        We'll do our best to get you into the beta as soon as humanly possible,
        but in the meantime, <a href='http://twitter.com/home?status=#{encodeURIComponent "just requested a beta invite @koding, a new way for developers to work! http://koding.com"}' target='_blank'>you can help us out by sharing Koding with your friends</a>
      """

  pistachio:->

    """
    <div>{{> @email}}</div>
    <div>{{> @button}}</div>
    <div>{{> @thanks}}</div>
    """