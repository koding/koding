$            = require 'jquery'
kd           = require 'kd'
React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'

module.exports = class Dropup extends React.Component

  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'


  componentDidUpdate: ->

    return  unless @props.visible

    element = $ @getMainElement()
    element.css top : -element.outerHeight()


  getMainElement: -> React.findDOMNode @refs.dropup


  handleMouseClick: (event) ->

    return  unless @props.visible

    { target } = event
    element    = React.findDOMNode this
    innerClick = $.contains element, target

    @props.onOuterClick?()  unless innerClick


  render: ->

    { className, visible } = @props
    classes =
      'Dropup-container' : yes
      'hidden'           : not visible
    classes[className]   = yes  if className

    <div className={classnames classes}>
      <div className="Dropup" ref="dropup">
        {this.props.children}
      </div>
    </div>