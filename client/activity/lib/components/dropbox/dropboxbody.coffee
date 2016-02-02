kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'
Header       = require './dropboxheader'

module.exports = class DropboxBody extends React.Component

  @propTypes =
    className        : React.PropTypes.string
    contentClassName : React.PropTypes.string
    type             : React.PropTypes.string

  @defaultProps =
    className        : ''
    contentClassName : ''
    type             : 'dropdown'


  getContentElement: -> ReactDOM.findDOMNode @refs.content


  getContainerClassName: ->

    { className, type } = @props

    classes =
      'Reactivity' : yes
      'Dropbox'    : yes
      'Dropup'     : type is 'dropup'
      'Dropdown'   : type is 'dropdown'
    classes[className] = yes  if className

    return classnames classes


  getContentClassName: ->

    { contentClassName } = @props

    classes =
      'Dropbox-scrollable' : yes
    classes[contentClassName] = yes  if contentClassName

    return classnames classes


  render: ->

    { title, subtitle } = @props
    containerClassName  = @getContainerClassName()
    contentClassName    = @getContentClassName()

    <div className={containerClassName} ref='dropbox'>
      <Header title={title} subtitle={subtitle} />
      <div className={contentClassName} ref='content'>
        <div className='Dropbox-content'>
          { @props.children }
        </div>
      </div>
    </div>
