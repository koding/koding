kd          = require 'kd'
React       = require 'kd-react'
immutable   = require 'immutable'
classnames  = require 'classnames'
DropboxItem = require 'activity/components/dropboxitem'

module.exports = class MentionDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  renderNames: ->

    { item } = @props
    names    = item.get 'names'

    names.map (name, index) ->
      <span>{ "@#{name}#{ if index is names.size - 1 then '' else ', ' }" }</span>


  renderDescription: ->

    { item }    = @props
    description = item.get 'description'

    return  unless description

    <span className='UserDropboxItem-fullName'> ({description})</span>    


  render: ->

    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated UserDropboxItem">
      <div className='UserDropboxItem-names'>
        { @renderNames() }
        { @renderDescription() }
      </div>
    </DropboxItem>

