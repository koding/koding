kd = require 'kd'
BaseErrorPageView = require './baseerrorpageview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.BuildStack

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>Back to Credentials'
      click    : @lazyBound 'emit', 'CredentialsRequested'

    @buildButton = new kd.ButtonView
      title    : 'Try Building Again'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'RebuildRequested'


  pistachio: ->

    '''
      <div class="error-page build-stack-error-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <h2>Oh no! Your stack build failed</h2>
          <p>There was an error while building your stack.<br />
          Please try building it again, or get in contact with us</p>
          {{> @errorContainer}}
        </section>
        <footer>
          {{> @backLink}}
          {{> @buildButton}}
        </footer>
      </div>
    '''
