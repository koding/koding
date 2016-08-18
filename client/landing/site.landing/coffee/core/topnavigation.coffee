kd             = require 'kd'
CustomLinkView = require './customlinkview'


module.exports = class TopNavigation extends kd.CustomHTMLView

  menu = [
    { title : 'Koding University', href : 'https://koding.com/docs',         name : 'about' }
    { title : 'Teams',             href : '/Teams',                          name : 'teams' }
    { title : 'Features',          href : 'https://www.koding.com/Features', name : 'features', attributes: { target: '_blank' } }
    { title : 'Sign In',           href : '/Login',                          name : 'buttonized white login',  attributes : { testpath : 'login-link' } }
    { title : 'Sign Up',           href : '/Register',                       name : 'buttonized green signup', attributes : { testpath : 'signup-link' } }
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

    @addSubView new kd.CustomHTMLView
      cssClass  : 'mobile-trigger'
      tagName   : 'a'
      partial   : '<span></span><i></i>'
      click     : -> document.body.classList.toggle 'expand-menu'

    @createItem options  for options in navItems


  createItem: (options) ->

    options.cssClass = options.name.toLowerCase()
    link             = new CustomLinkView options
    link.setAttribute 'target', '_self'

    @addSubView @menu[options.name] = link


  setActiveItem: (pane) ->

    @unsetActiveItems()

    { name } = pane

    @menu[name]?.setClass 'active'


  unsetActiveItems: ->

    item.unsetClass 'active'  for own name, item of @menu
