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

    { input } = @email
    input.setValue userData.email
    @email.placeholder.setClass 'out'
    input.validate()

    if input.valid
      @once 'emailValidatedOnServer', =>
        @submitOAuthData userData

      @once 'gravatarInfoFetched', =>
        @submitOAuthData userData

      @fetchGravatarInfo input.getValue()


  submitOAuthData: (userData) ->

    email = @email.input.getValue()
    gravatar = @gravatars[email]

    return  if not @emailIsAvailable or not gravatar?

    # oath username has more priority over gravatar username
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
