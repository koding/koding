JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'

createAvatar = (profile) ->

  { hash, firstName, lastName, nickname } = profile
  defaultImg = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.38.png"
  src        = "//gravatar.com/avatar/#{hash}?size=38&d=#{defaultImg}&r=g"
  name       = (firstName + ' ' + lastName) or nickname
  el         = "<li><img src=\"#{src}\" alt=\"#{name}'s avatar\" title=\"#{name}\" /></li>"

  return el



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
      style      : 'TeamsModal-button TeamsModal-button--green correct'
      callback   : -> KD.singletons.router.handleRoute '/Join'

    @decorateTeamMembers()


  decorateTeamMembers: ->

    KD.utils.fetchTeamMembers KD.config.groupName, (err, members) =>

      return  if err or not members

      @$('.team-members ul').append createAvatar profile  for { profile } in members
      @$('.team-members').removeClass 'hidden'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--onboarding">
      <h4>Welcome</h4>
      <p>You are about to join to <i>#{KD.config.group.title}</i> on Koding</p>
      <div class='team-members hidden'>
        <ul></ul>
        <span>and 34 of your team members are already here.</span>
      </div>
      <p>
        Your invitation was sent to:
        <email>#{KD.utils.getTeamData().invitation.email}<email>
      </p>
      <br/>
      <p>
        Is the email address above correct?<br/>
        {{> @correct}}
      </p>
      <br/>
      <p>If that's not right please contact the team administrators to get a new invitation.</p>
    </div>
    """