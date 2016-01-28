kd = require 'kd.js'
JView             = require './../../core/jview'
MainHeaderView    = require './../../core/mainheaderview'
TeamInviteTabForm = require './../forms/teaminvitetabform'

module.exports = class TeamInviteTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = kd.singletons
    name               = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamInviteTabForm
      callback: (formData) ->
        kd.utils.storeNewTeamData name, formData
        kd.singletons.router.handleRoute '/Team/Username'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Invite Colleagues</h4>
      {{> @form}}
    </div>
    """
