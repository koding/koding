kd                    = require 'kd'
KDView                = kd.View
TeamMembersCommonView = require '../members/teammemberscommonview'


module.exports = class AcceptedInvitationsView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    super options, data

