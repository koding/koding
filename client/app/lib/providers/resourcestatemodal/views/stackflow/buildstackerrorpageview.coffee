kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'
BuildStackHeaderView = require './buildstackheaderview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    { stack } = @getData()
    @header   = new BuildStackHeaderView {}, stack

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
      <div class="build-stack-flow error-page build-stack-error-page">
        {{> @header}}
        {{> @progressPane}}
        <section class="main">
          <h2>Oh no! Your stack build failed</h2>
          <p>There was an error while building your stack. Please try building it again,<br />
          or get in contact with us</p>
          {{> @errorContainer}}
        </section>
        <footer>
          {{> @backLink}}
          {{> @buildButton}}
        </footer>
      </div>
    '''
