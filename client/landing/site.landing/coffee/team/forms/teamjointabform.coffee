kd = require 'kd'

LoginInputView  = require './../../login/logininputview'


module.exports = class TeamJoinTabForm extends kd.FormView



  constructor: (options = {}, data) ->

    options.cssClass = 'clearfix login-form'

    super options, data

  getButton: (title) ->

    new kd.ButtonView
      title   : title
      style   : 'TeamsModal-button'
      type    : 'submit'
      loader  : yes


  getButtonLink: (partial, href, callback) ->

    new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link'
      partial  : if href then "<a href='#{href}'>#{partial}</a>" else partial
      click    : callback


  getPassword: ->

    new LoginInputView
      inputOptions  :
        type        : 'password'
        name        : 'password'
        label       : 'Your Password'
        placeholder : 'Enter your koding password'
        attributes   :
          autocomplete : 'password'
        validate    :
          container : this
          rules     : { required: yes }
          messages  : { required: 'Please enter your password.' }


  getTFCode: ->

    new LoginInputView
      cssClass      : 'hidden two-factor'
      inputOptions  :
        name        : 'tfcode'
        label       : '2FA Verification code'
        placeholder : 'Enter the 6-digit code'
        testPath    : 'login-form-tfcode'
        attributes  : { testpath: 'login-form-tfcode' }


  showTwoFactor: ->

    @button.hideLoader()
    @$('.two-factor').removeClass 'hidden'
    @tfcode.setFocus()
