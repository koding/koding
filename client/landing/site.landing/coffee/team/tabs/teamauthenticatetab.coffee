kd = require 'kd.js'
JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'
# TeamAuthenticateTabForm = require './../forms/teaminvitetabform'

module.exports = class TeamAuthenticateTab extends kd.TabPaneView

  JView.mixin @prototype

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
