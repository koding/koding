kd = require 'kd'


module.exports = class StartMachineSuccessPageView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    @closeButton = new kd.ButtonView
      title    : 'Start Using My VM'
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
          <h2>Your VM has finished Booting</h2>
          <p>We have finished booting your VM. You can now use your VM</p>
          {{> @closeButton}}
        </section>
      </div>
    '''
