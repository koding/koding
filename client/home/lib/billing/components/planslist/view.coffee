kd = require 'kd'
React = require 'kd-react'
List = require 'app/components/list'

module.exports = class PlansList extends React.Component

  numberOfSections: -> 1

  numberOfRowsInSection: -> @props.plans.size

  renderSectionHeaderAtIndex: -> null

  renderRowAtIndex: (sectionIndex, rowIndex) -> <SinglePlan plan={@props.plans.get rowIndex} />

  renderEmptySectionAtIndex: -> <div>No plans found</div>

  render: ->
    <div>
      <List
        numberOfSections={@bound 'numberOfSections'}
        rowClassName='HomeTeamBillingPlansList-row'
        numberOfRowsInSection={@bound 'numberOfRowsInSection'}
        renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
        renderRowAtIndex={@bound 'renderRowAtIndex'}
        renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      />
      <ActionBar />
    </div>


ActionBar = ->
  <fieldset className="HomeAppView--ActionBar">
    <a className="HomeAppView--button custom-link-view primary fr" href="#" onClick={kd.noop}>
      <span className="title">VIEW MEMBERS</span>
    </a>
    <a className="HomeAppView--button custom-link-view fr" href="#" onClick={kd.noop}>
      <span className="title">PRICING DETAILS</span>
    </a>
  </fieldset>


SinglePlan = ({ plan }) ->
  <div className="HomeAppViewListItem #{plan.get 'name'}">
    <div className='HomeAppViewListItem-label'>
      {plan.get 'label'}
    </div>
    <div className='HomeAppViewListItem-description'>
      {plan.get 'description'}
    </div>
    <div className='HomeAppViewListItem-SecondaryContainer'>
      <span className="PlansList-price">${plan.get 'price'}</span>
    </div>
  </div>


