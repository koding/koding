kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'
applyMarkdown = require 'app/util/applyMarkdown'

module.exports = class ReadmePageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.Instructions

    { description } = @getData()
    descriptionView = new kd.CustomHTMLView
      cssClass : 'description has-markdown'
      partial  : applyMarkdown description
    descriptionView.getDomElement().find('a').attr('target', '_blank')
    @descriptionContainer = new kd.CustomScrollView()
    @descriptionContainer.wrapper.addSubView descriptionView

    @stackTemplateButton = new kd.ButtonView
      title    : 'View Stack Template'
      cssClass : 'GenericButton secondary'
      callback : @lazyBound 'emit', 'StackTemplatePageRequested'

    @nextButton = new kd.ButtonView
      title    : 'Next'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'CredentialsPageRequested'


  pistachio: ->

    """
      <div class="readme-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <h2>Read Me First</h2>
          <p>Your admin created the following instructions to get you started</p>
          {{> @descriptionContainer}}
          {{> @stackTemplateButton}}
        </section>
        <footer>
          {{> @nextButton}}
        </footer>
      </div>
    """