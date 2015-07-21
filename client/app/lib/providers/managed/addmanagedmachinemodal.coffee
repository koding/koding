kd      = require 'kd'
globals = require 'globals'
whoami  = require 'app/util/whoami'


module.exports = class AddManagedMachineModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'add-managed-vm'
    options.title    = 'Add Your Own Machine'
    options.width    = 690
    options.height   = 310

    super options, data

    @createElements()
    @generateCode()


  createElements: ->

    @addSubView new kd.CustomHTMLView
      partial   : """
        <div class="bg"></div>
        <section>
          <p>Run the command below to connect to your machine to Koding. Note, machine should:</p>
          <p class="middle">1. have a public IP address</p>
          <p>2. you should have root access</p>
          <span>
            <strong>Leave this dialogue box open</strong> until you see a notification in the sidebar
            that the connection has been successful.
            <a href="http://learn.koding.com/connect_your_machine" target="_blank">Learn more about this feature.</a>
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
