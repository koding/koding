kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'

module.exports = class CredentialsErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>Re-Enter Your Credentials'
      click    : @lazyBound 'emit', 'CredentialsRequested'


  pistachio: ->

    '''
      <div class="error-page credentials-error-page">
        <section class="main">
          <h2>Whoops, Those Credentials Didn't Work</h2>
          <p>The credentials you have provided didn't work. You can try again<br />or add new credentials</p>
          {{> @errorContainer}}
        </section>
        <footer>
          {{> @backLink}}
        </footer>
      </div>
    '''
