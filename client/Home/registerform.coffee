class HomeRegisterForm extends RegisterInlineForm

  constructor: ->

    super

    @email.input.on    'focus', @bound 'handleFocus'
    @username.input.on 'focus', @bound 'handleFocus'
    @email.input.on    'blur', @bound 'handleBlur'
    @username.input.on 'blur', @bound 'handleBlur'


  handleFocus: -> @setClass 'focused'


  handleBlur: -> @unsetClass 'focused'


  pistachio : ->

    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl username'>{{> @username}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    <div class='hint'>Your username must be at least 4 characters and it’s also going to be your {{> @domain}} domain.</div>
    <div class="accept-tos">By creating an account, I accept Koding's <a href="/tos.html" target="_blank"> Terms of Service</a> and <a href="/privacy.html" target="_blank">Privacy Policy.</a></div>
    """
