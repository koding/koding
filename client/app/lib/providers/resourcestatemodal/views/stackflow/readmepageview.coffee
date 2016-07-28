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
      callback : @lazyBound 'emit', 'StackTemplateRequested'

    @nextButton = new kd.ButtonView
      title    : 'Next'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'NextPageRequested'


  pistachio: ->

    '''
      <div class="build-stack-flow readme-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <h2>Read Me</h2>
          <p>Instructions on getting started</p>
          {{> @descriptionContainer}}
        </section>
        <footer>
          {{> @stackTemplateButton}}
          {{> @nextButton}}
        </footer>
      </div>
    '''
