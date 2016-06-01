kd = require 'kd'
JView = require 'app/jview'
helpers = require '../helpers'
constants = require '../constants'

module.exports = class StartMachineProgressPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressBar = new kd.ProgressBarView
      initial : constants.INITIAL_PROGRESS_VALUE


  updateProgress: (percentage, message) ->

    percentage = Math.max percentage ? 0, constants.INITIAL_PROGRESS_VALUE
    message = helpers.formatProgressStatus message
    @progressBar.updateBar percentage, '%', message


  pistachio: ->

    machine = @getData()
    title   = machine.jMachine.label

    """
      <div class="start-machine-flow start-machine-progress-page">
        <header>
          <h1>Boot Virtual Machine</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2>Spinning up the "#{title}" VM.</h2>
          <p>We're building your VM. Once we're finished you can get to coding.</p>
          {{> @progressBar}}
        </section>
      </div>
    """
