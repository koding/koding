React = require 'kd-react'

module.exports = class ActivityAnnouncementWidget extends React.Component

  render: ->
    <div className='AnnouncementWidget ActivitySidebar-widget'>
      <div className="AnnouncementWidget-icon"></div>
      <h3>New: Koding Hackathon is Back!</h3>
      <p>Win over $150,000 in cash prizes! Hack from wherever you are!</p>
      <a
        target="_blank"
        href="https://koding.com/Hackathon"
        title="Apply Now, space limited!">Apply Now, space limited!</a>
    </div>


