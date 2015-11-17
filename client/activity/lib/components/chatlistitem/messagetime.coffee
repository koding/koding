$              = require 'jquery'
kd             = require 'kd'
React          = require 'kd-react'
dateFormat     = require 'dateformat'
Tooltip        = require 'app/components/tooltip'
Portal         = require('react-portal').default

module.exports = class MessageTime extends React.Component

  @propTypes =
    date : React.PropTypes.string.isRequired

  @defaultProps =
    tooltipY: 0
    tooltipX: 0
    isTooltipOpen: no

  constructor: (props) ->

    super props

    @state =
      tooltipY      : @props.tooltipY
      tooltipX      : @props.tooltipX
      isTooltipOpen : @props.isTooltipOpen

    @tooltipShouldBeVisible = no

  timeFormat            = 'h:MM TT'
  timeWithSecondsFormat = 'h:MM:ss TT'


  getTime: (date) ->

    dateFormat date, timeFormat


  setTooltipPosition: ->

    MessageDateDOMNode = @refs.MessageDate
    offset = $(MessageDateDOMNode).offset()

    @setState
      tooltipY : offset.top
      tooltipX : offset.left + MessageDateDOMNode.offsetWidth / 2


  setTooltipOpenState: (delay) ->

    kd.utils.wait delay, =>
      @setTooltipPosition()
      @setState isTooltipOpen: @tooltipShouldBeVisible


  getItemProps: ->
    onMouseEnter: =>
      @tooltipShouldBeVisible = yes
      @setTooltipOpenState(300)
    onMouseLeave: =>
      @tooltipShouldBeVisible = no
      @setTooltipOpenState(100)


  getTooltipTitle: (data, timeFormat) ->

    relativeDates  = ["Today", "Yesterday"]
    today          = new Date
    givenDate      = new Date @props.date
    dateDifference = today.getDate() - givenDate.getDate()
    dateString     = relativeDates[dateDifference] or dateFormat givenDate, "dddd, mmmm d"
    dateString     = "#{dateString} at #{dateFormat givenDate, timeFormat}"


  render: ->

    <time className='ChatItem-messageDate' {...@getItemProps()} ref='MessageDate'>
      { @getTime @props.date }
      <Portal isOpened={ @state.isTooltipOpen }>
        <Tooltip text={ @getTooltipTitle @props.date, timeWithSecondsFormat } tooltipX={@state.tooltipX} tooltipY={@state.tooltipY}/>
      </Portal>
    </time>
