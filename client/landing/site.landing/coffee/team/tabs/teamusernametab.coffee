kd                               = require 'kd'
utils                            = require './../../core/utils'
TeamJoinTab                      = require './teamjointab'
TeamUsernameTabForm              = require './../forms/teamusernametabform'
TeamLoginAndCreateTabForm        = require './../forms/teamloginandcreatetabform'
TeamCreateWithMemberAccountForm  = require './../forms/teamcreatewithmemberaccountform'


track = (action, properties = {}) ->

  properties.category = 'TeamSignup'
  properties.label    = 'AccountTab'
  utils.analytics.track action, properties


module.exports = class TeamUsernameTab extends TeamJoinTab

  constructor: (options = {}, data) ->

    options.loginForm        or= TeamLoginAndCreateTabForm
    options.loginFormInvited or= TeamCreateWithMemberAccountForm
    options.signupForm       or= TeamUsernameTabForm
    options.email            or= utils.getTeamData().signup.email

    super options, data


  show: ->
    kd.TabPaneView::show.call this
    @setOption 'email', utils.getTeamData().signup?.email
    @createSubViews()
    @wrapper.setClass 'create'


  getModalTitle: ->
    if @alreadyMember and @wantsToUseDifferentAccount
      'Your account'
    else if @alreadyMember
      ''
    else
      'Your account'


  getDescription: ->

    if @alreadyMember and @wantsToUseDifferentAccount
      "Please enter your <i>#{kd.config.domains.main}</i> username & password."
    else if @alreadyMember
      "<br>It seems that you're already a <i>#{kd.config.domains.main}</i> user, please type your password to proceed."
    else
      'Pick a username and a password to log in with.'


  addForgotPasswordLink: ->

    return  unless @alreadyMember
    return  if @forgotPassword?

    @addSubView @forgotPassword = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'additional-info'
      partial  : '<p>Forgot your password? <a href="/Team/Recover?mode=create">Click here</a> to reset.</p>'


  submit: (formData) ->

    if @alreadyMember
      track 'submitted login form'
      checkUsername = no
    else
      track 'submitted register form'
      checkUsername = yes

    { username } = formData

    teamData = utils.getTeamData()
    { slug } = teamData.domain

    if username is slug
      @form.emit 'FormSubmitFailed'
      return new kd.NotificationView { title : 'Sorry, your group domain and your username can not be the same!' }

    success = =>
      utils.storeNewTeamData 'username', formData
      utils.createTeam
        success : (data) ->
          props = {
            email: teamData.signup?.email
            team: "https://#{teamData.domain.slug}.koding.com"
            company: teamData.signup?.companyName
            phone: teamData.signup?.phone
            username: teamData.profile?.nickname
          }
          track 'succeeded to create a team', props
          utils.clearTeamData()
          { protocol, host } = location
          location.href      = "#{protocol}//#{slug}.#{host}/-/confirm?token=#{data.token}"
        error : ({ responseText }) =>
          @form.emit 'FormSubmitFailed'

          if /TwoFactor/.test responseText
            track 'requires two-factor authentication'
            @form.showTwoFactor()
          else
            track 'failed to create a team'
            new kd.NotificationView { title : responseText }


    unless checkUsername
    then success()
    else
      utils.usernameCheck username,
        success : ->
          track 'entered a valid username'
          success()
        error   : ({ responseJSON }) =>
          track 'entered an invalid username'

          @form.emit 'FormSubmitFailed'

          unless responseJSON
            return new kd.NotificationView
              title: 'Something went wrong'

          { forbidden, kodingUser } = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new kd.NotificationView { title : msg }
