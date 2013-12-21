var AccountAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountAppController=function(_super){function AccountAppController(options,data){null==options&&(options={})
options.view=new KDView({cssClass:"content-page"})
AccountAppController.__super__.constructor.call(this,options,data)}var handler,items
__extends(AccountAppController,_super)
handler=function(callback){return KD.singleton("appManager").open("Account",callback)}
KD.registerAppClass(AccountAppController,{name:"Account",routes:{"/:name?/Account":function(){return KD.singletons.router.handleRoute("/Account/Profile")},"/:name?/Account/:section":function(_arg){var section
section=_arg.params.section
return handler(function(app){return app.openSection(section)})}},behavior:"hideTabs",hiddenHandle:!0})
items={personal:{title:"Personal",items:[{slug:"Profile",title:"User profile",listType:"username",listHeader:"Here you can edit your account information."},{slug:"Email",title:"Email Notifications",listType:"emailNotifications",listHeader:"Email Notifications"},{slug:"Externals",title:"Linked accounts",listType:"linkedAccounts",listHeader:"Your Linked Accounts"}]},billing:{title:"Billing",items:[{slug:"Payment",title:"Payment methods",listHeader:"Your Payment Methods",listType:"methods"},{slug:"Subscriptions",title:"Your subscriptions",listHeader:"Your Active Subscriptions",listType:"subscriptions"},{slug:"Billing",title:"Billing history",listHeader:"Billing History",listType:"history"}]},danger:{title:"Danger",items:[{slug:"Delete",title:"Delete Account",listHeader:"Danger Zone",listType:"deleteAccount"}]}}
AccountAppController.prototype.createTab=function(itemData){var listType,title
title=itemData.title,listType=itemData.listType
return new KDTabPaneView({view:new AccountListWrapper({cssClass:"settings-list-wrapper "+KD.utils.slugify(title)},itemData)})}
AccountAppController.prototype.openSection=function(section){var item,_i,_len,_ref,_results
_ref=this.navController.itemsOrdered
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
if(section===item.getData().slug){this.tabView.addPane(this.createTab(item.getData()))
this.navController.selectSingleItem(item)
break}}return _results}
AccountAppController.prototype.loadView=function(mainView){var navView,section,sectionKey
this.navController=new KDListViewController({view:new KDListView({tagName:"aside",type:"inner-nav",itemClass:AccountNavigationItem}),wrapper:!1,scrollView:!1})
mainView.addSubView(navView=this.navController.getView())
mainView.addSubView(this.tabView=new KDTabView({hideHandleContainer:!0}))
for(sectionKey in items)if(__hasProp.call(items,sectionKey)){section=items[sectionKey]
this.navController.instantiateListItems(section.items)
navView.addSubView(new KDCustomHTMLView({tagName:"hr"}))}return navView.setPartial('<a href="/tos.html" target="_blank">Terms of service <span class="icon new-page"></span></a>\n<a href="/privacy.html" target="_blank">Privacy policy <span class="icon new-page"></span></a>')}
AccountAppController.prototype.showReferrerModal=function(){return new ReferrerModal}
return AccountAppController}(AppController)

var AccountNavigationController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountNavigationController=function(_super){function AccountNavigationController(){_ref=AccountNavigationController.__super__.constructor.apply(this,arguments)
return _ref}__extends(AccountNavigationController,_super)
AccountNavigationController.prototype.loadView=function(mainView){mainView.setPartial("<h3>"+this.getData().title+"</h3>")
return AccountNavigationController.__super__.loadView.apply(this,arguments)}
return AccountNavigationController}(KDListViewController)

var AccountContentWrapperController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountContentWrapperController=function(_super){function AccountContentWrapperController(){_ref=AccountContentWrapperController.__super__.constructor.apply(this,arguments)
return _ref}__extends(AccountContentWrapperController,_super)
AccountContentWrapperController.prototype.getSectionIndexForScrollOffset=function(offset){var sectionIndex,_ref1
sectionIndex=0
for(;(null!=(_ref1=this.sectionLists[sectionIndex+1])?_ref1.$().position().top:void 0)<=offset;)sectionIndex++
return sectionIndex}
AccountContentWrapperController.prototype.scrollTo=function(index){var itemToBeScrolled,scrollToValue
itemToBeScrolled=this.sectionLists[index]
scrollToValue=itemToBeScrolled.$().position().top
return this.getView().parent.$().animate({scrollTop:scrollToValue},300)}
return AccountContentWrapperController}(KDViewController)

var AccountSideBarController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountSideBarController=function(_super){function AccountSideBarController(options,data){options.view=new KDView({domId:options.domId})
AccountSideBarController.__super__.constructor.call(this,options,data)}__extends(AccountSideBarController,_super)
AccountSideBarController.prototype.loadView=function(){var allNavItems,controller,_i,_len,_ref
allNavItems=[]
_ref=this.sectionControllers
for(_i=0,_len=_ref.length;_len>_i;_i++){controller=_ref[_i]
allNavItems=allNavItems.concat(controller.itemsOrdered)}this.allNavItems=allNavItems
return this.setActiveNavItem(0)}
AccountSideBarController.prototype.setActiveNavItem=function(index){var activeNavController,activeNavItem,controllerIndex,sectionControllers,totalIndex
sectionControllers=this.sectionControllers
totalIndex=0
controllerIndex=0
for(;index>=totalIndex;){activeNavController=sectionControllers[controllerIndex]
controllerIndex++
totalIndex+=activeNavController.itemsOrdered.length}activeNavItem=this.allNavItems[index]
this.unselectAllNavItems(activeNavController)
return activeNavController.selectItem(activeNavItem)}
AccountSideBarController.prototype.unselectAllNavItems=function(clickedController){var controller,_i,_len,_ref,_results
_ref=this.sectionControllers
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){controller=_ref[_i]
clickedController!==controller?_results.push(controller.deselectAllItems()):_results.push(void 0)}return _results}
return AccountSideBarController}(KDViewController)

var AccountListViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountListViewController=function(_super){function AccountListViewController(options,data){options.noItemFoundWidget=new KDView({cssClass:"no-item-found hidden",partial:"<cite>"+options.noItemFoundText+"</cite>"})
AccountListViewController.__super__.constructor.call(this,options,data)}__extends(AccountListViewController,_super)
return AccountListViewController}(KDListViewController)

var AccountEditSecurity,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountEditSecurity=function(_super){function AccountEditSecurity(){_ref=AccountEditSecurity.__super__.constructor.apply(this,arguments)
return _ref}__extends(AccountEditSecurity,_super)
AccountEditSecurity.prototype.viewAppended=function(){var inputActions,nonPasswordInputs,passwordCancel,passwordConfirm,passwordEdit,passwordForm,passwordInput,passwordInputs,passwordLabel,passwordSave,passwordSpan,_this=this
this.addSubView(this.passwordForm=passwordForm=new KDFormView({callback:this.saveNewPassword.bind(this)}))
passwordForm.addSubView(passwordLabel=new KDLabelView({title:"Your password",cssClass:"main-label"}))
passwordInputs=new KDView({cssClass:"hiddenval clearfix passwords"})
passwordInputs.addSubView(passwordInput=new KDInputView({label:passwordLabel,type:"password",placeholder:"type new password",name:"password",testPath:"account-password-pass1",validate:{rules:{required:!0},messages:{required:"Password can't be empty..."}}}))
passwordInputs.addSubView(passwordConfirm=new KDInputView({type:"password",placeholder:"re-type new password",name:"passwordConfirm",testPath:"account-password-pass2",validate:{rules:{match:passwordInput},messages:{match:"Passwords do not match."}}}))
passwordInputs.addSubView(inputActions=new KDView({cssClass:"actions-wrapper"}))
inputActions.addSubView(passwordSave=new KDButtonView({title:"Save",type:"submit"}))
inputActions.addSubView(passwordCancel=new KDCustomHTMLView({tagName:"a",partial:"cancel",cssClass:"cancel-link",click:function(){return _this.passwordSwappable.swapViews()}}))
nonPasswordInputs=new KDView({cssClass:"initialval clearfix"})
nonPasswordInputs.addSubView(passwordSpan=new KDCustomHTMLView({tagName:"span",partial:"<i>your super secret password</i>",cssClass:"static-text"}))
nonPasswordInputs.addSubView(passwordEdit=new KDCustomHTMLView({tagName:"a",partial:"Edit",cssClass:"action-link",testPath:"account-password-edit",click:function(){return _this.passwordSwappable.swapViews()}}))
return passwordForm.addSubView(this.passwordSwappable=new AccountsSwappable({views:[passwordInputs,nonPasswordInputs],cssClass:"clearfix"}))}
AccountEditSecurity.prototype.passwordDidUpdate=function(){this.passwordSwappable.swapViews()
return new KDNotificationView({type:"growl",title:"Password Updated!",duration:1e3})}
AccountEditSecurity.prototype.saveNewPassword=function(formData){var _this=this
return KD.remote.api.JUser.changePassword(formData.password,function(err){return err?void 0:_this.passwordDidUpdate()})}
return AccountEditSecurity}(KDView)

var AccountEditUsername,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountEditUsername=function(_super){function AccountEditUsername(){AccountEditUsername.__super__.constructor.apply(this,arguments)
this.account=KD.whoami()
this.avatar=new AvatarStaticView(this.getAvatarOptions(),this.account)
this.emailForm=new KDFormViewWithFields({fields:{firstName:{placeholder:"firstname",name:"firstName",cssClass:"thin half",nextElement:{lastName:{cssClass:"thin half",placeholder:"lastname",name:"lastName"}}},email:{cssClass:"thin",placeholder:"you@yourdomain.com",name:"email",testPath:"account-email-input"},username:{cssClass:"thin",placeholder:"username",name:"username",attributes:{readonly:""+!/^guest-/.test(this.account.profile.nickname)},testPath:"account-username-input"},password:{cssClass:"thin half",placeholder:"password",name:"password",type:"password",nextElement:{confirm:{cssClass:"thin half",placeholder:"confirm password",name:"confirmPassword",type:"password"}}}},buttons:{Save:{title:"SAVE CHANGES",type:"submit",style:"solid green fr"}},callback:this.bound("update")})}var notify
__extends(AccountEditUsername,_super)
notify=function(msg){return new KDNotificationView({title:msg,duration:2e3})}
AccountEditUsername.prototype.update=function(formData){var JUser,confirmPassword,daisy,email,firstName,lastName,password,profileUpdated,queue,username
daisy=Bongo.daisy
JUser=KD.remote.api.JUser
email=formData.email,password=formData.password,confirmPassword=formData.confirmPassword,firstName=formData.firstName,lastName=formData.lastName,username=formData.username
profileUpdated=!0
queue=[function(){var me,oldFirstName,oldLastName,_ref
me=KD.whoami()
_ref=me.profile,oldFirstName=_ref.firstName,oldLastName=_ref.lastName
return oldFirstName===firstName&&oldLastName===lastName?queue.next():me.modify({"profile.firstName":firstName,"profile.lastName":lastName},function(err){return err?notify(err.message):queue.next()})},function(){return JUser.changeEmail({email:email},function(err){return err?"EmailIsSameError"===err.message?queue.next():notify(err.message):new VerifyPINModal("Update E-Mail",function(pin){return KD.remote.api.JUser.changeEmail({email:email,pin:pin},function(err){notify(err?err.message:"E-mail changed!")
return queue.next()})})})},function(){var token
if(password!==confirmPassword)return notify("Passwords did not match")
if(""===password){token=KD.utils.parseQuery().token
if(token){profileUpdated=!1
notify("You should set your password")}return queue.next()}return JUser.changePassword(password,function(err){return err?"PasswordIsSame"===err.message?queue.next():notify(err.message):queue.next()})},function(){return profileUpdated?notify("Profile Updated"):void 0}]
return daisy(queue)}
AccountEditUsername.prototype.viewAppended=function(){var JPasswordRecovery,JUser,token,_ref,_this=this
_ref=KD.remote.api,JPasswordRecovery=_ref.JPasswordRecovery,JUser=_ref.JUser
token=KD.utils.parseQuery().token
token&&JPasswordRecovery.validate(token,function(err,isValid){return err&&"redeemed_token"!==err.short?notify(err.message):isValid?notify("Thanks for confirming your email address"):void 0})
return KD.whoami().fetchEmailAndStatus(function(err,userInfo){_this.userInfo=userInfo
AccountEditUsername.__super__.viewAppended.apply(_this,arguments)
return _this.putDefaults()})}
AccountEditUsername.prototype.putDefaults=function(){var email,firstName,focus,lastName,nickname,o,_ref,_ref1,_this=this
email=this.userInfo.email
_ref=this.account.profile,nickname=_ref.nickname,firstName=_ref.firstName,lastName=_ref.lastName
this.emailForm.inputs.email.setDefaultValue(email)
this.emailForm.inputs.username.setDefaultValue(nickname)
this.emailForm.inputs.firstName.setDefaultValue(firstName)
this.emailForm.inputs.lastName.setDefaultValue(lastName)
focus=KD.utils.parseQuery().focus
focus&&null!=(_ref1=this.emailForm.inputs[focus])&&_ref1.setFocus()
"unconfirmed"===this.userInfo.status&&(o={tagName:"a",partial:"You didn't verify your email yet <span>Verify now</span>",cssClass:"action-link verify-email",testPath:"account-email-edit",click:function(){return KD.remote.api.JPasswordRecovery.recoverPassword(_this.account.profile.nickname,function(err){var message
message="Email confirmation mail is sent"
err?message=err.message:_this.verifyEmail.hide()
return new KDNotificationView({title:message,duration:3500})})}})
return this.addSubView(this.verifyEmail=new KDCustomHTMLView(o))}
AccountEditUsername.prototype.getAvatarOptions=function(){var _this=this
return{showStatus:!0,tooltip:{title:"<p class='centertext'>Click avatar to edit</p>",placement:"below",arrow:{placement:"top"}},size:{width:160,height:160},click:function(){return KD.singleton("appManager").require("Activity",function(){var pos,_ref
pos={top:_this.avatar.getY()-8,left:_this.avatar.getX()-8}
null!=(_ref=_this.avatarMenu)&&_ref.destroy()
_this.avatarMenu=new JContextMenu({menuWidth:312,cssClass:"avatar-menu dark",delegate:_this.avatar,x:_this.avatar.getX()+96,y:_this.avatar.getY()-7},{customView:_this.avatarChange=new AvatarChangeView({delegate:_this},_this.account)})
_this.avatarChange.on("UseGravatar",function(){return _this.account.modify({"profile.avatar":""})})
return _this.avatarChange.on("UsePhoto",function(dataURI){var avatarBase64,_,_ref1
_ref1=dataURI.split(","),_=_ref1[0],avatarBase64=_ref1[1]
_this.avatar.setAvatar("url("+dataURI+")")
_this.avatar.$().css({backgroundSize:"auto 90px"})
_this.avatarChange.emit("LoadingStart")
return _this.uploadAvatar(avatarBase64,function(){return _this.avatarChange.emit("LoadingEnd")})})})}}}
AccountEditUsername.prototype.pistachio=function(){return"{{> this.avatar}}\n<section>\n  {{> this.emailForm}}\n</section>"}
return AccountEditUsername}(JView)

var AccountLinkedAccountsList,AccountLinkedAccountsListController,AccountLinkedAccountsListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountLinkedAccountsListController=function(_super){function AccountLinkedAccountsListController(options,data){var nicename,provider
null==options&&(options={})
AccountLinkedAccountsListController.__super__.constructor.call(this,options,data)
this.instantiateListItems(function(){var _ref,_results
_ref=KD.config.externalProfiles
_results=[]
for(provider in _ref)if(__hasProp.call(_ref,provider)){nicename=_ref[provider].nicename
_results.push({title:nicename,provider:provider})}return _results}())}__extends(AccountLinkedAccountsListController,_super)
return AccountLinkedAccountsListController}(KDListViewController)
AccountLinkedAccountsList=function(_super){function AccountLinkedAccountsList(options,data){null==options&&(options={})
options.tagName||(options.tagName="ul")
options.itemClass||(options.itemClass=AccountLinkedAccountsListItem)
AccountLinkedAccountsList.__super__.constructor.call(this,options,data)}__extends(AccountLinkedAccountsList,_super)
return AccountLinkedAccountsList}(KDListView)
AccountLinkedAccountsListItem=function(_super){function AccountLinkedAccountsListItem(options,data){var mainController,provider,_this=this
null==options&&(options={})
options.tagName||(options.tagName="li")
options.type||(options.type="oauth")
AccountLinkedAccountsListItem.__super__.constructor.call(this,options,data)
this.linked=!1
provider=this.getData().provider
this.setClass(provider)
this["switch"]=new KodingSwitch({callback:function(state){_this["switch"].setOff(!1)
return state?_this.link():_this.unlink()}})
mainController=KD.getSingleton("mainController")
mainController.on("ForeignAuthSuccess."+provider,function(){_this.linked=!0
return _this["switch"].setOn(!1)})}var notify
__extends(AccountLinkedAccountsListItem,_super)
notify=function(message){return new KDNotificationView({title:message,type:"mini",duration:3e3})}
AccountLinkedAccountsListItem.prototype.link=function(){var provider
provider=this.getData().provider
return KD.singletons.oauthController.openPopup(provider)}
AccountLinkedAccountsListItem.prototype.unlink=function(){var account,provider,title,_ref,_this=this
_ref=this.getData(),title=_ref.title,provider=_ref.provider
account=KD.whoami()
return account.unlinkOauth(provider,function(err){if(err)return KD.showError(err)
account.unstore("ext|profile|"+provider,function(err){return err?warn(err):void 0})
notify("Your "+title+" account is now unlinked.")
return _this.linked=!1})}
AccountLinkedAccountsListItem.prototype.viewAppended=function(){var provider,_this=this
JView.prototype.viewAppended.call(this)
provider=this.getData().provider
return KD.whoami().fetchOAuthInfo(function(err,foreignAuth){_this.linked=null!=(null!=foreignAuth?foreignAuth[provider]:void 0)
return _this["switch"].setDefaultValue(_this.linked)})}
AccountLinkedAccountsListItem.prototype.pistachio=function(){return"<div class='title'><span class='icon'></span>{cite{#(title)}}</div>\n{{> this[\"switch\"]}}"}
return AccountLinkedAccountsListItem}(KDListItemView)

var AccountEmailNotifications,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountEmailNotifications=function(_super){function AccountEmailNotifications(){_ref=AccountEmailNotifications.__super__.constructor.apply(this,arguments)
return _ref}__extends(AccountEmailNotifications,_super)
AccountEmailNotifications.prototype.viewAppended=function(){var _this=this
return KD.whoami().fetchEmailFrequency(function(err,frequency){return _this.putContents(KD.whoami(),frequency)})}
AccountEmailNotifications.prototype.putContents=function(account,frequency){var field,fields,flag,global,globalValue,toggleFieldStates,turnedOffHint,_this=this
fields={daily:{title:"Send me a daily email about everything below"},privateMessage:{title:"Someone sends me a private message"},followActions:{title:"Someone follows me"},comment:{title:"My post receives a comment"},likeActivities:{title:"When I receive likes"},groupInvite:{title:"Someone invites me to their group"},groupRequest:{title:"Someone requests access to my group"},groupApproved:{title:"Group admin approves my access request"},groupJoined:{title:"When someone joins your group"},groupLeft:{title:"When someone leaves your group"}}
globalValue=frequency.global
turnedOffHint=new KDCustomHTMLView({partial:"Email notifications are turned off. You won't receive any emails about anything.",cssClass:"no-item-found "+(globalValue?"hidden":void 0)})
this.addSubView(turnedOffHint)
this.getDelegate().addSubView(global=new KodingSwitch({cssClass:"dark in-account-header",defaultValue:globalValue,callback:function(state){return account.setEmailPreferences({global:state},function(err){if(err){global.oldValue=globalValue
global.fallBackToOldState()
return new KDNotificationView({duration:2e3,title:"Failed to turn "+state.toLowerCase()+" the email notifications."})}return _this.emit("GlobalStateChanged",state)})}}))
for(flag in fields)if(__hasProp.call(fields,flag)){field=fields[flag]
this.addSubView(field.formView=new KDFormView)
field.formView.addSubView(new KDLabelView({title:field.title,cssClass:"main-label"}))
field.current=frequency[flag]
field.formView.addSubView(field["switch"]=new KodingSwitch({cssClass:"dark",defaultValue:field.current,callback:function(state){var prefs,_this=this
prefs={}
prefs[this.getData()]=state
fields[this.getData()].loader.show()
return account.setEmailPreferences(prefs,function(err){fields[_this.getData()].loader.hide()
if(err){_this.fallBackToOldState()
return KD.notify_("Failed to change state")}})}},flag))
fields[flag].formView.addSubView(fields[flag].loader=new KDLoaderView({size:{width:12},cssClass:"email-on-off-loader",loaderOptions:{color:"#FFFFFF"}}))}toggleFieldStates=function(state){var _results
_results=[]
for(flag in fields)if(__hasProp.call(fields,flag)){field=fields[flag]
state===!1?_results.push(field.formView.hide()):_results.push(field.formView.show())}return _results}
toggleFieldStates(globalValue)
return this.on("GlobalStateChanged",function(state){toggleFieldStates(state)
return state===!1?turnedOffHint.show():turnedOffHint.hide()})}
return AccountEmailNotifications}(KDView)

var AccountEditorExtensionTagger,AccountEditorList,AccountEditorListController,AccountEditorListItem,AccountEditorTags,_ref,_ref1,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountEditorListController=function(_super){function AccountEditorListController(options,data){data=$.extend({items:[{title:"Editor settings are coming soon"}]},data)
AccountEditorListController.__super__.constructor.call(this,options,data)}__extends(AccountEditorListController,_super)
return AccountEditorListController}(KDListViewController)
AccountEditorList=function(_super){function AccountEditorList(options,data){options=$.extend({tagName:"ul",itemClass:AccountEditorListItem},options)
AccountEditorList.__super__.constructor.call(this,options,data)}__extends(AccountEditorList,_super)
return AccountEditorList}(KDListView)
AccountEditorExtensionTagger=function(_super){function AccountEditorExtensionTagger(){_ref=AccountEditorExtensionTagger.__super__.constructor.apply(this,arguments)
return _ref}__extends(AccountEditorExtensionTagger,_super)
AccountEditorExtensionTagger.prototype.viewAppended=function(){var actions,cancel,save,tagInput,_this=this
this.addSubView(tagInput=new KDInputView({placeholder:"add a file type... (not available on Private Beta)",name:"extension-tag"}))
this.addSubView(actions=new KDView({cssClass:"actions-wrapper"}))
actions.addSubView(save=new KDButtonView({title:"Save"}))
return actions.addSubView(cancel=new KDCustomHTMLView({tagName:"a",partial:"cancel",cssClass:"cancel-link",click:function(){return _this.emit("FormCancelled")}}))}
return AccountEditorExtensionTagger}(KDFormView)
AccountEditorTags=function(_super){function AccountEditorTags(){_ref1=AccountEditorTags.__super__.constructor.apply(this,arguments)
return _ref1}__extends(AccountEditorTags,_super)
AccountEditorTags.prototype.viewAppended=function(){return this.setPartial(this.partial(this.data))}
AccountEditorTags.prototype.partial=function(data){var extHTMLArr,extension
extHTMLArr=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=data.length;_len>_i;_i++){extension=data[_i]
_results.push("<span class='blacktag'>"+extension+"</span>")}return _results}()
return""+extHTMLArr.join("")}
return AccountEditorTags}(KDView)
AccountEditorListItem=function(_super){function AccountEditorListItem(options,data){options={tagName:"li"}
AccountEditorListItem.__super__.constructor.call(this,options,data)}__extends(AccountEditorListItem,_super)
AccountEditorListItem.prototype.viewAppended=function(){var editLink,form,info,swappable
AccountEditorListItem.__super__.viewAppended.apply(this,arguments)
this.form=form=new AccountEditorExtensionTagger({delegate:this,cssClass:"posstatic"},this.data.extensions)
this.info=info=new AccountEditorTags({cssClass:"posstatic",delegate:this},this.data.extensions)
info.addSubView(editLink=new KDCustomHTMLView({tagName:"a",partial:"Edit",cssClass:"action-link",click:this.bound("swapSwappable")}))
this.swappable=swappable=new AccountsSwappable({views:[form,info],cssClass:"posstatic"})
this.addSubView(swappable,".swappable-wrapper")
return form.on("FormCancelled",this.bound("swapSwappable"))}
AccountEditorListItem.prototype.swapSwappable=function(){return this.swappable.swapViews()}
AccountEditorListItem.prototype.partial=function(data){return"<span class='darkText'>"+data.title+"</span>"}
return AccountEditorListItem}(KDListItemView)

var AccountSshKeyForm,AccountSshKeyList,AccountSshKeyListController,AccountSshKeyListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountSshKeyListController=function(_super){function AccountSshKeyListController(options,data){var _this=this
options.noItemFoundText="You have no SSH key."
AccountSshKeyListController.__super__.constructor.call(this,options,data)
this.loadItems()
this.getListView().on("UpdatedItems",function(){var newKeys,_ref
_this.newItem=!1
newKeys=_this.getItemsOrdered().map(function(item){return item.getData()})
0!==newKeys.length&&null!=(_ref=_this.customItem)&&_ref.destroy()
return KD.remote.api.JUser.setSSHKeys(newKeys,function(){return log("Saved keys.")})})
this.getListView().on("RemoveItem",function(item){_this.newItem=!1
_this.removeItem(item)
return _this.getListView().emit("UpdatedItems")})
this.newItem=!1}__extends(AccountSshKeyListController,_super)
AccountSshKeyListController.prototype.loadItems=function(){var _this=this
this.removeAllItems()
this.showLazyLoader(!1)
return KD.remote.api.JUser.getSSHKeys(function(keys){_this.instantiateListItems(keys)
return _this.hideLazyLoader()})}
AccountSshKeyListController.prototype.loadView=function(){var addButton,_this=this
AccountSshKeyListController.__super__.loadView.apply(this,arguments)
return this.getView().parent.addSubView(addButton=new KDButtonView({style:"solid green small account-header-button",title:"",icon:!0,iconOnly:!0,iconClass:"plus",callback:function(){if(!_this.newItem){_this.newItem=!0
_this.addItem({key:"",title:""},0)
return _this.getListView().items.first.swapSwappable({hideDelete:!0})}}}))}
return AccountSshKeyListController}(AccountListViewController)
AccountSshKeyList=function(_super){function AccountSshKeyList(options,data){options=$.extend({tagName:"ul",itemClass:AccountSshKeyListItem},options)
AccountSshKeyList.__super__.constructor.call(this,options,data)}__extends(AccountSshKeyList,_super)
return AccountSshKeyList}(KDListView)
AccountSshKeyForm=function(_super){function AccountSshKeyForm(){AccountSshKeyForm.__super__.constructor.apply(this,arguments)
this.titleLabel=new KDLabelView({"for":"sshtitle",title:"Title"})
this.titleInput=new KDInputView({placeholder:"your SSH key title",name:"sshtitle",label:this.titleLabel})
this.keyTextLabel=new KDLabelView({"for":"sshkey",title:"SSH Key"})
this.keyTextarea=new KDInputView({placeholder:"your SSH key",type:"textarea",name:"sshkey",cssClass:"light",label:this.keyTextLabel})}__extends(AccountSshKeyForm,_super)
AccountSshKeyForm.prototype.viewAppended=function(){var cancel,formline1,formline2,save,_this=this
this.addSubView(formline1=new KDCustomHTMLView({tagName:"div",cssClass:"formline"}))
formline1.addSubView(this.titleLabel)
formline1.addSubView(this.titleInput)
formline1.addSubView(this.keyTextLabel)
formline1.addSubView(this.keyTextarea)
this.addSubView(formline2=new KDCustomHTMLView({cssClass:"button-holder"}))
formline2.addSubView(save=new KDButtonView({style:"cupid-green savebtn",title:"Save",callback:function(){return _this.emit("FormSaved")}}))
formline2.addSubView(cancel=new KDCustomHTMLView({tagName:"button",partial:"Cancel",cssClass:"cancel-link clean-gray button",click:function(){return _this.emit("FormCancelled")}}))
return formline2.addSubView(this.deletebtn=new KDButtonView({style:"clean-red deletebtn",title:"Delete",callback:function(){return _this.emit("FormDeleted")}}))}
return AccountSshKeyForm}(KDFormView)
AccountSshKeyListItem=function(_super){function AccountSshKeyListItem(){_ref=AccountSshKeyListItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(AccountSshKeyListItem,_super)
AccountSshKeyListItem.prototype.setDomElement=function(cssClass){return this.domElement=$("<li class='kdview clearfix "+cssClass+"'></li>")}
AccountSshKeyListItem.prototype.viewAppended=function(){var editLink,form,info,key,swappable,title,_ref1
AccountSshKeyListItem.__super__.viewAppended.apply(this,arguments)
this.form=form=new AccountSshKeyForm({delegate:this,cssClass:"posrelative"})
_ref1=this.getData(),title=_ref1.title,key=_ref1.key
title&&form.titleInput.setValue(title)
key&&form.keyTextarea.setValue(key)
this.info=info=new KDCustomHTMLView({tagName:"span",partial:'<div>\n  <span class="title">'+this.getData().title+'</span>\n  <span class="key">'+this.getData().key.substr(0,45)+" . . . "+this.getData().key.substr(-25)+"</span>\n</div>",cssClass:"posstatic"})
info.addSubView(editLink=new KDCustomHTMLView({tagName:"a",partial:"Edit",cssClass:"action-link",click:this.bound("swapSwappable")}))
this.swappable=swappable=new AccountsSwappable({views:[form,info],cssClass:"posstatic"})
this.addSubView(swappable,".swappable-wrapper")
form.on("FormCancelled",this.bound("cancelItem"))
form.on("FormSaved",this.bound("saveItem"))
return form.on("FormDeleted",this.bound("deleteItem"))}
AccountSshKeyListItem.prototype.swapSwappable=function(options){options.hideDelete?this.form.deletebtn.hide():this.form.deletebtn.show()
return this.swappable.swapViews()}
AccountSshKeyListItem.prototype.cancelItem=function(){var key
key=this.getData().key
return key?this.swappable.swapViews():this.deleteItem()}
AccountSshKeyListItem.prototype.deleteItem=function(){return this.getDelegate().emit("RemoveItem",this)}
AccountSshKeyListItem.prototype.saveItem=function(){var key,title,_ref1
this.setData({key:this.form.keyTextarea.getValue(),title:this.form.titleInput.getValue()})
_ref1=this.getData(),key=_ref1.key,title=_ref1.title
if(key&&title){this.info.$("span.title").text(title)
this.info.$("span.key").text(""+key.substr(0,45)+" . . . "+key.substr(-25))
this.swappable.swapViews()
return this.getDelegate().emit("UpdatedItems")}return key?title?void 0:new KDNotificationView({title:"Title required for SSH key."}):new KDNotificationView({title:"Key shouldn't be empty."})}
AccountSshKeyListItem.prototype.partial=function(){return"<div class='swappableish swappable-wrapper posstatic'></div>"}
return AccountSshKeyListItem}(KDListItemView)

var AccountKodingKeyList,AccountKodingKeyListController,AccountKodingKeyListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountKodingKeyListController=function(_super){function AccountKodingKeyListController(options,data){options.noItemFoundText="You have no Koding key."
options.cssClass="koding-keys"
AccountKodingKeyListController.__super__.constructor.call(this,options,data)}__extends(AccountKodingKeyListController,_super)
AccountKodingKeyListController.prototype.loadView=function(){var _this=this
AccountKodingKeyListController.__super__.loadView.apply(this,arguments)
this.removeAllItems()
this.showLazyLoader(!1)
return KD.remote.api.JKodingKey.fetchAll({},function(err,keys){if(err)return warn(err)
_this.instantiateListItems(keys)
return _this.hideLazyLoader()})}
return AccountKodingKeyListController}(AccountListViewController)
AccountKodingKeyList=function(_super){function AccountKodingKeyList(options,data){var defaults
defaults={tagName:"ul",itemClass:AccountKodingKeyListItem}
options=__extends(defaults,options)
AccountKodingKeyList.__super__.constructor.call(this,options,data)}__extends(AccountKodingKeyList,_super)
return AccountKodingKeyList}(KDListView)
AccountKodingKeyListItem=function(_super){function AccountKodingKeyListItem(options,data){var defaults,deleteKey,viewKey,_this=this
defaults={tagName:"li"}
options=__extends(defaults,options)
AccountKodingKeyListItem.__super__.constructor.call(this,options,data)
this.addSubView(deleteKey=new KDCustomHTMLView({tagName:"a",partial:"Revoke Access",cssClass:"action-link",click:function(){var modal,nickname
nickname=KD.whoami().profile.nickname
return modal=new KDModalView({title:"Revoke Koding Key Access",overlay:!0,cssClass:"new-kdmodal",content:"<div class='modalformline'>\n  <p>\n    If you revoke access, your computer '<strong>"+data.hostname+"</strong>' \n    will not be able to use your Koding account '"+nickname+"'. It won't be \n    able to receive public url's, deploy your kites etc.\n  </p>\n  <p>\n    If you want to register a new key, you can use <code>\"kd register\"</code>\n    command anytime.\n  </p>\n  <p>\n    Do you really want to revoke <strong>"+data.hostname+"</strong>'s access?\n  </p>\n</div>",buttons:{"Yes, Revoke Access":{style:"modal-clean-red",callback:function(){_this.revokeAccess(options,data)
_this.destroy()
return modal.destroy()}},Close:{style:"modal-clean-gray",callback:function(){return modal.destroy()}}}})}}))
this.addSubView(viewKey=new KDCustomHTMLView({tagName:"a",partial:"View access key",click:function(){var modal
return modal=new KDModalView({title:""+data.hostname+" Access Key",width:500,overlay:!0,cssClass:"new-kdmodal",content:"<div class='modalformline'>\n  <p>\n    Please do not share this key anyone!\n  </p>\n  <p>\n    <code>"+data.key+"</code>\n  </p>\n</div>"})}}))}__extends(AccountKodingKeyListItem,_super)
AccountKodingKeyListItem.prototype.revokeAccess=function(options,data){return data.revoke()}
AccountKodingKeyListItem.prototype.partial=function(data){return'<span class="labelish">'+(data.hostname||"Unknown Host")+"</span>"}
return AccountKodingKeyListItem}(KDListItemView)

var AccountPaymentHistoryList,AccountPaymentHistoryListController,AccountPaymentHistoryListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountPaymentHistoryListController=function(_super){function AccountPaymentHistoryListController(options,data){null==options&&(options={})
options.noItemFoundText||(options.noItemFoundText="You have no payment history.")
AccountPaymentHistoryListController.__super__.constructor.call(this,options,data)
this.getListView().on("Reload",this.bound("loadItems"))
this.loadItems()}__extends(AccountPaymentHistoryListController,_super)
AccountPaymentHistoryListController.prototype.loadItems=function(){var JPayment,items,_this=this
JPayment=KD.remote.api.JPayment
this.removeAllItems()
this.showLazyLoader(!1)
items=[]
return JPayment.fetchTransactions(function(err,transactions){var amount,card,cardNumber,cardType,createdAt,invoice,owner,paymentMethodId,refundable,status,transaction,transactionList,type,_i,_len
err&&warn(err)
for(paymentMethodId in transactions)if(__hasProp.call(transactions,paymentMethodId)){transactionList=transactions[paymentMethodId]
for(_i=0,_len=transactionList.length;_len>_i;_i++){transaction=transactionList[_i]
if(transaction.amount>0){status=transaction.status,createdAt=transaction.createdAt,card=transaction.card,cardType=transaction.cardType,invoice=transaction.invoice,cardNumber=transaction.cardNumber,owner=transaction.owner,refundable=transaction.refundable,type=transaction.type
amount=_this.utils.formatMoney((transaction.amount+transaction.tax)/100)
items.push({status:status,cardType:cardType,cardNumber:cardNumber,owner:owner,refundable:refundable,amount:amount,invoice:invoice,currency:"USD",paidVia:card||""})}}}_this.instantiateListItems(items)
return _this.hideLazyLoader()})}
AccountPaymentHistoryListController.prototype.loadView=function(){var reloadButton
AccountPaymentHistoryListController.__super__.loadView.apply(this,arguments)
return this.getView().parent.addSubView(reloadButton=new KDButtonView({style:"solid green account-header-button",title:"",icon:!0,iconOnly:!0,iconClass:"refresh",callback:this.getListView().emit.bind(this.getListView(),"Reload")}))}
return AccountPaymentHistoryListController}(AccountListViewController)
AccountPaymentHistoryList=function(_super){function AccountPaymentHistoryList(options,data){null==options&&(options={})
options.tagName||(options.tagName="table")
options.itemClass||(options.itemClass=AccountPaymentHistoryListItem)
AccountPaymentHistoryList.__super__.constructor.call(this,options,data)}__extends(AccountPaymentHistoryList,_super)
return AccountPaymentHistoryList}(KDListView)
AccountPaymentHistoryListItem=function(_super){function AccountPaymentHistoryListItem(options,data){null==options&&(options={})
options.tagName||(options.tagName="tr")
AccountPaymentHistoryListItem.__super__.constructor.call(this,options,data)}__extends(AccountPaymentHistoryListItem,_super)
AccountPaymentHistoryListItem.prototype.viewAppended=function(){var editLink
AccountPaymentHistoryListItem.__super__.viewAppended.apply(this,arguments)
return this.addSubView(editLink=new KDCustomHTMLView({tagName:"a",partial:"View invoice",cssClass:"action-link"}))}
AccountPaymentHistoryListItem.prototype.click=function(event){event.stopPropagation()
event.preventDefault()
return $(event.target).is("a.delete-icon")?this.getDelegate().emit("UnlinkAccount",{accountType:this.getData().type}):void 0}
AccountPaymentHistoryListItem.prototype.partial=function(data){var cycleNotice
cycleNotice=data.billingCycle?"/"+data.billingCycle:""
return"<td>\n  <span class='invoice-date'>"+dateFormat(data.createdAt,"mmm dd, yyyy")+"</span>\n</td>\n<td>\n  <strong>"+data.amount+"</strong>\n</td>\n<td>\n  <span class='ttag "+data.status+"'>"+data.status.toUpperCase()+"</span>\n</td>\n<td class='ccard'>\n  <span class='icon "+data.cardType.toLowerCase().replace(" ","-")+"'></span>..."+data.cardNumber+"\n</td>"}
return AccountPaymentHistoryListItem}(KDListItemView)

var AccountPaymentMethodsList,AccountPaymentMethodsListController,AccountPaymentMethodsListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountPaymentMethodsListController=function(_super){function AccountPaymentMethodsListController(options,data){var list,_this=this
options.noItemFoundText="You have no payment method."
AccountPaymentMethodsListController.__super__.constructor.call(this,options,data)
data=this.getData()
this.loadItems()
this.on("reload",function(){return _this.loadItems()})
list=this.getListView()
list.on("ItemWasAdded",function(item){item.on("PaymentMethodEditRequested",_this.bound("editPaymentMethod"))
return item.on("PaymentMethodRemoveRequested",function(data){var modal
return modal=KDModalView.confirm({title:"Are you sure?",description:"Are you sure that you want to remove this payment method?",subView:new PaymentMethodView({},data),ok:{title:"Remove",callback:function(){modal.destroy()
return _this.removePaymentMethod(data,item)}}})})})
list.on("reload",function(){return _this.loadItems()})
KD.getSingleton("paymentController").on("PaymentDataChanged",function(){return _this.loadItems()})}__extends(AccountPaymentMethodsListController,_super)
AccountPaymentMethodsListController.prototype.editPaymentMethod=function(data){var paymentController
paymentController=KD.getSingleton("paymentController")
return this.showModal(data)}
AccountPaymentMethodsListController.prototype.removePaymentMethod=function(_arg,item){var paymentController,paymentMethodId,_this=this
paymentMethodId=_arg.paymentMethodId
paymentController=KD.getSingleton("paymentController")
return paymentController.removePaymentMethod(paymentMethodId,function(){return _this.removeItem(item)})}
AccountPaymentMethodsListController.prototype.loadItems=function(){var _this=this
this.removeAllItems()
this.showLazyLoader(!1)
return KD.whoami().fetchPaymentMethods(function(err,paymentMethods){var _ref
_this.instantiateListItems(paymentMethods)
null!=(_ref=_this.addButton)&&_ref.destroy()
_this.getListView().addSubView(_this.addButton=new KDCustomHTMLView({cssClass:"kdlistitemview-cc plus",partial:"<span><i></i><i></i></span>",click:function(){return _this.showModal()}}))
return _this.hideLazyLoader()})}
AccountPaymentMethodsListController.prototype.showModal=function(initialPaymentInfo){var modal,paymentController
paymentController=KD.getSingleton("paymentController")
modal=paymentController.createPaymentInfoModal()
modal.on("viewAppended",function(){return null!=initialPaymentInfo?modal.setState("editExisting",initialPaymentInfo):modal.setState("createNew")})
return paymentController.observePaymentSave(modal,function(err){return err?new KDNotificationView({title:err.message}):modal.destroy()})}
return AccountPaymentMethodsListController}(AccountListViewController)
AccountPaymentMethodsList=function(_super){function AccountPaymentMethodsList(options,data){null==options&&(options={})
options.tagName="ul"
options.itemClass=AccountPaymentMethodsListItem
AccountPaymentMethodsList.__super__.constructor.call(this,options,data)}__extends(AccountPaymentMethodsList,_super)
return AccountPaymentMethodsList}(KDListView)
AccountPaymentMethodsListItem=function(_super){function AccountPaymentMethodsListItem(options,data){var _this=this
null==options&&(options={})
options.tagName="li"
options.type="cc"
AccountPaymentMethodsListItem.__super__.constructor.call(this,options,data)
data=this.getData()
this.paymentMethod=new PaymentMethodView({},this.getData())
this.paymentMethod.on("PaymentMethodEditRequested",function(){return _this.emit("PaymentMethodEditRequested",data)})
this.editLink=new CustomLinkView({title:"edit",click:function(e){e.preventDefault()
return _this.emit("PaymentMethodEditRequested",data)}})
this.removeLink=new CustomLinkView({title:"remove",click:function(e){e.preventDefault()
return _this.emit("PaymentMethodRemoveRequested",data)}})}__extends(AccountPaymentMethodsListItem,_super)
AccountPaymentMethodsListItem.prototype.viewAppended=JView.prototype.viewAppended
AccountPaymentMethodsListItem.prototype.pistachio=function(){return'{{> this.paymentMethod}}\n<div class="controls">{{> this.editLink}} | {{> this.removeLink}}</div>'}
return AccountPaymentMethodsListItem}(KDListItemView)

var AccountSubscriptionsList,AccountSubscriptionsListController,AccountSubscriptionsListItem,SubscriptionControls,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountSubscriptionsListController=function(_super){function AccountSubscriptionsListController(options,data){var _this=this
null==options&&(options={})
options.noItemFoundText||(options.noItemFoundText="You have no subscriptions.")
AccountSubscriptionsListController.__super__.constructor.call(this,options,data)
this.loadItems()
this.getListView().on("ItemWasAdded",function(item){var subscription
subscription=item.getData()
subscription.plan.fetchProducts(function(err,products){return KD.showError(err)?void 0:item.setProductComponents(subscription,products)})
return item.on("UnsubscribeRequested",function(){return _this.confirm("cancel",subscription)}).on("ReactivateRequested",function(){return _this.confirm("resume",subscription)}).on("PlanChangeRequested",function(){var modal,payment,workflow
payment=KD.getSingleton("paymentController")
workflow=payment.createUpgradeWorkflow("vm")
modal=new KDModalView({view:workflow,overlay:!0})
return workflow.on("Finished",modal.bound("destroy"))})})}var getConfirmationButtonText,getConfirmationText
__extends(AccountSubscriptionsListController,_super)
getConfirmationText=function(action){switch(action){case"cancel":return"Are you sure you want to cancel this subscription?"
case"resume":return"Are you sure you want to reactivate this subscription?"}}
getConfirmationButtonText=function(action){switch(action){case"cancel":return"Unsubscribe"
case"resume":return"Reactivate"}}
AccountSubscriptionsListController.prototype.confirm=function(action,subscription,callback){var modal,_this=this
return modal=KDModalView.confirm({title:"Are you sure?",description:getConfirmationText(action,subscription),subView:new SubscriptionView({},subscription),ok:{title:getConfirmationButtonText(action,subscription),callback:null!=callback?callback:function(){return subscription[action](function(err){KD.showError(err)
modal.destroy()
return _this.loadItems()})}}})}
AccountSubscriptionsListController.prototype.loadItems=function(){var payment,status,_this=this
this.removeAllItems()
this.showLazyLoader(!1)
payment=KD.getSingleton("paymentController")
payment.once("SubscriptionDebited",this.bound("loadItems"))
status={status:{$in:["active","live","canceled","future","past_due","expired","in_trial"]}}
return payment.fetchSubscriptionsWithPlans(status,function(err,subscriptions){_this.instantiateListItems(subscriptions.filter(function(subscription){return"expired"!==subscription.status}))
return _this.hideLazyLoader()})}
AccountSubscriptionsListController.prototype.loadView=function(){var reloadButton
AccountSubscriptionsListController.__super__.loadView.apply(this,arguments)
return this.getView().parent.addSubView(reloadButton=new KDButtonView({style:"solid green small account-header-button",title:"",icon:!0,iconOnly:!0,iconClass:"refresh",callback:this.bound("loadItems")}))}
return AccountSubscriptionsListController}(AccountListViewController)
AccountSubscriptionsList=function(_super){function AccountSubscriptionsList(options,data){null==options&&(options={})
options.tagName||(options.tagName="ul")
options.itemClass||(options.itemClass=AccountSubscriptionsListItem)
AccountSubscriptionsList.__super__.constructor.call(this,options,data)}__extends(AccountSubscriptionsList,_super)
return AccountSubscriptionsList}(KDListView)
AccountSubscriptionsListItem=function(_super){function AccountSubscriptionsListItem(options,data){var listView,subscription
null==options&&(options={})
options.tagName||(options.tagName="li")
AccountSubscriptionsListItem.__super__.constructor.call(this,options,data)
listView=this.getDelegate()
subscription=this.getData()
this.subscription=new SubscriptionView({},subscription)
this.controls=new SubscriptionControls({},subscription)
this.forwardEvents(this.controls,["PlanChangeRequested","UnsubscribeRequested","ReactivateRequested"])}__extends(AccountSubscriptionsListItem,_super)
AccountSubscriptionsListItem.prototype.viewAppended=JView.prototype.viewAppended
AccountSubscriptionsListItem.prototype.setProductComponents=function(subscription,components){return this.addSubView(new SubscriptionUsageView({subscription:subscription,components:components}))}
AccountSubscriptionsListItem.prototype.pistachio=function(){return"<div class='payment-details'>\n  {{> this.subscription}}\n  {{> this.controls}}\n</div>"}
return AccountSubscriptionsListItem}(KDListItemView)
SubscriptionControls=function(_super){function SubscriptionControls(){_ref=SubscriptionControls.__super__.constructor.apply(this,arguments)
return _ref}__extends(SubscriptionControls,_super)
SubscriptionControls.prototype.getStatusInfo=function(subscription){null==subscription&&(subscription=this.getData())
switch(subscription.status){case"active":case"future":return{text:"unsubscribe",event:"UnsubscribeRequested",showChange:!0}
case"canceled":case"expired":return{text:"reactivate",event:"ReactivateRequested",showChange:!1}}}
SubscriptionControls.prototype.viewAppended=function(){var event,showChange,text,_ref1,_this=this
this.unsetClass("kdview")
this.setClass("controls")
_ref1=this.getStatusInfo(),text=_ref1.text,event=_ref1.event,showChange=_ref1.showChange
if(showChange){this.changeLink=new CustomLinkView({title:"change plan",click:function(e){e.preventDefault()
return _this.emit("PlanChangeRequested")}})
this.addSubView(this.changeLink)
this.setPartial(" | ")}this.statusLink=new CustomLinkView({title:text,click:function(e){e.preventDefault()
return _this.emit(event)}})
return this.addSubView(this.statusLink)}
return SubscriptionControls}(JView)

var AccountReferralSystemList,AccountReferralSystemListController,AccountReferralSystemListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountReferralSystemListController=function(_super){function AccountReferralSystemListController(options,data){options.noItemFoundText="You dont have any referal."
AccountReferralSystemListController.__super__.constructor.call(this,options,data)}__extends(AccountReferralSystemListController,_super)
AccountReferralSystemListController.prototype.loadItems=function(){var options,query,_this=this
this.removeAllItems()
this.showLazyLoader(!0)
query={type:"disk"}
options={limit:20}
KD.remote.api.JReferral.fetchReferredAccounts(query,options,function(err,referals){return err?KD.showError(err):_this.instantiateListItems(referals||[])})
this.hideLazyLoader()
this.on("RedeemReferralPointSubmitted",this.bound("redeemReferralPoint"))
return this.on("ShowRedeemReferralPointModal",this.bound("showRedeemReferralPointModal"))}
AccountReferralSystemListController.prototype.notify_=function(message){return new KDNotificationView({title:message,duration:2500})}
AccountReferralSystemListController.prototype.redeemReferralPoint=function(modal){var data,sizes,vmToResize,_ref,_this=this
_ref=modal.modal.modalTabs.forms.Redeem.inputs,vmToResize=_ref.vmToResize,sizes=_ref.sizes
data={vmName:vmToResize.getValue(),size:sizes.getValue(),type:"disk"}
return KD.remote.api.JReferral.redeem(data,function(err,refRes){if(err)return KD.showError(err)
modal.modal.destroy()
return KD.getSingleton("vmController").resizeDisk(data.vm,function(err){return err?KD.showError(err):_this.notify_(""+refRes.addedSize+" "+refRes.unit+" extra "+refRes.type+" is successfully added to your "+refRes.vm+" VM.")})})}
AccountReferralSystemListController.prototype.showRedeemReferralPointModal=function(){var vmController,_this=this
vmController=KD.getSingleton("vmController")
return vmController.fetchVMs(!0,function(err,vms){return err?KD.showError(err):!vms||vms.length<1?_this.notify_("You don't have any VMs. Please create one VM"):KD.remote.api.JReferral.fetchRedeemableReferrals({type:"disk"},function(err,referals){var modal
return err?KD.showError(err):!referals||referals.length<1?_this.notify_("You dont have any referrals"):_this.modal=modal=new KDModalViewWithForms({title:"Redeem Your Referral Points",content:"",overlay:!0,width:500,height:"auto",tabs:{forms:{Redeem:{callback:function(){_this.modal.modalTabs.forms.Redeem.buttons.redeemButton.showLoader()
return _this.emit("RedeemReferralPointSubmitted",_this)},buttons:{redeemButton:{title:"Redeem",style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12},callback:function(){return this.hideLoader()}},cancel:{title:"Cancel",style:"modal-cancel",callback:function(){return modal.destroy()}}},fields:{vmToResize:{label:"Select a WM to resize",itemClass:KDSelectBox,type:"select",name:"vmToResize",validate:{rules:{required:!0},messages:{required:"You must select a VM!"}},selectOptions:function(cb){var options,vm
options=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=vms.length;_len>_i;_i++){vm=vms[_i]
_results.push({title:vm,value:vm})}return _results}()
return cb(options)}},sizes:{label:"Select Size",itemClass:KDSelectBox,type:"select",name:"size",validate:{rules:{required:!0},messages:{required:"You must select a size!"}},selectOptions:function(cb){var options,previousTotal
options=[]
previousTotal=0
referals.forEach(function(referal){previousTotal+=referal.amount
return options.push({title:""+previousTotal+" "+referal.unit,value:previousTotal})})
return cb(options)}}}}}}})})})}
AccountReferralSystemListController.prototype.loadView=function(){AccountReferralSystemListController.__super__.loadView.apply(this,arguments)
this.addHeader()
return this.loadItems()}
AccountReferralSystemListController.prototype.addHeader=function(){var getYourReferrerCode,redeem,wrapper,_this=this
wrapper=new KDCustomHTMLView({tagName:"header",cssClass:"clearfix"})
this.getView().addSubView(wrapper,"",!0)
wrapper.addSubView(getYourReferrerCode=new CustomLinkView({title:"Get Your Referrer Code",tooltip:{title:"If anyone registers with your referrer code,\nyou will get 250MB Free disk space for your VM.\nUp to 16GB!."},click:function(){var appManager
appManager=KD.getSingleton("appManager")
return appManager.tell("Account","showReferrerModal",{linkView:getYourReferrerCode,top:50,left:35,arrowMargin:110})}}))
return wrapper.addSubView(redeem=new CustomLinkView({title:"Redeem Your Referrer Points",click:function(){return _this.emit("ShowRedeemReferralPointModal",_this)}}))}
return AccountReferralSystemListController}(AccountListViewController)
AccountReferralSystemList=function(_super){function AccountReferralSystemList(options,data){options=$.extend({tagName:"ul",itemClass:AccountReferralSystemListItem},options)
AccountReferralSystemList.__super__.constructor.call(this,options,data)}__extends(AccountReferralSystemList,_super)
return AccountReferralSystemList}(KDListView)
AccountReferralSystemListItem=function(_super){function AccountReferralSystemListItem(options,data){options={tagName:"li"}
AccountReferralSystemListItem.__super__.constructor.call(this,options,data)}__extends(AccountReferralSystemListItem,_super)
AccountReferralSystemListItem.prototype.viewAppended=function(){var _this=this
return this.getData().isEmailVerified(function(err,status){var editLink
err||status||_this.addSubView(editLink=new KDCustomHTMLView({tagName:"a",partial:"Mail Verification Waiting",cssClass:"action-link"}))
return AccountReferralSystemListItem.__super__.viewAppended.apply(_this,arguments)})}
AccountReferralSystemListItem.prototype.partial=function(data){return'<a href="/'+data.profile.nickname+'"> '+data.profile.firstName+" "+data.profile.lastName+" </a>"}
return AccountReferralSystemListItem}(KDListItemView)

var DeleteAccountView,DeleteModalView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__bind=function(fn,me){return function(){return fn.apply(me,arguments)}}
DeleteAccountView=function(_super){function DeleteAccountView(options,data){options.cssClass="delete-account-view"
DeleteAccountView.__super__.constructor.call(this,options,data)
this.button=new KDButtonView({title:"Delete Account",cssClass:"delete-account solid red fr",bind:"mouseenter",mouseenter:function(){var times
times=0
return function(){var _this=this
switch(times){case 0:this.setTitle("Are you sure?!")
break
case 1:this.setTitle("OK, go ahead :)")
break
default:KD.utils.wait(5e3,function(){times=0
return _this.setTitle("Delete Account")})
return}this.toggleClass("escape")
return times++}}(),callback:function(){return new DeleteModalView}})}__extends(DeleteAccountView,_super)
DeleteAccountView.prototype.pistachio=function(){return"<span>Delete your account (if you can)</span>\n{{> this.button}}"}
return DeleteAccountView}(JView)
DeleteModalView=function(_super){function DeleteModalView(options,data){var _this=this
null==options&&(options={})
this.checkUserName=__bind(this.checkUserName,this)
data=KD.nick()
options.title||(options.title="Please confirm account deletion")
options.content||(options.content="<div class='modalformline'><p><strong>CAUTION! </strong>This will destroy everything you have on Koding, including your data on your VM(s). This action <strong>CANNOT</strong> be undone.</p><br><p>Please enter <strong>"+data+"</strong> into the field below to continue: </p></div>")
null==options.callback&&(options.callback=function(){return log(""+options.action+" performed")})
null==options.overlay&&(options.overlay=!0)
null==options.width&&(options.width=500)
null==options.height&&(options.height="auto")
null==options.tabs&&(options.tabs={forms:{dangerForm:{callback:function(){var JUser,confirmButton,dangerForm,username
JUser=KD.remote.api.JUser
dangerForm=_this.modalTabs.forms.dangerForm
username=dangerForm.inputs.username
confirmButton=dangerForm.buttons.confirmButton
return JUser.unregister(username.getValue(),function(err){if(err)new KDNotificationView({title:"There was a problem, please try again!"})
else{new KDNotificationView({title:"Thank you for trying Koding!"})
KD.mixpanel("Deleted account")
KD.utils.wait(2e3,function(){$.cookie("clientId",{erase:!0})
return location.replace("/")})}return confirmButton.hideLoader()})},buttons:{confirmButton:{title:"Delete Account",style:"modal-clean-red",type:"submit",disabled:!0,loader:{color:"#ffffff",diameter:15},callback:function(){return this.showLoader()}},Cancel:{style:"modal-cancel",callback:this.bound("destroy")}},fields:{username:{placeholder:"Enter '"+data+"' to confirm...",validate:{rules:{required:!0,keyupCheck:function(input){return _this.checkUserName(input,!1)},finalCheck:function(input){return _this.checkUserName(input)}},messages:{required:"Please enter your username"},events:{required:"blur",keyupCheck:"keyup",finalCheck:"blur"}}}}}}})
DeleteModalView.__super__.constructor.call(this,options,data)}__extends(DeleteModalView,_super)
DeleteModalView.prototype.checkUserName=function(input,showError){null==showError&&(showError=!0)
if(input.getValue()===this.getData()){input.setValidationResult("keyupCheck",null)
return this.modalTabs.forms.dangerForm.buttons.confirmButton.enable()}this.modalTabs.forms.dangerForm.buttons.confirmButton.disable()
return input.setValidationResult("keyupCheck","Sorry, entered value does not match your username!",showError)}
return DeleteModalView}(KDModalViewWithForms)

var GmailContactsListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GmailContactsListItem=function(_super){function GmailContactsListItem(options,data){null==options&&(options={})
options.type="gmail"
GmailContactsListItem.__super__.constructor.call(this,options,data)
this.on("InvitationSent",this.bound("decorateInvitationSent"))}__extends(GmailContactsListItem,_super)
GmailContactsListItem.prototype.click=function(){var data,_this=this
data=this.getData()
return data.invite(function(err){if(err)return log(err)
_this.decorateInvitationSent()
return KD.kdMixpanel.track("User Sent Invitation",{$user:KD.nick(),count:1})})}
GmailContactsListItem.prototype.decorateInvitationSent=function(){this.setClass("invitation-sent")
return this.getData().invited=!0}
GmailContactsListItem.prototype.setAvatar=function(){var fallback,hash,uri
hash=md5.digest(this.getData().email)
fallback=""+KD.apiUri+"/images/defaultavatar/default.avatar.25.png"
uri="url(//gravatar.com/avatar/"+hash+"?size=25&d="+encodeURIComponent(fallback)+")"
return this.$(".avatar").css("background-image",uri)}
GmailContactsListItem.prototype.viewAppended=function(){JView.prototype.viewAppended.call(this)
this.getData().invited&&this.setClass("already-invited")
return this.setAvatar()}
GmailContactsListItem.prototype.pistachio=function(){var email,title,_ref
_ref=this.getData(),email=_ref.email,title=_ref.title
return'<div class="avatar"></div>\n<div class="contact-info">\n  <span class="full-name">'+(title||"Gmail Contact")+'</span>\n  {{#(email)}}\n</div>\n<div class="invitation-sent-overlay">\n  <span class="checkmark"></span>\n  <span class="title">Invitation is sent to</span>\n  <span class="email">'+email+"</span>\n</div>"}
return GmailContactsListItem}(KDListItemView)

var ReferrerModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ReferrerModal=function(_super){function ReferrerModal(options,data){var facebook,gmail,leftColumn,rightColumn,shareLinks,twitter,urlInput,urlLabel,usageWrapper,vmc,_ref,_this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("referrer-modal",options.cssClass)
options.width=570
null==options.overlay&&(options.overlay=!0)
options.title="Get free disk space!"
options.url||(options.url=KD.getReferralUrl(KD.nick()))
null==options.onlyInviteTab&&(options.onlyInviteTab=!1)
options.tabs={navigable:!1,goToNextFormOnSubmit:!1,hideHandleContainer:!0,forms:{share:{customView:KDCustomHTMLView,cssClass:"clearfix",partial:"<p class='description'>For each person registers with your referral code,             you'll get <strong>250 MB</strong> free disk space for your VM, up to <strong>16 GB</strong> total."},invite:{customView:KDCustomHTMLView}}}
options.onlyInviteTab&&(options.cssClass=KD.utils.curry("hidden",options.cssClass))
ReferrerModal.__super__.constructor.call(this,options,data)
_ref=this.modalTabs.forms,this.share=_ref.share,this.invite=_ref.invite
this.share.addSubView(usageWrapper=new KDCustomHTMLView({cssClass:"disk-usage-wrapper"}))
vmc=KD.getSingleton("vmController")
vmc.fetchDefaultVmName(function(name){return vmc.fetchDiskUsage(name,function(usage){return usage.max?usageWrapper.addSubView(new KDLabelView({title:"You've claimed <strong>"+KD.utils.formatBytesToHumanReadable(usage.max)+"</strong>            of your free <strong>16 GB</strong> disk space."})):void 0})})
this.share.addSubView(leftColumn=new KDCustomHTMLView({cssClass:"left-column"}))
this.share.addSubView(rightColumn=new KDCustomHTMLView({cssClass:"right-column"}))
leftColumn.addSubView(urlLabel=new KDLabelView({cssClass:"share-url-label",title:"Here is your invite code"}))
leftColumn.addSubView(urlInput=new KDInputView({defaultValue:options.url,cssClass:"share-url-input",attributes:{readonly:"true"},click:function(){return this.selectAll()}}))
leftColumn.addSubView(shareLinks=new KDCustomHTMLView({cssClass:"share-links",partial:"<span>Share your code on</span>"}))
shareLinks.addSubView(new TwitterShareLink({url:options.url}))
shareLinks.addSubView(new FacebookShareLink({url:options.url}))
shareLinks.addSubView(new LinkedInShareLink({url:options.url}))
rightColumn.addSubView(gmail=new KDButtonView({title:"Invite Gmail Contacts",style:"invite-button gmail",icon:!0,callback:this.bound("checkGoogleLinkStatus")}))
rightColumn.addSubView(facebook=new KDButtonView({title:"Invite Facebook Friends",style:"invite-button facebook hidden",disabled:!0,icon:!0}))
rightColumn.addSubView(twitter=new KDButtonView({title:"Invite Twitter Friends",style:"invite-button twitter hidden",disabled:!0,icon:!0}))
KD.getSingleton("mainController").once("ForeignAuthSuccess.google",function(data){return _this.showGmailContactsList(data)})}__extends(ReferrerModal,_super)
ReferrerModal.prototype.checkGoogleLinkStatus=function(){var _this=this
return KD.whoami().fetchStorage("ext|profile|google",function(err,account){return err?void 0:account?_this.showGmailContactsList():KD.singletons.oauthController.openPopup("google")})}
ReferrerModal.prototype.showGmailContactsList=function(){var footer,goBack,listController,warning,_this=this
listController=new KDListViewController({startWithLazyLoader:!0,view:new KDListView({type:"gmail",cssClass:"contact-list",itemClass:GmailContactsListItem})})
listController.once("AllItemsAddedToList",function(){return this.hideLazyLoader()})
this.invite.addSubView(listController.getView())
this.invite.addSubView(footer=new KDCustomHTMLView({cssClass:"footer"}))
footer.addSubView(warning=new KDLabelView({cssClass:"hidden",title:"This will send invitation to all contacts listed in here, do you confirm?"}))
footer.addSubView(goBack=new KDButtonView({title:"Go back",style:"clean-gray hidden",callback:function(){return _this.modalTabs.showPaneByName("share")}}))
KD.remote.api.JReferrableEmail.getUninvitedEmails(function(err,contacts){if(err){log(err)
_this.destroy()
return new KDNotificationView({title:"An error occurred",subtitle:"Please try again later"})}if(0===contacts.length){new KDNotificationView({title:"Your all contacts are already invited. Thanks!"})
return _this.getOptions().onlyInviteTab?_this.destroy():_this.modalTabs.showPaneByName("share")}_this.setTitle("Invite your friends from Gmail")
_this.show()
_this.modalTabs.showPaneByName("invite")
return listController.instantiateListItems(contacts)})
return this.setPositions()}
ReferrerModal.prototype.track=function(count){return KD.kdMixpanel.track("User Sent Invitation",{$user:KD.nick(),count:count})}
return ReferrerModal}(KDModalViewWithForms)

var AccountListWrapper,AccountNavigationItem,AccountsSwappable,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AccountListWrapper=function(_super){function AccountListWrapper(){_ref=AccountListWrapper.__super__.constructor.apply(this,arguments)
return _ref}var listClasses
__extends(AccountListWrapper,_super)
listClasses={username:AccountEditUsername,security:AccountEditSecurity,emailNotifications:AccountEmailNotifications,linkedAccountsController:AccountLinkedAccountsListController,linkedAccounts:AccountLinkedAccountsList,referralSystemController:AccountReferralSystemListController,referralSystem:AccountReferralSystemList,historyController:AccountPaymentHistoryListController,history:AccountPaymentHistoryList,methodsController:AccountPaymentMethodsListController,methods:AccountPaymentMethodsList,subscriptionsController:AccountSubscriptionsListController,subscriptions:AccountSubscriptionsList,editorsController:AccountEditorListController,editors:AccountEditorList,keysController:AccountSshKeyListController,keys:AccountSshKeyList,kodingKeysController:AccountKodingKeyListController,kodingKeys:AccountKodingKeyList,deleteAccount:DeleteAccountView}
AccountListWrapper.prototype.viewAppended=function(){var controller,controllerClass,listHeader,listType,listViewClass,type,view,_ref1
_ref1=this.getData(),listType=_ref1.listType,listHeader=_ref1.listHeader
this.addSubView(this.header=new KDHeaderView({type:"medium",title:listHeader}))
type=listType?listType||"":void 0
listViewClass=listClasses[type]?listClasses[type]:KDListView
controllerClass=listClasses[""+type+"Controller"]?listClasses[""+type+"Controller"]:void 0
this.addSubView(view=new listViewClass({cssClass:type,delegate:this}))
return controllerClass?controller=new controllerClass({view:view,wrapper:!1,scrollView:!1}):void 0}
return AccountListWrapper}(KDView)
AccountNavigationItem=function(_super){function AccountNavigationItem(options,data){null==options&&(options={})
options.tagName="a"
options.attributes={href:"/Account/"+data.slug}
AccountNavigationItem.__super__.constructor.call(this,options,data)
this.name=this.getData().title}__extends(AccountNavigationItem,_super)
AccountNavigationItem.prototype.partial=function(data){return data.title}
return AccountNavigationItem}(KDListItemView)
AccountsSwappable=function(_super){function AccountsSwappable(options){options=$.extend({views:[]},options)
AccountsSwappable.__super__.constructor.apply(this,arguments)
this.setClass("swappable")
this.addSubView(this.view1=this.options.views[0]).hide()
this.addSubView(this.view2=this.options.views[1])}__extends(AccountsSwappable,_super)
AccountsSwappable.prototype.swapViews=function(){if(this.view1.$().is(":visible")){this.view1.hide()
return this.view2.show()}this.view1.show()
return this.view2.hide()}
return AccountsSwappable}(KDView)

//@ sourceMappingURL=/js/__app.account.0.0.1.js.map