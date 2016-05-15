kd = require 'kd'
InstructionsController = require './controllers/instructionscontroller'
CredentialsController = require './controllers/credentialscontroller'
helpers = require './helpers'

module.exports = class BuildStackModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'build-stack-modal', options.cssClass
    super options, data

    stack = @getData()

    @instructions = new InstructionsController { delegate: this }, stack
    @instructions.on 'NextPageRequested', =>
      helpers.changePage @instructions, @credentials

    @credentials = new CredentialsController { delegate: this }, stack
    @credentials.on 'InstructionsRequested', =>
      helpers.changePage @credentials, @instructions
