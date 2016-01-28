JView             = require './../../core/jview'
MainHeaderView    = require './../../core/mainheaderview'
TeamInviteTabForm = require './../forms/teaminvitetabform'

module.exports = class TeamInviteTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = KD.singletons
    name               = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamInviteTabForm
      callback: (formData) ->
        KD.utils.storeNewTeamData name, formData
        KD.singletons.router.handleRoute '/Team/Username'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Invite Colleagues</h4>
      {{> @form}}
    </div>
    """
