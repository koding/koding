MainHeaderView            = require './../../core/mainheaderview'
TeamUsernameTabForm       = require './../forms/teamusernametabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamUsernameTab extends KDTabPaneView

  constructor:(options = {}, data)->

    super options, data

    @createSubViews()


  createSubViews: ->

    teamData = KD.utils.getTeamData()
    { @alreadyMember, profile } = teamData.signup

    @addSubView new MainHeaderView
      cssClass : 'team'
      navItems : []

    @addSubView wrapper = new KDCustomHTMLView
      cssClass : 'TeamsModal TeamsModal--groupCreation'

    if @alreadyMember

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h4'
        partial : "Sign in"

      wrapper.addSubView new KDCustomHTMLView
        tagName  : 'h5'
        cssClass : 'full'
        partial  : 'Almost there! Sign in with your Koding account.'

      wrapper.addSubView @form = new TeamLoginAndCreateTabForm
        callback : (formData) =>
          track 'submitted login form'
          @createTeam formData, no

    else

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Make an account'

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h5'
        partial : 'Pick a username and a password to log in with. Or use your existing Koding login.'

      wrapper.addSubView @form = new TeamUsernameTabForm
        callback : (formData) =>
          track 'submitted register form'
          @createTeam formData


  show: ->

    teamData = KD.utils.getTeamData()
    { alreadyMember } = teamData.signup
    if alreadyMember isnt @alreadyMember
      @form = null
      @destroySubViews()
      @createSubViews()

    super


  createTeam: (formData, checkUsername = yes) ->

    { username } = formData

    teamData = KD.utils.getTeamData()
    { slug } = teamData.domain
    if username is slug
      return new KDNotificationView title : "Sorry, your group domain and your username can not be the same!"

    success = =>
      KD.utils.storeNewTeamData 'username', formData
      KD.utils.createTeam
        success : (data) ->
          track 'succeeded to create a team'
          KD.utils.clearTeamData()
          { protocol, host } = location
          location.href      = "#{protocol}//#{slug}.#{host}/-/confirm?token=#{data.token}"
        error : ({responseText}) =>
          if /TwoFactor/.test responseText
            track 'requires two-factor authentication'
            @form.showTwoFactor()
          else
            track 'failed to create a team'
            new KDNotificationView title : responseText


    unless checkUsername
    then success()
    else
      KD.utils.usernameCheck username,
        success : ->
          track 'entered a valid username'
          success()
        error   : ({responseJSON}) =>
          track 'entered an invalid username'

          unless responseJSON
            return new KDNotificationView
              title: 'Something went wrong'

          {forbidden, kodingUser} = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new KDNotificationView title : msg


track = (action) ->

  category = 'TeamSignup'
  label    = 'AccountTab'
  KD.utils.analytics.track action, { category, label }
