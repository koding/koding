var FinderController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
FinderController=function(_super){function FinderController(options,data){options.appInfo={name:"Finder"}
FinderController.__super__.constructor.call(this,options,data)}__extends(FinderController,_super)
KD.registerAppClass(FinderController,{name:"Finder",background:!0})
FinderController.prototype.createFileFromPath=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return FSHelper.createFileFromPath.apply(FSHelper,rest)}
FinderController.prototype.create=function(options){null==options&&(options={})
null==options.useStorage&&(options.useStorage=!0)
null==options.addOrphansToRoot&&(options.addOrphansToRoot=!1)
this.controller=new NFinderController(options)
this.uploader=this.createDNDUploader(this.controller)
return this.controller}
FinderController.prototype.createDNDUploader=function(controller){var dndUploadHolder,dnduploader,onDrag,treeController
treeController=controller.treeController
dndUploadHolder=new KDView({domId:"finder-dnduploader",cssClass:"hidden"})
dnduploader=new DNDUploader({hoverDetect:!1})
dndUploadHolder.addSubView(dnduploader)
onDrag=function(){if(!treeController.internalDragging){dndUploadHolder.show()
return dnduploader.unsetClass("hover")}}
dnduploader.on("dragleave",function(){return dndUploadHolder.hide()}).on("drop",function(){return dndUploadHolder.hide()}).on("uploadProgress",function(_arg){var file,filePath,percent,_ref
file=_arg.file,percent=_arg.percent
filePath="["+file.vmName+"]"+file.path
return null!=(_ref=treeController.nodes[filePath])?_ref.showProgressView(percent):void 0}).on("uploadComplete",function(_arg){var parentPath
parentPath=_arg.parentPath
return controller.expandFolders(FSHelper.getPathHierarchy(parentPath))}).on("cancel",function(){dnduploader.setPath()
return dndUploadHolder.hide()})
treeController.on("dragEnter",onDrag)
treeController.on("dragOver",onDrag)
controller.getView().addSubView(dndUploadHolder)
return dndUploadHolder}
return FinderController}(KDController)


var DNDUploader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DNDUploader=function(_super){function DNDUploader(options,data){var _this=this
null==options&&(options={})
options.cssClass="file-droparea"
options.bind="dragenter dragover dragleave dragend drop"
null==options.hoverDetect&&(options.hoverDetect=!0)
null==options.uploadToVM&&(options.uploadToVM=!0)
options.defaultPath||(options.defaultPath="/home/"+KD.nick()+"/Uploads")
DNDUploader.__super__.constructor.call(this,options,data)
this.reset()
options.path&&this.setPath(options.path)
if(options.hoverDetect){this.on("dragenter",function(){return _this.setClass("hover")})
this.on("dragover",function(){return _this.setClass("hover")})
this.on("dragleave",function(){return _this.unsetClass("hover")})
this.on("drop",function(){return _this.unsetClass("hover")})}this.on("uploadFile",function(fsFile,percent){return _this.emit("uploadProgress",{file:fsFile,percent:percent})})
this.on("uploadStart",function(fsFile){var filePath,parentPath
filePath="["+fsFile.vmName+"]"+fsFile.path
parentPath="["+fsFile.vmName+"]"+fsFile.parentPath
return fsFile.save("",function(){return _this.emit("uploadComplete",{filePath:filePath,parentPath:parentPath})})})}__extends(DNDUploader,_super)
DNDUploader.prototype.viewAppended=function(){return DNDUploader.__super__.viewAppended.apply(this,arguments)}
DNDUploader.prototype.reset=function(){var defaultPath,title,uploadToVM,_ref
_ref=this.getOptions(),uploadToVM=_ref.uploadToVM,defaultPath=_ref.defaultPath,title=_ref.title
this.setPath()
this.updatePartial('<div class="file-drop">\n  '+(title||"Drop files here!")+"\n  <small>"+(uploadToVM?defaultPath:"")+"</small>\n</div>")
return this._uploaded={}}
DNDUploader.prototype.drop=function(event){var entry,files,item,items,_i,_len,_ref,_ref1,_results,_this=this
DNDUploader.__super__.drop.apply(this,arguments)
_ref=event.originalEvent.dataTransfer,files=_ref.files,items=_ref.items
files.length>=20&&KD.notify_("Too many files to transfer!<br>\nArchive your files and try again.","error","Max 20 files allowed to upload at once.\nYou can archive your files and try again.")
if(null!=items?"function"==typeof items.item?null!=(_ref1=items.item(0))?_ref1.webkitGetAsEntry:void 0:void 0:void 0){_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
entry=item.webkitGetAsEntry()
entry.isDirectory?_results.push(this.walkDirectory(entry.filesystem.root,function(file){return _this.uploadFiles([file],event)},function(){return _this.uploadFiles(files,event)})):entry.isFile?_results.push(entry.file(function(file){return _this.uploadFiles([file],event)})):_results.push(void 0)}return _results}return this.uploadFiles(files,event)}
DNDUploader.prototype.uploadFiles=function(files,event){var basename,file,fsFile,index,internalData,item,lastFile,lastItem,multipleItems,reader,sizeInMb,_i,_j,_len,_len1,_results,_results1,_this=this
this._uploaded||(this._uploaded={})
if(null!=files?files.length:void 0){lastFile=files.last
_results=[]
for(index=_i=0,_len=files.length;_len>_i;index=++_i){file=files[index]
sizeInMb=file.size/1024/1024
if(sizeInMb>100&&this.getOptions().uploadToVM)KD.notify_("Too big file to upload.","error","Max 100MB allowed per file.")
else{reader=new FileReader
reader.onloadend=function(file){return function(readEvent){var fileName,fsFile
fileName=file.fileName||file.name
if(file.relativePath){if(_this._uploaded[file.relativePath+fileName])return
_this._uploaded[file.relativePath+fileName]=!0}_this.getOptions().uploadToVM&&(fsFile=_this.upload(fileName,readEvent.target.result,file.relativePath))
_this.emit("dropFile",{origin:"external",filename:fileName,path:file.relativePath||!1,instance:fsFile,content:readEvent.target.result,isLast:file===lastFile},event,readEvent)
return file===lastFile?_this.reset():void 0}}(files[index])
_results.push(reader.readAsBinaryString(file))}}return _results}internalData=event.originalEvent.dataTransfer.getData("Text")
if(internalData){multipleItems=internalData.split(",")
lastItem=multipleItems.last
_results1=[]
for(_j=0,_len1=multipleItems.length;_len1>_j;_j++){item=multipleItems[_j]
basename=KD.getPathInfo(item).basename
fsFile=FSHelper.createFileFromPath(item)
this.emit("dropFile",{origin:"internal",filename:basename,instance:fsFile,content:null,isLast:item===lastItem},event,!1)
item===lastItem?_results1.push(this.reset()):_results1.push(void 0)}return _results1}}
DNDUploader.prototype.walkDirectory=function(dirEntry,callback,error){var dirReader,relative,_this=this
dirReader=dirEntry.createReader()
relative=FSHelper.convertToRelative(dirEntry.fullPath)
return dirReader.readEntries(function(entries){var entry,_i,_len,_results
_results=[]
for(_i=0,_len=entries.length;_len>_i;_i++){entry=entries[_i]
entry.isFile?_results.push(entry.file(function(file){file.relativePath=relative+file.name
return callback(file)})):_results.push(_this.walkDirectory(entry,callback,error))}return _results},error)}
DNDUploader.prototype.setPath=function(path){var title,uploadToVM,_ref
this.path=null!=path?path:this.getOptions().defaultPath
_ref=this.getOptions(),uploadToVM=_ref.uploadToVM,title=_ref.title
this.updatePartial('<div class="file-drop">\n  '+(title||"Drop files here!")+"\n  <small>"+(uploadToVM?FSHelper.getVMNameFromPath(this.path)||"":"")+"</small>\n  <small>"+(uploadToVM?FSHelper.plainPath(this.path):"")+"</small>\n</div>")
this.showCancel()
return uploadToVM&&this.finder?this.finder.expandFolders(FSHelper.getPathHierarchy(this.path)):void 0}
DNDUploader.prototype.showCancel=function(){var _this=this
return this.addSubView(new KDCustomHTMLView({tagName:"a",partial:"cancel",cssClass:"cancel",attributes:{href:"#"},click:function(){return _this.emit("cancel")}}))}
DNDUploader.prototype.saveFile=function(fsFile,data){var _this=this
this.emit("uploadStart",fsFile)
return fsFile.saveBinary(data,function(err,res,progress){progress||(progress=res)
return err?void 0:res.finished?_this.emit("uploadEnd",fsFile):res.abort?_this.emit("uploadAbort",fsFile):_this.emit("uploadFile",fsFile,progress.percent)})}
DNDUploader.prototype.upload=function(fileName,contents,relativePath){var folder,fsFileItem,fsFolderItem,modalStack,upload,_this=this
folder=relativePath&&relativePath!==fileName?""+this.path+"/"+relativePath.replace(/\/[^\/]*$/,""):this.path
modalStack=KDModalView.createStack({lastToFirst:!0})
fsFolderItem=FSHelper.createFileFromPath(folder,"folder")
fsFileItem=FSHelper.createFileFromPath(""+folder+"/"+fileName)
if(!FSHelper.isUnwanted(fsFolderItem.path)&&!FSHelper.isUnwanted(fsFileItem.path,!0)){upload=function(){return fsFileItem.exists(function(err,exists){var modal
return exists&&null==fsFileItem.getLocalFileInfo().lastUploadedChunk?modalStack.addModal(modal=new KDModalView({overlay:!1,title:"Overwrite File?",content:'<div class="modalformline">\nYou already have the file <code>'+fsFileItem.path+"</code>. Do you want\nto overwrite it?\n</div>",buttons:{Overwrite:{cssClass:"modal-clean-green",callback:function(){_this.saveFile(fsFileItem,contents)
return modal.destroy()}},cancel:{cssClass:"modal-cancel",callback:function(){return modal.destroy()}},"cancel all":{cssClass:"modal-cancel",callback:function(){return modalStack.destroy()}}}})):_this.saveFile(fsFileItem,contents)})}
fsFolderItem.exists(function(err,exists){return exists?upload():FSHelper.createRecursiveFolder(fsFolderItem,function(){return upload()})})
return fsFileItem}}
return DNDUploader}(KDView)

var OpenWithModalItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpenWithModalItem=function(_super){function OpenWithModalItem(options,data){var _this=this
null==options&&(options={})
options.cssClass="app"
OpenWithModalItem.__super__.constructor.call(this,options,data)
this.img=KD.utils.getAppIcon(this.getData())
this.getOptions().supported||this.setClass("not-supported")
this.on("click",function(){var delegate
delegate=_this.getDelegate()
delegate.selectedApp&&delegate.selectedApp.unsetClass("selected")
_this.setClass("selected")
return delegate.selectedApp=_this})}__extends(OpenWithModalItem,_super)
OpenWithModalItem.prototype.pistachio=function(){return"{{> this.img}}\n<div class='app-name'>"+this.getData()+"</div>"}
return OpenWithModalItem}(JView)

var OpenWithModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpenWithModal=function(_super){function OpenWithModal(options,data){var appManager,appName,apps,fileExtension,fileName,label,manifest,modal,nodeView,supportedApps,_i,_len,_ref
null==options&&(options={})
OpenWithModal.__super__.constructor.call(this,options,data)
_ref=this.getData(),nodeView=_ref.nodeView,apps=_ref.apps
appManager=KD.getSingleton("appManager")
fileName=FSHelper.getFileNameFromPath(nodeView.getData().path)
fileExtension=FSItem.getFileExtension(fileName)
modal=new KDModalView({title:"Choose application to open "+fileName,cssClass:"open-with-modal",overlay:!0,width:400,buttons:{Open:{title:"Open",style:"modal-clean-green",callback:function(){var appName
appName=modal.selectedApp.getData()
appManager.openFileWithApplication(appName,nodeView.getData())
return modal.destroy()}},Cancel:{title:"Cancel",style:"modal-cancel",callback:function(){return modal.destroy()}}}})
supportedApps=["Ace"]
for(_i=0,_len=supportedApps.length;_len>_i;_i++){appName=supportedApps[_i]
modal.addSubView(new OpenWithModalItem({supported:!0,delegate:modal},appName))}modal.addSubView(new KDView({cssClass:"separator"}))
for(appName in apps)if(__hasProp.call(apps,appName)){manifest=apps[appName];-1===supportedApps.indexOf(appName)&&modal.addSubView(new OpenWithModalItem({delegate:modal},manifest))}label=new KDLabelView({title:"Always open with..."})
this.alwaysOpenWith=new KDInputView({label:label,type:"checkbox"})
modal.buttonHolder.addSubView(this.alwaysOpenWith)
modal.buttonHolder.addSubView(label)}__extends(OpenWithModal,_super)
return OpenWithModal}(KDObject)

var VmDangerModalView,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmDangerModalView=function(_super){function VmDangerModalView(options,data){var _this=this
null==options&&(options={})
this.checkVmName=__bind(this.checkVmName,this)
options.action||(options.action="Danger Zone")
options.title||(options.title=options.action)
options.content||(options.content="<div class='modalformline'><p><strong>CAUTION! </strong>This will destroy the <strong>"+options.name+"</strong> VM including all its data. This action <strong>CANNOT</strong> be undone.</p><br><p>Please enter <strong>"+data+"</strong> into the field below to continue: </p></div>")
null==options.callback&&(options.callback=function(){return log(""+options.action+" performed")})
null==options.overlay&&(options.overlay=!0)
null==options.width&&(options.width=500)
null==options.height&&(options.height="auto")
null==options.tabs&&(options.tabs={forms:{dangerForm:{callback:function(){var callback
callback=function(){return _this.modalTabs.forms.dangerForm.buttons.confirmButton.hideLoader()}
return options.callback(callback)},buttons:{confirmButton:{title:options.action,style:"modal-clean-red",type:"submit",disabled:!0,loader:{color:"#ffffff",diameter:15},callback:function(){return this.showLoader()}},Cancel:{style:"modal-cancel",callback:this.bound("destroy")}},fields:{vmSlug:{itemClass:KDInputView,placeholder:"Enter '"+data+"' to confirm...",validate:{rules:{required:!0,slugCheck:function(input){return _this.checkVmName(input,!1)},finalCheck:function(input){return _this.checkVmName(input)}},messages:{required:"Please enter vm name"},events:{required:"blur",slugCheck:"keyup",finalCheck:"blur"}}}}}}})
VmDangerModalView.__super__.constructor.apply(this,arguments)}__extends(VmDangerModalView,_super)
VmDangerModalView.prototype.checkVmName=function(input,showError){null==showError&&(showError=!0)
if(input.getValue()===this.getData()){input.setValidationResult("slugCheck",null)
return this.modalTabs.forms.dangerForm.buttons.confirmButton.enable()}this.modalTabs.forms.dangerForm.buttons.confirmButton.disable()
return input.setValidationResult("slugCheck","Sorry, entered value does not match vm name!",showError)}
return VmDangerModalView}(KDModalViewWithForms)

var NFinderController,VMMountStateWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
NFinderController=function(_super){function NFinderController(options,data){var TreeControllerClass,nickname,treeOptions,_this=this
null==options&&(options={})
nickname=KD.whoami().profile.nickname
options.view=new KDView({cssClass:"nfinder file-container"})
treeOptions={}
treeOptions.treeItemClass=options.treeItemClass||(options.treeItemClass=NFinderItem)
treeOptions.nodeIdPath=options.nodeIdPath||(options.nodeIdPath="path")
treeOptions.nodeParentIdPath=options.nodeParentIdPath||(options.nodeParentIdPath="parentPath")
treeOptions.dragdrop=null!=options.dragdrop?options.dragdrop:options.dragdrop=!0
treeOptions.foldersOnly=null!=options.foldersOnly?options.foldersOnly:options.foldersOnly=!1
treeOptions.hideDotFiles=null!=options.hideDotFiles?options.hideDotFiles:options.hideDotFiles=!1
treeOptions.multipleSelection=null!=options.multipleSelection?options.multipleSelection:options.multipleSelection=!0
treeOptions.addOrphansToRoot=null!=options.addOrphansToRoot?options.addOrphansToRoot:options.addOrphansToRoot=!1
treeOptions.putDepthInfo=null!=options.putDepthInfo?options.putDepthInfo:options.putDepthInfo=!0
treeOptions.contextMenu=null!=options.contextMenu?options.contextMenu:options.contextMenu=!0
treeOptions.maxRecentFolders=options.maxRecentFolders||(options.maxRecentFolders=10)
treeOptions.useStorage=null!=options.useStorage?options.useStorage:options.useStorage=!1
treeOptions.loadFilesOnInit=null!=options.loadFilesOnInit?options.loadFilesOnInit:options.loadFilesOnInit=!1
treeOptions.delegate=this
NFinderController.__super__.constructor.call(this,options,data)
TreeControllerClass=options.treeControllerClass||NFinderTreeController
this.treeController=new TreeControllerClass(treeOptions,[])
this.appStorage=KD.getSingleton("appStorageController").storage("Finder","1.1")
this.watchers={}
options.useStorage&&this.appStorage.ready(function(){_this.treeController.on("file.opened",_this.bound("setRecentFile"))
_this.treeController.on("folder.expanded",function(folder){return _this.setRecentFolder(folder.path)})
return _this.treeController.on("folder.collapsed",function(_arg){var path
path=_arg.path
_this.unsetRecentFolder(path)
return _this.stopWatching(path)})})
this.noVMFoundWidget=new VMMountStateWidget
this.cleanup()
KD.getSingleton("vmController").on("StateChanged",this.bound("checkVMState"))}__extends(NFinderController,_super)
NFinderController.prototype.registerWatcher=function(path,stopWatching){return this.watchers[path]={stop:stopWatching}}
NFinderController.prototype.stopAllWatchers=function(){var path,watcher,_ref
_ref=this.watchers
for(path in _ref)if(__hasProp.call(_ref,path)){watcher=_ref[path]
watcher.stop()}return this.watchers={}}
NFinderController.prototype.stopWatching=function(pathToStop){var path,watcher,_ref,_results
_ref=this.watchers
_results=[]
for(path in _ref)if(__hasProp.call(_ref,path)){watcher=_ref[path]
if(0===path.indexOf(pathToStop)){watcher.stop()
_results.push(delete this.watchers[path])}}return _results}
NFinderController.prototype.loadView=function(mainView){mainView.addSubView(this.treeController.getView())
mainView.addSubView(this.noVMFoundWidget)
this.viewLoaded=!0
return this.getOptions().loadFilesOnInit?this.reset():void 0}
NFinderController.prototype.reset=function(){var _this=this
return this.getOptions().useStorage?this.appStorage.ready(function(){return _this.loadVms()}):this.utils.defer(function(){return _this.loadVms()})}
NFinderController.prototype.mountVms=function(vms){var vm,_i,_len,_results
if(Array.isArray(vms)){this.cleanup()
_results=[]
for(_i=0,_len=vms.length;_len>_i;_i++){vm=vms[_i]
_results.push(this.mountVm(vm))}return _results}}
NFinderController.prototype.loadVms=function(vmNames,callback){var groupSlug,_this=this
if(vmNames)return this.mountVms(vmNames)
groupSlug=KD.getSingleton("groupsController").getGroupSlug()
null==groupSlug&&(groupSlug=KD.defaultSlug)
return this.appStorage.fetchValue("mountedVM",function(vms){vms||(vms={})
vms[groupSlug]||(vms[groupSlug]=[])
return vms[groupSlug].length>0?_this.mountVms(vms[groupSlug]):KD.remote.api.JVM.fetchVmsByContext({},function(err,vms){return err?"function"==typeof callback?callback(err):void 0:vms&&0!==vms.length?_this.mountVms(vms):KD.getSingleton("vmController").fetchDefaultVmName(function(vm){return vm?_this.mountVms([vm]):_this.noVMFoundWidget.show()})})})}
NFinderController.prototype.getVmNode=function(vmName){var path,vmItem,_ref,_ref1
if(!vmName)return null
_ref=this.treeController.nodes
for(path in _ref)if(__hasProp.call(_ref,path)){vmItem=_ref[path]
if("vm"===(null!=(_ref1=vmItem.data)?_ref1.type:void 0)&&vmItem.data.vmName===vmName)return vmItem}}
NFinderController.prototype.updateMountState=function(vmName,state){var groupSlug,_this=this
if(!KD.isGuest()){groupSlug=KD.getSingleton("groupsController").getGroupSlug()
null==groupSlug&&(groupSlug=KD.defaultSlug)
return this.appStorage.fetchValue("mountedVM",function(vms){var items
vms||(vms={})
vms[groupSlug]||(vms[groupSlug]=[])
items=vms[groupSlug]
state&&__indexOf.call(items,vmName)<0?items.push(vmName):!state&&__indexOf.call(items,vmName)>=0&&items.splice(items.indexOf(vmName),1)
return _this.appStorage.setValue("mountedVM",vms)})}}
NFinderController.prototype.checkVMState=function(err,vm,info){if(err||!info)return warn(err)
switch(info.state){case"MAINTENANCE":return this.unmountVm(vm)}}
NFinderController.prototype.mountVm=function(vm,fetchContent){var path,pipedVm,vmItem,vmName,vmRoots,_ref,_this=this
null==fetchContent&&(fetchContent=!0)
if(!vm)return warn("VM path required! e.g VMNAME[:PATH]")
_ref=vm.split(":"),vmName=_ref[0],path=_ref[1]
vmRoots=this.appStorage.getValue("vmRoots")||{}
pipedVm=this._pipedVmName(vmName)
path||(path=vmRoots[pipedVm]||"/home/"+KD.nick())
if(vmItem=this.getVmNode(vmName))return warn("VM "+vmName+" is already mounted!")
this.updateMountState(vmName,!0)
this.vms.push(FSHelper.createFile({name:""+path,path:"["+vmName+"]"+path,type:"vm",vmName:vmName,treeController:this.treeController}))
this.noVMFoundWidget.hide()
this.treeController.addNode(this.vms.last)
vmItem=this.getVmNode(vmName)
return fetchContent&&vmItem?this.utils.wait(1e3,function(){return _this.treeController.expandFolder(vmItem,function(err){if("VMNotFoundError"===(null!=err?err.name:void 0))return _this.unmountVm(vmName)
_this.treeController.selectNode(vmItem)
return _this.utils.defer(function(){return _this.getOptions().useStorage?_this.reloadPreviousState(vmName):void 0})},!0)}):void 0}
NFinderController.prototype.unmountVm=function(vmName){var vmItem
vmItem=this.getVmNode(vmName)
if(!vmItem)return warn("No such VM!")
this.updateMountState(vmName,!1)
this.stopWatching(vmItem.data.path)
FSHelper.unregisterVmFiles(vmName)
this.treeController.removeNodeView(vmItem)
this.vms=this.vms.filter(function(vmData){return vmData!==vmItem.data})
if(0===this.vms.length){this.noVMFoundWidget.show()
return this.emit("EnvironmentsTabRequested")}}
NFinderController.prototype.updateVMRoot=function(vmName,path,callback){var pipedVm,vmRoots
if(!vmName&&!path)return warn("VM name and new path required!")
this.unmountVm(vmName)
"function"==typeof callback&&callback()
vmRoots=this.appStorage.getValue("vmRoots")||{}
pipedVm=this._pipedVmName(vmName)
vmRoots[pipedVm]=path
this.getOptions().useStorage&&this.appStorage.setValue("vmRoots",vmRoots)
return this.mountVm(""+vmName+":"+path)}
NFinderController.prototype.cleanup=function(){this.treeController.removeAllNodes()
FSHelper.resetRegistry()
this.stopAllWatchers()
return this.vms=[]}
NFinderController.prototype.setRecentFile=function(_arg){var path,recentFiles,_this=this
path=_arg.path
recentFiles=this.appStorage.getValue("recentFiles")
Array.isArray(recentFiles)||(recentFiles=[])
if(__indexOf.call(recentFiles,path)<0){recentFiles.length===this.treeController.getOptions().maxRecentFiles&&recentFiles.pop()
recentFiles.unshift(path)}return this.appStorage.setValue("recentFiles",recentFiles.slice(0,10),function(){return _this.emit("recentfiles.updated",recentFiles)})}
NFinderController.prototype.hideDotFiles=function(vmName){var file,node,path,_ref,_results
if(vmName){this.setNodesHidden(vmName,!0)
_ref=this.treeController.nodes
_results=[]
for(path in _ref)if(__hasProp.call(_ref,path)){node=_ref[path]
file=node.getData()
if(file.vmName===vmName&&file.isHidden()){this.stopWatching(file.path)
_results.push(this.treeController.removeNodeView(node))}else _results.push(void 0)}return _results}}
NFinderController.prototype.showDotFiles=function(vmName){var node,path,_ref,_this=this
if(vmName){this.setNodesHidden(vmName,!1)
_ref=this.treeController.nodes
for(path in _ref)if(__hasProp.call(_ref,path)){node=_ref[path]
if("vm"===node.getData().type&&node.getData().vmName===vmName)return this.treeController.collapseFolder(node,function(){return _this.reloadPreviousState(vmName)},!0)}}}
NFinderController.prototype.isNodesHiddenFor=function(vmName){var pipedVm
pipedVm=this._pipedVmName(vmName)
return(this.appStorage.getValue("vmsDotFileChoices")||{})[pipedVm]}
NFinderController.prototype.setNodesHidden=function(vmName,state){var pipedVm,prefs
pipedVm=this._pipedVmName(vmName)
prefs=this.appStorage.getValue("vmsDotFileChoices")||{}
prefs[pipedVm]=state
return this.appStorage.setValue("vmsDotFileChoices",prefs)}
NFinderController.prototype.getRecentFolders=function(){var recentFolders
recentFolders=this.appStorage.getValue("recentFolders")
Array.isArray(recentFolders)||(recentFolders=[])
return recentFolders}
NFinderController.prototype.setRecentFolder=function(folderPath,callback){var recentFolders
recentFolders=this.getRecentFolders()
__indexOf.call(recentFolders,folderPath)<0&&recentFolders.push(folderPath)
recentFolders.sort(function(path){return path===folderPath?-1:0})
return this.appStorage.setValue("recentFolders",recentFolders,callback)}
NFinderController.prototype.unsetRecentFolder=function(folderPath,callback){var recentFolders
recentFolders=this.getRecentFolders()
recentFolders=recentFolders.filter(function(path){return 0!==path.indexOf(folderPath)})
recentFolders.sort(function(path){return path===folderPath?-1:0})
return this.appStorage.setValue("recentFolders",recentFolders,callback)}
NFinderController.prototype.expandFolder=function(folderPath,callback){var node,path,_ref
null==callback&&(callback=noop)
if(folderPath){_ref=this.treeController.nodes
for(path in _ref)if(__hasProp.call(_ref,path)){node=_ref[path]
if(path===folderPath)return this.treeController.expandFolder(node,callback)}return callback({message:"Folder not exists: "+folderPath})}}
NFinderController.prototype.expandFolders=function(){var expandedFolderIndex
expandedFolderIndex=0
return function(paths,callback){var _this=this
null==callback&&(callback=noop)
return this.expandFolder(paths[expandedFolderIndex],function(err){if(err){"function"==typeof callback&&callback(err)
_this.unsetRecentFolder(paths[expandedFolderIndex])}expandedFolderIndex++
expandedFolderIndex<=paths.length&&_this.expandFolders(paths,callback,expandedFolderIndex)
if(expandedFolderIndex===paths.length){"function"==typeof callback&&callback(null,_this.treeController.nodes[paths.last])
return expandedFolderIndex=0}})}}()
NFinderController.prototype.reloadPreviousState=function(vmName){var recentFolders
recentFolders=this.getRecentFolders()
if(vmName){recentFolders=recentFolders.filter(function(folder){return folder.indexOf(0==="["+vmName+"]")})
0===recentFolders.length&&(recentFolders=["["+vmName+"]/home/"+KD.nick()])}return this.expandFolders(recentFolders)}
NFinderController.prototype.uploadTo=function(path){var sidebarView
sidebarView=this.getDelegate()
sidebarView.dnduploader.setPath(path)
return sidebarView.dndUploadHolder.show()}
NFinderController.prototype._pipedVmName=function(vmName){return vmName.replace(/\./g,"|")}
return NFinderController}(KDViewController)
VMMountStateWidget=function(_super){function VMMountStateWidget(){VMMountStateWidget.__super__.constructor.call(this,{cssClass:"no-vm-found-widget"})
this.loader=new KDLoaderView({size:{width:20},loaderOptions:{speed:.7,FPS:24}})
this.warning=new KDCustomHTMLView({partial:"There is no attached VM"})}__extends(VMMountStateWidget,_super)
VMMountStateWidget.prototype.pistachio=function(){return"{{> this.loader}}\n{{> this.warning}}"}
VMMountStateWidget.prototype.showMessage=function(message){message||(message="There is no VM attached to filetree, you can\nattach or create one from environment menu below.")
this.warning.updatePartial(message)
this.warning.show()
return this.loader.hide()}
VMMountStateWidget.prototype.show=function(){var group,_this=this
this.setClass("visible")
this.warning.hide()
this.loader.show()
if(KD.getSingleton("groupsController").getGroupSlug()===KD.defaultSlug)return this.showMessage()
if(__indexOf.call(KD.config.roles,"admin")>=0||__indexOf.call(KD.config.roles,"owner")>=0){group=KD.getSingleton("groupsController").getCurrentGroup()
return group.checkPayment(function(err,payments){err&&warn(err)
return 0===payments.length?_this.showMessage("There is no VM attached for this group, you can\nattach one or you can <b>pay</b> and create\na new one from environment menu below."):_this.showMessage("There is no VM attached for this group, you can\nattach one or you can create a new one from\nenvironment menu below.")})}return this.showMessage("There is no VM for this group or not attached to\nfiletree yet, you can attach one from environment\nmenu below.")}
VMMountStateWidget.prototype.hide=function(){this.unsetClass("visible")
return this.loader.hide()}
return VMMountStateWidget}(JView)

var NFinderTreeController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
NFinderTreeController=function(_super){function NFinderTreeController(){var mainController,_this=this
NFinderTreeController.__super__.constructor.apply(this,arguments)
if(this.getOptions().contextMenu){this.contextMenuController=new NFinderContextMenuController
this.contextMenuController.on("ContextMenuItemClicked",function(_arg){var contextMenuItem,fileView
fileView=_arg.fileView,contextMenuItem=_arg.contextMenuItem
return _this.contextMenuItemSelected(fileView,contextMenuItem)})}else this.getView().setClass("no-context-menu")
this.appManager=KD.getSingleton("appManager")
mainController=KD.getSingleton("mainController")
mainController.on("NewFileIsCreated",this.bound("navigateToNewFile"))
mainController.on("SelectedFileChanged",this.bound("highlightFile"))}var autoTriedOnce,lastEnteredNode,notification
__extends(NFinderTreeController,_super)
NFinderTreeController.prototype.addNode=function(nodeData,index){var fc,item
fc=this.getDelegate()
return this.getOption("foldersOnly")&&"file"===nodeData.type||nodeData.isHidden()&&fc.isNodesHiddenFor(nodeData.vmName)?void 0:item=NFinderTreeController.__super__.addNode.call(this,nodeData,index)}
NFinderTreeController.prototype.highlightFile=function(view){this.selectNode(this.nodes[view.data.path],null,!1)
return null!=view.ace?null!=view.ace.editor?view.ace.editor.focus():view.ace.on("ace.ready",function(){return view.ace.editor.focus()}):void 0}
NFinderTreeController.prototype.navigateToNewFile=function(newFile){var _this=this
return this.navigateTo(newFile.parentPath,function(){return _this.selectNode(_this.nodes[newFile.path])})}
NFinderTreeController.prototype.getOpenFolders=function(){return Object.keys(this.listControllers).slice(1)}
NFinderTreeController.prototype.openItem=function(nodeView,callback){var nodeData,options
options=this.getOptions()
nodeData=nodeView.getData()
switch(nodeData.type){case"folder":case"mount":case"vm":return this.toggleFolder(nodeView,callback)
case"file":this.openFile(nodeView)
this.emit("file.opened",nodeData)
return this.setBlurState()}}
NFinderTreeController.prototype.openFile=function(nodeView){var file
if(nodeView){file=nodeView.getData()
return this.getDelegate().emit("FileNeedsToBeOpened",file)}}
NFinderTreeController.prototype.previewFile=function(nodeView){var path,vmName,_ref
_ref=nodeView.getData(),vmName=_ref.vmName,path=_ref.path
return this.appManager.open("Viewer",{params:{path:path,vmName:vmName}})}
NFinderTreeController.prototype.resetVm=function(nodeView){var vmName
vmName=nodeView.data.vmName
return KD.getSingleton("vmController").reinitialize(vmName)}
NFinderTreeController.prototype.unmountVm=function(nodeView){var vmName
vmName=nodeView.data.vmName
return this.getDelegate().unmountVm(vmName)}
NFinderTreeController.prototype.openVmTerminal=function(nodeView){var vmName
vmName=nodeView.data.vmName
return this.appManager.open("Terminal",{params:{vmName:vmName},forceNew:!0})}
NFinderTreeController.prototype.toggleDotFiles=function(nodeView){var finder,path,vmName,_ref
finder=this.getDelegate()
_ref=nodeView.getData(),vmName=_ref.vmName,path=_ref.path
return finder.isNodesHiddenFor(vmName)?finder.showDotFiles(vmName):finder.hideDotFiles(vmName)}
NFinderTreeController.prototype.makeTopFolder=function(nodeView){var finder,path,vmName,_ref
_ref=nodeView.getData(),vmName=_ref.vmName,path=_ref.path
finder=this.getDelegate()
return finder.updateVMRoot(vmName,FSHelper.plainPath(path))}
NFinderTreeController.prototype.refreshFolder=function(nodeView,callback){var folder,_this=this
this.notify("Refreshing...")
folder=nodeView.getData()
folder.emit("fs.job.finished",[])
return this.collapseFolder(nodeView,function(){return _this.expandFolder(nodeView,function(){notification.destroy()
return"function"==typeof callback?callback():void 0})})}
NFinderTreeController.prototype.toggleFolder=function(nodeView,callback){return nodeView.expanded?this.collapseFolder(nodeView,callback):this.expandFolder(nodeView,callback)}
NFinderTreeController.prototype.expandFolder=function(nodeView,callback,silence){var failCallback,folder,_this=this
null==silence&&(silence=!1)
if(nodeView&&!nodeView.isLoading){if(!nodeView.expanded){folder=nodeView.getData()
if(folder.depth>10){this.notify("Folder is nested deeply, making it top folder")
this.makeTopFolder(nodeView)}failCallback=function(err){var message,_ref
if(!silence){if(null!=err?null!=(_ref=err.message)?_ref.match(/permission denied/i):void 0:void 0){message="Permission denied!"
KD.logToExternal("Couldn't fetch files, permission denied")}else{message="Couldn't fetch files! Click to retry"
KD.logToExternal("Couldn't fetch files")}_this.notify(message,"clickable","Sorry, a problem occured while communicating with servers,\nplease try again later.",!0)
_this.once("fs.retry.scheduled",function(){return _this.expandFolder(nodeView,callback)})}folder.emit("fs.job.finished",[])
return"function"==typeof callback?callback(err):void 0}
return folder.fetchContents(KD.utils.getTimedOutCallback(function(err,files){if(err)return failCallback(err)
nodeView.expand()
files&&_this.addNodes(files)
"function"==typeof callback&&callback(null,nodeView)
silence||_this.emit("folder.expanded",nodeView.getData())
_this.emit("fs.retry.success")
return _this.hideNotification()},failCallback,KD.config.fileFetchTimeout),!1)}"function"==typeof callback&&callback(null,nodeView)}}
NFinderTreeController.prototype.collapseFolder=function(nodeView,callback,silence){var folder,path,_this=this
null==silence&&(silence=!1)
if(nodeView){folder=nodeView.getData()
path=folder.path
silence||this.emit("folder.collapsed",folder)
if(this.listControllers[path])return this.listControllers[path].getView().collapse(function(){_this.removeChildNodes(path)
nodeView.collapse()
return"function"==typeof callback?callback(nodeView):void 0})
nodeView.collapse()
return"function"==typeof callback?callback(nodeView):void 0}}
NFinderTreeController.prototype.navigateTo=function(path,callback){var index,lastPath,_expand,_this=this
if(path){path=path.split("/")
""===path[0]&&path.shift()
""===path[path.length-1]&&path.pop()
path[1]="/"+path[0]+"/"+path[1]
path.shift()
index=0
lastPath=""
_expand=function(path){var nextPath
nextPath=path.slice(0,++index).join("/")
if(lastPath!==nextPath)return _this.expandFolder(_this.nodes[nextPath],function(){lastPath=nextPath
return _expand(path)})
_this.refreshFolder(_this.nodes[nextPath],function(){return"function"==typeof callback?callback():void 0})
return void 0}
return _expand(path)}}
NFinderTreeController.prototype.confirmDelete=function(nodeView){var extension,_ref,_this=this
extension=(null!=(_ref=nodeView.data)?_ref.getExtension():void 0)||null
if(this.selectedNodes.length>1)return new NFinderDeleteDialog({},{items:this.selectedNodes,callback:function(confirmation){confirmation&&_this.deleteFiles(_this.selectedNodes)
return _this.setKeyView()}})
this.beingEdited=nodeView
return nodeView.confirmDelete(function(confirmation){confirmation&&_this.deleteFiles([nodeView])
_this.setKeyView()
return _this.beingEdited=null})}
NFinderTreeController.prototype.deleteFiles=function(nodes,callback){var stack,_this=this
stack=[]
nodes.forEach(function(node){return stack.push(function(cb){return node.getData().remove(function(err){if(err)return _this.notify(null,null,err)
node.emit("ItemBeingDeleted")
return cb(err,node)})})})
return async.parallel(stack,function(error,result){var node,_i,_len
_this.notify(""+result.length+" item"+(result.length>1?"s":"")+" deleted!","success")
for(_i=0,_len=result.length;_len>_i;_i++){node=result[_i]
_this.removeNodeView(node)}return"function"==typeof callback?callback():void 0})}
NFinderTreeController.prototype.showRenameDialog=function(nodeView){var nodeData,oldPath,_this=this
this.beingEdited=nodeView
nodeData=nodeView.getData()
oldPath=nodeData.path
return nodeView.showRenameView(function(newValue){var caretPos
if(newValue!==nodeData.name){if(_this.nodes[""+nodeData.parentPath+"/"+newValue]){caretPos=nodeView.renameView.input.getCaretPosition()
_this.notify(""+nodeData.type.capitalize()+" exist!","error")
return KD.utils.defer(function(){_this.showRenameDialog(nodeView)
return nodeView.renameView.input.setCaretPosition(caretPos)})}nodeData.rename(newValue,function(err){return err?_this.notify(null,null,err):void 0})
return _this.beingEdited=null}})}
NFinderTreeController.prototype.createFile=function(nodeView,type){var nodeData,parentPath,path,vmName,_this=this
null==type&&(type="file")
this.notify("creating a new "+type+"!")
nodeData=nodeView.getData()
vmName=nodeData.vmName
parentPath="file"===nodeData.type?nodeData.parentPath:nodeData.path
path=FSHelper.plainPath(""+parentPath+"/New"+type.capitalize()+("file"===type?".txt":""))
return FSItem.create({path:path,type:type,vmName:vmName,treeController:this},function(err,file){return err?_this.notify(null,null,err):_this.refreshFolder(_this.nodes[parentPath],function(){var node
_this.notify(""+type+" created!","success")
node=_this.nodes["["+file.vmName+"]"+file.path]
_this.selectNode(node)
return _this.showRenameDialog(node)})})}
NFinderTreeController.prototype.moveFiles=function(nodesToBeMoved,targetNodeView,callback){var stack,targetItem,_this=this
targetItem=targetNodeView.getData()
if("file"===targetItem.type){targetNodeView=this.nodes[targetNodeView.getData().parentPath]
targetItem=targetNodeView.getData()}stack=[]
nodesToBeMoved.forEach(function(node){return stack.push(function(cb){var sourceItem
sourceItem=node.getData()
return FSItem.move(sourceItem,targetItem,function(err){return err?_this.notify(null,null,err):cb(err,node)})})})
callback||(callback=function(error,result){var node,_i,_len
_this.notify(""+result.length+" item"+(result.length>1?"s":"")+" moved!","success")
for(_i=0,_len=result.length;_len>_i;_i++){node=result[_i]
_this.removeNodeView(node)}return _this.refreshFolder(targetNodeView)})
return async.parallel(stack,callback)}
NFinderTreeController.prototype.copyFiles=function(nodesToBeCopied,targetNodeView,callback){var stack,targetItem,_this=this
targetItem=targetNodeView.getData()
if("file"===targetItem.type){targetNodeView=this.nodes[targetNodeView.getData().parentPath]
targetItem=targetNodeView.getData()}stack=[]
nodesToBeCopied.forEach(function(node){return stack.push(function(cb){var sourceItem
sourceItem=node.getData()
return FSItem.copy(sourceItem,targetItem,function(err){return err?_this.notify(null,null,err):cb(err,node)})})})
callback||(callback=function(error,result){_this.notify(""+result.length+" item"+(result.length>1?"s":"")+" copied!","success")
return _this.refreshFolder(targetNodeView)})
return async.parallel(stack,callback)}
NFinderTreeController.prototype.duplicateFiles=function(nodes,callback){var stack,_this=this
stack=[]
nodes.forEach(function(node){return stack.push(function(cb){var sourceItem,targetItem
sourceItem=node.getData()
targetItem=_this.nodes[sourceItem.parentPath].getData()
return FSItem.copy(sourceItem,targetItem,function(err){return err?_this.notify(null,null,err):cb(err,node)})})})
callback||(callback=function(error,result){var parentNode,parentNodes,_i,_len,_results
_this.notify(""+result.length+" item"+(result.length>1?"s":"")+" duplicated!","success")
parentNodes=[]
result.forEach(function(node){var parentNode
parentNode=_this.nodes[node.getData().parentPath]
return __indexOf.call(parentNodes,parentNode)<0?parentNodes.push(parentNode):void 0})
_results=[]
for(_i=0,_len=parentNodes.length;_len>_i;_i++){parentNode=parentNodes[_i]
_results.push(_this.refreshFolder(parentNode))}return _results})
return async.parallel(stack,callback)}
NFinderTreeController.prototype.compressFiles=function(nodeView,type){var file,_this=this
file=nodeView.getData()
return FSItem.compress(file,type,function(err){if(err)return _this.notify(null,null,err)
_this.notify(""+file.type.capitalize()+" compressed!","success")
return _this.refreshFolder(_this.nodes[file.parentPath])})}
NFinderTreeController.prototype.extractFiles=function(nodeView){var file,_this=this
file=nodeView.getData()
return FSItem.extract(file,function(err,response){if(err)return _this.notify(null,null,err)
_this.notify(""+file.type.capitalize()+" extracted!","success")
return _this.refreshFolder(_this.nodes[file.parentPath],function(){return _this.selectNode(_this.nodes[response.path])})})}
NFinderTreeController.prototype.cloneRepo=function(nodeView){var folder,modal,_this=this
folder=nodeView.getData()
modal=new CloneRepoModal({vmName:folder.vmName,path:folder.path})
return modal.on("RepoClonedSuccessfully",function(){return _this.notify("Repo cloned successfully.","success")})}
NFinderTreeController.prototype.openTerminalFromHere=function(nodeView){var _this=this
return this.appManager.open("Terminal",function(){var path,webTermView
path=nodeView.getData().path
webTermView=_this.appManager.getFrontApp().getView().tabView.getActivePane().getOptions().webTermView
return webTermView.on("WebTermConnected",function(server){return server.input("cd "+path+"\n")})})}
NFinderTreeController.prototype.cmExpand=function(){var node,_i,_len,_ref,_results
_ref=this.selectedNodes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){node=_ref[_i]
_results.push(this.expandFolder(node))}return _results}
NFinderTreeController.prototype.cmCollapse=function(){var node,_i,_len,_ref,_results
_ref=this.selectedNodes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){node=_ref[_i]
_results.push(this.collapseFolder(node))}return _results}
NFinderTreeController.prototype.cmMakeTopFolder=function(nodeView){return this.makeTopFolder(nodeView)}
NFinderTreeController.prototype.cmRefresh=function(nodeView){return this.refreshFolder(nodeView)}
NFinderTreeController.prototype.cmToggleDotFiles=function(nodeView){return this.toggleDotFiles(nodeView)}
NFinderTreeController.prototype.cmResetVm=function(nodeView){return this.resetVm(nodeView)}
NFinderTreeController.prototype.cmUnmountVm=function(nodeView){return this.unmountVm(nodeView)}
NFinderTreeController.prototype.cmOpenVmTerminal=function(nodeView){return this.openVmTerminal(nodeView)}
NFinderTreeController.prototype.cmCreateFile=function(nodeView){return this.createFile(nodeView)}
NFinderTreeController.prototype.cmCreateFolder=function(nodeView){return this.createFile(nodeView,"folder")}
NFinderTreeController.prototype.cmRename=function(nodeView){return this.showRenameDialog(nodeView)}
NFinderTreeController.prototype.cmDelete=function(nodeView){return this.confirmDelete(nodeView)}
NFinderTreeController.prototype.cmDuplicate=function(){return this.duplicateFiles(this.selectedNodes)}
NFinderTreeController.prototype.cmExtract=function(nodeView){return this.extractFiles(nodeView)}
NFinderTreeController.prototype.cmZip=function(nodeView){return this.compressFiles(nodeView,"zip")}
NFinderTreeController.prototype.cmTarball=function(nodeView){return this.compressFiles(nodeView,"tar.gz")}
NFinderTreeController.prototype.cmUpload=function(nodeView){return this.uploadFile(nodeView)}
NFinderTreeController.prototype.cmDownload=function(){return this.appManager.notify()}
NFinderTreeController.prototype.cmGitHubClone=function(){return this.appManager.notify()}
NFinderTreeController.prototype.cmOpenFile=function(nodeView){return this.openFile(nodeView)}
NFinderTreeController.prototype.cmPreviewFile=function(nodeView){return this.previewFile(nodeView)}
NFinderTreeController.prototype.cmOpenFileWithApp=function(nodeView,contextMenuItem){return this.openFileWithApp(nodeView,contextMenuItem)}
NFinderTreeController.prototype.cmCloneRepo=function(nodeView){return this.cloneRepo(nodeView)}
NFinderTreeController.prototype.cmDropboxChooser=function(nodeView){return this.chooseFromDropbox(nodeView)}
NFinderTreeController.prototype.cmDropboxSaver=function(nodeView){return __saveToDropbox(nodeView)}
NFinderTreeController.prototype.cmOpenTerminal=function(nodeView){return this.openTerminalFromHere(nodeView)}
NFinderTreeController.prototype.cmOpenFileWithCodeMirror=function(){return this.appManager.notify()}
NFinderTreeController.prototype.createContextMenu=function(nodeView,event){var contextMenu
event.stopPropagation()
event.preventDefault()
if(!nodeView.beingDeleted&&!nodeView.beingEdited){if(__indexOf.call(this.selectedNodes,nodeView)>=0)contextMenu=this.contextMenuController.getContextMenu(this.selectedNodes,event)
else{this.selectNode(nodeView)
contextMenu=this.contextMenuController.getContextMenu([nodeView],event)}return!1}}
NFinderTreeController.prototype.contextMenuItemSelected=function(nodeView,contextMenuItem){var action,_name
action=contextMenuItem.getData().action
if(action){null!=this["cm"+action.capitalize()]&&this.contextMenuController.destroyContextMenu()
return"function"==typeof this[_name="cm"+action.capitalize()]?this[_name](nodeView,contextMenuItem):void 0}}
NFinderTreeController.prototype.resetBeingEditedItems=function(){return this.beingEdited.resetView()}
NFinderTreeController.prototype.organizeSelectedNodes=function(listController,nodes,event){null==event&&(event={})
this.beingEdited&&this.resetBeingEditedItems()
return NFinderTreeController.__super__.organizeSelectedNodes.apply(this,arguments)}
NFinderTreeController.prototype.showDragOverFeedback=function(){return NFinderTreeController.__super__.showDragOverFeedback.apply(this,arguments)}
NFinderTreeController.prototype.clearDragOverFeedback=function(){return NFinderTreeController.__super__.clearDragOverFeedback.apply(this,arguments)}
NFinderTreeController.prototype.clearAllDragFeedback=function(){return NFinderTreeController.__super__.clearAllDragFeedback.apply(this,arguments)}
NFinderTreeController.prototype.click=function(nodeView,event){if($(event.target).is(".chevron")){this.contextMenu(nodeView,event)
return!1}if($(event.target).is(".arrow")){this.openItem(nodeView)
return!1}return NFinderTreeController.__super__.click.apply(this,arguments)}
NFinderTreeController.prototype.dblClick=function(nodeView){return this.openItem(nodeView)}
NFinderTreeController.prototype.contextMenu=function(nodeView,event){return this.getOptions().contextMenu?this.createContextMenu(nodeView,event):void 0}
NFinderTreeController.prototype.dragOver=function(nodeView,event){this.showDragOverFeedback(nodeView,event)
return NFinderTreeController.__super__.dragOver.apply(this,arguments)}
NFinderTreeController.prototype.dragStart=function(nodeView,event){var dndDownload,name,path,type,url,vmName,warningText,_ref
NFinderTreeController.__super__.dragStart.apply(this,arguments)
this.internalDragging=!0
_ref=nodeView.data,name=_ref.name,vmName=_ref.vmName,path=_ref.path
warningText="You should move "+name+" file to Web folder to download using drag and drop. -- Koding"
type="application/octet-stream"
url=KD.getPublicURLOfPath(path)
if(!url){url="data:"+type+";base64,"+btoa(warningText)
name+=".txt"}dndDownload=""+type+":"+name+":"+url
return event.originalEvent.dataTransfer.setData("DownloadURL",dndDownload)}
lastEnteredNode=null
NFinderTreeController.prototype.dragEnter=function(nodeView,event){var e,_ref,_ref1,_ref2,_this=this
if(lastEnteredNode===nodeView||__indexOf.call(this.selectedNodes,nodeView)>=0)return nodeView
lastEnteredNode=nodeView
clearTimeout(this.expandTimeout);("folder"===(_ref=nodeView.getData().type)||"mount"===_ref||"vm"===_ref)&&(this.expandTimeout=setTimeout(function(){return _this.expandFolder(nodeView)},800))
this.showDragOverFeedback(nodeView,event)
e=event.originalEvent
this.boundaries.top>(_ref1=e.pageY)&&_ref1>this.boundaries.top+20&&log("trigger top scroll")
this.boundaries.top+this.boundaries.height<(_ref2=e.pageY)&&_ref2<this.boundaries.top+this.boundaries.height+20&&log("trigger down scroll")
return NFinderTreeController.__super__.dragEnter.apply(this,arguments)}
NFinderTreeController.prototype.dragLeave=function(nodeView,event){this.clearDragOverFeedback(nodeView,event)
return NFinderTreeController.__super__.dragLeave.apply(this,arguments)}
NFinderTreeController.prototype.dragEnd=function(){this.clearAllDragFeedback()
this.internalDragging=!1
return NFinderTreeController.__super__.dragEnd.apply(this,arguments)}
NFinderTreeController.prototype.drop=function(nodeView,event){var _ref
if(!(__indexOf.call(this.selectedNodes,nodeView)>=0||"folder"!==(_ref="function"==typeof nodeView.getData?nodeView.getData().type:void 0)&&"mount"!==_ref&&"vm"!==_ref)){this.selectedNodes=this.selectedNodes.filter(function(node){var sourcePath,targetPath
targetPath="function"==typeof nodeView.getData?nodeView.getData().path:void 0
sourcePath="function"==typeof node.getData?node.getData().parentPath:void 0
return targetPath!==sourcePath})
event.altKey?this.copyFiles(this.selectedNodes,nodeView):this.moveFiles(this.selectedNodes,nodeView)
this.internalDragging=!1
return NFinderTreeController.__super__.drop.apply(this,arguments)}}
NFinderTreeController.prototype.keyEventHappened=function(){return NFinderTreeController.__super__.keyEventHappened.apply(this,arguments)}
NFinderTreeController.prototype.performDownKey=function(nodeView,event){var offset
if(event.altKey){offset=nodeView.$(".chevron").offset()
event.pageY=offset.top
event.pageX=offset.left
return this.contextMenu(nodeView,event)}return NFinderTreeController.__super__.performDownKey.apply(this,arguments)}
NFinderTreeController.prototype.performBackspaceKey=function(nodeView,event){event.preventDefault()
event.stopPropagation()
this.confirmDelete(nodeView,event)
return!1}
NFinderTreeController.prototype.performEnterKey=function(nodeView){this.selectNode(nodeView)
return this.openItem(nodeView)}
NFinderTreeController.prototype.performRightKey=function(nodeView){var type
type=nodeView.getData().type
return/mount|folder|vm/.test(type)?this.expandFolder(nodeView):void 0}
NFinderTreeController.prototype.performUpKey=function(){return NFinderTreeController.__super__.performUpKey.apply(this,arguments)}
NFinderTreeController.prototype.performLeftKey=function(nodeView){if(nodeView.expanded){this.collapseFolder(nodeView)
return!1}return NFinderTreeController.__super__.performLeftKey.apply(this,arguments)}
notification=null
autoTriedOnce=!0
NFinderTreeController.prototype.hideNotification=function(){return notification?notification.destroy():void 0}
NFinderTreeController.prototype.notify=function(msg,style,details,reconnect){var duration,_this=this
null==reconnect&&(reconnect=!1)
if(null!=this.getView().parent){notification&&notification.destroy()
details&&!msg&&/Permission denied/i.test(null!=details?details.message:void 0)&&(msg="Permission denied!")
details&&(style||(style="error"))
duration=reconnect?0:details?5e3:2500
return notification=new KDNotificationView({title:msg||"Something went wrong",type:"mini",cssClass:"filetree "+style,container:this.getView().parent,duration:duration,details:details,click:function(){if(reconnect){_this.emit("fs.retry.scheduled")
notification.notificationSetTitle("Attempting to fetch files")
notification.notificationSetPositions()
notification.setClass("loading")
_this.utils.wait(6e3,notification.bound("destroy"))
_this.once("fs.retry.success",notification.bound("destroy"))}else if(notification.getOptions().details){details=new KDNotificationView({title:"Error details",content:notification.getOptions().details,type:"growl",duration:0,click:function(){return details.destroy()}})
KD.getSingleton("windowController").addLayer(details)
return details.on("ReceivedClickElsewhere",function(){return details.destroy()})}}})}}
NFinderTreeController.prototype.refreshTopNode=function(){var nickname,_this=this
nickname=KD.whoami().profile.nickname
return this.refreshFolder(this.nodes["/home/"+nickname],function(){return _this.emit("fs.retry.success")})}
NFinderTreeController.prototype.chooseFromDropbox=function(nodeView){var fileItemViews,filePath,kallback,modal
fileItemViews=[]
filePath=FSHelper.plainPath(nodeView.getData().path)
modal=null
kallback=function(){var file
file=fileItemViews[0]
if(file){file.emit("FileNeedsToBeDownloaded",filePath)
return file.on("FileDownloadDone",function(){fileItemViews.shift()
if(fileItemViews.length)return kallback()
modal.destroy()
return new KDNotificationView({title:"Your download has been completed",type:"mini",cssClass:"success",duration:4e3})})}}
return Dropbox.choose({linkType:"direct",multiselect:!0,success:function(files){var file,fileItemView,_i,_len,_results
modal=new KDModalView({overlay:!0,title:"Download from Dropbox",buttons:{Start:{title:"Start",cssClass:"modal-clean-green",callback:function(){return kallback()}},Cancel:{title:"Cancel",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})
_results=[]
for(_i=0,_len=files.length;_len>_i;_i++){file=files[_i]
fileItemView=modal.addSubView(new DropboxDownloadItemView({nodeView:nodeView},file))
_results.push(fileItemViews.push(fileItemView))}return _results}})}
NFinderTreeController.prototype.uploadFile=function(nodeView){var finderController,path
finderController=this.getDelegate()
path=nodeView.data.path
return path?finderController.uploadTo(path):void 0}
return NFinderTreeController}(JTreeViewController)

var NFinderContextMenuController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFinderContextMenuController=function(_super){function NFinderContextMenuController(){_ref=NFinderContextMenuController.__super__.constructor.apply(this,arguments)
return _ref}__extends(NFinderContextMenuController,_super)
NFinderContextMenuController.prototype.getMenuItems=function(fileViews){var fileView
if(fileViews.length>1)return this.getMutilpleItemMenu(fileViews)
fileView=fileViews[0]
switch(fileView.getData().type){case"vm":return this.getVmMenu(fileView)
case"file":return this.getFileMenu(fileView)
case"folder":return this.getFolderMenu(fileView)
case"mount":return this.getMountMenu(fileView)
case"brokenLink":return this.getBrokenLinkMenu(fileView)}}
NFinderContextMenuController.prototype.getContextMenu=function(fileViews,event){var fileView,items,_this=this
this.contextMenu&&this.contextMenu.destroy()
items=this.getMenuItems(fileViews)
fileView=fileViews[0]
if(items){this.contextMenu=new JContextMenu({event:event,delegate:fileView,cssClass:"finder"},items)
this.contextMenu.on("ContextMenuItemReceivedClick",function(contextMenuItem){return _this.handleContextMenuClick(fileView,contextMenuItem)})
return this.contextMenu}return!1}
NFinderContextMenuController.prototype.destroyContextMenu=function(){return this.contextMenu.destroy()}
NFinderContextMenuController.prototype.handleContextMenuClick=function(fileView,contextMenuItem){return this.emit("ContextMenuItemClicked",{fileView:fileView,contextMenuItem:contextMenuItem})}
NFinderContextMenuController.prototype.getFileMenu=function(fileView){var fileData,items
fileData=fileView.getData()
items={"Open File":{separator:!0,action:"openFile"},Delete:{action:"delete",separator:!0},Rename:{action:"rename"},Duplicate:{action:"duplicate"},"Set permissions":{children:{customView:new NSetPermissionsView({},fileData)}},Extract:{action:"extract"},Compress:{separator:!0,children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},"Public URL...":{separator:!0},"New File":{action:"createFile"},"New Folder":{action:"createFolder"}}
"archive"!==FSItem.getFileType(FSItem.getFileExtension(fileData.name))?delete items.Extract:delete items.Compress
FSHelper.isPublicPath(fileData.path)?items["Public URL..."].children={customView:new NCopyUrlView({},fileData)}:delete items["Public URL..."]
return items}
NFinderContextMenuController.prototype.getFolderMenu=function(fileView){var fileData,items,nickname
fileData=fileView.getData()
items={Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},"Make this top Folder":{action:"makeTopFolder",separator:!0},Delete:{action:"delete",separator:!0},Rename:{action:"rename"},Duplicate:{action:"duplicate"},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},"Set permissions":{separator:!0,children:{customView:new NSetPermissionsView({},fileData)}},"New File":{action:"createFile"},"New Folder":{action:"createFolder"},"Upload file...":{action:"upload"},"Clone a repo here":{action:"cloneRepo",separator:!0},"Public URL...":{separator:!0},Refresh:{action:"refresh"}}
fileView.expanded?delete items.Expand:delete items.Collapse
FSHelper.isPublicPath(fileData.path)?items["Public URL..."].children={customView:new NCopyUrlView({},fileData)}:delete items["Public URL..."]
nickname=KD.whoami().profile.nickname
if(fileData.path==="/home/"+nickname+"/Applications"){items.Refresh.separator=!0
items["Make a new Application"]={action:"makeNewApp"}}if("kdapp"===fileData.getExtension()){items.Refresh.separator=!0
items["Application menu"]={children:{Compile:{action:"compile"},Run:{action:"runApp",separator:!0},"Download source files":{action:"downloadApp"}}}
if(KD.checkFlag("app-publisher")||KD.checkFlag("super-admin")){items["Application menu"].children["Download source files"].separator=!0
items["Application menu"].children["Publish to App Catalog"]={action:"publish"}}}return items}
NFinderContextMenuController.prototype.getBrokenLinkMenu=function(fileView){var fileData,items
fileData=fileView.getData()
items={Delete:{action:"delete"}}
return items}
NFinderContextMenuController.prototype.getVmMenu=function(fileView){var fileData,items
fileData=fileView.getData()
items={Refresh:{action:"refresh",separator:!0},"Unmount VM":{action:"unmountVm"},"Open VM Terminal":{action:"openVmTerminal",separator:!0},Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},"Toggle Invisible Files":{action:"toggleDotFiles",separator:!0},"New File":{action:"createFile"},"New Folder":{action:"createFolder"},"Upload file...":{action:"upload"}}
fileView.expanded?delete items.Expand:delete items.Collapse
return items}
NFinderContextMenuController.prototype.getMountMenu=function(fileView){var fileData,items
fileData=fileView.getData()
items={Refresh:{action:"refresh",separator:!0},Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},"New File":{action:"createFile"},"New Folder":{action:"createFolder"},"Upload file...":{action:"upload"}}
fileView.expanded?delete items.Expand:delete items.Collapse
return items}
NFinderContextMenuController.prototype.getMutilpleItemMenu=function(fileViews){var fileView,items,types,_i,_len
types={file:!1,folder:!1,mount:!1}
for(_i=0,_len=fileViews.length;_len>_i;_i++){fileView=fileViews[_i]
types[fileView.getData().type]=!0}if(types.file&&!types.folder&&!types.mount)return this.getMultipleFileMenu(fileViews)
if(!types.file&&types.folder&&!types.mount)return this.getMultipleFolderMenu(fileViews)
items={Delete:{action:"delete",separator:!0},Duplicate:{action:"duplicate"},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}}}
return items}
NFinderContextMenuController.prototype.getMultipleFolderMenu=function(folderViews){var allCollapsed,allExpanded,folderView,items,multipleText,_i,_len
items={Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},Delete:{action:"delete",separator:!0},Duplicate:{action:"duplicate"},"Set permissions":{children:{customView:new NSetPermissionsView({},{mode:"000",type:"multiple"})}},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}}}
multipleText="Delete "+folderViews.length+" folders"
items.Delete=items[multipleText]={action:"delete"}
allCollapsed=allExpanded=!0
for(_i=0,_len=folderViews.length;_len>_i;_i++){folderView=folderViews[_i]
folderView.expanded?allCollapsed=!1:allExpanded=!1}allCollapsed&&delete items.Collapse
allExpanded&&delete items.Expand
return items}
NFinderContextMenuController.prototype.getMultipleFileMenu=function(fileViews){var items,multipleText
items={"Open Files":{action:"openFile"},Delete:{action:"delete",separator:!0},Duplicate:{action:"duplicate"},"Set permissions":{children:{customView:new NSetPermissionsView({},{mode:"000"})}},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}}}
multipleText="Delete "+fileViews.length+" files"
items.Delete=items[multipleText]={action:"delete"}
return items}
NFinderContextMenuController.prototype.getOpenWithMenuItems=function(fileView){var fileExtension,items,path,plainPath,reWebHome
items={}
reWebHome=RegExp("^/home/"+KD.nick()+"/Web/")
path=fileView.getData().path
plainPath=FSHelper.plainPath(path)
fileExtension=FSItem.getFileExtension(path)
plainPath.match(reWebHome)&&(items.Viewer={action:"previewFile"})
items.separator={type:"separator"}
items["Other Apps"]={action:"showOpenWithModal",separator:!0}
items["Search the App Store"]={disabled:!0}
items["Contribute an Editor"]={disabled:!0}
return items}
return NFinderContextMenuController}(KDController)

var NFinderItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFinderItem=function(_super){function NFinderItem(options,data){var childConstructor,_this=this
null==options&&(options={})
options.tagName||(options.tagName="li")
options.type||(options.type="finderitem")
NFinderItem.__super__.constructor.call(this,options,data)
this.isLoading=!1
this.beingDeleted=!1
this.beingEdited=!1
this.beingProgress=!1
childConstructor=function(){switch(data.type){case"vm":return NVMItemView
case"folder":return NFolderItemView
case"section":return NSectionItemView
case"mount":return NMountItemView
case"brokenLink":return NBrokenLinkItemView
default:return NFileItemView}}()
this.childView=new childConstructor({delegate:this},data)
this.childView.$().css("margin-left",14*data.depth)
null!=data.name&&data.name.length>20-data.depth&&this.childView.setAttribute("title",FSHelper.plainPath(data.name))
this.on("ItemBeingDeleted",function(){return data.removeLocalFileInfo()})
this.on("viewAppended",function(){var fileInfo,lastUploadedChunk,totalChunks
fileInfo=data.getLocalFileInfo()
if(fileInfo.lastUploadedChunk){lastUploadedChunk=fileInfo.lastUploadedChunk,totalChunks=fileInfo.totalChunks
lastUploadedChunk===totalChunks&&data.removeLocalFileInfo()
return _this.showProgressView(100*lastUploadedChunk/totalChunks)}})}__extends(NFinderItem,_super)
NFinderItem.prototype.mouseDown=function(){return!0}
NFinderItem.prototype.resetView=function(){if(this.deleteView){this.deleteView.destroy()
delete this.deleteView}if(this.renameView){this.renameView.destroy()
delete this.renameView}if(this.progressView){this.progressView.destroy()
delete this.progressView}this.childView.show()
this.beingDeleted=!1
this.beingEdited=!1
this.beingProgress=!1
this.callback=null
this.unsetClass("being-deleted being-edited progress")
return this.getDelegate().setKeyView()}
NFinderItem.prototype.confirmDelete=function(callback){this.callback=callback
return this.showDeleteView()}
NFinderItem.prototype.showDeleteView=function(){var data,_this=this
if(!this.deleteView){this.setClass("being-deleted")
this.beingDeleted=!0
this.childView.hide()
data=this.getData()
this.addSubView(this.deleteView=new NFinderItemDeleteView({},data))
this.deleteView.on("FinderDeleteConfirmation",function(confirmation){"function"==typeof _this.callback&&_this.callback(confirmation)
return _this.resetView()})
return this.deleteView.setKeyView()}}
NFinderItem.prototype.showRenameView=function(callback){var data,_this=this
if(!this.renameView){this.setClass("being-edited")
this.beingEdited=!0
this.callback=callback
this.childView.hide()
data=this.getData()
this.addSubView(this.renameView=new NFinderItemRenameView({},data))
this.renameView.$().css("margin-left",10*(data.depth+1)+2)
this.renameView.on("FinderRenameConfirmation",function(newValue){"function"==typeof _this.callback&&_this.callback(newValue)
return _this.resetView()})
return this.renameView.input.setFocus()}}
NFinderItem.prototype.showProgressView=function(percent,determinate){var _this=this
null==percent&&(percent=0)
null==determinate&&(determinate=!0)
this.progressView||this.addSubView(this.progressView=new KDProgressBarView)
this.progressView.setOption("determinate",determinate)
this.progressView.updateBar(percent,"%","")
return percent>=0&&100>percent?this.setClass("progress"):this.utils.wait(1e3,function(){return _this.resetView()})}
NFinderItem.prototype.pistachio=function(){return"{{> this.childView}}"}
return NFinderItem}(JTreeItemView)

var NFileItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFileItemView=function(_super){function NFileItemView(options,data){var eventName,fileData,_i,_len,_this=this
null==options&&(options={})
options.tagName||(options.tagName="div")
options.cssClass||(options.cssClass="file")
NFileItemView.__super__.constructor.call(this,options,data)
fileData=this.getData()
this.loader=new KDLoaderView({size:{width:16},loaderOptions:{color:"#71BAA2",shape:"rect",diameter:16,density:12,range:1,speed:1,FPS:24}})
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"icon"})
for(_i=0,_len=loaderRequiredEvents.length;_len>_i;_i++){eventName=loaderRequiredEvents[_i]
fileData.on("fs."+eventName+".started",function(){return _this.showLoader()})
fileData.on("fs."+eventName+".finished",function(){return _this.hideLoader()})}}var loaderRequiredEvents
__extends(NFileItemView,_super)
loaderRequiredEvents=["job","remove","save","saveAs"]
NFileItemView.prototype.destroy=function(){var eventName,fileData,_i,_len
fileData=this.getData()
for(_i=0,_len=loaderRequiredEvents.length;_len>_i;_i++){eventName=loaderRequiredEvents[_i]
fileData.off("fs."+eventName+".started")
fileData.off("fs."+eventName+".finished")}return NFileItemView.__super__.destroy.apply(this,arguments)}
NFileItemView.prototype.decorateItem=function(){var extension,fileType
extension=FSItem.getFileExtension(this.getData().name)
if(extension){fileType=FSItem.getFileType(extension)
return this.icon.$().attr("class","icon "+extension+" "+fileType)}}
NFileItemView.prototype.render=function(){NFileItemView.__super__.render.apply(this,arguments)
return this.decorateItem()}
NFileItemView.prototype.mouseDown=function(){return!0}
NFileItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
this.template.update()
this.hideLoader()
return this.decorateItem()}
NFileItemView.prototype.showLoader=function(){var _ref
null!=(_ref=this.parent)&&(_ref.isLoading=!0)
this.icon.hide()
return this.loader.show()}
NFileItemView.prototype.hideLoader=function(){var _ref
null!=(_ref=this.parent)&&(_ref.isLoading=!1)
this.icon.show()
return this.loader.hide()}
NFileItemView.prototype.pistachio=function(){var data,name,path
data=this.getData()
path=FSHelper.plainPath(data.path)
name=Encoder.XSSEncode(data.name)
return"{{> this.icon}}\n{{> this.loader}}\n<span class='title' title=\""+path+'">'+name+"</span>\n<span class='chevron'></span>"}
return NFileItemView}(KDCustomHTMLView)

var NFolderItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFolderItemView=function(_super){function NFolderItemView(options,data){null==options&&(options={})
options.cssClass||(options.cssClass="folder")
NFolderItemView.__super__.constructor.call(this,options,data)}__extends(NFolderItemView,_super)
return NFolderItemView}(NFileItemView)

var NMountItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NMountItemView=function(_super){function NMountItemView(options,data){null==options&&(options={})
options.cssClass||(options.cssClass="mount")
NMountItemView.__super__.constructor.call(this,options,data)}__extends(NMountItemView,_super)
return NMountItemView}(NFileItemView)

var NBrokenLinkItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NBrokenLinkItemView=function(_super){function NBrokenLinkItemView(options,data){null==options&&(options={})
options.cssClass||(options.cssClass="broken")
NBrokenLinkItemView.__super__.constructor.call(this,options,data)}__extends(NBrokenLinkItemView,_super)
return NBrokenLinkItemView}(NFileItemView)

var NSectionItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NSectionItemView=function(_super){function NSectionItemView(options,data){null==options&&(options={})
options.cssClass||(options.cssClass="section")
NSectionItemView.__super__.constructor.call(this,options,data)}__extends(NSectionItemView,_super)
return NSectionItemView}(NFileItemView)

var NVMItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NVMItemView=function(_super){function NVMItemView(options,data){var _this=this
null==options&&(options={})
options.cssClass||(options.cssClass="vm")
NVMItemView.__super__.constructor.call(this,options,data)
this.vm=KD.getSingleton("vmController")
this.vm.on("StateChanged",this.bound("checkVMState"))
this.changePathButton=new KDCustomHTMLView({tagName:"span",cssClass:"path-select",delegate:this,click:this.bound("createRootContextMenu")})
this.vmInfo=new KDCustomHTMLView({tagName:"span",cssClass:"vm-info",partial:"on <strong>"+data.vmName+"</strong> VM"})
this.vm.fetchVMDomains(data.vmName,function(err,domains){return!err&&domains.length>0?_this.vmInfo.updatePartial('on <a id="open-vm-page-'+data.vmName+'"\nhref="http://'+domains.first+'" target="_blank">\n'+domains.first+"</a> VM"):void 0})}__extends(NVMItemView,_super)
NVMItemView.prototype.showLoader=function(){var _ref
null!=(_ref=this.parent)&&(_ref.isLoading=!0)
return this.loader.show()}
NVMItemView.prototype.hideLoader=function(){var _ref
null!=(_ref=this.parent)&&(_ref.isLoading=!1)
return this.loader.hide()}
NVMItemView.prototype.createRootContextMenu=function(){var contextMenu,currentPath,nodes,offset,parents,path,vm,width,x,_i,_ref
offset=this.changePathButton.$().offset()
currentPath=this.getData().path
width=30+3*currentPath.length
contextMenu=new JContextMenu({menuWidth:width,delegate:this.changePathButton,x:offset.left-106,y:offset.top+22,arrow:{placement:"top",margin:108},lazyLoad:!0},{})
parents=[]
nodes=currentPath.split("/")
for(x=_i=0,_ref=nodes.length-1;_ref>=0?_ref>_i:_i>_ref;x=_ref>=0?++_i:--_i){nodes=currentPath.split("/")
path=nodes.splice(1,x).join("/")
parents.push("/"+path)}parents.reverse()
vm=this.getData().vmName
return this.utils.defer(function(){parents.forEach(function(path){return contextMenu.treeController.addNode({title:path,callback:function(){return KD.getSingleton("finderController").updateVMRoot(vm,path,contextMenu.bound("destroy"))}})})
contextMenu.positionContextMenu()
return contextMenu.treeController.selectFirstNode()})}
NVMItemView.prototype.checkVMState=function(err,vm,info){if(vm===this.getData().vmName){if(err||!info){this.unsetClass("online")
return warn(err)}return"RUNNING"===info.state?this.setClass("online"):this.unsetClass("online")}}
NVMItemView.prototype.viewAppended=function(){NVMItemView.__super__.viewAppended.apply(this,arguments)
return this.vm.info(this.getData().vmName,this.bound("checkVMState"))}
NVMItemView.prototype.pistachio=function(){var path
path=FSHelper.plainPath(this.getData().path)
return'{{> this.icon}}\n{{> this.loader}}\n{span.title[title="'+path+"\"]{ #(name)}}\n{{> this.changePathButton}}\n{{> this.vmInfo}}\n<span class='chevron'></span>"}
return NVMItemView}(NFileItemView)

var NFinderItemDeleteView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFinderItemDeleteView=function(_super){function NFinderItemDeleteView(){var _this=this
NFinderItemDeleteView.__super__.constructor.apply(this,arguments)
this.setClass("delete-container")
this.button=new KDButtonView({title:"Delete",style:"clean-red",callback:function(){return _this.emit("FinderDeleteConfirmation",!0)}})
this.cancel=new KDCustomHTMLView({tagName:"a",attributes:{href:"#",title:"Cancel"},cssClass:"cancel",click:function(){return _this.emit("FinderDeleteConfirmation",!1)}})
this.label=new KDLabelView({title:"Are you sure?"})}__extends(NFinderItemDeleteView,_super)
NFinderItemDeleteView.prototype.viewAppended=function(){NFinderItemDeleteView.__super__.viewAppended.apply(this,arguments)
return this.button.$().focus()}
NFinderItemDeleteView.prototype.pistachio=function(){return"{{> this.label}}\n{{> this.button}}\n{{> this.cancel}}"}
NFinderItemDeleteView.prototype.keyDown=function(event){switch(event.which){case 27:this.emit("FinderDeleteConfirmation",!1)
return!1
case 9:if(!this.button.$().is(":focus")){this.button.$().focus()
return!1}}}
return NFinderItemDeleteView}(JView)

var NFinderDeleteDialog,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFinderDeleteDialog=function(_super){function NFinderDeleteDialog(options,data){var callback,items,numFiles,_this=this
null==options&&(options={})
items=data.items
callback=data.callback
numFiles=""+items.length+" item"+(items.length>1?"s":"")
options.title="Do you really want to delete "+numFiles
options.content=""
options.overlay=!0
options.cssClass="new-kdmodal"
options.width=500
options.height="auto"
options.buttons={}
options.buttons["Yes, delete "+numFiles]={style:"modal-clean-red",callback:function(){"function"==typeof callback&&callback(!0)
return _this.destroy()}}
options.buttons.cancel={style:"modal-cancel",callback:function(){"function"==typeof callback&&callback(!1)
return _this.destroy()}}
NFinderDeleteDialog.__super__.constructor.call(this,options,data)
KD.getSingleton("windowController").setKeyView(null)}__extends(NFinderDeleteDialog,_super)
NFinderDeleteDialog.prototype.viewAppended=function(){var fileView,item,items,scrollView,_i,_len
items=this.getData().items
this.$().css({top:75})
scrollView=new KDScrollView({cssClass:"modalformline file-container"})
scrollView.$().css({maxHeight:KD.getSingleton("windowController").winHeight-250})
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
scrollView.addSubView(fileView=new KDCustomHTMLView({tagName:"p",cssClass:"delete-file "+item.getData().type,partial:"<span class='icon'></span>"+item.getData().name}))}return this.addSubView(scrollView)}
NFinderDeleteDialog.prototype.destroy=function(){KD.getSingleton("windowController").revertKeyView()
return NFinderDeleteDialog.__super__.destroy.apply(this,arguments)}
return NFinderDeleteDialog}(KDModalView)

var NFinderItemRenameView,NFinderRenameInput,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NFinderItemRenameView=function(_super){function NFinderItemRenameView(options,data){var _this=this
NFinderItemRenameView.__super__.constructor.apply(this,arguments)
this.setClass("rename-container")
this.input=new NFinderRenameInput({defaultValue:data.name,type:"text",callback:function(newValue){return _this.emit("FinderRenameConfirmation",newValue)},keyup:function(event){return 27===event.which?_this.emit("FinderRenameConfirmation",data.name):void 0}})
KD.getSingleton("windowController").addLayer(this.input)
this.cancel=new KDCustomHTMLView({tagName:"a",attributes:{href:"#",title:"Cancel"},cssClass:"cancel",click:function(){return _this.emit("FinderRenameConfirmation",data.name)}})}__extends(NFinderItemRenameView,_super)
NFinderItemRenameView.prototype.pistachio=function(){return"{{> this.input}}\n{{> this.cancel}}"}
return NFinderItemRenameView}(JView)
NFinderRenameInput=function(_super){function NFinderRenameInput(options,data){null==options&&(options={})
NFinderRenameInput.__super__.constructor.call(this,options,data)
this.once("viewAppended",this.bound("selectAll"))}__extends(NFinderRenameInput,_super)
NFinderRenameInput.prototype.click=function(){return!1}
NFinderRenameInput.prototype.dblClick=function(){return!1}
return NFinderRenameInput}(KDHitEnterInputView)

var NSetPermissionsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NSetPermissionsView=function(_super){function NSetPermissionsView(){var _this=this
NSetPermissionsView.__super__.constructor.apply(this,arguments)
this.switches=[]
this.setPermissionsButton=new KDButtonView({title:"Set",callback:function(){var file,permissions,recursive
permissions=_this.getPermissions()
recursive=_this.recursive.getValue()||!1
file=_this.getData()
return file.chmod({permissions:permissions,recursive:recursive},function(err){return err?void 0:_this.displayOldOctalPermissions()})}})
this.recursive=new KDOnOffSwitch({size:"tiny"})}var permissionsToOctalString
__extends(NSetPermissionsView,_super)
permissionsToOctalString=function(permissions){var str
str=permissions.toString(8)
for(;str.length<3;)str="0"+str
return str.slice(-3)}
NSetPermissionsView.prototype.createSwitches=function(permission){var i,_i,_results,_this=this
_results=[]
for(i=_i=0;9>_i;i=++_i)_results.push(this.switches.push(new KDOnOffSwitch({defaultValue:0!==(permission&1<<i),callback:function(){return _this.displayOctalPermissions()}})))
return _results}
NSetPermissionsView.prototype.getPermissions=function(){var i,permissions,s,_i,_len,_ref
permissions=0
_ref=this.switches
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){s=_ref[i]
s.getValue()&&(permissions|=1<<i)}return permissions}
NSetPermissionsView.prototype.displayOctalPermissions=function(){return this.$("footer p.new em").html(permissionsToOctalString(this.getPermissions()))}
NSetPermissionsView.prototype.displayOldOctalPermissions=function(){return this.$("footer p.old em").html(permissionsToOctalString(this.getData().mode))}
NSetPermissionsView.prototype.viewAppended=function(){var _ref
this.setClass("set-permissions-wrapper")
this.applyExistingPermissions()
NSetPermissionsView.__super__.viewAppended.apply(this,arguments)
return"folder"===(_ref=this.getData().type)||"multiple"===_ref?this.$(".recursive").removeClass("hidden"):void 0}
NSetPermissionsView.prototype.pistachio=function(){var mode
mode=this.getData().mode
return null==mode?'<header class="clearfix"><div>Unknown file permissions</div></header>':'<header class="clearfix"><span>Read</span><span>Write</span><span>Execute</span></header>\n<aside class="permissions"><p>Owner:</p><p>Group:</p><p>Everyone:</p></aside>\n<section class="switch-holder clearfix">\n  <div class="kdview switcher-group">\n    {{> this.switches[8]}}\n    {{> this.switches[5]}}\n    {{> this.switches[2]}}\n  </div>\n  <div class="kdview switcher-group">\n    {{> this.switches[7]}}\n    {{> this.switches[4]}}\n    {{> this.switches[1]}}\n  </div>\n  <div class="kdview switcher-group">\n    {{> this.switches[6]}}\n    {{> this.switches[3]}}\n    {{> this.switches[0]}}\n  </div>\n</section>\n<footer class="clearfix">\n  <div class="recursive hidden">\n    <label>Apply to Enclosed Items</label>\n    {{> this.recursive}}\n  </div>\n  <p class="old">Old: <em></em></p>\n  <p class="new">New: <em></em></p>\n  {{> this.setPermissionsButton}}\n</footer>'}
NSetPermissionsView.prototype.applyExistingPermissions=function(){var mode,setPermissionsView,_this=this
setPermissionsView=this
mode=this.getData().mode
this.getData().newMode=mode
this.createSwitches(mode)
return setTimeout(function(){_this.displayOctalPermissions()
return _this.displayOldOctalPermissions()},0)}
return NSetPermissionsView}(JView)

var NVMToggleButtonView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NVMToggleButtonView=function(_super){function NVMToggleButtonView(options,data){var _this=this
NVMToggleButtonView.__super__.constructor.call(this,{cssClass:"vm-toggle-menu"},data)
this.vm=KD.getSingleton("vmController")
this.vm.on("StateChanged",this.bound("checkVMState"))
this.toggle=new KDOnOffSwitch({cssClass:"tiny vm-toggle-item",callback:function(state){return state?_this.vm.start(_this.getData().vmName):_this.vm.stop(_this.getData().vmName)}})}__extends(NVMToggleButtonView,_super)
NVMToggleButtonView.prototype.checkVMState=function(err,vm,info){var _ref
if(vm===this.getData().vmName){if(err||!info){null!=(_ref=this.notification)&&_ref.destroy()
this.notification=new KDNotificationView({type:"mini",cssClass:"error",duration:5e3,title:"I cannot turn this machine on, please give it a few seconds."})
this.toggle.setDefaultValue(!1)
KD.utils.notifyAndEmailVMTurnOnFailureToSysAdmin(vm,err.message)
return warn(err)}return"RUNNING"===info.state?this.toggle.setDefaultValue(!0):this.toggle.setDefaultValue(!1)}}
NVMToggleButtonView.prototype.pistachio=function(){return"<span>Change state</span> {{> this.toggle}}"}
NVMToggleButtonView.prototype.viewAppended=function(){NVMToggleButtonView.__super__.viewAppended.apply(this,arguments)
return this.vm.info(this.getData().vmName,this.bound("checkVMState"))}
return NVMToggleButtonView}(JView)

var NMountToggleButtonView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NMountToggleButtonView=function(_super){function NMountToggleButtonView(options,data){var _ref,_this=this
NMountToggleButtonView.__super__.constructor.call(this,{cssClass:"vm-toggle-menu",defaultLabel:null!=(_ref=options.defaultLabel)?_ref:"<span>Show in Filetree</span>"},data)
this.toggle=new KDOnOffSwitch({cssClass:"tiny vm-toggle-item",callback:function(state){var fc
fc=KD.getSingleton("finderController")
return state?fc.mountVm(_this.getData().vmName):fc.unmountVm(_this.getData().vmName)}})}__extends(NMountToggleButtonView,_super)
NMountToggleButtonView.prototype.checkMountState=function(){return this.toggle.setDefaultValue(!1)}
NMountToggleButtonView.prototype.pistachio=function(){return""+this.getOption("defaultLabel")+"{{> this.toggle}}"}
NMountToggleButtonView.prototype.viewAppended=function(){NMountToggleButtonView.__super__.viewAppended.apply(this,arguments)
return this.checkMountState()}
return NMountToggleButtonView}(JView)

var NCopyUrlView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
NCopyUrlView=function(_super){function NCopyUrlView(){var hostname,path,_this=this
NCopyUrlView.__super__.constructor.apply(this,arguments)
path=this.getData().path
hostname=FSHelper.getVMNameFromPath(path)
this.publicPath=FSHelper.isPublicPath(path)
this.inputUrlLabel=new KDLabelView({cssClass:"public-url-label",title:"Public URL",click:function(){return _this.focusAndSelectAll()}})
this.inputUrl=new KDInputView({label:this.inputUrlLabel,cssClass:"public-url-input",attributes:{readonly:!0}})
KD.getSingleton("vmController").fetchVMDomains(hostname,function(err,domains){var URI,match,pathrest,rest,subdomain,user,_i
if((null!=domains?domains.length:void 0)>0&&!err){path=FSHelper.plainPath(path)
match=path.match(/home\/(\w+)\/Web\/(.*)/)
if(!match)return
rest=3<=match.length?__slice.call(match,0,_i=match.length-2):(_i=0,[]),user=match[_i++],pathrest=match[_i++]
subdomain=/^shared-/.test(hostname)?user!==KD.nick()?"":""+user+".":""
_this.publicPath=""+subdomain+domains.first+"/"+pathrest
URI="http://"+_this.publicPath
_this.inputUrl.setValue(URI)
_this.focusAndSelectAll()
if(!_this.newPageLink)return _this.addSubView(_this.newPageLink=new CustomLinkView({cssClass:"icon-link",title:"",href:URI,target:URI,icon:{cssClass:"new-page",placement:"right"}}))}})}__extends(NCopyUrlView,_super)
NCopyUrlView.prototype.focusAndSelectAll=function(){this.inputUrl.setFocus()
return this.inputUrl.selectAll()}
NCopyUrlView.prototype.viewAppended=function(){this.setClass("copy-url-wrapper")
return NCopyUrlView.__super__.viewAppended.apply(this,arguments)}
NCopyUrlView.prototype.pistachio=function(){return this.publicPath?"{{> this.inputUrlLabel}}\n{{> this.inputUrl}}":'<div class="public-url-warning">This '+this.getData().type+" can not be reached over a public URL</div>"}
return NCopyUrlView}(JView)

var __saveToDropbox
__saveToDropbox=function(nodeView){var command,isFolder,kallback,notification,plainPath,relativePath,removeTempFile,runCommand,timestamp,title,tmpFileName,vmController
notification=null
vmController=KD.getSingleton("vmController")
plainPath=FSHelper.plainPath(nodeView.getData().path)
isFolder="folder"===nodeView.getData().type
timestamp=Date.now()
tmpFileName=isFolder?"tmp"+timestamp+".zip":"tmp"+timestamp
relativePath="/home/"+KD.nick()+"/Web/"+tmpFileName
removeTempFile=function(){return vmController.run({withArgs:"rm "+relativePath,vmName:nodeView.getData().vmName})}
runCommand=function(command){return vmController.run({withArgs:command,vmName:nodeView.getData().vmName},function(err){if(err){notification.notificationSetTitle("An error occured. Please try again.")
notification.notificationSetTimer(4e3)
return notification.setClass("error")}notification.hide()
return kallback()})}
kallback=function(){var modal
return modal=new KDBlockingModalView({title:"Upload to Dropbox",cssClass:"modal-with-text",content:'<p>Zipping your content is done. Click "Choose Folder" button to choose a folder on your Dropbox to start upload.</p>',overlay:!0,buttons:{Choose:{title:"Choose Folder",style:"modal-clean-green",callback:function(){var fileName,options
modal.destroy()
fileName=FSHelper.getFileNameFromPath(plainPath)
isFolder&&(fileName=""+fileName+".zip")
options={files:[{filename:fileName,url:"http://"+KD.getSingleton("vmController").defaultVmName+"/"+tmpFileName}],success:function(){notification.notificationSetTitle("Your file has been uploaded.")
notification.notificationSetTimer(4e3)
notification.setClass("success")
return removeTempFile()},error:function(){notification.notificationSetTitle("An error occured while uploading your file.")
notification.notificationSetTimer(4e3)
notification.setClass("error")
return removeTempFile()},cancel:function(){removeTempFile()
return notification.destroy()},progress:function(progress){notification.notificationSetTitle("Uploading to Dropbox - "+100*progress+"% done...")
return notification.show()}}
return Dropbox.save(options)}},Cancel:{style:"modal-cancel",callback:function(){modal.destroy()
return removeTempFile()}}}})}
command="mkdir -p Web ; cp "+plainPath+" "+relativePath
title="Uploading your file..."
if(isFolder){command="mkdir -p Web ; zip -r "+relativePath+" "+plainPath
title="Zipping your folder..."}notification=new KDNotificationView({title:title,type:"mini",duration:12e4})
return runCommand(command)}

var FSHelper,__hasProp={}.hasOwnProperty
FSHelper=function(){function FSHelper(){}var getFileName,parseWatcherFile
parseWatcherFile=function(vm,parentPath,file,user,treeController){var createdAt,group,mode,name,path,size,type
name=file.name,size=file.size,mode=file.mode
type=file.isBroken?"brokenLink":file.isDir?"folder":"file"
path=parentPath==="["+vm+"]/"?"["+vm+"]/"+name:""+parentPath+"/"+name
group=user
createdAt=file.time
return{size:size,user:user,group:group,createdAt:createdAt,mode:mode,type:type,parentPath:parentPath,path:path,name:name,vmName:vm,treeController:treeController}}
FSHelper.parseWatcher=function(vm,parentPath,files,treeController){var data,file,nickname,p,sortedFiles,x,z,_i,_j,_k,_len,_len1,_len2,_ref
data=[]
if(!files)return data
Array.isArray(files)||(files=[files])
sortedFiles=[]
_ref=[!0,!1]
for(_i=0,_len=_ref.length;_len>_i;_i++){p=_ref[_i]
z=function(){var _j,_len1,_results
_results=[]
for(_j=0,_len1=files.length;_len1>_j;_j++){x=files[_j]
x.isDir===p&&_results.push(x)}return _results}().sort(function(x,y){return x.name.toLowerCase()>y.name.toLowerCase()})
for(_j=0,_len1=z.length;_len1>_j;_j++){x=z[_j]
sortedFiles.push(x)}}nickname=KD.nick()
for(_k=0,_len2=sortedFiles.length;_len2>_k;_k++){file=sortedFiles[_k]
data.push(FSHelper.createFile(parseWatcherFile(vm,parentPath,file,nickname,treeController)))}return data}
FSHelper.folderOnChange=function(vm,path,change,treeController){var file,node,npath,_ref,_results
if(treeController){file=this.parseWatcher(vm,path,change.file,treeController).first
switch(change.event){case"added":return treeController.addNode(file)
case"removed":_ref=treeController.nodes
_results=[]
for(npath in _ref)if(__hasProp.call(_ref,npath)){node=_ref[npath]
if(npath===file.path){treeController.removeNodeView(node)
break}_results.push(void 0)}return _results}}}
FSHelper.plainPath=function(path){return path.replace(/\[.*\]/,"")}
FSHelper.getVMNameFromPath=function(path){var _ref
return null!=(_ref=/\[([^\]]+)\]/g.exec(path))?_ref[1]:void 0}
FSHelper.minimizePath=function(path){return this.plainPath(path).replace(RegExp("^\\/home\\/"+KD.nick()),"~")}
FSHelper.grepInDirectory=function(keyword,directory,callback,matchingLinesCount){var command
null==matchingLinesCount&&(matchingLinesCount=3)
command="grep "+keyword+" '"+directory+"' -n -r -i -I -H -T -C"+matchingLinesCount
return KD.getSingleton("vmController").run(command,function(err,res){var chunk,chunks,isMatchedLine,line,lineNumber,lineNumberWithPath,lines,path,result,_i,_j,_len,_len1,_ref
result={}
if(res){chunks=res.split("--\n")
for(_i=0,_len=chunks.length;_len>_i;_i++){chunk=chunks[_i]
lines=chunk.split("\n")
for(_j=0,_len1=lines.length;_len1>_j;_j++){line=lines[_j]
if(line){_ref=line.split("	"),lineNumberWithPath=_ref[0],line=_ref[1]
lineNumber=lineNumberWithPath.match(/\d+$/)[0]
path=lineNumberWithPath.split(lineNumber)[0].trim()
path=path.substring(0,path.length-1)
isMatchedLine=":"===line.charAt(1)
line=line.substring(2,line.length)
result[path]||(result[path]={})
result[path][lineNumber]={lineNumber:lineNumber,line:line,isMatchedLine:isMatchedLine,path:path}}}}}return"function"==typeof callback?callback(result):void 0})}
FSHelper.exists=function(path,vmName,callback){null==callback&&(callback=noop)
return this.getInfo(path,vmName,function(err,res){return callback(err,null!=res)})}
FSHelper.getInfo=function(path,vmName,callback){null==callback&&(callback=noop)
return KD.getSingleton("vmController").run({method:"fs.getInfo",vmName:vmName,withArgs:{path:path}},callback)}
FSHelper.glob=function(pattern,vmName,callback){var _ref
"function"==typeof vmName&&(_ref=[callback,vmName],vmName=_ref[0],callback=_ref[1])
return KD.getSingleton("vmController").run({method:"fs.glob",vmName:vmName,withArgs:{pattern:pattern}},callback)}
FSHelper.ensureNonexistentPath=function(path,vmName,callback){null==callback&&(callback=noop)
return KD.getSingleton("vmController").run({method:"fs.ensureNonexistentPath",vmName:vmName,withArgs:{path:path}},callback)}
FSHelper.registry={}
FSHelper.resetRegistry=function(){return this.registry={}}
FSHelper.register=function(file){this.setFileListeners(file)
return this.registry[file.path]=file}
FSHelper.unregister=function(path){return delete this.registry[path]}
FSHelper.unregisterVmFiles=function(vmName){var file,path,_ref,_results
_ref=this.registry
_results=[]
for(path in _ref)if(__hasProp.call(_ref,path)){file=_ref[path]
0===path.indexOf("["+vmName+"]")&&_results.push(this.unregister(path))}return _results}
FSHelper.updateInstance=function(fileData){var prop,value,_results
_results=[]
for(prop in fileData)if(__hasProp.call(fileData,prop)){value=fileData[prop]
_results.push(this.registry[fileData.path][prop]=value)}return _results}
FSHelper.setFileListeners=function(file){return file.on("fs.job.finished",function(){})}
FSHelper.getFileNameFromPath=getFileName=function(path){return path.split("/").pop()}
FSHelper.trimExtension=function(path){var name
name=getFileName(path)
return name.split(".").shift()}
FSHelper.getParentPath=function(path){var parentPath
"/"===path.substr(-1)&&(path=path.substr(0,path.length-1))
parentPath=path.split("/")
parentPath.pop()
return parentPath.join("/")}
FSHelper.createFileFromPath=function(path,type){var name,parentPath,vmName
null==type&&(type="file")
if(!path)return warn("pass a path to create a file instance")
vmName=this.getVMNameFromPath(path)||null
vmName&&(path=this.plainPath(path))
parentPath=this.getParentPath(path)
name=this.getFileNameFromPath(path)
return this.createFile({path:path,parentPath:parentPath,name:name,type:type,vmName:vmName})}
FSHelper.createFile=function(options){var constructor,instance
if(!(options&&options.type&&options.path))return warn("pass a path and type to create a file instance")
null==options.vmName&&(options.vmName=KD.getSingleton("vmController").defaultVmName)
if(this.registry[options.path]){instance=this.registry[options.path]
this.updateInstance(options)}else{constructor=function(){switch(options.type){case"vm":return FSVm
case"folder":return FSFolder
case"mount":return FSMount
case"symLink":return FSFolder
case"brokenLink":return FSBrokenLink
default:return FSFile}}()
instance=new constructor(options)
this.register(instance)}return instance}
FSHelper.createRecursiveFolder=function(_arg,callback){var path,vmName
path=_arg.path,vmName=_arg.vmName
null==callback&&(callback=noop)
return path?KD.getSingleton("vmController").run({method:"fs.createDirectory",withArgs:{recursive:!0,path:path},vmName:vmName},callback):warn("Pass a path to create folders recursively")}
FSHelper.isValidFileName=function(name){return/^([a-zA-Z]:\\)?[^\x00-\x1F"<>\|:\*\?/]+$/.test(name)}
FSHelper.isEscapedPath=function(path){return/^\s\"/.test(path)}
FSHelper.escapeFilePath=function(name){return FSHelper.plainPath(name.replace(/\'/g,"\\'").replace(/\"/g,'\\"').replace(/\ /g,"\\ "))}
FSHelper.unescapeFilePath=function(name){return name.replace(/^(\s\")/g,"").replace(/(\"\s)$/g,"").replace(/\\\'/g,"'").replace(/\\"/g,'"')}
FSHelper.isPublicPath=function(path){return/^\/home\/.*\/Web\//.test(FSHelper.plainPath(path))}
FSHelper.convertToRelative=function(path){return path.replace(/^\//,"").replace(/(.+?)\/?$/,"$1/")}
FSHelper.isUnwanted=function(path,isFile){var dummyFilePatterns,dummyFolderPatterns
null==isFile&&(isFile=!1)
dummyFilePatterns=/\.DS_Store|Thumbs.db/
dummyFolderPatterns=/\.git|__MACOSX/
return isFile?dummyFilePatterns.test(path):dummyFolderPatterns.test(path)}
FSHelper.s3={get:function(name){return""+KD.config.uploadsUri+"/"+KD.whoami().getId()+"/"+name},upload:function(name,content,callback){var vmController
vmController=KD.getSingleton("vmController")
return vmController.run({method:"s3.store",withArgs:{name:name,content:content}},function(err){return err?callback(err):callback(null,FSHelper.s3.get(name))})},remove:function(name,callback){var vmController
vmController=KD.getSingleton("vmController")
return vmController.run({method:"s3.delete",withArgs:{name:name}},callback)}}
FSHelper.getPathHierarchy=function(fullPath){var node,nodes,path,queue,subPath,vmName,_ref
_ref=KD.getPathInfo(fullPath),path=_ref.path,vmName=_ref.vmName
path=path.replace(/^~/,"/home/"+KD.nick())
nodes=path.split("/").filter(function(node){return!!node})
queue=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=nodes.length;_len>_i;_i++){node=nodes[_i]
subPath=nodes.join("/")
nodes.pop()
_results.push("["+vmName+"]/"+subPath)}return _results}()
return queue.reverse()}
FSHelper.chunkify=function(data,chunkSize){var chunks
chunks=[]
for(;data;){if(data.length<chunkSize){chunks.push(data)
break}chunks.push(data.substr(0,chunkSize))
data=data.substr(chunkSize)}return chunks}
return FSHelper}()
KD.classes.FSHelper=FSHelper

var FSWatcher,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FSWatcher=function(_super){function FSWatcher(options){null==options&&(options={})
null==options.recursive&&(options.recursive=!0)
null==options.ignoreTempChanges&&(options.ignoreTempChanges=!0)
FSWatcher.__super__.constructor.call(this,options)
this.path=this.getOption("path")}__extends(FSWatcher,_super)
FSWatcher.watchers={}
FSWatcher.registerWatcher=function(path,stopWatching){return this.watchers[path]={stop:stopWatching}}
FSWatcher.stopAllWatchers=function(){var path,watcher,_ref
_ref=this.watchers
for(path in _ref)if(__hasProp.call(_ref,path)){watcher=_ref[path]
watcher.stop()}return this.watchers={}}
FSWatcher.stopWatching=function(pathToStop){var path,watcher,_ref,_results
_ref=this.watchers
_results=[]
for(path in _ref)if(__hasProp.call(_ref,path)){watcher=_ref[path]
if(0===path.indexOf(pathToStop)){watcher.stop()
_results.push(delete this.watchers[path])}}return _results}
FSWatcher.prototype.watch=function(callback){var vmController,_this=this
vmController=KD.getSingleton("vmController")
this.vmName||(this.vmName=this.getOption("vmName")||vmController.defaultVmName)
if(!this.vmName)return"function"==typeof callback?callback({message:"No VM provided!"}):void 0
FSWatcher.stopWatching(this.getFullPath())
return vmController.run({method:"fs.readDirectory",vmName:this.vmName,withArgs:{onChange:function(change){return _this.changeHappened(_this.path,change)},path:FSHelper.plainPath(this.path),watchSubdirectories:this.getOption("recursive")}},function(err,response){var files
if(!err&&(null!=response?response.files:void 0)){files=FSHelper.parseWatcher(_this.vmName,_this.path,response.files)
FSWatcher.registerWatcher(_this.getFullPath(),response.stopWatching)
return"function"==typeof callback?callback(err,files):void 0}return"function"==typeof callback?callback(err,null):void 0})}
FSWatcher.prototype.fileAdded=function(){}
FSWatcher.prototype.folderAdded=function(){}
FSWatcher.prototype.fileRemoved=function(){}
FSWatcher.prototype.fileChanged=function(){}
FSWatcher.prototype.changeHappened=function(path,change){if(!this.getOption("ignoreTempChanges")||!/^\.|\~$/.test(change.file.name))switch(change.event){case"added":return change.file.isDir?this.folderAdded(change):this.fileAdded(change)
case"removed":return this.fileRemoved(change)
case"attributesChanged":return this.fileChanged(change)}}
FSWatcher.prototype.stopWatching=function(){return FSWatcher.stopWatching(this.getFullPath())}
FSWatcher.prototype.getFullPath=function(){return"["+this.vmName+"]"+this.path}
return FSWatcher}(KDObject)

var FSItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
FSItem=function(_super){function FSItem(options){var key,value
for(key in options)if(__hasProp.call(options,key)){value=options[key]
this[key]=value}FSItem.__super__.constructor.apply(this,arguments)
this.vmController=KD.getSingleton("vmController")}var escapeFilePath
__extends(FSItem,_super)
escapeFilePath=FSHelper.escapeFilePath
FSItem.create=function(_arg,callback){var path,treeController,type,vmName
path=_arg.path,type=_arg.type,vmName=_arg.vmName,treeController=_arg.treeController
return FSHelper.ensureNonexistentPath(path,vmName,function(err,response){if(err){"function"==typeof callback&&callback(err,response)
return warn(err)}return KD.getSingleton("vmController").run({method:"folder"===type?"fs.createDirectory":"fs.writeFile",vmName:vmName,withArgs:{path:FSHelper.plainPath(response),content:"",donotoverwrite:!0}},function(err){var file
err?warn(err):file=FSHelper.createFile({path:response,type:type,vmName:vmName,treeController:treeController})
return"function"==typeof callback?callback(err,file):void 0})})}
FSItem.copy=function(sourceItem,targetItem,callback){var targetPath,vmName
sourceItem.emit("fs.job.started")
targetPath=FSHelper.plainPath(""+targetItem.path+"/"+sourceItem.name)
vmName=targetItem.vmName||FSHelper.getVMNameFromPath(targetPath)
return FSHelper.ensureNonexistentPath(targetPath,vmName,function(err,response){if(err){warn(err)
return"function"==typeof callback?callback(err,response):void 0}return KD.getSingleton("vmController").run({vmName:vmName,withArgs:"cp -R "+escapeFilePath(sourceItem.path)+" "+escapeFilePath(response)},function(err){var file
sourceItem.emit("fs.job.finished")
err?warn(err):file=FSHelper.createFileFromPath(""+targetItem.path+"/"+sourceItem.name,sourceItem.type)
return"function"==typeof callback?callback(err,file):void 0})})}
FSItem.move=function(sourceItem,targetItem,callback){var targetPath,vmName
sourceItem.emit("fs.job.started")
targetPath=FSHelper.plainPath(""+targetItem.path+"/"+sourceItem.name)
vmName=targetItem.vmName||FSHelper.getVMNameFromPath(targetPath)
return FSHelper.ensureNonexistentPath(targetPath,vmName,function(err,response){if(err){warn(err)
return"function"==typeof callback?callback(err,response):void 0}return KD.getSingleton("vmController").run({vmName:vmName,withArgs:"mv "+escapeFilePath(sourceItem.path)+" "+escapeFilePath(response)},function(err){var file
sourceItem.emit("fs.job.finished")
err?warn(err):file=FSHelper.createFileFromPath(targetPath,sourceItem.type)
return"function"==typeof callback?callback(err,file):void 0})})}
FSItem.compress=function(file,type,callback){var path,vmName
file.emit("fs.job.started")
path=FSHelper.plainPath(""+file.path+"."+type)
vmName=file.vmName||FSHelper.getVMNameFromPath(path)
return FSHelper.ensureNonexistentPath(path,vmName,function(err,response){var command
if(err){warn(err)
return"function"==typeof callback?callback(err,response):void 0}command=function(){switch(type){case"tar.gz":return"tar -pczf "+escapeFilePath(response)+" "+escapeFilePath(file.path)
default:return"zip -r "+escapeFilePath(response)+" "+escapeFilePath(file.path)}}()
return KD.getSingleton("vmController").run({vmName:vmName,withArgs:command},function(err,res){file.emit("fs.job.finished")
err&&warn(err)
return"function"==typeof callback?callback(err,res):void 0})})}
FSItem.extract=function(file,callback){var command,extractFolder,path,tarPattern,vmName,zipPattern
tarPattern=/\.tar\.gz$/
zipPattern=/\.zip$/
file.emit("fs.job.started")
path=FSHelper.plainPath(file.path)
vmName=file.vmName||FSHelper.getVMNameFromPath(path)
command=tarPattern.test(file.name)?(extractFolder=file.path.replace(tarPattern,""),"cd "+escapeFilePath(file.parentPath)+";mkdir -p "+escapeFilePath(extractFolder)+";tar -zxf "+escapeFilePath(file.name)+" -C "+escapeFilePath(extractFolder)):zipPattern.test(file.name)?(extractFolder=file.path.replace(zipPattern,""),"cd "+escapeFilePath(file.parentPath)+";unzip -o "+escapeFilePath(file.name)+" -d "+escapeFilePath(extractFolder)):void 0
return command?KD.getSingleton("vmController").run({vmName:vmName,withArgs:command},function(err){var folder
file.emit("fs.job.finished")
err&&warn(err)
folder=FSHelper.createFileFromPath(extractFolder,"folder")
return"function"==typeof callback?callback(err,folder):void 0}):"function"==typeof callback?callback(!0):void 0}
FSItem.getFileExtension=function(path){var extension,fileName,name,_ref
fileName=path||""
_ref=fileName.split("."),name=_ref[0],extension=2<=_ref.length?__slice.call(_ref,1):[]
return extension=0===extension.length?"":extension.last}
FSItem.getFileType=function(extension){var ext,fileType,set,type,_extension_sets,_i,_len
fileType=null
_extension_sets={code:["php","pl","py","jsp","asp","htm","html","phtml","shtml","sh","cgi","htaccess","fcgi","wsgi","mvc","xml","sql","rhtml","js","json","coffee","css","styl","sass","erb"],text:["txt","doc","rtf","csv","docx","pdf"],archive:["zip","gz","bz2","tar","7zip","rar","gzip","bzip2","arj","cab","chm","cpio","deb","dmg","hfs","iso","lzh","lzma","msi","nsis","rpm","udf","wim","xar","z","jar","ace","7z","uue"],image:["png","gif","jpg","jpeg","bmp","svg","psd","qt","qtif","qif","qti","tif","tiff","aif","aiff"],video:["avi","mp4","h264","mov","mpg","ra","ram","mpg","mpeg","m4a","3gp","wmv","flv","swf","wma","rm","rpm","rv","webm"],sound:["aac","au","gsm","mid","midi","snd","wav","3g2","mp3","asx","asf"],app:["kdapp"]}
for(type in _extension_sets)if(__hasProp.call(_extension_sets,type)){set=_extension_sets[type]
for(_i=0,_len=set.length;_len>_i;_i++){ext=set[_i]
if(extension===ext){fileType=type
break}}if(fileType)break}return fileType||"unknown"}
FSItem.isHidden=function(name){return/^\./.test(name)}
FSItem.prototype.getExtension=function(){return FSItem.getFileExtension(this.name)}
FSItem.prototype.isHidden=function(){return FSItem.isHidden(this.name)}
FSItem.prototype.exists=function(callback){null==callback&&(callback=noop)
return FSHelper.exists(this.path,this.vmName,callback)}
FSItem.prototype.stat=function(callback){null==callback&&(callback=noop)
return FSHelper.getInfo(this.path,this.vmName,callback)}
FSItem.prototype.remove=function(callback,recursive){var _this=this
null==recursive&&(recursive=!1)
this.emit("fs.delete.started")
return KD.getSingleton("vmController").run({method:"fs.remove",vmName:this.vmName,withArgs:{path:FSHelper.plainPath(this.path),recursive:recursive}},function(err,response){callback(err,response)
if(err)return warn(err)
_this.emit("fs.delete.finished")
return _this.destroy()})}
FSItem.prototype.rename=function(newName,callback){var newPath,_this=this
newPath=FSHelper.plainPath(""+this.parentPath+"/"+newName)
this.emit("fs.job.started")
return FSHelper.ensureNonexistentPath(newPath,this.vmName,function(err,response){if(err){warn(err)
return"function"==typeof callback?callback(err,response):void 0}return KD.getSingleton("vmController").run({method:"fs.rename",vmName:_this.vmName,withArgs:{oldpath:FSHelper.plainPath(_this.path),newpath:newPath}},function(err){if(err)warn(err)
else{_this.path=newPath
_this.name=newName}"function"==typeof callback&&callback(err,_this)
return _this.emit("fs.job.finished")})})}
FSItem.prototype.chmod=function(options,callback){var permissions,recursive,_this=this
recursive=options.recursive,permissions=options.permissions
if(null==permissions)return"function"==typeof callback?callback("no permissions passed"):void 0
this.emit("fs.job.started")
return KD.getSingleton("vmController").run({method:"fs.setPermissions",vmName:this.vmName,withArgs:{path:FSHelper.plainPath(this.path),recursive:recursive,mode:permissions}},function(err,res){_this.emit("fs.job.finished")
err?warn(err):_this.mode=permissions
return"function"==typeof callback?callback(err,res):void 0})}
return FSItem}(KDObject)

var FSFile,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FSFile=function(_super){function FSFile(){var _this=this
FSFile.__super__.constructor.apply(this,arguments)
this.on("file.requests.saveAs",function(contents,name,parentPath){return _this.saveAs(contents,name,parentPath)})
this.on("file.requests.save",function(contents){return _this.save(contents)})
this.localStorage=KD.getSingleton("localStorageController").storage("Finder")
this.fileInfo=this.getLocalFileInfo()}__extends(FSFile,_super)
FSFile.prototype.getLocalFileInfo=function(){return this.localStorage.getValue(btoa(KD.utils.utf8Encode(FSHelper.plainPath(this.path))))||{}}
FSFile.prototype.setLocalFileInfo=function(data){var key,value
null==data&&(data={})
for(key in data)if(__hasProp.call(data,key)){value=data[key]
this.fileInfo[key]=value}return this.localStorage.setValue(btoa(KD.utils.utf8Encode(FSHelper.plainPath(this.path))),this.fileInfo)}
FSFile.prototype.removeLocalFileInfo=function(){return this.localStorage.unsetKey(btoa(KD.utils.utf8Encode(FSHelper.plainPath(this.path))))}
FSFile.prototype.fetchContentsBinary=function(callback){return this.fetchContents(callback,!1)}
FSFile.prototype.fetchContents=function(callback,useEncoding){var _this=this
null==useEncoding&&(useEncoding=!0)
this.emit("fs.job.started")
return this.vmController.run({method:"fs.readFile",vmName:this.vmName,withArgs:{path:FSHelper.plainPath(this.path)}},function(err,response){var content
if(err)warn(err)
else{content=atob(response.content)
useEncoding&&(content=KD.utils.utf8Decode(content))}callback.call(_this,err,content)
return _this.emit("fs.job.finished",err,content)})}
FSFile.prototype.saveAs=function(contents,name,parentPath,callback){var newPath,_this=this
parentPath&&(this.vmName=FSHelper.getVMNameFromPath(parentPath))
newPath=FSHelper.plainPath(""+parentPath+"/"+name)
this.emit("fs.saveAs.started")
return FSHelper.ensureNonexistentPath(""+newPath,this.vmName,function(err,path){var newFile
if(err){"function"==typeof callback&&callback(err,path)
return warn(err)}newFile=FSHelper.createFile({type:"file",path:path,vmName:_this.vmName})
return newFile.save(contents,function(err){return err?warn(err):_this.emit("fs.saveAs.finished",newFile,_this)})})}
FSFile.prototype.append=function(contents,callback){var content,_this=this
this.emit("fs.append.started")
content=btoa(contents)
return this.vmController.run({method:"fs.writeFile",vmName:this.vmName,withArgs:{path:FSHelper.plainPath(this.path),content:content,append:!0}},function(err,res){err&&warn(err)
_this.emit("fs.append.finished",err,res)
return"function"==typeof callback?callback(err,res):void 0})}
FSFile.createChunkQueue=function(data,chunkSize,skip){var chunk,chunks,index,isSkip,queue,_i,_len
null==chunkSize&&(chunkSize=1048576)
null==skip&&(skip=0)
if(data){chunks=FSHelper.chunkify(data,chunkSize)
queue=[]
for(index=_i=0,_len=chunks.length;_len>_i;index=++_i){chunk=chunks[index]
isSkip=skip>index
queue.push({content:isSkip?void 0:btoa(chunk),skip:isSkip,append:queue.length>0?!0:void 0})}return queue}}
FSFile.prototype.saveBinary=function(contents,callback){var chunkQueue,info,iterateChunks,total,_this=this
info=this.getLocalFileInfo()
chunkQueue=FSFile.createChunkQueue(contents,null,info.lastUploadedChunk)
total=chunkQueue.length
this.setLocalFileInfo({totalChunks:total})
this.on("ChunkUploaded",function(response){var loaded,percent
loaded=total-chunkQueue.length
percent=100*loaded/total
_this.setLocalFileInfo({lastUploadedChunk:loaded})
return"function"==typeof callback?callback(null,response,{total:total,loaded:loaded,percent:percent}):void 0})
this.once("AllChunksUploaded",function(){_this.off("ChunkUploaded")
_this.removeLocalFileInfo()
return"function"==typeof callback?callback(null,{finished:!0}):void 0})
this.once("AbortRequested",function(){_this.abortRequested=!0
return"function"==typeof callback?callback(null,{abort:!0}):void 0})
iterateChunks=function(){var append,content,next,skip
chunkQueue.length||_this.emit("AllChunksUploaded")
next=chunkQueue.shift()
if(next&&!_this.abortRequested){skip=next.skip,content=next.content,append=next.append
if(!skip)return _this.vmController.run({method:"fs.writeFile",vmName:_this.vmName,withArgs:{path:FSHelper.plainPath(_this.path),content:content,append:append}},function(err,res){if(err)return"function"==typeof callback?callback(err):void 0
_this.emit("ChunkUploaded",res)
return iterateChunks()})
callback(null,{},{percent:100*info.lastUploadedChunk/info.totalChunks})
iterateChunks()}}
return chunkQueue.length>0?iterateChunks():void 0}
FSFile.prototype.abort=function(){return this.emit("AbortRequested")}
FSFile.prototype.save=function(contents,callback,useEncoding){var content,_this=this
null==useEncoding&&(useEncoding=!0)
this.emit("fs.save.started")
useEncoding&&(contents=KD.utils.utf8Encode(contents))
content=btoa(contents)
return this.vmController.run({method:"fs.writeFile",vmName:this.vmName,withArgs:{path:FSHelper.plainPath(this.path),content:content}},function(err,res){err&&warn(err)
_this.emit("fs.save.finished",err,res)
return"function"==typeof callback?callback(err,res):void 0})}
return FSFile}(FSItem)

var FSFolder,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FSFolder=function(_super){function FSFolder(){_ref=FSFolder.__super__.constructor.apply(this,arguments)
return _ref}__extends(FSFolder,_super)
FSFolder.prototype.fetchContents=function(callback,dontWatch){var treeController,_this=this
null==dontWatch&&(dontWatch=!0)
treeController=this.getOptions().treeController
this.emit("fs.job.started")
return this.vmController.run({method:"fs.readDirectory",vmName:this.vmName,withArgs:{onChange:dontWatch?null:function(change){return FSHelper.folderOnChange(_this.vmName,_this.path,change,treeController)},path:FSHelper.plainPath(this.path)}},function(err,response){var files
if(!err&&(null!=response?response.files:void 0)){files=FSHelper.parseWatcher(_this.vmName,_this.path,response.files,treeController)
_this.registerWatcher(response)
_this.emit("fs.job.finished",err,files)}else _this.emit("fs.job.finished",err)
return"function"==typeof callback?callback(err,files):void 0})}
FSFolder.prototype.save=function(callback){var _this=this
this.emit("fs.save.started")
return this.vmController.run({vmName:this.vmName,method:"fs.createDirectory",withArgs:{path:FSHelper.plainPath(this.path)}},function(err,res){err&&warn(err)
_this.emit("fs.save.finished",err,res)
return"function"==typeof callback?callback(err,res):void 0})}
FSFolder.prototype.saveAs=function(callback){log("Not implemented yet.")
return"function"==typeof callback?callback(null):void 0}
FSFolder.prototype.remove=function(callback){var _this=this
this.off("fs.delete.finished")
this.on("fs.delete.finished",function(){var finder
finder=KD.getSingleton("finderController")
return finder.stopWatching(_this.path)})
return FSFolder.__super__.remove.call(this,callback,!0)}
FSFolder.prototype.registerWatcher=function(response){var finder
this.stopWatching=response.stopWatching
finder=KD.getSingleton("finderController")
return finder?this.stopWatching?finder.registerWatcher(this.path,this.stopWatching):void 0:void 0}
return FSFolder}(FSFile)

var FSMount,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FSMount=function(_super){function FSMount(){_ref=FSMount.__super__.constructor.apply(this,arguments)
return _ref}__extends(FSMount,_super)
return FSMount}(FSFolder)

var FSBrokenLink,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FSBrokenLink=function(_super){function FSBrokenLink(){_ref=FSBrokenLink.__super__.constructor.apply(this,arguments)
return _ref}__extends(FSBrokenLink,_super)
return FSBrokenLink}(FSItem)

var FSVm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FSVm=function(_super){function FSVm(){_ref=FSVm.__super__.constructor.apply(this,arguments)
return _ref}__extends(FSVm,_super)
return FSVm}(FSFolder)

var AppsWatcher,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
AppsWatcher=function(_super){function AppsWatcher(options){null==options&&(options={})
options.path="~/Applications"
AppsWatcher.__super__.constructor.call(this,options)
this._trackedApps=[]}var getAppName,isInKdApp,isKdApp,isManifest,throttle
__extends(AppsWatcher,_super)
AppsWatcher.prototype.folderAdded=function(change){var app,_this=this
if(isKdApp(change)){app=getAppName(change)
return throttle(function(){return _this.emit("NewAppIsAdded",app,change)})}}
AppsWatcher.prototype.fileRemoved=function(change){var app,_app,_this=this
if(isKdApp(change)||isManifest(change)){app=getAppName(change)
this._trackedApps=function(){var _i,_len,_ref,_results
_ref=this._trackedApps
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){_app=_ref[_i]
_app!==app&&_results.push(_app)}return _results}.call(this)
return throttle(function(){return _this.emit("AppIsRemoved",app,change)})}if(isInKdApp(change)){app=getAppName(change)
return throttle(function(){return _this.emit("FileIsRemoved",app,change)})}}
AppsWatcher.prototype.fileAdded=function(change){var app,_this=this
if(isInKdApp(change)){app=getAppName(change)
if(!isManifest(change))return throttle(function(){return _this.emit("FileIsAdded",app,change)})
if(__indexOf.call(this._trackedApps,app)<0){this._trackedApps.push(app)
return throttle(function(){return _this.emit("NewAppIsAdded",app,change)})}}}
AppsWatcher.prototype.fileChanged=function(change){var app,_this=this
if(isInKdApp(change)){app=getAppName(change)
if(!isManifest(change))return throttle(function(){return _this.emit("FileHasChanged",app,change)})
if(__indexOf.call(this._trackedApps,app)>=0)return throttle(function(){return _this.emit("ManifestHasChanged",app,change)})}}
isKdApp=function(change){return/\.kdapp$/.test(change.file.fullPath)}
isInKdApp=function(change){return/Applications\/.*\.kdapp/.test(change.file.fullPath)}
isManifest=function(change){return/manifest\.json$/.test(change.file.fullPath)}
getAppName=function(change){var _ref
return null!=(_ref=change.file.fullPath.match(/Applications\/([^\/]+)\.kdapp/))?_ref[1]:void 0}
throttle=function(cb){return KD.utils.throttle(cb,300)()}
return AppsWatcher}(FSWatcher)

//@ sourceMappingURL=/js/__app.finder.0.0.1.js.map