kd = require 'kd'


module.exports = class NoStackPageView extends kd.View

  pistachio: ->

    '''
      <div class="no-stack-page">
        <section class="main">
          <h2>Stacks not configured yet!</h2>
          <p>
            Your team currently is not providing any compute resources.
            Please contact with your team admins for more information.
          </p>
        </section>
      </div>
    '''
