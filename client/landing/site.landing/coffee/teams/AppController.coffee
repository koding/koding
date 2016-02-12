kd                = require 'kd.js'
utils             = require './../core/utils'
TeamsView         = require './AppView'
TeamSelectorView  = require './teamselectorview'


module.exports = class TeamsAppController extends kd.ViewController


  kd.registerAppClass this, name : 'Teams'


  constructor: (options = {}, data) ->

    if utils.getTeamData().invitation?.teamAccessCode
    then options.view = new TeamsView { cssClass: 'content-page' }
    else options.view = new TeamSelectorView { cssClass: 'content-page' }

    super options, data


  handleQuery: (query) ->

    return  if not query or not query.group

    { input } = @getView().form.companyName
    input.setValue query.group.capitalize()
    @getView().form.companyName.inputReceivedKeyup()
