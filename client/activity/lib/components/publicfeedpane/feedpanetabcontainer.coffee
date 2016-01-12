kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
immutable    = require 'immutable'
Link         = require 'app/components/common/link'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
ResultState  = require 'activity/constants/resultStates'

module.exports = class FeedPaneTabContainer extends React.Component

  @defaultProps =
    thread : immutable.Map()


  constructor: (props) ->

    super

    @state = { query: '' }


  showPopularMessages: (event) ->

    kd.utils.stopDOMEvent event

    @handleRoute 'Liked'


  showMostRecentMessages: (event) ->

    kd.utils.stopDOMEvent event

    @handleRoute '/Recent'


  handleRoute: (route) ->

    channelName = @props.thread.getIn ['channel', 'name']
    route       = "/Channels/#{channelName}/#{route}"

    kd.singletons.router.handleRoute route


  getMostRecentTabClassNames: -> classnames
    'FeedPane-tab' : yes
    'active'       : @props.thread.getIn(['flags', 'resultListState']) is ResultState.RECENT


  getMostLikedTabClassNames: -> classnames
    'FeedPane-tab' : yes
    'active'       : @props.thread.getIn(['flags', 'resultListState']) is ResultState.LIKED


  onEsc: (event) -> @redirectToChannel()


  redirectToChannel: ->

    @setState query: ''

    channelName = @props.thread.getIn ['channel', 'name']

    ActivityFlux.actions.message.setChannelMessagesSearchQuery ''

    return kd.singletons.router.handleRoute "/Channels/#{channelName}"


  render: ->

    return null  unless @props.thread

    <div className='FeedPane-tabContainer'>
      <Link
        onClick={@bound 'showPopularMessages'}
        className={@getMostLikedTabClassNames()}>Most Liked</Link>
      <Link
        onClick={@bound 'showMostRecentMessages'}
        className={@getMostRecentTabClassNames()}>Most Recent</Link>
      <div>
        <input
          value={ @state.query }
          onChange={ @bound 'onChange' }
          onKeyDown={ @bound 'onKeyDown' }
          className='FeedPane-searchInput'
          placeholder='Search...'/>
        <i className='FeedPane-searchIcon'/>
      </div>
    </div>
