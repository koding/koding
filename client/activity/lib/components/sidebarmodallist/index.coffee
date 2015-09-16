kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
Scroller       = require 'app/components/scroller'
ScrollerMixin  = require 'app/components/scroller/scrollermixin'
classnames     = require 'classnames'

module.exports = class SidebarModalList extends React.Component

  @include [ScrollerMixin]

  isSearching = no

  @defaultProps =
    title             : ''
    threads           : immutable.List()
    className         : ''
    searchProp        : 'name'
    onThresholdAction : ''

  constructor: (props) ->

    super

    @state =
      value: ''
      noResultText: no
      threads: @props.sidebarModalChannels.followed


  onThresholdReached: ->

    return  if isSearching

    { channel } = ActivityFlux.actions

    channel[@props.onThresholdAction] skip: @props.threads.size

    @setThreads()


  setThreads: kd.utils.debounce 1000, ->

    @setState threads: @props.sidebarModalChannels.followed


  resetSearch: ->

    threads = @props.sidebarModalChannels.followed
    @setState threads: threads
    @setState noResultText: no  if threads.size


  filter: kd.utils.debounce 800, ->

    { sidebarModalChannels } = @props
    { value } = @state

    threads = sidebarModalChannels.followed.filter (thread) =>
      typeConstant = thread.getIn ['channel', 'typeConstant']
      if @props.searchProp is 'purpose' and typeConstant is 'bot'
        thread = thread.setIn ['channel', 'purpose'], 'Bot Koding'
      searchProp = thread.getIn(['channel', @props.searchProp]).toLowerCase()
      return yes  if searchProp.indexOf(value) > -1

    @setState { threads : threads, noResultText : threads.size is 0}

    kd.utils.wait 1000, ->
      isSearching = no


  search: (event) ->

    { value }   = event.target
    { channel } = ActivityFlux.actions

    @setState { value }

    return @resetSearch()  if value is ''

    isSearching = yes

    value = value.slice(1)  if value[0] is '#'

    channel.loadChannelsByQuery value
    channel[@props.onThresholdAction] skip: @props.threads.size

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
    'hidden' : not @state.noResultText


  renderChildren: ->

    { itemComponent: Component, threads } = @props

    @state.threads.toList().map (thread, i) ->
      itemProps =
        key     : thread.get 'channelId'
        channel : thread.get 'channel'
      <Component {...itemProps} />


  renderNoResultText: ->

    <div className={@getNoResultClassNames()}>Sorry, your search did not have any results</div>


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

