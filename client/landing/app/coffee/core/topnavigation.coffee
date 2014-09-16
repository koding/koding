CustomLinkView = require './customlinkview'

module.exports = class TopNavigation extends KDCustomHTMLView

  menu = [
    { title : 'ABOUT',     href : '/About',     name : 'about'}
    { title : 'PRICING',   href : '/Pricing',   name : 'pricing'}
    { title : 'SIGN IN',   href : '/Login',     name : 'login'}
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

