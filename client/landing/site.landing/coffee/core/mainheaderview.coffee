TopNavigation  = require './topnavigation'

module.exports = class MainHeaderView extends KDView

  constructor: (options = {}, data) ->

    options.tagName    or= 'header'
    options.cssClass     = KD.utils.curry options.cssClass, 'main-header'
    options.attributes or= testpath : 'main-header'

    super options, data


  viewAppended: ->

    @addSubView @mobileMenu = new TopNavigation cssClass : 'mobile-menu'

    { navItems, headerLogo } = @getOptions()
    @addSubView new TopNavigation { navItems, cssClass : 'full-menu' }

    @addSubView @hamburgerMenu = new KDButtonView
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

    @addSubView @logo = headerLogo or new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'koding-header-logo'
      partial   : '<cite></cite>'
      click     : (event) ->
        KD.utils.stopDOMEvent event
        KD.singletons.router.handleRoute '/'

    @addSubView @hiringBadge = new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'hiring-badge'
      attributes:
        href    : 'http://bit.ly/1MTsnJt'
        title   : 'Join the Global Virtual Hackathon with $100k grand prize!'

    KD.utils.wait 3000, => @setClass 'hiring-badge-in'
