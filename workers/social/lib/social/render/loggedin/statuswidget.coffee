module.exports = (account)->

  {firstName} = account.profile
  encoder     = require 'htmlencode'

  """
  <div id="activity-update-widget" class="kdview activity-update-widget-wrapper">
    <div class="kdview widget-holder clearfix">
      <div class="kdbuttonwithmenu-wrapper activity-status-context with-icon">
        <button class="kdbutton activity-status-context with-icon with-menu" id="kd-320"><span class="icon update"></span><span class="title">Status Update</span></button><span class="chevron-separator"></span><span class="chevron"></span>
      </div>
      <div class="kdview kdscrollview kdtabview update-widget-tabs">
        <div class="kdview kdtabpaneview update clearfix no-shadow active">
          <form class="kdformview status-widget">
            <div class="small-input"><input name="dummy" type="text" class="kdinput text status-update-input warn-on-unsaved-data" placeholder="What's new #{encoder.XSSEncode firstName}?"></div>
          </form>
        </div>
      </div>
    </div>
  </div>
  """