kd              = require 'kd'
globals         = require 'globals'
whoami          = require 'app/util/whoami'
Tracker         = require 'app/util/tracker'
copyToClipboard = require 'app/util/copyToClipboard'

module.exports = class HomeUtilitiesKD extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    whoami().fetchOtaToken (err, token) =>

      key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
      cmd = if err
        "<a href='#'>Failed to generate your command, click to try again!</a>"
      else
        kontrolUrl = if globals.config.environment in ['dev', 'sandbox']
        then "export KONTROLURL=#{globals.config.newkontrol.url}; "
        else ''
        "#{kontrolUrl}curl -sL https://kodi.ng/d/kd | bash -s #{token}"

      @kdInstallView?.destroy()
      @addSubView @kdInstallView = new kd.CustomHTMLView
        partial : """
          <p><code>kd</code>  is a command line program that allows you to use your local
          IDE with your VMs. Copy and paste the command below into your terminal.</p>
          <code class="block"><cite>#{key}</cite></code>
          <p>Once installed, you can use <code>kd list</code> to list your Koding VMs and
          <code>kd mount</code> to mount your VM to a local folder in your computer.
          For detailed instructions:
          </p>
          <p class='view-guide'>
            <a class='HomeAppView--button primary' href='https://www.koding.com/docs/connect-your-machine' target='_blank'>VIEW GUIDE</a>
          </p>
          """

      @cmd?.destroy()
      @cmd = new kd.CustomHTMLView
        tagName  : 'span'
        partial  : cmd
        click    : @bound 'copyCommand'

      @kdInstallView.addSubView @cmd, 'code.block', yes


  copyCommand: (event) ->

    copyToClipboard @cmd.getElement()

    Tracker.track Tracker.KD_INSTALLED
