React = require 'app/react'
PlanDeactivation = require '../../plandeactivation'

class BusinessAddOnDeactivation extends React.Component

  deactivateBusinessAddOn: ->

    @props.onDeactivateBusinessAddOn()


  render: ->

    <section className='HomeAppView--section business-add-on-deactivation'>
      <PlanDeactivation.Container
        target='BUSINESS ADD-ON'
        onDeactivation={@bound 'deactivateBusinessAddOn'} />
    </section>


  module.exports = BusinessAddOnDeactivation
