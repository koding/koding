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
    @password.setOption 'stickyTooltip', yes

    @email.input.on    'focus', @bound 'handleFocus'
    @password.input.on 'focus', @bound 'handleFocus'

    @email.input.on 'keydown', @email.input.lazyBound 'setValidationResult', 'available', null
    @password.input.on 'keydown', @password.input.lazyBound 'setValidationResult', 'available', null

    KD.singletons.router.on 'RouteInfoHandled', =>
      @email.icon.unsetTooltip()
      @password.icon.unsetTooltip()

    @on 'EmailError', @bound 'showEmailError'


  handleOauthData: (userData) ->

    for own field, value of userData
      @[field]?.input?.setValue value
      @[field]?.placeholder?.setClass 'out'

    { input } = @email
    input.validate()
    if input.valid
      emailValidated = no
      @once 'emailValidatedOnServer', (result) =>
        emailValidated = yes; @submitOAuthData userData  if result and @gravatars[input.getValue()]

      @once 'gravatarInfoFetched', =>
        @submitOAuthData userData  if emailValidated and input.valid

      @fetchGravatarInfo input.getValue()


  submitOAuthData: (userData) ->

    email = @email.input.getValue()
    gravatar = @gravatars[email]
    gravatar.preferredUsername = userData.username  if userData.username?

    formData = { email: @email.input.getValue() }
    @getCallback() formData


  showEmailError: ->

    @email.input.setValidationResult 'available',
      'Sorry, this email is already in use!'


  handleFocus: -> @setClass 'focused'


  handleBlur: -> @unsetClass 'focused'


  pistachio : ->

    """
    <section class='clearfix'>
      <div class='fl email'>{{> @email}}</div>
      <div class='fl password'>{{> @password}}</div>
      <div class='fl submit'>{{> @button}}</div>
      {{> @github}}
    </section>
    """
