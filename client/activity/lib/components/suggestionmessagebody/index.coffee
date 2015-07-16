$             = require 'jquery'
htmlencode    = require 'htmlencode'
formatContent = require 'app/util/formatContent'
React         = require 'kd-react'
MessageBody   = require 'activity/components/common/messagebody'


module.exports = class SuggestionMessageBody extends MessageBody

  ###*
    Applies mardown markup and highlights matched words Angolia found in the text.
    Algolia wraps matched words in <em> tags. Since applying markdown markup encodes
    all html tags, we need to handle <em>s before and convert them into text markers
    instead of html tags. To be sure that <em> tags are well formed, message text is
    wrapped in temporary DOM element and <em>s are processed as DOM nodes.
    After mardown markup is applied, we find matched words using text markers and
    hightlight them wrapping in <span> with class 'SuggestionMessageBody-matchedWord'
  ###
  formatSource: ->

    wordStartMarker = '!SUGGESTION_WORD_START='
    wordEndMarker   = '=SUGGESTION_WORD_END!'

    source  = @props.source
    element = $('<span>').html source

    element.find('em').replaceWith -> "#{wordStartMarker}#{this.innerHTML}#{wordEndMarker}"
    source = element.html()

    content = formatContent source

    highlightStartTag = '<span class="SuggestionMessageBody-matchedWord">'
    highlightEndTag   = '</span>'

    content = content
      .replace(new RegExp(wordStartMarker, 'g'), highlightStartTag)
      .replace(new RegExp(wordEndMarker, 'g'), highlightEndTag)

    return content