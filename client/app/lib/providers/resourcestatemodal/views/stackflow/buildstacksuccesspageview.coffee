kd = require 'kd'
JView = require 'app/jview'

module.exports = class BuildStackSuccessPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @logsButton = new kd.ButtonView
      title    : 'See the Logs'
      cssClass : 'GenericButton secondary'
      callback : @lazyBound 'emit', 'LogsRequested'

    @closeButton = new kd.ButtonView
      title    : 'Start Coding'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'


  pistachio: ->

    '''
      <div class="build-stack-success-page">
        <section class="main">
          <div class="background"></div>
          <h1>Success</h1>
          <h2>Your stack has been built</h2>
        </section>
        <footer>
          {{> @logsButton}}
          {{> @closeButton}}
        </footer>
      </div>
    '''
