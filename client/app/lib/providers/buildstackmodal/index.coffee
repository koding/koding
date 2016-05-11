kd = require 'kd'
async = require 'async'
BuildStackView = require './buildstackview'
BuildStackModalController = require './buildstackmodalcontroller'

module.exports = class BuildStackModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'build-stack-modal', options.cssClass
    options.title   ?= 'Build Your Stack'

    super options, data

    stack = @getData()

    controller = new BuildStackModalController {}, stack
    queue = [
      (next) ->
        controller.loadCredentials next
      (next) ->
        controller.loadRequirements next
    ]

    async.parallel queue, (err, results) =>
      @addSubView new BuildStackView {}, {
        stack
        credentials  : results[0]
        requirements : results[1]
      }
