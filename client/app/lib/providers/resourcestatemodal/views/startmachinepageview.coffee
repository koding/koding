kd = require 'kd'
JView = require 'app/jview'

module.exports = class StartMachinePageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @startButton = new kd.ButtonView
      title    : 'Turn VM On'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'StartMachine'


  pistachio: ->

    '''
      <div class="start-machine-flow start-machine-page">
        <header>
          <h1>Boot Virtual Machine</h1>
        </header>
        <section class="main">
          <div class="background"></div>
          <h2>Let's Boot up your VM</h2>
          <p>One click and your flawless dev environment<br />will be ready to use</p>
          {{> @startButton}}
        </section>
      </div>
    '''
