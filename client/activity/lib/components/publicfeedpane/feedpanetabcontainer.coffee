kd        = require 'kd'
React     = require 'kd-react'
ReactDOM  = require 'react-dom'
immutable = require 'immutable'
Link      = require 'app/components/common/link'


module.exports = class FeedPaneTabContainer extends React.Component

  @defaultProps=
    thread = immutable.Map()


  render: ->

    return null  unless @props.thread

    <div className='FeedPane-tabContainer'>
      <Link className='FeedPane-tab'>Most Liked</Link>
      <Link className='FeedPane-tab active'>Most Recent</Link>
      <div>
        <input className='FeedPane-searchInput' placeholder='Search...'/>
        <i className='FeedPane-searchIcon'/>
      </div>
    </div>

