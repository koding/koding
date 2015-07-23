kd    = require 'kd'
JView = require 'app/jview'
AddManagedMachineModal = require 'app/providers/managed/addmanagedmachinemodal'


module.exports = class ActivityAnnouncementWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'activity-widget announcement-widget'

    super options, data

    @tryManagedMachineLink = new kd.CustomHTMLView
      tagName : 'a'
      partial : 'Try it now'
      click   : -> new AddManagedMachineModal


  pistachio: ->

    return """
      <div class="logo"></div>
      <h3>New: Connect your own machine!</h3>
      <p>You can now connect any Ubuntu Linux machine with a public IP address to your Koding account.</p>
      {{> @tryManagedMachineLink}}
    """


