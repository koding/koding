kd                   = require 'kd'


# SECTIONS =
#   'Invite Using Slack' : HomeTeamConnectSlack
#   'Send Invites'       : HomeTeamSendInvites
#   Teammates            : HomeTeamTeammates

# section = (name, options, data) ->
#   new (SECTIONS[name] or kd.View) options or {
#     tagName  : 'section'
#     cssClass : "HomeAppView--section #{kd.utils.slugify name}"
#   }, data


module.exports = class HomeTeamBilling extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { groupsController } = kd.singletons

    @addSubView scrollView = new kd.CustomScrollView
      cssClass : 'HomeAppView--scroller'

    { wrapper } = scrollView

    # wrapper.addSubView section 'Invite Using Slack'
    # wrapper.addSubView section 'Send Invites'
    # wrapper.addSubView section 'Teammates', null, team
