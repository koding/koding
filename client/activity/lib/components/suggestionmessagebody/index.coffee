$             = require 'jquery'
React         = require 'kd-react'
Constants     = require 'activity/flux/actions/suggestionconstants'
MessageBody   = require 'activity/components/common/messagebody'


module.exports = class SuggestionMessageBody extends MessageBody

  formatSource: ->

    { HIGHLIGHT_PRE_MARKER, HIGHLIGHT_POST_MARKER } = Constants

    startTag = '<span class="SuggestionMessageBody-matchedWord">'
    endTag   = '</span>'

    content = super()

   # Algolia wraps matched words in pre and post markers (HIGHLIGHT_PRE_MARKER
   # and HIGHLIGHT_POST_MARKER) so we need to replace them with <span>
   # with proper css class to highlight words in suggestion
    content = content
      .replace(new RegExp(HIGHLIGHT_PRE_MARKER, 'g'), startTag)
      .replace(new RegExp(HIGHLIGHT_POST_MARKER, 'g'), endTag)

    return content