kd = require 'kd'
_ = require 'lodash'
React = require 'kd-react'
TimeAgo = require 'app/components/common/timeago'

module.exports = class StackTemplateItem extends React.Component

  renderButton: ->

    { template, onAddToSidebar, onRemoveFromSidebar, isVisibleOnSidebar } = @props

    if isVisibleOnSidebar
      <a href="#" className="HomeAppView--button primary" onClick={onRemoveFromSidebar}>REMOVE FROM SIDEBAR</a>
    else
      <a href="#" className="HomeAppView--button primary" onClick={onAddToSidebar}>ADD TO SIDEBAR</a>


  render: ->

    { template, stack, onOpen } = @props

    return null  unless template

    editorUrl = "/Stack-Editor/#{template.get '_id'}"

    <div className='HomeAppViewListItem StackTemplateItem'>
      <a
        href={editorUrl}
        className='HomeAppViewListItem-label'
        onClick={onOpen}>
        { makeTitle { template, stack } }
      </a>
      <div className='HomeAppViewListItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className='HomeAppViewListItem-SecondaryContainer'>
        {@renderButton()}
      </div>
    </div>

makeTitle = ({ template, stack }) ->

  title = _.unescape template.get 'title'

  return title  unless stack
  return title  unless oldOwner = stack.getIn(['config', 'oldOwner'])

  return "#{title} (@#{oldOwner})"

