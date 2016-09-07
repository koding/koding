kd               = require 'kd'
React            = require 'kd-react'
classnames       = require 'classnames'
showNotification = require 'app/util/showNotification'

module.exports = class ChannelDropContainer extends React.Component

  constructor: (props) ->

    super props

    @state = { showDropArea: no }


  getClassNames: -> classnames
    'ChannelDropContainer': yes
    'hidden': not @state.showDropArea


  onDrop: (event) ->

    kd.utils.stopDOMEvent event
    @setState { showDropArea: no }
    showNotification 'Coming soon...', type: 'main'


  onDragEnter: (event) ->

    kd.utils.stopDOMEvent event
    @setState { showDropArea: yes }


  onDragOver: (event) -> kd.utils.stopDOMEvent event


  onDragLeave: (event) ->

    kd.utils.stopDOMEvent event
    @setState { showDropArea: no }


  renderDropArea: ->
    <div
      onDrop={@bound 'onDrop'}
      onDragOver={@bound 'onDragOver'}
      onDragLeave={@bound 'onDragLeave'}
      className={@getClassNames()}>
      <div className='ChannelDropContainer-content'>Drop VMs here<br/> to start collaborating</div>
    </div>


  render: ->

    <section onDragEnter={@bound 'onDragEnter'} className={@props.className}>
      {@renderDropArea()}
      {@props.children}
    </section>
