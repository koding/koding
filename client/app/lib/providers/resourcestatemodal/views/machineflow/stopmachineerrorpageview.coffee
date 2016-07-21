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
          <p>Make sure all of your work has been saved before you turn off the VM.</p>
          {{> @errorContainer}}
          {{> @tryAgainButton}}
        </section>
      </div>
    '''
