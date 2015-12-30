_                   = require 'lodash'
kd                  = require 'kd'
React               = require 'kd-react'
ReactDOM            = require 'react-dom'
shortenUrl          = require 'app/util/shortenUrl'
shortenText         = require 'app/util/shortenText'
Portal              = require('react-portal').default
ActivityFlux        = require 'activity/flux'
Link                = require 'app/components/common/link'
SocialShareLinkItem = require './socialsharelinkitem'

module.exports = class ActivitySharePopup extends React.Component

  @defaultProps=
    url      : ''
    onClose  : kd.noop
    isOpened : no
    gplus    : { enabled : yes }
    facebook : { enabled : yes }
    twitter  : { enabled : yes, text : '' }
    linkedin : { enabled : yes, title : 'Koding.com'}


  copyTheClipboard: ->

    shareUrlInput = ReactDOM.findDOMNode @refs.shareUrlInput
    return null  unless shareUrlInput
    event.clipboardData.setData('text/plain', shareUrlInput.value)
    kd.utils.stopDOMEvent event


  componentDidMount: ->

    @setCoordinates()

    document.addEventListener 'copy', @bound 'copyTheClipboard'


  componentWillUnmount: ->

    document.removeEventListener 'copy', @bound 'copyTheClipboard'


  setCoordinates: ->

    itemNode = ReactDOM.findDOMNode @props.socialShareLinkComponent
    popup    = ReactDOM.findDOMNode @refs.ActivitySharePopup

    if itemNode and popup
      { top, left, width } = itemNode.getBoundingClientRect()
      popup.style.top  = "#{top}px"
      popup.style.left = "#{left + width + 10}px"


  componentDidUpdate: ->

    @setCoordinates()

    shortenUrl @props.url, (shorten)=>
      shareUrlInput = ReactDOM.findDOMNode @refs.shareUrlInput
      return null  unless shareUrlInput
      shareUrlInput.value = shorten
      shareUrlInput.setSelectionRange(0, shareUrlInput.value.length)


  getTwitterShareText: ->

    { tags, title, body } = @props.message
    hashTags = ''

    if tags
      hashTags  = ("##{tag.slug}"  for tag in tags when tag?.slug)
      hashTags  = _.unique(hashTags).join " "
      hashTags += " "

    itemText  = shortenText title or body, maxLength: 100, minLength: 100
    shareText = "#{itemText} #{hashTags}- #{@props.url}"

    return shareText


  buildGPlusShareLink: ->

    if @props.gplus.enabled
      link = "https://plus.google.com/share?url=#{encodeURIComponent(@props.url)}"


  buildTwitterShareLink: ->

    if @props.twitter.enabled
      shareText = @getTwitterShareText() or @props.twitter.text
      link = """https://twitter.com/intent/tweet?
        text=#{encodeURIComponent shareText}&via=koding&source=koding"""


  buildFacebookShareLink: ->

    if @props.facebook.enabled
      link = "https://www.facebook.com/sharer/sharer.php?u=#{encodeURIComponent(@props.url)}"


  buildLinkedInShareLink: ->

    if @props.linkedin.enabled
      link = """http://www.linkedin.com/shareArticle?mini=true&url=
        #{encodeURIComponent(@props.url)}&
        title=#{encodeURIComponent(@props.linkedin.title)}&
        summary=#{encodeURIComponent(@props.url)}&
        source=#{location.origin}"""


  onClick: (url, provider)=>

    window.open(
      url,
      "#{provider}-share-dialog",
      "width=626,height=436,left=#{Math.floor (screen.width/2) - (500/2)},top=#{Math.floor (screen.height/2) - (350/2)}"
    )


  render: ->

    return null  unless @props.isOpened

    <Portal isOpened={@props.isOpened} closeOnOutsideClick={yes} onClose={@props.onClose}>
      <div ref='ActivitySharePopup' className='ActivitySharePopup'>
        <input ref='shareUrlInput' readOnly={yes} type='text' value={@props.url}/>
        <div>
          <SocialShareLinkItem onClick={@bound 'onClick'} href={@buildGPlusShareLink()} className='share-icon share-gplus' provider='gplus'/>
          <SocialShareLinkItem onClick={@bound 'onClick'} href={@buildLinkedInShareLink()} className='share-icon share-linkedin' provider='linkedin'/>
          <SocialShareLinkItem onClick={@bound 'onClick'} href={@buildFacebookShareLink()} className='share-icon share-facebook' provider='facebook'/>
          <SocialShareLinkItem onClick={@bound 'onClick'} href={@buildTwitterShareLink()} className='share-icon share-twitter' provider='twitter'/>
        </div>
      </div>
    </Portal>

