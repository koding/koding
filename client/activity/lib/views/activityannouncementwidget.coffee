kd    = require 'kd'
JView = require 'app/jview'


module.exports = class ActivityAnnouncementWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'activity-widget announcement-widget'

    super options, data


  pistachio: ->

    return """
      <div class="logo"></div>
      <h3>New: Connect your own system!</h3>
      <p>You can now connect any Ubuntu Linux system/VM with a public IP address your Koding account.</p>
      <a href="http://learn.koding.com/connect_your_system">Learn how.</a>
    """