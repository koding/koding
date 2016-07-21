kd = require 'kd'
JView = require 'app/jview'

module.exports = class StartMachineSuccessPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @closeButton = new kd.ButtonView
      title    : 'Start Coding'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'


  pistachio: ->

    '''
      <div class="start-machine-flow start-machine-success-page">
        <header>
          <h1>Boot Virtual Machine</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2>Your VM is Booted</h2>
          <p>We are building your VM. Once we are finished you can get to coding.</p>
          {{> @closeButton}}
        </section>
      </div>
    '''
