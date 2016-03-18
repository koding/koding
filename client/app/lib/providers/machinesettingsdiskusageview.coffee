kd                  = require 'kd'
KDView              = kd.View
showError           = require 'app/util/showError'
isKoding            = require 'app/util/isKoding'
KDCustomHTMLView    = kd.CustomHTMLView
ComputeResizeModal  = require './computeresizemodal'
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

    @addSubView new KDCustomHTMLView
      cssClass : 'usage-info'
      partial  : """
        <p>Usage</p>
        <span>#{format usage} of #{format total}</span>
      """

    { provider } = @getData()

    if isKoding() and provider not in ['softlayer', 'managed']
      @addSubView new KDCustomHTMLView
        cssClass : 'footline'
        partial  : """
          If you have a paid plan or storage through referrals, you can
          <a href='#' class='resize'>resize your VM</a>.<br>Share Koding and
          <a href='#' class='share'>get more storage for free</a>!
        """
        click    : (e) =>
          if e.target.tagName is 'A'

            { classList } = e.target

            if classList.contains 'share'
              kd.singletons.router.handleRoute '/Account/Referral'

            else if classList.contains 'resize'
              @handleResizeRequest()

            @emit 'ModalDestroyRequested'


  handleResizeRequest: ->

    @fetchUsageInfo (err, info) =>

      return showError err  if err

      { plan, plans, usage, reward } = info

      limits  = plans[plan]
      options = { plan, limits, usage, reward, machine: @getData() }

      new ComputeResizeModal options


  fetchUsageInfo: (callback = kd.noop) ->

    return callback null, @fetchedInfo  if @fetchedInfo

    kd.singletons.computeController.fetchPlanCombo 'koding', (err, info) =>

      return callback err  if err

      callback null, @fetchedInfo = info
