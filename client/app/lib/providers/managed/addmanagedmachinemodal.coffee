kd      = require 'kd'
globals = require 'globals'
whoami  = require 'app/util/whoami'


module.exports = class AddManagedMachineModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'add-managed-vm'
    options.title    = 'Add Your Own Machine'
    options.width    = 690
    options.height   = 305

    super options, data

    @createElements()
    @generateCode()


  createElements: ->

    @addSubView new kd.CustomHTMLView
      partial   : """
        <div class="bg"></div>
        <section>
          <p>Connect your VM from anywhere and collaborate!</p>
          <p>Simply run this command:</p>
          <span>
            Wait for this script to finish executing, once connection is
            established, your vm will appear on your sidebar.<br/>
            <strong>Don’t close this popup until you see your machine on the sidebar.</strong>
          </span>
        </section>
      """

    @addSubView @code = new kd.CustomHTMLView
      tagName  : 'div'
      cssClass : 'code'

    @code.addSubView @loader = new kd.LoaderView
      showLoader: yes
      size      : width: 16


  machineFoundCallback: (info, machine) ->

    kd.singletons.mainView.activitySidebar.showManagedMachineAddedModal info, machine
    @destroy()


  generateCode: ->

    { computeController } = kd.singletons

    computeController.ready =>
      whoami().fetchOtaToken (err, token) =>
        return @handleError err  if err

        kontrolUrl = if globals.config.environment in ['dev', 'sandbox']
        then "export KONTROLURL=#{globals.config.newkontrol.url}; "
        else ''

        cmd = "#{kontrolUrl}curl -sSL s3.amazonaws.com/koding-klient/install.sh | bash -s #{token}"

        @loader.destroy()
        @code.addSubView input = new kd.InputView
          defaultValue : cmd
          click        : -> @selectAll()

        @code.addSubView new kd.CustomHTMLView
          cssClass : 'select-all'
          partial  : '<span></span>SELECT'
          click    : -> input.selectAll()

        computeController.managedKiteChecker.addListener @bound 'machineFoundCallback'


  handleError: (err) ->

    console.warn "Couldn't fetch otatoken:", err  if err

    @loader.destroy()
    return @code.updatePartial 'Failed to fetch one time access token.'


  destroy: ->

    super

    cc = kd.singletons.computeController
    cc.managedKiteChecker.removeListener @bound 'machineFoundCallback'
