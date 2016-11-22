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
    isOpen: yes

  manager.on 'status', (status) ->
    newOptions =
      title: "Testing Koding: #{status or 'umut'}"
      # this works but the latest event is coming as undefined
      # that's why you will not see a modal, if you want to force
      # show modal, just pass `yes` here.
      isOpen: yes # status in ['failed', 'success']

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
