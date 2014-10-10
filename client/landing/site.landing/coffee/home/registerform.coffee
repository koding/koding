RegisterInlineForm = require './../login/registerform'
CustomLinkView     = require './../core/customlinkview'

module.exports = class HomeRegisterForm extends RegisterInlineForm

  constructor: ->

    super

    @github = new CustomLinkView
      cssClass : 'octo'
      title    : 'Sign up with GitHub'
      alt      : 'Sign up with GitHub'
      click    : ->
        KD.singletons.oauthController.openPopup "github"

    @email.setOption 'stickyTooltip', yes
    @username.setOption 'stickyTooltip', yes

    @email.input.on    'focus', @bound 'handleFocus'
    @username.input.on 'focus', @bound 'handleFocus'

    @email.input.on 'keydown', @email.input.lazyBound 'setValidationResult', 'available', null
    @username.input.on 'keydown', @username.input.lazyBound 'setValidationResult', 'usernameCheck', null

    KD.singletons.router.on 'RouteInfoHandled', =>
      @email.icon.unsetTooltip()
      @username.icon.unsetTooltip()

    @on 'EmailError', @bound 'showEmailError'
    @on 'UsernameError', @bound 'showUsernameError'


  showEmailError: ->

    @email.input.setValidationResult 'available',
      'Sorry, this email is already in use!'


  showUsernameError: ->

    @username.input.setValidationResult 'usernameCheck',
      'Sorry, this username is already taken!'


  handleFocus: -> @setClass 'focused'


  handleBlur: -> @unsetClass 'focused'


  pistachio : ->

    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl username'>{{> @username}}</div>
      <div class='fl submit'>{{> @button}}</div>
      {{> @github}}
    </section>
    """
