class RequestInlineForm extends LoginViewInlineForm

  constructor:->

    super
    @email = new LoginInputView
      inputOptions    :
        name          : "email"
        placeholder   : "Enter your email address"
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

    # <a href='http://twitter.com/home?status=#{encodeURIComponent "just requested a beta invite @koding, a new way for developers to work! http://koding.com"}' target='_blank'>you can help us out by sharing Koding with your friends.</a>
    @thanks = new KDCustomHTMLView
      tagName     : 'p'
      cssClass    : 'request-thanks'
      partial     : """
        <h5>Thanks for signing up!</h5>
        We'll do our best to get you into the beta as soon as possible.
        Also, we will be giving some to our followers, <a href='http://twitter.com/home?status=#{encodeURIComponent "just requested a beta invite @koding, a new way for developers to work! http://koding.com"}' target='_blank'>feel free to tweet and ask for an invitation.</a>
        <br>
        <a href="https://twitter.com/share" class="twitter-share-button" data-url="http://koding.com" data-text="just requested a beta invite @koding, a new way for developers to work!" data-via="koding">Tweet</a>
        <a href="https://twitter.com/koding" class="twitter-follow-button" data-show-count="false">Follow @koding</a>
        <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
        """

  pistachio:->

    """
    <div>{{> @email}}</div>
    <div>{{> @button}}</div>
    <div>{{> @thanks}}</div>
    """