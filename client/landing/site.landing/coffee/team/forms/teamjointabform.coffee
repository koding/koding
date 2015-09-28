TeamUsernameTabForm = require './teamusernametabform'

module.exports = class TeamJoinTabForm extends TeamUsernameTabForm

  constructor:(options = {}, data)->

    super options, data

    { @alreadyMember } = @getOptions()

    @button = new KDButtonView
      title      : if @alreadyMember then "Join #{KD.config.groupName}" else "Sign up & join"
      style      : 'TeamsModal-button TeamsModal-button--green'
      type       : 'submit'

    teamData = KD.utils.getTeamData()

    if @alreadyMember
      { username } = teamData.signup
      @username.setValue username
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

    email = teamData.invitation?.email

    @email = new KDInputView
      name         : 'email'
      placeholder  : 'your email address'
      defaultValue : if @alreadyMember then username else email
      validate     :
        rules      :
          email    : yes
        messages   :
          email    : 'Please type a valid email address.'

    loginLinkPartial = if @alreadyMember
    then """Have an account? <a href="/">Log in now</a>"""
    else """Don't have an account? <a href="/">Sign up now</a>"""

    @loginLink = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'TeamsModal-button-link'
      partial  : loginLinkPartial


  pistachio: ->

    if @alreadyMember
      """
      <div class='login-input-view'><span>Password</span>{{> @password}}</div>
      <p class='dim'>Your email address indicates that you're already a Koding user, please type your password to proceed.<br><a href='//#{KD.utils.getMainDomain()}/Recover' target='_self'>Forgot your password?</a></p>
      <div class='TeamsModal-button-separator'></div>
      {{> @button}}
      """
    else
      """
      <div class='login-input-view email'><span>Email</span>{{> @email}}</div>
      <div class='login-input-view'><span>Username</span>{{> @username}}</div>
      <div class='login-input-view password'><span>Password</span>{{> @password}}{{> @passwordStrength}}</div>
      <div class='TeamsModal-button-separator'></div>
      {{> @loginLink}}
      {{> @button}}
      """
