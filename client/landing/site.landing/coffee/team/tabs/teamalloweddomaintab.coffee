JView                    = require './../../core/jview'
MainHeaderView           = require './../../core/mainheaderview'
TeamAllowedDomainTabForm = require './../forms/teamalloweddomaintabform'

module.exports = class TeamAllowedDomainTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    name = @getOption 'name'
    @form = new TeamAllowedDomainTabForm
      callback : (formData) ->
        KD.utils.storeNewTeamData name, formData
        KD.singletons.router.handleRoute '/Team/Invite'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Email Domains</h4>
      <h5>You can let members of your team sign up by themselves using their email addreess if you have a company/team domain name.</h5>
      {{> @form}}
    </div>
    """
