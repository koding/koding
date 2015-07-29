kd = require 'kd'
React = require 'kd-react'
Link = require 'app/components/common/link'

module.exports = class FeedItemAction extends React.Component

  render: ->
    <div className="FeedItemAction">
      <Link href="#" {...@props} />
    </div>


