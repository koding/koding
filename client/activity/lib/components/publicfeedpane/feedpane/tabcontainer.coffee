kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
Link         = require 'app/components/common/link'
classnames   = require 'classnames'
ResultState  = require 'activity/constants/resultStates'


module.exports = class FeedPaneTabContainer extends React.Component

  @propTypes =
    thread                  : React.PropTypes.instanceOf immutable.Map
    showPopularMessages     : React.PropTypes.func
    showMostRecentMessages  : React.PropTypes.func

  @defaultProps =
    thread                 : immutable.Map()
    showPopularMessages    : kd.noop
    showMostRecentMessages : kd.noop


  getMostRecentTabClassNames: -> classnames
    'FeedPane-tab' : yes
    'active'       : @props.thread.getIn(['flags', 'resultListState']) is ResultState.RECENT


  getMostLikedTabClassNames: -> classnames
    'FeedPane-tab' : yes
    'active'       : @props.thread.getIn(['flags', 'resultListState']) is ResultState.LIKED


  render: ->

    return null  unless @props.thread

    <div className = 'FeedPane-tabContainer'>
      <Link
        onClick   = { @props.showPopularMessages }
        className = { @getMostLikedTabClassNames() }>Most Liked</Link>
      <Link
        onClick   = { @props.showMostRecentMessages }
        className = { @getMostRecentTabClassNames() }>Most Recent</Link>
      <div>
        <input className = 'FeedPane-searchInput' placeholder='Search...'/>
        <i className = 'FeedPane-searchIcon'/>
      </div>
    </div>
