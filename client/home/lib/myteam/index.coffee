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
camelizeString = require 'app/util/camelizeString'
toImmutable = require 'app/util/toImmutable'
canSeeMembers = require 'app/util/canSeeMembers'
isAdmin = require 'app/util/isAdmin'

SECTIONS =
  'Invite Using Slack' : HomeTeamConnectSlack
  'Send Invites'       : HomeTeamSendInvites
  Teammates            : HomeTeamTeammates
  'Team Settings'      : HomeTeamSettings
  Permissions          : HomeTeamPermissions

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

    @scroll = no
    @scrollToSection = null


  handleAction: (action) ->

    TeamFlux.actions.focusSendInvites yes  if action is 'send-invites'

    @scroll = yes
    @scrollToSection = camelizeString action

    @scrollToSectionArea()


  scrollToSectionArea: ->

    return  unless @scrollToSection

    if @scroll and subView = @[@scrollToSection]

      viewTop = @wrapper.getY()
      subViewTop = subView.getY()
      sectionHeader = 88  # height of header of dashboard
      sectionHeader = sectionHeader + 235 # height of permisson section

      scrollMuch = subViewTop - viewTop - sectionHeader

      subViewHeight = subView.getHeight()

      if subViewHeight > scrollMuch
        scrollMuch = subViewHeight - scrollMuch

      @wrapper?.scrollTo { top: scrollMuch }


  putViews: ->

    { JAccount } = remote.api
    { groupsController, reactor } = kd.singletons
    team = groupsController.getCurrentGroup()

    TeamFlux.actions.loadTeam()
    TeamFlux.actions.loadPendingInvitations()
    TeamFlux.actions.loadDisabledUsers()
    AppFlux.actions.user.loadLoggedInUserEmail()

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

    @wrapper.addSubView header  'Team Settings'
    @wrapper.addSubView @teamSettings = section 'Team Settings'

    if isAdmin()
      @wrapper.addSubView header  'Permissions'
      @wrapper.addSubView @permissions = section 'Permissions'

    if isAdmin() or canSeeMembers()

      @wrapper.addSubView header  'Send Invites'
      @wrapper.addSubView @sendInvites = section 'Send Invites'

      @wrapper.addSubView header  'Invite Using Slack'
      @wrapper.addSubView @connectSlack = section 'Invite Using Slack'
      @connectSlack.on 'InvitationsAreSent', -> TeamFlux.actions.loadPendingInvitations()

      @wrapper.addSubView header  'Teammates'
      @wrapper.addSubView @teammates = section 'Teammates'

    @scrollToSectionArea()
