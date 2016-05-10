kd = require 'kd'
BuildStackView = require './buildstackview'
BuildStackModalController = require './buildstackmodalcontroller'

module.exports = class BuildStackModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'build-stack-modal', options.cssClass
    options.title   ?= 'Build Your Stack'

    super options, data

    stack = @getData()

    @controller = new BuildStackModalController {}, stack
    @controller.loadData (err, credentials) =>
      { provider } = @controller
      @addSubView @view = new BuildStackView { provider }, { stack, credentials }
