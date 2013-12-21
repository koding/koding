var WebTerm,WebTermController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WebTermController=function(_super){function WebTermController(options,data){var joinUser,params,session,vmName
null==options&&(options={})
params=options.params||{}
joinUser=params.joinUser,session=params.session
vmName=params.vmName||KD.getSingleton("vmController").defaultVmName
options.view=new WebTermAppView({vmName:vmName,joinUser:joinUser,session:session})
options.appInfo={title:"Terminal on "+vmName,cssClass:"webterm"}
WebTermController.__super__.constructor.call(this,options,data)
KD.mixpanel("Opened Webterm tab",{vmName:vmName})}__extends(WebTermController,_super)
KD.registerAppClass(WebTermController,{name:"Terminal",title:"Terminal",route:{slug:"/:name?/Terminal",handler:function(_arg){var name,query,router,_ref
_ref=_arg.params,name=_ref.name,query=_arg.query
router=KD.getSingleton("router")
return router.openSection("Terminal",name,query)}},multiple:!0,hiddenHandle:!1,menu:{width:250,items:[{title:"customViewAdvancedSettings"}]},behavior:"application"})
WebTermController.prototype.handleQuery=function(query){var _this=this
return this.getView().ready(function(){return _this.getView().handleQuery(query)})}
return WebTermController}(AppController)
WebTerm={}

var WebTermView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WebTermView=function(_super){function WebTermView(options,data){null==options&&(options={})
WebTermView.__super__.constructor.call(this,options,data)
options.vmName&&(this._vmName=options.vmName)
this.initBackoff()}__extends(WebTermView,_super)
WebTermView.prototype.viewAppended=function(){var _base,_this=this
this.container=new KDView({cssClass:"console ubuntu-mono green-on-black",bind:"scroll"})
this.container.on("scroll",function(){return _this.container.$().scrollLeft(0)})
this.addSubView(this.container)
this.terminal=new WebTerm.Terminal(this.container.$())
null==(_base=this.options).advancedSettings&&(_base.advancedSettings=!1)
if(this.options.advancedSettings){this.advancedSettings=new KDButtonViewWithMenu({style:"editor-advanced-settings-menu",icon:!0,iconOnly:!0,iconClass:"cog",type:"contextmenu",delegate:this,itemClass:WebtermSettingsView,click:function(pubInst,event){return this.contextMenu(event)},menu:this.getAdvancedSettingsMenuItems.bind(this)})
this.addSubView(this.advancedSettings)}this.terminal.sessionEndedCallback=function(){_this.emit("WebTerm.terminated")
return _this.clearConnectionAttempts()}
this.terminal.setTitleCallback=function(){}
this.terminal.flushedCallback=function(){return _this.emit("WebTerm.flushed")}
this.listenWindowResize()
this.focused=!0
this.on("ReceivedClickElsewhere",function(){_this.focused=!1
_this.terminal.setFocused(!1)
return KD.getSingleton("windowController").removeLayer(_this)})
this.on("KDObjectWillBeDestroyed",this.bound("clearConnectionAttempts"))
window.addEventListener("blur",function(){return _this.terminal.setFocused(!1)})
window.addEventListener("focus",function(){return _this.terminal.setFocused(_this.focused)})
document.addEventListener("paste",function(event){var _ref
if(_this.focused){null!=(_ref=_this.terminal)&&_ref.server.input(event.clipboardData.getData("text/plain"))
return _this.setKeyView()}})
this.bindEvent("contextmenu")
return this.connectToTerminal()}
WebTermView.prototype.connectToTerminal=function(){var kiteController,kiteErrorCallback,_this=this
this.appStorage=KD.getSingleton("appStorageController").storage("WebTerm","1.0")
this.appStorage.fetchStorage(function(){var delegateOptions,myOptions
null==_this.appStorage.getValue("font")&&_this.appStorage.setValue("font","ubuntu-mono")
null==_this.appStorage.getValue("fontSize")&&_this.appStorage.setValue("fontSize",14)
null==_this.appStorage.getValue("theme")&&_this.appStorage.setValue("theme","green-on-black")
null==_this.appStorage.getValue("visualBell")&&_this.appStorage.setValue("visualBell",!1)
null==_this.appStorage.getValue("scrollback")&&_this.appStorage.setValue("scrollback",1e3)
_this.updateSettings()
delegateOptions=_this.getDelegate().getOptions()
myOptions=_this.getOptions()
return KD.getSingleton("vmController").run({method:"webterm.connect",vmName:_this._vmName||delegateOptions.vmName,withArgs:{remote:_this.terminal.clientInterface,sizeX:_this.terminal.sizeX,sizeY:_this.terminal.sizeY,joinUser:myOptions.joinUser||delegateOptions.joinUser,session:myOptions.session||delegateOptions.session,noScreen:delegateOptions.noScreen}},function(err,remote){if(err){warn(err)
if("Invalid session identifier."===err.message)return _this.reinitializeWebTerm()}_this.terminal.eventHandler=function(data){return _this.emit("WebTermEvent",data)}
_this.terminal.server=remote
_this.setKeyView()
_this.emit("WebTermConnected",remote)
return _this.sessionId=remote.session})})
KD.getSingleton("status").once("reconnected",function(){return _this.handleReconnect()})
kiteErrorCallback=function(err){var code,serviceGenericName
_this.reconnected=!1
code=err.code,serviceGenericName=err.serviceGenericName
return 503===code&&0===serviceGenericName.indexOf("kite-os")?_this.reconnectAttemptFailed(serviceGenericName,_this._vmName||_this.getDelegate().getOption("vmName")):void 0}
kiteController=KD.getSingleton("kiteController")
kiteController.on("KiteError",kiteErrorCallback)
return this.on("KiteErrorBindingNeedsToBeRemoved",function(){return kiteController.off("KiteError",kiteErrorCallback)})}
WebTermView.prototype.reconnectAttemptFailed=function(serviceGenericName,vmName){var kiteController,kiteRegion,kiteType,prefix,serviceName,_ref,_ref1
if(!this.reconnected&&serviceGenericName){kiteController=KD.getSingleton("kiteController")
_ref=serviceGenericName.split("-"),prefix=_ref[0],kiteType=_ref[1],kiteRegion=_ref[2]
serviceName="~"+kiteType+"-"+kiteRegion+"~"+vmName
this.setBackoffTimeout(this.bound("atttemptToReconnect"),this.bound("handleConnectionFailure"))
return null!=(_ref1=kiteController.kiteInstances[serviceName])?_ref1.cycleChannel():void 0}}
WebTermView.prototype.atttemptToReconnect=function(){var hasResponse,vmController,_this=this
if(!this.reconnected){null==this.reconnectingNotification&&(this.reconnectingNotification=new KDNotificationView({type:"mini",title:"Trying to reconnect your Terminal",duration:12e4,container:this.container}))
vmController=KD.getSingleton("vmController")
hasResponse=!1
vmController.info(this._vmName||this.getDelegate().getOption("vmName"),function(){hasResponse=!0
_this.handleReconnect()
return _this.clearConnectionAttempts()})
return this.utils.wait(500,function(){return hasResponse?void 0:_this.reconnectAttemptFailed()})}}
WebTermView.prototype.clearConnectionAttempts=function(){this.emit("KiteErrorBindingNeedsToBeRemoved")
return this.clearBackoffTimeout()}
WebTermView.prototype.handleReconnect=function(){var options,_ref
if(!this.reconnected){this.clearConnectionAttempts()
options={session:this.sessionId,joinUser:KD.nick()}
this.reinitializeWebTerm(options)
null!=(_ref=this.reconnectingNotification)&&_ref.destroy()
return this.reconnected=!0}}
WebTermView.prototype.reinitializeWebTerm=function(options){var webterm,_this=this
null==options&&(options={})
options.delegate=this.getDelegate()
this.addSubView(webterm=new WebTermView(options))
return webterm.on("WebTermConnected",function(){return _this.getSubViews().first.destroy()})}
WebTermView.prototype.handleConnectionFailure=function(){var _ref
if(!this.failedToReconnect){null!=(_ref=this.reconnectingNotification)&&_ref.destroy()
this.reconnected=!1
this.failedToReconnect=!0
this.clearConnectionAttempts()
return new KDNotificationView({type:"mini",title:"Sorry, something is wrong with our backend.",container:this.container,cssClass:"error",duration:15e3})}}
WebTermView.prototype.destroy=function(){var _ref
WebTermView.__super__.destroy.apply(this,arguments)
return null!=(_ref=this.terminal.server)?_ref.terminate():void 0}
WebTermView.prototype.updateSettings=function(){var font,theme,_i,_j,_len,_len1,_ref,_ref1
_ref=__webtermSettings.fonts
for(_i=0,_len=_ref.length;_len>_i;_i++){font=_ref[_i]
this.container.unsetClass(font.value)}_ref1=__webtermSettings.themes
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){theme=_ref1[_j]
this.container.unsetClass(theme.value)}this.container.setClass(this.appStorage.getValue("font"))
this.container.setClass(this.appStorage.getValue("theme"))
this.container.$().css({fontSize:this.appStorage.getValue("fontSize")+"px"})
this.terminal.updateSize(!0)
this.terminal.scrollToBottom(!1)
this.terminal.controlCodeReader.visualBell=this.appStorage.getValue("visualBell")
return this.terminal.setScrollbackLimit(this.appStorage.getValue("scrollback"))}
WebTermView.prototype.setKeyView=function(){WebTermView.__super__.setKeyView.apply(this,arguments)
KD.getSingleton("windowController").addLayer(this)
this.focused=!0
return this.terminal.setFocused(!0)}
WebTermView.prototype.click=function(){var _ref
this.setKeyView()
return null!=(_ref=this.textarea)?_ref.remove():void 0}
WebTermView.prototype.keyDown=function(event){this.listenFullscreen(event)
return this.terminal.keyDown(event)}
WebTermView.prototype.keyPress=function(event){return this.terminal.keyPress(event)}
WebTermView.prototype.keyUp=function(event){return this.terminal.keyUp(event)}
WebTermView.prototype.contextMenu=function(event){this.createInvisibleTextarea(event)
this.setKeyView()
return event}
WebTermView.prototype.createInvisibleTextarea=function(){var selectedText,_ref,_this=this
window.getSelection?selectedText=window.getSelection():document.getSelection?selectedText=document.getSelection():document.selection&&(selectedText=document.selection.createRange().text)
null!=(_ref=this.textarea)&&_ref.remove()
this.textarea=$(document.createElement("textarea"))
this.textarea.css({position:"absolute",opacity:0,width:"100%",height:"100%",top:0,left:0,right:0,bottom:0})
this.$().append(this.textarea)
this.textarea.on("copy cut paste",function(){_this.setKeyView()
_this.utils.wait(1e3,function(){return _this.textarea.remove()})
return!0})
if(selectedText){this.textarea.val(selectedText.toString())
this.textarea.select()}this.textarea.focus()
return this.utils.wait(15e3,function(){var _ref1
return null!=(_ref1=_this.textarea)?_ref1.remove():void 0})}
WebTermView.prototype._windowDidResize=function(){return this.terminal.windowDidResize()}
WebTermView.prototype.getAdvancedSettingsMenuItems=function(){return{settings:{type:"customView",view:new WebtermSettingsView({delegate:this})}}}
WebTermView.prototype.listenFullscreen=function(event){var mainView,requestFullscreen
requestFullscreen=(event.metaKey||event.ctrlKey)&&13===event.keyCode
if(requestFullscreen){mainView=KD.getSingleton("mainView")
mainView.toggleFullscreen()
return event.preventDefault()}}
WebTermView.prototype.initBackoff=KDBroker.Broker.prototype.initBackoff
return WebTermView}(KDView)

var VMSelection,VmListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmListItem=function(_super){function VmListItem(){_ref=VmListItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(VmListItem,_super)
VmListItem.prototype.click=function(){return this.getDelegate().emit("VMSelected",this.getData())}
VmListItem.prototype.viewAppended=function(){return JView.prototype.viewAppended.call(this)}
VmListItem.prototype.pistachio=function(){return'<div class="vm-info">\n  <cite></cite>\n  '+this.getData()+"\n</div>"}
return VmListItem}(KDListItemView)
VMSelection=function(_super){function VMSelection(options,data){null==options&&(options={})
VMSelection.__super__.constructor.call(this,{width:300,title:"Select VM",overlay:!0,draggable:!1,cancellable:!0,appendToDomBody:!0,delegate:options.delegate},data)
this.listController=new KDListViewController({view:new KDListView({type:"vm",cssClass:"vm-list",itemClass:VmListItem})})}__extends(VMSelection,_super)
VMSelection.prototype.viewAppended=function(){var view,_this=this
this.addSubView(view=this.listController.getView())
this.listController.getListView().on("VMSelected",function(vm){_this.emit("VMSelected",vm)
return _this.destroy()})
return this.listController.instantiateListItems(KD.getSingleton("vmController").vms)}
return VMSelection}(KDModalView)

var ChromeTerminalBanner,WebTermAppView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WebTermAppView=function(_super){function WebTermAppView(options,data){var _this=this
null==options&&(options={})
WebTermAppView.__super__.constructor.call(this,options,data)
this.tabHandleContainer=new ApplicationTabHandleHolder({delegate:this,addPlusHandle:!1})
this.tabView=new ApplicationTabView({delegate:this,tabHandleContainer:this.tabHandleContainer,resizeTabHandles:!0,closeAppWhenAllTabsClosed:!1})
this.tabView.on("PaneDidShow",function(pane){var webTermView,_ref
_this._windowDidResize()
webTermView=pane.getOptions().webTermView
webTermView.on("viewAppended",function(){return webTermView.terminal.setFocused(!0)})
webTermView.once("viewAppended",function(){return _this.emit("ready")})
null!=(_ref=webTermView.terminal)&&_ref.setFocused(!0)
KD.utils.defer(function(){return webTermView.setKeyView()})
return webTermView.on("WebTerm.terminated",function(){return pane.isDestroyed||_this.tabView.getActivePane()!==pane?void 0:_this.tabView.removePane(pane)})})
this.on("KDObjectWillBeDestroyed",function(){return KD.getSingleton("mainView").disableFullscreen()})
this.messagePane=new KDCustomHTMLView({cssClass:"message-pane",partial:"Loading Terminal..."})
this.tabView.on("AllTabsClosed",function(){return _this.setMessage("All tabs are closed. You can create a new\nTerminal by clicking (+) Plus button on top left.",!0)})}__extends(WebTermAppView,_super)
WebTermAppView.prototype.setMessage=function(msg,light,bindClose){null==light&&(light=!1)
null==bindClose&&(bindClose=!1)
this.messagePane.updatePartial(msg)
light?this.messagePane.setClass("light"):this.messagePane.unsetClass("light")
this.messagePane.show()
return bindClose?this.messagePane.once("click",function(){KD.singleton("router").back()
return KD.singleton("appManager").quitByName("Terminal")}):void 0}
WebTermAppView.prototype.checkVM=function(){var vmController,_this=this
vmController=KD.getSingleton("vmController")
return vmController.fetchDefaultVmName(function(vmName){KD.mixpanel("Click open Webterm",{vmName:vmName})
return vmName?vmController.info(vmName,KD.utils.getTimedOutCallback(function(err,vm,info){"RUNNING"===(null!=info?info.state:void 0)&&_this.addNewTab(vmName)
return KD.mixpanel("Opened Webterm",{vmName:vmName})},function(){KD.mixpanel("Can't open Webterm",{vmName:vmName})
return _this.setMessage("Couldn't connect to your VM, please try again later. <a href='#'>close this</a> ",!1,!0)},5e3)):_this.setMessage("It seems you don't have a VM to use with Terminal.")})}
WebTermAppView.prototype.showApprovalModal=function(remote,command){var modal
return modal=new KDModalView({title:"Warning!",content:'<div class="modalformline">\n  <p>\n    If you <strong>don\'t trust this app</strong>, or if you clicked on this\n    link <strong>not knowing what it would do</strong> - be careful it <strong>can\n    damage/destroy</strong> your Koding VM.\n  </p>\n</div>\n<div class="modalformline">\n  <p>\n    This URL is set to execute the command below:\n  </p>\n</div>\n<pre>\n  '+Encoder.XSSEncode(command)+"\n</pre>",buttons:{Run:{cssClass:"modal-clean-gray",callback:function(){remote.input(""+command+"\n")
return modal.destroy()}},Cancel:{cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})}
WebTermAppView.prototype.getAdvancedSettingsMenuView=function(item,menu){var pane,settingsView,webTermView
pane=this.tabView.getActivePane()
if(pane){webTermView=pane.getOptions().webTermView
settingsView=new KDView({cssClass:"editor-advanced-settings-menu"})
settingsView.addSubView(new WebtermSettingsView({menu:menu,delegate:webTermView}))
return settingsView}}
WebTermAppView.prototype.handleQuery=function(query){var pane,webTermView,_this=this
pane=this.tabView.getActivePane()
webTermView=pane.getOptions().webTermView
return webTermView.once("WebTermConnected",function(remote){var command
if(query.command){command=decodeURIComponent(query.command)
_this.showApprovalModal(remote,command)}if(query.chromeapp){query.fullscreen=!0
_this.chromeAppMode()}return query.fullscreen?KD.getSingleton("mainView").enableFullscreen():void 0})}
WebTermAppView.prototype.chromeAppMode=function(){var mainController,parent,windowController,_ref
windowController=KD.getSingleton("windowController")
mainController=KD.getSingleton("mainController")
if(null!=(_ref=window.parent)?_ref.postMessage:void 0){parent=window.parent
mainController.on("clientIdChanged",function(){return parent.postMessage("clientIdChanged","*")})
parent.postMessage("fullScreenTerminalReady","*")
KD.isLoggedIn()&&parent.postMessage("loggedIn","*")
this.on("KDObjectWillBeDestroyed",function(){return parent.postMessage("fullScreenWillBeDestroyed","*")})}return this.addSubView(new ChromeTerminalBanner)}
WebTermAppView.prototype.viewAppended=function(){WebTermAppView.__super__.viewAppended.apply(this,arguments)
return this.checkVM()}
WebTermAppView.prototype.createNewTab=function(vmName){var pane,webTermView
webTermView=new WebTermView({testPath:"webterm-tab",delegate:this,vmName:vmName})
pane=new KDTabPaneView({name:"Terminal",webTermView:webTermView})
this.tabView.addPane(pane)
return pane.addSubView(webTermView)}
WebTermAppView.prototype.addNewTab=function(vmName){var _this=this
this.messagePane.hide()
this.tabHandleContainer.plusHandle||this.tabHandleContainer.addPlusHandle()
this._secondTab&&KD.mixpanel("Click open new Webterm tab")
this._secondTab=!0
return vmName?this.createNewTab(vmName):this.utils.defer(function(){var vmc,vmselection
vmc=KD.getSingleton("vmController")
if(vmc.vms.length>1){vmselection=new VMSelection
return vmselection.once("VMSelected",function(vm){return _this.createNewTab(vm)})}return _this.createNewTab(vmc.vms.first)})}
WebTermAppView.prototype.pistachio=function(){return"{{> this.tabHandleContainer}}\n{{> this.messagePane}}\n{{> this.tabView}}"}
return WebTermAppView}(JView)
ChromeTerminalBanner=function(_super){function ChromeTerminalBanner(options,data){var _this=this
null==options&&(options={})
options.domId="chrome-terminal-banner"
ChromeTerminalBanner.__super__.constructor.call(this,options,data)
this.descriptionHidden=!0
this.mainView=KD.getSingleton("mainView")
this.router=KD.getSingleton("router")
this.finder=KD.getSingleton("finderController")
this.mainView.on("fullscreen",function(state){return state?_this.show():_this.hide()})
this.register=new CustomLinkView({cssClass:"action",title:"Register",click:function(){return _this.revealKoding("/Register")}})
this.login=new CustomLinkView({cssClass:"action",title:"Login",click:function(){return _this.revealKoding("/Login")}})
this.whatIsThis=new CustomLinkView({cssClass:"action",title:"What is This?",click:function(){_this.descriptionHidden?_this.description.show():_this.description.hide()
return _this.descriptionHidden=!_this.descriptionHidden}})
this.description=new KDCustomHTMLView({tagName:"p",cssClass:"hidden",partial:'This is a complete virtual environment provided by Koding. <br>\nKoding is a social development environment. <br>\nVisit and see it in action at <a href="http://koding.com" target="_blank">http://koding.com</a>'})
this.revealer=new CustomLinkView({cssClass:"action",title:"Reveal Koding",click:function(){return _this.revealKoding()}})}__extends(ChromeTerminalBanner,_super)
ChromeTerminalBanner.prototype.revealKoding=function(route){KD.isLoggedIn()||this.finder.mountVm("vm-0."+KD.nick()+".guests.kd.io")
route&&this.router.handleRoute(route)
return this.mainView.disableFullscreen()}
ChromeTerminalBanner.prototype.pistachio=function(){return KD.isLoggedIn()?'<span class="koding-icon"></span>\n<div class="actions">\n  {{> this.revealer}}\n</div>':'<span class="koding-icon"></span>\n<div class="actions">\n  {{> this.register}}\n  {{> this.login}}\n  {{> this.whatIsThis}}\n</div>\n{{> this.description}}'}
return ChromeTerminalBanner}(JView)

var WebtermSettingsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WebtermSettingsView=function(_super){function WebtermSettingsView(options,data){var mainView,webtermView,_this=this
null==options&&(options={})
WebtermSettingsView.__super__.constructor.call(this,options,data)
this.setClass("ace-settings-view webterm-settings-view")
webtermView=this.getDelegate()
this.font=new KDSelectBox({selectOptions:__webtermSettings.fonts,callback:function(value){webtermView.appStorage.setValue("font",value)
return webtermView.updateSettings()},defaultValue:webtermView.appStorage.getValue("font")})
this.fontSize=new KDSelectBox({selectOptions:__webtermSettings.fontSizes,callback:function(value){webtermView.appStorage.setValue("fontSize",value)
return webtermView.updateSettings()},defaultValue:webtermView.appStorage.getValue("fontSize")})
this.theme=new KDSelectBox({selectOptions:__webtermSettings.themes,callback:function(value){webtermView.appStorage.setValue("theme",value)
return webtermView.updateSettings()},defaultValue:webtermView.appStorage.getValue("theme")})
this.bell=new KDOnOffSwitch({callback:function(value){webtermView.appStorage.setValue("visualBell",value)
return webtermView.updateSettings()},defaultValue:webtermView.appStorage.getValue("visualBell")})
mainView=KD.getSingleton("mainView")
this.fullscreen=new KDOnOffSwitch({callback:function(state){var menu
state?mainView.enableFullscreen():mainView.disableFullscreen()
menu=_this.getOptions().menu
menu.contextMenu.destroy()
return menu.click()},defaultValue:mainView.isFullscreen()})
this.scrollback=new KDSelectBox({selectOptions:__webtermSettings.scrollback,callback:function(value){webtermView.appStorage.setValue("scrollback",value)
return webtermView.updateSettings()},defaultValue:webtermView.appStorage.getValue("scrollback")})}__extends(WebtermSettingsView,_super)
WebtermSettingsView.prototype.pistachio=function(){return"<p>Font                     {{> this.font}}</p>\n<p>Font Size                {{> this.fontSize}}</p>\n<p>Theme                    {{> this.theme}}</p>\n<p>Scrollback               {{> this.scrollback}}</p>\n<p>Use Visual Bell          {{> this.bell}}</p>\n<p>Fullscreen               {{> this.fullscreen}}</p>"}
return WebtermSettingsView}(JView)

var __webtermSettings
__webtermSettings={fonts:[{value:"source-code-pro",title:"Source Code Pro"},{value:"ubuntu-mono",title:"Ubuntu Mono"}],fontSizes:[{value:10,title:"10px"},{value:11,title:"11px"},{value:12,title:"12px"},{value:13,title:"13px"},{value:14,title:"14px"},{value:16,title:"16px"},{value:20,title:"20px"},{value:24,title:"24px"}],themes:[{title:"Black on White",value:"black-on-white"},{title:"Gray on Black",value:"gray-on-black"},{title:"Green on Black",value:"green-on-black"},{title:"Solarized Dark",value:"solarized-dark"},{title:"Solarized Light",value:"solarized-light"}],scrollback:[{title:"Unlimited",value:Number.MAX_VALUE},{title:"50",value:50},{title:"100",value:100},{title:"1000",value:1e3},{title:"10000",value:1e4}]}

WebTerm.ControlCodeReader=function(){function ControlCodeReader(terminal,handler,nextReader){this.terminal=terminal
this.handler=handler
this.nextReader=nextReader
this.data=""
this.pos=0
this.controlCodeOffset=null
this.regexp=new RegExp(Object.keys(this.handler.map).join("|"))}ControlCodeReader.prototype.skip=function(length){return this.pos+=length}
ControlCodeReader.prototype.readChar=function(){var c
if(this.pos>=this.data.length)return null
c=this.data.charAt(this.pos)
this.pos+=1
return c}
ControlCodeReader.prototype.readRegexp=function(regexp){var result
result=this.data.substring(this.pos).match(regexp)
if(null==result)return null
this.pos+=result[0].length
return result}
ControlCodeReader.prototype.readUntil=function(regexp){var endPos,string
endPos=this.data.substring(this.pos).search(regexp)
if(-1===endPos)return null
string=this.data.substring(this.pos,this.pos+endPos)
this.pos+=endPos
return string}
ControlCodeReader.prototype.addData=function(newData){return this.data+=newData}
ControlCodeReader.prototype.process=function(){var text
if(!this.nextReader.process())return!1
if(0===this.data.length)return!0
if(null!=this.controlCodeOffset){this.controlCodeIncomplete=!1
this.handler(this)
if(this.controlCodeIncomplete){this.pos=this.controlCodeOffset
return!0}this.controlCodeOffset=null
return!1}if(null!=(text=this.readUntil(this.regexp))){this.nextReader.addData(text)
this.nextReader.process()
this.controlCodeOffset=this.pos
return!1}this.nextReader.addData(this.data.substring(this.pos))
this.data=""
this.pos=0
return this.nextReader.process()}
ControlCodeReader.prototype.incompleteControlCode=function(){return this.controlCodeIncomplete=!0}
ControlCodeReader.prototype.unsupportedControlCode=function(){return warn("Unsupported control code: "+this.terminal.inspectString(this.data.substring(this.controlCodeOffset,this.pos)))}
return ControlCodeReader}()
WebTerm.TextReader=function(){function TextReader(terminal){this.terminal=terminal
this.data=""}TextReader.prototype.addData=function(newData){return this.data+=newData}
TextReader.prototype.process=function(){var remaining
if(0===this.data.length)return!0
for(;this.terminal.cursor.x+this.data.length>this.terminal.sizeX;){remaining=this.terminal.sizeX-this.terminal.cursor.x
this.terminal.writeText(this.data.substring(0,remaining))
this.terminal.lineFeed()
this.terminal.cursor.moveTo(0,this.terminal.cursor.y)
this.data=this.data.substring(remaining)}this.terminal.writeText(this.data)
this.terminal.cursor.move(this.data.length,0)
this.data=""
return!0}
return TextReader}()
WebTerm.createAnsiControlCodeReader=function(terminal){var catchCharacter,catchParameters,eachParameter,getOrigin,ignored,initCursorControlHandler,initEscapeSequenceHandler,insertOrDeleteLines,originMode,switchCharacter,switchParameter,switchRawParameter
switchCharacter=function(map){var f
f=function(reader){var c,handler
c=reader.readChar()
if(null==c)return reader.incompleteControlCode()
handler=map[c]
return null==handler?reader.unsupportedControlCode():handler(reader)}
f.map=map
return f}
catchCharacter=function(handler){return function(reader){var c
c=reader.readChar()
return null==c?reader.incompleteControlCode():handler(c)}}
catchParameters=function(regexp,map){return function(reader){var command,handler,p,paramString,params,prefix,rawParams,result,_
result=reader.readRegexp(regexp)
if(null==result)return reader.incompleteControlCode()
_=result[0],prefix=result[1],paramString=result[2],command=result[3]
rawParams=function(){var _i,_len,_ref,_results
if(0===paramString.length)return[]
_ref=paramString.split(";")
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){p=_ref[_i]
0===p.length?_results.push(null):_results.push(p)}return _results}()
params=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=rawParams.length;_len>_i;_i++){p=rawParams[_i]
p?_results.push(parseInt(p,10)):_results.push(null)}return _results}()
params.raw=rawParams
if(!(map instanceof Function)){handler=map[prefix+command]
return null==handler?reader.unsupportedControlCode():handler(params,reader)}map(params,reader)}}
switchParameter=function(index,map){return function(params,reader){var handler,_ref
handler=map[null!=(_ref=params[index])?_ref:0]
return null==handler?reader.unsupportedControlCode():handler(params)}}
switchRawParameter=function(index,map){return function(params,reader){var handler
handler=map[params.raw[index]]
return null==handler?reader.unsupportedControlCode():handler(params)}}
eachParameter=function(map){var f
f=function(params,reader){for(var handler,_ref;params.length>0;){handler=map[null!=(_ref=params[0])?_ref:0]
if(null==handler)return reader.unsupportedControlCode()
handler(params,reader)
params.shift()}}
f.addRange=function(from,to,handler){var i,_i
for(i=_i=from;to>=from?to>=_i:_i>=to;i=to>=from?++_i:--_i)map[i]=handler
return f}
return f}
ignored=function(str){return function(){return"true"===("undefined"!=typeof localStorage&&null!==localStorage?localStorage["WebTerm.logRawOutput"]:void 0)?log("Ignored: "+str):void 0}}
originMode=!1
getOrigin=function(){return originMode?terminal.screenBuffer.scrollingRegion[0]:0}
insertOrDeleteLines=function(amount){var previousScrollingRegion
previousScrollingRegion=terminal.screenBuffer.scrollingRegion
terminal.screenBuffer.scrollingRegion=[terminal.cursor.y,terminal.screenBuffer.scrollingRegion[1]]
terminal.screenBuffer.scroll(-amount)
return terminal.screenBuffer.scrollingRegion=previousScrollingRegion}
initCursorControlHandler=function(){return switchCharacter({"\0":function(){},"\b":function(){return terminal.cursor.move(-1,0)},"	":function(){return terminal.cursor.moveTo(terminal.cursor.x-terminal.cursor.x%8+8,terminal.cursor.y)},"\n":function(){return terminal.lineFeed()},"":function(){return terminal.lineFeed()},"\r":function(){return terminal.cursor.moveTo(0,terminal.cursor.y)}})}
initEscapeSequenceHandler=function(){return switchCharacter({"":function(){return this.visualBell?new KDNotificationView({title:"Bell!"}):void 0},"":function(){return terminal.setCharacterSetIndex(1)},"":function(){return terminal.setCharacterSetIndex(0)},"":switchCharacter({D:function(){return terminal.lineFeed()},E:function(){terminal.lineFeed()
return terminal.cursor.moveTo(0,terminal.cursor.y)},M:function(){return terminal.reverseLineFeed()},P:catchParameters(/^()(.*?)(\x1B\\)/,{}),"#":switchCharacter({8:function(){var text,x,y,_i,_j,_ref,_ref1,_results
terminal.screenBuffer.clear()
text=""
for(x=_i=0,_ref=terminal.sizeX;_ref>=0?_ref>_i:_i>_ref;x=_ref>=0?++_i:--_i)text+="E"
_results=[]
for(y=_j=0,_ref1=terminal.sizeY;_ref1>=0?_ref1>_j:_j>_ref1;y=_ref1>=0?++_j:--_j)_results.push(terminal.writeText(text,{x:0,y:y}))
return _results}}),"(":catchCharacter(function(c){return terminal.setCharacterSet(0,c)}),")":catchCharacter(function(c){return terminal.setCharacterSet(1,c)}),"*":catchCharacter(function(c){return terminal.setCharacterSet(2,c)}),"+":catchCharacter(function(c){return terminal.setCharacterSet(3,c)}),"-":catchCharacter(function(c){return terminal.setCharacterSet(1,c)}),".":catchCharacter(function(c){return terminal.setCharacterSet(2,c)}),"/":catchCharacter(function(c){return terminal.setCharacterSet(3,c)}),7:function(){return terminal.cursor.savePosition()},8:function(){return terminal.cursor.restorePosition()},"=":function(){return terminal.inputHandler.useApplicationKeypad(!0)},">":function(){return terminal.inputHandler.useApplicationKeypad(!1)},"[":catchParameters(/^(\??)(.*?)([a-zA-Z@`{|])/,{"@":function(params){var _ref
return terminal.writeEmptyText(null!=(_ref=params[0])?_ref:1,{insert:!0})},A:function(params){var _ref
return terminal.cursor.move(0,-(null!=(_ref=params[0])?_ref:1))},B:function(params){var _ref
return terminal.cursor.move(0,null!=(_ref=params[0])?_ref:1)},C:function(params){var _ref
return terminal.cursor.move(null!=(_ref=params[0])?_ref:1,0)},D:function(params){var _ref
return terminal.cursor.move(-(null!=(_ref=params[0])?_ref:1),0)},G:function(params){var _ref
return terminal.cursor.moveTo((null!=(_ref=params[0])?_ref:1)-1,terminal.cursor.y)},H:function(params){var _ref,_ref1
return terminal.cursor.moveTo((null!=(_ref=params[1])?_ref:1)-1,getOrigin()+(null!=(_ref1=params[0])?_ref1:1)-1)},I:function(params){var _ref
return 0!==params[0]?terminal.cursor.moveTo(8*(Math.floor(terminal.cursor.x/8)+(null!=(_ref=params[0])?_ref:1)),terminal.cursor.y):void 0},J:switchParameter(0,{0:function(){var y,_i,_ref,_ref1,_results
terminal.writeEmptyText(terminal.sizeX-terminal.cursor.x)
_results=[]
for(y=_i=_ref=terminal.cursor.y+1,_ref1=terminal.sizeY;_ref1>=_ref?_ref1>_i:_i>_ref1;y=_ref1>=_ref?++_i:--_i)_results.push(terminal.writeEmptyText(terminal.sizeX,{x:0,y:y}))
return _results},1:function(){var y,_i,_ref
for(y=_i=0,_ref=terminal.cursor.y;_ref>=0?_ref>_i:_i>_ref;y=_ref>=0?++_i:--_i)terminal.writeEmptyText(terminal.sizeX,{x:0,y:y})
return terminal.writeEmptyText(terminal.cursor.x+1,{x:0})},2:function(){return terminal.screenBuffer.clear()}}),K:switchParameter(0,{0:function(){return terminal.writeEmptyText(terminal.sizeX-terminal.cursor.x)},1:function(){return terminal.writeEmptyText(terminal.cursor.x+1,{x:0})},2:function(){return terminal.writeEmptyText(terminal.sizeX,{x:0})}}),L:function(params){var _ref
return insertOrDeleteLines(null!=(_ref=params[0])?_ref:1)},M:function(params){var _ref
return insertOrDeleteLines(-(null!=(_ref=params[0])?_ref:1))},P:function(params){var _ref
return terminal.deleteCharacters(null!=(_ref=params[0])?_ref:1)},S:function(params){var _ref
return terminal.screenBuffer.scroll(null!=(_ref=params[0])?_ref:1)},T:function(params){var _ref
return terminal.screenBuffer.scroll(-(null!=(_ref=params[0])?_ref:1))},X:function(params){var _ref
return terminal.writeEmptyText(null!=(_ref=params[0])?_ref:1)},Z:function(params){var _ref
return 0!==params[0]?terminal.cursor.moveTo(8*(Math.ceil(terminal.cursor.x/8)-(null!=(_ref=params[0])?_ref:1)),terminal.cursor.y):void 0},c:switchRawParameter(0,{0:function(){return terminal.server.controlSequence("[>?1;2c")},">":function(){return terminal.server.controlSequence("[>0;261;0c")},">0":function(){return terminal.server.controlSequence("[>0;261;0c")}}),d:function(params){var _ref
return terminal.cursor.moveTo(terminal.cursor.x,getOrigin()+(null!=(_ref=params[0])?_ref:1)-1)},f:function(params){var _ref,_ref1
return terminal.cursor.moveTo((null!=(_ref=params[1])?_ref:1)-1,getOrigin()+(null!=(_ref1=params[0])?_ref1:1)-1)},h:eachParameter({4:ignored("insert mode"),20:ignored("automatic newline")}),"?h":eachParameter({1:function(){return terminal.inputHandler.useApplicationKeypad(!0)},3:ignored("132 column mode"),4:ignored("smooth scroll"),5:ignored("reverse video"),6:function(){return originMode=!0},7:ignored("wraparound mode"),8:ignored("auto-repeat keys"),9:function(){return terminal.inputHandler.setMouseMode(!0,!1,!1)},12:ignored("start blinking cursor"),25:function(){return terminal.cursor.setVisibility(!0)},40:ignored("allow 80 to 132 mode"),42:ignored("enable nation replacement character sets"),45:ignored("reverse-wraparound mode"),47:function(){return terminal.changeScreenBuffer(1)},1e3:function(){return terminal.inputHandler.setMouseMode(!0,!0,!1)},1001:function(){return terminal.inputHandler.setMouseMode(!0,!0,!1)},1002:function(){return terminal.inputHandler.setMouseMode(!0,!0,!0)},1003:function(){return terminal.inputHandler.setMouseMode(!0,!0,!0)},1015:ignored("enable urxvt mouse mode"),1034:ignored("interpret meta key"),1047:function(){return terminal.changeScreenBuffer(1)},1048:function(){return terminal.cursor.savePosition()},1049:function(){terminal.cursor.savePosition()
return terminal.changeScreenBuffer(1)}}),l:eachParameter({4:ignored("replace mode"),20:ignored("normal linefeed")}),"?l":eachParameter({1:function(){return terminal.inputHandler.useApplicationKeypad(!1)},3:ignored("80 column mode"),4:ignored("jump scroll"),5:ignored("normal video"),6:function(){return originMode=!1},7:ignored("no wraparound mode"),8:ignored("no auto-repeat keys"),9:function(){return terminal.inputHandler.setMouseMode(!1,!1,!1)},12:ignored("stop blinking cursor"),25:function(){return terminal.cursor.setVisibility(!1)},40:ignored("disallow 80 to 132 mode"),42:ignored("disable nation replacement character sets"),45:ignored("no reverse-wraparound mode"),47:function(){return terminal.changeScreenBuffer(0)},1e3:function(){return terminal.inputHandler.setMouseMode(!1,!1,!1)},1001:function(){return terminal.inputHandler.setMouseMode(!1,!1,!1)},1002:function(){return terminal.inputHandler.setMouseMode(!1,!1,!1)},1003:function(){return terminal.inputHandler.setMouseMode(!1,!1,!1)},1015:ignored("disable urxvt mouse mode"),1034:ignored("don't interpret meta key"),1047:function(){return terminal.changeScreenBuffer(0)},1048:function(){return terminal.cursor.restorePosition()},1049:function(){terminal.changeScreenBuffer(0)
return terminal.cursor.moveTo(0,terminal.sizeY-1)}}),m:eachParameter({0:function(){return terminal.resetStyle()},1:function(){return terminal.setStyle("bold",!0)},4:function(){return terminal.setStyle("underlined",!0)},7:function(){return terminal.setStyle("inverse",!0)},22:function(){return terminal.setStyle("bold",!1)},24:function(){return terminal.setStyle("underlined",!1)},27:function(){return terminal.setStyle("inverse",!1)},38:switchParameter(1,{5:function(params){terminal.setStyle("textColor",params[2])
params.shift()
return params.shift()}}),39:function(){return terminal.setStyle("textColor",null)},48:switchParameter(1,{5:function(params){terminal.setStyle("backgroundColor",params[2])
params.shift()
return params.shift()}}),49:function(){return terminal.setStyle("backgroundColor",null)}}).addRange(30,37,function(params){return terminal.setStyle("textColor",params[0]-30)}).addRange(40,47,function(params){return terminal.setStyle("backgroundColor",params[0]-40)}).addRange(90,97,function(params){return terminal.setStyle("textColor",params[0]-90+8)}).addRange(100,107,function(params){return terminal.setStyle("backgroundColor",params[0]-100+8)}),r:function(params){var _ref,_ref1
return terminal.screenBuffer.scrollingRegion=[(null!=(_ref=params[0])?_ref:1)-1,(null!=(_ref1=params[1])?_ref1:terminal.sizeY)-1]},"?r":ignored("restore mode values"),p:switchRawParameter(0,{"!":function(){terminal.cursor.setVisibility(!0)
originMode=!1
terminal.changeScreenBuffer(0)
return terminal.inputHandler.useApplicationKeypad(!1)}}),"?s":ignored("save mode values")}),"]":catchParameters(/()(.*?)(\x07|\x1B\\)/,switchParameter(0,{0:function(params){return"function"==typeof terminal.setTitleCallback?terminal.setTitleCallback(params.raw[1]):void 0},1:function(params){return"function"==typeof terminal.eventHandler?terminal.eventHandler(params.raw.slice(1,-1).join(";")):void 0},2:function(params){return"function"==typeof terminal.setTitleCallback?terminal.setTitleCallback(params.raw[1]):void 0},100:function(params){return"function"==typeof terminal.eventHandler?terminal.eventHandler(params.raw.slice(1).join(";")):void 0}}))})})}
return new WebTerm.ControlCodeReader(terminal,initCursorControlHandler(),new WebTerm.ControlCodeReader(terminal,initEscapeSequenceHandler(),new WebTerm.TextReader(terminal)))}

WebTerm.Cursor=function(){function Cursor(terminal){this.terminal=terminal
this.x=0
this.y=0
this.element=null
this.inversed=!0
this.visible=!0
this.focused=!0
this.blinkInterval=null
this.savedX=0
this.savedY=0
this.resetBlink()}Cursor.prototype.move=function(x,y){return this.moveTo(this.x+x,this.y+y)}
Cursor.prototype.moveTo=function(x,y){var lastY
x=Math.max(x,0)
y=Math.max(y,0)
x=Math.min(x,this.terminal.sizeX-1)
y=Math.min(y,this.terminal.sizeY-1)
if(x!==this.x||y!==this.y){this.x=x
lastY=this.y
this.y=y
lastY<this.terminal.sizeY&&y!==lastY&&this.terminal.screenBuffer.addLineToUpdate(lastY)
return this.terminal.screenBuffer.addLineToUpdate(y)}}
Cursor.prototype.savePosition=function(){this.savedX=this.x
return this.savedY=this.y}
Cursor.prototype.restorePosition=function(){return this.moveTo(this.savedX,this.savedY)}
Cursor.prototype.setVisibility=function(value){if(this.visible!==value){this.visible=value
this.element=null
return this.terminal.screenBuffer.addLineToUpdate(this.y)}}
Cursor.prototype.setFocused=function(value){if(this.focused!==value){this.focused=value
return this.resetBlink()}}
Cursor.prototype.resetBlink=function(){var _this=this
if(null!=this.blinkInterval){window.clearInterval(this.blinkInterval)
this.blinkInterval=null}this.inversed=!0
this.updateCursorElement()
return this.focused?this.blinkInterval=window.setInterval(function(){_this.inversed="true"===("undefined"!=typeof localStorage&&null!==localStorage?localStorage["WebTerm.slowDrawing"]:void 0)?!0:!_this.inversed
return _this.updateCursorElement()},600):void 0}
Cursor.prototype.addCursorElement=function(content){var newContent,_ref
if(!this.visible)return content
newContent=content.substring(0,this.x)
newContent.merge=!1
this.element=null!=(_ref=content.substring(this.x,this.x+1).get(0))?_ref:new WebTerm.StyledText(" ",this.terminal.currentStyle)
this.element.spanForced=!0
this.element.style=jQuery.extend(!0,{},this.element.style)
this.element.style.outlined=!this.focused
this.element.style.inverse=this.focused&&this.inversed
newContent.push(this.element)
newContent.pushAll(content.substring(this.x+1))
return newContent}
Cursor.prototype.updateCursorElement=function(){if(null!=this.element){this.element.style.outlined=!this.focused
this.element.style.inverse=this.focused&&this.inversed
return this.element.updateNode()}}
return Cursor}()

WebTerm.InputHandler=function(){function InputHandler(terminal){this.terminal=terminal
this.applicationKeypad=!1
this.trackMouseDown=!1
this.trackMouseUp=!1
this.trackMouseHold=!1
this.previousMouseX=-1
this.previousMouseY=-1}var CSI,ESC,OSC,SS3
ESC=""
CSI=ESC+"["
OSC=ESC+"]"
SS3=ESC+"O"
InputHandler.prototype.KEY_SEQUENCES={8:"",9:"	",13:"\r",27:ESC,33:CSI+"5~",34:CSI+"6~",35:SS3+"F",36:SS3+"H",37:[CSI+"D",SS3+"D"],38:[CSI+"A",SS3+"A"],39:[CSI+"C",SS3+"C"],40:[CSI+"B",SS3+"B"],46:CSI+"3~",112:SS3+"P",113:SS3+"Q",114:SS3+"R",115:SS3+"S",116:CSI+"15~",117:CSI+"17~",118:CSI+"18~",119:CSI+"19~",120:CSI+"20~",121:CSI+"21~",122:CSI+"23~",123:CSI+"24~"}
InputHandler.prototype.keyDown=function(event){var seq
this.terminal.scrollToBottom()
this.terminal.cursor.resetBlink()
if(event.ctrlKey){if(!(event.shiftKey||event.altKey||event.keyCode<64)){this.terminal.server.controlSequence(String.fromCharCode(event.keyCode-64))
event.preventDefault()}}else{seq=this.KEY_SEQUENCES[event.keyCode]
seq instanceof Array&&(seq=seq[this.applicationKeypad?1:0])
if(null!=seq){this.terminal.server.controlSequence(seq)
return event.preventDefault()}}}
InputHandler.prototype.keyPress=function(event){var _ref
if(!event.metaKey||114!==(_ref=event.charCode)&&118!==_ref){event.ctrlKey&&!event.altKey||0===event.charCode||this.terminal.server.input(String.fromCharCode(event.charCode))
return event.preventDefault()}}
InputHandler.prototype.keyUp=function(){}
InputHandler.prototype.setMouseMode=function(trackMouseDown,trackMouseUp,trackMouseHold){this.trackMouseDown=trackMouseDown
this.trackMouseUp=trackMouseUp
this.trackMouseHold=trackMouseHold
return this.terminal.outputbox.css("cursor",this.trackMouseDown?"pointer":"text")}
InputHandler.prototype.mouseEvent=function(event){var eventCode,offset,x,y
offset=this.terminal.container.offset()
x=Math.floor((event.originalEvent.clientX-offset.left+this.terminal.container.scrollLeft())*this.terminal.sizeX/this.terminal.container.prop("scrollWidth"))
y=Math.floor((event.originalEvent.clientY-offset.top+this.terminal.container.scrollTop())*this.terminal.screenBuffer.lineDivs.length/this.terminal.container.prop("scrollHeight")-this.terminal.screenBuffer.lineDivs.length+this.terminal.sizeY)
if(!(0>x||x>=this.terminal.sizeX||0>y||y>=this.terminal.sizeY)){eventCode=0
event.shiftKey&&(eventCode|=4)
event.altKey&&(eventCode|=8)
event.ctrlKey&&(eventCode|=16)
switch(event.type){case"mousedown":if(!this.trackMouseDown)return
eventCode|=event.which-1
break
case"mouseup":if(!this.trackMouseUp)return
eventCode|=3
break
case"mousemove":if(!this.trackMouseHold||0===event.which||x===this.previousMouseX&&y===this.previousMouseY)return
eventCode|=event.which-1
eventCode+=32
break
case"mousewheel":return!this.trackMouseDown
case"contextmenu":return!this.trackMouseDown}this.previousMouseX=x
this.previousMouseY=y
this.terminal.server.controlSequence(CSI+"M"+String.fromCharCode(eventCode+32)+String.fromCharCode(x+33)+String.fromCharCode(y+33))
return event.preventDefault()}}
InputHandler.prototype.useApplicationKeypad=function(value){return this.applicationKeypad=value}
return InputHandler}()

var __indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
WebTerm.ScreenBuffer=function(){function ScreenBuffer(terminal){this.terminal=terminal
this.lineContents=[]
this.lineDivs=[]
this.lineDivOffset=0
this.scrollbackLimit=1e3
this.linesToUpdate=[]
this.lastScreenClearLineCount=1
this.scrollingRegion=[0,this.terminal.sizeY-1]}var ContentArray
ScreenBuffer.prototype.toLineIndex=function(y){return this.lineContents.length-Math.min(this.terminal.sizeY,this.lineContents.length)+y}
ScreenBuffer.prototype.getLineContent=function(index){var _ref
return null!=(_ref=this.lineContents[index])?_ref:new ContentArray}
ScreenBuffer.prototype.setLineContent=function(index,content){if(!(0===content.elements.length&&this.lineContents.length<=index&&index<this.terminal.sizeY)){for(;this.lineContents.length<index;)this.lineContents.push(new ContentArray)
this.lineContents[index]=content
return __indexOf.call(this.linesToUpdate,index)<0?this.linesToUpdate.push(index):void 0}}
ScreenBuffer.prototype.isFullScrollingRegion=function(){return 0===this.scrollingRegion[0]&&this.scrollingRegion[1]===this.terminal.sizeY-1}
ScreenBuffer.prototype.scroll=function(amount){var direction,newContent,startIndex,y,_i,_ref,_ref1,_results
if(amount>0&&this.isFullScrollingRegion()){this.addLineToUpdate(this.terminal.cursor.y)
return this.setLineContent(this.lineContents.length-1+amount,new ContentArray)}direction=amount>0?1:-1
startIndex=amount>0?0:1
_results=[]
for(y=_i=_ref=this.scrollingRegion[startIndex],_ref1=this.scrollingRegion[1-startIndex];direction>0?_ref1>=_i:_i>=_ref1;y=_i+=direction){newContent=y+amount>=this.scrollingRegion[0]&&y+amount<=this.scrollingRegion[1]?this.getLineContent(this.toLineIndex(y+amount)):new ContentArray
_results.push(this.setLineContent(this.toLineIndex(y),newContent))}return _results}
ScreenBuffer.prototype.clear=function(){var y,_i,_ref,_results
if(this.isFullScrollingRegion&&this.lastScreenClearLineCount!==this.lineContents.length){this.scroll(this.terminal.sizeY)
return this.lastScreenClearLineCount=this.lineContents.length}_results=[]
for(y=_i=0,_ref=this.terminal.sizeY;_ref>=0?_ref>_i:_i>_ref;y=_ref>=0?++_i:--_i)_results.push(this.setLineContent(this.toLineIndex(y),new ContentArray))
return _results}
ScreenBuffer.prototype.addLineToUpdate=function(index){var absoluteIndex
absoluteIndex=this.toLineIndex(index)
return __indexOf.call(this.linesToUpdate,absoluteIndex)<0?this.linesToUpdate.push(absoluteIndex):void 0}
ScreenBuffer.prototype.flush=function(){var content,div,i,index,linesToAdd,linesToDelete,maxLineIndex,newDivs,scrollOffset,scrolledToBottom,_base,_i,_j,_len,_ref
this.linesToUpdate.sort(function(a,b){return a-b})
maxLineIndex=this.linesToUpdate[this.linesToUpdate.length-1]
linesToAdd=maxLineIndex-this.lineDivOffset-this.lineDivs.length+1
if(linesToAdd>0){scrolledToBottom=this.terminal.isScrolledToBottom()||0!==this.terminal.container.queue().length
newDivs=[]
for(i=_i=0;linesToAdd>=0?linesToAdd>_i:_i>linesToAdd;i=linesToAdd>=0?++_i:--_i){div=document.createElement("div")
$(div).text(" ")
newDivs.push(div)
this.lineDivs.push(div)}this.terminal.outputbox.append(newDivs)
linesToDelete=this.lineDivs.length-this.scrollbackLimit
if(linesToDelete>0){scrollOffset=this.terminal.container.prop("scrollHeight")-this.terminal.container.scrollTop()
$(this.lineDivs.slice(0,linesToDelete)).remove()
this.lineDivs=this.lineDivs.slice(linesToDelete)
this.lineDivOffset+=linesToDelete
this.terminal.container.scrollTop(this.terminal.container.prop("scrollHeight")-scrollOffset)}scrolledToBottom&&this.terminal.scrollToBottom()}_ref=this.linesToUpdate
for(_j=0,_len=_ref.length;_len>_j;_j++){index=_ref[_j]
content=this.getLineContent(index)
index===this.toLineIndex(this.terminal.cursor.y)&&(content=this.terminal.cursor.addCursorElement(content))
div=$(this.lineDivs[index-this.lineDivOffset])
div.empty()
div.append(content.getNodes())
0===content.getNodes().length&&div.text(" ")}this.linesToUpdate=[]
return"function"==typeof(_base=this.terminal).flushedCallback?_base.flushedCallback():void 0}
ContentArray=function(){function ContentArray(){this.elements=[]
this.merge=!0}ContentArray.prototype.push=function(element){return this.merge&&this.elements.length>0&&this.elements[this.elements.length-1].style.equals(element.style)?this.elements[this.elements.length-1].text+=element.text:this.elements.push(element)}
ContentArray.prototype.pushAll=function(content){if(0!==content.elements.length){this.push(content.elements[0])
return this.elements=this.elements.concat(content.elements.slice(1))}}
ContentArray.prototype.length=function(){return this.elements.length}
ContentArray.prototype.get=function(index){return this.elements[index]}
ContentArray.prototype.getNodes=function(){var element,_i,_len,_ref,_results
_ref=this.elements
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){element=_ref[_i]
_results.push(element.getNode())}return _results}
ContentArray.prototype.substring=function(beginIndex,endIndex){var content,i,length,missing,offset,styledText,text,_i,_j,_len,_ref
content=new ContentArray
offset=0
length=0
_ref=this.elements
for(_i=0,_len=_ref.length;_len>_i;_i++){styledText=_ref[_i]
text=null!=endIndex?styledText.text.substring(beginIndex-offset,endIndex-offset):styledText.text.substring(beginIndex-offset)
if(text.length>0){content.push(new WebTerm.StyledText(text,styledText.style))
length+=text.length}offset+=styledText.text.length}missing=endIndex-beginIndex-length
if(missing>0){text=""
for(i=_j=0;missing>=0?missing>_j:_j>missing;i=missing>=0?++_j:--_j)text+=" "
content.push(new WebTerm.StyledText(text,WebTerm.StyledText.DEFAULT_STYLE))}return content}
return ContentArray}()
return ScreenBuffer}()

WebTerm.StyledText=function(){function StyledText(text,style){this.text=text
this.style=style
this.spanForced=!1
this.node=null}var COLOR_NAMES,Style
COLOR_NAMES=["Black","Red","Green","Yellow","Blue","Magenta","Cyan","White","BrightBlack","BrightRed","BrightGreen","BrightYellow","BrightBlue","BrightMagenta","BrightCyan","BrightWhite"]
StyledText.prototype.getNode=function(){if(null==this.node)if(!this.style.isDefault()||this.spanForced){this.node=$(document.createElement("span"))
this.node.text(this.text)
this.updateNode()}else this.node=document.createTextNode(this.text)
return this.node}
StyledText.prototype.updateNode=function(){return this.node.attr(this.style.getAttributes())}
Style=function(){function Style(){this.bold=!1
this.underlined=!1
this.outlined=!1
this.inverse=!1
this.textColor=null
this.backgroundColor=null}Style.prototype.isDefault=function(){return!this.bold&&!this.underlined&&!this.inverse&&null===this.textColor&&null===this.backgroundColor}
Style.prototype.equals=function(other){return this.bold===other.bold&&this.underlined===other.underlined&&this.inverse===other.inverse&&this.textColor===other.textColor&&this.backgroundColor===other.backgroundColor}
Style.prototype.getAttributes=function(){var classes,styles
classes=[]
styles=[]
this.bold&&classes.push("bold")
this.underlined&&classes.push("underlined")
this.outlined&&classes.push("outlined")
this.inverse&&classes.push("inverse")
null!=this.textColor&&(this.textColor<16?classes.push("text"+COLOR_NAMES[this.textColor]):this.textColor<232?styles.push("color: "+this.getColor(this.textColor-16)):this.textColor<256&&styles.push("color: "+this.getGrey(this.textColor-232)))
null!=this.backgroundColor&&(this.backgroundColor<16?classes.push("background"+COLOR_NAMES[this.backgroundColor]):this.backgroundColor<232?styles.push("background-color: "+this.getColor(this.backgroundColor-16)):this.backgroundColor<256&&styles.push("background-color: "+this.getGrey(this.backgroundColor-232)))
return{"class":classes.join(" "),style:styles.join("; ")}}
Style.prototype.getColor=function(index){var b,bIndex,g,gIndex,r,rIndex
rIndex=Math.floor(index/6/6)%6
gIndex=Math.floor(index/6)%6
bIndex=index%6
r=0===rIndex?0:40*rIndex+55
g=0===gIndex?0:40*gIndex+55
b=0===bIndex?0:40*bIndex+55
return"rgb("+r+", "+g+", "+b+")"}
Style.prototype.getGrey=function(index){var l
l=10*index+8
return"rgb("+l+", "+l+", "+l+")"}
return Style}()
StyledText.DEFAULT_STYLE=new Style
return StyledText}()

WebTerm.Terminal=function(){function Terminal(container){var _this=this
this.container=container
"undefined"!=typeof localStorage&&null!==localStorage&&null==localStorage["WebTerm.logRawOutput"]&&(localStorage["WebTerm.logRawOutput"]="false")
"undefined"!=typeof localStorage&&null!==localStorage&&null==localStorage["WebTerm.slowDrawing"]&&(localStorage["WebTerm.slowDrawing"]="false")
this.server=null
this.sessionEndedCallback=null
this.setTitleCallback=null
this.keyInput=new KDCustomHTMLView({tagName:"input",cssClass:"offscreen"})
this.keyInput.appendToDomBody()
this.pixelWidth=0
this.pixelHeight=0
this.sizeX=80
this.sizeY=24
this.currentStyle=WebTerm.StyledText.DEFAULT_STYLE
this.currentWhitespaceStyle=null
this.currentCharacterSets=["B","A","A","A"]
this.currentCharacterSetIndex=0
this.inputHandler=new WebTerm.InputHandler(this)
this.screenBuffer=new WebTerm.ScreenBuffer(this)
this.cursor=new WebTerm.Cursor(this)
this.controlCodeReader=WebTerm.createAnsiControlCodeReader(this)
this.measurebox=$(document.createElement("div"))
this.updateSizeTimer=null
this.measurebox.css("position","absolute")
this.measurebox.css("visibility","hidden")
this.container.append(this.measurebox)
this.updateSize()
this.outputbox=$(document.createElement("div"))
this.outputbox.css("cursor","text")
this.container.append(this.outputbox)
this.container.on("mousedown mousemove mouseup mousewheel contextmenu",function(event){return _this.inputHandler.mouseEvent(event)})
this.clientInterface={output:function(data){var atEnd
"true"===("undefined"!=typeof localStorage&&null!==localStorage?localStorage["WebTerm.logRawOutput"]:void 0)&&log(_this.inspectString(data))
_this.controlCodeReader.addData(data)
if("true"===("undefined"!=typeof localStorage&&null!==localStorage?localStorage["WebTerm.slowDrawing"]:void 0))return null!=_this.controlCodeInterval?_this.controlCodeInterval:_this.controlCodeInterval=window.setInterval(function(){var atEnd
atEnd=_this.controlCodeReader.process()
if("true"!==("undefined"!=typeof localStorage&&null!==localStorage?localStorage["WebTerm.slowDrawing"]:void 0))for(;!atEnd;)atEnd=_this.controlCodeReader.process()
_this.screenBuffer.flush()
if(atEnd){window.clearInterval(_this.controlCodeInterval)
return _this.controlCodeInterval=null}},20)
atEnd=!1
for(;!atEnd;)atEnd=_this.controlCodeReader.process()
return _this.screenBuffer.flush()},sessionEnded:function(){return _this.sessionEndedCallback()}}}var LINE_DRAWING_CHARSET,SPECIAL_CHARS
LINE_DRAWING_CHARSET=[8593,8595,8594,8592,9608,9626,9731,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,32,9670,9618,9225,9228,9229,9226,176,177,9252,9227,9496,9488,9484,9492,9532,9146,9147,9472,9148,9149,9500,9508,9524,9516,9474,8804,8805,960,8800,163,183]
SPECIAL_CHARS={"\b":"\\b","	":"\\t","\n":"\\n","\f":"\\f","\r":"\\r","\\":"\\\\","":"\\e"}
Terminal.prototype.destroy=function(){var _ref
null!=(_ref=this.keyInput)&&_ref.destroy()
return Terminal.__super__.destroy.call(this)}
Terminal.prototype.keyDown=function(event){return this.inputHandler.keyDown(event)}
Terminal.prototype.keyPress=function(event){return this.inputHandler.keyPress(event)}
Terminal.prototype.keyUp=function(event){return this.inputHandler.keyUp(event)}
Terminal.prototype.setKeyFocus=function(){return this.keyInput.getElement().focus()}
Terminal.prototype.setFocused=function(value){var _this=this
this.cursor.setFocused(value)
return KD.utils.defer(function(){return _this.setKeyFocus()})}
Terminal.prototype.setSize=function(x,y){var cursorLineIndex
if(x!==this.sizeX||y!==this.sizeY){cursorLineIndex=this.screenBuffer.toLineIndex(this.cursor.y)
this.sizeX=x
this.sizeY=y
this.screenBuffer.scrollingRegion=[0,y-1]
this.cursor.moveTo(this.cursor.x,cursorLineIndex-this.screenBuffer.toLineIndex(0))
return this.server?this.server.setSize(x,y):void 0}}
Terminal.prototype.updateSize=function(force){var div,elements,height,n,newHeight,newWidth,text,width,x,y,_i,_j,_k
null==force&&(force=!1)
if(force||this.pixelWidth!==this.container.prop("clientWidth")||this.pixelHeight!==this.container.prop("clientHeight")){this.container.prop("clientHeight")<this.pixelHeight&&this.container.scrollTop(this.container.scrollTop()+this.pixelHeight-this.container.prop("clientHeight")+1)
this.pixelWidth=this.container.prop("clientWidth")
this.pixelHeight=this.container.prop("clientHeight")
width=1
height=1
for(n=_i=0;10>=_i;n=++_i){text=""
for(x=_j=0;width>=0?width>_j:_j>width;x=width>=0?++_j:--_j)text+=" "
elements=[]
for(y=_k=0;height>=0?height>_k:_k>height;y=height>=0?++_k:--_k){div=$(document.createElement("div"))
div.text(text)
elements.push(div)}this.measurebox.empty()
this.measurebox.append(elements)
newWidth=Math.max(width,Math.floor(this.pixelWidth/this.measurebox.width()*width))
newHeight=Math.max(height,Math.floor(this.pixelHeight/this.measurebox.height()*height))
if(newWidth===width&&newHeight===height)break
if(newWidth>1e3||newHeight>1e3)break
width=newWidth
height=newHeight}this.measurebox.empty()
return this.setSize(width,height)}}
Terminal.prototype.windowDidResize=function(){var _this=this
window.clearTimeout(this.updateSizeTimer)
return this.updateSizeTimer=window.setTimeout(function(){return _this.updateSize()},500)}
Terminal.prototype.lineFeed=function(){return this.cursor.y===this.screenBuffer.scrollingRegion[1]?this.screenBuffer.scroll(1):this.cursor.move(0,1)}
Terminal.prototype.reverseLineFeed=function(){return this.cursor.y===this.screenBuffer.scrollingRegion[0]?this.screenBuffer.scroll(-1):this.cursor.move(0,-1)}
Terminal.prototype.writeText=function(text,options){var c,charStyle,i,insert,lineIndex,newContent,nonBoldStyle,oldContent,style,u,x,y,_i,_ref,_ref1,_ref2,_ref3,_ref4,_ref5
if(0!==text.length){x=null!=(_ref=null!=options?options.x:void 0)?_ref:this.cursor.x
y=null!=(_ref1=null!=options?options.y:void 0)?_ref1:this.cursor.y
style=null!=(_ref2=null!=options?options.style:void 0)?_ref2:this.currentStyle
insert=null!=(_ref3=null!=options?options.insert:void 0)?_ref3:!1
lineIndex=this.screenBuffer.toLineIndex(y)
oldContent=this.screenBuffer.getLineContent(lineIndex)
newContent=oldContent.substring(0,x)
text=text.replace(/[ ]/g," ")
switch(this.currentCharacterSets[this.currentCharacterSetIndex]){case"0":nonBoldStyle=jQuery.extend(!0,{},style)
nonBoldStyle.bold=!1
for(i=_i=0,_ref4=text.length;_ref4>=0?_ref4>=_i:_i>=_ref4;i=_ref4>=0?++_i:--_i){c=text.charCodeAt(i)
u=null!=(_ref5=LINE_DRAWING_CHARSET[c-65])?_ref5:c
charStyle=u>=8960?nonBoldStyle:style
newContent.push(new WebTerm.StyledText(String.fromCharCode(u),charStyle))}break
case"A":text=text.replace(/#/g,"£")
newContent.push(new WebTerm.StyledText(text,style))
break
default:newContent.push(new WebTerm.StyledText(text,style))}newContent.pushAll(oldContent.substring(insert?x:x+text.length))
return this.screenBuffer.setLineContent(lineIndex,newContent)}}
Terminal.prototype.writeEmptyText=function(length,options){var i,text,_i
if(null==this.currentWhitespaceStyle){this.currentWhitespaceStyle=jQuery.extend(!0,{},this.currentStyle)
this.currentWhitespaceStyle.inverse=!1}this.currentWhitespaceStyle
null==options&&(options={})
options.style=this.currentWhitespaceStyle
text=""
for(i=_i=0;length>=0?length>_i:_i>length;i=length>=0?++_i:--_i)text+=" "
return this.writeText(text,options)}
Terminal.prototype.deleteCharacters=function(count,options){var i,lineIndex,newContent,oldContent,text,x,y,_i,_ref,_ref1
x=null!=(_ref=null!=options?options.x:void 0)?_ref:this.cursor.x
y=null!=(_ref1=null!=options?options.y:void 0)?_ref1:this.cursor.y
lineIndex=this.screenBuffer.toLineIndex(y)
oldContent=this.screenBuffer.getLineContent(lineIndex)
newContent=oldContent.substring(0,x)
newContent.pushAll(oldContent.substring(x+count))
text=""
for(i=_i=0;count>=0?count>_i:_i>count;i=count>=0?++_i:--_i)text+=" "
newContent.push(new WebTerm.StyledText(text,oldContent.get(oldContent.length()-1).style))
return this.screenBuffer.setLineContent(lineIndex,newContent)}
Terminal.prototype.setStyle=function(name,value){this.currentStyle=jQuery.extend(!0,{},this.currentStyle)
this.currentStyle[name]=value
return this.currentWhitespaceStyle=null}
Terminal.prototype.resetStyle=function(){this.currentStyle=WebTerm.StyledText.DEFAULT_STYLE
return this.currentWhitespaceStyle=null}
Terminal.prototype.setCharacterSet=function(index,charset){return this.currentCharacterSets[index]=charset}
Terminal.prototype.setCharacterSetIndex=function(index){return this.currentCharacterSetIndex=index}
Terminal.prototype.changeScreenBuffer=function(){}
Terminal.prototype.isScrolledToBottom=function(){return this.container.scrollTop()+this.container.prop("clientHeight")>=this.container.prop("scrollHeight")-3}
Terminal.prototype.scrollToBottom=function(animate){null==animate&&(animate=!1)
if(!this.isScrolledToBottom()){this.container.stop()
return animate?this.container.animate({scrollTop:this.container.prop("scrollHeight")-this.container.prop("clientHeight")},{duration:200}):this.container.scrollTop(this.container.prop("scrollHeight")-this.container.prop("clientHeight"))}}
Terminal.prototype.setScrollbackLimit=function(limit){this.screenBuffer.scrollbackLimit=limit
return this.screenBuffer.flush()}
Terminal.prototype.inspectString=function(string){var escaped
escaped=string.replace(/[\x00-\x1f\\]/g,function(character){var hex,special
special=SPECIAL_CHARS[character]
if(special)return special
hex=character.charCodeAt(0).toString(16).toUpperCase()
1===hex.length&&(hex="0"+hex)
return"\\x"+hex})
return'"'+escaped.replace('"','\\"')+'"'}
return Terminal}()

//@ sourceMappingURL=/js/__app.terminal.0.0.1.js.map