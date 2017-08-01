kd = require 'kd'

helpers = require '../../helpers'
constants = require '../../constants'

module.exports = class StopMachineProgressPageView extends kd.View

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

    '''
      <div class="stop-machine-flow stop-machine-progress-page">
        <header>
          <h1>Turn Off VM</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2>{{#(label)}} is Being Turned Off</h2>
          <div class="progressbar-wrapper">
            {{> @progressBar}}
            {{> @statusText}}
          </div>
        </section>
      </div>
    '''
