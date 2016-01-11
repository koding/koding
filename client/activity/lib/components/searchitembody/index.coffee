kd        = require 'kd'
$         = require 'jquery'
React     = require 'kd-react'
Constants = require 'activity/flux/actions/searchconstants'
emojify   = require 'emojify.js'

module.exports = class SearchItemBody extends React.Component

  @defaultProps =
    contentFormatter : kd.noop


  ###*
   * Renders search item body
  ###
  render: ->

    <article className="has-markdown" dangerouslySetInnerHTML={__html: @formatSource()} />


  ###*
   * Processes body markup, converts markdown markup to html and highlights
   * matched words.
   * Algolia wraps matched words in pre and post markers (HIGHLIGHT_PRE_MARKER
   * and HIGHLIGHT_POST_MARKER) so we need to replace them with <span>
   * with proper css class to highlight words in body.
   * Markdown markup can contain links and images and Angolia can find
   * matched words in their urls and titles. In such cases we should ignore
   * Algolia suggestions and remove markers from links and images attributes.
   *
   * @return {string} html string
  ###
  formatSource: ->

    startTag = '<span class="SearchItemBody-matchedWord">'
    endTag   = '</span>'

    { source, contentFormatter } = @props

    content = source

    content = contentFormatter content, { highlight : no }

    content = helper.cleanUselessMarkers content
    content = helper.replaceMarkers content, startTag, endTag

    content = emojify.replace content

    return content


  # HELPER METHODS
  helper =

    preRegexp: new RegExp(Constants.HIGHLIGHT_PRE_MARKER, 'g')
    postRegexp: new RegExp(Constants.HIGHLIGHT_POST_MARKER, 'g')

    ###*
     * Cleans Algolia markers in links and images attributes
     * if there is any in the initial content.
     *
     * @param {string} content - initial html
     * @return {string} resulting html
    ###
    cleanUselessMarkers: (content) ->

      hasLinks  = content.indexOf('<a') > -1
      hasImages = content.indexOf('<img') > -1
      return content  unless hasLinks or hasImages

      wrapper = document.createElement 'span'
      wrapper.innerHTML = content

      helper.removeMarkersForElements wrapper, 'a', [ 'href', 'title' ]  if hasLinks
      helper.removeMarkersForElements wrapper, 'img', [ 'src', 'title', 'alt' ]  if hasImages

      return wrapper.innerHTML


    ###*
     * Cleans Algolia markers in specific attributes for elements
     * with specific tag names
     *
     * @param {DOMElement} wrapper - wrapper whose childs should be cleaned
     * @param {string} tagName - nodes with such tag name should be cleaned
     * @param {Array} attrNames - array of attributes which should be cleaned
    ###
    removeMarkersForElements: (wrapper, tagName, attrNames) ->

      elements = wrapper.querySelectorAll tagName
      for element in elements
        for attrName in attrNames
          attrValue = element.getAttribute attrName
          if attrValue
            element.setAttribute attrName, helper.replaceMarkers attrValue, '', ''


    ###*
     * Replaces Algolia markers with specific strings
     *
     * @param {string} content - initial html
     * @param {string} preValue - value which should replace HIGHLIGHT_PRE_MARKER
     * @param {string} postValue - value which should replace HIGHLIGHT_POST_MARKER
     * @return {string} resulting html
    ###
    replaceMarkers: (content, preValue, postValue) ->

      content = content
        .replace(helper.preRegexp, preValue)
        .replace(helper.postRegexp, postValue)

      return content
