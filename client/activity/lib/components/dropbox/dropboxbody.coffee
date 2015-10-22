kd           = require 'kd'
React        = require 'kd-react'
classnames   = require 'classnames'
ActivityFlux = require 'activity/flux'

module.exports = class DropboxBody extends React.Component

  @defaultProps =
    className : ''
    type      : 'dropdown'


  getContentElement: -> React.findDOMNode @refs.content


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


  renderSubtitle: ->

    { subtitle } = @props
    return  unless subtitle

    <span className="Dropbox-subtitle">{ subtitle }</span>


  renderHeader: ->

    { title } = @props
    return unless title

    <div className='Dropbox-header'>
      { title }
      { @renderSubtitle() }
    </div>


  render: ->

    containerClassName = @getContainerClassName()
    contentClassName   = @getContentClassName()
    <div className={containerClassName} ref='dropbox'>
      { @renderHeader() }
      <div className={contentClassName} ref='content'>
        <div className='Dropbox-content'>
          { @props.children }
        </div>
      </div>
    </div>

