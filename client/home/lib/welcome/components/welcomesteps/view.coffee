kd          = require 'kd'
React       = require 'kd-react'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'

module.exports = class WelcomeStepsView extends React.Component

  renderVideoLink: (link) ->

    return null  unless link

    <a className='WelcomeStepVideoIcon' href={link} target='_blank'> </a>


  renderBullets: ->
    <ul className='bullets clearfix'>
      {
        @props.steps.map (step) =>
          step = step.toJS()
          itemClass = ''
          itemClass = kd.utils.curry 'starred', itemClass  if step.starred
          itemClass = kd.utils.curry 'done', itemClass  if step.isDone
          itemClass = kd.utils.curry step.cssClass, itemClass  if step.cssClass

          <li key={ step.order } className={ itemClass }>
            <a className='WelcomeStepLink' href={ step.path }>
              <h3>{ step.title }</h3>
              <p dangerouslySetInnerHTML={ { __html : step.description } } />
              <cite>{ step.actionTitle }</cite>
            </a>
            { @renderVideoLink step.videoLink }
          </li>
      }
    </ul>


  render : ->

    name = getFullnameFromAccount null, yes

    <section>
      <h2>You are almost there, {name}!</h2>
      <p>Complete these easy steps to be an expert on Koding.</p>
      {@renderBullets()}
      <footer>Still don’t know how to start? <a href='//www.koding.com/docs' target='_blank'>Check the FAQs</a></footer>
    </section>
