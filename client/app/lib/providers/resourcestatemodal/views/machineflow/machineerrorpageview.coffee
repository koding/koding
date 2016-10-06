kd = require 'kd'
BaseErrorPageView = require '../baseerrorpageview'

module.exports = class MachineErrorPageView extends BaseErrorPageView

  pistachio: ->

    '''
      <div class="stop-machine-flow error-page stop-machine-error-page">
        <section class="main">
          <div class="background"></div>
          <h2>Something went wrong</h2>
          <p>There was an error while processing your VM.</p>
          {{> @errorContainer}}
        </section>
      </div>
    '''
