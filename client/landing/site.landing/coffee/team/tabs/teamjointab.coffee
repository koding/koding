MainHeaderView            = require './../../core/mainheaderview'
TeamJoinTabForm           = require './../forms/teamjointabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamJoinTab extends KDTabPaneView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'username', options.cssClass

    super options, data

    @addSubView new MainHeaderView
      cssClass : 'team'
      navItems : []

    @addSubView wrapper = new KDCustomHTMLView
      cssClass : 'TeamsModal TeamsModal--groupCreation'

    wrapper.addSubView new KDCustomHTMLView
      tagName : 'h4'
      partial : 'Join with your email'

    teamData = KD.utils.getTeamData()

    alreadyMember  = teamData.signup?.alreadyMember
    @alreadyMember = alreadyMember
    domains        = KD.config.group.allowedDomains

    desc = if @alreadyMember
      "Please enter your <i>Koding.com</i> password."
    else if domains?.length > 1
      domainsPartial = KD.utils.getAllowedDomainsPartial domains
      "You must have an email address from one of these domains #{domainsPartial} to join."
    else "You must have a <i>#{domains.first}</i> email address to join."


    wrapper.addSubView new KDCustomHTMLView
      tagName : 'h5'
      partial : desc

    wrapper.addSubView @form = new TeamJoinTabForm {
      callback    : @bound 'joinTeam'
      @alreadyMember
    }

    @addSubView new KDCustomHTMLView
      tagName : 'section'
      partial : """
        <p>Already a member? You can <a href="/">sign in here</a>.</p>
        """

  joinTeam: (formData) ->

    { username } = formData
    success      = ->
      KD.utils.storeNewTeamData 'join', formData
      KD.utils.joinTeam()

    if @alreadyMember then success()
    else
      KD.utils.usernameCheck username,
        success : success
        error   : ({responseJSON}) =>

          unless responseJSON
            return new KDNotificationView
              title: 'Something went wrong'

          {forbidden, kodingUser} = responseJSON
          msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
          else if kodingUser then "Sorry, \"#{username}\" is already taken!"
          else                    "Sorry, there is a problem with \"#{username}\"!"

          new KDNotificationView title : msg
