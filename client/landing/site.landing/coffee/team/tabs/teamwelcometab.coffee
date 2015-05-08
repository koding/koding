JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'

module.exports = class TeamWelcomeTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'welcome'

    super options, data

    { mainController } = KD.singletons

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @correct = new KDButtonView
      title      : 'Yes, that\'s the right address'
      style      : 'TeamsModal-button TeamsModal-button--green'
      callback   : ->
        console.log 'right address!'

    @decorateTeamMembers()


  decorateTeamMembers: ->

    KD.utils.fetchTeamMembers KD.config.groupName, (err, members) ->
      console.log err, members


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal">
      <h4>Welcome</h4>
      <p>You are about to join to <i>#{KD.config.group.title}</i> on Koding</p>
      <p class='team-members'>
        <ul>
          <li></li>
          <li></li>
          <li></li>
          <li></li>
        </ul>
        <span>and 34 of your team members are already here.</span>
      </p>
      <p>Your invitation was sent to:</p>
      <p><email>#{KD.utils.getTeamData().invitation.email}<email></p>
      <p>Is the email address above correct?</p>
      {{> @correct}}
      <p>If that's not right please contact the team administrators to get a new invitation.</p>
    </div>
    """