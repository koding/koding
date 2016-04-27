kd = require 'kd'
_ = require 'lodash'
React = require 'kd-react'
TimeAgo = require 'app/components/common/timeago'

module.exports = class StackTemplateItem extends React.Component

  renderButton: ->

    { template, onAddToSidebar, onRemoveFromSidebar } = @props

    unless template.get 'inUse'
      return <a href="#" className="HomeAppView--button primary" onClick={onAddToSidebar}>ADD TO SIDEBAR</a>

    unless template.get 'isDefault'
      return <a href="#" className="HomeAppView--button primary" onClick={onRemoveFromSidebar}>REMOVE FROM SIDEBAR</a>


  render: ->

    { template } = @props

    <div className='HomeAppViewListItem StackTemplateItem'>
      <div
        className='HomeAppViewListItem-label'
        onClick={kd.noop}>
        {_.unescape template.get 'title'}
      </div>
      <div className='HomeAppViewListItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>
