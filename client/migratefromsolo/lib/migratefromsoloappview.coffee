kd = require 'kd'
ProvidersView = require 'stacks/views/stacks/providersview'

module.exports = class MigrateFromSoloAppView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass or= kd.utils.curry 'MigrateFromSoloAppView', options.cssClass
    options.width ?= 1000
    options.height ?= '90%'
    options.overlay ?= yes

    super options, data

    @providersView = new ProvidersView

    @addSubView @providersView
