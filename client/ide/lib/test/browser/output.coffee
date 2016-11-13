kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

Modal = require 'lab/Modal'


class TestOutputModal extends ReactView
  constructor: (options = {}, data) ->
    options.title ?= ''
    options.isOpen ?= yes
    options.appendToDomBody ?= yes
    super options
    @appendToDomBody()  if @getOptions().appendToDomBody

  renderFooter: ->
    <span>
      Still don’t know what’s wrong? <a href='//www.koding.com/docs' target='_blank'>Check the testing @ koding</a>
    </span>

  renderReact: ->
    <Modal width="large" showAlien={yes} isOpen={@options.isOpen}>
      <Modal.Header title={@options.title} />
      <Modal.Content>
        <div>
          <div id="mocha"></div>
        </div>
      </Modal.Content>
      <Modal.TextFooter text={@renderFooter()} />
    </Modal>


module.exports = TestOutputModal