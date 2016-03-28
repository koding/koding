kd = require 'kd'
TopNavigation  = require './topnavigation'

module.exports = class MainHeaderView extends kd.View

  constructor: (options = {}, data) ->

    options.tagName    or= 'header'
    options.cssClass     = kd.utils.curry options.cssClass, 'main-header'
    options.attributes or= { testpath : 'main-header' }

    super options, data


  viewAppended: ->

    @addSubView @mobileMenu = new TopNavigation { cssClass : 'mobile-menu' }

    { navItems, headerLogo } = @getOptions()
    @addSubView new TopNavigation { navItems, cssClass : 'full-menu' }

    @addSubView @hamburgerMenu = new kd.ButtonView
      cssClass  : 'hamburger-menu'
      iconOnly  : yes
      callback  : =>
        @toggleClass 'mobile-menu-active'
        @hamburgerMenu.toggleClass 'active'
        @mobileMenu.toggleClass 'active'

        @once 'click', =>
          @toggleClass 'mobile-menu-active'
          @hamburgerMenu.toggleClass 'active'
          @mobileMenu.toggleClass 'active'

    @addSubView @logo = headerLogo or new kd.CustomHTMLView
      tagName   : 'a'
      cssClass  : 'koding-header-logo'
      partial   : '<cite></cite>'
      click     : (event) ->
        kd.utils.stopDOMEvent event
        kd.singletons.router.handleRoute '/'

    @addSubView @hiringBadge = new kd.CustomHTMLView
      tagName   : 'a'
      cssClass  : 'hiring-badge'
      attributes:
        href    : 'http://bit.ly/1MTsnJt'
        title   : 'Join the Global Virtual Hackathon with $100k grand prize!'

    kd.utils.wait 3000, => @setClass 'hiring-badge-in'
