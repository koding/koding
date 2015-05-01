kd                    = require 'kd'
KDView                = kd.View
TeamMembersCommonView = require './teammemberscommonview.coffee'


module.exports = class TeamMembersView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    super options, data

