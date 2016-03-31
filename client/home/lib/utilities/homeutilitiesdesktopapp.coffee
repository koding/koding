kd             = require 'kd'
JView          = require 'app/jview'
CustomLinkView = require 'app/customlinkview'

module.exports = class HomeUtilitiesDesktopApp extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @guide  = new CustomLinkView
      cssClass : 'HomeAppView--button'
      title    : 'VIEW GUIDE'
      href     : 'https://www.koding.com/docs/desktop-app'

    @download  = new CustomLinkView
      cssClass : 'HomeAppView--button primary'
      title    : 'DOWNLOAD'
      href     : 'https://www.koding.com/docs/desktop-app/download'


  pistachio: ->
    """
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
    <div class='link-holder'>
      {{> @download}}
      {{> @guide}}
    </div>
    """
