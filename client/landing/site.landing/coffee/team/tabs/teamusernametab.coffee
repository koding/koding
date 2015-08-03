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
        partial : "Almost there @#{profile.nickname}"

      wrapper.addSubView new KDCustomHTMLView
        tagName  : 'p'
        cssClass : 'full'
        partial  : """
          Your email indicates that you're already registered at Koding,
          if you wish you can <a href='/Teams'>go back and continue</a> with a different email.
        """

      wrapper.addSubView @form = new TeamLoginAndCreateTabForm callback : @bound 'createTeam'

    else

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Create your account'

      wrapper.addSubView new KDCustomHTMLView
        tagName : 'h5'
        partial : '...pick a username that others will recognize.'

      wrapper.addSubView @form = new TeamUsernameTabForm
        callback    : @bound 'createTeam'


  show: ->

    teamData = KD.utils.getTeamData()
    { alreadyMember } = teamData.signup
    if alreadyMember isnt @alreadyMember
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
      success : ->
        KD.utils.storeNewTeamData 'username', formData
        KD.utils.createTeam
          success : ->
            KD.utils.clearTeamData()
            { protocol, host } = location
            location.href      = "#{protocol}//#{slug}.#{host}"

      error   : ({responseJSON}) =>

        unless responseJSON
          return new KDNotificationView
            title: 'Something went wrong'

        {forbidden, kodingUser} = responseJSON
        msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
        else if kodingUser then "Sorry, \"#{username}\" is already taken!"
        else                    "Sorry, there is a problem with \"#{username}\"!"

        new KDNotificationView title : msg
