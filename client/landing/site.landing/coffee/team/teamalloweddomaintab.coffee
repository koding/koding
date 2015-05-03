JView                   = require './../core/jview'
MainHeaderView          = require './../core/mainheaderview'
TeamAllowedDomainTabForm = require './teamalloweddomaintabform'

module.exports = class TeamAllowedDomainTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'alloweddomain'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamAllowedDomainTabForm


  pistachio: ->

    """
    {{> @header }}
    <div class="SignupForm">
      <h4>Email Domains</h4>
      <h5>You can let members of your team sign up by themselves using their email addreess if you have a company/team domain name.</h5>
      {{> @form}}
    </div>
    """