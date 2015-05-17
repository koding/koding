JView               = require './../../core/jview'
MainHeaderView      = require './../../core/mainheaderview'
TeamUsernameTabForm = require './../forms/teamusernametabform'

module.exports = class TeamRegisterTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'register'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamUsernameTabForm
      callback : (formData) ->
        KD.utils.storeNewTeamData 'username', formData
        KD.utils.createTeam (err, res) -> console.log err, res


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Choose a Username</h4>
      {{> @form}}
    </div>
    """