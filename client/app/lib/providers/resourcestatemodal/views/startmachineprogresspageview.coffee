kd = require 'kd'
JView = require 'app/jview'

module.exports = class StartMachineProgressPageView extends JView

  INITIAL_PROGRESS_VALUE = 10

  constructor: (options = {}, data) ->

    super options, data

    @progressBar = new kd.ProgressBarView { initial : INITIAL_PROGRESS_VALUE }


  updateProgress: (percentage, label) ->

    percentage = Math.max percentage, INITIAL_PROGRESS_VALUE
    @progressBar.updateBar percentage, '%', label


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
