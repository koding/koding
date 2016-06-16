kd          = require 'kd'
React       = require 'kd-react'

module.exports = class WelcomeStepsView extends React.Component

  renderBullets: ->
    <ul className='bullets clearfix'>
      {
        @props.steps.map (step) ->
          step = step.toJS()
          <li key={ step.order } className={ if step.starred then 'starred' else ''}>
            <a href={ step.path }>
              <h3 dangerouslySetInnerHTML={ { __html : step.title } } />
              <p dangerouslySetInnerHTML={ { __html : step.description } } />
            </a>
          </li>
      }
    </ul>


  render : ->
    <section>
      <h2>Welcome to Koding For Teams!</h2>
      <p>Your new dev environment in the cloud.</p>
      {@renderBullets()}
    </section>
