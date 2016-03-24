kd = require 'kd'

module.exports = class SidebarMachineConnectedPopup extends kd.ModalView

  constructor: (options = {}, data) ->

    options.width    = 610
    options.height   = 400
    options.cssClass = 'activity-modal sidebar-info-modal'
    options.overlay  = yes

    super options, data

    @prodiver = if PROVIDERS[options.provider] then options.provider else 'UnknownProvider'

    @createArrow()
    @createElements()

  createArrow: ->

    _addSubview = kd.View::addSubView.bind this

    _addSubview new kd.CustomHTMLView
      cssClass  : 'modal-arrow'
      position  : { top : 20 }


  createElements: ->

    lowerCaseProviderName = @prodiver.toLowerCase()

    @addSubView new kd.CustomHTMLView
      partial: """
        <div class="artboard">
          <img class="#{lowerCaseProviderName}"
            src="/a/images/providers/#{lowerCaseProviderName}.png" />
        </div>
        <h2>Your #{PROVIDERS[@prodiver] or ''} machine is now connected!</h2>
        <p>
          You may now use this machine just like you use your Koding VM.
          You can open files, terminals and even initiate collaboration session.
        </p>
      """

    @addSubView new kd.ButtonView
      title     : 'AWESOME'
      cssClass  : 'solid green medium close'
      iconClass : 'check'
      callback  : @bound 'destroy'


  destroy: ->

    kd.singletons.router.handleRoute "/IDE/#{@getData().slug}"

    super


  PROVIDERS         =
    AWS             : 'Amazon'
    Azure           : 'Azure'
    HPCloud         : 'HP Cloud'
    Joyent          : 'Joyent'
    SoftLayer       : 'SoftLayer'
    Rackspace       : 'Rackspace'
    GoogleCloud     : 'Google Cloud'
    DigitalOcean    : 'DigitalOcean'
    UnknownProvider : '' # no custom name for unknown providers
