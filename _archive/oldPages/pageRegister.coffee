class PageRegister extends KDView

  KD.registerPage "Register",PageRegister

  viewAppended:()->
    @addSubView header = new KDHeaderView type : "big", title : "Create an account"

    @initForms()
    @registerLists = new KDTabView()
    @registerLists.hideHandleCloseIcons()
    @addSubView @registerLists
    @manageTraditional()

  formSubmit:(formData)=>
    KD.remote.api.JUser.register formData, (error, result) =>
      log arguments
      if error
        new KDNotificationView
          title   : error.message
          duration: 3000
      else
        @handleEvent type: 'NavigationLinkTitleClick', pageName: 'Home', appPath:"Home"
        new KDNotificationView
          title   : 'Good to go!'
          duration: 2000

  initForms:->
    options =
      callback : @formSubmit
      cssClass : "inner-split-pane"

    @formDefault  = new RegisterFormDefault  options
    @formFacebook = new RegisterFormTemplate options, 'facebook'
    @formTwitter  = new RegisterFormTemplate options, 'twitter'
    @formGoogle   = new RegisterFormTemplate options, 'google'
    @formGithub   = new RegisterFormTemplate options, 'github'
    @formDropbox  = new RegisterFormTemplate options, 'dropbox'


  popupWindowOAuth: (url)->
    window.popup.close() if window.popup?
    window.popup = window.open url, 'OAuth', 'location,width=1024,height=768'
    window.popup.focus()
    no

  manageTraditional:()->
    registerTraditional = new RegisterTabs
    @registerLists.addPane registerTraditional
    registerTraditional.setTitle("Traditional way")
    subTitle2 = new KDHeaderView type : "medium", title : "Easier way:"
    externals = new KDCustomHTMLView "div"
    externals.setClass "inner-split-pane"
    externals.addSubView subTitle2
    for provider in ['facebook', 'twitter', 'google', 'github', 'dropbox']
      do (provider)=>
        externals.addSubView new KDButtonView
          domId : "id-register-with-#{provider}"
          title : "Register with #{provider.capitalize()}"
          icon  : yes
          callback:()=>
            @popupWindowOAuth "/auth/#{provider}"
            no

    registerTraditional.splitView @formDefault, externals
    @registerLists.showPane registerTraditional

  manageFacebook:(user, form)->
    unless @registerFacebook?
      @registerFacebook = new RegisterTabs
      @registerLists.addPane @registerFacebook
      @registerFacebook.setTitle("from Facebook")
      #@registerFacebook.addSubView new Facebook_Custom_Button()
      form.addCustomData "authId"       , user.authId
      form.addCustomData "accessToken"  , user.accessToken
      form.addCustomData "accessSecret" , user.accessSecret
      form.inputUsername.setValue    user.username
      form.inputFullname.setValue    user.fullname
      form.inputEmail.setValue       user.email# "#{user.username}@facebook.com"
      @registerFacebook.splitView form
    @registerLists.showPane @registerFacebook

  manageTwitter:(user, form)->
    unless @registerTwitter?
      @registerTwitter = new RegisterTabs
      @registerLists.addPane @registerTwitter
      @registerTwitter.setTitle("from Twitter")
      form.addCustomData "authId"       , user.authId
      form.addCustomData "accessToken"  , user.accessToken
      form.addCustomData "accessSecret" , user.accessSecret
      form.inputUsername.setValue    user.username
      form.inputFullname.setValue    user.fullname
      @registerTwitter.splitView form
    @registerLists.showPane @registerTwitter

  manageGoogle:(user, form)->
    unless @registerGoogle?
      @registerGoogle = new RegisterTabs
      @registerLists.addPane @registerGoogle
      @registerGoogle.setTitle("from Google")
      form.addCustomData "authId"       , user.authId
      form.addCustomData "accessToken"  , user.accessToken
      form.addCustomData "accessSecret" , user.accessSecret
      form.inputUsername.setValue    user.username
      form.inputEmail.setValue       user.email
      @registerGoogle.splitView form
    @registerLists.showPane @registerGoogle

  manageGithub:(user, form)->
    unless @registerGithub?
      @registerGithub = new RegisterTabs
      @registerLists.addPane @registerGithub
      @registerGithub.setTitle("from GitHub")
      form.addCustomData "authId"       , user.authId
      form.addCustomData "accessToken"  , user.accessToken
      form.addCustomData "accessSecret" , user.accessSecret
      form.addCustomData "karmaVal"     , user.karmaVal
      form.addCustomData "karmaId"     , user.karmaId
      form.inputUsername.setValue    user.username
      form.inputEmail.setValue       user.email
      @registerGithub.splitView form
    @registerLists.showPane @registerGithub

  manageDropbox:(user, form)->
    unless @registerDropbox?
      @registerDropbox = new RegisterTabs
      @registerLists.addPane @registerDropbox
      @registerDropbox.setTitle("from DropBox")
      form.addCustomData "authId"       , user.authId
      form.addCustomData "accessToken"  , user.accessToken
      form.addCustomData "accessSecret" , user.accessSecret
      form.inputUsername.setValue    user.username
      form.inputEmail.setValue       user.email
      @registerDropbox.splitView form
    @registerLists.showPane @registerDropbox


  onOAuthSucces: (user, authType)->
    new KDNotificationView
      type    : "tray"
      title   : "Successfully fetched data from #{authType}!"
      duration: 3000
    switch authType
      when 'facebook' then @manageFacebook user, @formFacebook
      when 'twitter'  then @manageTwitter  user, @formTwitter
      when 'google'   then @manageGoogle   user, @formGoogle
      when 'github'   then @manageGithub   user, @formGithub
      when 'dropbox'  then @manageDropbox  user, @formDropbox
      else log 'manage error'

class RegisterTabs extends KDTabPaneView
  constructor:()->
    super null, null
    @split = null

  splitView: (leftSide, rightSide) ->
    rightSide = new KDView() unless rightSide?
    @removeSubView @split if @split?
    @split = new SplitView
      domId     : "register-splitview"
      views     : [leftSide, rightSide]
      resizable : no
    @addSubView @split

class KDHeaderViewSet extends KDHeaderView
  setTitle:(title)->
    @getDomElement().html "<span>#{title}</span>"


class FB_Root extends KDView
  viewAppended:()->
    @setHeight "auto"
    @setPartial @partial()

  partial:()->
    "<div><div id='fb-root'></div><p><fb:login-button autologoutlink='true'></fb:login-button></p></div><script src='http://connect.facebook.net/en_US/all.js'></script>"


class Custom_Button extends KDView
  viewAppended:()->
    @setHeight "auto"
    @setPartial @partial()

class Facebook_Custom_Button extends Custom_Button
  partial:()->
    "<div><div id='fb-root'></div><p><fb:login-button autologoutlink='true'></fb:login-button></p></div><script src='http://connect.facebook.net/en_US/all.js'></script>
    <div>
      <br>
      <a href='javascript:void(0);' onclick=\"javascript:customPopup('/auth/facebook');\">Catch data</a><br>
    </div>"

class Twitter_Custom_Button extends Custom_Button
  partial:()->
    "<div>
      <br>
      <a href='javascript:void(0);' onclick=\"javascript:customPopup('/auth/twitter');\">Catch data</a><br>
    </div>"

class Google_Custom_Button extends Custom_Button
  partial:()->
    "<div>
      <br>
      <a href='javascript:void(0);' onclick=\"javascript:customPopup('/auth/google');\">Catch data</a><br>
    </div>"

class Tweet_Button extends KDView
  viewAppended:()->
    @setHeight "auto"
    @setPartial @partial()

  partial:()->
     "<div><p><div id='register-with-twitter-button'></div></p></div>"

class Google_View extends KDView
  viewAppended:()->
    @setHeight "auto"
    @setPartial @partial()
  partial:()->
     "<a href=\"javascript:poptastic('https://accounts.google.com/o/oauth2/auth?scope=https://www.google.com/m8/feeds&client_id=198089300065.apps.googleusercontent.com&redirect_uri=http://127.0.0.1:3000&response_type=token');\">Try
          out that example URL now</a>"


class RegisterFormTemplate extends KDFormView
  constructor:(options, provider)->
    options.authType = provider
    options.title    = "#{provider.capitalize()} register form:"
    super options
    @addCustomData "authType", options.authType if options.authType?
    title = options.title ? "Traditional way:"
    @addCustomData "agree","on"
    title = new KDHeaderViewSet type : "medium", title : title
    fieldset1 = new KDCustomHTMLView "fieldset"
    fieldset2 = new KDCustomHTMLView "fieldset"
    fieldset3 = new KDCustomHTMLView "fieldset"
    fieldset4 = new KDCustomHTMLView "fieldset"
    @fieldsetCustom = new KDCustomHTMLView "fieldset"
    labelFullname = new KDLabelView
      title : "Fullname:"
    labelEmail = new KDLabelView
      title : "Email address:"
    labelAgree = new KDLabelView
      title : "I agree to the TOS:"
    labelUsername = new KDLabelView
      title : "Username:"
    inputAgree = new KDInputView
       type  : "checkbox"
       label : labelAgree
       name  : "agree"
       # validate  :
       #   rules     : "required"
       #   messages  :
       #     required  : "You need to agree to the Terms of Conditions!"
    @inputFullname = new KDInputView
      label     : labelFullname
      name      : "fullname"
      # validate  :
      #   rules     : "required"
      #   messages  :
      #     required  : "You need to set your full name!"
    @inputEmail = new KDInputView
      label     : labelEmail
      name      : "email"
    @inputUsername = new KDInputView
      label : labelUsername
      name  : "username"
      # validate  :
      #   rules     : "email"

    @addSubView title

    fieldset1.addSubView labelFullname
    fieldset1.addSubView @inputFullname
    @addSubView fieldset1

    fieldset2.addSubView labelEmail
    fieldset2.addSubView @inputEmail
    @addSubView fieldset2

    fieldset3.addSubView labelUsername
    fieldset3.addSubView @inputUsername
    @addSubView fieldset3

    @addSubView @fieldsetCustom

    fieldset4.addSubView labelAgree
    fieldset4.addSubView inputAgree
    @addSubView fieldset4

    @addSubView new KDButtonView
      title       : "Register"
    kdFileUpload = new KDFileUploadView
        limit        : 5
        preview      : "thumbs"
        extensions   : null
        fileMaxSize  : 500
        totalMaxSize : 700
        title        : "Drop a picture of you!"
    @addSubView kdFileUpload

    @inputFullname.setValue "test name"
    @inputEmail.setValue "testmail@mail.ru"



  userProvidedFn : (publishingInstance,event,callback)->
    return yes until callback?
    value = publishingInstance.getValue()
    now.usernameAvailable value, (available)->
      available = !!available and !!value
      publishingInstance.valid = available
      publishingInstance.setValidationResult available, publishingInstance.getOptions().validate.messages.userProvidedFn
      callback available

  extendFields:(fields)->
    @fieldsetCustom.addSubView fields



class RegisterFormDefault extends RegisterFormTemplate
  constructor:(options)->
    super options, 'default'
      # validate  :
      #   event     : "submit"
      #   rules     :
      #     required       : yes
      #     userProvidedFn : @userProvidedFn
      #   messages  :
      #     userProvidedFn : "This username is not available."
      #     required  : "You need to set username!"


    labelPassword = new KDLabelView
      title : "Password:"

    labelConfirmPassword = new KDLabelView
      title : "Confirm Password:"
    inputPassword = new KDInputView
      label : labelPassword
      name  : "password"
      type  : "password"
      # validate  :
      #   rules     :
      #     minLength : 8
      #   messages  :
      #     minLength : "Password should be more than 8 characters long."


    inputConfirmPassword = new KDInputView
      label : labelConfirmPassword
      name  : "password_confirm"
      type  : "password"
      # validate  :
      #   rules     :
      #     match     : inputPassword
      #   messages  :
      #     minLength : "Password should be more than 8 characters long."
      #     match     : "Passwords should match each other!"

    fields = new KDView()
    # fields.addSubView labelUsername
    # fields.addSubView @inputUsername
    fields.addSubView labelPassword
    fields.addSubView inputPassword
    fields.addSubView labelConfirmPassword
    fields.addSubView inputConfirmPassword

    @extendFields fields

    @inputUsername.setValue "user241234qw53"



# class PageRegisterBongo extends KDView
#
#   KD.registerPage "RegisterBongo",PageRegisterBongo
#
#   viewAppended:->
#     # @setPartial "here you go"
#     @addSubView newRegisterForm = new KDFormView
#       callback : @formSubmit
#
#     newRegisterForm.addSubView labelEmail = new KDLabelView
#       title : "Email:"
#     newRegisterForm.addSubView inputEmail = new KDInputView
#       label : labelEmail
#       name  : "email"
#       validate  :
#         rules     : "email"
#
#     newRegisterForm.addSubView labelUsername = new KDLabelView
#       title : "Username:"
#     newRegisterForm.addSubView inputUsername = new KDInputView
#       label : labelUsername
#       name  : "username"
#
#     newRegisterForm.addSubView labelPassword = new KDLabelView
#       title : "Password:"
#     newRegisterForm.addSubView inputPassword = new KDInputView
#       label : labelPassword
#       name  : "password"
#       type  : "password"
#       # validate  :
#       #   rules     :
#       #     minLength : 8
#       #   messages  :
#       #     minLength : "Password should be more than 8 characters long."
#
#     newRegisterForm.addSubView submit = new KDButtonView
#       title    : "register"
#
#   formSubmit:(formData,event)=>
#     log formData,"<<<<<<<< KD SUBMIT"
#
#     KD.remote.api.JUser.register formData, (err)->
#       log err

    #user.save (err,docs)->
    #  log err,docs,">>>>>>>>>> BONGO RESULT"
    #

    # KD.remote.api.Site.login credentials,(result)=>
    #   log "login response :",result
    #   if result.success
    #     new KDNotificationView
    #       title   : "Successfully logged in!"
    #       duration: 1000
    #     @getSingleton("site").refreshAccount()
    #   else
    #     new KDNotificationView
    #       title   : result.error.message
    #       content : result.error.stack
    #       duration: 5000
    #       overlay : yes
