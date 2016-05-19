kd                   = require 'kd'
HomeTeamConnectSlack = require './hometeamconnectslack'
HomeTeamSendInvites  = require './hometeamsendinvites'
HomeTeamTeammates    = require './hometeamteammates'
HomeTeamSettings     = require './hometeamsettings'
TeamFlux             = require 'app/flux/teams'
AppFlux              = require 'app/flux'
whoami               = require 'app/util/whoami'
remote               = require('app/remote').getInstance()
toImmutable = require 'app/util/toImmutable'

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

    { JAccount } = remote.api
    { groupsController, reactor } = kd.singletons
    team = groupsController.getCurrentGroup()

    TeamFlux.actions.loadTeam()
    TeamFlux.actions.loadPendingInvitations()
    TeamFlux.actions.loadDisabledUsers()
    AppFlux.actions.user.loadLoggedInUserEmail()

    groupsController.on 'GroupJoined', (data) ->

      if data.contents.actionType is 'groupJoined'
        { roles, email, username } = data.contents.memberData
        remote.cacheable username, (err, account) ->
          unless err
            account = toImmutable account[0]
            account = account.setIn ['profile', 'email'], email
            account = account.set 'role', roles

            id = account.get '_id'

            reactor.dispatch 'UPDATE_TEAM_MEMBER', { account }
            reactor.dispatch 'ADD_MEMBER_TO_TEAM', { id }
            reactor.dispatch 'REMOVE_PENDING_INVITATION', { email }

    groupsController.on 'GroupLeft', (data) ->

      { username } = data.contents
      remote.cacheable username, (err, account) ->
        account = account[0]
        reactor.dispatch 'DELETE_TEAM_MEMBER', account._id

    @wrapper.addSubView header  'Team Settings'
    @wrapper.addSubView section 'Team Settings'

    @wrapper.addSubView header  'Send Invites'
    @wrapper.addSubView section 'Send Invites'

    @wrapper.addSubView header  'Invite Using Slack'
    @wrapper.addSubView section 'Invite Using Slack'

    @wrapper.addSubView header  'Teammates'
    @wrapper.addSubView section 'Teammates'


