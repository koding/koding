kd      = require 'kd'
globals = require 'globals'
whoami  = require 'app/util/whoami'
Tracker = require 'app/util/tracker'

module.exports = class KodingUtilitiesView extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'KodingUtilitiesView', options.cssClass

    super options, data


  viewAppended: ->

    super

    @putKd()


  putKd: ->

    whoami().fetchOtaToken (err, token) =>

      key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
      cmd = if err
        "<a href='#'>Failed to generate your command, click to try again!</a>"
      else
        if globals.config.environment in ['dev', 'default', 'sandbox']
          "export KONTROLURL=#{globals.config.newkontrol.url}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
        else
          "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"

      @kdInstallView?.destroy()
      @wrapper.addSubView @kdInstallView = new kd.CustomHTMLView
        partial : """
          <h2>KD: Koding + Your Localhost!</h2>
          <p><code>kd</code>  is a command line program that allows you to use your local
          IDE with your VMs. Copy and paste the command below into your terminal.</p>
          <code class="block"><cite>#{key}</cite></code>
          <p>Once installed, you can use <code>kd list</code> to list your Koding VMs and
          <code>kd mount</code> to mount your VM to a local folder in your computer.
          For detailed instructions:
          <a href='https://www.koding.com/docs/connect-your-machine' target='_blank'>https://www.koding.com/docs/connect-your-machine</a>
          </p>
          """

      @cmd?.destroy()
      @cmd = new kd.CustomHTMLView
        tagName  : 'span'
        partial  : cmd
        click    : @bound 'copyCommand'

      @kdInstallView.addSubView @cmd, 'code.block', yes


  copyCommand: (event) ->

    if event.target.tagName is 'A'
      @putKd()
      return

    kd.utils.selectText @cmd.getElement()

    notification = 'Copied to clipboard!'

    try
      copied = document.execCommand 'copy'
      couldntCopy = 'couldn\'t copy'
      throw couldntCopy  unless copied
    catch
      key          = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
      notification = "Hit #{key} to copy!"

    new kd.NotificationView { title: notification }

    Tracker.track Tracker.KD_START_INSTALL
