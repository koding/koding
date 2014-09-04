class HomeRegisterForm extends RegisterInlineForm

  constructor: ->

    super

    @email.input.on    'focus', @bound 'handleFocus'
    @username.input.on 'focus', @bound 'handleFocus'


  handleFocus: -> @setClass 'focused'


  handleBlur: -> @unsetClass 'focused'


  pistachio : ->

    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl username'>{{> @username}}</div>
      <div class='fl submit'>{{> @button}}</div>
    </section>
    <div class='hint'>Usernames must be a minimum of 4 characters as they are also going to be used to set your Koding hostname, e.g. {{> @domain}}</div>
    <div class="accept-tos">By creating an account, you accept Koding's <a href="/tos.html" target="_blank"> Terms of Service</a> and <a href="/privacy.html" target="_blank">Privacy Policy.</a></div>
    """