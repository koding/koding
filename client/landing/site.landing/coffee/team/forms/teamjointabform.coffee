JView = require './../../core/jview'

module.exports = class TeamJoinTabForm extends KDFormView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

  getButton: (title) ->

    new KDButtonView
      title      : title
      style      : 'TeamsModal-button TeamsModal-button--green'
      type       : 'submit'


  getButtonLink: (partial, callback) ->

    new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link'
      partial  : partial
      click    : callback


  getPassword: ->

    new KDInputView
      type        : 'password'
      name        : 'password'
      placeholder : 'password'
      validate    :
        event     : 'blur'
        container : this
        rules     : { required: yes }
        messages  : { required: 'Please enter a password.' }


  getTFCode: ->

    new KDInputView
      name          : 'tfcode'
      placeholder   : 'authentication code'
      testPath      : 'login-form-tfcode'
      attributes    : { testpath: 'login-form-tfcode' }


  showTwoFactor: ->

    @$('.two-factor').removeClass 'hidden'
    @tfcode.setFocus()
