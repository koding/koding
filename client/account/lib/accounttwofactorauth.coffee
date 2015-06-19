kd     = require 'kd'
whoami = require 'app/util/whoami'


module.exports = class AccountTwoFactorAuth extends kd.View

  constructor: (options = {}, data) ->

    super options, data


  viewAppended: ->
    @buildInitialView()


  showError: (err) ->
    return  unless err

    console.warn err

    new kd.NotificationView
      type     : 'mini'
      title    : err.message
      cssClass : 'error'

    return err


  buildInitialView: ->

    @destroySubViews()

    @addSubView loader = @getLoaderView()

    kd.singletons.mainController.ready =>
      me = whoami()
      me.generate2FactorAuthKey (err, authInfo) =>

        loader.hide()

        if err
          if err.name is 'ALREADY_INUSE'
            @addSubView @getEnabledView()
            return
          return @showError err

        {key, qrcode} = authInfo
        @_activeKey   = key

        @addSubView @getInstructionsView()
        @addSubView @getQrCodeView qrcode
        @addSubView @getFormView()


  getEnabledView: ->

    @addSubView new kd.CustomHTMLView
      partial: 'You are using 2-Factor auth now'

    @addSubView password = new kd.InputView
      name          : 'password'
      type          : 'password'
      placeholder   : 'Current Password'

    @addSubView new kd.ButtonView
      title         : 'Disable 2-Factor Auth'
      callback      : =>

        options     =
          password  : password.getValue()
          disable   : yes

        me = whoami()
        me.setup2FactorAuth options, (err) =>

          return  if @showError err

          new kd.NotificationView
            title : 'Successfully Disabled!'
            type  : 'mini'

          @buildInitialView()


  getFormView: (key) ->

    @addSubView password = new kd.InputView
      name          : 'password'
      type          : 'password'
      placeholder   : 'Current Password'

    @addSubView tfcode = new kd.InputView
      name          : 'tfcode'
      placeholder   : '2factor verification code'

    @addSubView new kd.ButtonView
      title         : 'Enable 2-Factor Auth'
      callback      : =>

        options = {
          key,
          password     : password.getValue()
          verification : tfcode.getValue()
        }


        me = whoami()
        me.setup2FactorAuth options, (err) =>

          return  if @showError err

          new kd.NotificationView
            title : 'Successfully Enabled!'
            type  : 'mini'

          @buildInitialView()


  getQrCodeView: (url) ->
    new kd.CustomHTMLView
      tagName    : 'img'
      attributes :
        src      : url

  getLoaderView: ->
    new kd.LoaderView
      showLoader : yes
      size       :
        width    : 40
        height   : 40

  getInstructionsView: (key) ->
    new kd.CustomHTMLView
      partial: """
        <p>Download and Install the Google Authenticator app on your phone.</p>

        <p>
          <a href="https://itunes.apple.com/en/app/google-authenticator/id388497605?mt=8" target=_blank>Authenticator for iOS Devices</a>
          iPhone, iPod Touch, or iPad, available free in the Apple App store.
        </p>

        <p>
          <a href="https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&feature=search_result#?t=W251bGwsMSwyLDEsImNvbS5nb29nbGUuYW5kcm9pZC5hcHBzLmF1dGhlbnRpY2F0b3IyIl0." target=_blank>Authenticator for Android Devices</a>
          Available free from the Google Play store.
        </p>

        <p>
          <li>Launch the Google Authenticator app.</li>
          <li>Click the pencil icon, top right</li>
          <li>Click the + button</li>
          <li>Scan the Barcode below and you'll get a verification code.</li>
          <li>Or use this code for entering manually: #{key}</li>
        </p>
      """
