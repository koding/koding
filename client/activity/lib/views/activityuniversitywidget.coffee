kd = require 'kd'
ActivityBaseWidget = require './activitybasewidget'


module.exports = class ActivityUniversityWidget extends ActivityBaseWidget

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'university-widget', options.cssClass

    super options, data


  pistachio : ->

    """
      <h3>Most read articles on Koding University</h3>
      <p>
        <ol>
          <li><a href='https://koding.com/docs/ssh-into-your-vm/' target='_blank'>How to ssh into your VM?</a></li>
          <li><a href='https://koding.com/docs/getting-started-kpm/' target='_blank'>Using the Koding Package Manager</a></li>
          <li><a href='https://koding.com/docs/what-is-koding/' target='_blank'>What is Koding?</a></li>
          <li><a href='https://koding.com/docs/getting-started/workspaces/' target='_blank'>Getting started with IDE Workspaces</a></li>
          <li><a href='https://koding.com/docs/change-theme/' target='_blank'>Changing your IDE and Terminal themes</a></li>
        </ol>
        <br />
        <a href="https://koding.com/docs/index" target="_blank">More guides on Koding University...</a>
      </p>
    """
