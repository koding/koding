kd                   = require 'kd'
HomeTeamConnectSlack = require './hometeamconnectslack'
HomeTeamSendInvites  = require './hometeamsendinvites'
HomeTeamTeammates    = require './hometeamteammates'
HomeTeamSettings     = require './hometeamsettings'
TeamFlux             = require 'app/flux/teams'
AppFlux              = require 'app/flux'
whoami               = require 'app/util/whoami'
remote               = require('app/remote').getInstance()


SECTIONS =
  'Invite Using Slack' : HomeTeamConnectSlack
  'Send Invites'       : HomeTeamSendInvites
  Teammates            : HomeTeamTeammates
  'Team Settings'      : HomeTeamSettings

header = (title) ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title

section = (name, options, data) ->
  new (SECTIONS[name] or kd.View) options or {
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"
  }, data


module.exports = class HomeMyTeam extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    kd.singletons.groupsController.ready @bound 'putViews'


  putViews: ->

    { groupsController } = kd.singletons
    team = groupsController.getCurrentGroup()

    TeamFlux.actions.loadTeam()
    TeamFlux.actions.loadPendingInvitations()
    AppFlux.actions.user.loadLoggedInUserEmail()

    options =
      limit : 10
      sort  : { timestamp: -1 } # timestamp is at relationship collection
      skip  : 0

    TeamFlux.actions.fetchMembers(options).then =>
      TeamFlux.actions.fetchMembersRole().then ({ roles }) =>


        userRoles = {}
        for role in roles
          list = userRoles[role.targetId] or= []
          list.push role.as

        for id, roles of userRoles
          if id is whoami()._id
            hasOwner = 'owner' in roles
            hasAdmin = 'admin' in roles
            role = if hasOwner then 'owner' else if hasAdmin then 'admin' else 'member'

            @wrapper.addSubView header  'Team Settings'
            @wrapper.addSubView section 'Team Settings', null, role

            @wrapper.addSubView header  'Send Invites'
            @wrapper.addSubView section 'Send Invites', null, role

            @wrapper.addSubView header  'Invite Using Slack'
            @wrapper.addSubView section 'Invite Using Slack'

            @wrapper.addSubView header  'Teammates'
            @wrapper.addSubView section 'Teammates', null, role


