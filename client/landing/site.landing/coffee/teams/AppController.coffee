kd = require 'kd'

module.exports = class TeamsAppController extends kd.ViewController

  PAGES =
    create : require './AppView'
    select : require './teamselectorview'
    find   : require './findteamview'


  kd.registerAppClass this, { name : 'Teams' }


  constructor: (options = {}, data) ->

    { currentPath } = kd.singletons.router

    options.view = new kd.TabView { hideHandleContainer : yes }

    super options, data


  showPage: (name) ->

    view = @getView()

    if pane = view.getPaneByName name
    then view.showPane pane
    else view.addPane new PAGES[name] { name, cssClass : 'content-page' }


  handleQuery: (query) ->

    return  if not query or not query.group

    page = @getView().getActivePane()
    { input } = page.form.companyName
    input.setValue query.group.capitalize()
