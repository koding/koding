JView                     = require './../../core/jview'
MainHeaderView            = require './../../core/mainheaderview'
TeamUsernameTabForm       = require './../forms/teamusernametabform'
TeamLoginAndCreateTabForm = require './../forms/teamloginandcreatetabform'

module.exports = class TeamUsernameTab extends KDTabPaneView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.name = 'username'

    super options, data

    teamData           = KD.utils.getTeamData()
    { alreadyMember }  = teamData.signup
    { mainController } = KD.singletons

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

      @form = new TeamLoginAndCreateTabForm
        callback : (formData) ->
          KD.utils.storeNewTeamData 'username', formData
          KD.utils.createTeam (err, res) -> console.log err, res
    else

      @title = new KDCustomHTMLView
        tagName : 'h4'
        partial : 'Choose a Username'

      @subtitle = new KDCustomHTMLView
        tagName : 'h5'
        partial : '...or login with your existing Koding account.'

      @form = new TeamUsernameTabForm
        callback : (formData) ->
          KD.utils.storeNewTeamData 'username', formData
          KD.utils.createTeam (err, res) -> console.log err, res



  pistachio: ->

    """
    {{> @header }}
    <div class="TeamsModal TeamsModal--groupCreation">
      {{> @title}}
      {{> @subtitle}}
      {{> @form}}
    </div>
    """