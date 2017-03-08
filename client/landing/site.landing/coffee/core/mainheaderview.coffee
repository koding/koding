kd = require 'kd'
TopNavigation  = require './topnavigation'
utils = require './utils'

module.exports = class MainHeaderView extends kd.View

  constructor: (options = {}, data) ->

    options.tagName    or= 'header'
    options.cssClass     = kd.utils.curry options.cssClass, 'main-header'
    options.attributes or= { testpath : 'main-header' }

    super options, data


  viewAppended: ->

    { navItems, headerLogo } = @getOptions()
    @addSubView new TopNavigation { navItems, cssClass : 'full-menu' }

    if location.hostname is 'koding.com'
      href = 'https://www.koding.com'

    @addSubView @logo = headerLogo or new kd.CustomHTMLView
      tagName   : 'a'
      attributes: { href }  if href
      cssClass  : 'koding-header-logo'
      partial   : '<img src="/a/images/logos/header_logo.svg" class="main-header-logo" alt="Koding Logo">'
      click     : (event) ->

        return yes  if href

        kd.utils.stopDOMEvent event
        kd.singletons.router.handleRoute '/'
