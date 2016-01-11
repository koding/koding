React                      = require 'kd-react'
immutable                  = require 'immutable'
Scroller                   = require 'app/components/scroller'
PostingGuideLinesWidget    = require 'activity/components/sidebarwidgets/postingguidelineswidget'
ActivityAnnouncementWidget = require 'activity/components/sidebarwidgets/activityannouncementwidget'
MostReadArticlesWidget     = require 'activity/components/sidebarwidgets/mostreadarticleswidget'
SocialMediaWidget          = require 'activity/components/sidebarwidgets/socialmediawidget'
MostActiveChannelsWidget   = require 'activity/components/sidebarwidgets/mostactivechannelswidget'

module.exports = class FeedThreadSidebar extends React.Component

  @defaultProps=
    popularChannels = immutable.Map()


  render: ->

    <Scroller className="FeedThreadSidebar">
      <ActivityAnnouncementWidget/>
      <PostingGuideLinesWidget/>
      <MostReadArticlesWidget />
      <MostActiveChannelsWidget popularChannels={@props.popularChannels}/>
      <SocialMediaWidget />
    </Scroller>
