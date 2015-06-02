kd                        = require 'kd'
EnvironmentList           = require './environmentlist'
EnvironmentListController = require './environmentlistcontroller'


module.exports = class EnvironmentsModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environments-modal', options.cssClass
    options.width    = 742
    options.title    = 'Your VMs'
    options.overlay  = yes

    super options, data

  viewAppended: ->

    super

    listView   = new EnvironmentList
    controller = new EnvironmentListController
      view       : listView
      wrapper    : no
      scrollView : no

    @addSubView controller.getView()
