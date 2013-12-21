var EnvironmentsAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentsAppController=function(_super){function EnvironmentsAppController(options,data){null==options&&(options={})
options.view=new EnvironmentsMainView({cssClass:"environments split-layout"})
options.appInfo={name:"Environments"}
EnvironmentsAppController.__super__.constructor.call(this,options,data)}__extends(EnvironmentsAppController,_super)
KD.registerAppClass(EnvironmentsAppController,{name:"Environments",route:"/:name?/Environments",hiddenHandle:!0,behavior:"application"})
return EnvironmentsAppController}(AppController)

var EnvironmentsMainView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentsMainView=function(_super){function EnvironmentsMainView(){_ref=EnvironmentsMainView.__super__.constructor.apply(this,arguments)
return _ref}__extends(EnvironmentsMainView,_super)
EnvironmentsMainView.prototype.viewAppended=function(){this.addSubView(new HeaderViewSection({type:"big",title:"Environments"}))
return this.addSubView(new EnvironmentsMainScene)}
return EnvironmentsMainView}(JView)

var ColorSelection,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ColorSelection=function(_super){function ColorSelection(options){null==options&&(options={})
options.cssClass="environments-cs-container"
null==options.instant&&(options.instant=!0)
options.colors=["#a2a2a2","#ffa800","#e13986","#39bce1","#0018ff","#e24d45","#34b700","#a861ff"]
ColorSelection.__super__.constructor.call(this,options)}__extends(ColorSelection,_super)
ColorSelection.prototype.createColors=function(){var color,colorBox,colorBoxes,_i,_len,_ref,_results
colorBoxes=[]
_ref=this.getOption("colors")
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){color=_ref[_i]
this.addSubView(colorBox=new KDCustomHTMLView({cssClass:"environments-cs-color",color:color,attributes:{style:"background-color : "+color},click:function(){var box,_j,_len1
this.parent.options.selectedColor=this.getOption("color")
this.parent.emit("ColorChanged",this.parent.getOption("selectedColor"))
for(_j=0,_len1=colorBoxes.length;_len1>_j;_j++){box=colorBoxes[_j]
box.unsetClass("selected")}return this.setClass("selected")}}))
colorBoxes.push(colorBox)
color===this.getOption("selectedColor")?_results.push(colorBox.setClass("selected")):_results.push(void 0)}return _results}
ColorSelection.prototype.viewAppended=function(){return this.createColors()}
return ColorSelection}(KDCustomHTMLView)

var EnvironmentContainer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentContainer=function(_super){function EnvironmentContainer(options,data){var title,_ref,_this=this
null==options&&(options={})
options.cssClass="environments-container"
options.bind="scroll mousewheel wheel"
EnvironmentContainer.__super__.constructor.call(this,options,data)
title=this.getOption("title")
this.header=new KDHeaderView({type:"medium",title:title})
this.itemHeight=null!=(_ref=options.itemHeight)?_ref:40
this.on("DataLoaded",function(){return _this._dataLoaded=!0})
this.newItemPlus=new KDCustomHTMLView({cssClass:"new-item-plus",partial:"<i></i><span>Add new</span>",click:function(){return _this.once("transitionend",_this.emit("PlusButtonClicked"))}})
this.newItemPlus.bindTransitionEnd()
this.loader=new KDLoaderView({cssClass:"new-item-loader hidden",size:{height:20,width:20}})}__extends(EnvironmentContainer,_super)
EnvironmentContainer.prototype.viewAppended=function(){var _ref
EnvironmentContainer.__super__.viewAppended.apply(this,arguments)
this.addSubView(this.header)
this.header.addSubView(this.newItemPlus)
this.header.addSubView(this.loader)
return _ref=this.parent,this.appStorage=_ref.appStorage,_ref}
EnvironmentContainer.prototype.showLoader=function(){this.newItemPlus.hide()
return this.loader.show()}
EnvironmentContainer.prototype.hideLoader=function(){this.newItemPlus.show()
return this.loader.hide()}
EnvironmentContainer.prototype.addDia=function(diaObj,pos){var _this=this
pos={x:20,y:60+this.diaCount()*(this.itemHeight+10)}
EnvironmentContainer.__super__.addDia.call(this,diaObj,pos)
diaObj.on("KDObjectWillBeDestroyed",this.bound("updatePositions"))
return diaObj.on("KDObjectWillBeDestroyed",function(){return _this.emit("itemRemoved")})}
EnvironmentContainer.prototype.updatePositions=function(){var dia,index,_key,_ref,_results
index=0
_ref=this.dias
_results=[]
for(_key in _ref){dia=_ref[_key]
dia.setX(20)
dia.setY(60+50*index)
_results.push(index++)}return _results}
EnvironmentContainer.prototype.diaCount=function(){return Object.keys(this.dias).length}
EnvironmentContainer.prototype.mouseWheel=function(e){this.emit("UpdateScene")
return EnvironmentContainer.__super__.mouseWheel.call(this,e)}
EnvironmentContainer.prototype.loadItems=function(){return this.removeAllItems()}
return EnvironmentContainer}(KDDiaContainer)

var EnvironmentDomainContainer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
EnvironmentDomainContainer=function(_super){function EnvironmentDomainContainer(options,data){null==options&&(options={})
options.itemClass=EnvironmentDomainItem
options.title="Domains"
EnvironmentDomainContainer.__super__.constructor.call(this,options,data)}__extends(EnvironmentDomainContainer,_super)
EnvironmentDomainContainer.prototype.loadItems=function(){var _this=this
return KD.whoami().fetchDomains(function(err,domains){var addedCount
if(err||0===domains.length){_this.emit("DataLoaded")
if(err)return warn("Failed to fetch domains",err)}addedCount=0
return KD.singletons.vmController.fetchGroupVMs(function(err,vms){_this.removeAllItems()
return domains.forEach(function(domain){var vm,_i,_len,_ref
if(KD.checkFlag("nostradamus")&&!err){_ref=domain.hostnameAlias
for(_i=0,_len=_ref.length;_len>_i;_i++){vm=_ref[_i]
if(__indexOf.call(vms,vm)<0){domain=null
break}}}domain&&_this.addItem({title:domain.domain,description:$.timeago(domain.createdAt),activated:!0,aliases:domain.hostnameAlias,domain:domain})
addedCount++
return addedCount===domains.length?_this.emit("DataLoaded"):void 0})})})}
return EnvironmentDomainContainer}(EnvironmentContainer)

var EnvironmentRuleContainer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentRuleContainer=function(_super){function EnvironmentRuleContainer(options,data){null==options&&(options={})
options.itemClass=EnvironmentRuleItem
options.title="Rules"
EnvironmentRuleContainer.__super__.constructor.call(this,options,data)}__extends(EnvironmentRuleContainer,_super)
EnvironmentRuleContainer.prototype.loadItems=function(){var dummyRules,rule,_i,_len
EnvironmentRuleContainer.__super__.loadItems.apply(this,arguments)
dummyRules=[{title:"Allow Turkey",description:"allow from 5.2.80.0/21"},{title:"Block China",description:"deny from 65.19.146.2 220.248.0.0/14"},{title:"Allow Gokmen's Machine",description:"allow from 1.2.3.4"}]
for(_i=0,_len=dummyRules.length;_len>_i;_i++){rule=dummyRules[_i]
this.addItem(rule)}return this.emit("DataLoaded")}
return EnvironmentRuleContainer}(EnvironmentContainer)

var EnvironmentMachineContainer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentMachineContainer=function(_super){function EnvironmentMachineContainer(options,data){null==options&&(options={})
options.itemClass=EnvironmentMachineItem
options.title="Machines"
options.itemHeight=50
EnvironmentMachineContainer.__super__.constructor.call(this,options,data)}__extends(EnvironmentMachineContainer,_super)
EnvironmentMachineContainer.prototype.loadItems=function(){var cmd,vmc,_this=this
EnvironmentMachineContainer.__super__.loadItems.apply(this,arguments)
vmc=KD.getSingleton("vmController")
cmd=KD.checkFlag("nostradamus")?"fetchGroupVMs":"fetchVMs"
return vmc[cmd](!0,function(err,vms){var addedCount
if(err||0===vms.length){_this.emit("DataLoaded")
if(err)return warn("Failed to fetch VMs",err)}addedCount=0
return vms.forEach(function(vm){_this.addItem({title:vm,cpuUsage:KD.utils.getRandomNumber(100),memUsage:KD.utils.getRandomNumber(100),activated:!0})
addedCount++
return addedCount===vms.length?_this.emit("DataLoaded"):void 0})})}
return EnvironmentMachineContainer}(EnvironmentContainer)

var EnvironmentExtraContainer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentExtraContainer=function(_super){function EnvironmentExtraContainer(options,data){null==options&&(options={})
options.itemClass=EnvironmentExtraItem
options.title="Extras"
EnvironmentExtraContainer.__super__.constructor.call(this,options,data)}__extends(EnvironmentExtraContainer,_super)
EnvironmentExtraContainer.prototype.loadItems=function(){var addition,dummyAdditionals,_i,_len
EnvironmentExtraContainer.__super__.loadItems.apply(this,arguments)
dummyAdditionals=[{title:"20 GB Extra Space",description:"additional 20 GB"},{title:"10 GB Extra Space",description:"additional 20 GB"},{title:"512 MB Extra Memory",description:"additional 512 MB Ram"},{title:"4 GB Extra Memory",description:"additional 4 GB Ram"}]
for(_i=0,_len=dummyAdditionals.length;_len>_i;_i++){addition=dummyAdditionals[_i]
this.addItem(addition)}return this.emit("DataLoaded")}
return EnvironmentExtraContainer}(EnvironmentContainer)

var EnvironmentItemJoint,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentItemJoint=function(_super){function EnvironmentItemJoint(options,data){null==options&&(options={})
options.cssClass="environments-joint"
options.size=4
EnvironmentItemJoint.__super__.constructor.call(this,options,data)}__extends(EnvironmentItemJoint,_super)
return EnvironmentItemJoint}(KDDiaJoint)

var EnvironmentItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentItem=function(_super){function EnvironmentItem(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("environments-item",options.cssClass)
options.bind=KD.utils.curry("contextmenu",options.bind)
options.jointItemClass=EnvironmentItemJoint
options.draggable=!1
null==options.colorTag&&(options.colorTag="#a2a2a2")
EnvironmentItem.__super__.constructor.call(this,options,data)}var pipedVmName
__extends(EnvironmentItem,_super)
EnvironmentItem.prototype.contextMenuItems=function(){var colorSelection,items
colorSelection=new ColorSelection({selectedColor:this.getOption("colorTag")})
colorSelection.on("ColorChanged",this.bound("setColorTag"))
items={Delete:{disabled:KD.isGuest(),separator:!0,action:"delete"},customView:colorSelection}
return items}
EnvironmentItem.prototype.contextMenu=function(event){var ctxMenu,menuItems,_this=this
KD.utils.stopDOMEvent(event)
menuItems=this.contextMenuItems()
if(menuItems){ctxMenu=new JContextMenu({menuWidth:200,delegate:this,x:event.pageX,y:event.pageY,lazyLoad:!0},menuItems)
return ctxMenu.on("ContextMenuItemReceivedClick",function(item){var action,_name
action=item.getData().action
null!=_this["cm"+action]&&ctxMenu.destroy()
return"function"==typeof _this[_name="cm"+action]?_this[_name]():void 0})}}
EnvironmentItem.prototype.cmdelete=function(){return"function"==typeof this.confirmDestroy?this.confirmDestroy():void 0}
EnvironmentItem.prototype.cmunfocus=function(){return this.parent.emit("UnhighlightDias")}
EnvironmentItem.prototype.setColorTag=function(color,save){null==save&&(save=!0)
this.getElement().style.borderLeftColor=color
this.options.colorTag=color
save&&this.saveColorTag(color)
return this.parent.emit("UpdateScene")}
EnvironmentItem.prototype.saveColorTag=function(color){var colorTags,name,title
if(this.parent.appStorage){colorTags=this.parent.appStorage.getValue("colorTags")||{}
name=this.constructor.name
title=pipedVmName(this.getData().title)
colorTags[""+name+"-"+title]=color
return this.parent.appStorage.setValue("colorTags",colorTags)}}
EnvironmentItem.prototype.loadColorTag=function(){var color,colorTags,name,title
colorTags=this.parent.appStorage.getValue("colorTags")||{}
name=this.constructor.name
title=pipedVmName(this.getData().title)
color=colorTags[""+name+"-"+title]
return color?this.setColorTag(color):void 0}
pipedVmName=function(vmName){return vmName.replace(/\./g,"|")}
EnvironmentItem.prototype.click=function(event){if($(event.target).is(".chevron")){this.contextMenu(event)
return!1}return EnvironmentItem.__super__.click.apply(this,arguments)}
EnvironmentItem.prototype.viewAppended=function(){var _ref
EnvironmentItem.__super__.viewAppended.apply(this,arguments)
this.setColorTag(this.getOption("colorTag"),!1)
return null!=(_ref=this.parent.appStorage)?_ref.ready(this.bound("loadColorTag")):void 0}
EnvironmentItem.prototype.pistachio=function(){return"<div class='details'>\n  {h3{#(title)}}\n  {{#(description)}}\n  <span class='chevron'></span>\n</div>"}
return EnvironmentItem}(KDDiaObject)

var EnvironmentRuleItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentRuleItem=function(_super){function EnvironmentRuleItem(options,data){null==options&&(options={})
options.cssClass="rule"
options.joints=["right"]
options.allowedConnections={EnvironmentDomainItem:["left"]}
EnvironmentRuleItem.__super__.constructor.call(this,options,data)}__extends(EnvironmentRuleItem,_super)
return EnvironmentRuleItem}(EnvironmentItem)

var EnvironmentExtraItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentExtraItem=function(_super){function EnvironmentExtraItem(options,data){null==options&&(options={})
options.cssClass="additional"
options.joints=["left"]
options.allowedConnections={EnvironmentMachineItem:["right"]}
EnvironmentExtraItem.__super__.constructor.call(this,options,data)}__extends(EnvironmentExtraItem,_super)
return EnvironmentExtraItem}(EnvironmentItem)

var EnvironmentDomainItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentDomainItem=function(_super){function EnvironmentDomainItem(options,data){null==options&&(options={})
options.cssClass="domain"
options.joints=["right"]
KD.checkFlag("nostradamus")&&options.joints.push("left")
options.allowedConnections={EnvironmentRuleItem:["right"],EnvironmentMachineItem:["left"]}
EnvironmentDomainItem.__super__.constructor.call(this,options,data)}__extends(EnvironmentDomainItem,_super)
EnvironmentDomainItem.prototype.confirmDestroy=function(){this.deletionModal=new DomainDeletionModal({},this.getData().domain)
return this.deletionModal.on("domainRemoved",this.bound("destroy"))}
return EnvironmentDomainItem}(EnvironmentItem)

var EnvironmentMachineItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentMachineItem=function(_super){function EnvironmentMachineItem(options,data){null==options&&(options={})
options.cssClass="machine"
options.joints=["left"]
KD.checkFlag("nostradamus")&&options.joints.push("right")
options.allowedConnections={EnvironmentDomainItem:["right"],EnvironmentExtraItem:["left"]}
EnvironmentMachineItem.__super__.constructor.call(this,options,data)
this.ramUsage=new VMRamUsageBar(null,data.title)
this.diskUsage=new VMDiskUsageBar(null,data.title)}__extends(EnvironmentMachineItem,_super)
EnvironmentMachineItem.prototype.contextMenuItems=function(){var colorSelection,items,vmMountSwitch,vmName,vmStateSwitch
colorSelection=new ColorSelection({selectedColor:this.getOption("colorTag")})
colorSelection.on("ColorChanged",this.bound("setColorTag"))
vmName=this.getData().title
vmStateSwitch=new NVMToggleButtonView({},{vmName:vmName})
vmMountSwitch=new NMountToggleButtonView({},{vmName:vmName})
items={customView1:vmStateSwitch,customView2:vmMountSwitch,"Re-initialize VM":{disabled:KD.isGuest(),callback:function(){KD.getSingleton("vmController").reinitialize(vmName)
return this.destroy()}},"Open VM Terminal":{callback:function(){KD.getSingleton("appManager").open("Terminal",{params:{vmName:vmName},forceNew:!0})
return this.destroy()},separator:!0},Delete:{disabled:KD.isGuest(),separator:!0,action:"delete"},Unfocus:{separator:!0,action:"unfocus"},customView3:colorSelection}
return items}
EnvironmentMachineItem.prototype.confirmDestroy=function(){return KD.getSingleton("vmController").remove(this.getData().title,this.bound("destroy"))}
EnvironmentMachineItem.prototype.pistachio=function(){return"<div class='details'>\n  {h3{#(title)}}\n  {{> this.ramUsage}}\n  {{> this.diskUsage}}\n  <span class='chevron'></span>\n</div>"}
return EnvironmentMachineItem}(EnvironmentItem)

var EnvironmentApprovalModal,EnvironmentScene,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
EnvironmentScene=function(_super){function EnvironmentScene(){var sc
EnvironmentScene.__super__.constructor.call(this,{cssClass:"environments-scene",lineWidth:1})
this.boxes={}
sc=KD.getSingleton("appStorageController")
this.appStorage=sc.storage("EnvironmentsScene","1.0")}var containerMap,itemMap,parseItems,type
__extends(EnvironmentScene,_super)
containerMap={EnvironmentRuleContainer:"rules",EnvironmentExtraContainer:"extras",EnvironmentDomainContainer:"domains",EnvironmentMachineContainer:"machines"}
itemMap={EnvironmentRuleItem:"rule",EnvironmentExtraItem:"extra",EnvironmentDomainItem:"domain",EnvironmentMachineItem:"machine"}
EnvironmentScene.prototype.disconnect=function(dia,joint){var domain,extra,items,machine,modal,removeConnection,rule,source,target,targetConnection,_this=this
removeConnection=function(){return KDDiaScene.prototype.disconnect.call(_this,dia,joint)}
targetConnection=this.findTargetConnection(dia,joint)
if(targetConnection){source=targetConnection.source,target=targetConnection.target
items=parseItems(source,target)
if(!(Object.keys(items).length<2)){domain=items.domain,machine=items.machine,rule=items.rule,extra=items.extra
modal=this.createApproveModal(items,"delete")
return modal.once("Approved",function(){var jDomain,vmName
if(domain&&machine){jDomain=domain.dia.getData().domain
vmName=machine.dia.getData().title
return jDomain.unbindVM({hostnameAlias:vmName},function(err){modal.destroy()
if(err)return KD.showError(err)
jDomain.hostnameAlias.splice(jDomain.hostnameAlias.indexOf(vmName),1)
return removeConnection()})}if(domain&&rule){removeConnection()
return modal.destroy()}if(machine&&extra){removeConnection()
return modal.destroy()}})}}}
EnvironmentScene.prototype.connect=function(source,target,internal){var createConnection,domain,extra,items,machine,modal,rule,_this=this
null==internal&&(internal=!1)
createConnection=function(){return KDDiaScene.prototype.connect.call(_this,source,target)}
if(internal)return createConnection()
if(!this.allowedToConnect(source,target))return new KDNotificationView({title:"It's not allowed connect this two item."})
items=parseItems(source,target)
if(!(Object.keys(items).length<2)){domain=items.domain,machine=items.machine,rule=items.rule,extra=items.extra
if(domain&&machine&&!KD.checkFlag("nostradamus")&&domain.dia.getData().domain.hostnameAlias.length>0)return new KDNotificationView({title:"A domain name can only be bound to one VM."})
this.addFakeConnection({source:source,target:target,options:{lineColor:"#cdcdcd",lineDashes:[5]}})
modal=this.createApproveModal(items,"create")
modal.once("KDObjectWillBeDestroyed",this.bound("resetScene"))
return modal.once("Approved",function(){var jDomain,vmName
if(domain&&machine){jDomain=domain.dia.getData().domain
vmName=machine.dia.getData().title
return jDomain.bindVM({hostnameAlias:vmName},function(err){modal.destroy()
if(err)return KD.showError(err)
jDomain.hostnameAlias.push(vmName)
return createConnection()})}if(domain&&rule){createConnection()
return modal.destroy()}if(machine&&extra){createConnection()
return modal.destroy()}})}}
EnvironmentScene.prototype.updateConnections=function(){var domain,machine,_dkey,_mkey,_ref,_results
_ref=this.boxes.machines.dias
_results=[]
for(_mkey in _ref){machine=_ref[_mkey]
_results.push(function(){var _ref1,_ref2,_results1
_ref1=this.boxes.domains.dias
_results1=[]
for(_dkey in _ref1){domain=_ref1[_dkey]
domain.getData().aliases&&(_ref2=machine.getData().title,__indexOf.call(domain.getData().aliases,_ref2)>=0)?_results1.push(this.connect({dia:domain,joint:"right"},{dia:machine,joint:"left"},!0)):_results1.push(void 0)}return _results1}.call(this))}return _results}
EnvironmentScene.prototype.createApproveModal=function(items,action){return KD.isLoggedIn()?new EnvironmentApprovalModal({action:action},items):new KDNotificationView({title:"You need to login to change domain settings."})}
EnvironmentScene.prototype.whenItemsLoadedFor=function(){return function(containers,callback){var counter
counter=containers.length
return containers.forEach(function(container){container.once("DataLoaded",function(){1===counter&&callback()
return counter--})
return container.loadItems()})}}()
EnvironmentScene.prototype.addContainer=function(container,pos){var label,name
null==pos&&(pos={x:10+260*this.containers.length,y:0})
EnvironmentScene.__super__.addContainer.call(this,container,pos)
name=container.constructor.name
label=containerMap[name]||name
container._initialPosition=pos
return this.boxes[label]=container}
parseItems=function(source,target){var item,items,_i,_len,_ref
items={}
_ref=[source,target]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
items[itemMap[item.dia.constructor.name]]=item}return items}
type=function(item){return itemMap[item.dia.constructor.name]||null}
EnvironmentScene.prototype.viewAppended=function(){return EnvironmentScene.__super__.viewAppended.apply(this,arguments)}
return EnvironmentScene}(KDDiaScene)
EnvironmentApprovalModal=function(_super){function EnvironmentApprovalModal(options,data){var _this=this
null==options&&(options={})
options.title||(options.title="Are you sure?")
null==options.overlay&&(options.overlay=!0)
null==options.overlayClick&&(options.overlayClick=!1)
options.buttons={Yes:{loader:{color:"#444444",diameter:12},cssClass:"delete"===options.action?"modal-clean-red":"modal-clean-green",callback:function(){_this.buttons.Yes.showLoader()
return _this.emit("Approved")}},Cancel:{cssClass:"modal-cancel",callback:function(){_this.emit("Cancelled")
return _this.cancel()}}}
options.content=getContentFor(data,options.action)
EnvironmentApprovalModal.__super__.constructor.call(this,options,data)}var getContentFor
__extends(EnvironmentApprovalModal,_super)
getContentFor=function(items,action){var content,title,titles,_i,_len,_ref
content="God knows."
titles={}
_ref=["domain","machine","rule","extra"]
for(_i=0,_len=_ref.length;_len>_i;_i++){title=_ref[_i]
items[title]&&(titles[title]=items[title].dia.getData().title)}"create"===action?null!=titles.domain&&null!=titles.machine?content="Do you want to assign <b>"+titles.domain+"</b>\nto <b>"+titles.machine+"</b> machine?":null!=titles.domain&&null!=titles.rule?content="Do you want to enable <b>"+titles.rule+"</b> rule\nfor <b>"+titles.domain+"</b> domain?":null!=titles.machine&&null!=titles.extra&&(content="Do you want to add <b>"+titles.extra+"</b>\nto <b>"+titles.machine+"</b> machine?"):"delete"===action&&(null!=titles.domain&&null!=titles.machine?content="Do you want to remove <b>"+titles.domain+"</b>\ndomain from <b>"+titles.machine+"</b> machine?":null!=titles.domain&&null!=titles.rule?content="Do you want to disable <b>"+titles.rule+"</b> rule\nfor <b>"+titles.domain+"</b> domain?":null!=titles.machine&&null!=titles.extra&&(content="Do you want to remove <b>"+titles.extra+"</b>\nfrom <b>"+titles.machine+"</b> machine?"))
return"<div class='modalformline'><p>"+content+"</p></div>"}
return EnvironmentApprovalModal}(KDModalView)

var EnvironmentsMainScene,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EnvironmentsMainScene=function(_super){function EnvironmentsMainScene(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("environment-content",options.cssClass)
EnvironmentsMainScene.__super__.constructor.call(this,options,data)}__extends(EnvironmentsMainScene,_super)
EnvironmentsMainScene.prototype.viewAppended=function(){var actionArea,container,extrasContainer,rulesContainer,vmController,_i,_len,_ref,_this=this
this.addSubView(actionArea=new KDView({cssClass:"action-area"}))
actionArea.addSubView(this.domainCreateForm=new DomainCreateForm)
this.domainCreateForm.on("CloseClicked",function(){_this.unsetClass("in-progress")
_this.scene.unsetClass("out")
_this.domainCreateForm.unsetClass("opened")
return _this.scene.off("click")})
this.addSubView(this.scene=new EnvironmentScene)
if(KD.checkFlag("nostradamus")){rulesContainer=new EnvironmentRuleContainer
this.scene.addContainer(rulesContainer)}this.domainsContainer=new EnvironmentDomainContainer
this.scene.addContainer(this.domainsContainer)
this.domainsContainer.on("itemRemoved",this.domainCreateForm.bound("updateDomains"))
this.machinesContainer=new EnvironmentMachineContainer
this.scene.addContainer(this.machinesContainer)
this._containers=[this.machinesContainer,this.domainsContainer]
if(KD.checkFlag("nostradamus")){extrasContainer=new EnvironmentExtraContainer
this.scene.addContainer(extrasContainer)
this._containers=this._containers.concat([rulesContainer,extrasContainer])}_ref=this._containers
for(_i=0,_len=_ref.length;_len>_i;_i++){container=_ref[_i]
container.on("DataLoaded",this.scene.bound("updateConnections"))}this.refreshContainers()
this.domainCreateForm.on("DomainSaved",this.domainsContainer.bound("loadItems"))
KD.getSingleton("vmController").on("VMListChanged",this.bound("refreshContainers"))
this.domainsContainer.on("PlusButtonClicked",function(){if(!KD.isLoggedIn())return new KDNotificationView({title:"You need to login to add a new domain."})
if(0===_this.machinesContainer.diaCount())return new KDNotificationView({title:"You need to have at least one VM to manage domains."})
_this.setClass("in-progress")
_this.scene.setClass("out")
_this.domainCreateForm.setClass("opened")
_this.domainCreateForm.emit("DomainNameShouldFocus")
return _this.utils.defer(function(){return _this.scene.once("click",function(){return _this.domainCreateForm.emit("CloseClicked")})})})
vmController=KD.getSingleton("vmController")
vmController.on("VMPlansFetchStart",function(){return _this.machinesContainer.showLoader()})
vmController.on("VMPlansFetchEnd",function(){return _this.machinesContainer.hideLoader()})
return this.machinesContainer.on("PlusButtonClicked",function(){return KD.isLoggedIn()?vmController.createNewVM():new KDNotificationView({title:"You need to login to create a new machine."})})}
EnvironmentsMainScene.prototype.refreshContainers=function(){var _this=this
return this.scene.whenItemsLoadedFor(this._containers,function(){return _this.scene.updateConnections()})}
return EnvironmentsMainScene}(JView)

var DomainCreateForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DomainCreateForm=function(_super){function DomainCreateForm(options,data){var _this=this
null==options&&(options={})
options.cssClass="environments-add-domain-form"
DomainCreateForm.__super__.constructor.call(this,options,data)
this.addSubView(this.header=new KDHeaderView({title:"Add a domain"}))
this.header.addSubView(new KDButtonView({cssClass:"small-gray",title:"Cancel",callback:function(){return _this.emit("CloseClicked")}}))
this.addSubView(this.typeSelector=new KDInputRadioGroup({name:"DomainOption",radios:domainOptions,cssClass:"domain-option-group",defaultValue:"subdomain",change:function(actionType){var _ref
null!=(_ref=_this.successNote)&&_ref.destroy()
switch(actionType){case"new":_this.tabs.showPaneByName("NewDomain")
return _this.newDomainEntryForm.inputs.domainName.setFocus()
case"subdomain":_this.tabs.showPaneByName("SubDomain")
return _this.subDomainEntryForm.inputs.domainName.setFocus()}}}))
this.addSubView(this.tabs=new KDTabView({cssClass:"domain-tabs",hideHandleContainer:!0}))
this.newDomainPane=new KDTabPaneView({name:"NewDomain"})
this.newDomainPane.addSubView(this.newDomainEntryForm=new DomainBuyForm)
this.tabs.addPane(this.newDomainPane)
this.newDomainEntryForm.on("registerDomain",this.bound("checkDomainAvailability"))
this.subDomainPane=new KDTabPaneView({name:"SubDomain"})
this.subDomainPane.addSubView(this.subDomainEntryForm=new SubdomainCreateForm)
this.subDomainEntryForm.on("registerDomain",this.bound("createSubDomain"))
this.tabs.addPane(this.subDomainPane)}var domainOptions,notifyUser,subDomainPattern
__extends(DomainCreateForm,_super)
subDomainPattern=/^([a-z0-9]([_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/
domainOptions=[{title:"Create a subdomain",value:"subdomain"},{title:"Register a new domain",value:"new",disabled:!0},{title:"Use an existing domain",value:"existing",disabled:!0}]
DomainCreateForm.prototype.checkDomainAvailability=function(){var createButton,domainName,domains,getDomainInfo,getDomainSuggestions,message,_ref,_ref1,_ref2,_this=this
message=this.newDomainEntryForm.message
createButton=this.newDomainEntryForm.buttons.createButton
_ref=this.newDomainEntryForm.inputs,domains=_ref.domains,domainName=_ref.domainName
domainName=""+domainName.getValue()+"."+domains.getValue()
_ref1=KD.remote.api.JDomain,getDomainInfo=_ref1.getDomainInfo,getDomainSuggestions=_ref1.getDomainSuggestions
null!=(_ref2=this.newDomainEntryForm.domainListView)&&_ref2.unsetClass("in")
message.updatePartial("<br/> Checking for availability...")
message.setClass("in")
return getDomainInfo(domainName,function(err,status){if(err){createButton.hideLoader()
message.updatePartial("<br/> Please just provide domain name.")
return warn(err)}if(status.available){_this.newDomainEntryForm.setAvailableDomainsData([{domain:domainName,price:status.price}])
createButton.hideLoader()
return message.updatePartial("<br/> Yay it's available!")}message.updatePartial("<br/> Checking for alternatives...")
return getDomainSuggestions(domainName,function(err,suggestions){var result
createButton.hideLoader()
if(err)return warn(err)
result="Sorry, <b>"+domainName+"</b> is taken,"
result=1===suggestions.length?""+result+"<br/>but we found an alternative:":suggestions.length>1?""+result+"<br/>but we found following alternatives:":""+result+"<br/>and we couldn't find any alternative."
message.updatePartial(result)
return _this.newDomainEntryForm.setAvailableDomainsData(suggestions)})})}
DomainCreateForm.prototype.createSubDomain=function(){var createButton,domainName,domainType,domains,regYears,_ref,_this=this
_ref=this.subDomainEntryForm.inputs,domains=_ref.domains,domainName=_ref.domainName
createButton=this.subDomainEntryForm.buttons.createButton
domainName=domainName.getValue()
if(!subDomainPattern.test(domainName)){createButton.hideLoader()
return notifyUser(""+domainName+" is an invalid subdomain.")}domainName=""+domainName+"."+domains.getValue()
domainType="subdomain"
regYears=0
return this.createJDomain({domainName:domainName,regYears:regYears,domainType:domainType},function(err,domain){createButton.hideLoader()
if(err){warn("An error occured while creating domain:",err)
return 11e3===err.code?notifyUser("The domain "+domainName+" already exists."):"INVALIDDOMAIN"===err.name?notifyUser(""+domainName+" is an invalid subdomain."):notifyUser("An unknown error occured. Please try again later.")}_this.showSuccess(domain)
return _this.updateDomains()})}
DomainCreateForm.prototype.createJDomain=function(params,callback){var JDomain
JDomain=KD.remote.api.JDomain
return JDomain.createDomain({domain:params.domainName,regYears:params.regYears,proxy:{mode:"vm"},hostnameAlias:[],domainType:params.domainType,loadBalancer:{mode:""}},callback)}
DomainCreateForm.prototype.showSuccess=function(domain){var domainName,_ref
domainName=this.subDomainEntryForm.inputs.domainName
this.emit("DomainSaved",domain)
null!=(_ref=this.successNote)&&_ref.destroy()
this.addSubView(this.successNote=new KDCustomHTMLView({tagName:"p",cssClass:"success",partial:"Your subdomain <strong>"+domainName.getValue()+"</strong> has been added.\nYou can dismiss this panel and point your new domain to one of your VMs\non the right.",click:this.bound("reset")}))
return KD.utils.wait(7e3,this.successNote.bound("destroy"))}
notifyUser=function(msg){return new KDNotificationView({type:"tray",title:msg,duration:5e3})}
DomainCreateForm.prototype.reset=function(){var form,_i,_len,_ref,_ref1
null!=(_ref=this.successNote)&&_ref.destroy()
_ref1=[this.subDomainEntryForm,this.newDomainEntryForm]
for(_i=0,_len=_ref1.length;_len>_i;_i++){form=_ref1[_i]
form.inputs.domainName.setValue("")}return this.emit("CloseClicked")}
DomainCreateForm.prototype.updateDomains=function(){var _this=this
return KD.whoami().fetchDomains(function(err,userDomains){var domain,domainList,domainName,domains,_i,_len,_ref
err&&warn("Failed to update domains:",err)
domainList=[]
if(userDomains)for(_i=0,_len=userDomains.length;_len>_i;_i++){domain=userDomains[_i]
!domain.regYears>0&&domainList.push({title:"."+domain.domain,value:domain.domain})}_ref=_this.subDomainEntryForm.inputs,domains=_ref.domains,domainName=_ref.domainName
domainName.setValue("")
domains.removeSelectOptions()
return domains.setSelectOptions(domainList)})}
DomainCreateForm.prototype.viewAppended=function(){this.updateDomains()
KD.getSingleton("vmController").on("VMListChanged",this.bound("updateDomains"))
return this.subDomainEntryForm.inputs.domainName.setFocus()}
return DomainCreateForm}(KDCustomHTMLView)

var CommonDomainCreateForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommonDomainCreateForm=function(_super){function CommonDomainCreateForm(options,data){null==options&&(options={})
CommonDomainCreateForm.__super__.constructor.call(this,{cssClass:KD.utils.curry("new-domain-form",options.cssClass),fields:{domainName:{name:"domainInput",cssClass:"domain-input",placeholder:options.placeholder||"Type your domain",validate:{rules:{required:!0},messages:{required:"A domain name is required"}},nextElement:{domains:{itemClass:KDSelectBox,cssClass:"main-domain-select",selectOptions:options.selectOptions}}}},buttons:{createButton:{name:"createButton",title:options.buttonTitle||"Check availability",style:"cupid-green",cssClass:"add-domain",type:"submit",loader:{color:"#ffffff",diameter:10}}}},data)
this.addSubView(this.message=new KDCustomHTMLView({cssClass:"status-message"}))}__extends(CommonDomainCreateForm,_super)
CommonDomainCreateForm.prototype.submit=function(){var _this=this
this.buttons.createButton.hideLoader()
this.off("FormValidationPassed")
this.once("FormValidationPassed",function(){_this.emit("registerDomain")
return _this.buttons.createButton.showLoader()})
return CommonDomainCreateForm.__super__.submit.apply(this,arguments)}
return CommonDomainCreateForm}(KDFormViewWithFields)

var DomainDeletionModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DomainDeletionModal=function(_super){function DomainDeletionModal(options,data){var removeButton,_this=this
null==options&&(options={})
options.title||(options.title="Are you sure?")
null==options.overlay&&(options.overlay=!0)
null==options.overlayClick&&(options.overlayClick=!1)
options.content||(options.content="<div class='modalformline'>This will remove the domain <b>"+data.domain+"</b> permanently, there is no way back!</div>")
options.buttons||(options.buttons={Remove:{cssClass:"modal-clean-red",callback:function(){var domain
domain=_this.getData()
return domain.remove(function(err){if(err)return KD.showError(err)
new KDNotificationView({title:"<b>"+data.domain+"</b> has been removed."})
_this.emit("domainRemoved")
return _this.destroy()})}},"Keep it":{cssClass:"modal-clean-green",callback:function(){return _this.cancel()}}})
DomainDeletionModal.__super__.constructor.call(this,options,data)
removeButton=this.buttons.Remove
removeButton.$().blur()}__extends(DomainDeletionModal,_super)
return DomainDeletionModal}(KDModalView)

var DomainProductForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DomainProductForm=function(_super){function DomainProductForm(){_ref=DomainProductForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(DomainProductForm,_super)
DomainProductForm.prototype.viewAppended=function(){var locationController,_this=this
locationController=KD.getSingleton("locationController")
this.locationForm=locationController.createLocationForm({callback:function(){return _this.emit("DataCollected",_this.locationForm.getData())},fields:{privacyProtection:{label:"Use privacy protection?",itemClass:KDOnOffSwitch,labels:["yes","no"]}},phone:{required:!0}})
return DomainProductForm.__super__.viewAppended.call(this)}
DomainProductForm.prototype.processForm=function(){return this.locationForm.submit()}
DomainProductForm.prototype.pistachio=function(){return"<div class='modalformline'>\n  <p>\n    Please enter the address information that will be associated with this\n    domain name registration.  You can choose to register this domain\n    privately for an additional fee.\n  </p>\n</div>\n{{> this.locationForm}}"}
return DomainProductForm}(JView)

var DomainBuyForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DomainBuyForm=function(_super){function DomainBuyForm(options,data){var listView,_this=this
null==options&&(options={})
DomainBuyForm.__super__.constructor.call(this,{placeholder:"Type your awesome domain..."},data)
this.availableDomainsList=new KDListViewController({itemClass:DomainBuyItem})
this.domainListView=this.availableDomainsList.getView().setClass("domain-list")
listView=this.availableDomainsList.getListView()
listView.on("BuyButtonClicked",function(item){var displayPrice,domain,modal,price,workflow,year,_ref
_ref=item.getData(),price=_ref.price,domain=_ref.domain
year=+item.yearBox.getValue()
displayPrice=_this.utils.formatMoney(year*price)
workflow=new PaymentWorkflow({productForm:new DomainProductForm,confirmForm:new DomainPaymentConfirmForm({domain:domain,year:year,price:displayPrice})})
modal=new KDModalView({title:"Register <em>"+domain+"</em>",view:workflow,height:"auto",width:500,overlay:!0})
workflow.enter()
return workflow.on("DataCollected",function(){debugger})})}__extends(DomainBuyForm,_super)
DomainBuyForm.prototype.buyDomain=function(options){var JDomain,address,description,domain,feeAmount,paymentMethodId,price,priceInCents,year
JDomain=KD.remote.api.JDomain
price=options.price,paymentMethodId=options.paymentMethodId,address=options.productData,year=options.year,domain=options.domain
priceInCents=100*price
feeAmount=priceInCents*year
description="Domain name — "+domain+" — "+this.utils.formatPlural(year,"year")
options={domain:domain,year:year,address:address,transaction:{feeAmount:feeAmount,paymentMethodId:paymentMethodId,description:description}}
return JDomain.registerDomain(options,function(){debugger})}
DomainBuyForm.prototype.viewAppended=function(){var tldList,_this=this
tldList=[]
KD.remote.api.JDomain.getTldList(function(tlds){var tld,_i,_len
for(_i=0,_len=tlds.length;_len>_i;_i++){tld=tlds[_i]
tldList.push({title:"."+tld,value:tld})}return _this.inputs.domains.setSelectOptions(tldList)})
return this.addSubView(this.domainListView)}
DomainBuyForm.prototype.setAvailableDomainsData=function(domains){var _this=this
this.availableDomainsList.replaceAllItems(domains)
return this.utils.defer(function(){return _this.domainListView.setClass("in")})}
return DomainBuyForm}(CommonDomainCreateForm)

var DomainBuyItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DomainBuyItem=function(_super){function DomainBuyItem(options,data){var i,price,selectOptions,_this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("domain-buy-items",options.cssClass)
price=data.price
DomainBuyItem.__super__.constructor.call(this,options,data)
selectOptions=function(){var _i,_results
_results=[]
for(i=_i=1;5>=_i;i=++_i)_results.push({title:""+i+" year for "+this.utils.formatMoney(price*i),value:i})
return _results}.call(this)
this.yearBox=new KDSelectBox({name:"year",selectOptions:selectOptions})
this.buyButton=new KDButtonView({title:"Buy",style:"clean-gray",callback:function(){return _this.parent.emit("BuyButtonClicked",_this)}})}__extends(DomainBuyItem,_super)
DomainBuyItem.prototype.viewAppended=function(){return JView.prototype.viewAppended.call(this)}
DomainBuyItem.prototype.pistachio=function(){return"{h1{#(domain)}}\n{{> this.yearBox}}\n{{> this.buyButton}}"}
return DomainBuyItem}(KDListItemView)

var DomainPaymentConfirmForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DomainPaymentConfirmForm=function(_super){function DomainPaymentConfirmForm(){_ref=DomainPaymentConfirmForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(DomainPaymentConfirmForm,_super)
DomainPaymentConfirmForm.prototype.viewAppended=function(){var domain,price,year,yearFmt,_ref1
_ref1=this.getOptions(),year=_ref1.year,domain=_ref1.domain,price=_ref1.price
yearFmt=this.utils.formatPlural(year,"year",!1)
this.details=new KDView({partial:"<div class='modalformline'>\n  <h3>Do you want to buy "+domain+" for "+year+" "+yearFmt+"?</h3>\n  <p>You will be charged <b>"+price+"</b> for registering\n  <b>"+domain+"</b> domain for <b>"+year+"</b> "+yearFmt+".</p>\n</div>"})
return DomainPaymentConfirmForm.__super__.viewAppended.call(this)}
DomainPaymentConfirmForm.prototype.pistachio=function(){return"{{> this.details}}\n{{> this.buttonBar}}"}
return DomainPaymentConfirmForm}(PaymentConfirmForm)

var SubdomainCreateForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SubdomainCreateForm=function(_super){function SubdomainCreateForm(options,data){null==options&&(options={})
SubdomainCreateForm.__super__.constructor.call(this,{placeholder:"Type your subdomain...",buttonTitle:"Create subdomain"},data)}__extends(SubdomainCreateForm,_super)
return SubdomainCreateForm}(CommonDomainCreateForm)

var VmProductForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmProductForm=function(_super){function VmProductForm(){_ref=VmProductForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(VmProductForm,_super)
VmProductForm.prototype.createUpgradeForm=function(){return KD.getSingleton("paymentController").createUpgradeForm("vm",!0)}
VmProductForm.prototype.checkUsageLimits=function(pack,plan,callback){var data,oldSubscription,spend,subscription,usage,_ref1,_ref2,_this=this
callback||(_ref1=[plan,callback],callback=_ref1[0],plan=_ref1[1])
data=this.getData()
subscription=data.subscription,oldSubscription=data.oldSubscription
null==plan&&(plan=data.plan)
if(subscription)return subscription.checkUsage(pack,function(err,usage){if(err){_this.collectData({oldSubscription:subscription})
_this.clearData("subscription")}return callback(err,usage)})
if(plan){usage=null!=(_ref2=null!=oldSubscription?oldSubscription.quantities:void 0)?_ref2:{}
spend=pack.quantities
return plan.checkQuota(usage,spend,1,function(err,usage){err&&_this.clearData("plan")
return callback(err,usage)})}}
VmProductForm.prototype.createPackChoiceForm=function(){return new PackChoiceForm({title:"Choose your VM",itemClass:VmProductView})}
VmProductForm.prototype.setCurrentSubscriptions=function(subscriptions){var subscription
this.currentSubscriptions=subscriptions
switch(subscriptions.length){case 0:return this.showForm("upgrade")
case 1:subscription=subscriptions[0]
return this.collectData({subscription:subscription})
default:subscription=subscriptions[0]
this.collectData({subscription:subscription})
return console.warn({message:"User has multiple subscriptions",subscriptions:subscriptions})}}
VmProductForm.prototype.setContents=function(type,contents){switch(type){case"packs":return this.getForm("pack choice").setContents(contents)}}
VmProductForm.prototype.createChoiceForm=function(){return new KDView({partial:"this is a plan choice form"})}
VmProductForm.prototype.prepareWorkflow=function(){var all,any,choiceForm,packChoiceForm,upgradeForm,_this=this
all=Junction.all,any=Junction.any
this.requireData(all(any("subscription","plan"),"pack"))
upgradeForm=this.createUpgradeForm()
upgradeForm.on("PlanSelected",function(plan){var pack
pack=_this.collector.data.pack
return pack?_this.checkUsageLimits(pack,plan,function(err){return KD.showError(err)?void 0:_this.collectData({plan:plan})}):_this.collectData({plan:plan})})
this.addForm("upgrade",upgradeForm,["plan","subscription"])
packChoiceForm=this.createPackChoiceForm()
packChoiceForm.once("Activated",function(){return _this.emit("PackOfferingRequested")})
packChoiceForm.on("PackSelected",function(pack){return _this.checkUsageLimits(pack,function(err){KD.showError(err)
return _this.collectData({pack:pack})})})
this.addForm("pack choice",packChoiceForm,["pack"])
return choiceForm=this.createChoiceForm()}
return VmProductForm}(FormWorkflow)

var VmPaymentConfirmForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmPaymentConfirmForm=function(_super){function VmPaymentConfirmForm(){_ref=VmPaymentConfirmForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(VmPaymentConfirmForm,_super)
VmPaymentConfirmForm.prototype.viewAppended=function(){var data
data=this.getData()
this.pack=new KDView({cssClass:"payment-confirm-pack",partial:"<h2>VM</h2>\n<p>"+this.getExplanation("pack")+"</p>"})
this.subscription=new KDView({cssClass:"payment-confirm-subscription",partial:"<h3>Subscription</h3>\n<p>"+this.getExplanation("subscription")+"</p>"})
return VmPaymentConfirmForm.__super__.viewAppended.call(this)}
VmPaymentConfirmForm.prototype.getExplanation=function(key){switch(key){case"pack":return"You selected this VM:"
case"plan":return"You'll need to upgrade your plan for this purchase:"
case"subscription":return"Your existing subscription will cover this purchase."
default:return VmPaymentConfirmForm.__super__.getExplanation.call(this,key)}}
VmPaymentConfirmForm.prototype.setData=function(data){var packView
VmPaymentConfirmForm.__super__.setData.call(this,data)
if(null==data.productData)throw new Error("Product data was not provided!")
if(data.productData.pack){packView=new VmProductView({showControls:!1},data.productData.pack)
this.pack.addSubView(packView)}else this.pack.hide()
return data.productData.subscription?this.subscription.addSubView(new VmPlanView({},data.productData.subscription)):this.subscription.hide()}
VmPaymentConfirmForm.prototype.pistachio=function(){return"{{> this.pack}}\n{{> this.plan}}\n{{> this.subscription}}\n{{> this.payment}}\n{{> this.buttonBar}}"}
return VmPaymentConfirmForm}(PlanUpgradeConfirmForm)

var VmProductView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmProductView=function(_super){function VmProductView(){_ref=VmProductView.__super__.constructor.apply(this,arguments)
return _ref}__extends(VmProductView,_super)
VmProductView.prototype.shouldShowControls=function(){var _ref1
return null!=(_ref1=this.getOptions().showControls)?_ref1:!0}
VmProductView.prototype.viewAppended=function(){var options,_this=this
options=this.getOptions()
this.chooseButton=new KDButtonView({title:"Create VM",callback:function(){return _this.emit("PackSelected")}})
this.shouldShowControls()||this.chooseButton.hide()
return JView.prototype.viewAppended.call(this)}
VmProductView.prototype.pistachio=function(){return"{h3{#(title)}}\n{p{#(description)}}\n{{> this.chooseButton}}"}
return VmProductView}(KDListItemView)

var VmPlanView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmPlanView=function(_super){function VmPlanView(){_ref=VmPlanView.__super__.constructor.apply(this,arguments)
return _ref}__extends(VmPlanView,_super)
VmPlanView.prototype.pistachio=function(){return"{h4{#(title) || #(plan.title)}}\n{strong{this.utils.formatMoney(#(feeAmount) / 100)}}"}
return VmPlanView}(JView)

//@ sourceMappingURL=/js/__app.environments.0.0.1.js.map