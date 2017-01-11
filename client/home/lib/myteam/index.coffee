kd                   = require 'kd'
HomeTeamConnectSlack = require './hometeamconnectslack'
HomeTeamSendInvites  = require './hometeamsendinvites'
HomeTeamTeammates    = require './hometeamteammates'
HomeTeamSettings     = require './hometeamsettings'
HomeTeamPermissions  = require './hometeampermissions'
TeamFlux             = require 'app/flux/teams'
AppFlux              = require 'app/flux'
whoami               = require 'app/util/whoami'
remote               = require 'app/remote'
headerize = require '../commons/headerize'
sectionize = require '../commons/sectionize'
camelizeString = require 'app/util/camelizeString'
toImmutable = require 'app/util/toImmutable'
canSeeMembers = require 'app/util/canSeeMembers'
isAdmin = require 'app/util/isAdmin'
MembershipRoleChangedModal =  require 'app/components/membershiprolechangedmodal'

SECTIONS =
  'Invite Using Slack' : HomeTeamConnectSlack
  'Send Invites'       : HomeTeamSendInvites
  Teammates            : HomeTeamTeammates
  'Team Settings'      : HomeTeamSettings
  Permissions          : HomeTeamPermissions

section = (name, options, data) ->
  sectionize name, SECTIONS[name], options, data


module.exports = class HomeMyTeam extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    kd.singletons.groupsController.ready @bound 'putViews'


  handleAnchor: (anchor) ->

    kd.utils.defer ->
      selector = switch anchor
        when '#send-invites'
          '.user-email'
        when ''
          '.js-teamName'

      document.querySelector(selector).focus?()  if selector


  putViews: ->

    { JAccount } = remote.api
    { groupsController, reactor } = kd.singletons
    team = groupsController.getCurrentGroup()

    TeamFlux.actions.loadTeam()
    TeamFlux.actions.loadPendingInvitations()
    TeamFlux.actions.loadDisabledUsers()
    AppFlux.actions.user.loadLoggedInUserEmail()

    groupsController.on 'MembershipRoleChanged', (data) ->

      { contents: { role, id, adminNick } } = data
      reactor.dispatch 'UPDATE_TEAM_MEMBER_WITH_ID', { id, role }

      if id is whoami()._id
        modal = new MembershipRoleChangedModal
          success: ->
            modal.destroy()
            global.location.reload yes
        , { role, adminNick }

    groupsController.on 'InvitationChanged', (data) ->

      { contents: { type, invitations, id } } = data

      switch type
        when 'remove'
          reactor.dispatch 'REMOVE_PENDING_INVITATION_BY_ID', { id }
        when 'create'
          reactor.dispatch 'LOAD_PENDING_INVITATION_SUCCESS', { invitations }

    groupsController.on 'GroupJoined', (data) ->

      return console.warm 'We couldn\'t fetch neccessary information'  unless data.contents.member
      return  unless data.contents.actionType is 'groupJoined'

      { roles, email, username } = data.contents.member

      remote.cacheable username, (err, accounts) ->

        return  if err or not accounts

        account = toImmutable accounts[0]
        account = account.setIn ['profile', 'email'], email
        account = account.set 'role', roles

        id = account.get '_id'

        reactor.dispatch 'UPDATE_TEAM_MEMBER', { account }
        reactor.dispatch 'ADD_MEMBER_TO_TEAM', { id }
        reactor.dispatch 'REMOVE_PENDING_INVITATION', { email }

    groupsController.on 'GroupLeft', (data) ->

      { username } = data.contents.member
      remote.cacheable username, (err, accounts) ->

        return  if err or not accounts

        account = accounts[0]
        reactor.dispatch 'DELETE_TEAM_MEMBER', account._id

    @wrapper.addSubView headerize 'Team Settings'
    @wrapper.addSubView @teamSettings = section 'Team Settings'

    if isAdmin()
      @wrapper.addSubView headerize 'Permissions'
      @wrapper.addSubView @permissions = section 'Permissions'

    if isAdmin() or canSeeMembers()

      @wrapper.addSubView headerize 'Send Invites'
      @wrapper.addSubView @sendInvites = section 'Send Invites'

      @wrapper.addSubView headerize 'Invite Using Slack'
      @wrapper.addSubView @connectSlack = section 'Invite Using Slack'
      @connectSlack.on 'InvitationsAreSent', -> TeamFlux.actions.loadPendingInvitations()

      @wrapper.addSubView headerize 'Teammates'
      @wrapper.addSubView @teammates = section 'Teammates'

