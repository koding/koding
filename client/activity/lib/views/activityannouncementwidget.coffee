kd    = require 'kd'
JView = require 'app/jview'
AddManagedMachineModal = require 'app/providers/managed/addmanagedmachinemodal'


module.exports = class ActivityAnnouncementWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'activity-widget announcement-widget'

    super options, data


  pistachio: ->

    return """
      <div class="logo"></div>
      <h3>New: Koding Hackathon is Back!</h3>
      <p>Win over $150,000 in cash prizes! Hack from wherever you are!</p>
      <a href="/Hackathon" title="Apply Now, space limited!">Apply Now, space limited!</a>
    """


