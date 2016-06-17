kd          = require 'kd'
React       = require 'kd-react'

module.exports = class WelcomeStepsMiniView extends React.Component

  renderBullets: ->

    <ul className='bullets'>
      {
        @props.steps.map (step) ->
          step = step.toJS()
          <li key={ step.order } className={ if step.starred then 'starred' else ''}>
            <a href={ step.path }>
              <h3 dangerouslySetInnerHTML={ { __html : step.miniTitle or step.title } } />
            </a>
          </li>
      }
    </ul>


  render : ->

    <section className='WelcomeSteps-miniview'>
      <h2>Become An Expert</h2>
      {@renderBullets()}
      <button>SEE DETAILS</button>
    </section>
