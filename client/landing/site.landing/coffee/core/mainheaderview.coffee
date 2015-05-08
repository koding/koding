TopNavigation  = require './topnavigation'

module.exports = class MainHeaderView extends KDView

  constructor: (options = {}, data) ->

    options.tagName    or= 'header'
    options.cssClass     = KD.utils.curry options.cssClass, 'main-header'
    options.attributes or= testpath : 'main-header'

    super options, data


  viewAppended: ->

    @addSubView @mobileMenu = new TopNavigation cssClass : 'mobile-menu'

    { navItems } = @getOptions()
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

    @addSubView @logo = new KDCustomHTMLView
      tagName   : 'a'
      cssClass  : 'koding-header-logo'
      partial   : '<cite></cite>'
      click     : (event) ->
        KD.utils.stopDOMEvent event
        KD.singletons.router.handleRoute '/'
