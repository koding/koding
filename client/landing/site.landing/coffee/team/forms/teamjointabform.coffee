kd = require 'kd'
JView           = require './../../core/jview'
LoginInputView  = require './../../login/logininputview'


module.exports = class TeamJoinTabForm extends kd.FormView

  JView.mixin @prototype

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

    options    =
      cssClass : 'TeamsModal-button-link'
      partial  : partial
      click    : callback

    if href
      options.tagName    = 'a'
      options.attributes = { href }
    else
      options.tagName = 'span'

    new kd.CustomHTMLView options


  getPassword: ->

    new LoginInputView
      inputOptions  :
        type        : 'password'
        name        : 'password'
        placeholder : 'password'
        validate    :
          container : this
          rules     : { required: yes }
          messages  : { required: 'Please enter a password.' }


  getTFCode: ->

    new LoginInputView
      cssClass      : 'hidden two-factor'
      inputOptions  :
        name        : 'tfcode'
        placeholder : 'authentication code'
        testPath    : 'login-form-tfcode'
        attributes  : { testpath: 'login-form-tfcode' }


  showTwoFactor: ->

    @button.hideLoader()
    @$('.two-factor').removeClass 'hidden'
    @tfcode.setFocus()
