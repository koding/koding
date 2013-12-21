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

var DashboardAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DashboardAppController=function(_super){function DashboardAppController(options,data){null==options&&(options={})
options.view=new DashboardAppView({testPath:"groups-dashboard"})
data||(data=KD.getSingleton("groupsController").getCurrentGroup())
DashboardAppController.__super__.constructor.call(this,options,data)
this.tabData=[{name:"Settings",viewOptions:{viewClass:GroupGeneralSettingsView,lazy:!0}},{name:"Members",viewOptions:{viewClass:GroupsMemberPermissionsView,lazy:!0,callback:this.bound("membersViewAdded")}},{name:"Invitations",viewOptions:{viewClass:GroupsInvitationView,lazy:!0}},{name:"Permissions",viewOptions:{viewClass:GroupPermissionsView,lazy:!0}},{name:"Membership policy",hiddenHandle:"public"===this.getData().privacy,viewOptions:{viewClass:GroupsMembershipPolicyDetailView,lazy:!0,callback:this.bound("policyViewAdded")}},{name:"Payment",viewOptions:{viewClass:GroupPaymentSettingsView,lazy:!0,callback:this.bound("paymentViewAdded")}},{name:"Products",viewOptions:{viewClass:GroupProductSettingsView,lazy:!0,callback:this.bound("productViewAdded")}},{name:"Blocked Users",hiddenHandle:"public"===this.getData().privacy,kodingOnly:!0,viewOptions:{viewClass:GroupsBlockedUserView,lazy:!0}},{name:"Badges",hiddenHandle:"public"===this.getData().privacy,kodingOnly:!0,viewOptions:{viewClass:BadgeDashboardView,lazy:!0}}]}__extends(DashboardAppController,_super)
KD.registerAppClass(DashboardAppController,{name:"Dashboard",route:"/:name?/Dashboard",hiddenHandle:!0})
DashboardAppController.prototype.fetchTabData=function(callback){var _this=this
return this.utils.defer(function(){return callback(_this.tabData)})}
DashboardAppController.prototype.membersViewAdded=function(pane,view){var group
group=view.getData()
return group.on("MemberAdded",function(){return log("MemberAdded")})}
DashboardAppController.prototype.policyViewAdded=function(){}
DashboardAppController.prototype.paymentViewAdded=function(pane,view){return new GroupPaymentController({view:view})}
DashboardAppController.prototype.productViewAdded=function(pane,view){return new GroupProductsController({view:view})}
return DashboardAppController}(AppController)

var DashboardAppView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DashboardAppView=function(_super){function DashboardAppView(options,data){var _this=this
null==options&&(options={})
options.cssClass||(options.cssClass="content-page")
data||(data=KD.getSingleton("groupsController").getCurrentGroup())
DashboardAppView.__super__.constructor.call(this,options,data)
this.header=new HeaderViewSection({type:"big",title:"Group Dashboard"})
this.nav=new CommonInnerNavigation
this.tabs=new KDTabView({cssClass:"dashboard-tabs",hideHandleContainer:!0},data)
this.setListeners()
this.once("viewAppended",function(){var group
_this.header.hide()
_this.nav.hide()
group=KD.getSingleton("groupsController").getCurrentGroup()
return null!=group?group.canEditGroup(function(err,success){var entryPoint
if(err||!success){entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity",{entryPoint:entryPoint})}_this.header.show()
_this.nav.show()
return _this.createTabs()}):void 0})
this.searchWrapper=new KDCustomHTMLView({tagName:"section",cssClass:"searchbar"})
this.search=new KDHitEnterInputView({placeholder:"Search...",name:"searchInput",cssClass:"header-search-input",type:"text",focus:function(){return"Invitations"!==_this.tabs.getActivePane().name?_this.tabs.showPaneByName("Members"):void 0},callback:function(){var mainView,pane
pane="Invitations"===_this.tabs.getActivePane().name?_this.tabs.getActivePane():_this.tabs.getPaneByName("Members")
mainView=pane.mainView
if(mainView){mainView.emit("SearchInputChanged",_this.search.getValue())
return _this.search.focus()}},keyup:function(){var mainView,pane
if(""===_this.search.getValue()){pane="Invitations"===_this.tabs.getActivePane().name?_this.tabs.getActivePane():_this.tabs.getPaneByName("Members")
mainView=pane.mainView
if(mainView)return mainView.emit("SearchInputChanged","")}}})
this.searchIcon=new KDCustomHTMLView({tagName:"span",cssClass:"icon search"})
this.searchWrapper.addSubView(this.search)
this.searchWrapper.addSubView(this.searchIcon)
this.header.addSubView(this.searchWrapper)
this.on("groupSettingsUpdated",function(group){this.setData(group)
return this.createTabs()})}__extends(DashboardAppView,_super)
DashboardAppView.prototype.setListeners=function(){var _this=this
this.nav.on("viewAppended",function(){_this.navController=_this.nav.setListController({itemClass:CommonInnerNavigationListItem},{title:"SHOW ME",items:[]})
return _this.nav.addSubView(_this.navController.getView())})
this.nav.on("NavItemReceivedClick",function(_arg){var title
title=_arg.title
return _this.tabs.showPaneByName(title)})
return this.tabs.on("PaneDidShow",function(pane){return _this.navController.selectItemByName(pane.name)})}
DashboardAppView.prototype.createTabs=function(){var data,_this=this
data=this.getData()
return KD.getSingleton("appManager").tell("Dashboard","fetchTabData",function(tabData){var hiddenHandle,i,kodingOnly,name,navItems,pane,viewOptions,_i,_len,_ref
navItems=[]
for(i=_i=0,_len=tabData.length;_len>_i;i=++_i){_ref=tabData[i],name=_ref.name,hiddenHandle=_ref.hiddenHandle,viewOptions=_ref.viewOptions,kodingOnly=_ref.kodingOnly
viewOptions.data=data
"Settings"===name&&(viewOptions.options={delegate:_this})
hiddenHandle=null!=hiddenHandle&&"public"===data.privacy
_this.tabs.addPane(pane=new KDTabPaneView({name:name,viewOptions:viewOptions}),0===i)
kodingOnly&&"koding"!==data.slug||navItems.push({title:name,type:hiddenHandle?"hidden":null})}_this.navController.replaceAllItems(navItems)
return _this.navController.selectItem(_this.navController.itemsOrdered.first)})}
DashboardAppView.prototype.pistachio=function(){return"{{> this.nav}}\n{{> this.tabs}}"}
return DashboardAppView}(JView)

var GroupPaymentHistoryListController,GroupPaymentHistoryModal,GroupSubscriptionsModal,GroupSubscriptionsistController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPaymentHistoryModal=function(_super){function GroupPaymentHistoryModal(options,data){var dbList,dbListForm,group,_this=this
group=options.group
options={title:"Payment History",content:"",overlay:!0,width:500,height:"auto",cssClass:"billing-history-modal",tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{history:{fields:{Instances:{type:"hidden",cssClass:"database-list"}},buttons:{Refresh:{style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12},callback:function(){var form
form=_this.modalTabs.forms.history
return _this.dbController.loadItems(function(){return form.buttons.Refresh.hideLoader()})}}}}}}}
GroupPaymentHistoryModal.__super__.constructor.call(this,options,data)
this.dbController=new GroupPaymentHistoryListController({group:group,itemClass:AccountPaymentHistoryListItem})
dbList=this.dbController.getListView()
dbListForm=this.modalTabs.forms.history
dbListForm.fields.Instances.addSubView(this.dbController.getView())
this.dbController.loadItems()}__extends(GroupPaymentHistoryModal,_super)
return GroupPaymentHistoryModal}(KDModalViewWithForms)
GroupPaymentHistoryListController=function(_super){function GroupPaymentHistoryListController(options){null==options&&(options={})
this.group=options.group
GroupPaymentHistoryListController.__super__.constructor.apply(this,arguments)}__extends(GroupPaymentHistoryListController,_super)
GroupPaymentHistoryListController.prototype.loadItems=function(callback){var transactions,_ref,_this=this
this.removeAllItems()
null!=(_ref=this.customItem)&&_ref.destroy()
this.showLazyLoader(!1)
transactions=[]
return this.group.fetchTransactions(function(err,trans){var t,_i,_len
if(err){console.log(err)
_this.addCustomItem("There are no transactions.")
_this.hideLazyLoader()}if(!err){for(_i=0,_len=trans.length;_len>_i;_i++){t=trans[_i]
0!==t.amount+t.tax&&transactions.push({status:t.status,amount:_this.utils.formatMoney((t.amount+t.tax)/100),currency:"USD",createdAt:t.createdAt,paidVia:t.card||"",cardType:t.cardType,cardNumber:t.cardNumber,owner:t.owner,refundable:t.refundable})}0===transactions.length?_this.addCustomItem("There are no transactions."):_this.instantiateListItems(transactions)
_this.hideLazyLoader()
return"function"==typeof callback?callback():void 0}})}
GroupPaymentHistoryListController.prototype.addCustomItem=function(message){var _ref
this.removeAllItems()
null!=(_ref=this.customItem)&&_ref.destroy()
return this.scrollView.addSubView(this.customItem=new KDCustomHTMLView({cssClass:"no-item-found",partial:message}))}
return GroupPaymentHistoryListController}(KDListViewController)
GroupSubscriptionsModal=function(_super){function GroupSubscriptionsModal(options,data){var dbList,dbListForm,group,_this=this
group=options.group
options={title:"Subscriptions",content:"",overlay:!0,width:500,height:"auto",cssClass:"billing-history-modal",tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{history:{fields:{Instances:{type:"hidden",cssClass:"database-list"}},buttons:{Refresh:{style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12},callback:function(){var form
form=_this.modalTabs.forms.history
return _this.dbController.loadItems(function(){return form.buttons.Refresh.hideLoader()})}}}}}}}
GroupSubscriptionsModal.__super__.constructor.call(this,options,data)
this.dbController=new GroupSubscriptionsistController({group:group,itemClass:AccountSubscriptionsListItem})
dbList=this.dbController.getListView()
dbListForm=this.modalTabs.forms.history
dbListForm.fields.Instances.addSubView(this.dbController.getView())
this.dbController.loadItems()}__extends(GroupSubscriptionsModal,_super)
return GroupSubscriptionsModal}(KDModalViewWithForms)
GroupSubscriptionsistController=function(_super){function GroupSubscriptionsistController(options){var _this=this
null==options&&(options={})
this.group=options.group
GroupSubscriptionsistController.__super__.constructor.apply(this,arguments)
this.list=this.getListView()
this.list.on("reload",function(){return _this.loadItems()})}__extends(GroupSubscriptionsistController,_super)
GroupSubscriptionsistController.prototype.loadItems=function(callback){var _ref,_this=this
this.removeAllItems()
null!=(_ref=this.customItem)&&_ref.destroy()
this.showLazyLoader(!1)
return this.group.checkPayment(function(err,subs){var stack
if(err||0===subs.length){_this.addCustomItem("There are no subscriptions.")
return _this.hideLazyLoader()}stack=[]
subs.forEach(function(sub){return"expired"!==sub.status?stack.push(function(cb){return KD.remote.api.JPaymentPlan.fetchPlanByCode(sub.planCode,function(err,plan){if(err)return cb(err)
sub.plan=plan
return cb(null,sub)})}):void 0})
return async.parallel(stack,function(err,result){err&&(result=[])
0===result.length?_this.addCustomItem("There are no subscriptions."):_this.instantiateListItems(result)
_this.hideLazyLoader()
return"function"==typeof callback?callback():void 0})})}
GroupSubscriptionsistController.prototype.addCustomItem=function(message){var _ref
this.removeAllItems()
null!=(_ref=this.customItem)&&_ref.destroy()
return this.scrollView.addSubView(this.customItem=new KDCustomHTMLView({cssClass:"no-item-found",partial:message}))}
return GroupSubscriptionsistController}(KDListViewController)

var LinkablePaymentMethodView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LinkablePaymentMethodView=function(_super){function LinkablePaymentMethodView(){_ref=LinkablePaymentMethodView.__super__.constructor.apply(this,arguments)
return _ref}__extends(LinkablePaymentMethodView,_super)
LinkablePaymentMethodView.prototype.viewAppended=function(){var _this=this
LinkablePaymentMethodView.__super__.viewAppended.call(this)
this.linkButton=new KDButtonView({title:"Link a payment method",callback:function(){return _this.emit("PaymentMethodEditRequested",_this.getData())}})
this.addSubView(this.linkButton)
this.unlinkButton=new KDButtonView({title:"Unlink this payment method",callback:function(){return _this.emit("PaymentMethodUnlinkRequested",_this.getData())}})
this.unlinkButton.hide()
this.addSubView(this.unlinkButton)
return this.emit("ready")}
LinkablePaymentMethodView.prototype.setState=function(state){this.loader.hide()
switch(state){case"unlink":this.linkButton.hide()
this.unlinkButton.show()
return this.paymentMethodInfo.show()
case"link":this.linkButton.show()
this.unlinkButton.hide()
return this.paymentMethodInfo.hide()}}
LinkablePaymentMethodView.prototype.setPaymentInfo=function(paymentMethod){var _this=this
LinkablePaymentMethodView.__super__.setPaymentInfo.call(this,paymentMethod)
return this.ready(function(){return _this.setState((null!=paymentMethod?paymentMethod.billing:void 0)?"unlink":"link")})}
return LinkablePaymentMethodView}(PaymentMethodView)

var GroupPaymentSettingsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPaymentSettingsView=function(_super){function GroupPaymentSettingsView(){var formOptions,group,_this=this
GroupPaymentSettingsView.__super__.constructor.apply(this,arguments)
this.setClass("paymment-settings-view group-admin-modal")
group=this.getData()
formOptions={callback:function(formData){var overagePolicy,saveButton,updateOptions
saveButton=_this.settingsForm.buttons.Save
overagePolicy=formData["allow-over-usage"]?formData["require-approval"]?"by permission":"allowed":"not allowed"
updateOptions={overagePolicy:overagePolicy,sharedVM:formData["shared-vm"],allocation:formData.allocation}
return group.updateBundle(updateOptions,function(){return saveButton.hideLoader()})},buttons:{Save:{style:"modal-clean-green",type:"submit",loader:{color:"#444444",diameter:12}}},fields:{billing:{label:"Billing method",itemClass:LinkablePaymentMethodView},history:{label:"Payment history",tagName:"a",partial:"Show payment history",itemClass:KDCustomHTMLView,cssClass:"billing-link",click:function(){return new GroupPaymentHistoryModal({group:group})}},subscriptions:{label:"Subscriptions",tagName:"a",partial:"Show subscriptions",itemClass:KDCustomHTMLView,cssClass:"billing-link",click:function(){return new GroupSubscriptionsModal({group:group})}},expensedVMs:{label:"User VMs",tagName:"a",partial:"Show user VMs",itemClass:KDCustomHTMLView,cssClass:"billing-link",click:function(){return new GroupVMsModal({group:group})}},sharedVM:{label:"Shared VM",itemClass:KDOnOffSwitch,name:"shared-vm",cssClass:"hidden"},vmDesc:{itemClass:KDCustomHTMLView,cssClass:"vm-description hidden",partial:"<section>\n  <p>If you enable this, your group will have a shared VM.</p>\n</section>"},allocation:{itemClass:KDSelectBox,label:"Resources",type:"select",name:"allocation",defaultValue:"0",selectOptions:[{title:"None",value:"0"},{title:"$ 10",value:"1000"},{title:"$ 20",value:"2000"},{title:"$ 30",value:"3000"},{title:"$ 50",value:"5000"},{title:"$ 100",value:"10000"}]},allocDesc:{itemClass:KDCustomHTMLView,cssClass:"alloc-description",partial:"<section>\n  <p>You can pay for your members' resources. Each member's\n  payment up to a specific amount will be charged from your\n  balance.</p>\n</section>"},approval:{label:"Need approval?",itemClass:KDOnOffSwitch,name:"require-approval",cssClass:"no-title"}}}
this.settingsForm=new KDFormViewWithFields(formOptions,group)
this.forwardEvent(this.settingsForm.inputs.billing,"PaymentMethodEditRequested")
this.forwardEvent(this.settingsForm.inputs.billing,"PaymentMethodUnlinkRequested")}__extends(GroupPaymentSettingsView,_super)
GroupPaymentSettingsView.prototype.setPaymentInfo=function(paymentMethod){var billingView
billingView=this.settingsForm.inputs.billing
return billingView.setPaymentInfo(paymentMethod)}
GroupPaymentSettingsView.prototype.pistachio=function(){return"{{> this.settingsForm}}"}
return GroupPaymentSettingsView}(JView)

var GroupPaymentController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPaymentController=function(_super){function GroupPaymentController(options,data){null==options&&(options={})
GroupPaymentController.__super__.constructor.call(this,options,data)
this.preparePaymentsView()}__extends(GroupPaymentController,_super)
GroupPaymentController.prototype.preparePaymentsView=function(){var group,paymentController,view,_this=this
view=this.getOptions().view
group=KD.getGroup()
paymentController=KD.getSingleton("paymentController")
paymentController.on("PaymentDataChanged",function(){return _this.refreshPaymentView()})
this.refreshPaymentView()
view.on("PaymentMethodEditRequested",function(){return _this.showPaymentInfoModal()})
return view.on("PaymentMethodUnlinkRequested",function(paymentMethod){var modal
return modal=KDModalView.confirm({title:"Are you sure?",description:"Are you sure you want to unlink this payment method?",subView:new PaymentMethodView({},paymentMethod),ok:{title:"Unlink",callback:function(){return group.unlinkPaymentMethod(paymentMethod.paymentMethodId,function(){modal.destroy()
return _this.refreshPaymentView()})}}})})}
GroupPaymentController.prototype.refreshPaymentView=function(){var group,view
view=this.getOptions().view
group=KD.getGroup()
return group.fetchPaymentMethod(function(err,paymentMethod){return KD.showError(err)?void 0:view.setPaymentInfo(paymentMethod)})}
GroupPaymentController.prototype.showPaymentInfoModal=function(){var group,modal,paymentController,_this=this
modal=this.createPaymentInfoModal()
group=KD.getGroup()
paymentController=KD.getSingleton("paymentController")
paymentController.observePaymentSave(modal,function(err,_arg){var paymentMethodId
paymentMethodId=_arg.paymentMethodId
if(!KD.showError(err)){modal.destroy()
return group.linkPaymentMethod(paymentMethodId,function(err){return KD.showError(err)?void 0:_this.refreshPaymentView()})}})
return modal}
GroupPaymentController.prototype.createPaymentInfoModal=function(){var group,modal,paymentController,_this=this
paymentController=KD.getSingleton("paymentController")
modal=paymentController.createPaymentInfoModal("group")
group=KD.getGroup()
group.fetchPaymentMethod(function(err,groupPaymentMethod){return KD.showError(err)?void 0:groupPaymentMethod?modal.setState("editExisting",groupPaymentMethod):paymentController.fetchPaymentMethods(function(err,personalPaymentMethods){if(!KD.showError(err)){if(personalPaymentMethods.methods.length>0){modal.setState("selectPersonal",personalPaymentMethods)
return modal.on("PaymentMethodChosen",function(_arg){var paymentMethodId
paymentMethodId=_arg.paymentMethodId
return group.linkPaymentMethod(paymentMethodId,function(err){if(!KD.showError(err)){modal.destroy()
return _this.refreshPaymentView()}})})}return modal.setState("createNew")}})})
return modal}
return GroupPaymentController}(KDController)

var GroupProductsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupProductsController=function(_super){function GroupProductsController(options,data){null==options&&(options={})
GroupProductsController.__super__.constructor.call(this,options,data)
this.productsView=this.prepareProductView("product")
this.packsView=this.prepareProductView("pack")
this.plansView=this.prepareProductView("plan")}var confirmDelete,dash,getConstructor,getProductFormOptions,showEditModal
__extends(GroupProductsController,_super)
dash=Bongo.dash
GroupProductsController.prototype.prepareProductView=function(category){var categoryView,handleEdit,handleResponse,konstructor,reload,showAddProductsModal,view,_this=this
view=this.getOptions().view
konstructor=getConstructor(category);(reload=function(){return _this.fetchProducts(category,function(err,products){return view.setProducts(category,products)})})()
handleResponse=function(err){return KD.showError(err)?void 0:reload()}
handleEdit=function(data){var options
options=getProductFormOptions(category)
return showEditModal(options,data,function(err,model,productData){return KD.showError(err)?void 0:model?model.modify(productData,handleResponse):konstructor.create(productData,handleResponse)})}
showAddProductsModal=function(plan){var modal
modal=new GroupPlanAddProductsModal({},plan)
modal.on("ProductsAdded",function(quantities){return plan.updateProducts(quantities,function(err){handleResponse(err)
return modal.destroy()})})
return _this.fetchProducts("product",function(err,products){return KD.showError(err)?void 0:modal.setProducts(products)})}
categoryView=view.getCategoryView(category)
return categoryView.on("CreateRequested",handleEdit).on("EditRequested",handleEdit).on("AddProductsRequested",showAddProductsModal).on("DeleteRequested",function(data){return confirmDelete(data,function(){return konstructor.removeByCode(data.planCode,handleResponse)})}).on("BuyersReportRequested",function(){debugger})}
confirmDelete=function(data,callback){var modal,productViewOptions
productViewOptions={tagName:"div",cssClass:"modalformline"}
return modal=KDModalView.confirm({title:"Warning",description:"Are you sure you want to delete this item?",subView:new GroupProductView(productViewOptions,data),ok:{title:"Remove",callback:function(){modal.destroy()
return callback()}}})}
showEditModal=function(options,data,callback){var createForm,formConstructor,modal,productType,_ref,_ref1
productType=null!=(_ref=options.productType)?_ref:"product"
formConstructor=null!=(_ref1=options.formClass)?_ref1:GroupProductEditForm
modal=new KDModalView({overlay:!0,title:"Create "+productType})
createForm=new formConstructor(options,data)
modal.addSubView(createForm)
return createForm.on("CancelRequested",modal.bound("destroy")).on("SaveRequested",function(model,productData){modal.destroy()
return callback(null,model,productData)})}
getProductFormOptions=function(category){switch(category){case"product":return{productType:"product",isRecurOptional:!0,showOverage:!0,showSoldAlone:!0,showPriceIsVolatile:!0}
case"pack":return{productType:"pack",formClass:GroupPackEditForm,isRecurOptional:!1,showOverage:!1,showSoldAlone:!1,showPriceIsVolatile:!1,placeholders:{title:"VM — extra large",description:"4 cores, 4 GB RAM, 8 GB disk"}}
case"plan":return{productType:"plan",isRecurOptional:!1,showOverage:!1,showSoldAlone:!1,showPriceIsVolatile:!1,placeholders:{title:'e.g. "Gold Plan"',description:'e.g. "2 VMs, and a tee shirt"'}}}}
getConstructor=function(category){switch(category){case"product":return KD.remote.api.JPaymentProduct
case"pack":return KD.remote.api.JPaymentPack
case"plan":return KD.remote.api.JPaymentPlan}}
GroupProductsController.prototype.fetchProducts=function(category,callback){return KD.getGroup().fetchProducts(category,function(err,products){var queue
if(err)return callback(err)
queue=products.map(function(plan){return function(){return null!=plan.fetchProducts?plan.fetchProducts(function(err,planProducts){if(err)return queue.fin(err)
plan.childProducts=planProducts
return queue.fin()}):queue.fin()}})
return dash(queue,function(err){return err?callback(err):callback(null,products)})})}
return GroupProductsController}(KDController)

var InvitationRequestListController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
InvitationRequestListController=function(_super){function InvitationRequestListController(options,data){var _this=this
null==options&&(options={})
null==options.itemClass&&(options.itemClass=GroupsInvitationListItemView)
null==options.viewOptions&&(options.viewOptions={})
options.viewOptions.cssClass=this.utils.curry("invitation-request-list",options.viewOptions.cssClass)
null==options.noItemFoundWidget&&(options.noItemFoundWidget=new KDCustomHTMLView({cssClass:"lazy-loader",partial:options.noItemFound}))
InvitationRequestListController.__super__.constructor.call(this,options,data)
this.listView.setDelegate(this)
this.on("noItemsFound",function(){return _this.noItemLeft=!0})}__extends(InvitationRequestListController,_super)
return InvitationRequestListController}(KDListViewController)

var GroupGeneralSettingsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
GroupGeneralSettingsView=function(_super){function GroupGeneralSettingsView(options,data){var delegate,formOptions,group,_ref,_ref1,_ref2,_ref3,_this=this
null==options&&(options={})
GroupGeneralSettingsView.__super__.constructor.call(this,options,data)
this.setClass("general-settings-view group-admin-modal")
group=this.getData()
delegate=this.getDelegate()
formOptions={callback:function(formData){var appManager,saveButton
saveButton=_this.settingsForm.buttons.Save
appManager=KD.getSingleton("appManager")
return group.modify(formData,function(err){if(err){saveButton.hideLoader()
return new KDNotificationView({title:err.message,duration:1e3})}new KDNotificationView({title:"Group was updated!",duration:1e3})
return delegate.emit("groupSettingsUpdated",group)})},buttons:{Save:{style:"modal-clean-green",type:"submit",loader:{color:"#444444",diameter:12}},Remove:{cssClass:"modal-clean-red fr",title:"Remove this Group",callback:function(){var modal
return modal=new GroupsDangerModalView({action:"Remove Group",title:"Remove '"+data.slug+"'",longAction:"remove the '"+data.slug+"' group",callback:function(callback){return data.remove(function(err){callback()
if(err)return KD.showError(err)
new KDNotificationView({title:"Successfully removed!"})
modal.destroy()
return location.replace("/")})}},data)}}},fields:{Title:{label:"Group Name",name:"title",defaultValue:Encoder.htmlDecode(null!=(_ref=group.title)?_ref:""),placeholder:"Please enter a title here"},Description:{label:"Description",type:"textarea",name:"body",defaultValue:Encoder.htmlDecode(null!=(_ref1=group.body)?_ref1:""),placeholder:"Please enter a description here.",autogrow:!0},"Privacy settings":{itemClass:KDSelectBox,label:"Privacy",type:"select",name:"privacy",defaultValue:null!=(_ref2=group.privacy)?_ref2:"public",selectOptions:[{title:"Public",value:"public"},{title:"Private",value:"private"}]},"Visibility settings":{itemClass:KDSelectBox,label:"Visibility",type:"select",name:"visibility",defaultValue:null!=(_ref3=group.visibility)?_ref3:"visible",selectOptions:[{title:"Visible",value:"visible"},{title:"Hidden",value:"hidden"}]}}}
this.settingsForm=new KDFormViewWithFields(formOptions,group)
null!=KD.config.roles&&__indexOf.call(KD.config.roles,"owner")>=0||this.settingsForm.buttons.Remove.hide()
"koding"===data.slug&&this.settingsForm.buttons.Remove.hide()}__extends(GroupGeneralSettingsView,_super)
GroupGeneralSettingsView.prototype.pistachio=function(){return"{{> this.settingsForm}}"}
return GroupGeneralSettingsView}(JView)

var GroupProductSettingsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupProductSettingsView=function(_super){function GroupProductSettingsView(options,data){var _this=this
null==options&&(options={})
GroupProductSettingsView.__super__.constructor.call(this,options,data)
this.setClass("group-product-section")
this.productsView=new GroupProductSectionView({category:"product",itemClass:GroupProductListItem,controlsClass:ProductAdminControlsView,pistachio:"<h2>Products</h2>\n{{> this.createButton}}\n{{> this.list}}"})
this.packsView=new GroupProductSectionView({category:"pack",itemClass:GroupPlanListItem,controlsClass:PlanAdminControlsView,pistachio:"<h2>Packs</h2>\n<p>Packs are bundles of products, used for representing larger\n   products, for instance, a VM with 1 GB of RAM and 2 cores.</p>\n{{> this.createButton}}\n{{> this.list}}"})
this.plansView=new GroupProductSectionView({category:"plan",itemClass:GroupPlanListItem,controlsClass:PlanAdminControlsView,pistachio:"<h2>Plans</h2>\n<p>Plans are bundles of products.  Effectively, the quantities\n   you choose will serve as maximum quantities per plan.</p>\n{{> this.createButton}}\n{{> this.list}}"});["product","pack","plan"].forEach(function(category){var categoryView
categoryView=_this.getCategoryView(category)
categoryView.on("CreateRequested",function(){return _this.emit("EditRequested")})
return _this.forwardEvents(categoryView,["DeleteRequested","EditRequested","AddProductsRequested","BuyersReportRequested"])})}__extends(GroupProductSettingsView,_super)
GroupProductSettingsView.prototype.getCategoryView=function(category){return this[""+category+"sView"]}
GroupProductSettingsView.prototype.setProducts=function(category,contents){var view
view=this.getCategoryView(category)
return view.setContents(contents)}
GroupProductSettingsView.prototype.pistachio=function(){return"{{> this.productsView}}\n{{> this.packsView}}\n{{> this.plansView}}"}
return GroupProductSettingsView}(JView)

var GroupProductSectionView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupProductSectionView=function(_super){function GroupProductSectionView(){_ref=GroupProductSectionView.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupProductSectionView,_super)
GroupProductSectionView.prototype.viewAppended=function(){var category,controlsClass,itemClass,_ref1,_this=this
_ref1=this.getOptions(),category=_ref1.category,itemClass=_ref1.itemClass,controlsClass=_ref1.controlsClass
this.setClass("payment-settings-view")
this.createButton=new KDButtonView({cssClass:"cupid-green",title:"Create a "+category,callback:function(){return _this.emit("CreateRequested")}})
this.listController=new ProductSectionListController({itemClass:itemClass})
this.list=this.listController.getListView()
controlsClass&&this.list.on("ItemWasAdded",function(item){var controls
controls=new controlsClass({},item.getData())
item.setControls(controls)
return _this.forwardEvents(controls,["DeleteRequested","EditRequested","AddProductsRequested","BuyersReportRequested"])})
return GroupProductSectionView.__super__.viewAppended.call(this)}
GroupProductSectionView.prototype.setContents=function(contents){this.listController.removeAllItems()
return this.listController.instantiateListItems(contents)}
return GroupProductSectionView}(JView)

var GroupProductEditForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupProductEditForm=function(_super){function GroupProductEditForm(options,data){var model,_base,_base1,_base2,_base3,_base4,_base5,_base6,_base7,_ref,_ref1,_ref2,_ref3,_this=this
null==options&&(options={})
null==data&&(data=new KD.remote.api.JPaymentProduct)
data.planCode&&(model=data)
null==options.isRecurOptional&&(options.isRecurOptional=!0)
null==options.callback&&(options.callback=function(){return _this.emit("SaveRequested",model,_this.getProductData())})
null==options.buttons&&(options.buttons={Save:{cssClass:"modal-clean-green",type:"submit"},cancel:{cssClass:"modal-cancel",callback:function(){return _this.emit("CancelRequested")}}})
null==options.fields&&(options.fields={})
null==(_base=options.fields).title&&(_base.title={label:"Title",placeholder:null!=(_ref=options.placeholders)?_ref.title:void 0,defaultValue:data.decoded("title"),required:"Title is required!"})
null==(_base1=options.fields).description&&(_base1.description={label:"Description",placeholder:(null!=(_ref1=options.placeholders)?_ref1.description:void 0)||"(optional)",defaultValue:data.decoded("description")})
null==(_base2=options.fields).subscriptionType&&(_base2.subscriptionType={label:"Subscription type",itemClass:KDSelectBox,defaultValue:null!=(_ref2=data.subscriptionType)?_ref2:"mo",selectOptions:this.getSubscriptionTypes(options),callback:this.bound("subscriptionTypeChanged")})
null==(_base3=options.fields).feeAmount&&(_base3.feeAmount={label:"Amount",placeholder:"0.00",defaultValue:data.feeAmount?(data.feeAmount/100).toFixed(2):void 0,change:this.bound("feeChanged"),nextElementFlat:{perMonth:{itemClass:KDCustomHTMLView,partial:"/ "+(null!=(_ref3=data.subscriptionType)?_ref3:"mo"),cssClass:"fr"}}})
options.showPriceIsVolatile&&null==(_base4=options.fields).priceIsVolatile&&(_base4.priceIsVolatile={label:"Price is volatile",itemClass:KDOnOffSwitch,defaultValue:data.priceIsVolatile,callback:this.bound("priceVolatilityChanged")})
options.showOverage&&null==(_base5=options.fields).overageEnabled&&(_base5.overageEnabled={label:"Overage enabled",itemClass:KDOnOffSwitch,defaultValue:data.overageEnabled})
options.showSoldAlone&&null==(_base6=options.fields).soldAlone&&(_base6.soldAlone={label:"Sold alone",itemClass:KDOnOffSwitch,defaultValue:data.soldAlone})
null==(_base7=options.fields).tags&&(_base7.tags={label:"Tags",itemClass:KDDelimitedInputView,defaultValue:data.tags})
GroupProductEditForm.__super__.constructor.call(this,options,data)
data.priceIsVolatile&&this.fields.feeAmount.hide()}__extends(GroupProductEditForm,_super)
GroupProductEditForm.prototype.getPlanInfo=function(subscriptionType){var _ref
null==subscriptionType&&(subscriptionType=null!=(_ref=this.inputs.subscriptionType)?_ref.getValue():void 0)
return{feeUnit:"months",feeInterval:function(){switch(subscriptionType){case"mo":return 1
case"3 mo":return 3
case"6 mo":return 6
case"yr":return 12
case"2 yr":return 24
case"5 yr":return 60}}(),subscriptionType:subscriptionType}}
GroupProductEditForm.prototype.getProductData=function(){var _this=this
return function(i){var description,feeAmount,feeInterval,feeUnit,overageEnabled,priceIsVolatile,soldAlone,subscriptionType,tags,title,_ref,_ref1,_ref2,_ref3
title=i.title.getValue()
description=i.description.getValue()
overageEnabled=null!=(_ref=i.overageEnabled)?_ref.getValue():void 0
soldAlone=null!=(_ref1=i.soldAlone)?_ref1.getValue():void 0
priceIsVolatile=null!=(_ref2=i.priceIsVolatile)?_ref2.getValue():void 0
tags=i.tags.getValue()
feeAmount=priceIsVolatile?void 0:100*i.feeAmount.getValue()
_ref3=_this.getPlanInfo(),subscriptionType=_ref3.subscriptionType,feeUnit=_ref3.feeUnit,feeInterval=_ref3.feeInterval
return{title:title,description:description,feeAmount:feeAmount,feeUnit:feeUnit,feeInterval:feeInterval,subscriptionType:subscriptionType,overageEnabled:overageEnabled,soldAlone:soldAlone,priceIsVolatile:priceIsVolatile,tags:tags}}(this.inputs)}
GroupProductEditForm.prototype.getSubscriptionTypes=function(options){var selectOptions
selectOptions=[{title:"Recurs every month",value:"mo"},{title:"Recurs every 3 months",value:"3 mo"},{title:"Recurs every 6 months",value:"6 mo"},{title:"Recurs every year",value:"yr"},{title:"Recurs every 2 years",value:"2 yr"},{title:"Recurs every 5 years",value:"5 yr"}]
options.isRecurOptional&&selectOptions.push({title:"Single payment",value:"single"})
return selectOptions}
GroupProductEditForm.prototype.subscriptionTypeChanged=function(){var newType,perMonth,subscriptionType,_ref
_ref=this.inputs,subscriptionType=_ref.subscriptionType,perMonth=_ref.perMonth
newType=subscriptionType.getValue()
if("single"===subscriptionType)return perMonth.hide()
perMonth.show()
return perMonth.updatePartial("/ "+newType)}
GroupProductEditForm.prototype.feeChanged=function(){var feeAmount,num
feeAmount=this.inputs.feeAmount
num=parseFloat(feeAmount.getValue())
return feeAmount.setValue(isNaN(num)?"":num.toFixed(2))}
GroupProductEditForm.prototype.priceVolatilityChanged=function(){var enabled
enabled=this.inputs.priceIsVolatile.getValue()
return this.fields.feeAmount[enabled?"hide":"show"]()}
return GroupProductEditForm}(KDFormViewWithFields)

var GroupPackEditForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPackEditForm=function(_super){function GroupPackEditForm(options,data){var model,_base,_base1,_base2,_ref,_ref1,_this=this
null==options&&(options={})
null==data&&(data=new KD.remote.api.JPaymentPack)
null==options.fields&&(options.fields={})
data.planCode&&(model=data)
null==options.callback&&(options.callback=function(){return _this.emit("SaveRequested",model,_this.getProductData())})
null==options.buttons&&(options.buttons={Save:{cssClass:"modal-clean-green",type:"submit"},cancel:{cssClass:"modal-cancel",callback:function(){return _this.emit("CancelRequested")}}})
null==options.fields&&(options.fields={})
null==(_base=options.fields).title&&(_base.title={label:"Title",placeholder:null!=(_ref=options.placeholders)?_ref.title:void 0,defaultValue:data.decoded("title"),required:"Title is required!"})
null==(_base1=options.fields).description&&(_base1.description={label:"Description",placeholder:(null!=(_ref1=options.placeholders)?_ref1.description:void 0)||"(optional)",defaultValue:data.decoded("description")})
null==(_base2=options.fields).tags&&(_base2.tags={label:"Tags",itemClass:KDDelimitedInputView,defaultValue:data.tags})
GroupPackEditForm.__super__.constructor.call(this,options,data)}__extends(GroupPackEditForm,_super)
GroupPackEditForm.prototype.getProductData=GroupPackEditForm.prototype.getFormData
return GroupPackEditForm}(KDFormViewWithFields)

var EmbedCodeView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedCodeView=function(_super){function EmbedCodeView(options,data){null==options&&(options={})
this.planCode=options.planCode
null==options.cssClass&&(options.cssClass="hidden product-embed")
null==options.hideHandleCloseIcons&&(options.hideHandleCloseIcons=!0)
null==options.paneData&&(options.paneData=[{name:"Check Subscription",partial:"<pre>"+this.getCodeCheckSnippet()+"</pre>"},{name:"Get Subscribers",partial:"<pre>"+this.getCodeGetSnippet()+"</pre>"},{name:"Subscribe Widget",partial:"<pre>"+this.getCodeWidgetSnippet()+"</pre>"}])
EmbedCodeView.__super__.constructor.call(this,options,data)}__extends(EmbedCodeView,_super)
EmbedCodeView.prototype.getCodeWidgetSnippet=function(){return'@content = new KDButtonView\n  cssClass   : "clean-gray test-input"\n  title      : "Subscribed! View Video"\n  callback   : ->\n    console.log "Open video..."\n\n@payment = new PaymentWidget\n  planCode        : \''+this.planCode+'\'\n  contentCssClass : \'modal-clean-green\'\n  content         : @content\n\n@payment.on "subscribed", ->\n  console.log "User is subscribed."'}
EmbedCodeView.prototype.getCodeGetSnippet=function(){return"KD.remote.api.JPaymentPlan.fetchPlanByCode '"+this.planCode+'\', (err, plan)->\n  if not err and plan\n    plan.fetchSubscriptions (err, subs)->\n      console.log "Subscribers:", subs'}
EmbedCodeView.prototype.getCodeCheckSnippet=function(){return"KD.remote.api.JPaymentSubscription.checkUserSubscription '"+this.planCode+'\', (err, subscriptions)->\n  if not err and subscriptions.length > 0\n    console.log "User is subscribed to the plan."'}
return EmbedCodeView}(KDTabView)

var GroupProductView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupProductView=function(_super){function GroupProductView(options,data){null==options&&(options={})
null==options.tagName&&(options.tagName="span")
GroupProductView.__super__.constructor.call(this,options,data)}__extends(GroupProductView,_super)
GroupProductView.prototype.prepareData=function(){var displayPrice,price,product,subscriptionType,title
product=this.getData()
title=product.title
price=this.utils.formatMoney(product.feeAmount/100)
displayPrice=product.priceIsVolatile?'<span class="price-volatile">(price is volatile)</span>':'<span class="price">'+price+"</span>"
subscriptionType=function(){if("single"===product.subscriptionType)return"Single payment"
if("months"!==product.feeUnit)return""
switch(product.feeInterval){case 1:return"monthly"
case 3:return"every 3 months"
case 6:return"every 6 months"
case 12:return"yearly"
case 24:return"every 2 years"
case 60:return"every 5 years"
default:return"every "+product.feeInterval+" months"}}()
return{title:title,price:price,displayPrice:displayPrice,subscriptionType:subscriptionType}}
GroupProductView.prototype.pistachio=function(){var displayPrice,subscriptionType,title,_ref
_ref=this.prepareData(),title=_ref.title,displayPrice=_ref.displayPrice,subscriptionType=_ref.subscriptionType
return""+title+" — "+displayPrice+" "+subscriptionType}
return GroupProductView}(JView)

var ProductAdminControlsView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ProductAdminControlsView=function(_super){function ProductAdminControlsView(){_ref=ProductAdminControlsView.__super__.constructor.apply(this,arguments)
return _ref}__extends(ProductAdminControlsView,_super)
ProductAdminControlsView.prototype.viewAppended=function(){var planCode,product,soldAlone,_i,_ref1,_results,_this=this
product=this.getData()
planCode=product.planCode,soldAlone=product.soldAlone
this.embedView=new EmbedCodeView({planCode:planCode})
this.embedButton=new KDButtonView({title:"View Embed Code",callback:function(){return _this.embedView.hasClass("hidden")?_this.embedView.unsetClass("hidden"):_this.embedView.setClass("hidden")}})
soldAlone||this.embedButton.hide()
this.clientsButton=new KDButtonView({title:"View buyers",callback:function(){return _this.emit("BuyersReportRequested",product)}})
this.deleteButton=new KDButtonView({title:"Remove",callback:function(){return _this.emit("DeleteRequested",product)}})
this.editButton=new KDButtonView({title:"Edit",callback:function(){return _this.emit("EditRequested",product)}})
this.sortWeight=new KDSelectBox({title:"Sort weight",defaultValue:""+(null!=(_ref1=product.sortWeight)?_ref1:0),selectOptions:function(){_results=[]
for(_i=-100;100>=_i;_i++)_results.push(_i)
return _results}.apply(this).map(function(w){return{title:""+w,value:""+w}}),callback:function(){return _this.getData().modify({sortWeight:_this.sortWeight.getValue()})}})
return ProductAdminControlsView.__super__.viewAppended.call(this)}
ProductAdminControlsView.prototype.pistachio=function(){return"{{> this.embedButton}}\n{{> this.deleteButton}}\n{{> this.clientsButton}}\n{{> this.editButton}}\n{{> this.sortWeight}}\n{{> this.embedView}}"}
return ProductAdminControlsView}(JView)

var GroupProductListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupProductListItem=function(_super){function GroupProductListItem(){_ref=GroupProductListItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupProductListItem,_super)
GroupProductListItem.prototype.viewAppended=function(){var product
product=this.getData()
this.productView=new GroupProductView({},product)
null==this.controls&&(this.controls=new KDView)
return JView.prototype.viewAppended.call(this)}
GroupProductListItem.prototype.setControls=function(controlsView){null==this.controls&&(this.controls=new KDView)
return this.controls.addSubView(controlsView)}
GroupProductListItem.prototype.activate=function(){return this.setClass("active")}
GroupProductListItem.prototype.deactivate=function(){return this.unsetClass("active")}
GroupProductListItem.prototype.disable=function(){var view,_i,_len,_ref1,_results
this.setClass("disabled")
_ref1=this.controls.subViews
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){view=_ref1[_i]
_results.push("function"==typeof view.disable?view.disable():void 0)}return _results}
GroupProductListItem.prototype.enable=function(){var view,_i,_len,_ref1,_results
this.unsetClass("disabled")
_ref1=this.controls.subViews
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){view=_ref1[_i]
_results.push("function"==typeof view.enable?view.enable():void 0)}return _results}
GroupProductListItem.prototype.pistachio=function(){return'<div class="product-item">\n  {{> this.productView}}\n  {{> this.controls}}\n</div>\n<hr>'}
return GroupProductListItem}(KDListItemView)

var GroupChildProductListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupChildProductListItem=function(_super){function GroupChildProductListItem(){_ref=GroupChildProductListItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupChildProductListItem,_super)
GroupChildProductListItem.prototype.viewAppended=JView.prototype.viewAppended
GroupChildProductListItem.prototype.pistachio=function(){return'{.fl{#(product.title)}}\n<span class="fr">x{{#(quantity)}}</span>'}
return GroupChildProductListItem}(KDListItemView)

var PlanAdminControlsView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PlanAdminControlsView=function(_super){function PlanAdminControlsView(){_ref=PlanAdminControlsView.__super__.constructor.apply(this,arguments)
return _ref}__extends(PlanAdminControlsView,_super)
PlanAdminControlsView.prototype.viewAppended=function(){var plan,_this=this
plan=this.getData()
this.addProductsButton=new KDButtonView({title:"Add products",callback:function(){return _this.emit("AddProductsRequested",plan)}})
return PlanAdminControlsView.__super__.viewAppended.call(this)}
PlanAdminControlsView.prototype.pistachio=function(){return"{{> this.embedButton}}\n{{> this.deleteButton}}\n{{> this.clientsButton}}\n{{> this.editButton}}\n{{> this.addProductsButton}}\n{{> this.sortWeight}}\n{{> this.embedView}}"}
return PlanAdminControlsView}(ProductAdminControlsView)

var GroupPlanListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPlanListItem=function(_super){function GroupPlanListItem(){_ref=GroupPlanListItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupPlanListItem,_super)
GroupPlanListItem.prototype.viewAppended=function(){var plan
plan=this.getData()
this.planView=new GroupProductView({},plan)
this.childProducts=new KDListViewController({view:new KDListView({cssClass:"plan-child-products",itemClass:GroupChildProductListItem})})
null!=plan.childProducts&&this.childProducts.instantiateListItems(plan.childProducts.map(function(product){return{product:product,quantity:plan.quantities[product.planCode]}}))
return GroupPlanListItem.__super__.viewAppended.call(this)}
GroupPlanListItem.prototype.pistachio=function(){return'<div class="product-item">\n  {{> this.planView}}\n  {{> this.controls}}\n  <h3>Contains:</h3>\n  {{> this.childProducts.getView()}}\n</div>'}
return GroupPlanListItem}(GroupProductListItem)

var ProductSectionListController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ProductSectionListController=function(_super){function ProductSectionListController(){_ref=ProductSectionListController.__super__.constructor.apply(this,arguments)
return _ref}__extends(ProductSectionListController,_super)
ProductSectionListController.prototype.addCustomItem=function(message){var _ref1
this.removeAllItems()
null!=(_ref1=this.customItem)&&_ref1.destroy()
return this.scrollView.addSubView(this.customItem=new KDCustomHTMLView({cssClass:"no-item-found",partial:message}))}
return ProductSectionListController}(KDListViewController)

var GroupAddProductListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupAddProductListItem=function(_super){function GroupAddProductListItem(){_ref=GroupAddProductListItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupAddProductListItem,_super)
GroupAddProductListItem.prototype.viewAppended=function(){var options
options=this.getOptions()
this.qtyView=new KDInputView({attributes:{size:4}})
return JView.prototype.viewAppended.call(this)}
GroupAddProductListItem.prototype.setQuantity=function(qty){return this.qtyView.setValue(qty)}
GroupAddProductListItem.prototype.pistachio=function(){return'{strong{#(title)}}\n{{this.utils.formatMoney(#(feeAmount) / 100)}}\n<div class="fr">\n  <strong>QTY:</strong>\n  {{> this.qtyView}}\n</div>'}
return GroupAddProductListItem}(KDListItemView)

var GroupPlanProduct,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPlanProduct=function(_super){function GroupPlanProduct(){_ref=GroupPlanProduct.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupPlanProduct,_super)
GroupPlanProduct.prototype.pistachio=function(){return'<div class="clearfix">\n  {{#(planCode)}} {{#(qty)}}\n</div>'}
return GroupPlanProduct}(JView)

var GroupPlanAddProductsModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPlanAddProductsModal=function(_super){function GroupPlanAddProductsModal(options,data){var _this=this
null==options&&(options={})
null==options.title&&(options.title="Add products")
null==options.overlay&&(options.overlay=!0)
GroupPlanAddProductsModal.__super__.constructor.call(this,options,data)
data=this.getData()
this.loader=new KDLoaderView({size:14})
this.addSubView(this.loader)
this.loader.show()
this.planExplanation=new KDCustomHTMLView({cssClass:"modalformline",partial:"<h2>Plan</h2>"})
this.planView=new GroupProductView({cssClass:"modalformline",tagName:"div"},data)
this.productsExplanation=new KDCustomHTMLView({cssClass:"modalformline",partial:"<h2>Products</h2>\n<p>Add some products to this plan</p>"})
this.products=new KDListViewController({itemClass:GroupAddProductListItem})
this.buttonField=new KDView({cssClass:"formline button-field clearfix"})
this.buttonField.addSubView(new KDButtonView({title:"Save",cssClass:"modal-clean-green",callback:function(){_this.save()
return _this.destroy()}}))
this.buttonField.addSubView(new KDButtonView({title:"cancel",cssClass:"modal-cancel",callback:this.bound("destroy")}))
this.addSubView(this.planExplanation)
this.addSubView(this.planView)
this.addSubView(this.productsExplanation)
this.addSubView(this.products.getView())
this.addSubView(this.buttonField)}__extends(GroupPlanAddProductsModal,_super)
GroupPlanAddProductsModal.prototype.save=function(){var quantities
quantities={}
this.products.getItemsOrdered().forEach(function(item){var planCode,qty
planCode=item.getData().planCode
qty=item.qtyView.getValue()
return qty>0?quantities[planCode]=qty:void 0})
return this.emit("ProductsAdded",quantities)}
GroupPlanAddProductsModal.prototype.setProducts=function(products){var item,plan,product,qty,_i,_len,_ref,_ref1,_results
this.loader.hide()
plan=this.getData()
_results=[]
for(_i=0,_len=products.length;_len>_i;_i++){product=products[_i]
qty=null!=(_ref=null!=(_ref1=plan.quantities)?_ref1[product.planCode]:void 0)?_ref:0
item=this.products.addItem(product)
_results.push(item.setQuantity(qty))}return _results}
return GroupPlanAddProductsModal}(KDModalView)

var GroupsMemberPermissionsListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
GroupsMemberPermissionsListItemView=function(_super){function GroupsMemberPermissionsListItemView(options,data){var list,roles,userRoles,_ref,_this=this
null==options&&(options={})
options.cssClass="formline clearfix"
options.type="member-item"
GroupsMemberPermissionsListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
list=this.getDelegate()
_ref=list.getOptions(),roles=_ref.roles,userRoles=_ref.userRoles
this.avatar=new AvatarStaticView({},data)
this.profileLink=new ProfileTextView({},data)
this.usersRole=userRoles[data.getId()]
this.userRole=new KDCustomHTMLView({partial:"Roles: "+this.usersRole.join(", "),cssClass:"ib role"})
this.editLink=__indexOf.call(this.usersRole,"owner")>=0||KD.whoami().getId()===data.getId()?new KDCustomHTMLView("hidden"):new CustomLinkView({title:"Edit",cssClass:"fr edit-link",icon:{cssClass:"edit"},click:function(event){event.stopPropagation()
event.preventDefault()
return _this.showEditMemberRolesView()}})
this.cancelLink=new CustomLinkView({title:"Cancel",cssClass:"fr hidden cancel-link",icon:{cssClass:"delete"},click:function(event){event.stopPropagation()
event.preventDefault()
return _this.hideEditMemberRolesView()}})
this.editContainer=new KDView({cssClass:"edit-container hidden"})
list.on("EditMemberRolesViewShown",function(listItem){return listItem!==_this?_this.hideEditMemberRolesView():void 0})}__extends(GroupsMemberPermissionsListItemView,_super)
GroupsMemberPermissionsListItemView.prototype.showEditMemberRolesView=function(){var editorsRoles,group,list,roles,_ref,_this=this
list=this.getDelegate()
editorsRoles=list.getOptions().editorsRoles
_ref=list.getOptions(),group=_ref.group,roles=_ref.roles
this.editView=new GroupsMemberRolesEditView({delegate:this})
this.editView.setMember(this.getData())
this.editView.setGroup(group)
list.emit("EditMemberRolesViewShown",this)
this.setClass("editing")
this.editLink.hide()
this.cancelLink.show()
this.editContainer.show()
this.editContainer.addSubView(this.editView)
if(editorsRoles){this.editView.setRoles(editorsRoles,roles)
return this.editView.addViews()}return group.fetchMyRoles(function(err,editorsRoles){if(err)return log(err)
list.getOptions().editorsRoles=editorsRoles
_this.editView.setRoles(editorsRoles,roles)
return _this.editView.addViews()})}
GroupsMemberPermissionsListItemView.prototype.hideEditMemberRolesView=function(){this.unsetClass("editing")
this.editLink.show()
this.cancelLink.hide()
this.editContainer.hide()
return this.editContainer.destroySubViews()}
GroupsMemberPermissionsListItemView.prototype.viewAppended=JView.prototype.viewAppended
GroupsMemberPermissionsListItemView.prototype.updateRoles=function(roles){roles.push("member")
this.usersRole=roles
return this.userRole.updatePartial("Roles: "+this.usersRole.join(", "))}
GroupsMemberPermissionsListItemView.prototype.pistachio=function(){return'<div class="kdlistitemview-member-item-inner">\n  <section>\n    <span class="avatar">{{> this.avatar}}</span>\n    {{> this.editLink}}\n    {{> this.cancelLink}}\n    {{> this.profileLink}}\n    {{> this.userRole}}\n  </section>\n  {{> this.editContainer}}\n</div>'}
return GroupsMemberPermissionsListItemView}(KDListItemView)

var GroupsMemberPermissionsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsMemberPermissionsView=function(_super){function GroupsMemberPermissionsView(options,data){var _this=this
null==options&&(options={})
options.cssClass="member-related"
GroupsMemberPermissionsView.__super__.constructor.call(this,options,data)
this._searchValue=null
this.listController=new KDListViewController({itemClass:GroupsMemberPermissionsListItemView,lazyLoadThreshold:.99})
this.listWrapper=this.listController.getView()
this.listController.getListView().on("ItemWasAdded",function(view){return view.on("RolesChanged",_this.memberRolesChange.bind(_this,view))})
this.listController.on("LazyLoadThresholdReached",this.bound("continueLoadingTeasers"))
this.on("teasersLoaded",function(){return _this.listController.scrollView.hasScrollBars()?void 0:_this.continueLoadingTeasers()})
this.refresh()
this.on("SearchInputChanged",function(value){_this._searchValue=value
if(""!==value){_this.timestamp=new Date(0)
_this.listController.removeAllItems()
return _this.fetchSomeMembers()}return _this.refresh()})}__extends(GroupsMemberPermissionsView,_super)
GroupsMemberPermissionsView.prototype.fetchRoles=function(callback){var groupData,list
null==callback&&(callback=function(){})
groupData=this.getData()
list=this.listController.getListView()
list.getOptions().group=groupData
return groupData.fetchRoles(function(err,roles){return err?warn(err):list.getOptions().roles=roles})}
GroupsMemberPermissionsView.prototype.fetchSomeMembers=function(selector){var JAccount,options,_this=this
null==selector&&(selector={})
this.listController.showLazyLoader(!1)
options={limit:20,sort:{timestamp:-1}}
if(this._searchValue){JAccount=KD.remote.api.JAccount
return JAccount.byRelevance(this._searchValue,options,function(err,members){return _this.populateMembers(err,members)})}return this.getData().fetchMembers(selector,options,function(err,members){return _this.populateMembers(err,members)})}
GroupsMemberPermissionsView.prototype.populateMembers=function(err,members){var ids,member,_this=this
if(err)return warn(err)
this.listController.hideLazyLoader()
if(members.length>0){ids=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=members.length;_len>_i;_i++){member=members[_i]
_results.push(member._id)}return _results}()
return this.getData().fetchUserRoles(ids,function(err,userRoles){var list,userRole,userRolesHash,_base,_i,_len,_name
if(err)return warn(err)
userRolesHash={}
for(_i=0,_len=userRoles.length;_len>_i;_i++){userRole=userRoles[_i]
null==userRolesHash[_name=userRole.targetId]&&(userRolesHash[_name]=[])
userRolesHash[userRole.targetId].push(userRole.as)}list=_this.listController.getListView()
null==(_base=list.getOptions()).userRoles&&(_base.userRoles=[])
list.getOptions().userRoles=_.extend(list.getOptions().userRoles,userRolesHash)
_this.listController.instantiateListItems(members)
_this.timestamp=new Date(members.last.timestamp_)
return 20===members.length?_this.emit("teasersLoaded"):void 0})}}
GroupsMemberPermissionsView.prototype.refresh=function(){this.listController.removeAllItems()
this.timestamp=new Date(0)
this.fetchRoles()
return this.fetchSomeMembers()}
GroupsMemberPermissionsView.prototype.continueLoadingTeasers=function(){return this.fetchSomeMembers({timestamp:{$lt:this.timestamp.getTime()}})}
GroupsMemberPermissionsView.prototype.memberRolesChange=function(view,member,roles){return this.getData().changeMemberRoles(member.getId(),roles,function(err){return err?void 0:view.updateRoles(roles)})}
GroupsMemberPermissionsView.prototype.pistachio=function(){return"{{> this.listWrapper}}"}
return GroupsMemberPermissionsView}(JView)

var GroupsMemberRolesEditView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
GroupsMemberRolesEditView=function(_super){function GroupsMemberRolesEditView(options){null==options&&(options={})
GroupsMemberRolesEditView.__super__.constructor.apply(this,arguments)
this.loader=new KDLoaderView({size:{width:22}})}__extends(GroupsMemberRolesEditView,_super)
GroupsMemberRolesEditView.prototype.setRoles=function(editorsRoles,allRoles){allRoles=allRoles.reduce(function(acc,role){var _ref
"owner"!==(_ref=role.title)&&"guest"!==_ref&&"member"!==_ref&&acc.push(role.title)
return acc},[])
return this.roles={usersRole:this.getDelegate().usersRole,allRoles:allRoles,editorsRoles:editorsRoles}}
GroupsMemberRolesEditView.prototype.setMember=function(member){this.member=member}
GroupsMemberRolesEditView.prototype.setGroup=function(group){this.group=group}
GroupsMemberRolesEditView.prototype.getSelectedRoles=function(){return this.checkboxGroup.getValue()}
GroupsMemberRolesEditView.prototype.addViews=function(){var isAdmin,_this=this
this.loader.hide()
isAdmin=__indexOf.call(this.roles.usersRole,"admin")>=0
this.checkboxGroup=new KDInputCheckboxGroup({name:"user-role",cssClassPrefix:"role-",defaultValue:this.roles.usersRole,checkboxes:this.roles.allRoles.map(function(role){var callback
callback="admin"===role?function(){var el,_i,_len,_ref,_results
isAdmin=__indexOf.call(_this.checkboxGroup.getValue(),"admin")>=0
_ref=_this.checkboxGroup.getInputElements()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){el=_ref[_i]
el=$(el)
if("admin"!==el.val())if(isAdmin){el.removeAttr("checked")
_results.push(el.parent().hide())}else _results.push(el.parent().show())
else _results.push(void 0)}return _results}:function(){}
return{value:role,title:role.capitalize(),visible:"admin"!==role&&isAdmin?!1:!0,callback:callback}})})
this.addSubView(this.checkboxGroup,".checkboxes")
this.addSubView(new KDButtonView({title:"Save",cssClass:"modal-clean-green",callback:function(){_this.getDelegate().emit("RolesChanged",_this.getDelegate().getData(),_this.getSelectedRoles())
_this.getDelegate().hideEditMemberRolesView()
return log("save")}}),".buttons")
this.addSubView(new KDButtonView({title:"Kick",cssClass:"modal-clean-red",callback:function(){return _this.showKickModal()}}),".buttons")
__indexOf.call(this.roles.editorsRoles,"owner")>=0&&this.addSubView(new KDButtonView({title:"Make Owner",cssClass:"modal-clean-gray",callback:function(){return _this.showTransferOwnershipModal()}}),".buttons")
return this.$(".buttons").removeClass("hidden")}
GroupsMemberRolesEditView.prototype.showTransferOwnershipModal=function(){var modal,_this=this
return modal=new GroupsDangerModalView({action:"Transfer Ownership",longAction:"transfer the ownership to this user",callback:function(){return _this.group.transferOwnership(_this.member.getId(),function(err){if(err)return _this.showErrorMessage(err)
new KDNotificationView({title:"Ownership transferred!"})
return modal.destroy()})}},this.group)}
GroupsMemberRolesEditView.prototype.showKickModal=function(){var modal,_this=this
return modal=new KDModalView({title:"Kick Member",content:"<div class='modalformline'>Are you sure you want to kick this member?</div>",height:"auto",overlay:!0,buttons:{Kick:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return _this.group.kickMember(_this.member.getId(),function(err){if(err)return _this.showErrorMessage(err)
_this.getDelegate().destroy()
modal.buttons.Kick.hideLoader()
return modal.destroy()})}},Cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}}})}
GroupsMemberRolesEditView.prototype.showErrorMessage=function(err){return KD.showError(err)}
GroupsMemberRolesEditView.prototype.pistachio=function(){return"{{> this.loader}}\n<div class='checkboxes'/>\n<div class='buttons hidden'/>"}
GroupsMemberRolesEditView.prototype.viewAppended=function(){GroupsMemberRolesEditView.__super__.viewAppended.apply(this,arguments)
return this.loader.show()}
return GroupsMemberRolesEditView}(JView)

var GroupsMembershipPolicyDetailView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsMembershipPolicyDetailView=function(_super){function GroupsMembershipPolicyDetailView(options,data){var group,_this=this
null==options&&(options={})
GroupsMembershipPolicyDetailView.__super__.constructor.call(this,options,data)
this.setClass("policy-view-wrapper")
group=this.getData()
group.fetchMembershipPolicy(function(err,policy){if(err)return new KDNotificationView({title:err.message,duration:1e3})
_this.on("MembershipPolicyChanged",function(formData){return KD.getSingleton("appManager").tell("Groups","updateMembershipPolicy",group,policy,formData)})
return _this.createSubViews(policy)})}__extends(GroupsMembershipPolicyDetailView,_super)
GroupsMembershipPolicyDetailView.prototype.createSubViews=function(policy){var approvalEnabled,dataCollectionEnabled,policyLanguageExists,webhookEndpoint,webhookExists,_this=this
webhookEndpoint=policy.webhookEndpoint,approvalEnabled=policy.approvalEnabled,dataCollectionEnabled=policy.dataCollectionEnabled
webhookExists=!(!webhookEndpoint||!webhookEndpoint.length)
this.enableAccessRequests=new KDOnOffSwitch({defaultValue:approvalEnabled,callback:function(state){return _this.emit("MembershipPolicyChanged",{approvalEnabled:state})}})
this.enableDataCollection=new KDOnOffSwitch({defaultValue:dataCollectionEnabled,callback:function(state){if(state){_this.enableDataCollection.setValue(!1)
return new KDNotificationView({title:"Currently disabled!"})}_this.emit("MembershipPolicyChanged",{dataCollectionEnabled:state})
return _this.formGenerator[state?"show":"hide"]()}})
this.enableWebhooks=new KDOnOffSwitch({defaultValue:webhookExists,callback:function(state){if(state){_this.enableWebhooks.setValue(!1)
return new KDNotificationView({title:"Currently disabled!"})}_this.webhook.hide()
_this.webhookEditor[state?"show":"hide"]()
return state?_this.webhookEditor.setFocus():_this.emit("MembershipPolicyChanged",{webhookEndpoint:null})}})
this.webhook=new GroupsWebhookView({cssClass:webhookExists?void 0:"hidden"},policy)
this.webhookEditor=new GroupsEditableWebhookView({cssClass:"hidden"},policy)
this.on("MembershipPolicyChangeSaved",function(){return console.log("saved",_this.getData())})
this.webhook.on("WebhookEditRequested",function(){_this.webhook.hide()
return _this.webhookEditor.show()})
this.webhookEditor.on("WebhookChanged",function(data){_this.emit("MembershipPolicyChanged",data)
webhookEndpoint=data.webhookEndpoint
webhookExists=!!webhookEndpoint
policy.webhookEndpoint=webhookEndpoint
policy.emit("update")
_this.webhookEditor.hide()
_this.webhook[webhookExists?"show":"hide"]()
return _this.enableWebhooks.setValue(webhookExists)})
if(webhookExists){this.webhookEditor.setValue(webhookEndpoint)
this.webhook.show()}policyLanguageExists=policy.explanation
this.showPolicyLanguageLink=new CustomLinkView({cssClass:"edit-link "+(policyLanguageExists?"hidden":""),title:"Edit",click:function(event){event.preventDefault()
_this.showPolicyLanguageLink.hide()
return _this.policyLanguageEditor.show()}})
this.policyLanguageEditor=new GroupsMembershipPolicyLanguageEditor({cssClass:policyLanguageExists?void 0:"hidden"},policy)
this.policyLanguageEditor.on("EditorClosed",function(){return _this.showPolicyLanguageLink.show()})
this.policyLanguageEditor.on("PolicyLanguageChanged",function(data){var explanation,explanationExists
_this.emit("MembershipPolicyChanged",data)
explanation=data.explanation
explanationExists=!!explanation
policy.explanation=explanation
return policy.emit("update")})
this.formGenerator=new GroupsFormGeneratorView({cssClass:dataCollectionEnabled?void 0:"hidden",delegate:this},policy)
return JView.prototype.viewAppended.call(this)}
GroupsMembershipPolicyDetailView.prototype.pistachio=function(){return'{{> this.enableAccessRequests}}\n<section class="formline">\n  <h2>Users may request access</h2>\n  <div class="formline">\n    <p>If you disable this feature, users will not be able to request\n    access to this group.  Turn this off to globally disable new\n    invitations and approval requests.</p>\n  </div>\n</section>\n{{> this.enableDataCollection}}\n<section class="formline">\n  <h2>Enable data collection</h2>\n  <div class="formline">\n    <p>This will allow you to collect additional data from users who\n    request access to your group.</p>\n  </div>\n\n  {{> this.formGenerator}}\n</section>\n{{> this.enableWebhooks}}\n<section class="formline">\n  <h2>Webhooks</h2>\n  <div class="formline">\n    <p>If you enable webhooks, then we will post some data to your webhooks\n    when someone requests access to the group.  The business logic at your\n    endpoint will be responsible for validating and approving the request</p>\n    <p>Webhooks and invitations may be used together.</p>\n  </div>\n  {{> this.webhook}}\n  {{> this.webhookEditor}}\n</section>\n{{> this.showPolicyLanguageLink}}\n<section class="formline clearfix">\n  <h2>Policy language</h2>\n  <div class="formline">\n    <div class=\'policy-language-image-wrapper\'>\n      <img src=\'/images/policy-language-modal.jpg\' alt=\'the policy language modal\' class=\'policy-language-image\'/>\n      <span class=\'legend\'>This modal will be presented to people who request access.</span>\n    </div>\n    <p>It\'s possible to compose custom policy language (copy) to help your\n    users better understand how they may become members of your group.</p>\n    <p>The screenshot on the right shows where this text will be presented to the user.</p>\n    <p>If you wish, you may click \'Edit\' to the left and then enter custom language below (markdown is OK):</p>\n  </div>\n  {{> this.policyLanguageEditor}}\n</section>'}
return GroupsMembershipPolicyDetailView}(KDView)

var GroupsInvitationView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
GroupsInvitationView=function(_super){function GroupsInvitationView(options,data){var _this=this
null==options&&(options={})
options.cssClass="member-related"
GroupsInvitationView.__super__.constructor.call(this,options,data)
this.getData().fetchMembershipPolicy(function(err,policy){var tabHandleContainer,_ref
_this.policy=policy
_this.addSubView(tabHandleContainer=new KDCustomHTMLView)
_this.addSubView(_this.tabView=new GroupsInvitationTabView({delegate:_this,tabHandleClass:GroupTabHandleView,tabHandleContainer:tabHandleContainer},data))
return(null!=(_ref=_this.policy.communications)?_ref.inviteApprovedMessage:void 0)?void 0:_this.saveInviteMessage("inviteApprovedMessage",_this.getDefaultInvitationMessage())})
this.on("SearchInputChanged",function(value){return _this.tabView.getActivePane().mainView.emit("SearchInputChanged",value)})}__extends(GroupsInvitationView,_super)
GroupsInvitationView.prototype.showModalForm=function(options){var form,modal
modal=new KDModalViewWithForms({cssClass:options.cssClass,title:options.title,content:options.content,overlay:!0,width:options.width||400,height:options.height||"auto",tabs:{forms:{invite:{callback:options.callback,buttons:{Send:{itemClass:KDButtonView,testPath:"groups-dashboard-invite-button",title:options.submitButtonLabel||"Send",type:"submit",loader:{color:"#444444",diameter:12}},Cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}},fields:options.fields}}}})
form=modal.modalTabs.forms.invite
form.on("FormValidationFailed",function(){return form.buttons.Send.hideLoader()})
return modal}
GroupsInvitationView.prototype.showCreateInvitationCodeModal=function(){var _this=this
return KD.remote.api.JInvitation.suggestCode(function(err,suggestedCode){return err?_this.showErrorMessage(err):_this.createInvitationCode=_this.showModalForm({title:"Create an Invitation Code",cssClass:"create-invitation-code",callback:function(formData){return KD.remote.api.JInvitation.createMultiuse(formData,_this.modalCallback.bind(_this,_this.createInvitationCode,function(err){var _ref
return 11e3!==err.code?null!=(_ref=err.message)?_ref:"An error occured! Please try again later.":"Invitation code already exists. Please try a different one or leave empty to generate"}))},submitButtonLabel:"Create",fields:{invitationCode:{label:"Invitation code",itemClass:KDInputView,name:"code",placeholder:"Enter a creative invitation code!",defaultValue:suggestedCode,nextElement:{Suggest:{itemClass:KDButtonView,cssClass:"clean-gray suggest-button",callback:function(){return KD.remote.api.JInvitation.suggestCode(function(err,suggestedCode){var form
if(err)return _this.showErrorMessage(err)
form=_this.createInvitationCode.modalTabs.forms.invite
return form.inputs.invitationCode.setValue(suggestedCode)})}}}},maxUses:{label:"Maximum uses",itemClass:KDInputView,name:"maxUses",placeholder:"How many times can this code be redeemed?"},memo:{label:"Memo",itemClass:KDInputView,name:"memo",placeholder:"(optional)"}}})})}
GroupsInvitationView.prototype.getDefaultInvitationMessage=function(){return"Hi there,\n\n#INVITER# has invited you to the group "+this.getData().title+".\n\nThis link will allow you to join the group: #URL#\n\nIf you reply to this email, it will go to #INVITER#.\n\nEnjoy! :)"}
GroupsInvitationView.prototype.showEditInviteMessageModal=function(){var _ref,_this=this
return this.editInviteMessage=this.showModalForm({title:"Edit Invitation Message",cssClass:"edit-invitation-message",submitButtonLabel:"Save",callback:function(_arg){var message
message=_arg.message
return _this.saveInviteMessage("inviteApprovedMessage",message,function(err){_this.editInviteMessage.modalTabs.forms.invite.buttons.Send.hideLoader()
if(err)return _this.showErrorMessage(err)
new KDNotificationView({title:"Message saved"})
return _this.editInviteMessage.destroy()})},fields:{message:{label:"Message",type:"textarea",cssClass:"message-input",defaultValue:Encoder.htmlDecode((null!=(_ref=this.policy.communications)?_ref.inviteApprovedMessage:void 0)||this.getDefaultInvitationMessage()),validate:{rules:{required:!0,regExp:/(#URL#)+/},messages:{required:"Message is required!",regExp:"Message must contain #URL# for invitation link!"}}}}})}
GroupsInvitationView.prototype.showInviteByEmailModal=function(){var _ref,_this=this
this.inviteByEmail=this.showModalForm({title:"Invite by Email",cssClass:"invite-by-email",callback:function(_arg){var bcc,emails,message,saveMessage
emails=_arg.emails,message=_arg.message,saveMessage=_arg.saveMessage,bcc=_arg.bcc
return KD.whoami().fetchFromUser("email",function(err,userEmail){var emailList
emailList=emails.split(/\n/).map(function(email){return email.trim()})
if(__indexOf.call(emailList,userEmail)>=0){_this.inviteByEmail.modalTabs.forms.invite.buttons.Send.hideLoader()
return new KDNotificationView({title:"You cannot invite yourself!"})}return _this.getData().inviteByEmails(emails,{message:message,bcc:bcc},function(err){_this.modalCallback(_this.inviteByEmail,noop,err)
return saveMessage?_this.saveInviteMessage("invitationMessage",message):void 0})})},fields:{emails:{label:"Emails",type:"textarea",cssClass:"emails-input",testPath:"groups-dashboard-invite-list",placeholder:"Enter each email address on a new line...",validate:{rules:{required:!0},messages:{required:"At least one email address required!"}}},message:{label:"Message",type:"textarea",cssClass:"message-input",defaultValue:Encoder.htmlDecode((null!=(_ref=this.policy.communications)?_ref.invitationMessage:void 0)||this.getDefaultInvitationMessage()),validate:{rules:{required:!0,regExp:/(#URL#)+/},messages:{required:"Message is required!",regExp:"Message must contain #URL# for invitation link!"}}},saveMessage:{type:"checkbox",cssClass:"save-message",defaultValue:!1,nextElement:{saveMsgLabel:{itemClass:KDLabelView,title:"Remember this message",click:function(){return _this.inviteByEmail.modalTabs.forms.invite.fields.saveMessage.subViews.first.subViews.first.getDomElement().click()}}}},bcc:{label:"BCC",type:"text",placeholder:"(optional)"},report:{itemClass:KDScrollView,cssClass:"report"}}})
return this.inviteByEmail.modalTabs.forms.invite.fields.report.hide()}
GroupsInvitationView.prototype.showBulkApproveModal=function(){var subject,_this=this
subject=this.policy.approvalEnabled?"Membership":"Invitation"
this.bulkApprove=this.showModalForm({title:"Bulk Approve "+subject+" Requests",cssClass:"bulk-approve",callback:function(_arg){var bcc,count
count=_arg.count,bcc=_arg.bcc
return _this.getData().sendSomeInvitations(count,{bcc:bcc},function(err,emails){log("successfully approved/invited: ",emails)
return _this.modalCallback(_this.bulkApprove,noop,err)})},submitButtonLabel:this.policy.approvalEnabled?"Approve":"Invite",content:"<div class='modalformline'>Enter how many of the pending "+subject.toLowerCase()+" requests you want to approve:</div>",fields:{count:{label:"No. of requests",type:"text",defaultValue:10,placeholder:"how many requests do you want to approve?",validate:{rules:{regExp:/\d+/i},messages:{regExp:"numbers only please"}}},bcc:{label:"BCC",type:"text",placeholder:"(optional)"},report:{itemClass:KDScrollView,cssClass:"report"}}})
return this.bulkApprove.modalTabs.forms.invite.fields.report.hide()}
GroupsInvitationView.prototype.modalCallback=function(modal,errCallback,err){var form,scrollView
form=modal.modalTabs.forms.invite
form.buttons.Send.hideLoader()
this.tabView.getActivePane().subViews.first.refresh()
if(err){if(Array.isArray(err||form.fields.report)){form.fields.report.show()
scrollView=form.fields.report.subViews.first.subViews.first
err.forEach(function(errLine){errLine=(null!=errLine?errLine.message:void 0)?errLine.message:errLine
return scrollView.setPartial(""+errLine+"<br/>")})
return scrollView.scrollTo({top:scrollView.getScrollHeight()})}return this.showErrorMessage(err,errCallback)}new KDNotificationView({title:"Success!"})
return modal.destroy()}
GroupsInvitationView.prototype.saveInviteMessage=function(messageType,message,callback){var _this=this
null==callback&&(callback=noop)
return this.getData().saveInviteMessage(messageType,message,function(err){var _base
if(err)return callback(err)
null==(_base=_this.policy).communications&&(_base.communications={})
_this.policy.communications[messageType]=message
return callback(null)})}
GroupsInvitationView.prototype.showErrorMessage=function(err){var _ref,_ref1
warn(err)
return new KDNotificationView({title:null!=(_ref=null!=(_ref1="function"==typeof msgCallback?msgCallback(err):void 0)?_ref1:err.message)?_ref:"An error occured! Please try again later.",duration:2e3})}
return GroupsInvitationView}(KDView)

var GroupPermissionsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupPermissionsView=function(_super){function GroupPermissionsView(){var addPermissionsView,group,_this=this
GroupPermissionsView.__super__.constructor.apply(this,arguments)
this.setClass("permissions-view")
group=this.getData()
this.loader=new KDLoaderView({cssClass:"loader"})
this.loaderText=new KDView({partial:"Loading Permissions...",cssClass:" loader-text"})
addPermissionsView=function(newPermissions){return group.fetchRoles(function(err,roles){return group.fetchPermissions(function(err,permissionSet){_this.loader.hide()
_this.loaderText.hide()
if(err)return _this.addSubView(new KDView({partial:"No access"}))
newPermissions&&(permissionSet.permissions=newPermissions)
_this.permissions&&_this.permissions.destroy()
_this.addSubView(_this.permissions=new PermissionsForm({privacy:group.privacy,permissionSet:permissionSet,roles:roles,delegate:_this},group))
_this.permissions.emit("RoleViewRefreshed")
return _this.permissions.on("RoleWasAdded",function(newPermissions,role,copy){var copiedPermissions,item,permission,_i,_len
copiedPermissions=[]
for(permission in newPermissions)__hasProp.call(newPermissions,permission)&&newPermissions[permission].role===copy&&copiedPermissions.push({module:newPermissions[permission].module,permissions:newPermissions[permission].permissions,role:role})
for(_i=0,_len=copiedPermissions.length;_len>_i;_i++){item=copiedPermissions[_i]
newPermissions.push(item)}addPermissionsView(newPermissions)
return _this.permissions.emit("RoleViewRefreshed")})})})}
this.loader.show()
this.loaderText.show()
addPermissionsView()}__extends(GroupPermissionsView,_super)
GroupPermissionsView.prototype.viewAppended=function(){GroupPermissionsView.__super__.viewAppended.apply(this,arguments)
this.loader.show()
return this.loaderText.show()}
GroupPermissionsView.prototype.pistachio=function(){return"{{> this.loader}}\n{{> this.loaderText}}"}
return GroupPermissionsView}(JView)

var GroupsBlockedUserListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsBlockedUserListItemView=function(_super){function GroupsBlockedUserListItemView(options,data){var list,roles,userRoles,_ref,_this=this
null==options&&(options={})
options.cssClass="formline clearfix"
options.type="member-item"
GroupsBlockedUserListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
list=this.getDelegate()
_ref=list.getOptions(),roles=_ref.roles,userRoles=_ref.userRoles
this.avatar=new AvatarStaticView({},data)
this.profileLink=new ProfileTextView({},data)
this.usersRole=userRoles[data.getId()]
this.userRole=new KDCustomHTMLView({partial:"Roles: "+this.usersRole.join(", "),cssClass:"ib role"})
this.blockedUntil=new KDCustomHTMLView({partial:"BlockedUntil: "+this.data.blockedUntil,cssClass:""})
this.unblockButton=new KDButtonView({title:"Unblock",callback:function(){return KD.whoami().unblockUser(_this.getData().getId(),function(err){if(err)return warn(err)
new KDNotificationView({title:"User is unblocked!"})
return _this.hide()})}})
list.on("EditMemberRolesViewShown",function(listItem){return listItem!==_this?_this.hideEditMemberRolesView():void 0})}__extends(GroupsBlockedUserListItemView,_super)
GroupsBlockedUserListItemView.prototype.blockUser=function(accountId,duration,callback){return KD.whoami().blockUser(accountId,duration,callback)}
GroupsBlockedUserListItemView.prototype.hideEditMemberRolesView=function(){return this.unsetClass("editing")}
GroupsBlockedUserListItemView.prototype.viewAppended=JView.prototype.viewAppended
GroupsBlockedUserListItemView.prototype.updateRoles=function(roles){roles.push("member")
this.usersRole=roles
return this.userRole.updatePartial("Roles: "+this.usersRole.join(", "))}
GroupsBlockedUserListItemView.prototype.pistachio=function(){return'<div class="kdlistitemview-member-item-inner">\n  <section>\n    <span class="avatar">{{> this.avatar}}</span>\n    {{> this.profileLink}}\n    {{> this.userRole}}\n    {{> this.blockedUntil}}\n    {{> this.unblockButton}}\n  </section>\n</div>'}
return GroupsBlockedUserListItemView}(KDListItemView)

var GroupsBlockedUserView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsBlockedUserView=function(_super){function GroupsBlockedUserView(options,data){var _this=this
null==options&&(options={})
options.cssClass="member-related"
GroupsBlockedUserView.__super__.constructor.call(this,options,data)
this.listController=new KDListViewController({itemClass:GroupsBlockedUserListItemView,lazyLoadThreshold:.99})
this.listWrapper=this.listController.getView()
this.listController.getListView().on("ItemWasAdded",function(view){return view.on("RolesChanged",_this.memberRolesChange.bind(_this,view))})
this.listController.on("LazyLoadThresholdReached",this.bound("continueLoadingTeasers"))
this.on("teasersLoaded",function(){return _this.listController.scrollView.hasScrollBars()?void 0:_this.continueLoadingTeasers()})
this.refresh()}__extends(GroupsBlockedUserView,_super)
GroupsBlockedUserView.prototype.fetchRoles=function(callback){var groupData,list
null==callback&&(callback=function(){})
groupData=this.getData()
list=this.listController.getListView()
list.getOptions().group=groupData
return groupData.fetchRoles(function(err,roles){return err?warn(err):list.getOptions().roles=roles})}
GroupsBlockedUserView.prototype.fetchSomeMembers=function(selector){var JAccount,options,_this=this
null==selector&&(selector={})
this.listController.showLazyLoader(!1)
options={limit:10}
JAccount=KD.remote.api.JAccount
return JAccount.fetchBlockedUsers(options,function(err,blockedUsers){return _this.populateBlockedUsers(err,blockedUsers)})}
GroupsBlockedUserView.prototype.populateBlockedUsers=function(err,users){var ids,member,_this=this
if(err)return warn(err)
this.listController.hideLazyLoader()
if(users.length>0){ids=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=users.length;_len>_i;_i++){member=users[_i]
_results.push(member._id)}return _results}()
return this.getData().fetchUserRoles(ids,function(err,userRoles){var list,listOptions,userRole,userRolesHash,_i,_len,_name
if(err)return warn(err)
userRolesHash={}
for(_i=0,_len=userRoles.length;_len>_i;_i++){userRole=userRoles[_i]
null==userRolesHash[_name=userRole.targetId]&&(userRolesHash[_name]=[])
userRolesHash[userRole.targetId].push(userRole.as)}list=_this.listController.getListView()
listOptions=list.getOptions()
null==listOptions.userRoles&&(listOptions.userRoles=[])
listOptions.userRoles=_.extend(listOptions.userRoles,userRolesHash)
_this.listController.instantiateListItems(users)
_this.timestamp=new Date(users.last.timestamp_)
return 20===users.length?_this.emit("teasersLoaded"):void 0})}}
GroupsBlockedUserView.prototype.refresh=function(){this.listController.removeAllItems()
this.timestamp=new Date
this.fetchRoles()
return this.fetchSomeMembers()}
GroupsBlockedUserView.prototype.continueLoadingTeasers=function(){return this.fetchSomeMembers({timestamp:{$lt:this.timestamp.getTime()}})}
GroupsBlockedUserView.prototype.memberRolesChange=function(view,member,roles){return this.getData().changeMemberRoles(member.getId(),roles,function(err){return err?void 0:view.updateRoles(roles)})}
GroupsBlockedUserView.prototype.pistachio=function(){return"{{> this.listWrapper}}"}
return GroupsBlockedUserView}(JView)

var GroupsInvitationCodeListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsInvitationCodeListItemView=function(_super){function GroupsInvitationCodeListItemView(options,data){null==options&&(options={})
options.cssClass="formline clearfix"
options.type="invitation-request invitation-code"
GroupsInvitationCodeListItemView.__super__.constructor.call(this,options,data)
this.editButton=new KDButtonView({style:"clean-gray",title:"Edit",icon:!0,iconClass:"edit",callback:this.bound("showEditModal")})
this.shareButton=new KDButtonView({style:"clean-gray",title:"Share",icon:!0,iconClass:"share",callback:this.bound("showShareModal")})
this.statusText=new KDCustomHTMLView({partial:'<span class="icon"></span><span class="title"></span>',cssClass:"status hidden"})}__extends(GroupsInvitationCodeListItemView,_super)
GroupsInvitationCodeListItemView.prototype.showEditModal=function(){var maxUses,memo,modal,_ref,_this=this
_ref=this.getData(),maxUses=_ref.maxUses,memo=_ref.memo
return modal=new KDModalViewWithForms({cssClass:"invitation-share-modal",title:"Share Invitation Code",overlay:!0,width:400,height:"auto",tabs:{forms:{invite:{callback:function(formData){return _this.getData().modifyMultiuse(formData,function(err){KD.showError(err)
new KDNotificationView({title:"Invitation code updated!",duration:2e3})
return modal.destroy()})},buttons:{Save:{itemClass:KDButtonView,style:"modal-clean-green",type:"submit",loader:{color:"#444444",diameter:12}},Cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}},fields:{maxUses:{itemClass:KDInputView,label:"Maximum Uses",defaultValue:maxUses,validate:{rules:{regExp:/\d+/i},messages:{regExp:"numbers only please"}}},memo:{label:"Memo",itemClass:KDInputView,name:"memo",defaultValue:memo,placeholder:"(optional)"}}}}}})}
GroupsInvitationCodeListItemView.prototype.showShareModal=function(){var modal
return modal=new KDModalViewWithForms({cssClass:"invitation-share-modal",title:"Share Invitation Code",overlay:!0,width:400,height:"auto",tabs:{forms:{invite:{buttons:{Close:{itemClass:KDButtonView,style:"modal-clean-green",loader:{color:"#ffffff",diameter:12},callback:function(){return modal.destroy()}}},fields:{link:{itemClass:KDInputView,label:"Invitation Link",defaultValue:this.getInvitationUrl()}}}}}})}
GroupsInvitationCodeListItemView.prototype.getInvitationUrl=function(){var code,group,slug,_ref
_ref=this.getData(),group=_ref.group,code=_ref.code
slug=group&&group!==KD.defaultSlug?""+group+"/":""
return"https://"+location.host+"/"+slug+"Invitation/"+code}
GroupsInvitationCodeListItemView.prototype.markDeleted=function(){this.statusText.setClass("deleted")
this.statusText.$("span.title").html("Deleted")
this.statusText.unsetClass("hidden")
this.editButton.hide()
return this.shareButton.hide()}
GroupsInvitationCodeListItemView.prototype.viewAppended=JView.prototype.viewAppended
GroupsInvitationCodeListItemView.prototype.pistachio=function(){var code,codeSuffix,maxUses,memo,uses,_ref
_ref=this.getData(),code=_ref.code,maxUses=_ref.maxUses,uses=_ref.uses,memo=_ref.memo
codeSuffix=memo?" ("+memo+")":""
return'<section>\n  <div class="buttons">{{> this.shareButton}} {{> this.editButton}}</div>\n  {{> this.statusText}}\n  <div class="details">\n    <div class="code">'+code+codeSuffix+'</div>\n    <div class="usage">'+uses+" of "+maxUses+" used</div>\n  </div>\n</section>"}
return GroupsInvitationCodeListItemView}(KDListItemView)

var GroupsInvitationListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsInvitationListItemView=function(_super){function GroupsInvitationListItemView(options,data){var _this=this
null==options&&(options={})
options.cssClass="formline clearfix"
options.type="invitation-request"
GroupsInvitationListItemView.__super__.constructor.call(this,options,data)
this.avatar=new AvatarStaticView({size:{width:40,height:40}})
this.profileLink=new KDCustomHTMLView({tagName:"span",partial:this.getData().email})
if(this.getData().username){this.profileLink=new ProfileLinkView({})
KD.remote.cacheable(this.getData().username,function(err,_arg){var account
account=_arg[0]
_this.avatar.setData(account)
_this.avatar.render()
_this.profileLink.setData(account)
return _this.profileLink.render()})}this.approveButton=new KDButtonView({style:"clean-gray",title:"Approve",icon:!0,iconClass:"approve",testPath:"groups-request-approve",callback:function(){return _this.getData().approve(function(err){_this.updateButtons(err,"approved")
return err?void 0:_this.getDelegate().emit("InvitationStatusChanged")})}})
this.declineButton=new KDButtonView({style:"clean-gray",title:"Decline",icon:!0,iconClass:"decline",callback:function(){return _this.getData().decline(function(err){_this.updateButtons(err,"declined")
return err?void 0:_this.getDelegate().emit("InvitationStatusChanged")})}})
this.deleteButton=new KDButtonView({style:"clean-gray",title:"Delete",icon:!0,iconClass:"decline",callback:function(){return _this.getData().remove(function(err){_this.updateButtons(err,"deleted")
return err?void 0:_this.getDelegate().emit("InvitationStatusChanged")})}})
this.statusText=new KDCustomHTMLView({partial:'<span class="icon"></span><span class="title"></span>',cssClass:"status hidden"})}__extends(GroupsInvitationListItemView,_super)
GroupsInvitationListItemView.prototype.decorateButtons=function(){this.approveButton.hide()
this.declineButton.hide()
this.deleteButton.hide()
if("pending"===this.getData().status){this.approveButton.show()
return this.declineButton.show()}return"sent"===this.getData().status?this.deleteButton.show():void 0}
GroupsInvitationListItemView.prototype.decorateStatus=function(){this.statusText.setClass(this.getData().status)
this.statusText.$("span.title").html(this.getData().status.capitalize())
return this.statusText.unsetClass("hidden")}
GroupsInvitationListItemView.prototype.updateButtons=function(err,expectedStatus){if(err)return KD.showError(err)
this.getData().status=expectedStatus
this.decorateStatus()
this.decorateButtons()
return this.getDelegate().getDelegate().emit("UpdatePendingCount")}
GroupsInvitationListItemView.prototype.viewAppended=function(){JView.prototype.viewAppended.call(this)
"pending"!==this.getData().status&&this.decorateStatus()
return this.decorateButtons()}
GroupsInvitationListItemView.prototype.pistachio=function(){var createdAt,requestedAt,status,_ref
_ref=this.getData(),status=_ref.status,requestedAt=_ref.requestedAt,createdAt=_ref.createdAt
return'<section>\n  <div class="buttons">\n    {{> this.approveButton}} {{> this.declineButton}} {{> this.deleteButton}}\n  </div>\n  {{> this.statusText}}\n  <span class="avatar">{{> this.avatar}}</span>\n  <div class="details">\n    {{> this.profileLink}}\n    <div class="requested-at">{{(new Date(#(requestedAt) != null ? #(requestedAt) : #(createdAt))).format(\'mm/dd/yy\')}}</div>\n  </div>\n</section>'}
return GroupsInvitationListItemView}(KDListItemView)

var GroupsInvitationCodesTabPaneView,GroupsInvitationTabPaneView,GroupsMembershipRequestsTabPaneView,GroupsSentInvitationsTabPaneView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsInvitationTabPaneView=function(_super){function GroupsInvitationTabPaneView(options,data){var _this=this
null==options&&(options={})
null==options.showResolved&&(options.showResolved=!1)
GroupsInvitationTabPaneView.__super__.constructor.call(this,options,data)
this.controller=new InvitationRequestListController({delegate:this,itemClass:options.itemClass,noItemFound:options.noItemFound,lazyLoadThreshold:.9,startWithLazyLoader:!0})
this.addSubView(this.listView=this.controller.getView())
this.controller.on("UpdatePendingCount",this.updatePendingCount.bind(this))
this.listView.on("InvitationStatusChanged",function(){var _ref
return null!=(_ref=_this.getDelegate().tabHandle)?_ref.markDirty():void 0})}__extends(GroupsInvitationTabPaneView,_super)
GroupsInvitationTabPaneView.prototype.requestLimit=10
GroupsInvitationTabPaneView.prototype.addListeners=function(){var _this=this
this.on("teasersLoaded",function(){return _this.controller.scrollView.hasScrollBars()?void 0:_this.fetchAndPopulate()})
this.controller.on("LazyLoadThresholdReached",function(){return _this.controller.noItemLeft?_this.controller.hideLazyLoader():_this.fetchAndPopulate()})
return this.on("SearchInputChanged",function(searchValue){_this.searchValue=searchValue
return _this.refresh()})}
GroupsInvitationTabPaneView.prototype.viewAppended=function(){GroupsInvitationTabPaneView.__super__.viewAppended.call(this)
this.addListeners()
return this.fetchAndPopulate()}
GroupsInvitationTabPaneView.prototype.refresh=function(){this.controller.removeAllItems()
this.timestamp=null
this.fetchAndPopulate()
return this.updatePendingCount(this.parent)}
GroupsInvitationTabPaneView.prototype.setShowResolved=function(showResolved){return this.options.showResolved=showResolved}
GroupsInvitationTabPaneView.prototype.updatePendingCount=function(pane){null==pane&&(pane=this.parent)
return this.getData().countInvitationsFromGraph(this.options.type,{status:this.options.unresolvedStatus},function(err,count){return err?void 0:pane.getHandle().updatePendingCount(count)})}
GroupsInvitationTabPaneView.prototype.fetchAndPopulate=function(){var options,_this=this
this.controller.showLazyLoader(!1)
options={timestamp:this.timestamp,requestLimit:this.requestLimit,search:this.searchValue}
this.options.showResolved||(options.status=this.options.unresolvedStatus)
return this.getData().fetchInvitationsFromGraph(this.options.type,options,function(err,results){_this.controller.hideLazyLoader()
results=results.filter(function(res){return null!==res})
if(err||0===results.length){err&&warn(err)
return _this.controller.emit("noItemsFound")}_this.timestamp=results.last[_this.options.timestampField]
_this.controller.instantiateListItems(results)
return results.length===_this.requestLimit?_this.emit("teasersLoaded"):void 0})}
return GroupsInvitationTabPaneView}(KDView)
GroupsMembershipRequestsTabPaneView=function(_super){function GroupsMembershipRequestsTabPaneView(options,data){var _this=this
null==options&&(options={})
options.noItemFound="No requests found."
options.noMoreItemFound="No more requests found."
options.unresolvedStatus="pending"
options.type="InvitationRequest"
options.timestampField="requestedAt"
GroupsMembershipRequestsTabPaneView.__super__.constructor.call(this,options,data)
this.getData().on("NewInvitationRequest",function(){_this.emit("NewInvitationActionArrived")
return _this.parent.tabHandle.markDirty()})}__extends(GroupsMembershipRequestsTabPaneView,_super)
return GroupsMembershipRequestsTabPaneView}(GroupsInvitationTabPaneView)
GroupsSentInvitationsTabPaneView=function(_super){function GroupsSentInvitationsTabPaneView(options,data){null==options&&(options={})
options.noItemFound="No sent invitations found."
options.noMoreItemFound="No more sent invitations found."
options.unresolvedStatus="sent"
options.type="Invitation"
options.timestampField="createdAt"
GroupsSentInvitationsTabPaneView.__super__.constructor.call(this,options,data)}__extends(GroupsSentInvitationsTabPaneView,_super)
return GroupsSentInvitationsTabPaneView}(GroupsInvitationTabPaneView)
GroupsInvitationCodesTabPaneView=function(_super){function GroupsInvitationCodesTabPaneView(options,data){null==options&&(options={})
options.itemClass=GroupsInvitationCodeListItemView
options.noItemFound="No invitation codes found."
options.noMoreItemFound="No more invitation codes found."
options.unresolvedStatus="active"
options.type="InvitationCode"
options.timestampField="createdAt"
GroupsInvitationCodesTabPaneView.__super__.constructor.call(this,options,data)}__extends(GroupsInvitationCodesTabPaneView,_super)
return GroupsInvitationCodesTabPaneView}(GroupsInvitationTabPaneView)

var GroupsInvitationTabView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsInvitationTabView=function(_super){function GroupsInvitationTabView(options,data){var showResolvedLabelView,_ref,_this=this
null==options&&(options={})
options.cssClass||(options.cssClass="invitations-tabs")
options.maxHandleWidth||(options.maxHandleWidth=300)
null==options.hideHandleCloseIcons&&(options.hideHandleCloseIcons=!0)
GroupsInvitationTabView.__super__.constructor.call(this,options,data)
this.buttonContainer=new KDView({cssClass:"button-bar"})
this.getTabHandleContainer().addSubView(this.buttonContainer)
this.showResolvedView=new KDView({cssClass:"show-resolved"})
this.showResolvedView.addSubView(showResolvedLabelView=new KDLabelView({title:"Show Resolved: "}))
this.showResolvedView.addSubView(new KDOnOffSwitch({label:showResolvedLabelView,callback:function(showResolved){_this.showResolved=showResolved
return _this.setResolvedStateInView()}}))
this.approvalEnabled=null!=(_ref=this.getDelegate().policy)?_ref.approvalEnabled:void 0
this.showResolved=!1
this.on("PaneAdded",function(pane){return pane.options.view.updatePendingCount(pane)})
this.createTabs()
this.addHeaderButtons()
this.listenWindowResize()
this.on("viewAppended",this.bound("_windowDidResize"))
this.on("PaneDidShow",this.bound("paneDidShow"))}__extends(GroupsInvitationTabView,_super)
GroupsInvitationTabView.prototype.paneDidShow=function(){var mainView,tabHandle,_ref
this.decorateHeaderButtons()
_ref=this.getActivePane(),tabHandle=_ref.tabHandle,mainView=_ref.mainView
mainView.options.showResolved!==this.showResolved&&this.setResolvedStateInView()
tabHandle.isDirty&&mainView.refresh()
return tabHandle.markDirty(!1)}
GroupsInvitationTabView.prototype.setResolvedStateInView=function(){var view
view=this.getActivePane().subViews.first
view.setShowResolved(this.showResolved)
return view.refresh()}
GroupsInvitationTabView.prototype.createTabs=function(){var defaultTab,i,tab,_i,_len,_ref,_results
defaultTab="public"===this.getData().privacy?1:0
_ref=this.getTabs()
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){tab=_ref[i]
tab.view=new tab.viewOptions.viewClass({delegate:this},this.getData())
_results.push(this.addPane(new KDTabPaneView(tab),i===defaultTab))}return _results}
GroupsInvitationTabView.prototype.addHeaderButtons=function(){var bulkSubject
bulkSubject=this.approvalEnabled?"Approve":"Invite"
this.buttonContainer.addSubView(this.showResolvedView)
this.buttonContainer.addSubView(this.editInvitationMessageButtion=new KDButtonView({title:"Edit Invitation Message",cssClass:"clean-gray",callback:this.getDelegate().showEditInviteMessageModal.bind(this.getDelegate())}))
this.buttonContainer.addSubView(this.bulkApproveButton=new KDButtonView({title:"Bulk "+bulkSubject,cssClass:"clean-gray",callback:this.getDelegate().showBulkApproveModal.bind(this.getDelegate())}))
this.buttonContainer.addSubView(this.inviteByEmailButton=new KDButtonView({title:"Invite by Email",cssClass:"clean-gray",testPath:"groups-dashboard-invite-button",callback:this.getDelegate().showInviteByEmailModal.bind(this.getDelegate())}))
this.buttonContainer.addSubView(this.createInvitationCodeButton=new KDButtonView({title:"Create Invitation Code",cssClass:"clean-gray",callback:this.getDelegate().showCreateInvitationCodeModal.bind(this.getDelegate())}))
return this.decorateHeaderButtons()}
GroupsInvitationTabView.prototype.decorateHeaderButtons=function(){var button,_i,_len,_ref
_ref=this.buttonContainer.subViews.slice(1)
for(_i=0,_len=_ref.length;_len>_i;_i++){button=_ref[_i]
button.hide()}switch(this.getActivePane().name){case"Membership Requests":return this.bulkApproveButton.show()
case"Invitation Requests":this.editInvitationMessageButtion.show()
return this.bulkApproveButton.show()
case"Invitations":return this.inviteByEmailButton.show()
case"Invitation Codes":return this.createInvitationCodeButton.show()}}
GroupsInvitationTabView.prototype.getTabs=function(){return[{name:""+(this.approvalEnabled?"Membership":"Invitation")+" Requests",hiddenHandle:"public"===this.getData().privacy,viewOptions:{viewClass:GroupsMembershipRequestsTabPaneView}},{name:"Invitations",testPath:"groups-dashboard-invitations",viewOptions:{viewClass:GroupsSentInvitationsTabPaneView}},{name:"Invitation Codes",hiddenHandle:"public"===this.getData().privacy,viewOptions:{viewClass:GroupsInvitationCodesTabPaneView}}]}
GroupsInvitationTabView.prototype._windowDidResize=function(){return this.setHeight(this.parent.getHeight()-this.getTabHandleContainer().getHeight())}
return GroupsInvitationTabView}(KDTabView)

var GroupTabHandleView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupTabHandleView=function(_super){function GroupTabHandleView(options,data){null==options&&(options={})
options.cssClass=this.utils.curry("grouptabhandle",options.cssClass)
GroupTabHandleView.__super__.constructor.call(this,options,data)
this.isDirty=!1
this.currentCount=0}__extends(GroupTabHandleView,_super)
GroupTabHandleView.prototype.viewAppended=function(){this.newCount=new KDCustomHTMLView({tagName:"span",cssClass:"new"})
this.newCount.hide()
this.pendingCount=new KDCustomHTMLView({tagName:"span",cssClass:"pending"})
this.pendingCount.hide()
return JView.prototype.viewAppended.call(this)}
GroupTabHandleView.prototype.updatePendingCount=function(pendingCount){if(pendingCount){this.setClass("has-pending")
this.pendingCount.updatePartial(pendingCount)
return this.pendingCount.show()}this.unsetClass("has-pending")
this.pendingCount.updatePartial("")
return this.pendingCount.hide()}
GroupTabHandleView.prototype.markDirty=function(isDirty){this.isDirty=null!=isDirty?isDirty:!0
if(this.isDirty){this.currentCount++||this.setClass("dirty")
this.newCount.updatePartial(this.currentCount)
this.newCount.show()
return this.pendingCount.hide()}this.currentCount=0
this.unsetClass("dirty")
this.newCount.updatePartial("")
this.newCount.hide()
return this.pendingCount.hasClass("has-pending")?this.pendingCount.show():void 0}
GroupTabHandleView.prototype.pistachio=function(){return""+this.getOptions().title+" {{> this.newCount}}{{> this.pendingCount}}"}
return GroupTabHandleView}(KDTabHandleView)

var BadgeDashboardView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BadgeDashboardView=function(_super){function BadgeDashboardView(options,data){var _this=this
null==options&&(options={})
BadgeDashboardView.__super__.constructor.call(this,options,data)
this.addBadgeButton=new KDButtonView({style:"solid green",title:"add badge",callback:function(){return new NewBadgeForm({badgeListController:_this.badgeListController})}})
this.badgeListController=new KDListViewController({startWithLazyLoader:!1,view:new KDListView({type:"badges",cssClass:"badge-list",itemClass:BadgeListItem})})
KD.remote.api.JBadge.listBadges({},{limit:50},function(err,badges){return err?log("Couldn't fetch badges",err):_this.badgeListController.instantiateListItems(badges)})
this.badgeListView=this.badgeListController.getListView()}__extends(BadgeDashboardView,_super)
BadgeDashboardView.prototype.pistachio=function(){return"{{> this.addBadgeButton}}\n{{> this.badgeListView}}"}
return BadgeDashboardView}(JView)

var BadgeListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BadgeListItem=function(_super){function BadgeListItem(options,data){var description,iconURL,_ref,_this=this
null==options&&(options={})
options.type="badge"
BadgeListItem.__super__.constructor.call(this,options,data)
_ref=this.getData(),iconURL=_ref.iconURL,description=_ref.description
this.badgeIcon=new KDCustomHTMLView({tagName:"img",size:{width:70,height:70},attributes:{src:iconURL,title:description||""}})
this.editButton=new KDButtonView({title:"Modify",cssClass:"edit-badge",style:"solid",callback:function(){var modal
return modal=new BadgeUpdateForm({itemList:_this},{badge:_this.getData()})}})}__extends(BadgeListItem,_super)
BadgeListItem.prototype.viewAppended=JView.prototype.viewAppended
BadgeListItem.prototype.pistachio=function(){return"{{#(title)}}\n{{> this.badgeIcon}}\n{{> this.editButton}}"}
return BadgeListItem}(KDListItemView)

var NewBadgeForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
NewBadgeForm=function(_super){function NewBadgeForm(options,data){var _this=this
null==options&&(options={})
NewBadgeForm.__super__.constructor.call(this,options,data)
this.badgeForm=new KDModalViewWithForms({title:"Add New Badge",overlay:!0,cssClass:"add-badge-modal",width:600,tabs:{callback:function(formData){return _this.createBadgeAndAssign(formData)},navigable:!1,forms:{"New Badge":{buttons:{Add:{title:"Add",style:"modal-clean-green",type:"submit"},Cancel:{title:"Cancel",style:"modal-clean-red"}},fields:{Title:{label:"Title",name:"title",placeholder:"enter the name of the badge",validate:{rules:{required:!0},messages:{required:"add badge name"}}},Icon:{label:"Badge Icon",name:"iconURL",placeholder:"enter the path of badge"},Description:{label:"Description",name:"description",placeholder:"Description of the badge to be showed to user"},Permission:{label:"Permission",itemClass:KDSelectBox,name:"role",defaultValue:"none",selectOptions:[{title:"No Permission",value:"none"}]}}},Rules:{fields:{}}}}})
this.updateRulesTabView()
this.updatePermissionBoxData()}__extends(NewBadgeForm,_super)
NewBadgeForm.prototype.viewAppended=function(){return this.addSubView(this.badgeForm)}
NewBadgeForm.prototype.updatePermissionBoxData=function(){var currentGroup,permissionBox,selectRoles
selectRoles=[]
permissionBox=this.badgeForm.modalTabs.forms["New Badge"].inputs.Permission
currentGroup=KD.getSingleton("groupsController").getCurrentGroup()
return currentGroup.fetchRoles(function(err,roles){var role,title,tmpRoles,_i,_len,_ref
tmpRoles=["admin","owner","guest","member"]
for(_i=0,_len=roles.length;_len>_i;_i++){role=roles[_i]
if(_ref=role.title,__indexOf.call(tmpRoles,_ref)<0){title=role.title
selectRoles.push({title:title,value:title})}}return permissionBox.setSelectOptions(selectRoles)})}
NewBadgeForm.prototype.updateRulesTabView=function(){var parentView
parentView=this.badgeForm.modalTabs.forms.Rules
this.badgeRules=new BadgeRules
return parentView.addSubView(this.badgeRules)}
NewBadgeForm.prototype.createBadgeAndAssign=function(formData){var _this=this
return KD.remote.api.JBadge.create(formData,function(err,badge){var badgeListController,idArray
if(err)return new KDNotificationView({title:err.message})
badgeListController=_this.getOptions().badgeListController
badgeListController.addItem(badge)
_this.badgeRules.emit("BadgeCreated")
idArray=formData.ids.split(",")
return badge.assignBadgeBatch(idArray,function(err){return err?err:void 0})})}
return NewBadgeForm}(KDView)

var BadgeRuleItem,BadgeRules,BadgeUsersItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BadgeRules=function(_super){function BadgeRules(options,data){var listView,userListView,_this=this
null==options&&(options={})
BadgeRules.__super__.constructor.call(this,options,data)
this.badgeRulesListController=new KDListViewController({startWithLazyLoader:!1,view:new KDListView({type:"badges",cssClass:"badge-rules",itemClass:BadgeRuleItem,scrollView:!1,wrapper:!1})})
this.badgeListView=this.badgeRulesListController.getView()
this.addRuleButton=new KDButtonView({name:"addrule",style:"add-new-rule solid green",title:"Add new rule",callback:function(){return _this.badgeRulesListController.addItem({})}})
this.doneButton=new KDButtonView({name:"listdone",style:"rule-set-done solid green",title:"done",callback:function(){_this.createUserSelector()
return _this.giveBadgeButton.show()}})
this.filteredUsersController=new KDListViewController({startWithLazyLoader:!1,view:new KDListView({type:"users",cssClass:"user-list",itemClass:BadgeUsersItem})})
this.giveBadgeButton=new KDButtonView({name:"createbadge",style:"create-badge-button solid green",title:"Create",type:"submit",loader:{color:"#ffffff",diameter:21}})
this.usersInput=new KDInputView({type:"hidden",name:"ids"})
this.rule=new KDInputView({type:"hidden",name:"rule"})
this.userList=this.filteredUsersController.getView()
userListView=this.filteredUsersController.getListView()
listView=this.badgeRulesListController.getListView()
listView.on("RemoveRuleFromList",function(item){return _this.badgeRulesListController.removeItem(item)})
this.giveBadgeButton.hide()
this.once("BadgeCreated",function(){_this.giveBadgeButton.loader.hide()
_this.giveBadgeButton.hide()
_this.addRuleButton.hide()
_this.doneButton.hide()
return new KDNotificationView({title:"Badge created",duration:"2000"})})
userListView.on("RemoveBadgeUser",function(ac){var index,tmpArr
tmpArr=_this.usersInput.getValue().split(",")
index=tmpArr.indexOf(ac._id)
tmpArr.splice(index,1)
_this.usersInput.setValue(tmpArr.toString())
return _this.usersInput.getValue()})
this.badge=this.getOptions().badge
this.badge&&this.updateRulesList()}__extends(BadgeRules,_super)
BadgeRules.prototype.createUserSelector=function(){var action,countProp,key,operArr,propVal,property,ruleItem,ruleItems,rules,selector,tmpAct,_i,_len,_this=this
selector={}
rules=""
ruleItems=this.badgeRulesListController.getItemsOrdered()
for(key=_i=0,_len=ruleItems.length;_len>_i;key=++_i){ruleItem=ruleItems[key]
countProp=ruleItem.propertySelect.getValue()
property="counts."+countProp
tmpAct=ruleItem.propertyAction.getValue()
propVal=ruleItem.propertyVal.getValue()
operArr={}
action="<"===tmpAct?"$lt":"$gt"
operArr[action]=propVal
selector[property]=operArr
rules+=countProp+tmpAct+propVal
key<ruleItems.length-1&&(rules+="+")}this.rule.setValue(rules)
return KD.remote.api.JAccount.someWithRelationship(selector,{},function(err,users){var user
if(err)return err
_this.usersInput.setValue(function(){var _j,_len1,_results
_results=[]
for(_j=0,_len1=users.length;_len1>_j;_j++){user=users[_j]
_results.push(user._id)}return _results}())
_this.filteredUsersController.removeAllItems()
return _this.filteredUsersController.instantiateListItems(users)})}
BadgeRules.prototype.updateRulesList=function(){var action,actionPos,decoded,propVal,property,rule,ruleArray,_i,_len,_results
ruleArray=this.badge.rule.split("+")
_results=[]
for(_i=0,_len=ruleArray.length;_len>_i;_i++){rule=ruleArray[_i]
decoded=Encoder.htmlDecode(rule)
actionPos=decoded.search(/[\<\>\=]/)
action=decoded.substr(actionPos,1)
property=decoded.substr(0,actionPos)
propVal=decoded.substr(actionPos+1)
_results.push(this.badgeRulesListController.addItem({property:property,action:action,propVal:propVal}))}return _results}
BadgeRules.prototype.pistachio=function(){return"{{> this.addRuleButton}}\n{{> this.badgeListView}}\n{{> this.doneButton}}\n{{> this.userList}}\n{{> this.giveBadgeButton}}\n{{> this.usersInput}}\n{{> this.rule}}"}
return BadgeRules}(JView)
BadgeUsersItem=function(_super){function BadgeUsersItem(options,data){var _this=this
null==options&&(options={})
BadgeUsersItem.__super__.constructor.call(this,options,data)
this.avatar=new AvatarImage({origin:this.getData().profile.nickname,size:{width:40}})
this.remove=new KDButtonView({title:"x",cssClass:"solid red",callback:function(){_this.getDelegate().removeItem(_this)
return _this.getDelegate().emit("RemoveBadgeUser",_this.getData())}})}__extends(BadgeUsersItem,_super)
BadgeUsersItem.prototype.viewAppended=JView.prototype.viewAppended
BadgeUsersItem.prototype.pistachio=function(){return"{{> this.avatar}}\n{{#(profile.nickname)}}\n{{> this.remove}}"}
return BadgeUsersItem}(KDListItemView)
BadgeRuleItem=function(_super){function BadgeRuleItem(options,data){var _this=this
null==options&&(options={})
options.cssClass="rule-item"
BadgeRuleItem.__super__.constructor.call(this,options,data)
this.propertySelect=new KDSelectBox({name:"rule-property",selectOptions:[{title:"Follower",value:"followers"},{title:"Likes",value:"likes"},{title:"Topics",value:"topics"},{title:"Follows",value:"following"},{title:"Comments",value:"comments"},{title:"Invitations",value:"invitations"},{title:"Referred Users",value:"referredUsers"},{title:"Last Login",value:"lastLoginDate"},{title:"Status Updates",value:"statusUpdates"},{title:"Twitter Followers",value:"twitterFollowers"}],defaultValue:data.property||"followers",disabled:!!data.propVal})
this.propertyAction=new KDSelectBox({name:"rule-action",selectOptions:[{title:"more than",value:">"},{title:"less then",value:"<"}],defaultValue:data.action||">",disabled:data.propVal?!0:!1})
this.propertyVal=new KDInputView({name:"rule-value",placeholder:"enter value",defaultValue:data.propVal||"",disabled:data.propVal?!0:!1})
this.removeRule=new KDButtonView({name:"removeRule",style:"remove-rule solid red",title:"-",callback:function(){return _this.getDelegate().emit("RemoveRuleFromList",_this)}})
data.propVal&&this.removeRule.hide()}__extends(BadgeRuleItem,_super)
BadgeRuleItem.prototype.viewAppended=JView.prototype.viewAppended
BadgeRuleItem.prototype.pistachio=function(){return"{{> this.propertySelect}}\n{{> this.propertyAction}}\n{{> this.propertyVal}}\n{{> this.removeRule}}"}
return BadgeRuleItem}(KDListItemView)

var BadgeUpdateForm,MemberAutoCompleteItemView,MemberAutoCompletedItemView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
BadgeUpdateForm=function(_super){function BadgeUpdateForm(options,data){var _this=this
null==options&&(options={})
BadgeUpdateForm.__super__.constructor.call(this,options,data)
this.badge=this.getData().badge
this.badgeForm=new KDModalViewWithForms({title:"Modify Badge",overlay:!0,width:700,height:"auto",cssClass:"modify-badge-modal",tabs:{goToNextFormOnSubmit:!1,navigable:!0,forms:{Properties:{callback:function(formData){return _this.badge.modify(formData,function(err){return new KDNotificationView({title:err?err.message:"Badge Updated !",duration:1e3})})},buttons:{Add:{title:"Save",style:"modal-clean-green",type:"submit"}},fields:{Title:{label:"Title",name:"title",defaultValue:this.badge.title,validate:{rules:{required:!0},messages:{required:"badge name required"}}},Icon:{label:"Badge Icon",name:"iconURL",defaultValue:this.badge.iconURL},Description:{label:"Description",name:"description",defaultValue:this.badge.description},Permission:{label:"Permission",itemClass:KDSelectBox,name:"permission",defaultValue:this.badge.role||"none",selectOptions:[{title:"No Permission",value:"none"}]}}},Rules:{fields:{}},Assign:{fields:{Username:{label:"User",type:"hidden",nextElement:{userWrapper:{itemClass:KDView,cssClass:"completed-items"}}}},buttons:{Assign:{label:"",title:"Assign",style:"modal-clean-green",callback:function(){var idArray,user,users,_ref
if((null!=(_ref=_this.userController)?_ref.getSelectedItemData().length:void 0)>0){users=_this.userController.getSelectedItemData()
idArray=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=users.length;_len>_i;_i++){user=users[_i]
_results.push(user._id)}return _results}()
return _this.badge.assignBadgeBatch(idArray,function(err){new KDNotificationView({title:err?err.message:"Badge given "})
return _this.badgeUserList.loadUserList()})}}}}},Users:{fields:{}},Delete:{fields:{Approval:{title:"",label:"Are you sure ?",itemClass:KDLabelView}},buttons:{Remove:{label:"",title:"Remove",style:"modal-clean-red",callback:function(){var itemList,modal
itemList=_this.getOptions().itemList
return modal=new BadgeRemoveForm({itemList:itemList,delegate:_this},{badge:_this.badge})}}}}}}})
this.updatePermissionBoxData()
this.updateRulesTabView()
this.createUserAutoComplete()
this.updateBadgeUsersList()}__extends(BadgeUpdateForm,_super)
BadgeUpdateForm.prototype.createUserAutoComplete=function(){var buttons,fields,forms,inputs,userRequestLineEdit,_ref,_this=this
forms=this.badgeForm.modalTabs.forms
_ref=forms.Assign,fields=_ref.fields,inputs=_ref.inputs,buttons=_ref.buttons
this.userController=new KDAutoCompleteController({form:forms.Assign,name:"userController",itemClass:MemberAutoCompleteItemView,itemDataPath:"profile.nickname",outputWrapper:fields.userWrapper,selectedItemClass:MemberAutoCompletedItemView,listWrapperCssClass:"users",submitValuesAsText:!0,dataSource:function(args,callback){var inputValue,query
inputValue=args.inputValue
if(/^@/.test(inputValue)){query={"profile.nickname":inputValue.replace(/^@/,"")}
return KD.remote.api.JAccount.one(query,function(err,account){return account?callback([account]):_this.userController.showNoDataFound()})}return KD.remote.api.JAccount.byRelevance(inputValue,{},function(err,accounts){return callback(accounts)})}})
return fields.Username.addSubView(userRequestLineEdit=this.userController.getView())}
BadgeUpdateForm.prototype.updatePermissionBoxData=function(){var currentGroup,permissionBox,selectRoles
selectRoles=[]
permissionBox=this.badgeForm.modalTabs.forms.Properties.inputs.Permission
currentGroup=KD.getSingleton("groupsController").getCurrentGroup()
return currentGroup.fetchRoles(function(err,roles){var role,title,tmpRoles,_i,_len,_ref
tmpRoles=["admin","owner","guest","member"]
for(_i=0,_len=roles.length;_len>_i;_i++){role=roles[_i]
if(_ref=role.title,__indexOf.call(tmpRoles,_ref)<0){title=role.title
selectRoles.push({title:title,value:title})}}return permissionBox.setSelectOptions(selectRoles)})}
BadgeUpdateForm.prototype.updateRulesTabView=function(){var parentView
parentView=this.badgeForm.modalTabs.forms.Rules
return parentView.addSubView(new BadgeRules({badge:this.badge}))}
BadgeUpdateForm.prototype.updateBadgeUsersList=function(){var parentView
parentView=this.badgeForm.modalTabs.forms.Users
this.badgeUserList=new BadgeUsersList({badge:this.badge})
return parentView.addSubView(this.badgeUserList)}
return BadgeUpdateForm}(JView)
MemberAutoCompleteItemView=function(_super){function MemberAutoCompleteItemView(options,data){var userInput
options.cssClass="clearfix member-suggestion-item"
MemberAutoCompleteItemView.__super__.constructor.call(this,options,data)
userInput=options.userInput||this.getDelegate().userInput
this.addSubView(this.profileLink=new AutoCompleteProfileTextView({userInput:userInput,shouldShowNick:!0},data))}__extends(MemberAutoCompleteItemView,_super)
MemberAutoCompleteItemView.prototype.viewAppended=JView.prototype.viewAppended
return MemberAutoCompleteItemView}(KDAutoCompleteListItemView)
MemberAutoCompletedItemView=function(_super){function MemberAutoCompletedItemView(){_ref=MemberAutoCompletedItemView.__super__.constructor.apply(this,arguments)
return _ref}__extends(MemberAutoCompletedItemView,_super)
MemberAutoCompletedItemView.prototype.viewAppended=function(){this.addSubView(this.profileText=new AutoCompleteProfileTextView({},this.getData()))
return{viewAppended:JView.prototype.viewAppended}}
return MemberAutoCompletedItemView}(KDAutoCompletedItem)

var BadgeUsersList,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BadgeUsersList=function(_super){function BadgeUsersList(options,data){var listView,_this=this
null==options&&(options={})
BadgeUsersList.__super__.constructor.call(this,options,data)
this.badge=this.getOptions().badge
this.filteredUsersController=new KDListViewController({startWithLazyLoader:!1,view:new KDListView({type:"users",cssClass:"user-list",itemClass:BadgeUsersItem})})
this.loadUserList()
this.userView=this.filteredUsersController.getView()
listView=this.filteredUsersController.getListView()
listView.on("RemoveBadgeUser",function(account){return _this.badge.removeBadgeFromUser(account,function(err){return err?err:new KDNotificationView({title:"Badge removed",duration:2e3})})})}__extends(BadgeUsersList,_super)
BadgeUsersList.prototype.loadUserList=function(){var _this=this
return KD.remote.api.JBadge.fetchBadgeUsers(this.badge.getId(),{limit:10},function(err,accounts){return _this.filteredUsersController.replaceAllItems(accounts)})}
BadgeUsersList.prototype.viewAppended=function(){return this.addSubView(this.userView)}
return BadgeUsersList}(KDView)

var BadgeRemoveForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BadgeRemoveForm=function(_super){function BadgeRemoveForm(options,data){var _this=this
null==options&&(options={})
options.title||(options.title="Sure ?")
options.tabs={forms:{deleteForm:{buttons:{yes:{title:"YES",style:"modal-clean-green",type:"submit",callback:function(){var badge
badge=_this.getData().badge
return badge.deleteBadge(function(err){var itemList,updateForm
itemList=_this.getOptions().itemList
updateForm=_this.getDelegate()
updateForm.badgeForm.destroy()
itemList.destroy()
_this.destroy()
return err?err:void 0})}},Cancel:{title:"No",style:"modal-clean-red",type:"cancel",callback:function(){return _this.destroy()}}}}}}
BadgeRemoveForm.__super__.constructor.call(this,options,data)}__extends(BadgeRemoveForm,_super)
return BadgeRemoveForm}(KDModalViewWithForms)

var GroupsWebhookView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsWebhookView=function(_super){function GroupsWebhookView(){var _this=this
GroupsWebhookView.__super__.constructor.apply(this,arguments)
this.setClass("webhook")
this.editLink=new CustomLinkView({href:"#",title:"Edit",click:function(event){event.preventDefault()
return _this.emit("WebhookEditRequested")}})}__extends(GroupsWebhookView,_super)
GroupsWebhookView.prototype.pistachio=function(){return"{.endpoint{#(webhookEndpoint)}} {{> this.editLink}}"}
return GroupsWebhookView}(JView)

var GroupsEditableWebhookView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsEditableWebhookView=function(_super){function GroupsEditableWebhookView(){var _this=this
GroupsEditableWebhookView.__super__.constructor.apply(this,arguments)
this.setClass("editable-webhook")
this.webhookEndpointLabel=new KDLabelView({title:"Webhook endpoint"})
this.webhookEndpoint=new KDInputView({label:this.webhookEndpointLabel,name:"title",placeholder:"https://example.com/verify"})
this.saveButton=new KDButtonView({title:"Save",style:"cupid-green",callback:function(){return _this.emit("WebhookChanged",{webhookEndpoint:_this.webhookEndpoint.getValue()})}})}__extends(GroupsEditableWebhookView,_super)
GroupsEditableWebhookView.prototype.setFocus=function(){this.webhookEndpoint.focus()
return this}
GroupsEditableWebhookView.prototype.setValue=function(webhookEndpoint){return this.webhookEndpoint.setValue(webhookEndpoint)}
GroupsEditableWebhookView.prototype.pistachio=function(){return"{{> this.webhookEndpointLabel}}\n{{> this.webhookEndpoint}}\n{{> this.saveButton}}"}
return GroupsEditableWebhookView}(JView)

var GroupsMembershipPolicyLanguageEditor,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsMembershipPolicyLanguageEditor=function(_super){function GroupsMembershipPolicyLanguageEditor(){var policy,_this=this
GroupsMembershipPolicyLanguageEditor.__super__.constructor.apply(this,arguments)
this.setClass("policylanguage-editor")
policy=this.getData()
this.editorLabel=new KDLabelView({title:"Custom Policy Language"})
this.editor=new KDInputViewWithPreview({label:this.editorLabel,type:"textarea",defaultValue:policy.explanation,keydown:function(){return _this.saveButton.enable()},preview:{showInitially:!1}})
this.cancelButton=new KDButtonView({title:"Cancel",cssClass:"clean-gray",callback:function(){_this.hide()
return _this.emit("EditorClosed")}})
this.saveButton=new KDButtonView({title:"Save",cssClass:"cupid-green",callback:function(){_this.saveButton.disable()
return _this.emit("PolicyLanguageChanged",{explanation:_this.editor.getValue()})}})}__extends(GroupsMembershipPolicyLanguageEditor,_super)
GroupsMembershipPolicyLanguageEditor.prototype.pistachio=function(){return"{{> this.editorLabel}}{{> this.editor}}{{> this.saveButton}}{{> this.cancelButton}}"}
return GroupsMembershipPolicyLanguageEditor}(JView)

var FormGeneratorItemView,FormGeneratorMultipleInputItemView,FormGeneratorMultipleInputView,FormGeneratorView,GroupsFormGeneratorView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
FormGeneratorView=function(_super){function FormGeneratorView(options,data){var field,policy,_i,_len,_ref,_this=this
FormGeneratorView.__super__.constructor.call(this,options,data)
this.setClass("form-generator")
this.listController=new KDListViewController({itemClass:FormGeneratorItemView})
this.listWrapper=this.listController.getView()
this.listWrapper.setClass("form-builder")
this.inputTitle=new KDInputView({name:"title",placeholder:'Field title, e.g. "Student ID"',keyup:function(){return _this.inputKey.setValue(_this.utils.slugify(_this.inputTitle.getValue()).replace(/-/g,"_"))},validate:{rules:{required:!0},messages:{required:"A title is required!"}}})
this.inputKey=new KDInputView({name:"key",placeholder:'Field key, e.g. "student_id"'})
this.inputDefault=new KDInputView({name:"defaultValue",placeholder:"Default value"})
this.inputDefaultTextarea=new KDInputView({name:"defaultValueTextarea",type:"textarea",cssClass:"add-textarea"})
this.inputDefaultSelect=new KDSelectBox({name:"defaultValueSelect"})
this.inputDefaultRadio=new KDInputRadioGroup({radios:[],name:"defaultValueRadio"})
this.inputDefaultSwitch=new KDOnOffSwitch({defaultValue:this.getData().defaultValue||!1})
this.inputType=new KDSelectBox({name:"type",cssClass:"type-select",selectOptions:[{title:"Text Field",value:"text"},{title:"Select Box",value:"select"},{title:"On-Off Switch",value:"checkbox"},{title:"Textarea",value:"textarea"},{title:"Radio Button Field",value:"radio"}],change:function(){switch(_this.inputType.getValue()){case"select":return _this.decorateInputs(["Select"])
case"checkbox":return _this.decorateInputs(["Switch"])
case"textarea":return _this.decorateInputs(["Textarea"])
case"radio":return _this.decorateInputs(["Radio"])
default:return _this.decorateInputs()}}})
this.inputFieldsSelect=new FormGeneratorMultipleInputView({cssClass:"select-fields",type:"select",title:"Dropdown"})
this.inputFieldsRadio=new FormGeneratorMultipleInputView({cssClass:"radio-fields",type:"radio",title:"Radio"})
this.inputFieldsSelect.on("InputChanged",function(_arg){var type,value
type=_arg.type,value=_arg.value
_this.inputDefaultSelect.removeSelectOptions()
_this.inputDefaultSelect.setSelectOptions(value)
return _this.inputDefaultSelect.setValue(value[0])})
this.inputFieldsRadio.on("InputChanged",function(_arg){var i,id,item,type,value,_i,_len,_results
type=_arg.type,value=_arg.value
_this.inputDefaultRadio.$().empty()
_results=[]
for(i=_i=0,_len=value.length;_len>_i;i=++_i){item=value[i]
id=_this.utils.getRandomNumber()
_this.inputDefaultRadio.$().append("<div class='kd-radio-holder'>\n  <input id=\""+id+"\" class='no-kdinput' type='radio' name='add-radio' value='"+item.value+"' />\n  <label for=\""+id+'">'+item.title+"</label>\n</div>")
_results.push(_this.inputDefaultRadio.setDefaultValue(value[0]))}return _results})
this.addButton=new CustomLinkView({tagName:"span",title:"Add field",style:"clean-gray",cssClass:"add-button",click:function(){return _this.addFieldToList()}})
this.saveButton=new KDButtonView({title:"Save fields",cssClass:"clean-gray save-button",loader:{diameter:12,color:"#444"},callback:function(){return _this.saveToMembershipPolicy()}})
this.inputDefaultSelect.hide()
this.inputDefaultRadio.hide()
this.inputDefaultSwitch.hide()
this.inputDefaultTextarea.hide()
this.inputFieldsSelect.hide()
this.inputFieldsRadio.hide()
this.listController.listView.on("RemoveButtonClicked",function(instance){return _this.listController.removeItem(instance,{})})
policy=this.getData()
if(policy.fields){_ref=policy.fields
for(_i=0,_len=_ref.length;_len>_i;_i++){field=_ref[_i]
this.listController.addItem({title:field.title||"",defaultValue:field.defaultValue||"",key:field.key,type:field.type||"text",options:field.options})}}}__extends(FormGeneratorView,_super)
FormGeneratorView.prototype.saveToMembershipPolicy=function(){var defaultValue,item,key,newFields,options,title,type,_i,_len,_ref,_ref1,_this=this
newFields=[]
_ref=this.listController.listView.items
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
_ref1=item.getData(),type=_ref1.type,title=_ref1.title,key=_ref1.key,defaultValue=_ref1.defaultValue,options=_ref1.options
newFields.push({key:Encoder.XSSEncode(key),type:type,title:Encoder.XSSEncode(title),defaultValue:"string"==typeof defaultValue?Encoder.XSSEncode(defaultValue):defaultValue,options:options?options:void 0})}this.getDelegate().emit("MembershipPolicyChanged",{fields:newFields})
return this.getDelegate().once("MembershipPolicyChangeSaved",function(){return _this.saveButton.hideLoader()})}
FormGeneratorView.prototype.addFieldToList=function(){var item,key,newItem,_i,_len,_ref
key=this.inputKey.getValue()
newItem=""!==key
_ref=this.listController.listView.items
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
item.getData().key===key&&(newItem=!1)}if(newItem){this.listController.addItem({title:Encoder.XSSEncode(this.inputTitle.getValue()),key:Encoder.XSSEncode(this.inputKey.getValue()),defaultValue:function(){switch(this.inputType.getValue()){case"text":return Encoder.XSSEncode(this.inputDefault.getValue())
case"select":return this.inputDefaultSelect.getValue()
case"checkbox":return this.inputDefaultSwitch.getValue()
case"radio":return this.inputDefaultRadio.getValue()
case"textarea":return this.inputDefaultTextarea.getValue()
default:return Encoder.XSSEncode(this.inputDefault.getValue())}}.call(this),type:this.inputType.getValue(),options:function(){switch(this.inputType.getValue()){case"select":return this.inputFieldsSelect.getValue()
case"radio":return this.inputFieldsRadio.getValue()}}.call(this)})
this.inputTitle.setValue("")
this.inputKey.setValue("")
this.inputDefault.setValue("")
this.inputFieldsSelect.listController.removeAllItems()
this.inputDefaultSelect.removeSelectOptions()
return this.inputDefaultSelect.setValue(null)}return new KDNotificationView({title:""===key?"Please enter a key":"Duplicate key"})}
FormGeneratorView.prototype.decorateInputs=function(show){var input,inputSection,_i,_len,_ref,_results
null==show&&(show=[""])
_ref=["Fields","Default"]
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){inputSection=_ref[_i]
_results.push(function(){var _j,_len1,_ref1,_ref2,_results1
_ref1=["Text","Textarea","Select","Radio","Switch",""]
_results1=[]
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){input=_ref1[_j]
_results1.push(null!=(_ref2=this["input"+inputSection+input])?_ref2[__indexOf.call(show,input)>=0?"show":"hide"]():void 0)}return _results1}.call(this))}return _results}
FormGeneratorView.prototype.pistachio=function(){return'<div class="wrapper">\n  <div class="add-header">\n    <div class="add-type">Field type</div>\n    <div class="add-title">Title</div>\n    <div class="add-key">Key</div>\n    <div class="add-default">Default</div>\n  </div>\n\n  {{> this.listWrapper}}\n\n  <div class="add-inputs">\n    <div class=\'add-input\'>{{> this.inputType}}</div>\n    <div class=\'add-input\'>{{> this.inputTitle}}</div>\n    <div class=\'add-input\'>{{> this.inputKey}}</div>\n    <div class=\'add-input\'>\n      {{> this.inputDefault}}\n      {{> this.inputDefaultSelect}}\n      {{> this.inputDefaultSwitch}}\n      {{> this.inputDefaultRadio}}\n      {{> this.inputDefaultTextarea}}\n      </div>\n    <div class=\'add-input button\'>{{> this.addButton}}</div>\n    <div class=\'add-input select\'>{{> this.inputFieldsSelect}}{{> this.inputFieldsRadio}}</div>\n  </div>\n</div>\n{{> this.saveButton}}'}
return FormGeneratorView}(JView)
FormGeneratorMultipleInputView=function(_super){function FormGeneratorMultipleInputView(options,data){var title,type,_ref,_this=this
FormGeneratorMultipleInputView.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),type=_ref.type,title=_ref.title
this.listController=new KDListViewController({itemClass:FormGeneratorMultipleInputItemView,noItemView:new KDListItemView({cssClass:"default-item",partial:"Please add "+title+" options"})})
this.listWrapper=this.listController.getView()
this.listWrapper.setClass("form-builder-"+type)
this.inputTitle=new KDInputView({cssClass:"title"})
this.addButton=new CustomLinkView({cssClass:"add-button",tagName:"span",title:"Add option",click:function(){_this.listController.addItem({title:Encoder.XSSEncode(_this.inputTitle.getValue()),value:_this.utils.slugify(_this.inputTitle.getValue()).replace(/-/g,"_")})
_this.emit("InputChanged",{type:type,value:_this.getValue()})
return _this.inputTitle.setValue("")}})
this.listController.listView.on("RemoveButtonClicked",function(instance){_this.listController.removeItem(instance,{})
return _this.emit("InputChanged",{type:type,value:_this.getValue()})})}__extends(FormGeneratorMultipleInputView,_super)
FormGeneratorMultipleInputView.prototype.getValue=function(){var data,item,_i,_len,_ref
data=[]
_ref=this.listController.listView.items
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
data.push({title:item.getData().title,value:this.utils.slugify(item.getData().title).replace(/-/g,"_")})}return data}
FormGeneratorMultipleInputView.prototype.pistachio=function(){return"<h3>"+this.getOptions().title+" items</h3>\n{{> this.listWrapper}}\n{{> this.inputTitle}}\n{{> this.addButton}}"}
return FormGeneratorMultipleInputView}(JView)
FormGeneratorMultipleInputItemView=function(_super){function FormGeneratorMultipleInputItemView(options,data){var _this=this
FormGeneratorMultipleInputItemView.__super__.constructor.call(this,options,data)
this.optionTitle=new KDView({cssClass:"title",partial:this.getData().title+(" <span class='value'>("+this.getData().value+")</span>")})
this.removeButton=new CustomLinkView({tagName:"span",cssClass:"clean-gray remove-button",title:"Remove",click:function(){return _this.getDelegate().emit("RemoveButtonClicked",_this)}})}__extends(FormGeneratorMultipleInputItemView,_super)
FormGeneratorMultipleInputItemView.prototype.viewAppended=function(){FormGeneratorMultipleInputItemView.__super__.viewAppended.apply(this,arguments)
this.setTemplate(this.pistachio())
return this.template.update()}
FormGeneratorMultipleInputItemView.prototype.pistachio=function(){return"{{> this.optionTitle}}\n{{> this.removeButton}}"}
return FormGeneratorMultipleInputItemView}(KDListItemView)
FormGeneratorItemView=function(_super){function FormGeneratorItemView(options,data){var defaultValue,key,title,type,_ref,_this=this
FormGeneratorItemView.__super__.constructor.call(this,options,data)
_ref=this.getData(),type=_ref.type,title=_ref.title,key=_ref.key,defaultValue=_ref.defaultValue,options=_ref.options
this.type=new KDView({cssClass:"type",partial:function(){switch(type){case"text":return"Text Field"
case"select":return"Select Box"
case"checkbox":return"On-Off Switch"
case"radio":return"Radio Buttons"
case"textarea":return"Textarea"
default:return"Other"}}(),tooltip:{title:type,placement:"top",direction:"center"}})
this.title=new KDView({cssClass:"title",partial:title,tooltip:{title:title,placement:"top",direction:"center"}})
this.key=new KDView({cssClass:"key",partial:key,tooltip:{title:key,placement:"top",direction:"center"}})
switch(type){case"text":case"textarea":this.defaultValue=new KDView({cssClass:"default "+type,partial:defaultValue||"<span>none</span>",tooltip:{title:defaultValue,placement:"top",direction:"center"}})
break
case"select":this.defaultValue=new KDSelectBox({cssClass:"default",selectOptions:options||[],defaultValue:defaultValue})
break
case"radio":this.defaultValue=new KDInputRadioGroup({radios:options,name:"radios_"+this.utils.getRandomNumber(),cssClass:"default"})
this.defaultValue.setDefaultValue(defaultValue)
break
case"checkbox":this.defaultValue=new KDOnOffSwitch({size:"tiny",cssClass:"default",defaultValue:defaultValue})}this.removeButton=new CustomLinkView({tagName:"span",cssClass:"clean-gray remove-button",title:"Remove",click:function(){return _this.getDelegate().emit("RemoveButtonClicked",_this)}})}__extends(FormGeneratorItemView,_super)
FormGeneratorItemView.prototype.viewAppended=function(){this.setClass("form-item")
this.setTemplate(this.pistachio())
return this.template.update()}
FormGeneratorItemView.prototype.pistachio=function(){return'{{> this.type}}\n{{> this.title}}\n{{> this.key}}\n<div class="default">{{> this.defaultValue}}</div>\n{{> this.removeButton}}'}
return FormGeneratorItemView}(KDListItemView)
GroupsFormGeneratorView=function(_super){function GroupsFormGeneratorView(){_ref=GroupsFormGeneratorView.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupsFormGeneratorView,_super)
return GroupsFormGeneratorView}(FormGeneratorView)

var PermissionsForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
PermissionsForm=function(_super){function PermissionsForm(options,data){var addRoleDialog,group,permissionSet,privacy,role,roles,_this=this
group=data
privacy=options.privacy,permissionSet=options.permissionSet
roles=function(){var _i,_len,_ref,_results
_ref=options.roles
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){role=_ref[_i]
"owner"!==role.title&&_results.push(role.title)}return _results}()
addRoleDialog=null
options.buttons||(options.buttons={"Add Role":{style:"modal-clean-gray",cssClass:"add-role",callback:function(){var copyFormline,form,inputFormline,inputRoleName,labelCopyPermissions,labelRoleName,selectOptions,title,wrapper,_i,_len
null!=addRoleDialog&&addRoleDialog.destroy()
KD.getSingleton("contentPanel").addSubView(addRoleDialog=new KDDialogView({cssClass:"add-role-dialog",duration:200,topOffset:0,overlay:!0,height:"auto",buttons:{"Add Role":{style:"add-role-button modal-clean-gray",cssClass:"add-role-button",loader:{color:"#444444",diameter:12},callback:function(){var copy,name,nameSlug
name=_this.inputRoleName.getValue()
nameSlug=_this.utils.slugify(name)
copy=_this.inputCopyPermissions.getValue()
return group.addCustomRole({title:nameSlug,isConfigureable:!0},function(err,role){err&&log(err)
null!==copy&&log("copying permissions from ",copy," to ",role)
_this.on("RoleViewRefreshed",function(){return _this.utils.wait(500,function(){addRoleDialog.buttons["Add Role"].hideLoader()
return addRoleDialog.hide()})})
return _this.emit("RoleWasAdded",_this.reducedList(),nameSlug,copy)})}},Cancel:{style:"add-role-cancel modal-cancel",cssClass:"add-role-cancel",callback:function(){return addRoleDialog.hide()}}}}))
addRoleDialog.addSubView(wrapper=new KDView({cssClass:"kddialog-wrapper"}))
wrapper.addSubView(title=new KDCustomHTMLView({tagName:"h1",cssClass:"add-role-header",partial:"Add new Role"}))
wrapper.addSubView(form=new KDFormView)
form.addSubView(inputFormline=new KDView({cssClass:"formline"}))
inputFormline.addSubView(labelRoleName=new KDLabelView({cssClass:"label-role-name",title:"Role Name:"}))
inputFormline.addSubView(_this.inputRoleName=inputRoleName=new KDInputView({cssClass:"role-name",label:labelRoleName,defaultValue:"",placeholder:"new-role"}))
form.addSubView(copyFormline=new KDView({cssClass:"formline"}))
copyFormline.addSubView(labelCopyPermissions=new KDLabelView({cssClass:"label-copy-permissions",title:"Copy Permissions from"}))
selectOptions=[{title:"None",value:null}]
for(_i=0,_len=roles.length;_len>_i;_i++){role=roles[_i]
selectOptions.push({title:readableText(role),value:role})}copyFormline.addSubView(_this.inputCopyPermissions=new KDSelectBox({cssClass:"copy-permissions",selectOptions:selectOptions,defaultValue:null}))
return addRoleDialog.show()}},Save:{style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){return group.updatePermissions(_this.reducedList(),function(err){_this.buttons.Save.hideLoader()
err||new KDNotificationView({title:"Group permissions have been updated."})
return KD.showError(err)})}}})
options.fields||(options.fields=optionizePermissions(roles,permissionSet))
PermissionsForm.__super__.constructor.call(this,options,data)
this.setClass("permissions-form col-"+roles.length)}var cascadeFormElements,cascadeHeaderElements,checkForPermission,createReducedList,createTree,optionizePermissions,readableText,_getCheckboxName
__extends(PermissionsForm,_super)
readableText=function(text){var dictionary
dictionary={JTag:"Tags",JNewApp:"Apps",JGroup:"Groups",JPost:"Posts",JVM:"Compute",CActivity:"Activity",JGroupBundle:"Group Bundles",JDomain:"Domains",JProxyFilter:"Proxy Filters"}
return dictionary[text]||text.charAt(0).toUpperCase()+text.slice(1)}
_getCheckboxName=function(module,permission,role){return["permission",module].join("-")+"|"+[role,permission].join("|")}
checkForPermission=function(permissions,module,permission,role){var perm,perm1,_i,_j,_len,_len1,_ref
for(_i=0,_len=permissions.length;_len>_i;_i++){perm=permissions[_i]
if(perm.module===module&&perm.role===role){_ref=perm.permissions
for(_j=0,_len1=_ref.length;_len1>_j;_j++){perm1=_ref[_j]
if(null!=perm1&&perm1===permission)return!0}return!1}}}
cascadeFormElements=function(set,roles,module,permission){var cascadeData,cssClass,current,isChecked,name,remainder
current=roles[0],remainder=2<=roles.length?__slice.call(roles,1):[]
cascadeData={}
isChecked=checkForPermission(set.permissions,module,permission,current)
cssClass="permission-checkbox "+__utils.slugify(permission)+" "+current
name=_getCheckboxName(module,permission,current)
cascadeData[current]={name:name,cssClass:cssClass,itemClass:KDCheckBox,defaultValue:null!=isChecked?isChecked:!1}
if("admin"===current||"owner"===current){cascadeData[current].defaultValue=!0
cascadeData[current].disabled=!0}current&&remainder.length>0&&(cascadeData[current].nextElement=cascadeFormElements(set,remainder,module,permission))
return cascadeData}
cascadeHeaderElements=function(roles){var cascadeData,current,remainder
current=roles[0],remainder=2<=roles.length?__slice.call(roles,1):[]
cascadeData={}
cascadeData[current]={itemClass:KDView,partial:readableText(current),cssClass:"text header-item role-"+__utils.slugify(current),attributes:{title:readableText(current)}}
current&&remainder.length>0&&(cascadeData[current].nextElement=cascadeHeaderElements(remainder))
return cascadeData}
optionizePermissions=function(roles,set){var module,permission,permissionOptions,permissions,_i,_len,_ref
permissionOptions={head:{itemClass:KDView,cssClass:"permissions-header col-"+roles.length,nextElement:cascadeHeaderElements(roles)}}
_ref=set.permissionsByModule
for(module in _ref)if(__hasProp.call(_ref,module)){permissions=_ref[module]
permissionOptions["header "+module.toLowerCase()]={itemClass:KDView,partial:readableText(module),cssClass:"permissions-module text"}
for(_i=0,_len=permissions.length;_len>_i;_i++){permission=permissions[_i]
permissionOptions[module+"-"+__utils.slugify(permission)]={itemClass:KDView,partial:readableText(permission),cssClass:"text",attributes:{title:readableText(permission)},nextElement:cascadeFormElements(set,roles,module,permission)}}}return permissionOptions}
createTree=function(values){return values.reduce(function(acc,_arg){var module,permission,role,_base
module=_arg.module,role=_arg.role,permission=_arg.permission
null==acc[module]&&(acc[module]={})
null==(_base=acc[module])[role]&&(_base[role]=[])
acc[module][role].push(permission)
return acc},{})}
createReducedList=function(values){var cache
cache={}
return values.reduce(function(acc,_arg){var cached,module,permission,role,storageKey
module=_arg.module,role=_arg.role,permission=_arg.permission
storageKey=""+module+":"+role
cached=cache[storageKey]
if(null!=cached)cached.permissions.push(permission)
else{cache[storageKey]={module:module,role:role,permissions:[permission]}
acc.push(cache[storageKey])}return acc},[])}
PermissionsForm.prototype.getFormValues=function(){return this.$().serializeArray().map(function(_arg){var facet,module,name,permission,role,_ref
name=_arg.name
_ref=name.split("|"),facet=_ref[0],role=_ref[1],permission=_ref[2]
module=facet.split("-")[1]
return{module:module,role:role,permission:permission}})};["list","reducedList","tree"].forEach(function(method){return PermissionsForm.prototype[method]=function(){return this.getPermissions(method)}})
PermissionsForm.prototype.getPermissions=function(structure){var values
null==structure&&(structure="reducedList")
values=this.getFormValues()
switch(structure){case"reducedList":return createReducedList(values)
case"list":return values
case"tree":return createTree(values)
default:throw new Error("Unknown structure "+structure)}}
PermissionsForm.prototype.viewAppended=function(){return PermissionsForm.__super__.viewAppended.apply(this,arguments)}
return PermissionsForm}.call(this,KDFormViewWithFields)

var PricingAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PricingAppController=function(_super){function PricingAppController(options,data){null==options&&(options={})
options.view=new PricingAppView({params:options.params,workflow:this.createWorkflow(),cssClass:"content-page pricing"})
options.appInfo={title:"Pricing"}
PricingAppController.__super__.constructor.call(this,options,data)}__extends(PricingAppController,_super)
"localhost"===location.hostname&&KD.registerAppClass(PricingAppController,{name:"Pricing",route:"/Pricing"})
PricingAppController.prototype.createWorkflow=function(){var paymentController,workflow,_this=this
paymentController=KD.getSingleton("paymentController")
workflow=paymentController.createUpgradeWorkflow("vm")
workflow.on("Finished",function(){return _this.getView().showThankYou(workflow.getData())})
return workflow.on("Cancel",function(){return _this.getView().showCancellation()})}
return PricingAppController}(KDViewController)

var PricingAppView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PricingAppView=function(_super){function PricingAppView(){_ref=PricingAppView.__super__.constructor.apply(this,arguments)
return _ref}__extends(PricingAppView,_super)
PricingAppView.prototype.viewAppended=function(){return this.addSubView(this.getOptions().workflow)}
PricingAppView.prototype.hideWorkflow=function(){return this.getOptions().workflow.hide()}
PricingAppView.prototype.showThankYou=function(data){this.hideWorkflow()
this.thankYou=new KDCustomHTMLView({partial:"<h1>Thank you!</h1>\n<p>\n  Your order has been processed.\n</p>\n"+(data.createAccount?"<p>Please check your email for your registration link.</p>":"<p>We hope you enjoy your new subscription</p>")})
data.createAccount||this.thankYou.addSubView(this.getContinuationLinks())
return this.addSubView(this.thankYou)}
PricingAppView.prototype.getContinuationLinks=function(){return new KDCustomHTMLView({partial:'<ul>\n  <li><a href="/Activity">Activity</a></li>\n  <li><a href="/Account">Account</a></li>\n  <li><a href="/Account/Subscriptions">Subscriptions</a></li>\n  <li><a href="/Environments">Environments</a></li>\n</ul>'})}
PricingAppView.prototype.showCancellation=function(){this.hideWorkflow()
this.cancellation=new KDView({partial:"<h1>This order has been cancelled.</h1>"})
return this.addSubView(this.cancellation)}
return PricingAppView}(KDView)

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

//@ sourceMappingURL=/js/__payment.0.0.1.js.map