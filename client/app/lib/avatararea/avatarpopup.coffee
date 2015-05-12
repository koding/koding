$ = require 'jquery'
isLoggedIn = require '../util/isLoggedIn'
kd = require 'kd'
KDView = kd.View


module.exports = class AvatarPopup extends KDView

  constructor: (options = {}, data)->

    options.cssClass = kd.utils.curry 'avatararea-popup', options.cssClass

    super options, data

    @addSubView @avatarPopupContent = new KDView cssClass : 'content'

    @listenWindowResize()


  show:->

    { mainController, windowController } = kd.singletons
    kd.utils.killWait @loaderTimeout
    @_windowDidResize()
    windowController.addLayer this
    mainController.emit 'AvatarPopupIsActive'
    @setClass 'active'

    return this


  hide:->

    { mainController } = kd.singletons
    mainController.emit 'AvatarPopupIsInactive'
    @unsetClass 'active'

    return this


  _windowDidResize:->

    return  unless @listController

    { scrollView }  = @listController
    windowHeight    = window.innerHeight
    offset          = 65 + 50 # bottom offset + min top offset
    maxHeight       = windowHeight - offset

    scrollView.setCss { maxHeight }
