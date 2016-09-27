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
