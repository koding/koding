RegisterInlineForm = require './../login/registerform'
CustomLinkView     = require './../core/customlinkview'

module.exports = class HomeRegisterForm extends RegisterInlineForm

  constructor: ->

    super

    { oauthController } = KD.singletons

    @github = new CustomLinkView
      cssClass : 'gh'
      title    : 'Sign up with GitHub'
      alt      : 'Sign up with GitHub'
      click    : -> oauthController.redirectToOauth 'github'

    @google = new CustomLinkView
      cssClass : 'go'
      title    : 'Sign up with Google'
      alt      : 'Sign up with Google'
      click    : -> oauthController.redirectToOauth 'google'

    @facebook = new CustomLinkView
      cssClass : 'fb'
      title    : 'Sign up with Facebook'
      alt      : 'Sign up with Facebook'
      click    : -> oauthController.redirectToOauth 'facebook'

    @twitter = new CustomLinkView
      cssClass : 'tw'
      title    : 'Sign up with Twitter'
      alt      : 'Sign up with Twitter'
      click    : -> oauthController.redirectToOauth 'twitter'

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

    { username, firstName, lastName } = oauthData

    input.setValue oauthData.email
    @email.placeholder.setClass 'out'

    @emailIsAvailable = yes
    @once 'gravatarInfoFetched', (gravatar) =>
      # oath username has more priority over gravatar username
      gravatar.preferredUsername = username  if username
      gravatar.name =
        givenName  : firstName
        familyName : lastName

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
      <div class='buttons-extra'>
        {{> @google}}
        {{> @facebook}}
        {{> @twitter}}
      </div>
    </section>
    """
