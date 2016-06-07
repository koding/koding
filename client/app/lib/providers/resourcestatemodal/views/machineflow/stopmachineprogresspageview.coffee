kd = require 'kd'
JView = require 'app/jview'
helpers = require '../../helpers'
constants = require '../../constants'

module.exports = class StopMachineProgressPageView extends JView

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
      <div class="stop-machine-flow stop-machine-progress-page">
        <header>
          <h1>Turn Off VM</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2><span>"#{title}"</span> is Being Turned Off</h2>
          {{> @progressBar}}
        </section>
      </div>
    """
