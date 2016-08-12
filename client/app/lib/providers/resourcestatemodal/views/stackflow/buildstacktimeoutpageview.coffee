kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'

module.exports = class BuildStackTimeoutPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @startButton = new kd.ButtonView
      title    : 'Start using My VM'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'

    @setErrors [
      '''
      Software installation is taking longer than expected. However, your machine is now ready to use.
      Start using it and check the logs to look into the installation state.
      '''
    ]


  pistachio: ->

    '''
      <div class="error-page build-stack-timeout-page">
        <section class="main">
          <h2>It timed out</h2>
          <p>There was a timeout while installing your software.</p>
          {{> @errorContainer}}
        </section>
        <footer>
          {{> @startButton}}
        </footer>
      </div>
    '''
