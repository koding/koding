kd                  = require 'kd'
whoami              = require 'app/util/whoami'
KDView              = kd.View
KDButtonView        = kd.ButtonView


module.exports = class AccountTwoFactorAuth extends KDView


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

    @addSubView @disableForm = new kd.FormViewWithFields
      cssClass             : 'AppModal-form'
      fields               :
        password           :
          cssClass         : 'Formline--half'
          placeholder      : 'Enter your Koding password'
          name             : 'password'
          type             : 'password'
          label            : 'Password'
        button             :
          type             : 'submit'
          label            : '&nbsp;'
          cssClass         : 'Formline--half'
          itemClass        : KDButtonView
          title            : 'Disable 2-Factor Auth'
          style            : 'solid medium disable-tf'
      callback             : @bound 'handleDisableFormButton'


  handleDisableFormButton: ->

    { password }   = @disableForm.inputs

    options        =
      password     : password.getValue()
      disable      : yes

    @handleProcessOf2FactorAuth options, 'Successfully Disabled!'


  handleProcessOf2FactorAuth: (options, message) ->

    me = whoami()
    me.setup2FactorAuth options, (err) =>

      return  if @showError err

      new kd.NotificationView
        title : message
        type  : 'mini'

      @buildInitialView()


  getFormView: ->

    @addSubView @enableForm  = new kd.FormViewWithFields
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
      buttons              :
        Enable             :
          type             : 'submit'
          title            : 'Enable 2-Factor Auth'
          style            : 'solid green small enable-tf'
      callback             : @bound 'handleEnableFormButton'


  handleEnableFormButton: ->

    { password, tfcode } = @enableForm.inputs

    options =
      key          : @_activeKey
      password     : password.getValue()
      verification : tfcode.getValue()

    @handleProcessOf2FactorAuth options, 'Successfully Enabled!'


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
        width    : 25
        height   : 25

  getLearnLink: ->
    "
      <a class='learn-link' href='https://learn.koding.com/guides/2-factor-auth/' target=_blank>
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
