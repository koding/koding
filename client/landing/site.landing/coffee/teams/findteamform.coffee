kd                  = require 'kd'
utils               = require './../core/utils'
LoginViewInlineForm = require './../login/loginviewinlineform'
LoginInputView      = require './../login/logininputview'
FindTeamHelper      = require './findteamhelper'

module.exports = class FindTeamForm extends LoginViewInlineForm

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'login-form', options.cssClass

    super options, data

    { invitation, signup } = utils.getTeamData()
    email = signup?.email or invitation?.email

    @usernameOrEmail = new LoginInputView
      inputOptions             :
        name                   : 'email'
        label                  : 'Email address'
        placeholder            : 'Enter your email address'
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
      domId    : 'findTeamRecaptcha'
      cssClass : 'login-input-view'
    @recaptcha.hide()

    callback = @getCallback()
    @setCallback (formData) =>

      if @recaptchaId? and not recaptchaResponse = grecaptcha?.getResponse @recaptchaId
        @button.hideLoader()
        return new kd.NotificationView
          cssClass : 'recoverConfirmation'
          title    : 'Please tell us that you\'re not a robot!'

      formData.recaptcha = recaptchaResponse
      callback formData


  reloadRecaptcha: ->

    return  unless FindTeamHelper.isRecaptchaRequired()

    @recaptcha.show()
    if @recaptchaId?
      grecaptcha?.reset @recaptchaId
    else
      utils.loadRecaptchaScript =>
        @recaptchaId = grecaptcha?.render 'findTeamRecaptcha', { sitekey : kd.config.recaptcha.key }


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
