kd             = require 'kd'
React          = require 'kd-react'
dateFormat     = require 'dateformat'
Tooltip        = require 'app/components/tooltip'

module.exports = class MessageTime extends React.Component

  @propTypes =
    date : React.PropTypes.string.isRequired


  timeFormat            = 'h:MM TT'
  timeWithSecondsFormat = 'h:MM:ss TT'

  getTime: (date) ->

    dateFormat date, timeFormat


  getTooltipTitle: (data, timeFormat) ->

    relativeDates  = ["Today", "Yesterday"]
    today          = new Date
    givenDate      = new Date @props.date
    dateDifference = today.getDate() - givenDate.getDate()
    dateString     = relativeDates[dateDifference] or dateFormat givenDate, "dddd, mmmm d"
    dateString     = "#{dateString} at #{dateFormat givenDate, timeFormat}"


  render: ->

    <div className="ChatItem-messageDate">
      <time>{ @getTime @props.date }</time>
      <Tooltip text={ @getTooltipTitle @props.date, timeWithSecondsFormat }/>
    </div>

