RegisterInlineForm = require './../login/registerform'
CustomLinkView     = require './../core/customlinkview'

module.exports = class TeamsRegisterForm extends RegisterInlineForm

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


  handleOauthData: (oauthData) ->

    @oauthData = oauthData
    { input }  = @email

    input.setValue oauthData.email
    @email.placeholder.setClass 'out'

    @emailIsAvailable = no
    @once 'gravatarInfoFetched', (gravatar) =>
      # oath username has more priority over gravatar username
      gravatar.preferredUsername = @oauthData.username  if @oauthData.username
      input.validate()

    @fetchGravatarInfo input.getValue()


  callbackAfterValidation: ->

    email = @email.input.getValue()

    return super  unless @oauthData?.email is email

    @getCallback() { email }


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
