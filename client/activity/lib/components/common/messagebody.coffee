$             = require 'jquery'
React         = require 'kd-react'
emojify       = require 'emojify.js'
formatContent = require 'app/util/formatReactivityContent'
immutable     = require 'immutable'
urlGrabber    = require 'app/util/urlGrabber'
regexps       = require 'app/util/regexps'


module.exports = class MessageBody extends React.Component

  @defaultProps =
    message: immutable.Map()


  renderEmojis: ->

    contentElement = React.findDOMNode @content
    emojify.run contentElement  if contentElement


  contentDidMount: (content) ->

    @content = content
    @renderEmojis()


  componentDidUpdate: -> @renderEmojis()


  render: ->

    body    = @props.message.get 'body'
    body    = helper.markdownUrls body
    content = formatContent body

    return \
      <article
        className="MessageBody"
        ref={@bound 'contentDidMount'}
        dangerouslySetInnerHTML={__html: content} />


  helper =

    markdownUrls: (body) ->

      urls          = urlGrabber body
      processedUrls = {}

      for url in urls
        continue  if processedUrls[url]

        urlWithProtocol = unless regexps.hasProtocol.test url
        then "http://#{url}"
        else url

        urlMarkdown = "[#{url}](#{urlWithProtocol})"

        urlRegExp = new RegExp "(\\s|^)(#{url})(\\s|$)", 'g'
        body      = body.replace urlRegExp, (match, p1, p2, p3) -> p1 + urlMarkdown + p3

        processedUrls[url] = yes

      return body

