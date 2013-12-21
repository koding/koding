var DemosAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DemosAppController=function(_super){function DemosAppController(options,data){null==options&&(options={})
options.view=new DemosMainView
options.appInfo={name:"Demos"}
DemosAppController.__super__.constructor.call(this,options,data)}__extends(DemosAppController,_super)
"localhost"===location.hostname&&KD.registerAppClass(DemosAppController,{name:"Demos",route:"/Demos",behavior:"application"})
return DemosAppController}(AppController)

var DemosMainView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DemosMainView=function(_super){function DemosMainView(){_ref=DemosMainView.__super__.constructor.apply(this,arguments)
return _ref}__extends(DemosMainView,_super)
DemosMainView.prototype.viewAppended=function(){var i,pane,_i,_results
this.addSubView(this.tabHandleContainer=new ApplicationTabHandleHolder({delegate:this,addPlusHandle:!0}))
this.addSubView(this.tabView=new ApplicationTabView({delegate:this,sortable:!0,closeAppWhenAllTabsClosed:!1,resizeTabHandles:!1,lastTabHandleMargin:200,maxHandleWidth:200,tabHandleContainer:this.tabHandleContainer,enableMoveTabHandle:!0}))
_results=[]
for(i=_i=0;5>=_i;i=++_i){pane=new KDTabPaneView({name:""+i+" --- SOME FILE asdas das d"})
pane.addSubView(new KDCustomHTMLView({cssClass:"no-file",partial:"<h1 style='color:white'>SOME FILE -- "+i+"</h1>"}))
_results.push(this.tabView.addPane(pane))}return _results}
return DemosMainView}(KDScrollView)

//@ sourceMappingURL=/js/__app.demos.0.0.1.js.map