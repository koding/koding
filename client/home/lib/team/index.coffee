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


module.exports = class HomeTeamView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { groupsController } = kd.singletons

    @addSubView scrollView = new kd.CustomScrollView
      cssClass : 'HomeAppView--scroller'

    groupsController.ready ->
      team = groupsController.getCurrentGroup()

      { wrapper } = scrollView

      wrapper.addSubView section 'Invite Using Slack'
      wrapper.addSubView section 'Send Invites'
      wrapper.addSubView section 'Teammates', null, team
