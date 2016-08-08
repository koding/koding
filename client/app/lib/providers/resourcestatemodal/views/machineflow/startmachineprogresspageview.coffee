kd = require 'kd'
JView = require 'app/jview'
helpers = require '../../helpers'
constants = require '../../constants'

module.exports = class StartMachineProgressPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressBar = new kd.ProgressBarView
      initial    : constants.INITIAL_PROGRESS_VALUE
    @statusText  = new kd.CustomHTMLView
      cssClass   : 'status-text'


  updateProgress: (percentage, message) ->

    percentage = Math.max percentage ? 0, constants.INITIAL_PROGRESS_VALUE
    @progressBar.updateBar percentage

    message = helpers.formatProgressStatus message
    @statusText.updatePartial message  if message


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
          <h2>Spinning up #{title}</h2>
          <p>We're building your VM. Once is running you can get to coding.</p>
          <div class="progressbar-wrapper">
            {{> @progressBar}}
            {{> @statusText}}
          </div>
        </section>
      </div>
    """
