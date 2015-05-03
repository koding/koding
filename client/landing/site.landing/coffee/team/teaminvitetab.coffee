JView             = require './../core/jview'
MainHeaderView    = require './../core/mainheaderview'
TeamInviteTabForm = require './teaminvitetabform'

module.exports = class TeamInviteTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'invite'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamInviteTabForm


  pistachio: ->

    """
    {{> @header }}
    <div class="SignupForm">
      <h4>Invite Colleagues</h4>
      {{> @form}}
    </div>
    """