kd       = require 'kd'
React    = require 'kd-react'
ReactDOM = require 'react-dom'


module.exports = class DropboxContainer extends React.Component

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

