JView               = require './../../core/jview'
TeamUsernameTabForm = require './teamusernametabform'

module.exports = class TeamRegisterTabForm extends TeamUsernameTabForm

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'clearfix'

    super options, data

    @email = new KDInputView
      name         : 'email'
      placeholder  : 'Email address'
      validate     :
        rules      :
          email    : yes
        messages   :
          email    : 'Please type a valid email address.'

    @label.setTitle 'Occasionally Koding can share relevant announcements with me. Can it?'

    @button.destroy()
    @button = new KDButtonView
      title      : 'JOIN'
      style      : 'TeamsModal-button TeamsModal-button--green'
      type       : 'submit'


  pistachio: ->

    """
    <div class='login-input-view'>{{> @email}}</div>
    <div class='login-input-view'>{{> @username}}</div>
    <div class='login-input-view'>{{> @password}}{{> @passwordStrength}}</div>
    <p class='dim'>Your username  is how you will appear to other people on your team. Pick something others will recignize.</p>
    <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
    {{> @button}}
    """