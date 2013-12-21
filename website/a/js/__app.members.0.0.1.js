var ContentDisplayControllerMember,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayControllerMember=function(_super){function ContentDisplayControllerMember(options,data){var mainView
null==options&&(options={})
this.revivedContentDisplay=KD.singleton("display").revivedContentDisplay
options=$.extend({view:mainView=new KDView({cssClass:"member content-display",domId:this.revivedContentDisplay?void 0:"member-contentdisplay",type:"profile"})},options)
ContentDisplayControllerMember.__super__.constructor.call(this,options,data)}__extends(ContentDisplayControllerMember,_super)
ContentDisplayControllerMember.prototype.loadView=function(mainView){var lazy,member,viewClass
member=this.getData()
lazy=mainView.lazy
mainView.once("KDObjectWillBeDestroyed",function(){return KD.singleton("appManager").tell("Activity","resetProfileLastTo")})
this.addProfileView(member)
if(lazy){viewClass=KD.isLoggedIn()?KDCustomHTMLView:HomeLoginBar
mainView.addSubView(this.homeLoginBar=new viewClass({domId:"home-login-bar"}))
KD.isLoggedIn()&&this.homeLoginBar.hide()}return this.addActivityView(member)}
ContentDisplayControllerMember.prototype.addProfileView=function(member){var memberProfile,options
options={cssClass:"profilearea clearfix",domId:this.revivedContentDisplay?void 0:"profilearea",delegate:this.getView()}
KD.isMine(member)?options.cssClass=KD.utils.curry("own-profile",options.cssClass):KD.isMine(member)||(options.bind="mouseenter")
return this.getView().addSubView(memberProfile=new ProfileView(options,member))}
ContentDisplayControllerMember.prototype.createFilter=function(title,account,facets){var filter
filter={title:title,dataSource:function(selector,options,callback){options.originId=account.getId()
options.facet=facets
return KD.getSingleton("appManager").tell("Activity","fetchActivitiesProfilePage",options,callback)}}
return filter}
ContentDisplayControllerMember.prototype.addActivityView=function(account){var windowController,_this=this
this.getView().$("div.lazy").remove()
windowController=KD.getSingleton("windowController")
return KD.getSingleton("appManager").tell("Activity","feederBridge",{domId:this.revivedContentDisplay?void 0:"members-feeder-split-view",itemClass:ActivityListItemView,listControllerClass:ActivityListController,listCssClass:"activity-related",limitPerPage:8,useHeaderNav:!0,delegate:this.getDelegate(),filter:{statuses:this.createFilter("Status Updates",account,"JNewStatusUpdate")},sort:{likesCount:{title:"Most popular",direction:-1},modifiedAt:{title:"Latest activity",direction:-1},repliesCount:{title:"Most commented",direction:-1}}},function(controller){_this.feedController=controller
_this.getView().addSubView(controller.getView())
_this.getView().setCss({minHeight:windowController.winHeight})
return _this.emit("ready")})}
return ContentDisplayControllerMember}(KDViewController)

var MemberMailLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MemberMailLink=function(_super){function MemberMailLink(options,data){options=$.extend({tagName:"a",attributes:{href:"#"}},options)
MemberMailLink.__super__.constructor.call(this,options,data)}__extends(MemberMailLink,_super)
MemberMailLink.prototype.viewAppended=function(){MemberMailLink.__super__.viewAppended.apply(this,arguments)
this.setTemplate(this.pistachio())
return this.template.update()}
MemberMailLink.prototype.pistachio=function(){var name
name=KD.utils.getFullnameFromAccount(this.getData(),!0)
return"<cite/><span>Contact "+name+"</span>"}
MemberMailLink.prototype.click=function(event){var member,profile
event.preventDefault()
profile=(member=this.getData()).profile
return KD.getSingleton("appManager").tell("Inbox","createNewMessageModal",[member])}
return MemberMailLink}(KDCustomHTMLView)

var ExternalProfileView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ExternalProfileView=function(_super){function ExternalProfileView(options,account){var mainController,provider
options.tagName||(options.tagName="a")
options.provider||(options.provider="")
options.cssClass=KD.utils.curry("external-profile "+options.provider,options.cssClass)
options.attributes={href:"#"}
ExternalProfileView.__super__.constructor.call(this,options,account)
this.linked=!1
provider=this.getOptions().provider
mainController=KD.getSingleton("mainController")
mainController.on("ForeignAuthSuccess."+provider,this.bound("setLinkedState"))}__extends(ExternalProfileView,_super)
ExternalProfileView.prototype.viewAppended=function(){ExternalProfileView.__super__.viewAppended.apply(this,arguments)
this.setTooltip({title:"Click to link your "+this.getOption("nicename")+" account"})
return this.setLinkedState()}
ExternalProfileView.prototype.setLinkedState=function(){var account,firstName,nicename,provider,_ref,_this=this
if(this.parent){account=this.parent.getData()
firstName=account.profile.firstName
_ref=this.getOptions(),provider=_ref.provider,nicename=_ref.nicename
return account.fetchStorage("ext|profile|"+provider,function(err,storage){var urlLocation
if(err)return warn(err)
if(storage&&(urlLocation=_this.getOption("urlLocation"))){_this.setData(storage)
_this.$().detach()
_this.$().prependTo(_this.parent.$(".external-profiles"))
_this.linked=!0
_this.setClass("linked")
_this.setAttributes({href:JsPath.getAt(storage.content,urlLocation),target:"_blank"})
return _this.setTooltip(KD.isMine(account)?{title:"Go to my "+nicename+" profile"}:{title:"Go to "+firstName+"'s "+nicename+" profile"})}})}}
ExternalProfileView.prototype.click=function(event){var provider
if(!this.linked){provider=this.getOptions().provider
if(KD.isMine(this.parent.getData())){KD.utils.stopDOMEvent(event)
return KD.singletons.oauthController.openPopup(provider)}}}
ExternalProfileView.prototype.pistachio=function(){return'<span class="icon"></span>'}
return ExternalProfileView}(JView)

var AvatarChangeHeaderView,AvatarChangeView,ProfileView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__bind=function(fn,me){return function(){return fn.apply(me,arguments)}}
AvatarChangeHeaderView=function(_super){function AvatarChangeHeaderView(options,data){null==options&&(options={})
options.tagName="article"
options.cssClass="avatar-change-header"
AvatarChangeHeaderView.__super__.constructor.call(this,options,data)}__extends(AvatarChangeHeaderView,_super)
AvatarChangeHeaderView.prototype.viewAppended=function(){var button,options,_i,_len,_ref,_ref1,_results
AvatarChangeHeaderView.__super__.viewAppended.apply(this,arguments)
options=this.getOptions()
options.title&&this.addSubView(new KDCustomHTMLView({tagName:"strong",partial:options.title}))
if((null!=(_ref=options.buttons)?_ref.length:void 0)>0){_ref1=options.buttons
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){button=_ref1[_i]
_results.push(this.addSubView(button))}return _results}}
return AvatarChangeHeaderView}(JView)
AvatarChangeView=function(_super){function AvatarChangeView(options,data){var action,isDNDSupported,isVideoSupported,view,_ref,_ref1,_this=this
null==options&&(options={})
this.setAvatar=__bind(this.setAvatar,this)
this.updateAvatarImage=__bind(this.updateAvatarImage,this)
this.setAvatarPreviewImage=__bind(this.setAvatarPreviewImage,this)
this.setAvatarImage=__bind(this.setAvatarImage,this)
options.cssClass="avatar-change-menu"
AvatarChangeView.__super__.constructor.call(this,options,data)
_ref=detectFeatures(),isVideoSupported=_ref.isVideoSupported,isDNDSupported=_ref.isDNDSupported
this.on("viewAppended",function(){return _this.overlay=new KDOverlayView({isRemovable:!1,parent:"body"})})
this.on("KDObjectWillBeDestroyed",function(){return _this.overlay.destroy()})
this.avatarData=null
this.avatarPreviewData=null
this.webcamTip=new KDView({cssClass:"webcam-tip",partial:"<cite>Please allow Koding to access your camera.</cite>"})
this.takePhotoButton=new CustomLinkView({cssClass:"take-photo hidden",title:"Take Photo"})
this.photoRetakeButton=new KDButtonView({cssClass:"clean-gray confirm avatar-button",icon:!0,iconOnly:!0,iconClass:"cross",callback:function(){_this.changeHeader("photo")
_this.takePhotoButton.show()
return _this.webcamView.reset()}})
this.reuploadButton=new KDButtonView({cssClass:"clean-gray confirm avatar-button",icon:!0,iconOnly:!0,iconClass:"cross",callback:this.bound("showUploadView")})
this.photoButton=new KDButtonView({cssClass:"clean-gray avatar-button",title:"Take Photo",disabled:!isVideoSupported,callback:this.bound("showPhotoView")})
this.uploadButton=new KDButtonView({cssClass:"clean-gray avatar-button",disabled:!isDNDSupported,title:"Upload Image",callback:this.bound("showUploadView")})
this.gravatarButton=new KDButtonView({cssClass:"clean-gray avatar-button",title:"Use Gravatar",callback:function(){_this.avatarPreviewData=_this.avatar.getGravatarUri()
_this.setAvatarPreviewImage()
_this.unsetWide()
return _this.changeHeader("gravatar")}})
this.gravatarConfirmButton=new KDButtonView({cssClass:"clean-gray confirm avatar-button",icon:!0,iconOnly:!0,iconClass:"okay",callback:function(){_this.emit("UseGravatar")
return _this.changeHeader()}})
this.avatarHolder=new KDCustomHTMLView({cssClass:"avatar-holder",tagName:"div"})
this.avatarHolder.addSubView(this.avatar=new AvatarStaticView({size:{width:300,height:300}},this.getData()))
this.loader=new KDLoaderView({size:{width:15},loaderOptions:{color:"#ffffff",shape:"spiral"}})
this.cancelPhoto=this.getCancelView()
this.headers={actions:new AvatarChangeHeaderView({buttons:[this.photoButton,this.uploadButton,this.gravatarButton]}),gravatar:new AvatarChangeHeaderView({title:"Use Gravatar",buttons:[this.getCancelView(),this.gravatarConfirmButton]}),photo:new AvatarChangeHeaderView({title:"Take Photo",buttons:[this.cancelPhoto]}),upload:new AvatarChangeHeaderView({title:"Upload Image",buttons:[this.getCancelView()]}),phototaken:new AvatarChangeHeaderView({title:"Take Photo",buttons:[this.getCancelView(),this.photoRetakeButton,this.getConfirmView()]}),imagedropped:new AvatarChangeHeaderView({title:"Upload Image",buttons:[this.getCancelView(),this.reuploadButton,this.getConfirmView()]}),loading:new AvatarChangeHeaderView({title:"Uploading and resizing your avatar, please wait...",buttons:[this.loader]})}
this.wrapper=new KDCustomHTMLView({tagName:"section",cssClass:"wrapper"})
_ref1=this.headers
for(action in _ref1){view=_ref1[action]
this.wrapper.addSubView(view)}this.on("LoadingEnd",function(){return _this.changeHeader()})
this.on("LoadingStart",function(){_this.changeHeader("loading")
return _this.unsetWide()})
this.once("viewAppended",function(){_this.slideDownAvatar()
return _this.loader.show()})}var detectFeatures
__extends(AvatarChangeView,_super)
detectFeatures=function(){var isDNDSupported,isVideoSupported
isVideoSupported=KDWebcamView.getUserMediaVendor()
isDNDSupported=function(){var tester
tester=document.createElement("div")
return"draggable"in tester||"ondragstart"in tester&&"ondrop"in tester}()
return{isVideoSupported:isVideoSupported,isDNDSupported:isDNDSupported}}
AvatarChangeView.prototype.showUploadView=function(){var _this=this
this.avatarData=this.avatar.getAvatar()
this.changeHeader("upload")
this.resetView()
this.unsetWide()
this.avatar.hide()
this.avatarHolder.addSubView(this.uploaderView=new DNDUploader({title:"Drag and drop your avatar here!",uploadToVM:!1,size:{height:280}}))
return this.uploaderView.on("dropFile",function(_arg){var content,origin
origin=_arg.origin,content=_arg.content
if("external"===origin){_this.resetView()
_this.avatarPreviewData="data:image/png;base64,"+btoa(content)
_this.changeHeader("imagedropped")
return _this.setAvatarPreviewImage()}})}
AvatarChangeView.prototype.showPhotoView=function(){var release,_this=this
this.avatarData=this.avatar.getAvatar()
this.changeHeader("photo")
this.resetView()
this.avatar.hide()
this.avatarHolder.addSubView(this.webcamTip)
this.setWide()
this.cancelPhoto.disable()
this.getDelegate().avatarMenu.changeStickyState(!0)
release=function(){_this.cancelPhoto.enable()
return _this.getDelegate().avatarMenu.changeStickyState(!1)}
this.avatarHolder.addSubView(this.webcamView=new KDWebcamView({hideControls:!0,countdown:3,snapTitle:"Take Avatar Picture",size:{width:300},click:function(){_this.webcamView.takePicture()
_this.takePhotoButton.hide()
return _this.changeHeader("phototaken")}}))
this.webcamView.addSubView(this.takePhotoButton)
this.webcamView.on("snap",function(data){return _this.avatarPreviewData=data})
this.webcamView.on("allowed",function(){release()
_this.webcamTip.destroy()
return _this.takePhotoButton.show()})
return this.webcamView.on("forbidden",function(){release()
return _this.webcamTip.updatePartial("<cite>\n  You disabled the camera for Koding.\n  <a href='https://support.google.com/chrome/answer/2693767?hl=en' target='_blank'>How to fix?</a>\n</cite>")})}
AvatarChangeView.prototype.resetView=function(){var _ref,_ref1
null!=(_ref=this.webcamView)&&_ref.destroy()
this.webcamTip.destroy()
null!=(_ref1=this.uploaderView)&&_ref1.destroy()
this.unsetWide()
return this.avatar.show()}
AvatarChangeView.prototype.setWide=function(){this.avatarHolder.setClass("wide")
return this.avatar.setSize({width:300,height:225})}
AvatarChangeView.prototype.unsetWide=function(){this.avatarHolder.unsetClass("wide")
return this.avatar.setSize({width:300,height:300})}
AvatarChangeView.prototype.setAvatarImage=function(){return this.updateAvatarImage(this.avatarData)}
AvatarChangeView.prototype.setAvatarPreviewImage=function(){this.avatarData=this.avatar.getAvatar()
return this.updateAvatarImage(this.avatarPreviewData)}
AvatarChangeView.prototype.updateAvatarImage=function(imageData){this.avatar.setAvatar(""+imageData)
return this.avatar.setSize({width:300,height:300})}
AvatarChangeView.prototype.setAvatar=function(){this.setAvatarImage()
this.avatar.show()
return this.emit("UsePhoto",this.avatarData)}
AvatarChangeView.prototype.getConfirmView=function(){var _this=this
return new KDButtonView({cssClass:"clean-gray confirm avatar-button",icon:!0,iconOnly:!0,iconClass:"okay",callback:function(){_this.avatarData=_this.avatarPreviewData
_this.avatarPreviewData=null
return _this.setAvatar()}})}
AvatarChangeView.prototype.getCancelView=function(callback){var _this=this
return new KDButtonView({cssClass:"clean-gray cancel avatar-button",title:"Cancel",callback:function(){_this.changeHeader("actions")
_this.resetView()
_this.avatarPreviewData=null
_this.setAvatarImage()
return"function"==typeof callback?callback():void 0}})}
AvatarChangeView.prototype.slideDownAvatar=function(){return this.avatarHolder.setClass("opened")}
AvatarChangeView.prototype.slideUpAvatar=function(){return this.avatarHolder.unsetClass("opened")}
AvatarChangeView.prototype.changeHeader=function(viewname){var action,view,_ref,_ref1,_ref2
null==viewname&&(viewname="actions")
_ref=this.headers
for(action in _ref){view=_ref[action]
null!=(_ref1=this.headers[action])&&_ref1.hide()}return null!=(_ref2=this.headers[viewname])?_ref2.show():void 0}
AvatarChangeView.prototype.pistachio=function(){return'<i class="arrow"></i>\n{{> this.wrapper}}\n{{> this.avatarHolder}}'}
return AvatarChangeView}(JView)
ProfileView=function(_super){function ProfileView(options,data){var avatarOptions,input,mainController,route,userDomain,_base,_i,_j,_len,_len1,_ref,_ref1,_ref2,_this=this
null==options&&(options={})
ProfileView.__super__.constructor.call(this,options,data)
this.memberData=this.getData()
mainController=KD.getSingleton("mainController")
if(KD.checkFlag("exempt",this.memberData)&&!KD.checkFlag("super-admin"))return KD.getSingleton("router").handleRoute("/Activity")
this.editLink=KD.isMine(this.memberData)?new CustomLinkView({title:"Edit your profile",icon:{cssClass:"edit",placement:"right"},testPath:"profile-edit-button",cssClass:"edit",click:this.bound("edit")}):new KDCustomHTMLView
this.saveButton=new KDButtonView({testPath:"profile-save-button",cssClass:"save hidden",style:"cupid-green",title:"Save",callback:this.bound("save")})
this.cancelButton=new CustomLinkView({title:"Cancel",cssClass:"cancel hidden",click:this.bound("cancel")})
this.firstName=new KDContentEditableView({tagName:"span",testPath:"profile-first-name",pistachio:"{{#(profile.firstName) || ''}}",cssClass:"firstName",placeholder:"First name",delegate:this,validate:{rules:{required:!0,maxLength:25},messages:{required:"First name is required"}}},this.memberData)
this.lastName=new KDContentEditableView({tagName:"span",testPath:"profile-last-name",pistachio:"{{#(profile.lastName) || ''}}",cssClass:"lastName",placeholder:"Last name",delegate:this,validate:{rules:{maxLength:25}}},this.memberData);(_base=this.memberData).locationTags||(_base.locationTags=[])
this.location=new KDContentEditableView({testPath:"profile-location",pistachio:"{{#(locationTags)}}",cssClass:"location",placeholder:"Earth","default":"Earth",delegate:this},this.memberData)
this.bio=new KDContentEditableView({testPath:"profile-bio",pistachio:"{{this.utils.applyTextExpansions(#(profile.about), true)}}",cssClass:"bio",placeholder:KD.isMine(this.memberData)?"You haven't entered anything in your bio yet. Why not add something now?":"",textExpansion:!0,delegate:this,click:function(event){return KD.utils.showMoreClickHandler(event)}},this.memberData)
this.firstName.on("NextTabStop",function(){return _this.lastName.focus()})
this.firstName.on("PreviousTabStop",function(){return _this.bio.focus()})
this.lastName.on("NextTabStop",function(){return _this.location.focus()})
this.lastName.on("PreviousTabStop",function(){return _this.firstName.focus()})
this.location.on("NextTabStop",function(){return _this.bio.focus()})
this.location.on("PreviousTabStop",function(){return _this.lastName.focus()})
this.bio.on("NextTabStop",function(){return _this.firstName.focus()})
this.bio.on("PreviousTabStop",function(){return _this.lastName.focus()})
_ref=[this.firstName,this.lastName,this.location,this.bio]
for(_i=0,_len=_ref.length;_len>_i;_i++){input=_ref[_i]
input.on("click",function(){return!_this.editingMode&&KD.isMine(_this.memberData)?_this.setEditingMode(!0):void 0})}this.skillTagView=KD.isMine(this.memberData||this.memberData.skillTags.length>0)?new SkillTagFormView({},this.memberData):new KDCustomHTMLView
this.skillTagView.on("AutoCompleteNeedsTagData",function(event){var blacklist,callback,inputValue
callback=event.callback,inputValue=event.inputValue,blacklist=event.blacklist
return _this.fetchAutoCompleteDataForTags(inputValue,blacklist,callback)})
avatarOptions={showStatus:!0,size:{width:81,height:81},click:function(){var pos,_ref1
pos={top:_this.avatar.getBounds().y-8,left:_this.avatar.getBounds().x-8}
if(KD.isMine(_this.memberData)){null!=(_ref1=_this.avatarMenu)&&_ref1.destroy()
_this.avatarMenu=new JContextMenu({menuWidth:312,cssClass:"avatar-menu dark",delegate:_this.avatar,x:_this.avatar.getX()+96,y:_this.avatar.getY()-7},{customView:_this.avatarChange=new AvatarChangeView({delegate:_this},_this.memberData)})
_this.avatarChange.on("UseGravatar",function(){return _this.avatarSetGravatar()})
return _this.avatarChange.on("UsePhoto",function(dataURI){var avatarBase64,_,_ref2
_ref2=dataURI.split(","),_=_ref2[0],avatarBase64=_ref2[1]
_this.avatar.setAvatar("url("+dataURI+")")
_this.avatar.$().css({backgroundSize:"auto 90px"})
_this.avatarChange.emit("LoadingStart")
return _this.uploadAvatar(avatarBase64,function(){return _this.avatarChange.emit("LoadingEnd")})})}_this.modal=new KDModalView({cssClass:"avatar-container",width:390,fx:!0,overlay:!0,draggable:!0,position:pos})
return _this.modal.addSubView(_this.bigAvatar=new AvatarStaticView({size:{width:300,height:300}},_this.memberData))}}
KD.isMine(this.memberData)&&(avatarOptions.tooltip={title:"<p class='centertext'>Click avatar to edit</p>",placement:"below",arrow:{placement:"top"}})
this.avatar=new AvatarStaticView(avatarOptions,this.memberData)
userDomain=this.memberData.profile.nickname+"."+KD.config.userSitesDomain
this.userHomeLink=new KDCustomHTMLView({tagName:"a",cssClass:"user-home-link",attributes:{href:"http://"+userDomain,target:"_blank"},pistachio:userDomain,click:function(event){return"online"!==_this.memberData.onlineStatus?KD.utils.stopDOMEvent(event):void 0}})
this.followButton=KD.whoami().getId()===this.memberData.getId()?new KDCustomHTMLView:new MemberFollowToggleButton({style:"solid"},this.memberData)
_ref1=["followers","following","likes"]
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){route=_ref1[_j]
this[route]=this.getActionLink(route,this.memberData)}this.sendMessageLink=new KDCustomHTMLView
KD.isMine(this.memberData)||(this.sendMessageLink=new MemberMailLink({},this.memberData))
if(this.sendMessageLink instanceof MemberMailLink){this.sendMessageLink.on("AutoCompleteNeedsMemberData",function(pubInst,event){var blacklist,callback,inputValue
callback=event.callback,inputValue=event.inputValue,blacklist=event.blacklist
return _this.fetchAutoCompleteForToField(inputValue,blacklist,callback)})
null!=(_ref2=this.sendMessageLink)&&_ref2.on("MessageShouldBeSent",function(_arg){var callback,formOutput
formOutput=_arg.formOutput,callback=_arg.callback
return _this.prepareMessage(formOutput,callback)})}this.trollSwitch=KD.checkFlag("super-admin"&&!KD.isMine(this.memberData))?new KDCustomHTMLView({tagName:"a",partial:KD.checkFlag("exempt",this.memberData)?"Unmark Troll":"Mark as Troll",cssClass:"troll-switch",click:function(){return KD.checkFlag("exempt",_this.memberData)?mainController.unmarkUserAsTroll(_this.memberData):mainController.markUserAsTroll(_this.memberData)}}):new KDCustomHTMLView
this.userBadgesController=new KDListViewController({startWithLazyLoader:!1,view:new KDListView({cssClass:"badge-list",itemClass:UserBadgeView})})
this.memberData.fetchMyBadges(function(err,badges){return _this.userBadgesController.instantiateListItems(badges)})
this.userBadgesView=this.userBadgesController.getView()
this.badgeItemsList=new KDCustomHTMLView
KD.hasAccess("assign badge")&&(this.badgeItemsList=new UserPropertyList({},{counts:this.memberData.counts}))}__extends(ProfileView,_super)
ProfileView.prototype.viewAppended=function(){ProfileView.__super__.viewAppended.apply(this,arguments)
this.createExternalProfiles()
return this.createBadges()}
ProfileView.prototype.uploadAvatar=function(avatarData,callback){var _this=this
return FSHelper.s3.upload("avatar.png",avatarData,function(err,url){var resized
resized=KD.utils.proxifyUrl(url,{crop:!0,width:300,height:300})
return _this.memberData.modify({"profile.avatar":[url,+new Date].join("?")},callback)})}
ProfileView.prototype.avatarSetGravatar=function(callback){return this.memberData.modify({"profile.avatar":""},callback)}
ProfileView.prototype.createExternalProfiles=function(){var appManager,externalProfiles,options,provider,view,_ref,_results
appManager=KD.getSingleton("appManager")
externalProfiles=MembersAppController.externalProfiles
_results=[]
for(provider in externalProfiles)if(__hasProp.call(externalProfiles,provider)){options=externalProfiles[provider]
null!=(_ref=this[""+provider+"View"])&&_ref.destroy()
this[""+provider+"View"]=view=new ExternalProfileView({provider:provider,nicename:options.nicename,urlLocation:options.urlLocation})
_results.push(this.addSubView(view,".external-profiles"))}return _results}
ProfileView.prototype.createBadges=function(){}
ProfileView.prototype.setEditingMode=function(state){this.editingMode=state
this.emit("EditingModeToggled",state)
if(state){this.editLink.hide()
this.saveButton.show()
return this.cancelButton.show()}this.editLink.show()
this.saveButton.hide()
return this.cancelButton.hide()}
ProfileView.prototype.edit=function(event){event&&KD.utils.stopDOMEvent(event)
this.setEditingMode(!0)
return this.firstName.focus()}
ProfileView.prototype.save=function(){var input,_i,_len,_ref,_this=this
_ref=[this.firstName,this.lastName]
for(_i=0,_len=_ref.length;_len>_i;_i++){input=_ref[_i]
if(!input.validate())return}this.setEditingMode(!1)
return this.memberData.modify({"profile.firstName":this.firstName.getValue(),"profile.lastName":this.lastName.getValue(),"profile.about":this.bio.getValue(),locationTags:[this.location.getValue()||"Earth"]},function(err){var message,state
if(err){state="error"
message="There was an error updating your profile"}else{state="success"
message="Your profile is updated"}new KDNotificationView({title:message,type:"mini",cssClass:state,duration:2500})
return _this.utils.defer(function(){return _this.memberData.emit("update")})})}
ProfileView.prototype.cancel=function(event){event&&KD.utils.stopDOMEvent(event)
this.setEditingMode(!1)
return this.memberData.emit("update")}
ProfileView.prototype.getActionLink=function(route){var count,nickname,path,_this=this
count=this.memberData.counts[route]||0
nickname=this.memberData.profile.nickname
path=route[0].toUpperCase()+route.slice(1)
return new KDView({tagName:"a",attributes:{href:"/#"},pistachio:"<span>"+count+"</span>"+path,click:function(event){event.preventDefault()
return 0!==_this.memberData.counts[route]?KD.getSingleton("router").handleRoute("/"+nickname+"/"+path,{state:_this.memberData}):void 0}},this.memberData)}
ProfileView.prototype.fetchAutoCompleteForToField=function(inputValue,blacklist,callback){return KD.remote.api.JAccount.byRelevance(inputValue,{blacklist:blacklist},function(err,accounts){return callback(accounts)})}
ProfileView.prototype.fetchAutoCompleteDataForTags=function(inputValue,blacklist,callback){return KD.remote.api.JTag.byRelevanceForSkills(inputValue,{blacklist:blacklist},function(err,tags){return err?log("there was an error fetching topics "+err.message):"function"==typeof callback?callback(tags):void 0})}
ProfileView.prototype.prepareMessage=function(formOutput,callback){var body,recipients,subject,to
body=formOutput.body,subject=formOutput.subject,recipients=formOutput.recipients
to=recipients.join(" ")
return this.sendMessage({to:to,body:body,subject:subject},function(err,message){new KDNotificationView({title:err?"Failure!":"Success!",duration:1e3})
message.mark("read")
return"function"==typeof callback?callback(err,message):void 0})}
ProfileView.prototype.sendMessage=function(messageDetails,callback){return KD.isGuest()?new KDNotificationView({title:"Sending private message for guests not allowed"}):KD.remote.api.JPrivateMessage.create(messageDetails,callback)}
ProfileView.prototype.putNick=function(nick){return"@"+nick}
ProfileView.prototype.updateUserHomeLink=function(){var _ref
if(this.userHomeLink){if("online"===this.memberData.onlineStatus){this.userHomeLink.unsetClass("offline")
return null!=(_ref=this.userHomeLink.tooltip)?_ref.destroy():void 0}this.userHomeLink.setClass("offline")
return this.userHomeLink.setTooltip({title:""+this.memberData.profile.nickname+"'s VM is offline",placement:"right"})}}
ProfileView.prototype.render=function(){this.updateUserHomeLink()
return ProfileView.__super__.render.apply(this,arguments)}
ProfileView.prototype.pistachio=function(){var account,amountOfDays,onlineStatus
account=this.getData()
amountOfDays=Math.floor((new Date-new Date(account.meta.createdAt))/864e5)
onlineStatus=account.onlineStatus?"online":"offline"
return'<div class="users-profile clearfix">\n  {{> this.avatar}}\n  <h3 class="full-name">{{> this.firstName}} {{> this.lastName}}</h3>\n  {{> this.bio}}\n  {{> this.followButton}}\n  <div class="profilestats">\n    {{> this.followers}}\n    {{> this.following}}\n    {{> this.likes}}\n  </div>\n</div>\n<div class="user-menu">\n  <a href="#" class="active">Open Projects<span class="count">128</span></a>\n  <a href="#">Discussions</a>\n  <a href="#">Tutorials</a>\n  <a href="#">Blog Posts</a>\n</div>\n<div class="user-badges">\n  <h3>Badges</h3>\n  {{> this.userBadgesView}}\n  {{> this.badgeItemsList}}\n</div>\n'}
return ProfileView}(JView)

var UserBadgeView,UserPropertyList,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
UserBadgeView=function(_super){function UserBadgeView(options,data){var description,iconURL,title,_ref
null==options&&(options={})
UserBadgeView.__super__.constructor.call(this,options,data)
_ref=this.getData(),iconURL=_ref.iconURL,description=_ref.description,title=_ref.title
this.badgeIcon=new KDCustomHTMLView({tagName:"img",size:{width:70,height:70},attributes:{src:iconURL,title:description||""}})
this.title=new KDCustomHTMLView({partial:title})}__extends(UserBadgeView,_super)
UserBadgeView.prototype.viewAppended=function(){this.addSubView(this.badgeIcon)
return this.addSubView(this.title)}
return UserBadgeView}(KDListItemView)
UserPropertyList=function(_super){function UserPropertyList(options,data){null==options&&(options={})
UserPropertyList.__super__.constructor.call(this,options,data)}__extends(UserPropertyList,_super)
UserPropertyList.prototype.pistachio=function(){return' <a href="#">User Properties</a>\n <div class="badge-property">\n  <p>Likes count : {span.number{#(counts.likes)}}</p>\n  <p>Topic count : {span.number{#(counts.topics)}}</p>\n  <p>Follower count : {span.number{#(counts.followers)}}</p>\n  <p>Comments count : {span.number{#(counts.comments)}}</p>\n  <p>Following count : {span.number{#(counts.following)}}</p>\n  <p>Invitations count : {span.number{#(counts.invitations)}}</p>\n  <p>Referred User count : {span.number{#(counts.referredUsers)}}</p>\n  <p>Status updates count : {span.number{#(counts.statusUpdates)}}</p>\n  <p>Last Login : {span.number{#(counts.lastLoginDate)}}</p>\n</div>'}
return UserPropertyList}(JView)

var MembersListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MembersListItemView=function(_super){function MembersListItemView(options,data){var memberData
null==options&&(options={})
options.type="members"
options.avatarSizes||(options.avatarSizes=[60,60])
MembersListItemView.__super__.constructor.call(this,options,data)
memberData=this.getData()
options=this.getOptions()
this.avatar=new AvatarView({size:{width:options.avatarSizes[0],height:options.avatarSizes[1]},showStatus:!0,statusDiameter:5},memberData)
this.followButton=memberData.profile.nickname===KD.whoami().profile.nickname||"unregistered"===memberData.type?new KDView:new MemberFollowToggleButton({style:"follow-btn",loader:{color:"#333333",diameter:18,top:11}},memberData)
memberData.locationTags||(memberData.locationTags=[])
memberData.locationTags.length<1&&(memberData.locationTags[0]="Earth")
this.location=new KDCustomHTMLView({partial:memberData.locationTags[0],cssClass:"location"})
this.profileLink=new ProfileLinkView({},memberData)
this.profileLink.render()}__extends(MembersListItemView,_super)
MembersListItemView.prototype.click=function(event){var targetATag
KD.utils.showMoreClickHandler.call(this,event)
targetATag=$(event.target).closest("a")
return targetATag.is(".followers")&&0!==parseInt(targetATag.text())?KD.getSingleton("router").handleRoute("/"+this.getData().profile.nickname+"/Followers"):targetATag.is(".following")&&0!==parseInt(targetATag.text())?KD.getSingleton("router").handleRoute("/"+this.getData().profile.nickname+"/Following"):void 0}
MembersListItemView.prototype.clickOnMyItem=function(event){return $(event.target).is(".propagateProfile")?this.emit("VisitorProfileWantsToBeShown",{content:this.getData(),contentType:"member"}):void 0}
MembersListItemView.prototype.viewAppended=function(){this.setClass("member-item")
this.setTemplate(this.pistachio())
return this.template.update()}
MembersListItemView.prototype.pistachio=function(){return"<span>\n  {{> this.avatar}}\n</span>\n\n<div class='member-details'>\n  <header class='personal'>\n    <h3>{{> this.profileLink}}</h3> {{#(profile.nickname)}}\n    <span>{{> this.location}}</span>\n  </header>\n\n  <p>{{this.utils.applyTextExpansions(#(profile.about), true)}}</p>\n\n  <footer>\n    <span class='button-container'>{{> this.followButton}}</span>\n    <a class='followers' href='#'> <cite></cite> {{#(counts.followers)}} Followers</a>\n    <a class='following' href='#'> <cite></cite> {{#(counts.following)}} Following</a>\n    <time class='timeago hidden'>\n      <span class='icon'></span>\n      <span>\n        Active <cite title='{{#(meta.modifiedAt)}}'></cite>\n      </span>\n    </time>\n  </footer>\n\n</div>"}
return MembersListItemView}(KDListItemView)

var NewMemberActivityListItem,NewMemberListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NewMemberActivityListItem=function(_super){function NewMemberActivityListItem(options,data){null==options&&(options={})
options.avatarSizes=[30,30]
NewMemberActivityListItem.__super__.constructor.call(this,options,data)}__extends(NewMemberActivityListItem,_super)
NewMemberActivityListItem.prototype.pistachio=function(){return"<span>{{> this.avatar}}</span>\n<div class='member-details'>\n  <header class='personal'>\n    <h3>{{> this.profileLink}}</h3>\n  </header>\n  <p>{{this.utils.applyTextExpansions(#(profile.about), true)}}</p>\n  <footer>\n    <span class='button-container'>{{> this.followButton}}</span>\n  </footer>\n</div>"}
return NewMemberActivityListItem}(MembersListItemView)
NewMemberListItem=function(_super){function NewMemberListItem(options,data){null==options&&(options={})
options.tagName="li"
NewMemberListItem.__super__.constructor.call(this,options,data)}__extends(NewMemberListItem,_super)
NewMemberListItem.prototype.fetchUserDetails=function(){var _this=this
return KD.remote.cacheable("JAccount",this.getData().id,function(err,res){return _this.addSubView(new NewMemberActivityListItem({},res))})}
NewMemberListItem.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
this.template.update()
return this.fetchUserDetails()}
NewMemberListItem.prototype.pistachio=function(){return""}
return NewMemberListItem}(KDListItemView)

var MembersListViewController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MembersListViewController=function(_super){function MembersListViewController(){_ref=MembersListViewController.__super__.constructor.apply(this,arguments)
return _ref}__extends(MembersListViewController,_super)
MembersListViewController.prototype.loadView=function(){var _this=this
MembersListViewController.__super__.loadView.apply(this,arguments)
return this.getListView().on("ItemWasAdded",function(view){return _this.addListenersForItem(view)})}
MembersListViewController.prototype.addItem=function(member,index,animation){null==animation&&(animation=null)
return this.getListView().addItem(member,index,animation)}
MembersListViewController.prototype.addListenersForItem=function(item){var data
data=item.getData()
data.on("FollowCountChanged",function(followCounts){var followerCount,followingCount,newFollower,oldFollower
followerCount=followCounts.followerCount,followingCount=followCounts.followingCount,newFollower=followCounts.newFollower,oldFollower=followCounts.oldFollower
data.counts.followers=followerCount
data.counts.following=followingCount
item.setFollowerCount(followerCount)
switch(KD.getSingleton("mainController").getVisitor().currentDelegate){case newFollower:case oldFollower:return newFollower?item.unfollowTheButton():item.followTheButton()}})
return this}
MembersListViewController.prototype.getTotalMemberCount=function(callback){var _base
return"function"==typeof(_base=KD.whoami()).count?_base.count(this.getOptions().filterName,callback):void 0}
return MembersListViewController}(KDListViewController)

var MembersContentDisplayView,MembersLikedContentDisplayView,MembersLocationView,MembersMainView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
MembersMainView=function(_super){function MembersMainView(){_ref=MembersMainView.__super__.constructor.apply(this,arguments)
return _ref}__extends(MembersMainView,_super)
MembersMainView.prototype.createCommons=function(){this.addSubView(this.header=new HeaderViewSection({type:"big",title:"Members"}))
KD.getSingleton("mainController").on("AccountChanged",this.bound("setSearchInput"))
return this.setSearchInput()}
MembersMainView.prototype.setSearchInput=function(){return __indexOf.call(KD.config.permissions,"list members")>=0?this.header.setSearchInput():void 0}
return MembersMainView}(KDView)
MembersLocationView=function(_super){function MembersLocationView(options,data){options=$.extend({tagName:"p",cssClass:"place"},options)
MembersLocationView.__super__.constructor.call(this,options,data)}__extends(MembersLocationView,_super)
MembersLocationView.prototype.viewAppended=function(){var locations
locations=this.getData()
return this.setPartial((null!=locations?locations[0]:void 0)||"")}
return MembersLocationView}(KDCustomHTMLView)
MembersLikedContentDisplayView=function(_super){function MembersLikedContentDisplayView(options,data){var mainView
null==options&&(options={})
options.view||(options.view=mainView=new KDView)
options.cssClass||(options.cssClass="member-followers content-page-members")
MembersLikedContentDisplayView.__super__.constructor.call(this,options,data)}__extends(MembersLikedContentDisplayView,_super)
MembersLikedContentDisplayView.prototype.createCommons=function(account){var backLink,header,headerTitle,name,subHeader,_this=this
name=KD.utils.getFullnameFromAccount(account)
headerTitle="Activities which "+name+" liked"
this.addSubView(header=new HeaderViewSection({type:"big",title:headerTitle}))
this.addSubView(subHeader=new KDCustomHTMLView({tagName:"h2",cssClass:"sub-header"}))
backLink=new KDCustomHTMLView({tagName:"a",partial:"<span>&laquo;</span> Back",click:function(){return KD.singleton("display").emit("ContentDisplayWantsToBeHidden",_this)}})
KD.isLoggedIn()&&subHeader.addSubView(backLink)
return this.listenWindowResize()}
return MembersLikedContentDisplayView}(KDView)
MembersContentDisplayView=function(_super){function MembersContentDisplayView(options,data){var mainView
null==options&&(options={})
options=$.extend({view:mainView=new KDView,cssClass:"member-followers content-page-members"},options)
MembersContentDisplayView.__super__.constructor.call(this,options,data)}__extends(MembersContentDisplayView,_super)
MembersContentDisplayView.prototype.createCommons=function(account,filter){var backLink,header,name,subHeader,title,_this=this
name=KD.utils.getFullnameFromAccount(account)
title="following"===filter?"Members who "+name+" follows":"Members who follow "+name
this.addSubView(header=new HeaderViewSection({type:"big",title:title}))
this.addSubView(subHeader=new KDCustomHTMLView({tagName:"h2",cssClass:"sub-header"}))
backLink=new KDCustomHTMLView({tagName:"a",partial:"<span>&laquo;</span> Back",click:function(event){event.preventDefault()
event.stopPropagation()
return KD.singleton("display").emit("ContentDisplayWantsToBeHidden",_this)}})
KD.isLoggedIn()&&subHeader.addSubView(backLink)
return this.listenWindowResize()}
return MembersContentDisplayView}(KDView)

var MembersAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MembersAppController=function(_super){function MembersAppController(options,data){var _this=this
null==options&&(options={})
options.view=new MembersMainView({cssClass:"content-page members"})
options.appInfo={name:"Members"}
this.appManager=KD.getSingleton("appManager")
MembersAppController.__super__.constructor.call(this,options,data)
this.on("LazyLoadThresholdReached",function(){var _ref
return null!=(_ref=_this.feedController)?_ref.loadFeed():void 0})}var externalProfiles
__extends(MembersAppController,_super)
KD.registerAppClass(MembersAppController,{name:"Members",route:"/:name?/Members",hiddenHandle:!0})
externalProfiles=KD.config.externalProfiles
MembersAppController.prototype.createFeed=function(view,loadFeed){var _this=this
null==loadFeed&&(loadFeed=!1)
return this.appManager.tell("Feeder","createContentFeedController",{feedId:"members.main",itemClass:MembersListItemView,listControllerClass:MembersListViewController,useHeaderNav:!0,noItemFoundText:"There is no member.",limitPerPage:10,delegate:this,help:{subtitle:"Learn About Members",bookIndex:11,tooltip:{title:'<p class="bigtwipsy">These people are all members of koding.com. Learn more about them and their interests, activity and coding prowess here.</p>',placement:"above"}},filter:{everything:{title:"All members <span class='member-numbers-all'></span>",optional_title:this._searchValue?"<span class='optional_title'></span>":null,dataSource:function(selector,options,callback){var JAccount,group
JAccount=KD.remote.api.JAccount
if(_this._searchValue){_this.setCurrentViewHeader("Searching for <strong>"+_this._searchValue+"</strong>...")
return JAccount.byRelevance(_this._searchValue,options,callback)}group=KD.getSingleton("groupsController").getCurrentGroup()
group.fetchMembersFromGraph(options,function(err,res){return callback(err,res)})
return group.countMembers(function(err,count){err&&(count=0)
return _this.setCurrentViewNumber("all",count)})}},followed:{loggedInOnly:!0,title:"Followers <span class='member-numbers-followers'></span>",noItemFoundText:"No one is following you yet.",dataSource:function(selector,options,callback){options.groupId||(options.groupId=KD.getSingleton("groupsController").getCurrentGroup().getId())
KD.whoami().fetchMyFollowersFromGraph(options,callback)
return KD.whoami().countFollowersWithRelationship(selector,function(err,count){return _this.setCurrentViewNumber("followers",count)})}},followings:{loggedInOnly:!0,title:"Following <span class='member-numbers-following'></span>",noItemFoundText:"You are not following anyone.",dataSource:function(selector,options,callback){options.groupId||(options.groupId=KD.getSingleton("groupsController").getCurrentGroup().getId())
KD.whoami().fetchMyFollowingsFromGraph(options,callback)
return KD.whoami().countFollowingWithRelationship(selector,function(err,count){return _this.setCurrentViewNumber("following",count)})}}},sort:{"meta.modifiedAt":{title:"Latest activity",direction:-1},"counts.followers":{title:"Most followers",direction:-1},"counts.following":{title:"Most following",direction:-1}}},function(controller){_this.feedController=controller
loadFeed&&_this.feedController.loadFeed()
view.addSubView(_this._lastSubview=controller.getView())
_this.emit("ready")
controller.on("FeederListViewItemCountChanged",function(count,filter){return _this._searchValue&&"everything"===filter?_this.setCurrentViewHeader(count):void 0})
return KD.mixpanel("Loaded member list")})}
MembersAppController.prototype.createFeedForContentDisplay=function(view,account,followersOrFollowing,callback){return this.appManager.tell("Feeder","createContentFeedController",{feedId:"members."+account.profile.username,itemClass:MembersListItemView,listControllerClass:MembersListViewController,limitPerPage:10,noItemFoundText:"There is no member.",useHeaderNav:!0,delegate:this,help:{subtitle:"Learn About Members",bookIndex:11,tooltip:{title:'<p class="bigtwipsy">These people are all members of koding.com. Learn more about them and their interests, activity and coding prowess here.</p>',placement:"above"}},filter:{everything:{title:"All",dataSource:function(selector,options,callback){return"followers"===followersOrFollowing?account.fetchFollowersWithRelationship(selector,options,callback):account.fetchFollowingWithRelationship(selector,options,callback)}}},sort:{"meta.modifiedAt":{title:"Latest activity",direction:-1},"counts.followers":{title:"Most followers",direction:-1},"counts.following":{title:"Most following",direction:-1}}},function(controller){var _ref
view.addSubView(controller.getView())
callback(view,controller)
return null!=(null!=(_ref=controller.facetsController)?_ref.filterController:void 0)?controller.emit("ready"):controller.getView().on("viewAppended",function(){return controller.emit("ready")})})}
MembersAppController.prototype.createFolloweeContentDisplay=function(account,filter,callback){var newView
newView=new MembersContentDisplayView({cssClass:"content-display "+filter})
newView.createCommons(account,filter)
return this.createFeedForContentDisplay(newView,account,filter,callback)}
MembersAppController.prototype.createLikedFeedForContentDisplay=function(view,account,callback){return this.appManager.tell("Feeder","createContentFeedController",{itemClass:ActivityListItemView,listControllerClass:ActivityListController,listCssClass:"activity-related",noItemFoundText:"There is no liked activity.",limitPerPage:8,delegate:this,help:{subtitle:"Learn Personal feed",tooltip:{title:'<p class="bigtwipsy">This is the liked feed of a single Koding user.</p>',placement:"above"}},filter:{everything:{title:"Everything",dataSource:function(selector,options,callback){return account.fetchLikedContents(options,callback)}},statusupdates:{title:"Status Updates",dataSource:function(selector,options,callback){selector={sourceName:{$in:["JNewStatusUpdate"]}}
return account.fetchLikedContents(options,selector,callback)}},codesnippets:{title:"Code Snippets",dataSource:function(selector,options,callback){selector={sourceName:{$in:["JCodeSnip"]}}
return account.fetchLikedContents(options,selector,callback)}}},sort:{"timestamp|new":{title:"Latest activity",direction:-1},"timestamp|old":{title:"Most activity",direction:1}}},function(controller){var _ref
view.addSubView(controller.getView())
callback(view,controller)
return null!=(null!=(_ref=controller.facetsController)?_ref.filterController:void 0)?controller.emit("ready"):controller.getView().on("viewAppended",function(){return controller.emit("ready")})})}
MembersAppController.prototype.createLikedContentDisplay=function(account,callback){var newView
newView=new MembersLikedContentDisplayView({cssClass:"content-display likes"})
newView.createCommons(account)
return this.createLikedFeedForContentDisplay(newView,account,callback)}
MembersAppController.prototype.loadView=function(mainView,firstRun,loadFeed){var _this=this
null==firstRun&&(firstRun=!0)
null==loadFeed&&(loadFeed=!1)
if(firstRun){mainView.on("searchFilterChanged",function(value){var _base
if(value!==_this._searchValue){_this._searchValue=Encoder.XSSEncode(value)
"function"==typeof(_base=_this._lastSubview).destroy&&_base.destroy()
return _this.loadView(mainView,!1,!0)}})
mainView.createCommons()}return this.createFeed(mainView,loadFeed)}
MembersAppController.prototype.createContentDisplay=function(account,callback){var contentDisplay,controller
KD.singletons.appManager.setFrontApp(this)
controller=new ContentDisplayControllerMember({delegate:this},account)
contentDisplay=controller.getView()
contentDisplay.on("handleQuery",function(query){return controller.ready(function(){var _ref
return null!=(_ref=controller.feedController)?"function"==typeof _ref.handleQuery?_ref.handleQuery(query):void 0:void 0})})
this.showContentDisplay(contentDisplay)
return this.utils.defer(function(){return callback(contentDisplay)})}
MembersAppController.prototype.createContentDisplayWithOptions=function(options,callback){var kallback,model,query,route
model=options.model,route=options.route,query=options.query
kallback=function(contentDisplay,controller){var memberDisplay,_ref
if(!KD.getSingleton("router").openRoutes[null!=(_ref=KD.config.entryPoint)?_ref.slug:void 0]){memberDisplay=document.getElementById("member-contentdisplay")
null!=memberDisplay&&memberDisplay.parentNode.removeChild(memberDisplay)}contentDisplay.on("handleQuery",function(query){return controller.ready(function(){return"function"==typeof controller.handleQuery?controller.handleQuery(query):void 0})})
return callback(contentDisplay)}
switch(route.split("/")[2]){case"Followers":return this.createFolloweeContentDisplay(model,"followers",kallback)
case"Following":return this.createFolloweeContentDisplay(model,"following",kallback)
case"Likes":return this.createLikedContentDisplay(model,kallback)}}
MembersAppController.prototype.showContentDisplay=function(contentDisplay){KD.singleton("display").emit("ContentDisplayWantsToBeShown",contentDisplay)
return contentDisplay}
MembersAppController.prototype.setCurrentViewNumber=function(type,count){var countFmt,_ref
countFmt=null!=(_ref=count.toLocaleString())?_ref:"n/a"
return this.getView().$(".feeder-header span.member-numbers-"+type).text(countFmt)}
MembersAppController.prototype.setCurrentViewHeader=function(count){var result,title
if("number"!=typeof count){this.getView().$(".feeder-header span.optional_title").html(count)
return!1}count>=10&&(count="10+")
0===count&&(count="No")
result=""+count+" member"+(1!==count?"s":"")
title=""+result+" found for <strong>"+this._searchValue+"</strong>"
return this.getView().$(".feeder-header span.optional_title").html(title)}
MembersAppController.prototype.fetchFeedForHomePage=function(callback){var options,selector
options={limit:6,skip:0,sort:{"meta.modifiedAt":-1}}
selector={}
return KD.remote.api.JAccount.someWithRelationship(selector,options,callback)}
MembersAppController.prototype.fetchSomeMembers=function(options,callback){var selector
null==options&&(options={})
options.limit||(options.limit=6)
options.skip||(options.skip=0)
options.sort||(options.sort={"meta.modifiedAt":-1})
selector=options.selector||{}
console.log({selector:selector})
options.selector&&delete options.selector
return KD.remote.api.JAccount.byRelevance(selector,options,callback)}
MembersAppController.prototype.fetchExternalProfiles=function(account,callback){var whitelist
whitelist=Object.keys(externalProfiles).slice().map(function(a){return"ext|profile|"+a})
return account.fetchStorages(whitelist,callback)}
return MembersAppController}(AppController)

//@ sourceMappingURL=/js/__app.members.0.0.1.js.map