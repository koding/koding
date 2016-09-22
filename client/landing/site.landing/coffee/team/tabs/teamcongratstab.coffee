kd             = require 'kd'
utils          = require './../../core/utils'
JView          = require './../../core/jview'
MainHeaderView = require './../../core/mainheaderview'

module.exports = class TeamCongratzTab extends kd.TabPaneView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    { mainController } = kd.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    teamData = utils.getTeamData()
    { slug } = teamData.domain

    @button = new kd.ButtonView
      title      : "Sign in to #{slug}.#{kd.config.domains.main}"
      style      : 'TeamsModal-button'
      callback   : ->
        utils.clearTeamData()
        { protocol, host } = location
        location.href      = "#{protocol}//#{slug}.#{host}"

    @on 'PaneDidShow', => @button.setFocus()


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      <figure class='congrats'></figure>
      <h4>Congratulations!</h4>
      <h5>Now please go ahead and login to your team page and setup your compute stacks and communication channels for your team members.</h5>
      <p class='dim'>Don't worry we'll show you how.</p>
      {{> @button}}
    </div>
    """
