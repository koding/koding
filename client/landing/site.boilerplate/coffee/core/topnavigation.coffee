CustomLinkView = require './customlinkview'

module.exports = class TopNavigation extends KDCustomHTMLView

  menu = [
    { title : 'Koding University', href : 'http://learn.koding.com', name : 'about'}
    { title : 'Features',          href : '/Features',               name : 'features'}
    { title : 'SIGN IN',           href : '/Login',                  name : 'login', attributes: testpath: 'login-link'}
  ]

  constructor: (options = {}, data) ->

    options.tagName or= 'nav'

    super options, data

    @menu = {}

    {mainView} = KD.singletons
    mainView.on 'MainTabPaneShown', @bound 'setActiveItem'


  viewAppended: ->

    @createItem options  for options in menu


  createItem: (options) ->

    options.cssClass = options.name.toLowerCase()

    @addSubView @menu[options.name] = new CustomLinkView options


  setActiveItem: (pane) ->

    @unsetActiveItems()

    {name} = pane

    @menu[name]?.setClass 'active'


  unsetActiveItems: ->

    item.unsetClass 'active'  for own name, item of @menu

