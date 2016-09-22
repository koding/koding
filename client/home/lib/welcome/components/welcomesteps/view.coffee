kd          = require 'kd'
React       = require 'app/react'
htmlencode = require 'htmlencode'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'


module.exports = class WelcomeStepsView extends React.Component

  renderVideoLink: (link) ->

    return null  unless link

    <a className='WelcomeStepVideoIcon' href={link} target='_blank'> </a>

  renderSkipLink: (key, step) ->

    return null  if not step.skippable or step.isDone

    <strong className='WelcomeStepLinkSkip' onClick={@props.onSkipClick.bind this, key}>skip this</strong>


  renderBullets: ->

    children = @props.steps.map (step, key) =>
      step = step.toJS()
      itemClass = ''
      itemClass = kd.utils.curry 'starred', itemClass  if step.starred
      itemClass = kd.utils.curry 'done', itemClass  if step.isDone
      itemClass = kd.utils.curry 'pending', itemClass  if step.isPending
      itemClass = kd.utils.curry step.cssClass, itemClass  if step.cssClass

      <li key={ step.order } className={ itemClass }>
        <a className='WelcomeStepLink' href={ step.path }>
          <h3>{ step.title }</h3>
          <p dangerouslySetInnerHTML={ { __html : step.description } } />
          <cite>{ step.actionTitle }</cite>
        </a>
        { @renderSkipLink key, step }
        { @renderVideoLink step.videoLink }
      </li>

    <ul className='bullets clearfix'>{ children.toList() }</ul>


  render : ->

    name = htmlencode.htmlDecode getFullnameFromAccount null, yes

    <section>
      <h2>You are almost there, {name}!</h2>
      <p>Complete these easy steps to be an expert on Koding.</p>
      {@renderBullets()}
      <footer>Still don’t know how to start? <a href='//www.koding.com/docs' target='_blank'>Check the FAQs</a></footer>
    </section>
