kd        = require 'kd'
React     = require 'kd-react'
ReactDOM  = require 'react-dom'
immutable = require 'immutable'

module.exports = class DropboxContainer extends React.Component

  @propTypes =
    query           : React.PropTypes.string
    dropboxConfig   : React.PropTypes.instanceOf immutable.Map
    onItemSelected  : React.PropTypes.func
    onItemConfirmed : React.PropTypes.func
    onClose         : React.PropTypes.func


  @defaultProps =
    dropboxQuery    : ''
    dropboxConfig   : null
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  updatePosition: (inputDimensions) -> @refs.dropbox?.updatePosition inputDimensions


  render: ->

    { dropboxQuery, dropboxConfig, onItemSelected, onItemConfirmed, onClose } = @props
    return null  unless dropboxConfig

    Component = dropboxConfig.get 'component'

    componentProps = {
      query           : dropboxQuery
      onItemSelected
      onItemConfirmed
      onClose
    }

    getters = dropboxConfig.get('getters').toJS()
    for propName, getter of getters
      componentProps[propName] = @props[getter]

    <Component ref='dropbox' {...componentProps} />
