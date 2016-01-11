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
          <li><a href='http://learn.koding.com/guides/ssh-into-your-vm/' target='_blank'>How to ssh into your VM?</a></li>
          <li><a href='http://learn.koding.com/guides/getting-started-kpm/' target='_blank'>Using the Koding Package Manager</a></li>
          <li><a href='http://learn.koding.com/faq/what-is-koding/' target='_blank'>What is Koding?</a></li>
          <li><a href='http://learn.koding.com/guides/getting-started/workspaces/' target='_blank'>Getting started with IDE Workspaces</a></li>
          <li><a href='http://learn.koding.com/guides/change-theme/' target='_blank'>Changing your IDE and Terminal themes</a></li>
        </ol>
        <br />
        <a href="http://learn.koding.com/" target="_blank">More guides on Koding University...</a>
      </p>
    """
