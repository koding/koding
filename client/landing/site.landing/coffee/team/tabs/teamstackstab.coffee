JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'

module.exports = class TeamStacksTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'stacks'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @next = new KDButtonView
      title      : 'Next'
      style      : 'TeamsModal-button TeamsModal-button--green'
      callback   : -> KD.singletons.router.handleRoute '/Team/Congrats'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation clearfix">
      <h4>Setup your stack</h4>
      <h5>You can setup advanced things such as executing scripts in newly created machines, or provisioning new services from your group dashboard.</h5>
      <figure></figure>
      {{> @next}}
    </div>
    """