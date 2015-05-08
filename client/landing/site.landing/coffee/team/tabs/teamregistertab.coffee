JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'
# TeamRegisterTabForm = require './../forms/teaminvitetabform'

module.exports = class TeamRegisterTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'register'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    # @form = new KDFormView
    #   callback: (formData) ->
    #     KD.utils.storeNewTeamData 'invitees', formData
    #     KD.singletons.router.handleRoute '/Team/username'

  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal">
      <h4></h4>
    </div>
    """