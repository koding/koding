var ContentDisplayControllerApps,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayControllerApps=function(_super){function ContentDisplayControllerApps(options,data){var mainView
null==options&&(options={})
options.view||(options.view=mainView=new KDView({cssClass:"content-page appstore singleapp"}))
ContentDisplayControllerApps.__super__.constructor.call(this,options,data)}__extends(ContentDisplayControllerApps,_super)
ContentDisplayControllerApps.prototype.loadView=function(mainView){var appView
return mainView.addSubView(appView=new AppDetailsView({cssClass:"app-details",delegate:mainView},this.getData()))}
return ContentDisplayControllerApps}(KDViewController)

var AppsListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppsListItemView=function(_super){function AppsListItemView(options,data){var _this=this
null==options&&(options={})
options.type="appstore"
AppsListItemView.__super__.constructor.call(this,options,data)
this.thumbnail=new KDView({cssClass:"thumbnail",partial:"<span class='logo'>"+data.name[0]+"</span>"})
this.thumbnail.setCss("backgroundColor",KD.utils.getColorFromString(data.name))
this.getData().approved||this.setClass("waits-approve")
this.runButton=new KDButtonView({cssClass:"run",title:"run",callback:function(){return KodingAppsController.runExternalApp(_this.getData())}})}__extends(AppsListItemView,_super)
AppsListItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
AppsListItemView.prototype.pistachio=function(){return'<figure>\n  {{> this.thumbnail}}\n</figure>\n<div class="appmeta clearfix">\n  <h3><a href="/'+this.getData().slug+'">'+this.getData().name+"</a></h3>\n  <h4>{{#(manifest.author)}}</h4>\n  <div class=\"appdetails\">\n    <article>{{this.utils.shortenText(#(manifest.description))}}</article>\n  </div>\n</div>\n<div class='bottom'>\n  {{> this.runButton}}\n</div>"}
return AppsListItemView}(KDListItemView)

var AppDetailsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppDetailsView=function(_super){function AppDetailsView(){var app,authorNick,icns,identifier,version,_ref,_ref1,_this=this
AppDetailsView.__super__.constructor.apply(this,arguments)
this.app=app=this.getData()
_ref=app.manifest,identifier=_ref.identifier,version=_ref.version,authorNick=_ref.authorNick
this.appLogo=new KDView({cssClass:"app-logo",partial:"<span class='logo'>"+app.name[0]+"</span>"})
this.appLogo.setCss("backgroundColor",KD.utils.getColorFromString(app.name))
this.actionButtons=new KDView({cssClass:"action-buttons"})
this.removeButton=new KDButtonView({title:"Delete",style:"delete",callback:function(){var modal
return modal=new KDModalView({title:"Delete "+Encoder.XSSEncode(app.manifest.name),content:"<div class='modalformline'>Are you sure you want to delete\n<strong>"+Encoder.XSSEncode(app.manifest.name)+"</strong>\napplication?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return app["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
if(err){new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"})
return warn(err)}_this.emit("AppDeleted",app)
return _this.destroy()})}},cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}}})}});(KD.checkFlag("super-admin")||app.originId===KD.whoami().getId())&&this.actionButtons.addSubView(this.removeButton)
this.approveButton=new KDToggleButton({style:"approve",dataPath:"approved",defaultState:app.approved?"Disapprove":"Approve",states:[{title:"Approve",callback:function(callback){return app.approve(!0,function(err){err&&warn(err)
return"function"==typeof callback?callback(err):void 0})}},{title:"Disapprove",callback:function(callback){return app.approve(!1,function(err){return"function"==typeof callback?callback(err):void 0})}}]},app)
KD.checkFlag("super-admin")&&this.actionButtons.addSubView(this.approveButton)
this.actionButtons.addSubView(this.runButton=new KDButtonView({title:"Run",style:"run",callback:function(){return KodingAppsController.runExternalApp(app)}}))
_ref1=app.manifest,icns=_ref1.icns,identifier=_ref1.identifier,version=_ref1.version,authorNick=_ref1.authorNick
this.updatedTimeAgo=new KDTimeAgoView({},this.getData().meta.createdAt)
this.slideShow=new KDCustomHTMLView({tagName:"ul",pistachio:function(){var slide,slides,tmpl,_i,_len
slides=app.manifest.screenshots||[]
tmpl=""
for(_i=0,_len=slides.length;_len>_i;_i++){slide=slides[_i]
tmpl+='<li><img src="'+KD.appsUri+"/"+authorNick+"/"+identifier+"/"+version+"/"+slide+'" /></li>'}return tmpl}()})
this.reviewView=new ReviewView({},app)}__extends(AppDetailsView,_super)
AppDetailsView.prototype.viewAppended=JView.prototype.viewAppended
AppDetailsView.prototype.pistachio=function(){var screenshots,_ref;(null!=(_ref=this.app.manifest.screenshots)?_ref.length:void 0)&&(screenshots="<header><a href='#'>Screenshots</a></header>\n<section class='screenshots'>{{> this.slideShow}}</section>")
return'{{> this.appLogo}}\n\n<div class="app-info">\n  <h3><a href="/'+this.getData().slug+'">'+this.getData().name+'</a></h3>\n  <h4>{{#(manifest.author)}}</h4>\n\n  <div class="appdetails">\n    <article>{{#(manifest.description)}}</article>\n  </div>\n\n</div>\n<div class="installerbar">\n\n  <div class="versionstats updateddate">\n    Version {{#(manifest.version) || "---"}}\n    <p>Released {{> this.updatedTimeAgo}}</p>\n  </div>\n\n  {{> this.actionButtons}}\n\n</div>'}
return AppDetailsView}(KDScrollView)

var AppsMainView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppsMainView=function(_super){function AppsMainView(options,data){null==options&&(options={})
null==options.ownScrollBars&&(options.ownScrollBars=!0)
AppsMainView.__super__.constructor.call(this,options,data)}__extends(AppsMainView,_super)
AppsMainView.prototype.createCommons=function(){var header
header=new HeaderViewSection({type:"big",title:"App Catalog"})
header.addSubView(this.updateAppsButton=new KDButtonView({title:"Update All",style:"cupid-green update-apps-button",callback:function(){KD.getSingleton("kodingAppsController").updateAllApps()
return this.hide()}}))
this.updateAppsButton.hide()
this.updateAppsButton.on("UpdateView",function(filter){var appsController,_this=this
"updates"!==filter&&this.hide()
if("updates"===filter){appsController=KD.getSingleton("kodingAppsController")
return appsController.fetchUpdateAvailableApps(function(res,apps){return(null!=apps?apps.length:void 0)?_this.show():_this.hide()})}})
return this.addSubView(header)}
return AppsMainView}(KDView)

var AppsAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppsAppController=function(_super){function AppsAppController(options,data){null==options&&(options={})
options.view=new AppsMainView({cssClass:"content-page appstore"})
options.appInfo={name:"Apps"}
AppsAppController.__super__.constructor.call(this,options,data)}var handler
__extends(AppsAppController,_super)
handler=function(callback){return KD.singleton("appManager").open("Apps",callback)}
KD.registerAppClass(AppsAppController,{name:"Apps",routes:{"/:name?/Apps":function(_arg){var params,query
params=_arg.params,query=_arg.query
return handler(function(app){return app.handleQuery(query)})},"/:name?/Apps/:lala/:app?":function(arg){return handler(function(app){return app.handleRoute(arg)})}},hiddenHandle:!0,behaviour:"application",version:"1.0"})
AppsAppController.prototype.loadView=function(mainView){mainView.createCommons()
return this.createFeed(mainView)}
AppsAppController.prototype.createFeed=function(view){var options,_this=this
options={feedId:"apps.main",itemClass:AppsListItemView,limitPerPage:10,delegate:this,useHeaderNav:!0,filter:{allApps:{title:"All Apps",noItemFoundText:"There is no application yet",dataSource:function(selector,options,callback){return KD.remote.api.JNewApp.some(selector,options,callback)}},webApps:{title:"Web Apps",noItemFoundText:"There is no web apps yet",dataSource:function(selector,options,callback){selector["manifest.category"]="web-app"
return KD.remote.api.JNewApp.some(selector,options,callback)}},kodingAddOns:{title:"Add-ons",noItemFoundText:"There is no add-ons yet",dataSource:function(selector,options,callback){selector["manifest.category"]="add-on"
return KD.remote.api.JNewApp.some(selector,options,callback)}},serverStacks:{title:"Server Stacks",noItemFoundText:"There is no server-stacks yet",dataSource:function(selector,options,callback){selector["manifest.category"]="server-stack"
return KD.remote.api.JNewApp.some(selector,options,callback)}},frameworks:{title:"Frameworks",noItemFoundText:"There is no frameworks yet",dataSource:function(selector,options,callback){selector["manifest.category"]="framework"
return KD.remote.api.JNewApp.some(selector,options,callback)}},miscellaneous:{title:"Miscellaneous",noItemFoundText:"There is no miscellaneous app yet",dataSource:function(selector,options,callback){selector["manifest.category"]="misc"
return KD.remote.api.JNewApp.some(selector,options,callback)}}},sort:{"meta.modifiedAt":{title:"Latest activity",direction:-1},"counts.followers":{title:"Most popular",direction:-1},"counts.tagged":{title:"Most activity",direction:-1}},help:{subtitle:"Learn About Apps",bookIndex:26,tooltip:{title:'<p class="bigtwipsy">The App Catalog contains apps and Koding enhancements contributed to the community by users.</p>',placement:"above",offset:0,delayIn:300,html:!0,animate:!0}}}
KD.checkFlag("super-admin")&&(options.filter.waitsForApprove={title:"New Apps",dataSource:function(selector,options,callback){return KD.remote.api.JNewApp.some_(selector,options,callback)}})
return KD.getSingleton("appManager").tell("Feeder","createContentFeedController",options,function(controller){view.addSubView(controller.getView())
_this.feedController=controller
return _this.emit("ready")})}
AppsAppController.prototype.handleQuery=function(query){var _this=this
return this.ready(function(){return _this.feedController.handleQuery(query)})}
AppsAppController.prototype.handleRoute=function(route){var JNewApp,app,lala,slug,_ref,_this=this
_ref=route.params,app=_ref.app,lala=_ref.lala
JNewApp=KD.remote.api.JNewApp
if(app){log("slug:",slug="Apps/"+lala+"/"+app)
JNewApp.one({slug:slug},function(err,app){log("FOUND THIS JAPP",err,app)
return app?_this.showContentDisplay(app):void 0})}return log("HANDLING",route)}
AppsAppController.prototype.showContentDisplay=function(content){var contentDisplay,controller
controller=new ContentDisplayControllerApps(null,content)
contentDisplay=controller.getView()
KD.singleton("display").emit("ContentDisplayWantsToBeShown",contentDisplay)
return contentDisplay}
return AppsAppController}(AppController)

//@ sourceMappingURL=/js/__app.apps.0.0.1.js.map