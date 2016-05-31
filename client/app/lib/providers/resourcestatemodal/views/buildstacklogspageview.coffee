kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackLogsPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.BuildStack

    @closeButton = new kd.ButtonView
      title    : 'Start Coding'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'


  pistachio: ->

    '''
      <div class="build-stack-flow build-stack-logs-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
        </section>
        <footer>
          {{> @closeButton}}
        </footer>
      </div>
    '''
