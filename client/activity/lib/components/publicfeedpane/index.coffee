kd        = require 'kd'
React     = require 'kd-react'
FeedList  = require 'activity/components/feedlist'
immutable = require 'immutable'

module.exports = class PublicFeedPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()


  getMessages: ->
    @props.messages
      .toSeq()
      .sortBy (m) -> m.get 'createdAt'
      .reverse()
      .toMap()


  render: ->
    <div className="PublicFeedPane">
      <section className="PublicFeedPane-contentWrapper">
        <header className="PublicFeedPane-header">
        </header>
      </section>
      <section className="PublicFeedPane-body">
        <div className="PublicFeedPane-FeedList">
          <FeedList messages={@getMessages()} />
        </div>
      </section>
    </div>
