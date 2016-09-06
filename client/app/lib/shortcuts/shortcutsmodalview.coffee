kd = require 'kd'
AccountEditShortcuts = require './accounteditshortcuts'


module.exports = class ShortcutsModalView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.title     or= 'Shortcuts'
    options.cssClass    = kd.utils.curry 'AppModal AppModal--account shortcuts', options.cssClass
    options.overlay    ?= yes

    super options, data

    @addSubView new AccountEditShortcuts


  destroy: (goBack = yes) ->

    super

    kd.singletons.router.back()  if goBack
