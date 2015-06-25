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
      click    : -> oauthController.redirectToOauth {provider: 'github'}

    @google = new CustomLinkView
      cssClass : 'go'
      title    : 'Sign up with Google'
      alt      : 'Sign up with Google'
      click    : -> oauthController.redirectToOauth {provider: 'google'}

    @facebook = new CustomLinkView
      cssClass : 'fb'
      title    : 'Sign up with Facebook'
      alt      : 'Sign up with Facebook'
      click    : -> oauthController.redirectToOauth {provider: 'facebook'}

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


  bind2FAEvents: ->

    @on 'TwoFactorEnabled', =>
      modal = new KDModalView
        title     : 'Two-Factor Authentication <a href="http://learn.koding.com/guides/2-factor-auth/" target="_blank">What is 2FA?</a>'
        width     : 400
        overlay   : yes
        cssClass  : 'two-factor-code-modal'

      modal.addSubView form = new KDFormView
      form.addSubView @tfcode = @create2FAInput()
      form.addSubView @createPost2FACodeButton()


  createPost2FACodeButton: ->
    return @post2FACodeButton = new KDButtonView
      title         : 'SIGN IN'
      type          : 'submit'
      style         : 'solid green medium'
      attributes    :
        testpath    : 'signup-button'
      loader        : yes
      callback      : @bound 'submit2FACode'


  submit2FACode: ->
    data =
      email     : @email.input.getValue()
      password  : @password.input.getValue()
      tfcode    : @tfcode.input.getValue()

    if data.tfcode then KD.utils.validateEmail data,
      success : (res) ->
        return location.replace '/'  if res is 'User is logged in!'

      error   : ({responseText}) =>
        @post2FACodeButton.hideLoader()
        title = if /Bad Request/i.test responseText then 'Access Denied!' else responseText
        new KDNotificationView
          title : title
    else
       @post2FACodeButton.hideLoader()


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
      <div class='dots-extra'></div>
      <div class='buttons-extra'>
        {{> @google}}
        {{> @facebook}}
      </div>
    </section>
    """
