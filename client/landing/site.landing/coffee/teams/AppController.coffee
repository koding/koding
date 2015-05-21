TeamsView = require './AppView'

module.exports = class TeamsAppController extends KDViewController

  KD.registerAppClass this, name : 'Teams'

  constructor: (options = {}, data) ->

    options.view = new TeamsView
      cssClass   : 'content-page teams'

    super options, data


  handleQuery: (query) ->

    return  if not query or not query.group

    { input } = @getView().form.companyName
    input.setValue query.group.capitalize()
    @getView().form.companyName.inputReceivedKeyup()
