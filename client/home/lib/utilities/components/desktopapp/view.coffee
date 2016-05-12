kd               = require 'kd'
React            = require 'kd-react'


module.exports = class DesktopAppView extends React.Component


  renderGuideButton: ->
    
    <a className="custom-link-view HomeAppView--button" href="https://www.koding.com/docs/desktop-app">
      <span className="title">VIEW GUIDE</span>
    </a>
    
  renderDownloadButton: ->
    
    <a className="custom-link-view HomeAppView--button primary" href="https://www.koding.com/docs/desktop-app/download">
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
        <li>Only available for Mac OS X</li>
        <li>Current build in Beta (v.024)</li>
        <li>Requires 34MB of disk space</li>
      </ul>
      <div className='link-holder'>
        {@renderDownloadButton()}
        {@renderGuideButton()}
      </div>
    </div>
    