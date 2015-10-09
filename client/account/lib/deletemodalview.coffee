kd                   = require 'kd'
nick                 = require 'app/util/nick'
remote               = require('app/remote').getInstance()
Machine              = require 'app/providers/machine'
globals              = require 'globals'
kookies              = require 'kookies'
KDNotificationView   = kd.NotificationView
KDModalViewWithForms = kd.ModalViewWithForms


module.exports = class DeleteModalView extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    data = nick()

    options.title          or= 'Please confirm account deletion'
    options.buttonTitle    or= 'Delete Account'
    options.content        or= """
      <div class='modalformline'>
        <p>
          <strong>CAUTION! </strong>This will destroy everything you have on Koding, including your data on your VM(s). This action <strong>CANNOT</strong> be undone.
        </p>
        <br>
        <p>Please enter <strong>#{data}</strong> into the field below to continue: </p>
      </div>
      """
    options.callback        ?= -> kd.log "#{options.action} performed"
    options.overlay         ?= yes
    options.width           ?= 520
    options.height          ?= 'auto'
    options.tabs            ?=
      forms                  :
        dangerForm           :
          callback           : @bound 'doAction'
          buttons            :
            confirmButton    :
              title          : options.buttonTitle
              style          : 'solid red medium'
              type           : 'submit'
              disabled       : yes
              loader         :
                color        : '#ffffff'
              callback       : -> @showLoader()
            Cancel           :
              style          : 'solid light-gray medium'
              callback       : @bound 'destroy'
          fields             :
            username         :
              placeholder    : "Enter '#{data}' to confirm..."
              validate       :
                rules        :
                  required   : yes
                  keyupCheck : (input, event) => @checkUserName input, no
                  finalCheck : (input, event) => @checkUserName input
                messages     :
                  required   : 'Please enter your username'
                events       :
                  required   : 'blur'
                  keyupCheck : 'keyup'
                  finalCheck : 'blur'

    super options, data


  doAction: ->

    { JUser }         = remote.api
    { dangerForm }    = @modalTabs.forms
    { username }      = dangerForm.inputs
    { confirmButton } = dangerForm.buttons

    @destroyExistingMachines =>

      JUser.unregister username.getValue(), (err) =>
        if err then new KDNotificationView title : 'There was a problem, please try again!'
        else
          surveyLink = 'https://docs.google.com/forms/d/1fiC6wSThfXxtLpdRlQ7qnNvJrClqdUrmOT_L-_cu1tw/viewform'
          @setTitle 'Account successfully deleted'
          @setContent """
            <div class='modalformline'>
              <p>
                Thanks for trying out Koding. Sorry to see you go. We'd appreciate if you take a moment to tell us why.
              </p>
              <br>
              <p><a href='#{surveyLink}' target='_blank'>Click to take the 1 minute survey.</a></p>
            </div>
            """
            # <iframe src="https://docs.google.com/forms/d/1fiC6wSThfXxtLpdRlQ7qnNvJrClqdUrmOT_L-_cu1tw/viewform?embedded=true" width="430" height="600" frameborder="0" marginheight="0" marginwidth="0">Loading...</iframe>
          @_windowDidResize()

          logout =->
            kookies.expire 'clientId'
            global.location.replace '/'

          @on 'KDObjectWillBeDestroyed', logout
          kd.utils.wait 20000, logout

        confirmButton.hideLoader()


  checkUserName: (input, showError = yes) =>

    if input.getValue() is @getData()
      input.setValidationResult 'keyupCheck', null
      @modalTabs.forms.dangerForm.buttons.confirmButton.enable()
    else
      @modalTabs.forms.dangerForm.buttons.confirmButton.disable()
      input.setValidationResult 'keyupCheck', 'Sorry, entered value does not match your username!', showError


  destroyExistingMachines: (callback) ->

    { computeController } = kd.singletons

    remote.api.JMachine.some provider: "koding", (err, machines)=>

      if err? or not machines? then callback()
      else

        machines = machines.filter (machine) ->

          container = new Machine {machine}
          return container.isMine()

        machines.forEach (machine) ->

          computeController.getKloud()
          .destroy { machineId: machine._id }
          .then  (res) ->
            kd.info res if res?
            computeController.emit "revive-#{machine._id}"
          .timeout globals.COMPUTECONTROLLER_TIMEOUT
          .catch (err) ->
            kd.utils.wait 400, ->
              computeController.getKloud()
              .destroy { machineId: machine._id }
            kd.warn err if err?

        kd.utils.wait 4000, -> callback()
