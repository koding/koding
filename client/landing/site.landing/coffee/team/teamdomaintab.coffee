JView             = require './../core/jview'
MainHeaderView    = require './../core/mainheaderview'
TeamDomainTabForm = require './teamdomaintabform'

module.exports = class TeamDomainTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'domain'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamDomainTabForm


  pistachio: ->

    """
    {{> @header }}
    <div class="SignupForm">
      <h4>Team URL</h4>
      <h5>Pick something short, memorable for your team's web address.</h5>
      {{> @form}}
    </div>
    """