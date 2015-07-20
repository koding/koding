kd    = require 'kd'
JView = require 'app/jview'


module.exports = class ActivityAnnouncementWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'activity-widget announcement-widget'

    super options, data


  pistachio: ->

    return """
      <div class="logo"></div>
      <h3>New: Connect your own VM!</h3>
      <p>You can now connect any VM that has a public IP and is Ubuntu.</p>
      <a href="https://learn.koding.com">Learn how to add your VM</a>
    """