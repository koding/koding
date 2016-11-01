_ = require 'lodash'
kd = require 'kd'
React = require 'app/react'
ReactDOM = require 'react-dom'
Ps = require 'perfect-scrollbar'

{ PropTypes, Component } = React

require './styl/perfectscrollbar.styl'


module.exports = class PerfectScrollbar extends Component

  @propTypes =
    wheelSpeed             : PropTypes.number,
    wheelPropagation       : PropTypes.bool,
    swipePropagation       : PropTypes.bool,
    minScrollbarLength     : PropTypes.number,
    maxScrollbarLength     : PropTypes.number,
    useBothWheelAxes       : PropTypes.bool,
    useKeyboard            : PropTypes.bool,
    suppressScrollX        : PropTypes.bool,
    suppressScrollY        : PropTypes.bool,
    scrollXMarginOffset    : PropTypes.number,
    scrollYMarginOffset    : PropTypes.number,
    stopPropagationOnClick : PropTypes.bool,
    useSelectionScroll     : PropTypes.bool

  @defaultProps =
    wheelSpeed             : 1
    wheelPropagation       : off
    swipePropagation       : on
    minScrollbarLength     : null
    maxScrollbarLength     : null
    useBothWheelAxes       : off
    useKeyboard            : on
    suppressScrollX        : off
    suppressScrollY        : off
    scrollXMarginOffset    : 0
    scrollYMarginOffset    : 0
    stopPropagationOnClick : on
    useSelectionScroll     : off

  constructor: (props) ->

    super props
    @_listeners = {}


  addListener: (name, listener) ->

    global.addEventListener name, listener
    @_listeners[name] = listener


  componentDidMount: ->

    container = ReactDOM.findDOMNode @refs.container
    props     = _.pick @props, Object.keys PerfectScrollbar.defaultProps

    Ps.initialize container, props

    # update once it's rendered so that if the viewport is larger than
    # scrollable area, it will trigger an ps-y-reach-start. ~500 is approximate.
    # FIXME: remove `wait` from here and make sure it handles each case.
    kd.utils.wait 500, -> Ps.update container

    @addListener 'resize', @bound '_update'

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


  _update: ->

    Ps.update ReactDOM.findDOMNode @refs.container


  render: ->

    props = _.omit @props, [
      'hasMore'
      'threshold'
      'onThresholdReached'
      'onTopThresholdReached'
      'minScrollbarLength'
      'useSelectionScroll'
      'onUpLimitReached'
      'onDownLimitReached'
      'wheelSpeed'
      'wheelPropagation'
      'swipePropagation'
      'maxScrollbarLength'
      'useBothWheelAxes'
      'useKeyboard'
      'suppressScrollX'
      'suppressScrollY'
      'scrollXMarginOffset'
      'scrollYMarginOffset'
      'stopPropagationOnClick'
    ]

    props = _.assign {}, props,
      style: _.assign { position: 'relative', height: '100%' }, @props.style

    <div ref='container' {...props}>
      {@props.children}
    </div>
