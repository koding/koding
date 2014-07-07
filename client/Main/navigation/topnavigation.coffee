class TopNavigation extends KDCustomHTMLView

  menu = [
    { title : 'EDUCATION', href : '/Education', appName : 'Education'}
    { title : 'BUSINESS',  href : '/Business',  appName : 'Business'}
    { title : 'ABOUT',     href : '/About',     appName : 'About'}
    { title : 'PRICING',   href : '/Pricing',   appName : 'Pricing'}
    { title : 'SIGN IN',   href : '/Login',     appName : 'Login'}
  ]

  constructor: (options = {}, data) ->

    options.tagName or= 'nav'

    super options, data

    @menu = {}

    appManager = KD.singleton "appManager"

    appManager.on 'AppIsBeingShown', @bound 'setActiveItem'


  viewAppended: ->

    @createItem data  for data in menu


  createItem: (data) ->

    @addSubView @menu[data.appName] = new CustomLinkView href : data.href


  setActiveItem: (instance, view, options) ->

    @unsetActiveItems()

    appName = options.name

    @menu[appName]?.setClass 'active'


  unsetActiveItems: ->

    item.unsetClass 'active'  for own name, item of @menu

