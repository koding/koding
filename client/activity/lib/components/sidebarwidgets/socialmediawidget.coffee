React          = require 'kd-react'
Scroller       = require 'app/components/scroller'

TWITTER_LINK   = 'https://twitter.com/intent/follow?user_id=42704386'
FACEBOOK_LINK  = 'https://facebook.com/koding'

module.exports = class SocialMediaWidget extends React.Component

  render: ->

    <div className='SocialMediaWidget'>
      <a
        target='_blank'
        href={TWITTER_LINK}
        className='FeedThreadSidebar-social twitter'>Koding on Twitter</a>
      <a
        target='_blank'
        href={FACEBOOK_LINK}
        className='FeedThreadSidebar-social facebook'>Koding on Facebook</a>
    </div>

