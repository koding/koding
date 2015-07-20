TeamUsernameTabForm = require './teamusernametabform'

module.exports = class TeamJoinTabForm extends TeamUsernameTabForm

  constructor:(options = {}, data)->

    super options, data

    { @alreadyMember } = @getOptions()

    @button = new KDButtonView
      title      : "Join #{KD.config.groupName}!"
      style      : 'TeamsModal-button TeamsModal-button--green'
      type       : 'submit'


    if @alreadyMember
      email = KD.utils.getTeamData().signup.username
      @username.setValue email
      @password.destroy()
      @password = new KDInputView
        type          : 'password'
        name          : 'password'
        placeholder   : 'password'
        validate      :
          event       : 'blur'
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter a password.'

    @email = new KDInputView
      name         : 'email'
      placeholder  : 'Email address'
      defaultValue : if @alreadyMember then email
      validate     :
        rules      :
          email    : yes
        messages   :
          email    : 'Please type a valid email address.'



  pistachio: ->

    if @alreadyMember
      """
      <div class='login-input-view'><span>Password</span>{{> @password}}</div>
      <p class='dim'>Since you're already a Koding user to join <i>#{KD.config.groupName}</i> you need to enter your koding.com password to proceed.</p>
      <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
      {{> @button}}
      """
    else
      """
      <div class='login-input-view email'><span>Email</span>{{> @email}}</div>
      <div class='login-input-view'><span>Username</span>{{> @username}}</div>
      <div class='login-input-view password'><span>Password</span>{{> @password}}{{> @passwordStrength}}</div>
      <p class='dim'>Your username is how you will appear to other people on your team. Pick something others will recognize.</p>
      <div class='login-input-view tr'>{{> @checkbox}}{{> @label}}</div>
      {{> @button}}
      """
