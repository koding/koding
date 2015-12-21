React                      = require 'kd-react'
Scroller                   = require 'app/components/scroller'
PostingGuideLinesWidget    = require 'activity/components/sidebarwidgets/postingguidelineswidget'
ActivityAnnouncementWidget = require 'activity/components/sidebarwidgets/activityannouncementwidget'
MostReadArticlesWidget     = require 'activity/components/sidebarwidgets/mostreadarticleswidget'

module.exports = class FeedThreadSidebar extends React.Component

  render: ->
    <Scroller className="FeedThreadSidebar">
      <ActivityAnnouncementWidget />
      <PostingGuideLinesWidget />
      <MostReadArticlesWidget />
    </Scroller>


