MainHeaderView            = require './../../core/mainheaderview'
TeamUsernameTabForm       = require './../forms/teamusernametabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamUsernameTab extends KDTabPaneView

  callback = (formData) ->
    { storeNewTeamData, createTeam, joinTeam, getTeamData } = KD.utils
    { join } = getTeamData().signup

    if join
      storeNewTeamData 'join', formData
      joinTeam()
    else do ->
      storeNewTeamData 'username', formData
      createTeam success : -> KD.singletons.router.handleRoute '/Team/Stacks'


  constructor:(options = {}, data)->

    super options, data

    teamData = KD.utils.getTeamData()
    { @alreadyMember } = teamData.signup

    @createSubViews()


  createSubViews: ->

    @addSubView new MainHeaderView
      cssClass : 'team'
      navItems : []

    @addSubView wrapper = new KDCustomHTMLView
      cssClass : 'TeamsModal TeamsModal--groupCreation'

    if @alreadyMember

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Almost there'

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h5'
        partial : 'please enter your Koding password'

      wrapper.addSubView @form = new TeamLoginAndCreateTabForm { callback }

    else

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Choose a Username'

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h5'
        partial : '...or login with your existing Koding account.'

      wrapper.addSubView @form = new TeamUsernameTabForm
        callback : @bound 'createTeam'


  show: ->

    teamData = KD.utils.getTeamData()
    { alreadyMember } = teamData.signup
    if alreadyMember isnt @alreadyMember
      @alreadyMember = alreadyMember
      @form = null
      @destroySubViews()
      @createSubViews()

    super


  createTeam: (formData) ->

    { username } = formData

    teamData = KD.utils.getTeamData()
    { slug } = teamData.domain
    if username is slug
      return new KDNotificationView title : "Sorry, your group domain and your username can not be the same!"

    KD.utils.usernameCheck username,
      success : -> callback formData
      error   : ({responseJSON}) =>

        {forbidden, kodingUser} = responseJSON
        msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
        else if kodingUser then "Sorry, \"#{username}\" is already taken!"
        else                    "Sorry, there is a problem with \"#{username}\"!"

        new KDNotificationView title : msg
