kd                  = require 'kd'
utils               = require './../core/utils'
LoginViewInlineForm = require './../login/loginviewinlineform'
LoginInputView      = require './../login/logininputview'

module.exports = class FindTeamForm extends LoginViewInlineForm

  RECATCHA_JS = 'https://www.google.com/recaptcha/api.js?onload=onRecaptchaloadCallback&render=explicit'

  window.onRecaptchaloadCallback = (event) ->

    grecaptcha?.render 'recaptcha', sitekey : kd.config.recaptcha.key


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'login-form', options.cssClass

    super options, data

    { invitation, signup } = utils.getTeamData()
    email = signup?.email or invitation?.email

    @usernameOrEmail = new LoginInputView
      inputOptions             :
        name                   : 'email'
        placeholder            : 'Email address...'
        testPath               : 'find-team-input'
        defaultValue           : email
        validate               :
          container            : this
          rules                :
            required           : yes
          messages             :
            required           : 'Please enter your email.'

    @button = new kd.ButtonView
      title       : 'SEND TEAM LIST'
      style       : 'TeamsModal-button'
      type        : 'submit'
      loader      : yes

    @recaptcha = new kd.CustomHTMLView
      domId : 'recaptcha'
      cssClass : 'login-input-view'

    @on 'viewAppended', =>

      @recaptchaScript?.destroy()
      @recaptchaScript = new kd.CustomHTMLView
        tagName    : 'script'
        attributes :
          src      : RECATCHA_JS
          async    : yes
          defer    : yes

      @recaptchaScript.appendToDomBody()

    callback = @getCallback()
    @setCallback (formData) =>

      recaptchaResponse = grecaptcha?.getResponse()
      if recaptchaResponse is ''
        @button.hideLoader()
        return new kd.NotificationView
          cssClass : 'recoverConfirmation'
          title    : 'Please tell us that you\'re not a robot!'

      formData.recaptcha = recaptchaResponse
      callback formData


  reset: ->

    super
    @button.hideLoader()


  setFocus: -> @usernameOrEmail.input.setFocus()


  pistachio: ->

    '''
    {{> @usernameOrEmail}}
    {{> @recaptcha}}
    {{> @button}}
    '''
