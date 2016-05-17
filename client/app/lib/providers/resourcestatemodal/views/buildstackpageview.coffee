kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @wizardPane = new WizardProgressPane
      currentStep : WizardSteps.BuildStack

    @progressBar = new kd.ProgressBarView { initial : 10 }
    @statusText  = new kd.CustomHTMLView { cssClass : 'status-text' }


  updatePercentage: (percentage) ->

    @progressBar.updateBar percentage


  setStatusText: (text) ->

    @statusText.updatePartial text


  pistachio: ->

    { stackName } = @getOptions()

    """
      <div class="build-stack-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @wizardPane}}
        <section class="main">
          <h2><span>#{stackName}</span> is being built</h2>
          <p>Your flawless dev environment will be ready soon</p>
          {{> @progressBar}}
          {{> @statusText}}
        </section>
        <footer>
        </footer>
      </div>
    """