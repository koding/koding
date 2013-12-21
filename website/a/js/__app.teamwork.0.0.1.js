var AvatarContextMenuItem,TabHandleAvatarView,TabHandleWithAvatar,TeamworkTabView,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkTabView=function(_super){function TeamworkTabView(options,data){var _this=this
null==options&&(options={})
this.handlePaneCreate=__bind(this.handlePaneCreate,this)
TeamworkTabView.__super__.constructor.call(this,options,data)
this.createElements()
this.keysRef=this.workspaceRef.child("keys")
this.indexRef=this.workspaceRef.child("index")
this.requestRef=this.workspaceRef.child("request")
this.paneRef=this.workspaceRef.child("pane")
this.listenChildRemovedOnKeysRef()
this.listenRequestRef()
this.amIHost?this.bindRemoteEvents():this.keysRef.once("value",function(snapshot){var key,value
data=snapshot.val()
if(data){for(key in data){value=data[key]
_this.keysRefChildAddedCallback(value)}return _this.bindRemoteEvents()}})}__extends(TeamworkTabView,_super)
TeamworkTabView.prototype.listenRequestRef=function(){var _this=this
return this.requestRef.on("value",function(snapshot){var request
if(_this.amIHost){request=snapshot.val()
if(!request)return
_this.createTabFromFirebaseData(request)
return _this.requestRef.remove()}})}
TeamworkTabView.prototype.listenPaneDidShow=function(){}
TeamworkTabView.prototype.listenChildRemovedOnKeysRef=function(){var _this=this
return this.keysRef.on("child_removed",function(snapshot){var data,indexKey,pane,_i,_len,_ref,_results
data=snapshot.val()
if(data){indexKey=data.indexKey
_ref=_this.tabView.panes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i];(null!=pane?pane.getOptions().indexKey:void 0)===indexKey?_results.push(_this.tabView.removePane(pane)):_results.push(void 0)}return _results}})}
TeamworkTabView.prototype.bindRemoteEvents=function(){this.listenPaneDidShow()
this.listenIndexRef()
return this.listenChildAddedOnKeysRef()}
TeamworkTabView.prototype.listenChildAddedOnKeysRef=function(){var _this=this
return this.keysRef.on("child_added",function(snapshot){return _this.keysRefChildAddedCallback(snapshot.val())})}
TeamworkTabView.prototype.keysRefChildAddedCallback=function(data){var isExist,key,pane,panes,_i,_len
key=data.indexKey
panes=this.tabView.panes
for(_i=0,_len=panes.length;_len>_i;_i++){pane=panes[_i]
pane.getOptions().indexKey===key&&(isExist=!0)}return isExist?void 0:this.createTabFromFirebaseData(data)}
TeamworkTabView.prototype.listenIndexRef=function(){var _this=this
return this.indexRef.on("value",function(snapshot){var data,index,pane,username,watchMap,_i,_len,_ref,_results
data=snapshot.val()
watchMap=_this.workspace.watchMap
username=KD.nick()
if(data){_this.paneRef.child(data.by).set(data.indexKey)
if("everybody"===watchMap[username]||watchMap[username]===data.by){_ref=_this.tabView.panes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
if(pane.getOptions().indexKey===data.indexKey){index=_this.tabView.getPaneIndex(pane)
_results.push(_this.tabView.showPaneByIndex(index))}else _results.push(void 0)}return _results}}})}
TeamworkTabView.prototype.createElements=function(){var _this=this
this.tabHandleHolder=new ApplicationTabHandleHolder({delegate:this})
this.tabView=new ApplicationTabView({delegate:this,lastTabHandleMargin:80,tabHandleContainer:this.tabHandleHolder,enableMoveTabHandle:!0,resizeTabHandles:!1,closeAppWhenAllTabsClosed:!1,minHandleWidth:150,maxHandleWidth:150})
return this.tabView.on("PaneAdded",function(pane){return pane.getHandle().on("click",function(){var paneOptions
paneOptions=pane.getOptions()
_this.workspace.addToHistory({message:"$0 switched to "+paneOptions.title,by:KD.nick(),data:{title:paneOptions.title,indexKey:paneOptions.indexKey}})
return _this.indexRef.set({indexKey:pane.getOptions().indexKey,by:KD.nick()})})})}
TeamworkTabView.prototype.addNewTab=function(){return this.createPlusHandleDropDown()}
TeamworkTabView.prototype.createPlusHandleDropDown=function(){var contextMenu,offset
offset=this.tabHandleHolder.plusHandle.$().offset()
contextMenu=new JContextMenu({delegate:this,x:offset.left-125,y:offset.top+30,arrow:{placement:"top",margin:-20}},this.getDropdownItems())
return contextMenu.once("ContextMenuItemReceivedClick",function(){return contextMenu.destroy()})}
TeamworkTabView.prototype.getDropdownItems=function(){var _this=this
return{Dashboard:{separator:!0,callback:function(){return _this.createDashboard()}},Editor:{callback:function(){return _this.handlePaneCreate("editor",function(){return _this.createEditor()})}},Terminal:{callback:function(){return _this.handlePaneCreate("terminal",function(){return _this.createTerminal()})}},Browser:{callback:function(){return _this.handlePaneCreate("browser",function(){return _this.createPreview()})}},"Drawing Board":{callback:function(){return _this.handlePaneCreate("drawing",function(){return _this.createDrawingBoard()})}}}}
TeamworkTabView.prototype.handlePaneCreate=function(paneType,callback){null==callback&&(callback=noop)
this.amIHost?callback():this.requestRef.set({type:paneType,by:KD.nick()})
return this.workspace.addToHistory({message:"$0 opened a new "+paneType,by:KD.nick()})}
TeamworkTabView.prototype.createTabFromFirebaseData=function(data){var file,indexKey,path,sessionKey
sessionKey=data.sessionKey,indexKey=data.indexKey
switch(data.type){case"dashboard":return this.createDashboard()
case"terminal":return this.createTerminal(sessionKey,indexKey)
case"browser":return this.createPreview(sessionKey,indexKey)
case"drawing":return this.createDrawingBoard(sessionKey,indexKey)
case"editor":path=data.filePath||"localfile:/untitled.txt"
file=FSHelper.createFileFromPath(path)
return this.createEditor(file,"",sessionKey,indexKey)}}
TeamworkTabView.prototype.createDashboard=function(){var dashboard,_this=this
if(this.dashboard)return this.tabView.showPane(this.dashboard)
this.dashboard=new KDTabPaneView({title:"Dashboard",indexKey:"dashboard"})
dashboard=new TeamworkDashboard({delegate:this.workspace.getDelegate()})
this.appendPane_(this.dashboard,dashboard)
this.dashboard.once("KDObjectWillBeDestroyed",function(){return _this.dashboard=null})
this.amIHost&&this.keysRef.push({type:"dashboard",indexKey:"dashboard"})
return this.registerPaneRemoveListener_(this.dashboard)}
TeamworkTabView.prototype.createDrawingBoard=function(sessionKey,indexKey){var delegate,drawing,pane
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:"Drawing Board",indexKey:indexKey})
delegate=this.panel
drawing=new CollaborativeDrawingPane({delegate:delegate,sessionKey:sessionKey})
this.appendPane_(pane,drawing)
this.amIHost&&this.keysRef.push({type:"drawing",sessionKey:drawing.sessionKey,indexKey:indexKey})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.registerPaneRemoveListener_=function(pane){var _this=this
return pane.on("KDObjectWillBeDestroyed",function(){var paneIndexKey
paneIndexKey=pane.getOptions().indexKey
return _this.keysRef.once("value",function(snapshot){var data,key,value,_results
data=snapshot.val()
if(data){_results=[]
for(key in data){value=data[key]
value.indexKey===paneIndexKey?_results.push(_this.keysRef.child(key).remove()):_results.push(void 0)}return _results}})})}
TeamworkTabView.prototype.createEditor=function(file,content,sessionKey,indexKey){var delegate,editor,isLocal,pane
null==content&&(content="")
isLocal=!file
file=file||FSHelper.createFileFromPath("localfile:/untitled.txt")
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:file.name,indexKey:indexKey})
delegate=this.getDelegate()
editor=new CollaborativeEditorPane({delegate:delegate,sessionKey:sessionKey,file:file,content:content})
this.appendPane_(pane,editor)
this.amIHost&&this.keysRef.push({type:"editor",sessionKey:editor.sessionKey,filePath:file.path,indexKey:indexKey})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.openFile=function(file,content){return this.createEditor(file,content)}
TeamworkTabView.prototype.createTerminal=function(sessionKey,indexKey){var delegate,klass,pane,terminal,_this=this
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:"Terminal",indexKey:indexKey})
klass=this.isJoinedASession?SharableClientTerminalPane:SharableTerminalPane
delegate=this.getDelegate()
terminal=new klass({delegate:delegate,sessionKey:sessionKey})
this.appendPane_(pane,terminal)
this.amIHost&&terminal.on("WebtermCreated",function(){return _this.keysRef.push({type:"terminal",indexKey:indexKey,sessionKey:{key:terminal.remote.session,host:KD.nick(),vmName:KD.getSingleton("vmController").defaultVmName}})})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.createPreview=function(sessionKey,indexKey){var browser,delegate,pane
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:"Browser",indexKey:indexKey})
delegate=this.getDelegate()
browser=new CollaborativePreviewPane({delegate:delegate,sessionKey:sessionKey})
this.appendPane_(pane,browser)
this.amIHost&&this.keysRef.push({type:"browser",sessionKey:browser.sessionKey,indexKey:indexKey})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.createChat=function(){var chat,pane
pane=new KDTabPaneView({title:"Chat"})
chat=new ChatPane({cssClass:"full-screen",delegate:this.workspace})
return this.appendPane_(pane,chat)}
TeamworkTabView.prototype.appendPane_=function(pane,childView){pane.addSubView(childView)
return this.tabView.addPane(pane)}
TeamworkTabView.prototype.viewAppended=function(){TeamworkTabView.__super__.viewAppended.apply(this,arguments)
return this.amIHost?this.createDashboard():void 0}
TeamworkTabView.prototype.pistachio=function(){return"{{> this.tabHandleHolder}}\n{{> this.tabView}}"}
return TeamworkTabView}(CollaborativePane)
TabHandleWithAvatar=function(_super){function TabHandleWithAvatar(options,data){null==options&&(options={})
options.view=new TabHandleAvatarView(options)
TabHandleWithAvatar.__super__.constructor.call(this,options,data)}__extends(TabHandleWithAvatar,_super)
TabHandleWithAvatar.prototype.setTitle=function(title){return this.getOption("view").title.updatePartial(title)}
TabHandleWithAvatar.prototype.setAccounts=function(accounts){return this.getOption("view").setAccounts(accounts)}
return TabHandleWithAvatar}(KDTabHandleView)
TabHandleAvatarView=function(_super){function TabHandleAvatarView(options,data){var _this=this
null==options&&(options={})
options.cssClass="tw-tab-avatar-view"
TabHandleAvatarView.__super__.constructor.call(this,options,data)
this.accounts=["gokmen","devrim","sinan"]
this.addSubView(this.title=new KDCustomHTMLView({cssClass:"tw-tab-avatar-title",partial:""+options.title}))
this.addSubView(this.avatar=new AvatarStaticView({cssClass:"tw-tab-avatar-img",size:{width:20,height:20},bind:"mouseenter mouseleave",mouseenter:function(){var offset
offset=_this.avatar.$().offset()
_this.avatar.contextMenu=new JContextMenu({menuWidth:160,delegate:_this.avatar,treeItemClass:AvatarContextMenuItem,x:offset.left-106,y:offset.top+27,arrow:{placement:"top",margin:108},lazyLoad:!0},{})
return _this.utils.defer(function(){return _this.accounts.forEach(function(account){return KD.remote.cacheable(account,function(err,_arg){var account
account=_arg[0]
return!err&&account?_this.avatar.contextMenu.treeController.addNode(account):void 0})})})},mouseleave:function(){var _ref
return null!=(_ref=_this.avatar.contextMenu)?_ref.destroy():void 0}},KD.whoami()))}__extends(TabHandleAvatarView,_super)
TabHandleAvatarView.prototype.setAccounts=function(accounts){this.accounts=accounts}
return TabHandleAvatarView}(KDView)
AvatarContextMenuItem=function(_super){function AvatarContextMenuItem(){AvatarContextMenuItem.__super__.constructor.apply(this,arguments)
this.avatar=new AvatarStaticView({size:{width:20,height:20},cssClass:"tw-tab-avatar-img-context"},this.getData())}__extends(AvatarContextMenuItem,_super)
AvatarContextMenuItem.prototype.pistachio=function(){return"{{> this.avatar}} "+KD.utils.getFullnameFromAccount(this.getData())}
return AvatarContextMenuItem}(JContextMenuItem)

var TeamworkMarkdownModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkMarkdownModal=function(_super){function TeamworkMarkdownModal(options,data){var _this=this
null==options&&(options={})
options.title="README"
options.cssClass="has-markdown teamwork-markdown"
options.overlay=!0
options.width=630
TeamworkMarkdownModal.__super__.constructor.call(this,options,data)
this.bindTransitionEnd()
this.once("transitionend",function(){return _this.utils.wait(133,function(){KDModalView.prototype.destroy.call(_this)
return _this.getOptions().targetEl.setCss("opacity",1)})})}__extends(TeamworkMarkdownModal,_super)
TeamworkMarkdownModal.prototype.destroy=function(){var targetEl
this.setClass("scale")
targetEl=this.getOptions().targetEl
targetEl.setClass("opacity")
return this.setStyle({left:targetEl.getX()-this.getWidth()/2,top:targetEl.getY()-this.getHeight()/2+12})}
return TeamworkMarkdownModal}(KDModalView)

var FacebookTeamworkInstructionsModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FacebookTeamworkInstructionsModal=function(_super){function FacebookTeamworkInstructionsModal(options,data){var _this=this
null==options&&(options={})
options.title="Before Starting"
options.cssClass="tw-before-starting-modal"
options.width=700
options.overlay=!0
options.overlayClick=!1
options.tabs={navigable:!1,forms:{"Create New App":{fields:{createApp:{itemClass:KDView,cssClass:"step",partial:'<p class="tw-modal-line">1. Visit <strong><a href="http://developers.facebook.com/apps">http://developers.facebook.com/apps</a></strong> and click the <strong>Create New App</strong> button in the top right corner.</p>\n<div class="tw-modal-image">\n  <img src="/images/teamwork/facebook/step1.jpg" />\n</div>\n<p class="tw-modal-line">2. Then fill out <strong>App Name</strong>, <strong>App Namespace</strong> and <strong>App Category</strong> fields. Once that is done, click <strong>Continue</strong> button.</p>\n<div class="tw-modal-image step1">\n  <img class="tw-fb-step1" src="/images/teamwork/facebook/step2.jpg" />\n</div>\n<p class="tw-modal-line">3. Once that is done, click the <strong>Next</strong> button on this page.</p>'}},buttons:{Next:{cssClass:"modal-clean-green",callback:function(){return _this.modalTabs.showPaneByIndex(1)}}}},"App Setup":{fields:{image:{itemClass:KDView,cssClass:"step",partial:'<div class="tw-modal-image step-general">\n  <p class="tw-modal-line">1. Find your <strong>App ID</strong> and <strong>Namespace</strong> and copy below.</p>\n  <img src="/images/teamwork/facebook/step4.jpg" />\n</div>'},appId:{placeholder:"Enter you App ID",label:"App ID",validate:{rules:{required:!0},messages:{required:"Please enter your App ID"}}},appNamespace:{placeholder:"Enter you App Namespace",label:"App Namespace",validate:{rules:{required:!0},messages:{required:"Please enter your App Namespace"}}},canvasUrlText:{itemClass:KDView,cssClass:"step",partial:"<p>2. Copy the Canvas URL link below, and go back to Facebook. Scroll down to the <strong>Canvas URL</strong> under <strong>App on Facebook</strong> tab and paste the link you just copied into the field.</p>"},appCanvasUrl:{label:"Canvas URL",attributes:{readonly:"readonly"},defaultValue:"https://"+KD.nick()+".kd.io/Teamwork/Facebook/"},text:{itemClass:KDView,cssClass:"step",partial:'<div class="tw-modal-image step-general">\n  <img src="/images/teamwork/facebook/step3.jpg" />\n</div>'}},buttons:{Done:{cssClass:"modal-clean-green",callback:function(){var appCanvasUrl,appId,appNamespace,_ref
_ref=_this.modalTabs.forms["App Setup"].inputs,appId=_ref.appId,appNamespace=_ref.appNamespace,appCanvasUrl=_ref.appCanvasUrl
return appId.validate()&&appNamespace.validate()?_this.getDelegate().emit("FacebookAppInfoTaken",{appId:appId.getValue(),appNamespace:appNamespace.getValue(),appCanvasUrl:appCanvasUrl.getValue()},_this.destroy()):void 0}}}}}}
FacebookTeamworkInstructionsModal.__super__.constructor.call(this,options,data)}__extends(FacebookTeamworkInstructionsModal,_super)
return FacebookTeamworkInstructionsModal}(KDModalViewWithForms)

var TeamworkTools,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkTools=function(_super){function TeamworkTools(options,data){var _ref
null==options&&(options={})
options.cssClass="tw-share-modal"
TeamworkTools.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),this.modal=_ref.modal,this.panel=_ref.panel,this.workspace=_ref.workspace,this.twApp=_ref.twApp
this.createElements()}__extends(TeamworkTools,_super)
TeamworkTools.prototype.createElements=function(){var _this=this
this.teamUpHeader=new KDCustomHTMLView({cssClass:"header",partial:'<span class="icon"></span>\n<h3 class="text">Team Up</h3>\n<p class="desc">I want to code together right now, on my VM</p>',click:function(){if(_this.hasTeamUpElements){_this.teamUpPlaceholder.destroySubViews()
_this.unsetClass("active")
_this.teamUpHeader.unsetClass("active")
return _this.hasTeamUpElements=!1}_this.setClass("active")
_this.teamUpHeader.setClass("active")
_this.createTeamupElements()
return _this.hasTeamUpElements=!0}})
this.shareHeader=new KDCustomHTMLView({cssClass:"header share",partial:'<span class="icon"></span>\n<h3 class="text">Export and share</h3>\n<p class="desc">Select a folder to export and share the link with your friends.</p>',click:function(){if(_this.hasShareElements){_this.sharePlaceholder.destroySubViews()
_this.unsetClass("active")
_this.shareHeader.unsetClass("active")
return _this.hasShareElements=!1}_this.setClass("active")
_this.shareHeader.setClass("active")
_this.createShareElements()
return _this.hasShareElements=!0}})
this.teamUpPlaceholder=new KDCustomHTMLView({cssClass:"content"})
return this.sharePlaceholder=new KDCustomHTMLView({cssClass:"export"})}
TeamworkTools.prototype.createTeamupElements=function(){var _this=this
this.teamUpPlaceholder.addSubView(new KDCustomHTMLView({tagName:"p",cssClass:"option",partial:"Copy and send your session key or full URL to your friends"}))
this.keyInput=new KDInputView({cssClass:"teamwork-modal-input key",defaultValue:this.workspace.sessionKey,attributes:{readonly:"readonly"},click:function(){return _this.keyInput.getDomElement().select()}})
this.urlInput=new KDInputView({cssClass:"teamwork-modal-input url",defaultValue:""+document.location.href+"?sessionKey="+this.workspace.sessionKey,attributes:{readonly:"readonly"},click:function(){return _this.urlInput.getDomElement().select()}})
this.teamUpPlaceholder.addSubView(this.keyInput)
this.teamUpPlaceholder.addSubView(this.urlInput)
this.teamUpPlaceholder.addSubView(new KDCustomHTMLView({tagName:"p",cssClass:"option",partial:"Invite your Koding friends via their username"}))
this.inviteView=new CollaborativeWorkspaceUserList({workspaceRef:this.workspace.workspaceRef,sessionKey:this.workspace.sessionKey,container:this,delegate:this})
this.teamUpPlaceholder.addSubView(this.inviteView)
return this.hasTeamUpContent=!0}
TeamworkTools.prototype.createShareElements=function(){var exportButton,finder,_this=this
this.finderController=new NFinderController({nodeIdPath:"path",nodeParentIdPath:"parentPath",foldersOnly:!0,contextMenu:!1,loadFilesOnInit:!0,useStorage:!1})
finder=this.finderController.getView()
this.finderController.reset()
finder.setHeight(150)
this.sharePlaceholder.addSubView(finder)
return this.sharePlaceholder.addSubView(exportButton=new KDButtonView({cssClass:"tw-export-button",title:"Click to start export",callback:function(){return _this["export"]()}}))}
TeamworkTools.prototype["export"]=function(){var fileName,node,nodeData,notification,path,vmController,_this=this
if(!this.exporting){node=this.finderController.treeController.selectedNodes[0]
if(!node)return new KD.NotificationView({title:"Please select a folder to save!",type:"mini",cssClass:"error",duration:4e3})
vmController=KD.getSingleton("vmController")
nodeData=node.getData()
fileName=""+nodeData.name+".zip"
path=FSHelper.plainPath(nodeData.path)
notification=new KDNotificationView({title:"Exporting file...",type:"mini",duration:3e4,container:this.finderContainer})
return vmController.run("cd "+path+"/.. ; zip -r "+fileName+" "+nodeData.name,function(err){var file
_this.exporting=!0
if(err)return _this.updateNotification(notification)
file=FSHelper.createFileFromPath(""+nodeData.parentPath+"/"+fileName)
return file.fetchContents(function(err,contents){return err?_this.updateNotification(notification):FSHelper.s3.upload(fileName,btoa(contents),function(err,res){if(err)return _this.updateNotification(notification)
vmController.run("rm -f "+path+".zip",function(){})
return KD.utils.shortenUrl(res,function(shorten){_this.exporting=!1
notification.notificationSetTitle("Your content has been exported.")
notification.notificationSetTimer(4e3)
notification.setClass("success")
_this.showUrlView(shorten)
return _this.emit("Exported",nodeData.name,shorten)})})},!1)})}}
TeamworkTools.prototype.showUrlView=function(shortenUrl){var url
this.sharePlaceholder.destroySubViews()
this.sharePlaceholder.addSubView(new KDCustomHTMLView({tagName:"p",cssClass:"option",partial:"Your content is exported. Copy the url below and give it to your friends."}))
return this.sharePlaceholder.addSubView(url=new KDInputView({cssClass:"teamwork-modal-input shorten",defaultValue:shortenUrl,attributes:{readonly:"readonly"},click:function(){return url.getDomElement().select()}}))}
TeamworkTools.prototype.updateNotification=function(notification){notification.notificationSetTitle("Something went wrong")
notification.notificationSetTimer(4e3)
notification.setClass("error")
return this.exporting=!1}
TeamworkTools.prototype.pistachio=function(){return"{{> this.teamUpHeader}}\n{{> this.teamUpPlaceholder}}\n{{> this.shareHeader}}\n{{> this.sharePlaceholder}}"}
return TeamworkTools}(JView)

var TeamworkDashboard,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkDashboard=function(_super){function TeamworkDashboard(options,data){var _this=this
null==options&&(options={})
options.cssClass="tw-dashboard active"
TeamworkDashboard.__super__.constructor.call(this,options,data)
this.teamUpButton=new KDButtonView({title:"Team Up!",cssClass:"tw-rounded-button",callback:function(){var delegate
delegate=_this.getDelegate()
return delegate.teamwork?delegate.showTeamUpModal():delegate.emit("NewSessionRequested",function(){return delegate.emit("TeamUpRequested")})}})
this.joinInput=new KDHitEnterInputView({cssClass:"tw-dashboard-input",type:"text",placeholder:"Session key or url",validate:{rules:{required:!0},messages:{required:"Enter session key or URL to join."}},callback:function(){return _this.handleJoinSession()}})
this.joinButton=new KDButtonView({iconOnly:!0,iconClass:"join-in",cssClass:"tw-dashboard-button",callback:function(){return _this.handleJoinSession()}})
this.importInput=new KDHitEnterInputView({cssClass:"tw-dashboard-input",type:"text",placeholder:"Import url",validate:{rules:{required:!0},messages:{required:"Enter URL to import content."}},callback:function(){return _this.handleImport()}})
this.importButton=new KDButtonView({iconOnly:!0,iconClass:"import",cssClass:"tw-dashboard-button",callback:function(){return _this.handleImport()}})
this.playgrounds=new KDCustomHTMLView({cssClass:"tw-playgrounds"})
this.sessionButton=new KDButtonView({cssClass:"tw-session-button",title:"Start your session now!",callback:function(){return _this.getDelegate().emit("NewSessionRequested")}})
this.fetchManifests()}__extends(TeamworkDashboard,_super)
TeamworkDashboard.prototype.show=function(){return this.setClass("active")}
TeamworkDashboard.prototype.hide=function(){return this.unsetClass("active")}
TeamworkDashboard.prototype.createPlaygrounds=function(manifests){var _this=this
return null!=manifests?manifests.forEach(function(manifest){var view
_this.setClass("ready")
_this.playgrounds.addSubView(view=new KDCustomHTMLView({cssClass:"tw-playground-item",partial:'<img src="'+manifest.icon+'" />\n<div class="content">\n  <h4>'+manifest.name+"</h4>\n  <p>"+manifest.description+"</p>\n</div>"}))
return view.addSubView(new KDButtonView({cssClass:"tw-play-button",title:"Play",callback:function(){return new KDNotificationView({title:"Coming Soon"})}}))}):void 0}
TeamworkDashboard.prototype.handleImport=function(){return this.getDelegate().emit("ImportRequested",this.importInput.getValue())}
TeamworkDashboard.prototype.handleJoinSession=function(){var sessionKey,temp,_ref
sessionKey=this.joinInput.getValue()
if(sessionKey.match(/(http|https)/)){if(!(sessionKey.indexOf("koding.com")>-1&&sessionKey.indexOf("sessionKey=")>-1))return new KDNotificationView({type:"mini",cssClass:"error",title:"Could not resolve your URL",duration:5e3})
_ref=sessionKey.split("sessionKey="),temp=_ref[0],sessionKey=_ref[1]}return this.getDelegate().emit("JoinSessionRequested",sessionKey)}
TeamworkDashboard.prototype.fetchManifests=function(){var delegate,filename,_this=this
filename="localhost"===location.hostname?"manifest-dev":"manifest"
delegate=this.getDelegate()
return delegate.fetchManifestFile(""+filename+".json",function(err,manifests){if(err){_this.setClass("ready")
_this.playgrounds.hide()
return new KDNotificationView({type:"mini",cssClass:"error",title:"Could not fetch Playground manifest.",duration:4e3})}delegate.playgroundsManifest=manifests
return _this.createPlaygrounds(manifests)})}
TeamworkDashboard.prototype.pistachio=function(){return'<div class="actions">\n  <div class="tw-items-container">\n    <div class="item team-up">\n      <div class="badge"></div>\n      <h3>Team Up</h3>\n      <p>Team up and start working with your friends. Invite your Koding friends or invite them via email.</p>\n      {{> this.teamUpButton}}\n    </div>\n    <div class="item join-in">\n      <div class="badge"></div>\n      <h3>Join In</h3>\n      <p>Join your friend\'s Teamwork session. You can enter a session key or a full Koding URL.</p>\n      <div class="tw-input-container">\n        {{> this.joinInput}}\n        {{> this.joinButton}}\n      </div>\n    </div>\n    <div class="item import">\n      <div class="badge"></div>\n      <h3>Import</h3>\n      <p>Import content to your VM and start working on it. It might be a zip file or a GitHub repository.</p>\n      <div class="tw-input-container">\n        {{> this.importInput}}\n        {{> this.importButton}}\n      </div>\n    </div>\n  </div>\n</div>\n<div class="tw-playgrounds-container">\n  <p class="loading">Loading Playgrounds...</p>\n  {{> this.playgrounds}}\n</div>'}
return TeamworkDashboard}(JView)

var TeamworkImporter,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkImporter=function(_super){function TeamworkImporter(options,data){null==options&&(options={})
options.rootPath||(options.rootPath="/home/"+KD.nick()+"/Web/Teamwork")
TeamworkImporter.__super__.constructor.call(this,options,data)
this.vmController=KD.getSingleton("vmController")
this.vmName=this.vmController.defaultVmName
this.url=this.getOptions().url
this.parseUrl()}__extends(TeamworkImporter,_super)
TeamworkImporter.prototype.parseUrl=function(){var extension,gitHubUrlRegex,isGitHubUrl,_this=this
extension=FSItem.getFileExtension(this.url)
gitHubUrlRegex=/http(s)?:\/\/github.com/
isGitHubUrl=gitHubUrlRegex.test(this.url)
if(isGitHubUrl){if("git"===extension)return this.cloneRepo()
this.url=""+this.url+".git"
return this.cloneRepo()}switch(extension){case"zip":return this.downloadZip()
case"git":return this.cloneRepo()
default:return this.attemptedUrlResolve===!0?warn("Url couldn't resolved.. "+this.url):this.resolveUrl(function(){return _this.parseUrl()})}}
TeamworkImporter.prototype.downloadZip=function(){var commands,fileName,rootPath,_this=this
rootPath=this.getOptions().rootPath
this.tempPath=""+rootPath+"/.tmp"
fileName="tw-file-"+Date.now()+".zip"
commands=["rm -rf "+this.tempPath,"mkdir -p "+this.tempPath,"cd "+this.tempPath,"wget -O "+fileName+" "+this.url,"unzip "+fileName,"rm "+fileName,"rm -rf __MACOSX"]
this.notify("Downloading zip file...","",25e3)
commands=commands.join(" && ")
return this.vmController.run(commands,function(err){return err?_this.handleError(err):FSHelper.glob(""+_this.tempPath+"/*",_this.vmName,function(err,folders){var folder
if(err)return _this.handleError(err)
_this.folderName=FSHelper.getFileNameFromPath(folders.first)
folder=FSHelper.createFileFromPath(""+rootPath+"/"+_this.folderName,"folder")
return folder.exists(function(err,isExists){return err?_this.handleError(err):isExists?_this.showOverwriteModal():_this.importDone_()})})})}
TeamworkImporter.prototype.showOverwriteModal=function(contentOptions){var modal,options,_ref,_ref1,_this=this
null==contentOptions&&(contentOptions={})
options=this.getOptions()
null!=(_ref=options.modal)&&_ref.destroy()
null!=(_ref1=this.notification)&&_ref1.destroy()
return modal=new KDModalView({title:"Folder Exists",cssClass:"modal-with-text",overlay:!0,content:contentOptions.content||"<p>There is already a folder with the same name. Do you want to overwrite it?</p>",buttons:{Confirm:{title:"Overwrite",cssClass:"modal-clean-red",callback:function(){modal.destroy()
return contentOptions.confirmCallback?contentOptions.confirmCallback(modal):_this.importDone_()}},Cancel:{title:"Cancel",cssClass:"modal-cancel",callback:function(){var _ref2
modal.destroy()
if("function"==typeof contentOptions.cancelCallback?!contentOptions.cancelCallback(modal):!0){_this.vmController.run("rm -rf "+_this.tempPath)
null!=(_ref2=_this.notification)&&_ref2.destroy()
return _this.getDelegate().setVMRoot(""+_this.root+"/"+_this.folderName)}}}}})}
TeamworkImporter.prototype.importDone_=function(){var command,delegate,options,rootPath,_this=this
options=this.getOptions()
rootPath=options.rootPath
delegate=this.getDelegate()
command="rm -rf "+rootPath+"/"+this.folderName+" ; mv "+this.tempPath+"/"+this.folderName+" "+rootPath
return this.vmController.run(command,function(){var _ref,_ref1
null!=(_ref=options.modal)&&_ref.destroy()
null!=(_ref1=_this.notification)&&_ref1.destroy()
"function"==typeof options.callback&&options.callback()
_this.vmController.run("rm -rf @{tempPath}")
return _this.checkContent()})}
TeamworkImporter.prototype.checkContent=function(){var delegate,folderPath,mdFile,mdPath,rootPath,shFile,shPath,_this=this
rootPath=this.getOptions().rootPath
folderPath=""+rootPath+"/"+this.folderName
mdPath=""+folderPath+"/README.md"
shPath=""+folderPath+"/install.sh"
mdFile=FSHelper.createFileFromPath(mdPath)
shFile=FSHelper.createFileFromPath(shPath)
delegate=this.getDelegate()
delegate.setVMRoot(folderPath)
return mdFile.exists(function(err,mdExists){return mdExists?mdFile.fetchContents(function(err,mdContent){delegate=_this.getDelegate()
delegate.showMarkdownModal(mdContent)
return delegate.mdModal.once("KDObjectWillBeDestroyed",function(){return _this.checkShFile(shFile)})}):_this.checkShFile(shFile)})}
TeamworkImporter.prototype.checkShFile=function(shFile){var _this=this
return shFile.exists(function(err,fileExist){return fileExist?shFile.fetchContents(function(err,shContent){var modal
return modal=new KDModalView({title:"Installation Script",cssClass:"modal-with-text",width:600,overlay:!0,content:'<p>This Playground wants to execute the following install script. Do you want to continue?</p>\n<p>\n  <pre class="tw-sh-preview">'+shContent+"</pre>\n</p>",buttons:{Install:{title:"Install Script",cssClass:"modal-clean-green",callback:function(){return _this.runShFile(shFile,modal)}},Cancel:{title:"Cancel",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})}):void 0})}
TeamworkImporter.prototype.runShFile=function(shFile,modal){var paneLauncher,_this=this
modal.destroy()
paneLauncher=this.getDelegate().teamwork.getActivePanel().paneLauncher
paneLauncher.paneVisibilityState.terminal||paneLauncher.handleLaunch("terminal")
return this.vmController.run("chmod 777 "+shFile.path,function(err){return err?_this.handleError(err):paneLauncher.terminalPane.runCommand("./"+shFile.path)})}
TeamworkImporter.prototype.cloneRepo=function(){var repoFolder,rootPath,_this=this
rootPath=this.getOptions().rootPath
this.folderName=FSHelper.getFileNameFromPath(this.url).split(".git")[0]
repoFolder=FSHelper.createFileFromPath(""+rootPath+"/"+this.folderName,"folder")
return repoFolder.exists(function(err,isExists){return err?_this.handleError(err):isExists?_this.showOverwriteModal({content:"<p>Repo exists. Overwrite?</p>",confirmCallback:function(){return repoFolder.remove(function(){return _this.doClone()})},cancelCallback:function(modal){return modal.destroy()}}):_this.doClone()})}
TeamworkImporter.prototype.doClone=function(){var commands,modal,rootPath,_ref,_this=this
this.notify("Cloning repository...","",3e4)
_ref=this.getOptions(),rootPath=_ref.rootPath,modal=_ref.modal
commands=["mkdir -p "+rootPath,"cd "+rootPath,"git clone "+this.url]
null!=modal&&modal.destroy()
return this.vmController.run(commands.join(" && "),function(err){var _ref1
if(err)return _this.handleError(err)
_this.getDelegate().setVMRoot(""+rootPath+"/"+_this.folderName)
null!=(_ref1=_this.notification)&&_ref1.destroy()
return _this.checkContent()})}
TeamworkImporter.prototype.resolveUrl=function(callback){var _this=this
null==callback&&(callback=noop)
return this.vmController.run("curl -sIL "+this.url+" | grep ^Location",function(err,longUrl){err&&_this.handleError(err)
_this.url=longUrl.replace("Location: ","").replace(/\n/g,"").trim()
_this.attemptedUrlResolve=!0
return callback()})}
TeamworkImporter.prototype.notify=function(title,cssClass,duration){var type,_ref
null==duration&&(duration=4200)
type="mini"
null!=(_ref=this.notification)&&_ref.destroy()
return this.notification=new KDNotificationView({title:title,cssClass:cssClass,duration:duration,type:type})}
TeamworkImporter.prototype.handleError=function(err){this.notify("Something went wrong.","error")
return warn(err)}
return TeamworkImporter}(KDObject)

var TeamworkChatPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkChatPane=function(_super){function TeamworkChatPane(options,data){null==options&&(options={})
TeamworkChatPane.__super__.constructor.call(this,options,data)
this.setClass("tw-chat")
this.getDelegate().setClass("tw-chat-open")}__extends(TeamworkChatPane,_super)
TeamworkChatPane.prototype.createDock=function(){return this.dock=new KDCustomHTMLView({cssClass:"hidden"})}
TeamworkChatPane.prototype.updateCount=function(){}
return TeamworkChatPane}(ChatPane)

var TeamworkWorkspace,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkWorkspace=function(_super){function TeamworkWorkspace(options,data){var playground,playgroundManifest,_ref,_this=this
null==options&&(options={})
TeamworkWorkspace.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),playground=_ref.playground,playgroundManifest=_ref.playgroundManifest
this.avatars={}
this.on("PanelCreated",function(panel){_this.createButtons(panel)
playground&&_this.createRunButton(panel)
_this.getActivePanel().header.setClass("teamwork")
return _this.createActivityWidget(panel)})
this.on("WorkspaceSyncedWithRemote",function(){if(playground&&_this.amIHost()){_this.workspaceRef.child("playground").set(playground)
playgroundManifest&&_this.workspaceRef.child("playgroundManifest").set(playgroundManifest)}_this.amIHost()||_this.hidePlaygroundsButton()
return _this.workspaceRef.child("users").on("child_added",function(snapshot){var joinedUser
joinedUser=snapshot.name()
return joinedUser&&joinedUser!==KD.nick()?_this.hidePlaygroundsButton():void 0})})
this.on("WorkspaceUsersFetched",function(){return _this.workspaceRef.child("users").once("value",function(snapshot){var userStatus
userStatus=snapshot.val()
return userStatus?_this.manageUserAvatars(userStatus):void 0})})
this.on("NewHistoryItemAdded",function(data){return _this.sendSystemMessage(data.message)})}__extends(TeamworkWorkspace,_super)
TeamworkWorkspace.prototype.createButtons=function(panel){var chatButton,_this=this
panel.addSubView(this.buttonsContainer=new KDCustomHTMLView({cssClass:"tw-buttons-container"}))
this.buttonsContainer.addSubView(chatButton=new KDButtonView({cssClass:"tw-chat-toggle active",iconClass:"tw-chat",iconOnly:!0,callback:function(){var cssClass,isChatVisible
cssClass="tw-chat-open"
isChatVisible=_this.hasClass(cssClass)
_this.toggleClass(cssClass)
chatButton.toggleClass("active")
return isChatVisible?_this.chatView.hide():_this.chatView.show()}}))
return this.buttonsContainer.addSubView(new KDButtonView({iconClass:"tw-cog",iconOnly:!0,callback:function(){return _this.getDelegate().showToolsModal(panel,_this)}}))}
TeamworkWorkspace.prototype.displayBroadcastMessage=function(options){var _this=this
TeamworkWorkspace.__super__.displayBroadcastMessage.call(this,options)
return"users"===options.origin?KD.utils.wait(500,function(){return _this.fetchUsers()}):void 0}
TeamworkWorkspace.prototype.startNewSession=function(options){var teamwork,workspaceClass
KD.mixpanel("User Started Teamwork session")
this.destroySubViews()
if(!options){options=this.getOptions()
delete options.sessionKey}workspaceClass=this.getPlaygroundClass(options.playground)
teamwork=new workspaceClass(options)
this.getDelegate().teamwork=teamwork
return this.addSubView(teamwork)}
TeamworkWorkspace.prototype.joinSession=function(newOptions){var options,sessionKey,_this=this
sessionKey=newOptions.sessionKey.trim()
options=this.getOptions()
options.sessionKey=sessionKey
options.joinedASession=!0
this.destroySubViews()
this.forceDisconnect()
return this.firepadRef.child(sessionKey).once("value",function(snapshot){var playground,playgroundManifest,teamwork,teamworkClass,teamworkOptions,value
value=snapshot.val()
value&&(playground=value.playground,playgroundManifest=value.playgroundManifest)
teamworkClass=TeamworkWorkspace
teamworkOptions=options
playground&&(teamworkClass=_this.getPlaygroundClass(playground))
playgroundManifest&&(teamworkOptions=_this.getDelegate().mergePlaygroundOptions(playgroundManifest))
teamworkOptions.sessionKey=newOptions.sessionKey
teamwork=new teamworkClass(teamworkOptions)
_this.getDelegate().teamwork=teamwork
return _this.addSubView(teamwork)})}
TeamworkWorkspace.prototype.refreshPreviewPane=function(previewPane){return previewPane.previewer.emit("ViewerRefreshed")}
TeamworkWorkspace.prototype.createRunButton=function(panel){var _this=this
return panel.headerButtonsContainer.addSubView(new KDButtonView({title:"Run",cssClass:"clean-gray tw-ply-run",callback:function(){return _this.handleRun(panel)}}))}
TeamworkWorkspace.prototype.getPlaygroundClass=function(playground){return"Facebook"===playground?FacebookTeamwork:PlaygroundTeamwork}
TeamworkWorkspace.prototype.handleRun=function(){return console.warn("You should override this method.")}
TeamworkWorkspace.prototype.hidePlaygroundsButton=function(){var _ref
return null!=(_ref=this.getActivePanel().headerButtons.Playgrounds)?_ref.hide():void 0}
TeamworkWorkspace.prototype.showHintModal=function(){return this.markdownContent?this.getDelegate().showMarkdownModal():Panel.prototype.showHintModal.call(this.getActivePanel())}
TeamworkWorkspace.prototype.previewFile=function(){var activePanel,editor,error,file,isLocal,isNotPublic,path,previewPane,url
activePanel=this.getActivePanel()
editor=activePanel.getPaneByName("editor")
file=editor.getActivePaneFileData()
path=FSHelper.plainPath(file.path)
error="File must be under Web folder"
isLocal=0===path.indexOf("localfile")
isNotPublic=!FSHelper.isPublicPath(path)
previewPane=activePanel.paneLauncher.previewPane
if(isLocal||isNotPublic){isLocal&&(error="This file cannot be previewed")
return new KDNotificationView({title:error,cssClass:"error",type:"mini",duration:2500,container:previewPane})}url=path.replace("/home/"+this.getHost()+"/Web","https://"+KD.nick()+".kd.io")
return previewPane.openUrl(url)}
TeamworkWorkspace.prototype.manageUserAvatars=function(userStatus){var nickname,status,_results
_results=[]
for(nickname in userStatus)if(__hasProp.call(userStatus,nickname)){status=userStatus[nickname]
"online"===status?this.avatars[nickname]?_results.push(void 0):_results.push(this.createUserAvatar(this.users[nickname])):this.avatars[nickname]?_results.push(this.removeUserAvatar(nickname)):_results.push(void 0)}return _results}
TeamworkWorkspace.prototype.createUserAvatar=function(jAccount){var avatarView,followText,userNickname,_this=this
if(jAccount){userNickname=jAccount.profile.nickname
if(userNickname!==KD.nick()){followText="Click user avatar to watch "+userNickname
avatarView=new AvatarStaticView({size:{width:25,height:25},tooltip:{title:followText},click:function(){var isAlreadyWatched,message,_ref
null!=(_ref=_this.watchingUserAvatar)&&_ref.unsetClass("watching")
isAlreadyWatched=_this.watchingUserAvatar===avatarView
if(isAlreadyWatched){_this.watchRef.child(_this.nickname).set("nobody")
message=""+KD.nick()+" stopped watching "+userNickname
_this.watchingUserAvatar=null
avatarView.setTooltip({title:followText})}else{_this.watchRef.child(_this.nickname).set(userNickname)
message=""+KD.nick()+" started to watch "+userNickname+".  Type 'stop watching' or click on avatars to start/stop watching."
avatarView.setClass("watching")
_this.watchingUserAvatar=avatarView
avatarView.setTooltip({title:"You are now watching "+userNickname+". Click again to stop watching."})}message={user:{nickname:"teamwork"},time:Date.now(),body:message}
return _this.workspaceRef.child("chat").child(message.time).set(message)}},jAccount)
this.avatars[userNickname]=avatarView
this.avatarsView.addSubView(avatarView)
this.avatarsView.setClass("has-user")
return avatarView.bindTransitionEnd()}}}
TeamworkWorkspace.prototype.removeUserAvatar=function(nickname){var avatarView,_this=this
avatarView=this.avatars[nickname]
avatarView.setClass("fade-out")
return avatarView.once("transitionend",function(){avatarView.destroy()
delete _this.avatars[nickname]
return 0===_this.avatars.length?_this.avatarsView.unsetClass("has-user"):void 0})}
TeamworkWorkspace.prototype.sendSystemMessage=function(message){return this.getOptions().enableChat?this.chatView.sendMessage(message,!0):void 0}
TeamworkWorkspace.prototype.createActivityWidget=function(panel){var activityId,shareButton,_this=this
panel.addSubView(this.activityWidget=new ActivityWidget({cssClass:"tw-activity-widget collapsed",childOptions:{cssClass:"activity-item"}}))
this.activityWidget.addSubView(this.notification=new KDCustomHTMLView({cssClass:"notification",partial:"This status update will be visible in Activity feed."}))
this.activityWidget.addSubView(new KDCustomHTMLView({cssClass:"close-tab",click:this.bound("hideActivityWidget")}))
panel.addSubView(this.inviteTeammate=new KDButtonView({cssClass:"invite-teammate tw-rounded-button hidden",title:"Invite",callback:function(){var url
url=""+KD.config.apiUri+"/Teamwork?sessionKey="+_this.sessionKey
_this.activityWidget.setInputContent("Would you like to join my Teamwork session? "+url)
_this.showActivityWidget()
return _this.hideShareButtons()}}))
panel.addSubView(this.exportWorkspace=new KDButtonView({cssClass:"export-workspace tw-rounded-button hidden",title:"Export",callback:function(){_this.getDelegate().emit("ExportRequested",function(){})
return _this.hideShareButtons()}}))
panel.addSubView(shareButton=new KDButtonView({cssClass:"tw-rounded-button share",title:"Share",callback:function(){_this.inviteTeammate.toggleClass("hidden")
return _this.exportWorkspace.toggleClass("hidden")}}))
panel.addSubView(this.showActivityWidgetButton=new KDButtonView({cssClass:"tw-show-activity-widget",iconOnly:!0,iconClass:"icon",callback:function(){if(_this.activityWidget.activity){_this.activityWidget.hideForm()
return _this.showActivityWidget()}return _this.share()}}))
activityId=this.getOptions().activityId
activityId?this.displayActivity(activityId):this.workspaceRef.child("activityId").once("value",function(snapshot){return(activityId=snapshot.val())?_this.displayActivity(activityId):void 0})
return this.getDelegate().on("Exported",function(name,importUrl){var query,querystring,_ref
activityId=null!=(_ref=_this.activityWidget.activity)?_ref.getId():void 0
query={"import":importUrl}
activityId&&(query.activityId=activityId)
querystring=_this.utils.stringifyQuery(query)
return _this.utils.shortenUrl(""+KD.config.apiUri+"/Teamwork?"+querystring,function(url){var message
message=""+KD.nick()+" exported "+name+" "+url
if(activityId)return _this.activityWidget.reply(message)
_this.activityWidget.setInputContent(message)
return _this.showActivityWidget()})})}
TeamworkWorkspace.prototype.showActivityWidget=function(){this.activityWidget.show()
return this.activityWidget.unsetClass("collapsed")}
TeamworkWorkspace.prototype.hideActivityWidget=function(){var _this=this
this.activityWidget.setClass("collapsed")
return this.activityWidget.on("transitionend",function(){return _this.activityWidget.hide()})}
TeamworkWorkspace.prototype.showShareButtons=function(){this.inviteTeammate.show()
return this.exportWorkspace.show()}
TeamworkWorkspace.prototype.hideShareButtons=function(){this.inviteTeammate.hide()
return this.exportWorkspace.hide()}
TeamworkWorkspace.prototype.displayActivity=function(id){var _this=this
return this.activityWidget.display(id,function(){_this.notification.hide()
return _this.activityWidget.hideForm()})}
TeamworkWorkspace.prototype.share=function(){var _this=this
this.activityWidget.show()
this.activityWidget.unsetClass("collapsed")
return this.activityWidget.activity?this.activityWidget.hideForm():this.activityWidget.showForm(function(err,activity){if(err)return err
_this.activityWidget.hideForm()
_this.notification.hide()
return _this.workspaceRef.child("activityId").set(activity.getId())})}
return TeamworkWorkspace}(CollaborativeWorkspace)

var PlaygroundTeamwork,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PlaygroundTeamwork=function(_super){function PlaygroundTeamwork(options,data){var _this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("playground",options.cssClass)
PlaygroundTeamwork.__super__.constructor.call(this,options,data)
this.on("PanelCreated",function(){return _this.getActivePanel().header.unsetClass("teamwork")})
this.on("ContentIsReady",function(){var initialState,manifest,prerequisite
if(_this.amIHost()){manifest=_this.getOptions().playgroundManifest
prerequisite=manifest.prerequisite,initialState=manifest.initialState
return prerequisite?"sh"===prerequisite.type?initialState?_this.doPrerequisite(prerequisite.command,function(){return _this.setUpInitialState(initialState)}):_this.doPrerequisite(prerequisite.command):warn("Unhandled prerequisite type."):initialState?_this.setUpInitialState(initialState):void 0}})}__extends(PlaygroundTeamwork,_super)
PlaygroundTeamwork.prototype.handleRun=function(panel){var command,handler,options,paneLauncher,path,plainPath,playground,runConfig
options=this.getOptions()
playground=options.playground
runConfig=options.playgroundManifest.run
if(!runConfig)return warn("Missing run config for "+playground+".")
handler=runConfig.handler,command=runConfig.command
paneLauncher=panel.paneLauncher
if(!handler||!command)return warn("Missing parameter for "+playground+" run config. You must pass a handler and a command")
if("terminal"===handler){path=panel.getPaneByName("editor").getActivePaneFileData().path
plainPath=FSHelper.plainPath(path)
command=command.replace("$ACTIVE_FILE_PATH",' "'+plainPath+'" ')
paneLauncher.paneVisibilityState.terminal===!1&&paneLauncher.handleLaunch("terminal")
return paneLauncher.terminalPane.runCommand(command)}return"preview"===handler?this.handlePreview(command):warn("Unimplemented run hanldler for "+playground)}
PlaygroundTeamwork.prototype.doPrerequisite=function(command,callback){null==callback&&(callback=noop)
return command?KD.getSingleton("vmController").run(command,function(err){return err?warn(err):callback()}):warn("no command passed for prerequisite")}
PlaygroundTeamwork.prototype.setUpInitialState=function(initialState){initialState.preview&&this.handlePreview(initialState.preview.url)
return initialState.editor?this.openFiles(initialState.editor.files):void 0}
PlaygroundTeamwork.prototype.handlePreview=function(url){var paneLauncher
paneLauncher=this.getActivePanel().paneLauncher
url=url.replace("$USERNAME",this.getHost())
paneLauncher.paneVisibilityState.preview===!1&&paneLauncher.handleLaunch("preview")
return paneLauncher.previewPane.openUrl(url)}
PlaygroundTeamwork.prototype.openFiles=function(files){var editor,file,filePath,path,_i,_len,_results
editor=this.getActivePanel().getPaneByName("editor")
_results=[]
for(_i=0,_len=files.length;_len>_i;_i++){path=files[_i]
filePath="/home/"+KD.nick()+"/Web/Teamwork/"+this.getOptions().playground+"/"+path.replace(/^.\//,"")
file=FSHelper.createFileFromPath(filePath)
_results.push(file.fetchContents(function(err,contents){return editor.openFile(file,contents)}))}return _results}
return PlaygroundTeamwork}(TeamworkWorkspace)

var TeamworkApp,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkApp=function(_super){function TeamworkApp(options,data){var importUrl,sessionKey,_this=this
null==options&&(options={})
options.query||(options.query={})
TeamworkApp.__super__.constructor.call(this,options,data)
this.appView=this.getDelegate()
this.on("NewSessionRequested",function(callback,options){var _ref
null==callback&&(callback=noop)
null!=(_ref=_this.teamwork)&&_ref.destroy()
_this.createTeamwork(options)
_this.appView.addSubView(_this.teamwork)
return callback()})
this.on("JoinSessionRequested",function(sessionKey){var firebase
_this.setOption("sessionKey",sessionKey)
firebase=new Firebase("https://"+instanceName+".firebaseio.com/")
return firebase.child(sessionKey).once("value",function(snapshot){var val
val=snapshot.val()
if(null!=val?val.playground:void 0){_this.setOption("playgroundManifest",val.playgroundManifest)
_this.setOption("playground",val.playground)
options=_this.mergePlaygroundOptions(val.playgroundManifest,val.playground)
return _this.emit("NewSessionRequested",null,options)}return _this.emit("NewSessionRequested")})})
this.on("ImportRequested",function(importUrl){_this.emit("NewSessionRequested")
return _this.teamwork.on("WorkspaceSyncedWithRemote",function(){return _this.showImportWarning(importUrl)})})
this.on("ExportRequested",function(callback){_this.showExportModal()
return _this.tools.once("Exported",callback)})
this.on("TeamUpRequested",function(){return _this.teamwork.once("WorkspaceSyncedWithRemote",function(){return _this.showTeamUpModal()})})
sessionKey=options.query.sessionKey
importUrl=options.query["import"]
sessionKey?this.emit("JoinSessionRequested",sessionKey):importUrl?this.emit("ImportRequested",importUrl):this.emit("NewSessionRequested")}var instanceName
__extends(TeamworkApp,_super)
instanceName="localhost"===location.hostname?"tw-local":"kd-prod-1"
TeamworkApp.prototype.createTeamwork=function(options){var playgroundClass
playgroundClass=TeamworkWorkspace;(null!=options?options.playground:void 0)&&(playgroundClass="Facebook"===options.playground?FacebookTeamwork:PlaygroundTeamwork)
return this.teamwork=new playgroundClass(options||this.getTeamworkOptions())}
TeamworkApp.prototype.showTeamUpModal=function(){this.showToolsModal(this.teamwork.getActivePanel(),this.teamwork)
this.tools.teamUpHeader.emit("click")
return this.tools.setClass("team-up-mode")}
TeamworkApp.prototype.showExportModal=function(){this.showToolsModal(this.teamwork.getActivePanel(),this.teamwork)
this.tools.shareHeader.emit("click")
return this.tools.setClass("share-mode")}
TeamworkApp.prototype.getTeamworkOptions=function(){var options
options=this.getOptions()
return{name:options.name||"Teamwork",joinModalTitle:options.joinModalTitle||"Join a coding session",joinModalContent:options.joinModalContent||"<p>Paste the session key that you received and start coding together.</p>",shareSessionKeyInfo:options.shareSessionKeyInfo||"<p>This is your session key, you can share this key with your friends to work together.</p>",firebaseInstance:options.firebaseInstance||instanceName,sessionKey:options.sessionKey,activityId:options.query.activityId,delegate:this,enableChat:!0,chatPaneClass:TeamworkChatPane,playground:options.playground||null,panels:options.panels||[{hint:"<p>This is a collaborative coding environment where you can team up with others and work on the same code.</p>",buttons:[],layout:{direction:"vertical",sizes:["265px",null],splitName:"BaseSplit",views:[{title:"<div class='header-title'><span class='icon'></span>Teamwork</div>",type:"finder",name:"finder",editor:"tabView"},{type:"custom",paneClass:TeamworkTabView,name:"tabView"}]}}]}}
TeamworkApp.prototype.showToolsModal=function(panel,workspace){var modal
modal=new KDModalView({cssClass:"teamwork-tools-modal",title:"Teamwork Tools",overlay:!0,width:600})
modal.addSubView(this.tools=new TeamworkTools({modal:modal,panel:panel,workspace:workspace,twApp:this}))
this.emit("TeamworkToolsModalIsReady",modal)
return this.forwardEvent(this.tools,"Exported")}
TeamworkApp.prototype.showImportWarning=function(url,callback){var modal,_ref,_this=this
null==callback&&(callback=noop)
null!=(_ref=this.importModal)&&_ref.destroy()
return modal=this.importModal=new KDModalView({title:"Import File",cssClass:"modal-with-text",overlay:!0,content:this.teamwork.getOptions().importModalContent||"<p>This Teamwork URL wants to download a file to your VM from <strong>"+url+"</strong></p>\n<p>Would you like to import and start working with these files?</p>",buttons:{Import:{title:"Import",cssClass:"modal-clean-green",loader:{color:"#FFFFFF",diameter:14},callback:function(){return new TeamworkImporter({url:url,modal:modal,callback:callback,delegate:_this})}},DontImport:{title:"Don't import anything",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})}
TeamworkApp.prototype.showMarkdownModal=function(rawContent){var modal,t
t=this.teamwork
rawContent&&(t.markdownContent=KD.utils.applyMarkdown(rawContent))
return modal=this.mdModal=new TeamworkMarkdownModal({content:t.markdownContent,targetEl:t.getActivePanel().headerHint})}
TeamworkApp.prototype.setVMRoot=function(path){var defaultVmName,finderController
finderController=this.teamwork.getActivePanel().getPaneByName("finder").finderController
defaultVmName=KD.getSingleton("vmController").defaultVmName
finderController.getVmNode(defaultVmName)&&finderController.unmountVm(defaultVmName)
return finderController.mountVm(""+defaultVmName+":"+path)}
TeamworkApp.prototype.mergePlaygroundOptions=function(manifest,playground){var firstPanel,name,rawOptions
rawOptions=this.getTeamworkOptions()
name=manifest.name
firstPanel=rawOptions.panels.first
firstPanel.title=name
rawOptions.playground=playground
rawOptions.name=name
firstPanel.headerStyling=manifest.styling
rawOptions.examples=manifest.examples
rawOptions.contentDetails=manifest.content
rawOptions.playgroundManifest=manifest
manifest.importModalContent&&(rawOptions.importModalContent=manifest.importModalContent)
return rawOptions}
TeamworkApp.prototype.getPlaygroundClass=function(playground){return"Facebook"===playground?FacebookTeamwork:PlaygroundTeamwork}
TeamworkApp.prototype.handlePlaygroundSelection=function(playground,manifestUrl){var manifest,_i,_len,_ref,_this=this
if(!manifestUrl){_ref=this.playgroundsManifest
for(_i=0,_len=_ref.length;_len>_i;_i++){manifest=_ref[_i]
playground===manifest.name&&(manifestUrl=manifest.manifestUrl)}}return this.doCurlRequest(manifestUrl,function(err,manifest){var _ref1
null!=(_ref1=_this.teamwork)&&_ref1.destroy()
_this.createTeamwork(_this.mergePlaygroundOptions(manifest,playground))
_this.appView.addSubView(_this.teamwork)
_this.teamwork.container.setClass(playground)
return _this.teamwork.on("WorkspaceSyncedWithRemote",function(){var contentDetails,contentUrl,folder,manifestVersion,root
contentDetails=_this.teamwork.getOptions().contentDetails
KD.mixpanel("User Changed Playground",playground)
if("zip"===contentDetails.type){root="/home/"+_this.teamwork.getHost()+"/Web/Teamwork/"+playground
folder=FSHelper.createFileFromPath(root,"folder")
contentUrl=contentDetails.url
manifestVersion=manifest.version
return folder.exists(function(err,exists){var appStorage
if(!exists)return _this.setUpImport(contentUrl,manifestVersion,playground)
appStorage=KD.getSingleton("appStorageController").storage("Teamwork","1.0")
return appStorage.fetchStorage(function(){var currentVersion,hasNewVersion
currentVersion=appStorage.getValue(""+playground+"PlaygroundVersion")
hasNewVersion=KD.utils.versionCompare(manifestVersion,"gt",currentVersion)
if(hasNewVersion)return _this.setUpImport(contentUrl,manifestVersion,playground)
_this.setVMRoot(root)
return _this.teamwork.emit("ContentIsReady")})})}return warn("Unhandled content type for "+name)})})}
TeamworkApp.prototype.setUpImport=function(url,version,playground){var _this=this
if(!url)return warn("Missing url parameter to import zip file for "+playground)
this.teamwork.importInProgress=!0
return this.showImportWarning(url,function(){var appStorage
_this.teamwork.emit("ContentIsReady")
_this.teamwork.importModalContent=!1
appStorage=KD.getSingleton("appStorageController").storage("Teamwork","1.0")
return appStorage.setValue(""+playground+"PlaygroundVersion",version)})}
TeamworkApp.prototype.doCurlRequest=function(path,callback){var vmController
null==callback&&(callback=noop)
vmController=KD.getSingleton("vmController")
return vmController.run({withArgs:"kdwrap curl -kLs "+path,vmName:vmController.defaultVmName},function(err,contents){var error,extension,manifest
extension=FSItem.getFileExtension(path)
error=null
switch(extension){case"json":try{manifest=JSON.parse(contents)}catch(_error){err=_error
error="Manifest file is broken for "+path}return callback(error,manifest)
case"md":return callback(errorMessage,KD.utils.applyMarkdown(error,contents))}})}
TeamworkApp.prototype.fetchManifestFile=function(path,callback){null==callback&&(callback=noop)
return $.ajax({url:"http://resources.gokmen.kd.io/Teamwork/Playgrounds/"+path,type:"GET",success:function(response){return response?callback(null,response):callback(!0,null)},error:function(){return callback(!0,null)}})}
return TeamworkApp}(KDObject)

var FacebookTeamwork,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FacebookTeamwork=function(_super){function FacebookTeamwork(options,data){var _this=this
null==options&&(options={})
FacebookTeamwork.__super__.constructor.call(this,options,data)
this.appStorage=KD.getSingleton("appStorageController").storage("Teamwork")
this.on("PanelCreated",function(panel){var editor
editor=panel.getPaneByName("editor")
return editor.on("OpenedAFile",function(){var content
content=editor.getActivePaneContent().replace("YOUR_APP_ID",_this.appId)
editor.getActivePaneEditor().setValue(content)
return _this.runButton?void 0:_this.createRunButton(panel)})})
this.on("ContentImportDone",function(){_this.createIndexFile()
return _this.appId&&_this.appNamespace&&_this.appCanvasUrl||!_this.amIHost()?void 0:_this.showInstructions()})
this.on("FacebookAppInfoTaken",function(info){_this.appId=info.appId,_this.appNamespace=info.appNamespace,_this.appCanvasUrl=info.appCanvasUrl
_this.appStorage.setValue("FacebookAppId",_this.appId)
_this.appStorage.setValue("FacebookAppNamespace",_this.appNamespace)
_this.appStorage.setValue("FacebookAppCanvasUrl",_this.appCanvasUrl)
return _this.setAppInfoToCloud()})
this.container.setClass("Facebook")
this.on("WorkspaceSyncedWithRemote",function(){return _this.amIHost()?_this.getAppInfo():void 0})
this.getDelegate().on("TeamworkToolsModalIsReady",function(modal){var header,revoke,wrapper
modal.addSubView(header=new KDCustomHTMLView({cssClass:"teamwork-modal-header",partial:'<div class="header full-width">\n  <span class="text">Facebook App Details</span>\n</div>'}))
modal.addSubView(wrapper=new KDCustomHTMLView({cssClass:"teamwork-modal-content full-width tw-fb-revoke",partial:'<div class="teamwork-modal-content">\n  <span class="initial">Below you can find your app details.</span>\n  <p>\n    <span>App ID</span>         <strong>'+_this.appId+"</strong><br />\n    <span>App Namespace</span>  <strong>"+_this.appNamespace+"</strong><br />\n    <span>Canvas Url</span>     <strong>"+_this.appCanvasUrl+"</strong><br /><br />\n  </p>\n</div>"}))
wrapper.addSubView(revoke=new KDCustomHTMLView({cssClass:"teamwork-modal-content revoke",partial:"<p>If you want to update your Facebook App ID, App Namespace or App Canvas Url click this button to start progress.</p>"}))
return revoke.addSubView(new KDButtonView({title:"Update",callback:function(){modal.destroy()
return _this.showInstructions()}}))})}__extends(FacebookTeamwork,_super)
FacebookTeamwork.prototype.showInstructions=function(){var d,_ref
d=this.getDelegate()
null!=(_ref=d.instructionsModal)&&_ref.destroy()
return d.instructionsModal=new FacebookTeamworkInstructionsModal({delegate:this})}
FacebookTeamwork.prototype.getAppInfo=function(){var _this=this
return this.appStorage.fetchStorage(function(){_this.appId=_this.appStorage.getValue("FacebookAppId")
_this.appNamespace=_this.appStorage.getValue("FacebookAppNamespace")
_this.appCanvasUrl=_this.appStorage.getValue("FacebookAppCanvasUrl")
if(_this.appId&&_this.appNamespace&&_this.appCanvasUrl){_this.setAppInfoToCloud()
return _this.checkFiles(function(err,res){return res?void 0:_this.startImport()})}return _this.checkFiles(function(err,res){return res?_this.showInstructions():_this.startImport()})})}
FacebookTeamwork.prototype.checkFiles=function(callback){null==callback&&(callback=noop)
return FSHelper.exists("Web/Teamwork/Facebook",KD.getSingleton("vmController").defaultVmName,function(err,res){return callback(err,res)})}
FacebookTeamwork.prototype.startImport=function(){var contentDetails,playgroundManifest,_ref,_this=this
_ref=this.getOptions(),contentDetails=_ref.contentDetails,playgroundManifest=_ref.playgroundManifest
return this.getDelegate().showImportWarning(contentDetails.url,function(){_this.appStorage.setValue("FacebookAppVersion",playgroundManifest.version)
return _this.emit("ContentImportDone")})}
FacebookTeamwork.prototype.createRunButton=function(panel){var _this=this
return panel.header.addSubView(this.runButton=new KDButtonViewWithMenu({title:"Run",menu:{"Run on Facebook":{callback:function(){return _this.runOnFB()}}},callback:function(){return _this.run()}}))}
FacebookTeamwork.prototype.run=function(){var activePanel,editor,nick,paneLauncher,path,preview,previewPane,root,target
activePanel=this.getActivePanel()
paneLauncher=activePanel.paneLauncher
paneLauncher.panesCreated||paneLauncher.createPanes()
preview=paneLauncher.preview,previewPane=paneLauncher.previewPane
paneLauncher.handleLaunch("preview")
editor=activePanel.getPaneByName("editor")
root="Web/Teamwork/Facebook"
path=FSHelper.plainPath(editor.getActivePaneFileData().path).replace(root,"")
nick=this.amIHost()?KD.nick():this.getHost()
target="https://"+nick+".kd.io/Teamwork/Facebook"
path.indexOf("localfile")>-1||(target+=path)
return previewPane.previewer.openPath(target)}
FacebookTeamwork.prototype.runOnFB=function(){var _this=this
return this.amIHost()||this.appNamespace?KD.utils.createExternalLink("http://apps.facebook.com/"+this.appNamespace):this.getAppInforFromCloud(function(){return _this.runOnFB()})}
FacebookTeamwork.prototype.setAppInfoToCloud=function(){return this.workspaceRef.child("FacebookAppInfo").set({appId:this.appId,appNamespace:this.appNamespace,appCanvasUrl:this.appCanvasUrl})}
FacebookTeamwork.prototype.getAppInforFromCloud=function(callback){var _this=this
null==callback&&(callback=noop)
return this.workspaceRef.once("value",function(snapshot){var facebookAppInfo
facebookAppInfo=snapshot.val().FacebookAppInfo
if(facebookAppInfo){_this.appId=facebookAppInfo.appId
_this.appNamespace=facebookAppInfo.appNamespace
_this.appCanvasUrl=facebookAppInfo.appCanvasUrl
return callback()}})}
FacebookTeamwork.prototype.createIndexFile=function(){var example,file,markup,_i,_len,_ref
markup=""
_ref=this.getOptions().examples
for(_i=0,_len=_ref.length;_len>_i;_i++){example=_ref[_i]
markup+=this.exampleItemMarkup(example.title,example.description)}markup=this.examplesPageMarkup(markup)
file=FSHelper.createFileFromPath("Web/Teamwork/Facebook/index.html")
return file.save(markup,function(err){return err?warn(err):void 0})}
FacebookTeamwork.prototype.exampleItemMarkup=function(title,description){return'<a href="https://'+KD.nick()+".kd.io/Teamwork/Facebook/"+title+'/index.html">\n  <div class="example">\n    <h3>'+title+"</h3>\n    <p>"+description+"</p>\n  </div>\n</a>"}
FacebookTeamwork.prototype.examplesPageMarkup=function(examplesMarkup){return'<html>\n  <head>\n    <title>Facebook App Examples</title>\n    <link rel="stylesheet" type="text/css" href="https://koding-cdn.s3.amazonaws.com/teamwork/tw-fb.css" />\n  </head>\n  <body>\n    <div class="examples">\n      '+examplesMarkup+"\n    </div>\n  </body>\n</html>"}
FacebookTeamwork.prototype.showHintModal=function(){var editor,file,readme,_this=this
editor=this.getActivePanel().getPaneByName("editor")
file=editor.getActivePaneFileData()
readme=FSHelper.createFileFromPath(""+file.parentPath+"/README.md")
return readme.fetchContents(function(err,content){return content?_this.getDelegate().showMarkdownModal(content):void 0})}
return FacebookTeamwork}(TeamworkWorkspace)

var TeamworkAppView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkAppView=function(_super){function TeamworkAppView(options,data){null==options&&(options={})
TeamworkAppView.__super__.constructor.call(this,options,data)
this.emit("ready")
if(location.search.match("chromeapp")){KD.getSingleton("mainView").enableFullscreen()
window.parent.postMessage("TeamworkReady","*")}}__extends(TeamworkAppView,_super)
TeamworkAppView.prototype.handleQuery=function(query){return this.teamworkApp?void 0:this.teamworkApp=new TeamworkApp({delegate:this,query:query})}
return TeamworkAppView}(KDView)

var TeamworkAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkAppController=function(_super){function TeamworkAppController(options,data){null==options&&(options={})
options.view=new TeamworkAppView
options.appInfo={type:"application",name:"Teamwork"}
TeamworkAppController.__super__.constructor.call(this,options,data)}__extends(TeamworkAppController,_super)
KD.registerAppClass(TeamworkAppController,{name:"Teamwork",route:"/:name?/Teamwork",behavior:"application"})
TeamworkAppController.prototype.handleQuery=function(query){var view
view=this.getView()
return view.ready(function(){return view.handleQuery(query)})}
return TeamworkAppController}(AppController)

//@ sourceMappingURL=/js/__app.teamwork.0.0.1.js.map