kd = require 'kd'

applyMarkdown = require 'app/util/applyMarkdown'

module.exports = class ReadmePageView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { stack, stackTemplate } = @getData()

    descriptionView = new kd.CustomHTMLView
      cssClass : 'description has-markdown'
      partial  : applyMarkdown stackTemplate.description
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
      <div class="readme-page">
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
