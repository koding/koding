kd = require 'kd'
os = require 'os'
React = require 'kd-react'


module.exports = class DesktopAppView extends React.Component


  renderGuideButton: ->

    <a className="custom-link-view HomeAppView--button fl" onClick={@comingSoon}>
      <span className="title">VIEW GUIDE</span>
    </a>

  comingSoon: ->

    return new kd.NotificationView
      title    : 'Coming Soon!'
      duration : 2000


  renderDownloadButton: ->

    link = switch os
      when 'mac' then 'https://koding-cdn.s3.amazonaws.com/koding-app/Koding-mac.zip'
      when 'linux' then 'https://koding-cdn.s3.amazonaws.com/koding-app/Koding-linux.zip'

    <a className="custom-link-view HomeAppView--button primary" href={link}>
      <span className="title">DOWNLOAD</span>
    </a>

  render: ->

    <div>
      <p>
        Koding Collaborative Development Environment (CDE),
        built on top of the Atom IDE offers real-time VM-level
        collaboration
      </p>
      <ul>
        <li>Only available for macOS & Linux</li>
        <li>Current build in Beta</li>
        <li>Requires ~37MB of disk space</li>
      </ul>
      <div className='link-holder'>
        {@renderGuideButton()}
        {@renderDownloadButton()}
      </div>
    </div>

