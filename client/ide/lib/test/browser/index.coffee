React = require 'react'
ReactView = require 'app/react/reactview'
Dialog = require 'lab/Dialog'

expect = require 'expect'

run = ->

  tests = [
    require './example'
  ]

  try
    tests.forEach (test) -> test expect
    showSuccessModal()
  catch e
    showErrorModal(e.message)


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

showSuccessModal = ->

  modal = new ModalView
    title: 'Success!'
    type: 'success'
    message: 'All tests passed'
    buttonTitle: 'Close'
    onButtonClick: -> modal.destroy()


showErrorModal = (message) ->

  modal = new ModalView
    title: 'Error!'
    subtitle: 'There is an error'
    type: 'danger'
    message: message
    buttonTitle: 'Close'
    onButtonClick: -> modal.destroy()

# /cc @gokmen: this might be a strong possible replacement for
# pistachio. KDViews will be where we write logic, React components will always
# be small enough to be treated as a pistachio string.
# This way, each ReactView wrapping kd view can implement what the f*ck it
# wants, either bongo model, or a redux store. KDViews could be the solutions
# of colocating data with view components.
#
# tl;dr: KDViews will do the fetching data in the way we are used to it right now.
# Once they have the data, we can stop thinking about efficient rendering but
# let React handle updating the DOM.
#
# Only missing part is creating a React Component that can render a KDView,
# which is a pretty easy thing to do.
#
# I think we might be looking at *the best* solution out there, with KDView &
# ReactComponent duo combined, as a data fetching & business logic abstraction
# solution. ~Umut
class ModalView extends ReactView

  constructor: (options = {}, data) ->
    options.isOpen ?= yes
    options.alien ?= yes
    options.type ?= 'success'
    options.subtitle ?= ''
    options.appendToDomBody ?= yes
    super options
    @appendToDomBody()  if @getOptions().appendToDomBody

  onButtonClick: ->
    @options.onButtonClick()

  renderReact: ->
    <Dialog
      isOpen={@options.isOpen}
      showAlien={@options.alien}
      type={@options.type}
      title={@options.title}
      subtitle={@options.subtitle}
      message={@options.message}
      buttonTitle={@options.buttonTitle}
      onButtonClick={@bound 'onButtonClick'}
    />

module.exports = {
  run
  prepare
}
