var Pane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Pane=function(_super){function Pane(options,data){var hasButtons,_ref
null==options&&(options={})
options.cssClass=KD.utils.curry("ws-pane",options.cssClass)
Pane.__super__.constructor.call(this,options,data)
hasButtons=null!=(_ref=options.buttons)?_ref.length:void 0
this.createHeader()
hasButtons&&this.createButtons()
this.on("PaneResized",this.bound("handlePaneResized"))}__extends(Pane,_super)
Pane.prototype.createHeader=function(){var hasButtons,options,title,_ref
options=this.getOptions()
hasButtons=null!=(_ref=options.buttons)?_ref.length:void 0
title=options.title||""
return this.header=title||hasButtons?new KDHeaderView({cssClass:"ws-header inner-header",partial:title}):new KDCustomHTMLView({cssClass:"ws-header"})}
Pane.prototype.createButtons=function(){var buttonOptions,_i,_len,_ref,_results
_ref=this.getOptions().buttons
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){buttonOptions=_ref[_i]
_results.push(this.header.addSubView(new KDButtonView(buttonOptions)))}return _results}
Pane.prototype.handlePaneResized=function(){}
return Pane}(JView)

var EditorPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EditorPane=function(_super){function EditorPane(options,data){null==options&&(options={})
options.cssClass="editor-pane"
EditorPane.__super__.constructor.call(this,options,data)
this.files=this.getOptions().files
Array.isArray(this.files)?this.createEditorTabs():this.createSingleEditor()}__extends(EditorPane,_super)
EditorPane.prototype.createEditorInstance=function(file){return new Ace({delegate:this,enableShortcuts:!1},file)}
EditorPane.prototype.createSingleEditor=function(){var content,file,path,_this=this
path=this.files||"localfile:/Untitled.txt"
file=FSHelper.createFileFromPath(path)
this.ace=this.createEditorInstance(file)
content=this.getOptions().content
return this.ace.on("ace.ready",function(){return content?_this.ace.editor.setValue(content):void 0})}
EditorPane.prototype.createEditorTabs=function(){var file,fileOptions,pane,_i,_len,_ref,_results
this.tabHandleContainer=new ApplicationTabHandleHolder({delegate:this,addPlusHandle:!1})
this.tabView=new ApplicationTabView({delegate:this,tabHandleContainer:this.tabHandleContainer})
_ref=this.files
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){fileOptions=_ref[_i]
file=FSHelper.createFileFromPath(fileOptions.path)
pane=new KDTabPaneView({name:file.name||"Untitled.txt"})
pane.addSubView(this.createEditorInstance(file))
_results.push(this.tabView.addPane(pane))}return _results}
EditorPane.prototype.getValue=function(){return this.ace.editor.getSession().getValue()}
EditorPane.prototype.pistachio=function(){var multiple,single,template
single="{{> this.ace}}"
multiple="{{> this.tabHandleContainer}} {{> this.tabView}}"
template=Array.isArray(this.files)?multiple:single
return"{{> this.header}}\n"+template}
return EditorPane}(Pane)

var PreviewPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PreviewPane=function(_super){function PreviewPane(options,data){var url,viewerOptions
null==options&&(options={})
options.cssClass="preview-pane"
PreviewPane.__super__.constructor.call(this,options,data)
this.container=new KDView({cssClass:"workspace-viewer"})
url=this.getOptions().url
viewerOptions={delegate:this,params:{}}
url&&(viewerOptions.params.path=url)
this.container.addSubView(this.previewer=new PreviewerView(viewerOptions))}__extends(PreviewPane,_super)
PreviewPane.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.container}}"}
return PreviewPane}(Pane)

var TerminalPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TerminalPane=function(_super){function TerminalPane(options,data){var _this=this
null==options&&(options={})
options.cssClass="terminal-pane terminal"
null==options.delay&&(options.delay="localhost"===location.hostname?100:1e4)
TerminalPane.__super__.constructor.call(this,options,data)
this.container=new KDView({cssClass:"tw-terminal-splash",partial:"<p>Preparing your VM...</p>"})
KD.utils.wait(options.delay,function(){_this.createWebTermView()
_this.webterm.on("WebTermConnected",function(remote){_this.remote=remote
_this.emit("WebtermCreated")
return _this.onWebTermConnected()})
_this.container.destroy()
return _this.addSubView(_this.webterm)})}__extends(TerminalPane,_super)
TerminalPane.prototype.createWebTermView=function(){return this.webterm=new WebTermView({delegate:this,cssClass:"webterm",advancedSettings:!1})}
TerminalPane.prototype.onWebTermConnected=function(){var command
command=this.getOptions().command
return command?this.runCommand(command):void 0}
TerminalPane.prototype.runCommand=function(command,callback){var _this=this
if(command){if(this.remote){if(callback){this.webterm.once("WebTermEvent",callback)
command+=";echo $?|kdevent"}return this.remote.input(""+command+"\n")}return this.remote||this.triedAgain?void 0:this.utils.wait(2e3,function(){_this.runCommand(command)
return _this.triedAgain=!0})}}
TerminalPane.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.container}}"}
return TerminalPane}(Pane)

var VideoPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VideoPane=function(_super){function VideoPane(options,data){null==options&&(options={})
options.cssClass="vide-pane"
VideoPane.__super__.constructor.call(this,options,data)
this.container=new KDCustomHTMLView({tagName:"iframe",attributes:{type:"text/html",width:options.width||"100%",height:options.height||"100%",frameborder:0,src:"http://www.youtube.com/embed/"+options.videoId+"?autoplay=0"}})}__extends(VideoPane,_super)
VideoPane.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.container}}"}
return VideoPane}(Pane)

var Panel,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Panel=function(_super){function Panel(options,data){var buttonsLength,title,_ref
null==options&&(options={})
options.cssClass="panel"
Panel.__super__.constructor.call(this,options,data)
this.headerButtons={}
this.panesContainer=[]
this.panes=[]
this.panesByName={}
this.header=new KDCustomHTMLView
title=options.title
buttonsLength=null!=(_ref=options.buttons)?_ref.length:void 0;(title||buttonsLength)&&this.createHeader(title)
buttonsLength&&this.createHeaderButtons()
options.hint&&this.createHeaderHint()
this.createLayout()}__extends(Panel,_super)
Panel.prototype.createHeader=function(title){var headerStyling
null==title&&(title="")
this.header=new KDView({cssClass:"inner-header"})
this.headerTitle=new KDCustomHTMLView({tagName:"span",cssClass:"title",partial:' <span class="text">'+title+"</span> "})
this.headerIcon=new KDCustomHTMLView({tagName:"span",cssClass:"icon"})
this.headerTitle.addSubView(this.headerIcon,null,!0)
this.header.addSubView(this.headerTitle)
this.header.addSubView(this.headerButtonsContainer=new KDCustomHTMLView({cssClass:"tw-header-buttons"}))
headerStyling=this.getOptions().headerStyling
return headerStyling?this.applyHeaderStyling(headerStyling):void 0}
Panel.prototype.createHeaderButtons=function(){var _this=this
return this.getOptions().buttons.forEach(function(buttonOptions){var Klass,buttonView,_ref,_ref1
if(buttonOptions.itemClass){Klass=buttonOptions.itemClass
buttonOptions.callback=null!=(_ref=buttonOptions.callback)?_ref.bind(_this,_this,_this.getDelegate()):void 0
buttonView=new Klass(buttonOptions)}else{buttonOptions.callback=null!=(_ref1=buttonOptions.callback)?_ref1.bind(_this,_this,_this.getDelegate()):void 0
buttonView=new KDButtonView(buttonOptions)}_this.headerButtons[buttonOptions.title]=buttonView
return _this.headerButtonsContainer.addSubView(buttonView)})}
Panel.prototype.createHeaderHint=function(){var _this=this
return this.header.addSubView(this.headerHint=new KDCustomHTMLView({cssClass:"help",tooltip:{title:"Need help?"},click:function(){return _this.getDelegate().showHintModal()}}))}
Panel.prototype.createLayout=function(){var layout,newPane,pane,_ref
_ref=this.getOptions(),pane=_ref.pane,layout=_ref.layout
this.container=new KDView({cssClass:"panel-container"})
if(pane){newPane=this.createPane(pane)
this.container.addSubView(newPane)
return this.getDelegate().emit("AllPanesAddedToPanel",this,[newPane])}if(layout){this.layoutContainer=new WorkspaceLayout({delegate:this,layoutOptions:layout})
return this.container.addSubView(this.layoutContainer)}return warn("no layout config or pane passed to create a panel")}
Panel.prototype.createPane=function(paneOptions){var PaneClass,pane
PaneClass=this.getPaneClass(paneOptions)
pane=new PaneClass(paneOptions)
paneOptions.name&&(this.panesByName[paneOptions.name]=pane)
this.panes.push(pane)
this.emit("NewPaneCreated",pane)
return pane}
Panel.prototype.getPaneClass=function(paneOptions){var PaneClass,paneType
paneType=paneOptions.type
paneOptions.delegate=this
PaneClass="custom"===paneType?paneOptions.paneClass:this.findPaneClass(paneType)
return PaneClass?PaneClass:new Error('PaneClass is not defined for "'+paneOptions.type+'" pane type')}
Panel.prototype.findPaneClass=function(paneType){var paneTypesToPaneClass
paneTypesToPaneClass={terminal:this.TerminalPaneClass,editor:this.EditorPaneClass,video:this.VideoPaneClass,preview:this.PreviewPaneClass,finder:this.FinderPaneClass,tabbedEditor:this.TabbedEditorPaneClass,drawing:this.DrawingPaneClass}
return paneTypesToPaneClass[paneType]}
Panel.prototype.getPaneByName=function(name){return this.panesByName[name]||null}
Panel.prototype.showHintModal=function(){var modal,options
options=this.getOptions()
return modal=new KDModalView({cssClass:"workspace-modal",overlay:!0,title:options.title,content:options.hint,buttons:{Close:{title:"Close",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})}
Panel.prototype.applyHeaderStyling=function(options){var bgColor,bgGradient,bgImage,borderColor,textColor,textShadowColor
if(options.custom)return this.header.getElement().setAttribute("style",options.custom)
bgColor=options.bgColor,bgGradient=options.bgGradient,bgImage=options.bgImage,textColor=options.textColor,textShadowColor=options.textShadowColor,borderColor=options.borderColor
textColor&&this.header.setCss("color",textColor)
borderColor&&this.header.setCss("borderBottomColor",""+borderColor)
bgColor&&this.header.setCss("background",""+bgColor)
bgImage&&this.headerIcon.setCss("backgroundImage","url("+bgImage+")")
textShadowColor&&this.header.setCss("textShadowColor","0 1px 0 "+textShadowColor)
return bgGradient?KD.utils.applyGradient(this.header,bgGradient.first,bgGradient.last):void 0}
Panel.prototype.viewAppended=function(){Panel.__super__.viewAppended.apply(this,arguments)
this.getDelegate().emit("NewPanelAdded",this)
return this.getOptions().floatingPanes?this.addSubView(this.paneLauncher=new WorkspaceFloatingPaneLauncher({delegate:this})):void 0}
Panel.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.container}}"}
Panel.prototype.EditorPaneClass=EditorPane
Panel.prototype.TabbedEditorPaneClass=EditorPane
Panel.prototype.TerminalPaneClass=TerminalPane
Panel.prototype.VideoPaneClass=VideoPane
Panel.prototype.PreviewPaneClass=PreviewPane
Panel.prototype.DrawingPaneClass=KDView
return Panel}(JView)

var WorkspaceLayout,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WorkspaceLayout=function(_super){function WorkspaceLayout(){_ref=WorkspaceLayout.__super__.constructor.apply(this,arguments)
return _ref}__extends(WorkspaceLayout,_super)
WorkspaceLayout.prototype.init=function(){var direction,sizes,splitName,views,_ref1
this.splitViews={}
_ref1=this.getOptions().layoutOptions,direction=_ref1.direction,sizes=_ref1.sizes,views=_ref1.views,splitName=_ref1.splitName
this.baseSplitName=splitName
return this.addSubView(this.createSplitView(direction,sizes,views,splitName))}
WorkspaceLayout.prototype.createSplitView=function(type,sizes,viewsConfig,splitName){var splitView,views,_this=this
views=[]
viewsConfig.forEach(function(config){var options,splitView,wrapper
if("split"===config.type){options=config.options
splitName=options.splitName
splitView=_this.createSplitView(options.direction,options.sizes,config.views)
splitName&&(_this.splitViews[splitName]=splitView)
return views.push(splitView)}wrapper=new KDView
wrapper.on("viewAppended",function(){return wrapper.addSubView(_this.getDelegate().createPane(config))})
return views.push(wrapper)})
splitView=new SplitViewWithOlderSiblings({type:type,sizes:sizes,views:views})
this.baseSplitName&&(this.splitViews[this.baseSplitName]=splitView)
splitView.on("ResizeDidStop",function(){return _this.emitResizedEventToPanes()})
splitView.on("viewAppended",function(){var _ref1
return null!=(_ref1=splitView.resizers.first)?_ref1.on("DragInAction",function(){return _this.emitResizedEventToPanes()}):void 0})
return splitView}
WorkspaceLayout.prototype.getSplitByName=function(name){return this.splitViews[name]||null}
WorkspaceLayout.prototype.emitResizedEventToPanes=function(){var pane,_i,_len,_ref1,_results
_ref1=this.getDelegate().panes
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){pane=_ref1[_i]
_results.push(pane.emit("PaneResized"))}return _results}
return WorkspaceLayout}(KDSplitComboView)

var Workspace,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Workspace=function(_super){function Workspace(options,data){var key,raw,value,_this=this
null==options&&(options={})
raw={}
for(key in options)if(__hasProp.call(options,key)){value=options[key]
raw[key]=value}Workspace.__super__.constructor.call(this,options,data)
this.rawOptions=raw
this.listenWindowResize()
this.container=new KDView({cssClass:"workspace"})
this.panels=[]
this.lastCreatedPanelIndex=0
this.currentPanelIndex=0
this.on("PanelCreated",function(){_this.doInternalResize()
return KD.getSingleton("windowController").notifyWindowResizeListeners()})
this.init()}__extends(Workspace,_super)
Workspace.prototype.init=function(){return this.createPanel()}
Workspace.prototype.createPanel=function(callback){var newPanel,panelClass,panelOptions
null==callback&&(callback=noop)
panelOptions=this.getOptions().panels[this.lastCreatedPanelIndex]
panelOptions.delegate=this
panelClass=this.getOptions().panelClass||Panel
newPanel=new panelClass(panelOptions)
this.container.addSubView(newPanel)
this.panels.push(newPanel)
this.activePanel=newPanel
callback()
return this.emit("PanelCreated",newPanel)}
Workspace.prototype.next=function(){var _this=this
if(this.lastCreatedPanelIndex===this.currentPanelIndex){this.lastCreatedPanelIndex++
return this.createPanel(function(){_this.getPanelByIndex(_this.lastCreatedPanelIndex-1).setClass("hidden")
return _this.currentPanelIndex=_this.lastCreatedPanelIndex})}this.getPanelByIndex(this.currentPanelIndex).setClass("hidden")
return this.getPanelByIndex(++this.currentPanelIndex).unsetClass("hidden")}
Workspace.prototype.prev=function(){this.getPanelByIndex(this.currentPanelIndex).setClass("hidden")
return this.getPanelByIndex(--this.currentPanelIndex).unsetClass("hidden")}
Workspace.prototype.getActivePanel=function(){return this.panels[this.lastCreatedPanelIndex]}
Workspace.prototype.getPanelByIndex=function(index){return this.panels[index]||null}
Workspace.prototype.showHintModal=function(){return this.getActivePanel().showHintModal()}
Workspace.prototype._windowDidResize=function(){var pane,_i,_len,_ref,_results
if(this.activePanel){this.doInternalResize()
_ref=this.activePanel.panes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
_results.push(pane.emit("PaneResized"))}return _results}}
Workspace.prototype.doInternalResize=function(){var container,header,panel
panel=this.getActivePanel()
header=panel.header,container=panel.container
return header?container.setHeight(panel.getHeight()-header.getHeight()):void 0}
Workspace.prototype.viewAppended=function(){Workspace.__super__.viewAppended.apply(this,arguments)
return this._windowDidResize()}
Workspace.prototype.pistachio=function(){return"{{> this.container}}"}
return Workspace}(JView)

//@ sourceMappingURL=/js/__app.workspace.0.0.1.js.map