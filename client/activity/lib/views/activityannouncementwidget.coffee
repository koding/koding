kd    = require 'kd'
JView = require 'app/jview'


module.exports = class ActivityAnnouncementWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'activity-widget announcement-widget'

    super options, data


  pistachio: ->

    return """
      <div class="logo"></div>
      <h3>New: Connect your own machine!</h3>
      <p>You can now connect any Ubuntu Linux machine with a public IP address to your Koding account.</p>
      <a href="http://learn.koding.com/connect_your_machine">Learn how.</a>
    """
