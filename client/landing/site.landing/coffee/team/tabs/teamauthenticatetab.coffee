kd = require 'kd'

MainHeaderView     = require './../../core/mainheaderview'

module.exports = class TeamAuthenticateTab extends kd.TabPaneView



  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    # @form = new kd.FormView
    #   callback: (formData) ->
    #     kd.utils.storeNewTeamData 'invitees', formData
    #     kd.singletons.router.handleRoute '/Team/Username'

  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal onboarding">
      <h4></h4>
    </div>
    '''
