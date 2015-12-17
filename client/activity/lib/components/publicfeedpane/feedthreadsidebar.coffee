React                      = require 'kd-react'
Scroller                   = require 'app/components/scroller'
ActivityGuideWidget        = require 'activity/components/sidebarwidgets/ActivityGuideWidget'
ActivityAnnouncementWidget = require 'activity/components/sidebarwidgets/activityannouncementwidget'

module.exports = class FeedThreadSidebar extends React.Component

  render: ->
    <Scroller className="FeedThreadSidebar">
      <ActivityAnnouncementWidget/>
      <ActivityGuideWidget/>
    </Scroller>


