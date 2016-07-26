kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'

module.exports = class StartMachineErrorPageView extends BaseErrorPageView

  constructor: (options = {}, data) ->

    super options, data

    @startButton = new kd.ButtonView
      title    : 'Try Again'
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
          <h2>Something Went Wrong</h2>
          <p>There was an error while turning your VM on. Please try again or<br />
          contact us if the error continues.</p>
          {{> @errorContainer}}
          {{> @startButton}}
        </section>
      </div>
    '''
