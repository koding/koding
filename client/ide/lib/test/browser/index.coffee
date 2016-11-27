kd = require 'kd'
ModalView = require './modal'
OutputModal = require './output'
Modal = require 'lab/Modal'

IntegrationTestManager = require 'ide/integration-tests'

run = ->

  require './style.css'

  manager = new IntegrationTestManager()

  modal = new OutputModal
    title: 'Testing Koding'
    isOpen: no

  manager.on 'status', (status) ->
    status ?= 'passed'
    newOptions =
      title: "Testing Koding: #{status}"

    if (status is 'success' or 'failed' or 'passed')
      newOptions.isOpen = yes

    modal.updateOptions newOptions

  manager.start()


prepare = (machine, workspace) ->

  modal = new ModalView
    title: 'IDE Browser tests'
    type: 'success'
    message: 'Run IDE by clicking the button below. To start over please
              refresh your browser on this page.'
    buttonTitle: 'Run'
    onButtonClick: ->
      modal.destroy()
      run()


module.exports = {
  run
  prepare
}
