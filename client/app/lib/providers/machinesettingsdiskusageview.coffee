kd                  = require 'kd'
KDView              = kd.View
showError           = require 'app/util/showError'
KDCustomHTMLView    = kd.CustomHTMLView
CircularProgressBar = require 'app/commonviews/circularprogressbar'


module.exports = class MachineSettingsDiskUsageView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'disk-usage-info'

    super options, data

    @createProgressBar 0

    @getData().getBaseKite().systemInfo?() # data is machine
      .then (info) =>

        percent = parseInt((info.diskUsage / info.diskTotal) * 100, 10)

        @createProgressBar percent
        @createUsageInfo info

      .catch (err) ->
        kd.warn 'Failed to fetch system info for machine settings:', err
        showError 'Failed to fetch disk usage'


  createProgressBar: (percent) ->

    @progressBar?.destroy()

    @addSubView @progressBar = new CircularProgressBar
      percent   : percent
      size      : 158
      lineWidth : 14


  createUsageInfo: (info) ->

    format = kd.utils.formatBytesToHumanReadable
    total  = info.diskTotal * 1024
    usage  = info.diskUsage * 1024
    free   = total - usage

    @addSubView new KDCustomHTMLView
      cssClass : 'usage-info'
      partial  : """
        <p>Usage</p>
        <span>#{format usage} of #{format total}</span>
      """

    @addSubView new KDCustomHTMLView
      cssClass : 'share'
      partial  : "<a href='#'>Share Koding</a> and get extra disk"
      click    : (e) =>
        if e.target.tagName is 'A'
          kd.singletons.router.handleRoute '/Account/Referral'
          @emit 'ModalDestroyRequested'
