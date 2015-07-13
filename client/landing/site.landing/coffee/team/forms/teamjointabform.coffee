TeamUsernameTabForm = require './teamusernametabform'

module.exports = class TeamJoinTabForm extends TeamUsernameTabForm

  constructor:(options = {}, data)->

    super options, data

    @email = new KDInputView
      # type         : 'email'
      name         : 'email'
      placeholder  : 'Email address'
      validate     :
        rules      :
          email    : yes
        messages   :
          email    : 'Please type a valid email address.'

    @button = new KDButtonView
      title      : "Join #{KD.config.groupName}!"
      style      : 'TeamsModal-button TeamsModal-button--green'
      type       : 'submit'


  pistachio: ->

    """
    <div class='login-input-view'><span>Email</span>{{> @email}}</div>
    <div class='login-input-view'><span>Username</span>{{> @username}}</div>
    <div class='login-input-view'><span>Password</span>{{> @password}}{{> @passwordStrength}}</div>
    <p class='dim'>Your username is how you will appear to other people on your team. Pick something others will recognize.</p>
    <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
    {{> @button}}
    """