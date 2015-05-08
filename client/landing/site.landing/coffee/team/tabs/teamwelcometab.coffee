JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'

module.exports = class TeamWelcomeTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'welcome'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal">
      <h4></h4>
    </div>
    """