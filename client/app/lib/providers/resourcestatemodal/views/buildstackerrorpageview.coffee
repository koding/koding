kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackErrorPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.BuildStack

    @errorContent = new kd.CustomHTMLView
      cssClass : 'error-content'

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>  BACK TO CREDENTIALS'
      click    : @lazyBound 'emit', 'CredentialsRequested'

    @buildButton = new kd.ButtonView
      title    : 'Try Building Again'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'RebuildRequested'


  setError: (err) ->

    @errorContent.updatePartial """
      You got an error:
      <p>#{err}</p>
    """


  pistachio: ->

    """
      <div class="error-page build-stack-error-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <h2>Oh no! Your stack build failed</h2>
          <p>There was an error while building your stack. Please go back<br />
          and try building it again, or get in contact with us</p>
          {{> @errorContent}}
        </section>
        <footer>
          {{> @backLink}}
          {{> @buildButton}}
        </footer>
      </div>
    """