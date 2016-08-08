kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'

module.exports = class StopMachineErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @tryAgainButton = new kd.ButtonView
      title    : 'Try Again'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'StopMachine'


  pistachio: ->

    '''
      <div class="stop-machine-flow error-page stop-machine-error-page">
        <header>
          <h1>Turn Off VM</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2>Something went wrong</h2>
          <p>There was an error while turning your VM off. Please try again or<br />
          contact us if the error continues.</p>
          {{> @errorContainer}}
          {{> @tryAgainButton}}
        </section>
      </div>
    '''
