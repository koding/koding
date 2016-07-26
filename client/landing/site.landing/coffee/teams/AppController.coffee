kd                = require 'kd'
TeamsView         = require './AppView'
TeamSelectorView  = require './teamselectorview'
FindTeamView      = require './findteamview'


module.exports = class TeamsAppController extends kd.ViewController


  kd.registerAppClass this, { name : 'Teams' }


  constructor: (options = {}, data) ->

    { currentPath } = kd.singletons.router

    options.view = switch
      when currentPath.indexOf('/Teams/Create') > -1
      then new TeamsView { cssClass: 'content-page' }
      when currentPath.indexOf('/Teams/FindTeam') > -1
      then new FindTeamView { cssClass: 'content-page' }
      else new TeamSelectorView { cssClass: 'content-page' }

    super options, data


  handleQuery: (query) ->

    return  if not query or not query.group

    { input } = @getView().form.companyName
    input.setValue query.group.capitalize()
    @getView().form.companyName.inputReceivedKeyup()
