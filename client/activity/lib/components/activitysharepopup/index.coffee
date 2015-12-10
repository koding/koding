kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
Link                 = require 'app/components/common/link'
shortenUrl           = require 'app/util/shortenUrl'
groupifyLink         = require 'app/util/groupifyLink'

module.exports = class ActivitySharePopup extends React.Component

  defaultProps=
    url      : ''
    onClose  : kd.noop
    isOpened : no

  onClose: -> @props.onClose()


  copyTheClipboard: ->

    shareUrlInput = ReactDOM.findDOMNode @refs.shareUrlInput
    return null  unless shareUrlInput
    event.clipboardData.setData('text/plain', shareUrlInput.value)
    kd.utils.stopDOMEvent event


  componentDidMount: ->

    document.addEventListener 'copy', @bound 'copyTheClipboard'


  componentWillUnmount: ->

    document.removeEventListener 'copy', @bound 'copyTheClipboard'


  componentDidUpdate: ->

    shortenUrl @props.url, (shorten)=>
      shareUrlInput = ReactDOM.findDOMNode @refs.shareUrlInput
      return null  unless shareUrlInput
      shareUrlInput.value = shorten
      shareUrlInput.setSelectionRange(0, shareUrlInput.value.length)


  render: ->

    return null  unless @props.isOpened

    <div className='ActivitySharePopup'>
      <input ref='shareUrlInput' readOnly={yes} type='text' value={@props.url}/>
      <div>
        <Link className='share-icon share-gplus'/>
        <Link className='share-icon share-linkedin'/>
        <Link className='share-icon share-facebook'/>
        <Link className='share-icon share-twitter'/>
      </div>
    </div>

