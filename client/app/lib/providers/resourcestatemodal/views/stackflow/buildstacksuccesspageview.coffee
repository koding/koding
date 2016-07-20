kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackSuccessPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.BuildStack

    @logsButton = new kd.ButtonView
      title    : 'See the Logs'
      cssClass : 'GenericButton secondary'
      callback : @lazyBound 'emit', 'LogsRequested'

    @closeButton = new kd.ButtonView
      title    : 'Start Coding'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'


  pistachio: ->

    '''
      <div class="build-stack-flow build-stack-success-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <div class="background"></div>
          <h1>Success!</h1>
          <h2>Your stack has been built</h2>
          {{> @logsButton}}
        </section>
        <footer>
          {{> @closeButton}}
        </footer>
      </div>
    '''
