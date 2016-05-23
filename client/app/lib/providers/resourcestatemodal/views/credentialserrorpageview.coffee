kd = require 'kd'
BaseErrorPageView = require './baseerrorpageview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class CredentialsErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.Credentials

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>Re-Enter Your Credentials'
      click    : @lazyBound 'emit', 'CredentialsRequested'


  pistachio: ->

    '''
      <div class="error-page credentials-error-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <div class="background"></div>
          <h2>Whoops, Those Credentials Didn't Work</h2>
          <p>The credentials you have provided didn't work. You can try again<br />or add new credentials</p>
          {{> @errorContainer}}
        </section>
        <footer>
          {{> @backLink}}
        </footer>
      </div>
    '''
