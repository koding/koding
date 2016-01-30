kd              = require 'kd'
YourStacksView  = require 'app/environment/yourstacksview'


module.exports = class EnvironmentsModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.title     or= 'Your Machines'
    options.width     or= 742
    options.cssClass    = kd.utils.curry 'environments-modal', options.cssClass
    options.overlay    ?= yes

    super options, data

    @addSubView yourStacks = new YourStacksView

    yourStacks.on 'DestroyParent', @bound 'destroy'


  destroy: (goBack = yes) ->

    super

    kd.singletons.router.back()  if goBack
