kd          = require 'kd'
React       = require 'kd-react'

module.exports = class WelcomeStepsMiniView extends React.Component

  renderBullets: ->

    <ul className='bullets'>
      {
        @props.steps.map (step, i) ->
          step = step.toJS()
          <li key={ step.order } className={ if step.starred then 'starred' else ''}>
            <cite className=''>{ i + 1 }</cite>
            <a href={ step.path } dangerouslySetInnerHTML={ { __html : step.miniTitle or step.title } } />
          </li>
      }
    </ul>


  toggleDropdown: ->

    { dropdown } = @refs

    unless dropdown.classList.contains 'in'
    then @openDropdown()
    else @closeDropdown()


  openDropdown: ->

    { kdParent } = @props
    { dropdown } = @refs

    dropdown.classList.add 'in'
    dropdown.classList.remove 'out'

    kd.singletons.windowController.addLayer kdParent
    kdParent.once 'ReceivedClickElsewhere', => @closeDropdown yes


  closeDropdown: (elseWhere = no)->

    { dropdown } = @refs
    { kdParent } = @props

    dropdown.classList.remove 'in'
    dropdown.classList.add 'out'

    return  unless elseWhere

    kd.singletons.windowController.removeLayer kdParent
    kdParent.off 'ReceivedClickElsewhere'


  handleDetailsClick: ->

    kd.singletons.router.handleRoute '/Welcome'
    @closeDropdown()


  render : ->

    stepsUndone = 0
    @props.steps.map (step, i) -> stepsUndone++  unless step.get 'isDone'

    <div>
      <cite className='WelcomeSteps-miniview--count' onClick={ @bound 'toggleDropdown' }>{ stepsUndone }</cite>
      <section ref='dropdown' className='WelcomeSteps-miniview'>
        <h2>Become An Expert</h2>
        {@renderBullets()}
        <button className='GenericButton' onClick={ @bound 'handleDetailsClick' }>SEE DETAILS</button>
      </section>
    </div>
