kd             = require 'kd'
whoami         = require 'app/util/whoami'
CustomLinkView = require 'app/customlinkview'

module.exports = class HomeAccountSecurityView extends kd.CustomHTMLView


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

        { key, qrcode } = authInfo
        @_activeKey     = key

        instructionsView = @getInstructionsView()
        instructionsView.addSubView @getRenewQRCodeLink()
        
        @addSubView @getFormView()
        @addSubView @getQrCodeView qrcode
        @addSubView instructionsView


  getEnabledView: ->

    @addSubView new kd.CustomHTMLView
      cssClass  : 'enabled-intro'
      partial   : "
        <div>
          <p class='status'><strong>ACTIVE</strong> Your 2-factor status</p>
          <p class='info'>To change your code generator you must first disable the current authentication.</p>
        </div>
      "

    @addSubView @disableForm = new kd.FormViewWithFields
      cssClass             : 'AppModal-form enabled-form'
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
          itemClass        : kd.ButtonView
          title            : 'Disable'
          style            : 'solid medium red disable-tf'
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
        tfcode             :
          name             : 'tfcode'
          label            : 'Verification Code'
        password           :
          name             : 'password'
          type             : 'password'
          label            : 'Password'
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
      attributes : { src : url }

    return view


  getRenewQRCodeLink: ->

    new CustomLinkView
      title      : 'RENEW QR'
      cssClass   : 'HomeAppView--link'
      click      : =>
        me = whoami()
        me.generate2FactorAuthKey (err, authInfo) =>

          @showError err

          if authInfo
            @_activeKey = authInfo.key
            imageView.setAttribute 'src', authInfo.qrcode

          kd.utils.defer button.bound 'hideLoader'


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25


  getLearnLink: ->
    "
      <a class='learn-link HomeAppView--link primary' href='https://koding.com/docs/2-factor-auth/' target=_blank>
      LEARN MORE</a>
    "


  getInstructionsView: ->

    new kd.CustomHTMLView
      cssClass : 'instructions'
      partial  : """
        <div class='intro'>
          Use your Keychain or Authenticator App to generate a 6-digit
          Verification Code by scanning this QR: <br />
        </div>
        <ul>
          <li>Open Keychain or App</li>
          <li>Scan QR code</li>
          <li>Enter Verification Code & account password</li>
        </ul>
        #{@getLearnLink()}
      """
