JView                     = require './../../core/jview'
MainHeaderView            = require './../../core/mainheaderview'
TeamUsernameTabForm       = require './../forms/teamusernametabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamUsernameTab extends KDTabPaneView

  JView.mixin @prototype

  callback = (formData) ->
    { storeNewTeamData, createTeam, joinTeam, getTeamData } = KD.utils
    { join } = getTeamData().signup
    storeNewTeamData 'username', formData
    if join then joinTeam() else do ->
      createTeam success : -> KD.singletons.router.handleRoute '/Team/Stacks'

  constructor:(options = {}, data)->

    options.name = 'username'

    super options, data

    teamData          = KD.utils.getTeamData()
    { alreadyMember } = teamData.signup

    @header = new MainHeaderView
      cssClass : 'team'
      navItems : []

    if alreadyMember

      @title = new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Almost there'

      @subtitle = new KDCustomHTMLView
        tagName : 'h5'
        partial : 'please enter your Koding password'

      @form = new TeamLoginAndCreateTabForm { callback }

    else

      @title = new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Choose a Username'

      @subtitle = new KDCustomHTMLView
        tagName : 'h5'
        partial : '...or login with your existing Koding account.'

      @form = new TeamUsernameTabForm
        callback : (formData) ->
          { username } = formData

          KD.utils.usernameCheck username,
            success : -> callback formData
            error   : ({responseJSON}) =>

              {forbidden, kodingUser} = responseJSON
              msg = if forbidden then "Sorry, \"#{username}\" is forbidden to use!"
              else if kodingUser then "Sorry, \"#{username}\" is already taken!"
              else                    "Sorry, there is a problem with \"#{username}\"!"

              new KDNotificationView title : msg


  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      {{> @title}}
      {{> @subtitle}}
      {{> @form}}
    </div>
    """