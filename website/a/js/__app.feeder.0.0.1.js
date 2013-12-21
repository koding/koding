var FeederAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederAppController=function(_super){function FeederAppController(options,data){null==options&&(options={})
options.view=new KDView
options.appInfo={name:"Feeder"}
FeederAppController.__super__.constructor.call(this,options,data)}__extends(FeederAppController,_super)
KD.registerAppClass(FeederAppController,{name:"Feeder",background:!0})
FeederAppController.prototype.createContentFeedController=function(options,callback,feedControllerConstructor){return"function"==typeof callback?callback(null!=feedControllerConstructor?new feedControllerConstructor(options):new FeedController(options)):void 0}
return FeederAppController}(KDController)

var FeedController,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice,__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
FeedController=function(_super){function FeedController(options){var delegate,facetsController,filter,name,resultsController,sort,view,_ref,_ref1,_ref2,_this=this
null==options&&(options={})
this.loadFeed=__bind(this.loadFeed,this)
null==options.autoPopulate&&(options.autoPopulate=!1)
null==options.useHeaderNav&&(options.useHeaderNav=!1)
options.filter||(options.filter={})
options.sort||(options.sort={})
options.limitPerPage||(options.limitPerPage=10)
options.dataType||(options.dataType=null)
options.onboarding||(options.onboarding=null)
options.domId||(options.domId="")
null==options.delegate&&(options.delegate=null)
resultsController=options.resultsController||FeederResultsController
this.resultsController=new resultsController({itemClass:options.itemClass,filters:options.filter,listControllerClass:options.listControllerClass,listCssClass:options.listCssClass||"",delegate:this,onboarding:options.onboarding})
if(options.useHeaderNav){facetsController=options.facetsController||FeederHeaderFacetsController
this.facetsController=new facetsController({filters:options.filter,sorts:options.sort,help:options.help,delegate:this})
view=options.view||(options.view=new FeederSingleView)
view.on("viewAppended",function(){view.addSubView(_this.resultsController.getView())
return view.addSubView(_this.facetsController.getView())})}else{facetsController=options.facetsController||FeederFacetsController
this.facetsController=new facetsController({filters:options.filter,sorts:options.sort,help:options.help,delegate:this})
options.view||(options.view=new FeederSplitView({domId:options.domId,views:[this.facetsController.getView(),this.resultsController.getView()]}))}FeedController.__super__.constructor.call(this,options,null)
options=this.getOptions()
this.filters={}
this.sorts={}
this.defaultQuery=null!=(_ref=options.defaultQuery)?_ref:{}
delegate=options.delegate
delegate?delegate.on("LazyLoadThresholdReached",this.bound("loadFeed")):this.resultsController.on("LazyLoadThresholdReached",this.bound("loadFeed"))
_ref1=options.filter
for(name in _ref1)if(__hasProp.call(_ref1,name)){filter=_ref1[name]
this.defineFilter(name,filter)}_ref2=options.sort
for(name in _ref2)if(__hasProp.call(_ref2,name)){sort=_ref2[name]
this.defineSort(name,sort)}null!=options.dynamicDataType&&this.getNewFeedItems()
this.on("FilterLoaded",function(){return KD.getSingleton("windowController").notifyWindowResizeListeners()})}var USEDFEEDS
__extends(FeedController,_super)
USEDFEEDS=[]
FeedController.prototype.highlightFacets=function(){var filterName,sortName
filterName=this.selection.name
sortName=this.selection.activeSort||this.defaultSort.name
return this.facetsController.highlight(filterName,sortName)}
FeedController.prototype.handleQuery=function(_arg){var filter,sort
filter=_arg.filter,sort=_arg.sort
if(filter){null==this.filters[filter]&&(filter=Object.keys(this.filters).first)
this.selectFilter(filter,!1)}if(sort){null==this.sorts[sort]&&(sort=Object.keys(this.sorts).first)
this.changeActiveSort(sort,!1)}this.highlightFacets()
return this.loadFeed()}
FeedController.prototype.defineFilter=function(name,filter){filter.name=name
this.filters[name]=filter
return filter.isDefault||null==this.selection?this.selection=filter:void 0}
FeedController.prototype.defineSort=function(name,sort){sort.name=name
this.sorts[name]=sort
return sort.isDefault||null==this.defaultSort?this.defaultSort=sort:void 0}
FeedController.prototype.loadView=function(mainView){this.getOptions().autoPopulate&&this.loadFeed()
return mainView._windowDidResize()}
FeedController.prototype.selectFilter=function(name,loadFeed){null==loadFeed&&(loadFeed=!0)
this.selection=this.filters[name]
this.resultsController.openTab(this.filters[name])
0===this.resultsController.listControllers[name].itemsOrdered.length&&loadFeed&&this.loadFeed()
return this.emit("FilterChanged",name)}
FeedController.prototype.changeActiveSort=function(name,loadFeed){null==loadFeed&&(loadFeed=!0)
this.selection.activeSort=name
this.resultsController.listControllers[this.selection.name].removeAllItems()
return loadFeed?this.loadFeed():void 0}
FeedController.prototype.getFeedSelector=function(){return{}}
FeedController.prototype.getFeedOptions=function(){var filter,options,sort
options={sort:{}}
filter=this.selection
sort=this.sorts[this.selection.activeSort]||this.defaultSort
options.sort[sort.name.split("|")[0]]=sort.direction
options.limit=this.getOptions().limitPerPage
options.skip=this.resultsController.listControllers[filter.name].itemsOrdered.length
return options}
FeedController.prototype.emitLoadStarted=function(filter){var listController
listController=this.resultsController.listControllers[filter.name]
listController.showLazyLoader(!1)
return listController}
FeedController.prototype.emitLoadCompleted=function(filter){var listController
listController=this.resultsController.listControllers[filter.name]
listController.hideLazyLoader()
return listController}
FeedController.prototype.emitCountChanged=function(count,filter){return this.resultsController.getDelegate().emit("FeederListViewItemCountChanged",count,filter)}
FeedController.prototype.sortByKey=function(array,key){return array.sort(function(first,second){var firstVar,secondVar
firstVar=JsPath.getAt(first,key)
secondVar=JsPath.getAt(second,key)
return secondVar>firstVar?1:firstVar>secondVar?-1:0})}
FeedController.prototype.reload=function(){var defaultSort,selection
selection=this.selection,defaultSort=this.defaultSort
return this.changeActiveSort(selection.activeSort||defaultSort.title)}
FeedController.prototype.loadFeed=function(filter){var feedId,item,itemClass,kallback,options,prefetchedItems,selector,_ref,_this=this
null==filter&&(filter=this.selection)
options=this.getFeedOptions()
selector=this.getFeedSelector()
_ref=this.getOptions(),itemClass=_ref.itemClass,feedId=_ref.feedId
kallback=function(){var err,items,limit,listController,rest,scrollView
err=arguments[0],items=arguments[1],rest=3<=arguments.length?__slice.call(arguments,2):[]
listController=_this.emitLoadCompleted(filter)
_this.emit("FilterLoaded")
limit=options.limit
scrollView=listController.scrollView
if(!((null!=items?items.length:void 0)>0))return err?"function"==typeof filter.dataError?filter.dataError(_this,err):void 0:"function"==typeof filter.dataEnd?filter.dataEnd.apply(filter,[_this].concat(__slice.call(rest))):void 0
if(err)return warn(err)
filter.activeSort&&(items=_this.sortByKey(items,filter.activeSort))
listController.instantiateListItems(items)
_this.emitCountChanged(listController.itemsOrdered.length,filter.name)
return scrollView&&scrollView.getScrollHeight()<=scrollView.getHeight()?_this.loadFeed(filter):void 0}
this.emitLoadStarted(filter)
if(0!==options.skip&&options.skip<options.limit){this.emitLoadCompleted(filter)
return this.emit("FilterLoaded")}if(__indexOf.call(USEDFEEDS,feedId)<0){USEDFEEDS.push(feedId)
return(prefetchedItems=KD.prefetchedFeeds[feedId])?kallback(null,function(){var _i,_len,_results
_results=[]
for(_i=0,_len=prefetchedItems.length;_len>_i;_i++){item=prefetchedItems[_i]
_results.push(KD.remote.revive(item))}return _results}()):this.loadFeed(filter)}return filter.dataSource(selector,options,kallback)}
return FeedController}(KDViewController)

var FeederFacetsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederFacetsController=function(_super){function FeederFacetsController(options,data){null==options&&(options={})
options.view||(options.view=new KDView({cssClass:"common-inner-nav"}))
FeederFacetsController.__super__.constructor.call(this,options,data)
this.facetTypes=["filter","sort"]
this.state={}}__extends(FeederFacetsController,_super)
FeederFacetsController.prototype.facetChange=function(){return KD.getSingleton("router").handleQuery(this.state)}
FeederFacetsController.prototype.loadView=function(){var options,view,_this=this
options=this.getOptions()
view=this.getView()
this.facetTypes.forEach(function(facet){var controller,item,type
controller=new CommonInnerNavigationListController({},{title:options[""+facet+"Title"]||facet.toUpperCase(),items:function(){var _ref,_results
_ref=options[""+facet+"s"]
_results=[]
for(type in _ref)if(__hasProp.call(_ref,type)){item=_ref[type];(!item.loggedInOnly||KD.isLoggedIn())&&_results.push({title:item.title,type:type,action:facet})}return _results}()})
_this[""+facet+"Controller"]=controller
if(controller.getData().items.length>1){controller.on("NavItemReceivedClick",function(item){_this.state[item.action]=item.type
return _this.facetChange()})
return view.addSubView(controller.getView())}})
return view.addSubView(new HelpBox(this.getOptions().help))}
FeederFacetsController.prototype.highlight=function(filterName,sortName){var _this=this
return this.facetTypes.forEach(function(facetType){var action,controller,isSelectedItem,item,type,typeMatches,_i,_len,_ref,_ref1,_results
controller=_this[""+facetType+"Controller"]
_ref=controller.itemsOrdered
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
_ref1=item.getData(),type=_ref1.type,action=_ref1.action
typeMatches=function(){switch(action){case"filter":return filterName===type
case"sort":return sortName===type}}()
isSelectedItem=typeMatches&&controller.itemsOrdered.length>1
isSelectedItem?_results.push(controller.selectItem(item)):_results.push(void 0)}return _results})}
return FeederFacetsController}(KDViewController)

var FeederResultsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederResultsController=function(_super){function FeederResultsController(options,data){var filter,name,_ref
null==options&&(options={})
options.view||(options.view=new FeederTabView({hideHandleCloseIcons:!0}))
options.paneClass||(options.paneClass=KDTabPaneView)
options.itemClass||(options.itemClass=KDListItemView)
options.listControllerClass||(options.listControllerClass=KDListViewController)
options.onboarding||(options.onboarding=null)
FeederResultsController.__super__.constructor.call(this,options,data)
this.panes={}
this.listControllers={}
_ref=options.filters
for(name in _ref)if(__hasProp.call(_ref,name)){filter=_ref[name]
this.createTab(name,filter)}}__extends(FeederResultsController,_super)
FeederResultsController.prototype.loadView=function(mainView){mainView.hideHandleContainer()
mainView.showPaneByIndex(0)
return this.utils.defer(mainView.bound("_windowDidResize"))}
FeederResultsController.prototype.openTab=function(filter,callback){var pane,tabView
tabView=this.getView()
pane=tabView.getPaneByName(filter.name)
tabView.showPane(pane)
return"function"==typeof callback?callback(this.listControllers[filter.name]):void 0}
FeederResultsController.prototype.createTab=function(name,filter,callback){var forwardItemWasAdded,header,itemClass,listController,listControllerClass,listCssClass,onboarding,pane,paneClass,tabView,_ref,_ref1,_this=this
_ref=this.getOptions(),paneClass=_ref.paneClass,itemClass=_ref.itemClass,listControllerClass=_ref.listControllerClass,listCssClass=_ref.listCssClass,onboarding=_ref.onboarding
tabView=this.getView()
this.listControllers[name]=listController=new listControllerClass({lazyLoadThreshold:.75,startWithLazyLoader:!0,scrollView:!1,wrapper:!1,noItemFoundWidget:new KDCustomHTMLView({cssClass:"lazy-loader",partial:filter.noItemFoundText||this.getOptions().noItemFoundText||"There are no items."}),viewOptions:{cssClass:listCssClass,type:name,itemClass:itemClass}})
forwardItemWasAdded=this.emit.bind(this,"ItemWasAdded")
listController.getListView().on("ItemWasAdded",forwardItemWasAdded)
listController.on("LazyLoadThresholdReached",function(){return _this.emit("LazyLoadThresholdReached")})
tabView.addPane(this.panes[name]=pane=new paneClass({name:name}))
pane.addSubView(pane.listHeader=header=new CommonListHeader({title:filter.optional_title||filter.title}))
onboarding&&this.putOnboardingView(name)
pane.addSubView(pane.listWrapper=listController.getView())
null!=(_ref1=listController.scrollView)&&_ref1.on("scroll",function(event){return event.delegateTarget.scrollTop>0?header.setClass("scrolling-up-outset"):header.unsetClass("scrolling-up-outset")})
return"function"==typeof callback?callback(listController):void 0}
FeederResultsController.prototype.putOnboardingView=function(name){var app,appManager,cb,header,onboarding,pane,tabView,view,_ref
pane=this.panes[name]
tabView=this.getView()
onboarding=this.getOptions().onboarding
header=pane.listHeader
view=onboarding[name]instanceof KDView?onboarding[name]:"string"==typeof onboarding[name]?new FeederOnboardingView({pistachio:onboarding[name]}):void 0
if(view){appManager=KD.getSingleton("appManager")
app=appManager.getFrontApp()
cb=function(){view.bindTransitionEnd()
view.setOption("name",name)
header.ready(function(){header.addSubView(view)
view.setClass("no-anim")
view.$().css({marginTop:-view.getHeight()-50})
view.unsetClass("no-anim")
return KD.utils.wait(1e3,function(){view.once("transitionend",tabView.bound("_windowDidResize"))
view.$().css({marginTop:1})
return view.setClass("in")})})
return view.on("OnboardingMessageCloseIconClicked",function(){view.once("transitionend",tabView.bound("_windowDidResize"))
view.$().css({marginTop:-view.getHeight()-50})
view.unsetClass("in")
return pane.listWrapper.setHeight(window.innerHeight)})}
return null!=(_ref=app.appStorage)?_ref.fetchValue("onboardingMessageIsReadFor"+name.capitalize()+"Tab",function(value){return value?void 0:KD.utils.wait(1e3,cb)}):void 0}}
return FeederResultsController}(KDViewController)

var FeederHeaderFacetsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederHeaderFacetsController=function(_super){function FeederHeaderFacetsController(options){options.view||(options.view=new KDView({cssClass:"header-facets"}))
FeederHeaderFacetsController.__super__.constructor.apply(this,arguments)
this.facetTypes=["filter","sort"]
this.state={}
this.current}__extends(FeederHeaderFacetsController,_super)
FeederHeaderFacetsController.prototype.facetChange=function(){return KD.getSingleton("router").handleQuery(this.state)}
FeederHeaderFacetsController.prototype.loadView=function(mainView){var options,_this=this
options=this.getOptions()
return this.facetTypes.forEach(function(facet){var controller,item,type
controller=new HeaderNavigationController({delegate:mainView},{title:options[""+facet+"Title"]||facet.toUpperCase(),items:function(){var _ref,_results
_ref=options[""+facet+"s"]
_results=[]
for(type in _ref)if(__hasProp.call(_ref,type)){item=_ref[type];(!item.loggedInOnly||KD.isLoggedIn())&&_results.push({title:item.title,type:type,action:facet})}return _results}()})
_this[""+facet+"Controller"]=controller
return controller.getData().items.length>1?controller.on("NavItemReceivedClick",function(item){_this.state[item.action]=item.type
return _this.facetChange()}):void 0})}
FeederHeaderFacetsController.prototype.highlight=function(filterName,sortName){var _this=this
return this.facetTypes.forEach(function(facetType){var action,controller,item,type,typeMatches,_i,_len,_ref,_results
controller=_this[""+facetType+"Controller"]
_ref=controller.getData().items
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
type=item.type,action=item.action
typeMatches=function(){switch(action){case"filter":return filterName===type
case"sort":return sortName===type}}()
typeMatches?_results.push(controller.selectItem(item)):_results.push(void 0)}return _results})}
return FeederHeaderFacetsController}(KDViewController)

var HeaderNavigationController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
HeaderNavigationController=function(_super){function HeaderNavigationController(){var items,itemsObj,mainView,title,_ref,_this=this
HeaderNavigationController.__super__.constructor.apply(this,arguments)
mainView=this.getDelegate()
_ref=this.getData(),items=_ref.items,title=_ref.title
this.currentItem=items.first
itemsObj={}
items.forEach(function(item){return itemsObj[item.title]={callback:_this.emit.bind(_this,"contextMenuItemClicked",item),action:item.action}})
mainView.addSubView(new KDCustomHTMLView({tagName:"span",cssClass:"title",partial:""+title+":"}))
mainView.addSubView(this.activeFacet=new KDCustomHTMLView({tagName:"a",cssClass:"active-facet",pistachio:"{span{#(title)}}<cite/>",click:function(event){var offset
offset=_this.activeFacet.$().offset()
event.preventDefault()
return _this.contextMenu=new JContextMenu({event:event,delegate:mainView,x:offset.left+_this.activeFacet.getWidth()-138,y:offset.top+22,arrow:{placement:"top",margin:-20}},itemsObj)}},{title:items.first.title}))
this.on("contextMenuItemClicked",function(item){var _ref1
null!=(_ref1=_this.contextMenu)&&_ref1.destroy()
_this.currentItem=item
return _this.emit("NavItemReceivedClick",item)})}__extends(HeaderNavigationController,_super)
HeaderNavigationController.prototype.selectItem=function(item){var title
this.currentItem=item
title=item.title
this.activeFacet.setData({title:title})
return this.activeFacet.render()}
return HeaderNavigationController}(KDController)

var FeederSplitView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederSplitView=function(_super){function FeederSplitView(options){null==options&&(options={})
options.sizes||(options.sizes=[139,null])
options.minimums||(options.minimums=[10,null])
null==options.resizable&&(options.resizable=!1)
options.bind||(options.bind="mouseenter")
FeederSplitView.__super__.constructor.call(this,options)}__extends(FeederSplitView,_super)
return FeederSplitView}(ContentPageSplitBelowHeader)

var FeederSingleView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederSingleView=function(_super){function FeederSingleView(options){null==options&&(options={})
FeederSingleView.__super__.constructor.apply(this,arguments)
this.listenWindowResize()}__extends(FeederSingleView,_super)
FeederSingleView.prototype._windowDidResize=function(){var width
width=this.getWidth()
this.unsetClass("extra-wide wide medium narrow extra-narrow")
return this.setClass(width>1200?"extra-wide":1200>width&&width>900?"wide":900>width&&width>600?"medium":600>width&&width>300?"narrow":"extra-narrow")}
return FeederSingleView}(KDCustomHTMLView)

var FeederTabView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederTabView=function(_super){function FeederTabView(options,data){null==options&&(options={})
options.cssClass||(options.cssClass="feeder-tabs")
FeederTabView.__super__.constructor.call(this,options,data)
this.unsetClass("kdscrollview")}__extends(FeederTabView,_super)
return FeederTabView}(KDTabView)

var FeederOnboardingView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FeederOnboardingView=function(_super){function FeederOnboardingView(options,data){null==options&&(options={})
options.cssClass="onboarding-wrapper"
FeederOnboardingView.__super__.constructor.call(this,options,data)
this.addCloseButton()}__extends(FeederOnboardingView,_super)
FeederOnboardingView.prototype.addCloseButton=function(){var _this=this
return this.addSubView(this.close=new CustomLinkView({title:"",cssClass:"onboarding-close",icon:{cssClass:"close-icon"},click:function(event){var app,appManager,_ref
event.preventDefault()
appManager=KD.getSingleton("appManager")
app=appManager.getFrontApp()
return null!=(_ref=app.appStorage)?_ref.fetchStorage(function(){var name
name=_this.getOptions().name
app.appStorage.setValue("onboardingMessageIsReadFor"+name.capitalize()+"Tab",!0)
return _this.emit("OnboardingMessageCloseIconClicked")}):void 0}}))}
return FeederOnboardingView}(KDCustomHTMLView)

//@ sourceMappingURL=/js/__app.feeder.0.0.1.js.map