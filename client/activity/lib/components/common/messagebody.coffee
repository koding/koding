$                    = require 'jquery'
React                = require 'kd-react'
emojify              = require 'emojify.js'
formatContent        = require 'app/util/formatContent'
immutable            = require 'immutable'
ProfileTextContainer = require 'app/components/profile/profiletextcontainer'
MessageLink          = require 'activity/components/messagelink'

module.exports = class MessageBody extends React.Component

  @defaultProps =
    message: immutable.Map()


  contentDidMount: (content) ->

    contentElement = React.findDOMNode content
    emojify.run contentElement  if contentElement

    # dirty hack for to be able to show the `- in reply to` part as a part of
    # the body.
    if contentElement and parent = @props.message.get 'parent'
      React.render(
        generateReplyTo parent
        $(contentElement).find('#replyToContainer')[0]
      )


  render: ->

    content = formatContent @props.message.get 'body'

    # we are gonna use this container for showing the `- in reply to` part.
    # Hopefully a css wizard will jump here and fix this. ~Umut
    content += "<span id='replyToContainer'></span>"

    return \
      <article
        className="MessageBody"
        ref={@bound 'contentDidMount'}
        dangerouslySetInnerHTML={__html: content} />


generateReplyTo = (parent) ->

  account = parent.get 'account'

  profileText = \
    <ProfileTextContainer origin={account.toJS()} />

  return \
    <MessageLink className="InReplyToLink" message={parent} absolute={yes}>
      <em>- in reply to {profileText}</em>
    </MessageLink>


