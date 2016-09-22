kd             = require 'kd'
utils          = require './../../core/utils'
JView          = require './../../core/jview'
MainHeaderView = require './../../core/mainheaderview'

module.exports = class TeamStacksTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons
    name = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @next = new kd.ButtonView
      title      : 'Next'
      style      : 'TeamsModal-button'
      callback   : ->
        utils.storeNewTeamData name, yes
        kd.singletons.router.handleRoute '/Team/Congrats'

    @on 'PaneDidShow', => @next.setFocus()

  pistachio: ->

    '''
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation clearfix">
      <h4>Setup your stack</h4>
      <h5>You can setup advanced things such as executing scripts in newly created machines, or provisioning new services from your group dashboard.</h5>
      <figure></figure>
      {{> @next}}
    </div>
    '''
