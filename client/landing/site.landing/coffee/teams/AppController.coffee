TeamsView         = require './AppView'
TeamsWaitListView = require './teamswaitlistview'

module.exports = class TeamsAppController extends KDViewController

  KD.registerAppClass this, name : 'Teams'

  constructor: (options = {}, data) ->

    if KD.utils.getTeamData().invitation?.teamAccessCode
    then options.view = new TeamsView { cssClass: 'content-page' }
    else options.view = new TeamsWaitListView { cssClass: 'content-page teams' }

    super options, data


  handleQuery: (query) ->

    return  if not query or not query.group

    { input } = @getView().form.companyName
    input.setValue query.group.capitalize()
    @getView().form.companyName.inputReceivedKeyup()
