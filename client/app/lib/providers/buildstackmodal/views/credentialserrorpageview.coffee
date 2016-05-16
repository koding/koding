kd = require 'kd'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'

module.exports = class CredentialsErrorPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.Credentials

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>  RE-ENTER YOUR CREDENTIALS'
      click    : @lazyBound 'emit', 'CredentialsRequested'

    @errorContent = new kd.CustomHTMLView
      cssClass : 'error-content'


  setErrors: (errs) ->

    isSingleError = errs.length is 1

    title = if isSingleError
    then "You got an error:"
    else "You got some errors:"

    content = if isSingleError
    then "<p>#{errs.first}</p>"
    else "<ul>#{(errs.map (err) -> "<li>#{err}</li>").join ''}</ul>"

    @errorContent.updatePartial title + content


  pistachio: ->

    """
      <div class="error-page credentials-error-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <h2>Whoops, Those Credentials Didn't Work</h2>
          <p>The credentials you have provided didn't work. You can try again<br />or add new credentials</p>
          {{> @errorContent}}
        </section>
        <footer>
          {{> @backLink}}
        </footer>
      </div>
    """