var LoginAppsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginAppsController=function(_super){function LoginAppsController(options,data){null==options&&(options={})
options.view=new LoginView({testPath:"landing-login"})
options.appInfo={name:"Login"}
LoginAppsController.__super__.constructor.call(this,options,data)}var handleFinishRegistration,handleResetRoute,handler
__extends(LoginAppsController,_super)
handler=function(callback){return function(){return KD.isLoggedIn()?KD.getSingleton("router").handleRoute("/Activity"):KD.singleton("appManager").open("Login",function(app){return callback(app)})}}
handleResetRoute=function(_arg){var token
token=_arg.params.token
return KD.singleton("appManager").open("Login",function(app){if(KD.isLoggedIn())return KD.getSingleton("router").handleRoute("/Account/Profile?focus=password&token="+token)
app.getView().setCustomDataToForm("reset",{recoveryToken:token})
return app.getView().animateToForm("reset")})}
handleFinishRegistration=function(_arg){var token
token=_arg.params.token
return KD.singleton("appManager").open("Login",function(app){return KD.isLoggedIn()?void 0:app.prepareFinishRegistrationForm(token)})}
KD.registerAppClass(LoginAppsController,{name:"Login",routes:{"/:name?/Login/:token?":handler(function(app){return app.getView().animateToForm("login")}),"/:name?/Redeem":handler(function(app){return app.getView().animateToForm("redeem")}),"/:name?/Register/:token?":handler(function(app){return app.getView().animateToForm("register")}),"/:name?/Recover":handler(function(app){return app.getView().animateToForm("recover")}),"/:name?/Reset":handler(function(app){return app.getView().animateToForm("reset")}),"/:name?/Reset/:token":handleResetRoute,"/:name?/Confirm/:token":handleResetRoute,"/:name?/ResendToken":handler(function(app){return app.getView().animateToForm("resendEmail")})},hiddenHandle:!0,behavior:"application"})
LoginAppsController.prototype.prepareFinishRegistrationForm=function(token){var JPasswordRecovery,_this=this
JPasswordRecovery=KD.remote.api.JPasswordRecovery
return JPasswordRecovery.fetchRegistrationDetails(token,function(err,details){var view
if(!KD.showError(err)){view=_this.getView()
view.finishRegistrationForm.setRegistrationDetails(details)
view.setCustomDataToForm("finishRegistration",{recoveryToken:token})
return view.animateToForm("finishRegistration")}})}
return LoginAppsController}(AppController)

var LoginView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginView=function(_super){function LoginView(options,data){var entryPoint,handler,homeHandler,loginHandler,mainController,recoverHandler,registerHandler,setValue,_this=this
null==options&&(options={})
entryPoint=KD.config.entryPoint
options.cssClass="hidden"
LoginView.__super__.constructor.call(this,options,data)
this.setCss("background-image","url('../images/unsplash/"+backgroundImageNr+".jpg')")
this.hidden=!0
handler=function(route,event){stop(event)
return KD.getSingleton("router").handleRoute(route,{entryPoint:entryPoint})}
homeHandler=handler.bind(null,"/")
loginHandler=handler.bind(null,"/Login")
registerHandler=handler.bind(null,"/Register")
recoverHandler=handler.bind(null,"/Recover")
this.logo=new KDCustomHTMLView({cssClass:"logo",partial:"Koding<cite></cite>",click:homeHandler})
this.backToLoginLink=new KDCustomHTMLView({tagName:"a",partial:"Sign In",click:loginHandler})
this.goToRecoverLink=new KDCustomHTMLView({tagName:"a",partial:"Forgot your password?",testPath:"landing-recover-password",click:recoverHandler})
this.goToRegisterLink=new KDCustomHTMLView({tagName:"a",partial:"Create Account",click:registerHandler})
this.github=new KDButtonView({title:"Sign in with GitHub",style:"solid github",icon:!0,callback:function(){return KD.singletons.oauthController.openPopup("github")}})
this.github.setPartial("<span class='button-arrow'></span>")
this.loginForm=new LoginInlineForm({cssClass:"login-form",testPath:"login-form",callback:function(formData){return _this.doLogin(formData)}})
this.registerForm=new RegisterInlineForm({cssClass:"login-form",testPath:"register-form",callback:function(formData){_this.doRegister(formData)
return KD.mixpanel("RegisterButtonClicked")}})
this.redeemForm=new RedeemInlineForm({cssClass:"login-form",callback:function(formData){_this.doRedeem(formData)
return KD.mixpanel("RedeemButtonClicked")}})
this.recoverForm=new RecoverInlineForm({cssClass:"login-form",callback:function(formData){return _this.doRecover(formData)}})
this.resendForm=new ResendEmailConfirmationLinkInlineForm({cssClass:"login-form",callback:function(formData){_this.resendEmailConfirmationToken(formData)
return KD.track("Login","ResendEmailConfirmationTokenButtonClicked")}})
this.resetForm=new ResetInlineForm({cssClass:"login-form",callback:function(formData){return _this.doReset(formData)}})
this.finishRegistrationForm=new FinishRegistrationForm({cssClass:"login-form foobar",callback:function(formData){return _this.doFinishRegistration(formData)}})
this.headBanner=new KDCustomHTMLView({domId:"invite-recovery-notification-bar",cssClass:"invite-recovery-notification-bar hidden",partial:"..."})
KD.getSingleton("mainController").on("landingSidebarClicked",function(){return _this.unsetClass("landed")})
setValue=function(field,value){var _ref
return null!=(_ref=_this.registerForm[field].input)?_ref.setValue(value):void 0}
mainController=KD.getSingleton("mainController")
mainController.on("ForeignAuthCompleted",function(provider){var isUserLoggedIn,params
isUserLoggedIn=KD.isLoggedIn()
params={isUserLoggedIn:isUserLoggedIn,provider:provider}
return KD.getSingleton("mainController").handleOauthAuth(params,function(err,resp){var account,field,isNewUser,replacementToken,userInfo,value
if(err)return showError(err)
account=resp.account,replacementToken=resp.replacementToken,isNewUser=resp.isNewUser,userInfo=resp.userInfo
if(isNewUser){KD.getSingleton("router").handleRoute("/Register")
_this.animateToForm("register")
for(field in userInfo)if(__hasProp.call(userInfo,field)){value=userInfo[field]
setValue(field,value)}}else if(isUserLoggedIn){mainController.emit("ForeignAuthSuccess."+provider)
new KDNotificationView({title:"Your "+provider.capitalize()+" account has been linked.",type:"mini"})}else _this.afterLoginCallback(err,{account:account,replacementToken:replacementToken})
return KD.mixpanel("Authenticated oauth",{provider:provider})})})}var backgroundImageNr,backgroundImages,runExternal,showError,stop
__extends(LoginView,_super)
stop=KD.utils.stopDOMEvent
backgroundImageNr=KD.utils.getRandomNumber(15)
backgroundImages=[{path:"1",href:"http://www.flickr.com/photos/charliefoster/",photographer:"Charlie Foster"},{path:"2",href:"http://pican.de/",photographer:"Dietmar Becker"},{path:"3",href:"http://www.station75.com/",photographer:"Marcin Czerwinski"},{path:"4",href:"http://www.station75.com/",photographer:"Marcin Czerwinski"},{path:"5",href:"http://www.flickr.com/photos/discomethod/sets/72157635620513053/",photographer:"Anton Sulsky"},{path:"6",href:"http://www.jfrwebdesign.nl/",photographer:"Joeri Römer"},{path:"7",href:"http://be.net/Zugr",photographer:"Zugr"},{path:"8",href:"",photographer:"Mark Doda"},{path:"9",href:"http://www.twitter.com/rickwaalders",photographer:"Rick Waalders"},{path:"10",href:"http://madebyvadim.com/",photographer:"Vadim Sherbakov"},{path:"11",href:"",photographer:"Zwaddi"},{path:"12",href:"http://be.net/Zugr",photographer:"Zugr"},{path:"13",href:"http://www.romainbriaux.fr/",photographer:"Romain Briaux"},{path:"14",href:"https://twitter.com/Petchy19",photographer:"petradr"},{path:"15",href:"http://rileyb.me/",photographer:"Riley Briggs"},{path:"16",href:"http://chloecolorphotography.tumblr.com/",photographer:"Chloe Benko-Prieur"}]
LoginView.prototype.viewAppended=function(){this.setClass("login-screen login")
this.setTemplate(this.pistachio())
return this.template.update()}
LoginView.prototype.pistachio=function(){return'<div class=\'tint\'></div>\n<div class="flex-wrapper">\n  <div class="login-box-header">\n    <a class="betatag">beta</a>\n    {{> this.logo}}\n  </div>\n  <div class="login-form-holder lf">\n    {{> this.loginForm}}\n  </div>\n  <div class="login-form-holder rf">\n    {{> this.registerForm}}\n  </div>\n  <div class="login-form-holder frf">\n    {{> this.finishRegistrationForm}}\n  </div>\n  <div class="login-form-holder rdf">\n    {{> this.redeemForm}}\n  </div>\n  <div class="login-form-holder rcf">\n    {{> this.recoverForm}}\n  </div>\n  <div class="login-form-holder rsf">\n    {{> this.resetForm}}\n  </div>\n  <div class="login-form-holder resend-confirmation-form">\n    {{> this.resendForm}}\n  </div>\n  <div class="login-footer">\n    <div class=\'first-row clearfix\'>\n      <div class=\'fl\'>{{> this.goToRecoverLink}}</div><div class=\'fr\'>{{> this.goToRegisterLink}}<i>•</i>{{> this.backToLoginLink}}</div>\n    </div>\n    {{> this.github}}\n  </div>\n</div>\n<footer>\n  <a href="/tos.html" target="_blank">Terms of service</a><i>•</i><a href="/privacy.html" target="_blank">Privacy policy</a><i>•</i><a href="'+backgroundImages[backgroundImageNr].href+'" target="_blank"><span>photo by </span>'+backgroundImages[backgroundImageNr].photographer+"</a>\n</footer>"}
LoginView.prototype.doReset=function(_arg){var password,recoveryToken,_this=this
recoveryToken=_arg.recoveryToken,password=_arg.password
return KD.remote.api.JPasswordRecovery.resetPassword(recoveryToken,password,function(err,username){if(err)return new KDNotificationView({title:"An error occurred: "+err.message})
_this.resetForm.button.hideLoader()
_this.resetForm.reset()
_this.headBanner.hide()
return _this.doLogin({username:username,password:password})})}
LoginView.prototype.doRecover=function(formData){var _this=this
return KD.remote.api.JPasswordRecovery.recoverPassword(formData["username-or-email"],function(err){var entryPoint
_this.recoverForm.button.hideLoader()
if(err)return new KDNotificationView({title:"An error occurred: "+err.message})
_this.recoverForm.reset()
entryPoint=KD.config.entryPoint
KD.getSingleton("router").handleRoute("/Login",{entryPoint:entryPoint})
return new KDNotificationView({title:"Check your email",content:"We've sent you a password recovery token.",duration:4500})})}
LoginView.prototype.resendEmailConfirmationToken=function(formData){var _this=this
return KD.remote.api.JPasswordRecovery.recoverPassword(formData["username-or-email"],function(err){var entryPoint
_this.resendForm.button.hideLoader()
if(err)return new KDNotificationView({title:"An error occurred: "+err.message})
_this.resendForm.reset()
entryPoint=KD.config.entryPoint
KD.getSingleton("router").handleRoute("/Login",{entryPoint:entryPoint})
return new KDNotificationView({title:"Check your email",content:"We've sent you a confirmation mail.",duration:4500})})}
LoginView.prototype.doRegister=function(formData){var _ref,_ref1,_this=this
KD.getSingleton("mainController").isLoggingIn(!0)
formData.agree="on"
formData.referrer=$.cookie("referrer")
this.registerForm.notificationsDisabled=!0
null!=(_ref=this.registerForm.notification)&&_ref.destroy()
null!=(_ref1=KD.getSingleton("groupsController").groupChannel)&&_ref1.close()
return KD.remote.api.JUser.convert(formData,function(err,replacementToken){var account,message
account=KD.whoami()
_this.registerForm.button.hideLoader()
if(err){message=err.message
warn("An error occured while registering:",err)
_this.registerForm.notificationsDisabled=!1
return _this.registerForm.emit("SubmitFailed",message)}KD.mixpanel.alias(account.profile.nickname)
$.cookie("newRegister",!0)
$.cookie("clientId",replacementToken)
KD.getSingleton("mainController").accountChanged(account)
new KDNotificationView({cssClass:"login",title:"<span></span>Good to go, Enjoy!",duration:2e3})
KD.getSingleton("router").clear()
return setTimeout(function(){_this.hide()
_this.registerForm.reset()
return _this.registerForm.button.hideLoader()},1e3)})}
LoginView.prototype.doFinishRegistration=function(formData){return KD.getSingleton("mainController").handleFinishRegistration(formData,this.bound("afterLoginCallback"))}
LoginView.prototype.doLogin=function(credentials){return KD.getSingleton("mainController").handleLogin(credentials,this.bound("afterLoginCallback"))}
runExternal=function(token){KD.getSingleton("kiteController").run({kiteName:"externals",method:"import",correlationName:" ",withArgs:{value:token,serviceName:"github",userId:KD.whoami().getId()}})
return function(err,status){return console.log("Status of fetching stuff from external: "+status)}}
LoginView.prototype.afterLoginCallback=function(err,params){var account,entryPoint,firstRoute,mainController,mainView,replacementToken,_this=this
null==params&&(params={})
this.loginForm.button.hideLoader()
entryPoint=KD.config.entryPoint
if(err){showError(err)
this.loginForm.resetDecoration()
this.$(".flex-wrapper").removeClass("shake")
return KD.utils.defer(function(){return _this.$(".flex-wrapper").addClass("animate shake")})}account=params.account,replacementToken=params.replacementToken
replacementToken&&$.cookie("clientId",replacementToken)
account&&KD.utils.setPreferredDomain(account)
mainController=KD.getSingleton("mainController")
mainView=mainController.mainViewController.getView()
mainView.show()
mainView.$().css("opacity",1)
firstRoute=KD.getSingleton("router").visitedRoutes.first
firstRoute&&/^\/(?:Reset|Register|Confirm)\//.test(firstRoute)&&(firstRoute="/")
KD.getSingleton("appManager").quitAll()
KD.getSingleton("router").handleRoute(firstRoute||"/Activity",{replaceState:!0,entryPoint:entryPoint})
KD.getSingleton("groupsController").on("GroupChanged",function(){new KDNotificationView({cssClass:"login",title:"<span></span>Happy Coding!",duration:2e3})
return _this.loginForm.reset()})
new KDNotificationView({cssClass:"login",title:"<span></span>Happy Coding!",duration:2e3})
this.loginForm.reset()
this.hide()
return KD.mixpanel("Logged in")}
LoginView.prototype.doRedeem=function(_arg){var inviteCode,_ref,_this=this
inviteCode=_arg.inviteCode
return(null!=(_ref=KD.config.entryPoint)?_ref.slug:void 0)||KD.isLoggedIn()?KD.remote.cacheable(KD.config.entryPoint.slug,function(err,_arg1){var group
group=_arg1[0]
return group.redeemInvitation(inviteCode,function(err){_this.redeemForm.button.hideLoader()
if(err)return KD.notify_(err.message||err)
KD.notify_("Success!")
return KD.getSingleton("mainController").accountChanged(KD.whoami())})}):void 0}
LoginView.prototype.showHeadBanner=function(message,callback){this.headBannerMsg=message
this.headBanner.updatePartial(this.headBannerMsg)
this.headBanner.unsetClass("hidden")
this.headBanner.setClass("show")
$("body").addClass("recovery")
return this.headBanner.click=callback}
LoginView.prototype.headBannerShowGoBackGroup=function(groupTitle){var _this=this
return this.showHeadBanner("<span>Go Back to</span> "+groupTitle,function(){_this.headBanner.hide()
$("#group-landing").css("height","100%")
return $("#group-landing").css("opacity",1)})}
LoginView.prototype.headBannerShowInvitation=function(invite){var _this=this
return this.showHeadBanner("Cool! you got an invite! <span>Click here to register your account.</span>",function(){_this.headBanner.hide()
KD.getSingleton("router").clear(_this.getRouteWithEntryPoint("Register"))
$("body").removeClass("recovery")
return _this.show(function(){_this.animateToForm("register")
_this.$(".flex-wrapper").addClass("taller")
return KD.getSingleton("mainController").emit("InvitationReceived",invite)})})}
LoginView.prototype.hide=function(callback){this.$(".flex-wrapper").removeClass("expanded")
this.emit("LoginViewHidden")
this.setClass("hidden")
"function"==typeof callback&&callback()
return KD.mixpanel("Cancelled Login/Register")}
LoginView.prototype.show=function(callback){this.unsetClass("hidden")
this.emit("LoginViewShown")
this.hidden=!1
return"function"==typeof callback?callback():void 0}
LoginView.prototype.setCustomDataToForm=function(type,data){var formName
formName=""+type+"Form"
return this[formName].addCustomData(data)}
LoginView.prototype.animateToForm=function(name){var _this=this
return this.show(function(){var _ref
switch(name){case"register":KD.remote.api.JUser.isRegistrationEnabled(function(status){if(status===!1){log("Registrations are disabled!!!")
_this.registerForm.$(".main-part").addClass("hidden")
return _this.registerForm.disabledNotice.show()}_this.registerForm.disabledNotice.hide()
return _this.registerForm.$(".main-part").removeClass("hidden")})
KD.mixpanel("Opened register form")
break
case"home":null!=(_ref=parent.notification)&&_ref.destroy()
if(null!=_this.headBannerMsg){_this.headBanner.updatePartial(_this.headBannerMsg)
_this.headBanner.show()}}_this.unsetClass("register recover login reset home resendEmail finishRegistration")
_this.emit("LoginViewAnimated",name)
_this.setClass(name)
_this.$(".flex-wrapper").removeClass("three one")
switch(name){case"register":return _this.registerForm.email.input.setFocus()
case"finishRegistration":return _this.finishRegistrationForm.username.input.setFocus()
case"redeem":_this.$(".flex-wrapper").addClass("one")
return _this.redeemForm.inviteCode.input.setFocus()
case"login":return _this.loginForm.username.input.setFocus()
case"recover":_this.$(".flex-wrapper").addClass("one")
return _this.recoverForm.usernameOrEmail.input.setFocus()
case"resendEmail":_this.$(".flex-wrapper").addClass("one")
return _this.resendForm.usernameOrEmail.input.setFocus()}})}
LoginView.prototype.getRouteWithEntryPoint=function(route){var entryPoint
entryPoint=KD.config.entryPoint
return entryPoint&&entryPoint.slug!==KD.defaultSlug?"/"+entryPoint.slug+"/"+route:"/"+route}
showError=function(err){var name,nickname,_ref
if("CONFIRMATION_WAITING"===err.message){_ref=err.data,name=_ref.name,nickname=_ref.nickname
return KD.getSingleton("appManager").tell("Account","displayConfirmEmailModal",name,nickname)}return err.message.length>50?new KDModalView({title:"Something is wrong!",width:500,overlay:!0,cssClass:"new-kdmodal",content:"<div class='modalformline'>"+err.message+"</div>"}):new KDNotificationView({title:err.message,duration:1e3})}
return LoginView}(KDView)

var LoginInlineForm,LoginViewInlineForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginViewInlineForm=function(_super){function LoginViewInlineForm(){_ref=LoginViewInlineForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(LoginViewInlineForm,_super)
LoginViewInlineForm.prototype.viewAppended=function(){var _this=this
this.setTemplate(this.pistachio())
this.template.update()
return this.on("FormValidationFailed",function(){return _this.button.hideLoader()})}
LoginViewInlineForm.prototype.pistachio=function(){}
return LoginViewInlineForm}(KDFormView)
LoginInlineForm=function(_super){function LoginInlineForm(){LoginInlineForm.__super__.constructor.apply(this,arguments)
this.username=new LoginInputView({inputOptions:{name:"username",forceCase:"lowercase",placeholder:"username",testPath:"login-form-username",validate:{event:"blur",rules:{required:!0},messages:{required:"Please enter a username."}}}})
this.password=new LoginInputView({inputOptions:{name:"password",type:"password",placeholder:"password",testPath:"login-form-password",validate:{event:"blur",rules:{required:!0},messages:{required:"Please enter your password."}}}})
this.button=new KDButtonView({title:"SIGN ME IN",style:"solid green",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(LoginInlineForm,_super)
LoginInlineForm.prototype.activate=function(){return this.username.setFocus()}
LoginInlineForm.prototype.resetDecoration=function(){this.username.resetDecoration()
return this.password.resetDecoration()}
LoginInlineForm.prototype.pistachio=function(){return"<div>{{> this.username}}</div>\n<div>{{> this.password}}</div>\n<div>{{> this.button}}</div>"}
return LoginInlineForm}(LoginViewInlineForm)

var LoginInputView,LoginInputViewWithLoader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginInputView=function(_super){function LoginInputView(options,data){var inputOptions,placeholder,validate
null==options&&(options={})
inputOptions=options.inputOptions
options.cssClass=KD.utils.curry("login-input-view",options.cssClass)
inputOptions||(inputOptions={})
inputOptions.cssClass=KD.utils.curry("thin",inputOptions.cssClass)
placeholder=inputOptions.placeholder,validate=inputOptions.validate
delete inputOptions.placeholder
delete options.inputOptions
validate&&(validate.notifications=!1)
LoginInputView.__super__.constructor.call(this,options,null)
this.input=new KDInputView(inputOptions,data)
this.icon=new KDCustomHTMLView({cssClass:"validation-icon"})
this.placeholder=new KDCustomHTMLView({cssClass:"placeholder-helper",partial:placeholder||inputOptions.name})
this.errors={}
this.errorMessage=""
this.input.on("keyup",this.bound("inputReceivedKeyup"))
this.input.on("focus",this.bound("inputReceivedFocus"))
this.input.on("blur",this.bound("inputReceivedBlur"))
this.input.on("ValidationError",this.bound("decorateValidation"))
this.input.on("ValidationPassed",this.bound("decorateValidation"))
this.input.on("ValidationFeedbackCleared",this.bound("resetDecoration"))}__extends(LoginInputView,_super)
LoginInputView.prototype.setFocus=function(){return this.input.setFocus()}
LoginInputView.prototype.inputReceivedKeyup=function(){return this.input.getValue().length>0?this.placeholder.setClass("out"):this.placeholder.unsetClass("out")}
LoginInputView.prototype.inputReceivedFocus=function(){return this.input.getValue().length>0?this.placeholder.unsetClass("puff"):void 0}
LoginInputView.prototype.inputReceivedBlur=function(){return this.input.getValue().length>0?this.placeholder.setClass("puff"):this.placeholder.unsetClass("puff")}
LoginInputView.prototype.resetDecoration=function(){return this.unsetClass("validation-error validation-passed")}
LoginInputView.prototype.decorateValidation=function(err){this.resetDecoration()
err?this.icon.setTooltip({title:"<p>"+err+"</p>"}):this.icon.unsetTooltip()
return this.setClass(err?"validation-error":"validation-passed")}
LoginInputView.prototype.pistachio=function(){return"{{> this.input}}{{> this.placeholder}}{{> this.icon}}"}
return LoginInputView}(JView)
LoginInputViewWithLoader=function(_super){function LoginInputViewWithLoader(){LoginInputViewWithLoader.__super__.constructor.apply(this,arguments)
this.loader=new KDLoaderView({cssClass:"input-loader",size:{width:32,height:32},loaderOptions:{color:"#3E4F55"}})
this.loader.hide()}__extends(LoginInputViewWithLoader,_super)
LoginInputViewWithLoader.prototype.pistachio=function(){return"{{> this.input}}{{> this.loader}}{{> this.placeholder}}{{> this.icon}}"}
return LoginInputViewWithLoader}(LoginInputView)

var LoginOptions,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginOptions=function(_super){function LoginOptions(){_ref=LoginOptions.__super__.constructor.apply(this,arguments)
return _ref}__extends(LoginOptions,_super)
LoginOptions.prototype.viewAppended=function(){var inFrame,optionsHolder
inFrame=KD.runningInFrame()
this.addSubView(new KDHeaderView({type:"small",title:"SIGN IN WITH:"}))
this.addSubView(optionsHolder=new KDCustomHTMLView({tagName:"ul",cssClass:"login-options"}))
optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"koding active",partial:"koding",tooltip:{title:"<p class='login-tip'>Sign in with Koding</p>"}}))
return optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"github "+(inFrame?"hidden":void 0),partial:"github",click:function(){return new KDNotificationView({title:"Login restricted"})},tooltip:{title:"<p class='login-tip'>Sign in with GitHub</p>"}}))}
return LoginOptions}(KDView)

var RegisterOptions,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RegisterOptions=function(_super){function RegisterOptions(){_ref=RegisterOptions.__super__.constructor.apply(this,arguments)
return _ref}__extends(RegisterOptions,_super)
RegisterOptions.prototype.viewAppended=function(){var inFrame,optionsHolder
inFrame=KD.runningInFrame()
this.addSubView(optionsHolder=new KDCustomHTMLView({tagName:"ul",cssClass:"login-options"}))
optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"koding active",partial:"koding",tooltip:{title:"<p class='login-tip'>Register with Koding</p>"}}))
return optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"github active "+(inFrame?"hidden":void 0),partial:"github",click:function(){return KD.getSingleton("oauthController").openPopup("github")},tooltip:{title:"<p class='login-tip'>Register with GitHub</p>"}}))}
return RegisterOptions}(KDView)

var ResendEmailConfirmationLinkInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ResendEmailConfirmationLinkInlineForm=function(_super){function ResendEmailConfirmationLinkInlineForm(){ResendEmailConfirmationLinkInlineForm.__super__.constructor.apply(this,arguments)
this.usernameOrEmail=new LoginInputView({inputOptions:{name:"username-or-email",placeholder:"username or email",testPath:"recover-password-input",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your username or email."}}}})
this.button=new KDButtonView({title:"RESEND EMAIL",style:"solid green",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(ResendEmailConfirmationLinkInlineForm,_super)
ResendEmailConfirmationLinkInlineForm.prototype.pistachio=function(){return"<div>{{> this.usernameOrEmail}}</div>\n<div>{{> this.button}}</div>"}
return ResendEmailConfirmationLinkInlineForm}(LoginViewInlineForm)

var RegisterInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RegisterInlineForm=function(_super){function RegisterInlineForm(options,data){var _this=this
null==options&&(options={})
RegisterInlineForm.__super__.constructor.call(this,options,data)
this.email=new LoginInputViewWithLoader({inputOptions:{name:"email",placeholder:"email address",testPath:"register-form-email",validate:this.getEmailValidator(),blur:function(input){return _this.utils.defer(function(){return _this.userAvatarFeedback(input)})}}})
this.avatar=new AvatarStaticView({size:{width:55,height:55}},{profile:{hash:md5.digest("there is no such email"),firstName:"New koding user"}})
this.avatar.hide()
this.username=new LoginInputViewWithLoader({inputOptions:{name:"username",forceCase:"lowercase",placeholder:"username",testPath:"register-form-username",keyup:function(){var val
return""!==(val=_this.username.input.getValue()).trim()?_this.domain.updatePartial(""+val+".kd.io"):_this.domain.updatePartial("username.kd.io")},validate:{container:this,rules:{required:!0,rangeLength:[4,25],regExp:/^[a-z\d]+([-][a-z\d]+)*$/i,usernameCheck:function(input,event){return _this.usernameCheck(input,event)},finalCheck:function(input,event){return _this.usernameCheck(input,event,0)}},messages:{required:"Please enter a username.",regExp:"For username only lowercase letters and numbers are allowed!",rangeLength:"Username should be between 4 and 25 characters!"},events:{required:"blur",rangeLength:"keyup",regExp:"keyup",usernameCheck:"keyup",finalCheck:"blur"}}}})
this.button=new KDButtonView({title:"CREATE ACCOUNT",type:"submit",style:"solid green",loader:{color:"#ffffff",diameter:21}})
this.disabledNotice=new KDCustomHTMLView({tagName:"section",cssClass:"disabled-notice",partial:"<p>\n<b>REGISTRATIONS ARE CURRENTLY DISABLED</b>\nWe're sorry for that, please follow us on <a href='http://twitter.com/koding' target='_blank'>twitter</a>\nif you want to be notified when registrations are enabled again.\n</p>"})
this.invitationCode=new LoginInputView({cssClass:"hidden",inputOptions:{name:"inviteCode",type:"hidden"}})
this.domain=new KDCustomHTMLView({tagName:"strong",partial:"username.kd.io"})
this.on("SubmitFailed",function(){return _this.button.hideLoader()})}var usernameCheckTimer
__extends(RegisterInlineForm,_super)
usernameCheckTimer=null
RegisterInlineForm.prototype.reset=function(){var input,inputs,_i,_len
inputs=KDFormView.findChildInputs(this)
for(_i=0,_len=inputs.length;_len>_i;_i++){input=inputs[_i]
input.clearValidationFeedback()}return RegisterInlineForm.__super__.reset.apply(this,arguments)}
RegisterInlineForm.prototype.usernameCheck=function(input,event,delay){var name,_this=this
null==delay&&(delay=800)
if(9!==(null!=event?event.which:void 0)&&!(input.getValue().length<4)){clearTimeout(usernameCheckTimer)
input.setValidationResult("usernameCheck",null)
name=input.getValue()
return input.valid?usernameCheckTimer=setTimeout(function(){_this.username.loader.show()
return KD.remote.api.JUser.usernameAvailable(name,function(err,response){var forbidden,kodingUser
_this.username.loader.hide()
kodingUser=response.kodingUser,forbidden=response.forbidden
return err?(null!=response?response.kodingUser:void 0)?input.setValidationResult("usernameCheck",'Sorry, "'+name+'" is already taken!'):void 0:forbidden?input.setValidationResult("usernameCheck",'Sorry, "'+name+'" is forbidden to use!'):kodingUser?input.setValidationResult("usernameCheck",'Sorry, "'+name+'" is already taken!'):input.setValidationResult("usernameCheck",null)})},delay):void 0}}
RegisterInlineForm.prototype.userAvatarFeedback=function(input){if(input.valid){this.avatar.setData({profile:{hash:md5.digest(input.getValue()),firstName:"New koding user"}})
this.avatar.render()
return this.showUserAvatar()}return this.hideUserAvatar()}
RegisterInlineForm.prototype.showUserAvatar=function(){return this.avatar.show()}
RegisterInlineForm.prototype.hideUserAvatar=function(){return this.avatar.hide()}
RegisterInlineForm.prototype.viewAppended=function(){var _this=this
RegisterInlineForm.__super__.viewAppended.apply(this,arguments)
return KD.getSingleton("mainController").on("InvitationReceived",function(invite){var origin
_this.$(".invitation-field").addClass("hidden")
_this.$(".invited-by").removeClass("hidden")
origin=invite.origin
_this.invitationCode.input.setValue(invite.code)
_this.email.input.setValue(invite.email)
return"JAccount"===origin.constructorName?KD.remote.cacheable([origin],function(err,_arg){var account
account=_arg[0]
_this.addSubView(new AvatarStaticView({size:{width:30,height:30}},account),".invited-by .wrapper")
return _this.addSubView(new ProfileTextView({},account),".invited-by .wrapper")}):_this.$(".invited-by").addClass("hidden")})}
RegisterInlineForm.prototype.getEmailValidator=function(){var _this=this
return{container:this,event:"blur",rules:{required:!0,email:!0,available:function(input,event){var email
if(9!==(null!=event?event.which:void 0)){input.setValidationResult("available",null)
email=input.getValue()
if(input.valid){_this.email.loader.show()
KD.remote.api.JUser.emailAvailable(email,function(err,response){_this.email.loader.hide()
if(err)return warn(err)
response?input.setValidationResult("available",null):input.setValidationResult("available",'Sorry, "'+email+'" is already in use!')
return _this.userAvatarFeedback(input)})}}}},messages:{required:"Please enter your email address.",email:"That doesn't seem like a valid email address."}}}
RegisterInlineForm.prototype.pistachio=function(){return"<section class='main-part'>\n  <div class='email'>{{> this.avatar}}{{> this.email}}</div>\n  <div class='username'>{{> this.username}}</div>\n  <div class='invitation-field invited-by hidden'>\n    <span class='icon'></span>\n    Invited by:\n    <span class='wrapper'></span>\n  </div>\n  <div class='hint'>Your username must be at least 4 characters and it’s also going to be your {{> this.domain}} domain.</div>\n  <div>{{> this.button}}</div>\n</section>\n{{> this.invitationCode}}\n{{> this.disabledNotice}}"}
return RegisterInlineForm}(LoginViewInlineForm)

var RecoverInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RecoverInlineForm=function(_super){function RecoverInlineForm(){RecoverInlineForm.__super__.constructor.apply(this,arguments)
this.usernameOrEmail=new LoginInputView({inputOptions:{name:"username-or-email",placeholder:"username or email",testPath:"recover-password-input",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your username or email."}}}})
this.button=new KDButtonView({title:"RECOVER PASSWORD",style:"solid green",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(RecoverInlineForm,_super)
RecoverInlineForm.prototype.pistachio=function(){return"<div>{{> this.usernameOrEmail}}</div>\n<div>{{> this.button}}</div>"}
return RecoverInlineForm}(LoginViewInlineForm)

var ResetInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ResetInlineForm=function(_super){function ResetInlineForm(){ResetInlineForm.__super__.constructor.apply(this,arguments)
this.password=new LoginInputView({inputOptions:{name:"password",type:"password",testPath:"recover-password",placeholder:"Enter a new password",validate:{container:this,rules:{required:!0,minLength:8},messages:{required:"Please enter a password.",minLength:"Passwords should be at least 8 characters."}}}})
this.passwordConfirm=new LoginInputView({inputOptions:{name:"passwordConfirm",type:"password",testPath:"recover-password-confirm",placeholder:"Confirm your password",validate:{container:this,rules:{required:!0,match:this.password.input,minLength:8},messages:{required:"Please confirm your password.",match:"Password confirmation doesn't match!"}}}})
this.button=new KDButtonView({title:"RESET PASSWORD",style:"thin",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(ResetInlineForm,_super)
ResetInlineForm.prototype.pistachio=function(){return"<div class='login-hint'>Set your new password below.</div>\n<div>{{> this.password}}</div>\n<div>{{> this.passwordConfirm}}</div>\n<div>{{> this.button}}</div>"}
return ResetInlineForm}(LoginViewInlineForm)

var FinishRegistrationForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FinishRegistrationForm=function(_super){function FinishRegistrationForm(){FinishRegistrationForm.__super__.constructor.apply(this,arguments)
this.email.input.setAttribute("readonly","true")
this.password=new LoginInputView({inputOptions:{name:"password",type:"password",testPath:"recover-password",placeholder:"Enter a new password",validate:{container:this,rules:{required:!0,minLength:8},messages:{required:"Please enter a password.",minLength:"Passwords should be at least 8 characters."}}}})
this.passwordConfirm=new LoginInputView({inputOptions:{name:"passwordConfirm",type:"password",testPath:"recover-password-confirm",placeholder:"Confirm your password",validate:{container:this,rules:{required:!0,match:this.password.input,minLength:8},messages:{required:"Please confirm your password.",match:"Password confirmation doesn't match!"}}}})
this.button=new KDButtonView({title:"FINISH REGISTRATION",type:"submit",style:"solid green",loader:{color:"#ffffff",diameter:21}})}__extends(FinishRegistrationForm,_super)
FinishRegistrationForm.prototype.getEmailValidator=function(){}
FinishRegistrationForm.prototype.setRegistrationDetails=function(details){var key,val,_ref,_ref1,_results
_results=[]
for(key in details)if(__hasProp.call(details,key)){val=details[key]
_results.push(null!=(_ref=this[key])?null!=(_ref1=_ref.input)?"function"==typeof _ref1.setValue?_ref1.setValue(val):void 0:void 0:void 0)}return _results}
FinishRegistrationForm.prototype.pistachio=function(){return"<div class='login-hint'>Complete your registration:</div>\n<div class='email'>{{> this.avatar}}{{> this.email}}</div>\n<div class='username'>{{> this.username}}</div>\n<div>{{> this.password}}</div>\n<div>{{> this.passwordConfirm}}</div>\n<div>{{> this.button}}</div>"}
return FinishRegistrationForm}(RegisterInlineForm)

var RedeemInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RedeemInlineForm=function(_super){function RedeemInlineForm(options,data){null==options&&(options={})
RedeemInlineForm.__super__.constructor.call(this,options,data)
this.inviteCode=new LoginInputView({inputOptions:{name:"inviteCode",placeholder:"Enter your invite code",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your invite code."}}}})
this.button=new KDButtonView({title:"Redeem",style:"solid green",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(RedeemInlineForm,_super)
RedeemInlineForm.prototype.pistachio=function(){return"<div>{{> this.inviteCode}}</div>\n<div>{{> this.button}}</div>"}
return RedeemInlineForm}(LoginViewInlineForm)

//@ sourceMappingURL=/js/__app.Login.0.0.1.js.map