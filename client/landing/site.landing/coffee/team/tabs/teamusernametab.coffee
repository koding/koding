kd = require 'kd.js'
MainHeaderView            = require './../../core/mainheaderview'
TeamUsernameTabForm       = require './../forms/teamusernametabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamUsernameTab extends kd.TabPaneView

  constructor:(options = {}, data)->

    super options, data

    @createSubViews()


  createSubViews: ->

    teamData = kd.utils.getTeamData()
    { @alreadyMember, profile } = teamData.signup

    @addSubView new MainHeaderView
      cssClass : 'team'
      navItems : []

    @addSubView wrapper = new kd.CustomHTMLView
      cssClass : 'TeamsModal TeamsModal--groupCreation'

    if @alreadyMember

      wrapper.addSubView new kd.CustomHTMLView
        tagName : 'h4'
        partial : "Sign in"

      wrapper.addSubView new kd.CustomHTMLView
        tagName  : 'h5'
        cssClass : 'full'
        partial  : 'Almost there! Sign in with your Koding account.'

      wrapper.addSubView @form = new TeamLoginAndCreateTabForm
        callback : (formData) =>
          track 'submitted login form'
          @createTeam formData, no

    else

      wrapper.addSubView new kd.CustomHTMLView
        tagName : 'h4'
        partial : 'Make an account'

      wrapper.addSubView new kd.CustomHTMLView
        tagName : 'h5'
        partial : 'Pick a username and a password to log in with. Or use your existing Koding login.'

      wrapper.addSubView @form = new TeamUsernameTabForm
        callback : (formData) =>
          track 'submitted register form'
          @createTeam formData


  show: ->

    teamData = kd.utils.getTeamData()
    { alreadyMember } = teamData.signup
    if alreadyMember isnt @alreadyMember
      @form = null
      @destroySubViews()
      @createSubViews()

    super


  createTeam: (formData, checkUsername = yes) ->

    { username } = formData

    teamData = kd.utils.getTeamData()
    { slug } = teamData.domain
    if username is slug
      return new kd.NotificationView title : "Sorry, your group domain and your username can not be the same!"

    success = =>
      kd.utils.storeNewTeamData 'username', formData
      kd.utils.createTeam
        success : (data) ->
          track 'succeeded to create a team'
          kd.utils.clearTeamData()
          { protocol, host } = location
          location.href      = "#{protocol}//#{slug}.#{host}/-/confirm?token=#{data.token}"
        error : ({responseText}) =>
          @form.emit 'FailedToCreateATeam'

          if /TwoFactor/.test responseText
            track 'requires two-factor authentication'
            @form.showTwoFactor()
          else
            track 'failed to create a team'
            new kd.NotificationView title : responseText


    unless checkUsername
    then success()
    else
      kd.utils.usernameCheck username,
        success : ->
          track 'entered a valid username'
          success()
        error   : ({responseJSON}) =>
          track 'entered an invalid username'

          unless responseJSON
            return new kd.NotificationView
              title: 'Something went wrong'

          {forbidden, kodingUser} = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new kd.NotificationView title : msg


track = (action) ->

  category = 'TeamSignup'
  label    = 'AccountTab'
  kd.utils.analytics.track action, { category, label }
