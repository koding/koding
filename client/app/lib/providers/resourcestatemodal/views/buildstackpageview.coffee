kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'
IDETailerPane = require 'ide/workspace/panes/idetailerpane'
BuildStackLogsPane = require './buildstacklogspane'
helpers = require '../helpers'
constants = require '../constants'

module.exports = class BuildStackPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @wizardPane = new WizardProgressPane
      currentStep : WizardSteps.BuildStack

    @progressBar = new kd.ProgressBarView
      initial : constants.INITIAL_PROGRESS_VALUE
    @statusText  = new kd.CustomHTMLView { cssClass : 'status-text' }

    @logsContainer = new kd.CustomHTMLView { cssClass : 'logs-pane' }
    @render()


  render: ->

    file = @getData()
    { tailOffset } = @getOptions()

    @logsContainer.destroySubViews()
    @buildLogs = null

    isDummyFile = file.path.indexOf('localfile:/') is 0

    if isDummyFile
      @logsContainer.addSubView @buildLogs = new BuildStackLogsPane {
        delegate                 : this
      }, file
    else
      @logsContainer.addSubView new IDETailerPane {
        file
        tailOffset
        delegate : this
      }


  updateProgress: (percentage, message) ->

    percentage = Math.max percentage ? 0, constants.INITIAL_PROGRESS_VALUE
    @progressBar.updateBar percentage

    message = helpers.formatProgressStatus message
    @statusText.updatePartial message

    @buildLogs.appendLogMessage message


  pistachio: ->

    { stackName } = @getOptions()

    """
      <div class="build-stack-flow build-stack-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @wizardPane}}
        <section class="main">
          <h2><span>#{stackName}</span> is being built</h2>
          <p>Your flawless dev environment will be ready soon</p>
          {{> @progressBar}}
          {{> @statusText}}
          {{> @logsContainer}}
        </section>
        <footer>
        </footer>
      </div>
    """
