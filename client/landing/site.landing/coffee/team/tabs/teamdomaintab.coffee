JView             = require './../../core/jview'
MainHeaderView    = require './../../core/mainheaderview'
TeamDomainTabForm = require './../forms/teamdomaintabform'

module.exports = class TeamDomainTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = KD.singletons
    name               = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @form = new TeamDomainTabForm
      callback: (formData) =>

        KD.utils.verifySlug formData.slug,
          success : =>
            @form.input.unsetClass 'validation-error'
            KD.utils.storeNewTeamData name, formData
            KD.singletons.router.handleRoute '/Team/Email-domains'

          error    : =>
            @form.input.setClass 'validation-error'
            new KDNotificationView title : 'That domain is taken, please try another one.'




  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <h4>Team URL</h4>
      <h5>Pick something short, memorable for your team's web address.</h5>
      {{> @form}}
    </div>
    """