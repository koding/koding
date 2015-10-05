articlize                 = require 'indefinite-article'
MainHeaderView            = require './../../core/mainheaderview'
TeamJoinTabForm           = require './../forms/teamjointabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamJoinTab extends KDTabPaneView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'username', options.cssClass

    super options, data

    teamData = KD.utils.getTeamData()

    @alreadyMember = teamData.signup?.alreadyMember
    domains        = KD.config.group.allowedDomains

    @addSubView new MainHeaderView { cssClass : 'team', navItems : [] }
    @addSubView wrapper = new KDCustomHTMLView { cssClass : 'TeamsModal TeamsModal--groupCreation' }

    teamTitle  = KD.config.group.title
    modalTitle = "Join #{KD.utils.createTeamTitlePhrase teamTitle}"

    wrapper.addSubView new KDCustomHTMLView { tagName : 'h4', partial : modalTitle }

    desc = if @alreadyMember
      "Please enter your <i>Koding.com</i> password."
    else if domains?.length > 1
      domainsPartial = KD.utils.getAllowedDomainsPartial domains
      "You must have an email address from one of these domains #{domainsPartial} to join"
    else if domains?.length is 1
      "You must have a #{articlize domains.first} <i>#{domains.first}</i> email address to join"
    else
      "Please choose a username and password for your new Koding account."


    wrapper.addSubView new KDCustomHTMLView
      tagName : 'h5'
      partial : desc

    wrapper.addSubView @form = new TeamJoinTabForm {
      callback    : @bound 'joinTeam'
      @alreadyMember
    }

  joinTeam: (formData) ->

    { username } = formData
    success      = =>
      KD.utils.storeNewTeamData 'join', formData
      KD.utils.joinTeam
        error : ({responseText}) =>
          if /TwoFactor/.test responseText
            @form.showTwoFactor()
          else
            new KDNotificationView title : responseText

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
