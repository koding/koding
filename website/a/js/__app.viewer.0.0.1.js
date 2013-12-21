var ViewerAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ViewerAppController=function(_super){function ViewerAppController(options,data){null==options&&(options={})
options.view=new PreviewerView({params:options.params})
options.appInfo={title:"Preview",cssClass:"ace"}
ViewerAppController.__super__.constructor.call(this,options,data)}__extends(ViewerAppController,_super)
KD.registerAppClass(ViewerAppController,{name:"Viewer",route:"/:name?/Viewer",multiple:!0,openWith:"forceNew",behavior:"application",preCondition:{condition:function(options,cb){var path,publicPath,vmName
path=options.path,vmName=options.vmName
if(!path)return cb(!0)
path=FSHelper.plainPath(path)
publicPath=path.replace(/\/home\/(.*)\/Web\/(.*)/,"https://$1."+KD.config.userSitesDomain+"/$2")
return cb(publicPath!==path,{path:publicPath})},failure:function(){var correctPath
correctPath="/home/"+KD.nick()+"/Web/"
return KD.getSingleton("appManager").notify("File must be under: "+correctPath)}}})
ViewerAppController.prototype.open=function(path){return this.getView().openPath(path)}
return ViewerAppController}(KDViewController)

var PreviewerView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PreviewerView=function(_super){function PreviewerView(options,data){null==options&&(options={})
options.cssClass="previewer-body"
PreviewerView.__super__.constructor.call(this,options,data)}__extends(PreviewerView,_super)
PreviewerView.prototype.openPath=function(path){var initialPath
if(!/(^(https?:\/\/)?beta\.|^(https?:\/\/)?)koding\.com/.test(path)){initialPath=path
path+=""+(/\?/.test(path)?"&":"?")+Date.now()
path=/^https?:\/\//.test(path)?path:"http://"+path
this.path=path
this.iframe.setAttribute("src",path)
this.viewerHeader.setPath(initialPath)
return this.emit("ready")}this.viewerHeader.pageLocation.setClass("validation-error")}
PreviewerView.prototype.refreshIFrame=function(){return this.iframe.setAttribute("src",""+this.path)}
PreviewerView.prototype.isDocumentClean=function(){return this.clean}
PreviewerView.prototype.viewAppended=function(){var params,path,_this=this
this.addSubView(this.viewerHeader=new ViewerTopBar({delegate:this},this.path))
this.addSubView(this.iframe=new KDCustomHTMLView({tagName:"iframe"}))
params=this.getOptions().params
path=null!=params?params.path:void 0
return path?this.utils.defer(function(){return _this.openPath(path)}):void 0}
return PreviewerView}(KDView)

var ViewerTopBar,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ViewerTopBar=function(_super){function ViewerTopBar(options,data){var _this=this
options.cssClass="viewer-header top-bar clearfix"
ViewerTopBar.__super__.constructor.call(this,options,data)
this.addressBarIcon=new KDCustomHTMLView({tagName:"a",cssClass:"address-bar-icon",attributes:{href:"#",target:"_blank"}})
this.pageLocation=new KDHitEnterInputView({type:"text",keyup:function(){return _this.addressBarIcon.setAttribute("href",_this.pageLocation.getValue())},callback:function(){var newLocation
newLocation=_this.pageLocation.getValue()
_this.parent.openPath(newLocation)
_this.pageLocation.focus()
return _this.getDelegate().emit("ViewerLocationChanged",newLocation)}})
this.refreshButton=new KDCustomHTMLView({tagName:"a",attributes:{href:"#"},cssClass:"refresh-link",click:function(){_this.parent.refreshIFrame()
return _this.getDelegate().emit("ViewerRefreshed")}})}__extends(ViewerTopBar,_super)
ViewerTopBar.prototype.setPath=function(path){this.addressBarIcon.setAttribute("href",path)
this.pageLocation.unsetClass("validation-error")
return this.pageLocation.setValue(path)}
ViewerTopBar.prototype.pistachio=function(){return"{{> this.addressBarIcon}}\n{{> this.pageLocation}}\n{{> this.refreshButton}}"}
return ViewerTopBar}(JView)

//@ sourceMappingURL=/js/__app.viewer.0.0.1.js.map