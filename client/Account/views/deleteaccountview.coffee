class DeleteAccountView extends JView

  constructor:(options, data)->

    options.cssClass = 'delete-account-view'

    super options, data

    @button = new KDButtonView
      title      : "Delete Account"
      cssClass   : "delete-account solid red fr medium"
      bind       : "mouseenter"
      mouseenter : do ->
        times = 0
        ->
          switch times
            when 0 then @setTitle "Are you sure?!"
            when 1 then @setTitle "OK, go ahead :)"
            else
              KD.utils.wait 5000, =>
                times = 0
                @setTitle "Delete Account"
              return
          @toggleClass 'escape'
          times++
      callback   : -> new DeleteModalView

  pistachio:->
    """
    <span>Delete your account (if you can)</span>
    {{> @button}}
    """


class DeleteModalView extends KDModalViewWithForms

  constructor:(options = {}, data)->

    data = KD.nick()

    options.title     or= 'Please confirm account deletion'
    options.content   or= """
      <div class='modalformline'>
        <p>
          <strong>CAUTION! </strong>This will destroy everything you have on Koding, including your data on your VM(s). This action <strong>CANNOT</strong> be undone.
        </p>
        <br>
        <p>Please enter <strong>#{data}</strong> into the field below to continue: </p>
      </div>
      """
    options.callback   ?= -> log "#{options.action} performed"
    options.overlay    ?= yes
    options.width      ?= 520
    options.height     ?= 'auto'
    options.tabs       ?=
      forms                  :
        dangerForm           :
          callback           : =>
            {JUser}         = KD.remote.api
            {dangerForm}    = @modalTabs.forms
            {username}      = dangerForm.inputs
            {confirmButton} = dangerForm.buttons

            JUser.unregister username.getValue(), (err)=>
              if err then new KDNotificationView title : 'There was a problem, please try again!'
              else
                surveyLink = "https://docs.google.com/forms/d/1fiC6wSThfXxtLpdRlQ7qnNvJrClqdUrmOT_L-_cu1tw/viewform"
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
                KD.mixpanel "Delete account, success"
                KD.utils.wait 30000, ->
                  Cookies.expire 'clientId'
                  location.replace '/'
              confirmButton.hideLoader()

          buttons            :
            confirmButton    :
              title          : 'Delete Account'
              style          : 'modal-clean-red'
              type           : 'submit'
              disabled       : yes
              loader         :
                color        : '#ffffff'
              callback       : -> @showLoader()
            Cancel           :
              style          : 'modal-cancel'
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

  checkUserName:(input, showError=yes)=>

    if input.getValue() is @getData()
      input.setValidationResult 'keyupCheck', null
      @modalTabs.forms.dangerForm.buttons.confirmButton.enable()
    else
      @modalTabs.forms.dangerForm.buttons.confirmButton.disable()
      input.setValidationResult 'keyupCheck', 'Sorry, entered value does not match your username!', showError
