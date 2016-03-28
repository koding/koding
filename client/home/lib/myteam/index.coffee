kd                   = require 'kd'
HomeTeamConnectSlack = require './hometeamconnectslack'
HomeTeamSendInvites  = require './hometeamsendinvites'
HomeTeamTeammates    = require './hometeamteammates'


SECTIONS =
  'Invite Using Slack' : HomeTeamConnectSlack
  'Send Invites'       : HomeTeamSendInvites
  Teammates            : HomeTeamTeammates

section = (name, options, data) ->
  new (SECTIONS[name] or kd.View) options or {
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"
  }, data


module.exports = class HomeMyTeam extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    { groupsController } = kd.singletons

    groupsController.ready =>
      team = groupsController.getCurrentGroup()
      @wrapper.addSubView section 'Invite Using Slack'
      @wrapper.addSubView section 'Send Invites'
      @wrapper.addSubView section 'Teammates', null, team
