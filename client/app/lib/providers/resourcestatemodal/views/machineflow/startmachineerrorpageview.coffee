kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'

module.exports = class StartMachineErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @startButton = new kd.ButtonView
      title    : 'Try Booting Again'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'StartMachine'


  pistachio: ->

    '''
      <div class="start-machine-flow error-page start-machine-error-page">
        <header>
          <h1>Boot Virtual Machine</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2>Bummer:( It Didn't Work</h2>
          <p>There was an error while turning your VM on. Please go back and try to turn<br />
          it on again, or get in contact with us.</p>
          {{> @errorContainer}}
          {{> @startButton}}
        </section>
      </div>
    '''
