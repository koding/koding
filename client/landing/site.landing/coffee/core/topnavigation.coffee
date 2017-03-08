kd             = require 'kd'
CustomLinkView = require './customlinkview'


module.exports = class TopNavigation extends kd.CustomHTMLView

  menu = [
    { title : 'Login',   href : '/Teams', name : 'teams' }
  ]

  constructor: (options = {}, data) ->

    options.tagName  or= 'nav'
    options.navItems or= menu

    super options, data

    @menu = {}

    { mainView } = kd.singletons
    mainView.on 'MainTabPaneShown', @bound 'setActiveItem'


  viewAppended: ->

    { navItems } = @getOptions()
    return  unless navItems.length

    @createItem options  for options in navItems


  createItem: (options) ->

    options.cssClass = options.name.toLowerCase()
    link             = new CustomLinkView options

    if /^http/.test options.href
      link.setAttribute 'target', '_self'

    @addSubView @menu[options.name] = link


  setActiveItem: (pane) ->

    @unsetActiveItems()

    { name } = pane

    @menu[name]?.setClass 'active'


  unsetActiveItems: ->

    item.unsetClass 'active'  for own name, item of @menu
