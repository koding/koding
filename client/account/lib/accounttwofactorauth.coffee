kd     = require 'kd'
whoami = require 'app/util/whoami'


module.exports = class AccountTwoFactorAuth extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry \
      'AppModal--account tfauth', options.cssClass

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
      cssClass  : 'enabled-intro'
      partial   : "
        <div>
          2-Factor Authentication is <green>active</green> for your account.
          <cite></cite>
        </div>
        #{@getLearnLink()}
      "

    @addSubView inputForm  = new kd.FormViewWithFields
      cssClass             : 'AppModal-form'
      fields               :
        password           :
          cssClass         : 'Formline--half'
          placeholder      : 'Enter your Koding password'
          name             : 'password'
          type             : 'password'
          label            : 'Password'
        button             :
          label            : '&nbsp;'
          cssClass         : 'Formline--half'
          itemClass        : kd.ButtonView
          title            : 'Disable 2-Factor Auth'
          style            : 'solid medium disable-tf'
          callback         : =>

            { password }   = inputForm.inputs

            options        =
              password     : password.getValue()
              disable      : yes

            me = whoami()
            me.setup2FactorAuth options, (err) =>

              return  if @showError err

              new kd.NotificationView
                title      : 'Successfully Disabled!'
                type       : 'mini'

              @buildInitialView()


  getFormView: ->

    @addSubView inputForm  = new kd.FormViewWithFields
      cssClass             : 'AppModal-form'
      fields               :
        password           :
          cssClass         : 'Formline--half'
          placeholder      : 'Enter your Koding password'
          name             : 'password'
          type             : 'password'
          label            : 'Password'
        tfcode             :
          cssClass         : 'Formline--half'
          placeholder      : 'Enter the verification code'
          name             : 'tfcode'
          label            : 'Verification Code'

    { password, tfcode } = inputForm.inputs

    @addSubView new kd.ButtonView
      title            : 'Enable 2-Factor Auth'
      style            : 'solid green small enable-tf'
      callback         : =>

        options        =
          key          : @_activeKey
          password     : password.getValue()
          verification : tfcode.getValue()

        me = whoami()
        me.setup2FactorAuth options, (err) =>

          return  if @showError err

          new kd.NotificationView
            title : 'Successfully Enabled!'
            type  : 'mini'

          @buildInitialView()


  getQrCodeView: (url) ->

    view = new kd.CustomHTMLView
      cssClass   : 'qrcode-view'

    view.addSubView imageView = new kd.CustomHTMLView
      tagName    : 'img'
      attributes : src: url

    view.addSubView button = new kd.ButtonView
      iconOnly   : yes
      icon       : 'reload'
      loader     :
        color    : '#000000'
        size     :
          width  : 20
          height : 20
      callback   : =>

        me = whoami()
        me.generate2FactorAuthKey (err, authInfo) =>

          @showError err

          if authInfo
            @_activeKey = authInfo.key
            imageView.setAttribute 'src', authInfo.qrcode

          kd.utils.defer button.bound 'hideLoader'

    return view


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 40
        height   : 40

  getLearnLink: ->
    "
      <a class='learn-link' href='https://learn.koding.com' target=_blank>
      Learn more about 2-factor authentication.</a>
    "

  getInstructionsView: ->

    new kd.CustomHTMLView
      cssClass : 'instructions'
      partial  : """
        <div class='intro'>
          <cite></cite>
          Download and install the Google Authenticator app on your
          <a href='https://goo.gl/x01UdJ' target=_blank>iPhone</a> or
          <a href='https://goo.gl/Oe5t7l' target=_blank>Android</a> phone.
          Then follow the steps listed below to set up 2-factor authentication
          for your Koding account. <br />
          #{@getLearnLink()}
        </div>

        <li>Open the Authenticator app on your phone.
        <li>Tap the “+" or “..." icon and then choose “Scan barcode" to add Koding.
        <li>Scan the code shown below using your phone's camera.
        <li>Enter the 6-digit verification code generated by the app in the space
        below and click the “Enable” button.

      """
