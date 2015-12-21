kd       = require 'kd'
React    = require 'kd-react'
ReactDOM = require 'react-dom'


module.exports = (props) ->

  return class DropboxContainer extends React.Component

    updatePosition: (inputDimensions) -> @refs.dropbox?.updatePosition inputDimensions


    render: ->

      { dropboxQuery, dropboxConfig, onItemSelected, onItemConfirmed, onClose } = props
      return null  unless dropboxConfig

      Component = dropboxConfig.get 'component'

      componentProps = {
        query           : dropboxQuery
        items           : props[dropboxConfig.getIn ['getters', 'items']]
        selectedIndex   : props[dropboxConfig.getIn ['getters', 'selectedIndex']]
        selectedItem    : props[dropboxConfig.getIn ['getters', 'selectedItem']]
        onItemSelected
        onItemConfirmed
        onClose
      }

      <Component ref='dropbox' {...componentProps} />

