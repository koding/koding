kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
FailuresModal = require './failuresmodal'
Modal = require 'lab/Modal'


class TestOutputModal extends ReactView

  constructor: (options = {}, data) ->
    options.title ?= ''
    options.isOpen ?= yes
    options.appendToDomBody ?= yes
    options.showTable ?= no
    super options
    @appendToDomBody()  if @getOptions().appendToDomBody


  showTable: (event) ->
    @updateOptions { showTable: not @options.showTable }

  renderReact: ->

    buttonTitle = 'See Mocha Output View'
    buttonTitle = 'See Failures OutputView'  unless @options.showTable

    <Modal width='xlarge' height='taller' showAlien={yes} isOpen={@options.isOpen}>
      <Modal.Header title={@options.title} />
      <Modal.Content>
        <div className='switch-button' onClick={@bound 'showTable'}>{buttonTitle}</div>
        <ShowTable showTable={@options.showTable} />
        <MochaOutput showTable={@options.showTable} />
      </Modal.Content>
    </Modal>


MochaOutput = ({ showTable }) ->
  className = 'mocha-output'
  className = 'mocha-output hidden'  if showTable

  <div className={className}>
    <div id="mocha"></div>
  </div>

ShowTable = ({ showTable }) ->

  return <span />  unless showTable

  failureStore = kd.singletons.reactor.evaluate(['TestSuitesFailureStore'])
  fileNames = Object.keys failureStore

  return <span />  unless fileNames.length

  <div className='suite-results'>
   <FailuresModal store={failureStore} files={fileNames} />
  </div>


module.exports = TestOutputModal
