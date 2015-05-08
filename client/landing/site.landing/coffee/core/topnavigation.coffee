CustomLinkView = require './customlinkview'

module.exports = class TopNavigation extends KDCustomHTMLView

  menu = [
    { title : 'Koding University', href : 'http://learn.koding.com',  name : 'about' }
    { title : 'Features',          href : '/Features',                name : 'features' }
    { title : 'SIGN IN',           href : '/Login',                   name : 'buttonized white login',  attributes : testpath : 'login-link' }
    { title : 'SIGN UP',           href : '/Register',                name : 'buttonized green signup', attributes : testpath : 'signup-link' }
  ]

  if KD.config.environment isnt 'production'
    item = { title : 'Teams', href : '/Teams', name : 'teams' }
    menu.splice 1, 0, item

  constructor: (options = {}, data) ->

    options.tagName  or= 'nav'
    options.navItems or= menu

    super options, data

    @menu = {}

    {mainView} = KD.singletons
    mainView.on 'MainTabPaneShown', @bound 'setActiveItem'


  viewAppended: ->

    @createItem options  for options in @getOptions().navItems


  createItem: (options) ->

    options.cssClass = options.name.toLowerCase()

    @addSubView @menu[options.name] = new CustomLinkView options


  setActiveItem: (pane) ->

    @unsetActiveItems()

    {name} = pane

    @menu[name]?.setClass 'active'


  unsetActiveItems: ->

    item.unsetClass 'active'  for own name, item of @menu

