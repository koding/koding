kd = require 'kd'
React = require 'kd-react'
TimeAgo = require 'app/components/common/timeago'

module.exports = StackTemplateItem = ({ template }) ->

  <div className='HomeAppViewListItem StackTemplateItem'>
    <div
      className='HomeAppViewListItem-label'
      onClick={kd.noop}>
      {template.get 'title'}
    </div>
    <div className='HomeAppViewListItem-description'>
      Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
    </div>
    <div className='HomeAppViewListItem-SecondaryContainer'>
      <a href="#" className="HomeAppView--button" onClick={kd.noop}>RE-INITIALIZE</a>
      <a href="#" className="HomeAppView--button primary" onClick={kd.noop}>LAUNCH</a>
    </div>
  </div>
