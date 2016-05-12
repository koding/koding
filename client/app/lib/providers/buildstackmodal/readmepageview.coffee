kd = require 'kd'
JView = require 'app/jview'
applyMarkdown = require 'app/util/applyMarkdown'

module.exports = class ReadmePageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    { description } = @getData()
    descriptionView = new kd.CustomHTMLView
      cssClass : 'description has-markdown'
      partial  : applyMarkdown description
    descriptionView.getDomElement().find('a').attr('target', '_blank')
    @descriptionContainer = new kd.CustomScrollView()
    @descriptionContainer.wrapper.addSubView descriptionView

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
        <section class="main">
          <h2>Read Me First</h2>
          <p>Your admin created the following instructions to get you started</p>
          {{> @descriptionContainer}}
        </section>
        <footer>
          {{> @nextButton}}
        </footer>
      </div>
    """