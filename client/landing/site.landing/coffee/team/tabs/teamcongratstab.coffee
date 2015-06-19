JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'

module.exports = class TeamCongratzTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'congrats'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <figure></figure>
      <h4>Congratulations</h4>
      <h5>You are done.</h5>
    </div>
    """