React    = require 'kd-react'
Scroller = require 'app/components/scroller'

module.exports = class SocialMediaWidget extends React.Component

  render: ->

    twitter_link  = 'https://twitter.com/intent/follow?user_id=42704386'
    facebook_link = 'https://facebook.com/koding'

    <div className='SocialMediaWidget'>
      <a
        target='_blank'
        href={twitter_link}
        className='FeedThreadSidebar-social twitter'>Koding on Twitter</a>
      <a
        target='_blank'
        href={facebook_link}
        className='FeedThreadSidebar-social facebook'>Koding on Facebook</a>
    </div>

