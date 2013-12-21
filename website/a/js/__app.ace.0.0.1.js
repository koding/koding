var requirejs,require,define
!function(r){function K(a){return"[object Function]"===O.call(a)}function G(a){return"[object Array]"===O.call(a)}function $(a,c,l){for(var j in c)j in L||j in a&&!l||(a[j]=c[j])
return d}function P(a,c,d){a=Error(c+"\nhttp://requirejs.org/docs/errors.html#"+a)
d&&(a.originalError=d)
return a}function aa(a,c,d){var j,k,t
for(j=0;t=c[j];j++){t="string"==typeof t?{name:t}:t
k=t.location
d&&(!k||0!==k.indexOf("/")&&-1===k.indexOf(":"))&&(k=d+"/"+(k||t.name))
a[t.name]={name:t.name,location:k||t.name,main:(t.main||"main").replace(fa,"").replace(ba,"")}}}function V(a,c){a.holdReady?a.holdReady(c):c?a.readyWait+=1:a.ready(!0)}function ga(a){function c(b,f){var g,m
if(b&&"."===b.charAt(0))if(f){q.pkgs[f]?f=[f]:(f=f.split("/"),f=f.slice(0,f.length-1))
g=b=f.concat(b.split("/"))
var a
for(m=0;a=g[m];m++)if("."===a)g.splice(m,1),m-=1
else if(".."===a){if(1===m&&(".."===g[2]||".."===g[0]))break
m>0&&(g.splice(m-1,2),m-=2)}m=q.pkgs[g=b[0]]
b=b.join("/")
m&&b===g+"/"+m.main&&(b=g)}else 0===b.indexOf("./")&&(b=b.substring(2))
return b}function l(b,f){var e,d,g=b?b.indexOf("!"):-1,m=null,a=f?f.name:null,h=b;-1!==g&&(m=b.substring(0,g),b=b.substring(g+1,b.length))
m&&(m=c(m,a))
b&&(m?e=(g=n[m])&&g.normalize?g.normalize(b,function(b){return c(b,a)}):c(b,a):(e=c(b,a),d=G[e],d||(d=i.nameToUrl(b,null,f),G[e]=d)))
return{prefix:m,name:e,parentMap:f,url:d,originalName:h,fullName:m?m+"!"+(e||""):e}}function j(){var g,a,b=!0,f=q.priorityWait
if(f){for(a=0;g=f[a];a++)if(!s[g]){b=!1
break}b&&delete q.priorityWait}return b}function k(b,f,g){return function(){var c,a=ha.call(arguments,0)
g&&K(c=a[a.length-1])&&(c.__requireJsBuild=!0)
a.push(f)
return b.apply(null,a)}}function t(b,f,g){f=k(g||i.require,b,f)
$(f,{nameToUrl:k(i.nameToUrl,b),toUrl:k(i.toUrl,b),defined:k(i.requireDefined,b),specified:k(i.requireSpecified,b),isBrowser:d.isBrowser})
return f}function p(b){var f,g,a,c=b.callback,h=b.map,e=h.fullName,ca=b.deps
a=b.listeners
var j=q.requireExecCb||d.execCb
if(c&&K(c)){if(q.catchError.define)try{g=j(e,b.callback,ca,n[e])}catch(k){f=k}else g=j(e,b.callback,ca,n[e])
e&&((c=b.cjsModule)&&c.exports!==r&&c.exports!==n[e]?g=n[e]=b.cjsModule.exports:g===r&&b.usingExports?g=n[e]:(n[e]=g,H[e]&&(T[e]=!0)))}else e&&(g=n[e]=c,H[e]&&(T[e]=!0))
x[b.id]&&(delete x[b.id],b.isDone=!0,i.waitCount-=1,0===i.waitCount&&(J=[]))
delete M[e]
d.onResourceLoad&&!b.placeholder&&d.onResourceLoad(i,h,b.depArray)
if(f)return g=(e?l(e).url:"")||f.fileName||f.sourceURL,a=f.moduleTree,f=P("defineerror",'Error evaluating module "'+e+'" at location "'+g+'":\n'+f+"\nfileName:"+g+"\nlineNumber: "+(f.lineNumber||f.line),f),f.moduleName=e,f.moduleTree=a,d.onError(f)
for(f=0;c=a[f];f++)c(g)
return r}function u(b,f){return function(g){b.depDone[f]||(b.depDone[f]=!0,b.deps[f]=g,b.depCount-=1,b.depCount||p(b))}}function o(b,f){var e,g=f.map,a=g.fullName,c=g.name,h=N[b]||(N[b]=n[b])
f.loading||(f.loading=!0,e=function(b){f.callback=function(){return b}
p(f)
s[f.id]=!0
A()},e.fromText=function(b,f){var g=Q
s[b]=!1
i.scriptCount+=1
i.fake[b]=!0
g&&(Q=!1)
d.exec(f)
g&&(Q=!0)
i.completeLoad(b)},a in n?e(n[a]):h.load(c,t(g.parentMap,!0,function(b,a){var e,m,c=[]
for(e=0;m=b[e];e++)m=l(m,g.parentMap),b[e]=m.fullName,m.prefix||c.push(b[e])
f.moduleDeps=(f.moduleDeps||[]).concat(c)
return i.require(b,a)}),e,q))}function y(b){x[b.id]||(x[b.id]=b,J.push(b),i.waitCount+=1)}function D(b){this.listeners.push(b)}function v(b,f){var h,e,g=b.fullName,a=b.prefix,c=a?N[a]||(N[a]=n[a]):null
g&&(h=M[g])
h||(e=!0,h={id:(a&&!c?O++ +"__p@:":"")+(g||"__r@"+O++),map:b,depCount:0,depDone:[],depCallbacks:[],deps:[],listeners:[],add:D},B[h.id]=!0,!g||a&&!N[a])||(M[g]=h)
a&&!c?(g=l(a),a in n&&!n[a]&&(delete n[a],delete R[g.url]),a=v(g,!0),a.add(function(){var f=l(b.originalName,b.parentMap),f=v(f,!0)
h.placeholder=!0
f.add(function(b){h.callback=function(){return b}
p(h)})})):e&&f&&(s[h.id]=!1,i.paused.push(h),y(h))
return h}function C(b,f,a,c){var o,b=l(b,c),d=b.name,h=b.fullName,e=v(b),j=e.id,k=e.deps
if(h){if(h in n||s[j]===!0||"jquery"===h&&q.jQuery&&q.jQuery!==a().fn.jquery)return
B[j]=!0
s[j]=!0
"jquery"===h&&a&&W(a())}e.depArray=f
e.callback=a
for(a=0;a<f.length;a++)(j=f[a])&&(j=l(j,d?b:c),o=j.fullName,f[a]=o,"require"===o?k[a]=t(b):"exports"===o?(k[a]=n[h]={},e.usingExports=!0):"module"===o?e.cjsModule=k[a]={id:d,uri:d?i.nameToUrl(d,null,c):r,exports:n[h]}:!(o in n)||o in x||h in H&&!(h in H&&T[o])?(h in H&&(H[o]=!0,delete n[o],R[j.url]=!1),e.depCount+=1,e.depCallbacks[a]=u(e,a),v(j,!0).add(e.depCallbacks[a])):k[a]=n[o])
e.depCount?y(e):p(e)}function w(b){C.apply(null,b)}function F(b,f){var h,e,i,l,a=b.map.fullName,c=b.depArray,d=!0
if(b.isDone||!a||!s[a])return l
if(f[a])return b
f[a]=!0
if(c){for(h=0;h<c.length;h++){e=c[h]
if(!s[e]&&!ia[e]){d=!1
break}if((i=x[e])&&!i.isDone&&s[e]&&(l=F(i,f)))break}d||(l=r,delete f[a])}return l}function z(b,a){var d,h,e,i,g=b.map.fullName,c=b.depArray
if(b.isDone||!g||!s[g])return r
if(g){if(a[g])return n[g]
a[g]=!0}if(c)for(d=0;d<c.length;d++)(h=c[d])&&((e=l(h).prefix)&&(i=x[e])&&z(i,a),(e=x[h])&&!e.isDone&&s[h])&&(h=z(e,a),b.depCallbacks[d](h))
return n[g]}function E(){var h,e,b=1e3*q.waitSeconds,b=b&&i.startTime+b<(new Date).getTime(),a="",c=!1,l=!1,k=[]
if(i.pausedCount>0)return r
if(q.priorityWait){if(!j())return r
A()}for(h in s)if(!(h in L||(c=!0,s[h])))if(b)a+=h+" "
else{if(l=!0,-1===h.indexOf("!")){k=[]
break}(e=M[h]&&M[h].moduleDeps)&&k.push.apply(k,e)}if(!c&&!i.waitCount)return r
if(b&&a)return b=P("timeout","Load timeout for modules: "+a),b.requireType="timeout",b.requireModules=a,b.contextName=i.contextName,d.onError(b)
if(l&&k.length)for(a=0;h=x[k[a]];a++)if(h=F(h,{})){z(h,{})
break}if(!b&&(l||i.scriptCount)){!I&&!da||X||(X=setTimeout(function(){X=0
E()},50))
return r}if(i.waitCount){for(a=0;h=J[a];a++)z(h,{})
i.paused.length&&A()
5>Y&&(Y+=1,E())}Y=0
d.checkReadyState()
return r}var i,A,q={waitSeconds:7,baseUrl:"./",paths:{},pkgs:{},catchError:{}},S=[],B={require:!0,exports:!0,module:!0},G={},n={},s={},x={},J=[],R={},O=0,M={},N={},H={},T={},Z=0
W=function(b){i.jQuery||!(b=b||("undefined"!=typeof jQuery?jQuery:null))||q.jQuery&&b.fn.jquery!==q.jQuery||!("holdReady"in b||"readyWait"in b)||(i.jQuery=b,w(["jquery",[],function(){return jQuery}]),i.scriptCount)&&(V(b,!0),i.jQueryIncremented=!0)}
A=function(){var b,a,c,l,k,h
i.takeGlobalQueue()
Z+=1
i.scriptCount<=0&&(i.scriptCount=0)
for(;S.length;){if(b=S.shift(),null===b[0])return d.onError(P("mismatch","Mismatched anonymous define() module: "+b[b.length-1]))
w(b)}if(!q.priorityWait||j())for(;i.paused.length;){k=i.paused
i.pausedCount+=k.length
i.paused=[]
for(l=0;b=k[l];l++)a=b.map,c=a.url,h=a.fullName,a.prefix?o(a.prefix,b):!R[c]&&!s[h]&&((q.requireLoad||d.load)(i,h,c),0!==c.indexOf("empty:")&&(R[c]=!0))
i.startTime=(new Date).getTime()
i.pausedCount-=k.length}1===Z&&E()
Z-=1
return r}
i={contextName:a,config:q,defQueue:S,waiting:x,waitCount:0,specified:B,loaded:s,urlMap:G,urlFetched:R,scriptCount:0,defined:n,paused:[],pausedCount:0,plugins:N,needFullExec:H,fake:{},fullExec:T,managerCallbacks:M,makeModuleMap:l,normalize:c,configure:function(b){var a,c,d
b.baseUrl&&"/"!==b.baseUrl.charAt(b.baseUrl.length-1)&&(b.baseUrl+="/")
a=q.paths
d=q.pkgs
$(q,b,!0)
if(b.paths){for(c in b.paths)c in L||(a[c]=b.paths[c])
q.paths=a}if((a=b.packagePaths)||b.packages){if(a)for(c in a)c in L||aa(d,a[c],c)
b.packages&&aa(d,b.packages)
q.pkgs=d}b.priority&&(c=i.requireWait,i.requireWait=!1,A(),i.require(b.priority),A(),i.requireWait=c,q.priorityWait=b.priority);(b.deps||b.callback)&&i.require(b.deps||[],b.callback)},requireDefined:function(b,a){return l(b,a).fullName in n},requireSpecified:function(b,a){return l(b,a).fullName in B},require:function(b,c,g){if("string"==typeof b){if(K(c))return d.onError(P("requireargs","Invalid require call"))
if(d.get)return d.get(i,b,c)
c=l(b,c)
b=c.fullName
return b in n?n[b]:d.onError(P("notloaded","Module name '"+c.fullName+"' has not been loaded yet for context: "+a))}(b&&b.length||c)&&C(null,b,c,g)
if(!i.requireWait)for(;!i.scriptCount&&i.paused.length;)A()
return i.require},takeGlobalQueue:function(){U.length&&(ja.apply(i.defQueue,[i.defQueue.length-1,0].concat(U)),U=[])},completeLoad:function(b){var a
for(i.takeGlobalQueue();S.length;){if(a=S.shift(),null===a[0]){a[0]=b
break}if(a[0]===b)break
w(a),a=null}a?w(a):w([b,[],"jquery"===b&&"undefined"!=typeof jQuery?function(){return jQuery}:null])
d.isAsync&&(i.scriptCount-=1)
A()
d.isAsync||(i.scriptCount-=1)},toUrl:function(b,a){var c=b.lastIndexOf("."),d=null;-1!==c&&(d=b.substring(c,b.length),b=b.substring(0,c))
return i.nameToUrl(b,d,a)},nameToUrl:function(b,a,g){var l,k,h,e,j=i.config,b=c(b,g&&g.fullName)
if(d.jsExtRegExp.test(b))a=b+(a?a:"")
else{l=j.paths
k=j.pkgs
g=b.split("/")
for(e=g.length;e>0;e--){if(h=g.slice(0,e).join("/"),l[h]){g.splice(0,e,l[h])
break}if(h=k[h]){b=b===h.name?h.location+"/"+h.main:h.location
g.splice(0,e,b)
break}}a=g.join("/")+(a||".js")
a=("/"===a.charAt(0)||a.match(/^[\w\+\.\-]+:/)?"":j.baseUrl)+a}return j.urlArgs?a+((-1===a.indexOf("?")?"?":"&")+j.urlArgs):a}}
i.jQueryCheck=W
i.resume=A
return i}function ka(){var a,c,d
if(C&&"interactive"===C.readyState)return C
a=document.getElementsByTagName("script")
for(c=a.length-1;c>-1&&(d=a[c]);c--)if("interactive"===d.readyState)return C=d
return null}var la=/(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/gm,ma=/require\(\s*["']([^'"\s]+)["']\s*\)/g,fa=/^\.\//,ba=/\.js$/,O=Object.prototype.toString,u=Array.prototype,ha=u.slice,ja=u.splice,I=!("undefined"==typeof window||!navigator||!document),da=!I&&"undefined"!=typeof importScripts,na=I&&"PLAYSTATION 3"===navigator.platform?/^complete$/:/^(complete|loaded)$/,ea="undefined"!=typeof opera&&"[object Opera]"===opera.toString(),L={},D={},U=[],C=null,Y=0,Q=!1,ia={require:!0,module:!0,exports:!0},d,u={},J,y,v,E,o,w,F,B,z,W,X
if("undefined"==typeof define){if("undefined"!=typeof requirejs){if(K(requirejs))return
u=requirejs,requirejs=r}"undefined"!=typeof require&&!K(require)&&(u=require,require=r)
d=requirejs=function(a,c,d){var k,j="_"
!G(a)&&"string"!=typeof a&&(k=a,G(c)?(a=c,c=d):a=[])
k&&k.context&&(j=k.context)
d=D[j]||(D[j]=ga(j))
k&&d.configure(k)
return d.require(a,c)}
d.config=function(a){return d(a)}
require||(require=d)
d.toUrl=function(a){return D._.toUrl(a)}
d.version="1.0.8"
d.jsExtRegExp=/^\/|:|\?|\.js$/
y=d.s={contexts:D,skipAsync:{}};(d.isAsync=d.isBrowser=I)&&(v=y.head=document.getElementsByTagName("head")[0],E=document.getElementsByTagName("base")[0])&&(v=y.head=E.parentNode)
d.onError=function(a){throw a}
d.load=function(a,c,l){d.resourcesReady(!1)
a.scriptCount+=1
d.attach(l,a,c)
a.jQuery&&!a.jQueryIncremented&&(V(a.jQuery,!0),a.jQueryIncremented=!0)}
define=function(a,c,d){var j,k
"string"!=typeof a&&(d=c,c=a,a=null)
G(c)||(d=c,c=[])
!c.length&&K(d)&&d.length&&(d.toString().replace(la,"").replace(ma,function(a,d){c.push(d)}),c=(1===d.length?["require"]:["require","exports","module"]).concat(c))
Q&&(j=J||ka())&&(a||(a=j.getAttribute("data-requiremodule")),k=D[j.getAttribute("data-requirecontext")]);(k?k.defQueue:U).push([a,c,d])
return r}
define.amd={multiversion:!0,plugins:!0,jQuery:!0}
d.exec=function(a){return eval(a)}
d.execCb=function(a,c,d,j){return c.apply(j,d)}
d.addScriptToDom=function(a){J=a
E?v.insertBefore(a,E):v.appendChild(a)
J=null}
d.onScriptLoad=function(a){var l,c=a.currentTarget||a.srcElement;("load"===a.type||c&&na.test(c.readyState))&&(C=null,a=c.getAttribute("data-requirecontext"),l=c.getAttribute("data-requiremodule"),D[a].completeLoad(l),c.detachEvent&&!ea?c.detachEvent("onreadystatechange",d.onScriptLoad):c.removeEventListener("load",d.onScriptLoad,!1))}
d.attach=function(a,c,l,j,k,o){var p
if(I)return j=j||d.onScriptLoad,p=c&&c.config&&c.config.xhtml?document.createElementNS("http://www.w3.org/1999/xhtml","html:script"):document.createElement("script"),p.type=k||c&&c.config.scriptType||"text/javascript",p.charset="utf-8",p.async=!y.skipAsync[a],c&&p.setAttribute("data-requirecontext",c.contextName),p.setAttribute("data-requiremodule",l),!p.attachEvent||p.attachEvent.toString&&p.attachEvent.toString().indexOf("[native code]")<0||ea?p.addEventListener("load",j,!1):(Q=!0,o?p.onreadystatechange=function(){"loaded"===p.readyState&&(p.onreadystatechange=null,p.attachEvent("onreadystatechange",j),o(p))}:p.attachEvent("onreadystatechange",j)),p.src=a,o||d.addScriptToDom(p),p
da&&(importScripts(a),c.completeLoad(l))
return null}
if(I){o=document.getElementsByTagName("script")
for(B=o.length-1;B>-1&&(w=o[B]);B--){v||(v=w.parentNode)
if(F=w.getAttribute("data-main")){u.baseUrl||(o=F.split("/"),w=o.pop(),o=o.length?o.join("/")+"/":"./",u.baseUrl=o,F=w.replace(ba,""))
u.deps=u.deps?u.deps.concat(F):[F]
break}}}d.checkReadyState=function(){var c,a=y.contexts
for(c in a)if(!(c in L)&&a[c].waitCount)return
d.resourcesReady(!0)}
d.resourcesReady=function(a){var c,l
d.resourcesDone=a
if(d.resourcesDone)for(l in a=y.contexts)l in L||(c=a[l],!c.jQueryIncremented)||(V(c.jQuery,!1),c.jQueryIncremented=!1)}
d.pageLoaded=function(){"complete"!==document.readyState&&(document.readyState="complete")}
I&&document.addEventListener&&!document.readyState&&(document.readyState="loading",window.addEventListener("load",d.pageLoaded,!1))
d(u)
d.isAsync&&"undefined"!=typeof setTimeout&&(z=y.contexts[u.context||"_"],z.requireWait=!0,setTimeout(function(){z.requireWait=!1
z.scriptCount||z.resume()
d.checkReadyState()},0))}}()

var AceAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
require.config({baseUrl:"/js",waitSeconds:30})
AceAppController=function(_super){function AceAppController(options,data){null==options&&(options={})
options.view=new AceAppView
options.appInfo={name:"Ace",type:"application",cssClass:"ace"}
AceAppController.__super__.constructor.call(this,options,data)
this.on("AppDidQuit",function(){return this.getView().emit("AceAppDidQuit")})}__extends(AceAppController,_super)
KD.registerAppClass(AceAppController,{name:"Ace",multiple:!0,hiddenHandle:!1,openWith:"lastActive",route:{slug:"/:name?/Ace",handler:function(_arg){var name,query,router,_ref
_ref=_arg.params,name=_ref.name,query=_arg.query
router=KD.getSingleton("router")
warn("ace handling itself",name,query,arguments)
return router.openSection("Ace",name,query)}},behavior:"application",menu:[{title:"Save",eventName:"save"},{title:"Save As",eventName:"saveAs"},{type:"separator"},{title:"Find",eventName:"find"},{title:"Find and Replace",eventName:"findAndReplace"},{title:"Goto line",eventName:"gotoLine"},{type:"separator"},{title:"Preview",eventName:"preview"},{type:"separator"},{title:"Advanced Settings",id:"advancedSettings"},{title:"customViewAdvancedSettings",parentId:"advancedSettings"},{type:"separator"},{title:"Reopen Latest Files",eventName:"reopen"},{type:"separator"},{title:"customViewFullscreen"},{type:"separator"},{title:"Exit",eventName:"exit"}],fileTypes:["php","pl","py","jsp","asp","aspx","htm","html","phtml","shtml","sh","cgi","htaccess","fcgi","wsgi","mvc","xml","sql","rhtml","diff","js","json","coffee","css","styl","sass","scss","less","txt","erb"]})
AceAppController.prototype.openFile=function(file){return this.getView().openFile(file)}
return AceAppController}(AppController)

var AceView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AceView=function(_super){function AceView(options,file){null==options&&(options={})
null==options.advancedSettings&&(options.advancedSettings=!1)
AceView.__super__.constructor.call(this,options,file)
this.listenWindowResize()
this.caretPosition=new KDCustomHTMLView({tagName:"div",cssClass:"caret-position section",partial:"<span>1</span>:<span>1</span>"})
this.ace=new Ace({delegate:this,enableShortcuts:!0},file)
this.advancedSettings=new KDButtonViewWithMenu({style:"editor-advanced-settings-menu",icon:!0,iconOnly:!0,iconClass:"cog",type:"contextmenu",delegate:this,itemClass:AceSettingsView,click:function(pubInst,event){return this.contextMenu(event)},menu:this.getAdvancedSettingsMenuItems.bind(this)})
this.advancedSettings.disable()
options.advancedSettings||this.advancedSettings.hide()
this.findAndReplaceView=new AceFindAndReplaceView({delegate:this})
this.findAndReplaceView.hide()
this.setViewListeners()}__extends(AceView,_super)
AceView.prototype.setViewListeners=function(){var $spans,_this=this
this.ace.on("ace.ready",function(){return _this.advancedSettings.enable()})
this.ace.on("ace.changeSetting",function(setting,value){var _base,_name
return"function"==typeof(_base=_this.ace)[_name="set"+setting.capitalize()]?_base[_name](value):void 0})
this.advancedSettings.emit("ace.settingsView.setDefaults",this.ace)
$spans=this.caretPosition.$("span")
this.ace.on("ace.change.cursor",function(cursor){$spans.eq(0).text(++cursor.row)
return $spans.eq(1).text(++cursor.column)})
this.ace.on("ace.requests.saveAs",function(contents,options){return _this.openSaveDialog(options)})
this.ace.on("ace.requests.save",function(contents){var file
file=_this.getData()
if(/localfile:/.test(file.path))return _this.openSaveDialog({closeAfter:!1})
file.once("fs.save.started",_this.ace.bound("saveStarted"))
file.once("fs.save.finished",_this.ace.bound("saveFinished"))
return file.emit("file.requests.save",contents)})
this.ace.on("FileContentChanged",function(){_this.ace.contentChanged=!0
_this.getActiveTabHandle().setClass("modified")
return _this.getDelegate().quitOptions={message:"You have unsaved changes. You will lose them if you close this tab.",title:"Do you want to close this tab?"}})
this.ace.on("FileContentSynced",function(){_this.ace.contentChanged=!1
_this.getActiveTabHandle().unsetClass("modified")
return delete _this.getDelegate().quitOptions})
return this.ace.on("FileIsReadOnly",function(){var modal
_this.getActiveTabHandle().setClass("readonly")
_this.ace.setReadOnly(!0)
return modal=new KDModalView({title:"This file is readonly",content:'<div class="modalformline">\n  <p>\n    The file <code>'+_this.getData().name+"</code> is set to readonly,\n    you won't be able to save your changes.\n  </p>\n</div>",buttons:{"Edit Anyway":{cssClass:"modal-clean-red",callback:function(){_this.ace.setReadOnly(!1)
return modal.destroy()}},Cancel:{cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})})}
AceView.prototype.getActiveTabHandle=function(){return this.getDelegate().tabView.getActivePane().tabHandle}
AceView.prototype.preview=function(){var path,vmName,_ref
_ref=this.getData(),vmName=_ref.vmName,path=_ref.path
return KD.getSingleton("appManager").open("Viewer",{params:{path:path,vmName:vmName}})}
AceView.prototype.toggleFullscreen=function(){var mainView
mainView=KD.getSingleton("mainView")
return mainView.toggleFullscreen()}
AceView.prototype.viewAppended=function(){AceView.__super__.viewAppended.apply(this,arguments)
return this._windowDidResize()}
AceView.prototype.pistachio=function(){return'<div class="kdview editor-main">\n  {{> this.ace}}\n  <div class="editor-bottom-bar clearfix">\n    {{> this.caretPosition}}\n    {{> this.advancedSettings}}\n  </div>\n  {{> this.findAndReplaceView}}\n</div>'}
AceView.prototype.getAdvancedSettingsMenuItems=function(){return{settings:{type:"customView",view:new AceSettingsView({delegate:this.ace})}}}
AceView.prototype.getSaveMenu=function(){var _this=this
return{"Save as...":{id:13,parentId:null,callback:function(){return _this.openSaveDialog({closeAfter:!1})}}}}
AceView.prototype._windowDidResize=function(){var bottomBarHeight,height
height=this.getHeight()
bottomBarHeight=this.$(".editor-bottom-bar").height()
return this.ace.setHeight(height-bottomBarHeight)}
AceView.prototype.openSaveDialog=function(options){var closeAfter,file,_this=this
null==options&&(options={})
closeAfter=options.closeAfter
file=this.getData()
return KD.utils.showSaveDialog(this,function(input,finderController,dialog){var name,node,oldCursorPosition,parent
node=finderController.treeController.selectedNodes[0]
name=input.getValue()
if(!FSHelper.isValidFileName(name))return _this.ace.notify("Please type valid file name!","error")
if(!node)return _this.ace.notify("Please select a folder to save!","error")
dialog.destroy()
parent=node.getData()
file.emit("file.requests.saveAs",_this.ace.getContents(),name,parent.path)
file.once("fs.saveAs.finished",_this.ace.bound("saveAsFinished"))
_this.ace.emit("AceDidSaveAs",name,parent.path)
oldCursorPosition=_this.ace.editor.getCursorPosition()
return file.on("fs.saveAs.finished",function(){var tabView
tabView=_this.getDelegate().tabView
if(!tabView.willClose){_this.getDelegate().openFile(FSHelper.createFileFromPath(""+parent.path+"/"+name,!0))
return closeAfter?_this.utils.defer(function(){var ace
tabView.removePane_(tabView.getActivePane())
ace=tabView.getActivePane().getOptions().aceView.ace
return ace.on("ace.ready",function(){return ace.editor.moveCursorTo(oldCursorPosition.row,oldCursorPosition.column)})}):void 0}})},{inputDefaultValue:file.name})}
return AceView}(JView)

var AceApplicationTabView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AceApplicationTabView=function(_super){function AceApplicationTabView(){_ref=AceApplicationTabView.__super__.constructor.apply(this,arguments)
return _ref}__extends(AceApplicationTabView,_super)
AceApplicationTabView.prototype.removePane_=KDTabView.prototype.removePane
AceApplicationTabView.prototype.removePane=function(pane){var ace,file,modal,_this=this
ace=pane.getOptions().aceView.ace
file=ace.getData()
return ace.isContentChanged()?modal=new KDModalView({width:620,cssClass:"modal-with-text",title:"Do you want to save your changes?",content:"<p>Your changes will be lost if you don't save them.</p>",overlay:!0,buttons:{SaveClose:{cssClass:"modal-clean-green",title:"Save and Close",callback:function(){if(0===file.path.indexOf("localfile:")){file.once("fs.saveAs.finished",function(){return _this.removePane_(pane)})
_this.willClose=!0
ace.requestSaveAs()
return modal.destroy()}ace.requestSave()
return _this.closePaneAndModal(pane,modal)}},DontSave:{cssClass:"modal-clean-red",title:"Don't Save",callback:function(){return _this.closePaneAndModal(pane,modal)}},Cancel:{cssClass:"modal-cancel",title:"Cancel",callback:function(){return modal.destroy()}}}}):this.removePane_(pane)}
AceApplicationTabView.prototype.closePaneAndModal=function(pane,modal){this.removePane_(pane)
return modal.destroy()}
return AceApplicationTabView}(ApplicationTabView)

var AceAppView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AceAppView=function(_super){function AceAppView(options,data){null==options&&(options={})
AceAppView.__super__.constructor.call(this,options,data)
this.aceViews={}
this.timestamp=Date.now()
this.appManager=KD.getSingleton("appManager")
this.tabHandleContainer=new ApplicationTabHandleHolder({delegate:this})
this.tabView=new AceApplicationTabView({delegate:this,tabHandleContainer:this.tabHandleContainer,closeAppWhenAllTabsClosed:!1,saveSession:!0,sessionName:"AceTabHistory"})
this.finderWrapper=new KDCustomHTMLView({tagName:"aside"})
this.embedFinder()
this.attachEvents()
this.attachAppMenuEvents()}__extends(AceAppView,_super)
AceAppView.prototype.embedFinder=function(){var _this=this
return this.appManager.open("Finder",function(finderApp){_this.finderController=finderApp.create()
_this.finderWrapper.addSubView(_this.finderController.getView())
_this.finderController.reset()
return _this.finderController.on("FileNeedsToBeOpened",function(file){return _this.openFile(file,!0)})})}
AceAppView.prototype.attachEvents=function(){var _this=this
this.on("SessionDataCreated",function(sessionData){_this.sessionData=sessionData})
this.on("UpdateSessionData",function(openPanes,data){_this.sessionData=_this.createSessionData(openPanes,data)
return _this.tabView.emit("SaveSessionData",_this.sessionData)})
this.on("SessionItemClicked",function(items){var file,_i,_len,_results
if(items.length>1)return _this.appManager.open("Ace",{forceNew:!0},function(appController){var appView,file,_i,_len,_results
appView=appController.getView()
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){file=items[_i]
_results.push(appView.openFile(FSHelper.createFileFromPath(file)))}return _results})
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){file=items[_i]
_results.push(_this.openFile(FSHelper.createFileFromPath(file)))}return _results})
this.tabView.on("PaneDidShow",function(pane){var ace,title
ace=pane.getOptions().aceView.ace
ace.on("ace.ready",function(){return ace.focus()})
ace.focus()
title=FSHelper.minimizePath(ace.data.path).replace(/^localfile:\//,"")
pane.tabHandle.setTitle(title)
return ace.on("AceDidSaveAs",function(){return pane.tabHandle.setTitle(title)})})
return this.on("KDObjectWillBeDestroyed",function(){return KD.getSingleton("mainView").disableFullscreen()})}
AceAppView.prototype.createSessionData=function(openPanes,data){var latest,pane,path,paths,recordKey,shifted,_i,_len
null==data&&(data={})
paths=[]
recordKey=""+this.id+"-"+this.timestamp
for(_i=0,_len=openPanes.length;_len>_i;_i++){pane=openPanes[_i]
path=pane.getOptions().aceView.getData().path;-1===path.indexOf("localfile")&&paths.push(path)}data[recordKey]=paths
latest=data.latestSessions||(data.latestSessions=[]);-1===latest.indexOf(recordKey)&&latest.push(recordKey)
if(latest.length>10){shifted=latest.shift()
delete data[shifted]}return this.sessionData=data}
AceAppView.prototype.createSessionListItems=function(){var itemCount,items,nickname,sessionData,sessionId,sessionItems,_i,_len,_ref,_this=this
items={}
sessionData=this.sessionData
nickname=KD.whoami().profile.nickname
itemCount=0
_ref=null!=sessionData.latestSessions
for(_i=0,_len=_ref.length;_len>_i;_i++){sessionId=_ref[_i]
if(itemCount>14)return items
sessionItems=sessionData[sessionId]
sessionItems.forEach(function(path){var filePath
filePath=path.replace("/home/"+nickname,"~")
filePath=filePath.replace(/^\[[^\[\]]*]/,"")
items[filePath]={callback:function(){return _this.emit("SessionItemClicked",[path])}}
return itemCount++})}return items}
AceAppView.prototype.reopenLastSession=function(){var data,latest
data=this.sessionData
latest=data.latestSessions
return(null!=latest?latest.length:void 0)>0?this.emit("SessionItemClicked",data[latest.first]):this.getActiveAceView().ace.notify("No recent file.","error")}
AceAppView.prototype.viewAppended=function(){var _this=this
AceAppView.__super__.viewAppended.apply(this,arguments)
return this.utils.wait(100,function(){return 0===_this.tabView.panes.length?_this.addNewTab():void 0})}
AceAppView.prototype.addNewTab=function(file){var aceView,pane,_this=this
file=file||FSHelper.createFileFromPath("localfile:/Untitled.txt")
aceView=new AceView({delegate:this},file)
aceView.on("KDObjectWillBeDestroyed",function(){return _this.removeOpenDocument(aceView)})
this.aceViews[file.path]=aceView
this.setViewListeners(aceView)
pane=new KDTabPaneView({name:file.name||"Untitled.txt",aceView:aceView})
this.tabView.addPane(pane)
return pane.addSubView(aceView)}
AceAppView.prototype.setViewListeners=function(view){return this.setFileListeners(view.getData())}
AceAppView.prototype.getActiveAceView=function(){return this.tabView.getActivePane().getOptions().aceView}
AceAppView.prototype.isFileOpen=function(file){return null!=this.aceViews[file.path]}
AceAppView.prototype.openFile=function(file){var mainTabView
if(file&&this.isFileOpen(file)){mainTabView=KD.getSingleton("mainView").mainTabView
mainTabView.showPane(this.parent)
return this.tabView.showPane(this.aceViews[file.path].parent)}return this.addNewTab(file)}
AceAppView.prototype.removeOpenDocument=function(aceView){return aceView?this.clearFileRecords(aceView):void 0}
AceAppView.prototype.setFileListeners=function(file){var view,_this=this
view=this.aceViews[file.path]
file.on("fs.saveAs.finished",function(newFile,oldFile){if(_this.aceViews[oldFile.path]){view=_this.aceViews[oldFile.path]
_this.clearFileRecords(view)
_this.aceViews[newFile.path]=view
view.setData(newFile)
view.parent.setTitle(newFile.name)
view.ace.setData(newFile)
_this.setFileListeners(newFile)
view.ace.notify("New file is created!","success")
return KD.getSingleton("mainController").emit("NewFileIsCreated",newFile)}})
return file.on("fs.delete.finished",function(){return _this.removeOpenDocument(_this.aceViews[file.path])})}
AceAppView.prototype.clearFileRecords=function(view){var file
file=view.getData()
return delete this.aceViews[file.path]}
AceAppView.prototype.attachAppMenuEvents=function(){var _this=this
this.on("saveMenuItemClicked",function(){return _this.getActiveAceView().ace.requestSave()})
this.on("saveAsMenuItemClicked",function(){return _this.getActiveAceView().ace.requestSaveAs()})
this.on("compileAndRunMenuItemClicked",function(){return _this.getActiveAceView().compileAndRun()})
this.on("previewMenuItemClicked",function(){return _this.getActiveAceView().preview()})
this.on("reopenMenuItemClicked",function(){return _this.reopenLastSession()})
this.on("findMenuItemClicked",function(){return _this.getActiveAceView().ace.showFindReplaceView()})
this.on("findAndReplaceMenuItemClicked",function(){return _this.getActiveAceView().ace.showFindReplaceView(!0)})
this.on("gotoLineMenuItemClicked",function(){return _this.getActiveAceView().ace.showGotoLine()})
return this.on("exitMenuItemClicked",function(){return _this.appManager.quit(_this.appManager.frontApp)})}
AceAppView.prototype.getAdvancedSettingsMenuView=function(){var aceView,pane,settingsView
pane=this.tabView.getActivePane()
aceView=pane.getOptions().aceView
settingsView=new KDView({cssClass:"editor-advanced-settings-menu"})
settingsView.addSubView(new AceSettingsView({delegate:aceView.ace}))
return settingsView}
AceAppView.prototype.getRecentsMenuView=function(){var items
items=this.createSessionListItems()
return Object.keys(items).length?items:new KDView({partial:"<cite>No recently opened file exists.</cite>"})}
AceAppView.prototype.getFullscreenMenuView=function(item,menu){var labels,mainView,state,toggleFullscreen,_this=this
labels=["Enter Fullscreen","Exit Fullscreen"]
mainView=KD.getSingleton("mainView")
state=mainView.isFullscreen()||0
toggleFullscreen=new KDView({partial:"<span>"+labels[Number(state)]+"</span>",click:function(){_this.getActiveAceView().toggleFullscreen()
menu.contextMenu.destroy()
return menu.click()}})
return toggleFullscreen.on("viewAppended",function(){return toggleFullscreen.parent.setClass("default")})}
AceAppView.prototype.pistachio=function(){return"{{> this.finderWrapper}}\n<section>\n{{> this.tabHandleContainer}}\n{{> this.tabView}}\n</section>"}
return AceAppView}(JView)

var Ace,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Ace=function(_super){function Ace(options,file){Ace.__super__.constructor.call(this,options,file)
this.lastSavedContents=""
this.appStorage=KD.getSingleton("appStorageController").storage("Ace","1.0")}var notification
__extends(Ace,_super)
Ace.prototype.setDomElement=function(){return this.domElement=$("<figure class='kdview'><div id='editor"+this.getId()+"' class='code-wrapper'></div></figure>")}
Ace.prototype.viewAppended=function(){var _this=this
this.hide()
return this.appStorage.fetchStorage(function(){require(["ace/ace"],function(ace){return _this.fetchContents(function(err,contents){"undefined"!=typeof notification&&null!==notification&&notification.destroy()
_this.editor=ace.edit("editor"+_this.getId())
_this.prepareEditor()
_this.utils.defer(function(){return _this.emit("ace.ready")})
if(contents){_this.setContents(contents)
_this.lastSavedContents=contents}_this.editor.on("change",function(){return _this.isCurrentContentChanged()?_this.emit("FileContentChanged"):_this.emit("FileContentSynced")})
_this.editor.gotoLine(0)
_this.focus()
_this.show()
return KD.track("User Opened Ace",KD.getSingleton("groupsController").getCurrentGroup())})})
require(["ace/keyboard/vim"],function(vimMode){return _this.vimKeyboardHandler=vimMode.handler})
return _this.emacsKeyboardHandler="ace/keyboard/emacs"})}
Ace.prototype.prepareEditor=function(){var _this=this
this.setTheme()
this.setSyntax()
this.setEditorListeners()
this.appStorage.fetchStorage(function(){var _ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_ref7,_ref8,_ref9
_this.setUseSoftTabs(null!=(_ref=_this.appStorage.getValue("useSoftTabs"))?_ref:!0,!1)
_this.setShowGutter(null!=(_ref1=_this.appStorage.getValue("showGutter"))?_ref1:!0,!1)
_this.setUseWordWrap(null!=(_ref2=_this.appStorage.getValue("useWordWrap"))?_ref2:!1,!1)
_this.setShowPrintMargin(null!=(_ref3=_this.appStorage.getValue("showPrintMargin"))?_ref3:!1,!1)
_this.setHighlightActiveLine(null!=(_ref4=_this.appStorage.getValue("highlightActiveLine"))?_ref4:!0,!1)
_this.setShowInvisibles(null!=(_ref5=_this.appStorage.getValue("showInvisibles"))?_ref5:!1,!1)
_this.setSoftWrap(_this.appStorage.getValue("softWrap")||"off",!1)
_this.setFontSize(null!=(_ref6=_this.appStorage.getValue("fontSize"))?_ref6:12,!1)
_this.setTabSize(null!=(_ref7=_this.appStorage.getValue("tabSize"))?_ref7:4,!1)
_this.setKeyboardHandler(null!=(_ref8=_this.appStorage.getValue("keyboardHandler"))?_ref8:"default")
return _this.setScrollPastEnd(null!=(_ref9=_this.appStorage.getValue("scrollPastEnd"))?_ref9:!0)})
return require(["ace/ext/language_tools"],function(){return _this.editor.setOptions({enableBasicAutocompletion:!0,enableSnippets:!0})})}
Ace.prototype.saveStarted=function(){return this.lastContentsSentForSave=this.getContents()}
Ace.prototype.saveFinished=function(err){var _ref
if(!err){this.notify("Successfully saved!","success")
this.lastSavedContents=this.lastContentsSentForSave
this.emit("FileContentSynced")
return this.askedForSave=!1}return(null!=err?null!=(_ref=err.message)?"function"==typeof _ref.indexOf?_ref.indexOf(!1):void 0:void 0:void 0)?this.notify("You don't have enough permission to save!","error"):void 0}
Ace.prototype.saveAsFinished=function(){this.emit("FileContentSynced")
return this.emit("FileHasBeenSavedAs",this.getData())}
Ace.prototype.setEditorListeners=function(){var _this=this
this.editor.getSession().selection.on("changeCursor",function(){return _this.emit("ace.change.cursor",_this.editor.getSession().getSelection().getCursor())})
if(this.getOptions().enableShortcuts){this.addKeyCombo("save","Ctrl-S",this.bound("requestSave"))
this.addKeyCombo("saveAs","Ctrl-Shift-S",this.bound("requestSaveAs"))
this.addKeyCombo("find","Ctrl-F",function(){return _this.showFindReplaceView(!1)})
this.addKeyCombo("replace","Ctrl-Shift-F",function(){return _this.showFindReplaceView(!0)})
this.addKeyCombo("preview","Ctrl-Shift-P",function(){return _this.getDelegate().preview()})
this.addKeyCombo("fullscreen","Ctrl-Enter",function(){return _this.getDelegate().toggleFullscreen()})
this.addKeyCombo("gotoLine","Ctrl-G",this.bound("showGotoLine"))
return this.addKeyCombo("settings","Ctrl-,",noop)}}
Ace.prototype.showFindReplaceView=function(openReplaceView){var findAndReplaceView,selectedText,_this=this
findAndReplaceView=this.getDelegate().findAndReplaceView
selectedText=this.editor.session.getTextRange(this.editor.getSelectionRange())
findAndReplaceView.setViewHeight(openReplaceView)
findAndReplaceView.setTextIntoFindInput(selectedText)
return findAndReplaceView.on("FindAndReplaceViewClosed",function(){return _this.focus()})}
Ace.prototype.addKeyCombo=function(name,winKey,macKey,callback){if("function"==typeof macKey){callback=macKey
macKey=winKey.replace("Ctrl","Command")}return this.editor.commands.addCommand({name:name,bindKey:{win:winKey,mac:macKey},exec:function(){return"function"==typeof callback?callback():void 0}})}
Ace.prototype.isContentChanged=function(){return this.contentChanged}
Ace.prototype.isCurrentContentChanged=function(){return this.getContents()!==this.lastSavedContents}
Ace.prototype.requestSave=function(){var contents
contents=this.getContents()
if(!this.isContentChanged())return this.notify("Nothing to save!")
this.askedForSave=!0
return this.emit("ace.requests.save",contents)}
Ace.prototype.requestSaveAs=function(){var contents
contents=this.getContents()
return this.emit("ace.requests.saveAs",contents)}
Ace.prototype.fetchContents=function(callback){var file,path,vmName,_this=this
file=this.getData()
if(/localfile:/.test(file.path))return callback(null,file.contents||"")
this.notify("Loading...",null,null,1e4)
file.fetchContents(callback)
vmName=file.vmName,path=file.path
return FSHelper.getInfo(FSHelper.plainPath(path),vmName,function(err,info){return!err&&info?info.writable?void 0:_this.emit("FileIsReadOnly"):void 0})}
Ace.prototype.getContents=function(){return this.editor.getSession().getValue()}
Ace.prototype.getTheme=function(){return this.editor.getTheme().replace("ace/theme/","")}
Ace.prototype.getSyntax=function(){return this.syntaxMode}
Ace.prototype.getUseSoftTabs=function(){var _ref
return null!=(_ref=this.appStorage.getValue("useSoftTabs"))?_ref:this.editor.getSession().getUseSoftTabs()}
Ace.prototype.getShowGutter=function(){var _ref
return null!=(_ref=this.appStorage.getValue("showGutter"))?_ref:this.editor.renderer.getShowGutter()}
Ace.prototype.getShowPrintMargin=function(){var _ref
return null!=(_ref=this.appStorage.getValue("showPrintMargin"))?_ref:this.editor.getShowPrintMargin()}
Ace.prototype.getHighlightActiveLine=function(){var _ref
return null!=(_ref=this.appStorage.getValue("highlightActiveLine"))?_ref:this.editor.getHighlightActiveLine()}
Ace.prototype.getShowInvisibles=function(){var _ref
return null!=(_ref=this.appStorage.getValue("showInvisibles"))?_ref:this.editor.getShowInvisibles()}
Ace.prototype.getFontSize=function(){var _ref,_ref1
return null!=(_ref=this.appStorage.getValue("fontSize"))?_ref:parseInt(null!=(_ref1=this.$("#editor"+this.getId()).css("font-size"))?_ref1:12,10)}
Ace.prototype.getTabSize=function(){var _ref
return null!=(_ref=this.appStorage.getValue("tabSize"))?_ref:this.editor.getSession().getTabSize()}
Ace.prototype.getUseWordWrap=function(){var _ref
return null!=(_ref=this.appStorage.getValue("useWordWrap"))?_ref:this.editor.getSession().getUseWrapMode()}
Ace.prototype.getSoftWrap=function(){var limit,_ref
limit=null!=(_ref=this.appStorage.getValue("softWrap"))?_ref:this.editor.getSession().getWrapLimitRange().max
return limit?limit:this.getUseWordWrap()?"free":"off"}
Ace.prototype.getKeyboardHandler=function(){var _ref
return null!=(_ref=this.appStorage.getValue("keyboardHandler"))?_ref:"default"}
Ace.prototype.getScrollPastEnd=function(){var _ref
return null!=(_ref=this.appStorage.getValue("scrollPastEnd"))?_ref:!0}
Ace.prototype.getSettings=function(){return{theme:this.getTheme(),syntax:this.getSyntax(),useSoftTabs:this.getUseSoftTabs(),showGutter:this.getShowGutter(),useWordWrap:this.getUseWordWrap(),showPrintMargin:this.getShowPrintMargin(),highlightActiveLine:this.getHighlightActiveLine(),showInvisibles:this.getShowInvisibles(),fontSize:this.getFontSize(),tabSize:this.getTabSize(),softWrap:this.getSoftWrap(),keyboardHandler:this.getKeyboardHandler(),scrollPastEnd:this.getScrollPastEnd()}}
Ace.prototype.setContents=function(contents){return this.editor.getSession().setValue(contents)}
Ace.prototype.setSyntax=function(mode){var ext,extensions,file,language,name,_ref,_ref1,_this=this
file=this.getData()
mode||(mode=file.syntax)
if(!mode){ext=FSItem.getFileExtension(file.path)
_ref=__aceSettings.syntaxAssociations
for(name in _ref)if(__hasProp.call(_ref,name)){_ref1=_ref[name],language=_ref1[0],extensions=_ref1[1]
RegExp("^(?:"+extensions+")$","i").test(ext)&&(mode=name)}mode||(mode="text")}return require(["ace/mode/"+mode],function(_arg){var Mode
Mode=_arg.Mode
_this.editor.getSession().setMode(new Mode)
return _this.syntaxMode=mode})}
Ace.prototype.setTheme=function(themeName,save){var _this=this
null==save&&(save=!0)
themeName||(themeName=this.appStorage.getValue("theme")||"merbivore_soft")
return require(["ace/theme/"+themeName],function(callback){_this.editor.setTheme("ace/theme/"+themeName)
return save?_this.appStorage.setValue("theme",themeName,function(){return callback}):void 0})}
Ace.prototype.setUseSoftTabs=function(value,save){null==save&&(save=!0)
this.editor.getSession().setUseSoftTabs(value)
return save?this.appStorage.setValue("useSoftTabs",value):void 0}
Ace.prototype.setShowGutter=function(value,save){null==save&&(save=!0)
this.editor.renderer.setShowGutter(value)
return save?this.appStorage.setValue("showGutter",value):void 0}
Ace.prototype.setShowPrintMargin=function(value,save){null==save&&(save=!0)
this.editor.setShowPrintMargin(value)
return save?this.appStorage.setValue("showPrintMargin",value):void 0}
Ace.prototype.setHighlightActiveLine=function(value,save){null==save&&(save=!0)
this.editor.setHighlightActiveLine(value)
return save?this.appStorage.setValue("highlightActiveLine",value):void 0}
Ace.prototype.setShowInvisibles=function(value,save){null==save&&(save=!0)
this.editor.setShowInvisibles(value)
return save?this.appStorage.setValue("showInvisibles",value):void 0}
Ace.prototype.setKeyboardHandler=function(value){var handlers
null==value&&(value="default")
handlers={"default":null,vim:this.vimKeyboardHandler,emacs:this.emacsKeyboardHandler}
this.editor.setKeyboardHandler(handlers[value])
return this.appStorage.setValue("keyboardHandler",value)}
Ace.prototype.setScrollPastEnd=function(value){null==value&&(value=!0)
this.editor.setOption("scrollPastEnd",value)
return this.appStorage.setValue("scrollPastEnd",value)}
Ace.prototype.setFontSize=function(value,save){null==save&&(save=!0)
this.$("#editor"+this.getId()).css("font-size",""+value+"px")
return save?this.appStorage.setValue("fontSize",value):void 0}
Ace.prototype.setTabSize=function(value,save){null==save&&(save=!0)
this.editor.getSession().setTabSize(+value)
return save?this.appStorage.setValue("tabSize",value):void 0}
Ace.prototype.setUseWordWrap=function(value,save){null==save&&(save=!0)
this.editor.getSession().setUseWrapMode(value)
return save?this.appStorage.setValue("useWordWrap",value):void 0}
Ace.prototype.setReadOnly=function(value){return this.editor.setReadOnly(value)}
Ace.prototype.setSoftWrap=function(value,save){var limit,margin,softWrapValueMap,_ref
null==save&&(save=!0)
softWrapValueMap={off:[null,80],40:[40,40],80:[80,80],free:[null,80]}
_ref=softWrapValueMap[value],limit=_ref[0],margin=_ref[1]
this.editor.getSession().setWrapLimitRange(limit,limit)
this.editor.renderer.setPrintMarginColumn(margin)
"off"===value&&this.setUseWordWrap(!1)
return save?this.appStorage.setValue("softWrap",value):void 0}
Ace.prototype.gotoLine=function(lineNumber){return this.editor.gotoLine(lineNumber)}
Ace.prototype.focus=function(){var _ref
return null!=(_ref=this.editor)?_ref.focus():void 0}
notification=null
Ace.prototype.notify=function(msg,style,details,duration){notification&&notification.destroy()
details&&(style||(style="error"))
return notification=new KDNotificationView({title:msg||"Something went wrong",type:"mini",cssClass:""+style,duration:duration||(details?5e3:2500),details:details,click:function(){if(notification.getOptions().details){details=new KDNotificationView({title:"Error details",content:notification.getOptions().details,type:"growl",duration:0,click:function(){return details.destroy()}})
KD.getSingleton("windowController").addLayer(details)
return details.on("ReceivedClickElsewhere",function(){return details.destroy()})}}})}
Ace.prototype.showGotoLine=function(){var _this=this
if(!this.gotoLineModal){this.gotoLineModal=new KDModalViewWithForms({cssClass:"goto",width:180,height:"auto",overlay:!0,tabs:{forms:{Go:{callback:function(form){var lineNumber
lineNumber=parseInt(form.line,10)
lineNumber>0&&_this.gotoLine(lineNumber)
return _this.gotoLineModal.destroy()},fields:{Line:{type:"text",name:"line",placeholder:"Goto line",nextElement:{Go:{itemClass:KDButtonView,title:"Go",style:"modal-clean-gray fl",type:"submit"}}}}}}}})
this.gotoLineModal.on("KDModalViewDestroyed",function(){_this.gotoLineModal=null
return _this.focus()})
return this.gotoLineModal.modalTabs.forms.Go.focusFirstElement()}}
return Ace}(KDView)

var AceSettingsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AceSettingsView=function(_super){function AceSettingsView(){var button
AceSettingsView.__super__.constructor.apply(this,arguments)
this.setClass("ace-settings-view")
button=this.getDelegate()
this.useSoftTabs=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","useSoftTabs",state)}})
this.showGutter=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","showGutter",state)}})
this.useWordWrap=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","useWordWrap",state)}})
this.showPrintMargin=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","showPrintMargin",state)}})
this.highlightActiveLine=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","highlightActiveLine",state)}})
this.highlightWord=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","highlightSelectedWord",state)}})
this.showInvisibles=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","showInvisibles",state)}})
this.scrollPastEnd=new KDOnOffSwitch({callback:function(state){return button.emit("ace.changeSetting","scrollPastEnd",state)}})
this.keyboardHandler=new KDSelectBox({selectOptions:__aceSettings.keyboardHandlers,callback:function(value){return button.emit("ace.changeSetting","keyboardHandler",value)}})
this.softWrap=new KDSelectBox({selectOptions:__aceSettings.softWrapOptions,callback:function(value){return button.emit("ace.changeSetting","softWrap",value)}})
this.syntax=new KDSelectBox({selectOptions:__aceSettings.getSyntaxOptions(),callback:function(value){return button.emit("ace.changeSetting","syntax",value)}})
this.fontSize=new KDSelectBox({selectOptions:__aceSettings.fontSizes,callback:function(value){return button.emit("ace.changeSetting","fontSize",value)}})
this.theme=new KDSelectBox({selectOptions:__aceSettings.themes,callback:function(value){return button.emit("ace.changeSetting","theme",value)}})
this.tabSize=new KDSelectBox({selectOptions:__aceSettings.tabSizes,callback:function(value){return button.emit("ace.changeSetting","tabSize",value)}})
this.shortcuts=new KDCustomHTMLView({tagName:"a",cssClass:"shortcuts",attributes:{href:"#"},partial:"⌘ Keyboard Shortcuts",click:function(){return log("show shortcuts")}})}__extends(AceSettingsView,_super)
AceSettingsView.prototype.setDefaultValues=function(settings){var key,value,_ref,_results
_results=[]
for(key in settings)if(__hasProp.call(settings,key)){value=settings[key]
_results.push(null!=(_ref=this[key])?_ref.setDefaultValue(value):void 0)}return _results}
AceSettingsView.prototype.viewAppended=function(){var aceView
AceSettingsView.__super__.viewAppended.apply(this,arguments)
aceView=this.getDelegate()
return aceView?this.setDefaultValues(aceView.getSettings()):void 0}
AceSettingsView.prototype.click=function(event){event.preventDefault()
event.stopPropagation()
return!1}
AceSettingsView.prototype.pistachio=function(){return"<p>Use soft tabs            {{> this.useSoftTabs}}</p>\n<p>Line numbers             {{> this.showGutter}}</p>\n<p>Use word wrapping        {{> this.useWordWrap}}</p>\n<p>Show print margin        {{> this.showPrintMargin}}</p>\n<p>Highlight active line    {{> this.highlightActiveLine}}</p>\n\n<p class='hidden'>Highlight selected word  {{> this.highlightWord}}</p>\n\n<p>Show invisibles          {{> this.showInvisibles}}</p>\n<p>Use scroll past end      {{> this.scrollPastEnd}}</p>\n<hr>\n<p>Soft wrap                {{> this.softWrap}}</p>\n<p>Syntax                   {{> this.syntax}}</p>\n<p>Key binding              {{> this.keyboardHandler}}</p>\n<p>Font                     {{> this.fontSize}}</p>\n<p>Theme                    {{> this.theme}}</p>\n<p>Tab size                 {{> this.tabSize}}</p>\n\n<p class='hidden'>{{> this.shortcuts}}</p>\n"}
return AceSettingsView}(JView)

var __aceSettings,__hasProp={}.hasOwnProperty
__aceSettings={compilerCallNames:{coffee:{"class":"CoffeeScript",method:"compile",options:{bare:!0}}},softWrapOptions:[{value:"off",title:"Off"},{value:40,title:"40 chars"},{value:80,title:"80 chars"},{value:"free",title:"Free"}],fontSizes:[{value:10,title:"10px"},{value:11,title:"11px"},{value:12,title:"12px"},{value:14,title:"14px"},{value:16,title:"16px"},{value:20,title:"20px"},{value:24,title:"24px"}],tabSizes:[{value:2,title:"2 chars"},{value:4,title:"4 chars"},{value:8,title:"8 chars"}],keyboardHandlers:[{value:"default",title:"Default"},{value:"vim",title:"Vim"},{value:"emacs",title:"Emacs"}],themes:{Bright:[{title:"Chrome",value:"chrome"},{title:"Clouds",value:"clouds"},{title:"Crimson Editor",value:"crimson_editor"},{title:"Dawn",value:"dawn"},{title:"Dreamweaver",value:"dreamweaver"},{title:"Eclipse",value:"eclipse"},{title:"GitHub",value:"github"},{title:"Solarized Light",value:"solarized_light"},{title:"TextMate",value:"textmate"},{title:"Tomorrow",value:"tomorrow"},{title:"XCode",value:"xcode"}].sort(function(a,b){return a.title<b.title?-1:1}),Dark:[{title:"Ambiance",value:"ambiance"},{title:"Clouds Midnight",value:"clouds_midnight"},{title:"Cobalt",value:"cobalt"},{title:"Idle Fingers",value:"idle_fingers"},{title:"KR Theme",value:"kr_theme"},{title:"Koding",value:"koding"},{title:"Merbivore",value:"merbivore"},{title:"Merbivore Soft",value:"merbivore_soft"},{title:"Mono Industrial",value:"mono_industrial"},{title:"Monokai",value:"monokai"},{title:"Pastel on Dark",value:"pastel_on_dark"},{title:"Solarized Dark",value:"solarized_dark"},{title:"Twilight",value:"twilight"},{title:"Tomorrow Night",value:"tomorrow_night"},{title:"Tomorrow Night Blue",value:"tomorrow_night_blue"},{title:"Tomorrow Night Bright",value:"tomorrow_night_bright"},{title:"Tomorrow Night 80s",value:"tomorrow_night_eighties"},{title:"Vibrant Ink",value:"vibrant_ink"}].sort(function(a,b){return a.title<b.title?-1:1})},syntaxAssociations:{abap:["ABAP","abap"],asciidoc:["ASCIIDoc","AsciiDoc"],coffee:["CoffeeScript","coffee|Cakefile"],coldfusion:["ColdFusion","cfm"],csharp:["C#","cs"],css:["CSS","css"],dart:["Dart","dart"],diff:["Diff","diff|patch"],golang:["Go","go"],glsl:["GLSL","glsl"],groovy:["Groovy","groovy"],haxe:["haXe","hx"],haml:["HAML","haml"],html:["HTML","htm|html|xhtml"],c_cpp:["C/C++","c|cc|cpp|cxx|h|hh|hpp"],clojure:["Clojure","clj"],delphi:["Delphi","delphi"],jade:["Jade","jade"],java:["Java","java"],javascript:["JavaScript","js"],json:["JSON","json|manifest|kdapp"],jsx:["JSX","jsx"],latex:["LaTeX","latex|tex|ltx|bib"],less:["LESS","less"],liquid:["Liquid","liquid"],lisp:["Lisp","lisp"],lucene:["Lucene","cfs"],lua:["Lua","lua"],luapage:["LuaPage","lp"],makefile:["MAKEFILE","makefile"],markdown:["Markdown","md|markdown"],ocaml:["OCaml","ml|mli"],perl:["Perl","pl|pm"],pgsql:["pgSQL","pgsql"],php:["PHP","php|phtml"],rhtml:["RHTML","rhtml"],r:["R","r"],rdoc:["RDOC","rdoc"],powershell:["Powershell","ps1"],python:["Python","py"],ruby:["Ruby","ru|gemspec|rake|rb|erb"],scad:["OpenSCAD","scad"],scala:["Scala","scala"],scss:["SCSS","scss|sass"],stylus:["Stylus","styl"],sh:["SH","sh|bash|bat"],sql:["SQL","sql"],svg:["SVG","svg"],tex:["TeX","tex"],text:["Text","txt"],textile:["Textile","textile"],typescript:["Typescript","ts"],xml:["XML","xml|rdf|rss|wsdl|xslt|atom|mathml|mml|xul|xbl"],xquery:["XQuery","xq"],yaml:["YAML","yaml|yml"],objectivec:["Objective C","__dummy__"]},getSyntaxOptions:function(){var info,o,syntax
o=function(){var _ref,_results
_ref=__aceSettings.syntaxAssociations
_results=[]
for(syntax in _ref)if(__hasProp.call(_ref,syntax)){info=_ref[syntax]
_results.push({title:info[0],value:syntax})}return _results}()
o.sort(function(a,b){return a.title<b.title?-1:1})
return o},aceToHighlightJsSyntaxMap:{coffee:"coffee",csharp:"cs",css:"css",diff:"diff",dart:"dart",golang:"go",haml:"haml",html:"xml",c_cpp:"cpp",jade:"jade",java:"java",javascript:"javascript",json:"javascript",latex:"tex",go:"golang",less:"css",lisp:"lisp",lua:"lua",markdown:"markdown",ocaml:"ocaml",perl:"perl",pgsql:"sql",php:"php",powershell:"bash",python:"python",r:"r",rhtml:"rhtml",ruby:"ruby",scala:"scala",scss:"css",stylus:"stylus",sh:"bash",sql:"sql",typescript:"ts",xml:"xml",objectivec:"objectivec"}}

var AceFindAndReplaceView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AceFindAndReplaceView=function(_super){function AceFindAndReplaceView(options,data){var _this=this
null==options&&(options={})
options.cssClass="ace-find-replace-view"
AceFindAndReplaceView.__super__.constructor.call(this,options,data)
this.mode=null
this.lastViewHeight=0
this.findInput=new KDHitEnterInputView({type:"text",placeholder:"Find...",validate:{rules:{required:!0}},keyup:this.bindSpecialKeys("find"),callback:function(){return _this.findNext()}})
this.findNextButton=new KDButtonView({cssClass:"editor-button",title:"Find Next",callback:function(){return _this.findNext()}})
this.findPrevButton=new KDButtonView({cssClass:"editor-button",title:"Find Prev",callback:function(){return _this.findPrev()}})
this.replaceInput=new KDHitEnterInputView({type:"text",cssClass:"ace-replace-input",placeholder:"Replace...",validate:{rules:{required:!0}},keyup:this.bindSpecialKeys("replace"),callback:function(){return _this.replace()}})
this.replaceButton=new KDButtonView({title:"Replace",cssClass:"ace-replace-button",callback:function(){return _this.replace()}})
this.replaceAllButton=new KDButtonView({title:"Replace All",cssClass:"ace-replace-button",callback:function(){return _this.replaceAll()}})
this.closeButton=new KDCustomHTMLView({tagName:"span",cssClass:"close-icon",click:function(){return _this.close()}})
this.choices=new KDMultipleChoice({cssClass:"clean-gray editor-button control-button",labels:["case-sensitive","whole-word","regex"],multiple:!0,defaultValue:"fakeValueToDeselectFirstOne"})}__extends(AceFindAndReplaceView,_super)
AceFindAndReplaceView.prototype.bindSpecialKeys=function(input){var _this=this
return{esc:function(){return _this.close()},"super+f":function(e){e.preventDefault()
return _this.setViewHeight(!1)},"super+shift+f":function(e){e.preventDefault()
return _this.setViewHeight(!0)},"shift+enter":function(){return"find"===input?_this.findPrev():void 0}}}
AceFindAndReplaceView.prototype.close=function(){this.hide()
this.resizeEditor(0)
this.findInput.setValue("")
this.replaceInput.setValue("")
return this.emit("FindAndReplaceViewClosed")}
AceFindAndReplaceView.prototype.setViewHeight=function(isReplaceMode){var height
height=isReplaceMode?60:31
this.$().css({height:height})
this.resizeEditor(height)
return this.show()}
AceFindAndReplaceView.prototype.resizeEditor=function(height){var ace
ace=this.getDelegate().ace
ace.setHeight(ace.getHeight()+this.lastHeightTakenFromAce-height)
ace.editor.resize(!0)
return this.lastHeightTakenFromAce=height}
AceFindAndReplaceView.prototype.lastHeightTakenFromAce=0
AceFindAndReplaceView.prototype.setTextIntoFindInput=function(text){if(text.indexOf("\n")>0||0===text.length)return this.findInput.setFocus()
this.findInput.setValue(text)
return this.findInput.setFocus()}
AceFindAndReplaceView.prototype.getSearchOptions=function(){this.selections=this.choices.getValue()
return{caseSensitive:this.selections.indexOf("case-sensitive")>-1,wholeWord:this.selections.indexOf("whole-word")>-1,regExp:this.selections.indexOf("regex")>-1,backwards:!1}}
AceFindAndReplaceView.prototype.findNext=function(){return this.findHelper("next")}
AceFindAndReplaceView.prototype.findPrev=function(){return this.findHelper("prev")}
AceFindAndReplaceView.prototype.findHelper=function(direction){var keyword,methodName
keyword=this.findInput.getValue()
if(keyword){methodName="prev"===direction?"findPrevious":"find"
this.getDelegate().ace.editor[methodName](this.findInput.getValue(),this.getSearchOptions())
return this.findInput.focus()}}
AceFindAndReplaceView.prototype.replace=function(){return this.replaceHelper(!1)}
AceFindAndReplaceView.prototype.replaceAll=function(){return this.replaceHelper(!0)}
AceFindAndReplaceView.prototype.replaceHelper=function(doReplaceAll){var editor,findKeyword,methodName,replaceKeyword
findKeyword=this.findInput.getValue()
replaceKeyword=this.replaceInput.getValue()
if(findKeyword||replaceKeyword){editor=this.getDelegate().ace.editor
methodName=doReplaceAll?"replaceAll":"replace"
this.findNext()
return editor[methodName](replaceKeyword)}}
AceFindAndReplaceView.prototype.pistachio=function(){return'<div class="ace-find-replace-settings">\n  {{> this.choices}}\n</div>\n<div class="ace-find-replace-inputs">\n  {{> this.findInput}}\n  {{> this.replaceInput}}\n</div>\n<div class="ace-find-replace-buttons">\n  {{> this.findNextButton}}\n  {{> this.findPrevButton}}\n  {{> this.replaceButton}}\n  {{> this.replaceAllButton}}\n</div>\n{{> this.closeButton}}'}
return AceFindAndReplaceView}(JView)

//@ sourceMappingURL=/js/__app.ace.0.0.1.js.map