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

!function(){function g(a){throw a}function aa(a){return function(){return this[a]}}function r(a){return function(){return a}}function ca(){}function da(a){a.mb=function(){return a.bd?a.bd:a.bd=new a}}function ea(a){var b=typeof a
if("object"==b){if(!a)return"null"
if(a instanceof Array)return"array"
if(a instanceof Object)return b
var c=Object.prototype.toString.call(a)
if("[object Window]"==c)return"object"
if("[object Array]"==c||"number"==typeof a.length&&"undefined"!=typeof a.splice&&"undefined"!=typeof a.propertyIsEnumerable&&!a.propertyIsEnumerable("splice"))return"array"
if("[object Function]"==c||"undefined"!=typeof a.call&&"undefined"!=typeof a.propertyIsEnumerable&&!a.propertyIsEnumerable("call"))return"function"}else if("function"==b&&"undefined"==typeof a.call)return"object"
return b}function u(a){return a!==j}function fa(a){var b=ea(a)
return"array"==b||"object"==b&&"number"==typeof a.length}function v(a){return"string"==typeof a}function ga(a){return"number"==typeof a}function ha(a){var b=typeof a
return"object"==b&&a!=l||"function"==b}function ia(a){return a.call.apply(a.bind,arguments)}function ja(a,b){a||g(Error())
if(2<arguments.length){var d=Array.prototype.slice.call(arguments,2)
return function(){var c=Array.prototype.slice.call(arguments)
Array.prototype.unshift.apply(c,d)
return a.apply(b,c)}}return function(){return a.apply(b,arguments)}}function w(){w=Function.prototype.bind&&-1!=Function.prototype.bind.toString().indexOf("native code")?ia:ja
return w.apply(l,arguments)}function ka(a,b){function c(){}c.prototype=b.prototype
a.Vd=b.prototype
a.prototype=new c}function la(a){a=String(a)
if(/^\s*$/.test(a)?0:/^[\],:{}\s\u2028\u2029]*$/.test(a.replace(/\\["\\\/bfnrtu]/g,"@").replace(/"[^"\\\n\r\u2028\u2029\x00-\x08\x10-\x1f\x80-\x9f]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,"]").replace(/(?:^|:|,)(?:[\s\u2028\u2029]*\[)+/g,"")))try{return eval("("+a+")")}catch(b){}g(Error("Invalid JSON string: "+a))}function ma(){this.dc=j}function na(a,b,c){switch(typeof b){case"string":oa(b,c)
break
case"number":c.push(isFinite(b)&&!isNaN(b)?b:"null")
break
case"boolean":c.push(b)
break
case"undefined":c.push("null")
break
case"object":if(b==l){c.push("null")
break}if("array"==ea(b)){var d=b.length
c.push("[")
for(var e="",f=0;d>f;f++)c.push(e),e=b[f],na(a,a.dc?a.dc.call(b,String(f),e):e,c),e=","
c.push("]")
break}c.push("{")
d=""
for(f in b)Object.prototype.hasOwnProperty.call(b,f)&&(e=b[f],"function"!=typeof e&&(c.push(d),oa(f,c),c.push(":"),na(a,a.dc?a.dc.call(b,f,e):e,c),d=","))
c.push("}")
break
case"function":break
default:g(Error("Unknown type: "+typeof b))}}function oa(a,b){b.push('"',a.replace(qa,function(a){if(a in pa)return pa[a]
var b=a.charCodeAt(0),e="\\u"
16>b?e+="000":256>b?e+="00":4096>b&&(e+="0")
return pa[a]=e+b.toString(16)}),'"')}function y(a){if("undefined"!=typeof JSON&&u(JSON.stringify))a=JSON.stringify(a)
else{var b=[]
na(new ma,a,b)
a=b.join("")}return a}function ra(a){for(var b=[],c=0,d=0;d<a.length;d++){var e=a.charCodeAt(d)
e>=55296&&56319>=e&&(e-=55296,d++,z(d<a.length,"Surrogate pair missing trail surrogate."),e=65536+(e<<10)+(a.charCodeAt(d)-56320))
128>e?b[c++]=e:(2048>e?b[c++]=192|e>>6:(65536>e?b[c++]=224|e>>12:(b[c++]=240|e>>18,b[c++]=128|63&e>>12),b[c++]=128|63&e>>6),b[c++]=128|63&e)}return b}function A(a,b,c,d){var e
b>d?e="at least "+b:d>c&&(e=0===c?"none":"no more than "+c)
e&&g(Error(a+" failed: Was called with "+d+(1===d?" argument.":" arguments.")+" Expects "+e+"."))}function B(a,b,c){var d=""
switch(b){case 1:d=c?"first":"First"
break
case 2:d=c?"second":"Second"
break
case 3:d=c?"third":"Third"
break
case 4:d=c?"fourth":"Fourth"
break
default:sa.assert(o,"errorPrefix_ called with argumentNumber > 4.  Need to update it?")}return a+" failed: "+(d+" argument ")}function C(a,b,c,d){(!d||u(c))&&"function"!=ea(c)&&g(Error(B(a,b,d)+"must be a valid function."))}function ta(a,b,c){u(c)&&(!ha(c)||c===l)&&g(Error(B(a,b,k)+"must be a valid context object."))}function D(a,b){return Object.prototype.hasOwnProperty.call(a,b)}function ua(a,b){return Object.prototype.hasOwnProperty.call(a,b)?a[b]:void 0}function xa(a){return v(a)&&0!==a.length&&!va.test(a)}function ya(a,b,c){(!c||u(b))&&za(B(a,1,c),b)}function za(a,b,c,d){c||(c=0)
d||(d=[])
u(b)||g(Error(a+"contains undefined"+Aa(d)))
"function"==ea(b)&&g(Error(a+"contains a function"+Aa(d)+" with contents: "+b.toString()))
Ba(b)&&g(Error(a+"contains "+b.toString()+Aa(d)))
c>1e3&&g(new TypeError(a+"contains a cyclic object value ("+d.slice(0,100).join(".")+"...)"))
v(b)&&b.length>10485760/3&&10485760<ra(b).length&&g(Error(a+"contains a string greater than 10485760 utf8 bytes"+Aa(d)+" ('"+b.substring(0,50)+"...')"))
if(ha(b))for(var e in b)D(b,e)&&(".priority"!==e&&".value"!==e&&".sv"!==e&&!xa(e)&&g(Error(a+"contains an invalid key ("+e+")"+Aa(d)+'.  Keys must be non-empty strings and can\'t contain ".", "#", "$", "/", "[", or "]"')),d.push(e),za(a,b[e],c+1,d),d.pop())}function Aa(a){return 0==a.length?"":" in property '"+a.join(".")+"'"}function Ca(a,b){ha(b)||g(Error(B(a,1,o)+" must be an object containing the children to replace."))
ya(a,b,o)}function Da(a,b,c,d){!(d&&!u(c)||c===l||ga(c)||v(c)||ha(c)&&D(c,".sv")||!g(Error(B(a,b,d)+"must be a valid firebase priority (a string, number, or null).")))}function Ea(a,b,c){if(!c||u(b))switch(b){case"value":case"child_added":case"child_removed":case"child_changed":case"child_moved":break
default:g(Error(B(a,1,c)+'must be a valid event type: "value", "child_added", "child_removed", "child_changed", or "child_moved".'))}}function Fa(a,b){u(b)&&!xa(b)&&g(Error(B(a,2,k)+'was an invalid key: "'+b+'".  Firebase keys must be non-empty strings and can\'t contain ".", "#", "$", "/", "[", or "]").'))}function Ga(a,b){(!v(b)||0===b.length||wa.test(b))&&g(Error(B(a,1,o)+'was an invalid path: "'+b+'". Paths must be non-empty strings and can\'t contain ".", "#", "$", "[", or "]"'))}function E(a,b){".info"===F(b)&&g(Error(a+" failed: Can't modify data under /.info/"))}function H(a,b,c,d,e,f,h){this.n=a
this.path=b
this.Ba=c
this.ca=d
this.ua=e
this.za=f
this.Sa=h
u(this.ca)&&u(this.za)&&u(this.Ba)&&g("Query: Can't combine startAt(), endAt(), and limit().")}function Ia(a){var b={}
u(a.ca)&&(b.sp=a.ca)
u(a.ua)&&(b.sn=a.ua)
u(a.za)&&(b.ep=a.za)
u(a.Sa)&&(b.en=a.Sa)
u(a.Ba)&&(b.l=a.Ba)
u(a.ca)&&u(a.ua)&&a.ca===l&&a.ua===l&&(b.vf="l")
return b}function Ha(a,b,c){var d={}
b&&c?(d.cancel=b,C(a,3,d.cancel,k),d.T=c,ta(a,4,d.T)):b&&("object"==typeof b&&b!==l?d.T=b:"function"==typeof b?d.cancel=b:g(Error(B(a,3,k)+"must either be a cancel callback or a context object.")))
return d}function K(a){if(a instanceof K)return a
if(1==arguments.length){this.m=a.split("/")
for(var b=0,c=0;c<this.m.length;c++)0<this.m[c].length&&(this.m[b]=this.m[c],b++)
this.m.length=b
this.Z=0}else this.m=arguments[0],this.Z=arguments[1]}function F(a){return a.Z>=a.m.length?l:a.m[a.Z]}function Ka(a){var b=a.Z
b<a.m.length&&b++
return new K(a.m,b)}function La(a,b){var c=F(a)
if(c===l)return b
if(c===F(b))return La(Ka(a),Ka(b))
g("INTERNAL ERROR: innerPath ("+b+") is not within outerPath ("+a+")")
return void 0}function Ma(){this.children={}
this.pc=0
this.value=l}function Na(a,b,c){this.Ca=a?a:""
this.Bb=b?b:l
this.z=c?c:new Ma}function L(a,b){for(var e,c=b instanceof K?b:new K(b),d=a;(e=F(c))!==l;)d=new Na(e,d,ua(d.z.children,e)||new Ma),c=Ka(c)
return d}function M(a,b){z("undefined"!=typeof b)
a.z.value=b
Oa(a)}function Pa(a,b,c,d){c&&!d&&b(a)
a.w(function(a){Pa(a,b,k,d)})
c&&d&&b(a)}function Qa(a,b,c){for(a=c?a:a.parent();a!==l;){if(b(a))return k
a=a.parent()}return o}function Oa(a){if(a.Bb!==l){var b=a.Bb,c=a.Ca,d=a.f(),e=D(b.z.children,c)
d&&e?(delete b.z.children[c],b.z.pc--,Oa(b)):!d&&!e&&(b.z.children[c]=a.z,b.z.pc++,Oa(b))}}function Ra(a,b){this.Pa=a?a:Sa
this.ba=b?b:Ta}function Sa(a,b){return b>a?-1:a>b?1:0}function Ua(a,b){for(var c,d=a.ba,e=l;!d.f();){c=a.Pa(b,d.key)
if(0===c){if(d.left.f())return e?e.key:l
for(d=d.left;!d.right.f();)d=d.right
return d.key}0>c?d=d.left:c>0&&(e=d,d=d.right)}g(Error("Attempted to find predecessor key for a nonexistent key.  What gives?"))}function Va(a,b){this.jd=b
for(this.Rb=[];!a.f();)this.Rb.push(a),a=a.left}function Wa(a){if(0===a.Rb.length)return l
var c,b=a.Rb.pop()
c=a.jd?a.jd(b.key,b.value):{key:b.key,value:b.value}
for(b=b.right;!b.f();)a.Rb.push(b),b=b.left
return c}function Xa(a,b,c,d,e){this.key=a
this.value=b
this.color=c!=l?c:k
this.left=d!=l?d:Ta
this.right=e!=l?e:Ta}function Ya(a){return a.left.f()?a:Ya(a.left)}function bb(a){if(a.left.f())return Ta
!a.left.O()&&!a.left.left.O()&&(a=cb(a))
a=a.copy(l,l,l,bb(a.left),l)
return Za(a)}function Za(a){a.right.O()&&!a.left.O()&&(a=fb(a))
a.left.O()&&a.left.left.O()&&(a=db(a))
a.left.O()&&a.right.O()&&(a=eb(a))
return a}function cb(a){a=eb(a)
a.right.left.O()&&(a=a.copy(l,l,l,l,db(a.right)),a=fb(a),a=eb(a))
return a}function fb(a){var b
b=a.copy(l,l,k,l,a.right.left)
return a.right.copy(l,l,a.color,b,l)}function db(a){var b
b=a.copy(l,l,k,a.left.right,l)
return a.left.copy(l,l,a.color,l,b)}function eb(a){var b,c
b=a.left.copy(l,l,!a.left.color,l,l)
c=a.right.copy(l,l,!a.right.color,l,l)
return a.copy(l,l,!a.color,b,c)}function gb(){}function kb(){}function lb(){this.B=[]
this.oc=[]
this.rd=[]
this.Xb=[]
this.Xb[0]=128
for(var a=1;64>a;++a)this.Xb[a]=0
this.reset()}function mb(a,b){var c
c||(c=0)
for(var d=a.rd,e=c;c+64>e;e+=4)d[e/4]=b[e]<<24|b[e+1]<<16|b[e+2]<<8|b[e+3]
for(e=16;80>e;e++){var f=d[e-3]^d[e-8]^d[e-14]^d[e-16]
d[e]=4294967295&(f<<1|f>>>31)}c=a.B[0]
for(var p,h=a.B[1],i=a.B[2],m=a.B[3],n=a.B[4],e=0;80>e;e++)40>e?20>e?(f=m^h&(i^m),p=1518500249):(f=h^i^m,p=1859775393):60>e?(f=h&i|m&(h|i),p=2400959708):(f=h^i^m,p=3395469782),f=4294967295&(c<<5|c>>>27)+f+n+p+d[e],n=m,m=i,i=4294967295&(h<<30|h>>>2),h=c,c=f
a.B[0]=4294967295&a.B[0]+c
a.B[1]=4294967295&a.B[1]+h
a.B[2]=4294967295&a.B[2]+i
a.B[3]=4294967295&a.B[3]+m
a.B[4]=4294967295&a.B[4]+n}function nb(){this.Oa={}
this.length=0}function qb(a,b,c,d){this.host=a.toLowerCase()
this.domain=this.host.substr(this.host.indexOf(".")+1)
this.ec=b
this.ub=c
this.ea=d||ob.getItem(a)||this.host}function rb(a,b){b!==a.ea&&(a.ea=b,"s-"===a.ea.substr(0,2)&&ob.setItem(a.host,a.ea))}function wb(){return ba.navigator?ba.navigator.userAgent:l}function Gb(a,b){fa(a)||g(Error("encodeByteArray takes an array as a parameter"))
if(!Eb){Eb={}
Fb={}
for(var c=0;65>c;c++)Eb[c]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".charAt(c),Fb[c]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.".charAt(c)}for(var c=b?Fb:Eb,d=[],e=0;e<a.length;e+=3){var f=a[e],h=e+1<a.length,i=h?a[e+1]:0,m=e+2<a.length,n=m?a[e+2]:0,p=f>>2,f=(3&f)<<4|i>>4,i=(15&i)<<2|n>>6,n=63&n
m||(n=64,h||(i=64))
d.push(c[p],c[f],c[i],c[n])}return d.join("")}function z(a,b){a||g(Error("Firebase INTERNAL ASSERT FAILED:"+b))}function Jb(a){var b=ra(a),a=new lb
a.update(b)
var b=[],c=8*a.Sc
56>a.ob?a.update(a.Xb,56-a.ob):a.update(a.Xb,64-(a.ob-56))
for(var d=63;d>=56;d--)a.oc[d]=255&c,c/=256
mb(a,a.oc)
for(d=c=0;5>d;d++)for(var e=24;e>=0;e-=8)b[c++]=255&a.B[d]>>e
return Gb(b)}function Kb(){for(var a="",b=0;b<arguments.length;b++)a=fa(arguments[b])?a+Kb.apply(l,arguments[b]):"object"==typeof arguments[b]?a+y(arguments[b]):a+arguments[b],a+=" "
return a}function N(){Mb===k&&(Mb=o,Lb===l&&"true"===ob.getItem("logging_enabled")&&Nb(k))
if(Lb){var a=Kb.apply(l,arguments)
Lb(a)}}function Ob(a){return function(){N(a,arguments)}}function Pb(){if("undefined"!=typeof console){var a="FIREBASE INTERNAL ERROR: "+Kb.apply(l,arguments)
"undefined"!=typeof console.error?console.error(a):console.log(a)}}function Qb(){var a=Kb.apply(l,arguments)
g(Error("FIREBASE FATAL ERROR: "+a))}function P(){if("undefined"!=typeof console){var a="FIREBASE WARNING: "+Kb.apply(l,arguments)
"undefined"!=typeof console.warn?console.warn(a):console.log(a)}}function Ba(a){return ga(a)&&(a!=a||a==Number.POSITIVE_INFINITY||a==Number.NEGATIVE_INFINITY)}function Rb(a,b){return a!==b?a===l?-1:b===l?1:typeof a!=typeof b?"number"==typeof a?-1:1:a>b?1:-1:0}function Sb(a,b){if(a===b)return 0
var c=Tb(a),d=Tb(b)
return c!==l?d!==l?c-d:-1:d!==l?1:b>a?-1:1}function Ub(a,b){if(b&&a in b)return b[a]
g(Error("Missing required key ("+a+") in object: "+y(b)))
return void 0}function Ja(a){if("object"!=typeof a||a===l)return y(a)
var c,b=[]
for(c in a)b.push(c)
b.sort()
c="{"
for(var d=0;d<b.length;d++)0!==d&&(c+=","),c+=y(b[d]),c+=":",c+=Ja(a[b[d]])
return c+"}"}function Vb(a,b){if(a.length<=b)return[a]
for(var c=[],d=0;d<a.length;d+=b)d+b>a?c.push(a.substring(d,a.length)):c.push(a.substring(d,d+b))
return c}function Wb(a,b){if("array"==ea(a))for(var c=0;c<a.length;++c)b(c,a[c])
else Xb(a,b)}function Yb(a){z(!Ba(a))
var b,c,d,e
0===a?(d=c=0,b=-1/0===1/a?1:0):(b=0>a,a=Math.abs(a),a>=Math.pow(2,-1022)?(d=Math.min(Math.floor(Math.log(a)/Math.LN2),1023),c=d+1023,d=Math.round(a*Math.pow(2,52-d)-Math.pow(2,52))):(c=0,d=Math.round(a/Math.pow(2,-1074))))
e=[]
for(a=52;a;a-=1)e.push(d%2?1:0),d=Math.floor(d/2)
for(a=11;a;a-=1)e.push(c%2?1:0),c=Math.floor(c/2)
e.push(b?1:0)
e.reverse()
b=e.join("")
c=""
for(a=0;64>a;a+=8)d=parseInt(b.substr(a,8),2).toString(16),1===d.length&&(d="0"+d),c+=d
return c.toLowerCase()}function Tb(a){return Zb.test(a)&&(a=Number(a),a>=-2147483648&&2147483647>=a)?a:l}function $b(a){try{a()}catch(b){setTimeout(function(){g(b)})}}function ac(a,b){this.D=a
z(this.D!==l,"LeafNode shouldn't be created with null value.")
this.Za="undefined"!=typeof b?b:l}function cc(a,b){return Rb(a.ha,b.ha)||Sb(a.name,b.name)}function dc(a,b){return Sb(a.name,b.name)}function ec(a,b){return Sb(a,b)}function R(a,b){this.o=a||new Ra(ec)
this.Za="undefined"!=typeof b?b:l}function fc(a,b,c){R.call(this,a,c)
b===l&&(b=new Ra(cc),a.Aa(function(a,c){b=b.na({name:a,ha:c.j()},c)}))
this.ta=b}function S(a,b){if(a===l)return Q
var c=l
"object"==typeof a&&".priority"in a?c=a[".priority"]:"undefined"!=typeof b&&(c=b)
z(c===l||"string"==typeof c||"number"==typeof c||"object"==typeof c&&".sv"in c)
"object"==typeof a&&".value"in a&&a[".value"]!==l&&(a=a[".value"])
if("object"!=typeof a||".sv"in a)return new ac(a,c)
if(a instanceof Array){var d=Q
Xb(a,function(b,c){if(D(a,c)&&"."!==c.substring(0,1)){var e=S(b);(e.N()||!e.f())&&(d=d.G(c,e))}})
return d.Ea(c)}var e=[],f={},h=o
Wb(a,function(b,c){if("string"!=typeof c||"."!==c.substring(0,1)){var d=S(a[c])
d.f()||(h=h||d.j()!==l,e.push({name:c,ha:d.j()}),f[c]=d)}})
var i=hc(e,f,o)
if(h){var m=hc(e,f,k)
return new fc(i,m,c)}return new R(i,c)}function jc(a){this.count=parseInt(Math.log(a+1)/ic)
this.Xc=this.count-1
this.td=a+1&parseInt(Array(this.count+1).join("1"),2)}function hc(a,b,c){function d(d,f){var h=n-d,p=n
n-=d
var q=a[h].name,h=new Xa(c?a[h]:q,b[q],f,l,e(h+1,p))
i?i.left=h:m=h
i=h}function e(d,f){var h=f-d
if(0==h)return l
if(1==h){var h=a[d].name,i=c?a[d]:h
return new Xa(i,b[h],o,l,l)}var i=parseInt(h/2)+d,m=e(d,i),n=e(i+1,f),h=a[i].name,i=c?a[i]:h
return new Xa(i,b[h],o,m,n)}var f=c?cc:dc
a.sort(f)
var h,f=new jc(a.length),i=l,m=l,n=a.length
for(h=0;h<f.count;++h){var p=!(f.td&1<<f.Xc)
f.Xc--
var q=Math.pow(2,f.count-(h+1))
p?d(q,o):(d(q,o),d(q,k))}h=m
f=c?cc:ec
return h!==l?new Ra(f,h):new Ra(f)}function bc(a){return"number"==typeof a?"number:"+Yb(a):"string:"+a}function T(a,b){this.z=a
this.bc=b}function kc(a){z("array"==ea(a)&&0<a.length)
this.sd=a
this.sb={}}function mc(a,b){var d,c=a.sd
a:{d=function(a){return a===b}
for(var e=c.length,f=v(c)?c.split(""):c,h=0;e>h;h++)if(h in f&&d.call(j,f[h])){d=h
break a}d=-1}z(0>d?l:v(c)?c.charAt(d):c[d],"Unknown event: "+b)}function nc(){kc.call(this,["visible"])
var a,b
"undefined"!=typeof document&&"undefined"!=typeof document.addEventListener&&("undefined"!=typeof document.hidden?(b="visibilitychange",a="hidden"):"undefined"!=typeof document.mozHidden?(b="mozvisibilitychange",a="mozHidden"):"undefined"!=typeof document.msHidden?(b="msvisibilitychange",a="msHidden"):"undefined"!=typeof document.webkitHidden&&(b="webkitvisibilitychange",a="webkitHidden"))
this.hb=k
if(b){var c=this
document.addEventListener(b,function(){var b=!document[a]
if(b!==c.hb){c.hb=b
c.Uc("visible",b)}},o)}}function oc(a){this.Gc=a
this.Zb=[]
this.Ra=0
this.qc=-1
this.Ja=l}function Xb(a,b){for(var c in a)b.call(j,a[c],c,a)}function pc(a){var c,b={}
for(c in a)b[c]=a[c]
return b}function qc(){this.jb={}}function rc(a,b,c){u(c)||(c=1)
D(a.jb,b)||(a.jb[b]=0)
a.jb[b]+=c}function sc(a){this.ud=a
this.Qb=l}function tc(a,b){this.Pc={}
this.hc=new sc(a)
this.u=b
setTimeout(w(this.gd,this),10+6e4*Math.random())}function wc(a){a=a.toString()
uc[a]||(uc[a]=new qc)
return uc[a]}function yc(a,b,c){this.rc=a
this.e=Ob(this.rc)
this.frames=this.qb=l
this.Rc=0
this.$=wc(b)
this.Qa=(b.ec?"wss://":"ws://")+b.ea+"/.ws?v=5"
b.host!==b.ea&&(this.Qa=this.Qa+"&ns="+b.ub)
c&&(this.Qa=this.Qa+"&s="+c)}function Bc(a,b){a.frames.push(b)
if(a.frames.length==a.Rc){var c=a.frames.join("")
a.frames=l
c="undefined"!=typeof JSON&&u(JSON.parse)?JSON.parse(c):la(c)
a.Fd(c)}}function Ac(a){clearInterval(a.qb)
a.qb=setInterval(function(){a.Y.send("0")
Ac(a)},45e3)}function Cc(){this.set={}}function Dc(a,b){for(var c in a.set)D(a.set,c)&&b(c,a.set[c])}function Gc(a,b,c){this.rc=a
this.e=Ob(a)
this.Ud=b
this.$=wc(b)
this.gc=c
this.kb=o
this.Mb=function(a){b.host!==b.ea&&(a.ns=b.ub)
var f,c=[]
for(f in a)a.hasOwnProperty(f)&&c.push(f+"="+a[f])
return(b.ec?"https://":"http://")+b.ea+"/.lp?"+c.join("&")}}function Jc(a,b,c,d){this.Mb=d
this.ga=c
this.Ic=new Cc
this.Db=[]
this.sc=Math.floor(1e8*Math.random())
this.fc=k
this.jc=Hb()
window[Ec+this.jc]=a
window[Fc+this.jc]=b
a=document.createElement("iframe")
a.style.display="none"
if(document.body){document.body.appendChild(a)
try{a.contentWindow.document||N("No IE domain setting required")}catch(e){a.src="javascript:void((function(){document.open();document.domain='"+document.domain+"';document.close();})())"}}else g("Document body has not initialized. Wait to initialize Firebase until after the document is ready.")
a.contentDocument?a.ya=a.contentDocument:a.contentWindow?a.ya=a.contentWindow.document:a.document&&(a.ya=a.document)
this.X=a
a=""
this.X.src&&"javascript:"===this.X.src.substr(0,11)&&(a='<script>document.domain="'+document.domain+'";</script>')
a="<html><body>"+a+"</body></html>"
try{this.X.ya.open(),this.X.ya.write(a),this.X.ya.close()}catch(f){N("frame writing exception"),f.stack&&N(f.stack),N(f)}}function Lc(a){if(a.mc&&a.fc&&a.Ic.count()<(0<a.Db.length?2:1)){a.sc++
var b={}
b.id=a.Dd
b.pw=a.Ed
b.ser=a.sc
for(var b=a.Mb(b),c="",d=0;0<a.Db.length&&1870>=a.Db[0].Yc.length+30+c.length;){var e=a.Db.shift(),c=c+"&seg"+d+"="+e.Nd+"&ts"+d+"="+e.Sd+"&d"+d+"="+e.Yc
d++}var b=b+c,f=a.sc
a.Ic.add(f)
var h=function(){a.Ic.remove(f)
Lc(a)},i=setTimeout(h,25e3)
Kc(a,b,function(){clearTimeout(i)
h()})
return k}return o}function Kc(a,b,c){setTimeout(function(){try{if(a.fc){var d=a.X.ya.createElement("script")
d.type="text/javascript"
d.async=k
d.src=b
d.onload=d.onreadystatechange=function(){var a=d.readyState
a&&"loaded"!==a&&"complete"!==a||(d.onload=d.onreadystatechange=l,d.parentNode&&d.parentNode.removeChild(d),c())}
d.onerror=function(){N("Long-poll script failed to load: "+b)
a.fc=o
a.close()}
a.X.ya.body.appendChild(d)}}catch(e){}},1)}function Mc(){var a=[]
Wb(Nc,function(b,c){c&&c.isAvailable()&&a.push(c)})
this.ic=a}function Oc(a,b,c,d,e,f){this.id=a
this.e=Ob("c:"+this.id+":")
this.Gc=c
this.yb=d
this.R=e
this.Fc=f
this.K=b
this.Yb=[]
this.Vc=0
this.Tc=new Mc
this.va=0
this.e("Connection created")
Pc(this)}function Pc(a){var b,c=a.Tc
0<c.ic.length?b=c.ic[0]:g(Error("No transports available"))
a.L=new b("c:"+a.id+":"+a.Vc++,a.K)
var d=Qc(a,a.L),e=Rc(a,a.L)
a.Kb=a.L
a.Ib=a.L
a.A=l
setTimeout(function(){a.L&&a.L.open(d,e)},0)}function Rc(a,b){return function(c){b===a.L?(a.L=l,c||0!==a.va?1===a.va&&a.e("Realtime connection lost."):(a.e("Realtime connection failed."),"s-"===a.K.ea.substr(0,2)&&(ob.removeItem(a.K.ub),a.K.ea=a.K.host)),a.close()):b===a.A?(c=a.A,a.A=l,(a.Kb===c||a.Ib===c)&&a.close()):a.e("closing an old connection")}}function Qc(a,b){return function(c){if(2!=a.va)if(b===a.Ib){var d=Ub("t",c),c=Ub("d",c)
if("c"==d){if(d=Ub("t",c),"d"in c)if(c=c.d,"h"===d){var d=c.ts,e=c.v,f=c.h
a.gc=c.s
rb(a.K,f)
0==a.va&&(a.L.start(),c=a.L,a.e("Realtime connection established."),a.L=c,a.va=1,a.yb&&(a.yb(d),a.yb=l),"5"!==e&&P("Protocol version mismatch detected"),c=1<a.Tc.ic.length?a.Tc.ic[1]:l)&&(a.A=new c("c:"+a.id+":"+a.Vc++,a.K,a.gc),a.A.open(Qc(a,a.A),Rc(a,a.A)))}else if("n"===d){a.e("recvd end transmission on primary")
a.Ib=a.A
for(c=0;c<a.Yb.length;++c)a.Vb(a.Yb[c])
a.Yb=[]
Sc(a)}else"s"===d?(a.e("Connection shutdown command received. Shutting down..."),a.Fc&&(a.Fc(c),a.Fc=l),a.R=l,a.close()):"r"===d?(a.e("Reset packet received.  New host: "+c),rb(a.K,c),1===a.va?a.close():(Tc(a),Pc(a))):"e"===d?Pb("Server Error: "+c):Pb("Unknown control packet command: "+d)}else"d"==d&&a.Vb(c)}else b===a.A?(d=Ub("t",c),c=Ub("d",c),"c"==d?"t"in c&&(c=c.t,"a"===c?(a.A.start(),a.e("sending client ack on secondary"),a.A.send({t:"c",d:{t:"a",d:{}}}),a.e("Ending transmission on primary"),a.L.send({t:"c",d:{t:"n",d:{}}}),a.Kb=a.A,Sc(a)):"r"===c&&(a.e("Got a reset on secondary, closing it"),a.A.close(),(a.Kb===a.A||a.Ib===a.A)&&a.close())):"d"==d?a.Yb.push(c):g(Error("Unknown protocol layer: "+d))):a.e("message on old connection")}}function Sc(a){a.Kb===a.A&&a.Ib===a.A&&(a.e("cleaning up and promoting a connection: "+a.A.rc),a.L=a.A,a.A=l)}function Tc(a){a.e("Shutting down all connections")
a.L&&(a.L.close(),a.L=l)
a.A&&(a.A.close(),a.A=l)}function Vc(){kc.call(this,["online"])
this.zb=k
if("undefined"!=typeof window&&"undefined"!=typeof window.addEventListener){var a=this
window.addEventListener("online",function(){a.zb||a.Uc("online",k)
a.zb=k},o)
window.addEventListener("offline",function(){a.zb&&a.Uc("online",o)
a.zb=o},o)}}function Wc(a,b,c,d,e,f){this.id=Xc++
this.e=Ob("p:"+this.id+":")
this.Na=k
this.fa={}
this.U=[]
this.Ab=0
this.xb=[]
this.P=o
this.pa=1e3
this.Wb=b||ca
this.Ub=c||ca
this.wb=d||ca
this.Hc=e||ca
this.yc=f||ca
this.K=a
this.Lc=l
this.Hb={}
this.Md=0
this.rb=this.Cc=l
Yc(this,0)
nc.mb().Ya("visible",this.Hd,this);-1===a.host.indexOf("fblocal")&&Vc.mb().Ya("online",this.Gd,this)}function $c(a,b,c,d,e){a.e("Listen on "+b+" for "+c)
var f={p:b},d=jb(d,function(a){return Ia(a)})
"{}"!==c&&(f.q=d)
f.h=a.yc(b)
a.Da("l",f,function(d){a.e("listen response",d)
d=d.s
"ok"!==d&&ad(a,b,c)
e&&e(d)})}function bd(a){var b=a.Ga
a.P&&b&&a.Da("auth",{cred:b.vd},function(c){var d=c.s,c=c.d||"error"
"ok"!==d&&a.Ga===b&&delete a.Ga
a.wb("ok"===d)
b.Zc?"ok"!==d&&b.Ob&&b.Ob(d,c):(b.Zc=k,b.W&&b.W(d,c))})}function cd(a,b,c,d){b=b.toString()
ad(a,b,c)&&a.P&&(a.e("Unlisten on "+b+" for "+c),b={p:b},d=jb(d,function(a){return Ia(a)}),"{}"!==c&&(b.q=d),a.Da("u",b))}function dd(a,b,c,d){a.P?ed(a,"o",b,c,d):a.xb.push({Jc:b,action:"o",data:c,C:d})}function ed(a,b,c,d,e){c={p:c,d:d}
a.e("onDisconnect "+b,c)
a.Da(b,c,function(a){e&&setTimeout(function(){e(a.s)},0)})}function fd(a,b,c,d,e,f){c={p:c,d:d}
u(f)&&(c.h=f)
a.U.push({action:b,hd:c,C:e})
a.Ab++
b=a.U.length-1
a.P&&gd(a,b)}function gd(a,b){var c=a.U[b].action,d=a.U[b].hd,e=a.U[b].C
a.U[b].Jd=a.P
a.Da(c,d,function(d){a.e(c+" response",d)
delete a.U[b]
a.Ab--
0===a.Ab&&(a.U=[])
e&&e(d.s)})}function Yc(a,b){z(!a.ia,"Scheduling a connect when we're already connected/ing?")
a.Ta&&clearTimeout(a.Ta)
a.Ta=setTimeout(function(){a.Ta=l
if(a.Na){a.e("Making a connection attempt")
a.Cc=(new Date).getTime()
a.rb=l
var b=w(a.Vb,a),d=w(a.yb,a),e=w(a.dd,a),f=a.id+":"+Zc++
a.ia=new Oc(f,a.K,b,d,e,function(b){P(b+" ("+a.K.toString()+")")
a.Na=o})}},b)}function ad(a,b,c){b=new K(b).toString()
c||(c="{}")
var d=a.fa[b][c]
delete a.fa[b][c]
return d}function hd(){this.o=this.D=l}function id(a,b,c){if(b.f())a.D=c,a.o=l
else if(a.D!==l)a.D=a.D.xa(b,c)
else{a.o==l&&(a.o=new Cc)
var d=F(b)
a.o.contains(d)||a.o.add(d,new hd)
a=a.o.get(d)
b=Ka(b)
id(a,b,c)}}function jd(a,b){if(b.f())return a.D=l,a.o=l,k
if(a.D!==l){if(a.D.N())return o
var c=a.D
a.D=l
c.w(function(b,c){id(a,new K(b),c)})
return jd(a,b)}return a.o!==l?(c=F(b),b=Ka(b),a.o.contains(c)&&jd(a.o.get(c),b)&&a.o.remove(c),a.o.f()?(a.o=l,k):o):k}function kd(a,b,c){a.D!==l?c(b,a.D):a.w(function(a,e){var f=new K(b.toString()+"/"+a)
kd(e,f,c)})}function ld(){this.qa=Q}function U(a,b){return a.qa.Q(b)}function V(a,b,c){a.qa=a.qa.xa(b,c)}function md(){this.ra=new ld
this.I=new ld
this.la=new ld
this.Cb=new Na}function nd(a,b){for(var c=U(a.ra,b),d=U(a.I,b),e=L(a.Cb,b),f=o,h=e;h!==l;){if(h.k()!==l){f=k
break}h=h.parent()}if(f)return o
c=od(c,d,e)
return c!==d?(V(a.I,b,c),k):o}function od(a,b,c){if(c.f())return a
if(c.k()!==l)return b
a=a||Q
c.w(function(d){var d=d.name(),e=a.M(d),f=b.M(d),h=L(c,d),e=od(e,f,h)
a=a.G(d,e)})
return a}function pd(a,b){ib(b,function(b){var d=b.Od,b=L(a.Cb,b.path),e=b.k()
z(e!==l,"pendingPut should not be null.")
e===d&&M(b,l)})}function qd(){this.Ua=[]}function rd(a,b){if(0!==b.length)for(var c=0;c<b.length;c++)a.Ua.push(b[c])}function sd(a){var b=a.W,c=a.md,d=a.Eb
$b(function(){b(c,d)})}function W(a,b,c,d){this.type=a
this.sa=b
this.aa=c
this.Eb=d}function td(a){this.J=a
this.ma=[]
this.uc=new qd}function ud(a,b,c,d,e){a.ma.push({type:b,W:c,cancel:d,T:e})
var d=[],f=vd(a.i)
a.pb&&f.push(new W("value",a.i))
for(var h=0;h<f.length;h++)if(f[h].type===b){var i=new J(a.J.n,a.J.path)
f[h].aa&&(i=i.F(f[h].aa))
d.push({W:e?w(c,e):c,md:new T(f[h].sa,i),Eb:f[h].Eb})}rd(a.uc,d)}function wd(a,b){for(var c=[],d=0;d<b.length;d++){var e=b[d],f=e.type,h=new J(a.J.n,a.J.path)
b[d].aa&&(h=h.F(b[d].aa))
h=new T(b[d].sa,h)
"value"!==e.type||h.nb()?"value"!==e.type&&(f+=" "+h.name()):f+="("+h.V()+")"
N(a.J.n.u.id+": event:"+a.J.path+":"+a.J.La()+":"+f)
for(f=0;f<a.ma.length;f++){var i=a.ma[f]
b[d].type===i.type&&c.push({W:i.T?w(i.W,i.T):i.W,md:h,Eb:e.Eb})}}rd(a.uc,c)}function vd(a){var b=[]
if(!a.N()){var c=l
a.w(function(a,e){b.push(new W("child_added",e,a,c))
c=a})}return b}function xd(a){a.pb||(a.pb=k,wd(a,[new W("value",a.i)]))}function zd(a,b){td.call(this,a)
this.i=b}function Ad(a,b){this.Pb=a
this.Dc=b}function Bd(a,b,c,d,e){var f=a.Q(c),h=b.Q(c),d=new Ad(d,e),e=Cd(d,c,f,h),h=!f.f()&&!h.f()&&f.j()!==h.j()
if(e||h){f=c
for(c=e;f.parent()!==l;){var i=a.Q(f),e=b.Q(f),m=f.parent()
if(!d.Pb||L(d.Pb,m).k()){var n=b.Q(m),p=[],f=f.Z<f.m.length?f.m[f.m.length-1]:l
i.f()?(i=n.da(f,e),p.push(new W("child_added",e,f,i))):e.f()?p.push(new W("child_removed",i,f)):(i=n.da(f,e),h&&p.push(new W("child_moved",e,f,i)),c&&p.push(new W("child_changed",e,f,i)))
d.Dc(m,n,p)}h&&(h=o,c=k)
f=m}}}function Cd(a,b,c,d){var e,f=[]
c===d?e=o:c.N()&&d.N()?e=c.k()!==d.k():c.N()?(Dd(a,b,Q,d,f),e=k):d.N()?(Dd(a,b,c,Q,f),e=k):e=Dd(a,b,c,d,f)
e?a.Dc(b,d,f):c.j()!==d.j()&&a.Dc(b,d,l)
return e}function Dd(a,b,c,d,e){var x,O,I,G,f=o,h=!a.Pb||!L(a.Pb,b).f(),i=[],m=[],n=[],p=[],q={},t={}
x=c.Va()
I=Wa(x)
O=d.Va()
for(G=Wa(O);I!==l||G!==l;){c=I===l?1:G===l?-1:I.key===G.key?0:cc({name:I.key,ha:I.value.j()},{name:G.key,ha:G.value.j()})
if(0>c)f=ua(q,I.key),u(f)?(n.push({wc:I,Qc:i[f]}),i[f]=l):(t[I.key]=m.length,m.push(I)),f=k,I=Wa(x)
else{if(c>0)f=ua(t,G.key),u(f)?(n.push({wc:m[f],Qc:G}),m[f]=l):(q[G.key]=i.length,i.push(G)),f=k
else{c=b.F(G.key);(c=Cd(a,c,I.value,G.value))&&(p.push(G),f=k)
I.value.j()!==G.value.j()&&(n.push({wc:I,Qc:G}),f=k)
I=Wa(x)}G=Wa(O)}if(!h&&f)return k}for(h=0;h<m.length;h++)(q=m[h])&&(c=b.F(q.key),Cd(a,c,q.value,Q),e.push(new W("child_removed",q.value,q.key)))
for(h=0;h<i.length;h++)(q=i[h])&&(c=b.F(q.key),m=d.da(q.key,q.value),Cd(a,c,Q,q.value),e.push(new W("child_added",q.value,q.key,m)))
for(h=0;h<n.length;h++)q=n[h].wc,i=n[h].Qc,c=b.F(i.key),m=d.da(i.key,i.value),e.push(new W("child_moved",i.value,i.key,m)),(c=Cd(a,c,q.value,i.value))&&p.push(i)
for(h=0;h<p.length;h++)a=p[h],m=d.da(a.key,a.value),e.push(new W("child_changed",a.value,a.key,m))
return f}function Ed(){this.S=this.wa=l
this.set={}}function Fd(a){return a.contains("default")}function Gd(a){return a.wa!=l&&Fd(a)}function Hd(a,b){td.call(this,a)
this.i=Q
this.ac(b,vd(b))}function Id(a,b,c,d){if(a.N())return l
var e=l;(d?a.vc:a.w).call(a,function(a,d){return Jd(b,a,d)&&(e=a,c--,0===c)?k:void 0})
return e}function Jd(a,b,c){for(var d=0;d<a.length;d++)if(!a[d](b,c.j()))return o
return k}function Kd(a,b){this.u=a
this.g=b
this.Tb=b.qa
this.ka=new Na}function Nd(a,b,c,d,e){var h,f=a.get(b)
if(h=f){h=o
for(var i=f.ma.length-1;i>=0;i--){var m=f.ma[i]
if(!(c&&m.type!==c||d&&m.W!==d||e&&m.T!==e)&&(f.ma.splice(i,1),h=k,c&&d))break}h=h&&!(0<f.ma.length)}(c=h)&&a.remove(b)
return c}function Od(a,b,c,d,e,f){var h=b.path(),h=L(a.ka,h),c=c?c.La():l,i=[]
c&&"default"!==c?Nd(b,c,d,e,f)&&i.push(c):ib(b.keys(),function(a){Nd(b,a,d,e,f)&&i.push(a)})
b.f()&&M(h,l)
c=Ld(h)
if(0<i.length&&!c){for(var m=h,n=h.parent(),c=o;!c&&n;){var p=n.k()
if(p){z(!Gd(p))
var q=m.name(),t=o
Dc(p,function(a,b){t=b.zc(q)||t})
t&&(c=k)}m=n
n=n.parent()}m=l
if(!Gd(b)){n=b.wa
b.wa=l
var x=[],O=function(b){var c=b.k()
if(c&&Fd(c))x.push(c.path()),c.wa==l&&c.setActive(Md(a,c))
else{if(c){c.wa!=l||c.setActive(Md(a,c))
var d={}
Dc(c,function(a,b){b.i.w(function(a){D(d,a)||(d[a]=k,a=c.path().F(a),x.push(a))})})}b.w(O)}}
O(h)
m=x
n&&n()}return c?l:m}return l}function Pd(a,b,c){Pa(L(a.ka,b),function(a){(a=a.k())&&Dc(a,function(a,b){xd(b)})},c,k)}function Qd(a,b,c){function d(a){do{if(h[a.toString()])return k
a=a.parent()}while(a!==l)
return o}var e=a.Tb,f=a.g.qa
a.Tb=f
for(var h={},i=0;i<c.length;i++)h[c[i].toString()]=k
Bd(e,f,b,a.ka,function(c,e,f){if(b.contains(c)){var h=d(c)
h&&Pd(a,c,o)
a.$b(c,e,f)
h&&Pd(a,c,k)}else a.$b(c,e,f)})
d(b)&&Pd(a,b,k)
Rd(a,b)}function Rd(a,b){var c=L(a.ka,b)
Pa(c,function(a){(a=a.k())&&Dc(a,function(a,b){b.Fb()})},k,k)
Qa(c,function(a){(a=a.k())&&Dc(a,function(a,b){b.Fb()})},o)}function Ld(a){return Qa(a,function(a){return a.k()&&Gd(a.k())})}function Md(a,b){if(a.u){var h,c=a.u,d=b.path(),e=b.toString(),f=b.$a(),i=b.keys(),m=Fd(b),n=a.u,p=function(c){if("ok"!==c){var d="Unknown Error"
"too_big"===c?d="The data requested exceeds the maximum size that can be accessed with a single request.":"permission_denied"==c?d="Client doesn't have permission to access the desired data.":"unavailable"==c&&(d="The service is unavailable")
var e=Error(c+": "+d)
e.code=c.toUpperCase()
P("on() or once() for "+b.path().toString()+" failed: "+e.toString())
b&&(Dc(b,function(a,b){for(var c=0;c<b.ma.length;c++){var d=b.ma[c]
d.cancel&&(d.T?w(d.cancel,d.T):d.cancel)(e)}}),Od(a,b))}else h||(m?Pd(a,b.path(),k):ib(i,function(a){(a=b.get(a))&&xd(a)}),Rd(a,b.path()))},q=b.toString(),t=b.path().toString()
n.fa[t]=n.fa[t]||{}
z(!n.fa[t][q],"listen() called twice for same path/queryId.")
n.fa[t][q]={$a:b.$a(),C:p}
n.P&&$c(n,t,q,b.$a(),p)
return function(){h=k
cd(c,d,e,f)}}return ca}function Sd(a,b,c,d,e){var f=b.path(),b=a.lb(f,b,d,e),h=Q,i=[]
Xb(b,function(b,n){var p=new K(n)
3===b||1===b?h=h.G(n,d.Q(p)):(2===b&&i.push({path:f.F(n),oa:Q}),i=i.concat(Td(a,d.Q(p),L(c,p),e)))})
return[{path:f,oa:h}].concat(i)}function Ud(a,b,c,d){var e
a:{var f=L(a.ka,b)
e=f.parent()
for(var h=[];e!==l;){var i=e.k()
if(i!==l){if(Fd(i)){e=[{path:b,oa:c}]
break a}i=a.lb(b,i,c,d)
f=ua(i,f.name())
if(3===f||1===f){e=[{path:b,oa:c}]
break a}2===f&&h.push({path:b,oa:Q})}f=e
e=e.parent()}e=h}if(1==e.length&&(!e[0].oa.f()||c.f()))return e
h=L(a.ka,b)
f=h.k()
f!==l?Fd(f)?e.push({path:b,oa:c}):e=e.concat(Sd(a,f,h,c,d)):e=e.concat(Td(a,c,h,d))
return e}function Td(a,b,c,d){var e=c.k()
if(e!==l)return Fd(e)?[{path:c.path(),oa:b}]:Sd(a,e,c,b,d)
var f=[]
c.w(function(c){var e=b.N()?Q:b.M(c.name()),c=Td(a,e,c,d)
f=f.concat(c)})
return f}function Vd(a,b){if(!a||"object"!=typeof a)return a
z(".sv"in a,"Unexpected leaf node or priority contents")
return b[a[".sv"]]}function Wd(a,b){var d,c=Vd(a.j(),b)
if(a.N()){var e=Vd(a.k(),b)
return e!==a.k()||c!==a.j()?new ac(e,c):a}d=a
c!==a.j()&&(d=d.Ea(c))
a.w(function(a,c){var e=Wd(c,b)
e!==c&&(d=d.G(a,e))})
return d}function Xd(a){this.K=a
this.$=wc(a)
this.u=new Wc(this.K,w(this.Wb,this),w(this.Ub,this),w(this.wb,this),w(this.Hc,this),w(this.yc,this))
var b=w(function(){return new tc(this.$,this.u)},this),a=a.toString()
vc[a]||(vc[a]=b())
this.nd=vc[a]
this.fb=new Na
this.gb=new ld
this.g=new md
this.H=new Kd(this.u,this.g.la)
this.Ac=new ld
this.Bc=new Kd(l,this.Ac)
Yd(this,"connected",o)
Yd(this,"authenticated",o)
this.R=new hd
this.tc=0}function Zd(a){a=U(a.Ac,new K(".info/serverTimeOffset")).V()||0
return(new Date).getTime()+a}function $d(a){a=a={timestamp:Zd(a)}
a.timestamp=a.timestamp||(new Date).getTime()
return a}function Yd(a,b,c){b=new K("/.info/"+b)
V(a.Ac,b,S(c))
Qd(a.Bc,b,[b])}function ce(a,b,c,d){var e=S(c)
dd(a.u,b.toString(),e.V(k),function(c){"ok"===c&&id(a.R,b,e)
X(d,c)})}function de(a){rc(a.$,"deprecated_on_disconnect")
a.nd.Pc.deprecated_on_disconnect=k}function X(a,b,c){a&&$b(function(){if("ok"==b)a(l,c)
else{var d=(b||"error").toUpperCase(),e=d
c&&(e+=": "+c)
e=Error(e)
e.code=d
a(e)}})}function ee(a,b){var c=b||a.fb
b||fe(a,c)
if(c.k()!==l){var d=ge(a,c)
z(0<d.length)
if(2!==d[0].status&&4!==d[0].status){for(var e=c.path(),f=0;f<d.length;f++)z(1===d[f].status,"tryToSendTransactionQueue_: items in queue should all be run."),d[f].status=2,d[f].kd++
c=U(a.g.I,e).hash()
V(a.g.I,e,U(a.g.la,e))
for(var h=U(a.gb,e).V(k),i=Hb(),m={},n=0;n<d.length;n++)d[n].nc&&(m[d[n].path.toString()]=d[n].path)
var q,p=[]
for(q in m)p.push(m[q])
for(f=0;f<p.length;f++)M(L(a.g.Cb,p[f]),i)
a.u.put(e.toString(),h,function(b){a.e("transaction put response",{path:e.toString(),status:b})
for(f=0;f<p.length;f++){var c=L(a.g.Cb,p[f]),h=c.k()
z(h!==l,"sendTransactionQueue_: pendingPut should not be null.")
h===i&&(M(c,l),V(a.g.I,p[f],U(a.g.ra,p[f])))}if("ok"===b){b=[]
for(f=0;f<d.length;f++)d[f].status=3,d[f].C&&(c=he(a,d[f].path),b.push(w(d[f].C,l,l,k,c))),d[f].kc()
fe(a,L(a.fb,e))
ee(a)
for(f=0;f<b.length;f++)$b(b[f])}else{if("datastale"===b)for(f=0;f<d.length;f++)d[f].status=4===d[f].status?5:1
else{P("transaction at "+e+" failed: "+b)
for(f=0;f<d.length;f++)d[f].status=5,d[f].lc=b}b=ae(a,e)
Qd(a.H,b,[e])}},c)}}else c.nb()&&c.w(function(b){ee(a,b)})}function ae(a,b){var c=ie(a,b),d=c.path(),e=ge(a,c)
V(a.g.la,d,U(a.g.I,d))
V(a.gb,d,U(a.g.I,d))
if(0!==e.length){for(var f=c=U(a.g.la,d),h=[],i=0;i<e.length;i++){var p,m=La(d,e[i].path),n=o
z(m!==l,"rerunTransactionsUnderNode_: relativePath should not be null.")
if(5===e[i].status)n=k,p=e[i].lc
else if(1===e[i].status)if(25<=e[i].kd)n=k,p="maxretry"
else{var q=e[i].update(c.Q(m).V())
u(q)?(za("transaction failed: Data returned ",q),q=S(q),c=c.xa(m,q),e[i].nc&&(f=f.xa(m,q))):(n=k,p="nodata")}n&&(e[i].status=3,setTimeout(e[i].kc,0),e[i].C&&(n=new J(a,e[i].path),m=new T(c.Q(m),n),"nodata"===p?h.push(w(e[i].C,l,l,o,m)):h.push(w(e[i].C,l,Error(p),o,m))))}p=U(a.g.I,d).j()
c=c.Ea(p)
f=f.Ea(p)
V(a.gb,d,c)
V(a.g.la,d,f)
fe(a,a.fb)
for(i=0;i<h.length;i++)$b(h[i])
ee(a)}return d}function ie(a,b){for(var c,d=a.fb;(c=F(b))!==l&&d.k()===l;)d=L(d,c),b=Ka(b)
return d}function ge(a,b){var c=[]
je(a,b,c)
c.sort(function(a,b){return a.ed-b.ed})
return c}function je(a,b,c){var d=b.k()
if(d!==l)for(var e=0;e<d.length;e++)c.push(d[e])
b.w(function(b){je(a,b,c)})}function fe(a,b){var c=b.k()
if(c){for(var d=0,e=0;e<c.length;e++)3!==c[e].status&&(c[d]=c[e],d++)
c.length=d
M(b,0<c.length?c:l)}b.w(function(b){fe(a,b)})}function be(a,b){var c=ie(a,b).path(),d=L(a.fb,b)
Qa(d,function(a){ke(a)})
ke(d)
Pa(d,function(a){ke(a)})
return c}function ke(a){var b=a.k()
if(b!==l){for(var c=[],d=-1,e=0;e<b.length;e++)4!==b[e].status&&(2===b[e].status?(z(d===e-1,"All SENT items should be at beginning of queue."),d=e,b[e].status=4,b[e].lc="set"):(z(1===b[e].status),b[e].kc(),b[e].C&&c.push(w(b[e].C,l,Error("set"),o,l))));-1===d?M(a,l):b.length=d+1
for(e=0;e<c.length;e++)$b(c[e])}}function he(a,b){var c=new J(a,b)
return new T(U(a.gb,b),c)}function Y(){this.ab={}}function $(a,b,c){this.Gb=a
this.S=b
this.Ca=c}function J(){var a,b,c
if(arguments[0]instanceof Xd)c=arguments[0],a=arguments[1]
else{A("new Firebase",1,2,arguments.length)
var d=arguments[0]
b=a=""
var e=k,f=""
if(v(d)){var h=d.indexOf("//")
if(h>=0)var i=d.substring(0,h-1),d=d.substring(h+2)
h=d.indexOf("/");-1===h&&(h=d.length)
a=d.substring(0,h)
var d=d.substring(h+1),m=a.split(".")
if(3==m.length){h=m[2].indexOf(":")
e=h>=0?"https"===i:k
if("firebase"===m[1])Qb(a+" is no longer supported. Please use <YOUR FIREBASE>.firebaseio.com instead")
else{b=m[0]
f=""
d=("/"+d).split("/")
for(i=0;i<d.length;i++)if(0<d[i].length){h=d[i]
try{h=decodeURIComponent(h.replace(/\+/g," "))}catch(n){}f+="/"+h}}b=b.toLowerCase()}else b=l}e||"undefined"!=typeof window&&window.location&&window.location.protocol&&-1!==window.location.protocol.indexOf("https:")&&P("Insecure Firebase access from a secure page. Please use https in calls to new Firebase().")
a=new qb(a,e,b)
b=new K(f)
e=b.toString();(d=!v(a.host))||(d=0===a.host.length)||(d=!xa(a.ub))||(d=0!==e.length)&&(e&&(e=e.replace(/^\/*\.info(\/|$)/,"/")),d=!(v(e)&&0!==e.length&&!wa.test(e)))
d&&g(Error(B("new Firebase",1,o)+'must be a valid firebase URL and the path can\'t contain ".", "#", "$", "[", or "]".'))
arguments[1]?arguments[1]instanceof Y?c=arguments[1]:g(Error("Expected a valid Firebase.Context for second argument to new Firebase()")):c=Y.mb()
e=a.toString()
d=ua(c.ab,e)
d||(d=new Xd(a),c.ab[e]=d)
c=d
a=b}H.call(this,c,a)}function Nb(a,b){z(!b||a===k||a===o,"Can't turn on custom loggers persistently.")
a===k?("undefined"!=typeof console&&("function"==typeof console.log?Lb=w(console.log,console):"object"==typeof console.log&&(Lb=function(a){console.log(a)})),b&&ob.setItem("logging_enabled","true")):a?Lb=a:(Lb=l,ob.removeItem("logging_enabled"))}var j=void 0,k=!0,l=null,o=!1,s,ba=this
Math.floor(2147483648*Math.random()).toString(36)
var pa={'"':'\\"',"\\":"\\\\","/":"\\/","\b":"\\b","\f":"\\f","\n":"\\n","\r":"\\r","	":"\\t","":"\\u000b"},qa=/\uffff/.test("￿")?/[\\\"\x00-\x1f\x7f-\uffff]/g:/[\\\"\x00-\x1f\x7f-\xff]/g,sa={},va=/[\[\].#$\/]/,wa=/[\[\].#$]/
H.prototype.Kc=function(){A("Query.ref",0,0,arguments.length)
return new J(this.n,this.path)}
H.prototype.ref=H.prototype.Kc
H.prototype.Ya=function(a,b){A("Query.on",2,4,arguments.length)
Ea("Query.on",a,o)
C("Query.on",2,b,o)
var c=Ha("Query.on",arguments[2],arguments[3])
this.n.Nb(this,a,b,c.cancel,c.T)
return b}
H.prototype.on=H.prototype.Ya
H.prototype.vb=function(a,b,c){A("Query.off",0,3,arguments.length)
Ea("Query.off",a,k)
C("Query.off",2,b,k)
ta("Query.off",3,c)
this.n.cc(this,a,b,c)}
H.prototype.off=H.prototype.vb
H.prototype.Id=function(a,b){function c(h){f&&(f=o,e.vb(a,c),b.call(d.T,h))}A("Query.once",2,4,arguments.length)
Ea("Query.once",a,o)
C("Query.once",2,b,o)
var d=Ha("Query.once",arguments[2],arguments[3]),e=this,f=k
this.Ya(a,c,function(b){e.vb(a,c)
d.cancel&&d.cancel.call(d.T,b)})}
H.prototype.once=H.prototype.Id
H.prototype.Bd=function(a){A("Query.limit",1,1,arguments.length);(!ga(a)||Math.floor(a)!==a||0>=a)&&g("Query.limit: First argument must be a positive integer.")
return new H(this.n,this.path,a,this.ca,this.ua,this.za,this.Sa)}
H.prototype.limit=H.prototype.Bd
H.prototype.Rd=function(a,b){A("Query.startAt",0,2,arguments.length)
Da("Query.startAt",1,a,k)
Fa("Query.startAt",b)
u(a)||(b=a=l)
return new H(this.n,this.path,this.Ba,a,b,this.za,this.Sa)}
H.prototype.startAt=H.prototype.Rd
H.prototype.wd=function(a,b){A("Query.endAt",0,2,arguments.length)
Da("Query.endAt",1,a,k)
Fa("Query.endAt",b)
return new H(this.n,this.path,this.Ba,this.ca,this.ua,a,b)}
H.prototype.endAt=H.prototype.wd
H.prototype.La=function(){var a=Ja(Ia(this))
return"{}"===a?"default":a}
s=K.prototype
s.toString=function(){for(var a="",b=this.Z;b<this.m.length;b++)""!==this.m[b]&&(a+="/"+this.m[b])
return a||"/"}
s.parent=function(){if(this.Z>=this.m.length)return l
for(var a=[],b=this.Z;b<this.m.length-1;b++)a.push(this.m[b])
return new K(a,0)}
s.F=function(a){for(var b=[],c=this.Z;c<this.m.length;c++)b.push(this.m[c])
if(a instanceof K)for(c=a.Z;c<a.m.length;c++)b.push(a.m[c])
else{a=a.split("/")
for(c=0;c<a.length;c++)0<a[c].length&&b.push(a[c])}return new K(b,0)}
s.f=function(){return this.Z>=this.m.length}
s.contains=function(a){var b=0
if(this.m.length>a.m.length)return o
for(;b<this.m.length;){if(this.m[b]!==a.m[b])return o;++b}return k}
s=Na.prototype
s.k=function(){return this.z.value}
s.nb=function(){return 0<this.z.pc}
s.f=function(){return this.k()===l&&!this.nb()}
s.w=function(a){for(var b in this.z.children)a(new Na(b,this,this.z.children[b]))}
s.path=function(){return new K(this.Bb===l?this.Ca:this.Bb.path()+"/"+this.Ca)}
s.name=aa("Ca")
s.parent=aa("Bb")
s=Ra.prototype
s.na=function(a,b){return new Ra(this.Pa,this.ba.na(a,b,this.Pa).copy(l,l,o,l,l))}
s.remove=function(a){return new Ra(this.Pa,this.ba.remove(a,this.Pa).copy(l,l,o,l,l))}
s.get=function(a){for(var b,c=this.ba;!c.f();){b=this.Pa(a,c.key)
if(0===b)return c.value
0>b?c=c.left:b>0&&(c=c.right)}return l}
s.f=function(){return this.ba.f()}
s.count=function(){return this.ba.count()}
s.tb=function(){return this.ba.tb()}
s.Wa=function(){return this.ba.Wa()}
s.Aa=function(a){return this.ba.Aa(a)}
s.Ma=function(a){return this.ba.Ma(a)}
s.Va=function(a){return new Va(this.ba,a)}
s=Xa.prototype
s.copy=function(a,b,c,d,e){return new Xa(a!=l?a:this.key,b!=l?b:this.value,c!=l?c:this.color,d!=l?d:this.left,e!=l?e:this.right)}
s.count=function(){return this.left.count()+1+this.right.count()}
s.f=r(o)
s.Aa=function(a){return this.left.Aa(a)||a(this.key,this.value)||this.right.Aa(a)}
s.Ma=function(a){return this.right.Ma(a)||a(this.key,this.value)||this.left.Ma(a)}
s.tb=function(){return Ya(this).key}
s.Wa=function(){return this.right.f()?this.key:this.right.Wa()}
s.na=function(a,b,c){var d,e
e=this
d=c(a,e.key)
e=0>d?e.copy(l,l,l,e.left.na(a,b,c),l):0===d?e.copy(l,b,l,l,l):e.copy(l,l,l,l,e.right.na(a,b,c))
return Za(e)}
s.remove=function(a,b){var c,d
c=this
if(0>b(a,c.key))!c.left.f()&&!c.left.O()&&!c.left.left.O()&&(c=cb(c)),c=c.copy(l,l,l,c.left.remove(a,b),l)
else{c.left.O()&&(c=db(c))
!c.right.f()&&!c.right.O()&&!c.right.left.O()&&(c=eb(c),c.left.left.O()&&(c=db(c),c=eb(c)))
if(0===b(a,c.key)){if(c.right.f())return Ta
d=Ya(c.right)
c=c.copy(d.key,d.value,l,l,bb(c.right))}c=c.copy(l,l,l,l,c.right.remove(a,b))}return Za(c)}
s.O=aa("color")
s=gb.prototype
s.copy=function(){return this}
s.na=function(a,b){return new Xa(a,b,j,j,j)}
s.remove=function(){return this}
s.count=r(0)
s.f=r(k)
s.Aa=r(o)
s.Ma=r(o)
s.tb=r(l)
s.Wa=r(l)
s.O=r(o)
var Ta=new gb,hb=Array.prototype,ib=hb.forEach?function(a,b,c){hb.forEach.call(a,b,c)}:function(a,b,c){for(var d=a.length,e=v(a)?a.split(""):a,f=0;d>f;f++)f in e&&b.call(c,e[f],f,a)},jb=hb.map?function(a,b,c){return hb.map.call(a,b,c)}:function(a,b,c){for(var d=a.length,e=Array(d),f=v(a)?a.split(""):a,h=0;d>h;h++)h in f&&(e[h]=b.call(c,f[h],h,a))
return e}
ka(lb,kb)
lb.prototype.reset=function(){this.B[0]=1732584193
this.B[1]=4023233417
this.B[2]=2562383102
this.B[3]=271733878
this.B[4]=3285377520
this.Sc=this.ob=0}
lb.prototype.update=function(a,b){u(b)||(b=a.length)
var c=this.oc,d=this.ob,e=0
if(v(a))for(;b>e;)c[d++]=a.charCodeAt(e++),64==d&&(mb(this,c),d=0)
else for(;b>e;)c[d++]=a[e++],64==d&&(mb(this,c),d=0)
this.ob=d
this.Sc+=b}
nb.prototype.setItem=function(a,b){D(this.Oa,a)||(this.length+=1)
this.Oa[a]=b}
nb.prototype.getItem=function(a){return D(this.Oa,a)?this.Oa[a]:l}
nb.prototype.removeItem=function(a){D(this.Oa,a)&&(this.length-=1,delete this.Oa[a])}
var ob=l
try{"undefined"!=typeof sessionStorage&&(sessionStorage.setItem("firebase-sentinel","cache"),sessionStorage.removeItem("firebase-sentinel"),ob=sessionStorage)}catch(pb){}ob=ob||new nb
qb.prototype.toString=function(){return(this.ec?"https://":"http://")+this.host}
var sb,tb,ub,vb
vb=ub=tb=sb=o
var xb
if(xb=wb()){var yb=ba.navigator
sb=0==xb.indexOf("Opera")
tb=!sb&&-1!=xb.indexOf("MSIE")
ub=!sb&&-1!=xb.indexOf("WebKit")
vb=!sb&&!ub&&"Gecko"==yb.product}var zb=tb,Ab=vb,Bb=ub,Cb
if(sb&&ba.opera){var Db=ba.opera.version
"function"==typeof Db&&Db()}else Ab?Cb=/rv\:([^\);]+)(\)|;)/:zb?Cb=/MSIE\s+([^\);]+)(\)|;)/:Bb&&(Cb=/WebKit\/(\S+)/),Cb&&Cb.exec(wb())
var Eb=l,Fb=l,Hb,Ib=1
Hb=function(){return Ib++}
var Lb=l,Mb=k,Zb=/^-?\d{1,10}$/
s=ac.prototype
s.N=r(k)
s.j=aa("Za")
s.Ea=function(a){return new ac(this.D,a)}
s.M=function(){return Q}
s.Q=function(a){return F(a)===l?this:Q}
s.da=r(l)
s.G=function(a,b){return(new R).G(a,b).Ea(this.Za)}
s.xa=function(a,b){var c=F(a)
return c===l?b:this.G(c,Q.xa(Ka(a),b))}
s.f=r(o)
s.Sb=r(0)
s.V=function(a){return a&&this.j()!==l?{".value":this.k(),".priority":this.j()}:this.k()}
s.hash=function(){var a=""
this.j()!==l&&(a+="priority:"+bc(this.j())+":")
var b=typeof this.D,a=a+(b+":"),a="number"===b?a+Yb(this.D):a+this.D
return Jb(a)}
s.k=aa("D")
s.toString=function(){return"string"==typeof this.D?'"'+this.D+'"':this.D}
s=R.prototype
s.N=r(o)
s.j=aa("Za")
s.Ea=function(a){return new R(this.o,a)}
s.G=function(a,b){var c=this.o.remove(a)
b&&b.f()&&(b=l)
b!==l&&(c=c.na(a,b))
return b&&b.j()!==l?new fc(c,l,this.Za):new R(c,this.Za)}
s.xa=function(a,b){var c=F(a)
if(c===l)return b
var d=this.M(c).xa(Ka(a),b)
return this.G(c,d)}
s.f=function(){return this.o.f()}
s.Sb=function(){return this.o.count()}
var gc=/^\d+$/
s=R.prototype
s.V=function(a){if(this.f())return l
var b={},c=0,d=0,e=k
this.w(function(f,h){b[f]=h.V(a)
c++
e&&gc.test(f)?d=Math.max(d,Number(f)):e=o})
if(!a&&e&&2*c>d){var h,f=[]
for(h in b)f[h]=b[h]
return f}a&&this.j()!==l&&(b[".priority"]=this.j())
return b}
s.hash=function(){var a=""
this.j()!==l&&(a+="priority:"+bc(this.j())+":")
this.w(function(b,c){var d=c.hash()
""!==d&&(a+=":"+b+":"+d)})
return""===a?"":Jb(a)}
s.M=function(a){a=this.o.get(a)
return a===l?Q:a}
s.Q=function(a){var b=F(a)
return b===l?this:this.M(b).Q(Ka(a))}
s.da=function(a){return Ua(this.o,a)}
s.$c=function(){return this.o.tb()}
s.ad=function(){return this.o.Wa()}
s.w=function(a){return this.o.Aa(a)}
s.vc=function(a){return this.o.Ma(a)}
s.Va=function(){return this.o.Va()}
s.toString=function(){var a="{",b=k
this.w(function(c,d){b?b=o:a+=", "
a+='"'+c+'" : '+d.toString()})
return a+="}"}
var Q=new R
ka(fc,R)
s=fc.prototype
s.G=function(a,b){var c=this.M(a),d=this.o,e=this.ta
c!==l&&(d=d.remove(a),e=e.remove({name:a,ha:c.j()}))
b&&b.f()&&(b=l)
b!==l&&(d=d.na(a,b),e=e.na({name:a,ha:b.j()},b))
return new fc(d,e,this.j())}
s.da=function(a,b){var c=Ua(this.ta,{name:a,ha:b.j()})
return c?c.name:l}
s.w=function(a){return this.ta.Aa(function(b,c){return a(b.name,c)})}
s.vc=function(a){return this.ta.Ma(function(b,c){return a(b.name,c)})}
s.Va=function(){return this.ta.Va(function(a,b){return{key:a.name,value:b}})}
s.$c=function(){return this.ta.f()?l:this.ta.tb().name}
s.ad=function(){return this.ta.f()?l:this.ta.Wa().name}
var ic=Math.log(2)
T.prototype.V=function(){A("Firebase.DataSnapshot.val",0,0,arguments.length)
return this.z.V()}
T.prototype.val=T.prototype.V
T.prototype.xd=function(){A("Firebase.DataSnapshot.exportVal",0,0,arguments.length)
return this.z.V(k)}
T.prototype.exportVal=T.prototype.xd
T.prototype.F=function(a){A("Firebase.DataSnapshot.child",0,1,arguments.length)
ga(a)&&(a=String(a))
Ga("Firebase.DataSnapshot.child",a)
var b=new K(a),c=this.bc.F(b)
return new T(this.z.Q(b),c)}
T.prototype.child=T.prototype.F
T.prototype.zc=function(a){A("Firebase.DataSnapshot.hasChild",1,1,arguments.length)
Ga("Firebase.DataSnapshot.hasChild",a)
var b=new K(a)
return!this.z.Q(b).f()}
T.prototype.hasChild=T.prototype.zc
T.prototype.j=function(){A("Firebase.DataSnapshot.getPriority",0,0,arguments.length)
return this.z.j()}
T.prototype.getPriority=T.prototype.j
T.prototype.forEach=function(a){A("Firebase.DataSnapshot.forEach",1,1,arguments.length)
C("Firebase.DataSnapshot.forEach",1,a,o)
if(this.z.N())return o
var b=this
return this.z.w(function(c,d){return a(new T(d,b.bc.F(c)))})}
T.prototype.forEach=T.prototype.forEach
T.prototype.nb=function(){A("Firebase.DataSnapshot.hasChildren",0,0,arguments.length)
return this.z.N()?o:!this.z.f()}
T.prototype.hasChildren=T.prototype.nb
T.prototype.name=function(){A("Firebase.DataSnapshot.name",0,0,arguments.length)
return this.bc.name()}
T.prototype.name=T.prototype.name
T.prototype.Sb=function(){A("Firebase.DataSnapshot.numChildren",0,0,arguments.length)
return this.z.Sb()}
T.prototype.numChildren=T.prototype.Sb
T.prototype.Kc=function(){A("Firebase.DataSnapshot.ref",0,0,arguments.length)
return this.bc}
T.prototype.ref=T.prototype.Kc
kc.prototype.xc=function(){}
kc.prototype.Uc=function(a){for(var b=this.sb[a]||[],c=0;c<b.length;c++)b[c].W.apply(b[c].T,Array.prototype.slice.call(arguments,1))}
kc.prototype.Ya=function(a,b,c){mc(this,a)
this.sb[a]=this.sb[a]||[]
this.sb[a].push({W:b,T:c});(a=this.xc(a))&&b.apply(c,a)}
kc.prototype.vb=function(a,b,c){mc(this,a)
for(var a=this.sb[a]||[],d=0;d<a.length;d++)if(a[d].W===b&&(!c||c===a[d].T)){a.splice(d,1)
break}}
ka(nc,kc)
da(nc)
nc.prototype.xc=function(a){z("visible"===a)
return[this.hb]}
qc.prototype.get=function(){return pc(this.jb)}
sc.prototype.get=function(){var a=this.ud.get(),b=pc(a)
if(this.Qb)for(var c in this.Qb)b[c]-=this.Qb[c]
this.Qb=a
return b}
tc.prototype.gd=function(){var d,a=this.hc.get(),b={},c=o
for(d in a)0<a[d]&&D(this.Pc,d)&&(b[d]=a[d],c=k)
c&&(a=this.u,a.P&&(b={c:b},a.e("reportStats",b),a.Da("s",b)))
setTimeout(w(this.gd,this),6e5*Math.random())}
var uc={},vc={},xc=l
"undefined"!=typeof MozWebSocket?xc=MozWebSocket:"undefined"!=typeof WebSocket&&(xc=WebSocket)
var zc
yc.prototype.open=function(a,b){this.ga=b
this.Fd=a
this.e("websocket connecting to "+this.Qa)
this.Y=new xc(this.Qa)
this.kb=o
var c=this
this.Y.onopen=function(){c.e("Websocket connected.")
c.kb=k}
this.Y.onclose=function(){c.e("Websocket connection was disconnected.")
c.Y=l
c.Ka()}
this.Y.onmessage=function(a){if(c.Y!==l)if(a=a.data,rc(c.$,"bytes_received",a.length),Ac(c),c.frames!==l)Bc(c,a)
else{a:{z(c.frames===l,"We already have a frame buffer")
if(6>=a.length){var b=Number(a)
if(!isNaN(b)){c.Rc=b
c.frames=[]
a=l
break a}}c.Rc=1
c.frames=[]}a!==l&&Bc(c,a)}}
this.Y.onerror=function(a){c.e("WebSocket error.  Closing connection.")
a.data&&c.e(a.data)
c.Ka()}}
yc.prototype.start=function(){}
yc.isAvailable=function(){return!("undefined"!=typeof navigator&&"Opera"===navigator.appName||xc===l||zc)}
yc.prototype.send=function(a){Ac(this)
a=y(a)
rc(this.$,"bytes_sent",a.length)
a=Vb(a,16384)
1<a.length&&this.Y.send(String(a.length))
for(var b=0;b<a.length;b++)this.Y.send(a[b])}
yc.prototype.Jb=function(){this.Ia=k
this.qb&&(clearInterval(this.qb),this.qb=l)
this.Y&&(this.Y.close(),this.Y=l)}
yc.prototype.Ka=function(){this.Ia||(this.e("WebSocket is closing itself"),this.Jb(),this.ga&&(this.ga(this.kb),this.ga=l))}
yc.prototype.close=function(){this.Ia||(this.e("WebSocket is being closed"),this.Jb())}
s=Cc.prototype
s.add=function(a,b){this.set[a]=b!==l?b:k}
s.contains=function(a){return D(this.set,a)}
s.get=function(a){return this.contains(a)?this.set[a]:j}
s.remove=function(a){delete this.set[a]}
s.f=function(){var a
a:{for(a in this.set){a=o
break a}a=k}return a}
s.count=function(){var b,a=0
for(b in this.set)a++
return a}
s.keys=function(){var b,a=[]
for(b in this.set)D(this.set,b)&&a.push(b)
return a}
var Ec="pLPCommand",Fc="pRTLPCB",Hc,Ic
Gc.prototype.open=function(a,b){function c(){if(!d.Ia){d.ja=new Jc(function(a,b,c){rc(d.$,"bytes_received",y(arguments).length)
if(d.ja)if(d.Fa&&(clearTimeout(d.Fa),d.Fa=l),d.kb=k,"start"==a)d.id=b,d.fd=c
else if("close"===a)if(b){d.ja.fc=o
var h=d.cd
h.qc=b
h.Ja=function(){d.Ka()}
h.qc<h.Ra&&(h.Ja(),h.Ja=l)}else d.Ka()
else g(Error("Unrecognized command received: "+a))},function(a,b){rc(d.$,"bytes_received",y(arguments).length)
var c=d.cd
for(c.Zb[a]=b;c.Zb[c.Ra];){var e=c.Zb[c.Ra]
delete c.Zb[c.Ra]
for(var f=0;f<e.length;++f)if(e[f]){var h=c
$b(function(){h.Gc(e[f])})}if(c.Ra===c.qc){c.Ja&&(clearTimeout(c.Ja),c.Ja(),c.Ja=l)
break}c.Ra++}},function(){d.Ka()},d.Mb)
var a={start:"t"}
a.ser=Math.floor(1e8*Math.random())
d.ja.jc&&(a.cb=d.ja.jc)
a.v="5"
d.gc&&(a.s=d.gc)
a=d.Mb(a)
d.e("Connecting via long-poll to "+a)
Kc(d.ja,a,function(){})}}this.Wc=0
this.R=b
this.cd=new oc(a)
this.Ia=o
var d=this
this.Fa=setTimeout(function(){d.e("Timed out trying to connect.")
d.Ka()
d.Fa=l},3e4)
if("complete"===document.readyState)c()
else{var e=o,f=function(){document.body?e||(e=k,c()):setTimeout(f,10)}
document.addEventListener?(document.addEventListener("DOMContentLoaded",f,o),window.addEventListener("load",f,o)):document.attachEvent&&(document.attachEvent("onreadystatechange",function(){"complete"===document.readyState&&f()},o),window.attachEvent("onload",f,o))}}
Gc.prototype.start=function(){var a=this.ja,b=this.fd
a.Dd=this.id
a.Ed=b
for(a.mc=k;Lc(a););a=this.id
b=this.fd
this.Xa=document.createElement("iframe")
var c={dframe:"t"}
c.id=a
c.pw=b
a=this.Mb(c)
this.Xa.src=a
this.Xa.style.display="none"
document.body.appendChild(this.Xa)}
Gc.isAvailable=function(){return!(Ic||"object"==typeof window&&window.chrome&&window.chrome.extension&&!/^chrome/.test(window.location.href)||"object"==typeof Windows&&"object"==typeof Windows.Td||!Hc&&!k)}
Gc.prototype.Jb=function(){this.Ia=k
this.ja&&(this.ja.close(),this.ja=l)
this.Xa&&(document.body.removeChild(this.Xa),this.Xa=l)
this.Fa&&(clearTimeout(this.Fa),this.Fa=l)}
Gc.prototype.Ka=function(){this.Ia||(this.e("Longpoll is closing itself"),this.Jb(),this.R&&(this.R(this.kb),this.R=l))}
Gc.prototype.close=function(){this.Ia||(this.e("Longpoll is being closed."),this.Jb())}
Gc.prototype.send=function(a){a=y(a)
rc(this.$,"bytes_sent",a.length)
for(var a=ra(a),a=Gb(a,k),a=Vb(a,1840),b=0;b<a.length;b++){var c=this.ja
c.Db.push({Nd:this.Wc,Sd:a.length,Yc:a[b]})
c.mc&&Lc(c)
this.Wc++}}
Jc.prototype.close=function(){this.mc=o
if(this.X){this.X.ya.body.innerHTML=""
var a=this
setTimeout(function(){a.X!==l&&(document.body.removeChild(a.X),a.X=l)},0)}var b=this.ga
b&&(this.ga=l,b())}
var Nc=[Gc,{isAvailable:r(o)},yc]
Oc.prototype.ld=function(a){a={t:"d",d:a}
1!==this.va&&g("Connection is not connected")
this.Kb.send(a)}
Oc.prototype.Vb=function(a){this.Gc(a)}
Oc.prototype.close=function(){2!==this.va&&(this.e("Closing realtime connection."),this.va=2,Tc(this),this.R&&(this.R(),this.R=l))}
ka(Vc,kc)
da(Vc)
Vc.prototype.xc=function(a){z("online"===a)
return[this.zb]}
var Xc=0,Zc=0
s=Wc.prototype
s.Da=function(a,b,c){var d=++this.Md,a={r:d,a:a,b:b}
this.e(y(a))
z(this.P,"sendRequest_ call when we're not connected not allowed.")
this.ia.ld(a)
c&&(this.Hb[d]=c)}
s.ib=function(a,b,c){this.Ga={vd:a,Zc:o,W:b,Ob:c}
this.e("Authenticating using credential: "+this.Ga)
bd(this)}
s.Lb=function(a){delete this.Ga
this.wb(o)
this.P&&this.Da("unauth",{},function(b){a(b.s)})}
s.Ec=function(a,b){this.P?ed(this,"oc",a,l,b):this.xb.push({Jc:a,action:"oc",data:l,C:b})}
s.put=function(a,b,c,d){fd(this,"p",a,b,c,d)}
s.Vb=function(a){if("r"in a){this.e("from server: "+y(a))
var b=a.r,c=this.Hb[b]
c&&(delete this.Hb[b],c(a.b))}else"error"in a&&g("A server-side error has occurred: "+a.error),"a"in a&&(b=a.a,a=a.b,this.e("handleServerMessage",b,a),"d"===b?this.Wb(a.p,a.d):"m"===b?this.Wb(a.p,a.d,k):"c"===b?(b=a.p,a=(a=a.q)?jb(a,function(a){return Ja(a)}).join("$"):"{}",(a=ad(this,b,a))&&a.C&&a.C("permission_denied")):"ac"===b?(b=a.s,a=a.d,c=this.Ga,delete this.Ga,c&&c.Ob&&c.Ob(b,a),this.wb(o)):"sd"===b?this.Lc?this.Lc(a):"msg"in a&&"undefined"!=typeof console&&console.log("FIREBASE: "+a.msg.replace("\n","\nFIREBASE: ")):Pb("Unrecognized action received from server: "+y(b)+"\nAre you using the latest client?"))}
s.yb=function(a){this.e("connection ready")
this.P=k
this.rb=(new Date).getTime()
this.Hc({serverTimeOffset:a-(new Date).getTime()})
bd(this)
for(var b in this.fa)for(var c in this.fa[b])a=this.fa[b][c],$c(this,b,c,a.$a,a.C)
for(b=0;b<this.U.length;b++)this.U[b]&&gd(this,b)
for(;this.xb.length;)b=this.xb.shift(),ed(this,b.action,b.Jc,b.data,b.C)
this.Ub(k)}
s.Hd=function(a){a&&!this.hb&&3e5===this.pa&&(this.e("Window became visible.  Reducing delay."),this.pa=1e3,this.ia||Yc(this,0))
this.hb=a}
s.Gd=function(a){a?(this.e("Browser went online.  Reconnecting."),this.pa=1e3,this.Na=k,this.ia||Yc(this,0)):(this.e("Browser went offline.  Killing connection; don't reconnect."),this.Na=o,this.ia&&this.ia.close())}
s.dd=function(){this.e("data client disconnected")
this.P=o
this.ia=l
for(var a=0;a<this.U.length;a++){var b=this.U[a]
b&&"h"in b.hd&&b.Jd&&(b.C&&b.C("disconnect"),delete this.U[a],this.Ab--)}0===this.Ab&&(this.U=[])
if(this.Na)this.hb?this.rb&&(3e4<(new Date).getTime()-this.rb&&(this.pa=1e3),this.rb=l):(this.e("Window isn't visible.  Delaying reconnect."),this.pa=3e5,this.Cc=(new Date).getTime()),a=Math.max(0,this.pa-((new Date).getTime()-this.Cc)),a*=Math.random(),this.e("Trying to reconnect in "+a+"ms"),Yc(this,a),this.pa=Math.min(3e5,1.3*this.pa)
else for(var c in this.Hb)delete this.Hb[c]
this.Ub(o)}
s.Ha=function(){this.Na=o
this.ia?this.ia.close():(this.Ta&&(clearTimeout(this.Ta),this.Ta=l),this.P&&this.dd())}
s.bb=function(){this.Na=k
this.pa=1e3
this.P||Yc(this,0)}
hd.prototype.w=function(a){this.o!==l&&Dc(this.o,function(b,c){a(b,c)})}
ld.prototype.toString=function(){return this.qa.toString()}
md.prototype.set=function(a,b){var c=this,d=[]
ib(b,function(a){var b=a.path,a=a.oa,h=Hb()
M(L(c.Cb,b),h)
V(c.I,b,a)
d.push({path:b,Od:h})})
return d}
qd.prototype.Fb=function(){for(var a=0;a<this.Ua.length;a++)if(this.Ua[a]){var b=this.Ua[a]
this.Ua[a]=l
sd(b)}this.Ua=[]}
td.prototype.$b=function(a,b){b=this.ac(a,b)
b!=l&&wd(this,b)}
td.prototype.Fb=function(){this.uc.Fb()}
ka(zd,td)
zd.prototype.ac=function(a,b){this.i=a
this.pb&&b!=l&&b.push(new W("value",this.i))
return b}
zd.prototype.lb=function(){return{}}
ka(Ed,Cc)
s=Ed.prototype
s.setActive=function(a){this.wa=a}
s.defaultView=function(){return Fd(this)?this.get("default"):l}
s.path=aa("S")
s.toString=function(){return jb(this.keys(),function(a){return"default"===a?"{}":a}).join("$")}
s.$a=function(){var a=[]
Dc(this,function(b,c){a.push(c.J)})
return a}
ka(Hd,td)
Hd.prototype.ac=function(a,b){if(b===l)return b
var c=[],d=this.J
u(d.ca)&&(u(d.ua)&&d.ua!=l?c.push(function(a,b){var c=Rb(b,d.ca)
return c>0||0===c&&0<=Sb(a,d.ua)}):c.push(function(a,b){return 0<=Rb(b,d.ca)}))
u(d.za)&&(u(d.Sa)?c.push(function(a,b){var c=Rb(b,d.za)
return 0>c||0===c&&0>=Sb(a,d.Sa)}):c.push(function(a,b){return 0>=Rb(b,d.za)}))
var e=l,f=l
if(u(this.J.Ba))if(u(this.J.ca)){if(e=Id(a,c,this.J.Ba,o)){var h=a.M(e).j()
c.push(function(a,b){var c=Rb(b,h)
return 0>c||0===c&&0>=Sb(a,e)})}}else if(f=Id(a,c,this.J.Ba,k)){var i=a.M(f).j()
c.push(function(a,b){var c=Rb(b,i)
return c>0||0===c&&0<=Sb(a,f)})}for(var m=[],n=[],p=[],q=[],t=0;t<b.length;t++){var x=b[t].aa,O=b[t].sa
switch(b[t].type){case"child_added":Jd(c,x,O)&&(this.i=this.i.G(x,O),n.push(b[t]))
break
case"child_removed":this.i.M(x).f()||(this.i=this.i.G(x,l),m.push(b[t]))
break
case"child_changed":!this.i.M(x).f()&&Jd(c,x,O)&&(this.i=this.i.G(x,O),q.push(b[t]))
break
case"child_moved":var I=!this.i.M(x).f(),G=Jd(c,x,O)
I?G?(this.i=this.i.G(x,O),p.push(b[t])):(m.push(new W("child_removed",this.i.M(x),x)),this.i=this.i.G(x,l)):G&&(this.i=this.i.G(x,O),n.push(b[t]))}}var Uc=e||f
if(Uc){var yd=(t=f!==l)?this.i.$c():this.i.ad(),lc=o,$a=o,ab=this;(t?a.vc:a.w).call(a,function(a,b){!$a&&yd===l&&($a=k)
if($a&&lc)return k
lc?(m.push(new W("child_removed",ab.i.M(a),a)),ab.i=ab.i.G(a,l)):$a&&(n.push(new W("child_added",b,a)),ab.i=ab.i.G(a,b))
yd===a&&($a=k)
a===Uc&&(lc=k)})}for(t=0;t<n.length;t++)c=n[t],x=this.i.da(c.aa,c.sa),m.push(new W("child_added",c.sa,c.aa,x))
for(t=0;t<p.length;t++)c=p[t],x=this.i.da(c.aa,c.sa),m.push(new W("child_moved",c.sa,c.aa,x))
for(t=0;t<q.length;t++)c=q[t],x=this.i.da(c.aa,c.sa),m.push(new W("child_changed",c.sa,c.aa,x))
this.pb&&0<m.length&&m.push(new W("value",this.i))
return m}
Hd.prototype.zc=function(a){return this.i.M(a)!==Q}
Hd.prototype.lb=function(a,b,c){var d={}
this.i.N()||this.i.w(function(a){d[a]=3})
var e=this.i,c=U(c,new K("")),f=new Na
M(L(f,this.J.path),k)
var b=Q.xa(a,b),h=this
Bd(c,b,a,f,function(a,b,c){c!==l&&a.toString()===h.J.path.toString()&&h.ac(b,c)})
this.i.N()?Xb(d,function(a,b){d[b]=2}):(this.i.w(function(a){D(d,a)||(d[a]=1)}),Xb(d,function(a,b){h.i.M(b).f()&&(d[b]=2)}))
this.i=e
return d}
Kd.prototype.Nb=function(a,b,c,d,e){var f=a.path,h=L(this.ka,f),i=h.k()
i===l?(i=new Ed,M(h,i)):z(!i.f(),"We shouldn't be storing empty QueryMaps")
var m=a.La()
if(i.contains(m))a=i.get(m),ud(a,b,c,d,e)
else{var n=this.g.qa.Q(f),n=a="default"===a.La()?new zd(a,n):new Hd(a,n)
if(Gd(i)||Ld(h))i.add(m,n),i.S||(i.S=n.J.path)
else{var p,q
i.f()||(p=i.toString(),q=i.$a())
i.add(m,n)
i.S||(i.S=n.J.path)
i.setActive(Md(this,i))
p&&q&&cd(this.u,i.path(),p,q)}Gd(i)&&Pa(h,function(a){if(a=a.k()){a.wa&&a.wa()
a.wa=l}})
ud(a,b,c,d,e);(b=(b=Qa(L(this.ka,f),function(a){var b;(b=a.k())&&(b=a.k().defaultView())&&(b=a.k().defaultView().pb)
return b?k:void 0},k))||this.u===l&&!U(this.g,f).f())&&xd(a)}a.Fb()}
Kd.prototype.cc=function(a,b,c,d){var e=L(this.ka,a.path).k()
return e===l?l:Od(this,e,a,b,c,d)}
Kd.prototype.$b=function(a,b,c){a=L(this.ka,a).k()
a!==l&&Dc(a,function(a,e){e.$b(b,c)})}
Kd.prototype.lb=function(a,b,c,d){var e={}
Dc(b,function(b,h){var i=h.lb(a,c,d)
Xb(i,function(a,b){e[b]=3===a?3:(ua(e,b)||a)===a?a:3})})
c.N()||c.w(function(a){D(e,a)||(e[a]=4)})
return e}
s=Xd.prototype
s.toString=function(){return(this.K.ec?"https://":"http://")+this.K.host}
s.name=function(){return this.K.ub}
s.Wb=function(a,b,c){this.tc++
var d,e,f=[]
9<=a.length&&a.lastIndexOf(".priority")===a.length-9?(d=new K(a.substring(0,a.length-9)),e=U(this.g.ra,d).Ea(b),f.push(d)):c?(d=new K(a),e=U(this.g.ra,d),Xb(b,function(a,b){var c=new K(b)
e=e.xa(c,S(a))
f.push(d.F(b))})):(d=new K(a),e=S(b),f.push(d))
a=Ud(this.H,d,e,this.g.I)
b=o
for(c=0;c<a.length;++c){var h=a[c],i=this.g,m=h.path
V(i.ra,m,h.oa)
b=nd(i,m)||b}b&&(d=ae(this,d))
Qd(this.H,d,f)}
s.Ub=function(a){Yd(this,"connected",a)
if(a===o){this.e("onDisconnectEvents")
var b=this,c=[],d=$d(this),a=kd,e=new hd
kd(this.R,new K(""),function(a,b){id(e,a,Wd(b,d))})
a(e,new K(""),function(a,d){var e=Ud(b.H,a,d,b.g.I)
c.push.apply(c,b.g.set(a,e))
e=be(b,a)
ae(b,e)
Qd(b.H,e,[a])})
pd(this.g,c)
this.R=new hd}}
s.Hc=function(a){var b=this
Wb(a,function(a,d){Yd(b,d,a)})}
s.yc=function(a){a=new K(a)
return U(this.g.ra,a).hash()}
s.wb=function(a){Yd(this,"authenticated",a)}
s.ib=function(a,b,c){"firebaseio-demo.com"===this.K.domain&&P("FirebaseRef.auth() not supported on demo (*.firebaseio-demo.com) Firebases. Please use on production (*.firebaseio.com) Firebases only.")
this.u.ib(a,function(a,c){X(b,a,c)},function(a,b){P("auth() was canceled: "+b)
if(c){var f=Error(b)
f.code=a.toUpperCase()
c(f)}})}
s.Lb=function(a){this.u.Lb(function(b){X(a,b)})}
s.eb=function(a,b,c,d){this.e("set",{path:a.toString(),value:b,ha:c})
var e=$d(this),b=S(b,c),e=Wd(b,e),e=Ud(this.H,a,e,this.g.I),f=this.g.set(a,e),h=this
this.u.put(a.toString(),b.V(k),function(b){"ok"!==b&&P("set at "+a+" failed: "+b)
pd(h.g,f)
nd(h.g,a)
var c=ae(h,a)
Qd(h.H,c,[])
X(d,b)})
e=be(this,a)
ae(this,e)
Qd(this.H,e,[a])}
s.update=function(a,b,c){this.e("update",{path:a.toString(),value:b})
var m,d=U(this.g.la,a),e=k,f=[],h=$d(this),i=[]
for(m in b){var e=o,n=S(b[m]),n=Wd(n,h),d=d.G(m,n),p=a.F(m)
f.push(p)
n=Ud(this.H,p,n,this.g.I)
i=i.concat(this.g.set(a,n))}if(e)N("update() called with empty data.  Don't do anything."),X(c,"ok")
else{var q=this
fd(this.u,"m",a.toString(),b,function(b){z("ok"===b||"permission_denied"===b,"merge at "+a+" failed.")
"ok"!==b&&P("update at "+a+" failed: "+b)
pd(q.g,i)
nd(q.g,a)
var d=ae(q,a)
Qd(q.H,d,[])
X(c,b)},j)
b=be(this,a)
ae(this,b)
Qd(q.H,b,f)}}
s.Mc=function(a,b,c){this.e("setPriority",{path:a.toString(),ha:b})
var d=$d(this),d=Vd(b,d),d=U(this.g.I,a).Ea(d),d=Ud(this.H,a,d,this.g.I),e=this.g.set(a,d),f=this
this.u.put(a.toString()+"/.priority",b,function(a){pd(f.g,e)
X(c,a)})
a=ae(this,a)
Qd(f.H,a,[])}
s.Ec=function(a,b){var c=this
this.u.Ec(a.toString(),function(d){"ok"===d&&jd(c.R,a)
X(b,d)})}
s.Nb=function(a,b,c,d,e){".info"===F(a.path)?this.Bc.Nb(a,b,c,d,e):this.H.Nb(a,b,c,d,e)}
s.cc=function(a,b,c,d){if(".info"===F(a.path))this.Bc.cc(a,b,c,d)
else{b=this.H.cc(a,b,c,d)
if(c=b!==l){for(var c=this.g,d=a.path,e=[],f=0;f<b.length;++f)e[f]=U(c.ra,b[f])
V(c.ra,d,Q)
for(f=0;f<b.length;++f)V(c.ra,b[f],e[f])
c=nd(c,d)}c&&(z(this.g.la.qa===this.H.Tb,"We should have raised any outstanding events by now.  Else, we'll blow them away."),V(this.g.la,a.path,U(this.g.I,a.path)),this.H.Tb=this.g.la.qa)}}
s.Ha=function(){this.u.Ha()}
s.bb=function(){this.u.bb()}
s.Nc=function(a){if("undefined"!=typeof console){a?(this.hc||(this.hc=new sc(this.$)),a=this.hc.get()):a=this.$.get()
var e,b=a,c=[],d=0
for(e in b)c[d++]=e
var f=function(a,b){return Math.max(b.length,a)}
if(c.reduce)e=c.reduce(f,0)
else{var h=0
ib(c,function(a){h=f.call(j,h,a)})
e=h}for(var i in a){b=a[i]
for(c=i.length;e+2>c;c++)i+=" "
console.log(i+b)}}}
s.Oc=function(a){rc(this.$,a)
this.nd.Pc[a]=k}
s.e=function(){N("r:"+this.u.id+":",arguments)}
da(Y)
Y.prototype.Ha=function(){for(var a in this.ab)this.ab[a].Ha()}
Y.prototype.interrupt=Y.prototype.Ha
Y.prototype.bb=function(){for(var a in this.ab)this.ab[a].bb()}
Y.prototype.resume=Y.prototype.bb
var Z={Ad:function(a){var b=R.prototype.hash
R.prototype.hash=a
var c=ac.prototype.hash
ac.prototype.hash=a
return function(){R.prototype.hash=b
ac.prototype.hash=c}}}
Z.hijackHash=Z.Ad
Z.La=function(a){return a.La()}
Z.queryIdentifier=Z.La
Z.Cd=function(a){return a.n.u.fa}
Z.listens=Z.Cd
Z.Kd=function(a){return a.n.u.ia}
Z.refConnection=Z.Kd
Z.pd=Wc
Z.DataConnection=Z.pd
Wc.prototype.sendRequest=Wc.prototype.Da
Wc.prototype.interrupt=Wc.prototype.Ha
Z.qd=Oc
Z.RealTimeConnection=Z.qd
Oc.prototype.sendRequest=Oc.prototype.ld
Oc.prototype.close=Oc.prototype.close
Z.od=qb
Z.ConnectionTarget=Z.od
Z.yd=function(){Hc=zc=k}
Z.forceLongPolling=Z.yd
Z.zd=function(){Ic=k}
Z.forceWebSockets=Z.zd
Z.Qd=function(a,b){a.n.u.Lc=b}
Z.setSecurityDebugCallback=Z.Qd
Z.Nc=function(a,b){a.n.Nc(b)}
Z.stats=Z.Nc
Z.Oc=function(a,b){a.n.Oc(b)}
Z.statsIncrementCounter=Z.Oc
Z.tc=function(a){return a.n.tc}
$.prototype.cancel=function(a){A("Firebase.onDisconnect().cancel",0,1,arguments.length)
C("Firebase.onDisconnect().cancel",1,a,k)
this.Gb.Ec(this.S,a)}
$.prototype.cancel=$.prototype.cancel
$.prototype.remove=function(a){A("Firebase.onDisconnect().remove",0,1,arguments.length)
E("Firebase.onDisconnect().remove",this.S)
C("Firebase.onDisconnect().remove",1,a,k)
ce(this.Gb,this.S,l,a)}
$.prototype.remove=$.prototype.remove
$.prototype.set=function(a,b){A("Firebase.onDisconnect().set",1,2,arguments.length)
E("Firebase.onDisconnect().set",this.S)
ya("Firebase.onDisconnect().set",a,o)
C("Firebase.onDisconnect().set",2,b,k)
ce(this.Gb,this.S,a,b)}
$.prototype.set=$.prototype.set
$.prototype.eb=function(a,b,c){A("Firebase.onDisconnect().setWithPriority",2,3,arguments.length)
E("Firebase.onDisconnect().setWithPriority",this.S)
ya("Firebase.onDisconnect().setWithPriority",a,o)
Da("Firebase.onDisconnect().setWithPriority",2,b,o)
C("Firebase.onDisconnect().setWithPriority",3,c,k);(".length"===this.Ca||".keys"===this.Ca)&&g("Firebase.onDisconnect().setWithPriority failed: "+this.Ca+" is a read-only object.")
var d=this.Gb,e=this.S,f=S(a,b)
dd(d.u,e.toString(),f.V(k),function(a){"ok"===a&&id(d.R,e,f)
X(c,a)})}
$.prototype.setWithPriority=$.prototype.eb
$.prototype.update=function(a,b){A("Firebase.onDisconnect().update",1,2,arguments.length)
E("Firebase.onDisconnect().update",this.S)
Ca("Firebase.onDisconnect().update",a)
C("Firebase.onDisconnect().update",2,b,k)
var f,c=this.Gb,d=this.S,e=k
for(f in a)e=o
if(e)N("onDisconnect().update() called with empty data.  Don't do anything."),X(b,k)
else{e=c.u
f=d.toString()
var h=function(e){if("ok"===e)for(var f in a){var h=S(a[f])
id(c.R,d.F(f),h)}X(b,e)}
e.P?ed(e,"om",f,a,h):e.xb.push({Jc:f,action:"om",data:a,C:h})}}
$.prototype.update=$.prototype.update
var le,me=0,ne=[]
le=function(a){var b=a===me
me=a
for(var c=Array(8),d=7;d>=0;d--)c[d]="-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".charAt(a%64),a=Math.floor(a/64)
z(0===a)
a=c.join("")
if(b){for(d=11;d>=0&&63===ne[d];d--)ne[d]=0
ne[d]++}else for(d=0;12>d;d++)ne[d]=Math.floor(64*Math.random())
for(d=0;12>d;d++)a+="-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".charAt(ne[d])
z(20===a.length,"NextPushId: Length should be 20.")
return a}
ka(J,H)
var oe=J,pe=["Firebase"],qe=ba
!(pe[0]in qe)&&qe.execScript&&qe.execScript("var "+pe[0])
for(var re;pe.length&&(re=pe.shift());)!pe.length&&u(oe)?qe[re]=oe:qe=qe[re]?qe[re]:qe[re]={}
J.prototype.name=function(){A("Firebase.name",0,0,arguments.length)
return this.path.f()?l:this.path.Z<this.path.m.length?this.path.m[this.path.m.length-1]:l}
J.prototype.name=J.prototype.name
J.prototype.F=function(a){A("Firebase.child",1,1,arguments.length)
if(ga(a))a=String(a)
else if(!(a instanceof K))if(F(this.path)===l){var b=a
b&&(b=b.replace(/^\/*\.info(\/|$)/,"/"))
Ga("Firebase.child",b)}else Ga("Firebase.child",a)
return new J(this.n,this.path.F(a))}
J.prototype.child=J.prototype.F
J.prototype.parent=function(){A("Firebase.parent",0,0,arguments.length)
var a=this.path.parent()
return a===l?l:new J(this.n,a)}
J.prototype.parent=J.prototype.parent
J.prototype.root=function(){A("Firebase.ref",0,0,arguments.length)
for(var a=this;a.parent()!==l;)a=a.parent()
return a}
J.prototype.root=J.prototype.root
J.prototype.toString=function(){A("Firebase.toString",0,0,arguments.length)
var a
if(this.parent()===l)a=this.n.toString()
else{a=this.parent().toString()+"/"
var b=this.name()
a+=encodeURIComponent(String(b))}return a}
J.prototype.toString=J.prototype.toString
J.prototype.set=function(a,b){A("Firebase.set",1,2,arguments.length)
E("Firebase.set",this.path)
ya("Firebase.set",a,o)
C("Firebase.set",2,b,k)
return this.n.eb(this.path,a,l,b)}
J.prototype.set=J.prototype.set
J.prototype.update=function(a,b){A("Firebase.update",1,2,arguments.length)
E("Firebase.update",this.path)
Ca("Firebase.update",a)
C("Firebase.update",2,b,k)
return this.n.update(this.path,a,b)}
J.prototype.update=J.prototype.update
J.prototype.eb=function(a,b,c){A("Firebase.setWithPriority",2,3,arguments.length)
E("Firebase.setWithPriority",this.path)
ya("Firebase.setWithPriority",a,o)
Da("Firebase.setWithPriority",2,b,o)
C("Firebase.setWithPriority",3,c,k);(".length"===this.name()||".keys"===this.name())&&g("Firebase.setWithPriority failed: "+this.name()+" is a read-only object.")
return this.n.eb(this.path,a,b,c)}
J.prototype.setWithPriority=J.prototype.eb
J.prototype.remove=function(a){A("Firebase.remove",0,1,arguments.length)
E("Firebase.remove",this.path)
C("Firebase.remove",1,a,k)
this.set(l,a)}
J.prototype.remove=J.prototype.remove
J.prototype.transaction=function(a,b,c){function d(){}A("Firebase.transaction",1,3,arguments.length)
E("Firebase.transaction",this.path)
C("Firebase.transaction",1,a,o)
C("Firebase.transaction",2,b,k)
u(c)&&"boolean"!=typeof c&&g(Error(B("Firebase.transaction",3,k)+"must be a boolean."));(".length"===this.name()||".keys"===this.name())&&g("Firebase.transaction failed: "+this.name()+" is a read-only object.")
"undefined"==typeof c&&(c=k)
var e=this.n,f=this.path,h=c
e.e("transaction on "+f)
var i=new J(e,f)
i.Ya("value",d)
var h={path:f,update:a,C:b,status:l,ed:Hb(),nc:h,kd:0,kc:function(){i.vb("value",d)},lc:l},m=h.update(U(e.gb,f).V())
if(u(m)){za("transaction failed: Data returned ",m)
h.status=1
var n=L(e.fb,f),p=n.k()||[]
p.push(h)
M(n,p)
p="object"==typeof m&&m!==l&&D(m,".priority")?m[".priority"]:U(e.g.I,f).j()
n=$d(e)
m=S(m,p)
m=Wd(m,n)
V(e.gb,f,m)
h.nc&&(V(e.g.la,f,m),Qd(e.H,f,[f]))
ee(e)}else h.kc(),h.C&&(e=he(e,f),h.C(l,o,e))}
J.prototype.transaction=J.prototype.transaction
J.prototype.Mc=function(a,b){A("Firebase.setPriority",1,2,arguments.length)
E("Firebase.setPriority",this.path)
Da("Firebase.setPriority",1,a,o)
C("Firebase.setPriority",2,b,k)
this.n.Mc(this.path,a,b)}
J.prototype.setPriority=J.prototype.Mc
J.prototype.push=function(a,b){A("Firebase.push",0,2,arguments.length)
E("Firebase.push",this.path)
ya("Firebase.push",a,k)
C("Firebase.push",2,b,k)
var c=Zd(this.n),c=le(c),c=this.F(c)
"undefined"!=typeof a&&a!==l&&c.set(a,b)
return c}
J.prototype.push=J.prototype.push
J.prototype.ga=function(){return new $(this.n,this.path,this.name())}
J.prototype.onDisconnect=J.prototype.ga
J.prototype.Ld=function(){P("FirebaseRef.removeOnDisconnect() being deprecated. Please use FirebaseRef.onDisconnect().remove() instead.")
this.ga().remove()
de(this.n)}
J.prototype.removeOnDisconnect=J.prototype.Ld
J.prototype.Pd=function(a){P("FirebaseRef.setOnDisconnect(value) being deprecated. Please use FirebaseRef.onDisconnect().set(value) instead.")
this.ga().set(a)
de(this.n)}
J.prototype.setOnDisconnect=J.prototype.Pd
J.prototype.ib=function(a,b,c){A("Firebase.auth",1,3,arguments.length)
v(a)||g(Error(B("Firebase.auth",1,o)+"must be a valid credential (a string)."))
C("Firebase.auth",2,b,k)
C("Firebase.auth",3,b,k)
this.n.ib(a,b,c)}
J.prototype.auth=J.prototype.ib
J.prototype.Lb=function(a){A("Firebase.unauth",0,1,arguments.length)
C("Firebase.unauth",1,a,k)
this.n.Lb(a)}
J.prototype.unauth=J.prototype.Lb
J.goOffline=function(){A("Firebase.goOffline",0,0,arguments.length)
Y.mb().Ha()}
J.goOnline=function(){A("Firebase.goOnline",0,0,arguments.length)
Y.mb().bb()}
J.enableLogging=Nb
J.ServerValue={TIMESTAMP:{".sv":"timestamp"}}
J.INTERNAL=Z
J.Context=Y}()

window.CodeMirror=function(){function y(ek,el){if(!(this instanceof y))return new y(ek,el)
this.options=el=el||{}
for(var em in dq)!el.hasOwnProperty(em)&&dq.hasOwnProperty(em)&&(el[em]=dq[em])
bs(el)
var eq="string"==typeof el.value?0:el.value.first,ep=this.display=f(ek,eq)
ep.wrapper.CodeMirror=this
cJ(this)
el.autofocus&&!cN&&c2(this)
this.state={keyMaps:[],overlays:[],modeGen:0,overwrite:!1,focused:!1,suppressEdits:!1,pasteIncoming:!1,draggingText:!1,highlight:new ej}
bV(this)
el.lineWrapping&&(this.display.wrapper.className+=" CodeMirror-wrap")
var eo=el.value
"string"==typeof eo&&(eo=new X(el.value,el.mode))
b2(this,cI)(this,eo)
ct&&setTimeout(bH(dI,this,!0),20)
d2(this)
var er
try{er=document.activeElement==ep.input}catch(en){}er||el.autofocus&&!cN?setTimeout(bH(bL,this),20):aq(this)
b2(this,function(){for(var et in aF)aF.propertyIsEnumerable(et)&&aF[et](this,el[et],bq)
for(var es=0;es<az.length;++es)az[es](this)})()}function f(ek,em){var en={},el=en.input=d7("textarea",null,null,"position: absolute; padding: 0; width: 1px; height: 1em; outline: none; font-size: 4px;")
b1?el.style.width="1000px":el.setAttribute("wrap","off")
dn&&(el.style.border="1px solid black")
el.setAttribute("autocorrect","off")
el.setAttribute("autocapitalize","off")
el.setAttribute("spellcheck","false")
en.inputDiv=d7("div",[el],null,"overflow: hidden; position: relative; width: 3px; height: 0px;")
en.scrollbarH=d7("div",[d7("div",null,null,"height: 1px")],"CodeMirror-hscrollbar")
en.scrollbarV=d7("div",[d7("div",null,null,"width: 1px")],"CodeMirror-vscrollbar")
en.scrollbarFiller=d7("div",null,"CodeMirror-scrollbar-filler")
en.gutterFiller=d7("div",null,"CodeMirror-gutter-filler")
en.lineDiv=d7("div",null,"CodeMirror-code")
en.selectionDiv=d7("div",null,null,"position: relative; z-index: 1")
en.cursor=d7("div"," ","CodeMirror-cursor")
en.otherCursor=d7("div"," ","CodeMirror-cursor CodeMirror-secondarycursor")
en.measure=d7("div",null,"CodeMirror-measure")
en.lineSpace=d7("div",[en.measure,en.selectionDiv,en.lineDiv,en.cursor,en.otherCursor],null,"position: relative; outline: none")
en.mover=d7("div",[d7("div",[en.lineSpace],"CodeMirror-lines")],null,"position: relative")
en.sizer=d7("div",[en.mover],"CodeMirror-sizer")
en.heightForcer=d7("div",null,null,"position: absolute; height: "+aJ+"px; width: 1px;")
en.gutters=d7("div",null,"CodeMirror-gutters")
en.lineGutter=null
en.scroller=d7("div",[en.sizer,en.heightForcer,en.gutters],"CodeMirror-scroll")
en.scroller.setAttribute("tabIndex","-1")
en.wrapper=d7("div",[en.inputDiv,en.scrollbarH,en.scrollbarV,en.scrollbarFiller,en.gutterFiller,en.scroller],"CodeMirror")
if(by){en.gutters.style.zIndex=-1
en.scroller.style.paddingRight=0}ek.appendChild?ek.appendChild(en.wrapper):ek(en.wrapper)
dn&&(el.style.width="0px")
b1||(en.scroller.draggable=!0)
if(aC){en.inputDiv.style.height="1px"
en.inputDiv.style.position="absolute"}else by&&(en.scrollbarH.style.minWidth=en.scrollbarV.style.minWidth="18px")
en.viewOffset=en.lastSizeC=0
en.showingFrom=en.showingTo=em
en.lineNumWidth=en.lineNumInnerWidth=en.lineNumChars=null
en.prevInput=""
en.alignWidgets=!1
en.pollingFast=!1
en.poll=new ej
en.cachedCharWidth=en.cachedTextHeight=null
en.measureLineCache=[]
en.measureLineCachePos=0
en.inaccurateSelection=!1
en.maxLine=null
en.maxLineLength=0
en.maxLineChanged=!1
en.wheelDX=en.wheelDY=en.wheelStartX=en.wheelStartY=null
return en}function aR(ek){ek.doc.mode=y.getMode(ek.options,ek.doc.modeOption)
ek.doc.iter(function(el){el.stateAfter&&(el.stateAfter=null)
el.styles&&(el.styles=null)})
ek.doc.frontier=ek.doc.first
cM(ek,100)
ek.state.modeGen++
ek.curOp&&N(ek)}function da(ek){if(ek.options.lineWrapping){ek.display.wrapper.className+=" CodeMirror-wrap"
ek.display.sizer.style.minWidth=""}else{ek.display.wrapper.className=ek.display.wrapper.className.replace(" CodeMirror-wrap","")
ea(ek)}I(ek)
N(ek)
Q(ek)
setTimeout(function(){dl(ek)},100)}function aE(ek){var em=at(ek.display),el=ek.options.lineWrapping,en=el&&Math.max(5,ek.display.scroller.clientWidth/cr(ek.display)-3)
return function(eo){return dN(ek.doc,eo)?0:el?(Math.ceil(eo.text.length/en)||1)*em:em}}function I(ek){var em=ek.doc,el=aE(ek)
em.iter(function(en){var eo=el(en)
eo!=en.height&&ec(en,eo)})}function eh(ek){var em=du[ek.options.keyMap],el=em.style
ek.display.wrapper.className=ek.display.wrapper.className.replace(/\s*cm-keymap-\S+/g,"")+(el?" cm-keymap-"+el:"")
ek.state.disableInput=em.disableInput}function bV(ek){ek.display.wrapper.className=ek.display.wrapper.className.replace(/\s*cm-s-\S+/g,"")+ek.options.theme.replace(/(^|\s)\s*/g," cm-s-")
Q(ek)}function cm(ek){cJ(ek)
N(ek)
setTimeout(function(){c6(ek)},20)}function cJ(ek){var el=ek.display.gutters,ep=ek.options.gutters
cC(el)
for(var em=0;em<ep.length;++em){var en=ep[em],eo=el.appendChild(d7("div",null,"CodeMirror-gutter "+en))
if("CodeMirror-linenumbers"==en){ek.display.lineGutter=eo
eo.style.width=(ek.display.lineNumWidth||1)+"px"}}el.style.display=em?"":"none"}function cR(eo,em){if(0==em.height)return 0
for(var ek,el=em.text.length,ep=em;ek=dd(ep);){var en=ek.find()
ep=dx(eo,en.from.line)
el+=en.from.ch-en.to.ch}ep=em
for(;ek=cW(ep);){var en=ek.find()
el-=ep.text.length-en.from.ch
ep=dx(eo,en.to.line)
el+=ep.text.length-en.to.ch}return el}function ea(ek){var em=ek.display,el=ek.doc
em.maxLine=dx(el,el.first)
em.maxLineLength=cR(el,em.maxLine)
em.maxLineChanged=!0
el.iter(function(eo){var en=cR(el,eo)
if(en>em.maxLineLength){em.maxLineLength=en
em.maxLine=eo}})}function bs(ek){var el=ce(ek.gutters,"CodeMirror-linenumbers")
if(-1==el&&ek.lineNumbers)ek.gutters=ek.gutters.concat(["CodeMirror-linenumbers"])
else if(el>-1&&!ek.lineNumbers){ek.gutters=ek.gutters.slice(0)
ek.gutters.splice(el,1)}}function dl(ek){var eq=ek.display,el=ek.doc.height,en=el+a3(eq)
eq.sizer.style.minHeight=eq.heightForcer.style.top=en+"px"
eq.gutters.style.height=Math.max(en,eq.scroller.clientHeight-aJ)+"px"
var eo=Math.max(en,eq.scroller.scrollHeight),ep=eq.scroller.scrollWidth>eq.scroller.clientWidth+1,em=eo>eq.scroller.clientHeight+1
if(em){eq.scrollbarV.style.display="block"
eq.scrollbarV.style.bottom=ep?i(eq.measure)+"px":"0"
eq.scrollbarV.firstChild.style.height=eo-eq.scroller.clientHeight+eq.scrollbarV.clientHeight+"px"}else{eq.scrollbarV.style.display=""
eq.scrollbarV.firstChild.style.height="0"}if(ep){eq.scrollbarH.style.display="block"
eq.scrollbarH.style.right=em?i(eq.measure)+"px":"0"
eq.scrollbarH.firstChild.style.width=eq.scroller.scrollWidth-eq.scroller.clientWidth+eq.scrollbarH.clientWidth+"px"}else{eq.scrollbarH.style.display=""
eq.scrollbarH.firstChild.style.width="0"}if(ep&&em){eq.scrollbarFiller.style.display="block"
eq.scrollbarFiller.style.height=eq.scrollbarFiller.style.width=i(eq.measure)+"px"}else eq.scrollbarFiller.style.display=""
if(ep&&ek.options.coverGutterNextToScrollbar&&ek.options.fixedGutter){eq.gutterFiller.style.display="block"
eq.gutterFiller.style.height=i(eq.measure)+"px"
eq.gutterFiller.style.width=eq.gutters.offsetWidth+"px"}else eq.gutterFiller.style.display=""
bM&&0===i(eq.measure)&&(eq.scrollbarV.style.minWidth=eq.scrollbarH.style.minHeight=b6?"18px":"12px")}function bj(ep,eo,en){var em=ep.scroller.scrollTop,ek=ep.wrapper.clientHeight
if("number"==typeof en)em=en
else if(en){em=en.top
ek=en.bottom-en.top}em=Math.floor(em-ds(ep))
var el=Math.ceil(em+ek)
return{from:a1(eo,em),to:a1(eo,el)}}function c6(ek){var eq=ek.display
if(eq.alignWidgets||eq.gutters.firstChild&&ek.options.fixedGutter){for(var en=cB(eq)-eq.scroller.scrollLeft+ek.doc.scrollLeft,ep=eq.gutters.offsetWidth,em=en+"px",er=eq.lineDiv.firstChild;er;er=er.nextSibling)if(er.alignable)for(var eo=0,el=er.alignable;eo<el.length;++eo)el[eo].style.left=em
ek.options.fixedGutter&&(eq.gutters.style.left=en+ep+"px")}}function cE(ek){if(!ek.options.lineNumbers)return!1
var ep=ek.doc,el=cU(ek.options,ep.first+ep.size-1),eo=ek.display
if(el.length!=eo.lineNumChars){var eq=eo.measure.appendChild(d7("div",[d7("div",el)],"CodeMirror-linenumber CodeMirror-gutter-elt")),em=eq.firstChild.offsetWidth,en=eq.offsetWidth-em
eo.lineGutter.style.width=""
eo.lineNumInnerWidth=Math.max(em,eo.lineGutter.offsetWidth-en)
eo.lineNumWidth=eo.lineNumInnerWidth+en
eo.lineNumChars=eo.lineNumInnerWidth?el.length:-1
eo.lineGutter.style.width=eo.lineNumWidth+"px"
return!0}return!1}function cU(ek,el){return String(ek.lineNumberFormatter(el+ek.firstLineNumber))}function cB(ek){return ak(ek.scroller).left-ak(ek.sizer).left}function cu(ep,eo,es,et){for(var en,er=ep.display.showingFrom,eq=ep.display.showingTo,ek=bj(ep.display,ep.doc,es),em=!0;;em=!1){var el=ep.display.scroller.clientWidth
if(!cc(ep,eo,ek,et))break
en=!0
eo=[]
aY(ep)
dl(ep)
if(em&&ep.options.lineWrapping&&el!=ep.display.scroller.clientWidth)et=!0
else{et=!1
es&&(es=Math.min(ep.display.scroller.scrollHeight-ep.display.scroller.clientHeight,"number"==typeof es?es:es.top))
ek=bj(ep.display,ep.doc,es)
if(ek.from>=ep.display.showingFrom&&ek.to<=ep.display.showingTo)break}}if(en){L(ep,"update",ep);(ep.display.showingFrom!=er||ep.display.showingTo!=eq)&&L(ep,"viewportChange",ep,ep.display.showingFrom,ep.display.showingTo)}return en}function cc(eo,eC,el,eA){var eu=eo.display,eD=eo.doc
if(eu.wrapper.clientWidth){if(!(!eA&&0==eC.length&&el.from>eu.showingFrom&&el.to<eu.showingTo)){cE(eo)&&(eC=[{from:eD.first,to:eD.first+eD.size}])
var ez=eu.sizer.style.marginLeft=eu.gutters.offsetWidth+"px"
eu.scrollbarH.style.left=eo.options.fixedGutter?ez:"0"
var em=1/0
if(eo.options.lineNumbers)for(var ev=0;ev<eC.length;++ev)eC[ev].diff&&eC[ev].from<em&&(em=eC[ev].from)
var en=eD.first+eD.size,et=Math.max(el.from-eo.options.viewportMargin,eD.first),ek=Math.min(en,el.to+eo.options.viewportMargin)
eu.showingFrom<et&&et-eu.showingFrom<20&&(et=Math.max(eD.first,eu.showingFrom))
eu.showingTo>ek&&eu.showingTo-ek<20&&(ek=Math.min(en,eu.showingTo))
if(ay){et=a8(s(eD,dx(eD,et)))
for(;en>ek&&dN(eD,dx(eD,ek));)++ek}var ex=[{from:Math.max(eu.showingFrom,eD.first),to:Math.min(eu.showingTo,en)}]
ex=ex[0].from>=ex[0].to?[]:dH(ex,eC)
if(ay)for(var ev=0;ev<ex.length;++ev)for(var ey,eq=ex[ev];ey=cW(dx(eD,eq.to-1));){var eB=ey.find().from.line
if(!(eB>eq.from)){ex.splice(ev--,1)
break}eq.to=eB}for(var es=0,ev=0;ev<ex.length;++ev){var eq=ex[ev]
eq.from<et&&(eq.from=et)
eq.to>ek&&(eq.to=ek)
eq.from>=eq.to?ex.splice(ev--,1):es+=eq.to-eq.from}if(eA||es!=ek-et||et!=eu.showingFrom||ek!=eu.showingTo){ex.sort(function(eF,eE){return eF.from-eE.from})
try{var ep=document.activeElement}catch(ew){}.7*(ek-et)>es&&(eu.lineDiv.style.display="none")
bz(eo,et,ek,ex,em)
eu.lineDiv.style.display=""
ep&&document.activeElement!=ep&&ep.offsetHeight&&ep.focus()
var er=et!=eu.showingFrom||ek!=eu.showingTo||eu.lastSizeC!=eu.wrapper.clientHeight
if(er){eu.lastSizeC=eu.wrapper.clientHeight
cM(eo,400)}eu.showingFrom=et
eu.showingTo=ek
aA(eo)
h(eo)
return!0}h(eo)}}else{eu.showingFrom=eu.showingTo=eD.first
eu.viewOffset=0}}function aA(es){for(var et,ep=es.display,el=ep.lineDiv.offsetTop,ek=ep.lineDiv.firstChild;ek;ek=ek.nextSibling)if(ek.lineObj){if(by){var eo=ek.offsetTop+ek.offsetHeight
et=eo-el
el=eo}else{var en=ak(ek)
et=en.bottom-en.top}var er=ek.lineObj.height-et
2>et&&(et=at(ep))
if(er>.001||-.001>er){ec(ek.lineObj,et)
var eq=ek.lineObj.widgets
if(eq)for(var em=0;em<eq.length;++em)eq[em].height=eq[em].node.offsetHeight}}}function h(ek){var el=ek.display.viewOffset=a7(ek,dx(ek.doc,ek.display.showingFrom))
ek.display.mover.style.top=el+"px"}function dH(et,er){for(var eo=0,em=er.length||0;em>eo;++eo){for(var eq=er[eo],ek=[],es=eq.diff||0,en=0,el=et.length;el>en;++en){var ep=et[en]
if(eq.to<=ep.from&&eq.diff)ek.push({from:ep.from+es,to:ep.to+es})
else if(eq.to<=ep.from||eq.from>=ep.to)ek.push(ep)
else{eq.from>ep.from&&ek.push({from:ep.from,to:eq.from})
eq.to<ep.to&&ek.push({from:eq.to+es,to:ep.to+es})}}et=ek}return et}function dv(ek){for(var eo=ek.display,en={},em={},ep=eo.gutters.firstChild,el=0;ep;ep=ep.nextSibling,++el){en[ek.options.gutters[el]]=ep.offsetLeft
em[ek.options.gutters[el]]=ep.offsetWidth}return{fixedPos:cB(eo),gutterTotalWidth:eo.gutters.offsetWidth,gutterLeft:en,gutterWidth:em,wrapperWidth:eo.wrapper.clientWidth}}function bz(et,eq,er,ew,el){function eo(ey){var ex=ey.nextSibling
if(b1&&bk&&et.display.currentWheelTarget==ey){ey.style.display="none"
ey.lineObj=null}else ey.parentNode.removeChild(ey)
return ex}var es=dv(et),ep=et.display,ev=et.options.lineNumbers
ew.length||b1&&et.display.currentWheelTarget||cC(ep.lineDiv)
var ek=ep.lineDiv,eu=ek.firstChild,em=ew.shift(),en=eq
et.doc.iter(eq,er,function(eG){em&&em.to==en&&(em=ew.shift())
if(dN(et.doc,eG)){0!=eG.height&&ec(eG,0)
if(eG.widgets&&eu&&eu.previousSibling)for(var eB=0;eB<eG.widgets.length;++eB){var eD=eG.widgets[eB]
if(eD.showIfHidden){var ez=eu.previousSibling
if(/pre/i.test(ez.nodeName)){var ey=d7("div",null,null,"position: relative")
ez.parentNode.replaceChild(ey,ez)
ey.appendChild(ez)
ez=ey}var eE=ez.appendChild(d7("div",[eD.node],"CodeMirror-linewidget"))
eD.handleMouseEvents||(eE.ignoreEvents=!0)
a0(eD,eE,ez,es)}}}else if(em&&em.from<=en&&em.to>en){for(;eu.lineObj!=eG;)eu=eo(eu)
ev&&en>=el&&eu.lineNumber&&m(eu.lineNumber,cU(et.options,en))
eu=eu.nextSibling}else{if(eG.widgets)for(var eC,eA=0,eF=eu;eF&&20>eA;++eA,eF=eF.nextSibling)if(eF.lineObj==eG&&/div/i.test(eF.nodeName)){eC=eF
break}var ex=af(et,eG,en,es,eC)
if(ex!=eC)ek.insertBefore(ex,eu)
else{for(;eu!=eC;)eu=eo(eu)
eu=eu.nextSibling}ex.lineObj=eG}++en})
for(;eu;)eu=eo(eu)}function af(er,et,eu,ex,em){var es,eq=df(er,et),eD=eq.pre,eG=et.gutterMarkers,eE=er.display,el=eq.bgClass?eq.bgClass+" "+(et.bgClass||""):et.bgClass
if(!(er.options.lineNumbers||eG||el||et.wrapClass||et.widgets))return eD
if(em){em.alignable=null
for(var ey,eH=!0,ep=0,en=null,ez=em.firstChild;ez;ez=ey){ey=ez.nextSibling
if(/\bCodeMirror-linewidget\b/.test(ez.className)){for(var eF=0;eF<et.widgets.length;++eF){var eo=et.widgets[eF]
if(eo.node==ez.firstChild){eo.above||en||(en=ez)
a0(eo,ez,em,ex);++ep
break}}if(eF==et.widgets.length){eH=!1
break}}else em.removeChild(ez)}em.insertBefore(eD,en)
if(eH&&ep==et.widgets.length){es=em
em.className=et.wrapClass||""}}if(!es){es=d7("div",null,et.wrapClass,"position: relative")
es.appendChild(eD)}el&&es.insertBefore(d7("div",null,el+" CodeMirror-linebackground"),es.firstChild)
if(er.options.lineNumbers||eG){var eB=es.insertBefore(d7("div",null,null,"position: absolute; left: "+(er.options.fixedGutter?ex.fixedPos:-ex.gutterTotalWidth)+"px"),es.firstChild)
er.options.fixedGutter&&(es.alignable||(es.alignable=[])).push(eB)
!er.options.lineNumbers||eG&&eG["CodeMirror-linenumbers"]||(es.lineNumber=eB.appendChild(d7("div",cU(er.options,eu),"CodeMirror-linenumber CodeMirror-gutter-elt","left: "+ex.gutterLeft["CodeMirror-linenumbers"]+"px; width: "+eE.lineNumInnerWidth+"px")))
if(eG)for(var eC=0;eC<er.options.gutters.length;++eC){var ew=er.options.gutters[eC],ev=eG.hasOwnProperty(ew)&&eG[ew]
ev&&eB.appendChild(d7("div",[ev],"CodeMirror-gutter-elt","left: "+ex.gutterLeft[ew]+"px; width: "+ex.gutterWidth[ew]+"px"))}}by&&(es.style.zIndex=2)
if(et.widgets&&es!=em)for(var eF=0,ek=et.widgets;eF<ek.length;++eF){var eo=ek[eF],eA=d7("div",[eo.node],"CodeMirror-linewidget")
eo.handleMouseEvents||(eA.ignoreEvents=!0)
a0(eo,eA,es,ex)
eo.above?es.insertBefore(eA,er.options.lineNumbers&&0!=et.height?eB:eD):es.appendChild(eA)
L(eo,"redraw")}return es}function a0(en,em,el,eo){if(en.noHScroll){(el.alignable||(el.alignable=[])).push(em)
var ek=eo.wrapperWidth
em.style.left=eo.fixedPos+"px"
if(!en.coverGutter){ek-=eo.gutterTotalWidth
em.style.paddingLeft=eo.gutterTotalWidth+"px"}em.style.width=ek+"px"}if(en.coverGutter){em.style.zIndex=5
em.style.position="relative"
en.noHScroll||(em.style.marginLeft=-eo.gutterTotalWidth+"px")}}function aY(ek){var en=ek.display,eo=dW(ek.doc.sel.from,ek.doc.sel.to)
eo||ek.options.showCursorWhenSelecting?z(ek):en.cursor.style.display=en.otherCursor.style.display="none"
eo?en.selectionDiv.style.display="none":S(ek)
if(ek.options.moveInputWithCursor){var ep=cz(ek,ek.doc.sel.head,"div"),el=ak(en.wrapper),em=ak(en.lineDiv)
en.inputDiv.style.top=Math.max(0,Math.min(en.wrapper.clientHeight-10,ep.top+em.top-el.top))+"px"
en.inputDiv.style.left=Math.max(0,Math.min(en.wrapper.clientWidth-10,ep.left+em.left-el.left))+"px"}}function z(ek){var el=ek.display,em=cz(ek,ek.doc.sel.head,"div")
el.cursor.style.left=em.left+"px"
el.cursor.style.top=em.top+"px"
el.cursor.style.height=Math.max(0,em.bottom-em.top)*ek.options.cursorHeight+"px"
el.cursor.style.display=""
if(em.other){el.otherCursor.style.display=""
el.otherCursor.style.left=em.other.left+"px"
el.otherCursor.style.top=em.other.top+"px"
el.otherCursor.style.height=.85*(em.other.bottom-em.other.top)+"px"}else el.otherCursor.style.display="none"}function S(ev){function ex(eB,eA,ez,ey){0>eA&&(eA=0)
eo.appendChild(d7("div",null,"CodeMirror-selected","position: absolute; left: "+eB+"px; top: "+eA+"px; width: "+(null==ez?et-eB:ez)+"px; height: "+(ey-eA)+"px"))}function es(ez,eB,eE){function eD(eH,eG){return bS(ev,H(ez,eH),"div",eA,eG)}var eF,ey,eA=dx(eu,ez),eC=eA.text.length
cD(a(eA),eB||0,null==eE?eC:eE,function(eN,eM,eG){var eK,eL,eI,eJ=eD(eN,"left")
if(eN==eM){eK=eJ
eL=eI=eJ.left}else{eK=eD(eM-1,"right")
if("rtl"==eG){var eH=eJ
eJ=eK
eK=eH}eL=eJ.left
eI=eK.right}null==eB&&0==eN&&(eL=em)
if(eK.top-eJ.top>3){ex(eL,eJ.top,null,eJ.bottom)
eL=em
eJ.bottom<eK.top&&ex(eL,eJ.bottom,null,eK.top)}null==eE&&eM==eC&&(eI=et);(!eF||eJ.top<eF.top||eJ.top==eF.top&&eJ.left<eF.left)&&(eF=eJ);(!ey||eK.bottom>ey.bottom||eK.bottom==ey.bottom&&eK.right>ey.right)&&(ey=eK)
em+1>eL&&(eL=em)
ex(eL,eK.top,eI-eL,eK.bottom)})
return{start:eF,end:ey}}var eq=ev.display,eu=ev.doc,ek=ev.doc.sel,eo=document.createDocumentFragment(),et=eq.lineSpace.offsetWidth,em=ar(ev.display)
if(ek.from.line==ek.to.line)es(ek.from.line,ek.from.ch,ek.to.ch)
else{var en=dx(eu,ek.from.line),el=dx(eu,ek.to.line),ep=s(eu,en)==s(eu,el),ew=es(ek.from.line,ek.from.ch,ep?en.text.length:null).end,er=es(ek.to.line,ep?0:null,ek.to.ch).start
if(ep)if(ew.top<er.top-2){ex(ew.right,ew.top,null,ew.bottom)
ex(em,er.top,er.left,er.bottom)}else ex(ew.right,ew.top,er.left-ew.right,ew.bottom)
ew.bottom<er.top&&ex(em,ew.bottom,null,er.top)}bc(eq.selectionDiv,eo)
eq.selectionDiv.style.display=""}function k(ek){if(ek.state.focused){var em=ek.display
clearInterval(em.blinker)
var el=!0
em.cursor.style.visibility=em.otherCursor.style.visibility=""
ek.options.cursorBlinkRate>0&&(em.blinker=setInterval(function(){em.cursor.style.visibility=em.otherCursor.style.visibility=(el=!el)?"":"hidden"},ek.options.cursorBlinkRate))}}function cM(ek,el){ek.doc.mode.startState&&ek.doc.frontier<ek.display.showingTo&&ek.state.highlight.set(el,bH(bW,ek))}function bW(ek){var en=ek.doc
en.frontier<en.first&&(en.frontier=en.first)
if(!(en.frontier>=ek.display.showingTo)){var eo,el=+new Date+ek.options.workTime,em=bi(en.mode,cp(ek,en.frontier)),ep=[]
en.iter(en.frontier,Math.min(en.first+en.size,ek.display.showingTo+500),function(eq){if(en.frontier>=ek.display.showingFrom){var es=eq.styles
eq.styles=dS(ek,eq,em)
for(var et=!es||es.length!=eq.styles.length,er=0;!et&&er<es.length;++er)et=es[er]!=eq.styles[er]
et&&(eo&&eo.end==en.frontier?eo.end++:ep.push(eo={start:en.frontier,end:en.frontier+1}))
eq.stateAfter=bi(en.mode,em)}else{cn(ek,eq,em)
eq.stateAfter=0==en.frontier%5?bi(en.mode,em):null}++en.frontier
if(+new Date>el){cM(ek,ek.options.workDelay)
return!0}})
ep.length&&b2(ek,function(){for(var eq=0;eq<ep.length;++eq)N(this,ep[eq].start,ep[eq].end)})()}}function bJ(er,el,en){for(var em,eo,ep=er.doc,eq=er.doc.mode.innerMode?1e3:100,eu=el,ek=el-eq;eu>ek;--eu){if(eu<=ep.first)return ep.first
var et=dx(ep,eu-1)
if(et.stateAfter&&(!en||eu<=ep.frontier))return eu
var es=bb(et.text,null,er.options.tabSize)
if(null==eo||em>es){eo=eu-1
em=es}}return eo}function cp(ek,eq,el){var eo=ek.doc,en=ek.display
if(!eo.mode.startState)return!0
var ep=bJ(ek,eq,el),em=ep>eo.first&&dx(eo,ep-1).stateAfter
em=em?bi(eo.mode,em):bh(eo.mode)
eo.iter(ep,eq,function(er){cn(ek,er,em)
var es=ep==eq-1||0==ep%5||ep>=en.showingFrom&&ep<en.showingTo
er.stateAfter=es?bi(eo.mode,em):null;++ep})
return em}function ds(ek){return ek.lineSpace.offsetTop}function a3(ek){return ek.mover.offsetHeight-ek.lineSpace.offsetHeight}function ar(el){var ek=bc(el.measure,d7("pre",null,null,"text-align: left")).appendChild(d7("span","x"))
return ek.offsetLeft}function cO(er,es,el,eo,ep){var en=-1
eo=eo||a4(er,es)
if(eo.crude){var em=eo.left+el*eo.width
return{left:em,right:em+eo.width,top:eo.top,bottom:eo.bottom}}for(var eq=el;;eq+=en){var ek=eo[eq]
if(ek)break
0>en&&0==eq&&(en=1)}ep=eq>el?"left":el>eq?"right":ep
"left"==ep&&ek.leftSide?ek=ek.leftSide:"right"==ep&&ek.rightSide&&(ek=ek.rightSide)
return{left:el>eq?ek.right:ek.left,right:eq>el?ek.left:ek.right,top:ek.top,bottom:ek.bottom}}function dr(ek,el){for(var en=ek.display.measureLineCache,eo=0;eo<en.length;++eo){var em=en[eo]
if(em.text==el.text&&em.markedSpans==el.markedSpans&&ek.display.scroller.clientWidth==em.width&&em.classes==el.textClass+"|"+el.wrapClass)return em}}function d0(ek,el){var em=dr(ek,el)
em&&(em.text=em.measure=em.markedSpans=null)}function a4(ek,el){var ep=dr(ek,el)
if(ep)return ep.measure
var eo=cb(ek,el),en=ek.display.measureLineCache,em={text:el.text,width:ek.display.scroller.clientWidth,markedSpans:el.markedSpans,measure:eo,classes:el.textClass+"|"+el.wrapClass}
16==en.length?en[++ek.display.measureLineCachePos%16]=em:en.push(em)
return eo}function cb(er,et){function eC(eH){var eJ=eH.top-el.top,eL=eH.bottom-el.top
eL>eD&&(eL=eD)
0>eJ&&(eJ=0)
for(var eG=ek.length-2;eG>=0;eG-=2){var eI=ek[eG],eK=ek[eG+1]
if(!(eI>eL||eJ>eK)&&(eJ>=eI&&eK>=eL||eI>=eJ&&eL>=eK||Math.min(eL,eK)-Math.max(eJ,eI)>=eL-eJ>>1)){ek[eG]=Math.min(eJ,eI)
ek[eG+1]=Math.max(eL,eK)
break}}if(0>eG){eG=ek.length
ek.push(eJ,eL)}return{left:eH.left-el.left,right:eH.right-el.left,top:eG,bottom:null}}function eF(eG){eG.bottom=ek[eG.top+1]
eG.top=ek[eG.top]}if(!er.options.lineWrapping&&et.text.length>=er.options.crudeMeasuringFrom)return d8(er,et)
var ez=er.display,ep=R(et.text.length),ew=df(er,et,ep,!0).pre
if(ct&&!by&&!er.options.lineWrapping&&ew.childNodes.length>100){for(var em=document.createDocumentFragment(),eu=10,ex=ew.childNodes.length,eB=0,ev=Math.ceil(ex/eu);ev>eB;++eB){for(var es=d7("div",null,null,"display: inline-block"),eA=0;eu>eA&&ex;++eA){es.appendChild(ew.firstChild);--ex}em.appendChild(es)}ew.appendChild(em)}bc(ez.measure,ew)
var el=ak(ez.lineDiv),ek=[],eE=R(et.text.length),eD=ew.offsetHeight
bx&&ez.measure.first!=ew&&bc(ez.measure,ew)
for(var eo,eB=0;eB<ep.length;++eB)if(eo=ep[eB]){var ey=eo,en=null
if(/\bCodeMirror-widget\b/.test(eo.className)&&eo.getClientRects){1==eo.firstChild.nodeType&&(ey=eo.firstChild)
var eq=ey.getClientRects()
if(eq.length>1){en=eE[eB]=eC(eq[0])
en.rightSide=eC(eq[eq.length-1])}}en||(en=eE[eB]=eC(ak(ey)))
eo.measureRight&&(en.right=ak(eo.measureRight).left)
eo.leftSide&&(en.leftSide=eC(ak(eo.leftSide)))}cC(er.display.measure)
for(var eo,eB=0;eB<eE.length;++eB)if(eo=eE[eB]){eF(eo)
eo.leftSide&&eF(eo.leftSide)
eo.rightSide&&eF(eo.rightSide)}return eE}function d8(ek,el){var ep=new eb(el.text.slice(0,100),null)
el.textClass&&(ep.textClass=el.textClass)
var en=cb(ek,ep),eo=cO(ek,ep,0,en,"left"),em=cO(ek,ep,99,en,"right")
return{crude:!0,top:eo.top,left:eo.left,bottom:eo.bottom,width:(em.right-eo.left)/100}}function c7(ek,em){var er=!1
if(em.markedSpans)for(var en=0;en<em.markedSpans;++en){var ep=em.markedSpans[en]
!ep.collapsed||null!=ep.to&&ep.to!=em.text.length||(er=!0)}var eo=!er&&dr(ek,em)
if(eo||em.text.length>=ek.options.crudeMeasuringFrom)return cO(ek,em,em.text.length,eo&&eo.measure,"right").right
var eq=df(ek,em,null,!0).pre,el=eq.appendChild(aN(ek.display.measure))
bc(ek.display.measure,eq)
return ak(el).right-ak(ek.display.lineDiv).left}function Q(ek){ek.display.measureLineCache.length=ek.display.measureLineCachePos=0
ek.display.cachedCharWidth=ek.display.cachedTextHeight=null
ek.options.lineWrapping||(ek.display.maxLineChanged=!0)
ek.display.lineNumChars=null}function bG(){return window.pageXOffset||(document.documentElement||document.body).scrollLeft}function bF(){return window.pageYOffset||(document.documentElement||document.body).scrollTop}function de(eq,en,ep,el){if(en.widgets)for(var em=0;em<en.widgets.length;++em)if(en.widgets[em].above){var es=bZ(en.widgets[em])
ep.top+=es
ep.bottom+=es}if("line"==el)return ep
el||(el="local")
var eo=a7(eq,en)
"local"==el?eo+=ds(eq.display):eo-=eq.display.viewOffset
if("page"==el||"window"==el){var ek=ak(eq.display.lineSpace)
eo+=ek.top+("window"==el?0:bF())
var er=ek.left+("window"==el?0:bG())
ep.left+=er
ep.right+=er}ep.top+=eo
ep.bottom+=eo
return ep}function eg(el,eo,em){if("div"==em)return eo
var eq=eo.left,ep=eo.top
if("page"==em){eq-=bG()
ep-=bF()}else if("local"==em||!em){var en=ak(el.display.sizer)
eq+=en.left
ep+=en.top}var ek=ak(el.display.lineSpace)
return{left:eq-ek.left,top:ep-ek.top}}function bS(ek,eo,en,em,el){em||(em=dx(ek.doc,eo.line))
return de(ek,em,cO(ek,em,eo.ch,null,el),en)}function cz(et,es,em,er,ep){function eo(ex,ew){var ev=cO(et,er,ex,ep,ew?"right":"left")
ew?ev.left=ev.right:ev.right=ev.left
return de(et,er,ev,em)}function eu(ey,ev){var ew=eq[ev],ex=ew.level%2
if(ey==co(ew)&&ev&&ew.level<eq[ev-1].level){ew=eq[--ev]
ey=ef(ew)-(ew.level%2?0:1)
ex=!0}else if(ey==ef(ew)&&ev<eq.length-1&&ew.level<eq[ev+1].level){ew=eq[++ev]
ey=co(ew)-ew.level%2
ex=!1}return ex&&ey==ew.to&&ey>ew.from?eo(ey-1):eo(ey,ex)}er=er||dx(et.doc,es.line)
ep||(ep=a4(et,er))
var eq=a(er),ek=es.ch
if(!eq)return eo(ek)
var el=ag(eq,ek),en=eu(ek,el)
null!=dp&&(en.other=eu(ek,dp))
return en}function d6(ek,el,em,eo){var en=new H(ek,el)
en.xRel=eo
em&&(en.outside=!0)
return en}function d1(er,eo,en){var eq=er.doc
en+=er.display.viewOffset
if(0>en)return d6(eq.first,0,!0,-1)
var el=a1(eq,en),es=eq.first+eq.size-1
if(el>es)return d6(eq.first+eq.size-1,dx(eq,es).text.length,!0,1)
0>eo&&(eo=0)
for(;;){var em=dx(eq,el),et=b0(er,em,el,eo,en),ep=cW(em),ek=ep&&ep.find()
if(!ep||!(et.ch>ek.from.ch||et.ch==ek.from.ch&&et.xRel>0))return et
el=ek.to.line}}function b0(eu,em,ex,ew,ev){function eH(eJ){var eK=cz(eu,H(ex,eJ),"line",em,eC)
eq=!0
if(et>eK.bottom)return eK.left-eD
if(et<eK.top)return eK.left+eD
eq=!1
return eK.left}var et=ev-a7(eu,em),eq=!1,eD=2*eu.display.wrapper.clientWidth,eC=a4(eu,em),ez=a(em),eB=em.text.length,eE=bN(em),en=bX(em),eA=eH(eE),ek=eq,el=eH(en),ep=eq
if(ew>el)return d6(ex,en,ep,1)
for(;;){if(ez?en==eE||en==p(em,eE,1):1>=en-eE){for(var ey=eA>ew||el-ew>=ew-eA?eE:en,eG=ew-(ey==eE?eA:el);dJ.test(em.text.charAt(ey));)++ey
var es=d6(ex,ey,ey==eE?ek:ep,0>eG?-1:eG?1:0)
return es}var er=Math.ceil(eB/2),eI=eE+er
if(ez){eI=eE
for(var eF=0;er>eF;++eF)eI=p(em,eI,1)}var eo=eH(eI)
if(eo>ew){en=eI
el=eo;(ep=eq)&&(el+=1e3)
eB=er}else{eE=eI
eA=eo
ek=eq
eB-=er}}}function at(em){if(null!=em.cachedTextHeight)return em.cachedTextHeight
if(null==ah){ah=d7("pre")
for(var el=0;49>el;++el){ah.appendChild(document.createTextNode("x"))
ah.appendChild(d7("br"))}ah.appendChild(document.createTextNode("x"))}bc(em.measure,ah)
var ek=ah.offsetHeight/50
ek>3&&(em.cachedTextHeight=ek)
cC(em.measure)
return ek||1}function cr(en){if(null!=en.cachedCharWidth)return en.cachedCharWidth
var ek=d7("span","x"),em=d7("pre",[ek])
bc(en.measure,em)
var el=ek.offsetWidth
el>2&&(en.cachedCharWidth=el)
return el||10}function bR(ek){ek.curOp={changes:[],forceUpdate:!1,updateInput:null,userSelChange:null,textChanged:null,selectionChanged:!1,cursorActivity:!1,updateMaxLine:!1,updateScrollPos:!1,id:++cG}
bE++||(aO=[])}function T(ew){var er=ew.curOp,ev=ew.doc,es=ew.display
ew.curOp=null
er.updateMaxLine&&ea(ew)
if(es.maxLineChanged&&!ew.options.lineWrapping&&es.maxLine){var el=c7(ew,es.maxLine)
es.sizer.style.minWidth=Math.max(0,el+3+aJ)+"px"
es.maxLineChanged=!1
var et=Math.max(0,es.sizer.offsetLeft+es.sizer.offsetWidth-es.scroller.clientWidth)
et<ev.scrollLeft&&!er.updateScrollPos&&aZ(ew,Math.min(es.scroller.scrollLeft,et),!0)}var em,ep
if(er.updateScrollPos)em=er.updateScrollPos
else if(er.selectionChanged&&es.scroller.clientHeight){var eu=cz(ew,ev.sel.head)
em=x(ew,eu.left,eu.top,eu.left,eu.bottom)}if(er.changes.length||er.forceUpdate||em&&null!=em.scrollTop){ep=cu(ew,er.changes,em&&em.scrollTop,er.forceUpdate)
ew.display.scroller.offsetHeight&&(ew.doc.scrollTop=ew.display.scroller.scrollTop)}!ep&&er.selectionChanged&&aY(ew)
if(er.updateScrollPos){es.scroller.scrollTop=es.scrollbarV.scrollTop=ev.scrollTop=em.scrollTop
es.scroller.scrollLeft=es.scrollbarH.scrollLeft=ev.scrollLeft=em.scrollLeft
c6(ew)
er.scrollToPos&&u(ew,dX(ew.doc,er.scrollToPos),er.scrollToPosMargin)}else em&&ab(ew)
er.selectionChanged&&k(ew)
ew.state.focused&&er.updateInput&&dI(ew,er.userSelChange)
var eq=er.maybeHiddenMarkers,ek=er.maybeUnhiddenMarkers
if(eq)for(var eo=0;eo<eq.length;++eo)eq[eo].lines.length||ae(eq[eo],"hide")
if(ek)for(var eo=0;eo<ek.length;++eo)ek[eo].lines.length&&ae(ek[eo],"unhide")
var en
if(!--bE){en=aO
aO=null}er.textChanged&&ae(ew,"change",ew,er.textChanged)
er.cursorActivity&&ae(ew,"cursorActivity",ew)
if(en)for(var eo=0;eo<en.length;++eo)en[eo]()}function b2(ek,el){return function(){var en=ek||this,eo=!en.curOp
eo&&bR(en)
try{var em=el.apply(en,arguments)}finally{eo&&T(en)}return em}}function dR(ek){return function(){var el,em=this.cm&&!this.cm.curOp
em&&bR(this.cm)
try{el=ek.apply(this,arguments)}finally{em&&T(this.cm)}return el}}function bU(el,en){var ek,em=!el.curOp
em&&bR(el)
try{ek=en()}finally{em&&T(el)}return ek}function N(ek,en,em,el){null==en&&(en=ek.doc.first)
null==em&&(em=ek.doc.first+ek.doc.size)
ek.curOp.changes.push({from:en,to:em,diff:el})}function aM(ek){ek.display.pollingFast||ek.display.poll.set(ek.options.pollInterval,function(){bu(ek)
ek.state.focused&&aM(ek)})}function t(ek){function em(){var en=bu(ek)
if(en||el){ek.display.pollingFast=!1
aM(ek)}else{el=!0
ek.display.poll.set(60,em)}}var el=!1
ek.display.pollingFast=!0
ek.display.poll.set(20,em)}function bu(ev){var eq=ev.display.input,en=ev.display.prevInput,eu=ev.doc,ek=eu.sel
if(!ev.state.focused||aS(eq)||P(ev)||ev.state.disableInput)return!1
if(ev.state.pasteIncoming&&ev.state.fakedLastChar){eq.value=eq.value.substring(0,eq.value.length-1)
ev.state.fakedLastChar=!1}var ew=eq.value
if(ew==en&&dW(ek.from,ek.to))return!1
if(ct&&!bx&&ev.display.inputHasSelection===ew){dI(ev,!0)
return!1}var em=!ev.curOp
em&&bR(ev)
ek.shift=!1
for(var ep=0,el=Math.min(en.length,ew.length);el>ep&&en.charCodeAt(ep)==ew.charCodeAt(ep);)++ep
var et=ek.from,es=ek.to
ep<en.length?et=H(et.line,et.ch-(en.length-ep)):ev.state.overwrite&&dW(et,es)&&!ev.state.pasteIncoming&&(es=H(es.line,Math.min(dx(eu,es.line).text.length,es.ch+(ew.length-ep))))
var eo=ev.curOp.updateInput,er={from:et,to:es,text:av(ew.slice(ep)),origin:ev.state.pasteIncoming?"paste":"+input"}
aG(ev.doc,er,"end")
ev.curOp.updateInput=eo
L(ev,"inputRead",ev,er)
ew.length>1e3||ew.indexOf("\n")>-1?eq.value=ev.display.prevInput="":ev.display.prevInput=ew
em&&T(ev)
ev.state.pasteIncoming=!1
return!0}function dI(ek,em){var el,en,ep=ek.doc
if(dW(ep.sel.from,ep.sel.to)){if(em){ek.display.prevInput=ek.display.input.value=""
ct&&!bx&&(ek.display.inputHasSelection=null)}}else{ek.display.prevInput=""
el=b8&&(ep.sel.to.line-ep.sel.from.line>100||(en=ek.getSelection()).length>1e3)
var eo=el?"-":en||ek.getSelection()
ek.display.input.value=eo
ek.state.focused&&cv(ek.display.input)
ct&&!bx&&(ek.display.inputHasSelection=eo)}ek.display.inaccurateSelection=el}function c2(ek){"nocursor"==ek.options.readOnly||cN&&document.activeElement==ek.display.input||ek.display.input.focus()}function P(ek){return ek.options.readOnly||ek.doc.cantEdit}function d2(el){function er(){el.state.focused&&setTimeout(bH(c2,el),0)}function eo(){null==ek&&(ek=setTimeout(function(){ek=null
eq.cachedCharWidth=eq.cachedTextHeight=cX=null
Q(el)
bU(el,bH(N,el))},100))}function en(){for(var es=eq.wrapper.parentNode;es&&es!=document.body;es=es.parentNode);es?setTimeout(en,5e3):cL(window,"resize",eo)}function em(es){ao(el,es)||el.options.onDragEvent&&el.options.onDragEvent(el,V(es))||cT(es)}function ep(){if(eq.inaccurateSelection){eq.prevInput=""
eq.inaccurateSelection=!1
eq.input.value=el.getSelection()
cv(eq.input)}}var eq=el.display
bf(eq.scroller,"mousedown",b2(el,cV))
ct?bf(eq.scroller,"dblclick",b2(el,function(et){if(!ao(el,et)){var eu=bA(el,et)
if(eu&&!j(el,et)&&!aB(el.display,et)){bO(et)
var es=Y(dx(el.doc,eu.line).text,eu)
d4(el.doc,es.from,es.to)}}})):bf(eq.scroller,"dblclick",function(es){ao(el,es)||bO(es)})
bf(eq.lineSpace,"selectstart",function(es){aB(eq,es)||bO(es)})
bQ||bf(eq.scroller,"contextmenu",function(es){aa(el,es)})
bf(eq.scroller,"scroll",function(){if(eq.scroller.clientHeight){C(el,eq.scroller.scrollTop)
aZ(el,eq.scroller.scrollLeft,!0)
ae(el,"scroll",el)}})
bf(eq.scrollbarV,"scroll",function(){eq.scroller.clientHeight&&C(el,eq.scrollbarV.scrollTop)})
bf(eq.scrollbarH,"scroll",function(){eq.scroller.clientHeight&&aZ(el,eq.scrollbarH.scrollLeft)})
bf(eq.scroller,"mousewheel",function(es){b(el,es)})
bf(eq.scroller,"DOMMouseScroll",function(es){b(el,es)})
bf(eq.scrollbarH,"mousedown",er)
bf(eq.scrollbarV,"mousedown",er)
bf(eq.wrapper,"scroll",function(){eq.wrapper.scrollTop=eq.wrapper.scrollLeft=0})
var ek
bf(window,"resize",eo)
setTimeout(en,5e3)
bf(eq.input,"keyup",b2(el,function(es){ao(el,es)||el.options.onKeyEvent&&el.options.onKeyEvent(el,V(es))||16==es.keyCode&&(el.doc.sel.shift=!1)}))
bf(eq.input,"input",function(){ct&&!bx&&el.display.inputHasSelection&&(el.display.inputHasSelection=null)
t(el)})
bf(eq.input,"keydown",b2(el,l))
bf(eq.input,"keypress",b2(el,bI))
bf(eq.input,"focus",bH(bL,el))
bf(eq.input,"blur",bH(aq,el))
if(el.options.dragDrop){bf(eq.scroller,"dragstart",function(es){F(el,es)})
bf(eq.scroller,"dragenter",em)
bf(eq.scroller,"dragover",em)
bf(eq.scroller,"drop",b2(el,aI))}bf(eq.scroller,"paste",function(es){if(!aB(eq,es)){c2(el)
t(el)}})
bf(eq.input,"paste",function(){if(b1&&!el.state.fakedLastChar&&!(new Date-el.state.lastMiddleDown<200)){var et=eq.input.selectionStart,es=eq.input.selectionEnd
eq.input.value+="$"
eq.input.selectionStart=et
eq.input.selectionEnd=es
el.state.fakedLastChar=!0}el.state.pasteIncoming=!0
t(el)})
bf(eq.input,"cut",ep)
bf(eq.input,"copy",ep)
aC&&bf(eq.sizer,"mouseup",function(){document.activeElement==eq.input&&eq.input.blur()
c2(el)})}function aB(el,ek){for(var em=A(ek);em!=el.wrapper;em=em.parentNode)if(!em||em.ignoreEvents||em.parentNode==el.sizer&&em!=el.mover)return!0}function bA(el,eq,en){var ep=el.display
if(!en){var eo=A(eq)
if(eo==ep.scrollbarH||eo==ep.scrollbarH.firstChild||eo==ep.scrollbarV||eo==ep.scrollbarV.firstChild||eo==ep.scrollbarFiller||eo==ep.gutterFiller)return null}var ek,er,em=ak(ep.lineSpace)
try{ek=eq.clientX
er=eq.clientY}catch(eq){return null}return d1(el,ek-em.left,er-em.top)}function cV(eC){function eA(eG){if(!dW(ew,eG)){ew=eG
if("single"!=el){eD=dX(eE,eD)
es=dX(eE,es)
if("double"==el){var eF=Y(dx(eE,eG.line).text,eG)
dy(eG,eD)?d4(en.doc,eF.from,es):d4(en.doc,eD,eF.to)}else"triple"==el&&(dy(eG,eD)?d4(en.doc,es,dX(eE,H(eG.line,0))):d4(en.doc,eD,dX(eE,H(eG.line+1,0))))}else d4(en.doc,dX(eE,em),eG)}}function eB(eH){var eF=++ep,eJ=bA(en,eH,!0)
if(eJ)if(dW(eJ,eo)){var eG=eH.clientY<et.top?-20:eH.clientY>et.bottom?20:0
eG&&setTimeout(b2(en,function(){if(ep==eF){ex.scroller.scrollTop+=eG
eB(eH)}}),50)}else{en.state.focused||bL(en)
eo=eJ
eA(eJ)
var eI=bj(ex,eE);(eJ.line>=eI.to||eJ.line<eI.from)&&setTimeout(b2(en,function(){ep==eF&&eB(eH)}),150)}}function er(eF){ep=1/0
bO(eF)
c2(en)
cL(document,"mousemove",eu)
cL(document,"mouseup",eq)}if(!ao(this,eC)){var en=this,ex=en.display,eE=en.doc,ev=eE.sel
ev.shift=eC.shiftKey
if(aB(ex,eC)){if(!b1){ex.scroller.draggable=!1
setTimeout(function(){ex.scroller.draggable=!0},100)}}else if(!j(en,eC)){var em=bA(en,eC)
switch(dZ(eC)){case 3:bQ&&aa.call(en,en,eC)
return
case 2:b1&&(en.state.lastMiddleDown=+new Date)
em&&d4(en.doc,em)
setTimeout(bH(c2,en),20)
bO(eC)
return}if(em){en.state.focused||bL(en)
var ek=+new Date,el="single"
if(ca&&ca.time>ek-400&&dW(ca.pos,em)){el="triple"
bO(eC)
setTimeout(bH(c2,en),20)
aL(en,em.line)}else if(cg&&cg.time>ek-400&&dW(cg.pos,em)){el="double"
ca={time:ek,pos:em}
bO(eC)
var ez=Y(dx(eE,em.line).text,em)
d4(en.doc,ez.from,ez.to)}else cg={time:ek,pos:em}
var eo=em
if(!en.options.dragDrop||!dc||P(en)||dW(ev.from,ev.to)||dy(em,ev.from)||dy(ev.to,em)||"single"!=el){bO(eC)
"single"==el&&d4(en.doc,dX(eE,em))
var eD=ev.from,es=ev.to,ew=em,et=ak(ex.wrapper),ep=0,eu=b2(en,function(eF){ct||dZ(eF)?eB(eF):er(eF)}),eq=b2(en,er)
bf(document,"mousemove",eu)
bf(document,"mouseup",eq)}else{var ey=b2(en,function(eF){b1&&(ex.scroller.draggable=!1)
en.state.draggingText=!1
cL(document,"mouseup",ey)
cL(ex.scroller,"drop",ey)
if(Math.abs(eC.clientX-eF.clientX)+Math.abs(eC.clientY-eF.clientY)<10){bO(eF)
d4(en.doc,em)
c2(en)}})
b1&&(ex.scroller.draggable=!0)
en.state.draggingText=ey
ex.scroller.dragDrop&&ex.scroller.dragDrop()
bf(document,"mouseup",ey)
bf(ex.scroller,"drop",ey)}}else A(eC)==ex.scroller&&bO(eC)}}}function ei(ev,er,et,eu,en){try{var el=er.clientX,ek=er.clientY}catch(er){return!1}if(el>=Math.floor(ak(ev.display.gutters).right))return!1
eu&&bO(er)
var es=ev.display,eq=ak(es.lineDiv)
if(ek>eq.bottom||!dD(ev,et))return a6(er)
ek-=eq.top-es.viewOffset
for(var eo=0;eo<ev.options.gutters.length;++eo){var ep=es.gutters.childNodes[eo]
if(ep&&ak(ep).right>=el){var ew=a1(ev.doc,ek),em=ev.options.gutters[eo]
en(ev,et,ev,ew,em,er)
return a6(er)}}}function cd(ek,el){return dD(ek,"gutterContextMenu")?ei(ek,el,"gutterContextMenu",!1,ae):!1}function j(ek,el){return ei(ek,el,"gutterClick",!0,L)}function aI(eq){var es=this
if(!(ao(es,eq)||aB(es.display,eq)||es.options.onDragEvent&&es.options.onDragEvent(es,V(eq)))){bO(eq)
ct&&(M=+new Date)
var er=bA(es,eq,!0),ek=eq.dataTransfer.files
if(er&&!P(es))if(ek&&ek.length&&window.FileReader&&window.File)for(var em=ek.length,eu=Array(em),el=0,en=function(ex,ew){var ev=new FileReader
ev.onload=function(){eu[ew]=ev.result
if(++el==em){er=dX(es.doc,er)
aG(es.doc,{from:er,to:er,text:av(eu.join("\n")),origin:"paste"},"around")}}
ev.readAsText(ex)},eo=0;em>eo;++eo)en(ek[eo],eo)
else{if(es.state.draggingText&&!dy(er,es.doc.sel.from)&&!dy(es.doc.sel.to,er)){es.state.draggingText(eq)
setTimeout(bH(c2,es),20)
return}try{var eu=eq.dataTransfer.getData("Text")
if(eu){var et=es.doc.sel.from,ep=es.doc.sel.to
bd(es.doc,er,er)
es.state.draggingText&&aw(es.doc,"",et,ep,"paste")
es.replaceSelection(eu,null,"paste")
c2(es)
bL(es)}}catch(eq){}}}}function F(el,en){if(ct&&(!el.state.draggingText||+new Date-M<100))cT(en)
else if(!ao(el,en)&&!aB(el.display,en)){var ek=el.getSelection()
en.dataTransfer.setData("Text",ek)
if(en.dataTransfer.setDragImage&&!ad){var em=d7("img",null,null,"position: fixed; left: 0; top: 0;")
em.src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
if(dP){em.width=em.height=1
el.display.wrapper.appendChild(em)
em._top=em.offsetTop}en.dataTransfer.setDragImage(em,0,0)
dP&&em.parentNode.removeChild(em)}}}function C(ek,el){if(!(Math.abs(ek.doc.scrollTop-el)<2)){ek.doc.scrollTop=el
bB||cu(ek,[],el)
ek.display.scroller.scrollTop!=el&&(ek.display.scroller.scrollTop=el)
ek.display.scrollbarV.scrollTop!=el&&(ek.display.scrollbarV.scrollTop=el)
bB&&cu(ek,[])
cM(ek,100)}}function aZ(ek,em,el){if(!(el?em==ek.doc.scrollLeft:Math.abs(ek.doc.scrollLeft-em)<2)){em=Math.min(em,ek.display.scroller.scrollWidth-ek.display.scroller.clientWidth)
ek.doc.scrollLeft=em
c6(ek)
ek.display.scroller.scrollLeft!=em&&(ek.display.scroller.scrollLeft=em)
ek.display.scrollbarH.scrollLeft!=em&&(ek.display.scrollbarH.scrollLeft=em)}}function b(eq,el){var et=el.wheelDeltaX,es=el.wheelDeltaY
null==et&&el.detail&&el.axis==el.HORIZONTAL_AXIS&&(et=el.detail)
null==es&&el.detail&&el.axis==el.VERTICAL_AXIS?es=el.detail:null==es&&(es=el.wheelDelta)
var en=eq.display,ep=en.scroller
if(et&&ep.scrollWidth>ep.clientWidth||es&&ep.scrollHeight>ep.clientHeight){if(es&&bk&&b1)for(var er=el.target;er!=ep;er=er.parentNode)if(er.lineObj){eq.display.currentWheelTarget=er
break}if(!et||bB||dP||null==bt){if(es&&null!=bt){var ek=es*bt,eo=eq.doc.scrollTop,em=eo+en.wrapper.clientHeight
0>ek?eo=Math.max(0,eo+ek-50):em=Math.min(eq.doc.height,em+ek+50)
cu(eq,[],{top:eo,bottom:em})}if(20>dE)if(null==en.wheelStartX){en.wheelStartX=ep.scrollLeft
en.wheelStartY=ep.scrollTop
en.wheelDX=et
en.wheelDY=es
setTimeout(function(){if(null!=en.wheelStartX){var eu=ep.scrollLeft-en.wheelStartX,ew=ep.scrollTop-en.wheelStartY,ev=ew&&en.wheelDY&&ew/en.wheelDY||eu&&en.wheelDX&&eu/en.wheelDX
en.wheelStartX=en.wheelStartY=null
if(ev){bt=(bt*dE+ev)/(dE+1);++dE}}},200)}else{en.wheelDX+=et
en.wheelDY+=es}}else{es&&C(eq,Math.max(0,Math.min(ep.scrollTop+es*bt,ep.scrollHeight-ep.clientHeight)))
aZ(eq,Math.max(0,Math.min(ep.scrollLeft+et*bt,ep.scrollWidth-ep.clientWidth)))
bO(el)
en.wheelStartX=null}}}function d3(el,eo,ek){if("string"==typeof eo){eo=c4[eo]
if(!eo)return!1}el.display.pollingFast&&bu(el)&&(el.display.pollingFast=!1)
var ep=el.doc,en=ep.sel.shift,em=!1
try{P(el)&&(el.state.suppressEdits=!0)
ek&&(ep.sel.shift=!1)
em=eo(el)!=bp}finally{ep.sel.shift=en
el.state.suppressEdits=!1}return em}function ck(ek){var el=ek.state.keyMaps.slice(0)
ek.options.extraKeys&&el.push(ek.options.extraKeys)
el.push(ek.options.keyMap)
return el}function dB(ek,eq){var el=d5(ek.options.keyMap),eo=el.auto
clearTimeout(W)
eo&&!c3(eq)&&(W=setTimeout(function(){if(d5(ek.options.keyMap)==el){ek.options.keyMap=eo.call?eo.call(null,ek):eo
eh(ek)}},50))
var en=dK(eq,!0),ep=!1
if(!en)return!1
var em=ck(ek)
ep=eq.shiftKey?g("Shift-"+en,em,function(er){return d3(ek,er,!0)})||g(en,em,function(er){return("string"==typeof er?/^go[A-Z]/.test(er):er.motion)?d3(ek,er):void 0}):g(en,em,function(er){return d3(ek,er)})
if(ep){bO(eq)
k(ek)
if(bx){eq.oldKeyCode=eq.keyCode
eq.keyCode=0}L(ek,"keyHandled",ek,en,eq)}return ep}function cP(ek,en,el){var em=g("'"+el+"'",ck(ek),function(eo){return d3(ek,eo,!0)})
if(em){bO(en)
k(ek)
L(ek,"keyHandled",ek,"'"+el+"'",en)}return em}function l(en){var ek=this
ek.state.focused||bL(ek)
if(!(ao(ek,en)||ek.options.onKeyEvent&&ek.options.onKeyEvent(ek,V(en)))){ct&&27==en.keyCode&&(en.returnValue=!1)
var el=en.keyCode
ek.doc.sel.shift=16==el||en.shiftKey
var em=dB(ek,en)
if(dP){cf=em?el:null
!em&&88==el&&!b8&&(bk?en.metaKey:en.ctrlKey)&&ek.replaceSelection("")}}}function bI(eo){var ek=this
if(!(ao(ek,eo)||ek.options.onKeyEvent&&ek.options.onKeyEvent(ek,V(eo)))){var en=eo.keyCode,el=eo.charCode
if(dP&&en==cf){cf=null
bO(eo)}else if(!(dP&&(!eo.which||eo.which<10)||aC)||!dB(ek,eo)){var em=String.fromCharCode(null==el?en:el)
this.options.electricChars&&this.doc.mode.electricChars&&this.options.smartIndent&&!P(this)&&this.doc.mode.electricChars.indexOf(em)>-1&&setTimeout(b2(ek,function(){K(ek,ek.doc.sel.to.line,"smart")}),75)
if(!cP(ek,eo,em)){ct&&!bx&&(ek.display.inputHasSelection=null)
t(ek)}}}}function bL(ek){if("nocursor"!=ek.options.readOnly){if(!ek.state.focused){ae(ek,"focus",ek)
ek.state.focused=!0;-1==ek.display.wrapper.className.search(/\bCodeMirror-focused\b/)&&(ek.display.wrapper.className+=" CodeMirror-focused")
if(!ek.curOp){dI(ek,!0)
b1&&setTimeout(bH(dI,ek,!0),0)}}aM(ek)
k(ek)}}function aq(ek){if(ek.state.focused){ae(ek,"blur",ek)
ek.state.focused=!1
ek.display.wrapper.className=ek.display.wrapper.className.replace(" CodeMirror-focused","")}clearInterval(ek.display.blinker)
setTimeout(function(){ek.state.focused||(ek.doc.sel.shift=!1)},150)}function aa(et,eo){function en(){if(null!=eq.input.selectionStart){var eu=eq.input.value="​"+(dW(el.from,el.to)?"":eq.input.value)
eq.prevInput="​"
eq.input.selectionStart=1
eq.input.selectionEnd=eu.length}}function er(){eq.inputDiv.style.position="relative"
eq.input.style.cssText=ep
bx&&(eq.scrollbarV.scrollTop=eq.scroller.scrollTop=ek)
aM(et)
if(null!=eq.input.selectionStart){(!ct||bx)&&en()
clearTimeout(dT)
var eu=0,ev=function(){" "==eq.prevInput&&0==eq.input.selectionStart?b2(et,c4.selectAll)(et):eu++<10?dT=setTimeout(ev,500):dI(et)}
dT=setTimeout(ev,200)}}if(!ao(et,eo,"contextmenu")){var eq=et.display,el=et.doc.sel
if(!aB(eq,eo)&&!cd(et,eo)){var es=bA(et,eo),ek=eq.scroller.scrollTop
if(es&&!dP){(dW(el.from,el.to)||dy(es,el.from)||!dy(es,el.to))&&b2(et,bd)(et.doc,es,es)
var ep=eq.input.style.cssText
eq.inputDiv.style.position="absolute"
eq.input.style.cssText="position: fixed; width: 30px; height: 30px; top: "+(eo.clientY-5)+"px; left: "+(eo.clientX-5)+"px; z-index: 1000; background: white; outline: none;border-width: 0; outline: none; overflow: hidden; opacity: .05; -ms-opacity: .05; filter: alpha(opacity=5);"
c2(et)
dI(et,!0)
dW(el.from,el.to)&&(eq.input.value=eq.prevInput=" ")
ct&&!bx&&en()
if(bQ){cT(eo)
var em=function(){cL(window,"mouseup",em)
setTimeout(er,20)}
bf(window,"mouseup",em)}else setTimeout(er,50)}}}}function c5(eo,eq,ep){if(!dy(eq.from,ep))return dX(eo,ep)
var en=eq.text.length-1-(eq.to.line-eq.from.line)
if(ep.line>eq.to.line+en){var em=ep.line-en,el=eo.first+eo.size-1
return em>el?H(el,dx(eo,el).text.length):dL(ep,dx(eo,em).text.length)}if(ep.line==eq.to.line+en)return dL(ep,dV(eq.text).length+(1==eq.text.length?eq.from.ch:0)+dx(eo,eq.to.line).text.length-eq.to.ch)
var ek=ep.line-eq.from.line
return dL(ep,eq.text[ek].length+(ek?0:eq.from.ch))}function dC(el,eo,em){if(em&&"object"==typeof em)return{anchor:c5(el,eo,em.anchor),head:c5(el,eo,em.head)}
if("start"==em)return{anchor:eo.from,head:eo.from}
var ek=bY(eo)
if("around"==em)return{anchor:eo.from,head:ek}
if("end"==em)return{anchor:ek,head:ek}
var en=function(er){if(dy(er,eo.from))return er
if(!dy(eo.to,er))return ek
var ep=er.line+eo.text.length-(eo.to.line-eo.from.line)-1,eq=er.ch
er.line==eo.to.line&&(eq+=ek.ch-eo.to.ch)
return H(ep,eq)}
return{anchor:en(el.sel.anchor),head:en(el.sel.head)}}function cy(el,en,em){var ek={canceled:!1,from:en.from,to:en.to,text:en.text,origin:en.origin,cancel:function(){this.canceled=!0}}
em&&(ek.update=function(er,eq,ep,eo){er&&(this.from=dX(el,er))
eq&&(this.to=dX(el,eq))
ep&&(this.text=ep)
void 0!==eo&&(this.origin=eo)})
ae(el,"beforeChange",el,ek)
el.cm&&ae(el.cm,"beforeChange",el.cm,ek)
return ek.canceled?null:{from:ek.from,to:ek.to,text:ek.text,origin:ek.origin}}function aG(en,ep,eo,em){if(en.cm){if(!en.cm.curOp)return b2(en.cm,aG)(en,ep,eo,em)
if(en.cm.state.suppressEdits)return}if(dD(en,"beforeChange")||en.cm&&dD(en.cm,"beforeChange")){ep=cy(en,ep,!0)
if(!ep)return}var el=ee&&!em&&bP(en,ep.from,ep.to)
if(el){for(var ek=el.length-1;ek>=1;--ek)am(en,{from:el[ek].from,to:el[ek].to,text:[""]})
el.length&&am(en,{from:el[0].from,to:el[0].to,text:ep.text},eo)}else am(en,ep,eo)}function am(em,eo,en){if(1!=eo.text.length||""!=eo.text[0]||!dW(eo.from,eo.to)){var el=dC(em,eo,en)
c9(em,eo,el,em.cm?em.cm.curOp.id:0/0)
cK(em,eo,el,cQ(em,eo))
var ek=[]
cF(em,function(eq,ep){if(!ep&&-1==ce(ek,eq.history)){cs(eq.history,eo)
ek.push(eq.history)}cK(eq,eo,null,cQ(eq,eo))})}}function bm(et,eq){if(!et.cm||!et.cm.state.suppressEdits){var ep=et.history,el=("undo"==eq?ep.done:ep.undone).pop()
if(el){var er={changes:[],anchorBefore:el.anchorAfter,headBefore:el.headAfter,anchorAfter:el.anchorBefore,headAfter:el.headBefore,generation:ep.generation};("undo"==eq?ep.undone:ep.done).push(er)
ep.generation=el.generation||++ep.maxGeneration
for(var em=dD(et,"beforeChange")||et.cm&&dD(et.cm,"beforeChange"),en=el.changes.length-1;en>=0;--en){var es=el.changes[en]
es.origin=eq
if(em&&!cy(et,es,!1)){("undo"==eq?ep.done:ep.undone).length=0
return}er.changes.push(cl(et,es))
var ek=en?dC(et,es,null):{anchor:el.anchorBefore,head:el.headBefore}
cK(et,es,ek,cH(et,es))
var eo=[]
cF(et,function(ev,eu){if(!eu&&-1==ce(eo,ev.history)){cs(ev.history,es)
eo.push(ev.history)}cK(ev,es,null,cH(ev,es))})}}}}function dF(ek,em){function el(en){return H(en.line+em,en.ch)}ek.first+=em
ek.cm&&N(ek.cm,ek.first,ek.first,em)
ek.sel.head=el(ek.sel.head)
ek.sel.anchor=el(ek.sel.anchor)
ek.sel.from=el(ek.sel.from)
ek.sel.to=el(ek.sel.to)}function cK(eo,ep,en,el){if(eo.cm&&!eo.cm.curOp)return b2(eo.cm,cK)(eo,ep,en,el)
if(ep.to.line<eo.first)dF(eo,ep.text.length-1-(ep.to.line-ep.from.line))
else if(!(ep.from.line>eo.lastLine())){if(ep.from.line<eo.first){var ek=ep.text.length-1-(eo.first-ep.from.line)
dF(eo,ek)
ep={from:H(eo.first,0),to:H(ep.to.line+ek,ep.to.ch),text:[dV(ep.text)],origin:ep.origin}}var em=eo.lastLine()
ep.to.line>em&&(ep={from:ep.from,to:H(em,dx(eo,em).text.length),text:[ep.text[0]],origin:ep.origin})
ep.removed=d9(eo,ep.from,ep.to)
en||(en=dC(eo,ep,null))
eo.cm?ai(eo.cm,ep,el,en):dQ(eo,ep,el,en)}}function ai(eu,eq,en,ek){var et=eu.doc,ep=eu.display,er=eq.from,es=eq.to,el=!1,em=er.line
if(!eu.options.lineWrapping){em=a8(s(et,dx(et,er.line)))
et.iter(em,es.line+1,function(ex){if(ex==ep.maxLine){el=!0
return!0}})}dy(et.sel.head,eq.from)||dy(eq.to,et.sel.head)||(eu.curOp.cursorActivity=!0)
dQ(et,eq,en,ek,aE(eu))
if(!eu.options.lineWrapping){et.iter(em,er.line+eq.text.length,function(ey){var ex=cR(et,ey)
if(ex>ep.maxLineLength){ep.maxLine=ey
ep.maxLineLength=ex
ep.maxLineChanged=!0
el=!1}})
el&&(eu.curOp.updateMaxLine=!0)}et.frontier=Math.min(et.frontier,er.line)
cM(eu,400)
var ew=eq.text.length-(es.line-er.line)-1
N(eu,er.line,es.line+1,ew)
if(dD(eu,"change")){var eo={from:er,to:es,text:eq.text,removed:eq.removed,origin:eq.origin}
if(eu.curOp.textChanged){for(var ev=eu.curOp.textChanged;ev.next;ev=ev.next);ev.next=eo}else eu.curOp.textChanged=eo}}function aw(en,em,ep,eo,ek){eo||(eo=ep)
if(dy(eo,ep)){var el=eo
eo=ep
ep=el}"string"==typeof em&&(em=av(em))
aG(en,{from:ep,to:eo,text:em,origin:ek},null)}function H(ek,el){if(!(this instanceof H))return new H(ek,el)
this.line=ek
this.ch=el}function dW(el,ek){return el.line==ek.line&&el.ch==ek.ch}function dy(el,ek){return el.line<ek.line||el.line==ek.line&&el.ch<ek.ch}function bv(ek){return H(ek.line,ek.ch)}function b4(ek,el){return Math.max(ek.first,Math.min(el,ek.first+ek.size-1))}function dX(el,em){if(em.line<el.first)return H(el.first,0)
var ek=el.first+el.size-1
return em.line>ek?H(ek,dx(el,ek).text.length):dL(em,dx(el,em.line).text.length)}function dL(em,el){var ek=em.ch
return null==ek||ek>el?H(em.line,el):0>ek?H(em.line,0):em}function bn(el,ek){return ek>=el.first&&ek<el.first+el.size}function d4(eo,ep,ek,el){if(eo.sel.shift||eo.sel.extend){var en=eo.sel.anchor
if(ek){var em=dy(ep,en)
if(em!=dy(ek,en)){en=ep
ep=ek}else em!=dy(ep,ek)&&(ep=ek)}bd(eo,en,ep,el)}else bd(eo,ep,ek||ep,el)
eo.cm&&(eo.cm.curOp.userSelChange=!0)}function c(en,ek,el){var em={anchor:ek,head:el}
ae(en,"beforeSelectionChange",en,em)
en.cm&&ae(en.cm,"beforeSelectionChange",en.cm,em)
em.anchor=dX(en,em.anchor)
em.head=dX(en,em.head)
return em}function bd(er,eo,ep,em,el){if(!el&&dD(er,"beforeSelectionChange")||er.cm&&dD(er.cm,"beforeSelectionChange")){var en=c(er,eo,ep)
ep=en.head
eo=en.anchor}var eq=er.sel
eq.goalColumn=null
null==em&&(em=dy(ep,eq.head)?-1:1);(el||!dW(eo,eq.anchor))&&(eo=be(er,eo,em,"push"!=el));(el||!dW(ep,eq.head))&&(ep=be(er,ep,em,"push"!=el))
if(!dW(eq.anchor,eo)||!dW(eq.head,ep)){eq.anchor=eo
eq.head=ep
var ek=dy(ep,eo)
eq.from=ek?ep:eo
eq.to=ek?eo:ep
er.cm&&(er.cm.curOp.updateInput=er.cm.curOp.selectionChanged=er.cm.curOp.cursorActivity=!0)
L(er,"cursorActivity",er)}}function cY(ek){bd(ek.doc,ek.doc.sel.from,ek.doc.sel.to,null,"push")}function be(et,es,ep,eq){var eu=!1,em=es,en=ep||1
et.cantEdit=!1
search:for(;;){var ev=dx(et,em.line)
if(ev.markedSpans)for(var eo=0;eo<ev.markedSpans.length;++eo){var ek=ev.markedSpans[eo],el=ek.marker
if((null==ek.from||(el.inclusiveLeft?ek.from<=em.ch:ek.from<em.ch))&&(null==ek.to||(el.inclusiveRight?ek.to>=em.ch:ek.to>em.ch))){if(eq){ae(el,"beforeCursorEnter")
if(el.explicitlyCleared){if(ev.markedSpans){--eo
continue}break}}if(!el.atomic)continue
var er=el.find()[0>en?"from":"to"]
if(dW(er,em)){er.ch+=en
er.ch<0?er=er.line>et.first?dX(et,H(er.line-1)):null:er.ch>ev.text.length&&(er=er.line<et.first+et.size-1?H(er.line+1,0):null)
if(!er){if(eu){if(!eq)return be(et,es,ep,!0)
et.cantEdit=!0
return H(et.first,0)}eu=!0
er=es
en=-en}}em=er
continue search}}return em}}function ab(el){var eo=u(el,el.doc.sel.head,el.options.cursorScrollMargin)
if(el.state.focused){var ep=el.display,em=ak(ep.sizer),ek=null
eo.top+em.top<0?ek=!0:eo.bottom+em.top>(window.innerHeight||document.documentElement.clientHeight)&&(ek=!1)
if(null!=ek&&!dM){var en="none"==ep.cursor.style.display
if(en){ep.cursor.style.display=""
ep.cursor.style.left=eo.left+"px"
ep.cursor.style.top=eo.top-ep.viewOffset+"px"}ep.cursor.scrollIntoView(ek)
en&&(ep.cursor.style.display="none")}}}function u(ek,er,eo){null==eo&&(eo=0)
for(;;){var ep=!1,en=cz(ek,er),eq=x(ek,en.left,en.top-eo,en.left,en.bottom+eo),el=ek.doc.scrollTop,em=ek.doc.scrollLeft
if(null!=eq.scrollTop){C(ek,eq.scrollTop)
Math.abs(ek.doc.scrollTop-el)>1&&(ep=!0)}if(null!=eq.scrollLeft){aZ(ek,eq.scrollLeft)
Math.abs(ek.doc.scrollLeft-em)>1&&(ep=!0)}if(!ep)return en}}function w(ek,em,eo,el,en){var ep=x(ek,em,eo,el,en)
null!=ep.scrollTop&&C(ek,ep.scrollTop)
null!=ep.scrollLeft&&aZ(ek,ep.scrollLeft)}function x(eq,ey,en,ex,em){var ev=eq.display,eu=at(eq.display)
0>en&&(en=0)
var el=ev.scroller.clientHeight-aJ,et=ev.scroller.scrollTop,es={},eA=eq.doc.height+a3(ev),eB=eu>en,ew=em>eA-eu
if(et>en)es.scrollTop=eB?0:en
else if(em>et+el){var er=Math.min(en,(ew?eA:em)-el)
er!=et&&(es.scrollTop=er)}var ep=ev.scroller.clientWidth-aJ,ek=ev.scroller.scrollLeft
ey+=ev.gutters.offsetWidth
ex+=ev.gutters.offsetWidth
var eo=ev.gutters.offsetWidth,ez=eo+10>ey
if(ek+eo>ey||ez){ez&&(ey=0)
es.scrollLeft=Math.max(0,ey-10-eo)}else ex>ep+ek-3&&(es.scrollLeft=ex+10-ep)
return es}function v(ek,em,el){ek.curOp.updateScrollPos={scrollLeft:null==em?ek.doc.scrollLeft:em,scrollTop:null==el?ek.doc.scrollTop:el}}function bT(el,en,em){var eo=el.curOp.updateScrollPos||(el.curOp.updateScrollPos={scrollLeft:el.doc.scrollLeft,scrollTop:el.doc.scrollTop}),ek=el.display.scroller
eo.scrollTop=Math.max(0,Math.min(ek.scrollHeight-ek.clientHeight,eo.scrollTop+em))
eo.scrollLeft=Math.max(0,Math.min(ek.scrollWidth-ek.clientWidth,eo.scrollLeft+en))}function K(ew,en,ev,em){var eu=ew.doc
null==ev&&(ev="add")
if("smart"==ev)if(ew.doc.mode.indent)var el=cp(ew,en)
else ev="prev"
var es,eq=ew.options.tabSize,ex=dx(eu,en),ep=bb(ex.text,null,eq),ek=ex.text.match(/^\s*/)[0]
if("smart"==ev){es=ew.doc.mode.indent(el,ex.text.slice(ek.length),ex.text)
if(es==bp){if(!em)return
ev="prev"}}"prev"==ev?es=en>eu.first?bb(dx(eu,en-1).text,null,eq):0:"add"==ev?es=ep+ew.options.indentUnit:"subtract"==ev?es=ep-ew.options.indentUnit:"number"==typeof ev&&(es=ep+ev)
es=Math.max(0,es)
var et="",er=0
if(ew.options.indentWithTabs)for(var eo=Math.floor(es/eq);eo;--eo){er+=eq
et+="	"}es>er&&(et+=bC(es-er))
et!=ek&&aw(ew.doc,et,H(en,0),H(en,ek.length),"+input")
ex.stateAfter=null}function c0(ek,em,ep){var eo=em,el=em,en=ek.doc
"number"==typeof em?el=dx(en,b4(en,em)):eo=a8(em)
if(null==eo)return null
if(!ep(el,eo))return null
N(ek,eo,eo+1)
return el}function aU(eB,en,ev,eu,ep){function ez(){var eC=es+ev
if(eC<eB.first||eC>=eB.first+eB.size)return ey=!1
es=eC
return ek=dx(eB,eC)}function ex(eD){var eC=(ep?p:O)(ek,et,ev,!0)
if(null==eC){if(eD||!ez())return ey=!1
et=ep?(0>ev?bX:bN)(ek):0>ev?ek.text.length:0}else et=eC
return!0}var es=en.line,et=en.ch,eA=ev,ek=dx(eB,es),ey=!0
if("char"==eu)ex()
else if("column"==eu)ex(!0)
else if("word"==eu||"group"==eu)for(var ew=null,eq="group"==eu,eo=!0;!(0>ev)||ex(!eo);eo=!1){var el=ek.text.charAt(et)||"\n",em=bK(el)?"w":eq?/\s/.test(el)?null:"p":null
if(ew&&ew!=em){if(0>ev){ev=1
ex()}break}em&&(ew=em)
if(ev>0&&!ex(!eo))break}var er=be(eB,H(es,et),eA,!0)
ey||(er.hitSide=!0)
return er}function aQ(es,en,ek,er){var eo,eq=es.doc,ep=en.left
if("page"==er){var em=Math.min(es.display.wrapper.clientHeight,window.innerHeight||document.documentElement.clientHeight)
eo=en.top+ek*(em-(0>ek?1.5:.5)*at(es.display))}else"line"==er&&(eo=ek>0?en.bottom+3:en.top-3)
for(;;){var el=d1(es,ep,eo)
if(!el.outside)break
if(0>ek?0>=eo:eo>=eq.height){el.hitSide=!0
break}eo+=5*ek}return el}function Y(en,ep){var eo=ep.ch,em=ep.ch
if(en){(ep.xRel<0||em==en.length)&&eo?--eo:++em
for(var el=en.charAt(eo),ek=bK(el)?bK:/\s/.test(el)?function(eq){return/\s/.test(eq)}:function(eq){return!/\s/.test(eq)&&!bK(eq)};eo>0&&ek(en.charAt(eo-1));)--eo
for(;em<en.length&&ek(en.charAt(em));)++em}return{from:H(ep.line,eo),to:H(ep.line,em)}}function aL(ek,el){d4(ek.doc,H(el,0),dX(ek.doc,H(el+1,0)))}function n(ek,en,em,el){y.defaults[ek]=en
em&&(aF[ek]=el?function(eo,eq,ep){ep!=bq&&em(eo,eq,ep)}:em)}function bi(en,ek){if(ek===!0)return ek
if(en.copyState)return en.copyState(ek)
var em={}
for(var eo in ek){var el=ek[eo]
el instanceof Array&&(el=el.concat([]))
em[eo]=el}return em}function bh(em,el,ek){return em.startState?em.startState(el,ek):!0}function d5(ek){return"string"==typeof ek?du[ek]:ek}function g(el,ep,en){function eo(ev){ev=d5(ev)
var et=ev[el]
if(et===!1)return"stop"
if(null!=et&&en(et))return!0
if(ev.nofallthrough)return"stop"
var es=ev.fallthrough
if(null==es)return!1
if("[object Array]"!=Object.prototype.toString.call(es))return eo(es)
for(var er=0,eu=es.length;eu>er;++er){var eq=eo(es[er])
if(eq)return eq}return!1}for(var em=0;em<ep.length;++em){var ek=eo(ep[em])
if(ek)return"stop"!=ek}}function c3(el){var ek=dz[el.keyCode]
return"Ctrl"==ek||"Alt"==ek||"Shift"==ek||"Mod"==ek}function dK(el,em){if(dP&&34==el.keyCode&&el["char"])return!1
var ek=dz[el.keyCode]
if(null==ek||el.altGraphKey)return!1
el.altKey&&(ek="Alt-"+ek);(ba?el.metaKey:el.ctrlKey)&&(ek="Ctrl-"+ek);(ba?el.ctrlKey:el.metaKey)&&(ek="Cmd-"+ek)
!em&&el.shiftKey&&(ek="Shift-"+ek)
return ek}function dh(ek,el){this.pos=this.start=0
this.string=ek
this.tabSize=el||8
this.lastColumnPos=this.lastColumnValue=0}function E(el,ek){this.lines=[]
this.type=ek
this.doc=el}function c8(et,er,es,ev,ep){if(ev&&ev.shared)return D(et,er,es,ev,ep)
if(et.cm&&!et.cm.curOp)return b2(et.cm,c8)(et,er,es,ev,ep)
var eo=new E(et,ep)
if("range"==ep&&!dy(er,es))return eo
ev&&aj(ev,eo)
if(eo.replacedWith){eo.collapsed=!0
eo.replacedWith=d7("span",[eo.replacedWith],"CodeMirror-widget")
ev.handleMouseEvents||(eo.replacedWith.ignoreEvents=!0)}eo.collapsed&&(ay=!0)
eo.addToHistory&&c9(et,{from:er,to:es,origin:"markText"},{head:et.sel.head,anchor:et.sel.anchor},0/0)
var en,em,ek,el=er.line,eu=0,eq=et.cm
et.iter(el,es.line+1,function(ew){eq&&eo.collapsed&&!eq.options.lineWrapping&&s(et,ew)==eq.display.maxLine&&(ek=!0)
var ex={from:null,to:null,marker:eo}
eu+=ew.text.length
if(el==er.line){ex.from=er.ch
eu-=er.ch}if(el==es.line){ex.to=es.ch
eu-=ew.text.length-es.ch}if(eo.collapsed){el==es.line&&(em=aW(ew,es.ch))
el==er.line?en=aW(ew,er.ch):ec(ew,0)}br(ew,ex);++el})
eo.collapsed&&et.iter(er.line,es.line+1,function(ew){dN(et,ew)&&ec(ew,0)})
eo.clearOnEnter&&bf(eo,"beforeCursorEnter",function(){eo.clear()})
if(eo.readOnly){ee=!0;(et.history.done.length||et.history.undone.length)&&et.clearHistory()}if(eo.collapsed){if(en!=em)throw new Error("Inserting collapsed marker overlapping an existing one")
eo.size=eu
eo.atomic=!0}if(eq){ek&&(eq.curOp.updateMaxLine=!0);(eo.className||eo.title||eo.startStyle||eo.endStyle||eo.collapsed)&&N(eq,er.line,es.line+1)
eo.atomic&&cY(eq)}return eo}function r(en,el){this.markers=en
this.primary=el
for(var ek=0,em=this;ek<en.length;++ek){en[ek].parent=this
bf(en[ek],"clear",function(){em.clear()})}}function D(eo,er,eq,ek,em){ek=aj(ek)
ek.shared=!1
var ep=[c8(eo,er,eq,ek,em)],el=ep[0],en=ek.replacedWith
cF(eo,function(et){en&&(ek.replacedWith=en.cloneNode(!0))
ep.push(c8(et,dX(et,er),dX(et,eq),ek,em))
for(var es=0;es<et.linked.length;++es)if(et.linked[es].isParent)return
el=dV(ep)})
return new r(ep,el)}function dt(em,ek){if(em)for(var el=0;el<em.length;++el){var en=em[el]
if(en.marker==ek)return en}}function db(el,em){for(var en,ek=0;ek<el.length;++ek)el[ek]!=em&&(en||(en=[])).push(el[ek])
return en}function br(ek,el){ek.markedSpans=ek.markedSpans?ek.markedSpans.concat([el]):[el]
el.marker.attachLine(ek)}function an(el,em,eq){if(el)for(var er,eo=0;eo<el.length;++eo){var es=el[eo],ep=es.marker,ek=null==es.from||(ep.inclusiveLeft?es.from<=em:es.from<em)
if(ek||"bookmark"==ep.type&&es.from==em&&(!eq||!es.marker.insertLeft)){var en=null==es.to||(ep.inclusiveRight?es.to>=em:es.to>em);(er||(er=[])).push({from:es.from,to:en?null:es.to,marker:ep})}}return er}function ac(el,en,eq){if(el)for(var er,eo=0;eo<el.length;++eo){var es=el[eo],ep=es.marker,em=null==es.to||(ep.inclusiveRight?es.to>=en:es.to>en)
if(em||"bookmark"==ep.type&&es.from==en&&(!eq||es.marker.insertLeft)){var ek=null==es.from||(ep.inclusiveLeft?es.from<=en:es.from<en);(er||(er=[])).push({from:ek?null:es.from-en,to:null==es.to?null:es.to-en,marker:ep})}}return er}function cQ(ew,et){var es=bn(ew,et.from.line)&&dx(ew,et.from.line).markedSpans,ez=bn(ew,et.to.line)&&dx(ew,et.to.line).markedSpans
if(!es&&!ez)return null
var el=et.from.ch,eo=et.to.ch,er=dW(et.from,et.to),eq=an(es,el,er),ey=ac(ez,eo,er),ex=1==et.text.length,em=dV(et.text).length+(ex?el:0)
if(eq)for(var en=0;en<eq.length;++en){var ev=eq[en]
if(null==ev.to){var eA=dt(ey,ev.marker)
eA?ex&&(ev.to=null==eA.to?null:eA.to+em):ev.to=el}}if(ey)for(var en=0;en<ey.length;++en){var ev=ey[en]
null!=ev.to&&(ev.to+=em)
if(null==ev.from){var eA=dt(eq,ev.marker)
if(!eA){ev.from=em
ex&&(eq||(eq=[])).push(ev)}}else{ev.from+=em
ex&&(eq||(eq=[])).push(ev)}}if(ex&&eq){for(var en=0;en<eq.length;++en)null!=eq[en].from&&eq[en].from==eq[en].to&&"bookmark"!=eq[en].marker.type&&eq.splice(en--,1)
eq.length||(eq=null)}var ep=[eq]
if(!ex){var ek,eu=et.text.length-2
if(eu>0&&eq)for(var en=0;en<eq.length;++en)null==eq[en].to&&(ek||(ek=[])).push({from:null,to:null,marker:eq[en].marker})
for(var en=0;eu>en;++en)ep.push(ek)
ep.push(ey)}return ep}function cH(es,eq){var ek=bl(es,eq),et=cQ(es,eq)
if(!ek)return et
if(!et)return ek
for(var en=0;en<ek.length;++en){var eo=ek[en],ep=et[en]
if(eo&&ep)spans:for(var em=0;em<ep.length;++em){for(var er=ep[em],el=0;el<eo.length;++el)if(eo[el].marker==er.marker)continue spans
eo.push(er)}else ep&&(ek[en]=ep)}return ek}function bP(eu,es,et){var en=null
eu.iter(es.line,et.line+1,function(ev){if(ev.markedSpans)for(var ew=0;ew<ev.markedSpans.length;++ew){var ex=ev.markedSpans[ew].marker
!ex.readOnly||en&&-1!=ce(en,ex)||(en||(en=[])).push(ex)}})
if(!en)return null
for(var eo=[{from:es,to:et}],ep=0;ep<en.length;++ep)for(var eq=en[ep],el=eq.find(),em=0;em<eo.length;++em){var ek=eo[em]
if(!dy(ek.to,el.from)&&!dy(el.to,ek.from)){var er=[em,1];(dy(ek.from,el.from)||!eq.inclusiveLeft&&dW(ek.from,el.from))&&er.push({from:ek.from,to:el.from});(dy(el.to,ek.to)||!eq.inclusiveRight&&dW(ek.to,el.to))&&er.push({from:el.to,to:ek.to})
eo.splice.apply(eo,er)
em+=er.length-1}}return eo}function aW(el,en){var ep,ek=ay&&el.markedSpans
if(ek)for(var eo,em=0;em<ek.length;++em){eo=ek[em]
eo.marker.collapsed&&(null==eo.from||eo.from<en)&&(null==eo.to||eo.to>en)&&(!ep||ep.width<eo.marker.width)&&(ep=eo.marker)}return ep}function dd(ek){return aW(ek,-1)}function cW(ek){return aW(ek,ek.text.length+1)}function s(em,el){for(var ek;ek=dd(el);)el=dx(em,ek.find().from.line)
return el}function dN(eo,el){var ek=ay&&el.markedSpans
if(ek)for(var en,em=0;em<ek.length;++em){en=ek[em]
if(en.marker.collapsed){if(null==en.from)return!0
if(!en.marker.replacedWith&&0==en.from&&en.marker.inclusiveLeft&&G(eo,el,en))return!0}}}function G(eq,el,en){if(null==en.to){var ek=en.marker.find().to,eo=dx(eq,ek.line)
return G(eq,eo,dt(eo.markedSpans,en.marker))}if(en.marker.inclusiveRight&&en.to==el.text.length)return!0
for(var ep,em=0;em<el.markedSpans.length;++em){ep=el.markedSpans[em]
if(ep.marker.collapsed&&!ep.marker.replacedWith&&ep.from==en.to&&(ep.marker.inclusiveLeft||en.marker.inclusiveRight)&&G(eq,el,ep))return!0}}function ed(ek){var em=ek.markedSpans
if(em){for(var el=0;el<em.length;++el)em[el].marker.detachLine(ek)
ek.markedSpans=null}}function b3(ek,em){if(em){for(var el=0;el<em.length;++el)em[el].marker.attachLine(ek)
ek.markedSpans=em}}function B(ek){return function(){var em=!this.cm.curOp
em&&bR(this.cm)
try{var el=ek.apply(this,arguments)}finally{em&&T(this.cm)}return el}}function bZ(ek){if(null!=ek.height)return ek.height
ek.node.parentNode&&1==ek.node.parentNode.nodeType||bc(ek.cm.display.measure,d7("div",[ek.node],null,"position: relative"))
return ek.height=ek.node.offsetHeight}function a2(ek,eo,em,el){var en=new cq(ek,em,el)
en.noHScroll&&(ek.display.alignWidgets=!0)
c0(ek,eo,function(eq){var er=eq.widgets||(eq.widgets=[])
null==en.insertAt?er.push(en):er.splice(Math.min(er.length-1,Math.max(0,en.insertAt)),0,en)
en.line=eq
if(!dN(ek.doc,eq)||en.showIfHidden){var ep=a7(ek,eq)<ek.doc.scrollTop
ec(eq,eq.height+bZ(en))
ep&&bT(ek,0,en.height)}return!0})
return en}function cS(el,eo,em,ek){el.text=eo
el.stateAfter&&(el.stateAfter=null)
el.styles&&(el.styles=null)
null!=el.order&&(el.order=null)
ed(el)
b3(el,em)
var en=ek?ek(el):1
en!=el.height&&ec(el,en)}function aX(ek){ek.parent=null
ed(ek)}function q(es,eu,en,el,eo){var em=en.flattenSpans
null==em&&(em=es.options.flattenSpans)
var ek,eq=0,ep=null,et=new dh(eu,es.options.tabSize)
""==eu&&en.blankLine&&en.blankLine(el)
for(;!et.eol();){if(et.pos>es.options.maxHighlightLength){em=!1
et.pos=eu.length
ek=null}else ek=en.token(et,el)
if(!em||ep!=ek){eq<et.start&&eo(et.start,ep)
eq=et.start
ep=ek}et.start=et.pos}for(;eq<et.pos;){var er=Math.min(et.pos,eq+5e4)
eo(er,ep)
eq=er}}function dS(el,em,eq){var eo=[el.state.modeGen]
q(el,em.text,el.doc.mode,eq,function(es,et){eo.push(es,et)})
for(var er=0;er<el.state.overlays.length;++er){var en=el.state.overlays[er],ep=1,ek=0
q(el,em.text,en.mode,!0,function(es,eu){for(var ew=ep;es>ek;){var et=eo[ep]
et>es&&eo.splice(ep,1,es,eo[ep+1],et)
ep+=2
ek=Math.min(es,et)}if(eu)if(en.opaque){eo.splice(ew,ep-ew,es,eu)
ep=ew+2}else for(;ep>ew;ew+=2){var ev=eo[ew+1]
eo[ew+1]=ev?ev+" "+eu:eu}})}return eo}function b7(ek,el){el.styles&&el.styles[0]==ek.state.modeGen||(el.styles=dS(ek,el,el.stateAfter=cp(ek,a8(el))))
return el.styles}function cn(ek,el,em){var eo=ek.doc.mode,en=new dh(el.text,ek.options.tabSize)
""==el.text&&eo.blankLine&&eo.blankLine(em)
for(;!en.eol()&&en.pos<=ek.options.maxHighlightLength;){eo.token(en,em)
en.start=en.pos}}function dj(em,el){if(!em)return null
for(;;){var ek=em.match(/(?:^|\s)line-(background-)?(\S+)/)
if(!ek)break
em=em.slice(0,ek.index)+em.slice(ek.index+ek[0].length)
var en=ek[1]?"bgClass":"textClass"
null==el[en]?el[en]=ek[2]:new RegExp("(?:^|s)"+ek[2]+"(?:$|s)").test(el[en])||(el[en]+=" "+ek[2])}return cA[em]||(cA[em]="cm-"+em.replace(/ +/g," cm-"))}function df(et,ex,ek,ew){for(var eu,ey=ex,ep=!0;eu=dd(ey);)ey=dx(et.doc,eu.find().from.line)
var eq={pre:d7("pre"),col:0,pos:0,measure:null,measuredSomething:!1,cm:et,copyWidgets:ew}
do{ey.text&&(ep=!1)
eq.measure=ey==ex&&ek
eq.pos=0
eq.addToken=eq.measure?e:o;(ct||b1)&&et.getOption("lineWrapping")&&(eq.addToken=dU(eq.addToken))
var eo=aP(ey,eq,b7(et,ey))
if(ek&&ey==ex&&!eq.measuredSomething){ek[0]=eq.pre.appendChild(aN(et.display.measure))
eq.measuredSomething=!0}eo&&(ey=dx(et.doc,eo.to.line))}while(eo)
!ek||eq.measuredSomething||ek[0]||(ek[0]=eq.pre.appendChild(ep?d7("span"," "):aN(et.display.measure)))
eq.pre.firstChild||dN(et.doc,ex)||eq.pre.appendChild(document.createTextNode(" "))
var el
if(ek&&ct&&(el=a(ey))){var en=el.length-1
el[en].from==el[en].to&&--en
var ev=el[en],em=el[en-1]
if(ev.from+1==ev.to&&em&&ev.level<em.level){var es=ek[eq.pos-1]
es&&es.parentNode.insertBefore(es.measureRight=aN(et.display.measure),es.nextSibling)}}var er=eq.textClass?eq.textClass+" "+(ex.textClass||""):ex.textClass
er&&(eq.pre.className=er)
ae(et,"renderLine",et,ex,eq.pre)
return eq}function o(eo,ew,ek,en,ex,ev){if(ew){if(b5.test(ew))for(var er=document.createDocumentFragment(),et=0;;){b5.lastIndex=et
var el=b5.exec(ew),eq=el?el.index-et:ew.length-et
if(eq){er.appendChild(document.createTextNode(ew.slice(et,et+eq)))
eo.col+=eq}if(!el)break
et+=eq+1
if("	"==el[0]){var ep=eo.cm.options.tabSize,es=ep-eo.col%ep
er.appendChild(d7("span",bC(es),"cm-tab"))
eo.col+=es}else{var em=d7("span","•","cm-invalidchar")
em.title="\\u"+el[0].charCodeAt(0).toString(16)
er.appendChild(em)
eo.col+=1}}else{eo.col+=ew.length
var er=document.createTextNode(ew)}if(ek||en||ex||eo.measure){var eu=ek||""
en&&(eu+=en)
ex&&(eu+=ex)
var em=d7("span",[er],eu)
ev&&(em.title=ev)
return eo.pre.appendChild(em)}eo.pre.appendChild(er)}}function e(er,et,el,eo,eu){for(var eq=er.cm.options.lineWrapping,ep=0;ep<et.length;++ep){var ek=et.charAt(ep),em=0==ep
if(ek>="���"&&"���">ek&&ep<et.length-1){ek=et.slice(ep,ep+2);++ep}else ep&&eq&&bo(et,ep)&&er.pre.appendChild(d7("wbr"))
var en=er.measure[er.pos],es=er.measure[er.pos]=o(er,ek,el,em&&eo,ep==et.length-1&&eu)
en&&(es.leftSide=en.leftSide||en)
ct&&eq&&" "==ek&&ep&&!/\s/.test(et.charAt(ep-1))&&ep<et.length-1&&!/\s/.test(et.charAt(ep+1))&&(es.style.whiteSpace="normal")
er.pos+=ek.length}et.length&&(er.measuredSomething=!0)}function dU(ek){function el(em){for(var en=" ",eo=0;eo<em.length-2;++eo)en+=eo%2?" ":" "
en+=" "
return en}return function(en,er,eo,em,eq,ep){return ek(en,er.replace(/ {3,}/,el),eo,em,eq,ep)}}function J(el,eo,ek,en){var ep=!en&&ek.replacedWith
if(ep){el.copyWidgets&&(ep=ep.cloneNode(!0))
el.pre.appendChild(ep)
if(el.measure){if(eo)el.measure[el.pos]=ep
else{var em=aN(el.cm.display.measure)
if("bookmark"!=ek.type||ek.insertLeft){if(el.measure[el.pos])return
el.measure[el.pos]=el.pre.insertBefore(em,ep)}else el.measure[el.pos]=el.pre.appendChild(em)}el.measuredSomething=!0}}el.pos+=eo}function aP(et,ez,es){var ep=et.markedSpans,er=et.text,ex=0
if(ep)for(var eE,ek,eF,ew,eH,em,eD=er.length,eo=0,eC=1,ev="",eG=0;;){if(eG==eo){ek=eF=ew=eH=""
em=null
eG=1/0
for(var eq=[],eA=0;eA<ep.length;++eA){var eB=ep[eA],ey=eB.marker
if(eB.from<=eo&&(null==eB.to||eB.to>eo)){if(null!=eB.to&&eG>eB.to){eG=eB.to
eF=""}ey.className&&(ek+=" "+ey.className)
ey.startStyle&&eB.from==eo&&(ew+=" "+ey.startStyle)
ey.endStyle&&eB.to==eG&&(eF+=" "+ey.endStyle)
ey.title&&!eH&&(eH=ey.title)
ey.collapsed&&(!em||em.marker.size<ey.size)&&(em=eB)}else eB.from>eo&&eG>eB.from&&(eG=eB.from)
"bookmark"==ey.type&&eB.from==eo&&ey.replacedWith&&eq.push(ey)}if(em&&(em.from||0)==eo){J(ez,(null==em.to?eD:em.to)-eo,em.marker,null==em.from)
if(null==em.to)return em.marker.find()}if(!em&&eq.length)for(var eA=0;eA<eq.length;++eA)J(ez,0,eq[eA])}if(eo>=eD)break
for(var eu=Math.min(eD,eG);;){if(ev){var el=eo+ev.length
if(!em){var en=el>eu?ev.slice(0,eu-eo):ev
ez.addToken(ez,en,eE?eE+ek:ek,ew,eo+en.length==eG?eF:"",eH)}if(el>=eu){ev=ev.slice(eu-eo)
eo=eu
break}eo=el
ew=""}ev=er.slice(ex,ex=es[eC++])
eE=dj(es[eC++],ez)}}else for(var eC=1;eC<es.length;eC+=2)ez.addToken(ez,er.slice(ex,ex=es[eC]),dj(es[eC+1],ez))}function dQ(eB,es,eo,ew,eq){function en(eC){return eo?eo[eC]:null}function er(eC,eE,eD){cS(eC,eE,eD,eq)
L(eC,"change",eC,es)}var ex=es.from,el=es.to,eu=es.text,et=dx(eB,ex.line),ek=dx(eB,el.line),em=dV(eu),ez=en(eu.length-1),ev=el.line-ex.line
if(0==ex.ch&&0==el.ch&&""==em){for(var ey=0,eA=eu.length-1,ep=[];eA>ey;++ey)ep.push(new eb(eu[ey],en(ey),eq))
er(ek,ek.text,ez)
ev&&eB.remove(ex.line,ev)
ep.length&&eB.insert(ex.line,ep)}else if(et==ek)if(1==eu.length)er(et,et.text.slice(0,ex.ch)+em+et.text.slice(el.ch),ez)
else{for(var ep=[],ey=1,eA=eu.length-1;eA>ey;++ey)ep.push(new eb(eu[ey],en(ey),eq))
ep.push(new eb(em+et.text.slice(el.ch),ez,eq))
er(et,et.text.slice(0,ex.ch)+eu[0],en(0))
eB.insert(ex.line+1,ep)}else if(1==eu.length){er(et,et.text.slice(0,ex.ch)+eu[0]+ek.text.slice(el.ch),en(0))
eB.remove(ex.line+1,ev)}else{er(et,et.text.slice(0,ex.ch)+eu[0],en(0))
er(ek,em+ek.text.slice(el.ch),ez)
for(var ey=1,eA=eu.length-1,ep=[];eA>ey;++ey)ep.push(new eb(eu[ey],en(ey),eq))
ev>1&&eB.remove(ex.line+1,ev-1)
eB.insert(ex.line+1,ep)}L(eB,"change",eB,es)
bd(eB,ew.anchor,ew.head,null,!0)}function dm(el){this.lines=el
this.parent=null
for(var em=0,en=el.length,ek=0;en>em;++em){el[em].parent=this
ek+=el[em].height}this.height=ek}function dO(en){this.children=en
for(var em=0,ek=0,el=0,ep=en.length;ep>el;++el){var eo=en[el]
em+=eo.chunkSize()
ek+=eo.height
eo.parent=this}this.size=em
this.height=ek
this.parent=null}function cF(en,em,el){function ek(et,er,ep){if(et.linked)for(var eq=0;eq<et.linked.length;++eq){var eo=et.linked[eq]
if(eo.doc!=er){var es=ep&&eo.sharedHist
if(!el||es){em(eo.doc,es)
ek(eo.doc,et,es)}}}}ek(en,null,!0)}function cI(ek,el){if(el.cm)throw new Error("This document is already in use.")
ek.doc=el
el.cm=ek
I(ek)
aR(ek)
ek.options.lineWrapping||ea(ek)
ek.options.mode=el.modeOption
N(ek)}function dx(ek,eo){eo-=ek.first
for(;!ek.lines;)for(var el=0;;++el){var en=ek.children[el],em=en.chunkSize()
if(em>eo){ek=en
break}eo-=em}return ek.lines[eo]}function d9(em,eo,ek){var el=[],en=eo.line
em.iter(eo.line,ek.line+1,function(ep){var eq=ep.text
en==ek.line&&(eq=eq.slice(0,ek.ch))
en==eo.line&&(eq=eq.slice(eo.ch))
el.push(eq);++en})
return el}function ax(el,en,em){var ek=[]
el.iter(en,em,function(eo){ek.push(eo.text)})
return ek}function ec(el,ek){for(var em=ek-el.height,en=el;en;en=en.parent)en.height+=em}function a8(ek){if(null==ek.parent)return null
for(var eo=ek.parent,en=ce(eo.lines,ek),el=eo.parent;el;eo=el,el=el.parent)for(var em=0;el.children[em]!=eo;++em)en+=el.children[em].chunkSize()
return en+eo.first}function a1(eq,eo){var em=eq.first
outer:do{for(var en=0,ep=eq.children.length;ep>en;++en){var el=eq.children[en],ek=el.height
if(ek>eo){eq=el
continue outer}eo-=ek
em+=el.chunkSize()}return em}while(!eq.lines)
for(var en=0,ep=eq.lines.length;ep>en;++en){var es=eq.lines[en],er=es.height
if(er>eo)break
eo-=er}return em+en}function a7(ek,en){en=s(ek.doc,en)
for(var ep=0,em=en.parent,eo=0;eo<em.lines.length;++eo){var el=em.lines[eo]
if(el==en)break
ep+=el.height}for(var eq=em.parent;eq;em=eq,eq=em.parent)for(var eo=0;eo<eq.children.length;++eo){var er=eq.children[eo]
if(er==em)break
ep+=er.height}return ep}function a(el){var ek=el.order
null==ek&&(ek=el.order=aH(el.text))
return ek}function Z(ek){return{done:[],undone:[],undoDepth:1/0,lastTime:0,lastOp:null,lastOrigin:null,generation:ek||1,maxGeneration:ek||1}}function bg(el,ep,eo,en){var ek=ep["spans_"+el.id],em=0
el.iter(Math.max(el.first,eo),Math.min(el.first+el.size,en),function(eq){eq.markedSpans&&((ek||(ek=ep["spans_"+el.id]={}))[em]=eq.markedSpans);++em})}function cl(ek,en){var em={line:en.from.line,ch:en.from.ch},el={from:em,to:bY(en),text:d9(ek,en.from,en.to)}
bg(ek,el,en.from.line,en.to.line+1)
cF(ek,function(eo){bg(eo,el,en.from.line,en.to.line+1)},!0)
return el}function c9(ep,er,eo,ek){var en=ep.history
en.undone.length=0
var em=+new Date,eq=dV(en.done)
if(eq&&(en.lastOp==ek||en.lastOrigin==er.origin&&er.origin&&("+"==er.origin.charAt(0)&&ep.cm&&en.lastTime>em-ep.cm.options.historyEventDelay||"*"==er.origin.charAt(0)))){var el=dV(eq.changes)
dW(er.from,er.to)&&dW(er.from,el.to)?el.to=bY(er):eq.changes.push(cl(ep,er))
eq.anchorAfter=eo.anchor
eq.headAfter=eo.head}else{eq={changes:[cl(ep,er)],generation:en.generation,anchorBefore:ep.sel.anchor,headBefore:ep.sel.head,anchorAfter:eo.anchor,headAfter:eo.head}
en.done.push(eq)
en.generation=++en.maxGeneration
for(;en.done.length>en.undoDepth;)en.done.shift()}en.lastTime=em
en.lastOp=ek
en.lastOrigin=er.origin}function aK(em){if(!em)return null
for(var ek,el=0;el<em.length;++el)em[el].marker.explicitlyCleared?ek||(ek=em.slice(0,el)):ek&&ek.push(em[el])
return ek?ek.length?ek:null:em}function bl(en,eo){var em=eo["spans_"+en.id]
if(!em)return null
for(var el=0,ek=[];el<eo.text.length;++el)ek.push(aK(em[el]))
return ek}function a9(eu,en){for(var eq=0,el=[];eq<eu.length;++eq){var em=eu[eq],es=em.changes,et=[]
el.push({changes:et,anchorBefore:em.anchorBefore,headBefore:em.headBefore,anchorAfter:em.anchorAfter,headAfter:em.headAfter})
for(var ep=0;ep<es.length;++ep){var eo,er=es[ep]
et.push({from:er.from,to:er.to,text:er.text})
if(en)for(var ek in er)if((eo=ek.match(/^spans_(\d+)$/))&&ce(en,Number(eo[1]))>-1){dV(et)[ek]=er[ek]
delete er[ek]}}}return el}function dk(en,em,el,ek){if(el<en.line)en.line+=ek
else if(em<en.line){en.line=em
en.ch=0}}function dA(en,ep,eq,er){for(var em=0;em<en.length;++em){for(var ek=en[em],eo=!0,el=0;el<ek.changes.length;++el){var es=ek.changes[el]
if(!ek.copied){es.from=bv(es.from)
es.to=bv(es.to)}if(eq<es.from.line){es.from.line+=er
es.to.line+=er}else if(ep<=es.to.line){eo=!1
break}}if(!ek.copied){ek.anchorBefore=bv(ek.anchorBefore)
ek.headBefore=bv(ek.headBefore)
ek.anchorAfter=bv(ek.anchorAfter)
ek.readAfter=bv(ek.headAfter)
ek.copied=!0}if(eo){dk(ek.anchorBefore)
dk(ek.headBefore)
dk(ek.anchorAfter)
dk(ek.headAfter)}else{en.splice(0,em+1)
em=0}}}function cs(el,eo){var en=eo.from.line,em=eo.to.line,ek=eo.text.length-(em-en)-1
dA(el.done,en,em,ek)
dA(el.undone,en,em,ek)}function dg(){cT(this)}function V(ek){ek.stop||(ek.stop=dg)
return ek}function bO(ek){ek.preventDefault?ek.preventDefault():ek.returnValue=!1}function ci(ek){ek.stopPropagation?ek.stopPropagation():ek.cancelBubble=!0}function a6(ek){return null!=ek.defaultPrevented?ek.defaultPrevented:0==ek.returnValue}function cT(ek){bO(ek)
ci(ek)}function A(ek){return ek.target||ek.srcElement}function dZ(el){var ek=el.which
null==ek&&(1&el.button?ek=1:2&el.button?ek=3:4&el.button&&(ek=2))
bk&&el.ctrlKey&&1==ek&&(ek=3)
return ek}function bf(en,el,em){if(en.addEventListener)en.addEventListener(el,em,!1)
else if(en.attachEvent)en.attachEvent("on"+el,em)
else{var eo=en._handlers||(en._handlers={}),ek=eo[el]||(eo[el]=[])
ek.push(em)}}function cL(eo,em,en){if(eo.removeEventListener)eo.removeEventListener(em,en,!1)
else if(eo.detachEvent)eo.detachEvent("on"+em,en)
else{var ek=eo._handlers&&eo._handlers[em]
if(!ek)return
for(var el=0;el<ek.length;++el)if(ek[el]==en){ek.splice(el,1)
break}}}function ae(eo,en){var ek=eo._handlers&&eo._handlers[en]
if(ek)for(var el=Array.prototype.slice.call(arguments,2),em=0;em<ek.length;++em)ek[em].apply(null,el)}function L(ep,eo){function el(eq){return function(){eq.apply(null,em)}}var ek=ep._handlers&&ep._handlers[eo]
if(ek){var em=Array.prototype.slice.call(arguments,2)
if(!aO){++bE
aO=[]
setTimeout(c1,0)}for(var en=0;en<ek.length;++en)aO.push(el(ek[en]))}}function ao(ek,em,el){ae(ek,el||em.type,ek,em)
return a6(em)||em.codemirrorIgnore}function c1(){--bE
var ek=aO
aO=null
for(var el=0;el<ek.length;++el)ek[el]()}function dD(em,el){var ek=em._handlers&&em._handlers[el]
return ek&&ek.length>0}function aV(ek){ek.prototype.on=function(el,em){bf(this,el,em)}
ek.prototype.off=function(el,em){cL(this,el,em)}}function ej(){this.id=null}function bb(em,ek,eo,ep,el){if(null==ek){ek=em.search(/[^\s\u00a0]/);-1==ek&&(ek=em.length)}for(var en=ep||0,eq=el||0;ek>en;++en)"	"==em.charAt(en)?eq+=eo-eq%eo:++eq
return eq}function bC(ek){for(;au.length<=ek;)au.push(dV(au)+" ")
return au[ek]}function dV(ek){return ek[ek.length-1]}function cv(el){if(dn){el.selectionStart=0
el.selectionEnd=el.value.length}else try{el.select()}catch(ek){}}function ce(en,ek){if(en.indexOf)return en.indexOf(ek)
for(var el=0,em=en.length;em>el;++el)if(en[el]==ek)return el
return-1}function bw(en,el){function ek(){}ek.prototype=en
var em=new ek
el&&aj(el,em)
return em}function aj(el,ek){ek||(ek={})
for(var em in el)el.hasOwnProperty(em)&&(ek[em]=el[em])
return ek}function R(em){for(var ek=[],el=0;em>el;++el)ek.push(void 0)
return ek}function bH(el){var ek=Array.prototype.slice.call(arguments,1)
return function(){return el.apply(null,ek)}}function bK(ek){return/\w/.test(ek)||ek>""&&(ek.toUpperCase()!=ek.toLowerCase()||aD.test(ek))}function di(ek){for(var el in ek)if(ek.hasOwnProperty(el)&&ek[el])return!1
return!0}function d7(ek,eo,en,em){var ep=document.createElement(ek)
en&&(ep.className=en)
em&&(ep.style.cssText=em)
if("string"==typeof eo)m(ep,eo)
else if(eo)for(var el=0;el<eo.length;++el)ep.appendChild(eo[el])
return ep}function cC(el){for(var ek=el.childNodes.length;ek>0;--ek)el.removeChild(el.firstChild)
return el}function bc(ek,el){return cC(ek).appendChild(el)}function m(ek,el){if(bx){ek.innerHTML=""
ek.appendChild(document.createTextNode(el))}else ek.textContent=el}function ak(ek){return ek.getBoundingClientRect()}function bo(){return!1}function i(ek){if(null!=cX)return cX
var el=d7("div",null,null,"width: 50px; height: 50px; overflow-x: scroll")
bc(ek,el)
el.offsetWidth&&(cX=el.offsetHeight-el.clientHeight)
return cX||0}function aN(ek){if(null==dY){var el=d7("span","​")
bc(ek,d7("span",[el,document.createTextNode("x")]))
0!=ek.firstChild.offsetHeight&&(dY=el.offsetWidth<=1&&el.offsetHeight>2&&!by)}return dY?d7("span","​"):d7("span"," ",null,"display: inline-block; width: 1px; margin-right: -1px")}function cD(ek,eq,ep,eo){if(!ek)return eo(eq,ep,"ltr")
for(var en=!1,em=0;em<ek.length;++em){var el=ek[em]
if(el.from<ep&&el.to>eq||eq==ep&&el.to==eq){eo(Math.max(el.from,eq),Math.min(el.to,ep),1==el.level?"rtl":"ltr")
en=!0}}en||eo(eq,ep,"ltr")}function co(ek){return ek.level%2?ek.to:ek.from}function ef(ek){return ek.level%2?ek.from:ek.to}function bN(el){var ek=a(el)
return ek?co(ek[0]):0}function bX(el){var ek=a(el)
return ek?ef(dV(ek)):el.text.length}function aT(el,eo){var em=dx(el.doc,eo),ep=s(el.doc,em)
ep!=em&&(eo=a8(ep))
var ek=a(ep),en=ek?ek[0].level%2?bX(ep):bN(ep):0
return H(eo,en)}function cx(em,ep){for(var el,en;el=cW(en=dx(em.doc,ep));)ep=el.find().to.line
var ek=a(en),eo=ek?ek[0].level%2?bN(en):bX(en):en.text.length
return H(ep,eo)}function U(el,em,ek){var en=el[0].level
return em==en?!0:ek==en?!1:ek>em}function ag(ek,eo){for(var em,el=0;el<ek.length;++el){var en=ek[el]
if(en.from<eo&&en.to>eo){dp=null
return el}if(en.from==eo||en.to==eo){if(null!=em){if(U(ek,en.level,ek[em].level)){dp=em
return el}dp=el
return em}em=el}}dp=null
return em}function dw(ek,en,el,em){if(!em)return en+el
do en+=el
while(en>0&&dJ.test(ek.text.charAt(en)))
return en}function p(ek,er,em,en){var eo=a(ek)
if(!eo)return O(ek,er,em,en)
for(var eq=ag(eo,er),el=eo[eq],ep=dw(ek,er,el.level%2?-em:em,en);;){if(ep>el.from&&ep<el.to)return ep
if(ep==el.from||ep==el.to){if(ag(eo,ep)==eq)return ep
el=eo[eq+=em]
return em>0==el.level%2?el.to:el.from}el=eo[eq+=em]
if(!el)return null
ep=em>0==el.level%2?dw(ek,el.to,-1,en):dw(ek,el.from,1,en)}}function O(ek,eo,el,em){var en=eo+el
if(em)for(;en>0&&dJ.test(ek.text.charAt(en));)en+=el
return 0>en||en>ek.text.length?null:en}var bB=/gecko\/\d/i.test(navigator.userAgent),ct=/MSIE \d/.test(navigator.userAgent),by=ct&&(null==document.documentMode||document.documentMode<8),bx=ct&&(null==document.documentMode||document.documentMode<9),b1=/WebKit\//.test(navigator.userAgent),cw=b1&&/Qt\/\d+\.\d+/.test(navigator.userAgent),b9=/Chrome\//.test(navigator.userAgent),dP=/Opera\//.test(navigator.userAgent),ad=/Apple Computer/.test(navigator.vendor),aC=/KHTML\//.test(navigator.userAgent),bM=/Mac OS X 1\d\D([7-9]|\d\d)\D/.test(navigator.userAgent),b6=/Mac OS X 1\d\D([8-9]|\d\d)\D/.test(navigator.userAgent),dM=/PhantomJS/.test(navigator.userAgent),dn=/AppleWebKit/.test(navigator.userAgent)&&/Mobile\/\w+/.test(navigator.userAgent),cN=dn||/Android|webOS|BlackBerry|Opera Mini|Opera Mobi|IEMobile/i.test(navigator.userAgent),bk=dn||/Mac/.test(navigator.platform),al=/win/i.test(navigator.platform),cZ=dP&&navigator.userAgent.match(/Version\/(\d*\.\d*)/)
cZ&&(cZ=Number(cZ[1]))
if(cZ&&cZ>=15){dP=!1
b1=!0}var ah,cg,ca,ba=bk&&(cw||dP&&(null==cZ||12.11>cZ)),bQ=bB||ct&&!bx,ee=!1,ay=!1,cG=0,M=0,dE=0,bt=null
ct?bt=-.53:bB?bt=15:b9?bt=-.7:ad&&(bt=-1/3)
var W,dT,cf=null,bY=y.changeEnd=function(ek){return ek.text?H(ek.from.line+ek.text.length-1,dV(ek.text).length+(1==ek.text.length?ek.from.ch:0)):ek.to}
y.Pos=H
y.prototype={constructor:y,focus:function(){window.focus()
c2(this)
bL(this)
t(this)},setOption:function(em,en){var el=this.options,ek=el[em]
if(el[em]!=en||"mode"==em){el[em]=en
aF.hasOwnProperty(em)&&b2(this,aF[em])(this,en,ek)}},getOption:function(ek){return this.options[ek]},getDoc:function(){return this.doc},addKeyMap:function(el,ek){this.state.keyMaps[ek?"push":"unshift"](el)},removeKeyMap:function(el){for(var em=this.state.keyMaps,ek=0;ek<em.length;++ek)if(em[ek]==el||"string"!=typeof em[ek]&&em[ek].name==el){em.splice(ek,1)
return!0}},addOverlay:b2(null,function(ek,el){var em=ek.token?ek:y.getMode(this.options,ek)
if(em.startState)throw new Error("Overlays may not be stateful.")
this.state.overlays.push({mode:em,modeSpec:ek,opaque:el&&el.opaque})
this.state.modeGen++
N(this)}),removeOverlay:b2(null,function(ek){for(var em=this.state.overlays,el=0;el<em.length;++el){var en=em[el].modeSpec
if(en==ek||"string"==typeof ek&&en.name==ek){em.splice(el,1)
this.state.modeGen++
N(this)
return}}}),indentLine:b2(null,function(em,ek,el){"string"!=typeof ek&&"number"!=typeof ek&&(ek=null==ek?this.options.smartIndent?"smart":"prev":ek?"add":"subtract")
bn(this.doc,em)&&K(this,em,ek,el)}),indentSelection:b2(null,function(el){var em=this.doc.sel
if(dW(em.from,em.to))return K(this,em.from.line,el)
for(var en=em.to.line-(em.to.ch?0:1),ek=em.from.line;en>=ek;++ek)K(this,ek,el)}),getTokenAt:function(er,el){var eo=this.doc
er=dX(eo,er)
for(var en=cp(this,er.line,el),eq=this.doc.mode,ek=dx(eo,er.line),ep=new dh(ek.text,this.options.tabSize);ep.pos<er.ch&&!ep.eol();){ep.start=ep.pos
var em=eq.token(ep,en)}return{start:ep.start,end:ep.pos,string:ep.current(),className:em||null,type:em||null,state:en}},getTokenTypeAt:function(ep){ep=dX(this.doc,ep)
var em=b7(this,dx(this.doc,ep.line)),en=0,eo=(em.length-1)/2,el=ep.ch
if(0==el)return em[2]
for(;;){var ek=en+eo>>1
if((ek?em[2*ek-1]:0)>=el)eo=ek
else{if(!(em[2*ek+1]<el))return em[2*ek+2]
en=ek+1}}},getModeAt:function(el){var ek=this.doc.mode
return ek.innerMode?y.innerMode(ek,this.getTokenAt(el).state).mode:ek},getHelper:function(en,el){if(dG.hasOwnProperty(el)){var ek=dG[el],em=this.getModeAt(en)
return em[el]&&ek[em[el]]||em.helperType&&ek[em.helperType]||ek[em.name]}},getStateAfter:function(el,ek){var em=this.doc
el=b4(em,null==el?em.first+em.size-1:el)
return cp(this,el+1,ek)},cursorCoords:function(en,el){var em,ek=this.doc.sel
em=null==en?ek.head:"object"==typeof en?dX(this.doc,en):en?ek.from:ek.to
return cz(this,em,el||"page")},charCoords:function(el,ek){return bS(this,dX(this.doc,el),ek||"page")},coordsChar:function(ek,el){ek=eg(this,ek,el||"page")
return d1(this,ek.left,ek.top)},lineAtHeight:function(ek,el){ek=eg(this,{top:ek,left:0},el||"page").top
return a1(this.doc,ek+this.display.viewOffset)},heightAtLine:function(el,eo){var ek=!1,en=this.doc.first+this.doc.size-1
if(el<this.doc.first)el=this.doc.first
else if(el>en){el=en
ek=!0}var em=dx(this.doc,el)
return de(this,dx(this.doc,el),{top:0,left:0},eo||"page").top+(ek?em.height:0)},defaultTextHeight:function(){return at(this.display)},defaultCharWidth:function(){return cr(this.display)},setGutterMarker:b2(null,function(ek,el,em){return c0(this,ek,function(en){var eo=en.gutterMarkers||(en.gutterMarkers={})
eo[el]=em
!em&&di(eo)&&(en.gutterMarkers=null)
return!0})}),clearGutter:b2(null,function(em){var ek=this,en=ek.doc,el=en.first
en.iter(function(eo){if(eo.gutterMarkers&&eo.gutterMarkers[em]){eo.gutterMarkers[em]=null
N(ek,el,el+1)
di(eo.gutterMarkers)&&(eo.gutterMarkers=null)}++el})}),addLineClass:b2(null,function(em,el,ek){return c0(this,em,function(en){var eo="text"==el?"textClass":"background"==el?"bgClass":"wrapClass"
if(en[eo]){if(new RegExp("(?:^|\\s)"+ek+"(?:$|\\s)").test(en[eo]))return!1
en[eo]+=" "+ek}else en[eo]=ek
return!0})}),removeLineClass:b2(null,function(em,el,ek){return c0(this,em,function(eo){var er="text"==el?"textClass":"background"==el?"bgClass":"wrapClass",eq=eo[er]
if(!eq)return!1
if(null==ek)eo[er]=null
else{var ep=eq.match(new RegExp("(?:^|\\s+)"+ek+"(?:$|\\s+)"))
if(!ep)return!1
var en=ep.index+ep[0].length
eo[er]=eq.slice(0,ep.index)+(ep.index&&en!=eq.length?" ":"")+eq.slice(en)||null}return!0})}),addLineWidget:b2(null,function(em,el,ek){return a2(this,em,el,ek)}),removeLineWidget:function(ek){ek.clear()},lineInfo:function(ek){if("number"==typeof ek){if(!bn(this.doc,ek))return null
var el=ek
ek=dx(this.doc,ek)
if(!ek)return null}else{var el=a8(ek)
if(null==el)return null}return{line:el,handle:ek,text:ek.text,gutterMarkers:ek.gutterMarkers,textClass:ek.textClass,bgClass:ek.bgClass,wrapClass:ek.wrapClass,widgets:ek.widgets}},getViewport:function(){return{from:this.display.showingFrom,to:this.display.showingTo}},addWidget:function(ep,em,er,en,et){var eo=this.display
ep=cz(this,dX(this.doc,ep))
var eq=ep.bottom,el=ep.left
em.style.position="absolute"
eo.sizer.appendChild(em)
if("over"==en)eq=ep.top
else if("above"==en||"near"==en){var ek=Math.max(eo.wrapper.clientHeight,this.doc.height),es=Math.max(eo.sizer.clientWidth,eo.lineSpace.clientWidth);("above"==en||ep.bottom+em.offsetHeight>ek)&&ep.top>em.offsetHeight?eq=ep.top-em.offsetHeight:ep.bottom+em.offsetHeight<=ek&&(eq=ep.bottom)
el+em.offsetWidth>es&&(el=es-em.offsetWidth)}em.style.top=eq+"px"
em.style.left=em.style.right=""
if("right"==et){el=eo.sizer.clientWidth-em.offsetWidth
em.style.right="0px"}else{"left"==et?el=0:"middle"==et&&(el=(eo.sizer.clientWidth-em.offsetWidth)/2)
em.style.left=el+"px"}er&&w(this,el,eq,el+em.offsetWidth,eq+em.offsetHeight)},triggerOnKeyDown:b2(null,l),execCommand:function(ek){return c4[ek](this)},findPosH:function(eq,en,eo,el){var ek=1
if(0>en){ek=-1
en=-en}for(var em=0,ep=dX(this.doc,eq);en>em;++em){ep=aU(this.doc,ep,ek,eo,el)
if(ep.hitSide)break}return ep},moveH:b2(null,function(ek,el){var en,em=this.doc.sel
en=em.shift||em.extend||dW(em.from,em.to)?aU(this.doc,em.head,ek,el,this.options.rtlMoveVisually):0>ek?em.from:em.to
d4(this.doc,en,en,ek)}),deleteH:b2(null,function(ek,el){var em=this.doc.sel
dW(em.from,em.to)?aw(this.doc,"",em.from,aU(this.doc,em.head,ek,el,!1),"+delete"):aw(this.doc,"",em.from,em.to,"+delete")
this.curOp.userSelChange=!0}),findPosV:function(ep,em,eq,es){var ek=1,eo=es
if(0>em){ek=-1
em=-em}for(var el=0,er=dX(this.doc,ep);em>el;++el){var en=cz(this,er,"div")
null==eo?eo=en.left:en.left=eo
er=aQ(this,en,ek,eq)
if(er.hitSide)break}return er},moveV:b2(null,function(ek,el){var em=this.doc.sel,eo=cz(this,em.head,"div")
null!=em.goalColumn&&(eo.left=em.goalColumn)
var en=aQ(this,eo,ek,el)
"page"==el&&bT(this,0,bS(this,en,"div").top-eo.top)
d4(this.doc,en,en,ek)
em.goalColumn=eo.left}),toggleOverwrite:function(ek){(null==ek||ek!=this.state.overwrite)&&((this.state.overwrite=!this.state.overwrite)?this.display.cursor.className+=" CodeMirror-overwrite":this.display.cursor.className=this.display.cursor.className.replace(" CodeMirror-overwrite",""))},hasFocus:function(){return this.state.focused},scrollTo:b2(null,function(ek,el){v(this,ek,el)}),getScrollInfo:function(){var ek=this.display.scroller,el=aJ
return{left:ek.scrollLeft,top:ek.scrollTop,height:ek.scrollHeight-el,width:ek.scrollWidth-el,clientHeight:ek.clientHeight-el,clientWidth:ek.clientWidth-el}},scrollIntoView:b2(null,function(en,em){"number"==typeof en&&(en=H(en,0))
em||(em=0)
var el=en
if(!en||null!=en.line){this.curOp.scrollToPos=en?dX(this.doc,en):this.doc.sel.head
this.curOp.scrollToPosMargin=em
el=cz(this,this.curOp.scrollToPos)}var ek=x(this,el.left,el.top-em,el.right,el.bottom+em)
v(this,ek.scrollLeft,ek.scrollTop)}),setSize:b2(null,function(em,ek){function el(en){return"number"==typeof en||/^\d+$/.test(String(en))?en+"px":en}null!=em&&(this.display.wrapper.style.width=el(em))
null!=ek&&(this.display.wrapper.style.height=el(ek))
this.options.lineWrapping&&(this.display.measureLineCache.length=this.display.measureLineCachePos=0)
this.curOp.forceUpdate=!0}),operation:function(ek){return bU(this,ek)},refresh:b2(null,function(){var ek=null==this.display.cachedTextHeight
Q(this)
v(this,this.doc.scrollLeft,this.doc.scrollTop)
N(this)
ek&&I(this)}),swapDoc:b2(null,function(el){var ek=this.doc
ek.cm=null
cI(this,el)
Q(this)
dI(this,!0)
v(this,el.scrollLeft,el.scrollTop)
return ek}),getInputField:function(){return this.display.input},getWrapperElement:function(){return this.display.wrapper},getScrollerElement:function(){return this.display.scroller},getGutterElement:function(){return this.display.gutters}}
aV(y)
var aF=y.optionHandlers={},dq=y.defaults={},bq=y.Init={toString:function(){return"CodeMirror.Init"}}
n("value","",function(ek,el){ek.setValue(el)},!0)
n("mode",null,function(ek,el){ek.doc.modeOption=el
aR(ek)},!0)
n("indentUnit",2,aR,!0)
n("indentWithTabs",!1)
n("smartIndent",!0)
n("tabSize",4,function(ek){aR(ek)
Q(ek)
N(ek)},!0)
n("electricChars",!0)
n("rtlMoveVisually",!al)
n("theme","default",function(ek){bV(ek)
cm(ek)},!0)
n("keyMap","default",eh)
n("extraKeys",null)
n("onKeyEvent",null)
n("onDragEvent",null)
n("lineWrapping",!1,da,!0)
n("gutters",[],function(ek){bs(ek.options)
cm(ek)},!0)
n("fixedGutter",!0,function(ek,el){ek.display.gutters.style.left=el?cB(ek.display)+"px":"0"
ek.refresh()},!0)
n("coverGutterNextToScrollbar",!1,dl,!0)
n("lineNumbers",!1,function(ek){bs(ek.options)
cm(ek)},!0)
n("firstLineNumber",1,cm,!0)
n("lineNumberFormatter",function(ek){return ek},cm,!0)
n("showCursorWhenSelecting",!1,aY,!0)
n("readOnly",!1,function(ek,el){if("nocursor"==el){aq(ek)
ek.display.input.blur()}else el||dI(ek,!0)})
n("dragDrop",!0)
n("cursorBlinkRate",530)
n("cursorScrollMargin",0)
n("cursorHeight",1)
n("workTime",100)
n("workDelay",100)
n("flattenSpans",!0)
n("pollInterval",100)
n("undoDepth",40,function(ek,el){ek.doc.history.undoDepth=el})
n("historyEventDelay",500)
n("viewportMargin",10,function(ek){ek.refresh()},!0)
n("maxHighlightLength",1e4,function(ek){aR(ek)
ek.refresh()},!0)
n("crudeMeasuringFrom",1e4)
n("moveInputWithCursor",!0,function(ek,el){el||(ek.display.inputDiv.style.top=ek.display.inputDiv.style.left=0)})
n("tabindex",null,function(ek,el){ek.display.input.tabIndex=el||""})
n("autofocus",null)
var cj=y.modes={},ap=y.mimeModes={}
y.defineMode=function(ek,em){y.defaults.mode||"null"==ek||(y.defaults.mode=ek)
if(arguments.length>2){em.dependencies=[]
for(var el=2;el<arguments.length;++el)em.dependencies.push(arguments[el])}cj[ek]=em}
y.defineMIME=function(el,ek){ap[el]=ek}
y.resolveMode=function(ek){if("string"==typeof ek&&ap.hasOwnProperty(ek))ek=ap[ek]
else if(ek&&"string"==typeof ek.name&&ap.hasOwnProperty(ek.name)){var el=ap[ek.name]
ek=bw(el,ek)
ek.name=el.name}else if("string"==typeof ek&&/^[\w\-]+\/[\w\-]+\+xml$/.test(ek))return y.resolveMode("application/xml")
return"string"==typeof ek?{name:ek}:ek||{name:"null"}}
y.getMode=function(el,ek){var ek=y.resolveMode(ek),en=cj[ek.name]
if(!en)return y.getMode(el,"text/plain")
var eo=en(el,ek)
if(ch.hasOwnProperty(ek.name)){var em=ch[ek.name]
for(var ep in em)if(em.hasOwnProperty(ep)){eo.hasOwnProperty(ep)&&(eo["_"+ep]=eo[ep])
eo[ep]=em[ep]}}eo.name=ek.name
return eo}
y.defineMode("null",function(){return{token:function(ek){ek.skipToEnd()}}})
y.defineMIME("text/plain","null")
var ch=y.modeExtensions={}
y.extendMode=function(em,el){var ek=ch.hasOwnProperty(em)?ch[em]:ch[em]={}
aj(el,ek)}
y.defineExtension=function(ek,el){y.prototype[ek]=el}
y.defineDocExtension=function(ek,el){X.prototype[ek]=el}
y.defineOption=n
var az=[]
y.defineInitHook=function(ek){az.push(ek)}
var dG=y.helpers={}
y.registerHelper=function(el,ek,em){dG.hasOwnProperty(el)||(dG[el]=y[el]={})
dG[el][ek]=em}
y.isWordChar=bK
y.copyState=bi
y.startState=bh
y.innerMode=function(em,ek){for(;em.innerMode;){var el=em.innerMode(ek)
if(!el||el.mode==em)break
ek=el.state
em=el.mode}return el||{mode:em,state:ek}}
var c4=y.commands={selectAll:function(ek){ek.setSelection(H(ek.firstLine(),0),H(ek.lastLine()))},killLine:function(ek){var en=ek.getCursor(!0),em=ek.getCursor(!1),el=!dW(en,em)
el||ek.getLine(en.line).length!=en.ch?ek.replaceRange("",en,el?em:H(en.line),"+delete"):ek.replaceRange("",en,H(en.line+1,0),"+delete")},deleteLine:function(ek){var el=ek.getCursor().line
ek.replaceRange("",H(el,0),H(el),"+delete")},delLineLeft:function(ek){var el=ek.getCursor()
ek.replaceRange("",H(el.line,0),el,"+delete")},undo:function(ek){ek.undo()},redo:function(ek){ek.redo()},goDocStart:function(ek){ek.extendSelection(H(ek.firstLine(),0))},goDocEnd:function(ek){ek.extendSelection(H(ek.lastLine()))},goLineStart:function(ek){ek.extendSelection(aT(ek,ek.getCursor().line))},goLineStartSmart:function(el){var ep=el.getCursor(),eq=aT(el,ep.line),em=el.getLineHandle(eq.line),ek=a(em)
if(ek&&0!=ek[0].level)el.extendSelection(eq)
else{var eo=Math.max(0,em.text.search(/\S/)),en=ep.line==eq.line&&ep.ch<=eo&&ep.ch
el.extendSelection(H(eq.line,en?0:eo))}},goLineEnd:function(ek){ek.extendSelection(cx(ek,ek.getCursor().line))},goLineRight:function(ek){var el=ek.charCoords(ek.getCursor(),"div").top+5
ek.extendSelection(ek.coordsChar({left:ek.display.lineDiv.offsetWidth+100,top:el},"div"))},goLineLeft:function(ek){var el=ek.charCoords(ek.getCursor(),"div").top+5
ek.extendSelection(ek.coordsChar({left:0,top:el},"div"))},goLineUp:function(ek){ek.moveV(-1,"line")},goLineDown:function(ek){ek.moveV(1,"line")},goPageUp:function(ek){ek.moveV(-1,"page")},goPageDown:function(ek){ek.moveV(1,"page")},goCharLeft:function(ek){ek.moveH(-1,"char")},goCharRight:function(ek){ek.moveH(1,"char")},goColumnLeft:function(ek){ek.moveH(-1,"column")},goColumnRight:function(ek){ek.moveH(1,"column")},goWordLeft:function(ek){ek.moveH(-1,"word")},goGroupRight:function(ek){ek.moveH(1,"group")},goGroupLeft:function(ek){ek.moveH(-1,"group")},goWordRight:function(ek){ek.moveH(1,"word")},delCharBefore:function(ek){ek.deleteH(-1,"char")},delCharAfter:function(ek){ek.deleteH(1,"char")},delWordBefore:function(ek){ek.deleteH(-1,"word")},delWordAfter:function(ek){ek.deleteH(1,"word")},delGroupBefore:function(ek){ek.deleteH(-1,"group")},delGroupAfter:function(ek){ek.deleteH(1,"group")},indentAuto:function(ek){ek.indentSelection("smart")},indentMore:function(ek){ek.indentSelection("add")},indentLess:function(ek){ek.indentSelection("subtract")},insertTab:function(ek){ek.replaceSelection("	","end","+input")},defaultTab:function(ek){ek.somethingSelected()?ek.indentSelection("add"):ek.replaceSelection("	","end","+input")},transposeChars:function(ek){var em=ek.getCursor(),el=ek.getLine(em.line)
em.ch>0&&em.ch<el.length-1&&ek.replaceRange(el.charAt(em.ch)+el.charAt(em.ch-1),H(em.line,em.ch-1),H(em.line,em.ch+1))},newlineAndIndent:function(ek){b2(ek,function(){ek.replaceSelection("\n","end","+input")
ek.indentLine(ek.getCursor().line,null,!0)})()},toggleOverwrite:function(ek){ek.toggleOverwrite()}},du=y.keyMap={}
du.basic={Left:"goCharLeft",Right:"goCharRight",Up:"goLineUp",Down:"goLineDown",End:"goLineEnd",Home:"goLineStartSmart",PageUp:"goPageUp",PageDown:"goPageDown",Delete:"delCharAfter",Backspace:"delCharBefore",Tab:"defaultTab","Shift-Tab":"indentAuto",Enter:"newlineAndIndent",Insert:"toggleOverwrite"}
du.pcDefault={"Ctrl-A":"selectAll","Ctrl-D":"deleteLine","Ctrl-Z":"undo","Shift-Ctrl-Z":"redo","Ctrl-Y":"redo","Ctrl-Home":"goDocStart","Alt-Up":"goDocStart","Ctrl-End":"goDocEnd","Ctrl-Down":"goDocEnd","Ctrl-Left":"goGroupLeft","Ctrl-Right":"goGroupRight","Alt-Left":"goLineStart","Alt-Right":"goLineEnd","Ctrl-Backspace":"delGroupBefore","Ctrl-Delete":"delGroupAfter","Ctrl-S":"save","Ctrl-F":"find","Ctrl-G":"findNext","Shift-Ctrl-G":"findPrev","Shift-Ctrl-F":"replace","Shift-Ctrl-R":"replaceAll","Ctrl-[":"indentLess","Ctrl-]":"indentMore",fallthrough:"basic"}
du.macDefault={"Cmd-A":"selectAll","Cmd-D":"deleteLine","Cmd-Z":"undo","Shift-Cmd-Z":"redo","Cmd-Y":"redo","Cmd-Up":"goDocStart","Cmd-End":"goDocEnd","Cmd-Down":"goDocEnd","Alt-Left":"goGroupLeft","Alt-Right":"goGroupRight","Cmd-Left":"goLineStart","Cmd-Right":"goLineEnd","Alt-Backspace":"delGroupBefore","Ctrl-Alt-Backspace":"delGroupAfter","Alt-Delete":"delGroupAfter","Cmd-S":"save","Cmd-F":"find","Cmd-G":"findNext","Shift-Cmd-G":"findPrev","Cmd-Alt-F":"replace","Shift-Cmd-Alt-F":"replaceAll","Cmd-[":"indentLess","Cmd-]":"indentMore","Cmd-Backspace":"delLineLeft",fallthrough:["basic","emacsy"]}
du["default"]=bk?du.macDefault:du.pcDefault
du.emacsy={"Ctrl-F":"goCharRight","Ctrl-B":"goCharLeft","Ctrl-P":"goLineUp","Ctrl-N":"goLineDown","Alt-F":"goWordRight","Alt-B":"goWordLeft","Ctrl-A":"goLineStart","Ctrl-E":"goLineEnd","Ctrl-V":"goPageDown","Shift-Ctrl-V":"goPageUp","Ctrl-D":"delCharAfter","Ctrl-H":"delCharBefore","Alt-D":"delWordAfter","Alt-Backspace":"delWordBefore","Ctrl-K":"killLine","Ctrl-T":"transposeChars"}
y.lookupKey=g
y.isModifierKey=c3
y.keyName=dK
y.fromTextArea=function(er,es){function eo(){er.value=eq.getValue()}es||(es={})
es.value=er.value
!es.tabindex&&er.tabindex&&(es.tabindex=er.tabindex)
!es.placeholder&&er.placeholder&&(es.placeholder=er.placeholder)
if(null==es.autofocus){var ek=document.body
try{ek=document.activeElement}catch(em){}es.autofocus=ek==er||null!=er.getAttribute("autofocus")&&ek==document.body}if(er.form){bf(er.form,"submit",eo)
if(!es.leaveSubmitMethodAlone){var el=er.form,ep=el.submit
try{var en=el.submit=function(){eo()
el.submit=ep
el.submit()
el.submit=en}}catch(em){}}}er.style.display="none"
var eq=y(function(et){er.parentNode.insertBefore(et,er.nextSibling)},es)
eq.save=eo
eq.getTextArea=function(){return er}
eq.toTextArea=function(){eo()
er.parentNode.removeChild(eq.getWrapperElement())
er.style.display=""
if(er.form){cL(er.form,"submit",eo)
"function"==typeof er.form.submit&&(er.form.submit=ep)}}
return eq}
dh.prototype={eol:function(){return this.pos>=this.string.length},sol:function(){return 0==this.pos},peek:function(){return this.string.charAt(this.pos)||void 0},next:function(){return this.pos<this.string.length?this.string.charAt(this.pos++):void 0},eat:function(ek){var em=this.string.charAt(this.pos)
if("string"==typeof ek)var el=em==ek
else var el=em&&(ek.test?ek.test(em):ek(em))
if(el){++this.pos
return em}},eatWhile:function(ek){for(var el=this.pos;this.eat(ek););return this.pos>el},eatSpace:function(){for(var ek=this.pos;/[\s\u00a0]/.test(this.string.charAt(this.pos));)++this.pos
return this.pos>ek},skipToEnd:function(){this.pos=this.string.length},skipTo:function(ek){var el=this.string.indexOf(ek,this.pos)
if(el>-1){this.pos=el
return!0}},backUp:function(ek){this.pos-=ek},column:function(){if(this.lastColumnPos<this.start){this.lastColumnValue=bb(this.string,this.start,this.tabSize,this.lastColumnPos,this.lastColumnValue)
this.lastColumnPos=this.start}return this.lastColumnValue},indentation:function(){return bb(this.string,null,this.tabSize)},match:function(eo,el,ek){if("string"!=typeof eo){var em=this.string.slice(this.pos).match(eo)
if(em&&em.index>0)return null
em&&el!==!1&&(this.pos+=em[0].length)
return em}var ep=function(eq){return ek?eq.toLowerCase():eq},en=this.string.substr(this.pos,eo.length)
if(ep(en)==ep(eo)){el!==!1&&(this.pos+=eo.length)
return!0}},current:function(){return this.string.slice(this.start,this.pos)}}
y.StringStream=dh
y.TextMarker=E
aV(E)
E.prototype.clear=function(){if(!this.explicitlyCleared){var er=this.doc.cm,el=er&&!er.curOp
el&&bR(er)
if(dD(this,"clear")){var es=this.find()
es&&L(this,"clear",es.from,es.to)}for(var em=null,ep=null,en=0;en<this.lines.length;++en){var et=this.lines[en],eq=dt(et.markedSpans,this)
null!=eq.to&&(ep=a8(et))
et.markedSpans=db(et.markedSpans,eq)
null!=eq.from?em=a8(et):this.collapsed&&!dN(this.doc,et)&&er&&ec(et,at(er.display))}if(er&&this.collapsed&&!er.options.lineWrapping)for(var en=0;en<this.lines.length;++en){var ek=s(er.doc,this.lines[en]),eo=cR(er.doc,ek)
if(eo>er.display.maxLineLength){er.display.maxLine=ek
er.display.maxLineLength=eo
er.display.maxLineChanged=!0}}null!=em&&er&&N(er,em,ep+1)
this.lines.length=0
this.explicitlyCleared=!0
if(this.atomic&&this.doc.cantEdit){this.doc.cantEdit=!1
er&&cY(er)}el&&T(er)}}
E.prototype.find=function(){for(var ep,eo,el=0;el<this.lines.length;++el){var ek=this.lines[el],em=dt(ek.markedSpans,this)
if(null!=em.from||null!=em.to){var en=a8(ek)
null!=em.from&&(ep=H(en,em.from))
null!=em.to&&(eo=H(en,em.to))}}return"bookmark"==this.type?ep:ep&&{from:ep,to:eo}}
E.prototype.changed=function(){var en=this.find(),ek=this.doc.cm
if(en&&ek){"bookmark"!=this.type&&(en=en.from)
var el=dx(this.doc,en.line)
d0(ek,el)
if(en.line>=ek.display.showingFrom&&en.line<ek.display.showingTo){for(var em=ek.display.lineDiv.firstChild;em;em=em.nextSibling)if(em.lineObj==el){em.offsetHeight!=el.height&&ec(el,em.offsetHeight)
break}bU(ek,function(){ek.curOp.selectionChanged=ek.curOp.forceUpdate=ek.curOp.updateMaxLine=!0})}}}
E.prototype.attachLine=function(ek){if(!this.lines.length&&this.doc.cm){var el=this.doc.cm.curOp
el.maybeHiddenMarkers&&-1!=ce(el.maybeHiddenMarkers,this)||(el.maybeUnhiddenMarkers||(el.maybeUnhiddenMarkers=[])).push(this)}this.lines.push(ek)}
E.prototype.detachLine=function(ek){this.lines.splice(ce(this.lines,ek),1)
if(!this.lines.length&&this.doc.cm){var el=this.doc.cm.curOp;(el.maybeHiddenMarkers||(el.maybeHiddenMarkers=[])).push(this)}}
y.SharedTextMarker=r
aV(r)
r.prototype.clear=function(){if(!this.explicitlyCleared){this.explicitlyCleared=!0
for(var ek=0;ek<this.markers.length;++ek)this.markers[ek].clear()
L(this,"clear")}}
r.prototype.find=function(){return this.primary.find()}
var cq=y.LineWidget=function(ek,en,el){if(el)for(var em in el)el.hasOwnProperty(em)&&(this[em]=el[em])
this.cm=ek
this.node=en}
aV(cq)
cq.prototype.clear=B(function(){var el=this.line.widgets,en=a8(this.line)
if(null!=en&&el){for(var em=0;em<el.length;++em)el[em]==this&&el.splice(em--,1)
el.length||(this.line.widgets=null)
var ek=a7(this.cm,this.line)<this.cm.doc.scrollTop
ec(this.line,Math.max(0,this.line.height-bZ(this)))
ek&&bT(this.cm,0,-this.height)
N(this.cm,en,en+1)}})
cq.prototype.changed=B(function(){var ek=this.height
this.height=null
var el=bZ(this)-ek
if(el){ec(this.line,this.line.height+el)
var em=a8(this.line)
N(this.cm,em,em+1)}})
var eb=y.Line=function(em,el,ek){this.text=em
b3(this,el)
this.height=ek?ek(this):1}
aV(eb)
var cA={},b5=/[\t\u0000-\u0019\u00ad\u200b\u2028\u2029\uFEFF]/g
dm.prototype={chunkSize:function(){return this.lines.length},removeInner:function(ek,eo){for(var em=ek,en=ek+eo;en>em;++em){var el=this.lines[em]
this.height-=el.height
aX(el)
L(el,"delete")}this.lines.splice(ek,eo)},collapse:function(ek){ek.splice.apply(ek,[ek.length,0].concat(this.lines))},insertInner:function(el,em,ek){this.height+=ek
this.lines=this.lines.slice(0,el).concat(em).concat(this.lines.slice(el))
for(var en=0,eo=em.length;eo>en;++en)em[en].parent=this},iterN:function(ek,en,em){for(var el=ek+en;el>ek;++ek)if(em(this.lines[ek]))return!0}}
dO.prototype={chunkSize:function(){return this.size},removeInner:function(ek,er){this.size-=er
for(var em=0;em<this.children.length;++em){var eq=this.children[em],eo=eq.chunkSize()
if(eo>ek){var en=Math.min(er,eo-ek),ep=eq.height
eq.removeInner(ek,en)
this.height-=ep-eq.height
if(eo==en){this.children.splice(em--,1)
eq.parent=null}if(0==(er-=en))break
ek=0}else ek-=eo}if(this.size-er<25){var el=[]
this.collapse(el)
this.children=[new dm(el)]
this.children[0].parent=this}},collapse:function(ek){for(var el=0,em=this.children.length;em>el;++el)this.children[el].collapse(ek)},insertInner:function(el,es,er){this.size+=es.length
this.height+=er
for(var em=0,eo=this.children.length;eo>em;++em){var ek=this.children[em],ep=ek.chunkSize()
if(ep>=el){ek.insertInner(el,es,er)
if(ek.lines&&ek.lines.length>50){for(;ek.lines.length>50;){var en=ek.lines.splice(ek.lines.length-25,25),eq=new dm(en)
ek.height-=eq.height
this.children.splice(em+1,0,eq)
eq.parent=this}this.maybeSpill()}break}el-=ep}},maybeSpill:function(){if(!(this.children.length<=10)){var en=this
do{var el=en.children.splice(en.children.length-5,5),em=new dO(el)
if(en.parent){en.size-=em.size
en.height-=em.height
var ek=ce(en.parent.children,en)
en.parent.children.splice(ek+1,0,em)}else{var eo=new dO(en.children)
eo.parent=en
en.children=[eo,em]
en=eo}em.parent=en.parent}while(en.children.length>10)
en.parent.maybeSpill()}},iterN:function(ek,er,eq){for(var el=0,eo=this.children.length;eo>el;++el){var ep=this.children[el],en=ep.chunkSize()
if(en>ek){var em=Math.min(er,en-ek)
if(ep.iterN(ek,em,eq))return!0
if(0==(er-=em))break
ek=0}else ek-=en}}}
var bD=0,X=y.Doc=function(em,el,ek){if(!(this instanceof X))return new X(em,el,ek)
null==ek&&(ek=0)
dO.call(this,[new dm([new eb("",null)])])
this.first=ek
this.scrollTop=this.scrollLeft=0
this.cantEdit=!1
this.history=Z()
this.cleanGeneration=1
this.frontier=ek
var en=H(ek,0)
this.sel={from:en,to:en,head:en,anchor:en,shift:!1,extend:!1,goalColumn:null}
this.id=++bD
this.modeOption=el
"string"==typeof em&&(em=av(em))
dQ(this,{from:en,to:en,text:em},null,{head:en,anchor:en})}
X.prototype=bw(dO.prototype,{constructor:X,iter:function(em,el,ek){ek?this.iterN(em-this.first,el-em,ek):this.iterN(this.first,this.first+this.size,em)},insert:function(el,em){for(var ek=0,en=0,eo=em.length;eo>en;++en)ek+=em[en].height
this.insertInner(el-this.first,em,ek)},remove:function(ek,el){this.removeInner(ek-this.first,el)},getValue:function(el){var ek=ax(this,this.first,this.first+this.size)
return el===!1?ek:ek.join(el||"\n")},setValue:function(el){var em=H(this.first,0),ek=this.first+this.size-1
aG(this,{from:em,to:H(ek,dx(this,ek).text.length),text:av(el),origin:"setValue"},{head:em,anchor:em},!0)},replaceRange:function(el,en,em,ek){en=dX(this,en)
em=em?dX(this,em):en
aw(this,el,en,em,ek)},getRange:function(en,em,el){var ek=d9(this,dX(this,en),dX(this,em))
return el===!1?ek:ek.join(el||"\n")},getLine:function(el){var ek=this.getLineHandle(el)
return ek&&ek.text},setLine:function(ek,el){bn(this,ek)&&aw(this,el,H(ek,0),dX(this,H(ek)))},removeLine:function(ek){ek?aw(this,"",dX(this,H(ek-1)),dX(this,H(ek))):aw(this,"",H(0,0),dX(this,H(1,0)))},getLineHandle:function(ek){return bn(this,ek)?dx(this,ek):void 0},getLineNumber:function(ek){return a8(ek)},getLineHandleVisualStart:function(ek){"number"==typeof ek&&(ek=dx(this,ek))
return s(this,ek)},lineCount:function(){return this.size},firstLine:function(){return this.first},lastLine:function(){return this.first+this.size-1},clipPos:function(ek){return dX(this,ek)},getCursor:function(em){var el,ek=this.sel
el=null==em||"head"==em?ek.head:"anchor"==em?ek.anchor:"end"==em||em===!1?ek.to:ek.from
return bv(el)},somethingSelected:function(){return!dW(this.sel.head,this.sel.anchor)},setCursor:dR(function(ek,el,en){var em=dX(this,"number"==typeof ek?H(ek,el||0):ek)
en?d4(this,em):bd(this,em,em)}),setSelection:dR(function(el,em,ek){bd(this,dX(this,el),dX(this,em||el),ek)}),extendSelection:dR(function(em,el,ek){d4(this,dX(this,em),el&&dX(this,el),ek)}),getSelection:function(ek){return this.getRange(this.sel.from,this.sel.to,ek)},replaceSelection:function(el,em,ek){aG(this,{from:this.sel.from,to:this.sel.to,text:av(el),origin:ek},em||"around")},undo:dR(function(){bm(this,"undo")}),redo:dR(function(){bm(this,"redo")}),setExtending:function(ek){this.sel.extend=ek},historySize:function(){var ek=this.history
return{undo:ek.done.length,redo:ek.undone.length}},clearHistory:function(){this.history=Z(this.history.maxGeneration)},markClean:function(){this.cleanGeneration=this.changeGeneration()},changeGeneration:function(){this.history.lastOp=this.history.lastOrigin=null
return this.history.generation},isClean:function(ek){return this.history.generation==(ek||this.cleanGeneration)},getHistory:function(){return{done:a9(this.history.done),undone:a9(this.history.undone)}},setHistory:function(el){var ek=this.history=Z(this.history.maxGeneration)
ek.done=el.done.slice(0)
ek.undone=el.undone.slice(0)},markText:function(em,el,ek){return c8(this,dX(this,em),dX(this,el),ek,"range")},setBookmark:function(em,ek){var el={replacedWith:ek&&(null==ek.nodeType?ek.widget:ek),insertLeft:ek&&ek.insertLeft}
em=dX(this,em)
return c8(this,em,em,el,"bookmark")},findMarksAt:function(eo){eo=dX(this,eo)
var en=[],el=dx(this,eo.line).markedSpans
if(el)for(var ek=0;ek<el.length;++ek){var em=el[ek];(null==em.from||em.from<=eo.ch)&&(null==em.to||em.to>=eo.ch)&&en.push(em.marker.parent||em.marker)}return en},getAllMarks:function(){var ek=[]
this.iter(function(em){var el=em.markedSpans
if(el)for(var en=0;en<el.length;++en)null!=el[en].from&&ek.push(el[en].marker)})
return ek},posFromIndex:function(el){var ek,em=this.first
this.iter(function(en){var eo=en.text.length+1
if(eo>el){ek=el
return!0}el-=eo;++em})
return dX(this,H(em,ek))},indexFromPos:function(el){el=dX(this,el)
var ek=el.ch
if(el.line<this.first||el.ch<0)return 0
this.iter(this.first,el.line,function(em){ek+=em.text.length+1})
return ek},copy:function(ek){var el=new X(ax(this,this.first,this.first+this.size),this.modeOption,this.first)
el.scrollTop=this.scrollTop
el.scrollLeft=this.scrollLeft
el.sel={from:this.sel.from,to:this.sel.to,head:this.sel.head,anchor:this.sel.anchor,shift:this.sel.shift,extend:!1,goalColumn:this.sel.goalColumn}
if(ek){el.history.undoDepth=this.history.undoDepth
el.setHistory(this.getHistory())}return el},linkedDoc:function(ek){ek||(ek={})
var en=this.first,em=this.first+this.size
null!=ek.from&&ek.from>en&&(en=ek.from)
null!=ek.to&&ek.to<em&&(em=ek.to)
var el=new X(ax(this,en,em),ek.mode||this.modeOption,en)
ek.sharedHist&&(el.history=this.history);(this.linked||(this.linked=[])).push({doc:el,sharedHist:ek.sharedHist})
el.linked=[{doc:this,isParent:!0,sharedHist:ek.sharedHist}]
return el},unlinkDoc:function(el){el instanceof y&&(el=el.doc)
if(this.linked)for(var em=0;em<this.linked.length;++em){var en=this.linked[em]
if(en.doc==el){this.linked.splice(em,1)
el.unlinkDoc(this)
break}}if(el.history==this.history){var ek=[el.id]
cF(el,function(eo){ek.push(eo.id)},!0)
el.history=Z()
el.history.done=a9(this.history.done,ek)
el.history.undone=a9(this.history.undone,ek)}},iterLinkedDocs:function(ek){cF(this,ek)},getMode:function(){return this.mode},getEditor:function(){return this.cm}})
X.prototype.eachLine=X.prototype.iter
var d="iter insert remove copy getEditor".split(" ")
for(var a5 in X.prototype)X.prototype.hasOwnProperty(a5)&&ce(d,a5)<0&&(y.prototype[a5]=function(ek){return function(){return ek.apply(this.doc,arguments)}}(X.prototype[a5]))
aV(X)
y.e_stop=cT
y.e_preventDefault=bO
y.e_stopPropagation=ci
var aO,bE=0
y.on=bf
y.off=cL
y.signal=ae
var aJ=30,bp=y.Pass={toString:function(){return"CodeMirror.Pass"}}
ej.prototype={set:function(ek,el){clearTimeout(this.id)
this.id=setTimeout(el,ek)}}
y.countColumn=bb
var au=[""],aD=/[\u3040-\u309f\u30a0-\u30ff\u3400-\u4db5\u4e00-\u9fcc\uac00-\ud7af]/,dJ=/[\u0300-\u036F\u0483-\u0487\u0488-\u0489\u0591-\u05BD\u05BF\u05C1-\u05C2\u05C4-\u05C5\u05C7\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED\uA66F\uA670-\uA672\uA674-\uA67D\uA69F\udc00-\udfff]/
y.replaceGetRect=function(ek){ak=ek}
var dc=function(){if(bx)return!1
var ek=d7("div")
return"draggable"in ek||"dragDrop"in ek}()
bB?bo=function(el,ek){return 36==el.charCodeAt(ek-1)&&39==el.charCodeAt(ek)}:ad&&!/Version\/([6-9]|\d\d)\b/.test(navigator.userAgent)?bo=function(el,ek){return/\-[^ \-?]|\?[^ !\'\"\),.\-\/:;\?\]\}]/.test(el.slice(ek-1,ek+1))}:b1&&/Chrome\/(?:29|[3-9]\d|\d\d\d)\./.test(navigator.userAgent)?bo=function(em,ek){var el=em.charCodeAt(ek-1)
return el>=8208&&8212>=el}:b1&&(bo=function(el,ek){if(ek>1&&45==el.charCodeAt(ek-1)){if(/\w/.test(el.charAt(ek-2))&&/[^\-?\.]/.test(el.charAt(ek)))return!0
if(ek>2&&/[\d\.,]/.test(el.charAt(ek-2))&&/[\d\.,]/.test(el.charAt(ek)))return!1}return/[~!#%&*)=+}\]\\|\"\.>,:;][({[<]|-[^\-?\.\u2010-\u201f\u2026]|\?[\w~`@#$%\^&*(_=+{[|><]|…[\w~`@#$%\^&*(_=+{[><]/.test(el.slice(ek-1,ek+1))})
var cX,dY,av=3!="\n\nb".split(/\n/).length?function(ep){for(var eq=0,ek=[],eo=ep.length;eo>=eq;){var en=ep.indexOf("\n",eq);-1==en&&(en=ep.length)
var em=ep.slice(eq,"\r"==ep.charAt(en-1)?en-1:en),el=em.indexOf("\r")
if(-1!=el){ek.push(em.slice(0,el))
eq+=el+1}else{ek.push(em)
eq=en+1}}return ek}:function(ek){return ek.split(/\r\n?|\n/)}
y.splitLines=av
var aS=window.getSelection?function(el){try{return el.selectionStart!=el.selectionEnd}catch(ek){return!1}}:function(em){try{var ek=em.ownerDocument.selection.createRange()}catch(el){}return ek&&ek.parentElement()==em?0!=ek.compareEndPoints("StartToEnd",ek):!1},b8=function(){var ek=d7("div")
if("oncopy"in ek)return!0
ek.setAttribute("oncopy","return;")
return"function"==typeof ek.oncopy}(),dz={3:"Enter",8:"Backspace",9:"Tab",13:"Enter",16:"Shift",17:"Ctrl",18:"Alt",19:"Pause",20:"CapsLock",27:"Esc",32:"Space",33:"PageUp",34:"PageDown",35:"End",36:"Home",37:"Left",38:"Up",39:"Right",40:"Down",44:"PrintScrn",45:"Insert",46:"Delete",59:";",91:"Mod",92:"Mod",93:"Mod",109:"-",107:"=",127:"Delete",186:";",187:"=",188:",",189:"-",190:".",191:"/",192:"`",219:"[",220:"\\",221:"]",222:"'",63276:"PageUp",63277:"PageDown",63275:"End",63273:"Home",63234:"Left",63232:"Up",63235:"Right",63233:"Down",63302:"Insert",63272:"Delete"}
y.keyNames=dz
!function(){for(var ek=0;10>ek;ek++)dz[ek+48]=String(ek)
for(var ek=65;90>=ek;ek++)dz[ek]=String.fromCharCode(ek)
for(var ek=1;12>=ek;ek++)dz[ek+111]=dz[ek+63235]="F"+ek}()
var dp,aH=function(){function en(et){return 255>=et?eq.charAt(et):et>=1424&&1524>=et?"R":et>=1536&&1791>=et?eo.charAt(et-1536):et>=1792&&2220>=et?"r":"L"}var eq="bbbbbbbbbtstwsbbbbbbbbbbbbbbssstwNN%%%NNNNNN,N,N1111111111NNNNNNNLLLLLLLLLLLLLLLLLLLLLLLLLLNNNNNNLLLLLLLLLLLLLLLLLLLLLLLLLLNNNNbbbbbbsbbbbbbbbbbbbbbbbbbbbbbbbbb,N%%%%NNNNLNNNNN%%11NLNNN1LNNNNNLLLLLLLLLLLLLLLLLLLLLLLNLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLNLLLLLLLL",eo="rrrrrrrrrrrr,rNNmmmmmmrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrmmmmmmmmmmmmmmrrrrrrrnnnnnnnnnn%nnrrrmrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrmmmmmmmmmmmmmmmmmmmNmmmmrrrrrrrrrrrrrrrrrr",ek=/[\u0590-\u05f4\u0600-\u06ff\u0700-\u08ac]/,es=/[stwN]/,em=/[LRr]/,el=/[Lb1n]/,ep=/[1n]/,er="L"
return function(eD){if(!ek.test(eD))return!1
for(var ev,eJ=eD.length,ez=[],eI=0;eJ>eI;++eI)ez.push(ev=en(eD.charCodeAt(eI)))
for(var eI=0,eC=er;eJ>eI;++eI){var ev=ez[eI]
"m"==ev?ez[eI]=eC:eC=ev}for(var eI=0,et=er;eJ>eI;++eI){var ev=ez[eI]
if("1"==ev&&"r"==et)ez[eI]="n"
else if(em.test(ev)){et=ev
"r"==ev&&(ez[eI]="R")}}for(var eI=1,eC=ez[0];eJ-1>eI;++eI){var ev=ez[eI]
"+"==ev&&"1"==eC&&"1"==ez[eI+1]?ez[eI]="1":","!=ev||eC!=ez[eI+1]||"1"!=eC&&"n"!=eC||(ez[eI]=eC)
eC=ev}for(var eI=0;eJ>eI;++eI){var ev=ez[eI]
if(","==ev)ez[eI]="N"
else if("%"==ev){for(var ew=eI+1;eJ>ew&&"%"==ez[ew];++ew);for(var eK=eI&&"!"==ez[eI-1]||eJ-1>ew&&"1"==ez[ew]?"1":"N",eG=eI;ew>eG;++eG)ez[eG]=eK
eI=ew-1}}for(var eI=0,et=er;eJ>eI;++eI){var ev=ez[eI]
"L"==et&&"1"==ev?ez[eI]="L":em.test(ev)&&(et=ev)}for(var eI=0;eJ>eI;++eI)if(es.test(ez[eI])){for(var ew=eI+1;eJ>ew&&es.test(ez[ew]);++ew);for(var eA="L"==(eI?ez[eI-1]:er),eu="L"==(eJ-1>ew?ez[ew]:er),eK=eA||eu?"L":"R",eG=eI;ew>eG;++eG)ez[eG]=eK
eI=ew-1}for(var eE,eH=[],eI=0;eJ>eI;)if(el.test(ez[eI])){var ex=eI
for(++eI;eJ>eI&&el.test(ez[eI]);++eI);eH.push({from:ex,to:eI,level:0})}else{var ey=eI,eB=eH.length
for(++eI;eJ>eI&&"L"!=ez[eI];++eI);for(var eG=ey;eI>eG;)if(ep.test(ez[eG])){eG>ey&&eH.splice(eB,0,{from:ey,to:eG,level:1})
var eF=eG
for(++eG;eI>eG&&ep.test(ez[eG]);++eG);eH.splice(eB,0,{from:eF,to:eG,level:2})
ey=eG}else++eG
eI>ey&&eH.splice(eB,0,{from:ey,to:eI,level:1})}if(1==eH[0].level&&(eE=eD.match(/^\s+/))){eH[0].from=eE[0].length
eH.unshift({from:0,to:eE[0].length,level:0})}if(1==dV(eH).level&&(eE=eD.match(/\s+$/))){dV(eH).to-=eE[0].length
eH.push({from:eJ-eE[0].length,to:eJ,level:0})}eH[0].level!=dV(eH).level&&eH.push({from:eJ,to:eJ,level:eH[0].level})
return eH}}()
y.version="3.18.0"
return y}()
CodeMirror.defineMode("htmlembedded",function(c,e){function g(j,i){if(j.match(a,!1)){i.token=d
return h.token(j,i.scriptState)}return f.token(j,i.htmlState)}function d(j,i){if(j.match(b,!1)){i.token=g
return f.token(j,i.htmlState)}return h.token(j,i.scriptState)}var h,f,a=e.scriptStartRegex||/^<%/i,b=e.scriptEndRegex||/^%>/i
return{startState:function(){h=h||CodeMirror.getMode(c,e.scriptingModeSpec)
f=f||CodeMirror.getMode(c,"htmlmixed")
return{token:e.startOpen?d:g,htmlState:CodeMirror.startState(f),scriptState:CodeMirror.startState(h)}},token:function(j,i){return i.token(j,i)},indent:function(j,i){return j.token==g?f.indent(j.htmlState,i):h.indent?h.indent(j.scriptState,i):void 0},copyState:function(i){return{token:i.token,htmlState:CodeMirror.copyState(f,i.htmlState),scriptState:CodeMirror.copyState(h,i.scriptState)}},electricChars:"/{}:",innerMode:function(i){return i.token==d?{state:i.scriptState,mode:h}:{state:i.htmlState,mode:f}}}},"htmlmixed")
CodeMirror.defineMIME("application/x-ejs",{name:"htmlembedded",scriptingModeSpec:"javascript"})
CodeMirror.defineMIME("application/x-aspx",{name:"htmlembedded",scriptingModeSpec:"text/x-csharp"})
CodeMirror.defineMIME("application/x-jsp",{name:"htmlembedded",scriptingModeSpec:"text/x-java"})
CodeMirror.defineMIME("application/x-erb",{name:"htmlembedded",scriptingModeSpec:"ruby"})
!function(){function a(c,d){CodeMirror.changeEnd(d).line==c.lastLine()&&b(c)}function b(c){var f=""
if(c.lineCount()>1){var d=c.display.scroller.clientHeight-30,e=c.getLineHandle(c.lastLine()).height
f=d-e+"px"}if(c.state.scrollPastEndPadding!=f){c.state.scrollPastEndPadding=f
c.display.lineSpace.parentNode.style.paddingBottom=f
c.setSize()}}CodeMirror.defineOption("scrollPastEnd",!1,function(c,e,d){if(d&&d!=CodeMirror.Init){c.off("change",a)
c.display.lineSpace.parentNode.style.paddingBottom=""
c.state.scrollPastEndPadding=null}if(e){c.on("change",a)
b(c)}})}()

!function(){function splitCallback(cont,n){var countDown=n
return function(){0==--countDown&&cont()}}function ensureDeps(mode,cont){var deps=CodeMirror.modes[mode].dependencies
if(!deps)return cont()
for(var missing=[],i=0;i<deps.length;++i)CodeMirror.modes.hasOwnProperty(deps[i])||missing.push(deps[i])
if(!missing.length)return cont()
for(var split=splitCallback(cont,missing.length),i=0;i<missing.length;++i)CodeMirror.requireMode(missing[i],split)}CodeMirror.modeURL||(CodeMirror.modeURL="../mode/%N/%N.js")
var loading={}
CodeMirror.requireMode=function(mode,cont){"string"!=typeof mode&&(mode=mode.name)
if(CodeMirror.modes.hasOwnProperty(mode))return ensureDeps(mode,cont)
if(loading.hasOwnProperty(mode))return loading[mode].push(cont)
var script=document.createElement("script")
script.src=CodeMirror.modeURL.replace(/%N/g,mode)
var others=document.getElementsByTagName("script")[0]
others.parentNode.insertBefore(script,others)
var list=loading[mode]=[cont],count=0,poll=setInterval(function(){if(++count>100)return clearInterval(poll)
if(CodeMirror.modes.hasOwnProperty(mode)){clearInterval(poll)
loading[mode]=null
ensureDeps(mode,function(){for(var i=0;i<list.length;++i)list[i]()})}},200)}
CodeMirror.autoLoadMode=function(instance,mode){CodeMirror.modes.hasOwnProperty(mode)||CodeMirror.requireMode(mode,function(){instance.setOption("mode",instance.getOption("mode"))})}}()

CodeMirror.defineMode("javascript",function(config,parserConfig){function chain(stream,state,f){state.tokenize=f
return f(stream,state)}function nextUntilUnescaped(stream,end){for(var next,escaped=!1;null!=(next=stream.next());){if(next==end&&!escaped)return!1
escaped=!escaped&&"\\"==next}return escaped}function ret(tp,style,cont){type=tp
content=cont
return style}function jsTokenBase(stream,state){var ch=stream.next()
if('"'==ch||"'"==ch)return chain(stream,state,jsTokenString(ch))
if(/[\[\]{}\(\),;\:\.]/.test(ch))return ret(ch)
if("0"==ch&&stream.eat(/x/i)){stream.eatWhile(/[\da-f]/i)
return ret("number","number")}if(/\d/.test(ch)||"-"==ch&&stream.eat(/\d/)){stream.match(/^\d*(?:\.\d*)?(?:[eE][+\-]?\d+)?/)
return ret("number","number")}if("/"==ch){if(stream.eat("*"))return chain(stream,state,jsTokenComment)
if(stream.eat("/")){stream.skipToEnd()
return ret("comment","comment")}if("operator"==state.lastType||"keyword c"==state.lastType||/^[\[{}\(,;:]$/.test(state.lastType)){nextUntilUnescaped(stream,"/")
stream.eatWhile(/[gimy]/)
return ret("regexp","string-2")}stream.eatWhile(isOperatorChar)
return ret("operator",null,stream.current())}if("#"==ch){stream.skipToEnd()
return ret("error","error")}if(isOperatorChar.test(ch)){stream.eatWhile(isOperatorChar)
return ret("operator",null,stream.current())}stream.eatWhile(/[\w\$_]/)
var word=stream.current(),known=keywords.propertyIsEnumerable(word)&&keywords[word]
return known&&"."!=state.lastType?ret(known.type,known.style,word):ret("variable","variable",word)}function jsTokenString(quote){return function(stream,state){nextUntilUnescaped(stream,quote)||(state.tokenize=jsTokenBase)
return ret("string","string")}}function jsTokenComment(stream,state){for(var ch,maybeEnd=!1;ch=stream.next();){if("/"==ch&&maybeEnd){state.tokenize=jsTokenBase
break}maybeEnd="*"==ch}return ret("comment","comment")}function JSLexical(indented,column,type,align,prev,info){this.indented=indented
this.column=column
this.type=type
this.prev=prev
this.info=info
null!=align&&(this.align=align)}function inScope(state,varname){for(var v=state.localVars;v;v=v.next)if(v.name==varname)return!0}function parseJS(state,style,type,content,stream){var cc=state.cc
cx.state=state
cx.stream=stream
cx.marked=null,cx.cc=cc
state.lexical.hasOwnProperty("align")||(state.lexical.align=!0)
for(;;){var combinator=cc.length?cc.pop():jsonMode?expression:statement
if(combinator(type,content)){for(;cc.length&&cc[cc.length-1].lex;)cc.pop()()
return cx.marked?cx.marked:"variable"==type&&inScope(state,content)?"variable-2":style}}}function pass(){for(var i=arguments.length-1;i>=0;i--)cx.cc.push(arguments[i])}function cont(){pass.apply(null,arguments)
return!0}function register(varname){function inList(list){for(var v=list;v;v=v.next)if(v.name==varname)return!0
return!1}var state=cx.state
if(state.context){cx.marked="def"
if(inList(state.localVars))return
state.localVars={name:varname,next:state.localVars}}else{if(inList(state.globalVars))return
state.globalVars={name:varname,next:state.globalVars}}}function pushcontext(){cx.state.context={prev:cx.state.context,vars:cx.state.localVars}
cx.state.localVars=defaultVars}function popcontext(){cx.state.localVars=cx.state.context.vars
cx.state.context=cx.state.context.prev}function pushlex(type,info){var result=function(){var state=cx.state
state.lexical=new JSLexical(state.indented,cx.stream.column(),type,null,state.lexical,info)}
result.lex=!0
return result}function poplex(){var state=cx.state
if(state.lexical.prev){")"==state.lexical.type&&(state.indented=state.lexical.indented)
state.lexical=state.lexical.prev}}function expect(wanted){return function(type){return type==wanted?cont():";"==wanted?pass():cont(arguments.callee)}}function statement(type){return"var"==type?cont(pushlex("vardef"),vardef1,expect(";"),poplex):"keyword a"==type?cont(pushlex("form"),expression,statement,poplex):"keyword b"==type?cont(pushlex("form"),statement,poplex):"{"==type?cont(pushlex("}"),block,poplex):";"==type?cont():"if"==type?cont(pushlex("form"),expression,statement,poplex,maybeelse(cx.state.indented)):"function"==type?cont(functiondef):"for"==type?cont(pushlex("form"),expect("("),pushlex(")"),forspec1,expect(")"),poplex,statement,poplex):"variable"==type?cont(pushlex("stat"),maybelabel):"switch"==type?cont(pushlex("form"),expression,pushlex("}","switch"),expect("{"),block,poplex,poplex):"case"==type?cont(expression,expect(":")):"default"==type?cont(expect(":")):"catch"==type?cont(pushlex("form"),pushcontext,expect("("),funarg,expect(")"),statement,poplex,popcontext):pass(pushlex("stat"),expression,expect(";"),poplex)}function expression(type){return expressionInner(type,!1)}function expressionNoComma(type){return expressionInner(type,!0)}function expressionInner(type,noComma){var maybeop=noComma?maybeoperatorNoComma:maybeoperatorComma
return atomicTypes.hasOwnProperty(type)?cont(maybeop):"function"==type?cont(functiondef):"keyword c"==type?cont(noComma?maybeexpressionNoComma:maybeexpression):"("==type?cont(pushlex(")"),maybeexpression,expect(")"),poplex,maybeop):"operator"==type?cont(noComma?expressionNoComma:expression):"["==type?cont(pushlex("]"),commasep(expressionNoComma,"]"),poplex,maybeop):"{"==type?cont(pushlex("}"),commasep(objprop,"}"),poplex,maybeop):cont()}function maybeexpression(type){return type.match(/[;\}\)\],]/)?pass():pass(expression)}function maybeexpressionNoComma(type){return type.match(/[;\}\)\],]/)?pass():pass(expressionNoComma)}function maybeoperatorComma(type,value){return","==type?cont(expression):maybeoperatorNoComma(type,value,maybeoperatorComma)}function maybeoperatorNoComma(type,value,me){me||(me=maybeoperatorNoComma)
return"operator"==type?/\+\+|--/.test(value)?cont(me):"?"==value?cont(expression,expect(":"),expression):cont(expression):";"!=type?"("==type?cont(pushlex(")","call"),commasep(expressionNoComma,")"),poplex,me):"."==type?cont(property,me):"["==type?cont(pushlex("]"),expression,expect("]"),poplex,me):void 0:void 0}function maybelabel(type){return":"==type?cont(poplex,statement):pass(maybeoperatorComma,expect(";"),poplex)}function property(type){if("variable"==type){cx.marked="property"
return cont()}}function objprop(type,value){if("variable"==type){cx.marked="property"
if("get"==value||"set"==value)return cont(getterSetter)}else("number"==type||"string"==type)&&(cx.marked=type+" property")
return atomicTypes.hasOwnProperty(type)?cont(expect(":"),expressionNoComma):void 0}function getterSetter(type){if(":"==type)return cont(expression)
if("variable"!=type)return cont(expect(":"),expression)
cx.marked="property"
return cont(functiondef)}function commasep(what,end){function proceed(type){if(","==type){var lex=cx.state.lexical
"call"==lex.info&&(lex.pos=(lex.pos||0)+1)
return cont(what,proceed)}return type==end?cont():cont(expect(end))}return function(type){return type==end?cont():pass(what,proceed)}}function block(type){return"}"==type?cont():pass(statement,block)}function maybetype(type){return":"==type?cont(typedef):pass()}function typedef(type){if("variable"==type){cx.marked="variable-3"
return cont()}return pass()}function vardef1(type,value){if("variable"==type){register(value)
return isTS?cont(maybetype,vardef2):cont(vardef2)}return pass()}function vardef2(type,value){return"="==value?cont(expressionNoComma,vardef2):","==type?cont(vardef1):void 0}function maybeelse(indent){return function(type,value){if("keyword b"==type&&"else"==value){cx.state.lexical=new JSLexical(indent,0,"form",null,cx.state.lexical)
return cont(statement,poplex)}return pass()}}function forspec1(type){return"var"==type?cont(vardef1,expect(";"),forspec2):";"==type?cont(forspec2):"variable"==type?cont(formaybein):pass(expression,expect(";"),forspec2)}function formaybein(_type,value){return"in"==value?cont(expression):cont(maybeoperatorComma,forspec2)}function forspec2(type,value){return";"==type?cont(forspec3):"in"==value?cont(expression):pass(expression,expect(";"),forspec3)}function forspec3(type){")"!=type&&cont(expression)}function functiondef(type,value){if("variable"==type){register(value)
return cont(functiondef)}return"("==type?cont(pushlex(")"),pushcontext,commasep(funarg,")"),poplex,statement,popcontext):void 0}function funarg(type,value){if("variable"==type){register(value)
return isTS?cont(maybetype):cont()}}var type,content,indentUnit=config.indentUnit,jsonMode=parserConfig.json,isTS=parserConfig.typescript,keywords=function(){function kw(type){return{type:type,style:"keyword"}}var A=kw("keyword a"),B=kw("keyword b"),C=kw("keyword c"),operator=kw("operator"),atom={type:"atom",style:"atom"},jsKeywords={"if":kw("if"),"while":A,"with":A,"else":B,"do":B,"try":B,"finally":B,"return":C,"break":C,"continue":C,"new":C,"delete":C,"throw":C,"var":kw("var"),"const":kw("var"),let:kw("var"),"function":kw("function"),"catch":kw("catch"),"for":kw("for"),"switch":kw("switch"),"case":kw("case"),"default":kw("default"),"in":operator,"typeof":operator,"instanceof":operator,"true":atom,"false":atom,"null":atom,undefined:atom,NaN:atom,Infinity:atom,"this":kw("this")}
if(isTS){var type={type:"variable",style:"variable-3"},tsKeywords={"interface":kw("interface"),"class":kw("class"),"extends":kw("extends"),constructor:kw("constructor"),"public":kw("public"),"private":kw("private"),"protected":kw("protected"),"static":kw("static"),"super":kw("super"),string:type,number:type,bool:type,any:type}
for(var attr in tsKeywords)jsKeywords[attr]=tsKeywords[attr]}return jsKeywords}(),isOperatorChar=/[+\-*&%=<>!?|~^]/,atomicTypes={atom:!0,number:!0,variable:!0,string:!0,regexp:!0,"this":!0},cx={state:null,column:null,marked:null,cc:null},defaultVars={name:"this",next:{name:"arguments"}}
poplex.lex=!0
return{startState:function(basecolumn){return{tokenize:jsTokenBase,lastType:null,cc:[],lexical:new JSLexical((basecolumn||0)-indentUnit,0,"block",!1),localVars:parserConfig.localVars,globalVars:parserConfig.globalVars,context:parserConfig.localVars&&{vars:parserConfig.localVars},indented:0}},token:function(stream,state){if(stream.sol()){state.lexical.hasOwnProperty("align")||(state.lexical.align=!1)
state.indented=stream.indentation()}if(state.tokenize!=jsTokenComment&&stream.eatSpace())return null
var style=state.tokenize(stream,state)
if("comment"==type)return style
state.lastType="operator"!=type||"++"!=content&&"--"!=content?type:"incdec"
return parseJS(state,style,type,content,stream)},indent:function(state,textAfter){if(state.tokenize==jsTokenComment)return CodeMirror.Pass
if(state.tokenize!=jsTokenBase)return 0
var firstChar=textAfter&&textAfter.charAt(0),lexical=state.lexical
"stat"==lexical.type&&"}"==firstChar&&(lexical=lexical.prev)
var type=lexical.type,closing=firstChar==type
if(null!=parserConfig.statementIndent){")"==type&&lexical.prev&&"stat"==lexical.prev.type&&(lexical=lexical.prev)
if("stat"==lexical.type)return lexical.indented+parserConfig.statementIndent}return"vardef"==type?lexical.indented+("operator"==state.lastType||","==state.lastType?4:0):"form"==type&&"{"==firstChar?lexical.indented:"form"==type?lexical.indented+indentUnit:"stat"==type?lexical.indented+("operator"==state.lastType||","==state.lastType?indentUnit:0):"switch"!=lexical.info||closing?lexical.align?lexical.column+(closing?0:1):lexical.indented+(closing?0:indentUnit):lexical.indented+(/^(?:case|default)\b/.test(textAfter)?indentUnit:2*indentUnit)},electricChars:":{}",blockCommentStart:jsonMode?null:"/*",blockCommentEnd:jsonMode?null:"*/",lineComment:jsonMode?null:"//",jsonMode:jsonMode}})
CodeMirror.defineMIME("text/javascript","javascript")
CodeMirror.defineMIME("text/ecmascript","javascript")
CodeMirror.defineMIME("application/javascript","javascript")
CodeMirror.defineMIME("application/ecmascript","javascript")
CodeMirror.defineMIME("application/json",{name:"javascript",json:!0})
CodeMirror.defineMIME("application/x-json",{name:"javascript",json:!0})
CodeMirror.defineMIME("text/typescript",{name:"javascript",typescript:!0})
CodeMirror.defineMIME("application/typescript",{name:"javascript",typescript:!0})

var Firepad=function(){var firepad=firepad||{}
firepad.utils={}
firepad.utils.makeEventEmitter=function(clazz,opt_allowedEVents){clazz.prototype.allowedEvents_=opt_allowedEVents
clazz.prototype.on=function(eventType,callback,context){this.validateEventType_(eventType)
this.eventListeners_=this.eventListeners_||{}
this.eventListeners_[eventType]=this.eventListeners_[eventType]||[]
this.eventListeners_[eventType].push({callback:callback,context:context})}
clazz.prototype.off=function(eventType,callback){this.validateEventType_(eventType)
this.eventListeners_=this.eventListeners_||{}
for(var listeners=this.eventListeners_[eventType]||[],i=0;i<listeners.length;i++)if(listeners[i].callback===callback){listeners.splice(i,1)
return}}
clazz.prototype.trigger=function(eventType){this.eventListeners_=this.eventListeners_||{}
for(var listeners=this.eventListeners_[eventType]||[],i=0;i<listeners.length;i++)listeners[i].callback.apply(listeners[i].context,Array.prototype.slice.call(arguments,1))}
clazz.prototype.validateEventType_=function(eventType){if(this.allowedEvents_&&-1===this.allowedEvents_.indexOf(eventType))throw new Error('Unknown event "'+eventType+'"')}}
firepad.utils.elt=function(tag,content,attrs){var e=document.createElement(tag)
if("string"==typeof content)firepad.utils.setTextContent(e,content)
else if(content)for(var i=0;i<content.length;++i)e.appendChild(content[i])
for(var attr in attrs||{})e.setAttribute(attr,attrs[attr])
return e}
firepad.utils.setTextContent=function(e,str){e.innerHTML=""
e.appendChild(document.createTextNode(str))}
firepad.utils.on=function(emitter,type,f,capture){emitter.addEventListener?emitter.addEventListener(type,f,capture||!1):emitter.attachEvent&&emitter.attachEvent("on"+type,f)}
firepad.utils.off=function(emitter,type,f,capture){emitter.removeEventListener?emitter.removeEventListener(type,f,capture||!1):emitter.detachEvent&&emitter.detachEvent("on"+type,f)}
firepad.utils.preventDefault=function(e){e.preventDefault?e.preventDefault():e.returnValue=!1}
firepad.utils.stopPropagation=function(e){e.stopPropagation?e.stopPropagation():e.cancelBubble=!0}
firepad.utils.stopEvent=function(e){firepad.utils.preventDefault(e)
firepad.utils.stopPropagation(e)}
firepad.utils.stopEventAnd=function(fn){return function(e){fn(e)
firepad.utils.stopEvent(e)
return!1}}
firepad.utils.assert=function(b,msg){if(!b)throw new Error(msg||"assertion error")}
firepad.utils.log=function(){if("undefined"!=typeof console&&"undefined"!=typeof console.log){for(var args=["Firepad:"],i=0;i<arguments.length;i++)args.push(arguments[i])
console.log.apply(console,args)}}
var firepad=firepad||{}
firepad.Span=function(){function Span(pos,length){this.pos=pos
this.length=length}Span.prototype.end=function(){return this.pos+this.length}
return Span}()
var firepad=firepad||{}
firepad.TextOp=function(){function TextOp(type){this.type=type
this.chars=null
this.text=null
this.attributes=null
if("insert"===type){this.text=arguments[1]
utils.assert("string"==typeof this.text)
this.attributes=arguments[2]||{}
utils.assert("object"==typeof this.attributes)}else if("delete"===type){this.chars=arguments[1]
utils.assert("number"==typeof this.chars)}else if("retain"===type){this.chars=arguments[1]
utils.assert("number"==typeof this.chars)
this.attributes=arguments[2]||{}
utils.assert("object"==typeof this.attributes)}}var utils=firepad.utils
TextOp.prototype.isInsert=function(){return"insert"===this.type}
TextOp.prototype.isDelete=function(){return"delete"===this.type}
TextOp.prototype.isRetain=function(){return"retain"===this.type}
TextOp.prototype.equals=function(other){return this.type===other.type&&this.text===other.text&&this.chars===other.chars&&this.attributesEqual(other.attributes)}
TextOp.prototype.attributesEqual=function(otherAttributes){for(var attr in this.attributes)if(this.attributes[attr]!==otherAttributes[attr])return!1
for(attr in otherAttributes)if(this.attributes[attr]!==otherAttributes[attr])return!1
return!0}
TextOp.prototype.hasEmptyAttributes=function(){var empty=!0
for(var attr in this.attributes){empty=!1
break}return empty}
return TextOp}()
var firepad=firepad||{}
firepad.TextOperation=function(){"use strict"
function TextOperation(){if(!this||this.constructor!==TextOperation)return new TextOperation
this.ops=[]
this.baseLength=0
this.targetLength=0}function getSimpleOp(operation){var ops=operation.ops
switch(ops.length){case 1:return ops[0]
case 2:return ops[0].isRetain()?ops[1]:ops[1].isRetain()?ops[0]:null
case 3:if(ops[0].isRetain()&&ops[2].isRetain())return ops[1]}return null}function getStartIndex(operation){return operation.ops[0].isRetain()?operation.ops[0].chars:0}var TextOp=firepad.TextOp,utils=firepad.utils
TextOperation.prototype.equals=function(other){if(this.baseLength!==other.baseLength)return!1
if(this.targetLength!==other.targetLength)return!1
if(this.ops.length!==other.ops.length)return!1
for(var i=0;i<this.ops.length;i++)if(!this.ops[i].equals(other.ops[i]))return!1
return!0}
TextOperation.prototype.retain=function(n,attributes){if("number"!=typeof n||0>n)throw new Error("retain expects a positive integer.")
if(0===n)return this
this.baseLength+=n
this.targetLength+=n
attributes=attributes||{}
var prevOp=this.ops.length>0?this.ops[this.ops.length-1]:null
prevOp&&prevOp.isRetain()&&prevOp.attributesEqual(attributes)?prevOp.chars+=n:this.ops.push(new TextOp("retain",n,attributes))
return this}
TextOperation.prototype.insert=function(str,attributes){if("string"!=typeof str)throw new Error("insert expects a string")
if(""===str)return this
attributes=attributes||{}
this.targetLength+=str.length
var prevOp=this.ops.length>0?this.ops[this.ops.length-1]:null,prevPrevOp=this.ops.length>1?this.ops[this.ops.length-2]:null
if(prevOp&&prevOp.isInsert()&&prevOp.attributesEqual(attributes))prevOp.text+=str
else if(prevOp&&prevOp.isDelete())if(prevPrevOp&&prevPrevOp.isInsert()&&prevPrevOp.attributesEqual(attributes))prevPrevOp.text+=str
else{this.ops[this.ops.length-1]=new TextOp("insert",str,attributes)
this.ops.push(prevOp)}else this.ops.push(new TextOp("insert",str,attributes))
return this}
TextOperation.prototype["delete"]=function(n){"string"==typeof n&&(n=n.length)
if("number"!=typeof n||0>n)throw new Error("delete expects a positive integer or a string")
if(0===n)return this
this.baseLength+=n
var prevOp=this.ops.length>0?this.ops[this.ops.length-1]:null
prevOp&&prevOp.isDelete()?prevOp.chars+=n:this.ops.push(new TextOp("delete",n))
return this}
TextOperation.prototype.isNoop=function(){return 0===this.ops.length||1===this.ops.length&&this.ops[0].isRetain()&&this.ops[0].hasEmptyAttributes()}
TextOperation.prototype.clone=function(){for(var clone=new TextOperation,i=0;i<this.ops.length;i++)this.ops[i].isRetain()?clone.retain(this.ops[i].chars,this.ops[i].attributes):this.ops[i].isInsert()?clone.insert(this.ops[i].text,this.ops[i].attributes):clone["delete"](this.ops[i].chars)
return clone}
TextOperation.prototype.toString=function(){var map=Array.prototype.map||function(fn){for(var arr=this,newArr=[],i=0,l=arr.length;l>i;i++)newArr[i]=fn(arr[i])
return newArr}
return map.call(this.ops,function(op){return op.isRetain()?"retain "+op.chars:op.isInsert()?"insert '"+op.text+"'":"delete "+op.chars}).join(", ")}
TextOperation.prototype.toJSON=function(){for(var ops=[],i=0;i<this.ops.length;i++){this.ops[i].hasEmptyAttributes()||ops.push(this.ops[i].attributes)
"retain"===this.ops[i].type?ops.push(this.ops[i].chars):"insert"===this.ops[i].type?ops.push(this.ops[i].text):"delete"===this.ops[i].type&&ops.push(-this.ops[i].chars)}0===ops.length&&ops.push(0)
return ops}
TextOperation.fromJSON=function(ops){for(var o=new TextOperation,i=0,l=ops.length;l>i;i++){var op=ops[i],attributes={}
if("object"==typeof op){attributes=op
i++
op=ops[i]}if("number"==typeof op)op>0?o.retain(op,attributes):o["delete"](-op)
else{utils.assert("string"==typeof op)
o.insert(op,attributes)}}return o}
TextOperation.prototype.apply=function(str,oldAttributes,newAttributes){var operation=this
oldAttributes=oldAttributes||[]
newAttributes=newAttributes||[]
if(str.length!==operation.baseLength)throw new Error("The operation's base length must be equal to the string's length.")
for(var k,attr,newStringParts=[],j=0,oldIndex=0,ops=this.ops,i=0,l=ops.length;l>i;i++){var op=ops[i]
if(op.isRetain()){if(oldIndex+op.chars>str.length)throw new Error("Operation can't retain more characters than are left in the string.")
newStringParts[j++]=str.slice(oldIndex,oldIndex+op.chars)
for(k=0;k<op.chars;k++){var currAttributes=oldAttributes[oldIndex+k]||{},updatedAttributes={}
for(attr in currAttributes){updatedAttributes[attr]=currAttributes[attr]
utils.assert(updatedAttributes[attr]!==!1)}for(attr in op.attributes){op.attributes[attr]===!1?delete updatedAttributes[attr]:updatedAttributes[attr]=op.attributes[attr]
utils.assert(updatedAttributes[attr]!==!1)}newAttributes.push(updatedAttributes)}oldIndex+=op.chars}else if(op.isInsert()){newStringParts[j++]=op.text
for(k=0;k<op.text.length;k++){var insertedAttributes={}
for(attr in op.attributes){insertedAttributes[attr]=op.attributes[attr]
utils.assert(insertedAttributes[attr]!==!1)}newAttributes.push(insertedAttributes)}}else oldIndex+=op.chars}if(oldIndex!==str.length)throw new Error("The operation didn't operate on the whole string.")
var newString=newStringParts.join("")
utils.assert(newString.length===newAttributes.length)
return newString}
TextOperation.prototype.invert=function(str){for(var strIndex=0,inverse=new TextOperation,ops=this.ops,i=0,l=ops.length;l>i;i++){var op=ops[i]
if(op.isRetain()){inverse.retain(op.chars)
strIndex+=op.chars}else if(op.isInsert())inverse["delete"](op.text.length)
else{inverse.insert(str.slice(strIndex,strIndex+op.chars))
strIndex+=op.chars}}return inverse}
TextOperation.prototype.compose=function(operation2){function composeAttributes(first,second,firstOpIsInsert){var attr,merged={}
for(attr in first)merged[attr]=first[attr]
for(attr in second)firstOpIsInsert&&second[attr]===!1?delete merged[attr]:merged[attr]=second[attr]
return merged}var operation1=this
if(operation1.targetLength!==operation2.baseLength)throw new Error("The base length of the second operation has to be the target length of the first operation")
for(var attributes,operation=new TextOperation,ops1=operation1.clone().ops,ops2=operation2.clone().ops,i1=0,i2=0,op1=ops1[i1++],op2=ops2[i2++];;){if("undefined"==typeof op1&&"undefined"==typeof op2)break
if(op1&&op1.isDelete()){operation["delete"](op1.chars)
op1=ops1[i1++]}else if(op2&&op2.isInsert()){operation.insert(op2.text,op2.attributes)
op2=ops2[i2++]}else{if("undefined"==typeof op1)throw new Error("Cannot compose operations: first operation is too short.")
if("undefined"==typeof op2)throw new Error("Cannot compose operations: first operation is too long.")
if(op1.isRetain()&&op2.isRetain()){attributes=composeAttributes(op1.attributes,op2.attributes)
if(op1.chars>op2.chars){operation.retain(op2.chars,attributes)
op1.chars-=op2.chars
op2=ops2[i2++]}else if(op1.chars===op2.chars){operation.retain(op1.chars,attributes)
op1=ops1[i1++]
op2=ops2[i2++]}else{operation.retain(op1.chars,attributes)
op2.chars-=op1.chars
op1=ops1[i1++]}}else if(op1.isInsert()&&op2.isDelete())if(op1.text.length>op2.chars){op1.text=op1.text.slice(op2.chars)
op2=ops2[i2++]}else if(op1.text.length===op2.chars){op1=ops1[i1++]
op2=ops2[i2++]}else{op2.chars-=op1.text.length
op1=ops1[i1++]}else if(op1.isInsert()&&op2.isRetain()){attributes=composeAttributes(op1.attributes,op2.attributes,!0)
if(op1.text.length>op2.chars){operation.insert(op1.text.slice(0,op2.chars),attributes)
op1.text=op1.text.slice(op2.chars)
op2=ops2[i2++]}else if(op1.text.length===op2.chars){operation.insert(op1.text,attributes)
op1=ops1[i1++]
op2=ops2[i2++]}else{operation.insert(op1.text,attributes)
op2.chars-=op1.text.length
op1=ops1[i1++]}}else{if(!op1.isRetain()||!op2.isDelete())throw new Error("This shouldn't happen: op1: "+JSON.stringify(op1)+", op2: "+JSON.stringify(op2))
if(op1.chars>op2.chars){operation["delete"](op2.chars)
op1.chars-=op2.chars
op2=ops2[i2++]}else if(op1.chars===op2.chars){operation["delete"](op2.chars)
op1=ops1[i1++]
op2=ops2[i2++]}else{operation["delete"](op1.chars)
op2.chars-=op1.chars
op1=ops1[i1++]}}}}return operation}
TextOperation.prototype.shouldBeComposedWith=function(other){if(this.isNoop()||other.isNoop())return!0
var startA=getStartIndex(this),startB=getStartIndex(other),simpleA=getSimpleOp(this),simpleB=getSimpleOp(other)
return simpleA&&simpleB?simpleA.isInsert()&&simpleB.isInsert()?startA+simpleA.text.length===startB:simpleA.isDelete()&&simpleB.isDelete()?startB+simpleB.chars===startA||startA===startB:!1:!1}
TextOperation.prototype.shouldBeComposedWithInverted=function(other){if(this.isNoop()||other.isNoop())return!0
var startA=getStartIndex(this),startB=getStartIndex(other),simpleA=getSimpleOp(this),simpleB=getSimpleOp(other)
return simpleA&&simpleB?simpleA.isInsert()&&simpleB.isInsert()?startA+simpleA.text.length===startB||startA===startB:simpleA.isDelete()&&simpleB.isDelete()?startB+simpleB.chars===startA:!1:!1}
TextOperation.transformAttributes=function(attributes1,attributes2){var attr,attributes1prime={},attributes2prime={},allAttrs={}
for(attr in attributes1)allAttrs[attr]=!0
for(attr in attributes2)allAttrs[attr]=!0
for(attr in allAttrs){var attr1=attributes1[attr],attr2=attributes2[attr]
utils.assert(null!=attr1||null!=attr2)
null==attr1?attributes2prime[attr]=attr2:null==attr2?attributes1prime[attr]=attr1:attr1===attr2||(attributes1prime[attr]=attr1)}return[attributes1prime,attributes2prime]}
TextOperation.transform=function(operation1,operation2){if(operation1.baseLength!==operation2.baseLength)throw new Error("Both operations have to have the same base length")
for(var operation1prime=new TextOperation,operation2prime=new TextOperation,ops1=operation1.clone().ops,ops2=operation2.clone().ops,i1=0,i2=0,op1=ops1[i1++],op2=ops2[i2++];;){if("undefined"==typeof op1&&"undefined"==typeof op2)break
if(op1&&op1.isInsert()){operation1prime.insert(op1.text,op1.attributes)
operation2prime.retain(op1.text.length)
op1=ops1[i1++]}else if(op2&&op2.isInsert()){operation1prime.retain(op2.text.length)
operation2prime.insert(op2.text,op2.attributes)
op2=ops2[i2++]}else{if("undefined"==typeof op1)throw new Error("Cannot transform operations: first operation is too short.")
if("undefined"==typeof op2)throw new Error("Cannot transform operations: first operation is too long.")
var minl
if(op1.isRetain()&&op2.isRetain()){var attributesPrime=TextOperation.transformAttributes(op1.attributes,op2.attributes)
if(op1.chars>op2.chars){minl=op2.chars
op1.chars-=op2.chars
op2=ops2[i2++]}else if(op1.chars===op2.chars){minl=op2.chars
op1=ops1[i1++]
op2=ops2[i2++]}else{minl=op1.chars
op2.chars-=op1.chars
op1=ops1[i1++]}operation1prime.retain(minl,attributesPrime[0])
operation2prime.retain(minl,attributesPrime[1])}else if(op1.isDelete()&&op2.isDelete())if(op1.chars>op2.chars){op1.chars-=op2.chars
op2=ops2[i2++]}else if(op1.chars===op2.chars){op1=ops1[i1++]
op2=ops2[i2++]}else{op2.chars-=op1.chars
op1=ops1[i1++]}else if(op1.isDelete()&&op2.isRetain()){if(op1.chars>op2.chars){minl=op2.chars
op1.chars-=op2.chars
op2=ops2[i2++]}else if(op1.chars===op2.chars){minl=op2.chars
op1=ops1[i1++]
op2=ops2[i2++]}else{minl=op1.chars
op2.chars-=op1.chars
op1=ops1[i1++]}operation1prime["delete"](minl)}else{if(!op1.isRetain()||!op2.isDelete())throw new Error("The two operations aren't compatible")
if(op1.chars>op2.chars){minl=op2.chars
op1.chars-=op2.chars
op2=ops2[i2++]}else if(op1.chars===op2.chars){minl=op1.chars
op1=ops1[i1++]
op2=ops2[i2++]}else{minl=op1.chars
op2.chars-=op1.chars
op1=ops1[i1++]}operation2prime["delete"](minl)}}}return[operation1prime,operation2prime]}
return TextOperation}()
var firepad=firepad||{}
firepad.AnnotationList=function(){function assert(bool,text){if(!bool)throw new Error("AnnotationList assertion failed"+(text?": "+text:""))}function OldAnnotatedSpan(pos,node){this.pos=pos
this.length=node.length
this.annotation=node.annotation
this.attachedObject_=node.attachedObject}function NewAnnotatedSpan(pos,node){this.pos=pos
this.length=node.length
this.annotation=node.annotation
this.node_=node}function AnnotationList(changeHandler){this.head_=new Node(0,NullAnnotation)
this.changeHandler_=changeHandler}function Node(length,annotation){this.length=length
this.annotation=annotation
this.attachedObject=null
this.next=null}var Span=firepad.Span
OldAnnotatedSpan.prototype.getAttachedObject=function(){return this.attachedObject_}
NewAnnotatedSpan.prototype.attachObject=function(object){this.node_.attachedObject=object}
var NullAnnotation={equals:function(){return!1}}
AnnotationList.prototype.insertAnnotatedSpan=function(span,annotation){this.wrapOperation_(new Span(span.pos,0),function(oldPos,old){assert(!old||null===old.next)
var toInsert=new Node(span.length,annotation)
if(old){assert(span.pos>oldPos&&span.pos<oldPos+old.length)
var newNodes=new Node(0,NullAnnotation)
newNodes.next=new Node(span.pos-oldPos,old.annotation)
newNodes.next.next=toInsert
toInsert.next=new Node(oldPos+old.length-span.pos,old.annotation)
return newNodes.next}return toInsert})}
AnnotationList.prototype.removeSpan=function(removeSpan){0!==removeSpan.length&&this.wrapOperation_(removeSpan,function(oldPos,old){assert(null!==old)
var newNodes=new Node(0,NullAnnotation),current=newNodes
if(removeSpan.pos>oldPos){current.next=new Node(removeSpan.pos-oldPos,old.annotation)
current=current.next}for(;removeSpan.end()>oldPos+old.length;){oldPos+=old.length
old=old.next}var afterChars=oldPos+old.length-removeSpan.end()
afterChars>0&&(current.next=new Node(afterChars,old.annotation))
return newNodes.next})}
AnnotationList.prototype.updateSpan=function(span,updateFn){0!==span.length&&this.wrapOperation_(span,function(oldPos,old){assert(null!==old)
var newNodes=new Node(0,NullAnnotation),current=newNodes,currentPos=oldPos,beforeChars=span.pos-currentPos
assert(beforeChars<old.length)
if(beforeChars>0){current.next=new Node(beforeChars,old.annotation)
current=current.next
currentPos+=current.length}for(;null!==old&&span.end()>=oldPos+old.length;){var length=oldPos+old.length-currentPos
current.next=new Node(length,updateFn(old.annotation,length))
current=current.next
oldPos+=old.length
old=old.next
currentPos=oldPos}var updateChars=span.end()-currentPos
if(updateChars>0){assert(updateChars<old.length)
current.next=new Node(updateChars,updateFn(old.annotation,updateChars))
current=current.next
currentPos+=current.length
current.next=new Node(oldPos+old.length-currentPos,old.annotation)}return newNodes.next})}
AnnotationList.prototype.wrapOperation_=function(span,operationFn){if(span.pos<0)throw new Error("Span start cannot be negative.")
var tail,oldNodes=[],newNodes=[],res=this.getAffectedNodes_(span)
if(null!==res.start){tail=res.end.next
res.end.next=null}else tail=res.succ
var newSegment=operationFn(res.startPos,res.start),includePredInOldNodes=!1,includeSuccInOldNodes=!1
if(newSegment){this.mergeNodesWithSameAnnotations_(newSegment)
var newPos
if(res.pred&&res.pred.annotation.equals(newSegment.annotation)){includePredInOldNodes=!0
newSegment.length+=res.pred.length
res.beforePred.next=newSegment
newPos=res.predPos}else{res.beforeStart.next=newSegment
newPos=res.startPos}for(;newSegment.next;){newNodes.push(new NewAnnotatedSpan(newPos,newSegment))
newPos+=newSegment.length
newSegment=newSegment.next}if(res.succ&&res.succ.annotation.equals(newSegment.annotation)){newSegment.length+=res.succ.length
includeSuccInOldNodes=!0
newSegment.next=res.succ.next}else newSegment.next=tail
newNodes.push(new NewAnnotatedSpan(newPos,newSegment))}else if(res.pred&&res.succ&&res.pred.annotation.equals(res.succ.annotation)){includePredInOldNodes=!0
includeSuccInOldNodes=!0
newSegment=new Node(res.pred.length+res.succ.length,res.pred.annotation)
res.beforePred.next=newSegment
newSegment.next=res.succ.next
newNodes.push(new NewAnnotatedSpan(res.startPos-res.start.length,newSegment))}else res.beforeStart.next=tail
includePredInOldNodes&&oldNodes.push(new OldAnnotatedSpan(res.predPos,res.pred))
for(var oldPos=res.startPos,oldSegment=res.start;null!==oldSegment;){oldNodes.push(new OldAnnotatedSpan(oldPos,oldSegment))
oldPos+=oldSegment.length
oldSegment=oldSegment.next}includeSuccInOldNodes&&oldNodes.push(new OldAnnotatedSpan(oldPos,res.succ))
this.changeHandler_(oldNodes,newNodes)}
AnnotationList.prototype.getAffectedNodes_=function(span){for(var result={},prevprev=null,prev=this.head_,current=prev.next,currentPos=0;null!==current&&span.pos>=currentPos+current.length;){currentPos+=current.length
prevprev=prev
prev=current
current=current.next}if(null===current&&(0!==span.length||span.pos!==currentPos))throw new Error("Span start exceeds the bounds of the AnnotationList.")
result.startPos=currentPos
result.start=0===span.length&&span.pos===currentPos?null:current
result.beforeStart=prev
if(currentPos===span.pos&&currentPos>0){result.pred=prev
result.predPos=currentPos-prev.length
result.beforePred=prevprev}else result.pred=null
for(;null!==current&&span.end()>currentPos;){currentPos+=current.length
prev=current
current=current.next}if(span.end()>currentPos)throw new Error("Span end exceeds the bounds of the AnnotationList.")
result.end=0===span.length&&span.end()===currentPos?null:prev
result.succ=currentPos===span.end()?current:null
return result}
AnnotationList.prototype.mergeNodesWithSameAnnotations_=function(list){if(list)for(var prev=null,curr=list;curr;){if(prev&&prev.annotation.equals(curr.annotation)){prev.length+=curr.length
prev.next=curr.next}else prev=curr
curr=curr.next}}
AnnotationList.prototype.forEach=function(callback){for(var current=this.head_.next;null!==current;){callback(current.length,current.annotation,current.attachedObject)
current=current.next}}
AnnotationList.prototype.getAnnotatedSpansForPos=function(pos){for(var currentPos=0,current=this.head_.next,prev=null;null!==current&&currentPos+current.length<=pos;){currentPos+=current.length
prev=current
current=current.next}if(null===current&&currentPos!==pos)throw new Error("pos exceeds the bounds of the AnnotationList")
var res=[]
currentPos===pos&&prev&&res.push(new OldAnnotatedSpan(currentPos-prev.length,prev))
current&&res.push(new OldAnnotatedSpan(currentPos,current))
return res}
AnnotationList.prototype.getAnnotatedSpansForSpan=function(span){if(0===span.length)return[]
for(var oldSpans=[],res=this.getAffectedNodes_(span),currentPos=res.startPos,current=res.start;null!==current&&currentPos<span.end();){var start=Math.max(currentPos,span.pos),end=Math.min(currentPos+current.length,span.end()),oldSpan=new Span(start,end-start)
oldSpan.annotation=current.annotation
oldSpans.push(oldSpan)
currentPos+=current.length
current=current.next}return oldSpans}
AnnotationList.prototype.count=function(){for(var count=0,current=this.head_.next,prev=null;null!==current;){prev&&assert(!prev.annotation.equals(current.annotation))
prev=current
current=current.next
count++}return count}
Node.prototype.clone=function(){var node=new Node(this.spanLength,this.annotation)
node.next=this.next
return node}
return AnnotationList}()
var firepad=firepad||{}
firepad.Cursor=function(){"use strict"
function Cursor(position,selectionEnd){this.position=position
this.selectionEnd=selectionEnd}Cursor.fromJSON=function(obj){return new Cursor(obj.position,obj.selectionEnd)}
Cursor.prototype.equals=function(other){return this.position===other.position&&this.selectionEnd===other.selectionEnd}
Cursor.prototype.compose=function(other){return other}
Cursor.prototype.transform=function(other){function transformIndex(index){for(var newIndex=index,ops=other.ops,i=0,l=other.ops.length;l>i;i++){if(ops[i].isRetain())index-=ops[i].chars
else if(ops[i].isInsert())newIndex+=ops[i].text.length
else{newIndex-=Math.min(index,ops[i].chars)
index-=ops[i].chars}if(0>index)break}return newIndex}var newPosition=transformIndex(this.position)
return this.position===this.selectionEnd?new Cursor(newPosition,newPosition):new Cursor(newPosition,transformIndex(this.selectionEnd))}
return Cursor}()
var firepad=firepad||{}
firepad.FirebaseAdapter=function(){function FirebaseAdapter(ref,userId,userColor){this.ref_=ref
this.ready_=!1
this.firebaseCallbacks_=[]
this.zombie_=!1
this.document_=new TextOperation
this.revision_=0
this.pendingReceivedRevisions_={}
this.setUserId(userId)
this.setColor(userColor)
var self=this
this.firebaseOn_(ref.root().child(".info/connected"),"value",function(snapshot){snapshot.val()===!0&&self.initializeUserData_()},this)
setTimeout(function(){self.monitorHistory_()},0)
this.on("ready",function(){self.monitorCursors_()})}function assert(b,msg){if(!b)throw new Error(msg||"assertion error")}function revisionToId(revision){if(0===revision)return"A0"
for(var str="";revision>0;){var digit=revision%characters.length
str=characters[digit]+str
revision-=digit
revision/=characters.length}var prefix=characters[str.length+9]
return prefix+str}function revisionFromId(revisionId){assert(revisionId.length>0&&revisionId[0]===characters[revisionId.length+8])
for(var revision=0,i=1;i<revisionId.length;i++){revision*=characters.length
revision+=characters.indexOf(revisionId[i])}return revision}var TextOperation=firepad.TextOperation,utils=firepad.utils,CHECKPOINT_FREQUENCY=100
utils.makeEventEmitter(FirebaseAdapter,["ready","cursor","operation","ack","retry"])
FirebaseAdapter.prototype.dispose=function(){this.removeFirebaseCallbacks_()
this.userRef_.child("cursor").remove()
this.userRef_.child("color").remove()
this.ref_=null
this.document_=null
this.zombie_=!0}
FirebaseAdapter.prototype.setUserId=function(userId){if(this.userRef_){this.userRef_.child("cursor").remove()
this.userRef_.child("cursor").onDisconnect().cancel()
this.userRef_.child("color").remove()
this.userRef_.child("color").onDisconnect().cancel()}this.userId_=userId
this.userRef_=this.ref_.child("users").child(userId)
this.initializeUserData_()}
FirebaseAdapter.prototype.isHistoryEmpty=function(){assert(this.ready_,"Not ready yet.")
return 0===this.revision_}
FirebaseAdapter.prototype.sendOperation=function(operation,cursor){function doTransaction(revisionId,revisionData,cursor){self.ref_.child("history").child(revisionId).transaction(function(current){return null===current?revisionData:void 0},function(error,committed){if(error){if("disconnect"!==error.message){utils.log("Transaction failure!",error)
throw error}self.sent_&&self.sent_.id===revisionId&&setTimeout(function(){doTransaction(revisionId,revisionData,cursor)},0)}else committed&&self.sendCursor(cursor)},!1)}var self=this
if(this.ready_){assert(this.document_.targetLength===operation.baseLength,"sendOperation() called with invalid operation.")
var revisionId=revisionToId(this.revision_)
this.sent_={id:revisionId,op:operation}
doTransaction(revisionId,{a:self.userId_,o:operation.toJSON()},cursor)}else this.on("ready",function(){self.trigger("retry")})}
FirebaseAdapter.prototype.sendCursor=function(obj){this.userRef_.child("cursor").set(obj)
this.cursor_=obj}
FirebaseAdapter.prototype.setColor=function(color){this.userRef_.child("color").set(color)
this.color_=color}
FirebaseAdapter.prototype.getDocument=function(){return this.document_}
FirebaseAdapter.prototype.registerCallbacks=function(callbacks){for(var eventType in callbacks)this.on(eventType,callbacks[eventType])}
FirebaseAdapter.prototype.initializeUserData_=function(){this.userRef_.child("cursor").onDisconnect().remove()
this.userRef_.child("color").onDisconnect().remove()
this.sendCursor(this.cursor_||null)
this.setColor(this.color_||null)}
FirebaseAdapter.prototype.monitorCursors_=function(){function childChanged(childSnap){var userId=childSnap.name()
if(userId!==self.userId_){var userData=childSnap.val()
self.trigger("cursor",userId,userData.cursor,userData.color)}}var usersRef=this.ref_.child("users"),self=this,user2Callback={}
this.firebaseOn_(usersRef,"child_added",childChanged)
this.firebaseOn_(usersRef,"child_changed",childChanged)
this.firebaseOn_(usersRef,"child_removed",function(childSnap){var userId=childSnap.name()
self.firebaseOff_(childSnap.ref(),"value",user2Callback[userId])
self.trigger("cursor",userId,null)})}
FirebaseAdapter.prototype.monitorHistory_=function(){var self=this
this.ref_.child("checkpoint").once("value",function(s){if(!self.zombie_){var revisionId=s.child("id").val(),op=s.child("o").val(),author=s.child("a").val()
if(null!=op&&null!=revisionId&&null!==author){self.pendingReceivedRevisions_[revisionId]={o:op,a:author}
self.checkpointRevision_=revisionFromId(revisionId)
self.monitorHistoryStartingAt_(self.checkpointRevision_+1)}else{self.checkpointRevision_=0
self.monitorHistoryStartingAt_(self.checkpointRevision_)}}})}
FirebaseAdapter.prototype.monitorHistoryStartingAt_=function(revision){var historyRef=this.ref_.child("history").startAt(null,revisionToId(revision)),self=this
setTimeout(function(){self.firebaseOn_(historyRef,"child_added",function(revisionSnapshot){var revisionId=revisionSnapshot.name()
self.pendingReceivedRevisions_[revisionId]=revisionSnapshot.val()
self.ready_&&self.handlePendingReceivedRevisions_()})
historyRef.once("value",function(){self.handleInitialRevisions_()})},0)}
FirebaseAdapter.prototype.handleInitialRevisions_=function(){assert(!this.ready_,"Should not be called multiple times.")
this.revision_=this.checkpointRevision_
for(var revisionId=revisionToId(this.revision_),pending=this.pendingReceivedRevisions_;null!=pending[revisionId];){var revision=this.parseRevision_(pending[revisionId])
revision?this.document_=this.document_.compose(revision.operation):utils.log("Invalid operation.",this.ref_.toString(),revisionId,pending[revisionId])
delete pending[revisionId]
this.revision_++
revisionId=revisionToId(this.revision_)}this.trigger("operation",this.document_)
this.ready_=!0
var self=this
setTimeout(function(){self.trigger("ready")},0)}
FirebaseAdapter.prototype.handlePendingReceivedRevisions_=function(){for(var pending=this.pendingReceivedRevisions_,revisionId=revisionToId(this.revision_),triggerRetry=!1;null!=pending[revisionId];){this.revision_++
var revision=this.parseRevision_(pending[revisionId])
if(revision){this.document_=this.document_.compose(revision.operation)
if(this.sent_&&revisionId===this.sent_.id)if(this.sent_.op.equals(revision.operation)&&revision.author===this.userId_){0===this.revision_%CHECKPOINT_FREQUENCY&&this.saveCheckpoint_()
this.sent_=null
this.trigger("ack")}else{triggerRetry=!0
this.trigger("operation",revision.operation)}else this.trigger("operation",revision.operation)}else utils.log("Invalid operation.",this.ref_.toString(),revisionId,pending[revisionId])
delete pending[revisionId]
revisionId=revisionToId(this.revision_)}if(triggerRetry){this.sent_=null
this.trigger("retry")}}
FirebaseAdapter.prototype.parseRevision_=function(data){if("object"!=typeof data)return null
if("string"!=typeof data.a||"object"!=typeof data.o)return null
var op=null
try{op=TextOperation.fromJSON(data.o)}catch(e){return null}return op.baseLength!==this.document_.targetLength?null:{author:data.a,operation:op}}
FirebaseAdapter.prototype.saveCheckpoint_=function(){this.ref_.child("checkpoint").set({a:this.userId_,o:this.document_.toJSON(),id:revisionToId(this.revision_-1)})}
FirebaseAdapter.prototype.firebaseOn_=function(ref,eventType,callback,context){this.firebaseCallbacks_.push({ref:ref,eventType:eventType,callback:callback,context:context})
ref.on(eventType,callback,context)
return callback}
FirebaseAdapter.prototype.firebaseOff_=function(ref,eventType,callback,context){ref.off(eventType,callback,context)
for(var i=0;i<this.firebaseCallbacks_.length;i++){var l=this.firebaseCallbacks_[i]
if(l.ref===ref&&l.eventType===eventType&&l.callback===callback&&l.context===context){this.firebaseCallbacks_.splice(i,1)
break}}}
FirebaseAdapter.prototype.removeFirebaseCallbacks_=function(){for(var i=0;i<this.firebaseCallbacks_.length;i++){var l=this.firebaseCallbacks_[i]
l.ref.off(l.eventType,l.callback,l.context)}this.firebaseCallbacks_=[]}
var characters="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
return FirebaseAdapter}()
var firepad=firepad||{}
firepad.RichTextToolbar=function(){function RichTextToolbar(){this.element_=this.makeElement_()}var utils=firepad.utils
utils.makeEventEmitter(RichTextToolbar,["bold","italic","underline","font","font-size","color","unordered-list","ordered-list"])
RichTextToolbar.prototype.element=function(){return this.element_}
RichTextToolbar.prototype.makeElement_=function(){var self=this,bold=utils.elt("a","B",{"class":"firepad-btn firepad-btn-bold"})
utils.on(bold,"click",utils.stopEventAnd(function(){self.trigger("bold")}))
var italic=utils.elt("a","I",{"class":"firepad-btn firepad-btn-italic"})
utils.on(italic,"click",utils.stopEventAnd(function(){self.trigger("italic")}))
var underline=utils.elt("a","U",{"class":"firepad-btn firepad-btn-underline"})
utils.on(underline,"click",utils.stopEventAnd(function(){self.trigger("underline")}))
var ul=utils.elt("a",[utils.elt("div",[],{"class":"firepad-btn-icon"})],{"class":"firepad-btn firepad-btn-ul"})
utils.on(ul,"click",utils.stopEventAnd(function(){self.trigger("unordered-list")}))
var ol=utils.elt("a",[utils.elt("div",[],{"class":"firepad-btn-icon"})],{"class":"firepad-btn firepad-btn-ol"})
utils.on(ol,"click",utils.stopEventAnd(function(){self.trigger("ordered-list")}))
var font=this.makeFontDropdown_(),fontSize=this.makeFontSizeDropdown_(),color=this.makeColorDropdown_(),toolbar=utils.elt("div",[utils.elt("div",[font],{"class":"firepad-btn-group"}),utils.elt("div",[fontSize],{"class":"firepad-btn-group"}),utils.elt("div",[color],{"class":"firepad-btn-group"}),utils.elt("div",[bold,italic,underline],{"class":"firepad-btn-group"}),utils.elt("div",[ul,ol],{"class":"firepad-btn-group"})],{"class":"firepad-toolbar"})
return toolbar}
RichTextToolbar.prototype.makeFontDropdown_=function(){for(var fonts=["Arial","Comic Sans MS","Courier New","Impact","Times New Roman","Verdana"],items=[],i=0;i<fonts.length;i++){var content=utils.elt("span",fonts[i])
content.setAttribute("style","font-family:"+fonts[i])
items.push({content:content,value:fonts[i]})}return this.makeDropdown_("Font","font",items)}
RichTextToolbar.prototype.makeFontSizeDropdown_=function(){for(var sizes=[9,10,12,14,18,24,32,42],items=[],i=0;i<sizes.length;i++){var content=utils.elt("span",sizes[i].toString())
content.setAttribute("style","font-size:"+sizes[i]+"px; line-height:"+(sizes[i]-6)+"px;")
items.push({content:content,value:sizes[i]})}return this.makeDropdown_("Size","font-size",items)}
RichTextToolbar.prototype.makeColorDropdown_=function(){for(var colors=["black","red","green","blue","yellow","cyan","magenta","grey"],items=[],i=0;i<colors.length;i++){var content=utils.elt("div")
content.className="firepad-color-dropdown-item"
content.setAttribute("style","background-color:"+colors[i])
items.push({content:content,value:colors[i]})}return this.makeDropdown_("Color","color",items)}
RichTextToolbar.prototype.makeDropdown_=function(title,eventName,items){function showDropdown(){if(!isShown){list.style.display="block"
utils.on(document,"click",hideDropdown,!0)
isShown=!0}}function hideDropdown(){if(isShown){list.style.display=""
utils.off(document,"click",hideDropdown,!0)
isShown=!1}justDismissed=!0
setTimeout(function(){justDismissed=!1},0)}function addItem(content,value){"object"!=typeof content&&(content=document.createTextNode(String(content)))
var element=utils.elt("a",[content])
utils.on(element,"click",utils.stopEventAnd(function(){hideDropdown()
self.trigger(eventName,value)}))
list.appendChild(element)}var self=this,button=utils.elt("a",title+" â–¾",{"class":"firepad-btn firepad-dropdown"}),list=utils.elt("ul",[],{"class":"firepad-dropdown-menu"})
button.appendChild(list)
for(var isShown=!1,justDismissed=!1,i=0;i<items.length;i++){var content=items[i].content,value=items[i].value
addItem(content,value)}utils.on(button,"click",utils.stopEventAnd(function(){justDismissed||showDropdown()}))
return button}
return RichTextToolbar}()
var firepad=firepad||{}
firepad.WrappedOperation=function(){"use strict"
function WrappedOperation(operation,meta){this.wrapped=operation
this.meta=meta}function copy(source,target){for(var key in source)source.hasOwnProperty(key)&&(target[key]=source[key])}function composeMeta(a,b){if(a&&"object"==typeof a){if("function"==typeof a.compose)return a.compose(b)
var meta={}
copy(a,meta)
copy(b,meta)
return meta}return b}function transformMeta(meta,operation){return meta&&"object"==typeof meta&&"function"==typeof meta.transform?meta.transform(operation):meta}WrappedOperation.prototype.apply=function(){return this.wrapped.apply.apply(this.wrapped,arguments)}
WrappedOperation.prototype.invert=function(){var meta=this.meta
return new WrappedOperation(this.wrapped.invert.apply(this.wrapped,arguments),meta&&"object"==typeof meta&&"function"==typeof meta.invert?meta.invert.apply(meta,arguments):meta)}
WrappedOperation.prototype.compose=function(other){return new WrappedOperation(this.wrapped.compose(other.wrapped),composeMeta(this.meta,other.meta))}
WrappedOperation.transform=function(a,b){var transform=a.wrapped.constructor.transform,pair=transform(a.wrapped,b.wrapped)
return[new WrappedOperation(pair[0],transformMeta(a.meta,b.wrapped)),new WrappedOperation(pair[1],transformMeta(b.meta,a.wrapped))]}
return WrappedOperation}()
var firepad=firepad||{}
firepad.UndoManager=function(){"use strict"
function UndoManager(maxItems){this.maxItems=maxItems||50
this.state=NORMAL_STATE
this.dontCompose=!1
this.undoStack=[]
this.redoStack=[]}function transformStack(stack,operation){for(var newStack=[],Operation=operation.constructor,i=stack.length-1;i>=0;i--){var pair=Operation.transform(stack[i],operation)
"function"==typeof pair[0].isNoop&&pair[0].isNoop()||newStack.push(pair[0])
operation=pair[1]}return newStack.reverse()}var NORMAL_STATE="normal",UNDOING_STATE="undoing",REDOING_STATE="redoing"
UndoManager.prototype.add=function(operation,compose){if(this.state===UNDOING_STATE){this.redoStack.push(operation)
this.dontCompose=!0}else if(this.state===REDOING_STATE){this.undoStack.push(operation)
this.dontCompose=!0}else{var undoStack=this.undoStack
if(!this.dontCompose&&compose&&undoStack.length>0)undoStack.push(operation.compose(undoStack.pop()))
else{undoStack.push(operation)
undoStack.length>this.maxItems&&undoStack.shift()}this.dontCompose=!1
this.redoStack=[]}}
UndoManager.prototype.transform=function(operation){this.undoStack=transformStack(this.undoStack,operation)
this.redoStack=transformStack(this.redoStack,operation)}
UndoManager.prototype.performUndo=function(fn){this.state=UNDOING_STATE
if(0===this.undoStack.length)throw new Error("undo not possible")
fn(this.undoStack.pop())
this.state=NORMAL_STATE}
UndoManager.prototype.performRedo=function(fn){this.state=REDOING_STATE
if(0===this.redoStack.length)throw new Error("redo not possible")
fn(this.redoStack.pop())
this.state=NORMAL_STATE}
UndoManager.prototype.canUndo=function(){return 0!==this.undoStack.length}
UndoManager.prototype.canRedo=function(){return 0!==this.redoStack.length}
UndoManager.prototype.isUndoing=function(){return this.state===UNDOING_STATE}
UndoManager.prototype.isRedoing=function(){return this.state===REDOING_STATE}
return UndoManager}()
var firepad=firepad||{}
firepad.Client=function(){"use strict"
function Client(){this.state=synchronized_}function Synchronized(){}function AwaitingConfirm(outstanding){this.outstanding=outstanding}function AwaitingWithBuffer(outstanding,buffer){this.outstanding=outstanding
this.buffer=buffer}Client.prototype.setState=function(state){this.state=state}
Client.prototype.applyClient=function(operation){this.setState(this.state.applyClient(this,operation))}
Client.prototype.applyServer=function(operation){this.setState(this.state.applyServer(this,operation))}
Client.prototype.serverAck=function(){this.setState(this.state.serverAck(this))}
Client.prototype.transformCursor=function(cursor){return this.state.transformCursor(cursor)}
Client.prototype.serverRetry=function(){this.setState(this.state.serverRetry(this))}
Client.prototype.sendOperation=function(){throw new Error("sendOperation must be defined in child class")}
Client.prototype.applyOperation=function(){throw new Error("applyOperation must be defined in child class")}
Client.Synchronized=Synchronized
Synchronized.prototype.applyClient=function(client,operation){client.sendOperation(operation)
return new AwaitingConfirm(operation)}
Synchronized.prototype.applyServer=function(client,operation){client.applyOperation(operation)
return this}
Synchronized.prototype.serverAck=function(){throw new Error("There is no pending operation.")}
Synchronized.prototype.serverRetry=function(){throw new Error("There is no pending operation.")}
Synchronized.prototype.transformCursor=function(cursor){return cursor}
var synchronized_=new Synchronized
Client.AwaitingConfirm=AwaitingConfirm
AwaitingConfirm.prototype.applyClient=function(client,operation){return new AwaitingWithBuffer(this.outstanding,operation)}
AwaitingConfirm.prototype.applyServer=function(client,operation){var pair=operation.constructor.transform(this.outstanding,operation)
client.applyOperation(pair[1])
return new AwaitingConfirm(pair[0])}
AwaitingConfirm.prototype.serverAck=function(){return synchronized_}
AwaitingConfirm.prototype.serverRetry=function(client){client.sendOperation(this.outstanding)
return this}
AwaitingConfirm.prototype.transformCursor=function(cursor){return cursor.transform(this.outstanding)}
Client.AwaitingWithBuffer=AwaitingWithBuffer
AwaitingWithBuffer.prototype.applyClient=function(client,operation){var newBuffer=this.buffer.compose(operation)
return new AwaitingWithBuffer(this.outstanding,newBuffer)}
AwaitingWithBuffer.prototype.applyServer=function(client,operation){var transform=operation.constructor.transform,pair1=transform(this.outstanding,operation),pair2=transform(this.buffer,pair1[1])
client.applyOperation(pair2[1])
return new AwaitingWithBuffer(pair1[0],pair2[0])}
AwaitingWithBuffer.prototype.serverRetry=function(client){var outstanding=this.outstanding.compose(this.buffer)
client.sendOperation(outstanding)
return new AwaitingConfirm(outstanding)}
AwaitingWithBuffer.prototype.serverAck=function(client){client.sendOperation(this.buffer)
return new AwaitingConfirm(this.buffer)}
AwaitingWithBuffer.prototype.transformCursor=function(cursor){return cursor.transform(this.outstanding).transform(this.buffer)}
return Client}()
var firepad=firepad||{}
firepad.EditorClient=function(){"use strict"
function SelfMeta(cursorBefore,cursorAfter){this.cursorBefore=cursorBefore
this.cursorAfter=cursorAfter}function OtherClient(id,editorAdapter){this.id=id
this.editorAdapter=editorAdapter
this.li=document.createElement("li")}function EditorClient(serverAdapter,editorAdapter){Client.call(this)
this.serverAdapter=serverAdapter
this.editorAdapter=editorAdapter
this.undoManager=new UndoManager
this.clients={}
var self=this
this.editorAdapter.registerCallbacks({change:function(operation,inverse){self.onChange(operation,inverse)},cursorActivity:function(){self.onCursorActivity()},blur:function(){self.onBlur()}})
this.editorAdapter.registerUndo(function(){self.undo()})
this.editorAdapter.registerRedo(function(){self.redo()})
this.serverAdapter.registerCallbacks({ack:function(){self.serverAck()},retry:function(){self.serverRetry()},operation:function(operation){self.applyServer(operation)},cursor:function(clientId,cursor,color){var client=self.getClientObject(clientId)
if(cursor){client.setColor(color)
client.updateCursor(self.transformCursor(Cursor.fromJSON(cursor)))}else client.removeCursor()}})}function inherit(Const,Super){function F(){}F.prototype=Super.prototype
Const.prototype=new F
Const.prototype.constructor=Const}function last(arr){return arr[arr.length-1]}var Client=firepad.Client,Cursor=firepad.Cursor,UndoManager=firepad.UndoManager,WrappedOperation=firepad.WrappedOperation
SelfMeta.prototype.invert=function(){return new SelfMeta(this.cursorAfter,this.cursorBefore)}
SelfMeta.prototype.compose=function(other){return new SelfMeta(this.cursorBefore,other.cursorAfter)}
SelfMeta.prototype.transform=function(operation){return new SelfMeta(this.cursorBefore?this.cursorBefore.transform(operation):null,this.cursorAfter?this.cursorAfter.transform(operation):null)}
OtherClient.prototype.setColor=function(color){this.color=color}
OtherClient.prototype.updateCursor=function(cursor){this.removeCursor()
this.cursor=cursor
this.mark=this.editorAdapter.setOtherCursor(cursor,this.color,this.id)}
OtherClient.prototype.removeCursor=function(){this.mark&&this.mark.clear()}
inherit(EditorClient,Client)
EditorClient.prototype.getClientObject=function(clientId){var client=this.clients[clientId]
return client?client:this.clients[clientId]=new OtherClient(clientId,this.editorAdapter)}
EditorClient.prototype.applyUnredo=function(operation){this.undoManager.add(this.editorAdapter.invertOperation(operation))
this.editorAdapter.applyOperation(operation.wrapped)
this.cursor=operation.meta.cursorAfter
this.editorAdapter.setCursor(this.cursor)
this.applyClient(operation.wrapped)}
EditorClient.prototype.undo=function(){var self=this
this.undoManager.canUndo()&&this.undoManager.performUndo(function(o){self.applyUnredo(o)})}
EditorClient.prototype.redo=function(){var self=this
this.undoManager.canRedo()&&this.undoManager.performRedo(function(o){self.applyUnredo(o)})}
EditorClient.prototype.onChange=function(textOperation,inverse){var cursorBefore=this.cursor
this.updateCursor()
var compose=this.undoManager.undoStack.length>0&&inverse.shouldBeComposedWithInverted(last(this.undoManager.undoStack).wrapped),inverseMeta=new SelfMeta(this.cursor,cursorBefore)
this.undoManager.add(new WrappedOperation(inverse,inverseMeta),compose)
this.applyClient(textOperation)}
EditorClient.prototype.updateCursor=function(){this.cursor=this.editorAdapter.getCursor()}
EditorClient.prototype.onCursorActivity=function(){var oldCursor=this.cursor
this.updateCursor()
oldCursor&&this.cursor.equals(oldCursor)||this.sendCursor(this.cursor)}
EditorClient.prototype.onBlur=function(){this.cursor=null
this.sendCursor(null)}
EditorClient.prototype.sendCursor=function(cursor){this.state instanceof Client.AwaitingWithBuffer||this.serverAdapter.sendCursor(cursor)}
EditorClient.prototype.sendOperation=function(operation){this.serverAdapter.sendOperation(operation,this.cursor)}
EditorClient.prototype.applyOperation=function(operation){this.editorAdapter.applyOperation(operation)
this.updateCursor()
this.undoManager.transform(new WrappedOperation(operation,null))}
return EditorClient}()
var firepad=firepad||{}
firepad.AttributeConstants={BOLD:"b",ITALIC:"i",UNDERLINE:"u",FONT:"f",FONT_SIZE:"fs",COLOR:"c",LINE_SENTINEL:"l",LINE_INDENT:"li",LIST_TYPE:"lt"}
var firepad=firepad||{}
firepad.RichTextCodeMirror=function(){function RichTextCodeMirror(codeMirror,options){this.codeMirror=codeMirror
this.options_=options||{}
this.currentAttributes_=null
var self=this
this.annotationList_=new AnnotationList(function(oldNodes,newNodes){self.onAnnotationsChanged_(oldNodes,newNodes)})
this.initAnnotationList_()
bind(this,"onCodeMirrorChange_")
bind(this,"onCursorActivity_")
this.codeMirror.on("change",this.onCodeMirrorChange_)
this.codeMirror.on("cursorActivity",this.onCursorActivity_)
this.changeId_=0
this.outstandingChanges_={}}function RichTextAnnotation(attributes){this.attributes=attributes||{}}function emptyAttributes(attributes){for(var attr in attributes)return!1
return!0}function bind(obj,method){var fn=obj[method]
obj[method]=function(){fn.apply(obj,arguments)}}var AnnotationList=firepad.AnnotationList,Span=firepad.Span,utils=firepad.utils,ATTR=firepad.AttributeConstants,RichTextClassPrefixDefault="cmrt-",RichTextOriginPrefix="cmrt-"
utils.makeEventEmitter(RichTextCodeMirror,["change","attributesChange"])
var LineSentinelCharacter=""
RichTextCodeMirror.LineSentinelCharacter=LineSentinelCharacter
RichTextCodeMirror.prototype.detach=function(){this.codeMirror.off("change",this.onCodeMirrorChange_)
this.codeMirror.off("cursorActivity",this.onCursorActivity_)
this.clearAnnotations_()}
RichTextCodeMirror.prototype.toggleAttribute=function(attribute){if(this.emptySelection_()){var attrs=this.getCurrentAttributes_()
attrs[attribute]===!0?delete attrs[attribute]:attrs[attribute]=!0
this.currentAttributes_=attrs}else{var attributes=this.getCurrentAttributes_(),newValue=attributes[attribute]!==!0
this.setAttribute(attribute,newValue)}}
RichTextCodeMirror.prototype.setAttribute=function(attribute,value){var cm=this.codeMirror
if(this.emptySelection_()){var attrs=this.getCurrentAttributes_()
value===!1?delete attrs[attribute]:attrs[attribute]=value
this.currentAttributes_=attrs}else{this.updateTextAttributes(cm.indexFromPos(cm.getCursor("start")),cm.indexFromPos(cm.getCursor("end")),function(attributes){value===!1?delete attributes[attribute]:attributes[attribute]=value})
this.updateCurrentAttributes_()}}
RichTextCodeMirror.prototype.updateTextAttributes=function(start,end,updateFn,origin){var newChangeList={},newChange=newChangeList,pos=start,self=this
this.annotationList_.updateSpan(new Span(start,end-start),function(annotation,length){var attributes={}
for(var attr in annotation.attributes)attributes[attr]=annotation.attributes[attr]
updateFn(attributes)
var changedAttributes={},changedAttributesInverse={}
self.computeChangedAttributes_(annotation.attributes,attributes,changedAttributes,changedAttributesInverse)
if(!emptyAttributes(changedAttributes)){newChange.next={start:pos,end:pos+length,attributes:changedAttributes,attributesInverse:changedAttributesInverse,origin:origin}
newChange=newChange.next}pos+=length
return new RichTextAnnotation(attributes)})
newChangeList.next&&this.trigger("attributesChange",this,newChangeList.next)}
RichTextCodeMirror.prototype.computeChangedAttributes_=function(oldAttrs,newAttrs,changed,inverseChanged){var attr,attrs={}
for(attr in oldAttrs)attrs[attr]=!0
for(attr in newAttrs)attrs[attr]=!0
for(attr in attrs)if(attr in newAttrs)if(attr in oldAttrs){if(oldAttrs[attr]!==newAttrs[attr]){changed[attr]=newAttrs[attr]
inverseChanged[attr]=oldAttrs[attr]}}else{changed[attr]=newAttrs[attr]
inverseChanged[attr]=!1}else{changed[attr]=!1
inverseChanged[attr]=oldAttrs[attr]}}
RichTextCodeMirror.prototype.toggleLineAttribute=function(attribute,value){var newValue,currentAttributes=this.getCurrentLineAttributes_()
newValue=attribute in currentAttributes&&currentAttributes[attribute]===value?!1:value
this.setLineAttribute(attribute,newValue)}
RichTextCodeMirror.prototype.setLineAttribute=function(attribute,value){this.updateLineAttributesForSelection(function(attributes){value===!1?delete attributes[attribute]:attributes[attribute]=value})}
RichTextCodeMirror.prototype.updateLineAttributesForSelection=function(updateFn){var cm=this.codeMirror,start=cm.getCursor("start"),end=cm.getCursor("end"),startLine=start.line,endLine=end.line,endLineText=cm.getLine(endLine),endsAtBeginningOfLine=this.areLineSentinelCharacters_(endLineText.substr(0,end.ch))
endLine>startLine&&endsAtBeginningOfLine&&endLine--
this.updateLineAttributes(startLine,endLine,updateFn)}
RichTextCodeMirror.prototype.updateLineAttributes=function(startLine,endLine,updateFn){for(var line=startLine;endLine>=line;line++){var text=this.codeMirror.getLine(line),lineStartIndex=this.codeMirror.indexFromPos({line:line,ch:0})
if(text[0]!==LineSentinelCharacter){var attributes={}
attributes[ATTR.LINE_SENTINEL]=!0
updateFn(attributes)
this.insertText(lineStartIndex,LineSentinelCharacter,attributes)}else this.updateTextAttributes(lineStartIndex,lineStartIndex+1,updateFn)}}
RichTextCodeMirror.prototype.replaceText=function(start,end,text,attributes,origin){this.changeId_++
var newOrigin=RichTextOriginPrefix+this.changeId_
this.outstandingChanges_[newOrigin]={origOrigin:origin,attributes:attributes}
var cm=this.codeMirror,from=cm.posFromIndex(start),to="number"==typeof end?cm.posFromIndex(end):null
cm.replaceRange(text,from,to,newOrigin)}
RichTextCodeMirror.prototype.insertText=function(index,text,attributes,origin){this.replaceText(index,null,text,attributes,origin)}
RichTextCodeMirror.prototype.removeText=function(start,end,origin){var cm=this.codeMirror
cm.replaceRange("",cm.posFromIndex(start),cm.posFromIndex(end),origin)}
RichTextCodeMirror.prototype.getAttributeSpans=function(start,end){for(var spans=[],annotatedSpans=this.annotationList_.getAnnotatedSpansForSpan(new Span(start,end-start)),i=0;i<annotatedSpans.length;i++)spans.push({length:annotatedSpans[i].length,attributes:annotatedSpans[i].annotation.attributes})
return spans}
RichTextCodeMirror.prototype.end=function(){var lastLine=this.codeMirror.lineCount()-1
return this.codeMirror.indexFromPos({line:lastLine,ch:this.codeMirror.getLine(lastLine).length})}
RichTextCodeMirror.prototype.getText=function(start,end){var from=this.codeMirror.posFromIndex(start),to=this.codeMirror.posFromIndex(end)
return this.codeMirror.getRange(from,to)}
RichTextCodeMirror.prototype.initAnnotationList_=function(){var end=this.end()
0!==end&&this.annotationList_.insertAnnotatedSpan(new Span(0,end),new RichTextAnnotation)}
RichTextCodeMirror.prototype.onAnnotationsChanged_=function(oldNodes,newNodes){for(var marker,linesToReMark={},i=0;i<oldNodes.length;i++){var attributes=oldNodes[i].annotation.attributes
ATTR.LINE_SENTINEL in attributes&&(linesToReMark[this.codeMirror.posFromIndex(oldNodes[i].pos).line]=!0)
marker=oldNodes[i].getAttachedObject()
marker&&marker.clear()}for(i=0;i<newNodes.length;i++){var annotation=newNodes[i].annotation,className=this.getClassNameForAttributes_(annotation.attributes),forLine=ATTR.LINE_SENTINEL in annotation.attributes
if(""!==className){var from=this.codeMirror.posFromIndex(newNodes[i].pos)
if(forLine)linesToReMark[from.line]=!0
else{var to=this.codeMirror.posFromIndex(newNodes[i].pos+newNodes[i].length)
marker=this.codeMirror.markText(from,to,{className:className})
newNodes[i].attachObject(marker)}}}for(var line in linesToReMark)!function(self,lineHandle){setTimeout(function(){var lineNum=self.codeMirror.getLineNumber(lineHandle)
self.markLineSentinelCharactersForChangedLines_(lineNum,lineNum)},0)}(this,this.codeMirror.getLineHandle(Number(line)))}
RichTextCodeMirror.prototype.getClassNameForAttributes_=function(attributes){var className=""
for(var attr in attributes){var val=attributes[attr]
if(attr===ATTR.LINE_SENTINEL)firepad.utils.assert(val===!0,"LINE_SENTINEL attribute should be true if it exists.")
else{className+=" "+(this.options_.cssPrefix||RichTextClassPrefixDefault)+attr
if(val!==!0){val=val.toString().toLowerCase().replace(/[^a-z0-9-_]/g,"-")
className+="-"+val}}}return className}
RichTextCodeMirror.prototype.lineClassRemover_=function(lineNum){var cm=this.codeMirror,lineHandle=cm.getLineHandle(lineNum)
return{clear:function(){cm.removeLineClass(lineHandle,"text",".*")}}}
RichTextCodeMirror.prototype.emptySelection_=function(){var start=this.codeMirror.getCursor("start"),end=this.codeMirror.getCursor("end")
return start.line===end.line&&start.ch===end.ch}
RichTextCodeMirror.prototype.onCodeMirrorChange_=function(cm,changes){for(var newChangeList={},newChange=newChangeList,change=changes;change;){var start=this.codeMirror.indexFromPos(change.from),removedText=change.removed.join("\n")
if(removedText.length>0){for(var oldAnnotationSpans=this.annotationList_.getAnnotatedSpansForSpan(new Span(start,removedText.length)),removedTextPos=0,i=0;i<oldAnnotationSpans.length;i++){var span=oldAnnotationSpans[i]
newChange.next={start:start,end:start+span.length,removedAttributes:span.annotation.attributes,removed:removedText.substr(removedTextPos,span.length),attributes:{},text:"",origin:change.origin}
newChange=newChange.next
removedTextPos+=span.length}this.annotationList_.removeSpan(new Span(start,removedText.length))}var text=change.text.join("\n"),origin=change.origin
if(text.length>0){var attributes
if("+input"===change.origin||"paste"===change.origin)attributes=this.getCurrentAttributes_()
else if(origin in this.outstandingChanges_){attributes=this.outstandingChanges_[origin].attributes
origin=this.outstandingChanges_[origin].origOrigin
delete this.outstandingChanges_[origin]}else attributes={}
this.annotationList_.insertAnnotatedSpan(new Span(start,text.length),new RichTextAnnotation(attributes))
newChange.next={start:start,end:start,removedAttributes:{},removed:"",text:text,attributes:attributes,origin:origin}
newChange=newChange.next}change=change.next}this.markLineSentinelCharactersForChanges_(changes)
newChangeList.next&&this.trigger("change",this,newChangeList.next)}
RichTextCodeMirror.prototype.markLineSentinelCharactersForChanges_=function(changes){for(var startLine=Number.MAX_VALUE,endLine=-1,change=changes;change;){var line=change.from.line
change.from.ch
if(change.removed.length>1||change.removed[0].indexOf(LineSentinelCharacter)>=0){startLine=Math.min(startLine,line)
endLine=Math.max(endLine,line)}if(change.text.length>1){startLine=Math.min(startLine,line)
endLine=Math.max(endLine,line+change.text.length-1)}else if(change.text[0].indexOf(LineSentinelCharacter)>=0){startLine=Math.min(startLine,line)
endLine=Math.max(endLine,line)}change=change.next}this.markLineSentinelCharactersForChangedLines_(startLine,endLine)}
RichTextCodeMirror.prototype.markLineSentinelCharactersForChangedLines_=function(startLine,endLine){if(startLine<Number.MAX_VALUE)for(;startLine>0&&this.lineIsListItemOrIndented_(startLine-1);)startLine--
if(endLine>-1)for(var lineCount=this.codeMirror.lineCount();lineCount>endLine+1&&this.lineIsListItemOrIndented_(endLine+1);)endLine++
for(var listNumber=[1,1,1,1,1,1,1],cm=this.codeMirror,line=startLine;endLine>=line;line++){var text=cm.getLine(line),lineHandle=cm.getLineHandle(line)
cm.removeLineClass(lineHandle,"text",".*")
if(text.length>0)for(var markIndex=text.indexOf(LineSentinelCharacter);markIndex>=0;){for(var markStartIndex=markIndex;markIndex<text.length&&text[markIndex]===LineSentinelCharacter;){for(var marks=cm.findMarksAt({line:line,ch:markIndex}),i=0;i<marks.length;i++)marks[i].isForLineSentinel&&marks[i].clear()
markIndex++}var element=null
if(0===markStartIndex){var attributes=this.getLineAttributes_(line),listType=attributes[ATTR.LIST_TYPE],indent=attributes[ATTR.LINE_INDENT]||0
listType&&0===indent&&(indent=1)
indent>=listNumber.length&&(indent=listNumber.length-1)
if("o"===listType){element=this.makeOrderedListElement_(listNumber[indent])
listNumber[indent]++}else if("u"===listType){element=this.makeUnorderedListElement_()
listNumber[indent]=1}var className=this.getClassNameForAttributes_(attributes)
""!==className&&this.codeMirror.addLineClass(line,"text",className)
for(i=indent+1;i<listNumber.length;i++)listNumber[i]=1}var markerOptions={inclusiveLeft:!0,collapsed:!0}
element&&(markerOptions.replacedWith=element)
var marker=cm.markText({line:line,ch:markStartIndex},{line:line,ch:markIndex},markerOptions)
marker.isForLineSentinel=!0
markIndex=text.indexOf(LineSentinelCharacter,markIndex)}else for(i=0;i<listNumber.length;i++)listNumber[i]=1}}
RichTextCodeMirror.prototype.makeOrderedListElement_=function(number){return utils.elt("div",number+".",{style:"margin-left: -20px; display:inline-block; width:15px;"})}
RichTextCodeMirror.prototype.makeUnorderedListElement_=function(){return utils.elt("div","•",{style:"margin-left: -20px; display:inline-block; width:15px;"})}
RichTextCodeMirror.prototype.lineIsListItemOrIndented_=function(lineNum){var attrs=this.getLineAttributes_(lineNum)
return(attrs[ATTR.LIST_TYPE]||!1)!==!1||0!==(attrs[ATTR.LINE_INDENT]||0)}
RichTextCodeMirror.prototype.onCursorActivity_=function(){this.updateCurrentAttributes_()}
RichTextCodeMirror.prototype.getCurrentAttributes_=function(){this.currentAttributes_||this.updateCurrentAttributes_()
return this.currentAttributes_}
RichTextCodeMirror.prototype.updateCurrentAttributes_=function(){var pos,cm=this.codeMirror,anchor=cm.indexFromPos(cm.getCursor("anchor")),head=cm.indexFromPos(cm.getCursor("head"))
pos=anchor>head?head+1:head
var spans=this.annotationList_.getAnnotatedSpansForPos(pos)
this.currentAttributes_={}
var attributes={}
if(spans.length>0&&!(ATTR.LINE_SENTINEL in spans[0].annotation.attributes))attributes=spans[0].annotation.attributes
else if(spans.length>1){firepad.utils.assert(!(ATTR.LINE_SENTINEL in spans[1].annotation.attributes),"Cursor can't be between two line sentinel characters.")
attributes=spans[1].annotation.attributes}for(var attr in attributes)this.currentAttributes_[attr]=attributes[attr]
delete this.currentAttributes_.l
delete this.currentAttributes_.lt}
RichTextCodeMirror.prototype.getCurrentLineAttributes_=function(){var cm=this.codeMirror,anchor=cm.getCursor("anchor"),head=cm.getCursor("head"),line=head.line
0===head.ch&&anchor.line<head.line&&line--
return this.getLineAttributes_(line)}
RichTextCodeMirror.prototype.getLineAttributes_=function(lineNum){var attributes={},line=this.codeMirror.getLine(lineNum)
if(line.length>0&&line[0]===LineSentinelCharacter){var lineStartIndex=this.codeMirror.indexFromPos({line:lineNum,ch:0}),spans=this.annotationList_.getAnnotatedSpansForSpan(new Span(lineStartIndex,1))
firepad.utils.assert(1===spans.length)
for(var attr in spans[0].annotation.attributes)attributes[attr]=spans[0].annotation.attributes[attr]}return attributes}
RichTextCodeMirror.prototype.clearAnnotations_=function(){this.annotationList_.updateSpan(new Span(0,this.end()),function(){return new RichTextAnnotation({})})}
RichTextCodeMirror.prototype.newline=function(){var cm=this.codeMirror
if(this.emptySelection_()){var cursorLine=cm.getCursor("head").line,lineAttributes=this.getLineAttributes_(cursorLine),listType=lineAttributes[ATTR.LIST_TYPE]
if(listType&&1===cm.getLine(cursorLine).length)this.updateLineAttributes(cursorLine,cursorLine,function(attributes){delete attributes[ATTR.LIST_TYPE]
delete attributes[ATTR.LINE_INDENT]})
else{cm.replaceSelection("\n","end","+input")
listType&&this.updateLineAttributes(cursorLine+1,cursorLine+1,function(attributes){for(var attr in lineAttributes)attributes[attr]=lineAttributes[attr]})}}else cm.replaceSelection("\n","end","+input")}
RichTextCodeMirror.prototype.deleteLeft=function(){var cm=this.codeMirror,cursorPos=cm.getCursor("head"),lineAttributes=this.getLineAttributes_(cursorPos.line),listType=lineAttributes[ATTR.LIST_TYPE],indent=lineAttributes[ATTR.LINE_INDENT],backspaceAtStartOfLine=this.emptySelection_()&&1===cursorPos.ch
backspaceAtStartOfLine&&listType?this.updateLineAttributes(cursorPos.line,cursorPos.line,function(attributes){delete attributes[ATTR.LIST_TYPE]
delete attributes[ATTR.LINE_INDENT]}):backspaceAtStartOfLine&&indent&&indent>0?this.updateLineAttributes(cursorPos.line,cursorPos.line,function(attributes){attributes[ATTR.LINE_INDENT]--}):cm.deleteH(-1,"char")}
RichTextCodeMirror.prototype.deleteRight=function(){var cm=this.codeMirror,cursorPos=cm.getCursor("head"),text=cm.getLine(cursorPos.line),emptyLine=this.areLineSentinelCharacters_(text),nextLineText=cursorPos.line+1<cm.lineCount()?cm.getLine(cursorPos.line+1):""
this.emptySelection_()&&emptyLine&&nextLineText[0]===LineSentinelCharacter?cm.replaceRange("",{line:cursorPos.line,ch:0},{line:cursorPos.line+1,ch:0},"+input"):cm.deleteH(1,"char")}
RichTextCodeMirror.prototype.indent=function(){this.updateLineAttributesForSelection(function(attributes){var indent=attributes[ATTR.LINE_INDENT],listType=attributes[ATTR.LIST_TYPE]
indent&&6>indent?attributes[ATTR.LINE_INDENT]++:attributes[ATTR.LINE_INDENT]=listType?2:1})}
RichTextCodeMirror.prototype.unindent=function(){this.updateLineAttributesForSelection(function(attributes){var indent=attributes[ATTR.LINE_INDENT],listType=attributes[ATTR.LIST_TYPE]
if(indent&&indent>1)attributes[ATTR.LINE_INDENT]=indent-1
else{attributes[ATTR.LINE_INDENT]=!1
listType&&(attributes[ATTR.LIST_TYPE]=!1)}})}
RichTextCodeMirror.prototype.getText=function(){return this.codeMirror.getValue().replace(new RegExp(LineSentinelCharacter,"g"),"")}
RichTextCodeMirror.prototype.areLineSentinelCharacters_=function(text){for(var i=0;i<text.length;i++)if(text[i]!==LineSentinelCharacter)return!1
return!0}
RichTextAnnotation.prototype.equals=function(other){if(!(other instanceof RichTextAnnotation))return!1
var attr
for(attr in this.attributes)if(other.attributes[attr]!==this.attributes[attr])return!1
for(attr in other.attributes)if(other.attributes[attr]!==this.attributes[attr])return!1
return!0}
return RichTextCodeMirror}()
var firepad=firepad||{}
firepad.RichTextCodeMirrorAdapter=function(){"use strict"
function RichTextCodeMirrorAdapter(rtcm){this.rtcm=rtcm
this.cm=rtcm.codeMirror
bind(this,"onChange")
bind(this,"onAttributesChange")
bind(this,"onCursorActivity")
bind(this,"onFocus")
bind(this,"onBlur")
this.rtcm.on("change",this.onChange)
this.rtcm.on("attributesChange",this.onAttributesChange)
this.cm.on("cursorActivity",this.onCursorActivity)
this.cm.on("focus",this.onFocus)
this.cm.on("blur",this.onBlur)}function cmpPos(a,b){return a.line<b.line?-1:a.line>b.line?1:a.ch<b.ch?-1:a.ch>b.ch?1:0}function posEq(a,b){return 0===cmpPos(a,b)}function codemirrorLength(cm){var lastLine=cm.lineCount()-1
return cm.indexFromPos({line:lastLine,ch:cm.getLine(lastLine).length})}function assert(b,msg){if(!b)throw new Error(msg||"assertion error")}function bind(obj,method){var fn=obj[method]
obj[method]=function(){fn.apply(obj,arguments)}}function emptyAttributes(attrs){for(var attr in attrs)return!1
return!0}var TextOperation=firepad.TextOperation,WrappedOperation=firepad.WrappedOperation,Cursor=firepad.Cursor
RichTextCodeMirrorAdapter.prototype.detach=function(){this.rtcm.off("change",this.onChange)
this.rtcm.off("attributesChange",this.onAttributesChange)
this.cm.off("cursorActivity",this.onCursorActivity)
this.cm.off("focus",this.onFocus)
this.cm.off("blur",this.onBlur)}
RichTextCodeMirrorAdapter.operationFromCodeMirrorChange=function(change,cm){for(var changes=[],i=0;change;){changes[i++]=change
change=change.next}var docEndLength=codemirrorLength(cm),operation=(new TextOperation).retain(docEndLength),inverse=(new TextOperation).retain(docEndLength)
for(i=changes.length-1;i>=0;i--){change=changes[i]
var fromIndex=change.start,restLength=docEndLength-fromIndex-change.text.length
operation=(new TextOperation).retain(fromIndex)["delete"](change.removed.length).insert(change.text,change.attributes).retain(restLength).compose(operation)
inverse=inverse.compose((new TextOperation).retain(fromIndex)["delete"](change.text.length).insert(change.removed,change.removedAttributes).retain(restLength))
docEndLength+=change.removed.length-change.text.length}return[operation,inverse]}
RichTextCodeMirrorAdapter.operationFromAttributesChange=function(change,cm){for(var docEndLength=codemirrorLength(cm),operation=new TextOperation,inverse=new TextOperation,pos=0;change;){var toRetain=change.start-pos
assert(toRetain>=0)
operation.retain(toRetain)
inverse.retain(toRetain)
var length=change.end-change.start
operation.retain(length,change.attributes)
inverse.retain(length,change.attributesInverse)
pos=change.start+length
change=change.next}operation.retain(docEndLength-pos)
inverse.retain(docEndLength-pos)
return[operation,inverse]}
RichTextCodeMirrorAdapter.applyOperationToCodeMirror=function(operation,rtcm){rtcm.codeMirror.operation(function(){for(var ops=operation.ops,index=0,i=0,l=ops.length;l>i;i++){var op=ops[i]
if(op.isRetain()){emptyAttributes(op.attributes)||rtcm.updateTextAttributes(index,index+op.chars,function(attributes){for(var attr in op.attributes)op.attributes[attr]===!1?delete attributes[attr]:attributes[attr]=op.attributes[attr]},"RTCMADAPTER")
index+=op.chars}else if(op.isInsert()){rtcm.insertText(index,op.text,op.attributes,"RTCMADAPTER")
index+=op.text.length}else op.isDelete()&&rtcm.removeText(index,index+op.chars,"RTCMADAPTER")}})}
RichTextCodeMirrorAdapter.prototype.registerCallbacks=function(cb){this.callbacks=cb}
RichTextCodeMirrorAdapter.prototype.onChange=function(_,change){if("RTCMADAPTER"!==change.origin){var pair=RichTextCodeMirrorAdapter.operationFromCodeMirrorChange(change,this.cm)
this.trigger("change",pair[0],pair[1])}}
RichTextCodeMirrorAdapter.prototype.onAttributesChange=function(_,change){if("RTCMADAPTER"!==change.origin){var pair=RichTextCodeMirrorAdapter.operationFromAttributesChange(change,this.cm)
this.trigger("change",pair[0],pair[1])}}
RichTextCodeMirrorAdapter.prototype.onCursorActivity=RichTextCodeMirrorAdapter.prototype.onFocus=function(){this.trigger("cursorActivity")}
RichTextCodeMirrorAdapter.prototype.onBlur=function(){this.cm.somethingSelected()||this.trigger("blur")}
RichTextCodeMirrorAdapter.prototype.getValue=function(){return this.cm.getValue()}
RichTextCodeMirrorAdapter.prototype.getCursor=function(){var selectionEnd,cm=this.cm,cursorPos=cm.getCursor(),position=cm.indexFromPos(cursorPos)
if(cm.somethingSelected()){var startPos=cm.getCursor(!0),selectionEndPos=posEq(cursorPos,startPos)?cm.getCursor(!1):startPos
selectionEnd=cm.indexFromPos(selectionEndPos)}else selectionEnd=position
return new Cursor(position,selectionEnd)}
RichTextCodeMirrorAdapter.prototype.setCursor=function(cursor){this.cm.setSelection(this.cm.posFromIndex(cursor.position),this.cm.posFromIndex(cursor.selectionEnd))}
var addStyleRule=function(){if("undefined"!=typeof document){var added={},styleElement=document.createElement("style")
document.documentElement.getElementsByTagName("head")[0].appendChild(styleElement)
var styleSheet=styleElement.sheet
return function(css){if(!added[css]){added[css]=!0
styleSheet.insertRule(css,(styleSheet.cssRules||styleSheet.rules).length)}}}}()
RichTextCodeMirrorAdapter.prototype.setOtherCursor=function(cursor,color,clientId){var cursorPos=this.cm.posFromIndex(cursor.position)
if("string"==typeof color&&color.match(/^#[a-fA-F0-9]{3,6}$/)){var end=this.rtcm.end()
if("object"==typeof cursor&&"number"==typeof cursor.position&&"number"==typeof cursor.selectionEnd&&!(cursor.position<0||cursor.position>end||cursor.selectionEnd<0||cursor.selectionEnd>end)){if(cursor.position===cursor.selectionEnd){var cursorCoords=this.cm.cursorCoords(cursorPos),cursorEl=document.createElement("pre")
cursorEl.className="other-client"
cursorEl.style.borderLeftWidth="2px"
cursorEl.style.borderLeftStyle="solid"
cursorEl.innerHTML="&nbsp;"
cursorEl.style.borderLeftColor=color
cursorEl.style.height=.9*(cursorCoords.bottom-cursorCoords.top)+"px"
cursorEl.style.marginTop=cursorCoords.top-cursorCoords.bottom+"px"
cursorEl.setAttribute("data-clientid",clientId)
cursorEl.style.zIndex=0
this.cm.addWidget(cursorPos,cursorEl,!1)
return{clear:function(){var parent=cursorEl.parentNode
parent&&parent.removeChild(cursorEl)}}}var selectionClassName="selection-"+color.replace("#",""),rule="."+selectionClassName+" { background: "+color+"; }"
addStyleRule(rule)
var fromPos,toPos
if(cursor.selectionEnd>cursor.position){fromPos=cursorPos
toPos=this.cm.posFromIndex(cursor.selectionEnd)}else{fromPos=this.cm.posFromIndex(cursor.selectionEnd)
toPos=cursorPos}return this.cm.markText(fromPos,toPos,{className:selectionClassName})}}}
RichTextCodeMirrorAdapter.prototype.trigger=function(event){var args=Array.prototype.slice.call(arguments,1),action=this.callbacks&&this.callbacks[event]
action&&action.apply(this,args)}
RichTextCodeMirrorAdapter.prototype.applyOperation=function(operation){RichTextCodeMirrorAdapter.applyOperationToCodeMirror(operation,this.rtcm)}
RichTextCodeMirrorAdapter.prototype.registerUndo=function(undoFn){this.cm.undo=undoFn}
RichTextCodeMirrorAdapter.prototype.registerRedo=function(redoFn){this.cm.redo=redoFn}
RichTextCodeMirrorAdapter.prototype.invertOperation=function(operation){for(var spans,i,pos=0,cm=this.rtcm.codeMirror,inverse=new TextOperation,opIndex=0;opIndex<operation.wrapped.ops.length;opIndex++){var op=operation.wrapped.ops[opIndex]
if(op.isRetain())if(emptyAttributes(op.attributes)){inverse.retain(op.chars)
pos+=op.chars}else{spans=this.rtcm.getAttributeSpans(pos,pos+op.chars)
for(i=0;i<spans.length;i++){var inverseAttributes={}
for(var attr in op.attributes){var opValue=op.attributes[attr],curValue=spans[i].attributes[attr]
opValue===!1?curValue&&(inverseAttributes[attr]=curValue):opValue!==curValue&&(inverseAttributes[attr]=curValue||!1)}inverse.retain(spans[i].length,inverseAttributes)
pos+=spans[i].length}}else if(op.isInsert())inverse["delete"](op.text.length)
else if(op.isDelete()){var text=cm.getRange(cm.posFromIndex(pos),cm.posFromIndex(pos+op.chars))
spans=this.rtcm.getAttributeSpans(pos,pos+op.chars)
var delTextPos=0
for(i=0;i<spans.length;i++){inverse.insert(text.substr(delTextPos,spans[i].length),spans[i].attributes)
delTextPos+=spans[i].length}pos+=op.chars}}return new WrappedOperation(inverse,operation.meta.invert())}
return RichTextCodeMirrorAdapter}()
var firepad=firepad||{}
firepad.Formatting=function(){function Formatting(attributes){if(!(this instanceof Formatting))return new Formatting(attributes)
this.attributes=attributes||{}
return void 0}var ATTR=firepad.AttributeConstants
Formatting.prototype.cloneWithNewAttribute_=function(attribute,value){var attributes={}
for(var attr in this.attributes)attributes[attr]=this.attributes[attr]
value===!1?delete attributes[attribute]:attributes[attribute]=value
return new Formatting(attributes)}
Formatting.prototype.bold=function(val){return this.cloneWithNewAttribute_(ATTR.BOLD,val)}
Formatting.prototype.italic=function(val){return this.cloneWithNewAttribute_(ATTR.ITALIC,val)}
Formatting.prototype.underline=function(val){return this.cloneWithNewAttribute_(ATTR.UNDERLINE,val)}
Formatting.prototype.font=function(font){return this.cloneWithNewAttribute_(ATTR.FONT,font)}
Formatting.prototype.fontSize=function(size){return this.cloneWithNewAttribute_(ATTR.FONT_SIZE,size)}
Formatting.prototype.color=function(color){return this.cloneWithNewAttribute_(ATTR.COLOR,color)}
return Formatting}()
var firepad=firepad||{}
firepad.Text=function(){function Text(text,formatting){if(!(this instanceof Text))return new Text(text,formatting)
this.text=text
this.formatting=formatting||firepad.Formatting()}return Text}()
var firepad=firepad||{}
firepad.LineFormatting=function(){function LineFormatting(attributes){if(!(this instanceof LineFormatting))return new LineFormatting(attributes)
this.attributes=attributes||{}
this.attributes[ATTR.LINE_SENTINEL]=!0}var ATTR=firepad.AttributeConstants
LineFormatting.LIST_TYPE={NONE:!1,ORDERED:"o",UNORDERED:"u"}
LineFormatting.prototype.cloneWithNewAttribute_=function(attribute,value){var attributes={}
for(var attr in this.attributes)attributes[attr]=this.attributes[attr]
value===!1?delete attributes[attribute]:attributes[attribute]=value
return new LineFormatting(attributes)}
LineFormatting.prototype.indent=function(indent){return this.cloneWithNewAttribute_(ATTR.LINE_INDENT,indent)}
LineFormatting.prototype.listItem=function(val){firepad.utils.assert(val===!1||"u"===val||"o"===val)
return this.cloneWithNewAttribute_(ATTR.LIST_TYPE,val)}
LineFormatting.prototype.getIndent=function(){return this.attributes[ATTR.LINE_INDENT]||0}
LineFormatting.prototype.getListItem=function(){return this.attributes[ATTR.LIST_TYPE]||!1}
return LineFormatting}()
var firepad=firepad||{}
firepad.Line=function(){function Line(textPieces,formatting){if(!(this instanceof Line))return new Line(textPieces,formatting)
"[object Array]"!==Object.prototype.toString.call(textPieces)&&(textPieces="undefined"==typeof textPieces?[]:[textPieces])
this.textPieces=textPieces
this.formatting=formatting||firepad.LineFormatting()}return Line}()
var firepad=firepad||{}
firepad.ParseHtml=function(){function ParseState(opt_listType,opt_lineFormatting,opt_textFormatting){this.listType=opt_listType||LIST_TYPE.UNORDERED
this.lineFormatting=opt_lineFormatting||firepad.LineFormatting()
this.textFormatting=opt_textFormatting||firepad.Formatting()}function ParseOutput(){this.lines=[]
this.currentLine=[]
this.currentLineListItemType=null}function parseHtml(html){var div=document.createElement("div")
div.innerHTML=html
var output=new ParseOutput,state=new ParseState
parseNode(div,state,output)
return output.lines}function parseNode(node,state,output){switch(node.nodeType){case Node.TEXT_NODE:var text=node.nodeValue.replace(/\s+/g," ")
output.currentLine.push(firepad.Text(text,state.textFormatting))
break
case Node.ELEMENT_NODE:var style=node.getAttribute("style")||""
state=state.withTextFormatting(parseStyle(state.textFormatting,style))
switch(node.nodeName.toLowerCase()){case"div":case"h1":case"h2":case"h3":case"p":output.newlineIfNonEmpty(state)
parseChildren(node,state,output)
output.newlineIfNonEmpty(state)
break
case"b":case"strong":parseChildren(node,state.withTextFormatting(state.textFormatting.bold(!0)),output)
break
case"u":parseChildren(node,state.withTextFormatting(state.textFormatting.underline(!0)),output)
break
case"i":case"em":parseChildren(node,state.withTextFormatting(state.textFormatting.italic(!0)),output)
break
case"font":var face=node.getAttribute("face"),color=node.getAttribute("color"),size=parseInt(node.getAttribute("size"))
face&&(state=state.withTextFormatting(state.textFormatting.font(face)))
color&&(state=state.withTextFormatting(state.textFormatting.color(color)))
size&&(state=state.withTextFormatting(state.textFormatting.fontSize(size)))
parseChildren(node,state,output)
break
case"br":output.newline(state)
break
case"ul":output.newlineIfNonEmptyOrListItem(state)
parseChildren(node,state.withListType(LIST_TYPE.UNORDERED).withIncreasedIndent(),output)
output.newlineIfNonEmpty(state)
break
case"ol":output.newlineIfNonEmptyOrListItem(state)
parseChildren(node,state.withListType(LIST_TYPE.ORDERED).withIncreasedIndent(),output)
output.newlineIfNonEmpty(state)
break
case"li":parseListItem(node,state,output)
break
default:parseChildren(node,state,output)}}}function parseChildren(node,state,output){if(node.hasChildNodes())for(var i=0;i<node.childNodes.length;i++)parseNode(node.childNodes[i],state,output)}function parseListItem(node,state,output){output.newlineIfNonEmptyOrListItem(state)
output.makeListItem(state.listType)
var oldLine=output.currentLine
parseChildren(node,state,output);(oldLine===output.currentLine||output.currentLine.length>0)&&output.newline(state)}function parseStyle(formatting,styleString){for(var styles=styleString.split(";"),i=0;i<styles.length;i++){var stylePieces=styles[i].split(":")
if(2===stylePieces.length){var prop=stylePieces[0].trim().toLowerCase(),val=stylePieces[1].trim()
switch(prop){case"text-decoration":var underline=val.indexOf("underline")>=0
formatting=formatting.underline(underline)
break
case"font-weight":var bold="bold"===val||parseInt(val)>=600
formatting=formatting.bold(bold)
break
case"font-style":var italic="italic"===val||"oblique"===val
formatting=formatting.italic(italic)
break
case"color":formatting=formatting.color(val.toLowerCase())
break
case"font-size":switch(val){case"xx-small":formatting=formatting.fontSize(9)
break
case"x-small":formatting=formatting.fontSize(10)
break
case"small":formatting=formatting.fontSize(12)
break
case"medium":formatting=formatting.fontSize(14)
break
case"large":formatting=formatting.fontSize(18)
break
case"x-large":formatting=formatting.fontSize(24)
break
case"xx-large":formatting=formatting.fontSize(32)
break
default:formatting=formatting.fontSize(parseInt(val))}break
case"font-family":var font=val.split(",")[0].trim()
font=font.replace(/['"]/g,"")
formatting=formatting.font(font)}}}return formatting}var LIST_TYPE=firepad.LineFormatting.LIST_TYPE
ParseState.prototype.withTextFormatting=function(textFormatting){return new ParseState(this.listType,this.lineFormatting,textFormatting)}
ParseState.prototype.withLineFormatting=function(lineFormatting){return new ParseState(this.listType,lineFormatting,this.textFormatting)}
ParseState.prototype.withListType=function(listType){return new ParseState(listType,this.lineFormatting,this.textFormatting)}
ParseState.prototype.withIncreasedIndent=function(){var lineFormatting=this.lineFormatting.indent(this.lineFormatting.getIndent()+1)
return new ParseState(this.listType,lineFormatting,this.textFormatting)}
ParseOutput.prototype.newlineIfNonEmpty=function(state){this.currentLine.length>0&&this.newline(state)}
ParseOutput.prototype.newlineIfNonEmptyOrListItem=function(state){(this.currentLine.length>0||null!==this.currentLineListItemType)&&this.newline(state)}
ParseOutput.prototype.newline=function(state){var lineFormatting=state.lineFormatting
if(null!==this.currentLineListItemType){lineFormatting=lineFormatting.listItem(this.currentLineListItemType)
this.currentLineListItemType=null}this.lines.push(firepad.Line(this.currentLine,lineFormatting))
this.currentLine=[]}
ParseOutput.prototype.makeListItem=function(type){this.currentLineListItemType=type}
ParseOutput.prototype.isListItem=function(){return null!==this.currentLineListItemType}
return parseHtml}()
var firepad=firepad||{}
firepad.Firepad=function(global){function Firepad(ref,place,options){if(!(this instanceof Firepad))return new Firepad(ref,place,options)
if(!CodeMirror)throw new Error("Couldn't find CodeMirror.  Did you forget to include codemirror.js?")
if(place instanceof CodeMirror){this.codeMirror_=place
var curValue=this.codeMirror_.getValue()
if(""!==curValue)throw new Error("Can't initialize Firepad with a CodeMirror instance that already contains text.")}else this.codeMirror_=new CodeMirror(place)
var cmWrapper=this.codeMirror_.getWrapperElement()
this.firepadWrapper_=utils.elt("div",null,{"class":"firepad"})
cmWrapper.parentNode.replaceChild(this.firepadWrapper_,cmWrapper)
this.firepadWrapper_.appendChild(cmWrapper)
this.codeMirror_.firepad=this
this.options_=options||{}
if(this.getOption("richTextShortcuts",!1)){CodeMirror.keyMap.richtext||this.initializeKeyMap_()
this.codeMirror_.setOption("keyMap","richtext")
this.firepadWrapper_.className+=" firepad-richtext"}if(this.getOption("richTextToolbar",!1)){this.addToolbar_()
this.firepadWrapper_.className+=" firepad-richtext firepad-with-toolbar"}this.addPoweredByLogo_()
this.codeMirror_.refresh()
var userId=this.getOption("userId",ref.push().name()),userColor=this.getOption("userColor",colorFromUserId(userId))
this.richTextCodeMirror_=new RichTextCodeMirror(this.codeMirror_,{cssPrefix:"firepad-"})
this.firebaseAdapter_=new FirebaseAdapter(ref,userId,userColor)
this.cmAdapter_=new RichTextCodeMirrorAdapter(this.richTextCodeMirror_)
this.client_=new EditorClient(this.firebaseAdapter_,this.cmAdapter_)
var self=this
this.firebaseAdapter_.on("ready",function(){self.ready_=!0
self.trigger("ready")})}function colorFromUserId(userId){for(var a=1,i=0;i<userId.length;i++)a=17*(a+userId.charCodeAt(i))%360
var hue=a/360
return hsl2hex(hue,1,.85)}function rgb2hex(r,g,b){function digits(n){var m=Math.round(255*n).toString(16)
return 1===m.length?"0"+m:m}return"#"+digits(r)+digits(g)+digits(b)}function hsl2hex(h,s,l){if(0===s)return rgb2hex(l,l,l)
var var2=.5>l?l*(1+s):l+s-s*l,var1=2*l-var2,hue2rgb=function(hue){0>hue&&(hue+=1)
hue>1&&(hue-=1)
return 1>6*hue?var1+6*(var2-var1)*hue:1>2*hue?var2:2>3*hue?var1+6*(var2-var1)*(2/3-hue):var1}
return rgb2hex(hue2rgb(h+1/3),hue2rgb(h),hue2rgb(h-1/3))}var RichTextCodeMirrorAdapter=firepad.RichTextCodeMirrorAdapter,RichTextCodeMirror=firepad.RichTextCodeMirror,RichTextToolbar=firepad.RichTextToolbar,FirebaseAdapter=firepad.FirebaseAdapter,EditorClient=firepad.EditorClient,ATTR=firepad.AttributeConstants,utils=firepad.utils,LIST_TYPE=firepad.LineFormatting.LIST_TYPE,CodeMirror=global.CodeMirror
utils.makeEventEmitter(Firepad)
Firepad.fromCodeMirror=Firepad
Firepad.prototype.dispose=function(){this.zombie_=!0
var cmWrapper=this.codeMirror_.getWrapperElement()
this.firepadWrapper_.removeChild(cmWrapper)
this.firepadWrapper_.parentNode.replaceChild(cmWrapper,this.firepadWrapper_)
this.codeMirror_.firepad=null
"richtext"===this.codeMirror_.getOption("keyMap")&&this.codeMirror_.setOption("keyMap","default")
this.firebaseAdapter_.dispose()
this.cmAdapter_.detach()
this.richTextCodeMirror_.detach()}
Firepad.prototype.setUserId=function(userId){this.firebaseAdapter_.setUserId(userId)}
Firepad.prototype.setUserColor=function(color){this.firebaseAdapter_.setColor(color)}
Firepad.prototype.getText=function(){this.assertReady_("getText")
return this.richTextCodeMirror_.getText()}
Firepad.prototype.setText=function(textPieces){function insert(string,attributes){self.richTextCodeMirror_.insertText(end,string,attributes||null)
end+=string.length
atNewLine="\n"===string[string.length-1]}function insertTextOrString(x){if(x instanceof firepad.Text)insert(x.text,x.formatting.attributes)
else{if("string"!=typeof x){console.error("Can't insert into firepad",x)
throw"Can't insert into firepad: "+x}insert(x)}}function insertLine(line){atNewLine||insert("\n")
insert(RichTextCodeMirror.LineSentinelCharacter,line.formatting.attributes)
for(var i=0;i<line.textPieces.length;i++)insertTextOrString(line.textPieces[i])
insert("\n")}this.assertReady_("setText")
"[object Array]"!==Object.prototype.toString.call(textPieces)&&(textPieces=[textPieces])
this.codeMirror_.setValue("")
for(var end=0,atNewLine=!0,self=this,i=0;i<textPieces.length;i++)textPieces[i]instanceof firepad.Line?insertLine(textPieces[i]):insertTextOrString(textPieces[i])}
Firepad.prototype.getHtml=function(){function open(listType){return listType===LIST_TYPE.ORDERED?"<ol>":"<ul>"}function close(listType){return listType===LIST_TYPE.ORDERED?"</ol>":"</ul>"}for(var doc=this.firebaseAdapter_.getDocument(),html="",newLine=!0,listTypeStack=[],inListItem=!1,i=0,op=doc.ops[i];op;){utils.assert(op.isInsert())
var attrs=op.attributes
if(newLine){newLine=!1
var indent=0,listType=null
if(ATTR.LINE_SENTINEL in attrs){indent=attrs[ATTR.LINE_INDENT]||0
listType=attrs[ATTR.LIST_TYPE]||null}if(inListItem){html+="</li>"
inListItem=!1}for(;listTypeStack.length>indent||indent===listTypeStack.length&&null!==listType&&listType!==listTypeStack[listTypeStack.length-1];)html+=close(listTypeStack.pop())
for(;listTypeStack.length<indent;){var toOpen=listType||LIST_TYPE.UNORDERED
html+=open(toOpen)
listTypeStack.push(toOpen)}if(listType){html+="<li>"
inListItem=!0}}if(ATTR.LINE_SENTINEL in attrs)op=doc.ops[++i]
else{var prefix="",suffix=""
for(var attr in attrs){var start,end,value=attrs[attr]
if(attr===ATTR.BOLD||attr===ATTR.ITALIC||attr===ATTR.UNDERLINE){utils.assert(value===!0)
start=end=attr}else if(attr===ATTR.FONT_SIZE){start='span style="font-size: '+value+'px"'
end="span"}else if(attr===ATTR.FONT){start='span style="font-family: '+value+'"'
end="span"}else if(attr===ATTR.COLOR){start='span style="color: '+value+'"'
end="span"}else utils.assert(!1,"Encountered unknown attribute while rendering html: "+attr)
prefix+="<"+start+">"
suffix="</"+end+">"+suffix}var text=op.text,newLineIndex=text.indexOf("\n")
if(newLineIndex>=0){newLine=!0
if(newLineIndex<text.length-1){op=new firepad.TextOp("insert",text.substr(newLineIndex+1),attrs)
text=text.substr(0,newLineIndex+1)}else op=doc.ops[++i]}else op=doc.ops[++i]
html+=prefix+this.textToHtml_(text)+suffix}}inListItem&&(html+="</li>")
for(;listTypeStack.length>0;)html+=close(listTypeStack.pop())
return html}
Firepad.prototype.textToHtml_=function(text){return text.replace(/&/g,"&amp;").replace(/"/g,"&quot;").replace(/'/g,"&#39;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/\n/g,"<br/>")}
Firepad.prototype.setHtml=function(html){var lines=firepad.ParseHtml(html)
this.setText(lines)}
Firepad.prototype.isHistoryEmpty=function(){this.assertReady_("isHistoryEmpty")
return this.firebaseAdapter_.isHistoryEmpty()}
Firepad.prototype.bold=function(){this.richTextCodeMirror_.toggleAttribute(ATTR.BOLD)
this.codeMirror_.focus()}
Firepad.prototype.italic=function(){this.richTextCodeMirror_.toggleAttribute(ATTR.ITALIC)
this.codeMirror_.focus()}
Firepad.prototype.underline=function(){this.richTextCodeMirror_.toggleAttribute(ATTR.UNDERLINE)
this.codeMirror_.focus()}
Firepad.prototype.fontSize=function(size){this.richTextCodeMirror_.setAttribute(ATTR.FONT_SIZE,size)
this.codeMirror_.focus()}
Firepad.prototype.font=function(font){this.richTextCodeMirror_.setAttribute(ATTR.FONT,font)
this.codeMirror_.focus()}
Firepad.prototype.color=function(color){this.richTextCodeMirror_.setAttribute(ATTR.COLOR,color)
this.codeMirror_.focus()}
Firepad.prototype.orderedList=function(){this.richTextCodeMirror_.toggleLineAttribute(ATTR.LIST_TYPE,"o")
this.codeMirror_.focus()}
Firepad.prototype.unorderedList=function(){this.richTextCodeMirror_.toggleLineAttribute(ATTR.LIST_TYPE,"u")
this.codeMirror_.focus()}
Firepad.prototype.newline=function(){this.richTextCodeMirror_.newline()}
Firepad.prototype.deleteLeft=function(){this.richTextCodeMirror_.deleteLeft()}
Firepad.prototype.deleteRight=function(){this.richTextCodeMirror_.deleteRight()}
Firepad.prototype.indent=function(){this.richTextCodeMirror_.indent()}
Firepad.prototype.unindent=function(){this.richTextCodeMirror_.unindent()}
Firepad.prototype.getOption=function(option,def){return option in this.options_?this.options_[option]:def}
Firepad.prototype.assertReady_=function(funcName){if(!this.ready_)throw new Error('You must wait for the "ready" event before calling '+funcName+".")
if(this.zombie_)throw new Error("You can't use a Firepad after calling dispose()!")}
Firepad.prototype.addToolbar_=function(){var toolbar=new RichTextToolbar
toolbar.on("bold",this.bold,this)
toolbar.on("italic",this.italic,this)
toolbar.on("underline",this.underline,this)
toolbar.on("font-size",this.fontSize,this)
toolbar.on("font",this.font,this)
toolbar.on("color",this.color,this)
toolbar.on("ordered-list",this.orderedList,this)
toolbar.on("unordered-list",this.unorderedList,this)
this.firepadWrapper_.insertBefore(toolbar.element(),this.firepadWrapper_.firstChild)}
Firepad.prototype.addPoweredByLogo_=function(){var poweredBy=utils.elt("a",null,{"class":"powered-by-firepad"})
poweredBy.setAttribute("href","http://www.firepad.io/")
poweredBy.setAttribute("target","_blank")
this.firepadWrapper_.appendChild(poweredBy)}
Firepad.prototype.initializeKeyMap_=function(){function binder(fn){return function(cm){fn.call(cm.firepad)}}CodeMirror.keyMap.richtext={"Ctrl-B":binder(this.bold),"Cmd-B":binder(this.bold),"Ctrl-I":binder(this.italic),"Cmd-I":binder(this.italic),"Ctrl-U":binder(this.underline),"Cmd-U":binder(this.underline),Enter:binder(this.newline),Delete:binder(this.deleteRight),Backspace:binder(this.deleteLeft),Tab:binder(this.indent),"Shift-Tab":binder(this.unindent),fallthrough:["default"]}}
return Firepad}(this)
firepad.Firepad.Formatting=firepad.Formatting
firepad.Firepad.Text=firepad.Text
firepad.Firepad.LineFormatting=firepad.LineFormatting
firepad.Firepad.Line=firepad.Line
firepad.Firepad.TextOperation=firepad.TextOperation
return firepad.Firepad}()

var CollaborativePane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativePane=function(_super){function CollaborativePane(options,data){options.cssClass=KD.utils.curry("ws-pane",options.cssClass)
CollaborativePane.__super__.constructor.call(this,options,data)
this.panel=this.getDelegate()
this.workspace=this.panel.getDelegate()
this.sessionKey=this.getOptions().sessionKey||this.createSessionKey()
this.workspaceRef=this.workspace.firepadRef.child(this.sessionKey)
this.isJoinedASession=this.getOptions().sessionKey
this.amIHost=this.workspace.amIHost()
this.container=new KDView({cssClass:"ws-container"})
this.amIHost&&this.workspaceRef.onDisconnect().remove()}__extends(CollaborativePane,_super)
CollaborativePane.prototype.createSessionKey=function(){var nick,u
nick=KD.nick()
u=KD.utils
return""+nick+"_"+u.generatePassword(4)+"_"+u.getRandomNumber(100)}
CollaborativePane.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.container}}"}
return CollaborativePane}(Pane)

var CollaborativeTabbedEditorPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeTabbedEditorPane=function(_super){function CollaborativeTabbedEditorPane(options,data){var _this=this
null==options&&(options={})
CollaborativeTabbedEditorPane.__super__.constructor.call(this,options,data)
this.openedFiles=[]
this.editors=[]
this.activeTabIndex=0
this.tabsRef=this.workspaceRef.child("tabs")
this.indexRef=this.workspaceRef.child("ActiveTabIndex")
this.createEditorTabs()
this.isJoinedASession||this.createEditorInstance()
this.tabsRef.on("child_added",function(snapshot){var file
data=snapshot.val()
if(data&&data.path&&-1===_this.openedFiles.indexOf(data.path)){file=FSHelper.createFileFromPath(data.path)
return _this.createEditorInstance(file,null,data.sessionKey)}})
this.tabsRef.on("child_removed",function(snapshot){var basePath,fileIndex,filePath,fileTab
if(snapshot.val()){basePath=snapshot.val().path
filePath=_this.amIHost?basePath:FSHelper.plainPath(basePath)
fileIndex=_this.openedFiles.indexOf(filePath)
fileTab=_this.tabView.getPaneByIndex(fileIndex)
if(fileTab){_this.tabView.removePane(fileTab)
return _this.workspaceRef.once("value",function(snapshot){var _ref
return(null!=(_ref=snapshot.val())?_ref.keys:void 0)?_this.indexRef.set(_this.tabView.getPaneIndex(_this.tabView.getActivePane())):void 0})}}})
this.indexRef.on("value",function(snapshot){return null!==snapshot.val()?_this.tabView.showPaneByIndex(snapshot.val()):void 0})
this.workspace.amIHost()&&this.workspaceRef.onDisconnect().remove()}__extends(CollaborativeTabbedEditorPane,_super)
CollaborativeTabbedEditorPane.prototype.getActivePaneEditor=function(){return this.editors[this.getActivePaneIndex()]||null}
CollaborativeTabbedEditorPane.prototype.getActivePaneContent=function(){return this.getActivePaneEditor().getValue()}
CollaborativeTabbedEditorPane.prototype.getActivePaneFileData=function(){return this.getActivePaneEditor().getData()}
CollaborativeTabbedEditorPane.prototype.getActivePane=function(){return this.tabView.getActivePane()}
CollaborativeTabbedEditorPane.prototype.getActivePaneIndex=function(){return this.tabView.getPaneIndex(this.getActivePane())}
CollaborativeTabbedEditorPane.prototype.createEditorTabs=function(){var _this=this
this.tabHandleContainer=new ApplicationTabHandleHolder({delegate:this,addPlusHandle:!1})
this.tabView=new ApplicationTabView({delegate:this,sortable:!1,closeAppWhenAllTabsClosed:!1,lastTabHandleMargin:200,tabHandleContainer:this.tabHandleContainer})
this.tabView.addSubView(new KDCustomHTMLView({cssClass:"no-file",partial:"<h3>No files are open</h3>\n<p>Double click a file from filetree to start editing.</p>"}))
return this.tabView.on("PaneDidShow",function(){var activeTab,newIndex
activeTab=_this.getActivePane()
newIndex=_this.tabView.getPaneIndex(activeTab)
if(newIndex!==_this.activeTabIndex){_this.indexRef.set(newIndex)
return _this.activeTabIndex=newIndex}})}
CollaborativeTabbedEditorPane.prototype.createEditorInstance=function(file,content,sessionKey){var editor,index,pane,plainPath,workspaceRefData,_this=this
file||(file=FSHelper.createFileFromPath("localfile:/untitled.txt"))
plainPath=FSHelper.plainPath(file.path)
index=this.openedFiles.indexOf(plainPath)
if(index>-1)return this.tabView.showPaneByIndex(index)
pane=new KDTabPaneView({name:file.name})
editor=new CollaborativeEditorPane({delegate:this.getDelegate(),saveCallback:this.getOptions().saveCallback,sessionKey:sessionKey,file:file,content:content})
this.forwardEvent(editor,"EditorDidSave")
this.forwardEvent(editor,"OpenedAFile")
pane.addSubView(editor)
this.editors.push(editor)
this.tabView.addPane(pane)
this.activeTabIndex=this.tabView.panes.length
workspaceRefData={sessionKey:editor.sessionKey}
workspaceRefData.path=plainPath
this.openedFiles.push(plainPath)
sessionKey||this.tabsRef.push(workspaceRefData)
pane.on("KDTabPaneDestroy",function(){var removedPaneIndex
removedPaneIndex=_this.tabView.getPaneIndex(pane)
_this.editors.splice(removedPaneIndex,1)
_this.workspaceRef.once("value",function(snapshot){var fileName,key,tabs,value
tabs=snapshot.val().tabs
if(tabs){for(key in tabs)if(__hasProp.call(tabs,key)){value=tabs[key]
if(value.sessionKey===editor.sessionKey){fileName=FSHelper.getFileNameFromPath(tabs[key].path)
delete tabs[key]}}return _this.workspaceRef.set({tabs:tabs})}})
return _this.openedFiles.splice(_this.openedFiles.indexOf(plainPath),1)})
return!0}
CollaborativeTabbedEditorPane.prototype.openFile=CollaborativeTabbedEditorPane.prototype.createEditorInstance
CollaborativeTabbedEditorPane.prototype.viewAppended=function(){CollaborativeTabbedEditorPane.__super__.viewAppended.apply(this,arguments)
return this.emit("PaneResized")}
CollaborativeTabbedEditorPane.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.tabHandleContainer}}\n{{> this.tabView}}"}
return CollaborativeTabbedEditorPane}(CollaborativePane)

var SharableTerminalPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SharableTerminalPane=function(_super){function SharableTerminalPane(options,data){null==options&&(options={})
SharableTerminalPane.__super__.constructor.call(this,options,data)
this.panel=this.getDelegate()
this.workspace=this.panel.getDelegate()
this.sessionKey="dummy-"+KD.utils.getRandomNumber(100)}__extends(SharableTerminalPane,_super)
SharableTerminalPane.prototype.onWebTermConnected=function(){var keysRef,_this=this
SharableTerminalPane.__super__.onWebTermConnected.apply(this,arguments)
keysRef=this.workspace.workspaceRef.child("keys")
return keysRef.once("value",function(snapshot){var index,key,keyChain,keys,_i,_len
keyChain=snapshot.val()
keys=keyChain[_this.workspace.lastCreatedPanelIndex]
for(index=_i=0,_len=keys.length;_len>_i;index=++_i){key=keys[index]
if(key===_this.sessionKey){_this.sessionKey={key:_this.remote.session,host:KD.nick(),vmName:KD.getSingleton("vmController").defaultVmName}
keys[index]=_this.sessionKey}}return keysRef.set(keyChain)})}
return SharableTerminalPane}(TerminalPane)

var SharableClientTerminalPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SharableClientTerminalPane=function(_super){function SharableClientTerminalPane(options,data){var sessionOptions
null==options&&(options={})
sessionOptions=options.sessionKey
options.vmName=sessionOptions.vmName
options.joinUser=sessionOptions.host
options.session=sessionOptions.key
options.delay=0
SharableClientTerminalPane.__super__.constructor.call(this,options,data)}__extends(SharableClientTerminalPane,_super)
SharableClientTerminalPane.prototype.createWebTermView=function(){return this.webterm=new WebTermView({cssClass:"webterm",advancedSettings:!1,delegate:this})}
return SharableClientTerminalPane}(TerminalPane)

var CollaborativeFinderPane,CollaborativeFinderTreeController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeFinderPane=function(_super){function CollaborativeFinderPane(options,data){var _ref,_this=this
null==options&&(options={})
options.cssClass="finder-pane nfinder file-container"
CollaborativeFinderPane.__super__.constructor.call(this,options,data)
this.finderController=new NFinderController({nodeIdPath:"path",nodeParentIdPath:"parentPath",contextMenu:!0,useStorage:!1,treeControllerClass:CollaborativeFinderTreeController})
null!=(_ref=this.container)&&_ref.destroy()
this.finder=this.container=this.finderController.getView()
this.workspaceRef.on("value",function(snapshot){var clientData,nodeView,path,treeController,_ref1
clientData=null!=(_ref1=snapshot.val())?_ref1.ClientWantsToInteractWithRemoteFileTree:void 0
if(clientData){path="["+clientData.vmName+"]"+clientData.path
treeController=_this.finderController.treeController
nodeView=treeController.nodes[path]
nodeView.user=clientData.user
treeController.openItem(nodeView,clientData)
return _this.finderController.treeController.syncInteraction()}})
this.finderController.on("FileTreeInteractionDone",function(files){return _this.syncContent(files)})
this.finderController.on("OpenedAFile",function(file,content){var editorPane,pane,_i,_len,_ref1
editorPane=_this.panel.getPaneByName(_this.getOptions().editor)
if(!editorPane){_ref1=_this.panel.panes
for(_i=0,_len=_ref1.length;_len>_i;_i++){pane=_ref1[_i];(pane instanceof CollaborativeEditorPane||pane instanceof CollaborativeTabbedEditorPane)&&(editorPane=pane)}}return editorPane?editorPane.openFile(file,content):warn("could not find an editor instance to set file content")})
this.workspace.amIHost()&&this.workspaceRef.onDisconnect().remove()
this.workspace.getOptions().playground||this.finderController.reset()
this.finderController.treeController.on("HistoryItemCreated",function(historyItem){return _this.workspace.addToHistory(historyItem)})}__extends(CollaborativeFinderPane,_super)
CollaborativeFinderPane.prototype.syncContent=function(files){return this.workspaceRef.set({files:files})}
return CollaborativeFinderPane}(CollaborativePane)
CollaborativeFinderTreeController=function(_super){function CollaborativeFinderTreeController(){_ref=CollaborativeFinderTreeController.__super__.constructor.apply(this,arguments)
return _ref}__extends(CollaborativeFinderTreeController,_super)
CollaborativeFinderTreeController.prototype.addNodes=function(nodes){CollaborativeFinderTreeController.__super__.addNodes.call(this,nodes)
return this.syncInteraction()}
CollaborativeFinderTreeController.prototype.openItem=function(nodeView,clientData){var isExpanded,keyword,name,nodeData,path,type,user
nodeData=nodeView.getData()
keyword="opened"
user=clientData?clientData.requestedBy:KD.nick()
name=nodeData.name,path=nodeData.path,type=nodeData.type
if("folder"===type){isExpanded=this.nodes[nodeData.path].expanded
keyword=isExpanded?"collapsed":"expanded"}this.emit("HistoryItemCreated",{message:""+user+" "+keyword+" "+nodeData.name,data:{name:name,path:path,type:type}})
return CollaborativeFinderTreeController.__super__.openItem.call(this,nodeView)}
CollaborativeFinderTreeController.prototype.getSnapshot=function(){var node,nodeData,path,snapshot,_ref1
snapshot=[]
_ref1=this.nodes
for(path in _ref1)if(__hasProp.call(_ref1,path)){node=_ref1[path]
nodeData=node.data
snapshot.push({path:FSHelper.plainPath(path),type:nodeData.type,vmName:nodeData.vmName,name:nodeData.name})}return snapshot}
CollaborativeFinderTreeController.prototype.syncInteraction=function(){return this.getDelegate().emit("FileTreeInteractionDone",this.getSnapshot())}
CollaborativeFinderTreeController.prototype.toggleFolder=function(nodeView){return CollaborativeFinderTreeController.__super__.toggleFolder.call(this,nodeView,this.bound("syncInteraction"))}
CollaborativeFinderTreeController.prototype.openFile=function(nodeView){var file,_this=this
if(nodeView){file=nodeView.getData()
return file.fetchContents(function(err,contents){return _this.getDelegate().emit("OpenedAFile",file,contents)})}}
return CollaborativeFinderTreeController}(NFinderTreeController)

var CollaborativeClientFinderPane,CollaborativeClientTreeViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeClientFinderPane=function(_super){function CollaborativeClientFinderPane(options,data){var panel,workspace,_this=this
null==options&&(options={})
options.cssClass="finder-pane nfinder file-container client-finder-pane"
CollaborativeClientFinderPane.__super__.constructor.call(this,options,data)
this.container=new KDView({cssClass:"client-finder-pane"})
panel=this.getDelegate()
workspace=panel.getDelegate()
this.sessionKey=this.getOptions().sessionKey
this.workspaceRef=workspace.firepadRef.child(this.sessionKey)
this.createLoader()
this.workspaceRef.on("value",function(snapshot){var file,fileInstance,fileInstances,files,view,_i,_len,_ref
files=null!=(_ref=snapshot.val())?_ref.files:void 0
if(files){fileInstances=[]
for(_i=0,_len=files.length;_len>_i;_i++){file=files[_i]
fileInstance=FSHelper.createFileFromPath(file.path,file.type)
fileInstance.vmName=file.vmName
fileInstances.push(fileInstance)}_this.fileTree=new CollaborativeClientTreeViewController({workspaceRef:_this.workspaceRef,workspace:workspace},fileInstances)
view=_this.fileTree.getView()
_this.container.updatePartial("")
return _this.container.addSubView(view)}})}__extends(CollaborativeClientFinderPane,_super)
CollaborativeClientFinderPane.prototype.createLoader=function(){var loaderContainer
this.container.addSubView(loaderContainer=new KDView({cssClass:"loader-container"}))
loaderContainer.addSubView(new KDLoaderView({showLoader:!0,size:{width:32}}))
return loaderContainer.addSubView(new KDCustomHTMLView({tagName:"p",partial:"Fetching remote file tree"}))}
CollaborativeClientFinderPane.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.container}}"}
return CollaborativeClientFinderPane}(Pane)
CollaborativeClientTreeViewController=function(_super){function CollaborativeClientTreeViewController(options,data){null==options&&(options={})
options.nodeIdPath="path"
options.nodeParentIdPath="parentPath"
options.contextMenu=!1
options.loadFilesOnInit=!0
options.treeItemClass=NFinderItem
CollaborativeClientTreeViewController.__super__.constructor.call(this,options,data)}__extends(CollaborativeClientTreeViewController,_super)
CollaborativeClientTreeViewController.prototype.dblClick=function(nodeView){var nodeData
nodeData=nodeView.getData()
return this.getOptions().workspaceRef.set({ClientWantsToInteractWithRemoteFileTree:{path:nodeData.path,type:nodeData.type,vmName:nodeData.vmName,requestedBy:KD.nick()}})}
return CollaborativeClientTreeViewController}(JTreeViewController)

var CollaborativeEditorPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeEditorPane=function(_super){function CollaborativeEditorPane(options,data){var _this=this
null==options&&(options={})
CollaborativeEditorPane.__super__.constructor.call(this,options,data)
this.container.on("viewAppended",function(){_this.createEditor()
_this.ref=_this.workspace.firepadRef.child(_this.sessionKey)
_this.firepad=Firepad.fromCodeMirror(_this.ref,_this.codeMirrorEditor)
_this.firepad.on("ready",function(){var content,file,_ref
_this.firepad.isHistoryEmpty()&&_this.firepad.setText(" ")
_this.codeMirrorEditor.scrollTo(0,0)
_ref=_this.getOptions(),file=_ref.file,content=_ref.content
return file?_this.openFile(file,content):void 0})
_this.amIHost&&_this.ref.on("value",function(snapshot){var value
value=snapshot.val()
return value?value.WaitingSaveRequest===!0?_this.save():void 0:void 0})
return _this.amIHost?_this.ref.onDisconnect().remove():void 0})}var cdnRoot
__extends(CollaborativeEditorPane,_super)
cdnRoot="https://koding-cdn.s3.amazonaws.com/codemirror/latest"
CollaborativeEditorPane.prototype.openFile=function(file,content){var isLocalFile
this.setData(file)
isLocalFile=0===file.path.indexOf("localfile")
this.amIHost&&isLocalFile&&(content="")
this.amIHost&&this.firepad.setText(content)
this.codeMirrorEditor.scrollTo(0,0)
return this.emit("OpenedAFile",file,content)}
CollaborativeEditorPane.prototype.save=function(){var file,isValidFile,_base,_this=this
file=this.getData()
isValidFile=file instanceof FSFile&&-1===file.path.indexOf("localfile")
if(this.amIHost){if(!isValidFile)return warn("no file instance to handle save as")
this.ref.child("WaitingSaveRequest").set(!1)
file.save(this.firepad.getText(),function(){return _this.workspace.broadcastMessage({title:""+file.name+" is saved",sender:""})})}else this.ref.child("WaitingSaveRequest").set(!0)
"function"==typeof(_base=this.getOptions()).saveCallback&&_base.saveCallback(this.panel,this.workspace,file,this.firepad.getText())
return this.emit("EditorDidSave")}
CollaborativeEditorPane.prototype.getValue=function(){return this.codeMirrorEditor.getValue()}
CollaborativeEditorPane.prototype.setValue=function(value){return this.codeMirrorEditor.setValue(value)}
CollaborativeEditorPane.prototype.createEditor=function(){this.codeMirrorEditor=CodeMirror(this.container.getDomElement()[0],{lineNumbers:!0,scrollPastEnd:!0,mode:"htmlmixed",extraKeys:{"Cmd-S":this.bound("handleSave"),"Ctrl-S":this.bound("handleSave")}})
this.setEditorTheme()
return this.setEditorMode()}
CollaborativeEditorPane.prototype.handleSave=function(){this.save()
return this.workspace.addToHistory("$0 saved "+this.getData().name)}
CollaborativeEditorPane.prototype.setEditorTheme=function(){var link
if(document.getElementById("codemirror-ambiance-style"))return this.codeMirrorEditor.setOption("theme","ambiance")
link=document.createElement("link")
link.rel="stylesheet"
link.type="text/css"
link.href=""+cdnRoot+"/theme/ambiance.css"
link.id="codemirror-ambiance-style"
document.head.appendChild(link)
return this.codeMirrorEditor.setOption("theme","ambiance")}
CollaborativeEditorPane.prototype.setEditorMode=function(){var corrections,file,fileExtension,modeName,syntaxHandler
file=this.getOptions().file
if(file){CodeMirror.modeURL=""+cdnRoot+"/mode/%N/%N.js"
fileExtension=file.getExtension()
syntaxHandler=__aceSettings.syntaxAssociations[fileExtension]
modeName=null
corrections={html:"htmlmixed",json:"javascript",js:"javascript",go:"go"}
corrections[fileExtension]?modeName=corrections[fileExtension]:syntaxHandler&&(modeName=syntaxHandler[0].toLowerCase())
if(modeName){this.codeMirrorEditor.setOption("mode",modeName)
return CodeMirror.autoLoadMode(this.codeMirrorEditor,modeName)}}}
return CollaborativeEditorPane}(CollaborativePane)

var CollaborativePreviewPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativePreviewPane=function(_super){function CollaborativePreviewPane(options,data){var _this=this
null==options&&(options={})
CollaborativePreviewPane.__super__.constructor.call(this,options,data)
this.container.addSubView(this.previewPane=new PreviewPane(this.getOptions()))
this.previewer=this.previewPane.previewer
this.isJoinedASession&&this.workspaceRef.once("value",function(snapshot){return _this.openPathFromSnapshot(snapshot)})
this.previewer.on("ViewerLocationChanged",function(){return _this.saveUrl()})
this.previewer.on("ViewerRefreshed",function(){return _this.saveUrl(!0)})
this.workspaceRef.on("value",function(snapshot){return _this.openPathFromSnapshot(snapshot)})
this.amIHost&&this.workspaceRef.onDisconnect().remove()}__extends(CollaborativePreviewPane,_super)
CollaborativePreviewPane.prototype.openPathFromSnapshot=function(snapshot){var value
value=snapshot.val()
return(null!=value?value.url:void 0)?this.previewer.openPath(value.url):void 0}
CollaborativePreviewPane.prototype.openUrl=function(url){this.previewer.openPath(url)
return this.saveUrl(!0)}
CollaborativePreviewPane.prototype.saveUrl=function(force){var path,url
path=this.previewer.path
url=force?""+path+"?"+Date.now():path.replace(/\?.*/,"")
this.workspaceRef.child("url").set(url)
return this.workspace.addToHistory("$0 opened "+url)}
return CollaborativePreviewPane}(CollaborativePane)

var CollaborativeDrawingPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeDrawingPane=function(_super){function CollaborativeDrawingPane(options,data){var _this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("ws-drawing-pane",options.cssClass)
CollaborativeDrawingPane.__super__.constructor.call(this,options,data)
this.pointRef=this.workspaceRef.child("point")
this.linesRef=this.workspaceRef.child("lines")
this.stateRef=this.workspaceRef.child("state")
this.usersRef=this.workspaceRef.child("users")
this.drawedQueue=[]
this.userColors={}
this.container.on("viewAppended",function(){_this.createCanvas()
_this.setUserColor()
_this.bindMouseDownOnCanvas()
_this.bindMouseUpOnCanvas()
_this.bindMouseMoveCanvas()
_this.amIHost&&_this.workspaceRef.onDisconnect().remove()
_this.isJoinedASession&&_this.redrawCanvas()
_this.bindRemoteEvents()
return _this.container.addSubView(_this.canvas)})}__extends(CollaborativeDrawingPane,_super)
CollaborativeDrawingPane.prototype.createCanvas=function(){this.canvas=new KDCustomHTMLView({tagName:"canvas",bind:"mousemove mousedown mouseup",attributes:{width:this.getWidth(),height:this.getHeight()}})
return this.context=this.canvas.getElement().getContext("2d")}
CollaborativeDrawingPane.prototype.redrawCanvas=function(){var _this=this
this.context.closePath()
return this.linesRef.once("value",function(snapshot){var color,index,key,point,points,pointsArr,username,value,x,y,_ref,_results
value=snapshot.val()
if(value){_this.context.beginPath()
_results=[]
for(key in value)if(__hasProp.call(value,key)){points=value[key]
pointsArr=points.split("|")
_ref=pointsArr.splice(0,2),username=_ref[0],color=_ref[1]
_this.userColors[username]=color
_this.context.closePath()
_this.context.beginPath()
_results.push(function(){var _i,_len,_ref1,_results1
_results1=[]
for(index=_i=0,_len=pointsArr.length;_len>_i;index=++_i){point=pointsArr[index]
_ref1=point.split(","),x=_ref1[0],y=_ref1[1]
0===index&&this.context.moveTo(x,y)
_results1.push(this.addPoint(x,y,username))}return _results1}.call(_this))}return _results}})}
CollaborativeDrawingPane.prototype.bindMouseDownOnCanvas=function(){var _this=this
return this.canvas.on("mousedown",function(e){var x,y
KD.utils.stopDOMEvent(e)
x=e.offsetX
y=e.offsetY
_this.startDrawing=!0
_this.context.beginPath()
_this.context.moveTo(e.offsetX,e.offsetY)
_this.addPoint(x,y)
_this.drawedQueue.push(""+x+","+y)
_this.pointRef.set({x:x,y:y,nickname:KD.nick()})
return _this.stateRef.set(!0)})}
CollaborativeDrawingPane.prototype.bindMouseMoveCanvas=function(){var _this=this
return this.canvas.on("mousemove",function(e){var x,y
if(_this.startDrawing){x=e.offsetX
y=e.offsetY
_this.addPoint(x,y)
_this.drawedQueue.push(""+x+","+y)
return _this.pointRef.set({x:x,y:y,nickname:KD.nick()})}})}
CollaborativeDrawingPane.prototype.bindMouseUpOnCanvas=function(){var _this=this
return this.canvas.on("mouseup",function(){_this.context.closePath()
_this.startDrawing=!1
_this.stateRef.set(!1)
_this.drawedQueue.unshift(KD.nick(),_this.userColors[KD.nick()])
_this.linesRef.push(_this.drawedQueue.join("|"))
return _this.drawedQueue.length=0})}
CollaborativeDrawingPane.prototype.bindRemoteEvents=function(){var _this=this
this.isContextMoved=!0
this.pointRef.on("value",function(snapshot){var value
if(!_this.startDrawing){value=snapshot.val()
if(value){if(!_this.isContextMoved){_this.context.beginPath()
_this.context.moveTo(value.x,value.y)
_this.isContextMoved=!0}return _this.addPoint(value.x,value.y,value.nickname)}}})
this.stateRef.on("value",function(snapshot){return _this.isContextMoved=snapshot.val()!==!1})
return this.usersRef.on("value",function(snapshot){var key,userData,value,_results
value=snapshot.val()
if(value){_results=[]
for(key in value)if(__hasProp.call(value,key)){userData=value[key]
_results.push(_this.userColors[userData.nickname]=userData.color)}return _results}})}
CollaborativeDrawingPane.prototype.addPoint=function(x,y,nickname){var ctx
null==nickname&&(nickname=KD.nick())
ctx=this.context
ctx.strokeStyle=this.userColors[nickname]
ctx.lineTo(x,y)
return ctx.stroke()}
CollaborativeDrawingPane.prototype.setUserColor=function(){var color,nickname
nickname=KD.nick()
color=KD.utils.getRandomHex()
this.userColors[nickname]=color
return this.usersRef.push({nickname:nickname,color:color})}
return CollaborativeDrawingPane}(CollaborativePane)

var ChatItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ChatItem=function(_super){function ChatItem(options,data){var account,ownMessage,user
options.cssClass="chat-item"
ChatItem.__super__.constructor.call(this,options,data)
account=this.getData()
this.avatar=new AvatarView({size:{width:30,height:30}},account)
user=this.getOptions().user
ownMessage=user.nickname===KD.nick()
this.messageList=new KDView({cssClass:"items-container"})
this.messageList.addSubView(this.header=new KDCustomHTMLView({cssClass:"username",partial:ownMessage?"Me":""+user.nickname}))
this.header.addSubView(this.timeAgo=new KDTimeAgoView({cssClass:"time-ago"},new Date(this.getOptions().time)))
this.messageList.addSubView(new KDCustomHTMLView({partial:Encoder.XSSEncode(this.getOptions().body)}))
ownMessage&&this.setClass("mine")}__extends(ChatItem,_super)
ChatItem.prototype.pistachio=function(){return"{{> this.avatar}}\n{{> this.messageList}}"}
return ChatItem}(JView)

var ChatPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ChatPane=function(_super){function ChatPane(options,data){var floatingCssClass
null==options&&(options={})
floatingCssClass=options.floating?"floating":""
options.cssClass=KD.utils.curry("workspace-chat",floatingCssClass)
ChatPane.__super__.constructor.call(this,options,data)
this.unreadCount=0
this.workspace=this.getDelegate()
this.chatRef=this.workspace.chatRef
this.createElements()
this.createDock()
this.bindRemoteEvents()}__extends(ChatPane,_super)
ChatPane.prototype.bindRemoteEvents=function(){var _this=this
return this.chatRef.on("child_added",function(snapshot){_this.isVisible()||_this.getOptions().floating||_this.updateCount(++_this.unreadCount)
return _this.addNew(snapshot.val())})}
ChatPane.prototype.updateCount=function(){this.title.updatePartial("Chat ("+ ++this.unreadCount+")")
return this.dock.setClass("pulsing")}
ChatPane.prototype.createElements=function(){var _this=this
this.messages=new KDView({cssClass:"messages"})
return this.input=new KDHitEnterInputView({placeholder:"Type your message and hit enter",callback:function(){_this.sendMessage(_this.input.getValue())
_this.input.setValue("")
return _this.input.setFocus()}})}
ChatPane.prototype.createDock=function(){var _this=this
this.dock=new KDView({cssClass:"dock",click:function(){_this.dock.unsetClass("pulsing")
_this.toggleClass("active")
_this.toggle.toggleClass("active")
_this.unreadCount=0
_this.title.updatePartial("Chat")
return _this.isVisible()?void 0:_this.emit("WorkspaceChatClosed")}})
this.title=new KDCustomHTMLView({tagName:"span",partial:"Chat"})
this.toggle=new KDView({cssClass:"toggle"})
this.dock.addSubView(this.toggle)
return this.dock.addSubView(this.title)}
ChatPane.prototype.isVisible=function(){return this.hasClass("active")}
ChatPane.prototype.sendMessage=function(message){message={user:{nickname:KD.nick()},time:Date.now(),body:message}
return this.chatRef.child(message.time).set(message)}
ChatPane.prototype.addNew=function(details){var ownerNickname
ownerNickname=details.user.nickname
if(this.lastChatItemOwner===ownerNickname){this.lastChatItem.messageList.addSubView(new KDCustomHTMLView({partial:Encoder.XSSEncode(details.body)}))
this.updateDate(details.time)
return this.scrollToTop()}this.lastChatItem=new ChatItem(details,this.workspace.users[ownerNickname])
this.lastChatItemOwner=ownerNickname
this.messages.addSubView(this.lastChatItem)
this.updateDate(details.time)
return this.scrollToTop()}
ChatPane.prototype.updateDate=function(timestamp){return this.lastChatItem.timeAgo.setData(new Date(timestamp))}
ChatPane.prototype.scrollToTop=function(){var $messages
$messages=this.messages.$()
return $messages.scrollTop($messages[0].scrollHeight)}
ChatPane.prototype.pistachio=function(){return'{{> this.dock}}\n{{> this.messages}}\n<div class="input-container">\n  {{> this.input}}\n</div>'}
return ChatPane}(JView)

var WorkspaceFloatingPaneLauncher,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WorkspaceFloatingPaneLauncher=function(_super){function WorkspaceFloatingPaneLauncher(options,data){var workspaceRef,_this=this
null==options&&(options={})
options.cssClass="workspace-launcher vertical"
WorkspaceFloatingPaneLauncher.__super__.constructor.call(this,options,data)
this.sessionKeys={}
this.panel=this.getDelegate()
this.workspace=this.panel.getDelegate()
this.container=new KDView({cssClass:"workspace-floating-panes"})
workspaceRef=this.workspace.workspaceRef
this.isJoinedASession=this.workspace.isJoinedASession()
this.lastActivePaneKey=null
this.keysRef=workspaceRef.child("floatingPaneKeys")
this.paneStateRef=workspaceRef.child("floatingPaneState")
this.paneVisibilityState={chat:!1,preview:!1,terminal:!1}
this.panel.addSubView(this.container)
this.isJoinedASession?this.keysRef.once("value",function(snapshot){_this.sessionKeys=snapshot.val()
return _this.createPanes()}):this.createPanes()
this.paneStateRef.on("value",function(snapshot){var key,pane,state,value
state=snapshot.val()
if(state){for(key in state)if(__hasProp.call(state,key)){value=state[key]
pane=_this.getPaneByType(key)
value===!1?_this.hidePane(pane,key):_this.showPane(pane,key)}return _this.resizePanes(state)}})}__extends(WorkspaceFloatingPaneLauncher,_super)
WorkspaceFloatingPaneLauncher.prototype.click=function(){return this.toggleClass("active")}
WorkspaceFloatingPaneLauncher.prototype.createPanes=function(){var panes,_this=this
panes=this.panel.getOptions().floatingPanes
return panes.forEach(function(pane){_this.createFloatingPane(pane)
_this.addSubView(new KDCustomHTMLView({cssClass:KD.utils.curry("launcher-item",pane),tooltip:{title:pane.capitalize()},click:function(){return _this.handleLaunch(pane)}}))
return _this.panesCreated=!0})}
WorkspaceFloatingPaneLauncher.prototype.createFloatingPane=function(paneKey){return this["create"+paneKey.capitalize()+"Pane"]()}
WorkspaceFloatingPaneLauncher.prototype.handleLaunch=function(paneKey){var pane
pane=this.getPaneByType(paneKey)
if(this.lastActivePaneKey===paneKey){this.lastActivePaneKey=null
return this.updatePaneVisiblityState(paneKey,!1)}this.lastActivePaneKey=paneKey
return this.updatePaneVisiblityState(paneKey,!0)}
WorkspaceFloatingPaneLauncher.prototype.hidePane=function(pane){return pane.unsetClass("active")}
WorkspaceFloatingPaneLauncher.prototype.showPane=function(pane,paneKey){return"chat"===paneKey?this.chat.dock.emit("click"):pane.setClass("active")}
WorkspaceFloatingPaneLauncher.prototype.updatePaneVisiblityState=function(paneKey,value){var key,map
map=this.paneVisibilityState
for(key in map)__hasProp.call(map,key)&&(map[key]=!1)
map[paneKey]=value
return this.paneStateRef.set(map)}
WorkspaceFloatingPaneLauncher.prototype.createChatPane=function(){var _this=this
this.container.addSubView(this.chat=new ChatPane({delegate:this.panel.getDelegate(),floating:!0}))
return this.chat.on("WorkspaceChatClosed",function(){_this.lastActivePaneKey=null
return _this.updatePaneVisiblityState("chat",!1)})}
WorkspaceFloatingPaneLauncher.prototype.createTerminalPane=function(){var terminalClass,_this=this
terminalClass=SharableTerminalPane
this.isJoinedASession&&(terminalClass=SharableClientTerminalPane)
this.container.addSubView(this.terminal=new KDView({cssClass:"floating-pane",size:{height:400}}))
this.terminal.addSubView(this.terminalPane=new terminalClass({delegate:this.panel,sessionKey:this.sessionKeys.terminal}))
return this.workspace.amIHost()?this.terminalPane.on("WebtermCreatead",function(){return _this.keysRef.child("terminal").set({key:_this.terminalPane.remote.session,host:KD.nick(),vmName:KD.getSingleton("vmController").defaultVmName})}):void 0}
WorkspaceFloatingPaneLauncher.prototype.createPreviewPane=function(){var _this=this
this.container.addSubView(this.preview=new KDView({cssClass:"floating-pane floating-preview-pane",size:{height:400},partial:'<div class="warning">\n  <p>Type a URL to browse it with your friends.</p>\n  <span>Note that, if you click links inside the page it can\'t be synced. You need to change the URL.</span>\n</div>'}))
this.previewPane=new CollaborativePreviewPane({delegate:this.panel,sessionKey:this.sessionKeys.preview})
this.workspace.amIHost()&&this.workspace.on("WorkspaceSyncedWithRemote",function(){return _this.keysRef.child("preview").set(_this.previewPane.sessionKey)})
return this.preview.addSubView(this.previewPane)}
WorkspaceFloatingPaneLauncher.prototype.resizePanes=function(statesObj){var activePanel,finder,finderContainer,finderNeedsResize,key,value,_this=this
activePanel=this.workspace.getActivePanel()
if(!activePanel)return this.workspace.once("WorkspaceSyncedWithRemote",function(){return _this.resizePanes(statesObj)})
finder=activePanel.getPaneByName("finder")
if(finder){finderContainer=finder.container
finderNeedsResize=!1
for(key in statesObj)if(__hasProp.call(statesObj,key)){value=statesObj[key]
"chat"!==key&&value===!0&&(finderNeedsResize=!0)}if(finderNeedsResize||this.finderResized){if(finderNeedsResize){if(this.finderResized)return
finderContainer.setHeight(finderContainer.getHeight()-400)
return this.finderResized=!0}finderContainer.setHeight(finderContainer.getHeight()+400)
return this.finderResized=!1}}}
WorkspaceFloatingPaneLauncher.prototype.getPaneByType=function(type){return this[type]||null}
return WorkspaceFloatingPaneLauncher}(KDCustomHTMLView)

var CollaborativeWorkspaceUserList,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeWorkspaceUserList=function(_super){function CollaborativeWorkspaceUserList(options,data){var _ref
null==options&&(options={})
options.cssClass="user-list-container"
CollaborativeWorkspaceUserList.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),this.workspaceRef=_ref.workspaceRef,this.container=_ref.container,this.sessionKey=_ref.sessionKey
this.header=new KDView({cssClass:"inner-header",partial:'<span class="title">Participants</span>'})
this.header.addSubView(new KDCustomHTMLView({tagName:"span",cssClass:"close",click:this.bound("close")}))
this.loaderView=new KDLoaderView({size:{width:36}})
this.onlineUsers=new KDView({cssClass:"group online hidden",partial:'<p class="header">ONLINE</p>'})
this.offlineUsers=new KDView({cssClass:"group offline hidden",partial:'<p class="header">OFFLINE</p>'})
this.invitedUsers=new KDView({cssClass:"group invited hidden",partial:'<p class="header">INVITED</p>'})
this.inviteBar=new KDView({partial:"Invite Friends",cssClass:"invite-bar",click:this.bound("showInviteView")})
this.createInviteView()
this.fetchUsers()
KD.getSingleton("windowController").addLayer(this)
this.on("ReceivedClickElsewhere",this.bound("close"))}__extends(CollaborativeWorkspaceUserList,_super)
CollaborativeWorkspaceUserList.prototype.fetchUsers=function(){var _this=this
return this.workspaceRef.once("value",function(snapshot){var status,userList,userName,userNames,val,_ref
val=snapshot.val()
userList={}
userNames=[]
_ref=val.users
for(userName in _ref)if(__hasProp.call(_ref,userName)){status=_ref[userName]
userList[userName]=status
userNames.push(userName)}return KD.remote.api.JAccount.some({"profile.nickname":{$in:userNames}},{},function(err,jAccounts){var user,_i,_len
_this.loaderView.hide()
for(_i=0,_len=jAccounts.length;_len>_i;_i++){user=jAccounts[_i]
user.status=userList[user.profile.nickname]
_this.createUserView(user)}return _this.emit("UserListCreated")})})}
CollaborativeWorkspaceUserList.prototype.createUserView=function(user){var avatarOptions,container,sessionOwner,userView
userView=new KDView({cssClass:"user-view "+user.status})
avatarOptions={size:{width:36,height:36}}
userView.addSubView(new AvatarView(avatarOptions,user))
userView.addSubView(new KDView({cssClass:"user-name",partial:"<p>"+user.profile.firstName+" "+user.profile.lastName+"</p>\n<p>"+user.profile.nickname+"</p>"}))
sessionOwner=this.sessionKey.split("_")[0]
user.profile.nickname===sessionOwner&&userView.addSubView(new KDView({cssClass:"host-badge",partial:'<span class="icon"></span> HOST'}))
container=this.onlineUsers
"offline"===user.status?container=this.offlineUsers:"invited"===user.status&&(container=this.invitedUsers)
container.addSubView(userView)
return container.unsetClass("hidden")}
CollaborativeWorkspaceUserList.prototype.showInviteView=function(){var key,_i,_len,_ref
_ref=["onlineUsers","offlineUsers","invitedUsers","inviteBar"]
for(_i=0,_len=_ref.length;_len>_i;_i++){key=_ref[_i]
this[key].hide()}return this.inviteView.unsetClass("hidden")}
CollaborativeWorkspaceUserList.prototype.createInviteView=function(){var _this=this
this.inviteView=new KDView({cssClass:"invite-view hidden",partial:"<p>You can share your session key with your friends or type a name to send an invite to your session.</p>"})
this.inviteView.addSubView(new KDView({cssClass:"session-key",partial:this.sessionKey}))
this.userController=new KDAutoCompleteController({form:new KDFormView,name:"userController",itemClass:MemberAutoCompleteItemView,itemDataPath:"profile.nickname",outputWrapper:this.completedItems,selectedItemClass:MemberAutoCompletedItemView,listWrapperCssClass:"users",submitValuesAsText:!0,dataSource:function(args,callback){var blacklist,data,inputValue
inputValue=args.inputValue
blacklist=function(){var _i,_len,_ref,_results
_ref=this.userController.getSelectedItemData()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){data=_ref[_i]
_results.push(data.getId())}return _results}.call(_this)
blacklist.push(KD.whoami()._id)
return KD.remote.api.JAccount.byRelevance(inputValue,{blacklist:blacklist},function(err,accounts){return callback(accounts)})}})
this.userController.on("ItemListChanged",function(){var accounts
accounts=_this.userController.getSelectedItemData()
return accounts.length>0?_this.inviteButton.enable():_this.inviteButton.disable()})
this.inviteView.addSubView(this.userController.getView())
this.inviteView.addSubView(this.completedItems=new KDView({cssClass:"completed-items"}))
this.inviteView.addSubView(this.cancelInviteButton=new KDButtonView({cssClass:"invite-button cancel-button",title:"Cancel",callback:this.bound("returnToInviteView")}))
return this.inviteView.addSubView(this.inviteButton=new KDButtonView({cssClass:"invite-button cupid-green",title:"Invite",callback:function(){var account,accounts,_i,_len
accounts=_this.userController.getSelectedItemData()
for(_i=0,_len=accounts.length;_len>_i;_i++){account=accounts[_i]
_this.sendInvite(account)}return _this.reset()}}))}
CollaborativeWorkspaceUserList.prototype.sendInvite=function(account){var appName,body,delegate,fromFullName,nickname,profile,sessionKey,subject,to,userName
if(!account)return this.emit("UserInviteFailed")
to=account.profile.nickname
nickname=KD.nick()
profile=KD.whoami().profile
fromFullName=""+profile.firstName+" "+profile.lastName
delegate=this.getDelegate()
appName=delegate.getOptions().name
sessionKey=delegate.sessionKey
userName=""+profile.firstName+" "+profile.lastName+" (@"+nickname+")"
subject="Join my "+appName+" session"
body="Hey "+account.profile.firstName+",\n\n"+fromFullName+" (@"+profile.nickname+") invited you to "+appName+" session.\n\nYou can use this key "+sessionKey+" to join "+fromFullName+"'s "+appName+" session or you can click the link below:\n\nhttp://koding.com/Develop/"+appName+"?sessionKey="+sessionKey+"\n\nIf you don't have "+appName+" installed, you can install it from the App Catalog."
if(to!==nickname){KD.remote.api.JPrivateMessage.create({to:to,subject:subject,body:body},noop)
this.workspaceRef.child("users").child(to).set("invited")
return this.emit("UserInvited",to)}}
CollaborativeWorkspaceUserList.prototype.returnToInviteView=function(){var key,_i,_len,_ref
_ref=["onlineUsers","offlineUsers","invitedUsers"]
for(_i=0,_len=_ref.length;_len>_i;_i++){key=_ref[_i]
this[key].getSubViews().length>0&&this[key].show()}this.inviteView.setClass("hidden")
return this.inviteBar.show()}
CollaborativeWorkspaceUserList.prototype.close=function(){var container,_this=this
container=this.container
container.unsetClass("active")
return container.once("transitionend",function(){container.destroySubViews()
return delete _this.getDelegate().userList})}
CollaborativeWorkspaceUserList.prototype.reset=function(){this.container.destroySubViews()
return this.getDelegate().showUsers()}
CollaborativeWorkspaceUserList.prototype.viewAppended=function(){CollaborativeWorkspaceUserList.__super__.viewAppended.apply(this,arguments)
return this.loaderView.show()}
CollaborativeWorkspaceUserList.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.loaderView}}\n{{> this.onlineUsers}}\n{{> this.offlineUsers}}\n{{> this.invitedUsers}}\n{{> this.inviteBar}}\n{{> this.inviteView}}"}
return CollaborativeWorkspaceUserList}(JView)

var CollaborativePanel,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativePanel=function(_super){function CollaborativePanel(options,data){var createdPanes,panesLength,workspace,_this=this
null==options&&(options={})
CollaborativePanel.__super__.constructor.call(this,options,data)
workspace=this.getDelegate()
panesLength=this.getPaneLengthFromLayoutConfig()
createdPanes=[]
this.on("NewPaneCreated",function(pane){createdPanes.push(pane)
return createdPanes.length===panesLength?_this.getDelegate().emit("AllPanesAddedToPanel",_this,createdPanes):void 0})}__extends(CollaborativePanel,_super)
CollaborativePanel.prototype.createHeaderButtons=function(){var _this=this
CollaborativePanel.__super__.createHeaderButtons.apply(this,arguments)
return this.headerButtonsContainer.addSubView(new KDCustomHTMLView({cssClass:"users",tooltip:{title:"Show Users"},click:function(){return _this.getDelegate().showUsers()}}))}
CollaborativePanel.prototype.createPane=function(paneOptions){var PaneClass,isJoinedASession,pane
PaneClass=this.getPaneClass(paneOptions)
this.getOptions().sessionKeys&&(paneOptions.sessionKey=this.getOptions().sessionKeys[this.panes.length])
isJoinedASession=!!paneOptions.sessionKey&&!this.getDelegate().amIHost()
isJoinedASession&&("terminal"===paneOptions.type?PaneClass=SharableClientTerminalPane:"finder"===paneOptions.type&&(PaneClass=CollaborativeClientFinderPane))
if(!PaneClass)return warn("Unknown pane class: "+paneOptions.type)
pane=new PaneClass(paneOptions)
paneOptions.name&&(this.panesByName[paneOptions.name]=pane)
this.panes.push(pane)
this.emit("NewPaneCreated",pane)
return pane}
CollaborativePanel.prototype.getPaneLengthFromLayoutConfig=function(){var key,length,options,value,_ref
options=this.getOptions()
length=0
if(options.pane)return 1
_ref=options.layout.views
for(key in _ref)if(__hasProp.call(_ref,key)){value=_ref[key]
"split"===value.type?length+=value.views.length:length++}return length}
CollaborativePanel.prototype.viewAppended=function(){var container
CollaborativePanel.__super__.viewAppended.apply(this,arguments)
this.header.addSubView(container=new KDCustomHTMLView({cssClass:"workspace-broadcast-container"}))
return container.addSubView(this.broadcastItem=new KDCustomHTMLView({tagName:"span",cssClass:"workspace-broadcast pulsing hidden"}))}
CollaborativePanel.prototype.EditorPaneClass=CollaborativeEditorPane
CollaborativePanel.prototype.TerminalPaneClass=SharableTerminalPane
CollaborativePanel.prototype.FinderPaneClass=CollaborativeFinderPane
CollaborativePanel.prototype.TabbedEditorPaneClass=CollaborativeTabbedEditorPane
CollaborativePanel.prototype.PreviewPaneClass=CollaborativePreviewPane
CollaborativePanel.prototype.DrawingPaneClass=CollaborativeDrawingPane
CollaborativePanel.prototype.VideoPaneClass=VideoPane
return CollaborativePanel}(Panel)

var CollaborativeWorkspace,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CollaborativeWorkspace=function(_super){function CollaborativeWorkspace(){_ref=CollaborativeWorkspace.__super__.constructor.apply(this,arguments)
return _ref}__extends(CollaborativeWorkspace,_super)
CollaborativeWorkspace.prototype.init=function(){this.nickname=KD.nick()
this.sessionData=[]
this.users={}
this.createRemoteInstance()
this.createLoader()
this.fetchUsers()
this.createUserListContainer()
this.getOptions().enableChat&&this.createChat()
return this.bindRemoteEvents()}
CollaborativeWorkspace.prototype.createChat=function(){var chatPaneClass
chatPaneClass=this.getOptions().chatPaneClass||ChatPane
this.container.addSubView(this.chatView=new chatPaneClass({delegate:this}))
return this.chatView.hide()}
CollaborativeWorkspace.prototype.createRemoteInstance=function(){var instanceName
instanceName=this.getOptions().firebaseInstance
if(!instanceName)return warn("CollaborativeWorkspace requires a Firebase instance.")
this.firepadRef=new Firebase("https://"+instanceName+".firebaseio.com/")
this.sessionKey=this.getOptions().sessionKey||this.createSessionKey()
this.workspaceRef=this.firepadRef.child(this.sessionKey)
this.broadcastRef=this.workspaceRef.child("broadcast")
this.historyRef=this.workspaceRef.child("history")
this.chatRef=this.workspaceRef.child("chat")
this.watchRef=this.workspaceRef.child("watch")
return this.usersRef=this.workspaceRef.child("users")}
CollaborativeWorkspace.prototype.bindRemoteEvents=function(){var _this=this
this.workspaceRef.once("value",function(snapshot){var isOldSession,keys,record,_ref1,_ref2,_ref3
if(_this.getOptions().sessionKey&&!(null!=(_ref1=snapshot.val())?_ref1.keys:void 0)){_this.showNotActiveView()
return!1}isOldSession=keys=null!=(_ref2=snapshot.val())?_ref2.keys:void 0
if(isOldSession){_this.sessionData=keys
_this.createPanel()}else{_this.createPanel()
_this.workspaceRef.set({keys:_this.sessionData})}_this.userRef=_this.usersRef.child(_this.nickname)
_this.userRef.set("online")
_this.userRef.onDisconnect().set("offline")
record=isOldSession?"$0 joined the session":"$0 started the session"
_this.addToHistory(record)
_this.watchRef.child(_this.nickname).set("everybody")
if(_this.amIHost()){_this.workspaceRef.onDisconnect().remove()
_this.userRef.onDisconnect().remove()}_this.loader.destroy()
null!=(_ref3=_this.chatView)&&_ref3.show()
_this.emit("WorkspaceSyncedWithRemote")
return isOldSession?_this.emit("SomeoneJoinedToSession",KD.nick()):void 0})
this.usersRef.on("child_added",function(){return _this.fetchUsers()})
this.usersRef.on("child_changed",function(snapshot){var message,name
name=snapshot.name()
if(_this.amIHost()&&"offline"===snapshot.val()){message=""+name+" has left the session"
_this.broadcastMessage({title:message,cssClass:"error",sender:name})
_this.addToHistory(message)
return _this.emit("SomeoneHasLeftSession",name)}})
this.workspaceRef.on("child_removed",function(){return _this.disconnectedModal?void 0:KD.utils.wait(1500,function(){return _this.workspaceRef.once("value",function(snapshot){return snapshot.val()||_this.disconnectedModal||_this.sessionNotActive?void 0:_this.showDisconnectedModal()})})})
this.broadcastRef.on("value",function(snapshot){var message
message=snapshot.val()
return message&&message.data&&message.data.sender!==_this.nickname?_this.displayBroadcastMessage(message.data):void 0})
this.broadcastMessage({title:""+this.nickname+" has joined to the session",sender:this.nickname})
this.on("AllPanesAddedToPanel",function(panel,panes){var pane,paneSessionKeys,_i,_len
paneSessionKeys=[]
for(_i=0,_len=panes.length;_len>_i;_i++){pane=panes[_i]
paneSessionKeys.push(pane.sessionKey)}return this.sessionData.push(paneSessionKeys)})
this.on("KDObjectWillBeDestroyed",function(){var eventName,events,_i,_len,_results
_this.forceDisconnect()
events=["value","child_added","child_removed","child_changed"]
_results=[]
for(_i=0,_len=events.length;_len>_i;_i++){eventName=events[_i]
_results.push(_this.workspaceRef.off(eventName))}return _results})
return this.watchRef.on("value",function(snapshot){return _this.watchMap=snapshot.val()||{}})}
CollaborativeWorkspace.prototype.fetchUsers=function(){var _this=this
return this.workspaceRef.once("value",function(snapshot){var status,username,usernames,val,_ref1
val=snapshot.val()
if(val){usernames=[]
if(!_this.users[username]){_ref1=val.users
for(username in _ref1)if(__hasProp.call(_ref1,username)){status=_ref1[username]
usernames.push(username)}}return KD.remote.api.JAccount.some({"profile.nickname":{$in:usernames}},{},function(err,jAccounts){var user,_i,_len
for(_i=0,_len=jAccounts.length;_len>_i;_i++){user=jAccounts[_i]
_this.users[user.profile.nickname]=user}return _this.emit("WorkspaceUsersFetched")})}})}
CollaborativeWorkspace.prototype.createPanel=function(callback){var newPanel,panelClass,panelOptions
null==callback&&(callback=noop)
panelOptions=this.getOptions().panels[this.lastCreatedPanelIndex]
panelOptions.delegate=this
this.sessionData&&(panelOptions.sessionKeys=this.sessionData[this.lastCreatedPanelIndex])
panelClass=this.getOptions().panelClass||CollaborativePanel
newPanel=new panelClass(panelOptions)
this.container.addSubView(newPanel)
this.panels.push(newPanel)
this.activePanel=newPanel
callback()
return this.emit("PanelCreated",newPanel)}
CollaborativeWorkspace.prototype.createSessionKey=function(){var u
u=KD.utils
return""+this.nickname+"_"+u.generatePassword(4)+"_"+u.getRandomNumber(100)}
CollaborativeWorkspace.prototype.getHost=function(){return this.sessionKey.split("_").first}
CollaborativeWorkspace.prototype.amIHost=function(){var sessionOwner
sessionOwner=this.sessionKey.split("_")[0]
return sessionOwner===this.nickname}
CollaborativeWorkspace.prototype.showNotActiveView=function(){var notValid,_this=this
notValid=new KDView({cssClass:"not-valid",partial:"This session is not valid or no longer available."})
notValid.addSubView(new KDView({cssClass:"description",partial:"This usually means, the person who is hosting this session is disconnected or closed the session."}))
notValid.addSubView(new KDButtonView({cssClass:"cupid-green",title:"Start New Session",callback:function(){return _this.startNewSession()}}))
this.container.addSubView(notValid)
this.sessionNotActive=!0
return this.loader.hide()}
CollaborativeWorkspace.prototype.startNewSession=function(){var options
this.destroySubViews()
options=this.getOptions()
delete options.sessionKey
return this.addSubView(new CollaborativeWorkspace(options))}
CollaborativeWorkspace.prototype.createLoader=function(){var loaderView
this.loader=new KDView({cssClass:"workspace-loader",partial:'<span class="text">Loading...<span>'})
this.loader.addSubView(loaderView=new KDLoaderView({size:{width:36}}))
this.loader.on("viewAppended",function(){return loaderView.show()})
return this.container.addSubView(this.loader)}
CollaborativeWorkspace.prototype.isJoinedASession=function(){return this.getHost()!==KD.nick()}
CollaborativeWorkspace.prototype.joinSession=function(newOptions){var options
options=this.getOptions()
options.sessionKey=newOptions.sessionKey.trim()
options.joinedASession=!0
this.destroySubViews()
this.forceDisconnect()
return this.addSubView(new CollaborativeWorkspace(options))}
CollaborativeWorkspace.prototype.forceDisconnect=function(){var _this=this
if(this.amIHost()){this.forcedToDisconnect=!0
this.workspaceRef.remove()
return KD.utils.wait(2e3,function(){return _this.forcedToDisconnect=!1})}}
CollaborativeWorkspace.prototype.showDisconnectedModal=function(){var content,title,_this=this
if(!this.forcedToDisconnect){if(this.amIHost()){title="Disconnected from remote"
content="It seems, you have been disconnected from Firebase server. You cannot continue this session."}else{title="Host disconnected"
content="It seems, host is disconnected from Firebase server. You cannot continue this session."}this.disconnectedModal=new KDBlockingModalView({title:title,appendToDomBody:!1,content:"<p>"+content+"</p>",cssClass:"host-disconnected-modal",overlay:!1,width:470,buttons:{Start:{title:"Start New Session",callback:function(){_this.disconnectedModal.destroy()
return _this.startNewSession()}},Join:{title:"Join Another Session",callback:function(){_this.disconnectedModal.destroy()
return _this.showJoinModal()}},Exit:{title:"Exit App",cssClass:"modal-cancel",callback:function(){var appManager
_this.disconnectedModal.destroy()
appManager=KD.getSingleton("appManager")
return appManager.quit(appManager.frontApp)}}}})
this.disconnectedModal.on("KDObjectWillBeDestroyed",function(){delete _this.disconnectedModal
return _this.disconnectOverlay.destroy()})
this.disconnectOverlay=new KDOverlayView({parent:KD.singletons.mainView.mainTabView.activePane,isRemovable:!1})
return this.container.getDomElement().append(this.disconnectedModal.getDomElement())}}
CollaborativeWorkspace.prototype.showJoinModal=function(){var modal,options,sessionKeyInput,_this=this
options=this.getOptions()
modal=new KDModalView({title:options.joinModalTitle||"Join New Session",content:options.joinModalContent||"<p>This is your session key, you can share this key with your friends to work together.</p>",overlay:!0,cssClass:"workspace-modal join-modal",width:500,buttons:{Join:{title:"Join Session",cssClass:"modal-clean-green",callback:function(){return _this.handleJoinASessionFromModal(sessionKeyInput.getValue(),modal)}},Close:{title:"Close",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})
return modal.addSubView(sessionKeyInput=new KDHitEnterInputView({type:"text",placeholder:"Paste new session key and hit enter to join",callback:function(){return _this.handleJoinASessionFromModal(sessionKeyInput.getValue(),modal)}}))}
CollaborativeWorkspace.prototype.handleJoinASessionFromModal=function(sessionKey,modal){if(sessionKey){this.joinSession({sessionKey:sessionKey})
return modal.destroy()}}
CollaborativeWorkspace.prototype.showShareView=function(panel,workspace,event){var button,shareUrl
button=KD.instances[event.currentTarget.id]
shareUrl=""+location.origin+"/Develop/"+this.getOptions().name+"?sessionKey="+this.sessionKey
return new JContextMenu({cssClass:"activity-share-popup",type:"activity-share",delegate:this,x:button.getX()+25,y:button.getY()+25,arrow:{placement:"top",margin:-10},lazyLoad:!0},{customView:new SharePopup({url:shareUrl,shortenURL:!1,twitter:{text:"Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! "+shareUrl},linkedin:{title:"Join me @koding!",text:"Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! "+shareUrl}})})}
CollaborativeWorkspace.prototype.createUserListContainer=function(){this.container.addSubView(this.userListContainer=new KDView({cssClass:"user-list"}))
return this.userListContainer.bindTransitionEnd()}
CollaborativeWorkspace.prototype.showUsers=function(){if(!this.userList){this.userListContainer.setClass("active")
this.createUserList()
return this.userListContainer.addSubView(this.userList)}}
CollaborativeWorkspace.prototype.createUserList=function(){return this.userList=new CollaborativeWorkspaceUserList({workspaceRef:this.workspaceRef,sessionKey:this.sessionKey,container:this.userListContainer,delegate:this})}
CollaborativeWorkspace.prototype.setWatchMode=function(targetUsername){var username
username=KD.nick()
return this.watchRef.child(username).set(targetUsername)}
CollaborativeWorkspace.prototype.addToHistory=function(data){var target
target=this.historyRef.child(Date.now())
"string"==typeof data&&(data={message:data})
data.message=data.message.replace("$0",KD.nick())
target.set(data)
return this.emit("NewHistoryItemAdded",data)}
CollaborativeWorkspace.prototype.broadcastMessage=function(details){var _ref1,_ref2
this.broadcastRef.set({data:{title:details.title||"",cssClass:null!=(_ref1=details.cssClass)?_ref1:"success",duration:details.duration||4200,origin:details.origin||"users",sender:null!=(_ref2=details.sender)?_ref2:this.nickname}})
return this.broadcastRef.set({})}
CollaborativeWorkspace.prototype.displayBroadcastMessage=function(options){var activePanel,broadcastItem,_this=this
if(options.title){options.title=options.title.replace("$0",KD.nick())
activePanel=this.getActivePanel()
broadcastItem=activePanel.broadcastItem
activePanel.setClass("broadcasting")
broadcastItem.updatePartial(options.title)
broadcastItem.unsetClass("success")
broadcastItem.unsetClass("error")
broadcastItem.setClass(options.cssClass)
broadcastItem.show()
return KD.utils.wait(options.duration,function(){broadcastItem.hide()
activePanel.unsetClass("broadcasting")
return _this.emit("MessageBroadcasted")})}}
return CollaborativeWorkspace}(Workspace)

var AvatarContextMenuItem,TabHandleAvatarView,TabHandleWithAvatar,TeamworkTabView,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkTabView=function(_super){function TeamworkTabView(options,data){var _this=this
null==options&&(options={})
this.handlePaneCreate=__bind(this.handlePaneCreate,this)
TeamworkTabView.__super__.constructor.call(this,options,data)
this.createElements()
this.keysRef=this.workspaceRef.child("keys")
this.indexRef=this.workspaceRef.child("index")
this.requestRef=this.workspaceRef.child("request")
this.paneRef=this.workspaceRef.child("pane")
this.listenChildRemovedOnKeysRef()
this.listenRequestRef()
this.amIHost?this.bindRemoteEvents():this.keysRef.once("value",function(snapshot){var key,value
data=snapshot.val()
if(data){for(key in data){value=data[key]
_this.keysRefChildAddedCallback(value)}return _this.bindRemoteEvents()}})}__extends(TeamworkTabView,_super)
TeamworkTabView.prototype.listenRequestRef=function(){var _this=this
return this.requestRef.on("value",function(snapshot){var request
if(_this.amIHost){request=snapshot.val()
if(!request)return
_this.createTabFromFirebaseData(request)
return _this.requestRef.remove()}})}
TeamworkTabView.prototype.listenPaneDidShow=function(){}
TeamworkTabView.prototype.listenChildRemovedOnKeysRef=function(){var _this=this
return this.keysRef.on("child_removed",function(snapshot){var data,indexKey,pane,_i,_len,_ref,_results
data=snapshot.val()
if(data){indexKey=data.indexKey
_ref=_this.tabView.panes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i];(null!=pane?pane.getOptions().indexKey:void 0)===indexKey?_results.push(_this.tabView.removePane(pane)):_results.push(void 0)}return _results}})}
TeamworkTabView.prototype.bindRemoteEvents=function(){this.listenPaneDidShow()
this.listenIndexRef()
return this.listenChildAddedOnKeysRef()}
TeamworkTabView.prototype.listenChildAddedOnKeysRef=function(){var _this=this
return this.keysRef.on("child_added",function(snapshot){return _this.keysRefChildAddedCallback(snapshot.val())})}
TeamworkTabView.prototype.keysRefChildAddedCallback=function(data){var isExist,key,pane,panes,_i,_len
key=data.indexKey
panes=this.tabView.panes
for(_i=0,_len=panes.length;_len>_i;_i++){pane=panes[_i]
pane.getOptions().indexKey===key&&(isExist=!0)}return isExist?void 0:this.createTabFromFirebaseData(data)}
TeamworkTabView.prototype.listenIndexRef=function(){var _this=this
return this.indexRef.on("value",function(snapshot){var data,index,pane,username,watchMap,_i,_len,_ref,_results
data=snapshot.val()
watchMap=_this.workspace.watchMap
username=KD.nick()
if(data){_this.paneRef.child(data.by).set(data.indexKey)
if("everybody"===watchMap[username]||watchMap[username]===data.by){_ref=_this.tabView.panes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
if(pane.getOptions().indexKey===data.indexKey){index=_this.tabView.getPaneIndex(pane)
_results.push(_this.tabView.showPaneByIndex(index))}else _results.push(void 0)}return _results}}})}
TeamworkTabView.prototype.createElements=function(){var _this=this
this.tabHandleHolder=new ApplicationTabHandleHolder({delegate:this})
this.tabView=new ApplicationTabView({delegate:this,lastTabHandleMargin:80,tabHandleContainer:this.tabHandleHolder,enableMoveTabHandle:!0,resizeTabHandles:!1,closeAppWhenAllTabsClosed:!1,minHandleWidth:150,maxHandleWidth:150})
return this.tabView.on("PaneAdded",function(pane){return pane.getHandle().on("click",function(){var paneOptions
paneOptions=pane.getOptions()
_this.workspace.addToHistory({message:"$0 switched to "+paneOptions.title,by:KD.nick(),data:{title:paneOptions.title,indexKey:paneOptions.indexKey}})
return _this.indexRef.set({indexKey:pane.getOptions().indexKey,by:KD.nick()})})})}
TeamworkTabView.prototype.addNewTab=function(){return this.createPlusHandleDropDown()}
TeamworkTabView.prototype.createPlusHandleDropDown=function(){var contextMenu,offset
offset=this.tabHandleHolder.plusHandle.$().offset()
contextMenu=new JContextMenu({delegate:this,x:offset.left-125,y:offset.top+30,arrow:{placement:"top",margin:-20}},this.getDropdownItems())
return contextMenu.once("ContextMenuItemReceivedClick",function(){return contextMenu.destroy()})}
TeamworkTabView.prototype.getDropdownItems=function(){var _this=this
return{Dashboard:{separator:!0,callback:function(){return _this.createDashboard()}},Editor:{callback:function(){return _this.handlePaneCreate("editor",function(){return _this.createEditor()})}},Terminal:{callback:function(){return _this.handlePaneCreate("terminal",function(){return _this.createTerminal()})}},Browser:{callback:function(){return _this.handlePaneCreate("browser",function(){return _this.createPreview()})}},"Drawing Board":{callback:function(){return _this.handlePaneCreate("drawing",function(){return _this.createDrawingBoard()})}}}}
TeamworkTabView.prototype.handlePaneCreate=function(paneType,callback){null==callback&&(callback=noop)
this.amIHost?callback():this.requestRef.set({type:paneType,by:KD.nick()})
return this.workspace.addToHistory({message:"$0 opened a new "+paneType,by:KD.nick()})}
TeamworkTabView.prototype.createTabFromFirebaseData=function(data){var file,indexKey,path,sessionKey
sessionKey=data.sessionKey,indexKey=data.indexKey
switch(data.type){case"dashboard":return this.createDashboard()
case"terminal":return this.createTerminal(sessionKey,indexKey)
case"browser":return this.createPreview(sessionKey,indexKey)
case"drawing":return this.createDrawingBoard(sessionKey,indexKey)
case"editor":path=data.filePath||"localfile:/untitled.txt"
file=FSHelper.createFileFromPath(path)
return this.createEditor(file,"",sessionKey,indexKey)}}
TeamworkTabView.prototype.createDashboard=function(){var dashboard,_this=this
if(this.dashboard)return this.tabView.showPane(this.dashboard)
this.dashboard=new KDTabPaneView({title:"Dashboard",indexKey:"dashboard"})
dashboard=new TeamworkDashboard({delegate:this.workspace.getDelegate()})
this.appendPane_(this.dashboard,dashboard)
this.dashboard.once("KDObjectWillBeDestroyed",function(){return _this.dashboard=null})
this.amIHost&&this.keysRef.push({type:"dashboard",indexKey:"dashboard"})
return this.registerPaneRemoveListener_(this.dashboard)}
TeamworkTabView.prototype.createDrawingBoard=function(sessionKey,indexKey){var delegate,drawing,pane
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:"Drawing Board",indexKey:indexKey})
delegate=this.panel
drawing=new CollaborativeDrawingPane({delegate:delegate,sessionKey:sessionKey})
this.appendPane_(pane,drawing)
this.amIHost&&this.keysRef.push({type:"drawing",sessionKey:drawing.sessionKey,indexKey:indexKey})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.registerPaneRemoveListener_=function(pane){var _this=this
return pane.on("KDObjectWillBeDestroyed",function(){var paneIndexKey
paneIndexKey=pane.getOptions().indexKey
return _this.keysRef.once("value",function(snapshot){var data,key,value,_results
data=snapshot.val()
if(data){_results=[]
for(key in data){value=data[key]
value.indexKey===paneIndexKey?_results.push(_this.keysRef.child(key).remove()):_results.push(void 0)}return _results}})})}
TeamworkTabView.prototype.createEditor=function(file,content,sessionKey,indexKey){var delegate,editor,isLocal,pane
null==content&&(content="")
isLocal=!file
file=file||FSHelper.createFileFromPath("localfile:/untitled.txt")
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:file.name,indexKey:indexKey})
delegate=this.getDelegate()
editor=new CollaborativeEditorPane({delegate:delegate,sessionKey:sessionKey,file:file,content:content})
this.appendPane_(pane,editor)
this.amIHost&&this.keysRef.push({type:"editor",sessionKey:editor.sessionKey,filePath:file.path,indexKey:indexKey})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.openFile=function(file,content){return this.createEditor(file,content)}
TeamworkTabView.prototype.createTerminal=function(sessionKey,indexKey){var delegate,klass,pane,terminal,_this=this
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:"Terminal",indexKey:indexKey})
klass=this.isJoinedASession?SharableClientTerminalPane:SharableTerminalPane
delegate=this.getDelegate()
terminal=new klass({delegate:delegate,sessionKey:sessionKey})
this.appendPane_(pane,terminal)
this.amIHost&&terminal.on("WebtermCreated",function(){return _this.keysRef.push({type:"terminal",indexKey:indexKey,sessionKey:{key:terminal.remote.session,host:KD.nick(),vmName:KD.getSingleton("vmController").defaultVmName}})})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.createPreview=function(sessionKey,indexKey){var browser,delegate,pane
indexKey=indexKey||this.createSessionKey()
pane=new KDTabPaneView({title:"Browser",indexKey:indexKey})
delegate=this.getDelegate()
browser=new CollaborativePreviewPane({delegate:delegate,sessionKey:sessionKey})
this.appendPane_(pane,browser)
this.amIHost&&this.keysRef.push({type:"browser",sessionKey:browser.sessionKey,indexKey:indexKey})
return this.registerPaneRemoveListener_(pane)}
TeamworkTabView.prototype.createChat=function(){var chat,pane
pane=new KDTabPaneView({title:"Chat"})
chat=new ChatPane({cssClass:"full-screen",delegate:this.workspace})
return this.appendPane_(pane,chat)}
TeamworkTabView.prototype.appendPane_=function(pane,childView){pane.addSubView(childView)
return this.tabView.addPane(pane)}
TeamworkTabView.prototype.viewAppended=function(){TeamworkTabView.__super__.viewAppended.apply(this,arguments)
return this.amIHost?this.createDashboard():void 0}
TeamworkTabView.prototype.pistachio=function(){return"{{> this.tabHandleHolder}}\n{{> this.tabView}}"}
return TeamworkTabView}(CollaborativePane)
TabHandleWithAvatar=function(_super){function TabHandleWithAvatar(options,data){null==options&&(options={})
options.view=new TabHandleAvatarView(options)
TabHandleWithAvatar.__super__.constructor.call(this,options,data)}__extends(TabHandleWithAvatar,_super)
TabHandleWithAvatar.prototype.setTitle=function(title){return this.getOption("view").title.updatePartial(title)}
TabHandleWithAvatar.prototype.setAccounts=function(accounts){return this.getOption("view").setAccounts(accounts)}
return TabHandleWithAvatar}(KDTabHandleView)
TabHandleAvatarView=function(_super){function TabHandleAvatarView(options,data){var _this=this
null==options&&(options={})
options.cssClass="tw-tab-avatar-view"
TabHandleAvatarView.__super__.constructor.call(this,options,data)
this.accounts=["gokmen","devrim","sinan"]
this.addSubView(this.title=new KDCustomHTMLView({cssClass:"tw-tab-avatar-title",partial:""+options.title}))
this.addSubView(this.avatar=new AvatarStaticView({cssClass:"tw-tab-avatar-img",size:{width:20,height:20},bind:"mouseenter mouseleave",mouseenter:function(){var offset
offset=_this.avatar.$().offset()
_this.avatar.contextMenu=new JContextMenu({menuWidth:160,delegate:_this.avatar,treeItemClass:AvatarContextMenuItem,x:offset.left-106,y:offset.top+27,arrow:{placement:"top",margin:108},lazyLoad:!0},{})
return _this.utils.defer(function(){return _this.accounts.forEach(function(account){return KD.remote.cacheable(account,function(err,_arg){var account
account=_arg[0]
return!err&&account?_this.avatar.contextMenu.treeController.addNode(account):void 0})})})},mouseleave:function(){var _ref
return null!=(_ref=_this.avatar.contextMenu)?_ref.destroy():void 0}},KD.whoami()))}__extends(TabHandleAvatarView,_super)
TabHandleAvatarView.prototype.setAccounts=function(accounts){this.accounts=accounts}
return TabHandleAvatarView}(KDView)
AvatarContextMenuItem=function(_super){function AvatarContextMenuItem(){AvatarContextMenuItem.__super__.constructor.apply(this,arguments)
this.avatar=new AvatarStaticView({size:{width:20,height:20},cssClass:"tw-tab-avatar-img-context"},this.getData())}__extends(AvatarContextMenuItem,_super)
AvatarContextMenuItem.prototype.pistachio=function(){return"{{> this.avatar}} "+KD.utils.getFullnameFromAccount(this.getData())}
return AvatarContextMenuItem}(JContextMenuItem)

var TeamworkMarkdownModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkMarkdownModal=function(_super){function TeamworkMarkdownModal(options,data){var _this=this
null==options&&(options={})
options.title="README"
options.cssClass="has-markdown teamwork-markdown"
options.overlay=!0
options.width=630
TeamworkMarkdownModal.__super__.constructor.call(this,options,data)
this.bindTransitionEnd()
this.once("transitionend",function(){return _this.utils.wait(133,function(){KDModalView.prototype.destroy.call(_this)
return _this.getOptions().targetEl.setCss("opacity",1)})})}__extends(TeamworkMarkdownModal,_super)
TeamworkMarkdownModal.prototype.destroy=function(){var targetEl
this.setClass("scale")
targetEl=this.getOptions().targetEl
targetEl.setClass("opacity")
return this.setStyle({left:targetEl.getX()-this.getWidth()/2,top:targetEl.getY()-this.getHeight()/2+12})}
return TeamworkMarkdownModal}(KDModalView)

var FacebookTeamworkInstructionsModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FacebookTeamworkInstructionsModal=function(_super){function FacebookTeamworkInstructionsModal(options,data){var _this=this
null==options&&(options={})
options.title="Before Starting"
options.cssClass="tw-before-starting-modal"
options.width=700
options.overlay=!0
options.overlayClick=!1
options.tabs={navigable:!1,forms:{"Create New App":{fields:{createApp:{itemClass:KDView,cssClass:"step",partial:'<p class="tw-modal-line">1. Visit <strong><a href="http://developers.facebook.com/apps">http://developers.facebook.com/apps</a></strong> and click the <strong>Create New App</strong> button in the top right corner.</p>\n<div class="tw-modal-image">\n  <img src="/images/teamwork/facebook/step1.jpg" />\n</div>\n<p class="tw-modal-line">2. Then fill out <strong>App Name</strong>, <strong>App Namespace</strong> and <strong>App Category</strong> fields. Once that is done, click <strong>Continue</strong> button.</p>\n<div class="tw-modal-image step1">\n  <img class="tw-fb-step1" src="/images/teamwork/facebook/step2.jpg" />\n</div>\n<p class="tw-modal-line">3. Once that is done, click the <strong>Next</strong> button on this page.</p>'}},buttons:{Next:{cssClass:"modal-clean-green",callback:function(){return _this.modalTabs.showPaneByIndex(1)}}}},"App Setup":{fields:{image:{itemClass:KDView,cssClass:"step",partial:'<div class="tw-modal-image step-general">\n  <p class="tw-modal-line">1. Find your <strong>App ID</strong> and <strong>Namespace</strong> and copy below.</p>\n  <img src="/images/teamwork/facebook/step4.jpg" />\n</div>'},appId:{placeholder:"Enter you App ID",label:"App ID",validate:{rules:{required:!0},messages:{required:"Please enter your App ID"}}},appNamespace:{placeholder:"Enter you App Namespace",label:"App Namespace",validate:{rules:{required:!0},messages:{required:"Please enter your App Namespace"}}},canvasUrlText:{itemClass:KDView,cssClass:"step",partial:"<p>2. Copy the Canvas URL link below, and go back to Facebook. Scroll down to the <strong>Canvas URL</strong> under <strong>App on Facebook</strong> tab and paste the link you just copied into the field.</p>"},appCanvasUrl:{label:"Canvas URL",attributes:{readonly:"readonly"},defaultValue:"https://"+KD.nick()+".kd.io/Teamwork/Facebook/"},text:{itemClass:KDView,cssClass:"step",partial:'<div class="tw-modal-image step-general">\n  <img src="/images/teamwork/facebook/step3.jpg" />\n</div>'}},buttons:{Done:{cssClass:"modal-clean-green",callback:function(){var appCanvasUrl,appId,appNamespace,_ref
_ref=_this.modalTabs.forms["App Setup"].inputs,appId=_ref.appId,appNamespace=_ref.appNamespace,appCanvasUrl=_ref.appCanvasUrl
return appId.validate()&&appNamespace.validate()?_this.getDelegate().emit("FacebookAppInfoTaken",{appId:appId.getValue(),appNamespace:appNamespace.getValue(),appCanvasUrl:appCanvasUrl.getValue()},_this.destroy()):void 0}}}}}}
FacebookTeamworkInstructionsModal.__super__.constructor.call(this,options,data)}__extends(FacebookTeamworkInstructionsModal,_super)
return FacebookTeamworkInstructionsModal}(KDModalViewWithForms)

var TeamworkTools,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkTools=function(_super){function TeamworkTools(options,data){var _ref
null==options&&(options={})
options.cssClass="tw-share-modal"
TeamworkTools.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),this.modal=_ref.modal,this.panel=_ref.panel,this.workspace=_ref.workspace,this.twApp=_ref.twApp
this.createElements()}__extends(TeamworkTools,_super)
TeamworkTools.prototype.createElements=function(){var _this=this
this.teamUpHeader=new KDCustomHTMLView({cssClass:"header",partial:'<span class="icon"></span>\n<h3 class="text">Team Up</h3>\n<p class="desc">I want to code together right now, on my VM</p>',click:function(){if(_this.hasTeamUpElements){_this.teamUpPlaceholder.destroySubViews()
_this.unsetClass("active")
_this.teamUpHeader.unsetClass("active")
return _this.hasTeamUpElements=!1}_this.setClass("active")
_this.teamUpHeader.setClass("active")
_this.createTeamupElements()
return _this.hasTeamUpElements=!0}})
this.shareHeader=new KDCustomHTMLView({cssClass:"header share",partial:'<span class="icon"></span>\n<h3 class="text">Export and share</h3>\n<p class="desc">Select a folder to export and share the link with your friends.</p>',click:function(){if(_this.hasShareElements){_this.sharePlaceholder.destroySubViews()
_this.unsetClass("active")
_this.shareHeader.unsetClass("active")
return _this.hasShareElements=!1}_this.setClass("active")
_this.shareHeader.setClass("active")
_this.createShareElements()
return _this.hasShareElements=!0}})
this.teamUpPlaceholder=new KDCustomHTMLView({cssClass:"content"})
return this.sharePlaceholder=new KDCustomHTMLView({cssClass:"export"})}
TeamworkTools.prototype.createTeamupElements=function(){var _this=this
this.teamUpPlaceholder.addSubView(new KDCustomHTMLView({tagName:"p",cssClass:"option",partial:"Copy and send your session key or full URL to your friends"}))
this.keyInput=new KDInputView({cssClass:"teamwork-modal-input key",defaultValue:this.workspace.sessionKey,attributes:{readonly:"readonly"},click:function(){return _this.keyInput.getDomElement().select()}})
this.urlInput=new KDInputView({cssClass:"teamwork-modal-input url",defaultValue:""+document.location.href+"?sessionKey="+this.workspace.sessionKey,attributes:{readonly:"readonly"},click:function(){return _this.urlInput.getDomElement().select()}})
this.teamUpPlaceholder.addSubView(this.keyInput)
this.teamUpPlaceholder.addSubView(this.urlInput)
this.teamUpPlaceholder.addSubView(new KDCustomHTMLView({tagName:"p",cssClass:"option",partial:"Invite your Koding friends via their username"}))
this.inviteView=new CollaborativeWorkspaceUserList({workspaceRef:this.workspace.workspaceRef,sessionKey:this.workspace.sessionKey,container:this,delegate:this})
this.teamUpPlaceholder.addSubView(this.inviteView)
return this.hasTeamUpContent=!0}
TeamworkTools.prototype.createShareElements=function(){var exportButton,finder,_this=this
this.finderController=new NFinderController({nodeIdPath:"path",nodeParentIdPath:"parentPath",foldersOnly:!0,contextMenu:!1,loadFilesOnInit:!0,useStorage:!1})
finder=this.finderController.getView()
this.finderController.reset()
finder.setHeight(150)
this.sharePlaceholder.addSubView(finder)
return this.sharePlaceholder.addSubView(exportButton=new KDButtonView({cssClass:"tw-export-button",title:"Click to start export",callback:function(){return _this["export"]()}}))}
TeamworkTools.prototype["export"]=function(){var fileName,node,nodeData,notification,path,vmController,_this=this
if(!this.exporting){node=this.finderController.treeController.selectedNodes[0]
if(!node)return new KD.NotificationView({title:"Please select a folder to save!",type:"mini",cssClass:"error",duration:4e3})
vmController=KD.getSingleton("vmController")
nodeData=node.getData()
fileName=""+nodeData.name+".zip"
path=FSHelper.plainPath(nodeData.path)
notification=new KDNotificationView({title:"Exporting file...",type:"mini",duration:3e4,container:this.finderContainer})
return vmController.run("cd "+path+"/.. ; zip -r "+fileName+" "+nodeData.name,function(err){var file
_this.exporting=!0
if(err)return _this.updateNotification(notification)
file=FSHelper.createFileFromPath(""+nodeData.parentPath+"/"+fileName)
return file.fetchContents(function(err,contents){return err?_this.updateNotification(notification):FSHelper.s3.upload(fileName,btoa(contents),function(err,res){if(err)return _this.updateNotification(notification)
vmController.run("rm -f "+path+".zip",function(){})
return KD.utils.shortenUrl(res,function(shorten){_this.exporting=!1
notification.notificationSetTitle("Your content has been exported.")
notification.notificationSetTimer(4e3)
notification.setClass("success")
_this.showUrlView(shorten)
return _this.emit("Exported",nodeData.name,shorten)})})},!1)})}}
TeamworkTools.prototype.showUrlView=function(shortenUrl){var url
this.sharePlaceholder.destroySubViews()
this.sharePlaceholder.addSubView(new KDCustomHTMLView({tagName:"p",cssClass:"option",partial:"Your content is exported. Copy the url below and give it to your friends."}))
return this.sharePlaceholder.addSubView(url=new KDInputView({cssClass:"teamwork-modal-input shorten",defaultValue:shortenUrl,attributes:{readonly:"readonly"},click:function(){return url.getDomElement().select()}}))}
TeamworkTools.prototype.updateNotification=function(notification){notification.notificationSetTitle("Something went wrong")
notification.notificationSetTimer(4e3)
notification.setClass("error")
return this.exporting=!1}
TeamworkTools.prototype.pistachio=function(){return"{{> this.teamUpHeader}}\n{{> this.teamUpPlaceholder}}\n{{> this.shareHeader}}\n{{> this.sharePlaceholder}}"}
return TeamworkTools}(JView)

var TeamworkDashboard,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkDashboard=function(_super){function TeamworkDashboard(options,data){var _this=this
null==options&&(options={})
options.cssClass="tw-dashboard active"
TeamworkDashboard.__super__.constructor.call(this,options,data)
this.teamUpButton=new KDButtonView({title:"Team Up!",cssClass:"tw-rounded-button",callback:function(){var delegate
delegate=_this.getDelegate()
return delegate.teamwork?delegate.showTeamUpModal():delegate.emit("NewSessionRequested",function(){return delegate.emit("TeamUpRequested")})}})
this.joinInput=new KDHitEnterInputView({cssClass:"tw-dashboard-input",type:"text",placeholder:"Session key or url",validate:{rules:{required:!0},messages:{required:"Enter session key or URL to join."}},callback:function(){return _this.handleJoinSession()}})
this.joinButton=new KDButtonView({iconOnly:!0,iconClass:"join-in",cssClass:"tw-dashboard-button",callback:function(){return _this.handleJoinSession()}})
this.importInput=new KDHitEnterInputView({cssClass:"tw-dashboard-input",type:"text",placeholder:"Import url",validate:{rules:{required:!0},messages:{required:"Enter URL to import content."}},callback:function(){return _this.handleImport()}})
this.importButton=new KDButtonView({iconOnly:!0,iconClass:"import",cssClass:"tw-dashboard-button",callback:function(){return _this.handleImport()}})
this.playgrounds=new KDCustomHTMLView({cssClass:"tw-playgrounds"})
this.sessionButton=new KDButtonView({cssClass:"tw-session-button",title:"Start your session now!",callback:function(){return _this.getDelegate().emit("NewSessionRequested")}})
this.fetchManifests()}__extends(TeamworkDashboard,_super)
TeamworkDashboard.prototype.show=function(){return this.setClass("active")}
TeamworkDashboard.prototype.hide=function(){return this.unsetClass("active")}
TeamworkDashboard.prototype.createPlaygrounds=function(manifests){var _this=this
return null!=manifests?manifests.forEach(function(manifest){var view
_this.setClass("ready")
_this.playgrounds.addSubView(view=new KDCustomHTMLView({cssClass:"tw-playground-item",partial:'<img src="'+manifest.icon+'" />\n<div class="content">\n  <h4>'+manifest.name+"</h4>\n  <p>"+manifest.description+"</p>\n</div>"}))
return view.addSubView(new KDButtonView({cssClass:"tw-play-button",title:"Play",callback:function(){return new KDNotificationView({title:"Coming Soon"})}}))}):void 0}
TeamworkDashboard.prototype.handleImport=function(){return this.getDelegate().emit("ImportRequested",this.importInput.getValue())}
TeamworkDashboard.prototype.handleJoinSession=function(){var sessionKey,temp,_ref
sessionKey=this.joinInput.getValue()
if(sessionKey.match(/(http|https)/)){if(!(sessionKey.indexOf("koding.com")>-1&&sessionKey.indexOf("sessionKey=")>-1))return new KDNotificationView({type:"mini",cssClass:"error",title:"Could not resolve your URL",duration:5e3})
_ref=sessionKey.split("sessionKey="),temp=_ref[0],sessionKey=_ref[1]}return this.getDelegate().emit("JoinSessionRequested",sessionKey)}
TeamworkDashboard.prototype.fetchManifests=function(){var delegate,filename,_this=this
filename="localhost"===location.hostname?"manifest-dev":"manifest"
delegate=this.getDelegate()
return delegate.fetchManifestFile(""+filename+".json",function(err,manifests){if(err){_this.setClass("ready")
_this.playgrounds.hide()
return new KDNotificationView({type:"mini",cssClass:"error",title:"Could not fetch Playground manifest.",duration:4e3})}delegate.playgroundsManifest=manifests
return _this.createPlaygrounds(manifests)})}
TeamworkDashboard.prototype.pistachio=function(){return'<div class="actions">\n  <div class="tw-items-container">\n    <div class="item team-up">\n      <div class="badge"></div>\n      <h3>Team Up</h3>\n      <p>Team up and start working with your friends. Invite your Koding friends or invite them via email.</p>\n      {{> this.teamUpButton}}\n    </div>\n    <div class="item join-in">\n      <div class="badge"></div>\n      <h3>Join In</h3>\n      <p>Join your friend\'s Teamwork session. You can enter a session key or a full Koding URL.</p>\n      <div class="tw-input-container">\n        {{> this.joinInput}}\n        {{> this.joinButton}}\n      </div>\n    </div>\n    <div class="item import">\n      <div class="badge"></div>\n      <h3>Import</h3>\n      <p>Import content to your VM and start working on it. It might be a zip file or a GitHub repository.</p>\n      <div class="tw-input-container">\n        {{> this.importInput}}\n        {{> this.importButton}}\n      </div>\n    </div>\n  </div>\n</div>\n<div class="tw-playgrounds-container">\n  <p class="loading">Loading Playgrounds...</p>\n  {{> this.playgrounds}}\n</div>'}
return TeamworkDashboard}(JView)

var TeamworkImporter,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkImporter=function(_super){function TeamworkImporter(options,data){null==options&&(options={})
options.rootPath||(options.rootPath="/home/"+KD.nick()+"/Web/Teamwork")
TeamworkImporter.__super__.constructor.call(this,options,data)
this.vmController=KD.getSingleton("vmController")
this.vmName=this.vmController.defaultVmName
this.url=this.getOptions().url
this.parseUrl()}__extends(TeamworkImporter,_super)
TeamworkImporter.prototype.parseUrl=function(){var extension,gitHubUrlRegex,isGitHubUrl,_this=this
extension=FSItem.getFileExtension(this.url)
gitHubUrlRegex=/http(s)?:\/\/github.com/
isGitHubUrl=gitHubUrlRegex.test(this.url)
if(isGitHubUrl){if("git"===extension)return this.cloneRepo()
this.url=""+this.url+".git"
return this.cloneRepo()}switch(extension){case"zip":return this.downloadZip()
case"git":return this.cloneRepo()
default:return this.attemptedUrlResolve===!0?warn("Url couldn't resolved.. "+this.url):this.resolveUrl(function(){return _this.parseUrl()})}}
TeamworkImporter.prototype.downloadZip=function(){var commands,fileName,rootPath,_this=this
rootPath=this.getOptions().rootPath
this.tempPath=""+rootPath+"/.tmp"
fileName="tw-file-"+Date.now()+".zip"
commands=["rm -rf "+this.tempPath,"mkdir -p "+this.tempPath,"cd "+this.tempPath,"wget -O "+fileName+" "+this.url,"unzip "+fileName,"rm "+fileName,"rm -rf __MACOSX"]
this.notify("Downloading zip file...","",25e3)
commands=commands.join(" && ")
return this.vmController.run(commands,function(err){return err?_this.handleError(err):FSHelper.glob(""+_this.tempPath+"/*",_this.vmName,function(err,folders){var folder
if(err)return _this.handleError(err)
_this.folderName=FSHelper.getFileNameFromPath(folders.first)
folder=FSHelper.createFileFromPath(""+rootPath+"/"+_this.folderName,"folder")
return folder.exists(function(err,isExists){return err?_this.handleError(err):isExists?_this.showOverwriteModal():_this.importDone_()})})})}
TeamworkImporter.prototype.showOverwriteModal=function(contentOptions){var modal,options,_ref,_ref1,_this=this
null==contentOptions&&(contentOptions={})
options=this.getOptions()
null!=(_ref=options.modal)&&_ref.destroy()
null!=(_ref1=this.notification)&&_ref1.destroy()
return modal=new KDModalView({title:"Folder Exists",cssClass:"modal-with-text",overlay:!0,content:contentOptions.content||"<p>There is already a folder with the same name. Do you want to overwrite it?</p>",buttons:{Confirm:{title:"Overwrite",cssClass:"modal-clean-red",callback:function(){modal.destroy()
return contentOptions.confirmCallback?contentOptions.confirmCallback(modal):_this.importDone_()}},Cancel:{title:"Cancel",cssClass:"modal-cancel",callback:function(){var _ref2
modal.destroy()
if("function"==typeof contentOptions.cancelCallback?!contentOptions.cancelCallback(modal):!0){_this.vmController.run("rm -rf "+_this.tempPath)
null!=(_ref2=_this.notification)&&_ref2.destroy()
return _this.getDelegate().setVMRoot(""+_this.root+"/"+_this.folderName)}}}}})}
TeamworkImporter.prototype.importDone_=function(){var command,delegate,options,rootPath,_this=this
options=this.getOptions()
rootPath=options.rootPath
delegate=this.getDelegate()
command="rm -rf "+rootPath+"/"+this.folderName+" ; mv "+this.tempPath+"/"+this.folderName+" "+rootPath
return this.vmController.run(command,function(){var _ref,_ref1
null!=(_ref=options.modal)&&_ref.destroy()
null!=(_ref1=_this.notification)&&_ref1.destroy()
"function"==typeof options.callback&&options.callback()
_this.vmController.run("rm -rf @{tempPath}")
return _this.checkContent()})}
TeamworkImporter.prototype.checkContent=function(){var delegate,folderPath,mdFile,mdPath,rootPath,shFile,shPath,_this=this
rootPath=this.getOptions().rootPath
folderPath=""+rootPath+"/"+this.folderName
mdPath=""+folderPath+"/README.md"
shPath=""+folderPath+"/install.sh"
mdFile=FSHelper.createFileFromPath(mdPath)
shFile=FSHelper.createFileFromPath(shPath)
delegate=this.getDelegate()
delegate.setVMRoot(folderPath)
return mdFile.exists(function(err,mdExists){return mdExists?mdFile.fetchContents(function(err,mdContent){delegate=_this.getDelegate()
delegate.showMarkdownModal(mdContent)
return delegate.mdModal.once("KDObjectWillBeDestroyed",function(){return _this.checkShFile(shFile)})}):_this.checkShFile(shFile)})}
TeamworkImporter.prototype.checkShFile=function(shFile){var _this=this
return shFile.exists(function(err,fileExist){return fileExist?shFile.fetchContents(function(err,shContent){var modal
return modal=new KDModalView({title:"Installation Script",cssClass:"modal-with-text",width:600,overlay:!0,content:'<p>This Playground wants to execute the following install script. Do you want to continue?</p>\n<p>\n  <pre class="tw-sh-preview">'+shContent+"</pre>\n</p>",buttons:{Install:{title:"Install Script",cssClass:"modal-clean-green",callback:function(){return _this.runShFile(shFile,modal)}},Cancel:{title:"Cancel",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})}):void 0})}
TeamworkImporter.prototype.runShFile=function(shFile,modal){var paneLauncher,_this=this
modal.destroy()
paneLauncher=this.getDelegate().teamwork.getActivePanel().paneLauncher
paneLauncher.paneVisibilityState.terminal||paneLauncher.handleLaunch("terminal")
return this.vmController.run("chmod 777 "+shFile.path,function(err){return err?_this.handleError(err):paneLauncher.terminalPane.runCommand("./"+shFile.path)})}
TeamworkImporter.prototype.cloneRepo=function(){var repoFolder,rootPath,_this=this
rootPath=this.getOptions().rootPath
this.folderName=FSHelper.getFileNameFromPath(this.url).split(".git")[0]
repoFolder=FSHelper.createFileFromPath(""+rootPath+"/"+this.folderName,"folder")
return repoFolder.exists(function(err,isExists){return err?_this.handleError(err):isExists?_this.showOverwriteModal({content:"<p>Repo exists. Overwrite?</p>",confirmCallback:function(){return repoFolder.remove(function(){return _this.doClone()})},cancelCallback:function(modal){return modal.destroy()}}):_this.doClone()})}
TeamworkImporter.prototype.doClone=function(){var commands,modal,rootPath,_ref,_this=this
this.notify("Cloning repository...","",3e4)
_ref=this.getOptions(),rootPath=_ref.rootPath,modal=_ref.modal
commands=["mkdir -p "+rootPath,"cd "+rootPath,"git clone "+this.url]
null!=modal&&modal.destroy()
return this.vmController.run(commands.join(" && "),function(err){var _ref1
if(err)return _this.handleError(err)
_this.getDelegate().setVMRoot(""+rootPath+"/"+_this.folderName)
null!=(_ref1=_this.notification)&&_ref1.destroy()
return _this.checkContent()})}
TeamworkImporter.prototype.resolveUrl=function(callback){var _this=this
null==callback&&(callback=noop)
return this.vmController.run("curl -sIL "+this.url+" | grep ^Location",function(err,longUrl){err&&_this.handleError(err)
_this.url=longUrl.replace("Location: ","").replace(/\n/g,"").trim()
_this.attemptedUrlResolve=!0
return callback()})}
TeamworkImporter.prototype.notify=function(title,cssClass,duration){var type,_ref
null==duration&&(duration=4200)
type="mini"
null!=(_ref=this.notification)&&_ref.destroy()
return this.notification=new KDNotificationView({title:title,cssClass:cssClass,duration:duration,type:type})}
TeamworkImporter.prototype.handleError=function(err){this.notify("Something went wrong.","error")
return warn(err)}
return TeamworkImporter}(KDObject)

var TeamworkChatPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkChatPane=function(_super){function TeamworkChatPane(options,data){null==options&&(options={})
TeamworkChatPane.__super__.constructor.call(this,options,data)
this.setClass("tw-chat")
this.getDelegate().setClass("tw-chat-open")}__extends(TeamworkChatPane,_super)
TeamworkChatPane.prototype.createDock=function(){return this.dock=new KDCustomHTMLView({cssClass:"hidden"})}
TeamworkChatPane.prototype.updateCount=function(){}
return TeamworkChatPane}(ChatPane)

var TeamworkWorkspace,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkWorkspace=function(_super){function TeamworkWorkspace(options,data){var playground,playgroundManifest,_ref,_this=this
null==options&&(options={})
TeamworkWorkspace.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),playground=_ref.playground,playgroundManifest=_ref.playgroundManifest
this.avatars={}
this.on("PanelCreated",function(panel){_this.createButtons(panel)
playground&&_this.createRunButton(panel)
_this.getActivePanel().header.setClass("teamwork")
return _this.createActivityWidget(panel)})
this.on("WorkspaceSyncedWithRemote",function(){if(playground&&_this.amIHost()){_this.workspaceRef.child("playground").set(playground)
playgroundManifest&&_this.workspaceRef.child("playgroundManifest").set(playgroundManifest)}_this.amIHost()||_this.hidePlaygroundsButton()
return _this.workspaceRef.child("users").on("child_added",function(snapshot){var joinedUser
joinedUser=snapshot.name()
return joinedUser&&joinedUser!==KD.nick()?_this.hidePlaygroundsButton():void 0})})
this.on("WorkspaceUsersFetched",function(){return _this.workspaceRef.child("users").once("value",function(snapshot){var userStatus
userStatus=snapshot.val()
return userStatus?_this.manageUserAvatars(userStatus):void 0})})
this.on("NewHistoryItemAdded",function(data){return _this.sendSystemMessage(data.message)})}__extends(TeamworkWorkspace,_super)
TeamworkWorkspace.prototype.createButtons=function(panel){var chatButton,_this=this
panel.addSubView(this.buttonsContainer=new KDCustomHTMLView({cssClass:"tw-buttons-container"}))
this.buttonsContainer.addSubView(chatButton=new KDButtonView({cssClass:"tw-chat-toggle active",iconClass:"tw-chat",iconOnly:!0,callback:function(){var cssClass,isChatVisible
cssClass="tw-chat-open"
isChatVisible=_this.hasClass(cssClass)
_this.toggleClass(cssClass)
chatButton.toggleClass("active")
return isChatVisible?_this.chatView.hide():_this.chatView.show()}}))
return this.buttonsContainer.addSubView(new KDButtonView({iconClass:"tw-cog",iconOnly:!0,callback:function(){return _this.getDelegate().showToolsModal(panel,_this)}}))}
TeamworkWorkspace.prototype.displayBroadcastMessage=function(options){var _this=this
TeamworkWorkspace.__super__.displayBroadcastMessage.call(this,options)
return"users"===options.origin?KD.utils.wait(500,function(){return _this.fetchUsers()}):void 0}
TeamworkWorkspace.prototype.startNewSession=function(options){var teamwork,workspaceClass
KD.mixpanel("User Started Teamwork session")
this.destroySubViews()
if(!options){options=this.getOptions()
delete options.sessionKey}workspaceClass=this.getPlaygroundClass(options.playground)
teamwork=new workspaceClass(options)
this.getDelegate().teamwork=teamwork
return this.addSubView(teamwork)}
TeamworkWorkspace.prototype.joinSession=function(newOptions){var options,sessionKey,_this=this
sessionKey=newOptions.sessionKey.trim()
options=this.getOptions()
options.sessionKey=sessionKey
options.joinedASession=!0
this.destroySubViews()
this.forceDisconnect()
return this.firepadRef.child(sessionKey).once("value",function(snapshot){var playground,playgroundManifest,teamwork,teamworkClass,teamworkOptions,value
value=snapshot.val()
value&&(playground=value.playground,playgroundManifest=value.playgroundManifest)
teamworkClass=TeamworkWorkspace
teamworkOptions=options
playground&&(teamworkClass=_this.getPlaygroundClass(playground))
playgroundManifest&&(teamworkOptions=_this.getDelegate().mergePlaygroundOptions(playgroundManifest))
teamworkOptions.sessionKey=newOptions.sessionKey
teamwork=new teamworkClass(teamworkOptions)
_this.getDelegate().teamwork=teamwork
return _this.addSubView(teamwork)})}
TeamworkWorkspace.prototype.refreshPreviewPane=function(previewPane){return previewPane.previewer.emit("ViewerRefreshed")}
TeamworkWorkspace.prototype.createRunButton=function(panel){var _this=this
return panel.headerButtonsContainer.addSubView(new KDButtonView({title:"Run",cssClass:"clean-gray tw-ply-run",callback:function(){return _this.handleRun(panel)}}))}
TeamworkWorkspace.prototype.getPlaygroundClass=function(playground){return"Facebook"===playground?FacebookTeamwork:PlaygroundTeamwork}
TeamworkWorkspace.prototype.handleRun=function(){return console.warn("You should override this method.")}
TeamworkWorkspace.prototype.hidePlaygroundsButton=function(){var _ref
return null!=(_ref=this.getActivePanel().headerButtons.Playgrounds)?_ref.hide():void 0}
TeamworkWorkspace.prototype.showHintModal=function(){return this.markdownContent?this.getDelegate().showMarkdownModal():Panel.prototype.showHintModal.call(this.getActivePanel())}
TeamworkWorkspace.prototype.previewFile=function(){var activePanel,editor,error,file,isLocal,isNotPublic,path,previewPane,url
activePanel=this.getActivePanel()
editor=activePanel.getPaneByName("editor")
file=editor.getActivePaneFileData()
path=FSHelper.plainPath(file.path)
error="File must be under Web folder"
isLocal=0===path.indexOf("localfile")
isNotPublic=!FSHelper.isPublicPath(path)
previewPane=activePanel.paneLauncher.previewPane
if(isLocal||isNotPublic){isLocal&&(error="This file cannot be previewed")
return new KDNotificationView({title:error,cssClass:"error",type:"mini",duration:2500,container:previewPane})}url=path.replace("/home/"+this.getHost()+"/Web","https://"+KD.nick()+".kd.io")
return previewPane.openUrl(url)}
TeamworkWorkspace.prototype.manageUserAvatars=function(userStatus){var nickname,status,_results
_results=[]
for(nickname in userStatus)if(__hasProp.call(userStatus,nickname)){status=userStatus[nickname]
"online"===status?this.avatars[nickname]?_results.push(void 0):_results.push(this.createUserAvatar(this.users[nickname])):this.avatars[nickname]?_results.push(this.removeUserAvatar(nickname)):_results.push(void 0)}return _results}
TeamworkWorkspace.prototype.createUserAvatar=function(jAccount){var avatarView,followText,userNickname,_this=this
if(jAccount){userNickname=jAccount.profile.nickname
if(userNickname!==KD.nick()){followText="Click user avatar to watch "+userNickname
avatarView=new AvatarStaticView({size:{width:25,height:25},tooltip:{title:followText},click:function(){var isAlreadyWatched,message,_ref
null!=(_ref=_this.watchingUserAvatar)&&_ref.unsetClass("watching")
isAlreadyWatched=_this.watchingUserAvatar===avatarView
if(isAlreadyWatched){_this.watchRef.child(_this.nickname).set("nobody")
message=""+KD.nick()+" stopped watching "+userNickname
_this.watchingUserAvatar=null
avatarView.setTooltip({title:followText})}else{_this.watchRef.child(_this.nickname).set(userNickname)
message=""+KD.nick()+" started to watch "+userNickname+".  Type 'stop watching' or click on avatars to start/stop watching."
avatarView.setClass("watching")
_this.watchingUserAvatar=avatarView
avatarView.setTooltip({title:"You are now watching "+userNickname+". Click again to stop watching."})}message={user:{nickname:"teamwork"},time:Date.now(),body:message}
return _this.workspaceRef.child("chat").child(message.time).set(message)}},jAccount)
this.avatars[userNickname]=avatarView
this.avatarsView.addSubView(avatarView)
this.avatarsView.setClass("has-user")
return avatarView.bindTransitionEnd()}}}
TeamworkWorkspace.prototype.removeUserAvatar=function(nickname){var avatarView,_this=this
avatarView=this.avatars[nickname]
avatarView.setClass("fade-out")
return avatarView.once("transitionend",function(){avatarView.destroy()
delete _this.avatars[nickname]
return 0===_this.avatars.length?_this.avatarsView.unsetClass("has-user"):void 0})}
TeamworkWorkspace.prototype.sendSystemMessage=function(message){return this.getOptions().enableChat?this.chatView.sendMessage(message,!0):void 0}
TeamworkWorkspace.prototype.createActivityWidget=function(panel){var activityId,shareButton,_this=this
panel.addSubView(this.activityWidget=new ActivityWidget({cssClass:"tw-activity-widget collapsed",childOptions:{cssClass:"activity-item"}}))
this.activityWidget.addSubView(this.notification=new KDCustomHTMLView({cssClass:"notification",partial:"This status update will be visible in Activity feed."}))
this.activityWidget.addSubView(new KDCustomHTMLView({cssClass:"close-tab",click:this.bound("hideActivityWidget")}))
panel.addSubView(this.inviteTeammate=new KDButtonView({cssClass:"invite-teammate tw-rounded-button hidden",title:"Invite",callback:function(){var url
url=""+KD.config.apiUri+"/Teamwork?sessionKey="+_this.sessionKey
_this.activityWidget.setInputContent("Would you like to join my Teamwork session? "+url)
_this.showActivityWidget()
return _this.hideShareButtons()}}))
panel.addSubView(this.exportWorkspace=new KDButtonView({cssClass:"export-workspace tw-rounded-button hidden",title:"Export",callback:function(){_this.getDelegate().emit("ExportRequested",function(){})
return _this.hideShareButtons()}}))
panel.addSubView(shareButton=new KDButtonView({cssClass:"tw-rounded-button share",title:"Share",callback:function(){_this.inviteTeammate.toggleClass("hidden")
return _this.exportWorkspace.toggleClass("hidden")}}))
panel.addSubView(this.showActivityWidgetButton=new KDButtonView({cssClass:"tw-show-activity-widget",iconOnly:!0,iconClass:"icon",callback:function(){if(_this.activityWidget.activity){_this.activityWidget.hideForm()
return _this.showActivityWidget()}return _this.share()}}))
activityId=this.getOptions().activityId
activityId?this.displayActivity(activityId):this.workspaceRef.child("activityId").once("value",function(snapshot){return(activityId=snapshot.val())?_this.displayActivity(activityId):void 0})
return this.getDelegate().on("Exported",function(name,importUrl){var query,querystring,_ref
activityId=null!=(_ref=_this.activityWidget.activity)?_ref.getId():void 0
query={"import":importUrl}
activityId&&(query.activityId=activityId)
querystring=_this.utils.stringifyQuery(query)
return _this.utils.shortenUrl(""+KD.config.apiUri+"/Teamwork?"+querystring,function(url){var message
message=""+KD.nick()+" exported "+name+" "+url
if(activityId)return _this.activityWidget.reply(message)
_this.activityWidget.setInputContent(message)
return _this.showActivityWidget()})})}
TeamworkWorkspace.prototype.showActivityWidget=function(){this.activityWidget.show()
return this.activityWidget.unsetClass("collapsed")}
TeamworkWorkspace.prototype.hideActivityWidget=function(){var _this=this
this.activityWidget.setClass("collapsed")
return this.activityWidget.on("transitionend",function(){return _this.activityWidget.hide()})}
TeamworkWorkspace.prototype.showShareButtons=function(){this.inviteTeammate.show()
return this.exportWorkspace.show()}
TeamworkWorkspace.prototype.hideShareButtons=function(){this.inviteTeammate.hide()
return this.exportWorkspace.hide()}
TeamworkWorkspace.prototype.displayActivity=function(id){var _this=this
return this.activityWidget.display(id,function(){_this.notification.hide()
return _this.activityWidget.hideForm()})}
TeamworkWorkspace.prototype.share=function(){var _this=this
this.activityWidget.show()
this.activityWidget.unsetClass("collapsed")
return this.activityWidget.activity?this.activityWidget.hideForm():this.activityWidget.showForm(function(err,activity){if(err)return err
_this.activityWidget.hideForm()
_this.notification.hide()
return _this.workspaceRef.child("activityId").set(activity.getId())})}
return TeamworkWorkspace}(CollaborativeWorkspace)

var PlaygroundTeamwork,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PlaygroundTeamwork=function(_super){function PlaygroundTeamwork(options,data){var _this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("playground",options.cssClass)
PlaygroundTeamwork.__super__.constructor.call(this,options,data)
this.on("PanelCreated",function(){return _this.getActivePanel().header.unsetClass("teamwork")})
this.on("ContentIsReady",function(){var initialState,manifest,prerequisite
if(_this.amIHost()){manifest=_this.getOptions().playgroundManifest
prerequisite=manifest.prerequisite,initialState=manifest.initialState
return prerequisite?"sh"===prerequisite.type?initialState?_this.doPrerequisite(prerequisite.command,function(){return _this.setUpInitialState(initialState)}):_this.doPrerequisite(prerequisite.command):warn("Unhandled prerequisite type."):initialState?_this.setUpInitialState(initialState):void 0}})}__extends(PlaygroundTeamwork,_super)
PlaygroundTeamwork.prototype.handleRun=function(panel){var command,handler,options,paneLauncher,path,plainPath,playground,runConfig
options=this.getOptions()
playground=options.playground
runConfig=options.playgroundManifest.run
if(!runConfig)return warn("Missing run config for "+playground+".")
handler=runConfig.handler,command=runConfig.command
paneLauncher=panel.paneLauncher
if(!handler||!command)return warn("Missing parameter for "+playground+" run config. You must pass a handler and a command")
if("terminal"===handler){path=panel.getPaneByName("editor").getActivePaneFileData().path
plainPath=FSHelper.plainPath(path)
command=command.replace("$ACTIVE_FILE_PATH",' "'+plainPath+'" ')
paneLauncher.paneVisibilityState.terminal===!1&&paneLauncher.handleLaunch("terminal")
return paneLauncher.terminalPane.runCommand(command)}return"preview"===handler?this.handlePreview(command):warn("Unimplemented run hanldler for "+playground)}
PlaygroundTeamwork.prototype.doPrerequisite=function(command,callback){null==callback&&(callback=noop)
return command?KD.getSingleton("vmController").run(command,function(err){return err?warn(err):callback()}):warn("no command passed for prerequisite")}
PlaygroundTeamwork.prototype.setUpInitialState=function(initialState){initialState.preview&&this.handlePreview(initialState.preview.url)
return initialState.editor?this.openFiles(initialState.editor.files):void 0}
PlaygroundTeamwork.prototype.handlePreview=function(url){var paneLauncher
paneLauncher=this.getActivePanel().paneLauncher
url=url.replace("$USERNAME",this.getHost())
paneLauncher.paneVisibilityState.preview===!1&&paneLauncher.handleLaunch("preview")
return paneLauncher.previewPane.openUrl(url)}
PlaygroundTeamwork.prototype.openFiles=function(files){var editor,file,filePath,path,_i,_len,_results
editor=this.getActivePanel().getPaneByName("editor")
_results=[]
for(_i=0,_len=files.length;_len>_i;_i++){path=files[_i]
filePath="/home/"+KD.nick()+"/Web/Teamwork/"+this.getOptions().playground+"/"+path.replace(/^.\//,"")
file=FSHelper.createFileFromPath(filePath)
_results.push(file.fetchContents(function(err,contents){return editor.openFile(file,contents)}))}return _results}
return PlaygroundTeamwork}(TeamworkWorkspace)

var TeamworkApp,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkApp=function(_super){function TeamworkApp(options,data){var importUrl,sessionKey,_this=this
null==options&&(options={})
options.query||(options.query={})
TeamworkApp.__super__.constructor.call(this,options,data)
this.appView=this.getDelegate()
this.on("NewSessionRequested",function(callback,options){var _ref
null==callback&&(callback=noop)
null!=(_ref=_this.teamwork)&&_ref.destroy()
_this.createTeamwork(options)
_this.appView.addSubView(_this.teamwork)
return callback()})
this.on("JoinSessionRequested",function(sessionKey){var firebase
_this.setOption("sessionKey",sessionKey)
firebase=new Firebase("https://"+instanceName+".firebaseio.com/")
return firebase.child(sessionKey).once("value",function(snapshot){var val
val=snapshot.val()
if(null!=val?val.playground:void 0){_this.setOption("playgroundManifest",val.playgroundManifest)
_this.setOption("playground",val.playground)
options=_this.mergePlaygroundOptions(val.playgroundManifest,val.playground)
return _this.emit("NewSessionRequested",null,options)}return _this.emit("NewSessionRequested")})})
this.on("ImportRequested",function(importUrl){_this.emit("NewSessionRequested")
return _this.teamwork.on("WorkspaceSyncedWithRemote",function(){return _this.showImportWarning(importUrl)})})
this.on("ExportRequested",function(callback){_this.showExportModal()
return _this.tools.once("Exported",callback)})
this.on("TeamUpRequested",function(){return _this.teamwork.once("WorkspaceSyncedWithRemote",function(){return _this.showTeamUpModal()})})
sessionKey=options.query.sessionKey
importUrl=options.query["import"]
sessionKey?this.emit("JoinSessionRequested",sessionKey):importUrl?this.emit("ImportRequested",importUrl):this.emit("NewSessionRequested")}var instanceName
__extends(TeamworkApp,_super)
instanceName="localhost"===location.hostname?"tw-local":"kd-prod-1"
TeamworkApp.prototype.createTeamwork=function(options){var playgroundClass
playgroundClass=TeamworkWorkspace;(null!=options?options.playground:void 0)&&(playgroundClass="Facebook"===options.playground?FacebookTeamwork:PlaygroundTeamwork)
return this.teamwork=new playgroundClass(options||this.getTeamworkOptions())}
TeamworkApp.prototype.showTeamUpModal=function(){this.showToolsModal(this.teamwork.getActivePanel(),this.teamwork)
this.tools.teamUpHeader.emit("click")
return this.tools.setClass("team-up-mode")}
TeamworkApp.prototype.showExportModal=function(){this.showToolsModal(this.teamwork.getActivePanel(),this.teamwork)
this.tools.shareHeader.emit("click")
return this.tools.setClass("share-mode")}
TeamworkApp.prototype.getTeamworkOptions=function(){var options
options=this.getOptions()
return{name:options.name||"Teamwork",joinModalTitle:options.joinModalTitle||"Join a coding session",joinModalContent:options.joinModalContent||"<p>Paste the session key that you received and start coding together.</p>",shareSessionKeyInfo:options.shareSessionKeyInfo||"<p>This is your session key, you can share this key with your friends to work together.</p>",firebaseInstance:options.firebaseInstance||instanceName,sessionKey:options.sessionKey,activityId:options.query.activityId,delegate:this,enableChat:!0,chatPaneClass:TeamworkChatPane,playground:options.playground||null,panels:options.panels||[{hint:"<p>This is a collaborative coding environment where you can team up with others and work on the same code.</p>",buttons:[],layout:{direction:"vertical",sizes:["265px",null],splitName:"BaseSplit",views:[{title:"<div class='header-title'><span class='icon'></span>Teamwork</div>",type:"finder",name:"finder",editor:"tabView"},{type:"custom",paneClass:TeamworkTabView,name:"tabView"}]}}]}}
TeamworkApp.prototype.showToolsModal=function(panel,workspace){var modal
modal=new KDModalView({cssClass:"teamwork-tools-modal",title:"Teamwork Tools",overlay:!0,width:600})
modal.addSubView(this.tools=new TeamworkTools({modal:modal,panel:panel,workspace:workspace,twApp:this}))
this.emit("TeamworkToolsModalIsReady",modal)
return this.forwardEvent(this.tools,"Exported")}
TeamworkApp.prototype.showImportWarning=function(url,callback){var modal,_ref,_this=this
null==callback&&(callback=noop)
null!=(_ref=this.importModal)&&_ref.destroy()
return modal=this.importModal=new KDModalView({title:"Import File",cssClass:"modal-with-text",overlay:!0,content:this.teamwork.getOptions().importModalContent||"<p>This Teamwork URL wants to download a file to your VM from <strong>"+url+"</strong></p>\n<p>Would you like to import and start working with these files?</p>",buttons:{Import:{title:"Import",cssClass:"modal-clean-green",loader:{color:"#FFFFFF",diameter:14},callback:function(){return new TeamworkImporter({url:url,modal:modal,callback:callback,delegate:_this})}},DontImport:{title:"Don't import anything",cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})}
TeamworkApp.prototype.showMarkdownModal=function(rawContent){var modal,t
t=this.teamwork
rawContent&&(t.markdownContent=KD.utils.applyMarkdown(rawContent))
return modal=this.mdModal=new TeamworkMarkdownModal({content:t.markdownContent,targetEl:t.getActivePanel().headerHint})}
TeamworkApp.prototype.setVMRoot=function(path){var defaultVmName,finderController
finderController=this.teamwork.getActivePanel().getPaneByName("finder").finderController
defaultVmName=KD.getSingleton("vmController").defaultVmName
finderController.getVmNode(defaultVmName)&&finderController.unmountVm(defaultVmName)
return finderController.mountVm(""+defaultVmName+":"+path)}
TeamworkApp.prototype.mergePlaygroundOptions=function(manifest,playground){var firstPanel,name,rawOptions
rawOptions=this.getTeamworkOptions()
name=manifest.name
firstPanel=rawOptions.panels.first
firstPanel.title=name
rawOptions.playground=playground
rawOptions.name=name
firstPanel.headerStyling=manifest.styling
rawOptions.examples=manifest.examples
rawOptions.contentDetails=manifest.content
rawOptions.playgroundManifest=manifest
manifest.importModalContent&&(rawOptions.importModalContent=manifest.importModalContent)
return rawOptions}
TeamworkApp.prototype.getPlaygroundClass=function(playground){return"Facebook"===playground?FacebookTeamwork:PlaygroundTeamwork}
TeamworkApp.prototype.handlePlaygroundSelection=function(playground,manifestUrl){var manifest,_i,_len,_ref,_this=this
if(!manifestUrl){_ref=this.playgroundsManifest
for(_i=0,_len=_ref.length;_len>_i;_i++){manifest=_ref[_i]
playground===manifest.name&&(manifestUrl=manifest.manifestUrl)}}return this.doCurlRequest(manifestUrl,function(err,manifest){var _ref1
null!=(_ref1=_this.teamwork)&&_ref1.destroy()
_this.createTeamwork(_this.mergePlaygroundOptions(manifest,playground))
_this.appView.addSubView(_this.teamwork)
_this.teamwork.container.setClass(playground)
return _this.teamwork.on("WorkspaceSyncedWithRemote",function(){var contentDetails,contentUrl,folder,manifestVersion,root
contentDetails=_this.teamwork.getOptions().contentDetails
KD.mixpanel("User Changed Playground",playground)
if("zip"===contentDetails.type){root="/home/"+_this.teamwork.getHost()+"/Web/Teamwork/"+playground
folder=FSHelper.createFileFromPath(root,"folder")
contentUrl=contentDetails.url
manifestVersion=manifest.version
return folder.exists(function(err,exists){var appStorage
if(!exists)return _this.setUpImport(contentUrl,manifestVersion,playground)
appStorage=KD.getSingleton("appStorageController").storage("Teamwork","1.0")
return appStorage.fetchStorage(function(){var currentVersion,hasNewVersion
currentVersion=appStorage.getValue(""+playground+"PlaygroundVersion")
hasNewVersion=KD.utils.versionCompare(manifestVersion,"gt",currentVersion)
if(hasNewVersion)return _this.setUpImport(contentUrl,manifestVersion,playground)
_this.setVMRoot(root)
return _this.teamwork.emit("ContentIsReady")})})}return warn("Unhandled content type for "+name)})})}
TeamworkApp.prototype.setUpImport=function(url,version,playground){var _this=this
if(!url)return warn("Missing url parameter to import zip file for "+playground)
this.teamwork.importInProgress=!0
return this.showImportWarning(url,function(){var appStorage
_this.teamwork.emit("ContentIsReady")
_this.teamwork.importModalContent=!1
appStorage=KD.getSingleton("appStorageController").storage("Teamwork","1.0")
return appStorage.setValue(""+playground+"PlaygroundVersion",version)})}
TeamworkApp.prototype.doCurlRequest=function(path,callback){var vmController
null==callback&&(callback=noop)
vmController=KD.getSingleton("vmController")
return vmController.run({withArgs:"kdwrap curl -kLs "+path,vmName:vmController.defaultVmName},function(err,contents){var error,extension,manifest
extension=FSItem.getFileExtension(path)
error=null
switch(extension){case"json":try{manifest=JSON.parse(contents)}catch(_error){err=_error
error="Manifest file is broken for "+path}return callback(error,manifest)
case"md":return callback(errorMessage,KD.utils.applyMarkdown(error,contents))}})}
TeamworkApp.prototype.fetchManifestFile=function(path,callback){null==callback&&(callback=noop)
return $.ajax({url:"http://resources.gokmen.kd.io/Teamwork/Playgrounds/"+path,type:"GET",success:function(response){return response?callback(null,response):callback(!0,null)},error:function(){return callback(!0,null)}})}
return TeamworkApp}(KDObject)

var FacebookTeamwork,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FacebookTeamwork=function(_super){function FacebookTeamwork(options,data){var _this=this
null==options&&(options={})
FacebookTeamwork.__super__.constructor.call(this,options,data)
this.appStorage=KD.getSingleton("appStorageController").storage("Teamwork")
this.on("PanelCreated",function(panel){var editor
editor=panel.getPaneByName("editor")
return editor.on("OpenedAFile",function(){var content
content=editor.getActivePaneContent().replace("YOUR_APP_ID",_this.appId)
editor.getActivePaneEditor().setValue(content)
return _this.runButton?void 0:_this.createRunButton(panel)})})
this.on("ContentImportDone",function(){_this.createIndexFile()
return _this.appId&&_this.appNamespace&&_this.appCanvasUrl||!_this.amIHost()?void 0:_this.showInstructions()})
this.on("FacebookAppInfoTaken",function(info){_this.appId=info.appId,_this.appNamespace=info.appNamespace,_this.appCanvasUrl=info.appCanvasUrl
_this.appStorage.setValue("FacebookAppId",_this.appId)
_this.appStorage.setValue("FacebookAppNamespace",_this.appNamespace)
_this.appStorage.setValue("FacebookAppCanvasUrl",_this.appCanvasUrl)
return _this.setAppInfoToCloud()})
this.container.setClass("Facebook")
this.on("WorkspaceSyncedWithRemote",function(){return _this.amIHost()?_this.getAppInfo():void 0})
this.getDelegate().on("TeamworkToolsModalIsReady",function(modal){var header,revoke,wrapper
modal.addSubView(header=new KDCustomHTMLView({cssClass:"teamwork-modal-header",partial:'<div class="header full-width">\n  <span class="text">Facebook App Details</span>\n</div>'}))
modal.addSubView(wrapper=new KDCustomHTMLView({cssClass:"teamwork-modal-content full-width tw-fb-revoke",partial:'<div class="teamwork-modal-content">\n  <span class="initial">Below you can find your app details.</span>\n  <p>\n    <span>App ID</span>         <strong>'+_this.appId+"</strong><br />\n    <span>App Namespace</span>  <strong>"+_this.appNamespace+"</strong><br />\n    <span>Canvas Url</span>     <strong>"+_this.appCanvasUrl+"</strong><br /><br />\n  </p>\n</div>"}))
wrapper.addSubView(revoke=new KDCustomHTMLView({cssClass:"teamwork-modal-content revoke",partial:"<p>If you want to update your Facebook App ID, App Namespace or App Canvas Url click this button to start progress.</p>"}))
return revoke.addSubView(new KDButtonView({title:"Update",callback:function(){modal.destroy()
return _this.showInstructions()}}))})}__extends(FacebookTeamwork,_super)
FacebookTeamwork.prototype.showInstructions=function(){var d,_ref
d=this.getDelegate()
null!=(_ref=d.instructionsModal)&&_ref.destroy()
return d.instructionsModal=new FacebookTeamworkInstructionsModal({delegate:this})}
FacebookTeamwork.prototype.getAppInfo=function(){var _this=this
return this.appStorage.fetchStorage(function(){_this.appId=_this.appStorage.getValue("FacebookAppId")
_this.appNamespace=_this.appStorage.getValue("FacebookAppNamespace")
_this.appCanvasUrl=_this.appStorage.getValue("FacebookAppCanvasUrl")
if(_this.appId&&_this.appNamespace&&_this.appCanvasUrl){_this.setAppInfoToCloud()
return _this.checkFiles(function(err,res){return res?void 0:_this.startImport()})}return _this.checkFiles(function(err,res){return res?_this.showInstructions():_this.startImport()})})}
FacebookTeamwork.prototype.checkFiles=function(callback){null==callback&&(callback=noop)
return FSHelper.exists("Web/Teamwork/Facebook",KD.getSingleton("vmController").defaultVmName,function(err,res){return callback(err,res)})}
FacebookTeamwork.prototype.startImport=function(){var contentDetails,playgroundManifest,_ref,_this=this
_ref=this.getOptions(),contentDetails=_ref.contentDetails,playgroundManifest=_ref.playgroundManifest
return this.getDelegate().showImportWarning(contentDetails.url,function(){_this.appStorage.setValue("FacebookAppVersion",playgroundManifest.version)
return _this.emit("ContentImportDone")})}
FacebookTeamwork.prototype.createRunButton=function(panel){var _this=this
return panel.header.addSubView(this.runButton=new KDButtonViewWithMenu({title:"Run",menu:{"Run on Facebook":{callback:function(){return _this.runOnFB()}}},callback:function(){return _this.run()}}))}
FacebookTeamwork.prototype.run=function(){var activePanel,editor,nick,paneLauncher,path,preview,previewPane,root,target
activePanel=this.getActivePanel()
paneLauncher=activePanel.paneLauncher
paneLauncher.panesCreated||paneLauncher.createPanes()
preview=paneLauncher.preview,previewPane=paneLauncher.previewPane
paneLauncher.handleLaunch("preview")
editor=activePanel.getPaneByName("editor")
root="Web/Teamwork/Facebook"
path=FSHelper.plainPath(editor.getActivePaneFileData().path).replace(root,"")
nick=this.amIHost()?KD.nick():this.getHost()
target="https://"+nick+".kd.io/Teamwork/Facebook"
path.indexOf("localfile")>-1||(target+=path)
return previewPane.previewer.openPath(target)}
FacebookTeamwork.prototype.runOnFB=function(){var _this=this
return this.amIHost()||this.appNamespace?KD.utils.createExternalLink("http://apps.facebook.com/"+this.appNamespace):this.getAppInforFromCloud(function(){return _this.runOnFB()})}
FacebookTeamwork.prototype.setAppInfoToCloud=function(){return this.workspaceRef.child("FacebookAppInfo").set({appId:this.appId,appNamespace:this.appNamespace,appCanvasUrl:this.appCanvasUrl})}
FacebookTeamwork.prototype.getAppInforFromCloud=function(callback){var _this=this
null==callback&&(callback=noop)
return this.workspaceRef.once("value",function(snapshot){var facebookAppInfo
facebookAppInfo=snapshot.val().FacebookAppInfo
if(facebookAppInfo){_this.appId=facebookAppInfo.appId
_this.appNamespace=facebookAppInfo.appNamespace
_this.appCanvasUrl=facebookAppInfo.appCanvasUrl
return callback()}})}
FacebookTeamwork.prototype.createIndexFile=function(){var example,file,markup,_i,_len,_ref
markup=""
_ref=this.getOptions().examples
for(_i=0,_len=_ref.length;_len>_i;_i++){example=_ref[_i]
markup+=this.exampleItemMarkup(example.title,example.description)}markup=this.examplesPageMarkup(markup)
file=FSHelper.createFileFromPath("Web/Teamwork/Facebook/index.html")
return file.save(markup,function(err){return err?warn(err):void 0})}
FacebookTeamwork.prototype.exampleItemMarkup=function(title,description){return'<a href="https://'+KD.nick()+".kd.io/Teamwork/Facebook/"+title+'/index.html">\n  <div class="example">\n    <h3>'+title+"</h3>\n    <p>"+description+"</p>\n  </div>\n</a>"}
FacebookTeamwork.prototype.examplesPageMarkup=function(examplesMarkup){return'<html>\n  <head>\n    <title>Facebook App Examples</title>\n    <link rel="stylesheet" type="text/css" href="https://koding-cdn.s3.amazonaws.com/teamwork/tw-fb.css" />\n  </head>\n  <body>\n    <div class="examples">\n      '+examplesMarkup+"\n    </div>\n  </body>\n</html>"}
FacebookTeamwork.prototype.showHintModal=function(){var editor,file,readme,_this=this
editor=this.getActivePanel().getPaneByName("editor")
file=editor.getActivePaneFileData()
readme=FSHelper.createFileFromPath(""+file.parentPath+"/README.md")
return readme.fetchContents(function(err,content){return content?_this.getDelegate().showMarkdownModal(content):void 0})}
return FacebookTeamwork}(TeamworkWorkspace)

var TeamworkAppView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkAppView=function(_super){function TeamworkAppView(options,data){null==options&&(options={})
TeamworkAppView.__super__.constructor.call(this,options,data)
this.emit("ready")
if(location.search.match("chromeapp")){KD.getSingleton("mainView").enableFullscreen()
window.parent.postMessage("TeamworkReady","*")}}__extends(TeamworkAppView,_super)
TeamworkAppView.prototype.handleQuery=function(query){return this.teamworkApp?void 0:this.teamworkApp=new TeamworkApp({delegate:this,query:query})}
return TeamworkAppView}(KDView)

var TeamworkAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TeamworkAppController=function(_super){function TeamworkAppController(options,data){null==options&&(options={})
options.view=new TeamworkAppView
options.appInfo={type:"application",name:"Teamwork"}
TeamworkAppController.__super__.constructor.call(this,options,data)}__extends(TeamworkAppController,_super)
KD.registerAppClass(TeamworkAppController,{name:"Teamwork",route:"/:name?/Teamwork",behavior:"application"})
TeamworkAppController.prototype.handleQuery=function(query){var view
view=this.getView()
return view.ready(function(){return view.handleQuery(query)})}
return TeamworkAppController}(AppController)

//@ sourceMappingURL=/js/__teamwork.0.0.1.js.map