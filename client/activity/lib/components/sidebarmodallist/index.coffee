kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
Scroller       = require 'app/components/scroller'
ScrollerMixin  = require 'app/components/scroller/scrollermixin'
classnames     = require 'classnames'

module.exports = class SidebarModalList extends React.Component

  @include [ScrollerMixin]

  @defaultProps =
    title             : ''
    threads           : immutable.List()
    className         : ''
    searchProp        : 'name'
    onThresholdAction : ''
    onItemClick       : kd.noop

  constructor: (props) ->

    super

    @state =
      value             : ''
      showNoResultText  : no
      isSearching       : no
      threads           : @props.threads


  componentWillReceiveProps: (nextProps) ->

    @setState threads: nextProps.threads


  onThresholdReached: ->

    return  if @state.isSearching

    { channel } = ActivityFlux.actions
    loadFollowedChannels = channel[@props.onThresholdAction]
    loadFollowedChannels skip: @props.threads.size


  resetSearch: ->

    threads = @props.threads
    @setState threads: threads
    @setState showNoResultText: no  if threads.size


  filter: kd.utils.debounce 800, ->

    { threads } = @props
    { value } = @state

    threads = threads.filter (thread) =>
      typeConstant = thread.getIn ['channel', 'typeConstant']
      if @props.searchProp is 'purpose' and typeConstant is 'bot'
        thread = thread.setIn ['channel', 'purpose'], 'Bot Koding'
      searchProp = thread.getIn(['channel', @props.searchProp]).toLowerCase()
      return yes  if searchProp.indexOf(value) > -1

    @setState
      threads : threads,
      showNoResultText : threads.size is 0

    kd.utils.wait 1000, =>
      @setState isSearching: no


  search: (event) ->

    { value }   = event.target
    { channel } = ActivityFlux.actions

    @setState { value }

    return @resetSearch()  if value is ''

    @setState isSearching: yes

    value = value.slice(1)  if value[0] is '#'
    loadFollowedChannels = channel[@props.onThresholdAction]

    channel.loadChannelsByQuery value
    loadFollowedChannels skip: @props.threads.size

    @filter()


  renderHeader: ->

    <div>
      <div className='ChannelList-title'>{@props.title}</div>
      <div>
        <input
          className   = 'ChannelList-searchInput'
          placeholder = 'Search'
          onChange    = { @bound 'search' }
          ref         = 'ChannelSearchInput'
          value       = { @state.value }
        />
      </div>
    </div>


  getNoResultClassNames: -> classnames
    'ChannelList-emptySearch': yes
    'hidden' : not @state.showNoResultText


  renderChildren: ->

    { itemComponent: Component, onItemClick } = @props

    @state.threads.toList().map (thread, i) ->
      itemProps =
        thread      : thread
        key         : thread.get 'channelId'
        onItemClick : onItemClick
      <Component {...itemProps} />


  renderNoResultText: ->

    <div className={@getNoResultClassNames()}>
      Sorry, your search did not have any results
    </div>


  renderChannelList: ->

    <div className='ChannelList'>
      <Scroller
        onThresholdReached={@bound 'onThresholdReached'}
        ref="scrollContainer">
        {@renderChildren()}
        {@renderNoResultText()}
      </Scroller>
    </div>


  render: ->

    <div className='ChannelListWrapper'>
      {@renderHeader()}
      {@renderChannelList()}
    </div>

