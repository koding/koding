TopNavigation  = require './topnavigation'

module.exports = class MainHeaderView extends KDView

  constructor: (options = {}, data) ->

    options.tagName or    = 'header'
    options.domId   or    = 'main-header'
    options.attributes or = testpath : 'main-header'

    super options, data


  viewAppended: ->

    @addSubView @mobileMenu = new TopNavigation cssClass : 'mobile-menu'

    @addSubView new TopNavigation

    @addSubView @hamburgerMenu = new KDButtonView
      cssClass  : 'hamburger-menu'
      iconOnly  : yes
      callback  : =>
        @hamburgerMenu.toggleClass 'active'
        @mobileMenu.toggleClass 'active'

        @once 'click', =>
          @hamburgerMenu.toggleClass 'active'
          @mobileMenu.toggleClass 'active'

    @addSubView @logo = new KDCustomHTMLView
      tagName   : 'a'
      domId     : 'koding-logo'
      partial   : '<cite></cite>'
      click     : (event) ->
        KD.utils.stopDOMEvent event
        KD.singletons.router.handleRoute '/'
