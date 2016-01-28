JView              = require './../../core/jview'
MainHeaderView     = require './../../core/mainheaderview'

createAvatar = (profile) ->

  { hash, firstName, lastName, nickname } = profile
  defaultImg = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.38.png"
  src        = "//gravatar.com/avatar/#{hash}?size=38&d=#{defaultImg}&r=g"
  name       = "#{firstName} #{lastName}" or nickname
  el         = "<li><img src=\"#{src}\" alt=\"#{name}'s avatar\" title=\"#{name}\" /></li>"

  return el


module.exports = class TeamWelcomeTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    super options, data

    { mainController } = KD.singletons
    teamData           = KD.utils.getTeamData()
    name               = @getOption 'name'

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    @correct = new KDButtonView
      title      : 'Yes, that\'s the right address'
      style      : 'TeamsModal-button TeamsModal-button--green correct'
      callback   : ->
        go = ->
          KD.utils.storeNewTeamData 'signup', formData
          KD.utils.storeNewTeamData name, yes
          KD.singletons.router.handleRoute '/Join'

        formData          = {}
        { email }         = teamData.invitation
        formData.join     = yes
        formData.username = email
        formData.slug     = KD.config.group.slug

        KD.utils.validateEmail { email },
          success : -> formData.alreadyMember = no; go()
          error   : -> formData.alreadyMember = yes; go()

    @membersDesc = new KDCustomHTMLView
      tagName: 'span'

    @decorateTeamMembers()

    # temp
    @correct.click()


  decorateTeamMembers: ->

    name      = KD.config.groupName
    { token } = KD.utils.getTeamData().invitation

    KD.utils.fetchTeamMembers { name, token }, (err, members) =>

      return  if err or not members

      if memberCount = KD.config.group.counts?.members
        @membersDesc.updatePartial "#{memberCount} of your team members are<br/>already here."
      else
        @membersDesc.updatePartial "<i>@#{members.first.profile.nickname}</i> has invited you to join."

      @$('.team-members ul').append createAvatar profile  for { profile } in members
      @$('.team-members').removeClass 'hidden'


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--onboarding">
      <h4>Welcome</h4>
      <p>You are about to join to <i>#{KD.config.group.title}</i> on Koding</p>
      <div class='team-members clearfix hidden'>
        <ul></ul>
        {{> @membersDesc}}
      </div>
      <p>
        Your invitation was sent to:
        <address>#{KD.utils.getTeamData().invitation.email}</address>
      </p>
      <p>
        Is the email address above correct?<br/>
        {{> @correct}}
      </p>
      <p>If that's not right please contact the team administrators to get a new invitation.</p>
    </div>
    """
