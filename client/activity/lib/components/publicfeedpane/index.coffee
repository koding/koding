kd        = require 'kd'
React     = require 'kd-react'
FeedList  = require 'activity/components/feedlist'
immutable = require 'immutable'

module.exports = class PublicFeedPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()


  getMessages: ->
    return immutable.Map()  unless @props.messages

    @props.messages.sort (a, b) ->
      if a.get 'createdAt' > b.get 'createdAt' then 1
      else if b.get 'createdAt' < b.get 'createdAt' then return -1
      else 0


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
