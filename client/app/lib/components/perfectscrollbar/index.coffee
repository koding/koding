_ = require 'lodash'
React = require 'kd-react'
ReactDOM = require 'react-dom'
Ps = require 'perfect-scrollbar'

{ PropTypes, Component } = React

perfectProps = [
  'wheelSpeed', 'wheelPropagation', 'swipePropagation',
  'minScrollbarLength', 'maxScrollbarLength', 'useBothWheelAxes',
  'useKeyboard', 'suppressScrollX', 'suppressScrollY',
  'scrollXMarginOffset', 'scrollYMarginOffset', 'stopPropagationOnClick',
  'useSelectionScroll'
]

mapPerfectPropsWith = (values) ->
  perfectProps.reduce (result, prop, index) ->
    result[prop] = values[index]
    return result
  , {}


module.exports = class PerfectScrollbar extends Component

  @propTypes = mapPerfectPropsWith [
    PropTypes.number,
    PropTypes.bool,
    PropTypes.bool,
    PropTypes.number,
    PropTypes.number,
    PropTypes.bool,
    PropTypes.bool,
    PropTypes.bool,
    PropTypes.bool,
    PropTypes.number,
    PropTypes.number,
    PropTypes.bool,
    PropTypes.bool
  ]

  @defaultProps = mapPerfectPropsWith [
    1,
    false,
    true,
    null,
    null,
    false,
    true,
    false,
    false,
    0,
    0,
    true,
    false
  ]

  constructor: (props) ->

    super props
    @_listeners = {}


  addListener: (name, listener) ->

    global.addEventListener name, listener
    @_listeners[name] = listener


  componentDidMount: ->

    container = ReactDOM.findDOMNode @refs.container
    props = _.pick @props, perfectProps

    Ps.initialize container, props

    @addListener 'resize', @bound 'onResize'

    if _.isFunction @props.onScrollY
      @addListener 'ps-scroll-y', @props.onScrollY

    if _.isFunction @props.onScrollX
      @addListener 'ps-scroll-x', @props.onScrollY

    if _.isFunction @props.onScrollUp
      @addListener 'ps-scroll-up', @props.onScrollUp

    if _.isFunction @props.onScrollDown
      @addListener 'ps-scroll-up', @props.onScrollDown

    if _.isFunction @props.onScrollLeft
      @addListener 'ps-scroll-down', @props.onScrollLeft

    if _.isFunction @props.onScrollRight
      @addListener 'ps-scroll-right', @props.onScrollRight

    if _.isFunction @props.onUpLimitReached
      @addListener 'ps-y-reach-start', @props.onUpLimitReached

    if _.isFunction @props.onDownLimitReached
      @addListener 'ps-y-reach-end', @props.onDownLimitReached

    if _.isFunction @props.onLeftLimitReached
      @addListener 'ps-x-reach-start', @props.onLeftLimitReached

    if _.isFunction @props.onRightLimitReached
      @addListener 'ps-x-reach-end', @props.onRightLimitReached


  componentWillUnmount: ->

    for own name, listener of @_listeners
      global.removeEventListener name, listener

    @_listeners = {}


  onResize: ->

    Ps.update ReactDOM.findDOMNode @refs.container


  render: ->

    props = _.assign {}, @props,
      style: _.assign {position: 'relative', height: '100%'}, @props.style

    <div ref='container' {...props}>
      {@props.children}
    </div>


