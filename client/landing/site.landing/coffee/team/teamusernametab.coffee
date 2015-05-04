JView                   = require './../core/jview'
MainHeaderView          = require './../core/mainheaderview'
TeamUsernameTabForm     = require './teamusernametabform'

module.exports = class TeamUsernameTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'username'

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
    <div class="SignupForm">
      <h4>Choose a Username</h4>
      {{> @form}}
    </div>
    """