var JSON
JSON||(JSON={}),function(){function str(a,b){var c,d,e,f,h,g=gap,i=b[a]
i&&"object"==typeof i&&"function"==typeof i.toJSON&&(i=i.toJSON(a)),"function"==typeof rep&&(i=rep.call(b,a,i))
switch(typeof i){case"string":return quote(i)
case"number":return isFinite(i)?String(i):"null"
case"boolean":case"null":return String(i)
case"object":if(!i)return"null"
gap+=indent,h=[]
if("[object Array]"===Object.prototype.toString.apply(i)){f=i.length
for(c=0;f>c;c+=1)h[c]=str(c,i)||"null"
e=0===h.length?"[]":gap?"[\n"+gap+h.join(",\n"+gap)+"\n"+g+"]":"["+h.join(",")+"]",gap=g
return e}if(rep&&"object"==typeof rep){f=rep.length
for(c=0;f>c;c+=1)"string"==typeof rep[c]&&(d=rep[c],e=str(d,i),e&&h.push(quote(d)+(gap?": ":":")+e))}else for(d in i)Object.prototype.hasOwnProperty.call(i,d)&&(e=str(d,i),e&&h.push(quote(d)+(gap?": ":":")+e))
e=0===h.length?"{}":gap?"{\n"+gap+h.join(",\n"+gap)+"\n"+g+"}":"{"+h.join(",")+"}",gap=g
return e}}function quote(a){escapable.lastIndex=0
return escapable.test(a)?'"'+a.replace(escapable,function(a){var b=meta[a]
return"string"==typeof b?b:"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)})+'"':'"'+a+'"'}function f(a){return 10>a?"0"+a:a}"function"!=typeof Date.prototype.toJSON&&(Date.prototype.toJSON=function(){return isFinite(this.valueOf())?this.getUTCFullYear()+"-"+f(this.getUTCMonth()+1)+"-"+f(this.getUTCDate())+"T"+f(this.getUTCHours())+":"+f(this.getUTCMinutes())+":"+f(this.getUTCSeconds())+"Z":null},String.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(){return this.valueOf()})
var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={"\b":"\\b","	":"\\t","\n":"\\n","\f":"\\f","\r":"\\r",'"':'\\"',"\\":"\\\\"},rep
"function"!=typeof JSON.stringify&&(JSON.stringify=function(a,b,c){var d
gap="",indent=""
if("number"==typeof c)for(d=0;c>d;d+=1)indent+=" "
else"string"==typeof c&&(indent=c)
rep=b
if(!b||"function"==typeof b||"object"==typeof b&&"number"==typeof b.length)return str("",{"":a})
throw new Error("JSON.stringify")}),"function"!=typeof JSON.parse&&(JSON.parse=function(text,reviver){function walk(a,b){var c,d,e=a[b]
if(e&&"object"==typeof e)for(c in e)Object.prototype.hasOwnProperty.call(e,c)&&(d=walk(e,c),void 0!==d?e[c]=d:delete e[c])
return reviver.call(a,b,e)}var j
text=String(text),cx.lastIndex=0,cx.test(text)&&(text=text.replace(cx,function(a){return"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)}))
if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,"@").replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,"]").replace(/(?:^|:|,)(?:\s*\[)+/g,""))){j=eval("("+text+")")
return"function"==typeof reviver?walk({"":j},""):j}throw new SyntaxError("JSON.parse")})}()
SockJS=function(){var _document=document,_window=window,utils={},REventTarget=function(){}
REventTarget.prototype.addEventListener=function(eventType,listener){this._listeners||(this._listeners={})
eventType in this._listeners||(this._listeners[eventType]=[])
var arr=this._listeners[eventType];-1===utils.arrIndexOf(arr,listener)&&arr.push(listener)}
REventTarget.prototype.removeEventListener=function(eventType,listener){if(this._listeners&&eventType in this._listeners){var arr=this._listeners[eventType],idx=utils.arrIndexOf(arr,listener);-1===idx||(arr.length>1?this._listeners[eventType]=arr.slice(0,idx).concat(arr.slice(idx+1)):delete this._listeners[eventType])}}
REventTarget.prototype.dispatchEvent=function(event){var t=event.type,args=Array.prototype.slice.call(arguments,0)
this["on"+t]&&this["on"+t].apply(this,args)
if(this._listeners&&t in this._listeners)for(var i=0;i<this._listeners[t].length;i++)this._listeners[t][i].apply(this,args)}
var SimpleEvent=function(type,obj){this.type=type
if("undefined"!=typeof obj)for(var k in obj)obj.hasOwnProperty(k)&&(this[k]=obj[k])}
SimpleEvent.prototype.toString=function(){var r=[]
for(var k in this)if(this.hasOwnProperty(k)){var v=this[k]
"function"==typeof v&&(v="[function]")
r.push(k+"="+v)}return"SimpleEvent("+r.join(", ")+")"}
var EventEmitter=function(events){this.events=events||[]}
EventEmitter.prototype.emit=function(type){var that=this,args=Array.prototype.slice.call(arguments,1)
!that.nuked&&that["on"+type]&&that["on"+type].apply(that,args);-1===utils.arrIndexOf(that.events,type)&&utils.log("Event "+JSON.stringify(type)+" not listed "+JSON.stringify(that.events)+" in "+that)}
EventEmitter.prototype.nuke=function(){var that=this
that.nuked=!0
for(var i=0;i<that.events.length;i++)delete that[that.events[i]]}
var random_string_chars="abcdefghijklmnopqrstuvwxyz0123456789_"
utils.random_string=function(length,max){max=max||random_string_chars.length
var i,ret=[]
for(i=0;length>i;i++)ret.push(random_string_chars.substr(Math.floor(Math.random()*max),1))
return ret.join("")}
utils.random_number=function(max){return Math.floor(Math.random()*max)}
utils.random_number_string=function(max){var t=(""+(max-1)).length,p=Array(t+1).join("0")
return(p+utils.random_number(max)).slice(-t)}
utils.getOrigin=function(url){url+="/"
var parts=url.split("/").slice(0,3)
return parts.join("/")}
utils.isSameOriginUrl=function(url_a,url_b){url_b||(url_b=_window.location.href)
return url_a.split("/").slice(0,3).join("/")===url_b.split("/").slice(0,3).join("/")}
utils.getParentDomain=function(url){if(/^[0-9.]*$/.test(url))return url
if(/^\[/.test(url))return url
if(!/[.]/.test(url))return url
var parts=url.split(".").slice(1)
return parts.join(".")}
utils.objectExtend=function(dst,src){for(var k in src)src.hasOwnProperty(k)&&(dst[k]=src[k])
return dst}
var WPrefix="_jp"
utils.polluteGlobalNamespace=function(){WPrefix in _window||(_window[WPrefix]={})}
utils.closeFrame=function(code,reason){return"c"+JSON.stringify([code,reason])}
utils.userSetCode=function(code){return 1e3===code||code>=3e3&&4999>=code}
utils.countRTO=function(rtt){var rto
rto=rtt>100?3*rtt:rtt+200
return rto}
utils.log=function(){_window.console&&console.log&&console.log.apply&&console.log.apply(console,arguments)}
utils.bind=function(fun,that){return fun.bind?fun.bind(that):function(){return fun.apply(that,arguments)}}
utils.flatUrl=function(url){return-1===url.indexOf("?")&&-1===url.indexOf("#")}
utils.amendUrl=function(url){var dl=_document.location
if(!url)throw new Error("Wrong url for SockJS")
if(!utils.flatUrl(url))throw new Error("Only basic urls are supported in SockJS")
0===url.indexOf("//")&&(url=dl.protocol+url)
0===url.indexOf("/")&&(url=dl.protocol+"//"+dl.host+url)
url=url.replace(/[/]+$/,"")
return url}
utils.arrIndexOf=function(arr,obj){for(var i=0;i<arr.length;i++)if(arr[i]===obj)return i
return-1}
utils.arrSkip=function(arr,obj){var idx=utils.arrIndexOf(arr,obj)
if(-1===idx)return arr.slice()
var dst=arr.slice(0,idx)
return dst.concat(arr.slice(idx+1))}
utils.isArray=Array.isArray||function(value){return{}.toString.call(value).indexOf("Array")>=0}
utils.delay=function(t,fun){if("function"==typeof t){fun=t
t=0}return setTimeout(fun,t)}
var extra_lookup,json_escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,json_lookup={"\0":"\\u0000","":"\\u0001","":"\\u0002","":"\\u0003","":"\\u0004","":"\\u0005","":"\\u0006","":"\\u0007","\b":"\\b","	":"\\t","\n":"\\n","":"\\u000b","\f":"\\f","\r":"\\r","":"\\u000e","":"\\u000f","":"\\u0010","":"\\u0011","":"\\u0012","":"\\u0013","":"\\u0014","":"\\u0015","":"\\u0016","":"\\u0017","":"\\u0018","":"\\u0019","":"\\u001a","":"\\u001b","":"\\u001c","":"\\u001d","":"\\u001e","":"\\u001f",'"':'\\"',"\\":"\\\\","":"\\u007f","":"\\u0080","":"\\u0081","":"\\u0082","":"\\u0083","":"\\u0084","":"\\u0085","":"\\u0086","":"\\u0087","":"\\u0088","":"\\u0089","":"\\u008a","":"\\u008b","":"\\u008c","":"\\u008d","":"\\u008e","":"\\u008f","":"\\u0090","":"\\u0091","":"\\u0092","":"\\u0093","":"\\u0094","":"\\u0095","":"\\u0096","":"\\u0097","":"\\u0098","":"\\u0099","":"\\u009a","":"\\u009b","":"\\u009c","":"\\u009d","":"\\u009e","":"\\u009f","­":"\\u00ad","؀":"\\u0600","؁":"\\u0601","؂":"\\u0602","؃":"\\u0603","؄":"\\u0604","܏":"\\u070f","឴":"\\u17b4","឵":"\\u17b5","‌":"\\u200c","‍":"\\u200d","‎":"\\u200e","‏":"\\u200f","\u2028":"\\u2028","\u2029":"\\u2029","‪":"\\u202a","‫":"\\u202b","‬":"\\u202c","‭":"\\u202d","‮":"\\u202e"," ":"\\u202f","⁠":"\\u2060","⁡":"\\u2061","⁢":"\\u2062","⁣":"\\u2063","⁤":"\\u2064","⁥":"\\u2065","⁦":"\\u2066","⁧":"\\u2067","⁨":"\\u2068","⁩":"\\u2069","⁪":"\\u206a","⁫":"\\u206b","⁬":"\\u206c","⁭":"\\u206d","⁮":"\\u206e","⁯":"\\u206f","﻿":"\\ufeff","￰":"\\ufff0","￱":"\\ufff1","￲":"\\ufff2","￳":"\\ufff3","￴":"\\ufff4","￵":"\\ufff5","￶":"\\ufff6","￷":"\\ufff7","￸":"\\ufff8","￹":"\\ufff9","￺":"\\ufffa","￻":"\\ufffb","￼":"\\ufffc","�":"\\ufffd","￾":"\\ufffe","￿":"\\uffff"},extra_escapable=/[\x00-\x1f\ud800-\udfff\ufffe\uffff\u0300-\u0333\u033d-\u0346\u034a-\u034c\u0350-\u0352\u0357-\u0358\u035c-\u0362\u0374\u037e\u0387\u0591-\u05af\u05c4\u0610-\u0617\u0653-\u0654\u0657-\u065b\u065d-\u065e\u06df-\u06e2\u06eb-\u06ec\u0730\u0732-\u0733\u0735-\u0736\u073a\u073d\u073f-\u0741\u0743\u0745\u0747\u07eb-\u07f1\u0951\u0958-\u095f\u09dc-\u09dd\u09df\u0a33\u0a36\u0a59-\u0a5b\u0a5e\u0b5c-\u0b5d\u0e38-\u0e39\u0f43\u0f4d\u0f52\u0f57\u0f5c\u0f69\u0f72-\u0f76\u0f78\u0f80-\u0f83\u0f93\u0f9d\u0fa2\u0fa7\u0fac\u0fb9\u1939-\u193a\u1a17\u1b6b\u1cda-\u1cdb\u1dc0-\u1dcf\u1dfc\u1dfe\u1f71\u1f73\u1f75\u1f77\u1f79\u1f7b\u1f7d\u1fbb\u1fbe\u1fc9\u1fcb\u1fd3\u1fdb\u1fe3\u1feb\u1fee-\u1fef\u1ff9\u1ffb\u1ffd\u2000-\u2001\u20d0-\u20d1\u20d4-\u20d7\u20e7-\u20e9\u2126\u212a-\u212b\u2329-\u232a\u2adc\u302b-\u302c\uaab2-\uaab3\uf900-\ufa0d\ufa10\ufa12\ufa15-\ufa1e\ufa20\ufa22\ufa25-\ufa26\ufa2a-\ufa2d\ufa30-\ufa6d\ufa70-\ufad9\ufb1d\ufb1f\ufb2a-\ufb36\ufb38-\ufb3c\ufb3e\ufb40-\ufb41\ufb43-\ufb44\ufb46-\ufb4e\ufff0-\uffff]/g,JSONQuote=JSON&&JSON.stringify||function(string){json_escapable.lastIndex=0
json_escapable.test(string)&&(string=string.replace(json_escapable,function(a){return json_lookup[a]}))
return'"'+string+'"'},unroll_lookup=function(escapable){var i,unrolled={},c=[]
for(i=0;65536>i;i++)c.push(String.fromCharCode(i))
escapable.lastIndex=0
c.join("").replace(escapable,function(a){unrolled[a]="\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)
return""})
escapable.lastIndex=0
return unrolled}
utils.quote=function(string){var quoted=JSONQuote(string)
extra_escapable.lastIndex=0
if(!extra_escapable.test(quoted))return quoted
extra_lookup||(extra_lookup=unroll_lookup(extra_escapable))
return quoted.replace(extra_escapable,function(a){return extra_lookup[a]})}
var _all_protocols=["websocket","xdr-streaming","xhr-streaming","iframe-eventsource","iframe-htmlfile","xdr-polling","xhr-polling","iframe-xhr-polling","jsonp-polling"]
utils.probeProtocols=function(){for(var probed={},i=0;i<_all_protocols.length;i++){var protocol=_all_protocols[i]
probed[protocol]=SockJS[protocol]&&SockJS[protocol].enabled()}return probed}
utils.detectProtocols=function(probed,protocols_whitelist,info){var pe={},protocols=[]
protocols_whitelist||(protocols_whitelist=_all_protocols)
for(var i=0;i<protocols_whitelist.length;i++){var protocol=protocols_whitelist[i]
pe[protocol]=probed[protocol]}var maybe_push=function(protos){var proto=protos.shift()
pe[proto]?protocols.push(proto):protos.length>0&&maybe_push(protos)}
info.websocket!==!1&&maybe_push(["websocket"])
pe["xhr-streaming"]&&!info.null_origin?protocols.push("xhr-streaming"):!pe["xdr-streaming"]||info.cookie_needed||info.null_origin?maybe_push(["iframe-eventsource","iframe-htmlfile"]):protocols.push("xdr-streaming")
pe["xhr-polling"]&&!info.null_origin?protocols.push("xhr-polling"):!pe["xdr-polling"]||info.cookie_needed||info.null_origin?maybe_push(["iframe-xhr-polling","jsonp-polling"]):protocols.push("xdr-polling")
return protocols}
var MPrefix="_sockjs_global"
utils.createHook=function(){var window_id="a"+utils.random_string(8)
if(!(MPrefix in _window)){var map={}
_window[MPrefix]=function(window_id){window_id in map||(map[window_id]={id:window_id,del:function(){delete map[window_id]}})
return map[window_id]}}return _window[MPrefix](window_id)}
utils.attachMessage=function(listener){utils.attachEvent("message",listener)}
utils.attachEvent=function(event,listener){if("undefined"!=typeof _window.addEventListener)_window.addEventListener(event,listener,!1)
else{_document.attachEvent("on"+event,listener)
_window.attachEvent("on"+event,listener)}}
utils.detachMessage=function(listener){utils.detachEvent("message",listener)}
utils.detachEvent=function(event,listener){if("undefined"!=typeof _window.addEventListener)_window.removeEventListener(event,listener,!1)
else{_document.detachEvent("on"+event,listener)
_window.detachEvent("on"+event,listener)}}
var on_unload={},after_unload=!1,trigger_unload_callbacks=function(){for(var ref in on_unload){on_unload[ref]()
delete on_unload[ref]}},unload_triggered=function(){if(!after_unload){after_unload=!0
trigger_unload_callbacks()}}
utils.attachEvent("unload",unload_triggered)
utils.unload_add=function(listener){var ref=utils.random_string(8)
on_unload[ref]=listener
after_unload&&utils.delay(trigger_unload_callbacks)
return ref}
utils.unload_del=function(ref){ref in on_unload&&delete on_unload[ref]}
utils.createIframe=function(iframe_url,error_callback){var tref,unload_ref,iframe=_document.createElement("iframe"),unattach=function(){clearTimeout(tref)
try{iframe.onload=null}catch(x){}iframe.onerror=null},cleanup=function(){if(iframe){unattach()
setTimeout(function(){iframe&&iframe.parentNode.removeChild(iframe)
iframe=null},0)
utils.unload_del(unload_ref)}},onerror=function(r){if(iframe){cleanup()
error_callback(r)}},post=function(msg,origin){try{iframe&&iframe.contentWindow&&iframe.contentWindow.postMessage(msg,origin)}catch(x){}}
iframe.src=iframe_url
iframe.style.display="none"
iframe.style.position="absolute"
iframe.onerror=function(){onerror("onerror")}
iframe.onload=function(){clearTimeout(tref)
tref=setTimeout(function(){onerror("onload timeout")},2e3)}
_document.body.appendChild(iframe)
tref=setTimeout(function(){onerror("timeout")},15e3)
unload_ref=utils.unload_add(cleanup)
return{post:post,cleanup:cleanup,loaded:unattach}}
utils.createHtmlfile=function(iframe_url,error_callback){var tref,unload_ref,iframe,doc=new ActiveXObject("htmlfile"),unattach=function(){clearTimeout(tref)},cleanup=function(){if(doc){unattach()
utils.unload_del(unload_ref)
iframe.parentNode.removeChild(iframe)
iframe=doc=null
CollectGarbage()}},onerror=function(r){if(doc){cleanup()
error_callback(r)}},post=function(msg,origin){try{iframe&&iframe.contentWindow&&iframe.contentWindow.postMessage(msg,origin)}catch(x){}}
doc.open()
doc.write('<html><script>document.domain="'+document.domain+'";'+"</s"+"cript></html>")
doc.close()
doc.parentWindow[WPrefix]=_window[WPrefix]
var c=doc.createElement("div")
doc.body.appendChild(c)
iframe=doc.createElement("iframe")
c.appendChild(iframe)
iframe.src=iframe_url
tref=setTimeout(function(){onerror("timeout")},15e3)
unload_ref=utils.unload_add(cleanup)
return{post:post,cleanup:cleanup,loaded:unattach}}
var AbstractXHRObject=function(){}
AbstractXHRObject.prototype=new EventEmitter(["chunk","finish"])
AbstractXHRObject.prototype._start=function(method,url,payload,opts){var that=this
try{that.xhr=new XMLHttpRequest}catch(x){}if(!that.xhr)try{that.xhr=new _window.ActiveXObject("Microsoft.XMLHTTP")}catch(x){}(_window.ActiveXObject||_window.XDomainRequest)&&(url+=(-1===url.indexOf("?")?"?":"&")+"t="+ +new Date)
that.unload_ref=utils.unload_add(function(){that._cleanup(!0)})
try{that.xhr.open(method,url,!0)}catch(e){that.emit("finish",0,"")
that._cleanup()
return}opts&&opts.no_credentials||(that.xhr.withCredentials="true")
if(opts&&opts.headers)for(var key in opts.headers)that.xhr.setRequestHeader(key,opts.headers[key])
that.xhr.onreadystatechange=function(){if(that.xhr){var x=that.xhr
switch(x.readyState){case 3:try{var status=x.status,text=x.responseText}catch(x){}text&&text.length>0&&that.emit("chunk",status,text)
break
case 4:that.emit("finish",x.status,x.responseText)
that._cleanup(!1)}}}
that.xhr.send(payload)}
AbstractXHRObject.prototype._cleanup=function(abort){var that=this
if(that.xhr){utils.unload_del(that.unload_ref)
that.xhr.onreadystatechange=function(){}
if(abort)try{that.xhr.abort()}catch(x){}that.unload_ref=that.xhr=null}}
AbstractXHRObject.prototype.close=function(){var that=this
that.nuke()
that._cleanup(!0)}
var XHRCorsObject=utils.XHRCorsObject=function(){var that=this,args=arguments
utils.delay(function(){that._start.apply(that,args)})}
XHRCorsObject.prototype=new AbstractXHRObject
var XHRLocalObject=utils.XHRLocalObject=function(method,url,payload){var that=this
utils.delay(function(){that._start(method,url,payload,{no_credentials:!0})})}
XHRLocalObject.prototype=new AbstractXHRObject
var XDRObject=utils.XDRObject=function(method,url,payload){var that=this
utils.delay(function(){that._start(method,url,payload)})}
XDRObject.prototype=new EventEmitter(["chunk","finish"])
XDRObject.prototype._start=function(method,url,payload){var that=this,xdr=new XDomainRequest
url+=(-1===url.indexOf("?")?"?":"&")+"t="+ +new Date
var onerror=xdr.ontimeout=xdr.onerror=function(){that.emit("finish",0,"")
that._cleanup(!1)}
xdr.onprogress=function(){that.emit("chunk",200,xdr.responseText)}
xdr.onload=function(){that.emit("finish",200,xdr.responseText)
that._cleanup(!1)}
that.xdr=xdr
that.unload_ref=utils.unload_add(function(){that._cleanup(!0)})
try{that.xdr.open(method,url)
that.xdr.send(payload)}catch(x){onerror()}}
XDRObject.prototype._cleanup=function(abort){var that=this
if(that.xdr){utils.unload_del(that.unload_ref)
that.xdr.ontimeout=that.xdr.onerror=that.xdr.onprogress=that.xdr.onload=null
if(abort)try{that.xdr.abort()}catch(x){}that.unload_ref=that.xdr=null}}
XDRObject.prototype.close=function(){var that=this
that.nuke()
that._cleanup(!0)}
utils.isXHRCorsCapable=function(){return _window.XMLHttpRequest&&"withCredentials"in new XMLHttpRequest?1:_window.XDomainRequest&&_document.domain?2:IframeTransport.enabled()?3:4}
var SockJS=function(url,dep_protocols_whitelist,options){var protocols_whitelist,that=this
that._options={devel:!1,debug:!1,protocols_whitelist:[],info:void 0,rtt:void 0}
options&&utils.objectExtend(that._options,options)
that._base_url=utils.amendUrl(url)
that._server=that._options.server||utils.random_number_string(1e3)
if(that._options.protocols_whitelist&&that._options.protocols_whitelist.length)protocols_whitelist=that._options.protocols_whitelist
else{protocols_whitelist="string"==typeof dep_protocols_whitelist&&dep_protocols_whitelist.length>0?[dep_protocols_whitelist]:utils.isArray(dep_protocols_whitelist)?dep_protocols_whitelist:null
protocols_whitelist&&that._debug('Deprecated API: Use "protocols_whitelist" option instead of supplying protocol list as a second parameter to SockJS constructor.')}that._protocols=[]
that.protocol=null
that.readyState=SockJS.CONNECTING
that._ir=createInfoReceiver(that._base_url)
that._ir.onfinish=function(info,rtt){that._ir=null
if(info){that._options.info&&(info=utils.objectExtend(info,that._options.info))
that._options.rtt&&(rtt=that._options.rtt)
that._applyInfo(info,rtt,protocols_whitelist)
that._didClose()}else that._didClose(1002,"Can't connect to server",!0)}}
SockJS.prototype=new REventTarget
SockJS.version="0.3.2"
SockJS.CONNECTING=0
SockJS.OPEN=1
SockJS.CLOSING=2
SockJS.CLOSED=3
SockJS.prototype._debug=function(){this._options.debug&&utils.log.apply(utils,arguments)}
SockJS.prototype._dispatchOpen=function(){var that=this
if(that.readyState===SockJS.CONNECTING){if(that._transport_tref){clearTimeout(that._transport_tref)
that._transport_tref=null}that.readyState=SockJS.OPEN
that.dispatchEvent(new SimpleEvent("open"))}else that._didClose(1006,"Server lost session")}
SockJS.prototype._dispatchMessage=function(data){var that=this
that.readyState===SockJS.OPEN&&that.dispatchEvent(new SimpleEvent("message",{data:data}))}
SockJS.prototype._dispatchHeartbeat=function(){var that=this
that.readyState===SockJS.OPEN&&that.dispatchEvent(new SimpleEvent("heartbeat",{}))}
SockJS.prototype._didClose=function(code,reason,force){var that=this
if(that.readyState!==SockJS.CONNECTING&&that.readyState!==SockJS.OPEN&&that.readyState!==SockJS.CLOSING)throw new Error("INVALID_STATE_ERR")
if(that._ir){that._ir.nuke()
that._ir=null}if(that._transport){that._transport.doCleanup()
that._transport=null}var close_event=new SimpleEvent("close",{code:code,reason:reason,wasClean:utils.userSetCode(code)})
if(!utils.userSetCode(code)&&that.readyState===SockJS.CONNECTING&&!force){if(that._try_next_protocol(close_event))return
close_event=new SimpleEvent("close",{code:2e3,reason:"All transports failed",wasClean:!1,last_event:close_event})}that.readyState=SockJS.CLOSED
utils.delay(function(){that.dispatchEvent(close_event)})}
SockJS.prototype._didMessage=function(data){var that=this,type=data.slice(0,1)
switch(type){case"o":that._dispatchOpen()
break
case"a":for(var payload=JSON.parse(data.slice(1)||"[]"),i=0;i<payload.length;i++)that._dispatchMessage(payload[i])
break
case"m":var payload=JSON.parse(data.slice(1)||"null")
that._dispatchMessage(payload)
break
case"c":var payload=JSON.parse(data.slice(1)||"[]")
that._didClose(payload[0],payload[1])
break
case"h":that._dispatchHeartbeat()}}
SockJS.prototype._try_next_protocol=function(close_event){var that=this
if(that.protocol){that._debug("Closed transport:",that.protocol,""+close_event)
that.protocol=null}if(that._transport_tref){clearTimeout(that._transport_tref)
that._transport_tref=null}for(;;){var protocol=that.protocol=that._protocols.shift()
if(!protocol)return!1
if(SockJS[protocol]&&SockJS[protocol].need_body===!0&&(!_document.body||"undefined"!=typeof _document.readyState&&"complete"!==_document.readyState)){that._protocols.unshift(protocol)
that.protocol="waiting-for-load"
utils.attachEvent("load",function(){that._try_next_protocol()})
return!0}if(SockJS[protocol]&&SockJS[protocol].enabled(that._options)){var roundTrips=SockJS[protocol].roundTrips||1,to=(that._options.rto||0)*roundTrips||5e3
that._transport_tref=utils.delay(to,function(){that.readyState===SockJS.CONNECTING&&that._didClose(2007,"Transport timeouted")})
var connid=utils.random_string(8),trans_url=that._base_url+"/"+that._server+"/"+connid
that._debug("Opening transport:",protocol," url:"+trans_url," RTO:"+that._options.rto)
that._transport=new SockJS[protocol](that,trans_url,that._base_url)
return!0}that._debug("Skipping transport:",protocol)}}
SockJS.prototype.close=function(code,reason){var that=this
if(code&&!utils.userSetCode(code))throw new Error("INVALID_ACCESS_ERR")
if(that.readyState!==SockJS.CONNECTING&&that.readyState!==SockJS.OPEN)return!1
that.readyState=SockJS.CLOSING
that._didClose(code||1e3,reason||"Normal closure")
return!0}
SockJS.prototype.send=function(data){var that=this
if(that.readyState===SockJS.CONNECTING)throw new Error("INVALID_STATE_ERR")
that.readyState===SockJS.OPEN&&that._transport.doSend(utils.quote(""+data))
return!0}
SockJS.prototype._applyInfo=function(info,rtt,protocols_whitelist){var that=this
that._options.info=info
that._options.rtt=rtt
that._options.rto=utils.countRTO(rtt)
that._options.info.null_origin=!_document.domain
var probed=utils.probeProtocols()
that._protocols=utils.detectProtocols(probed,protocols_whitelist,info)}
var WebSocketTransport=SockJS.websocket=function(ri,trans_url){var that=this,url=trans_url+"/websocket"
url="https"===url.slice(0,5)?"wss"+url.slice(5):"ws"+url.slice(4)
that.ri=ri
that.url=url
var Constructor=_window.WebSocket||_window.MozWebSocket
that.ws=new Constructor(that.url)
that.ws.onmessage=function(e){that.ri._didMessage(e.data)}
that.unload_ref=utils.unload_add(function(){that.ws.close()})
that.ws.onclose=function(){that.ri._didMessage(utils.closeFrame(1006,"WebSocket connection broken"))}}
WebSocketTransport.prototype.doSend=function(data){this.ws.send("["+data+"]")}
WebSocketTransport.prototype.doCleanup=function(){var that=this,ws=that.ws
if(ws){ws.onmessage=ws.onclose=null
ws.close()
utils.unload_del(that.unload_ref)
that.unload_ref=that.ri=that.ws=null}}
WebSocketTransport.enabled=function(){return!(!_window.WebSocket&&!_window.MozWebSocket)}
WebSocketTransport.roundTrips=2
var BufferedSender=function(){}
BufferedSender.prototype.send_constructor=function(sender){var that=this
that.send_buffer=[]
that.sender=sender}
BufferedSender.prototype.doSend=function(message){var that=this
that.send_buffer.push(message)
that.send_stop||that.send_schedule()}
BufferedSender.prototype.send_schedule_wait=function(){var tref,that=this
that.send_stop=function(){that.send_stop=null
clearTimeout(tref)}
tref=utils.delay(25,function(){that.send_stop=null
that.send_schedule()})}
BufferedSender.prototype.send_schedule=function(){var that=this
if(that.send_buffer.length>0){var payload="["+that.send_buffer.join(",")+"]"
that.send_stop=that.sender(that.trans_url,payload,function(){that.send_stop=null
that.send_schedule_wait()})
that.send_buffer=[]}}
BufferedSender.prototype.send_destructor=function(){var that=this
that._send_stop&&that._send_stop()
that._send_stop=null}
var jsonPGenericSender=function(url,payload,callback){var that=this
if(!("_send_form"in that)){var form=that._send_form=_document.createElement("form"),area=that._send_area=_document.createElement("textarea")
area.name="d"
form.style.display="none"
form.style.position="absolute"
form.method="POST"
form.enctype="application/x-www-form-urlencoded"
form.acceptCharset="UTF-8"
form.appendChild(area)
_document.body.appendChild(form)}var form=that._send_form,area=that._send_area,id="a"+utils.random_string(8)
form.target=id
form.action=url+"/jsonp_send?i="+id
var iframe
try{iframe=_document.createElement('<iframe name="'+id+'">')}catch(x){iframe=_document.createElement("iframe")
iframe.name=id}iframe.id=id
form.appendChild(iframe)
iframe.style.display="none"
try{area.value=payload}catch(e){utils.log("Your browser is seriously broken. Go home! "+e.message)}form.submit()
var completed=function(){if(iframe.onerror){iframe.onreadystatechange=iframe.onerror=iframe.onload=null
utils.delay(500,function(){iframe.parentNode.removeChild(iframe)
iframe=null})
area.value=""
callback()}}
iframe.onerror=iframe.onload=completed
iframe.onreadystatechange=function(){"complete"==iframe.readyState&&completed()}
return completed},createAjaxSender=function(AjaxObject){return function(url,payload,callback){var xo=new AjaxObject("POST",url+"/xhr_send",payload)
xo.onfinish=function(status){callback(status)}
return function(abort_reason){callback(0,abort_reason)}}},jsonPGenericReceiver=function(url,callback){var tref,script2,script=_document.createElement("script"),close_script=function(frame){if(script2){script2.parentNode.removeChild(script2)
script2=null}if(script){clearTimeout(tref)
script.parentNode.removeChild(script)
script.onreadystatechange=script.onerror=script.onload=script.onclick=null
script=null
callback(frame)
callback=null}},loaded_okay=!1,error_timer=null
script.id="a"+utils.random_string(8)
script.src=url
script.type="text/javascript"
script.charset="UTF-8"
script.onerror=function(){error_timer||(error_timer=setTimeout(function(){loaded_okay||close_script(utils.closeFrame(1006,"JSONP script loaded abnormally (onerror)"))},1e3))}
script.onload=function(){close_script(utils.closeFrame(1006,"JSONP script loaded abnormally (onload)"))}
script.onreadystatechange=function(){if(/loaded|closed/.test(script.readyState)){if(script&&script.htmlFor&&script.onclick){loaded_okay=!0
try{script.onclick()}catch(x){}}script&&close_script(utils.closeFrame(1006,"JSONP script loaded abnormally (onreadystatechange)"))}}
if("undefined"==typeof script.async&&_document.attachEvent)if(/opera/i.test(navigator.userAgent)){script2=_document.createElement("script")
script2.text="try{var a = document.getElementById('"+script.id+"'); if(a)a.onerror();}catch(x){};"
script.async=script2.async=!1}else{try{script.htmlFor=script.id
script.event="onclick"}catch(x){}script.async=!0}"undefined"!=typeof script.async&&(script.async=!0)
tref=setTimeout(function(){close_script(utils.closeFrame(1006,"JSONP script loaded abnormally (timeout)"))},35e3)
var head=_document.getElementsByTagName("head")[0]
head.insertBefore(script,head.firstChild)
script2&&head.insertBefore(script2,head.firstChild)
return close_script},JsonPTransport=SockJS["jsonp-polling"]=function(ri,trans_url){utils.polluteGlobalNamespace()
var that=this
that.ri=ri
that.trans_url=trans_url
that.send_constructor(jsonPGenericSender)
that._schedule_recv()}
JsonPTransport.prototype=new BufferedSender
JsonPTransport.prototype._schedule_recv=function(){var that=this,callback=function(data){that._recv_stop=null
data&&(that._is_closing||that.ri._didMessage(data))
that._is_closing||that._schedule_recv()}
that._recv_stop=jsonPReceiverWrapper(that.trans_url+"/jsonp",jsonPGenericReceiver,callback)}
JsonPTransport.enabled=function(){return!0}
JsonPTransport.need_body=!0
JsonPTransport.prototype.doCleanup=function(){var that=this
that._is_closing=!0
that._recv_stop&&that._recv_stop()
that.ri=that._recv_stop=null
that.send_destructor()}
var jsonPReceiverWrapper=function(url,constructReceiver,user_callback){var id="a"+utils.random_string(6),url_id=url+"?c="+escape(WPrefix+"."+id),callback=function(frame){delete _window[WPrefix][id]
user_callback(frame)},close_script=constructReceiver(url_id,callback)
_window[WPrefix][id]=close_script
var stop=function(){_window[WPrefix][id]&&_window[WPrefix][id](utils.closeFrame(1e3,"JSONP user aborted read"))}
return stop},AjaxBasedTransport=function(){}
AjaxBasedTransport.prototype=new BufferedSender
AjaxBasedTransport.prototype.run=function(ri,trans_url,url_suffix,Receiver,AjaxObject){var that=this
that.ri=ri
that.trans_url=trans_url
that.send_constructor(createAjaxSender(AjaxObject))
that.poll=new Polling(ri,Receiver,trans_url+url_suffix,AjaxObject)}
AjaxBasedTransport.prototype.doCleanup=function(){var that=this
if(that.poll){that.poll.abort()
that.poll=null}}
var XhrStreamingTransport=SockJS["xhr-streaming"]=function(ri,trans_url){this.run(ri,trans_url,"/xhr_streaming",XhrReceiver,utils.XHRCorsObject)}
XhrStreamingTransport.prototype=new AjaxBasedTransport
XhrStreamingTransport.enabled=function(){return _window.XMLHttpRequest&&"withCredentials"in new XMLHttpRequest&&!/opera/i.test(navigator.userAgent)}
XhrStreamingTransport.roundTrips=2
XhrStreamingTransport.need_body=!0
var XdrStreamingTransport=SockJS["xdr-streaming"]=function(ri,trans_url){this.run(ri,trans_url,"/xhr_streaming",XhrReceiver,utils.XDRObject)}
XdrStreamingTransport.prototype=new AjaxBasedTransport
XdrStreamingTransport.enabled=function(){return!!_window.XDomainRequest}
XdrStreamingTransport.roundTrips=2
var XhrPollingTransport=SockJS["xhr-polling"]=function(ri,trans_url){this.run(ri,trans_url,"/xhr",XhrReceiver,utils.XHRCorsObject)}
XhrPollingTransport.prototype=new AjaxBasedTransport
XhrPollingTransport.enabled=XhrStreamingTransport.enabled
XhrPollingTransport.roundTrips=2
var XdrPollingTransport=SockJS["xdr-polling"]=function(ri,trans_url){this.run(ri,trans_url,"/xhr",XhrReceiver,utils.XDRObject)}
XdrPollingTransport.prototype=new AjaxBasedTransport
XdrPollingTransport.enabled=XdrStreamingTransport.enabled
XdrPollingTransport.roundTrips=2
var IframeTransport=function(){}
IframeTransport.prototype.i_constructor=function(ri,trans_url,base_url){var that=this
that.ri=ri
that.origin=utils.getOrigin(base_url)
that.base_url=base_url
that.trans_url=trans_url
var iframe_url=base_url+"/iframe.html"
that.ri._options.devel&&(iframe_url+="?t="+ +new Date)
that.window_id=utils.random_string(8)
iframe_url+="#"+that.window_id
that.iframeObj=utils.createIframe(iframe_url,function(r){that.ri._didClose(1006,"Unable to load an iframe ("+r+")")})
that.onmessage_cb=utils.bind(that.onmessage,that)
utils.attachMessage(that.onmessage_cb)}
IframeTransport.prototype.doCleanup=function(){var that=this
if(that.iframeObj){utils.detachMessage(that.onmessage_cb)
try{that.iframeObj.iframe.contentWindow&&that.postMessage("c")}catch(x){}that.iframeObj.cleanup()
that.iframeObj=null
that.onmessage_cb=that.iframeObj=null}}
IframeTransport.prototype.onmessage=function(e){var that=this
if(e.origin===that.origin){var window_id=e.data.slice(0,8),type=e.data.slice(8,9),data=e.data.slice(9)
if(window_id===that.window_id)switch(type){case"s":that.iframeObj.loaded()
that.postMessage("s",JSON.stringify([SockJS.version,that.protocol,that.trans_url,that.base_url]))
break
case"t":that.ri._didMessage(data)}}}
IframeTransport.prototype.postMessage=function(type,data){var that=this
that.iframeObj.post(that.window_id+type+(data||""),that.origin)}
IframeTransport.prototype.doSend=function(message){this.postMessage("m",message)}
IframeTransport.enabled=function(){var konqueror=navigator&&navigator.userAgent&&-1!==navigator.userAgent.indexOf("Konqueror")
return("function"==typeof _window.postMessage||"object"==typeof _window.postMessage)&&!konqueror}
var curr_window_id,postMessage=function(type,data){parent!==_window?parent.postMessage(curr_window_id+type+(data||""),"*"):utils.log("Can't postMessage, no parent window.",type,data)},FacadeJS=function(){}
FacadeJS.prototype._didClose=function(code,reason){postMessage("t",utils.closeFrame(code,reason))}
FacadeJS.prototype._didMessage=function(frame){postMessage("t",frame)}
FacadeJS.prototype._doSend=function(data){this._transport.doSend(data)}
FacadeJS.prototype._doCleanup=function(){this._transport.doCleanup()}
utils.parent_origin=void 0
SockJS.bootstrap_iframe=function(){var facade
curr_window_id=_document.location.hash.slice(1)
var onMessage=function(e){if(e.source===parent){"undefined"==typeof utils.parent_origin&&(utils.parent_origin=e.origin)
if(e.origin===utils.parent_origin){var window_id=e.data.slice(0,8),type=e.data.slice(8,9),data=e.data.slice(9)
if(window_id===curr_window_id)switch(type){case"s":var p=JSON.parse(data),version=p[0],protocol=p[1],trans_url=p[2],base_url=p[3]
version!==SockJS.version&&utils.log('Incompatibile SockJS! Main site uses: "'+version+'", the iframe:'+' "'+SockJS.version+'".')
if(!utils.flatUrl(trans_url)||!utils.flatUrl(base_url)){utils.log("Only basic urls are supported in SockJS")
return}if(!utils.isSameOriginUrl(trans_url)||!utils.isSameOriginUrl(base_url)){utils.log("Can't connect to different domain from within an iframe. ("+JSON.stringify([_window.location.href,trans_url,base_url])+")")
return}facade=new FacadeJS
facade._transport=new FacadeJS[protocol](facade,trans_url,base_url)
break
case"m":facade._doSend(data)
break
case"c":facade&&facade._doCleanup()
facade=null}}}}
utils.attachMessage(onMessage)
postMessage("s")}
var InfoReceiver=function(base_url,AjaxObject){var that=this
utils.delay(function(){that.doXhr(base_url,AjaxObject)})}
InfoReceiver.prototype=new EventEmitter(["finish"])
InfoReceiver.prototype.doXhr=function(base_url,AjaxObject){var that=this,t0=(new Date).getTime(),xo=new AjaxObject("GET",base_url+"/info"),tref=utils.delay(8e3,function(){xo.ontimeout()})
xo.onfinish=function(status,text){clearTimeout(tref)
tref=null
if(200===status){var rtt=(new Date).getTime()-t0,info=JSON.parse(text)
"object"!=typeof info&&(info={})
that.emit("finish",info,rtt)}else that.emit("finish")}
xo.ontimeout=function(){xo.close()
that.emit("finish")}}
var InfoReceiverIframe=function(base_url){var that=this,go=function(){var ifr=new IframeTransport
ifr.protocol="w-iframe-info-receiver"
var fun=function(r){if("string"==typeof r&&"m"===r.substr(0,1)){var d=JSON.parse(r.substr(1)),info=d[0],rtt=d[1]
that.emit("finish",info,rtt)}else that.emit("finish")
ifr.doCleanup()
ifr=null},mock_ri={_options:{},_didClose:fun,_didMessage:fun}
ifr.i_constructor(mock_ri,base_url,base_url)}
_document.body?go():utils.attachEvent("load",go)}
InfoReceiverIframe.prototype=new EventEmitter(["finish"])
var InfoReceiverFake=function(){var that=this
utils.delay(function(){that.emit("finish",{},2e3)})}
InfoReceiverFake.prototype=new EventEmitter(["finish"])
var createInfoReceiver=function(base_url){if(utils.isSameOriginUrl(base_url))return new InfoReceiver(base_url,utils.XHRLocalObject)
switch(utils.isXHRCorsCapable()){case 1:return new InfoReceiver(base_url,utils.XHRLocalObject)
case 2:return new InfoReceiver(base_url,utils.XDRObject)
case 3:return new InfoReceiverIframe(base_url)
default:return new InfoReceiverFake}},WInfoReceiverIframe=FacadeJS["w-iframe-info-receiver"]=function(ri,_trans_url,base_url){var ir=new InfoReceiver(base_url,utils.XHRLocalObject)
ir.onfinish=function(info,rtt){ri._didMessage("m"+JSON.stringify([info,rtt]))
ri._didClose()}}
WInfoReceiverIframe.prototype.doCleanup=function(){}
var EventSourceIframeTransport=SockJS["iframe-eventsource"]=function(){var that=this
that.protocol="w-iframe-eventsource"
that.i_constructor.apply(that,arguments)}
EventSourceIframeTransport.prototype=new IframeTransport
EventSourceIframeTransport.enabled=function(){return"EventSource"in _window&&IframeTransport.enabled()}
EventSourceIframeTransport.need_body=!0
EventSourceIframeTransport.roundTrips=3
var EventSourceTransport=FacadeJS["w-iframe-eventsource"]=function(ri,trans_url){this.run(ri,trans_url,"/eventsource",EventSourceReceiver,utils.XHRLocalObject)}
EventSourceTransport.prototype=new AjaxBasedTransport
var XhrPollingIframeTransport=SockJS["iframe-xhr-polling"]=function(){var that=this
that.protocol="w-iframe-xhr-polling"
that.i_constructor.apply(that,arguments)}
XhrPollingIframeTransport.prototype=new IframeTransport
XhrPollingIframeTransport.enabled=function(){return _window.XMLHttpRequest&&IframeTransport.enabled()}
XhrPollingIframeTransport.need_body=!0
XhrPollingIframeTransport.roundTrips=3
var XhrPollingITransport=FacadeJS["w-iframe-xhr-polling"]=function(ri,trans_url){this.run(ri,trans_url,"/xhr",XhrReceiver,utils.XHRLocalObject)}
XhrPollingITransport.prototype=new AjaxBasedTransport
var HtmlFileIframeTransport=SockJS["iframe-htmlfile"]=function(){var that=this
that.protocol="w-iframe-htmlfile"
that.i_constructor.apply(that,arguments)}
HtmlFileIframeTransport.prototype=new IframeTransport
HtmlFileIframeTransport.enabled=function(){return IframeTransport.enabled()}
HtmlFileIframeTransport.need_body=!0
HtmlFileIframeTransport.roundTrips=3
var HtmlFileTransport=FacadeJS["w-iframe-htmlfile"]=function(ri,trans_url){this.run(ri,trans_url,"/htmlfile",HtmlfileReceiver,utils.XHRLocalObject)}
HtmlFileTransport.prototype=new AjaxBasedTransport
var Polling=function(ri,Receiver,recv_url,AjaxObject){var that=this
that.ri=ri
that.Receiver=Receiver
that.recv_url=recv_url
that.AjaxObject=AjaxObject
that._scheduleRecv()}
Polling.prototype._scheduleRecv=function(){var that=this,poll=that.poll=new that.Receiver(that.recv_url,that.AjaxObject),msg_counter=0
poll.onmessage=function(e){msg_counter+=1
that.ri._didMessage(e.data)}
poll.onclose=function(e){that.poll=poll=poll.onmessage=poll.onclose=null
that.poll_is_closing||("permanent"===e.reason?that.ri._didClose(1006,"Polling error ("+e.reason+")"):that._scheduleRecv())}}
Polling.prototype.abort=function(){var that=this
that.poll_is_closing=!0
that.poll&&that.poll.abort()}
var EventSourceReceiver=function(url){var that=this,es=new EventSource(url)
es.onmessage=function(e){that.dispatchEvent(new SimpleEvent("message",{data:unescape(e.data)}))}
that.es_close=es.onerror=function(e,abort_reason){var reason=abort_reason?"user":2!==es.readyState?"network":"permanent"
that.es_close=es.onmessage=es.onerror=null
es.close()
es=null
utils.delay(200,function(){that.dispatchEvent(new SimpleEvent("close",{reason:reason}))})}}
EventSourceReceiver.prototype=new REventTarget
EventSourceReceiver.prototype.abort=function(){var that=this
that.es_close&&that.es_close({},!0)}
var _is_ie_htmlfile_capable,isIeHtmlfileCapable=function(){if(void 0===_is_ie_htmlfile_capable)if("ActiveXObject"in _window)try{_is_ie_htmlfile_capable=!!new ActiveXObject("htmlfile")}catch(x){}else _is_ie_htmlfile_capable=!1
return _is_ie_htmlfile_capable},HtmlfileReceiver=function(url){var that=this
utils.polluteGlobalNamespace()
that.id="a"+utils.random_string(6,26)
url+=(-1===url.indexOf("?")?"?":"&")+"c="+escape(WPrefix+"."+that.id)
var iframeObj,constructor=isIeHtmlfileCapable()?utils.createHtmlfile:utils.createIframe
_window[WPrefix][that.id]={start:function(){iframeObj.loaded()},message:function(data){that.dispatchEvent(new SimpleEvent("message",{data:data}))},stop:function(){that.iframe_close({},"network")}}
that.iframe_close=function(e,abort_reason){iframeObj.cleanup()
that.iframe_close=iframeObj=null
delete _window[WPrefix][that.id]
that.dispatchEvent(new SimpleEvent("close",{reason:abort_reason}))}
iframeObj=constructor(url,function(){that.iframe_close({},"permanent")})}
HtmlfileReceiver.prototype=new REventTarget
HtmlfileReceiver.prototype.abort=function(){var that=this
that.iframe_close&&that.iframe_close({},"user")}
var XhrReceiver=function(url,AjaxObject){var that=this,buf_pos=0
that.xo=new AjaxObject("POST",url,null)
that.xo.onchunk=function(status,text){if(200===status)for(;;){var buf=text.slice(buf_pos),p=buf.indexOf("\n")
if(-1===p)break
buf_pos+=p+1
var msg=buf.slice(0,p)
that.dispatchEvent(new SimpleEvent("message",{data:msg}))}}
that.xo.onfinish=function(status,text){that.xo.onchunk(status,text)
that.xo=null
var reason=200===status?"network":"permanent"
that.dispatchEvent(new SimpleEvent("close",{reason:reason}))}}
XhrReceiver.prototype=new REventTarget
XhrReceiver.prototype.abort=function(){var that=this
if(that.xo){that.xo.close()
that.dispatchEvent(new SimpleEvent("close",{reason:"user"}))
that.xo=null}}
SockJS.getUtils=function(){return utils}
SockJS.getIframeTransport=function(){return IframeTransport}
return SockJS}()
"_sockjs_onload"in window&&setTimeout(_sockjs_onload,1)
"function"==typeof define&&define.amd&&define("sockjs",[],function(){return SockJS})

!function(){var require=function(file,cwd){var resolved=require.resolve(file,cwd||"/"),mod=require.modules[resolved]
if(!mod)throw new Error("Failed to resolve module "+file+", tried "+resolved)
var cached=require.cache[resolved],res=cached?cached.exports:mod()
return res}
require.paths=[]
require.modules={}
require.cache={}
require.extensions=[".js",".coffee",".json"]
require._core={assert:!0,events:!0,fs:!0,path:!0,vm:!0}
require.resolve=function(){return function(x,cwd){function loadAsFileSync(x){x=path.normalize(x)
if(require.modules[x])return x
for(var i=0;i<require.extensions.length;i++){var ext=require.extensions[i]
if(require.modules[x+ext])return x+ext}}function loadAsDirectorySync(x){x=x.replace(/\/+$/,"")
var pkgfile=path.normalize(x+"/package.json")
if(require.modules[pkgfile]){var pkg=require.modules[pkgfile](),b=pkg.browserify
if("object"==typeof b&&b.main){var m=loadAsFileSync(path.resolve(x,b.main))
if(m)return m}else if("string"==typeof b){var m=loadAsFileSync(path.resolve(x,b))
if(m)return m}else if(pkg.main){var m=loadAsFileSync(path.resolve(x,pkg.main))
if(m)return m}}return loadAsFileSync(x+"/index")}function loadNodeModulesSync(x,start){for(var dirs=nodeModulesPathsSync(start),i=0;i<dirs.length;i++){var dir=dirs[i],m=loadAsFileSync(dir+"/"+x)
if(m)return m
var n=loadAsDirectorySync(dir+"/"+x)
if(n)return n}var m=loadAsFileSync(x)
return m?m:void 0}function nodeModulesPathsSync(start){var parts
parts="/"===start?[""]:path.normalize(start).split("/")
for(var dirs=[],i=parts.length-1;i>=0;i--)if("node_modules"!==parts[i]){var dir=parts.slice(0,i+1).join("/")+"/node_modules"
dirs.push(dir)}return dirs}cwd||(cwd="/")
if(require._core[x])return x
var path=require.modules.path()
cwd=path.resolve("/",cwd)
var y=cwd||"/"
if(x.match(/^(?:\.\.?\/|\/)/)){var m=loadAsFileSync(path.resolve(y,x))||loadAsDirectorySync(path.resolve(y,x))
if(m)return m}var n=loadNodeModulesSync(x,y)
if(n)return n
throw new Error("Cannot find module '"+x+"'")}}()
require.alias=function(from,to){var path=require.modules.path(),res=null
try{res=require.resolve(from+"/package.json","/")}catch(err){res=require.resolve(from,"/")}for(var basedir=path.dirname(res),keys=(Object.keys||function(obj){var res=[]
for(var key in obj)res.push(key)
return res})(require.modules),i=0;i<keys.length;i++){var key=keys[i]
if(key.slice(0,basedir.length+1)===basedir+"/"){var f=key.slice(basedir.length)
require.modules[to+f]=require.modules[basedir+f]}else key===basedir&&(require.modules[to]=require.modules[basedir])}}
!function(){var process={},global="undefined"!=typeof window?window:{},definedProcess=!1
require.define=function(filename,fn){if(!definedProcess&&require.modules.__browserify_process){process=require.modules.__browserify_process()
definedProcess=!0}var dirname=require._core[filename]?"":require.modules.path().dirname(filename),require_=function(file){var requiredModule=require(file,dirname),cached=require.cache[require.resolve(file,dirname)]
cached&&null===cached.parent&&(cached.parent=module_)
return requiredModule}
require_.resolve=function(name){return require.resolve(name,dirname)}
require_.modules=require.modules
require_.define=require.define
require_.cache=require.cache
var module_={id:filename,filename:filename,exports:{},loaded:!1,parent:null}
require.modules[filename]=function(){require.cache[filename]=module_
fn.call(module_.exports,require_,module_,module_.exports,dirname,filename,process,global)
module_.loaded=!0
return module_.exports}}}()
require.define("path",function(require,module,exports,__dirname,__filename,process){function filter(xs,fn){for(var res=[],i=0;i<xs.length;i++)fn(xs[i],i,xs)&&res.push(xs[i])
return res}function normalizeArray(parts,allowAboveRoot){for(var up=0,i=parts.length;i>=0;i--){var last=parts[i]
if("."==last)parts.splice(i,1)
else if(".."===last){parts.splice(i,1)
up++}else if(up){parts.splice(i,1)
up--}}if(allowAboveRoot)for(;up--;up)parts.unshift("..")
return parts}var splitPathRe=/^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/
exports.resolve=function(){for(var resolvedPath="",resolvedAbsolute=!1,i=arguments.length;i>=-1&&!resolvedAbsolute;i--){var path=i>=0?arguments[i]:process.cwd()
if("string"==typeof path&&path){resolvedPath=path+"/"+resolvedPath
resolvedAbsolute="/"===path.charAt(0)}}resolvedPath=normalizeArray(filter(resolvedPath.split("/"),function(p){return!!p}),!resolvedAbsolute).join("/")
return(resolvedAbsolute?"/":"")+resolvedPath||"."}
exports.normalize=function(path){var isAbsolute="/"===path.charAt(0),trailingSlash="/"===path.slice(-1)
path=normalizeArray(filter(path.split("/"),function(p){return!!p}),!isAbsolute).join("/")
path||isAbsolute||(path=".")
path&&trailingSlash&&(path+="/")
return(isAbsolute?"/":"")+path}
exports.join=function(){var paths=Array.prototype.slice.call(arguments,0)
return exports.normalize(filter(paths,function(p){return p&&"string"==typeof p}).join("/"))}
exports.dirname=function(path){var dir=splitPathRe.exec(path)[1]||"",isWindows=!1
return dir?1===dir.length||isWindows&&dir.length<=3&&":"===dir.charAt(1)?dir:dir.substring(0,dir.length-1):"."}
exports.basename=function(path,ext){var f=splitPathRe.exec(path)[2]||""
ext&&f.substr(-1*ext.length)===ext&&(f=f.substr(0,f.length-ext.length))
return f}
exports.extname=function(path){return splitPathRe.exec(path)[3]||""}})
require.define("__browserify_process",function(require,module,exports,__dirname,__filename,process){var process=module.exports={}
process.nextTick=function(){var canSetImmediate="undefined"!=typeof window&&window.setImmediate,canPost="undefined"!=typeof window&&window.postMessage&&window.addEventListener
if(canSetImmediate)return window.setImmediate
if(canPost){var queue=[]
window.addEventListener("message",function(ev){if(ev.source===window&&"browserify-tick"===ev.data){ev.stopPropagation()
if(queue.length>0){var fn=queue.shift()
fn()}}},!0)
return function(fn){queue.push(fn)
window.postMessage("browserify-tick","*")}}return function(fn){setTimeout(fn,0)}}()
process.title="browser"
process.browser=!0
process.env={}
process.argv=[]
process.binding=function(name){if("evals"===name)return require("vm")
throw new Error("No such module. (Possibly not yet loaded)")}
!function(){var path,cwd="/"
process.cwd=function(){return cwd}
process.chdir=function(dir){path||(path=require("path"))
cwd=path.resolve(dir,cwd)}}()})
require.define("/node_modules_koding/koding-broker-client/lib/broker-client/index.js",function(require,module,exports){exports.Broker=require("./broker")
exports.Channel=require("./channel")
"undefined"!=typeof window&&null!==window&&(window.KDBroker=exports)})
require.define("/node_modules_koding/koding-broker-client/lib/broker-client/broker.js",function(require,module,exports,__dirname,__filename,process){var Broker,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
module.exports=Broker=function(_super){function Broker(ws,options){var _ref1,_ref2
Broker.__super__.constructor.apply(this,arguments)
this.sockURL=ws
this.autoReconnect=options.autoReconnect,this.authExchange=options.authExchange,this.overlapDuration=options.overlapDuration,this.servicesEndpoint=options.servicesEndpoint
null==(_ref1=this.overlapDuration)&&(this.overlapDuration=3e3)
null==(_ref2=this.authExchange)&&(this.authExchange="auth")
this.readyState=NOTREADY
this.channels={}
this.namespacedEvents={}
this.subscriptions={}
this.autoReconnect&&this.initBackoff(options.backoff)
this.connect()}var CLOSED,Channel,NOTREADY,READY,createId,emitToChannel,_ref
__extends(Broker,_super)
_ref=[0,1,3],NOTREADY=_ref[0],READY=_ref[1],CLOSED=_ref[2]
Channel=require("./channel")
createId=require("hat")
emitToChannel=require("./util").emitToChannel
Broker.prototype.initBackoff=require("koding-backoff")
Broker.prototype.setP2PKeys=function(channelName,_arg,serviceType){var bindingKey,channel,consumerChannel,producerChannel,routingKey
routingKey=_arg.routingKey,bindingKey=_arg.bindingKey
channel=this.channels[channelName]
if(channel){channel.close()
consumerChannel=this.subscribe(bindingKey,{exchange:"chat",isReadOnly:!0,isSecret:!0})
consumerChannel.setAuthenticationInfo({serviceType:serviceType})
consumerChannel.pipe(channel)
producerChannel=this.subscribe(routingKey,{exchange:"chat",isReadOnly:!1,isSecret:!0})
producerChannel.setAuthenticationInfo({serviceType:serviceType})
channel.off("publish")
channel.on("publish",producerChannel.bound("publish"))
channel.consumerChannel=consumerChannel
channel.producerChannel=producerChannel
return channel}}
Broker.prototype.bound=require("koding-bound")
Broker.prototype.onopen=function(){var _this=this
this.clearBackoffTimeout()
this.once("broker.connected",function(newSocketId){return _this.socketId=newSocketId})
this.readyState===CLOSED&&this.resubscribe()
this.readyState=READY
this.emit("ready")
return this.emit("connected")}
Broker.prototype.onclose=function(){var _this=this
this.readyState=CLOSED
this.emit("disconnected",Object.keys(this.channels))
return this.autoReconnect?process.nextTick(function(){return _this.connectAttemptFail()}):void 0}
Broker.prototype.connectAttemptFail=function(){return this.setBackoffTimeout(this.bound("connect"),this.bound("connectFail"))}
Broker.prototype.selectAndConnect=function(){var xhr,_this=this
xhr=new XMLHttpRequest
xhr.open("GET",this.servicesEndpoint)
xhr.onreadystatechange=function(){var response,_ref1
if(0===xhr.status||xhr.status>=400){_this.connectAttemptFail()
return _this}if(4===xhr.readyState&&(200===(_ref1=xhr.status)||304===_ref1)){response=JSON.parse(xhr.responseText)
_this.sockURL=""+(Array.isArray(response)?response[0]:response)+"/subscribe"
return _this.connectDirectly()}}
return xhr.send()}
Broker.prototype.connectDirectly=function(){var _this=this
this.ws=new SockJS(this.sockURL)
this.ws.addEventListener("open",this.bound("onopen"))
this.ws.addEventListener("close",this.bound("onclose"))
this.ws.addEventListener("message",this.bound("handleMessageEvent"))
return this.ws.addEventListener("message",function(){return _this.emit("messageArrived")})}
Broker.prototype.disconnect=function(reconnect){null==reconnect&&(reconnect=!0)
null!=reconnect&&(this.autoReconnect=!!reconnect)
return this.ws.close()}
Broker.prototype.connect=function(){return null!=this.servicesEndpoint?this.selectAndConnect():this.connectDirectly()}
Broker.prototype.connectFail=function(){return this.emit("connectFailed")}
Broker.prototype.createRoutingKeyPrefix=function(name,options){var isReadOnly,suffix
null==options&&(options={})
isReadOnly=options.isReadOnly,suffix=options.suffix
name+=suffix||""
return isReadOnly?name:"client."+name}
Broker.prototype.wrapPrivateChannel=function(channel){var _this=this
channel.on("cycle",function(){return _this.authenticate(channel)})
return channel.on("setSecretNames",function(secretName){var consumerChannel,isReadOnly
isReadOnly=channel.isReadOnly
channel.setSecretName(secretName)
channel.isForwarder=!0
consumerChannel=_this.subscribe(secretName.publishingName,{isReadOnly:isReadOnly,isSecret:!0,exchange:channel.exchange})
consumerChannel.setAuthenticationInfo({serviceType:"secret",wrapperRoutingKeyPrefix:channel.routingKeyPrefix})
channel.consumerChannel=consumerChannel
consumerChannel.on("cycleChannel",function(){channel.oldConsumerChannel=channel.consumerChannel
return channel.cycle()})
isReadOnly||channel.on("publish",function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return consumerChannel.publish.apply(consumerChannel,rest)})
_this.swapPrivateSourceChannel(channel)
return channel.emit("ready")})}
Broker.prototype.swapPrivateSourceChannel=function(channel){var consumerChannel,oldConsumerChannel
consumerChannel=channel.consumerChannel,oldConsumerChannel=channel.oldConsumerChannel
return null!=oldConsumerChannel?setTimeout(function(){oldConsumerChannel.close().off()
delete channel.oldConsumerChannel
return consumerChannel.pipe(channel)},this.overlapDuration):consumerChannel.pipe(channel)}
Broker.prototype.registerNamespacedEvent=function(name){var register,_ref1
register=this.namespacedEvents
null==(_ref1=register[name])&&(register[name]=0)
register[name]+=1
return 1===register[name]}
Broker.prototype.createChannel=function(name,options){var channel,exchange,handler,isExclusive,isP2P,isPrivate,isReadOnly,isSecret,routingKeyPrefix,suffix,_this=this
if(null!=this.channels[name])return this.channels[name]
isReadOnly=options.isReadOnly,isSecret=options.isSecret,isExclusive=options.isExclusive,isPrivate=options.isPrivate,isP2P=options.isP2P,suffix=options.suffix,exchange=options.exchange
null==suffix&&(suffix=isExclusive?"."+createId(32):"")
routingKeyPrefix=this.createRoutingKeyPrefix(name,{suffix:suffix,isReadOnly:isReadOnly})
channel=new Channel(name,routingKeyPrefix,{isReadOnly:isReadOnly,isSecret:isSecret,isP2P:isP2P,isExclusive:null!=isExclusive?isExclusive:isPrivate,exchange:exchange})
this.on("broker.subscribed",handler=function(routingKeyPrefixes){var prefix,_i,_len,_ref1
_ref1=routingKeyPrefixes.split(" ")
for(_i=0,_len=_ref1.length;_len>_i;_i++){prefix=_ref1[_i]
if(prefix===routingKeyPrefix){_this.authenticate(channel)
channel.emit("broker.subscribed",channel.routingKeyPrefix)
return}}})
this.on(routingKeyPrefix,function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return channel.isForwarder?void 0:channel.emit.apply(channel,["message"].concat(__slice.call(rest)))})
channel.on("newListener",function(event,listener){var namespacedEvent,needsToBeRegistered;(channel.isExclusive||channel.isP2P)&&channel.trackListener(event,listener)
if("broker.subscribed"!==event){namespacedEvent=""+routingKeyPrefix+"."+event
needsToBeRegistered=_this.registerNamespacedEvent(namespacedEvent)
if(needsToBeRegistered)return _this.on(namespacedEvent,function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return emitToChannel.apply(null,[_this,channel,event].concat(__slice.call(rest)))})}})
isSecret||channel.on("auth.authOk",function(){return channel.isAuthenticated=!0})
channel.once("error",channel.bound("close"))
channel.once("close",function(){return _this.unsubscribe(channel.name)});(isExclusive||isPrivate)&&this.wrapPrivateChannel(channel)
isPrivate||isReadOnly||channel.on("publish",function(options,payload){var _ref1,_ref2,_ref3
null==payload&&(_ref1=[options,payload],payload=_ref1[0],options=_ref1[1])
exchange=null!=(_ref2=null!=(_ref3=null!=options?options.exchange:void 0)?_ref3:channel.exchange)?_ref2:channel.name
return _this.publish({exchange:exchange,routingKey:channel.name},payload)})
this.channels[name]=channel
return channel}
Broker.prototype.authenticate=function(channel){var authInfo,key,val,_ref1
authInfo={}
_ref1=channel.getAuthenticationInfo()
for(key in _ref1)if(__hasProp.call(_ref1,key)){val=_ref1[key]
authInfo[key]=val}authInfo.routingKey=channel.routingKeyPrefix
return this.publish(this.authExchange,authInfo)}
Broker.prototype.handleMessageEvent=function(event){var message
message=event.data
this.emit("rawMessage",message)
message.routingKey&&this.emit(message.routingKey,message.payload)}
Broker.prototype.ready=function(listener){return this.readyState===READY?process.nextTick(listener):this.once("ready",listener)}
Broker.prototype.send=function(data){var _this=this
this.emit("send",data)
this.ready(function(){var e
try{return _this.ws._transport.doSend(JSON.stringify(data))}catch(_error){e=_error
return _this.disconnect()}})
return this}
Broker.prototype.publish=function(options,payload){var exchange,routingKey
this.emit("messagePublished")
"string"==typeof options?routingKey=exchange=options:(routingKey=options.routingKey,exchange=options.exchange)
routingKey=this.createRoutingKeyPrefix(routingKey)
"string"!=typeof payload&&(payload=JSON.stringify(payload))
this.send({action:"publish",exchange:exchange,routingKey:routingKey,payload:payload})
return this}
Broker.prototype.resubscribeBySocketId=function(){var _this=this
this.send({action:"resubscribe",socketId:this.socketId})
return this.once("broker.resubscribed",function(found){var channel,_,_ref1,_results
if(found){_ref1=_this.channels
_results=[]
for(_ in _ref1)if(__hasProp.call(_ref1,_)){channel=_ref1[_]
_results.push(channel.emit("broker.subscribed"))}return _results}return _this.resubscribeBySubscriptions()})}
Broker.prototype.resubscribeBySubscriptions=function(){var rk,routingKeyPrefix,_
routingKeyPrefix=function(){var _ref1,_results
_ref1=this.subscriptions
_results=[]
for(_ in _ref1)if(__hasProp.call(_ref1,_)){rk=_ref1[_].routingKeyPrefix
_results.push(rk)}return _results}.call(this).join(" ")
return this.send({action:"subscribe",routingKeyPrefix:routingKeyPrefix})}
Broker.prototype.resubscribe=function(){return null!=this.socketId?this.resubscribeBySocketId():this.resubscribeBySubscriptions()}
Broker.prototype.subscribe=function(name,options,callback){var channel,exchange,handler,isExclusive,isP2P,isPrivate,isReadOnly,isSecret,routingKeyPrefix,suffix,_this=this
null==options&&(options={})
channel=this.channels[name]
if(null==channel){isSecret=!!options.isSecret
isExclusive=!!options.isExclusive
isReadOnly=null!=options.isReadOnly?!!options.isReadOnly:isExclusive
isPrivate=!!options.isPrivate
isP2P=!!options.isP2P
suffix=options.suffix,exchange=options.exchange
routingKeyPrefix=this.createRoutingKeyPrefix(name,{isReadOnly:isReadOnly})
this.subscriptions[name]={name:name,routingKeyPrefix:routingKeyPrefix,arguments:arguments}
channel=this.channels[name]=this.createChannel(name,{isReadOnly:isReadOnly,isSecret:isSecret,isExclusive:isExclusive,isPrivate:isPrivate,isP2P:isP2P,suffix:suffix,exchange:exchange})}this.send({action:"subscribe",routingKeyPrefix:channel.routingKeyPrefix})
null!=callback&&this.on("broker.subscribed",handler=function(routingKeyPrefixes){var prefix,_i,_len,_ref1
_ref1=routingKeyPrefixes.split(" ")
for(_i=0,_len=_ref1.length;_len>_i;_i++){prefix=_ref1[_i]
if(prefix===routingKeyPrefix){_this.off("broker.subscribed",handler)
callback(prefix)
return}}})
return channel}
Broker.prototype.unsubscribe=function(name){this.send({action:"unsubscribe",routingKeyPrefix:this.createRoutingKeyPrefix(name)})
delete this.channels[name]
delete this.subscriptions[name]
return this}
Broker.prototype.ping=function(callback){this.send({action:"ping"})
return null!=callback?this.once("broker.pong",callback):void 0}
return Broker}(KDEventEmitter.Wildcard)})
require.define("/node_modules_koding/koding-broker-client/lib/broker-client/channel.js",function(require,module){var Channel,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
module.exports=Channel=function(_super){function Channel(name,routingKeyPrefix,options){var _this=this
this.name=name
this.routingKeyPrefix=routingKeyPrefix
Channel.__super__.constructor.apply(this,arguments)
this.isOpen=!0
this.isReadOnly=options.isReadOnly,this.isSecret=options.isSecret,this.isExclusive=options.isExclusive,this.isP2P=options.isP2P,this.exchange=options.exchange
if(this.isExclusive||this.isP2P){this.eventRegister=[]
this.trackListener=function(event,listener){var _ref
_this.eventRegister.push({event:event,listener:listener})
return"publish"!==event?null!=(_ref=_this.consumerChannel)?_ref.on(event,listener):void 0:void 0}}}__extends(Channel,_super)
Channel.prototype.publish=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return this.isReadOnly?void 0:this.emit.apply(this,["publish"].concat(__slice.call(rest)))}
Channel.prototype.close=function(){this.isOpen=!1
return this.emit("close")}
Channel.prototype.cycle=function(){return this.isOpen?this.emit("cycle"):void 0}
Channel.prototype.pipe=function(channel){var event,listener,_i,_len,_ref,_ref1
_ref=channel.eventRegister
for(_i=0,_len=_ref.length;_len>_i;_i++){_ref1=_ref[_i],event=_ref1.event,listener=_ref1.listener
"publish"!==event&&this.on(event,listener)}return this.on("message",function(message){return channel.emit("message",message)})}
Channel.prototype.setAuthenticationInfo=function(authenticationInfo){this.authenticationInfo=authenticationInfo}
Channel.prototype.getAuthenticationInfo=function(){return this.authenticationInfo}
Channel.prototype.isListeningTo=function(event){var listeners,_ref
listeners=null!=(_ref=this._events)?_ref[event]:void 0
return listeners&&Object.keys(listeners).length>0}
Channel.prototype.setSecretName=function(secretName){this.secretName=secretName}
Channel.prototype.bound=require("koding-bound")
return Channel}(KDEventEmitter)})
require.define("/node_modules/koding-bound/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/koding-bound/index.js",function(require,module){module.exports=require("./lib/koding-bound")})
require.define("/node_modules/koding-bound/lib/koding-bound/index.js",function(require,module){module.exports=function(method){var boundMethod
if(null==this[method])throw new Error("@bound: unknown method! "+method)
boundMethod="__bound__"+method
boundMethod in this||Object.defineProperty(this,boundMethod,{value:this[method].bind(this)})
return this[boundMethod]}})
require.define("/node_modules/hat/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/hat/index.js",function(require,module){var hat=module.exports=function(bits,base){base||(base=16)
void 0===bits&&(bits=128)
if(0>=bits)return"0"
for(var digits=Math.log(Math.pow(2,bits))/Math.log(base),i=2;1/0===digits;i*=2)digits=Math.log(Math.pow(2,bits/i))/Math.log(base)*i
for(var rem=digits-Math.floor(digits),res="",i=0;i<Math.floor(digits);i++){var x=Math.floor(Math.random()*base).toString(base)
res=x+res}if(rem){var b=Math.pow(base,rem),x=Math.floor(Math.random()*b).toString(base)
res=x+res}var parsed=parseInt(res,base)
return 1/0!==parsed&&parsed>=Math.pow(2,bits)?hat(bits,base):res}
hat.rack=function(bits,base,expandBy){var fn=function(data){var iters=0
do{if(iters++>10){if(!expandBy)throw new Error("too many ID collisions, use more bits")
bits+=expandBy}var id=hat(bits,base)}while(Object.hasOwnProperty.call(hats,id))
hats[id]=data
return id},hats=fn.hats={}
fn.get=function(id){return fn.hats[id]}
fn.set=function(id,value){fn.hats[id]=value
return fn}
fn.bits=bits||128
fn.base=base||16
return fn}})
require.define("/node_modules_koding/koding-broker-client/lib/broker-client/util.js",function(require,module,exports){var __slice=[].slice
exports.emitToChannel=function(){var channel,ctx,event,oldChannelEvent,rest
ctx=arguments[0],channel=arguments[1],event=arguments[2],rest=4<=arguments.length?__slice.call(arguments,3):[]
if(!channel.isForwarder||"cycleChannel"===event||"setSecretNames"===event){null!=channel.event&&(oldChannelEvent=channel.event)
channel.event=ctx.event
channel.emit.apply(channel,[event].concat(__slice.call(rest)))
null!=oldChannelEvent?channel.event=oldChannelEvent:delete channel.event}}})
require.define("/node_modules/koding-backoff/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/koding-backoff/index.js",function(require,module){module.exports=require("./lib/backoff.js")})
require.define("/node_modules/koding-backoff/lib/backoff.js",function(require,module){module.exports=function(ctx,options){var initalDelayMs,maxDelayMs,maxReconnectAttempts,multiplyFactor,totalReconnectAttempts,_ref,_ref1,_ref2,_ref3,_ref4
null==options&&(options={})
options||(_ref=[ctx,options],options=_ref[0],ctx=_ref[1])
ctx||(ctx=this)
totalReconnectAttempts=0
initalDelayMs=null!=(_ref1=options.initialDelayMs)?_ref1:700
multiplyFactor=null!=(_ref2=options.multiplyFactor)?_ref2:1.4
maxDelayMs=null!=(_ref3=options.maxDelayMs)?_ref3:15e3
maxReconnectAttempts=null!=(_ref4=options.maxReconnectAttempts)?_ref4:50
ctx.clearBackoffTimeout=function(){return totalReconnectAttempts=0}
ctx.setBackoffTimeout=function(attemptFn,failFn){var timeout
if(maxReconnectAttempts>totalReconnectAttempts){timeout=Math.min(initalDelayMs*Math.pow(multiplyFactor,totalReconnectAttempts),maxDelayMs)
setTimeout(attemptFn,timeout)
return totalReconnectAttempts++}return failFn()}
return ctx}})
require.define("/node_modules_koding/koding-broker-client/index.js",function(require,module){module.exports=require("./lib/broker-client")})
require("/node_modules_koding/koding-broker-client/index.js")}()

!function(){!function(){var require=function(file,cwd){var resolved=require.resolve(file,cwd||"/"),mod=require.modules[resolved]
if(!mod)throw new Error("Failed to resolve module "+file+", tried "+resolved)
var cached=require.cache[resolved],res=cached?cached.exports:mod()
return res}
require.paths=[]
require.modules={}
require.cache={}
require.extensions=[".js",".coffee"]
require._core={assert:!0,events:!0,fs:!0,path:!0,vm:!0}
require.resolve=function(){return function(x,cwd){function loadAsFileSync(x){x=path.normalize(x)
if(require.modules[x])return x
for(var i=0;i<require.extensions.length;i++){var ext=require.extensions[i]
if(require.modules[x+ext])return x+ext}}function loadAsDirectorySync(x){x=x.replace(/\/+$/,"")
var pkgfile=path.normalize(x+"/package.json")
if(require.modules[pkgfile]){var pkg=require.modules[pkgfile](),b=pkg.browserify
if("object"==typeof b&&b.main){var m=loadAsFileSync(path.resolve(x,b.main))
if(m)return m}else if("string"==typeof b){var m=loadAsFileSync(path.resolve(x,b))
if(m)return m}else if(pkg.main){var m=loadAsFileSync(path.resolve(x,pkg.main))
if(m)return m}}return loadAsFileSync(x+"/index")}function loadNodeModulesSync(x,start){for(var dirs=nodeModulesPathsSync(start),i=0;i<dirs.length;i++){var dir=dirs[i],m=loadAsFileSync(dir+"/"+x)
if(m)return m
var n=loadAsDirectorySync(dir+"/"+x)
if(n)return n}var m=loadAsFileSync(x)
return m?m:void 0}function nodeModulesPathsSync(start){var parts
parts="/"===start?[""]:path.normalize(start).split("/")
for(var dirs=[],i=parts.length-1;i>=0;i--)if("node_modules"!==parts[i]){var dir=parts.slice(0,i+1).join("/")+"/node_modules"
dirs.push(dir)}return dirs}cwd||(cwd="/")
if(require._core[x])return x
var path=require.modules.path()
cwd=path.resolve("/",cwd)
var y=cwd||"/"
if(x.match(/^(?:\.\.?\/|\/)/)){var m=loadAsFileSync(path.resolve(y,x))||loadAsDirectorySync(path.resolve(y,x))
if(m)return m}var n=loadNodeModulesSync(x,y)
if(n)return n
throw new Error("Cannot find module '"+x+"'")}}()
require.alias=function(from,to){var path=require.modules.path(),res=null
try{res=require.resolve(from+"/package.json","/")}catch(err){res=require.resolve(from,"/")}for(var basedir=path.dirname(res),keys=(Object.keys||function(obj){var res=[]
for(var key in obj)res.push(key)
return res})(require.modules),i=0;i<keys.length;i++){var key=keys[i]
if(key.slice(0,basedir.length+1)===basedir+"/"){var f=key.slice(basedir.length)
require.modules[to+f]=require.modules[basedir+f]}else key===basedir&&(require.modules[to]=require.modules[basedir])}}
!function(){var process={}
require.define=function(filename,fn){require.modules.__browserify_process&&(process=require.modules.__browserify_process())
var dirname=require._core[filename]?"":require.modules.path().dirname(filename),require_=function(file){var requiredModule=require(file,dirname),cached=require.cache[require.resolve(file,dirname)]
cached&&null===cached.parent&&(cached.parent=module_)
return requiredModule}
require_.resolve=function(name){return require.resolve(name,dirname)}
require_.modules=require.modules
require_.define=require.define
require_.cache=require.cache
var module_={id:filename,filename:filename,exports:{},loaded:!1,parent:null}
require.modules[filename]=function(){require.cache[filename]=module_
fn.call(module_.exports,require_,module_,module_.exports,dirname,filename,process)
module_.loaded=!0
return module_.exports}}}()
require.define("path",function(require,module,exports,__dirname,__filename,process){function filter(xs,fn){for(var res=[],i=0;i<xs.length;i++)fn(xs[i],i,xs)&&res.push(xs[i])
return res}function normalizeArray(parts,allowAboveRoot){for(var up=0,i=parts.length;i>=0;i--){var last=parts[i]
if("."==last)parts.splice(i,1)
else if(".."===last){parts.splice(i,1)
up++}else if(up){parts.splice(i,1)
up--}}if(allowAboveRoot)for(;up--;up)parts.unshift("..")
return parts}var splitPathRe=/^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/
exports.resolve=function(){for(var resolvedPath="",resolvedAbsolute=!1,i=arguments.length;i>=-1&&!resolvedAbsolute;i--){var path=i>=0?arguments[i]:process.cwd()
if("string"==typeof path&&path){resolvedPath=path+"/"+resolvedPath
resolvedAbsolute="/"===path.charAt(0)}}resolvedPath=normalizeArray(filter(resolvedPath.split("/"),function(p){return!!p}),!resolvedAbsolute).join("/")
return(resolvedAbsolute?"/":"")+resolvedPath||"."}
exports.normalize=function(path){var isAbsolute="/"===path.charAt(0),trailingSlash="/"===path.slice(-1)
path=normalizeArray(filter(path.split("/"),function(p){return!!p}),!isAbsolute).join("/")
path||isAbsolute||(path=".")
path&&trailingSlash&&(path+="/")
return(isAbsolute?"/":"")+path}
exports.join=function(){var paths=Array.prototype.slice.call(arguments,0)
return exports.normalize(filter(paths,function(p){return p&&"string"==typeof p}).join("/"))}
exports.dirname=function(path){var dir=splitPathRe.exec(path)[1]||"",isWindows=!1
return dir?1===dir.length||isWindows&&dir.length<=3&&":"===dir.charAt(1)?dir:dir.substring(0,dir.length-1):"."}
exports.basename=function(path,ext){var f=splitPathRe.exec(path)[2]||""
ext&&f.substr(-1*ext.length)===ext&&(f=f.substr(0,f.length-ext.length))
return f}
exports.extname=function(path){return splitPathRe.exec(path)[3]||""}})
require.define("__browserify_process",function(require,module,exports,__dirname,__filename,process){var process=module.exports={}
process.nextTick=function(){var queue=[],canPost="undefined"!=typeof window&&window.postMessage&&window.addEventListener
canPost&&window.addEventListener("message",function(ev){if(ev.source===window&&"browserify-tick"===ev.data){ev.stopPropagation()
if(queue.length>0){var fn=queue.shift()
fn()}}},!0)
return function(fn){if(canPost){queue.push(fn)
window.postMessage("browserify-tick","*")}else setTimeout(fn,0)}}()
process.title="browser"
process.browser=!0
process.env={}
process.argv=[]
process.binding=function(name){if("evals"===name)return require("vm")
throw new Error("No such module. (Possibly not yet loaded)")}
!function(){var path,cwd="/"
process.cwd=function(){return cwd}
process.chdir=function(dir){path||(path=require("path"))
cwd=path.resolve(dir,cwd)}}()})
require.define("vm",function(require,module){module.exports=require("vm-browserify")})
require.define("/node_modules/vm-browserify/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/vm-browserify/index.js",function(require,module,exports,__dirname,__filename,process){var Object_keys=function(obj){if(Object.keys)return Object.keys(obj)
var res=[]
for(var key in obj)res.push(key)
return res},forEach=function(xs,fn){if(xs.forEach)return xs.forEach(fn)
for(var i=0;i<xs.length;i++)fn(xs[i],i,xs)},Script=exports.Script=function(code){if(!(this instanceof Script))return new Script(code)
this.code=code
return void 0}
Script.prototype.runInNewContext=function(context){context||(context={})
var iframe=document.createElement("iframe")
iframe.style||(iframe.style={})
iframe.style.display="none"
document.body.appendChild(iframe)
var win=iframe.contentWindow
forEach(Object_keys(context),function(key){win[key]=context[key]})
!win.eval&&win.execScript&&win.execScript("null")
var res=win.eval(this.code)
forEach(Object_keys(win),function(key){context[key]=win[key]})
document.body.removeChild(iframe)
return res}
Script.prototype.runInThisContext=function(){return eval(this.code)}
Script.prototype.runInContext=function(context){return this.runInNewContext(context)}
forEach(Object_keys(Script.prototype),function(name){exports[name]=Script[name]=function(code){var s=Script(code)
return s[name].apply(s,[].slice.call(arguments,1))}})
exports.createScript=function(code){return exports.Script(code)}
exports.createContext=Script.createContext=function(context){var copy={}
"object"==typeof context&&forEach(Object_keys(context),function(key){copy[key]=context[key]})
return copy}})
require.define("/node_modules/microemitter/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/microemitter/index.js",function(require,module){var EventEmitter,__slice=[].slice,__hasProp={}.hasOwnProperty
EventEmitter=function(){"use strict"
function EventEmitter(obj){null!=obj?mixin(obj):obj=this}var createId,defineProperty,idKey,init,mixin
idKey="ಠ_ಠ"
EventEmitter.listeners={}
EventEmitter.targets={}
EventEmitter.off=function(listenerId){delete this.listeners[listenerId]
delete this.targets[listenerId]
return this}
defineProperty=Object.defineProperty||function(obj,prop,_arg){var value
value=_arg.value
return obj[prop]=value}
createId=function(){var counter
counter=0
return function(){return counter++}}()
mixin=function(obj){var prop,prot,_results
prot=EventEmitter.prototype
_results=[]
for(prop in prot)_results.push(obj[prop]=prot[prop])
return _results}
init=function(obj){idKey in obj||defineProperty(obj,idKey,{value:""+Math.round(1e9*Math.random())})
return"_events"in obj?void 0:defineProperty(obj,"_events",{value:{}})}
EventEmitter.prototype.on=function(evt,listener){var lid,listeners,_base
if(null==listener)throw new Error("Listener is required!")
init(this)
this.emit("newListener",evt,listener)
listeners=(_base=this._events)[evt]||(_base[evt]={})
if(this[idKey]in listener)lid=listener[this[idKey]]
else{lid=createId()
defineProperty(listener,this[idKey],{value:lid})}EventEmitter.listeners[lid]=listeners[lid]=listener
EventEmitter.targets[lid]=this
return this}
EventEmitter.prototype.once=function(evt,listener){var wrappedListener,_this=this
wrappedListener=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
_this.off(evt,wrappedListener)
return listener.apply(_this,rest)}
return this.on(evt,wrappedListener)}
EventEmitter.prototype.when=function(){}
EventEmitter.prototype.off=function(evt,listener){var key,listenerId,listeners,_ref
init(this)
switch(arguments.length){case 0:_ref=this._events
for(key in _ref)__hasProp.call(_ref,key)&&delete this._events[key]
break
case 1:this._events[evt]={}
break
default:listeners=this._events[evt]
listenerId=listener[this[idKey]]
null!=listeners&&delete listeners[listenerId]
EventEmitter.off(listenerId)}return this}
EventEmitter.prototype.emit=function(){var evt,id,listener,listeners,rest
evt=arguments[0],rest=2<=arguments.length?__slice.call(arguments,1):[]
init(this)
listeners=this._events[evt]
for(id in listeners)if(__hasProp.call(listeners,id)){listener=listeners[id]
listener.call.apply(listener,[this].concat(__slice.call(rest)))}null===listeners&&(listeners=[])
if("error"===evt&&0===listeners.length)throw rest[0]
return this}
return EventEmitter}()
null!=("undefined"!=typeof module&&null!==module?module.exports:void 0)?module.exports.EventEmitter=EventEmitter:null!=("undefined"!=typeof define&&null!==define?define.amd:void 0)?define(function(){return EventEmitter}):this.EventEmitter=EventEmitter})
require.define("/node_modules/traverse/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/traverse/index.js",function(require,module){function Traverse(obj){this.value=obj}function walk(root,cb,immutable){var path=[],parents=[],alive=!0
return function walker(node_){function updateState(){if("object"==typeof state.node&&null!==state.node){state.keys&&state.node_===state.node||(state.keys=objectKeys(state.node))
state.isLeaf=0==state.keys.length}else{state.isLeaf=!0
state.keys=null}state.notLeaf=!state.isLeaf
state.notRoot=!state.isRoot}var node=immutable?copy(node_):node_,modifiers={},keepGoing=!0,state={node:node,node_:node_,path:[].concat(path),parent:parents[parents.length-1],parents:parents,key:path.slice(-1)[0],isRoot:0===path.length,level:path.length,update:function(x,stopHere){state.isRoot||(state.parent.node[state.key]=x)
state.node=x
stopHere&&(keepGoing=!1)},"delete":function(stopHere){delete state.parent.node[state.key]
stopHere&&(keepGoing=!1)},remove:function(stopHere){isArray(state.parent.node)?state.parent.node.splice(state.key,1):delete state.parent.node[state.key]
stopHere&&(keepGoing=!1)},keys:null,before:function(f){modifiers.before=f},after:function(f){modifiers.after=f},pre:function(f){modifiers.pre=f},post:function(f){modifiers.post=f},stop:function(){alive=!1},block:function(){keepGoing=!1}}
if(!alive)return state
updateState()
var ret=cb.call(state,state.node)
void 0!==ret&&state.update&&state.update(ret)
modifiers.before&&modifiers.before.call(state,state.node)
if(!keepGoing)return state
if("object"==typeof state.node&&null!==state.node){parents.push(state)
forEach(state.keys,function(key,i){path.push(key)
modifiers.pre&&modifiers.pre.call(state,state.node[key],key)
var child=walker(state.node[key])
immutable&&Object.hasOwnProperty.call(state.node,key)&&(state.node[key]=child.node)
child.isLast=i==state.keys.length-1
child.isFirst=0==i
modifiers.post&&modifiers.post.call(state,child)
path.pop()})
parents.pop()}modifiers.after&&modifiers.after.call(state,state.node)
return state}(root).node}function copy(src){if("object"==typeof src&&null!==src){var dst
if(isArray(src))dst=[]
else if(isDate(src))dst=new Date(src)
else if(isRegExp(src))dst=new RegExp(src)
else if(isError(src))dst={message:src.message}
else if(isBoolean(src))dst=new Boolean(src)
else if(isNumber(src))dst=new Number(src)
else if(isString(src))dst=new String(src)
else if(Object.create&&Object.getPrototypeOf)dst=Object.create(Object.getPrototypeOf(src))
else if(src.constructor===Object)dst={}
else{var proto=src.constructor&&src.constructor.prototype||src.__proto__||{},T=function(){}
T.prototype=proto
dst=new T}forEach(objectKeys(src),function(key){dst[key]=src[key]})
return dst}return src}function toS(obj){return Object.prototype.toString.call(obj)}function isDate(obj){return"[object Date]"===toS(obj)}function isRegExp(obj){return"[object RegExp]"===toS(obj)}function isError(obj){return"[object Error]"===toS(obj)}function isBoolean(obj){return"[object Boolean]"===toS(obj)}function isNumber(obj){return"[object Number]"===toS(obj)}function isString(obj){return"[object String]"===toS(obj)}var traverse=module.exports=function(obj){return new Traverse(obj)}
Traverse.prototype.get=function(ps){for(var node=this.value,i=0;i<ps.length;i++){var key=ps[i]
if(!Object.hasOwnProperty.call(node,key)){node=void 0
break}node=node[key]}return node}
Traverse.prototype.has=function(ps){for(var node=this.value,i=0;i<ps.length;i++){var key=ps[i]
if(!Object.hasOwnProperty.call(node,key))return!1
node=node[key]}return!0}
Traverse.prototype.set=function(ps,value){for(var node=this.value,i=0;i<ps.length-1;i++){var key=ps[i]
Object.hasOwnProperty.call(node,key)||(node[key]={})
node=node[key]}node[ps[i]]=value
return value}
Traverse.prototype.map=function(cb){return walk(this.value,cb,!0)}
Traverse.prototype.forEach=function(cb){this.value=walk(this.value,cb,!1)
return this.value}
Traverse.prototype.reduce=function(cb,init){var skip=1===arguments.length,acc=skip?this.value:init
this.forEach(function(x){this.isRoot&&skip||(acc=cb.call(this,acc,x))})
return acc}
Traverse.prototype.paths=function(){var acc=[]
this.forEach(function(){acc.push(this.path)})
return acc}
Traverse.prototype.nodes=function(){var acc=[]
this.forEach(function(){acc.push(this.node)})
return acc}
Traverse.prototype.clone=function(){var parents=[],nodes=[]
return function clone(src){if("object"==typeof src&&null!==src){var dst=copy(src)
parents.push(src)
nodes.push(dst)
forEach(objectKeys(src),function(key){dst[key]=clone(src[key])})
parents.pop()
nodes.pop()
return dst}return src}(this.value)}
var objectKeys=Object.keys||function(obj){var res=[]
for(var key in obj)res.push(key)
return res},isArray=Array.isArray||function(xs){return"[object Array]"===Object.prototype.toString.call(xs)},forEach=function(xs,fn){if(xs.forEach)return xs.forEach(fn)
for(var i=0;i<xs.length;i++)fn(xs[i],i,xs)}
forEach(objectKeys(Traverse.prototype),function(key){traverse[key]=function(obj){var args=[].slice.call(arguments,1),t=new Traverse(obj)
return t[key].apply(t,args)}})})
require.define("/node_modules/hat/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/hat/index.js",function(require,module){var hat=module.exports=function(bits,base){base||(base=16)
void 0===bits&&(bits=128)
if(0>=bits)return"0"
for(var digits=Math.log(Math.pow(2,bits))/Math.log(base),i=2;1/0===digits;i*=2)digits=Math.log(Math.pow(2,bits/i))/Math.log(base)*i
for(var rem=digits-Math.floor(digits),res="",i=0;i<Math.floor(digits);i++){var x=Math.floor(Math.random()*base).toString(base)
res=x+res}if(rem){var b=Math.pow(base,rem),x=Math.floor(Math.random()*b).toString(base)
res=x+res}var parsed=parseInt(res,base)
return 1/0!==parsed&&parsed>=Math.pow(2,bits)?hat(bits,base):res}
hat.rack=function(bits,base,expandBy){var fn=function(data){var iters=0
do{if(iters++>10){if(!expandBy)throw new Error("too many ID collisions, use more bits")
bits+=expandBy}var id=hat(bits,base)}while(Object.hasOwnProperty.call(hats,id))
hats[id]=data
return id},hats=fn.hats={}
fn.get=function(id){return fn.hats[id]}
fn.set=function(id,value){fn.hats[id]=value
return fn}
fn.bits=bits||128
fn.base=base||16
return fn}})
require.define("/node_modules/jspath/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/jspath/index.js",function(require,module){!function(){var JsPath,__slice=Array.prototype.slice
module.exports=JsPath=function(){function JsPath(path,val){return JsPath.setAt({},path,val||{})}var primTypes
primTypes=/^(string|number|boolean)$/;["forEach","indexOf","join","pop","reverse","shift","sort","splice","unshift","push"].forEach(function(method){return JsPath[method+"At"]=function(){var obj,path,rest,target
obj=arguments[0],path=arguments[1],rest=3<=arguments.length?__slice.call(arguments,2):[]
target=JsPath.getAt(obj,path)
if("function"==typeof(null!=target?target[method]:void 0))return target[method].apply(target,rest)
throw new Error("Does not implement method "+method+" at "+path)}})
JsPath.getAt=function(ref,path){var prop
path="function"==typeof path.split?path.split("."):path.slice()
for(;null!=ref&&(prop=path.shift());)ref=ref[prop]
return ref}
JsPath.setAt=function(obj,path,val){var component,last,prev,ref
path="function"==typeof path.split?path.split("."):path.slice()
last=path.pop()
prev=[]
ref=obj
for(;component=path.shift();){if(primTypes.test(typeof ref[component]))throw new Error(""+prev.concat(component).join(".")+" is\nprimitive, and cannot be extended.")
ref=ref[component]||(ref[component]={})
prev.push(component)}ref[last]=val
return obj}
JsPath.assureAt=function(ref,path,initializer){var obj
if(obj=JsPath.getAt(ref,path))return obj
JsPath.setAt(ref,path,initializer)
return initializer}
JsPath.deleteAt=function(ref,path){var component,last,prev
path="function"==typeof path.split?path.split("."):path.slice()
prev=[]
last=path.pop()
for(;component=path.shift();){if(primTypes.test(typeof ref[component]))throw new Error(""+prev.concat(component).join(".")+" is\nprimitive; cannot drill any deeper.")
if(!(ref=ref[component]))return!1
prev.push(component)}return delete ref[last]}
return JsPath}.call(this)}.call(this)})
require.define("/node_modules/koding-dnode-protocol/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/koding-dnode-protocol/index.js",function(require,module,exports,__dirname,__filename,process){var DnodeScrubber,DnodeSession,DnodeStore,EventEmitter,Scrubber,createId,exports,getAt,json,parseArgs,setAt,stream,_ref,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EventEmitter=require("events").EventEmitter
_ref=require("jspath"),getAt=_ref.getAt,setAt=_ref.setAt
Scrubber=require("scrubber")
createId=require("hat").rack()
stream="browser"===process.title?{}:require("stream")
json="undefined"!=typeof JSON&&null!==JSON?JSON:require("jsonify")
exports=module.exports=function(wrapper){return{sessions:{},create:function(){var id
id=createId()
return this.sessions[id]=new DnodeSession(id,wrapper)},destroy:function(id){return delete this.sessions[id]}}}
exports.Session=DnodeSession=function(_super){function DnodeSession(id,wrapper){var _this=this
this.id=id
this.parse=__bind(this.parse,this)
this.remote={}
this.instance="function"==typeof wrapper?new wrapper(this.remote,this):wrapper||{}
this.localStore=new DnodeStore
this.remoteStore=new DnodeStore
this.localStore.on("cull",function(id){return _this.emit("request",{method:"cull",arguments:[id],callbacks:{}})})}var apply
__extends(DnodeSession,_super)
DnodeSession.prototype.start=function(){return this.request("methods",[this.instance])}
DnodeSession.prototype.request=function(method,args){var scrubber,_this=this
scrubber=new DnodeScrubber(this.localStore)
return scrubber.scrub(args,function(){var scrubbed
scrubbed=scrubber.toDnodeProtocol()
scrubbed.method=method
return _this.emit("request",scrubbed)})}
DnodeSession.prototype.parse=function(line){var err,msg
try{msg=json.parse(line)}catch(_error){err=_error
this.emit("error",new SyntaxError("JSON parsing error: "+err))}return this.handle(msg)}
DnodeSession.prototype.handle=function(msg){var args,method,scrubber,_this=this
scrubber=new DnodeScrubber(this.localStore)
args=scrubber.unscrub(msg,function(callbackId){_this.remoteStore.has(callbackId)||_this.remoteStore.add(callbackId,function(){return _this.request(callbackId,[].slice.call(arguments))})
return _this.remoteStore.get(callbackId)})
method=msg.method
switch(method){case"methods":return this.handleMethods(args[0])
case"error":return this.emit("remoteError",args[0])
case"cull":return args.forEach(function(id){return _this.remoteStore.cull(id)})
default:switch(typeof method){case"string":return this.instance.propertyIsEnumerable(method)?apply(this.instance[method],this.instance,args):this.emit("error",new Error("Request for non-enumerable method: "+method))
case"number":return apply(this.localStore.get(method),this.instance,args)}}}
DnodeSession.prototype.handleMethods=function(methods){var _this=this
null==methods&&(methods={})
Object.keys(this.remote).forEach(function(key){return delete _this.remote[key]})
Object.keys(methods).forEach(function(key){return _this.remote[key]=methods[key]})
this.emit("remote",this.remote)
return this.emit("ready")}
apply=function(fn,ctx,args){return fn.apply(ctx,args)}
return DnodeSession}(EventEmitter)
exports.Scrubber=DnodeScrubber=function(_super){function DnodeScrubber(store){var dnodeMutators,userStack
null==store&&(store=new DnodeStore)
this.paths={}
this.links=[]
dnodeMutators=[function(cursor){var i,id,node,path
node=cursor.node,path=cursor.path
if("function"==typeof node){i=store.indexOf(node)
if(!~i||i in this.paths){id=store.add(node)
this.paths[id]=path}else this.paths[i]=path
return cursor.update("[Function]",!0)}}]
userStack=DnodeScrubber.stack||[]
Scrubber.apply(this,dnodeMutators.concat(userStack))}__extends(DnodeScrubber,_super)
DnodeScrubber.prototype.unscrub=function(msg,getCallback){var args
args=msg.arguments||[]
Object.keys(msg.callbacks||{}).forEach(function(strId){var callback,id,path
id=parseInt(strId,10)
path=msg.callbacks[id]
callback=getCallback(id)
callback.id=id
return setAt(args,path,callback)});(msg.links||[]).forEach(function(link){return setAt(args,link.to,getAt(args,link.from))})
return args}
DnodeScrubber.prototype.toDnodeProtocol=function(){var out
out={arguments:this.out}
out.callbacks=this.paths
this.links.length&&(out.links=this.links)
return out}
return DnodeScrubber}(Scrubber)
exports.Store=DnodeStore=function(_super){function DnodeStore(){this.items=[]}var autoCull,wrap
__extends(DnodeStore,_super)
DnodeStore.prototype.has=function(id){return null!=this.items[id]}
DnodeStore.prototype.get=function(id){var item
item=this.items[id]
return null==item?null:wrap(item)}
DnodeStore.prototype.add=function(id,fn){var _ref1
fn||(_ref1=[id,fn],fn=_ref1[0],id=_ref1[1])
null==id&&(id=this.items.length)
this.items[id]=fn
return id}
DnodeStore.prototype.cull=function(arg){"function"==typeof arg&&(arg=this.items.indexOf(arg))
delete this.items[arg]
return arg}
DnodeStore.prototype.indexOf=function(fn){return this.items.indexOf(fn)}
wrap=function(fn){return function(){fn.apply(this,arguments)
return autoCull(fn)}}
autoCull=function(fn){var id
if("number"==typeof fn.times){fn.times--
if(0===fn.times){id=this.cull(fn)
return this.emit("cull",id)}}}
return DnodeStore}(EventEmitter)
parseArgs=exports.parseArgs=function(argv){var params
params={};[].slice.call(argv).forEach(function(arg){switch(typeof arg){case"string":return arg.match(/^\d+$/)?params.port=parseInt(arg,10):arg.match("^/")?params.path=arg:params.host=arg
case"number":return params.port=arg
case"function":return params.block=arg
case"object":return arg.__proto__===Object.prototype?Object.keys(arg).forEach(function(key){return params[key]=arg[key]}):stream.Stream&&arg instanceof stream.Stream?params.stream=arg:params.server=arg
case"undefined":break
default:throw new Error("Not sure what to do about "+typeof arg+" objects")}})
return params}})
require.define("events",function(require,module,exports,__dirname,__filename,process){process.EventEmitter||(process.EventEmitter=function(){})
var EventEmitter=exports.EventEmitter=process.EventEmitter,isArray="function"==typeof Array.isArray?Array.isArray:function(xs){return"[object Array]"===Object.prototype.toString.call(xs)},defaultMaxListeners=10
EventEmitter.prototype.setMaxListeners=function(n){this._events||(this._events={})
this._events.maxListeners=n}
EventEmitter.prototype.emit=function(type){if("error"===type&&(!this._events||!this._events.error||isArray(this._events.error)&&!this._events.error.length))throw arguments[1]instanceof Error?arguments[1]:new Error("Uncaught, unspecified 'error' event.")
if(!this._events)return!1
var handler=this._events[type]
if(!handler)return!1
if("function"==typeof handler){switch(arguments.length){case 1:handler.call(this)
break
case 2:handler.call(this,arguments[1])
break
case 3:handler.call(this,arguments[1],arguments[2])
break
default:var args=Array.prototype.slice.call(arguments,1)
handler.apply(this,args)}return!0}if(isArray(handler)){for(var args=Array.prototype.slice.call(arguments,1),listeners=handler.slice(),i=0,l=listeners.length;l>i;i++)listeners[i].apply(this,args)
return!0}return!1}
EventEmitter.prototype.addListener=function(type,listener){if("function"!=typeof listener)throw new Error("addListener only takes instances of Function")
this._events||(this._events={})
this.emit("newListener",type,listener)
if(this._events[type])if(isArray(this._events[type])){if(!this._events[type].warned){var m
m=void 0!==this._events.maxListeners?this._events.maxListeners:defaultMaxListeners
if(m&&m>0&&this._events[type].length>m){this._events[type].warned=!0
console.error("(node) warning: possible EventEmitter memory leak detected. %d listeners added. Use emitter.setMaxListeners() to increase limit.",this._events[type].length)
console.trace()}}this._events[type].push(listener)}else this._events[type]=[this._events[type],listener]
else this._events[type]=listener
return this}
EventEmitter.prototype.on=EventEmitter.prototype.addListener
EventEmitter.prototype.once=function(type,listener){var self=this
self.on(type,function g(){self.removeListener(type,g)
listener.apply(this,arguments)})
return this}
EventEmitter.prototype.removeListener=function(type,listener){if("function"!=typeof listener)throw new Error("removeListener only takes instances of Function")
if(!this._events||!this._events[type])return this
var list=this._events[type]
if(isArray(list)){var i=list.indexOf(listener)
if(0>i)return this
list.splice(i,1)
0==list.length&&delete this._events[type]}else this._events[type]===listener&&delete this._events[type]
return this}
EventEmitter.prototype.removeAllListeners=function(type){type&&this._events&&this._events[type]&&(this._events[type]=null)
return this}
EventEmitter.prototype.listeners=function(type){this._events||(this._events={})
this._events[type]||(this._events[type]=[])
isArray(this._events[type])||(this._events[type]=[this._events[type]])
return this._events[type]}})
require.define("/node_modules/scrubber/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/scrubber/index.js",function(require,module,exports,__dirname,__filename,process){var Scrubber,Traverse,daisy,global,slowDaisy,__slice=[].slice
Traverse=require("traverse")
global="undefined"!=typeof window&&null!==window?window:this
daisy=function(args){return process.nextTick(args.next=function(){var fn
return(fn=args.shift())?!!fn(args):void 0})}
slowDaisy=function(args){return console.log("it's a slow daisy",args)}
module.exports=Scrubber=function(){function Scrubber(){var middleware
middleware=1<=arguments.length?__slice.call(arguments,0):[]
this.stack="function"==typeof middleware[0]?middleware:middleware[0]}var seemsTooComplex
Scrubber.use=function(){var middleware
middleware=1<=arguments.length?__slice.call(arguments,0):[]
return this.stack=null==this.stack?middleware:this.stack.concat(middleware)}
Scrubber.prototype.scrub=function(obj,callback){var nodes,queue,scrubber,steps
scrubber=this
queue=[]
steps=this.stack.map(function(fn){switch(fn.length){case 0:case 1:return function(cursor,next){fn.call(this,cursor)
return next()}
case 2:return fn
default:throw new TypeError("Scrubber requires a callback with 1- or 2-arity. "+("User provided a "+fn.length+"-arity callback"))}})
nodes=[]
this.out=new Traverse(obj).map(function(){var cursor
cursor=this
steps.forEach(function(step){return queue.push(function(){return step.call(scrubber,cursor,function(){return queue.next()})})})})
queue.push(function(){return callback.call(scrubber)})
return daisy(queue)}
seemsTooComplex=function(){var f,i,maxStackSize
maxStackSize=function(){try{i=0
return(f=function(){i++
return f()})()}catch(e){return i}}()
return function(length,weight){var guess
guess=length*weight
return guess>maxStackSize}}();["forEach","indexOf","join","pop","reverse","shift","sort","splice","unshift","push"].forEach(function(method){return Scrubber.prototype[method]=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return this.stack[method].apply(this.stack,rest)}})
Scrubber.prototype.use=Scrubber.prototype.push
return Scrubber}.call(this)})
require.define("stream",function(require,module){function Stream(){events.EventEmitter.call(this)}var events=require("events"),util=require("util")
util.inherits(Stream,events.EventEmitter)
module.exports=Stream
Stream.Stream=Stream
Stream.prototype.pipe=function(dest,options){function ondata(chunk){dest.writable&&!1===dest.write(chunk)&&source.pause&&source.pause()}function ondrain(){source.readable&&source.resume&&source.resume()}function onend(){if(!didOnEnd){didOnEnd=!0
dest._pipeCount--
cleanup()
dest._pipeCount>0||dest.end()}}function onclose(){if(!didOnEnd){didOnEnd=!0
dest._pipeCount--
cleanup()
dest._pipeCount>0||dest.destroy()}}function onerror(er){cleanup()
if(0===this.listeners("error").length)throw er}function cleanup(){source.removeListener("data",ondata)
dest.removeListener("drain",ondrain)
source.removeListener("end",onend)
source.removeListener("close",onclose)
source.removeListener("error",onerror)
dest.removeListener("error",onerror)
source.removeListener("end",cleanup)
source.removeListener("close",cleanup)
dest.removeListener("end",cleanup)
dest.removeListener("close",cleanup)}var source=this
source.on("data",ondata)
dest.on("drain",ondrain)
if(!(dest._isStdio||options&&options.end===!1)){dest._pipeCount=dest._pipeCount||0
dest._pipeCount++
source.on("end",onend)
source.on("close",onclose)}var didOnEnd=!1
source.on("error",onerror)
dest.on("error",onerror)
source.on("end",cleanup)
source.on("close",cleanup)
dest.on("end",cleanup)
dest.on("close",cleanup)
dest.emit("pipe",source)
return dest}})
require.define("util",function(require,module,exports){function isArray(ar){return ar instanceof Array||Array.isArray(ar)||ar&&ar!==Object.prototype&&isArray(ar.__proto__)}function isRegExp(re){return re instanceof RegExp||"object"==typeof re&&"[object RegExp]"===Object.prototype.toString.call(re)}function isDate(d){if(d instanceof Date)return!0
if("object"!=typeof d)return!1
var properties=Date.prototype&&Object_getOwnPropertyNames(Date.prototype),proto=d.__proto__&&Object_getOwnPropertyNames(d.__proto__)
return JSON.stringify(proto)===JSON.stringify(properties)}require("events")
exports.print=function(){}
exports.puts=function(){}
exports.debug=function(){}
exports.inspect=function(obj,showHidden,depth,colors){function format(value,recurseTimes){if(value&&"function"==typeof value.inspect&&value!==exports&&(!value.constructor||value.constructor.prototype!==value))return value.inspect(recurseTimes)
switch(typeof value){case"undefined":return stylize("undefined","undefined")
case"string":var simple="'"+JSON.stringify(value).replace(/^"|"$/g,"").replace(/'/g,"\\'").replace(/\\"/g,'"')+"'"
return stylize(simple,"string")
case"number":return stylize(""+value,"number")
case"boolean":return stylize(""+value,"boolean")}if(null===value)return stylize("null","null")
var visible_keys=Object_keys(value),keys=showHidden?Object_getOwnPropertyNames(value):visible_keys
if("function"==typeof value&&0===keys.length){if(isRegExp(value))return stylize(""+value,"regexp")
var name=value.name?": "+value.name:""
return stylize("[Function"+name+"]","special")}if(isDate(value)&&0===keys.length)return stylize(value.toUTCString(),"date")
var base,type,braces
if(isArray(value)){type="Array"
braces=["[","]"]}else{type="Object"
braces=["{","}"]}if("function"==typeof value){var n=value.name?": "+value.name:""
base=isRegExp(value)?" "+value:" [Function"+n+"]"}else base=""
isDate(value)&&(base=" "+value.toUTCString())
if(0===keys.length)return braces[0]+base+braces[1]
if(0>recurseTimes)return isRegExp(value)?stylize(""+value,"regexp"):stylize("[Object]","special")
seen.push(value)
var output=keys.map(function(key){var name,str
value.__lookupGetter__&&(value.__lookupGetter__(key)?str=value.__lookupSetter__(key)?stylize("[Getter/Setter]","special"):stylize("[Getter]","special"):value.__lookupSetter__(key)&&(str=stylize("[Setter]","special")))
visible_keys.indexOf(key)<0&&(name="["+key+"]")
if(!str)if(seen.indexOf(value[key])<0){str=null===recurseTimes?format(value[key]):format(value[key],recurseTimes-1)
str.indexOf("\n")>-1&&(str=isArray(value)?str.split("\n").map(function(line){return"  "+line}).join("\n").substr(2):"\n"+str.split("\n").map(function(line){return"   "+line}).join("\n"))}else str=stylize("[Circular]","special")
if("undefined"==typeof name){if("Array"===type&&key.match(/^\d+$/))return str
name=JSON.stringify(""+key)
if(name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)){name=name.substr(1,name.length-2)
name=stylize(name,"name")}else{name=name.replace(/'/g,"\\'").replace(/\\"/g,'"').replace(/(^"|"$)/g,"'")
name=stylize(name,"string")}}return name+": "+str})
seen.pop()
var numLinesEst=0,length=output.reduce(function(prev,cur){numLinesEst++
cur.indexOf("\n")>=0&&numLinesEst++
return prev+cur.length+1},0)
output=length>50?braces[0]+(""===base?"":base+"\n ")+" "+output.join(",\n  ")+" "+braces[1]:braces[0]+base+" "+output.join(", ")+" "+braces[1]
return output}var seen=[],stylize=function(str,styleType){var styles={bold:[1,22],italic:[3,23],underline:[4,24],inverse:[7,27],white:[37,39],grey:[90,39],black:[30,39],blue:[34,39],cyan:[36,39],green:[32,39],magenta:[35,39],red:[31,39],yellow:[33,39]},style={special:"cyan",number:"blue","boolean":"yellow",undefined:"grey","null":"bold",string:"green",date:"magenta",regexp:"red"}[styleType]
return style?"["+styles[style][0]+"m"+str+"["+styles[style][1]+"m":str}
colors||(stylize=function(str){return str})
return format(obj,"undefined"==typeof depth?2:depth)}
exports.log=function(){}
exports.pump=null
var Object_keys=Object.keys||function(obj){var res=[]
for(var key in obj)res.push(key)
return res},Object_getOwnPropertyNames=Object.getOwnPropertyNames||function(obj){var res=[]
for(var key in obj)Object.hasOwnProperty.call(obj,key)&&res.push(key)
return res},Object_create=Object.create||function(prototype,properties){var object
if(null===prototype)object={__proto__:null}
else{if("object"!=typeof prototype)throw new TypeError("typeof prototype["+typeof prototype+"] != 'object'")
var Type=function(){}
Type.prototype=prototype
object=new Type
object.__proto__=prototype}"undefined"!=typeof properties&&Object.defineProperties&&Object.defineProperties(object,properties)
return object}
exports.inherits=function(ctor,superCtor){ctor.super_=superCtor
ctor.prototype=Object_create(superCtor.prototype,{constructor:{value:ctor,enumerable:!1,writable:!0,configurable:!0}})}})
require.define("/node_modules/jsonify/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/jsonify/index.js",function(require,module,exports){exports.parse=require("./lib/parse")
exports.stringify=require("./lib/stringify")})
require.define("/node_modules/jsonify/lib/parse.js",function(require,module){var at,ch,text,value,escapee={'"':'"',"\\":"\\","/":"/",b:"\b",f:"\f",n:"\n",r:"\r",t:"	"},error=function(m){throw{name:"SyntaxError",message:m,at:at,text:text}},next=function(c){c&&c!==ch&&error("Expected '"+c+"' instead of '"+ch+"'")
ch=text.charAt(at)
at+=1
return ch},number=function(){var number,string=""
if("-"===ch){string="-"
next("-")}for(;ch>="0"&&"9">=ch;){string+=ch
next()}if("."===ch){string+="."
for(;next()&&ch>="0"&&"9">=ch;)string+=ch}if("e"===ch||"E"===ch){string+=ch
next()
if("-"===ch||"+"===ch){string+=ch
next()}for(;ch>="0"&&"9">=ch;){string+=ch
next()}}number=+string
if(isFinite(number))return number
error("Bad number")
return void 0},string=function(){var hex,i,uffff,string=""
if('"'===ch)for(;next();){if('"'===ch){next()
return string}if("\\"===ch){next()
if("u"===ch){uffff=0
for(i=0;4>i;i+=1){hex=parseInt(next(),16)
if(!isFinite(hex))break
uffff=16*uffff+hex}string+=String.fromCharCode(uffff)}else{if("string"!=typeof escapee[ch])break
string+=escapee[ch]}}else string+=ch}error("Bad string")},white=function(){for(;ch&&" ">=ch;)next()},word=function(){switch(ch){case"t":next("t")
next("r")
next("u")
next("e")
return!0
case"f":next("f")
next("a")
next("l")
next("s")
next("e")
return!1
case"n":next("n")
next("u")
next("l")
next("l")
return null}error("Unexpected '"+ch+"'")},array=function(){var array=[]
if("["===ch){next("[")
white()
if("]"===ch){next("]")
return array}for(;ch;){array.push(value())
white()
if("]"===ch){next("]")
return array}next(",")
white()}}error("Bad array")},object=function(){var key,object={}
if("{"===ch){next("{")
white()
if("}"===ch){next("}")
return object}for(;ch;){key=string()
white()
next(":")
Object.hasOwnProperty.call(object,key)&&error('Duplicate key "'+key+'"')
object[key]=value()
white()
if("}"===ch){next("}")
return object}next(",")
white()}}error("Bad object")}
value=function(){white()
switch(ch){case"{":return object()
case"[":return array()
case'"':return string()
case"-":return number()
default:return ch>="0"&&"9">=ch?number():word()}}
module.exports=function(source,reviver){var result
text=source
at=0
ch=" "
result=value()
white()
ch&&error("Syntax error")
return"function"==typeof reviver?function walk(holder,key){var k,v,value=holder[key]
if(value&&"object"==typeof value)for(k in value)if(Object.prototype.hasOwnProperty.call(value,k)){v=walk(value,k)
void 0!==v?value[k]=v:delete value[k]}return reviver.call(holder,key,value)}({"":result},""):result}})
require.define("/node_modules/jsonify/lib/stringify.js",function(require,module){function quote(string){escapable.lastIndex=0
return escapable.test(string)?'"'+string.replace(escapable,function(a){var c=meta[a]
return"string"==typeof c?c:"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4)})+'"':'"'+string+'"'}function str(key,holder){var i,k,v,length,partial,mind=gap,value=holder[key]
value&&"object"==typeof value&&"function"==typeof value.toJSON&&(value=value.toJSON(key))
"function"==typeof rep&&(value=rep.call(holder,key,value))
switch(typeof value){case"string":return quote(value)
case"number":return isFinite(value)?String(value):"null"
case"boolean":case"null":return String(value)
case"object":if(!value)return"null"
gap+=indent
partial=[]
if("[object Array]"===Object.prototype.toString.apply(value)){length=value.length
for(i=0;length>i;i+=1)partial[i]=str(i,value)||"null"
v=0===partial.length?"[]":gap?"[\n"+gap+partial.join(",\n"+gap)+"\n"+mind+"]":"["+partial.join(",")+"]"
gap=mind
return v}if(rep&&"object"==typeof rep){length=rep.length
for(i=0;length>i;i+=1){k=rep[i]
if("string"==typeof k){v=str(k,value)
v&&partial.push(quote(k)+(gap?": ":":")+v)}}}else for(k in value)if(Object.prototype.hasOwnProperty.call(value,k)){v=str(k,value)
v&&partial.push(quote(k)+(gap?": ":":")+v)}v=0===partial.length?"{}":gap?"{\n"+gap+partial.join(",\n"+gap)+"\n"+mind+"}":"{"+partial.join(",")+"}"
gap=mind
return v}}var gap,indent,rep,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,meta={"\b":"\\b","	":"\\t","\n":"\\n","\f":"\\f","\r":"\\r",'"':'\\"',"\\":"\\\\"}
module.exports=function(value,replacer,space){var i
gap=""
indent=""
if("number"==typeof space)for(i=0;space>i;i+=1)indent+=" "
else"string"==typeof space&&(indent=space)
rep=replacer
if(replacer&&"function"!=typeof replacer&&("object"!=typeof replacer||"number"!=typeof replacer.length))throw new Error("JSON.stringify")
return str("",{"":value})}})
require.define("/node_modules_koding/bongo-client/src/scrubber.coffee",function(require,module){!function(){var BongoScrubber,Scrubber,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
Scrubber=require("koding-dnode-protocol").Scrubber
module.exports=BongoScrubber=function(_super){function BongoScrubber(){BongoScrubber.__super__.constructor.apply(this,arguments)
this.unshift(compensateForLatency)}var compensateForLatency,createFailHandler,error,noop
__extends(BongoScrubber,_super)
noop=function(){}
error=function(message){throw new Error(message)}
createFailHandler=function(fn){return function(){var err,rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
err=rest[0]
return null!=err?fn.apply(null,rest):void 0}}
compensateForLatency=function(cursor){var hasFailMethod,hasFinalizeMethod,node
node=cursor.node
if(node&&"object"==typeof node&&"compensate"in node){node.compensate()
hasFailMethod="fail"in node
hasFinalizeMethod="finalize"in node
hasFinalizeMethod&&hasFailMethod&&error("Provide a handler only for finalize, or fail, not both")
return hasFailMethod?cursor.update(createFailHandler(node.fail)):hasFinalizeMethod?cursor.update(node.finalize):cursor.update(noop)}}
return BongoScrubber}(Scrubber)}.call(this)})
require.define("/node_modules_koding/bongo-client/src/model.coffee",function(require,module){!function(){"use strict"
var EventEmitter,Model,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EventEmitter=require("microemitter").EventEmitter
module.exports=Model=function(_super){function Model(){return Model.__super__.constructor.apply(this,arguments)}var EventMultiplexer,JsPath,MongoOp,createId,extend
__extends(Model,_super)
MongoOp=require("mongoop")
JsPath=require("jspath")
EventMultiplexer=require("./eventmultiplexer")
createId=Model.createId=require("hat")
extend=require("./util").extend
Model.isOpaque=function(){return!1}
Model.streamModels=function(selector,options,callback){var ids
if(!("each"in this))throw new Error("streamModels depends on Model#each, but cursor was not found!\n(Hint: it may not be whitelisted)")
ids=[]
return this.each(selector,options,function(err,model){if(err)return callback(err)
if(null!=model){ids.push("function"==typeof model.getId?model.getId():void 0)
return callback(err,[model])}return callback(null,null,ids)})}
Model.prototype.mixin=Model.mixin=function(source){var key,val,_results
_results=[]
for(key in source){val=source[key]
"constructor"!==key&&_results.push(this[key]=val)}return _results}
Model.prototype.watch=function(field,watcher){var _base;(_base=this.watchers)[field]||(_base[field]=[])
return this.watchers[field].push(watcher)}
Model.prototype.unwatch=function(field,watcher){var index
if(!watcher)return delete this.watchers[field]
index=this.watchers.indexOf(watcher)
return~index?this.watchers.splice(index,1):void 0}
Model.prototype.init=function(data){var model,_this=this
model=this
model.watchers={}
model.bongo_||(model.bongo_={})
null!=data&&model.set(data)
"instanceId"in model.bongo_||(model.bongo_.instanceId=createId())
this.emit("init")
return this.on("updateInstance",function(data){return _this.update_(data)})}
Model.prototype.set=function(data){var model
null==data&&(data={})
model=this
delete data.data
extend(model,data)
return model}
Model.prototype.getFlagValue=function(flagName){var _ref
return null!=(_ref=this.flags_)?_ref[flagName]:void 0}
Model.prototype.watchFlagValue=function(flagName,callback){return this.watch("flags_."+flagName,callback)}
Model.prototype.unwatchFlagValue=function(flagName){return this.unwatch("flags_."+flagName)}
Model.prototype.getAt=function(path){return JsPath.getAt(this,path)}
Model.prototype.setAt=function(path,value){return JsPath.setAt(this,path,value)}
Model.prototype.getId=function(){return this._id}
Model.prototype.getSubscribable=function(){var subscribable
subscribable=this.bongo_.subscribable
return null!=subscribable?subscribable:!0}
Model.prototype.equals=function(model){return this.getId&&(null!=model?model.getId:void 0)?this.getId()===model.getId():this===model}
Model.prototype.valueOf=function(){var _ref
return null!=(_ref="function"==typeof this.getValue?this.getValue():void 0)?_ref:this}
Model.prototype.save=function(callback){var model
model=this
return model.save_(function(err,docs){if(err)return callback(err)
extend(model,docs[0])
bongo.addReferences(model)
return callback(null,docs)})}
Model.prototype.update_=function(data){var fields,_this=this
fields=new MongoOp(data).applyTo(this)
Object.keys(fields).forEach(function(field){var _ref
return null!=(_ref=_this.watchers[field])?_ref.forEach(function(watcher){return watcher.call(_this,fields[field])}):void 0})
return this.emit("update")}
Model.prototype.addListener=Model.prototype.on
Model.prototype.removeListener=Model.prototype.off
return Model}(EventEmitter)}.call(this)})
require.define("/node_modules/mongoop/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/mongoop/index.js",function(require,module){!function(){var MongoOp,__slice=[].slice
MongoOp=function(){function MongoOp(operation){if(!(this instanceof MongoOp))return new MongoOp(operation)
this.operation=operation
return void 0}var JsPath,deleteAt,getAt,isEqual,keys,popAt,pushAt,setAt,_
if("undefined"!=typeof require&&null!==require&&"undefined"!=typeof module&&null!==module){("undefined"==typeof JsPath||null===JsPath)&&(JsPath=require("jspath"));("undefined"==typeof _||null===_)&&(_=require("underscore"))}else _=window._,JsPath=window.JsPath
isEqual=_.isEqual
setAt=JsPath.setAt,getAt=JsPath.getAt,deleteAt=JsPath.deleteAt,pushAt=JsPath.pushAt,popAt=JsPath.popAt
keys=Object.keys
MongoOp.prototype.applyTo=function(target){var _this=this
this.result={}
keys(this.operation).forEach(function(operator){if("function"!=typeof _this[operator])throw new Error("Unrecognized operator: "+operator)
return _this[operator](target,_this.operation[operator])})
return this}
MongoOp.prototype.forEachField=function(fields,fn){var _this=this
return keys(fields).map(function(path){var val
val=fields[path]
return _this.result[path]=fn(path,val)})}
MongoOp.prototype.$addToSet=function(){var $addToSet
$addToSet=function(collection,val){var item,matchFound,_i,_len
matchFound=!1
for(_i=0,_len=collection.length;_len>_i;_i++){item=collection[_i]
if(isEqual(item,val)){matchFound=!0
break}}return matchFound?void 0:collection.push(val)}
return function(target,fields){return this.forEachField(fields,function(path,val){var child,collection,_i,_len,_ref,_results
collection=getAt(target,path)
if(null==collection){collection=[]
setAt(target,path,collection)}if(null!=val.$each){_ref=val.$each
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){child=_ref[_i]
_results.push($addToSet(collection,child))}return _results}return $addToSet(collection,val)})}}()
MongoOp.prototype.$push=function(target,fields){return this.forEachField(fields,function(path,val){return pushAt(target,path,val)})}
MongoOp.prototype.$pushAll=function(target,fields){return this.forEachField(fields,function(path,vals){return pushAt.apply(null,[target,path].concat(__slice.call(vals)))})}
MongoOp.prototype.$pull=function(){throw new Error("This version of MongoOp does not implement $pull...\nLook for that in a future version.  You can use $pullAll instead.")}
MongoOp.prototype.$pullAll=function(target,fields){return this.forEachField(fields,function(path,val){var collection,i,index,_results
collection=getAt(target,path)
index=0
_results=[]
for(;collection&&index<collection.length;){i=index++
isEqual(collection[i],val)?_results.push(collection.splice(i,1)):_results.push(void 0)}return _results})}
MongoOp.prototype.$pop=function(target,fields){return this.forEachField(fields,function(path){return popAt(target,path)})}
MongoOp.prototype.$set=function(target,fields){return this.forEachField(fields,function(path,val){setAt(target,path,val)
return val})}
MongoOp.prototype.$unset=function(target,fields){return this.forEachField(fields,function(path){return deleteAt(target,path)})}
MongoOp.prototype.$rename=function(target,fields){return this.forEachField(fields,function(oldPath,newPath){var val
val=getAt(target,oldPath)
deleteAt(target,oldPath)
return setAt(target,newPath,val)})}
MongoOp.prototype.$inc=function(){var $inc
$inc=function(val,amt){return val+=amt}
return function(target,fields){return this.forEachField(fields,function(path,val){return setAt(target,path,$inc(getAt(target,path),val))})}}()
return MongoOp}()
null!=("undefined"!=typeof module&&null!==module?module.exports:void 0)?module.exports=MongoOp:"undefined"!=typeof window&&null!==window&&(window.MongoOp=MongoOp)}.call(this)})
require.define("/node_modules/underscore/package.json",function(require,module){module.exports={main:"underscore.js"}})
require.define("/node_modules/underscore/underscore.js",function(require,module,exports){!function(){function eq(a,b,stack){if(a===b)return 0!==a||1/a==1/b
if(null==a||null==b)return a===b
a._chain&&(a=a._wrapped)
b._chain&&(b=b._wrapped)
if(a.isEqual&&_.isFunction(a.isEqual))return a.isEqual(b)
if(b.isEqual&&_.isFunction(b.isEqual))return b.isEqual(a)
var className=toString.call(a)
if(className!=toString.call(b))return!1
switch(className){case"[object String]":return a==String(b)
case"[object Number]":return a!=+a?b!=+b:0==a?1/a==1/b:a==+b
case"[object Date]":case"[object Boolean]":return+a==+b
case"[object RegExp]":return a.source==b.source&&a.global==b.global&&a.multiline==b.multiline&&a.ignoreCase==b.ignoreCase}if("object"!=typeof a||"object"!=typeof b)return!1
for(var length=stack.length;length--;)if(stack[length]==a)return!0
stack.push(a)
var size=0,result=!0
if("[object Array]"==className){size=a.length
result=size==b.length
if(result)for(;size--&&(result=size in a==size in b&&eq(a[size],b[size],stack)););}else{if("constructor"in a!="constructor"in b||a.constructor!=b.constructor)return!1
for(var key in a)if(hasOwnProperty.call(a,key)){size++
if(!(result=hasOwnProperty.call(b,key)&&eq(a[key],b[key],stack)))break}if(result){for(key in b)if(hasOwnProperty.call(b,key)&&!size--)break
result=!size}}stack.pop()
return result}var root=this,previousUnderscore=root._,breaker={},ArrayProto=Array.prototype,ObjProto=Object.prototype,FuncProto=Function.prototype,slice=ArrayProto.slice,concat=ArrayProto.concat,unshift=ArrayProto.unshift,toString=ObjProto.toString,hasOwnProperty=ObjProto.hasOwnProperty,nativeForEach=ArrayProto.forEach,nativeMap=ArrayProto.map,nativeReduce=ArrayProto.reduce,nativeReduceRight=ArrayProto.reduceRight,nativeFilter=ArrayProto.filter,nativeEvery=ArrayProto.every,nativeSome=ArrayProto.some,nativeIndexOf=ArrayProto.indexOf,nativeLastIndexOf=ArrayProto.lastIndexOf,nativeIsArray=Array.isArray,nativeKeys=Object.keys,nativeBind=FuncProto.bind,_=function(obj){return new wrapper(obj)}
if("undefined"!=typeof exports){"undefined"!=typeof module&&module.exports&&(exports=module.exports=_)
exports._=_}else"function"==typeof define&&define.amd?define("underscore",function(){return _}):root._=_
_.VERSION="1.2.3"
var each=_.each=_.forEach=function(obj,iterator,context){if(null!=obj)if(nativeForEach&&obj.forEach===nativeForEach)obj.forEach(iterator,context)
else if(obj.length===+obj.length){for(var i=0,l=obj.length;l>i;i++)if(i in obj&&iterator.call(context,obj[i],i,obj)===breaker)return}else for(var key in obj)if(hasOwnProperty.call(obj,key)&&iterator.call(context,obj[key],key,obj)===breaker)return}
_.map=function(obj,iterator,context){var results=[]
if(null==obj)return results
if(nativeMap&&obj.map===nativeMap)return obj.map(iterator,context)
each(obj,function(value,index,list){results[results.length]=iterator.call(context,value,index,list)})
return results}
_.reduce=_.foldl=_.inject=function(obj,iterator,memo,context){var initial=arguments.length>2
null==obj&&(obj=[])
if(nativeReduce&&obj.reduce===nativeReduce){context&&(iterator=_.bind(iterator,context))
return initial?obj.reduce(iterator,memo):obj.reduce(iterator)}each(obj,function(value,index,list){if(initial)memo=iterator.call(context,memo,value,index,list)
else{memo=value
initial=!0}})
if(!initial)throw new TypeError("Reduce of empty array with no initial value")
return memo}
_.reduceRight=_.foldr=function(obj,iterator,memo,context){var initial=arguments.length>2
null==obj&&(obj=[])
if(nativeReduceRight&&obj.reduceRight===nativeReduceRight){context&&(iterator=_.bind(iterator,context))
return initial?obj.reduceRight(iterator,memo):obj.reduceRight(iterator)}var reversed=_.toArray(obj).reverse()
context&&!initial&&(iterator=_.bind(iterator,context))
return initial?_.reduce(reversed,iterator,memo,context):_.reduce(reversed,iterator)}
_.find=_.detect=function(obj,iterator,context){var result
any(obj,function(value,index,list){if(iterator.call(context,value,index,list)){result=value
return!0}})
return result}
_.filter=_.select=function(obj,iterator,context){var results=[]
if(null==obj)return results
if(nativeFilter&&obj.filter===nativeFilter)return obj.filter(iterator,context)
each(obj,function(value,index,list){iterator.call(context,value,index,list)&&(results[results.length]=value)})
return results}
_.reject=function(obj,iterator,context){var results=[]
if(null==obj)return results
each(obj,function(value,index,list){iterator.call(context,value,index,list)||(results[results.length]=value)})
return results}
_.every=_.all=function(obj,iterator,context){var result=!0
if(null==obj)return result
if(nativeEvery&&obj.every===nativeEvery)return obj.every(iterator,context)
each(obj,function(value,index,list){return(result=result&&iterator.call(context,value,index,list))?void 0:breaker})
return result}
var any=_.some=_.any=function(obj,iterator,context){iterator||(iterator=_.identity)
var result=!1
if(null==obj)return result
if(nativeSome&&obj.some===nativeSome)return obj.some(iterator,context)
each(obj,function(value,index,list){return result||(result=iterator.call(context,value,index,list))?breaker:void 0})
return!!result}
_.include=_.contains=function(obj,target){var found=!1
if(null==obj)return found
if(nativeIndexOf&&obj.indexOf===nativeIndexOf)return-1!=obj.indexOf(target)
found=any(obj,function(value){return value===target})
return found}
_.invoke=function(obj,method){var args=slice.call(arguments,2)
return _.map(obj,function(value){return(method.call?method||value:value[method]).apply(value,args)})}
_.pluck=function(obj,key){return _.map(obj,function(value){return value[key]})}
_.max=function(obj,iterator,context){if(!iterator&&_.isArray(obj))return Math.max.apply(Math,obj)
if(!iterator&&_.isEmpty(obj))return-1/0
var result={computed:-1/0}
each(obj,function(value,index,list){var computed=iterator?iterator.call(context,value,index,list):value
computed>=result.computed&&(result={value:value,computed:computed})})
return result.value}
_.min=function(obj,iterator,context){if(!iterator&&_.isArray(obj))return Math.min.apply(Math,obj)
if(!iterator&&_.isEmpty(obj))return 1/0
var result={computed:1/0}
each(obj,function(value,index,list){var computed=iterator?iterator.call(context,value,index,list):value
computed<result.computed&&(result={value:value,computed:computed})})
return result.value}
_.shuffle=function(obj){var rand,shuffled=[]
each(obj,function(value,index){if(0==index)shuffled[0]=value
else{rand=Math.floor(Math.random()*(index+1))
shuffled[index]=shuffled[rand]
shuffled[rand]=value}})
return shuffled}
_.sortBy=function(obj,iterator,context){return _.pluck(_.map(obj,function(value,index,list){return{value:value,criteria:iterator.call(context,value,index,list)}}).sort(function(left,right){var a=left.criteria,b=right.criteria
return b>a?-1:a>b?1:0}),"value")}
_.groupBy=function(obj,val){var result={},iterator=_.isFunction(val)?val:function(obj){return obj[val]}
each(obj,function(value,index){var key=iterator(value,index);(result[key]||(result[key]=[])).push(value)})
return result}
_.sortedIndex=function(array,obj,iterator){iterator||(iterator=_.identity)
for(var low=0,high=array.length;high>low;){var mid=low+high>>1
iterator(array[mid])<iterator(obj)?low=mid+1:high=mid}return low}
_.toArray=function(iterable){return iterable?iterable.toArray?iterable.toArray():_.isArray(iterable)?slice.call(iterable):_.isArguments(iterable)?slice.call(iterable):_.values(iterable):[]}
_.size=function(obj){return _.toArray(obj).length}
_.first=_.head=function(array,n,guard){return null==n||guard?array[0]:slice.call(array,0,n)}
_.initial=function(array,n,guard){return slice.call(array,0,array.length-(null==n||guard?1:n))}
_.last=function(array,n,guard){return null==n||guard?array[array.length-1]:slice.call(array,Math.max(array.length-n,0))}
_.rest=_.tail=function(array,index,guard){return slice.call(array,null==index||guard?1:index)}
_.compact=function(array){return _.filter(array,function(value){return!!value})}
_.flatten=function(array,shallow){return _.reduce(array,function(memo,value){if(_.isArray(value))return memo.concat(shallow?value:_.flatten(value))
memo[memo.length]=value
return memo},[])}
_.without=function(array){return _.difference(array,slice.call(arguments,1))}
_.uniq=_.unique=function(array,isSorted,iterator){var initial=iterator?_.map(array,iterator):array,result=[]
_.reduce(initial,function(memo,el,i){if(0==i||(isSorted===!0?_.last(memo)!=el:!_.include(memo,el))){memo[memo.length]=el
result[result.length]=array[i]}return memo},[])
return result}
_.union=function(){return _.uniq(_.flatten(arguments,!0))}
_.intersection=_.intersect=function(array){var rest=slice.call(arguments,1)
return _.filter(_.uniq(array),function(item){return _.every(rest,function(other){return _.indexOf(other,item)>=0})})}
_.difference=function(array){var rest=_.flatten(slice.call(arguments,1))
return _.filter(array,function(value){return!_.include(rest,value)})}
_.zip=function(){for(var args=slice.call(arguments),length=_.max(_.pluck(args,"length")),results=new Array(length),i=0;length>i;i++)results[i]=_.pluck(args,""+i)
return results}
_.indexOf=function(array,item,isSorted){if(null==array)return-1
var i,l
if(isSorted){i=_.sortedIndex(array,item)
return array[i]===item?i:-1}if(nativeIndexOf&&array.indexOf===nativeIndexOf)return array.indexOf(item)
for(i=0,l=array.length;l>i;i++)if(i in array&&array[i]===item)return i
return-1}
_.lastIndexOf=function(array,item){if(null==array)return-1
if(nativeLastIndexOf&&array.lastIndexOf===nativeLastIndexOf)return array.lastIndexOf(item)
for(var i=array.length;i--;)if(i in array&&array[i]===item)return i
return-1}
_.range=function(start,stop,step){if(arguments.length<=1){stop=start||0
start=0}step=arguments[2]||1
for(var len=Math.max(Math.ceil((stop-start)/step),0),idx=0,range=new Array(len);len>idx;){range[idx++]=start
start+=step}return range}
var ctor=function(){}
_.bind=function(func,context){var bound,args
if(func.bind===nativeBind&&nativeBind)return nativeBind.apply(func,slice.call(arguments,1))
if(!_.isFunction(func))throw new TypeError
args=slice.call(arguments,2)
return bound=function(){if(!(this instanceof bound))return func.apply(context,args.concat(slice.call(arguments)))
ctor.prototype=func.prototype
var self=new ctor,result=func.apply(self,args.concat(slice.call(arguments)))
return Object(result)===result?result:self}}
_.bindAll=function(obj){var funcs=slice.call(arguments,1)
0==funcs.length&&(funcs=_.functions(obj))
each(funcs,function(f){obj[f]=_.bind(obj[f],obj)})
return obj}
_.memoize=function(func,hasher){var memo={}
hasher||(hasher=_.identity)
return function(){var key=hasher.apply(this,arguments)
return hasOwnProperty.call(memo,key)?memo[key]:memo[key]=func.apply(this,arguments)}}
_.delay=function(func,wait){var args=slice.call(arguments,2)
return setTimeout(function(){return func.apply(func,args)},wait)}
_.defer=function(func){return _.delay.apply(_,[func,1].concat(slice.call(arguments,1)))}
_.throttle=function(func,wait){var context,args,timeout,throttling,more,whenDone=_.debounce(function(){more=throttling=!1},wait)
return function(){context=this
args=arguments
var later=function(){timeout=null
more&&func.apply(context,args)
whenDone()}
timeout||(timeout=setTimeout(later,wait))
throttling?more=!0:func.apply(context,args)
whenDone()
throttling=!0}}
_.debounce=function(func,wait){var timeout
return function(){var context=this,args=arguments,later=function(){timeout=null
func.apply(context,args)}
clearTimeout(timeout)
timeout=setTimeout(later,wait)}}
_.once=function(func){var memo,ran=!1
return function(){if(ran)return memo
ran=!0
return memo=func.apply(this,arguments)}}
_.wrap=function(func,wrapper){return function(){var args=concat.apply([func],arguments)
return wrapper.apply(this,args)}}
_.compose=function(){var funcs=arguments
return function(){for(var args=arguments,i=funcs.length-1;i>=0;i--)args=[funcs[i].apply(this,args)]
return args[0]}}
_.after=function(times,func){return 0>=times?func():function(){return--times<1?func.apply(this,arguments):void 0}}
_.keys=nativeKeys||function(obj){if(obj!==Object(obj))throw new TypeError("Invalid object")
var keys=[]
for(var key in obj)hasOwnProperty.call(obj,key)&&(keys[keys.length]=key)
return keys}
_.values=function(obj){return _.map(obj,_.identity)}
_.functions=_.methods=function(obj){var names=[]
for(var key in obj)_.isFunction(obj[key])&&names.push(key)
return names.sort()}
_.extend=function(obj){each(slice.call(arguments,1),function(source){for(var prop in source)void 0!==source[prop]&&(obj[prop]=source[prop])})
return obj}
_.defaults=function(obj){each(slice.call(arguments,1),function(source){for(var prop in source)null==obj[prop]&&(obj[prop]=source[prop])})
return obj}
_.clone=function(obj){return _.isObject(obj)?_.isArray(obj)?obj.slice():_.extend({},obj):obj}
_.tap=function(obj,interceptor){interceptor(obj)
return obj}
_.isEqual=function(a,b){return eq(a,b,[])}
_.isEmpty=function(obj){if(_.isArray(obj)||_.isString(obj))return 0===obj.length
for(var key in obj)if(hasOwnProperty.call(obj,key))return!1
return!0}
_.isElement=function(obj){return!(!obj||1!=obj.nodeType)}
_.isArray=nativeIsArray||function(obj){return"[object Array]"==toString.call(obj)}
_.isObject=function(obj){return obj===Object(obj)}
_.isArguments=function(obj){return"[object Arguments]"==toString.call(obj)}
_.isArguments(arguments)||(_.isArguments=function(obj){return!(!obj||!hasOwnProperty.call(obj,"callee"))})
_.isFunction=function(obj){return"[object Function]"==toString.call(obj)}
_.isString=function(obj){return"[object String]"==toString.call(obj)}
_.isNumber=function(obj){return"[object Number]"==toString.call(obj)}
_.isNaN=function(obj){return obj!==obj}
_.isBoolean=function(obj){return obj===!0||obj===!1||"[object Boolean]"==toString.call(obj)}
_.isDate=function(obj){return"[object Date]"==toString.call(obj)}
_.isRegExp=function(obj){return"[object RegExp]"==toString.call(obj)}
_.isNull=function(obj){return null===obj}
_.isUndefined=function(obj){return void 0===obj}
_.noConflict=function(){root._=previousUnderscore
return this}
_.identity=function(value){return value}
_.times=function(n,iterator,context){for(var i=0;n>i;i++)iterator.call(context,i)}
_.escape=function(string){return(""+string).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#x27;").replace(/\//g,"&#x2F;")}
_.mixin=function(obj){each(_.functions(obj),function(name){addToWrapper(name,_[name]=obj[name])})}
var idCounter=0
_.uniqueId=function(prefix){var id=idCounter++
return prefix?prefix+id:id}
_.templateSettings={evaluate:/<%([\s\S]+?)%>/g,interpolate:/<%=([\s\S]+?)%>/g,escape:/<%-([\s\S]+?)%>/g}
_.template=function(str,data){var c=_.templateSettings,tmpl="var __p=[],print=function(){__p.push.apply(__p,arguments);};with(obj||{}){__p.push('"+str.replace(/\\/g,"\\\\").replace(/'/g,"\\'").replace(c.escape,function(match,code){return"',_.escape("+code.replace(/\\'/g,"'")+"),'"}).replace(c.interpolate,function(match,code){return"',"+code.replace(/\\'/g,"'")+",'"}).replace(c.evaluate||null,function(match,code){return"');"+code.replace(/\\'/g,"'").replace(/[\r\n\t]/g," ")+";__p.push('"}).replace(/\r/g,"\\r").replace(/\n/g,"\\n").replace(/\t/g,"\\t")+"');}return __p.join('');",func=new Function("obj","_",tmpl)
return data?func(data,_):function(data){return func.call(this,data,_)}}
var wrapper=function(obj){this._wrapped=obj}
_.prototype=wrapper.prototype
var result=function(obj,chain){return chain?_(obj).chain():obj},addToWrapper=function(name,func){wrapper.prototype[name]=function(){var args=slice.call(arguments)
unshift.call(args,this._wrapped)
return result(func.apply(_,args),this._chain)}}
_.mixin(_)
each(["pop","push","reverse","shift","sort","splice","unshift"],function(name){var method=ArrayProto[name]
wrapper.prototype[name]=function(){method.apply(this._wrapped,arguments)
return result(this._wrapped,this._chain)}})
each(["concat","join","slice"],function(name){var method=ArrayProto[name]
wrapper.prototype[name]=function(){return result(method.apply(this._wrapped,arguments),this._chain)}})
wrapper.prototype.chain=function(){this._chain=!0
return this}
wrapper.prototype.value=function(){return this._wrapped}}.call(this)})
require.define("/node_modules_koding/bongo-client/src/eventmultiplexer.coffee",function(require,module){!function(){"use strict"
var EventMultiplexer,slice
slice=[].slice
module.exports=EventMultiplexer=function(){function EventMultiplexer(context){this.context=context
this.events={}}EventMultiplexer.prototype.on=function(event,listener){var isNew,multiplex,multiplexer
multiplexer=this
multiplex=multiplexer.events[event]
if(null==multiplex){isNew=!0
multiplex=multiplexer.events[event]=function(){var _i,_len,_ref
_ref=multiplex.listeners
for(_i=0,_len=_ref.length;_len>_i;_i++){listener=_ref[_i]
listener.apply(multiplexer.context,slice.call(arguments))}}
multiplex.listeners=[]}multiplex.listeners.push(listener)
return isNew?multiplex:void 0}
EventMultiplexer.prototype.off=function(event,listenerToRemove){var index,listener,multiplex,multiplexer,_i,_len,_ref
multiplexer=this
multiplex=multiplexer.events[event]
if(multiplex){_ref=multiplex.listeners
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){listener=_ref[index]
listener===listenerToRemove&&multiplex.listeners.splice(index,1)}return multiplex.listeners.length}return-1}
return EventMultiplexer}()}.call(this)})
require.define("/node_modules_koding/bongo-client/src/util.coffee",function(require,module){!function(){"use strict"
var __slice=[].slice
module.exports={extend:function(){var key,obj,rest,source,val,_i,_len
obj=arguments[0],rest=2<=arguments.length?__slice.call(arguments,1):[]
for(_i=0,_len=rest.length;_len>_i;_i++){source=rest[_i]
for(key in source){val=source[key]
obj[key]=val}}return obj},asynchronizeOwnMethods:function(ofObject){var result
result={}
Object.keys(ofObject).forEach(function(key){var fn
return"function"==typeof(fn=ofObject[key])?result[key]=function(){var callback,rest,_i
rest=2<=arguments.length?__slice.call(arguments,0,_i=arguments.length-1):(_i=0,[]),callback=arguments[_i++]
return callback(fn.apply(null,rest))}:void 0})
return result}}}.call(this)})
require.define("/node_modules_koding/bongo-client/src/listenertree.coffee",function(require,module){!function(){"use strict"
var ListenerTree,__slice=[].slice
module.exports=ListenerTree=function(){function ListenerTree(){this.tree=Object.create(null)}var assureAt,getAt,pushAt,_ref
_ref=require("jspath"),assureAt=_ref.assureAt,pushAt=_ref.pushAt,getAt=_ref.getAt
ListenerTree.prototype.on=function(routingKey,listener){assureAt(this.tree,routingKey,[])
pushAt(this.tree,routingKey,listener)
return this}
ListenerTree.prototype.off=function(){console.log("ListenerTree#off is still unimplemented.")
return this}
ListenerTree.prototype.emit=function(){var listener,listeners,rest,routingKey,_i,_len
routingKey=arguments[0],rest=2<=arguments.length?__slice.call(arguments,1):[]
listeners=getAt(this.tree,routingKey)
if(null!=listeners?listeners.length:void 0)for(_i=0,_len=listeners.length;_len>_i;_i++){listener=listeners[_i]
listener.apply(null,rest)}return this}
return ListenerTree}()}.call(this)})
require.define("/node_modules_koding/bongo-client/src/eventbus.coffee",function(require,module){!function(){"use strict"
var EventBus
module.exports=EventBus=function(){function EventBus(mq){this.mq=mq
this.tree=new ListenerTree
this.channels={}
this.counts={}}var ListenerTree,getGenericInstanceRoutingKey,getGenericStaticRoutingKey,getInstanceRoutingKey,getStaticRoutingKey
ListenerTree=require("./listenertree")
EventBus.prototype.bound=require("koding-bound")
EventBus.prototype.dispatch=function(routingKey,payload){return this.tree.emit(routingKey,payload)}
EventBus.prototype.addListener=function(getGenericRoutingKey,getRoutingKey,name,event,listener){var channel,genericRoutingKey
if(null==this.channels[name]){this.counts[name]=0
genericRoutingKey=getGenericRoutingKey(name)
channel=this.channels[name]=this.mq.subscribe(genericRoutingKey,{isReadOnly:!0})}else channel=this.channels[name]
channel.isListeningTo(event)||channel.on(event,this.dispatch.bind(this,getRoutingKey(name,event)))
this.counts[name]++
return this.tree.on(getRoutingKey(name,event),listener)}
EventBus.prototype.removeListener=function(getRoutingKey,name,event,listener){var channel
if(0===--this.counts[name]){channel=this.channels[name]
channel.close()
delete this.channels[name]}return this.tree.off(getRoutingKey(name,event),listener)}
getStaticRoutingKey=function(constructorName,event){return"constructor."+constructorName+".event."+event}
getGenericStaticRoutingKey=function(constructorName){return"constructor."+constructorName+".event"}
EventBus.prototype.staticOn=function(konstructor,event,listener){return this.addListener(getGenericStaticRoutingKey,getStaticRoutingKey,konstructor.name,event,listener)}
EventBus.prototype.staticOff=function(konstructor,event,listener){return this.removeListener(getStaticRoutingKey,konstructor.name,event,listener)}
getInstanceRoutingKey=function(oid,event){return"oid."+oid+".event."+event}
getGenericInstanceRoutingKey=function(oid){return"oid."+oid+".event"}
EventBus.prototype.on=function(inst,event,listener){return inst.getSubscribable()?this.addListener(getGenericInstanceRoutingKey,getInstanceRoutingKey,inst.getId(),event,listener):void 0}
EventBus.prototype.off=function(inst,event,listener){return this.removeListener(getInstanceRoutingKey,inst.getId(),event,listener)}
return EventBus}()}.call(this)})
require.define("/node_modules/koding-bound/package.json",function(require,module){module.exports={main:"index.js"}})
require.define("/node_modules/koding-bound/index.js",function(require,module){module.exports=require("./lib/koding-bound")})
require.define("/node_modules/koding-bound/lib/koding-bound/index.js",function(require,module){module.exports=function(method){var boundMethod
if(null==this[method])throw new Error("@bound: unknown method! "+method)
boundMethod="__bound__"+method
boundMethod in this||Object.defineProperty(this,boundMethod,{value:this[method].bind(this)})
return this[boundMethod]}})
require.define("/node_modules_koding/bongo-client/src/opaquetype.coffee",function(require,module){!function(){var OpaqueType,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
module.exports=OpaqueType=function(){function OpaqueType(type){var konstructor
konstructor=Function("return function "+type+"() {}")()
__extends(konstructor,OpaqueType)
return konstructor}OpaqueType.isOpaque=function(){return!0}
return OpaqueType}()}.call(this)})
require.define("/node_modules_koding/bongo-client/src/eventemitter/broker.coffee",function(require,module){!function(){"use strict"
module.exports=function(){var defineProperty,getPusherEvent
getPusherEvent=function(event){return Array.isArray(event)?event=event.join(":"):event}
defineProperty=Object.defineProperty
return{destroy:function(){return null!=this.channel?this.mq.unsubscribe(this.channel):void 0},removeListener:function(event,listener){this.emit("listenerRemoved",event,listener)
return this.constructor.prototype.removeListener.call(event,listener)}}}()}.call(this)})
require.define("/node_modules/sinkrow/package.json",function(require,module){module.exports={main:"lib/sinkrow/index.js"}})
require.define("/node_modules/sinkrow/lib/sinkrow/index.js",function(require,module,exports,__dirname,__filename,process){this.sequence=require("./sequence")
this.race=require("./race")
this.future=require("./future")
this.daisy=function(args){process.nextTick(args.next=function(){var fn
return(fn=args.shift())?!!fn(args)||!0:!1})
return args.next}
this.dash=function(args,cb){var arg,count,length,_i,_len,_ref
"function"==typeof args&&(_ref=[args,cb],cb=_ref[0],args=_ref[1])
length=args.length
if(0===length)process.nextTick(cb)
else{count=0
args.fin=function(){return++count===length?!!cb()||!0:!1}
for(_i=0,_len=args.length;_len>_i;_i++){arg=args[_i]
process.nextTick(arg)}}return args.fin}})
require.define("/node_modules/sinkrow/lib/sinkrow/sequence.js",function(require,module,exports,__dirname,__filename,process){var Sequence,slice
Sequence=function(){function Sequence(fn,cb){this.fn=fn
this.cb=cb
this.times=0
this.args=[]}Sequence.prototype.next=function(args){var nextArgs,nextFn
nextFn=(nextArgs=this.args.shift())?this.next.bind(this,nextArgs):this.cb
return this.times--?this.fn.apply(this,args.concat(nextFn)):void 0}
Sequence.prototype.add=function(args){return this.times++?this.args.push(args):process.nextTick(this.next.bind(this,args))}
return Sequence}()
slice=[].slice
module.exports=function(fn,cb){var sequence
sequence=new Sequence(fn,cb)
return function(){return sequence.add(slice.call(arguments))}}})
require.define("/node_modules/sinkrow/lib/sinkrow/race.js",function(require,module){var Race,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__slice=[].slice
Race=function(){function Race(fn,cb){this.fn=fn
this.cb=cb
this.fin=__bind(this.fin,this)
this.times=0
this.finTimes=0}Race.prototype.fin=function(){return this.times===++this.finTimes?"function"==typeof this.cb?this.cb.apply(this,arguments):void 0:void 0}
Race.prototype.add=function(args){var i
i=this.times++
return this.fn.apply(this,[i].concat(args.concat(this.fin)))}
return Race}()
module.exports=function(fn,cb){var race
race=new Race(fn,cb)
return function(){var args
args=1<=arguments.length?__slice.call(arguments,0):[]
return race.add(args)}}})
require.define("/node_modules/sinkrow/lib/sinkrow/future.js",function(require,module){var initializeFuture,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
module.exports=function(context){var Future
if("function"==typeof context){if(context.name)return Future=function(_super){function Future(){this.queue=[]
Future.__super__.constructor.apply(this,arguments)}__extends(Future,_super)
Future.queue||(Future.queue=[])
initializeFuture.call(Future)
return Future}(context)
context.isFuture=!0
return context}}
initializeFuture=function(){var Pipeline,andThen,filter,isFuture,method,methods,next,originalMethods,replaceMethods,slice,_ref
_ref=require("underscore"),filter=_ref.filter,methods=_ref.methods
slice=[].slice
Pipeline=require("./pipeline")
originalMethods={}
method=function(context,methodName){originalMethods[methodName]=context[methodName]
return function(){this.queue.push({context:context,methodName:methodName,args:slice.call(arguments)})
return this}}
next=function(pipeline,err){var args,context,e,methodName,queued
if(null!=err)return pipeline.callback.call(this,err)
queued=pipeline.queue.shift()
if(null==queued)return pipeline.callback.call(this,null,pipeline)
methodName=queued.methodName,context=queued.context,args=queued.args
args.unshift(pipeline)
args.push(next.bind(this,pipeline))
try{return originalMethods[methodName].apply(originalMethods,args)}catch(_error){e=_error
return pipeline.callback.call(this,e,pipeline)}}
andThen=function(callback){var pipeline
pipeline=new Pipeline([],this.queue,callback)
pipeline.queue.length&&next.call(this,pipeline)
this.queue=[]
return this}
isFuture=function(methodName){return this[methodName].isFuture}
replaceMethods=function(){var methodName,_i,_len,_ref1
_ref1=filter(methods(this),isFuture.bind(this))
for(_i=0,_len=_ref1.length;_len>_i;_i++){methodName=_ref1[_i]
this[methodName]=method(this,methodName)}return this.then=andThen}
return function(){replaceMethods.call(this)
return replaceMethods.call(this.prototype)}}()})
require.define("/node_modules/sinkrow/lib/sinkrow/pipeline.js",function(require,module){var Pipeline,underscore,__slice=[].slice
underscore=require("underscore")
module.exports=Pipeline=function(){function Pipeline(pipeline,queue,callback){this.queue=queue
this.length=0
pipeline.length&&this.push.apply(this,[].slice.call(pipeline))
Object.defineProperty(this,"callback",{value:callback})}var empty,method,_i,_j,_len,_len1,_ref,_ref1
empty=[]
_ref="forEach,indexOf,join,pop,reverse,shift,sort,splice,unshift,push".split(",")
for(_i=0,_len=_ref.length;_len>_i;_i++){method=_ref[_i]
Pipeline.prototype[method]=empty[method]}_ref1="first,initial,last,rest,compact,flatten,without,union,intersection,difference,uniq,zip,lastIndexOf,range".split(",")
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){method=_ref1[_j]
Pipeline.prototype[method]=function(method){return function(){return underscore[method].apply(underscore,[this].concat(__slice.call(arguments)))}}(method)}Pipeline.prototype.root=function(){var _ref2,_ref3
return null!=(_ref2=this.first())?null!=(_ref3=_ref2.nodes)?_ref3[0]:void 0:void 0}
return Pipeline}()})
require.define("/node_modules_koding/bongo-client/src/cacheable.coffee",function(require,module){!function(){"use strict"
var ModelLoader,dash,getModelLoader,handleBatch,handleByName,handleSingle
ModelLoader=require("./modelloader")
dash=require("sinkrow").dash
module.exports=function(){switch(arguments.length){case 2:return handleBatch.apply(this,arguments)
case 3:return handleSingle.apply(this,arguments)
default:throw new Error("Bongo#cacheable expects either 2 or 3 arguments.")}}
getModelLoader=function(){var loading_
loading_={}
return function(constructor,id){var loader,_base,_name
loading_[_name=constructor.name]||(loading_[_name]={})
return loader=(_base=loading_[constructor.name])[id]||(_base[id]=new ModelLoader(constructor,id))}}()
handleByName=function(strName,callback){return"function"==typeof this.fetchName?this.fetchName(strName,callback):callback(new Error("Client must provide an implementation of fetchName!"))}
handleSingle=function(constructorName,_id,callback){var constructor,model
constructor="string"==typeof constructorName?this.api[constructorName]:"function"==typeof constructorName?constructorName:void 0
if(constructor){constructor.cache||(constructor.cache={});(model=constructor.cache[_id])?callback(null,model):getModelLoader(constructor,_id).load(function(err,model){constructor.cache[_id]=model
return callback(err,model)})}else callback(new Error("Unknown type "+constructorName))}
handleBatch=function(batch,callback){var models,queue,_this=this
if("string"==typeof batch)return handleByName.call(this,batch,callback)
models=[]
queue=batch.map(function(single,i){return function(){var constructorName,id,name,type
name=single.name,type=single.type,constructorName=single.constructorName,id=single.id
return handleSingle.call(_this,type||name||constructorName,id,function(err,model){if(err)return callback(err)
models[i]=model
return queue.fin()})}})
dash(queue,function(){return callback(null,models)})}}.call(this)})
require.define("/node_modules_koding/bongo-client/src/modelloader.coffee",function(require,module){!function(){"use strict"
var EventEmitter,ModelLoader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EventEmitter=require("microemitter").EventEmitter
module.exports=ModelLoader=function(_super){function ModelLoader(konstructor,_id){this._id=_id
this.konstructor=konstructor}var load_
__extends(ModelLoader,_super)
load_=function(){var _this=this
return this.konstructor.one({_id:this._id},function(err,model){return _this.emit("load",err,model)})}
ModelLoader.prototype.load=function(listener){this.once("load",listener)
if(!this.isLoading){this.isLoading=!0
return load_.call(this)}}
return ModelLoader}(EventEmitter)}.call(this)})
require.define("/node_modules_koding/bongo-client/bongo.js",function(require,module,exports,__dirname,__filename,process){"use strict"
var Bongo,EventEmitter,isBrowser,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1},__slice=[].slice
isBrowser="undefined"!=typeof window
EventEmitter=require("microemitter").EventEmitter
Bongo=function(_super){function Bongo(options){var _ref3,_this=this
EventEmitter(this)
this.mq=options.mq,this.getSessionToken=options.getSessionToken,this.getUserArea=options.getUserArea,this.fetchName=options.fetchName,this.resourceName=options.resourceName,this.precompiledApi=options.precompiledApi
null==(_ref3=this.getUserArea)&&(this.getUserArea=function(){})
this.localStore=new Store
this.remoteStore=new Store
this.readyState=NOTCONNECTED
this.stack=[]
this.eventBus=new EventBus(this.mq)
this.mq.on("message",this.bound("handleRequestString"))
this.mq.on("disconnected",this.emit.bind(this,"disconnected"))
this.opaqueTypes={}
this.on("newListener",function(event){return"ready"===event&&_this.readyState===CONNECTED?process.nextTick(function(){_this.emit("ready")
return _this.off("ready")}):void 0})}var CONNECTED,CONNECTING,DISCONNECTED,EventBus,JsPath,Model,NOTCONNECTED,OpaqueType,Scrubber,Store,Traverse,addGlobalListener,createBongoName,createId,dash,extend,getEventChannelName,getRevivingListener,race,sequence,slice,_ref,_ref1,_ref2
__extends(Bongo,_super)
_ref=[0,1,2,3],NOTCONNECTED=_ref[0],CONNECTING=_ref[1],CONNECTED=_ref[2],DISCONNECTED=_ref[3]
Traverse=require("traverse")
createId=Bongo.createId=require("hat")
JsPath=Bongo.JsPath=require("jspath")
Store=require("koding-dnode-protocol").Store
Scrubber=require("./src/scrubber")
Bongo.dnodeProtocol={Store:Store,Scrubber:Scrubber}
Bongo.EventEmitter=EventEmitter
Model=Bongo.Model=require("./src/model")
Bongo.ListenerTree=require("./src/listenertree")
EventBus=Bongo.EventBus=require("./src/eventbus")
OpaqueType=require("./src/opaquetype")
Model.prototype.mixin(require("./src/eventemitter/broker"))
Model.prototype.off=Model.prototype.removeListener
Model.prototype.addGlobalListener=Model.prototype.on
slice=[].slice
extend=require("./src/util").extend
_ref1=require("sinkrow"),race=_ref1.race,sequence=_ref1.sequence,dash=_ref1.dash
_ref2=require("sinkrow"),Bongo.daisy=_ref2.daisy,Bongo.dash=_ref2.dash,Bongo.sequence=_ref2.sequence,Bongo.race=_ref2.race,Bongo.future=_ref2.future
Bongo.bound=require("koding-bound")
Bongo.prototype.bound=require("koding-bound")
createBongoName=function(resourceName){return""+createId(128)+".unknown.bongo-"+resourceName}
Bongo.prototype.cacheable=require("./src/cacheable")
Bongo.prototype.createRemoteApiShims=function(api){var instance,name,options,shimmedApi,statik,_ref3
shimmedApi={}
for(name in api)if(__hasProp.call(api,name)){_ref3=api[name],statik=_ref3.statik,instance=_ref3.instance,options=_ref3.options
shimmedApi[name]=this.createConstructor(name,statik,instance,options)}return shimmedApi}
Bongo.prototype.wrapStaticMethods=function(){var optimizeThese
optimizeThese=["on","off"]
return function(constructor,constructorName,statik){var bongo
bongo=this
return statik.forEach(function(method){__indexOf.call(optimizeThese,method)>=0&&(method+="_")
return constructor[method]=function(){var rest,rpc
rest=1<=arguments.length?__slice.call(arguments,0):[]
rpc={type:"static",constructorName:constructorName,method:method}
return bongo.send(rpc,rest)}})}}()
Bongo.prototype.wrapInstanceMethods=function(){var optimizeThese
optimizeThese=["on","addListener","off","removeListener","save"]
return function(constructor,constructorName,instance){var bongo
bongo=this
return instance.forEach(function(method){__indexOf.call(optimizeThese,method)>=0&&(method+="_")
return constructor.prototype[method]=function(){var data,id,rpc
id=this.getId()
null==id&&(data=this.data)
rpc={type:"instance",constructorName:constructorName,method:method,id:id,data:data}
return bongo.send(rpc,[].slice.call(arguments))}})}}()
Bongo.prototype.registerInstance=function(inst){var _this=this
inst.on("listenerRemoved",function(event,listener){return _this.eventBus.off(inst,event,listener.bind(inst))})
return inst.on("newListener",function(event,listener){return _this.eventBus.on(inst,event,listener.bind(inst))})}
getEventChannelName=function(name){return"event-"+name}
getRevivingListener=function(bongo,ctx,listener){return function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return listener.apply(ctx,bongo.revive(rest))}}
addGlobalListener=function(konstructor,event,listener){var _this=this
return this.eventBus.staticOn(konstructor,event,function(){var rest,revived
rest=1<=arguments.length?__slice.call(arguments,0):[]
revived=_this.revive(rest)
return listener.apply(konstructor,revived)})}
Bongo.prototype.reviveType=function(type,shouldWrap){var revived,_base,_ref3,_ref4,_ref5
if(Array.isArray(type))return this.reviveType(type[0],!0)
if("string"!=typeof type)return type
revived=null!=(_ref3=null!=(_ref4=this.api[type])?_ref4:window[type])?_ref3:null!=(_ref5=(_base=this.opaqueTypes)[type])?_ref5:_base[type]=new OpaqueType(type)
return shouldWrap?[revived]:revived}
Bongo.prototype.reviveSchema=function(){var isArray,keys,reviveSchema,reviveSchemaRecursively
keys=Object.keys
isArray=Array.isArray
reviveSchemaRecursively=function(bongo,schema){return keys(schema).map(function(slot){var type
type=schema[slot]
type&&"object"==typeof type&&!isArray(type)&&(type=reviveSchemaRecursively(bongo,type))
return[slot,type]}).reduce(function(acc,_arg){var slot,type
slot=_arg[0],type=_arg[1]
acc[slot]=bongo.reviveType(type)
return acc},{})}
return reviveSchema=function(schema){return reviveSchemaRecursively(this,schema)}}()
Bongo.prototype.reviveOption=function(option,value){switch(option){case"schema":return this.reviveSchema(value)
default:return value}}
Bongo.prototype.createConstructor=function(name,staticMethods,instanceMethods,options){var konstructor,_this=this
konstructor=Function("bongo","return function "+name+" () {\n  bongo.registerInstance(this);\n  this.init.apply(this, [].slice.call(arguments));\n  this.bongo_.constructorName = '"+name+"';\n}")(this)
EventEmitter(konstructor)
this.wrapStaticMethods(konstructor,name,staticMethods)
__extends(konstructor,Model)
konstructor.prototype.updateInstanceChannel=this.updateInstanceChannel
konstructor.on("newListener",addGlobalListener.bind(this,konstructor))
process.nextTick(function(){var option,_results
_results=[]
for(option in options)__hasProp.call(options,option)&&_results.push(konstructor[option]=_this.reviveOption(option,options[option]))
return _results})
this.wrapInstanceMethods(konstructor,name,instanceMethods)
return konstructor}
Bongo.prototype.getInstancesById=function(){}
Bongo.prototype.getInstanceMethods=function(){return["changeLoggedInState","updateSessionToken"]}
Bongo.prototype.revive=function(obj){var bongo,hasEncoder
bongo=this
hasEncoder=null!=("undefined"!=typeof Encoder&&null!==Encoder?Encoder.XSSEncode:void 0)
return new Traverse(obj).map(function(node){var constructorName,instance,instanceId,konstructor,_ref3
if(null!=(null!=node?node.bongo_:void 0)){_ref3=node.bongo_,constructorName=_ref3.constructorName,instanceId=_ref3.instanceId
instance=bongo.getInstancesById(instanceId)
if(null!=instance)return this.update(instance,!0)
konstructor=bongo.api[node.bongo_.constructorName]
return null==konstructor?this.update(node):this.update(new konstructor(node))}return hasEncoder&&"string"==typeof node?this.update(Encoder.XSSEncode(node)):this.update(node)})}
Bongo.prototype.reviveFromSnapshots=function(){var snapshotReviver
snapshotReviver=function(k,v){return"_events"!==k?v:void 0}
return function(instances,callback){var results,_this=this
results=instances.map(function(instance){var e,revivee
revivee=null
try{null!=instance.snapshot&&(revivee=JSON.parse(instance.snapshot,snapshotReviver))}catch(_error){e=_error
console.warn("couldn't revive snapshot! "+instance._id)
revivee=null}return revivee?_this.revive(revivee):null})
results=results.filter(Boolean)
return callback(null,results)}}()
Bongo.prototype.handleRequestString=function(messageStr){var e
return this.handleRequest(function(){try{return JSON.parse(messageStr)}catch(_error){e=_error
return messageStr}}())}
Bongo.prototype.handleRequest=function(message){var callback,context,method,revived,scrubber,unscrubbed,_this=this
if("defineApi"===(null!=message?message.method:void 0)&&null==this.api)return this.defineApi(message.arguments[0])
if("handshakeDone"===(null!=message?message.method:void 0))return this.handshakeDone()
method=message.method,context=message.context
scrubber=new Scrubber(this.localStore)
unscrubbed=scrubber.unscrub(message,function(callbackId){_this.remoteStore.has(callbackId)||_this.remoteStore.add(callbackId,function(){var args
args=1<=arguments.length?__slice.call(arguments,0):[]
return _this.send(callbackId,args)})
return _this.remoteStore.get(callbackId)})
revived=this.revive(unscrubbed)
if(__indexOf.call(this.getInstanceMethods(),method)>=0)return this[method].apply(this,revived)
if(isNaN(+method))return console.warn("Unhandleable message; dropping it on the floor.")
callback=this.localStore.get(method)
return null!=callback?callback.apply(null,revived):void 0}
Bongo.prototype.reconnectHelper=function(){if(null!=this.api){this.readyState=CONNECTED
return this.emit("ready")}}
Bongo.prototype.connectHelper=function(callback){var _this=this
null!=callback&&this.mq.once("connected",callback.bind(this))
this.channelName=createBongoName(this.resourceName)
this.channel=this.mq.subscribe(this.channelName)
this.channel.exchange=this.resourceName
this.channel.setAuthenticationInfo({serviceType:"bongo",name:this.resourceName,clientId:this.getSessionToken()})
this.channel.off("message",this.bound("handleRequest"))
this.channel.on("message",this.bound("handleRequest"))
this.reconnectHelper()
this.channel.once("broker.subscribed",function(){return _this.stack.forEach(function(fn){return fn.call(_this)})})
return this.channel.on("broker.subscribed",function(){return _this.emit("connected")})}
Bongo.prototype.connect=function(callback){var _this=this
switch(this.readyState){case CONNECTED:case CONNECTING:return"already connected"
case DISCONNECTED:this.readyState=CONNECTING
this.mq.connect(function(){return _this.connectHelper(callback)})
break
default:this.readyState=CONNECTING
this.connectHelper(callback)}return this.mq.autoReconnect?this.mq.once("disconnected",function(){return _this.mq.on("connected",function(){return _this.reconnectHelper()})}):void 0}
Bongo.prototype.disconnect=function(shouldReconnect,callback){if("function"==typeof shouldReconnect){callback=shouldReconnect
shouldReconnect=!1}if(this.readyState===NOTCONNECTED||this.readyState===DISCONNECTED)return"already disconnected"
null!=callback&&this.mq.once("disconnected",callback.bind(this))
this.mq.disconnect(shouldReconnect)
return this.readyState=DISCONNECTED}
Bongo.prototype.messageFailed=function(message){return console.log("MESSAGE FAILED",message)}
Bongo.prototype.getTimeout=function(message,clientTimeout){null==clientTimeout&&(clientTimeout=5e3)
return setTimeout(this.messageFailed.bind(this,message),clientTimeout)}
Bongo.prototype.ping=function(callback){return this.send("ping",callback)}
Bongo.prototype.send=function(method,args){var scrubber,_this=this
Array.isArray(args)||(args=[args])
if(!this.channel)throw new Error("No channel!")
scrubber=new Scrubber(this.localStore)
return scrubber.scrub(args,function(){var message,messageString
message=scrubber.toDnodeProtocol()
message.method=method
message.sessionToken=_this.getSessionToken()
message.userArea=_this.getUserArea()
messageString=JSON.stringify(message)
return _this.channel.publish(messageString)})}
Bongo.prototype.authenticateUser=function(){var clientId
clientId=this.getSessionToken()
return this.send("authenticateUser",[clientId,this.bound("changeLoggedInState")])}
Bongo.prototype.handshakeDone=function(){this.api||(this.api=this.createRemoteApiShims(REMOTE_API))
this.readyState=CONNECTED
this.emit("ready")
return this.authenticateUser()}
Bongo.prototype.defineApi=function(api){this.api=this.createRemoteApiShims(api)
return this.handshakeDone()}
Bongo.prototype.changeLoggedInState=function(state){return this.emit("loggedInStateChanged",state)}
Bongo.prototype.updateSessionToken=function(token){return this.emit("sessionTokenChanged",token)}
Bongo.prototype.fetchChannel=function(channelName,callback){var channel
channel=this.mq.subscribe(channelName)
return channel.once("broker.subscribed",function(){return callback(channel)})}
Bongo.prototype.use=function(fn){return this.stack.push(fn)}
Bongo.prototype.monitorPresence=function(callbacks){return this.send("monitorPresence",callbacks)}
Bongo.prototype.subscribe=function(name,options,callback){var channel,_ref3
null==options&&(options={})
null==(_ref3=options.serviceType)&&(options.serviceType="application")
channel=this.mq.subscribe(name,options)
channel.setAuthenticationInfo({serviceType:options.serviceType,group:options.group,name:name,clientId:this.getSessionToken()})
null!=callback&&channel.once("broker.subscribed",function(){return callback(channel)})
return channel}
return Bongo}(EventEmitter)
!isBrowser&&module?module.exports=Bongo:"undefined"!=typeof window&&null!==window&&(window.Bongo=Bongo)})
require("/node_modules_koding/bongo-client/bongo.js")}()}()


!function(){var async={},root=this,previous_async=root.async
"undefined"!=typeof module&&module.exports?module.exports=async:root.async=async
async.noConflict=function(){root.async=previous_async
return async}
var _forEach=function(arr,iterator){if(arr.forEach)return arr.forEach(iterator)
for(var i=0;i<arr.length;i+=1)iterator(arr[i],i,arr)},_map=function(arr,iterator){if(arr.map)return arr.map(iterator)
var results=[]
_forEach(arr,function(x,i,a){results.push(iterator(x,i,a))})
return results},_reduce=function(arr,iterator,memo){if(arr.reduce)return arr.reduce(iterator,memo)
_forEach(arr,function(x,i,a){memo=iterator(memo,x,i,a)})
return memo},_keys=function(obj){if(Object.keys)return Object.keys(obj)
var keys=[]
for(var k in obj)obj.hasOwnProperty(k)&&keys.push(k)
return keys},_indexOf=function(arr,item){if(arr.indexOf)return arr.indexOf(item)
for(var i=0;i<arr.length;i+=1)if(arr[i]===item)return i
return-1}
async.nextTick="undefined"!=typeof process&&process.nextTick?process.nextTick:function(fn){setTimeout(fn,0)}
async.forEach=function(arr,iterator,callback){if(!arr.length)return callback()
var completed=0
_forEach(arr,function(x){iterator(x,function(err){if(err){callback(err)
callback=function(){}}else{completed+=1
completed===arr.length&&callback()}})})}
async.forEachSeries=function(arr,iterator,callback){if(!arr.length)return callback()
var completed=0,iterate=function(){iterator(arr[completed],function(err){if(err){callback(err)
callback=function(){}}else{completed+=1
completed===arr.length?callback():iterate()}})}
iterate()}
var doParallel=function(fn){return function(){var args=Array.prototype.slice.call(arguments)
return fn.apply(null,[async.forEach].concat(args))}},doSeries=function(fn){return function(){var args=Array.prototype.slice.call(arguments)
return fn.apply(null,[async.forEachSeries].concat(args))}},_asyncMap=function(eachfn,arr,iterator,callback){var results=[]
arr=_map(arr,function(x,i){return{index:i,value:x}})
eachfn(arr,function(x,callback){iterator(x.value,function(err,v){results[x.index]=v
callback(err)})},function(err){callback(err,results)})}
async.map=doParallel(_asyncMap)
async.mapSeries=doSeries(_asyncMap)
async.reduce=function(arr,memo,iterator,callback){async.forEachSeries(arr,function(x,callback){iterator(memo,x,function(err,v){memo=v
callback(err)})},function(err){callback(err,memo)})}
async.inject=async.reduce
async.foldl=async.reduce
async.reduceRight=function(arr,memo,iterator,callback){var reversed=_map(arr,function(x){return x}).reverse()
async.reduce(reversed,memo,iterator,callback)}
async.foldr=async.reduceRight
var _filter=function(eachfn,arr,iterator,callback){var results=[]
arr=_map(arr,function(x,i){return{index:i,value:x}})
eachfn(arr,function(x,callback){iterator(x.value,function(v){v&&results.push(x)
callback()})},function(){callback(_map(results.sort(function(a,b){return a.index-b.index}),function(x){return x.value}))})}
async.filter=doParallel(_filter)
async.filterSeries=doSeries(_filter)
async.select=async.filter
async.selectSeries=async.filterSeries
var _reject=function(eachfn,arr,iterator,callback){var results=[]
arr=_map(arr,function(x,i){return{index:i,value:x}})
eachfn(arr,function(x,callback){iterator(x.value,function(v){v||results.push(x)
callback()})},function(){callback(_map(results.sort(function(a,b){return a.index-b.index}),function(x){return x.value}))})}
async.reject=doParallel(_reject)
async.rejectSeries=doSeries(_reject)
var _detect=function(eachfn,arr,iterator,main_callback){eachfn(arr,function(x,callback){iterator(x,function(result){result?main_callback(x):callback()})},function(){main_callback()})}
async.detect=doParallel(_detect)
async.detectSeries=doSeries(_detect)
async.some=function(arr,iterator,main_callback){async.forEach(arr,function(x,callback){iterator(x,function(v){if(v){main_callback(!0)
main_callback=function(){}}callback()})},function(){main_callback(!1)})}
async.any=async.some
async.every=function(arr,iterator,main_callback){async.forEach(arr,function(x,callback){iterator(x,function(v){if(!v){main_callback(!1)
main_callback=function(){}}callback()})},function(){main_callback(!0)})}
async.all=async.every
async.sortBy=function(arr,iterator,callback){async.map(arr,function(x,callback){iterator(x,function(err,criteria){err?callback(err):callback(null,{value:x,criteria:criteria})})},function(err,results){if(err)return callback(err)
var fn=function(left,right){var a=left.criteria,b=right.criteria
return b>a?-1:a>b?1:0}
callback(null,_map(results.sort(fn),function(x){return x.value}))})}
async.auto=function(tasks,callback){callback=callback||function(){}
var keys=_keys(tasks)
if(!keys.length)return callback(null)
var completed=[],listeners=[],addListener=function(fn){listeners.unshift(fn)},removeListener=function(fn){for(var i=0;i<listeners.length;i+=1)if(listeners[i]===fn){listeners.splice(i,1)
return}},taskComplete=function(){_forEach(listeners,function(fn){fn()})}
addListener(function(){completed.length===keys.length&&callback(null)})
_forEach(keys,function(k){var task=tasks[k]instanceof Function?[tasks[k]]:tasks[k],taskCallback=function(err){if(err){callback(err)
callback=function(){}}else{completed.push(k)
taskComplete()}},requires=task.slice(0,Math.abs(task.length-1))||[],ready=function(){return _reduce(requires,function(a,x){return a&&-1!==_indexOf(completed,x)},!0)}
if(ready())task[task.length-1](taskCallback)
else{var listener=function(){if(ready()){removeListener(listener)
task[task.length-1](taskCallback)}}
addListener(listener)}})}
async.waterfall=function(tasks,callback){if(!tasks.length)return callback()
callback=callback||function(){}
var wrapIterator=function(iterator){return function(err){if(err){callback(err)
callback=function(){}}else{var args=Array.prototype.slice.call(arguments,1),next=iterator.next()
next?args.push(wrapIterator(next)):args.push(callback)
async.nextTick(function(){iterator.apply(null,args)})}}}
wrapIterator(async.iterator(tasks))()}
async.parallel=function(tasks,callback){callback=callback||function(){}
if(tasks.constructor===Array)async.map(tasks,function(fn,callback){fn&&fn(function(err){var args=Array.prototype.slice.call(arguments,1)
args.length<=1&&(args=args[0])
callback.call(null,err,args)})},callback)
else{var results={}
async.forEach(_keys(tasks),function(k,callback){tasks[k](function(err){var args=Array.prototype.slice.call(arguments,1)
args.length<=1&&(args=args[0])
results[k]=args
callback(err)})},function(err){callback(err,results)})}}
async.series=function(tasks,callback){callback=callback||function(){}
if(tasks.constructor===Array)async.mapSeries(tasks,function(fn,callback){fn&&fn(function(err){var args=Array.prototype.slice.call(arguments,1)
args.length<=1&&(args=args[0])
callback.call(null,err,args)})},callback)
else{var results={}
async.forEachSeries(_keys(tasks),function(k,callback){tasks[k](function(err){var args=Array.prototype.slice.call(arguments,1)
args.length<=1&&(args=args[0])
results[k]=args
callback(err)})},function(err){callback(err,results)})}}
async.iterator=function(tasks){var makeCallback=function(index){var fn=function(){tasks.length&&tasks[index].apply(null,arguments)
return fn.next()}
fn.next=function(){return index<tasks.length-1?makeCallback(index+1):null}
return fn}
return makeCallback(0)}
async.apply=function(fn){var args=Array.prototype.slice.call(arguments,1)
return function(){return fn.apply(null,args.concat(Array.prototype.slice.call(arguments)))}}
var _concat=function(eachfn,arr,fn,callback){var r=[]
eachfn(arr,function(x,cb){fn(x,function(err,y){r=r.concat(y||[])
cb(err)})},function(err){callback(err,r)})}
async.concat=doParallel(_concat)
async.concatSeries=doSeries(_concat)
async.whilst=function(test,iterator,callback){test()?iterator(function(err){if(err)return callback(err)
async.whilst(test,iterator,callback)
return void 0}):callback()}
async.until=function(test,iterator,callback){test()?callback():iterator(function(err){if(err)return callback(err)
async.until(test,iterator,callback)
return void 0})}
async.queue=function(worker,concurrency){var workers=0,tasks=[],q={concurrency:concurrency,saturated:null,empty:null,drain:null,push:function(data,callback){tasks.push({data:data,callback:callback})
q.saturated&&tasks.length==concurrency&&q.saturated()
async.nextTick(q.process)},process:function(){if(workers<q.concurrency&&tasks.length){var task=tasks.splice(0,1)[0]
q.empty&&0==tasks.length&&q.empty()
workers+=1
worker(task.data,function(){workers-=1
task.callback&&task.callback.apply(task,arguments)
q.drain&&0==tasks.length+workers&&q.drain()
q.process()})}},length:function(){return tasks.length},running:function(){return workers}}
return q}
var _console_fn=function(name){return function(fn){var args=Array.prototype.slice.call(arguments,1)
fn.apply(null,args.concat([function(err){var args=Array.prototype.slice.call(arguments,1)
"undefined"!=typeof console&&(err?console.error&&console.error(err):console[name]&&_forEach(args,function(x){console[name](x)}))}]))}}
async.log=_console_fn("log")
async.dir=_console_fn("dir")
async.memoize=function(fn,hasher){var memo={}
hasher=hasher||function(x){return x}
return function(){var args=Array.prototype.slice.call(arguments),callback=args.pop(),key=hasher.apply(null,args)
key in memo?callback.apply(null,memo[key]):fn.apply(null,args.concat([function(){memo[key]=arguments
callback.apply(null,arguments)}]))}}}()

var md5
md5=function(){function hex_md5(a){return rstr2hex(rstr_md5(str2rstr_utf8(a)))}function rstr_md5(a){return binl2rstr(binl_md5(rstr2binl(a),8*a.length))}function rstr2hex(c){try{}catch(g){hexcase=0}for(var a,f=hexcase?"0123456789ABCDEF":"0123456789abcdef",b="",d=0;d<c.length;d++){a=c.charCodeAt(d)
b+=f.charAt(15&a>>>4)+f.charAt(15&a)}return b}function str2rstr_utf8(c){for(var a,e,b="",d=-1;++d<c.length;){a=c.charCodeAt(d)
e=d+1<c.length?c.charCodeAt(d+1):0
if(a>=55296&&56319>=a&&e>=56320&&57343>=e){a=65536+((1023&a)<<10)+(1023&e)
d++}127>=a?b+=String.fromCharCode(a):2047>=a?b+=String.fromCharCode(192|31&a>>>6,128|63&a):65535>=a?b+=String.fromCharCode(224|15&a>>>12,128|63&a>>>6,128|63&a):2097151>=a&&(b+=String.fromCharCode(240|7&a>>>18,128|63&a>>>12,128|63&a>>>6,128|63&a))}return b}function rstr2binl(b){for(var a=Array(b.length>>2),c=0;c<a.length;c++)a[c]=0
for(var c=0;c<8*b.length;c+=8)a[c>>5]|=(255&b.charCodeAt(c/8))<<c%32
return a}function binl2rstr(b){for(var a="",c=0;c<32*b.length;c+=8)a+=String.fromCharCode(255&b[c>>5]>>>c%32)
return a}function binl_md5(p,k){p[k>>5]|=128<<k%32
p[(k+64>>>9<<4)+14]=k
for(var o=1732584193,n=-271733879,m=-1732584194,l=271733878,g=0;g<p.length;g+=16){var j=o,h=n,f=m,e=l
o=md5_ff(o,n,m,l,p[g+0],7,-680876936)
l=md5_ff(l,o,n,m,p[g+1],12,-389564586)
m=md5_ff(m,l,o,n,p[g+2],17,606105819)
n=md5_ff(n,m,l,o,p[g+3],22,-1044525330)
o=md5_ff(o,n,m,l,p[g+4],7,-176418897)
l=md5_ff(l,o,n,m,p[g+5],12,1200080426)
m=md5_ff(m,l,o,n,p[g+6],17,-1473231341)
n=md5_ff(n,m,l,o,p[g+7],22,-45705983)
o=md5_ff(o,n,m,l,p[g+8],7,1770035416)
l=md5_ff(l,o,n,m,p[g+9],12,-1958414417)
m=md5_ff(m,l,o,n,p[g+10],17,-42063)
n=md5_ff(n,m,l,o,p[g+11],22,-1990404162)
o=md5_ff(o,n,m,l,p[g+12],7,1804603682)
l=md5_ff(l,o,n,m,p[g+13],12,-40341101)
m=md5_ff(m,l,o,n,p[g+14],17,-1502002290)
n=md5_ff(n,m,l,o,p[g+15],22,1236535329)
o=md5_gg(o,n,m,l,p[g+1],5,-165796510)
l=md5_gg(l,o,n,m,p[g+6],9,-1069501632)
m=md5_gg(m,l,o,n,p[g+11],14,643717713)
n=md5_gg(n,m,l,o,p[g+0],20,-373897302)
o=md5_gg(o,n,m,l,p[g+5],5,-701558691)
l=md5_gg(l,o,n,m,p[g+10],9,38016083)
m=md5_gg(m,l,o,n,p[g+15],14,-660478335)
n=md5_gg(n,m,l,o,p[g+4],20,-405537848)
o=md5_gg(o,n,m,l,p[g+9],5,568446438)
l=md5_gg(l,o,n,m,p[g+14],9,-1019803690)
m=md5_gg(m,l,o,n,p[g+3],14,-187363961)
n=md5_gg(n,m,l,o,p[g+8],20,1163531501)
o=md5_gg(o,n,m,l,p[g+13],5,-1444681467)
l=md5_gg(l,o,n,m,p[g+2],9,-51403784)
m=md5_gg(m,l,o,n,p[g+7],14,1735328473)
n=md5_gg(n,m,l,o,p[g+12],20,-1926607734)
o=md5_hh(o,n,m,l,p[g+5],4,-378558)
l=md5_hh(l,o,n,m,p[g+8],11,-2022574463)
m=md5_hh(m,l,o,n,p[g+11],16,1839030562)
n=md5_hh(n,m,l,o,p[g+14],23,-35309556)
o=md5_hh(o,n,m,l,p[g+1],4,-1530992060)
l=md5_hh(l,o,n,m,p[g+4],11,1272893353)
m=md5_hh(m,l,o,n,p[g+7],16,-155497632)
n=md5_hh(n,m,l,o,p[g+10],23,-1094730640)
o=md5_hh(o,n,m,l,p[g+13],4,681279174)
l=md5_hh(l,o,n,m,p[g+0],11,-358537222)
m=md5_hh(m,l,o,n,p[g+3],16,-722521979)
n=md5_hh(n,m,l,o,p[g+6],23,76029189)
o=md5_hh(o,n,m,l,p[g+9],4,-640364487)
l=md5_hh(l,o,n,m,p[g+12],11,-421815835)
m=md5_hh(m,l,o,n,p[g+15],16,530742520)
n=md5_hh(n,m,l,o,p[g+2],23,-995338651)
o=md5_ii(o,n,m,l,p[g+0],6,-198630844)
l=md5_ii(l,o,n,m,p[g+7],10,1126891415)
m=md5_ii(m,l,o,n,p[g+14],15,-1416354905)
n=md5_ii(n,m,l,o,p[g+5],21,-57434055)
o=md5_ii(o,n,m,l,p[g+12],6,1700485571)
l=md5_ii(l,o,n,m,p[g+3],10,-1894986606)
m=md5_ii(m,l,o,n,p[g+10],15,-1051523)
n=md5_ii(n,m,l,o,p[g+1],21,-2054922799)
o=md5_ii(o,n,m,l,p[g+8],6,1873313359)
l=md5_ii(l,o,n,m,p[g+15],10,-30611744)
m=md5_ii(m,l,o,n,p[g+6],15,-1560198380)
n=md5_ii(n,m,l,o,p[g+13],21,1309151649)
o=md5_ii(o,n,m,l,p[g+4],6,-145523070)
l=md5_ii(l,o,n,m,p[g+11],10,-1120210379)
m=md5_ii(m,l,o,n,p[g+2],15,718787259)
n=md5_ii(n,m,l,o,p[g+9],21,-343485551)
o=safe_add(o,j)
n=safe_add(n,h)
m=safe_add(m,f)
l=safe_add(l,e)}return Array(o,n,m,l)}function md5_cmn(h,e,d,c,g,f){return safe_add(bit_rol(safe_add(safe_add(e,h),safe_add(c,f)),g),d)}function md5_ff(g,f,k,j,e,i,h){return md5_cmn(f&k|~f&j,g,f,e,i,h)}function md5_gg(g,f,k,j,e,i,h){return md5_cmn(f&j|k&~j,g,f,e,i,h)}function md5_hh(g,f,k,j,e,i,h){return md5_cmn(f^k^j,g,f,e,i,h)}function md5_ii(g,f,k,j,e,i,h){return md5_cmn(k^(f|~j),g,f,e,i,h)}function safe_add(a,d){var c=(65535&a)+(65535&d),b=(a>>16)+(d>>16)+(c>>16)
return b<<16|65535&c}function bit_rol(a,b){return a<<b|a>>>32-b}function md5(){}var hexcase=0
md5.name="md5"
md5.digest=hex_md5
return md5}()

__utils.extend(__utils,{proxifyUrl:function(url,options){var endpoint
null==url&&(url="")
null==options&&(options={})
options.width||(options.width=-1)
options.height||(options.height=-1)
if(""===url)return"data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";(options.width||options.height)&&(endpoint="/resize")
options.crop&&(endpoint="/crop")
return"https://i.embed.ly/1/display"+(endpoint||"")+"?grow=false&width="+options.width+"&height="+options.height+"&key="+KD.config.embedly.apiKey+"&url="+encodeURIComponent(url)},showMoreClickHandler:function(event){var $trg,less,more
$trg=$(event.target)
more="span.collapsedtext a.more-link"
less="span.collapsedtext a.less-link"
$trg.is(more)&&$trg.parent().addClass("show").removeClass("hide")
return $trg.is(less)?$trg.parent().removeClass("show").addClass("hide"):void 0},applyTextExpansions:function(text,shorten){var i,link,links,_i,_len,_ref
if(!text)return null
text=text.replace(/&#10;/g," ")
_ref=this.expandUrls(text,!0),links=_ref.links,text=_ref.text
shorten&&(text=__utils.putShowMore(text))
if(null!=links)for(i=_i=0,_len=links.length;_len>_i;i=++_i){link=links[i]
text=text.replace("[tempLink"+i+"]",link)}text=this.expandUsernames(text)
return text},expandWwwDotDomains:function(text){return text?text.replace(/(^|\s)(www\.[A-Za-z0-9-_]+.[A-Za-z0-9-_:%&\?\/.=]+)/g,function(_,whitespace,www){return""+whitespace+"<a href='http://"+www+"' target='_blank'>"+www+"</a>"}):null},expandUsernames:function(text,excludeSelector){var result
if(!text)return null
if(excludeSelector){result=""
$(text).each(function(i,element){var $element,childrenCheck,elementCheck,parentCheck,replacedText
$element=$(element)
elementCheck=$element.not(excludeSelector)
parentCheck=0===$element.parents(excludeSelector).length
childrenCheck=0===$element.find(excludeSelector).length
if(elementCheck&&parentCheck&&childrenCheck&&null!=$element.html()){replacedText=$element.html().replace(/\B\@([\w\-]+)/gim,function(u){var username
username=u.replace("@","")
return u.link("/"+username)})
$element.html(replacedText)}return result+=$element.get(0).outerHTML||""})
return result}return text.replace(/\B\@([\w\-]+)/gim,function(u){var username
username=u.replace("@","")
return u.link("/"+username)})},expandTags:function(text){return text?text.replace(/[#]+[A-Za-z0-9-_]+/g,function(t){var tag
tag=t.replace("#","")
return"<a href='#!/topic/"+tag+"' class='ttag'><span>"+tag+"</span></a>"}):null},expandUrls:function(text,replaceAndYieldLinks){var linkCount,links,urlGrabber
null==replaceAndYieldLinks&&(replaceAndYieldLinks=!1)
if(!text)return null
links=[]
linkCount=0
urlGrabber=/(?!\s)([a-zA-Z]+:\/\/)(\w+:\w+@|[\w|\d]+@|)((?:[a-zA-Z\d]+(?:-[a-zA-Z\d]+)*\.)*)([a-zA-Z\d]+(?:[a-zA-Z\d]|-(?=[a-zA-Z\d]))*[a-zA-Z\d]?)\.([a-zA-Z]{2,4})(:\d+|)(\/\S*|)(?!\S)/g
text=text.replace(urlGrabber,function(url){var checkForPostSlash,originalUrl,visibleUrl
url=url.trim()
originalUrl=url
visibleUrl=url.replace(/(ht|f)tp(s)?\:\/\//,"").replace(/\/.*/,"")
checkForPostSlash=/.*(\/\/)+.*\/.+/.test(originalUrl);/[A-Za-z]+:\/\//.test(url)||(url="//"+url)
if(replaceAndYieldLinks){links.push("<a href='"+url+"' data-original-url='"+originalUrl+"' target='_blank' >"+visibleUrl+(checkForPostSlash?"/…":"")+"<span class='expanded-link'></span></a>")
return"[tempLink"+linkCount++ +"]"}return"<a href='"+url+"' data-original-url='"+originalUrl+"' target='_blank' >"+visibleUrl+(checkForPostSlash?"/…":"")+"<span class='expanded-link'></span></a>"})
return replaceAndYieldLinks?{links:links,text:text}:text},putShowMore:function(text,l){var morePart,shortenedText
null==l&&(l=500)
shortenedText=__utils.shortenText(text,{minLength:l,maxLength:l+Math.floor(l/10),suffix:""})
return text=Encoder.htmlEncode(text).length>Encoder.htmlEncode(shortenedText).length?(morePart="<span class='collapsedtext hide'>",morePart+="<a href='#' class='more-link' title='Show more...'>Show more...</a>",morePart+=Encoder.htmlEncode(text).substr(Encoder.htmlEncode(shortenedText).length),morePart+="<a href='#' class='less-link' title='Show less...'>...show less</a>",morePart+="</span>",Encoder.htmlEncode(shortenedText)+morePart):Encoder.htmlEncode(shortenedText)},shortenText:function(){var tryToShorten
tryToShorten=function(longText,optimalBreak,suffix){null==optimalBreak&&(optimalBreak=" ")
return~longText.indexOf(optimalBreak)?""+longText.split(optimalBreak).slice(0,-1).join(optimalBreak)+(null!=suffix?suffix:optimalBreak):!1}
return function(longText,options){var candidate,finalMaxLength,lastClosingTag,lastOpeningTag,longTextLength,maxLength,minLength,suffix,tempText,_ref
null==options&&(options={})
if(longText){minLength=options.minLength||450
maxLength=options.maxLength||600
suffix=null!=(_ref=options.suffix)?_ref:"..."
longTextLength=longText.length
tempText=longText.slice(0,maxLength)
lastClosingTag=tempText.lastIndexOf("]")
lastOpeningTag=tempText.lastIndexOf("[")
finalMaxLength=lastClosingTag>=lastOpeningTag?maxLength:lastOpeningTag
if(longText.length<minLength||longText.length<maxLength)return longText
longText=longText.substr(0,finalMaxLength)
candidate=tryToShorten(longText,". ",suffix)||tryToShorten(longText," ",suffix)
return(null!=candidate?candidate.length:void 0)>minLength?candidate:longText}}}(),getMonthOptions:function(){var i,_i,_results
_results=[]
for(i=_i=1;12>=_i;i=++_i)_results.push(i>9?{title:""+i,value:i}:{title:"0"+i,value:i})
return _results},getYearOptions:function(min,max){var i,_i,_results
null==min&&(min=1900)
null==max&&(max=Date.prototype.getFullYear())
_results=[]
for(i=_i=min;max>=min?max>=_i:_i>=max;i=max>=min?++_i:--_i)_results.push({title:""+i,value:i})
return _results},getFullnameFromAccount:function(account,justName){var name
null==justName&&(justName=!1)
account||(account=KD.whoami())
name="unregistered"===account.type?"a guest":justName?account.profile.firstName:""+account.profile.firstName+" "+account.profile.lastName
return Encoder.htmlEncode(name||"a Koding user")},getNameFromFullname:function(fullname){return fullname.split(" ")[0]},notifyAndEmailVMTurnOnFailureToSysAdmin:function(vmName,reason){if(!(window.localStorage.notifiedSysAdminOfVMFailureTime&&parseInt(window.localStorage.notifiedSysAdminOfVMFailureTime,10)+36e5>Date.now())){window.localStorage.notifiedSysAdminOfVMFailureTime=Date.now()
new KDNotificationView({title:"Sorry, your vm failed to turn on. An email has been sent to a sysadmin."})
return KD.whoami().sendEmailVMTurnOnFailureToSysAdmin(vmName,reason)}},generatePassword:function(){var consonant,letter,vowel
letter=/[a-zA-Z]$/
vowel=/[aeiouAEIOU]$/
consonant=/[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]$/
return function(length,memorable,pattern,prefix){var chr,n
null==length&&(length=10)
null==memorable&&(memorable=!0)
null==pattern&&(pattern=/\w/)
null==prefix&&(prefix="")
if(prefix.length>=length)return prefix
memorable&&(pattern=consonant.test(prefix)?vowel:consonant)
n=Math.floor(100*Math.random())%94+33
chr=String.fromCharCode(n)
memorable&&(chr=chr.toLowerCase())
return pattern.test(chr)?__utils.generatePassword(length,memorable,pattern,""+prefix+chr):__utils.generatePassword(length,memorable,pattern,prefix)}}(),versionCompare:function(v1,operator,v2){var compare,i,numVersion,prepVersion,vm,x,_i
i=x=compare=0
vm={dev:-6,alpha:-5,a:-5,beta:-4,b:-4,RC:-3,rc:-3,"#":-2,p:-1,pl:-1}
prepVersion=function(v){v=(""+v).replace(/[_\-+]/g,".")
v=v.replace(/([^.\d]+)/g,".$1.").replace(/\.{2,}/g,".")
return v.length?v.split("."):[-8]}
numVersion=function(v){return v?isNaN(v)?vm[v]||-7:parseInt(v,10):0}
v1=prepVersion(v1)
v2=prepVersion(v2)
x=Math.max(v1.length,v2.length)
for(i=_i=0;x>=0?x>=_i:_i>=x;i=x>=0?++_i:--_i)if(v1[i]!==v2[i]){v1[i]=numVersion(v1[i])
v2[i]=numVersion(v2[i])
if(v1[i]<v2[i]){compare=-1
break}if(v1[i]>v2[i]){compare=1
break}}if(!operator)return compare
switch(operator){case">":case"gt":return compare>0
case">=":case"ge":return compare>=0
case"<=":case"le":return 0>=compare
case"==":case"=":case"eq":case"is":return 0===compare
case"<>":case"!=":case"ne":case"isnt":return 0!==compare
case"":case"<":case"lt":return 0>compare
default:return null}},getDummyName:function(){var gp,gr,u
u=KD.utils
gr=u.getRandomNumber
gp=u.generatePassword
return gp(gr(10),!0)},registerDummyUser:function(){var formData,u,uniqueness
if("localhost"===location.hostname){u=KD.utils
uniqueness=(Date.now()+"").slice(6)
formData={agree:"on",email:"sinanyasar+"+uniqueness+"@gmail.com",firstName:u.getDummyName(),lastName:u.getDummyName(),inviteCode:"twitterfriends",password:"123123123",passwordConfirm:"123123123",username:uniqueness}
return KD.remote.api.JUser.register(formData,function(){return location.reload(!0)})}},postDummyStatusUpdate:function(){var body,group,_ref,_ref1
if("localhost"===location.hostname){body=KD.utils.generatePassword(KD.utils.getRandomNumber(50),!0)+" "+dateFormat(Date.now(),"dddd, mmmm dS, yyyy, h:MM:ss TT")
group="group"===(null!=(_ref=KD.config.entryPoint)?_ref.type:void 0)&&(null!=(_ref1=KD.config.entryPoint)?_ref1.slug:void 0)?KD.config.entryPoint.slug:"koding"
return KD.remote.api.JStatusUpdate.create({body:body,group:group},function(err,reply){return err?new KDNotificationView({type:"mini",title:"There was an error, try again later!"}):KD.getSingleton("appManager").tell("Activity","ownActivityArrived",reply)})}},startRollbar:function(){return this.replaceFromTempStorage("_rollbar")},stopRollbar:function(){this.storeToTempStorage("_rollbar",window._rollbar)
return window._rollbar={push:function(){}}},startMixpanel:function(){return this.replaceFromTempStorage("mixpanel")},stopMixpanel:function(){this.storeToTempStorage("mixpanel",window.mixpanel)
return window.mixpanel={track:function(){}}},replaceFromTempStorage:function(name){var item
return(item=this.tempStorage[name])?window[item]=item:log("no "+name+" in mainController temp storage")},storeToTempStorage:function(name,item){return this.tempStorage[name]=item},tempStorage:function(){return KD.getSingleton("mainController").tempStorage},applyGradient:function(view,color1,color2){var rule,rules,_i,_len,_results
rules=["-moz-linear-gradient(100% 100% 90deg, "+color2+", "+color1+")","-webkit-gradient(linear, 0% 0%, 0% 100%, from("+color1+"), to("+color2+"))"]
_results=[]
for(_i=0,_len=rules.length;_len>_i;_i++){rule=rules[_i]
_results.push(view.setCss("backgroundImage",rule))}return _results},getAppIcon:function(appManifest){var authorNick,icns,image,img,name,resourceRoot,size,thumb,version,_i,_len,_ref
authorNick=appManifest.authorNick,name=appManifest.name,version=appManifest.version,icns=appManifest.icns
resourceRoot=""+KD.appsUri+"/"+authorNick+"/"+name+"/"+version+"/"
appManifest.devMode&&(resourceRoot="http://"+KD.getSingleton("vmController").defaultVm+"/.applications/"+__utils.slugify(name)+"/")
image="Ace"===name?"icn-ace":"default.app.thumb"
thumb=""+KD.apiUri+"/images/"+image+".png"
_ref=[64,128,160,256,512]
for(_i=0,_len=_ref.length;_len>_i;_i++){size=_ref[_i]
if(icns&&icns[String(size)]){thumb=""+resourceRoot+"/"+icns[String(size)]
break}}img=new KDCustomHTMLView({tagName:"img",bind:"error",error:function(){return this.getElement().setAttribute("src","/images/default.app.thumb.png")},attributes:{src:thumb}})
return img},compileCoffeeOnClient:function(coffeeCode,callback){null==callback&&(callback=noop)
return require(["//cdnjs.cloudflare.com/ajax/libs/coffee-script/1.6.3/coffee-script.min.js"],function(coffeeCompiler){return callback(coffeeCompiler.eval(coffeeCode))})},showSaveDialog:function(container,callback,options){var dialog,finder,finderController,finderWrapper,form,input,label,labelFinder,wrapper
null==callback&&(callback=noop)
null==options&&(options={})
container.addSubView(dialog=new KDDialogView({cssClass:KD.utils.curry("save-as-dialog",options.cssClass),duration:200,topOffset:0,overlay:!0,height:"auto",buttons:{Save:{style:"modal-clean-gray",callback:function(){return callback(input,finderController,dialog)}},Cancel:{style:"modal-cancel",callback:function(){finderController.stopAllWatchers()
delete finderController
finderController.destroy()
return dialog.destroy()}}}}))
dialog.addSubView(wrapper=new KDView({cssClass:"kddialog-wrapper"}))
wrapper.addSubView(form=new KDFormView)
form.addSubView(label=new KDLabelView({title:options.inputLabelTitle||"Filename:"}))
form.addSubView(input=new KDInputView({label:label,defaultValue:options.inputDefaultValue||""}))
form.addSubView(labelFinder=new KDLabelView({title:options.finderLabel||"Select a folder:"}))
dialog.show()
input.setFocus()
finderController=new NFinderController({nodeIdPath:"path",nodeParentIdPath:"parentPath",foldersOnly:!0,contextMenu:!1,loadFilesOnInit:!0})
finder=finderController.getView()
finderController.reset()
form.addSubView(finderWrapper=new KDView({cssClass:"save-as-dialog save-file-container"},null))
finderWrapper.addSubView(finder)
return finderWrapper.setHeight(200)}})

var __indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1},__slice=[].slice
KD.extend({apiUri:KD.config.apiUri,appsUri:KD.config.appsUri,singleton:KD.getSingleton.bind(KD),impersonate:function(username){return KD.remote.api.JAccount.impersonate(username,function(err){return err?new KDNotificationView({title:err.message}):location.reload()})},notify_:function(message,type){null==type&&(type="")
log(message)
return new KDNotificationView({cssClass:""+type,title:message,duration:3500})},requireMembership:function(options){var callback,groupName,mainController,onFail,onFailMsg,silence,tryAgain,_this=this
null==options&&(options={})
callback=options.callback,onFailMsg=options.onFailMsg,onFail=options.onFail,silence=options.silence,tryAgain=options.tryAgain,groupName=options.groupName
if(KD.isLoggedIn())return groupName?this.joinGroup_(groupName,function(err){return err?_this.notify_("Joining "+groupName+" group failed","error"):"function"==typeof callback?callback():void 0}):"function"==typeof callback?callback():void 0
onFailMsg&&this.notify_(onFailMsg,"error")
"function"==typeof onFail&&onFail()
silence||KD.getSingleton("router").handleRoute("/Login",{entryPoint:KD.config.entryPoint})
if(null!=callback&&tryAgain&&!KD.lastFuncCall){KD.lastFuncCall=callback
mainController=KD.getSingleton("mainController")
return mainController.once("accountChanged.to.loggedIn",function(){if(KD.isLoggedIn()){"function"==typeof KD.lastFuncCall&&KD.lastFuncCall()
KD.lastFuncCall=null
if(groupName)return _this.joinGroup_(groupName,function(err){return err?_this.notify_("Joining "+groupName+" group failed","error"):void 0})}})}},joinGroup_:function(groupName,callback){var user,_this=this
if(!groupName)return callback(null)
user=this.whoami()
return user.checkGroupMembership(groupName,function(err,isMember){return err?callback(err):isMember?callback(null):_this.remote.api.JGroup.one({slug:groupName},function(err,currentGroup){return err?callback(err):currentGroup?currentGroup.join(function(err){if(err)return callback(err)
_this.notify_("You have joined to "+groupName+" group!","success")
return callback(null)}):callback(null)})})},nick:function(){return KD.whoami().profile.nickname},whoami:function(){return KD.getSingleton("mainController").userAccount},logout:function(){var mainController
mainController=KD.getSingleton("mainController")
mainController.isLoggingIn(!0)
return null!=mainController?delete mainController.userAccount:void 0},isGuest:function(){return!KD.isLoggedIn()},isLoggedIn:function(){var _ref
return"unregistered"!==(null!=(_ref=KD.whoami())?_ref.type:void 0)},isMine:function(account){return KD.whoami().profile.nickname===account.profile.nickname},checkFlag:function(flagToCheck,account){var flag,_i,_len
null==account&&(account=KD.whoami())
if(account.globalFlags){if("string"==typeof flagToCheck)return __indexOf.call(account.globalFlags,flagToCheck)>=0
for(_i=0,_len=flagToCheck.length;_len>_i;_i++){flag=flagToCheck[_i]
if(__indexOf.call(account.globalFlags,flag)>=0)return!0}}return!1},showError:function(err,messages){var content,defaultMessages,duration,errMessage,message,title
if(err){if("string"==typeof err){message=err
err={message:message}}defaultMessages={AccessDenied:"Permission denied",KodingError:"Something went wrong"}
err.name||(err.name="KodingError")
content=""
messages&&(errMessage=messages[err.name]||messages.KodingError||defaultMessages.KodingError)
messages||(messages=defaultMessages)
errMessage||(errMessage=err.message||messages[err.name]||messages.KodingError)
null!=errMessage&&("string"==typeof errMessage?title=errMessage:null!=errMessage.title&&null!=errMessage.content&&(title=errMessage.title,content=errMessage.content))
duration=errMessage.duration||2500
title||(title=err.message)
new KDNotificationView({title:title,content:content,duration:duration})
return"AccessDenied"!==err.name?warn("KodingError:",err.message):void 0}},getPathInfo:function(fullPath){var basename,isPublic,parent,path,vmName
if(!fullPath)return!1
path=FSHelper.plainPath(fullPath)
basename=FSHelper.getFileNameFromPath(fullPath)
parent=FSHelper.getParentPath(path)
vmName=FSHelper.getVMNameFromPath(fullPath)
isPublic=FSHelper.isPublicPath(fullPath)
return{path:path,basename:basename,parent:parent,vmName:vmName,isPublic:isPublic}},getPublicURLOfPath:function(fullPath,secure){var isPublic,path,pathPartials,publicPath,subdomain,user,vmName,_,_ref
null==secure&&(secure=!1)
_ref=KD.getPathInfo(fullPath),vmName=_ref.vmName,isPublic=_ref.isPublic,path=_ref.path
if(isPublic){pathPartials=path.match(/^\/home\/(\w+)\/Web\/(.*)/)
if(pathPartials){_=pathPartials[0],user=pathPartials[1],publicPath=pathPartials[2]
publicPath||(publicPath="")
subdomain=/^shared\-/.test(vmName)&&user===KD.nick()?""+user+".":""
return""+(secure?"https":"http")+"://"+subdomain+vmName+"/"+publicPath}}},runningInFrame:function(){return window.top!==window.self},getReferralUrl:function(username){return""+location.origin+"/R/"+username},tell:function(){var rest,_ref
rest=1<=arguments.length?__slice.call(arguments,0):[]
return(_ref=KD.getSingleton("appManager")).tell.apply(_ref,rest)}})
Object.defineProperty(KD,"defaultSlug",{get:function(){return KD.isGuest()?"guests":"koding"}})

var KodingRouter,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
KodingRouter=function(_super){function KodingRouter(defaultRoute){var _this=this
this.defaultRoute=defaultRoute
this.defaultRoute||(this.defaultRoute=location.pathname+location.search)
this.openRoutes={}
this.openRoutesById={}
KD.singleton("display").on("DisplayIsDestroyed",this.bound("cleanupRoute"))
this.ready=!1
KD.getSingleton("mainController").once("AccountChanged",function(){_this.ready=!0
return _this.utils.defer(function(){return _this.emit("ready")})})
KodingRouter.__super__.constructor.call(this)
KodingRouter.emit("RouterReady",this)
this.addRoutes(getRoutes.call(this))
this.on("AlreadyHere",function(){return log("You're already here!")})}var getRoutes,getSectionName,handleRoot,nicenames,notFound
__extends(KodingRouter,_super)
KodingRouter.registerStaticEmitter()
nicenames={StartTab:"Develop"}
getSectionName=function(model){var sectionName
sectionName=nicenames[model.bongo_.constructorName]
return null!=sectionName?" - "+sectionName:""}
KodingRouter.prototype.listen=function(){var entryPoint
KodingRouter.__super__.listen.apply(this,arguments)
if(!this.userRoute){entryPoint=KD.config.entryPoint
return this.handleRoute(this.defaultRoute,{shouldPushState:!0,replaceState:!0,entryPoint:entryPoint})}}
notFound=function(route){var _this=this
return this.utils.defer(function(){return _this.addRoute(route,function(){return console.warn("Contract warning: shared route "+route+" is not implemented.")})})}
KodingRouter.prototype.handleRoute=function(route,options){var appManager,entryPoint,entrySlug,frags,name,_this=this
null==options&&(options={})
appManager=KD.getSingleton("appManager")
frags=route.split("/")
name=frags[1]||""
name="Develop"===name&&frags.length>2?frags[2]:name
log("handlingRoute",route,"for the",name,"app")
if(appManager.checkAppAvailability(name)){log("couldn't find",name)
return KodingAppsController.putAppScript(name,function(err){log("Router: loaded",name)
return err?warn(err):KD.utils.defer(function(){return _this.handleRoute(route,options)})})}entryPoint=options.entryPoint
if(null!=(null!=entryPoint?entryPoint.slug:void 0)&&"group"===entryPoint.type){entrySlug="/"+entryPoint.slug
RegExp("^"+entrySlug).test(route)||"/koding"===entrySlug||(route=entrySlug+route)}return KodingRouter.__super__.handleRoute.call(this,route,options)}
handleRoot=function(){var entryPoint
if(!location.hash.length){KD.singleton("display").hideAllDisplays()
entryPoint=KD.config.entryPoint
return KD.isLoggedIn()?this.handleRoute(this.userRoute||this.getDefaultRoute(),{replaceState:!0,entryPoint:entryPoint}):this.handleRoute(this.getDefaultRoute(),{entryPoint:entryPoint})}}
KodingRouter.prototype.cleanupRoute=function(contentDisplay){return delete this.openRoutes[this.openRoutesById[contentDisplay.id]]}
KodingRouter.prototype.openSection=function(app,group,query){var _ref,_this=this
return this.ready?KD.getSingleton("groupsController").changeGroup(group,function(err){var appManager,appWasOpen,handleQuery,_ref1
if(err)return new KDNotificationView({title:err.message})
_this.setPageTitle(null!=(_ref1=nicenames[app])?_ref1:app)
appManager=KD.getSingleton("appManager")
handleQuery=appManager.tell.bind(appManager,app,"handleQuery",query);(appWasOpen=appManager.get(app))||appManager.once("AppCreated",handleQuery)
appManager.open(app,function(appInstance){return appInstance.setOption("initialRoute",_this.getCurrentPath())})
return appWasOpen?handleQuery():void 0}):this.once("ready",(_ref=this.openSection).bind.apply(_ref,[this].concat(__slice.call(arguments))))}
KodingRouter.prototype.handleNotFound=function(route){var status_301,status_404,_this=this
status_404=function(){return KDRouter.prototype.handleNotFound.call(_this,route)}
status_301=function(redirectTarget){return _this.handleRoute("/"+redirectTarget,{replaceState:!0})}
return KD.remote.api.JUrlAlias.resolve(route,function(err,target){return err||null==target?status_404():status_301(target)})}
KodingRouter.prototype.getDefaultRoute=function(){return KD.isLoggedIn()?"/Activity":"/"}
KodingRouter.prototype.setPageTitle=function(title){null==title&&(title="Koding")
return document.title=Encoder.htmlDecode(title)}
KodingRouter.prototype.getContentTitle=function(model){var JAccount,JGroup,JStatusUpdate,_ref
_ref=KD.remote.api,JAccount=_ref.JAccount,JStatusUpdate=_ref.JStatusUpdate,JGroup=_ref.JGroup
return this.utils.shortenText(function(){switch(model.constructor){case JAccount:return KD.utils.getFullnameFromAccount(model)
case JStatusUpdate:return model.body
case JGroup:return model.title
default:return""+model.title+getSectionName(model)}}(),{maxLength:100})}
KodingRouter.prototype.openContent=function(name,section,models,route,query,passOptions){var callback,currentGroup,groupName,groupsController,method,options,_this=this
null==passOptions&&(passOptions=!1)
method="createContentDisplay"
Array.isArray(models)&&(models=models[0])
this.setPageTitle(this.getContentTitle(models))
if(passOptions){method+="WithOptions"
options={model:models,route:route,query:query}}callback=function(){return KD.getSingleton("appManager").tell(section,method,null!=options?options:models,function(contentDisplay){var routeWithoutParams
routeWithoutParams=route.split("?")[0]
_this.openRoutes[routeWithoutParams]=contentDisplay
_this.openRoutesById[contentDisplay.id]=routeWithoutParams
return contentDisplay.emit("handleQuery",query)})}
groupsController=KD.getSingleton("groupsController")
currentGroup=groupsController.getCurrentGroup()
if(currentGroup)return callback()
groupName="Groups"===section?name:"koding"
return groupsController.changeGroup(groupName,function(err){err&&KD.showError(err)
return callback()})}
KodingRouter.prototype.loadContent=function(name,section,slug,route,query,passOptions){var groupName,routeWithoutParams,_this=this
routeWithoutParams=route.split("?")[0]
groupName="Groups"===section?name:"koding"
return KD.getSingleton("groupsController").changeGroup(groupName,function(err){var onError,onSuccess,slashlessSlug
err&&KD.showError(err)
onSuccess=function(models){return _this.openContent(name,section,models,route,query,passOptions)}
onError=function(err){KD.showError(err)
return _this.handleNotFound(route)}
if(name&&!slug)return KD.remote.cacheable(name,function(err,models){return null!=models?onSuccess(models):onError(err)})
slashlessSlug=routeWithoutParams.slice(1)
return KD.remote.api.JName.one({name:slashlessSlug},function(err,jName){var models
if(err)return onError(err)
if(null!=jName){models=[]
return jName.slugs.forEach(function(aSlug,i){var constructorName,konstructor,selector,usedAsPath
constructorName=aSlug.constructorName,usedAsPath=aSlug.usedAsPath
selector={}
konstructor=KD.remote.api[constructorName]
selector[usedAsPath]=aSlug.slug
aSlug.group&&(selector.group=aSlug.group)
return null!=konstructor?konstructor.one(selector,function(err,model){if(null!=err)return onError(err)
if(model){models[i]=model
if(models.length===jName.slugs.length)return onSuccess(models)}}):void 0})}return onError()})})}
KodingRouter.prototype.createContentDisplayHandler=function(section,passOptions){var _this=this
null==passOptions&&(passOptions=!1)
return function(_arg,models,route){var contentDisplay,name,query,slug,_ref
_ref=_arg.params,name=_ref.name,slug=_ref.slug,query=_arg.query
route||(route=name)
contentDisplay=_this.openRoutes[route.split("?")[0]]
if(null!=contentDisplay){KD.singleton("display").hideAllDisplays(contentDisplay)
return contentDisplay.emit("handleQuery",query)}return null!=models?_this.openContent(name,section,models,route,query,passOptions):_this.loadContent(name,section,slug,route,query,passOptions)}}
KodingRouter.prototype.createStaticContentDisplayHandler=function(section,passOptions){var _this=this
null==passOptions&&(passOptions=!1)
return function(params,models,route){var contentDisplay
contentDisplay=_this.openRoutes[route]
return null!=contentDisplay?KD.singleton("display").hideAllDisplays(contentDisplay):_this.openContent(null,section,models,route,null,passOptions)}}
KodingRouter.prototype.clear=function(route,replaceState){var entryPoint,_ref
null==replaceState&&(replaceState=!0)
if(!route){entryPoint=KD.config.entryPoint
route=KD.isLoggedIn()&&"group"===(null!=entryPoint?entryPoint.type:void 0)&&null!=(null!=entryPoint?entryPoint.slug:void 0)?"/"+(null!=(_ref=KD.config.entryPoint)?_ref.slug:void 0):"/"}return KodingRouter.__super__.clear.call(this,route,replaceState)}
getRoutes=function(){var clear,createContentHandler,createSectionHandler,createStaticContentHandler,getAction,mainController,requireLogin,requireLogout,routes,_this=this
mainController=KD.getSingleton("mainController")
clear=this.bound("clear")
getAction=function(formName){switch(formName){case"login":return"log in"
case"register":return"register"}}
requireLogin=function(fn){return mainController.ready(function(){return KD.isLoggedIn()?__utils.defer(fn):clear()})}
requireLogout=function(fn){return mainController.ready(function(){return KD.isLoggedIn()?clear():__utils.defer(fn)})}
createSectionHandler=function(sec){return function(_arg){var name,query,slug,_ref
_ref=_arg.params,name=_ref.name,slug=_ref.slug,query=_arg.query
return _this.openSection(slug||sec,name,query)}}
createContentHandler=this.bound("createContentDisplayHandler")
createStaticContentHandler=this.bound("createStaticContentDisplayHandler")
routes={"/":handleRoot,"":handleRoot,"/Landing/:page":noop,"/R/:username":noop,"/:name?/Logout":function(_arg){var name
name=_arg.params.name
return requireLogin(function(){return mainController.doLogout()})},"/:name?/Topics/:slug":createContentHandler("Topics"),"/:name?/Activity/:slug":createContentHandler("Activity"),"/:name?/Apps/:slug":createContentHandler("Apps"),"/:name/Groups":createSectionHandler("Groups"),"/:name/Followers":createContentHandler("Members",!0),"/:name/Following":createContentHandler("Members",!0),"/:name/Likes":createContentHandler("Members",!0),"/:name?/Recover/:recoveryToken":function(_arg){var JPasswordRecovery,recoveryToken,_this=this
recoveryToken=_arg.params.recoveryToken
if("Password"!==recoveryToken){recoveryToken=decodeURIComponent(recoveryToken)
JPasswordRecovery=KD.remote.api.JPasswordRecovery
return JPasswordRecovery.validate(recoveryToken,function(err,isValid){err||!isValid?KD.isLoggedIn()||new KDNotificationView({title:"Something went wrong.",content:(null!=err?err.message:void 0)||"That doesn't seem to be a valid recovery token!"}):warn("FIXME Add tell to Login app ~ GG @ kodingrouter")
return _this.clear("/")})}},"/:name?/Invitation/:inviteCode":function(_arg){var inviteCode
inviteCode=_arg.params.inviteCode
inviteCode=decodeURIComponent(inviteCode)
if(KD.isLoggedIn()){warn("FIXME Add tell to Login app ~ GG @ kodingrouter")
return _this.handleRoute("/",{entryPoint:KD.config.entryPoint})}return KD.remote.api.JInvitation.byCode(inviteCode,function(err,invite){var _ref
if(err||null==invite||"active"!==(_ref=invite.status)&&"sent"!==_ref){if(!KD.isLoggedIn()){err&&error(err)
new KDNotificationView({title:"Invalid invitation code!"})}}else warn("FIXME Add tell to Login app ~ GG @ kodingrouter")
return _this.clear("/")})},"/:name?/Verify/:confirmationToken":function(_arg){var confirmationToken,_this=this
confirmationToken=_arg.params.confirmationToken
confirmationToken=decodeURIComponent(confirmationToken)
return KD.remote.api.JEmailConfirmation.confirmByToken(confirmationToken,function(err){if(err){error(err)
KD.showError(err)}else new KDNotificationView({title:"Thanks for confirming your email address!"})
return _this.clear()})},"/:name?/InviteFriends":function(){if(KD.isLoggedIn()){this.handleRoute("/Activity",{entryPoint:KD.config.entryPoint})
return KD.introView?KD.introView.once("transitionend",function(){return KD.utils.wait(1200,function(){return new ReferrerModal})}):new ReferrerModal}return this.handleRoute("/Login")},"/member/:username":function(_arg){var username
username=_arg.params.username
return this.handleRoute("/"+username,{replaceState:!0})},"/:name?/Unsubscribe/:token/:email/:opt?":function(_arg){var email,opt,token,_ref,_this=this
_ref=_arg.params,token=_ref.token,email=_ref.email,opt=_ref.opt
opt=decodeURIComponent(opt)
email=decodeURIComponent(email)
token=decodeURIComponent(token)
return("email"===opt?KD.remote.api.JMail:KD.remote.api.JMailNotification).unsubscribeWithId(token,email,opt,function(err,content){var modal,title
if(err||!content){title="An error occured"
content="Invalid unsubscribe token provided."
log(err)}else title="E-mail settings updated"
modal=new KDModalView({title:title,overlay:!0,cssClass:"new-kdmodal",content:"<div class='modalformline'>"+content+"</div>",buttons:{Close:{style:"modal-clean-gray",callback:function(){return modal.destroy()}}}})
return _this.clear()})},"/:name":function(){var open
open=function(routeInfo,model){var _ref
switch(null!=model?null!=(_ref=model.bongo_)?_ref.constructorName:void 0:void 0){case"JAccount":return createContentHandler("Members")(routeInfo,[model])
case"JGroup":return createSectionHandler("Activity")(routeInfo,model)
default:return this.handleNotFound(routeInfo.params.name)}}
return function(routeInfo,state){var _this=this
return null!=state?open.call(this,routeInfo,state):KD.remote.cacheable(routeInfo.params.name,function(err,models){var model
models&&(model=models.first)
return open.call(_this,routeInfo,model)})}}()}
return routes}
return KodingRouter}(KDRouter)

var _ref,_ref1
KD.remote=new Bongo({precompileApi:null!=(_ref=KD.config.precompiledApi)?_ref:!1,resourceName:null!=(_ref1=KD.config.resourceName)?_ref1:"koding-social",getUserArea:function(){return KD.getSingleton("groupsController").getUserArea()},getSessionToken:function(){return $.cookie("clientId")},fetchName:function(){var cache,dash
cache={}
dash=Bongo.dash
return function(nameStr,callback){var model,name,_ref2,_this=this
if(null!=cache[nameStr]){_ref2=cache[nameStr],model=_ref2.model,name=_ref2.name
return callback(null,model,name)}return this.api.JName.one({name:nameStr},function(err,name){var models,queue
if(err)return callback(err)
if(null==name)return callback(new Error("Unknown name: "+nameStr))
"JUser"===name.slugs[0].constructorName&&(name=new _this.api.JName({name:name.name,slugs:[{constructorName:"JAccount",collectionName:"jAccounts",slug:name.name,usedAsPath:"profile.nickname"}]}))
models=[]
err=null
queue=name.slugs.map(function(slug){return function(){var selector,_base
selector={}
selector[slug.usedAsPath]=slug.slug
return"function"==typeof(_base=_this.api[slug.constructorName]).one?_base.one(selector,function(err,model){if(err)return callback(err)
null==model?err=new Error("Unable to find model: "+nameStr+" of type "+name.constructorName):models.push(model)
return queue.fin()}):void 0}})
return dash(queue,function(){return callback(err,models,name)})})}}(),mq:function(){var authExchange,broker,options,servicesEndpoint,_ref2,_ref3
_ref2=KD.config,_ref3=_ref2.broker,servicesEndpoint=_ref3.servicesEndpoint,authExchange=_ref2.authExchange
options={servicesEndpoint:servicesEndpoint,authExchange:authExchange,autoReconnect:!0}
return broker=new KDBroker.Broker(null,options)}()})

var ActivityController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityController=function(_super){function ActivityController(options,data){var groupChannel,groupsController,_this=this
null==options&&(options={})
ActivityController.__super__.constructor.call(this,options,data)
this.newItemsCount=0
this.flags={}
groupsController=KD.getSingleton("groupsController")
groupChannel=null
groupsController.on("GroupChannelReady",function(){null!=groupChannel&&groupChannel.close().off()
groupChannel=groupsController.groupChannel
return groupChannel.on("feed-new",function(activities){var activity,isOnActivityPage
return _this.emit("ActivitiesArrived",function(){var _i,_len,_results
_results=[]
for(_i=0,_len=activities.length;_len>_i;_i++){activity=activities[_i]
_results.push(KD.remote.revive(activity))}return _results}(),isOnActivityPage="/Activity"===KD.getSingleton("router").getCurrentPath(),isOnActivityPage?void 0:++_this.newItemsCount)})})
this.on("ActivityItemBlockUserClicked",this.bound("openBlockUserModal"))
this.on("ActivityItemMarkUserAsTrollClicked",this.bound("markUserAsTroll"))
this.on("ActivityItemUnMarkUserAsTrollClicked",this.bound("unmarkUserAsTroll"))
this.setPageTitleForActivities()
KD.getSingleton("appManager").on("AppIsBeingShown",function(appController,appView,appOptions){return"Activity"===appOptions.name?_this.clearNewItemsCount():void 0})}__extends(ActivityController,_super)
ActivityController.prototype.blockUser=function(accountId,duration,callback){return KD.whoami().blockUser(accountId,duration,callback)}
ActivityController.prototype.openBlockUserModal=function(nicknameOrAccountId){var calculateBlockingTime,changeButtonTitle,form,modal,_this=this
this.modal=modal=new KDModalViewWithForms({title:"Block User For a Time Period",content:"<div class='modalformline'>\nThis will block user from logging in to Koding(with all sub-groups).<br><br>\nYou can specify a duration to block user.\nEntry format: [number][S|H|D|T|M|Y] eg. 1M\n</div>",overlay:!0,cssClass:"modalformline",width:500,height:"auto",tabs:{forms:{BlockUser:{callback:function(){var blockingTime
blockingTime=calculateBlockingTime(modal.modalTabs.forms.BlockUser.inputs.duration.getValue())
return _this.blockUser(nicknameOrAccountId,blockingTime,function(err){if(err){warn(err)
return modal.modalTabs.forms.BlockUser.buttons.blockUser.hideLoader()}modal.destroy()
return new KDNotificationView({title:"User is blocked!"})})},buttons:{blockUser:{title:"Block User",style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12},callback:function(){return this.hideLoader()}},cancel:{title:"Cancel",style:"modal-cancel"}},fields:{duration:{label:"Block User For",itemClass:KDInputView,name:"duration",placeholder:"e.g. 1Y 1W 3D 2H...",keyup:function(){return changeButtonTitle(this.getValue())},change:function(){return changeButtonTitle(this.getValue())},validate:{rules:{required:!0,minLength:2,regExp:/\d[SHDTMY]+/i},messages:{required:"Please enter a time period",minLength:"You must enter one pair",regExp:"Entry should be in following format [number][S|H|D|T|M|Y] eg. 1M"}},iconOptions:{tooltip:{placement:"right",offset:2,title:"You can enter {#}H/D/W/M/Y,\nOrder is not sensitive."}}}}}}}})
form=modal.modalTabs.forms.BlockUser
form.on("FormValidationFailed",function(){})
form.buttons.blockUser.hideLoader()
changeButtonTitle=function(value){var blockingTime,button,date
blockingTime=calculateBlockingTime(value)
button=modal.modalTabs.forms.BlockUser.buttons.blockUser
if(blockingTime>0){date=new Date(Date.now()+blockingTime)
return button.setTitle("Block User to: "+date.toUTCString())}return button.setTitle("Block User")}
return calculateBlockingTime=function(value){var hour,numericalValue,timeCase,totalTimestamp,val,_i,_len,_ref
totalTimestamp=0
if(!value)return totalTimestamp
_ref=value.split(" ")
for(_i=0,_len=_ref.length;_len>_i;_i++){val=_ref[_i]
numericalValue=parseInt(val.slice(0,-1),10)||0
if(0!==numericalValue){hour=1e3*60*60*numericalValue
timeCase=val.charAt(val.length-1)
switch(timeCase.toUpperCase()){case"S":totalTimestamp=1e3
break
case"H":totalTimestamp=hour
break
case"D":totalTimestamp=24*hour
break
case"W":totalTimestamp=7*24*hour
break
case"M":totalTimestamp=30*24*hour
break
case"Y":totalTimestamp=365*24*hour}}}return totalTimestamp}}
ActivityController.prototype.unmarkUserAsTroll=function(data){var kallback
kallback=function(acc){return acc.markUserAsExempt(!1,function(err){return err?warn(err):new KDNotificationView({title:"@"+acc.profile.nickname+" won't be treated as a troll anymore!"})})}
return data.originId?KD.remote.cacheable("JAccount",data.originId,function(err,account){return account?kallback(account):void 0}):"JAccount"===data.bongo_.constructorName?kallback(data):void 0}
ActivityController.prototype.markUserAsTroll=function(data){var modal
return modal=new KDModalView({title:"MARK USER AS TROLL",content:"<div class='modalformline'>\nThis is what we call \"Trolling the troll\" mode.<br><br>\nAll of the troll's activity will disappear from the feeds, but the troll\nhimself will think that people still gets his posts/comments.<br><br>\nAre you sure you want to mark him as a troll?\n</div>",height:"auto",overlay:!0,buttons:{"YES, THIS USER IS DEFINITELY A TROLL":{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){var kallback
kallback=function(acc){return acc.markUserAsExempt(!0,function(err){if(err)return warn(err)
modal.destroy()
return new KDNotificationView({title:"@"+acc.profile.nickname+" marked as a troll!"})})}
return data.originId?KD.remote.cacheable("JAccount",data.originId,function(err,account){return account?kallback(account):void 0}):"JAccount"===data.bongo_.constructorName?kallback(data):void 0}}}})}
ActivityController.prototype.setPageTitleForActivities=function(){var _this=this
this.oldTitle=document.title
KD.getSingleton("windowController").addFocusListener(function(focused){return focused?document.title=_this.oldTitle:_this.updateDocTitle()})
return KD.getSingleton("mainController").ready(function(){return KD.getSingleton("activityController").on("ActivitiesArrived",function(){return KD.getSingleton("windowController").isFocused()?void 0:_this.updateDocTitle()})})}
ActivityController.prototype.updateDocTitle=function(){var itemCount
itemCount=KD.getSingleton("activityController").getNewItemsCount();-1===document.title.indexOf("Activity")&&(this.oldTitle=document.title)
return itemCount>0?document.title="("+itemCount+") Activity":void 0}
ActivityController.prototype.getNewItemsCount=function(){return this.newItemsCount}
ActivityController.prototype.clearNewItemsCount=function(){var isOnActivityPage
isOnActivityPage="/Activity"===KD.getSingleton("router").getCurrentPath()
if(this.flags.liveUpdates&&!isOnActivityPage)return!1
this.newItemsCount=0
return this.emit("NewItemsCounterCleared")}
return ActivityController}(KDObject)

var NotificationController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NotificationController=function(_super){function NotificationController(){var _this=this
NotificationController.__super__.constructor.apply(this,arguments)
KD.getSingleton("mainController").on("AccountChanged",function(){var _ref
_this.off("NotificationHasArrived")
null!=(_ref=_this.notificationChannel)&&_ref.close().off()
return _this.setListeners()})}var subjectMap
__extends(NotificationController,_super)
subjectMap=function(){return{JStatusUpdate:"<a href='#'>status</a>",JCodeSnip:"<a href='#'>code snippet</a>",JQuestionActivity:"<a href='#'>question</a>",JDiscussion:"<a href='#'>discussion</a>",JLinkActivity:"<a href='#'>link</a>",JPrivateMessage:"<a href='#'>private message</a>",JOpinion:"<a href='#'>opinion</a>",JTutorial:"<a href='#'>tutorial</a>",JComment:"<a href='#'>comment</a>",JReview:"<a href='#'>review</a>"}}
NotificationController.prototype.setListeners=function(){var deleteUserCookie,displayEmailConfirmedNotification,_this=this
this.notificationChannel=KD.remote.subscribe("notification",{serviceType:"notification",isExclusive:!0})
this.notificationChannel.on("message",function(notification){log("Notification has arrived",notification)
_this.emit("NotificationHasArrived",notification)
if(notification.contents){_this.emit(notification.event,notification.contents)
return _this.prepareNotification(notification)}})
this.on("GuestTimePeriodHasEnded",function(){return deleteUserCookie()})
deleteUserCookie=function(){return $.cookie("clientId",{erase:!0})}
displayEmailConfirmedNotification=function(modal){modal.off("KDObjectWillBeDestroyed")
new KDNotificationView({title:"Thanks for confirming your e-mail address",duration:5e3})
return modal.destroy()}
this.once("EmailShouldBeConfirmed",function(){var firstName,nickname,_ref,_this=this
_ref=KD.whoami().profile,firstName=_ref.firstName,nickname=_ref.nickname
return KD.getSingleton("appManager").tell("Account","displayConfirmEmailModal",name,nickname,function(modal){_this.once("EmailConfirmed",displayEmailConfirmedNotification.bind(_this,modal))
return modal.on("KDObjectWillBeDestroyed",deleteUserCookie.bind(_this))})})
this.on("UsernameChanged",function(_arg){var oldUsername,username
username=_arg.username,oldUsername=_arg.oldUsername
deleteUserCookie()
return new KDModalView({title:"Your username was changed",overlay:!0,content:'<div class="modalformline">\nYour username has been changed to <strong>'+username+"</strong>.\nYour <em>old</em> username <strong>"+oldUsername+"</strong> is\nnow available for registration by another Koding user.  You have\nbeen logged out.  If you wish, you may close this box, and save\nyour work locally.\n</div>",buttons:{Refresh:{style:"modal-clean-red",callback:function(){return location.replace("/Login")}},Close:{style:"modal-clean-gray",callback:function(){return modal.destroy()}}}})})
return this.on("UserBlocked",function(_arg){var blockedDate
blockedDate=_arg.blockedDate
new KDModalView({title:"Permission denied. You've been banned.",overlay:!0,content:'<div class="modalformline">\nYou have been blocked until <strong>'+blockedDate+"</strong>.\n</div>",buttons:{Ok:{style:"modal-clean-gray",callback:function(){$.cookie("clientId",{erase:!0})
return modal.destroy()}}}})
return this.utils.wait(1e4,function(){return $.cookie("clientId",{erase:!0})})})}
NotificationController.prototype.prepareNotification=function(notification){var actionType,actor,actorType,fetchSubjectObj,isMine,options,origin,subject,_ref,_this=this
options={}
_ref=notification.contents,origin=_ref.origin,subject=_ref.subject,actionType=_ref.actionType,actorType=_ref.actorType
isMine=(null!=origin?origin._id:void 0)&&origin._id===KD.whoami()._id?!0:!1
actor=notification.contents[actorType]
if(actor){fetchSubjectObj=function(callback){var args,method,_ref1
if(!subject||"JPrivateMessage"===subject.constructorName)return callback(null)
if("JComment"===(_ref1=subject.constructorName)||"JOpinion"===_ref1){method="fetchRelated"
args=subject.id}else{method="one"
args={_id:subject.id}}return KD.remote.api[subject.constructorName][method](args,callback)}
return KD.remote.cacheable(actor.constructorName,actor.id,function(err,actorAccount){return"unregistered"!==actorAccount.type?fetchSubjectObj(function(err,subjectObj){var actorName,originatorName,separator
if(!err&&subjectObj){actorName=KD.utils.getFullnameFromAccount(actorAccount)
options.title=function(){switch(actionType){case"reply":case"opinion":if(isMine)switch(subject.constructorName){case"JPrivateMessage":return""+actorName+" replied to your "+subjectMap()[subject.constructorName]+"."
default:return""+actorName+" commented on your "+subjectMap()[subject.constructorName]+"."}else switch(subject.constructorName){case"JPrivateMessage":return""+actorName+" also replied to your "+subjectMap()[subject.constructorName]+"."
default:originatorName=KD.utils.getFullnameFromAccount(origin)
if(actorName===originatorName){originatorName="their own"
separator=""}else separator="'s"
return""+actorName+" also commented on "+originatorName+separator+" "+subjectMap()[subject.constructorName]+"."}break
case"like":return""+actorName+" liked your "+subjectMap()[subject.constructorName]+"."
case"newMessage":this.emit("NewMessageArrived")
return""+actorName+" sent you a "+subjectMap()[subject.constructorName]+"."
case"groupRequestApproved":return"Your membership request to <a href='#'>"+subjectObj.title+"</a> has been approved."
case"groupAccessRequested":return""+actorName+" has requested access to <a href='#'>"+subjectObj.title+"</a>."
case"groupInvited":return""+actorName+" has invited you to <a href='#'>"+subjectObj.title+"</a>."
case"groupJoined":return""+actorName+" has joined <a href='/"+subjectObj.slug+"'>"+subjectObj.title+"</a>."
case"groupLeft":return""+actorName+" has left <a href='/"+subjectObj.slug+"'>"+subjectObj.title+"</a>."
default:if("follower"===actorType)return""+actorName+" started following you."}}.call(_this)
subject&&(options.click=function(){var suffix,view
view=this
if("JPrivateMessage"===subject.constructorName)return KD.getSingleton("router").handleRoute("/Inbox")
if("JOpinion"===subjectObj.constructor.name)return KD.remote.api.JOpinion.fetchRelated(subjectObj._id,function(err,post){KD.getSingleton("router").handleRoute("/Activity/"+post.slug,{state:post})
return view.destroy()})
if("JGroup"===subject.constructorName){suffix=""
"groupAccessRequested"===actionType&&(suffix="/Dashboard")
KD.getSingleton("router").handleRoute("/"+subjectObj.slug+suffix)
return view.destroy()}KD.getSingleton("router").handleRoute("/Activity/"+subjectObj.slug,{state:subjectObj})
return view.destroy()})
options.type=actionType||actorType||""
return _this.notify(options)}}):void 0})}}
NotificationController.prototype.notify=function(options){var notification
null==options&&(options={})
options.title||(options.title="notification arrived")
notification=new KDNotificationView({type:"tray",cssClass:"mini realtime "+options.type,duration:1e4,showTimer:!0,title:"<span></span>"+options.title,content:options.content||null})
return notification.once("click",options.click)}
return NotificationController}(KDObject)

var LinkController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LinkController=function(_super){function LinkController(){LinkController.__super__.constructor.apply(this,arguments)
this.linkHandlers={}}__extends(LinkController,_super)
LinkController.prototype.handleLinkClick=function(link){var JAccount,JGroup,JTag,data,group,route,slug,_ref
_ref=KD.remote.api,JAccount=_ref.JAccount,JGroup=_ref.JGroup,JTag=_ref.JTag
data="function"==typeof link.getData?link.getData():void 0
if(null!=data){route=function(){switch(data.constructor){case JAccount:return"/"+data.profile.nickname
case JGroup:return"/"+data.slug
case JTag:group=data.group,slug=data.slug
route=group===KD.defaultSlug?"":"/"+group
return route+="/Topics/"+slug}}()
return null!=route?KD.getSingleton("router").handleRoute(route,{state:data}):void 0}}
LinkController.prototype.registerLink=function(link){var handler,id,_this=this
id=link.getId()
link.on("LinkClicked",handler=function(){return _this.handleLinkClick(link)})
return this.linkHandlers[id]=handler}
LinkController.prototype.unregisterLink=function(link){var id
id=link.getId()
link.off(this.linkHandlers[id])
return delete this.linkHandlers[id]}
return LinkController}(KDController)

var PaymentController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentController=function(_super){function PaymentController(){_ref=PaymentController.__super__.constructor.apply(this,arguments)
return _ref}var required,sanitizeRecurlyErrors
__extends(PaymentController,_super)
sanitizeRecurlyErrors=function(fields,inputs,err){var ERRORS,e,inputEl,inputName,key,val,_i,_len,_results
ERRORS={address1:{input:inputs.address1,field:fields.address1},address2:{input:inputs.address2,field:fields.address2},city:{input:inputs.city,field:fields.city},state:{input:inputs.state,field:fields.state},country:{input:inputs.country,field:fields.country},first_name:{input:inputs.cardFirstName,field:fields.cardFirstName},last_name:{input:inputs.cardLastName,field:fields.cardLastName},number:{input:inputs.cardNumber,field:fields.cardNumber},zip:{input:inputs.zip,field:fields.zip},verification_value:{input:inputs.cardCV,field:fields.cardCV}}
for(key in ERRORS){val=ERRORS[key]
val.input.giveValidationFeedback(!1)}_results=[]
for(_i=0,_len=err.length;_len>_i;_i++){e=err[_i]
if("account.base"===e.field){val.input.showValidationError(e.message)
e.message.indexOf("card")>-1?_results.push(inputs.cardNumber.giveValidationFeedback(!0)):_results.push(void 0)}else _results.push(function(){var _results1
_results1=[]
for(key in ERRORS){val=ERRORS[key]
if(e.field.indexOf(key)>-1){val.input.giveValidationFeedback(!0)
inputName=val.input.inputLabel?val.input.inputLabel.getTitle():(inputEl=val.input.$()[0],inputEl.getAttribute("placeholder")||inputEl.getAttribute("name")||"")
_results1.push(val.input.showValidationError(""+inputName+" "+e.message))}else _results1.push(void 0)}return _results1}())}return _results}
required=function(msg){return{rules:{required:!0},messages:{required:msg}}}
PaymentController.prototype.addPaymentMethod=function(form,callback){var formData
formData=form.getFormData()
formData.cardNumber.indexOf("...")>-1&&delete formData.cardNumber
"XXX"===formData.cardCV&&delete formData.cardCV
return KD.remote.api.JPayment.setAccount(formData,function(err){if(err){sanitizeRecurlyErrors(form.fields,form.inputs,err)
return"function"==typeof callback?callback(!0):void 0}sanitizeRecurlyErrors(form.fields,form.inputs,[])
KD.remote.api.JPayment.getAccount({},function(e,r){var k,v,_results
if(!e){_results=[]
for(k in r){v=r[k]
form.inputs[k]&&_results.push(form.inputs[k].setValue(v))}return _results}})
return"function"==typeof callback?callback(!1):void 0})}
PaymentController.prototype.validatePaymentMethodForm=function(formData,callback){var button,form,onError,onSuccess
if(this.modal){form=this.modal.modalTabs.forms["Billing Info"]
button=this.modal.buttons.Save
onError=function(err){warn(err)
sanitizeRecurlyErrors(form.fields,form.inputs,err)
return button.hideLoader()}
onSuccess=this.modal.destroy.bind(this.modal)
return callback(formData,onError,onSuccess)}}
PaymentController.prototype.createPaymentMethodModal=function(data,callback){var form,k,modal,v,_this=this
this.modal=modal=new KDModalViewWithForms({title:"Billing Information",width:495,height:"auto",cssClass:"payments-modal",overlay:!0,buttons:{Save:{title:"Save",style:"modal-clean-green",type:"button",loader:{color:"#ffffff",diameter:12},callback:function(){return modal.modalTabs.forms["Billing Info"].submit()}}},tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{"Billing Info":{callback:function(formData){return _this.validatePaymentMethodForm(formData,callback)},fields:{cardFirstName:{label:"Name",name:"cardFirstName",placeholder:"First Name",defaultValue:KD.whoami().profile.firstName,validate:required("First name is required!"),nextElementFlat:{cardLastName:{name:"cardLastName",placeholder:"Last Name",defaultValue:KD.whoami().profile.lastName,validate:required("Last name is required!")}}},cardNumber:{label:"Card Number",name:"cardNumber",placeholder:"Card Number",defaultValue:"",validate:{event:"blur",rules:{creditCard:!0}},nextElementFlat:{cardCV:{name:"cardCV",placeholder:"CV Number",defaultValue:"",validate:{rules:{required:!0,minLength:3,regExp:/[0-9]/},messages:{required:"Card security code is required! (CVV)",minLength:"Card security code needs to be at least 3 digits!",regExp:"Card security code should be a number!"}}}}},cardMonth:{label:"Expire Date",itemClass:KDSelectBox,name:"cardMonth",selectOptions:__utils.getMonthOptions(),defaultValue:(new Date).getMonth()+2,nextElementFlat:{cardYear:{itemClass:KDSelectBox,name:"cardYear",selectOptions:__utils.getYearOptions((new Date).getFullYear(),(new Date).getFullYear()+25),defaultValue:(new Date).getFullYear()}}},address1:{label:"Address",name:"address1",placeholder:"Street Name & Number",defaultValue:"",validate:required("First address field is required!")},address2:{label:" ",name:"address2",placeholder:"Apartment/Suite Number"},city:{label:"City & State",name:"city",placeholder:"City Name",defaultValue:"",validate:required("City is required!"),nextElementFlat:{state:{name:"state",placeholder:"State",defaultValue:"",validate:required("State is required!")}}},zip:{label:"ZIP & Country",name:"zipCode",placeholder:"ZIP Code",defaultValue:"",validate:required("Zip code is required!"),nextElementFlat:{country:{name:"country",placeholder:"Country",defaultValue:"USA",validate:required("First address field is required!")}}}}}}}})
form=modal.modalTabs.forms["Billing Info"]
form.on("FormValidationFailed",function(){return modal.buttons.Save.hideLoader()})
form.inputs.cardNumber.on("ValidationError",function(){return this.parent.unsetClass("visa mastercard amex diners discover jcb")})
form.inputs.cardNumber.on("CreditCardTypeIdentified",function(type){var cardType
this.parent.unsetClass("visa mastercard amex diners discover jcb")
cardType=type.toLowerCase()
return this.parent.setClass(cardType)})
for(k in data){v=data[k]
form.inputs[k]&&form.inputs[k].setValue(v)}modal.on("KDObjectWillBeDestroyed",function(){return delete _this.modal})
return modal}
PaymentController.prototype.deleteAccountPaymentMethod=function(callback){return this.deleteModal=new KDModalView({title:"Warning",content:"<div class='modalformline'>Are you sure you want to delete your billing information?</div>",height:"auto",overlay:!0,buttons:{Yes:{loader:{color:"#ffffff",diameter:16},style:"modal-clean-gray",callback:function(){return KD.remote.api.JPayment.deleteAccountPaymentMethod({},function(){modal.destroy()
return"function"==typeof callback?callback():void 0})}}}})}
PaymentController.prototype.getBalance=function(type,group,cb){return"user"===type?KD.remote.api.JRecurlyPlan.getUserBalance(cb):KD.remote.api.JRecurlyPlan.getGroupBalance(group,cb)}
PaymentController.prototype.setBillingInfo=function(type,group,cb){return this.createPaymentMethodModal({},function(newData,onError,onSuccess){return"group"===type?group.setBillingInfo(newData,function(err,result){if(err)return onError(err)
onSuccess(result)
return cb(!0)}):KD.remote.api.JRecurlyPlan.setUserAccount(newData,function(err,result){if(err)return onError(err)
onSuccess(result)
return cb(!0)})})}
PaymentController.prototype.getBillingInfo=function(type,group,cb){return"group"===type?group.getBillingInfo(cb):KD.remote.api.JRecurlyPlan.getUserAccount(cb)}
PaymentController.prototype.createPaymentConfirmationModal=function(options,cb){var amount,balance,content,group,modal,needBilling,plan,subscription,type,_this=this
type=options.type,group=options.group,plan=options.plan,needBilling=options.needBilling,balance=options.balance,amount=options.amount,subscription=options.subscription
content=this.paymentWarning(balance,amount,subscription)
modal=new KDModalView({title:"Confirm VM Creation",content:"<div class='modalformline'>"+content+"</div>",cssClass:"vm-new",overlay:!0,buttons:{No:{title:"Cancel",cssClass:"modal-clean-gray",callback:function(){return modal.destroy()}},ReActivate:{title:"Re-activate Plan",cssClass:"modal-clean-green hidden",callback:function(){return subscription.resume(function(){modal.buttons.ReActivate.hide()
return modal.buttons.Yes.show()})}},Billing:{title:"Enter Billing Info",cssClass:"modal-clean-green hidden",callback:function(){return _this.setBillingInfo(type,group,function(success){if(success){"canceled"===subscription.status?modal.buttons.ReActivate.show():modal.buttons.Yes.show()
return modal.buttons.Billing.hide()}})}},Yes:{title:"OK, create the VM",cssClass:"modal-clean-green hidden",callback:function(){modal.destroy()
return _this.makePayment(type,plan,amount)}}}})
modal.on("KDModalViewDestroyed",function(){return cb()})
return needBilling?modal.buttons.Billing.show():"canceled"===subscription.status&&amount>0?modal.buttons.ReActivate.show():modal.buttons.Yes.show()}
PaymentController.prototype.paymentWarning=function(){var formatMoney
formatMoney=function(amount){return(amount/100).toFixed(2)}
return function(balance,amount,subscription){var chargeAmount,content
content=""
chargeAmount=Math.max(amount-balance,0)
if("canceled"===subscription.status&&amount>0){content+="<p>You have a canceled subscription for "+subscription.quantity+" x VM(s).                    To add a new VM, you should re-activate your subscription.</p>"
balance>0&&(content+="<p>You also have $"+formatMoney(balance)+" credited to your account.</p>")}else 0===amount?content+="<p>You are already subscribed for an extra VM.</p>":balance>0&&(content+="<p>You have $"+formatMoney(balance)+" credited to your account.</p>")
content+=chargeAmount>0?"<p>You will be charged for $"+formatMoney(chargeAmount)+".</p>":"<p>You won't be charged for this VM.</p>"
content+="<p>Do you want to continue?</p>"
return content}}()
PaymentController.prototype.getSubscriptionInfo=function(){var findActiveSubscription
findActiveSubscription=function(subs,planCode,callback){var info
info="none"
subs.every(function(sub){var _ref1
if(sub.planCode===planCode&&("canceled"===(_ref1=sub.status)||"active"===_ref1)){info=sub
return!1}return!0})
return callback(info)}
return function(group,type,planCode,callback){var info
info="none"
return"group"===type?group.checkPayment(function(err,subs){return findActiveSubscription(subs,planCode,callback)}):KD.remote.api.JRecurlySubscription.getUserSubscriptions(function(err,subs){return findActiveSubscription(subs,planCode,callback)})}}()
PaymentController.prototype.confirmPayment=function(type,plan,callback){var group,_this=this
null==callback&&(callback=function(){})
group=KD.getSingleton("groupsController").getCurrentGroup()
return group.canCreateVM({type:type,planCode:plan.code},function(err,status){return _this.getSubscriptionInfo(group,type,plan.code,function(subscription){return status?_this.createPaymentConfirmationModal({needBilling:!1,balance:0,amount:0,type:type,group:group,plan:plan,subscription:subscription},callback):_this.getBillingInfo(type,group,function(err,account){var needBilling
needBilling=err||!account||!account.cardNumber
return _this.getBalance(type,group,function(err,balance){err&&(balance=0)
return _this.createPaymentConfirmationModal({amount:plan.feeMonthly,type:type,group:group,plan:plan,subscription:subscription,needBilling:needBilling,balance:balance},callback)})})})})}
PaymentController.prototype.makePayment=function(type,plan,amount){var group,vmController
vmController=KD.getSingleton("vmController")
group=KD.getSingleton("groupsController").getCurrentGroup()
return 0===amount?vmController.createGroupVM(type,plan.code):"group"===type?group.makePayment({plan:plan.code},function(err){return err?void 0:vmController.createGroupVM(type,plan.code)}):plan.subscribe({},function(err){return err?void 0:vmController.createGroupVM(type,plan.code)})}
PaymentController.prototype.createDeleteConfirmationModal=function(subscription,cb){var content,modal
content="canceled"===subscription.status?"<p>Removing this VM will <b>destroy</b> all the data in\nthis VM including all other users in filesystem. <b>Please\nbe careful this process cannot be undone.</b></p>\n\n<p>Do you want to continue?</p>":"<p>Removing this VM will <b>destroy</b> all the data in\nthis VM including all other users in filesystem. <b>Please\nbe careful this process cannot be undone.</b></p>\n\n<p>You can 'pause' your plan instead, and continue using it\nuntil "+dateFormat(subscription.renew)+".</p>\n\n<p>What do you want to do?</p>"
modal=new KDModalView({title:"Confirm VM Deletion",content:"<div class='modalformline'>"+content+"</div>",cssClass:"vm-delete",overlay:!0,buttons:{No:{title:"Cancel",cssClass:"modal-clean-gray",callback:function(){modal.destroy()
return cb(!1)}},Pause:{title:"Pause Plan",cssClass:"modal-clean-green hidden",callback:function(){return subscription.cancel(function(){modal.destroy()
return cb(!1)})}},Delete:{title:"Delete VM",cssClass:"modal-clean-red",callback:function(){modal.destroy()
return cb(!0)}}}})
return"canceled"!==subscription.status?modal.buttons.Pause.show():void 0}
PaymentController.prototype.deleteVM=function(vmInfo,callback){var group,type,_this=this
group=KD.getSingleton("groupsController").getCurrentGroup()
type=vmInfo.planOwner.indexOf("user_")>-1?"user":"group"
return this.getSubscriptionInfo(group,type,vmInfo.planCode,function(subscription){return _this.createDeleteConfirmationModal(subscription,callback)})}
return PaymentController}(KDController)

var OAuthController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OAuthController=function(_super){function OAuthController(){_ref=OAuthController.__super__.constructor.apply(this,arguments)
return _ref}var notify
__extends(OAuthController,_super)
OAuthController.prototype.openPopup=function(provider){KD.getSingleton("mainController").isLoggingIn(!0)
return KD.remote.api.OAuth.getUrl(provider,function(err,url){var name,newWindow,size
if(err)return notify(err)
name="Login"
size="height=643,width=1143"
newWindow=window.open(url,name,size)
newWindow||notify("Please disable your popup blocker and try again.")
return newWindow.focus()})}
OAuthController.prototype.authCompleted=function(err,provider){var mainController
mainController=KD.getSingleton("mainController")
return err?notify(err):mainController.emit("ForeignAuthCompleted",provider)}
notify=function(err){var message
message=err?"Error: "+err:"Something went wrong"
return new KDNotificationView({title:message})}
return OAuthController}(KDController)

var ApplicationTabView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ApplicationTabView=function(_super){function ApplicationTabView(options,data){var appManager,focusActivePane,mainView,_this=this
null==options&&(options={})
null==options.resizeTabHandles&&(options.resizeTabHandles=!0)
null==options.lastTabHandleMargin&&(options.lastTabHandleMargin=40)
null==options.sortable&&(options.sortable=!0)
null==options.closeAppWhenAllTabsClosed&&(options.closeAppWhenAllTabsClosed=!0)
null==options.saveSession&&(options.saveSession=!1)
options.sessionName||(options.sessionName="")
options.cssClass=KD.utils.curry("application-tabview",options.cssClass)
ApplicationTabView.__super__.constructor.call(this,options,data)
appManager=KD.getSingleton("appManager")
this.isSessionEnabled=options.saveSession&&options.sessionName
this.isSessionEnabled&&this.initSession()
this.on("PaneAdded",function(pane){var plusHandle,tabHandle,tabView
_this.tabHandleContainer.repositionPlusHandle(_this.handles)
_this.isSessionEnabled&&_this.sessionData&&_this.updateSession()
tabView=_this
pane.on("KDTabPaneDestroy",function(){0===tabView.panes.length-1&&options.closeAppWhenAllTabsClosed&&appManager.quit(appManager.getFrontApp())
return tabView.tabHandleContainer.repositionPlusHandle(tabView.handles)})
tabHandle=pane.tabHandle
plusHandle=_this.getOptions().tabHandleContainer.plusHandle
tabHandle.on("DragInAction",function(){return tabHandle.dragIsAllowed?plusHandle.hide():void 0})
return tabHandle.on("DragFinished",function(){return plusHandle.show()})})
this.on("SaveSessionData",function(data){return _this.isSessionEnabled?_this.appStorage.setValue("sessions",data):void 0})
focusActivePane=function(pane){var tabView,_ref
tabView=pane.getMainView().tabView
return _this===tabView?null!=(_ref=_this.getActivePane())?"function"==typeof _ref.getHandle?_ref.getHandle().$().click():void 0:void 0:void 0}
mainView=KD.getSingleton("mainViewController").getView()
mainView.mainTabView.on("PaneDidShow",focusActivePane)
this.on("KDObjectWillBeDestroyed",function(){return mainView.mainTabView.off("PaneDidShow",focusActivePane)})}__extends(ApplicationTabView,_super)
ApplicationTabView.prototype.initSession=function(){var _this=this
this.appStorage=new AppStorage(this.getOptions().sessionName,"1.0")
return this.appStorage.fetchStorage(function(){var data
data=_this.appStorage.getValue("sessions")
_this.sessionData=data||{}
return _this.restoreSession(data)})}
ApplicationTabView.prototype.updateSession=function(){return this.getDelegate().emit("UpdateSessionData",this.panes,this.sessionData)}
ApplicationTabView.prototype.restoreSession=function(){return this.getDelegate().emit("SessionDataCreated",this.sessionData)}
return ApplicationTabView}(KDTabView)

var ApplicationTabHandleHolder,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ApplicationTabHandleHolder=function(_super){function ApplicationTabHandleHolder(options,data){var _this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("application-tab-handle-holder",options.cssClass)
options.bind="mouseenter mouseleave"
null==options.addPlusHandle&&(options.addPlusHandle=!0)
ApplicationTabHandleHolder.__super__.constructor.call(this,options,data)
options.addPlusHandle&&this.on("PlusHandleClicked",function(){return _this.getDelegate().addNewTab()})}__extends(ApplicationTabHandleHolder,_super)
ApplicationTabHandleHolder.prototype.viewAppended=function(){return this.getOptions().addPlusHandle?this.addPlusHandle():void 0}
ApplicationTabHandleHolder.prototype.addPlusHandle=function(){var _this=this
return this.addSubView(this.plusHandle=new KDCustomHTMLView({cssClass:"kdtabhandle visible-tab-handle plus",partial:"<span class='icon'></span>",delegate:this,click:function(){return _this.emit("PlusHandleClicked")}}))}
ApplicationTabHandleHolder.prototype.repositionPlusHandle=function(handles){var handlesLength,_ref
handlesLength=handles.length
return handlesLength?null!=(_ref=this.plusHandle)?_ref.$().insertAfter(handles[handlesLength-1].$()):void 0:void 0}
return ApplicationTabHandleHolder}(KDView)

var SharePopup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SharePopup=function(_super){function SharePopup(options,data){var urlInput,_base,_base1,_base2,_base3,_base4,_base5,_base6,_base7,_this=this
null==options&&(options={})
null==options.cssClass&&(options.cssClass="share-popup")
null==options.shortenURL&&(options.shortenURL=!0)
null==options.url&&(options.url="")
null==options.twitter&&(options.twitter={})
null==(_base=options.twitter).enabled&&(_base.enabled=!0)
null==(_base1=options.twitter).text&&(_base1.text="")
null==options.facebook&&(options.facebook={})
null==(_base2=options.facebook).enabled&&(_base2.enabled=!0)
null==options.linkedin&&(options.linkedin={})
null==(_base3=options.linkedin).enabled&&(_base3.enabled=!0)
null==(_base4=options.linkedin).title&&(_base4.title="Koding.com")
null==(_base5=options.linkedin).text&&(_base5.text=options.url||"The next generation development environment")
null==options.newTab&&(options.newTab={})
null==(_base6=options.newTab).enabled&&(_base6.enabled=!0)
null==(_base7=options.newTab).url&&(_base7.url=options.url)
SharePopup.__super__.constructor.call(this,options,data)
this.urlInput=urlInput=new KDInputView({cssClass:"share-input",type:"text",placeholder:"building url...",attributes:{readonly:!0},width:50})
if(options.shortenURL)KD.utils.shortenUrl(options.url,function(shorten){_this.urlInput.setValue(shorten)
return _this.urlInput.$().select()})
else{urlInput.setValue(options.url)
urlInput.$().select()}this.once("viewAppended",function(){return _this.urlInput.$().select()})
this.twitterShareLink=this.buildTwitterShareLink()
this.facebookShareLink=this.buildFacebookShareLink()
this.linkedInShareLink=this.buildLinkedInShareLink()
this.openNewTabButton=this.buildNewTabLink()}__extends(SharePopup,_super)
SharePopup.prototype.buildURLInput=function(){var options,_this=this
this.urlInput=new KDInputView({cssClass:"share-input",type:"text",placeholder:"building url...",attributes:{readonly:!0},width:50})
options=this.getOptions()
if(options.shortenURL)return KD.utils.shortenUrl(options.url,function(shorten){_this.urlInput.setValue(shorten)
_this.urlInput.$().select()
return _this.urlInput})
this.urlInput.setValue(options.url)
this.urlInput.$().select()
return this.urlInput}
SharePopup.prototype.buildTwitterShareLink=function(){var link,shareText
if(this.getOptions().twitter.enabled){shareText=this.getOptions().twitter.text||this.getOptions().text
link="https://twitter.com/intent/tweet?text="+encodeURIComponent(shareText)+"&via=koding&source=koding"
return this.generateView(link,"twitter")}return new KDView}
SharePopup.prototype.buildFacebookShareLink=function(){var link
if(this.getOptions().facebook.enabled){link="https://www.facebook.com/sharer/sharer.php?u="+encodeURIComponent(this.getOptions().url)
return this.generateView(link,"facebook")}return new KDView}
SharePopup.prototype.buildLinkedInShareLink=function(){var link
if(this.getOptions().linkedin.enabled){link="http://www.linkedin.com/shareArticle?mini=true&url="+encodeURIComponent(this.getOptions().url)+"&title="+encodeURIComponent(this.getOptions().linkedin.title)+"&summary="+encodeURIComponent(this.getOptions().linkedin.text)+"&source="+location.origin
return this.generateView(link,"linkedin")}return new KDView}
SharePopup.prototype.generateView=function(link,provider){return new KDCustomHTMLView({tagName:"a",cssClass:"share-"+provider+" icon-link",partial:"<span class='icon'></span>",click:function(event){KD.utils.stopDOMEvent(event)
return window.open(link,""+provider+"-share-dialog","width=626,height=436,left="+Math.floor(screen.width/2-250)+",top="+Math.floor(screen.height/2-175))}})}
SharePopup.prototype.buildNewTabLink=function(){return this.getOptions().newTab.enabled?new CustomLinkView({cssClass:"icon-link",title:"",href:this.getOptions().newTab.url,target:this.getOptions().newTab.url,icon:{cssClass:"new-page",placement:"right"}}):new KDView}
SharePopup.prototype.pistachio=function(){return"{{> this.urlInput}}\n{{> this.openNewTabButton}}\n{{> this.twitterShareLink}}\n{{> this.facebookShareLink}}\n{{> this.linkedInShareLink}}"}
return SharePopup}(JView)

var FacebookShareLink,LinkedInShareLink,ShareLink,TwitterShareLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ShareLink=function(_super){function ShareLink(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("share-icon "+options.provider,options.cssClass)
options.partial='<span class="icon"></span>'
null==options.iconOnly&&(options.iconOnly=!0)
ShareLink.__super__.constructor.call(this,options,data)}__extends(ShareLink,_super)
ShareLink.prototype.click=function(event){var provider
KD.utils.stopDOMEvent(event)
provider=this.getOptions().provider
window.open(this.getUrl(),""+provider+"-share-dialog","width=626,height=436,left="+Math.floor(screen.width/2-250)+",top="+Math.floor(screen.height/2-175))
return KD.kdMixpanel.track(""+provider+" Share Link Clicked",{$user:KD.nick()})}
return ShareLink}(KDButtonView)
TwitterShareLink=function(_super){function TwitterShareLink(options,data){null==options&&(options={})
options.provider="twitter"
TwitterShareLink.__super__.constructor.call(this,options,data)}__extends(TwitterShareLink,_super)
TwitterShareLink.prototype.getUrl=function(){var text,url
url=this.getOptions().url
text="Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! "+url
return"https://twitter.com/intent/tweet?text="+encodeURIComponent(text)+"&via=koding&source=koding"}
return TwitterShareLink}(ShareLink)
FacebookShareLink=function(_super){function FacebookShareLink(options,data){null==options&&(options={})
options.provider="facebook"
FacebookShareLink.__super__.constructor.call(this,options,data)}__extends(FacebookShareLink,_super)
FacebookShareLink.prototype.getUrl=function(){return"https://www.facebook.com/sharer/sharer.php?u="+encodeURIComponent(this.getOptions().url)}
return FacebookShareLink}(ShareLink)
LinkedInShareLink=function(_super){function LinkedInShareLink(options,data){null==options&&(options={})
options.provider="linkedin"
LinkedInShareLink.__super__.constructor.call(this,options,data)}__extends(LinkedInShareLink,_super)
LinkedInShareLink.prototype.getUrl=function(){var text,url
url=this.getOptions().url
text="Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! "+url
return"http://www.linkedin.com/shareArticle?mini=true&url="+encodeURIComponent(url)+"&title="+encodeURIComponent(this.title)+"&summary="+encodeURIComponent(text)+"&source="+location.origin}
LinkedInShareLink.prototype.title="Join me @koding!"
return LinkedInShareLink}(ShareLink)

var LinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LinkView=function(_super){function LinkView(options,data){null==options&&(options={})
options.tagName||(options.tagName="a")
data||(data={fake:!0})
data=this._addDefaultProfile(data)
LinkView.__super__.constructor.call(this,options,data)
data.fake&&options.origin&&this.loadFromOrigin(options.origin)
KD.getSingleton("linkController").registerLink(this)}__extends(LinkView,_super)
LinkView.prototype._addDefaultProfile=function(data){var _base,_base1
data.profile||(data.profile={})
null==(_base=data.profile).firstName&&(_base.firstName="a koding")
null==(_base1=data.profile).lastName&&(_base1.lastName="user")
return data}
LinkView.prototype.click=function(event){this.emit("LinkClicked")
return this.utils.stopDOMEvent(event)}
LinkView.prototype.destroy=function(){LinkView.__super__.destroy.apply(this,arguments)
return KD.getSingleton("linkController").unregisterLink(this)}
LinkView.prototype.loadFromOrigin=function(origin){var callback,kallback,_this=this
callback=function(data){data=_this._addDefaultProfile(data)
_this.setData(data)
"function"==typeof data.on&&data.on("update",_this.bound("render"))
_this.render()
return _this.emit("OriginLoadComplete",data)}
kallback=function(err,originModel){Array.isArray(originModel)&&(originModel=originModel.first)
return originModel?callback(originModel):warn("couldn't get the model via cacheable",origin)}
return origin.constructorName?KD.remote.cacheable(origin.constructorName,origin.id,kallback):"string"==typeof origin?KD.remote.cacheable(origin,kallback):callback(origin)}
LinkView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
return LinkView}(KDCustomHTMLView)

var CustomLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CustomLinkView=function(_super){function CustomLinkView(options,data){var _base,_base1
null==options&&(options={})
null==data&&(data={})
options.tagName||(options.tagName="a")
options.cssClass=KD.utils.curry("custom-link-view",options.cssClass)
null==data.title&&(data.title=options.title)
null==options.attributes&&(options.attributes={})
null!=options.href&&(options.attributes.href=options.href)
null!=options.target&&(options.attributes.target=options.target)
if(options.icon){options.icon||(options.icon={});(_base=options.icon).placement||(_base.placement="left");(_base1=options.icon).cssClass||(_base1.cssClass="")}CustomLinkView.__super__.constructor.call(this,options,data)
if(options.icon){options.icon.tagName="span"
options.icon.cssClass=KD.utils.curry("icon",options.icon.cssClass)
this.icon=new KDCustomHTMLView(options.icon)}}__extends(CustomLinkView,_super)
CustomLinkView.prototype.viewAppended=JView.prototype.viewAppended
CustomLinkView.prototype.pistachio=function(){var data,options,tmpl
options=this.getOptions()
data=this.getData()
null==data.title&&(data.title=options.attributes.href)
tmpl="{{> this.icon}}"
options.icon&&data.title?"left"===options.icon.placement?tmpl+="{span.title{#(title)}}":tmpl="{span.title{#(title)}}"+tmpl:!options.icon&&data.title&&(tmpl="{span.title{#(title)}}")
return tmpl}
return CustomLinkView}(KDCustomHTMLView)

var LinkGroup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LinkGroup=function(_super){function LinkGroup(options,data){var _ref
null==options&&(options={})
options.tagName="div"
options.cssClass="link-group"
options.itemClass||(options.itemClass=ProfileLinkView)
options.itemOptions||(options.itemOptions={})
options.itemsToShow||(options.itemsToShow=3)
options.totalCount||(options.totalCount=(null!=data?data.length:void 0)||(null!=(_ref=options.group)?_ref.length:void 0)||0)
options.hasMore=options.totalCount>options.itemsToShow
null==options.separator&&(options.separator=", ")
options.suffix||(options.suffix="")
LinkGroup.__super__.constructor.call(this,options,data)
this.getData()?this.createParticipantSubviews():options.group&&this.loadFromOrigins(options.group)}__extends(LinkGroup,_super)
LinkGroup.prototype.loadFromOrigins=function(group){var callback,lastFour,_ref,_this=this
callback=function(data){_this.setData(data)
_this.createParticipantSubviews()
return _this.render()}
if(null!=(_ref=group[0])?_ref.constructorName:void 0){lastFour=group.slice(-4)
return KD.remote.cacheable(lastFour,function(err,bucketContents){return err?warn(err):callback(bucketContents)})}return callback(group)}
LinkGroup.prototype.createParticipantSubviews=function(){var index,itemClass,itemOptions,participant,participants,_i,_len,_ref,_ref1
_ref=this.getOptions(),itemClass=_ref.itemClass,itemOptions=_ref.itemOptions
participants=this.getData()
for(index=_i=0,_len=participants.length;_len>_i;index=++_i){participant=participants[index]
if(participant)if("ObjectRef"===(null!=participant?null!=(_ref1=participant.bongo_)?_ref1.constructorName:void 0:void 0)){itemOptions.origin=participant
this["participant"+index]=new itemClass(itemOptions)}else this["participant"+index]=new itemClass(itemOptions,participant)}if(this.participant0){this.setTemplate(this.pistachio())
return this.template.update()}}
LinkGroup.prototype.createMoreLink=function(){var group,totalCount,_ref,_this=this
this.more&&this.more.destroy()
_ref=this.getOptions(),totalCount=_ref.totalCount,group=_ref.group
return this.more=new KDCustomHTMLView({tagName:"a",cssClass:"more",partial:""+(totalCount-3)+" more",attributes:{href:"#",title:"Click to view..."},click:function(){return new ShowMoreDataModalView({group:group},_this.getData())}})}
LinkGroup.prototype.pistachio=function(){var count,group,hasMore,participants,separator,suffix,totalCount,_ref
participants=this.getData()
_ref=this.getOptions(),suffix=_ref.suffix,hasMore=_ref.hasMore,totalCount=_ref.totalCount,group=_ref.group,separator=_ref.separator
this.createMoreLink()
count=totalCount
4!==count||this.participant3||(count=1e3)
switch(count){case 0:return""
case 1:return"{{> this.participant0}}"+suffix
case 2:return"{{> this.participant0}} and {{> this.participant1}}"+suffix
case 3:return"{{> this.participant0}}"+separator+"{{> this.participant1}} and {{> this.participant2}}"+suffix
case 4:return"{{> this.participant0}}"+separator+"{{> this.participant1}}"+separator+"{{> this.participant2}} and {{> this.participant3}}"+suffix
default:return"{{> this.participant0}}"+separator+"{{> this.participant1}}"+separator+"{{> this.participant2}} and {{> this.more}}"+suffix}}
LinkGroup.prototype.render=function(){return this.createParticipantSubviews()}
return LinkGroup}(KDCustomHTMLView)

var ProfileLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ProfileLinkView=function(_super){function ProfileLinkView(options,data){var _this=this
null==options&&(options={})
null==options.noTooltip&&(options.noTooltip=!0)
options.noTooltip||(this.avatarPreview={constructorName:AvatarTooltipView,options:{delegate:this,origin:options.origin},data:data})
this.avatarPreview&&(options.tooltip||(options.tooltip={view:options.noTooltip?null:this.avatarPreview,cssClass:"avatar-tooltip",animate:!0,placement:"top",direction:"left"}))
ProfileLinkView.__super__.constructor.call(this,options,data)
null!=this.avatarPreview&&this.on("TooltipReady",function(){return _this.utils.defer(function(){var _ref,_ref1,_ref2
return null!=(null!=(_ref=_this.getData())?_ref.profile.nickname:void 0)?null!=(_ref1=_this.tooltip)?null!=(_ref2=_ref1.getView())?_ref2.updateData(_this.getData()):void 0:void 0:void 0})})
this.setClass("profile")}__extends(ProfileLinkView,_super)
ProfileLinkView.prototype.render=function(){var nickname,_ref
nickname=null!=(_ref=this.getData().profile)?_ref.nickname:void 0
nickname&&this.setAttribute("href","/"+nickname)
return ProfileLinkView.__super__.render.apply(this,arguments)}
ProfileLinkView.prototype.pistachio=function(){return ProfileLinkView.__super__.pistachio.call(this,"{{#(profile.firstName) + ' ' + #(profile.lastName)}}")}
return ProfileLinkView}(LinkView)

var ProfileTextView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ProfileTextView=function(_super){function ProfileTextView(options){options.tagName||(options.tagName="span")
ProfileTextView.__super__.constructor.apply(this,arguments)}__extends(ProfileTextView,_super)
ProfileTextView.prototype.click=function(){return!0}
return ProfileTextView}(ProfileLinkView)

var ProfileTextGroup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ProfileTextGroup=function(_super){function ProfileTextGroup(options){null==options&&(options={})
options.tagName||(options.tagName="span")
options.cssClass||(options.cssClass="link-group")
options.itemClass||(options.itemClass=ProfileTextView)
ProfileTextGroup.__super__.constructor.call(this,options)}__extends(ProfileTextGroup,_super)
ProfileTextGroup.prototype.click=function(){return!0}
return ProfileTextGroup}(LinkGroup)

var TagLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TagLinkView=function(_super){function TagLinkView(options,data){var _this=this
null==options&&(options={})
null==options.expandable&&(options.expandable=!0)
null==options.clickable&&(options.clickable=!0)
!options.expandable&&(null!=data?data.title.length:void 0)>16&&(options.tooltip={title:data.title,placement:"above",delayIn:120})
TagLinkView.__super__.constructor.call(this,options,data)
"function"==typeof data.on&&data.on("TagIsDeleted",function(){return _this.destroy()})
this.setClass("ttag expandable")
options.expandable||this.unsetClass("expandable")
this.on("viewAppended",function(){var _ref
return null!=(_ref=_this.tooltip)?_ref.setPosition():void 0})}__extends(TagLinkView,_super)
TagLinkView.prototype.pistachio=function(){return TagLinkView.__super__.pistachio.call(this,"{{#(title)}}")}
return TagLinkView}(LinkView)

var AppLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppLinkView=function(_super){function AppLinkView(options,data){var _this=this
null==options&&(options={})
options.cssClass="app"
AppLinkView.__super__.constructor.call(this,options,data)
this.on("OriginLoadComplete",function(data){log(data)
_this.setTooltip({title:data.body,placement:"above",delayIn:120,offset:1})
return"function"==typeof data.on?data.on("AppIsDeleted",function(){return _this.destroy()}):void 0})}__extends(AppLinkView,_super)
AppLinkView.prototype.pistachio=function(){return AppLinkView.__super__.pistachio.call(this,"{{#(title)}}")}
AppLinkView.prototype.click=function(){var app
app=this.getData()
return KD.getSingleton("appManager").tell("Apps","createContentDisplay",app)}
return AppLinkView}(LinkView)

var ActivityChildViewTagGroup,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityChildViewTagGroup=function(_super){function ActivityChildViewTagGroup(){_ref=ActivityChildViewTagGroup.__super__.constructor.apply(this,arguments)
return _ref}__extends(ActivityChildViewTagGroup,_super)
ActivityChildViewTagGroup.prototype.pistachio=function(){var group,hasMore,participants,totalCount,_ref1
participants=this.getData()
_ref1=this.getOptions(),hasMore=_ref1.hasMore,totalCount=_ref1.totalCount,group=_ref1.group
this.createMoreLink()
switch(totalCount){case 0:return""
case 1:return"in {{> this.participant0}}"
case 2:return"in {{> this.participant0}}{{> this.participant1}}"
case 3:return"in {{> this.participant0}}{{> this.participant1}}{{> this.participant2}}"
case 4:return"in {{> this.participant0}}{{> this.participant1}}{{> this.participant2}}{{> this.participant3}}"
default:return"in {{> this.participant0}}{{> this.participant1}}{{> this.participant2}}and {{> this.more}}"}}
return ActivityChildViewTagGroup}(LinkGroup)

var AutoCompleteProfileTextView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AutoCompleteProfileTextView=function(_super){function AutoCompleteProfileTextView(){_ref=AutoCompleteProfileTextView.__super__.constructor.apply(this,arguments)
return _ref}__extends(AutoCompleteProfileTextView,_super)
AutoCompleteProfileTextView.prototype.highlightMatch=function(str,isNick){var userInput,_this=this
null==isNick&&(isNick=!1)
userInput=this.getOptions().userInput
return userInput?str=str.replace(RegExp(userInput,"gi"),function(match){isNick&&_this.setClass("nick-matches")
return"<b>"+match+"</b>"}):str}
AutoCompleteProfileTextView.prototype.pistachio=function(){var name
name=KD.utils.getFullnameFromAccount(this.getData())
return""+this.highlightMatch(name)+(this.getOptions().shouldShowNick?"<span class='nick'>\n  (@{{this.highlightMatch(#(profile.nickname), true)}})\n</span>":"")}
return AutoCompleteProfileTextView}(ProfileTextView)

var GroupLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupLinkView=function(_super){function GroupLinkView(options,data){null==options&&(options={})
GroupLinkView.__super__.constructor.call(this,options,data)
this.setClass("profile")}__extends(GroupLinkView,_super)
GroupLinkView.prototype.render=function(){var slug
slug=this.getData().slug
this.setAttribute("href","/"+slug)
this.setAttribute("target","_blank")
return GroupLinkView.__super__.render.apply(this,arguments)}
GroupLinkView.prototype.pistachio=function(){return GroupLinkView.__super__.pistachio.call(this,"{{#(title)}}")}
GroupLinkView.prototype.click=function(){}
return GroupLinkView}(LinkView)

var SplitView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SplitView=function(_super){function SplitView(){_ref=SplitView.__super__.constructor.apply(this,arguments)
return _ref}__extends(SplitView,_super)
SplitView.prototype._windowDidResize=function(){var _this=this
return this.utils.wait(300,function(){_this._setSize(_this._getParentSize())
_this._resizePanels()
_this._repositionPanels()
_this._setPanelPositions()
return _this.getOptions().resizable?_this._repositionResizers():void 0})}
return SplitView}(KDSplitView)

var SlidingSplit,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SlidingSplit=function(_super){function SlidingSplit(){_ref=SlidingSplit.__super__.constructor.apply(this,arguments)
return _ref}__extends(SlidingSplit,_super)
SlidingSplit.prototype.viewAppended=function(){this.scrollContainer=this.getOptions().scrollContainer||this.parent
return SlidingSplit.__super__.viewAppended.apply(this,arguments)}
SlidingSplit.prototype.splitPanel=function(index){index||(index=this.getPanelIndex(this.focusedPanel))
this.setFocusedPanel(SlidingSplit.__super__.splitPanel.call(this,index))
this._resizePanels()
this._repositionPanels()
return this.getOptions().resizable?this._repositionResizers():void 0}
SlidingSplit.prototype.removePanel=function(){if(SlidingSplit.__super__.removePanel.apply(this,arguments)){this._resizePanels()
this._repositionPanels()
if(this.getOptions().resizable)return this._repositionResizers()}}
SlidingSplit.prototype.setFocusedPanel=function(panel){var p,_i,_len,_ref1
if(panel){this.focusedPanel=panel
_ref1=this.panels
for(_i=0,_len=_ref1.length;_len>_i;_i++){p=_ref1[_i]
p.unsetClass("focused")}panel.setClass("focused")
this.scrollToFocusedPanel()
this.setKeyView()
return this.emit("PanelIsFocused",panel)}}
SlidingSplit.prototype.focusNextPanel=function(){var focusedIndex
focusedIndex=this.getPanelIndex(this.focusedPanel)
return focusedIndex<this.panels.length-1?this.setFocusedPanel(this.panels[focusedIndex+1]):void 0}
SlidingSplit.prototype.focusPrevPanel=function(){var focusedIndex
focusedIndex=this.getPanelIndex(this.focusedPanel)
return focusedIndex>0?this.setFocusedPanel(this.panels[focusedIndex-1]):void 0}
SlidingSplit.prototype.focusByIndex=function(){return this.setFocusedPanel(this.panels[i])}
SlidingSplit.prototype.scrollToFocusedPanel=function(){var container,duration,edge1,edge2,offset1,offset2,options1,options2,panel
panel=this.focusedPanel
container=this.scrollContainer
duration=this.getOptions().duration||150
offset1=panel._getOffset()
offset2=panel._getOffset()+panel._getSize()
if(this.isVertical()){edge1=container.getScrollLeft()
edge2=edge1+container.getWidth()-20
options1={left:offset1-2*panel._getSize(),duration:duration}
options2={left:offset1,duration:duration}}else{edge1=container.getScrollTop()
edge2=edge1+container.getHeight()-20
options1={top:offset1-2*panel._getSize(),duration:duration}
options2={top:offset1,duration:duration}}if(offset1>edge1&&edge2>offset1){if(offset2>edge2)return container.scrollTo(options1)}else{edge1>offset1&&container.scrollTo(options2)
if(offset1>edge2)return container.scrollTo(options1)}}
SlidingSplit.prototype.keyDown=function(e){var focusedIndex,i,_ref1,_ref2
e.preventDefault()
e.stopPropagation()
focusedIndex=this.getPanelIndex(this.focusedPanel)
if(e.altKey&&(37===(_ref1=e.which)||39===_ref1)){this.splitPanel(focusedIndex)
return!1}if(27===e.which&&this.panels.length>1){this.removePanel(focusedIndex)
this.panels[focusedIndex-1]?this.setFocusedPanel(this.panels[focusedIndex-1]):this.setFocusedPanel(this.panels[0])
return!1}if(e.metaKey)switch(e.which){case 37:this.focusPrevPanel()
break
case 39:this.focusNextPanel()
break
default:0<=(_ref2=i=e.which-49)&&10>_ref2&&this.focusByIndex(i)}return!1}
SlidingSplit.prototype._createPanel=function(){var panel,_this=this
panel=SlidingSplit.__super__._createPanel.apply(this,arguments)
panel.on("click",function(){return _this.setFocusedPanel(panel)})
return panel}
SlidingSplit.prototype._resizeUponPanelCount=function(){var i,l,parentSize,sizeArr
i=0
sizeArr=[]
parentSize=this._getParentSize()
switch(l=this.panels.length){case 1:case 2:case 3:for(;l>i;){sizeArr.push(parentSize/l)
i++}this._setSize(parentSize)
break
default:for(;l>i;){sizeArr.push(parentSize/3)
i++}this._setSize(parentSize+(l-3)/3*parentSize)}return this.sizes=sizeArr}
SlidingSplit.prototype._resizePanels=function(){this._resizeUponPanelCount()
this.getOptions().sizes=this.sizes.slice()
return SlidingSplit.__super__._resizePanels.apply(this,arguments)}
SlidingSplit.prototype._windowDidResize=function(){var _this=this
return this.utils.wait(300,function(){_this._resizePanels()
_this._repositionPanels()
return _this.getOptions().resizable?_this._repositionResizers():void 0})}
return SlidingSplit}(KDSplitView)

var TokenView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TokenView=function(_super){function TokenView(options,data){null==options&&(options={})
options.tagName||(options.tagName="span")
options.cssClass=KD.utils.curry("token",options.cssClass)
options.attributes||(options.attributes={})
options.attributes.contenteditable=!1
options.itemClass||(options.itemClass=KDCustomHTMLView)
options.type||(options.type="generic")
TokenView.__super__.constructor.call(this,options,data)
this.item=new options.itemClass({},data)}__extends(TokenView,_super)
TokenView.prototype.getKey=function(){return this.getData().getId()}
TokenView.prototype.encodeValue=function(){var data,prefix
if(!(data=this.getData()))return""
prefix=this.getOptions().prefix
return"|"+prefix+":"+data.bongo_.constructorName+":"+data.getId()+"|"}
TokenView.prototype.pistachio=function(){return"{{> this.item}}"}
TokenView.getPlaceholder=function(id){return'<span class="token" id="'+id+'"></span>'}
return TokenView}(JView)

var AvatarImage,AvatarTooltipView,AvatarView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarView=function(_super){function AvatarView(options,data){var _base,_base1,_base2,_base3,_base4,_this=this
null==options&&(options={})
options.cssClass||(options.cssClass="")
options.size||(options.size={width:50,height:50})
null==options.detailed&&(options.detailed=!1)
options.showStatus||(options.showStatus=!1)
options.statusDiameter||(options.statusDiameter=5)
if(options.detailed){this.detailedAvatar={constructorName:AvatarTooltipView,options:{delegate:this,origin:options.origin},data:data}
options.tooltip||(options.tooltip={});(_base=options.tooltip).view||(_base.view=options.detailed?this.detailedAvatar:null);(_base1=options.tooltip).cssClass||(_base1.cssClass="avatar-tooltip")
null==(_base2=options.tooltip).animate&&(_base2.animate=!0);(_base3=options.tooltip).placement||(_base3.placement="top");(_base4=options.tooltip).direction||(_base4.direction="right")}options.cssClass="avatarview "+options.cssClass
AvatarView.__super__.constructor.call(this,options,data)
null!=this.detailedAvatar&&this.on("TooltipReady",function(){return _this.utils.defer(function(){data=_this.getData()
return(null!=data?data.profile.nickname:void 0)?_this.tooltip.getView().updateData(data):void 0})})
this.bgImg=null
this.fallbackUri=""+KD.apiUri+"/images/defaultavatar/default.avatar."+options.size.width+".png"}__extends(AvatarView,_super)
AvatarView.prototype.setAvatar=function(uri){if(this.bgImg!==uri){this.$().css("background-image","url("+uri+")")
return this.bgImg=uri}}
AvatarView.prototype.render=function(){var account,avatarURI,flags,height,key,onlineStatus,profile,resizedAvatar,type,value,width,_ref,_ref1
account=this.getData()
if(account){profile=account.profile,type=account.type
if("unregistered"===type)return this.setAvatar("url("+this.fallbackUri+")")
_ref=this.getOptions().size,width=_ref.width,height=_ref.height
height||(height=width)
avatarURI=profile.hash?"//gravatar.com/avatar/"+profile.hash+"?size="+width+"&d="+encodeURIComponent(this.fallbackUri):""+this.fallbackUri
if(null!=(_ref1=profile.avatar)?_ref1.match(/^https?:\/\//):void 0){resizedAvatar=KD.utils.proxifyUrl(profile.avatar,{crop:!0,width:width,height:height})
avatarURI=""+resizedAvatar}this.setAvatar(avatarURI)
flags=""
account.globalFlags&&(flags=Array.isArray(account.globalFlags)?account.globalFlags.join(" "):function(){var _ref2,_results
_ref2=account.globalFlags
_results=[]
for(key in _ref2)if(__hasProp.call(_ref2,key)){value=_ref2[key]
_results.push(value)}return _results}().join(" "))
this.$("cite").addClass(flags)
this.setAttribute("href","/"+profile.nickname)
if(this.getOptions().showStatus){onlineStatus=account.onlineStatus||"offline"
null!=this.statusAttr&&onlineStatus!==this.statusAttr&&this.setClass("animate")
this.statusAttr=onlineStatus
if("online"===this.statusAttr){this.unsetClass("offline")
return this.setClass("online")}this.unsetClass("online")
return this.setClass("offline")}}}
AvatarView.prototype.viewAppended=function(){var statusDiameter
AvatarView.__super__.viewAppended.apply(this,arguments)
this.getData()&&this.render()
if(this.getOptions().showStatus){statusDiameter=this.getOptions().statusDiameter
this.addSubView(this.statusIndicator=new KDCustomHTMLView({cssClass:"statusIndicator"}))
this.statusIndicator.setWidth(statusDiameter)
return this.statusIndicator.setHeight(statusDiameter)}}
AvatarView.prototype.pistachio=function(){return"<cite></cite>"}
return AvatarView}(LinkView)
AvatarTooltipView=function(_super){function AvatarTooltipView(options,data){var name,origin,_this=this
null==options&&(options={})
AvatarTooltipView.__super__.constructor.call(this,options,data)
origin=options.origin
name=KD.utils.getFullnameFromAccount(this.getData())
this.profileName=new KDCustomHTMLView({tagName:"a",cssClass:"profile-name",attributes:{href:"/"+this.getData().profile.nickname,target:"_blank"},pistachio:"<h2>"+name+"</h2>"},data)
this.staticAvatar=new AvatarStaticView({cssClass:"avatar-static",noTooltip:!0,size:{width:80,height:80},origin:origin},data)
this.followButton=new MemberFollowToggleButton({style:"follow-btn",loader:{color:"#333333",diameter:18,top:11}},this.getData())
this.followers=new KDView({tagName:"a",attributes:{href:"#"},pistachio:"<cite/>{{#(counts.followers)}} <span>Followers</span>",click:function(){return 0!==this.getData().counts.followers?KD.getSingleton("appManager").tell("Members","createFolloweeContentDisplay",this.getData(),"followers"):void 0}},this.getData())
this.following=new KDView({tagName:"a",attributes:{href:"#"},pistachio:"<cite/>{{#(counts.following)}} <span>Following</span>",click:function(){return 0!==this.getData().counts.following?KD.getSingleton("appManager").tell("Members","createFolloweeContentDisplay",this.getData(),"following"):void 0}},this.getData())
this.likes=new KDView({tagName:"a",attributes:{href:"#"},pistachio:"<cite/>{{#(counts.likes) || 0}} <span>Likes</span>",click:function(){return 0!==_this.getData().counts.following?KD.getSingleton("appManager").tell("Members","createLikedContentDisplay",_this.getData()):void 0}},this.getData())
this.sendMessageLink=new MemberMailLink({},this.getData())}__extends(AvatarTooltipView,_super)
AvatarTooltipView.prototype.viewAppended=function(){AvatarTooltipView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
return this.template.update()}
AvatarTooltipView.prototype.click=function(){}
AvatarTooltipView.prototype.decorateFollowButton=function(data){var _base,_this=this
if(null!=data.getId){if(null==data.followee)"function"==typeof(_base=KD.whoami()).isFollowing&&_base.isFollowing(data.getId(),"JAccount",function(err,following){data.followee=following
KD.isLoggedIn()&&warn(err)
if(data.followee){_this.followButton.setClass("following-btn")
return _this.followButton.setState("Following")}_this.followButton.setState("Follow")
return _this.followButton.unsetClass("following-btn")})
else if(data.followee){this.followButton.setClass("following-btn")
this.followButton.setState("Following")}this.followButton.setData(data)
return this.followButton.render()}}
AvatarTooltipView.prototype.updateData=function(data){null==data&&(data={})
this.setData(data)
this.decorateFollowButton(data)
this.profileName.setData(data)
this.profileName.render()
this.followers.setData(data)
this.following.setData(data)
this.likes.setData(data)
this.sendMessageLink.setData(data)
this.followers.render()
this.following.render()
this.likes.render()
return this.sendMessageLink.render()}
AvatarTooltipView.prototype.pistachio=function(){return'<div class="leftcol">\n  {{> this.staticAvatar}}\n  {{> this.followButton}}\n</div>\n<div class="rightcol">\n  {{> this.profileName}}\n  <div class="profilestats">\n      <div class="fers">\n        {{> this.followers}}\n      </div>\n      <div class="fing">\n        {{> this.following}}\n      </div>\n       <div class="liks">\n        {{> this.likes}}\n      </div>\n      <div class=\'contact\'>\n        {{> this.sendMessageLink}}\n      </div>\n    </div>\n</div>'}
return AvatarTooltipView}(KDView)
AvatarImage=function(_super){function AvatarImage(options,data){null==options&&(options={})
options.tagName||(options.tagName="img")
options.cssClass||(options.cssClass="")
options.size||(options.size={width:50,height:50})
options.cssClass=KD.utils.curry("avatarimage",options.cssClass)
AvatarImage.__super__.constructor.call(this,options,data)
this.bgImg=null
this.fallbackUri=""+KD.apiUri+"/images/defaultavatar/default.avatar."+options.size.width+".png"}__extends(AvatarImage,_super)
AvatarImage.prototype.setAvatar=function(uri){if(this.bgImg!==uri){this.setAttribute("src",uri)
return this.bgImg=uri}}
AvatarImage.prototype.pistachio=function(){return""}
return AvatarImage}(AvatarView)

var AvatarStaticView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarStaticView=function(_super){function AvatarStaticView(options){null==options&&(options={})
options.tagName||(options.tagName="span")
AvatarStaticView.__super__.constructor.apply(this,arguments)}__extends(AvatarStaticView,_super)
AvatarStaticView.prototype.click=function(){return!0}
return AvatarStaticView}(AvatarView)

var AutoCompleteAvatarView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AutoCompleteAvatarView=function(_super){function AutoCompleteAvatarView(options){null==options&&(options={})
options.size||(options.size={width:20,height:20})
options.cssClass="avatarview "+options.cssClass
AutoCompleteAvatarView.__super__.constructor.apply(this,arguments)}__extends(AutoCompleteAvatarView,_super)
return AutoCompleteAvatarView}(AvatarView)

var MainNavController,NavigationController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
NavigationController=function(_super){function NavigationController(){_ref=NavigationController.__super__.constructor.apply(this,arguments)
return _ref}__extends(NavigationController,_super)
NavigationController.prototype.reset=function(){var name,previousSelection,_i,_len,_results
previousSelection=this.selectedItems.slice()
this.removeAllItems()
this.instantiateListItems(this.getData().items)
_results=[]
for(_i=0,_len=previousSelection.length;_len>_i;_i++){name=previousSelection[_i].name
_results.push(this.selectItemByName(name))}return _results}
NavigationController.prototype.getItemByName=function(name){var navItem,_i,_len,_ref1,_ref2
_ref1=this.itemsOrdered
for(_i=0,_len=_ref1.length;_len>_i;_i++){navItem=_ref1[_i]
if((null!=(_ref2=navItem.getData())?_ref2.title:void 0)===name)return navItem}}
NavigationController.prototype.selectItemByName=function(name){var item;(item=this.getItemByName(name))?this.selectItem(item):this.deselectAllItems()
return item}
NavigationController.prototype.removeItemByTitle=function(name){var navItem,_i,_len,_ref1,_results
_ref1=this.itemsOrdered
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){navItem=_ref1[_i];(null!=navItem?navItem.name:void 0)===name&&_results.push(this.removeItem(navItem))}return _results}
NavigationController.prototype.instantiateListItems=function(items){var itemData,roles,_i,_len,_ref1,_results
roles=KD.config.roles
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){itemData=items[_i]
if(null!=itemData.loggedIn){if(itemData.loggedIn&&!KD.isLoggedIn())continue
if(!itemData.loggedIn&&KD.isLoggedIn())continue}itemData.role?(_ref1=itemData.role,__indexOf.call(roles,_ref1)>=0?_results.push(this.getListView().addItem(itemData)):_results.push(void 0)):_results.push(this.getListView().addItem(itemData))}return _results}
return NavigationController}(KDListViewController)
MainNavController=function(_super){function MainNavController(){var index,listView,viewWidth
MainNavController.__super__.constructor.apply(this,arguments)
listView=this.getListView()
viewWidth=61
index=0
listView.on("ItemWasAdded",function(view){return view.once("viewAppended",function(){return this.setX(index++*viewWidth)})})}__extends(MainNavController,_super)
MainNavController.prototype.reset=function(){var name,previousSelection,_i,_len,_results
previousSelection=this.selectedItems.slice()
this.removeAllItems()
this.instantiateListItems(KD.getNavItems())
_results=[]
for(_i=0,_len=previousSelection.length;_len>_i;_i++){name=previousSelection[_i].name
_results.push(this.selectItemByName(name))}return _results}
return MainNavController}(NavigationController)

var VideoPopup,VideoPopupController,VideoPopupList,VideoPopupListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VideoPopupController=function(_super){function VideoPopupController(options,data){VideoPopupController.__super__.constructor.call(this,options,data)
this.videoPopups=[]}__extends(VideoPopupController,_super)
VideoPopupController.prototype.newPopup=function(url,windowTitle,optionString,imageTitle,imageThumb){var newWindow,_this=this
newWindow=window.open(url,windowTitle,optionString)
newWindow.onbeforeunload=function(){newWindow.onbeforeunload=noop
_this.closePopup(newWindow)
return void 0}
this.videoPopups.push(newWindow)
this.emit("PopupOpened",newWindow,{title:imageTitle,thumb:imageThumb})
return newWindow}
VideoPopupController.prototype.listPopups=function(){return this.videoPopups}
VideoPopupController.prototype.countPopups=function(){return this.videoPopups.length}
VideoPopupController.prototype.focusWindowByName=function(windowName,callback){var video,_i,_len,_ref,_results
null==callback&&(callback=noop)
_ref=this.videoPopups
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){video=_ref[_i]
video.name===windowName?_results.push(video.focus()):_results.push(void 0)}return _results}
VideoPopupController.prototype.closeWindowByName=function(windowName,callback){var video,_i,_len,_ref,_results
null==callback&&(callback=noop)
_ref=this.videoPopups
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){video=_ref[_i];(null!=video?video.name:void 0)===windowName?_results.push(this.closePopup(video)):_results.push(void 0)}return _results}
VideoPopupController.prototype.closePopup=function(popupWindow){var i,videoPopup,_i,_len,_ref
_ref=this.videoPopups
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){videoPopup=_ref[i]
if(popupWindow===videoPopup){this.videoPopups.splice(i,1)
this.emit("PopupClosed",popupWindow.name,i)}}return null!=popupWindow?popupWindow.close():void 0}
return VideoPopupController}(KDController)
VideoPopupList=function(_super){function VideoPopupList(options,data){var _this=this
VideoPopupList.__super__.constructor.call(this,options,data)
this.setClass("video-popup-list")
this.controller=KD.getSingleton("mainController").popupController
this.controller.on("PopupOpened",function(popup,data){_this.addItem({delegate:_this,name:popup.name||"New Window",title:data.title,thumb:data.thumb})
return _this.resizeView()})
this.controller.on("PopupClosed",function(popupName,index){_this.removeItem({},{},index)
return _this.resizeView()})
this.on("FocusWindow",function(windowName){return _this.controller.focusWindowByName(windowName,function(){return _this.resizeView()})})
this.on("CloseWindow",function(windowName){return _this.controller.closeWindowByName(windowName,function(){return _this.resizeView()})})
this.hasNoItems=new KDView({cssClass:"has-no-video",partial:"There are no open Videos"})
this.addSubView(this.hasNoItems)}__extends(VideoPopupList,_super)
VideoPopupList.prototype.resizeView=function(){var _ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_ref7
switch(this.controller.countPopups()){case 0:this.hasNoItems.show()
null!=(_ref=KD.getSingleton("mainView"))&&null!=(_ref1=_ref.videoButton)&&_ref1.unsetClass("has-videos")
this.unsetClass("layout1x1")
this.unsetClass("layout2x2")
return this.unsetClass("layout3x3")
case 1:this.hasNoItems.hide()
null!=(_ref2=KD.getSingleton("mainView"))&&null!=(_ref3=_ref2.videoButton)&&_ref3.setClass("has-videos")
this.setClass("layout1x1")
this.unsetClass("layout2x2")
return this.unsetClass("layout3x3")
case 2:case 3:case 4:this.hasNoItems.hide()
null!=(_ref4=KD.getSingleton("mainView"))&&null!=(_ref5=_ref4.videoButton)&&_ref5.setClass("has-videos")
this.unsetClass("layout1x1")
this.setClass("layout2x2")
return this.unsetClass("layout3x3")
default:this.hasNoItems.hide()
null!=(_ref6=KD.getSingleton("mainView"))&&null!=(_ref7=_ref6.videoButton)&&_ref7.setClass("has-videos")
this.unsetClass("layout1x1")
this.unsetClass("layout2x2")
return this.setClass("layout3x3")}}
return VideoPopupList}(KDListView)
VideoPopupListItem=function(_super){function VideoPopupListItem(options,data){var _this=this
VideoPopupListItem.__super__.constructor.call(this,options,data)
this.setClass("video-popup-list-item")
this.focusWindowBar=new KDView({cssClass:"overlay-bar focus",partial:"<span class='overlay-text'>Focus</span>",click:function(){return _this.getDelegate().emit("FocusWindow",_this.getData().name)}})
this.closeWindowBar=new KDView({cssClass:"overlay-bar close",partial:"<span class='overlay-text'>Close</span>",click:function(){return _this.getDelegate().emit("CloseWindow",_this.getData().name)}})}__extends(VideoPopupListItem,_super)
VideoPopupListItem.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
VideoPopupListItem.prototype.pistachio=function(){return'<img title="'+this.getData().title+'" src="'+this.utils.proxifyUrl(this.getData().thumb)+'" />\n{{> this.focusWindowBar}}\n{{> this.closeWindowBar}}'}
return VideoPopupListItem}(KDListItemView)
VideoPopup=function(_super){function VideoPopup(options,data){VideoPopup.__super__.constructor.call(this,options,data)
this.setClass("hidden invisible")
this.embedData=data
this.options=options
this.controller=KD.getSingleton("mainController").popupController}__extends(VideoPopup,_super)
VideoPopup.prototype.openVideoPopup=function(){var h,minH,minW,popupUrl,t,w,_ref,_this=this
minH=185
minW=240
h=this.getDelegate().getHeight()>minH?this.getDelegate().getHeight():minH
w=this.getDelegate().getWidth()>minW?this.getDelegate().getWidth():minW
t=this.getDelegate().$().offset()
null!=(_ref=this.videoPopup)&&_ref.close()
popupUrl="/video-container.html"
this.videoPopup=this.controller.newPopup(popupUrl,"KodingVideo_"+Math.random().toString(36).substring(7),"menubar=no,location=no,resizable=yes,titlebar=no,scrollbars=no,status=no,innerHeight="+h+",width="+w+",left="+(t.left+window.screenX)+",top="+(window.screenY+t.top+(window.outerHeight-window.innerHeight)),this.options.title,this.options.thumb)
return this.utils.wait(1500,function(){var command,_ref1,_ref2
window.onfocus=function(){return _this.utils.wait(500,function(){var countdownInterval,currentSeconds,modal,secondsToAutoClose,userChoice
if(0!==_this.videoPopup.length){window.onfocus=noop
userChoice=!1
secondsToAutoClose=10
modal=new KDModalView({title:"Do you want to keep the video running?",content:"<p class='modal-video-close'>Your video will automatically end in <span class='countdown'>"+secondsToAutoClose+"</span> seconds unless you click the 'Yes'-Button below.</p>",overlay:!0,buttons:{"No, close it":{title:"No, close it",cssClass:"modal-clean-gray",callback:function(){var _ref1
null!=(_ref1=_this.videoPopup)&&_ref1.close()
return modal.destroy()}},"Yes, keep it running":{title:"Yes, keep it running",cssClass:"modal-clean-green",callback:function(){modal.destroy()
return userChoice=!0}}}})
currentSeconds=secondsToAutoClose-1
countdownInterval=window.setInterval(function(){return modal.$("span.countdown").text(currentSeconds--)},1e3)
return _this.utils.wait(1e3*secondsToAutoClose,function(){window.clearInterval(countdownInterval)
if(!userChoice){_this.controller.closePopup(_this.videoPopup)
return modal.destroy()}})}})}
command={type:"embed",embed:_this.embedData,coordinates:{left:(null!=(_ref1=_this.options.popup)?_ref1.left:void 0)||t.left+window.screenX||100,top:(null!=(_ref2=_this.options.popup)?_ref2.top:void 0)||window.screenY+t.top+(window.outerHeight-window.innerHeight)||100}}
return command&&_this.videoPopup?_this.videoPopup.postMessage(command,"*"):void 0})}
return VideoPopup}(KDView)

var LikeView,LikeViewClean,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LikeView=function(_super){function LikeView(options,data){var _this=this
null==options&&(options={})
options.tagName||(options.tagName="span")
options.cssClass||(options.cssClass="like-view")
options.tooltipPosition||(options.tooltipPosition="se")
null==options.checkIfLikedBefore&&(options.checkIfLikedBefore=!1)
LikeView.__super__.constructor.call(this,options,data)
this._lastUpdatedCount=-1
this._currentState=!1
this.likeCount=new ActivityLikeCount({tooltip:{gravity:options.tooltipPosition,title:""},bind:"mouseenter",mouseenter:function(){return _this.fetchLikeInfo()},attributes:{href:"#"},click:function(){return data.meta.likes>0?data.fetchLikedByes({},{sort:{timestamp:-1}},function(err,likes){return new ShowMoreDataModalView({title:"Members who liked <cite>"+data.body+"</cite>"},likes)}):void 0}},data)
this.likeLink=new ActivityActionLink
this.setTemplate(this.pistachio())
options.checkIfLikedBefore&&KD.isLoggedIn()&&data.checkIfLikedBefore(function(err,likedBefore){likedBefore?_this.setClass("liked"):_this.unsetClass("liked")
return _this._currentState=likedBefore})}__extends(LikeView,_super)
LikeView.prototype.fetchLikeInfo=function(){var data,_this=this
data=this.getData()
if(this._lastUpdatedCount!==data.meta.likes){this.likeCount.getTooltip().update({title:"Loading..."})
if(0!==data.meta.likes)return data.fetchLikedByes({},{limit:3,sort:{timestamp:-1}},function(err,likes){var andMore,guests,item,likers,name,sep,strong,tooltip,users,_i,_len
users=[]
likers=[]
guests=0
if(likes){strong=function(x){return"<strong>"+x+"</strong>"}
for(_i=0,_len=likes.length;_len>_i;_i++){item=likes[_i]
name=KD.utils.getFullnameFromAccount(item)
likers.push(""+strong(name))
"unregistered"===item.type?guests++:users.push(""+strong(name))}if(data.meta.likes>3){sep=", "
andMore="and <strong>"+(data.meta.likes-3)+" more.</strong>"}else{sep=" and "
andMore=""}tooltip=function(){switch(data.meta.likes){case 0:return""
case 1:return""+likers[0]
case 2:return 2===guests?""+strong("2 guests"):""+likers[0]+" and "+likers[1]
default:switch(guests){case 3:return""+strong("3 guests")+" "+andMore
case 2:return""+users[0]+sep+strong("2 guests")+" "+andMore
default:return""+likers[0]+", "+likers[1]+sep+likers[2]+" "+andMore}}}()
_this.likeCount.getTooltip().update({title:tooltip})
return _this._lastUpdatedCount=data.meta.likes}})
this.unsetClass("liked")}}
LikeView.prototype.click=function(event){var _this=this
event.preventDefault()
return $(event.target).is("a.action-link")?this.getData().like(function(err){KD.showError(err,{AccessDenied:"You are not allowed to like activities",KodingError:"Something went wrong while like"})
if(!err){_this._currentState=!_this._currentState
_this._currentState?_this.setClass("liked"):_this.unsetClass("liked")
_this._lastUpdatedCount=-1
return KD.mixpanel("Liked activity")}}):void 0}
LikeView.prototype.pistachio=function(){return"{{> this.likeLink}}{{> this.likeCount}}"}
return LikeView}(KDView)
LikeViewClean=function(_super){function LikeViewClean(){LikeViewClean.__super__.constructor.apply(this,arguments)
this.likeLink.updatePartial("Like")}__extends(LikeViewClean,_super)
LikeViewClean.prototype.pistachio=function(){return"<span class='comment-actions'>{{> this.likeLink}}{{> this.likeCount}}</span>"}
return LikeViewClean}(LikeView)

var ShowMoreDataModalView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
ShowMoreDataModalView=function(_super){function ShowMoreDataModalView(options,data){var css,participants,_this=this
null==options&&(options={})
participants=data
if(participants[0]instanceof KD.remote.api.JAccount){this.type="account"
css="modal-topic-wrapper"}else if(participants[0]instanceof KD.remote.api.JTag){this.type="tag"
css="modal-topic-wrapper"}else{this.type="app"
css="modal-applications-wrapper"}options.title||(options.title=titleMap()[this.type])
options.height="auto"
options.overlay=!0
options.cssClass=css
options.buttons={Close:{style:"modal-clean-gray",callback:function(){return _this.destroy()}}}
ShowMoreDataModalView.__super__.constructor.apply(this,arguments)}var listControllerMap,listItemMap,titleMap
__extends(ShowMoreDataModalView,_super)
titleMap=function(){return{account:"Members",tag:"Topics",app:"Applications"}}
listControllerMap=function(){return{account:MembersListViewController,tag:KDListViewController,app:KDListViewController}}
listItemMap=function(){return{account:MembersListItemView,tag:ModalTopicsListItem,app:ModalAppsListItemView}}
ShowMoreDataModalView.prototype.viewAppended=function(){this.addSubView(this.loader=new KDLoaderView({size:{width:30},loaderOptions:{color:"#cccccc",shape:"spiral",diameter:30,density:30,range:.4,speed:1,FPS:24}}))
this.loader.show()
this.prepareList()
return this.setPositions()}
ShowMoreDataModalView.prototype.putList=function(participants){var _this=this
this.controller=new KDListViewController({view:new KDListView({itemClass:listItemMap()[this.type],cssClass:"modal-topic-list"})},{items:participants})
this.controller.getListView().on("CloseTopicsModal",function(){return _this.destroy()})
this.controller.on("AllItemsAddedToList",function(){var item
"tag"===_this.type&&_this.reviveFollowButtons(function(){var _i,_len,_results
_results=[]
for(_i=0,_len=participants.length;_len>_i;_i++){item=participants[_i]
_results.push(item.getId())}return _results}())
return _this.loader.destroy()})
return this.addSubView(this.controller.getView())}
ShowMoreDataModalView.prototype.reviveFollowButtons=function(ids){var _this=this
return KD.remote.api.JTag.fetchMyFollowees(ids,function(err,followees){var button,id,modal,_i,_len,_ref,_ref1,_results
_ref=_this.controller.getItemsOrdered()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){modal=_ref[_i]
button=modal.followButton
id=null!=button?null!=(_ref1=button.getData())?_ref1.getId():void 0:void 0
id&&__indexOf.call(followees,id)>=0?_results.push(button.setState("Following")):_results.push(void 0)}return _results})}
ShowMoreDataModalView.prototype.prepareList=function(){var group,_this=this
group=this.getOptions().group
return group?KD.remote.cacheable(group,function(err,participants){return err?warn(err):_this.putList(participants)}):this.putList(this.getData())}
return ShowMoreDataModalView}(KDModalView)

var SkillTagFormView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SkillTagFormView=function(_super){function SkillTagFormView(options,data){var _base
null==options&&(options={})
options.cssClass="kdautocomplete-form"
SkillTagFormView.__super__.constructor.call(this,options,null)
this.memberData=data;(_base=this.memberData).skillTags||(_base.skillTags=[])}__extends(SkillTagFormView,_super)
SkillTagFormView.prototype.showForm=function(){if(!this.hasClass("active")){this.setClass("active")
return this.focusFirstElement()}}
SkillTagFormView.prototype.viewAppended=function(){var tagWrapper,_this=this
SkillTagFormView.__super__.viewAppended.apply(this,arguments)
this.parent.on("EditingModeToggled",function(state){return state?_this.showForm():_this.unsetClass("active")})
this.addSubView(tagWrapper=new KDCustomHTMLView({tagName:"div",cssClass:"form-actions-holder clearfix"}))
tagWrapper.addSubView(this.label=new KDLabelView({cssClass:"skilltagslabel",title:"SKILLS","for":"skillTagsInput",click:function(){return _this.parent.setEditingMode(!0)}}))
tagWrapper.addSubView(this.tip=new KDCustomHTMLView({tagName:"span",cssClass:"tip hidden",pistachio:"Adding skills help others to find you more easily."}))
0===this.memberData.skillTags.length&&this.tip.show()
tagWrapper.addSubView(this.loader=new KDLoaderView({size:{width:14}}))
this.tagController=new SkillTagAutoCompleteController({name:"skillTagsInput",cssClass:"skilltag-form",type:"tags",itemDataPath:"title",itemClass:TagAutoCompleteItemView,selectedItemClass:SkillTagAutoCompletedItem,outputWrapper:tagWrapper,selectedItemsLimit:10,form:this,view:new KDAutoComplete({placeholder:"Add a skill...",name:"skillTagsInput"}),dataSource:function(_arg,callback){var blacklist,data,inputValue
inputValue=_arg.inputValue
blacklist=function(){var _i,_len,_ref,_results
_ref=this.tagController.getSelectedItemData()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){data=_ref[_i]
"function"==typeof data.getId&&_results.push(data.getId())}return _results}.call(_this)
return _this.emit("AutoCompleteNeedsTagData",{inputValue:inputValue,blacklist:blacklist,callback:callback})}})
this.tagController.on("ItemListChanged",function(){var skillTags
_this.loader.show()
skillTags=_this.getData().skillTags
return _this.memberData.addTags(skillTags,function(err){var skillTagsFlat
if(err)return KD.notify_("There was an error while adding new skills.")
skillTagsFlat=skillTags.map(function(tag){var _ref
return null!=(_ref=tag.$suggest)?_ref:tag.title})
skillTagsFlat.length?_this.tip.hide():_this.tip.show()
return _this.memberData.modify({skillTags:skillTagsFlat},function(err){err&&KD.notify_("There was an error updating your skills.")
_this.memberData.emit("update")
return _this.loader.hide()})})})
this.addSubView(this.tagController.getView())
return this.tagController.putDefaultValues(this.memberData.skillTags)}
SkillTagFormView.prototype.mouseDown=function(){return!1}
return SkillTagFormView}(KDFormView)

var SkillTagAutoCompleteController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SkillTagAutoCompleteController=function(_super){function SkillTagAutoCompleteController(options,data){null==options&&(options={})
options.nothingFoundItemClass||(options.nothingFoundItemClass=SuggestNewTagItem)
null==options.allowNewSuggestions&&(options.allowNewSuggestions=!0)
SkillTagAutoCompleteController.__super__.constructor.call(this,options,data)}__extends(SkillTagAutoCompleteController,_super)
SkillTagAutoCompleteController.prototype.putDefaultValues=function(stringTags){var _this=this
return KD.remote.api.JTag.fetchSkillTags({title:{$in:stringTags}},{sort:{title:1}},function(err,tags){return!err||tags?_this.setDefaultValue(tags):warn("There was a problem fetching default tags!",err,tags)})}
SkillTagAutoCompleteController.prototype.getCollectionPath=function(){return"skillTags"}
return SkillTagAutoCompleteController}(KDAutoCompleteController)

var SkillTagAutoCompletedItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SkillTagAutoCompletedItem=function(_super){function SkillTagAutoCompletedItem(options,data){null==options&&(options={})
options.cssClass="clearfix"
SkillTagAutoCompletedItem.__super__.constructor.call(this,options,data)
this.tag=new TagLinkView({},this.getData())}__extends(SkillTagAutoCompletedItem,_super)
SkillTagAutoCompletedItem.prototype.viewAppended=JView.prototype.viewAppended
SkillTagAutoCompletedItem.prototype.pistachio=function(){return"{{> this.tag}}"}
SkillTagAutoCompletedItem.prototype.click=function(event){var delegate
delegate=this.getDelegate()
$(event.target).is("span.close-icon")&&delegate.removeFromSubmitQueue(this)
return delegate.getView().$input().trigger(event)}
return SkillTagAutoCompletedItem}(KDAutoCompletedItem)

var MessagesListController,MessagesListItemView,MessagesListView,NotificationListItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MessagesListItemView=function(_super){function MessagesListItemView(){MessagesListItemView.__super__.constructor.apply(this,arguments)}__extends(MessagesListItemView,_super)
MessagesListItemView.prototype.partial=function(data){return"<div>"+(data.subject||"(No title)")+"</div>"}
return MessagesListItemView}(KDListItemView)
MessagesListView=function(_super){function MessagesListView(){_ref=MessagesListView.__super__.constructor.apply(this,arguments)
return _ref}__extends(MessagesListView,_super)
return MessagesListView}(KDListView)
MessagesListController=function(_super){function MessagesListController(options,data){var _this=this
options.itemClass||(options.itemClass=MessagesListItemView)
options.listView||(options.listView=new MessagesListView)
options.startWithLazyLoader=!0
MessagesListController.__super__.constructor.call(this,options,data)
this.getListView().on("AvatarPopupShouldBeHidden",function(){return _this.emit("AvatarPopupShouldBeHidden")})}__extends(MessagesListController,_super)
MessagesListController.prototype.fetchMessages=function(callback){var _this=this
return KD.isLoggedIn()?KD.getSingleton("appManager").tell("Inbox","fetchMessages",{limit:3,sort:{timestamp:-1}},function(err,messages){var message,unreadCount,_i,_len,_ref1
_this.removeAllItems()
_this.instantiateListItems(messages)
unreadCount=0
for(_i=0,_len=messages.length;_len>_i;_i++){message=messages[_i];(null!=(_ref1=message.flags_)?_ref1.read:void 0)||unreadCount++}_this.emit("MessageCountDidChange",unreadCount)
_this.hideLazyLoader()
return"function"==typeof callback?callback(err,messages):void 0}):"function"==typeof callback?callback(!0):void 0}
MessagesListController.prototype.fetchNotificationTeasers=function(callback){var _base,_this=this
return"function"==typeof(_base=KD.whoami()).fetchActivityTeasers?_base.fetchActivityTeasers({targetName:{$in:["CReplieeBucketActivity","CFolloweeBucketActivity","CLikeeBucketActivity","CGroupJoineeBucketActivity","CNewMemberBucketActivity","CGroupLeaveeBucketActivity"]}},{limit:8,sort:{timestamp:-1}},function(err,items){var unglanced
if(err)warn("There was a problem fetching notifications!",err)
else{unglanced=items.filter(function(item){return item.getFlagValue("glanced")!==!0})
_this.emit("NotificationCountDidChange",unglanced.length)
"function"==typeof callback&&callback(items)}return _this.hideLazyLoader()}):void 0}
return MessagesListController}(KDListViewController)
NotificationListItem=function(_super){function NotificationListItem(options,data){var group,member,myid,_ref1
null==options&&(options={})
options.tagName||(options.tagName="li")
options.linkGroupClass||(options.linkGroupClass=LinkGroup)
options.avatarClass||(options.avatarClass=AvatarView)
NotificationListItem.__super__.constructor.call(this,options,data)
this.setClass(bucketNameMap()[data.bongo_.constructorName])
this.snapshot=JSON.parse(Encoder.htmlDecode(data.snapshot))
group=this.snapshot.group
myid=null!=(_ref1=KD.whoami())?_ref1.getId():void 0
if(myid){group=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=group.length;_len>_i;_i++){member=group[_i]
member.id!==myid&&_results.push(member)}return _results}()
this.participants=new options.linkGroupClass({group:group})
this.avatar=new options.avatarClass({size:{width:40,height:40},origin:group[0]})
this.interactedGroups="JGroup"===this.snapshot.anchor.constructorName?new options.linkGroupClass({itemClass:GroupLinkView,group:[this.snapshot.anchor.data]}):new KDCustomHTMLView
this.timeAgoView=new KDTimeAgoView({},this.getLatestTimeStamp(this.getData().dummy))}}var actionPhraseMap,activityNameMap,bucketNameMap
__extends(NotificationListItem,_super)
activityNameMap=function(){return{JStatusUpdate:"your status update.",JCodeSnip:"your status update.",JAccount:"started following you.",JPrivateMessage:"your private message.",JComment:"your comment.",JDiscussion:"your discussion.",JOpinion:"your opinion.",JReview:"your review.",JGroup:"your group"}}
bucketNameMap=function(){return{CReplieeBucketActivity:"comment",CFolloweeBucketActivity:"follow",CLikeeBucketActivity:"like",CGroupJoineeBucketActivity:"groupJoined",CGroupLeaveeBucketActivity:"groupLeft"}}
actionPhraseMap=function(){return{comment:"commented on",reply:"replied to",like:"liked",follow:"",share:"shared",commit:"committed",member:"joined",groupJoined:"joined",groupLeft:"left"}}
NotificationListItem.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
NotificationListItem.prototype.pistachio=function(){return"<div class='avatar-wrapper fl'>\n  {{> this.avatar}}\n</div>\n<div class='right-overflow'>\n  <p>{{> this.participants}} {{this.getActionPhrase(#(dummy))}} {{this.getActivityPlot(#(dummy))}} {{> this.interactedGroups}}</p>\n  <footer>\n    {{> this.timeAgoView}}\n  </footer>\n</div>"}
NotificationListItem.prototype.getLatestTimeStamp=function(){var data,lastUpdateAt
data=this.getData()
lastUpdateAt=this.snapshot.group.modifiedAt
return lastUpdateAt||data.createdAt}
NotificationListItem.prototype.getActionPhrase=function(){var data
data=this.getData()
if("JPrivateMessage"===this.snapshot.anchor.constructorName){this.unsetClass("comment")
this.setClass("reply")
return actionPhraseMap().reply}return actionPhraseMap()[bucketNameMap()[data.bongo_.constructorName]]}
NotificationListItem.prototype.getActivityPlot=function(){var data
data=this.getData()
return activityNameMap()[this.snapshot.anchor.constructorName]}
NotificationListItem.prototype.click=function(){var appManager,showPost
showPost=function(err,post){var internalApp
if(post){internalApp="JApp"===post.constructor.name?"Apps":"Activity"
return KD.getSingleton("router").handleRoute("/"+internalApp+"/"+post.slug,{state:post})}return new KDNotificationView({title:"This post has been deleted!",duration:1e3})}
switch(this.snapshot.anchor.constructorName){case"JPrivateMessage":appManager=KD.getSingleton("appManager")
appManager.open("Inbox")
return appManager.tell("Inbox","goToMessages")
case"JComment":case"JReview":case"JOpinion":return KD.remote.api[this.snapshot.anchor.constructorName].fetchRelated(this.snapshot.anchor.id,showPost)
case"JGroup":break
default:if("JAccount"!==this.snapshot.anchor.constructorName)return KD.remote.api[this.snapshot.anchor.constructorName].one({_id:this.snapshot.anchor.id},showPost)}}
return NotificationListItem}(KDListItemView)

var SplitViewWithOlderSiblings,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SplitViewWithOlderSiblings=function(_super){function SplitViewWithOlderSiblings(){_ref=SplitViewWithOlderSiblings.__super__.constructor.apply(this,arguments)
return _ref}__extends(SplitViewWithOlderSiblings,_super)
SplitViewWithOlderSiblings.prototype.viewAppended=function(){var index,siblings
SplitViewWithOlderSiblings.__super__.viewAppended.apply(this,arguments)
siblings=this.parent.getSubViews()
index=siblings.indexOf(this)
return this._olderSiblings=siblings.slice(0,index)}
SplitViewWithOlderSiblings.prototype._windowDidResize=function(){var newH,offset,olderSibling,siblingStyle,_i,_len,_ref1
SplitViewWithOlderSiblings.__super__._windowDidResize.apply(this,arguments)
offset=0
_ref1=this._olderSiblings
for(_i=0,_len=_ref1.length;_len>_i;_i++){olderSibling=_ref1[_i]
siblingStyle=window.getComputedStyle(olderSibling.getElement())
"absolute"!==siblingStyle.position&&(offset+=olderSibling.getHeight())}newH=this.parent.getHeight()-offset
return this.setHeight(newH)}
return SplitViewWithOlderSiblings}(SplitView)

var ContentPageSplitBelowHeader,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentPageSplitBelowHeader=function(_super){function ContentPageSplitBelowHeader(){_ref=ContentPageSplitBelowHeader.__super__.constructor.apply(this,arguments)
return _ref}__extends(ContentPageSplitBelowHeader,_super)
ContentPageSplitBelowHeader.prototype.viewAppended=function(){var panel0,panel1,_ref1,_this=this
ContentPageSplitBelowHeader.__super__.viewAppended.apply(this,arguments)
_ref1=this.panels,panel0=_ref1[0],panel1=_ref1[1]
panel0.setClass("toggling")
panel0.addSubView(this._toggler=new KDCustomHTMLView({tagName:"span",cssClass:"generic-menu-toggler",click:this.bound("toggleFirstPanel")}))
panel0.on("click",function(event){return panel0.$().hasClass("collapsed")?_this.toggleFirstPanel(event):void 0})
return panel1.on("PanelDidResize",function(){return _this.setRightColumnClass()})}
ContentPageSplitBelowHeader.prototype.toggleFirstPanel=function(event){var $panel
$panel=this.panels[0].$()
if($panel.hasClass("collapsed")){$panel.removeClass("collapsed")
this.resizePanel(139,0)}else this.resizePanel(10,0,function(){return $panel.addClass("collapsed")})
return event.stopPropagation()}
ContentPageSplitBelowHeader.prototype._windowDidResize=function(){ContentPageSplitBelowHeader.__super__._windowDidResize.apply(this,arguments)
return this.setRightColumnClass()}
ContentPageSplitBelowHeader.prototype.setRightColumnClass=function(){var col,w
col=this.panels[1]
col.unsetClass("extra-wide wide medium narrow extra-narrow")
w=col.size
return col.setClass(w>1200?"extra-wide":w>900&&1200>w?"wide":w>600&&900>w?"medium":w>300&&600>w?"narrow":"extra-narrow")}
return ContentPageSplitBelowHeader}(SplitViewWithOlderSiblings)

var CommonListHeader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommonListHeader=function(_super){function CommonListHeader(options,data){null==options&&(options={})
options.tagName="header"
options.cssClass="feeder-header clearfix"
CommonListHeader.__super__.constructor.call(this,options,data)}__extends(CommonListHeader,_super)
CommonListHeader.prototype.viewAppended=function(){this.setPartial("<p>"+this.getOptions().title+"</p> <span></span>")
return this.emit("ready")}
return CommonListHeader}(KDView)

var CommonInnerNavigation,CommonInnerNavigationList,CommonInnerNavigationListController,CommonInnerNavigationListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommonInnerNavigation=function(_super){function CommonInnerNavigation(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("common-inner-nav",options.cssClass)
CommonInnerNavigation.__super__.constructor.call(this,options,data)}__extends(CommonInnerNavigation,_super)
CommonInnerNavigation.prototype.setListController=function(options,data,isSorter){var controller,_this=this
null==isSorter&&(isSorter=!1)
controller=new CommonInnerNavigationListController(options,data)
controller.getListView().on("NavItemReceivedClick",function(data){return _this.emit("NavItemReceivedClick",data)})
isSorter&&(this.sortController=controller)
return controller}
CommonInnerNavigation.prototype.selectSortItem=function(sortType){var item,itemToBeSelected,_i,_len,_ref
if(this.sortController){itemToBeSelected=null
_ref=this.sortController.itemsOrdered
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
item.getData().type===sortType&&(itemToBeSelected=item)}return itemToBeSelected?this.sortController.selectItem(itemToBeSelected):void 0}}
return CommonInnerNavigation}(KDView)
CommonInnerNavigationListController=function(_super){function CommonInnerNavigationListController(options,data){var listView,mainView,_this=this
null==options&&(options={})
options.viewOptions||(options.viewOptions={itemClass:options.itemClass||CommonInnerNavigationListItem})
options.view||(options.view=mainView=new CommonInnerNavigationList(options.viewOptions))
CommonInnerNavigationListController.__super__.constructor.call(this,options,data)
listView=this.getListView()
listView.on("ItemWasAdded",function(view){return view.on("click",function(){if(!view.getData().disabledForBeta){_this.selectItem(view)
_this.emit("NavItemReceivedClick",view.getData())
return listView.emit("NavItemReceivedClick",view.getData())}})})}__extends(CommonInnerNavigationListController,_super)
CommonInnerNavigationListController.prototype.loadView=function(mainView){var list
list=this.getListView()
mainView.setClass("list")
mainView.addSubView(new KDHeaderView({size:"small",title:this.getData().title,cssClass:"list-group-title"}))
mainView.addSubView(list)
return this.instantiateListItems(this.getData().items||[])}
return CommonInnerNavigationListController}(NavigationController)
CommonInnerNavigationList=function(_super){function CommonInnerNavigationList(options,data){null==options&&(options={})
options.tagName||(options.tagName="ul")
CommonInnerNavigationList.__super__.constructor.call(this,options,data)}__extends(CommonInnerNavigationList,_super)
return CommonInnerNavigationList}(KDListView)
CommonInnerNavigationListItem=function(_super){function CommonInnerNavigationListItem(options,data){null==options&&(options={})
options.tagName||(options.tagName="li")
options.partial||(options.partial="<a href='#'>"+data.title+"</a>")
CommonInnerNavigationListItem.__super__.constructor.call(this,options,data)
this.setClass(data.type)}__extends(CommonInnerNavigationListItem,_super)
CommonInnerNavigationListItem.prototype.partial=function(){return""}
return CommonInnerNavigationListItem}(KDListItemView)

var HeaderViewSection,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
HeaderViewSection=function(_super){function HeaderViewSection(){HeaderViewSection.__super__.constructor.apply(this,arguments)
this.setClass("header-view-section")}__extends(HeaderViewSection,_super)
HeaderViewSection.prototype.setTitle=function(title){return this.$().append("<cite></cite> <span class='section-title'>"+title+"</span>")}
HeaderViewSection.prototype.setSearchInput=function(options){var icon,_ref,_this=this
null==options&&(options={})
null!=(_ref=this.searchInput)&&_ref.destroy()
this.addSubView(this.searchInput=new KDHitEnterInputView({placeholder:options.placeholder||"Search...",name:options.name||"searchInput",cssClass:options.cssClass||"header-search-input",type:"text",callback:function(){_this.parent.emit("searchFilterChanged",_this.searchInput.getValue())
return _this.searchInput.focus()},keyup:function(){return""===_this.searchInput.getValue()?_this.parent.emit("searchFilterChanged",""):void 0}}))
return this.addSubView(icon=new KDCustomHTMLView({tagName:"span",cssClass:"header-search-input-icon"}))}
return HeaderViewSection}(KDHeaderView)

var HelpBox,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
HelpBox=function(_super){function HelpBox(options,data){null==options&&(options={})
null==data&&(data={})
options.cssClass||(options.cssClass="help-box")
options.title||(options.title="NEED HELP?")
options.subtitle||(options.subtitle="Learn about sharing")
data.title=options.title
data.subtitle=options.subtitle
HelpBox.__super__.constructor.call(this,options,data)}__extends(HelpBox,_super)
HelpBox.prototype.click=function(){var bookIndex,mainController
bookIndex=this.getOptions().bookIndex
if(bookIndex){mainController=KD.getSingleton("mainController")
return mainController.emit("ShowInstructionsBook",bookIndex)}}
HelpBox.prototype.pistachio=function(){return'<span></span>\n<div>\n  {cite{#(title)}}\n  <a href="#">{{#(subtitle)}}</a>\n</div>'}
return HelpBox}(JView)

var KeySetView,KeyView,KeyboardHelperModalView,KeyboardHelperView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KeyboardHelperView=function(_super){function KeyboardHelperView(options,data){options=$.extend({title:"",itemClass:KeySetView},options)
KeyboardHelperView.__super__.constructor.call(this,options,data)}__extends(KeyboardHelperView,_super)
KeyboardHelperView.prototype.viewAppended=function(){this.getOptions().title&&this.setPartial("<li class='title'>"+this.getOptions().title+"</li>")
return KeyboardHelperView.__super__.viewAppended.apply(this,arguments)}
KeyboardHelperView.prototype.setDomElement=function(cssClass){return this.domElement=$("<ul class='kdview keyboard-helper "+cssClass+"'></ul>")}
return KeyboardHelperView}(KDListView)
KeySetView=function(_super){function KeySetView(){KeySetView.__super__.constructor.apply(this,arguments)}__extends(KeySetView,_super)
KeySetView.prototype.setDomElement=function(cssClass){return this.domElement=$("<li class='kdview keyset clearfix "+cssClass+"'></li>")}
KeySetView.prototype.viewAppended=function(){var i,keyGroup,keyGroups,keySet,title,_i,_len,_ref
_ref=this.getData(),keySet=_ref.keySet,title=_ref.title
keyGroups=this.getKeyGroups(keySet)
for(i=_i=0,_len=keyGroups.length;_len>_i;i=++_i){keyGroup=keyGroups[i]
this.createKeyGroup(keyGroup)
i!==keyGroups.length-1&&this.setPartial("<cite>+</cite>")}return this.setPartial("<h6>"+title+"</h6>")}
KeySetView.prototype.getKeyGroups=function(keySet){var group,groups,i,keyGroups
keyGroups=keySet.split("+")
return groups=function(){var _i,_len,_results
_results=[]
for(i=_i=0,_len=keyGroups.length;_len>_i;i=++_i){group=keyGroups[i]
_results.push(group=/,/.test(group)?group.split(","):[group])}return _results}()}
KeySetView.prototype.createKeyGroup=function(keyGroup){var key,_i,_len,_results
_results=[]
for(_i=0,_len=keyGroup.length;_len>_i;_i++){key=keyGroup[_i]
_results.push(this.addSubView(new KeyView(null,key)))}return _results}
return KeySetView}(KDListItemView)
KeyView=function(_super){function KeyView(options,data){options=$.extend({tagName:"span",cssClass:"keyview"},options)
KeyView.__super__.constructor.call(this,options,data)}var sanitizePrinting
__extends(KeyView,_super)
sanitizePrinting=function(text){var metaKey,optionKey
if(/Macintosh/.test(navigator.userAgent)){metaKey="⌘"
optionKey="option"}else{metaKey="ctrl"
optionKey="alt"}switch(text){case"cmd":return metaKey
case"option":return optionKey
case"up":return"↑"
case"down":return"↓"
case"left":return"←"
case"right":return"→"
default:return text}}
KeyView.prototype.viewAppended=function(){var printing,text
text=this.getData()
printing=sanitizePrinting(text)
this.setPartial(printing)
this.setClass("key-"+text)
return printing.length>1?this.setClass("large"):void 0}
return KeyView}(KDCustomHTMLView)
KeyboardHelperModalView=function(_super){function KeyboardHelperModalView(options,data){var _this=this
options=$.extend({overlay:!1,height:300,width:400,title:null,content:null,cssClass:"",buttons:null,fx:!1,view:null,draggable:null,resizable:!1},options)
options.overlay&&this.putOverlay(options.overlay)
KeyboardHelperModalView.__super__.constructor.call(this,options,data)
options.fx&&this.setClass("fx")
options.content&&this.setContent(options.content)
this.appendToDomBody()
this.setModalWidth(options.width)
options.height&&this.setModalHeight(options.height)
this.display()
this.setPositions()
$(window).on("keydown.modal",function(e){return 27===e.which?_this.destroy():void 0})}__extends(KeyboardHelperModalView,_super)
KeyboardHelperModalView.prototype.setDomElement=function(cssClass){return this.domElement=$("<div class='kdmodal keyboard-helper "+cssClass+"'>\n  <span class='close-icon'></span>\n</div>")}
KeyboardHelperModalView.prototype.click=function(e){return $(e.target).is(".close-icon")?this.destroy():void 0}
KeyboardHelperModalView.prototype.setTitle=function(title){this.getDomElement().find(".kdmodal-title").append("<span class='title'>"+title+"</span>")
return this.modalTitle=title}
return KeyboardHelperModalView}(KDModalView)

var VerifyPINModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VerifyPINModal=function(_super){function VerifyPINModal(buttonTitle,callback){var options,_this=this
null==buttonTitle&&(buttonTitle="Submit")
options={title:"Please provide the PIN that we've emailed you",overlay:!0,width:400,height:"auto",tabs:{navigable:!0,forms:{form:{callback:function(){callback(_this.modalTabs.forms.form.inputs.pin.getValue())
return _this.destroy()},buttons:{Submit:{title:buttonTitle,cssClass:"modal-clean-gray",type:"submit"}},fields:{pin:{label:"PIN:",name:"pin",placeholder:"PIN",testPath:"account-email-pin",validate:{rules:{required:!0},messages:{required:"PIN required!"}}}}}}}}
VerifyPINModal.__super__.constructor.call(this,options)}__extends(VerifyPINModal,_super)
return VerifyPINModal}(KDModalViewWithForms)

var FollowButton,MemberFollowToggleButton,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FollowButton=function(_super){function FollowButton(options,data){var _ref,_ref1,_ref2,_ref3,_this=this
null==options&&(options={})
options.cssClass=this.utils.curry("follow-btn",options.cssClass)
options=$.extend({defaultState:data.followee?"Following":"Follow",bind:"mouseenter mouseleave",dataPath:"followee",loader:{color:"#333333",diameter:18,top:11},states:[{title:"Follow",cssClass:null!=(_ref=options.stateOptions)?null!=(_ref1=_ref.follow)?_ref1.cssClass:void 0:void 0,callback:function(cb){return KD.requireMembership({tryAgain:!0,onFailMsg:"Login required to follow",onFail:function(){return cb(!0)},callback:function(){var account
account=_this.getData()
return account.follow(function(err,response){account.followee=response
return"function"==typeof cb?cb(err):void 0})}})}},{title:"Following",cssClass:null!=(_ref2=options.stateOptions)?null!=(_ref3=_ref2.unfollow)?_ref3.cssClass:void 0:void 0,callback:function(cb){return _this.getData().unfollow(function(err,response){KD.showError(err,options.errorMessages)
_this.getData().followee=response
return"function"==typeof cb?cb(err):void 0})}}]},options)
FollowButton.__super__.constructor.call(this,options,data)}__extends(FollowButton,_super)
FollowButton.prototype.viewAppended=function(){var dataType,_base,_this=this
FollowButton.__super__.viewAppended.apply(this,arguments)
if(!this.getData().followee){dataType=this.getOptions().dataType
if(!dataType)return
return"function"==typeof(_base=KD.whoami()).isFollowing?_base.isFollowing(this.getData().getId(),dataType,function(err,following){_this.getData().followee=following
return following?_this.setState("Following",!1):void 0}):void 0}}
FollowButton.prototype.mouseEnter=function(){return"Following"===this.getTitle()?this.setTitle("Unfollow"):void 0}
FollowButton.prototype.mouseLeave=function(){return"Unfollow"===this.getTitle()?this.setTitle("Following"):void 0}
return FollowButton}(KDToggleButton)
MemberFollowToggleButton=function(_super){function MemberFollowToggleButton(options,data){null==options&&(options={})
options=$.extend({errorMessages:{KodingError:"Something went wrong while follow",AccessDenied:"You are not allowed to follow members"},stateOptions:{unfollow:{cssClass:"following-btn"}},dataType:"JAccount"},options)
MemberFollowToggleButton.__super__.constructor.call(this,options,data)}__extends(MemberFollowToggleButton,_super)
MemberFollowToggleButton.prototype.decorateState=function(){return MemberFollowToggleButton.__super__.decorateState.apply(this,arguments)}
return MemberFollowToggleButton}(FollowButton)

var OpinionView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionView=function(_super){function OpinionView(options,data){OpinionView.__super__.constructor.apply(this,arguments)
this.setClass("opinion-container opinion-container-box")
this.createSubViews(data)
this.resetDecoration()
this.attachListeners()}__extends(OpinionView,_super)
OpinionView.prototype.render=function(){return this.resetDecoration()}
OpinionView.prototype.createSubViews=function(data){var i,maxOpinions,opinion,_i,_len,_ref,_this=this
this.opinionList=new KDListView({type:"opinions",itemClass:OpinionListItemView,delegate:this},data)
this.opinionController=new OpinionListViewController({view:this.opinionList})
this.opinionHeader=new OpinionViewHeader({delegate:this.opinionList},data)
this.addSubView(this.opinionList)
this.addSubView(this.opinionHeader)
this.opinionList.on("OwnOpinionHasArrived",function(){return _this.opinionHeader.updateRemainingText()})
this.opinionList.on("OpinionIsDeleted",function(){})
this.opinionList.on("RefreshTeaser",function(){return _this.opinionController.fetchTeaser(function(){})})
if(data.opinions){_ref=data.opinions
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){opinion=_ref[i]
null!=opinion&&"object"==typeof opinion&&this.opinionList.addItem(opinion)}}if(data.opinionCount&&null==data.opinions){maxOpinions=data.opinionCount<=5?data.opinionCount:5
this.opinionController.fetchOpinionsByRange(0,maxOpinions,function(err,opinions){var _j,_len1
for(i=_j=0,_len1=opinions.length;_len1>_j;i=++_j){opinion=opinions[i]
null!=opinion&&"object"==typeof opinion&&_this.opinionList.addItem(opinion)}return _this.opinionHeader.updateRemainingText()})}return this.opinionList.emit("BackgroundActivityFinished")}
OpinionView.prototype.attachListeners=function(){var _this=this
this.opinionList.on("DecorateActiveOpinionView",function(){return _this.decorateActiveCommentState})
this.opinionList.on("OpinionLinkReceivedClick",function(){var _ref,_ref1,_ref2
return null!=(_ref=_this.parent)?null!=(_ref1=_ref.opinionForm)?null!=(_ref2=_ref1.opinionBody)?_ref2.setFocus():void 0:void 0:void 0})
this.opinionList.on("CommentLinkReceivedClick",function(){var _ref,_ref1,_ref2,_ref3
return null!=(_ref=_this.parent)?null!=(_ref1=_ref.commentBox)?null!=(_ref2=_ref1.commentForm)?null!=(_ref3=_ref2.commentInput)?_ref3.setFocus():void 0:void 0:void 0:void 0})
this.opinionList.on("OpinionCountClicked",function(){return _this.opinionList.emit("AllOpinionsLinkWasClicked")})
return this.opinionList.on("OpinionViewShouldReset",this.bound("resetDecoration"))}
OpinionView.prototype.resetDecoration=function(){var opinions
opinions=this.getData().opinions
return opinions&&0===opinions.length?this.decorateNoCommentState():this.decorateCommentedState()}
OpinionView.prototype.decorateNoCommentState=function(){this.unsetClass("active-opinion")
this.unsetClass("opinionated")
return this.setClass("no-opinion")}
OpinionView.prototype.decorateCommentedState=function(){this.unsetClass("active-opinion")
this.unsetClass("no-opinion")
return this.setClass("opinionated")}
OpinionView.prototype.decorateActiveCommentState=function(){this.unsetClass("opinionated")
this.unsetClass("no-opinion")
return this.setClass("active-opinion")}
OpinionView.prototype.decorateItemAsLiked=function(likeObj){var _ref;(null!=likeObj?null!=(_ref=likeObj.results)?_ref.likeCount:void 0:void 0)>0?this.setClass("liked"):this.unsetClass("liked")
return this.ActivityActionsView.setLikedCount(likeObj)}
return OpinionView}(KDView)

var DiscussionActivityOpinionView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DiscussionActivityOpinionView=function(_super){function DiscussionActivityOpinionView(options,data){DiscussionActivityOpinionView.__super__.constructor.apply(this,arguments)
this.setClass("activity-opinion-container opinion-container kdlistview-activity-opinions")
this.createSubViews(data)}__extends(DiscussionActivityOpinionView,_super)
DiscussionActivityOpinionView.prototype.createSubViews=function(data){var i,opinion,_i,_len,_ref,_this=this
this.opinionList=new KDListView({type:"comments",itemClass:DiscussionActivityOpinionListItemView,delegate:this},data)
this.opinionController=new OpinionListViewController({view:this.opinionList})
this.getData().on("update",function(){var item,items,opinion,opinions,opinionsData,_i,_len,_results
opinionsData=_this.getData().opinions
items=_this.opinionList.items
if((null!=opinionsData?opinionsData.length:void 0)&&items.length<2){opinions=opinionsData.slice(0,2)
_results=[]
for(_i=0,_len=opinions.length;_len>_i;_i++){opinion=opinions[_i]
_results.push(function(){var _j,_len1,_results1
_results1=[]
for(_j=0,_len1=items.length;_len1>_j;_j++){item=items[_j]
opinion!==item.getData()&&_results1.push(this.opinionList.addItem(opinion))}return _results1}.call(_this))}return _results}})
this.addSubView(this.opinionList)
if(data.opinions){_ref=data.opinions
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){opinion=_ref[i]
null!=opinion&&"object"==typeof opinion&&(i>1||this.opinionList.addItem(opinion))}}return this.addSubView(this.opinionHeader=new OpinionViewHeader({delegate:this.opinionList},data))}
DiscussionActivityOpinionView.prototype.viewAppended=function(){DiscussionActivityOpinionView.__super__.viewAppended.apply(this,arguments)
return this.getData().fake?this.hide():void 0}
return DiscussionActivityOpinionView}(KDView)

var DiscussionActivityOpinionListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DiscussionActivityOpinionListItemView=function(_super){function DiscussionActivityOpinionListItemView(options,data){var deleterId,origin,originId,originType,_ref,_this=this
options=$.extend({type:"opinion",cssClass:"kdlistitemview-activity-opinion",tooltip:{title:"Answer",offset:3,selector:"span.type-icon"}},options)
DiscussionActivityOpinionListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
data.on("OpinionIsDeleted",function(){var opinionIndex,opinions
opinions=_this.parent.getData().opinions
opinionIndex=opinions.indexOf(data)
opinions.splice(opinionIndex,1)
return _this.destroy()})
originId=data.getAt("originId")
originType=data.getAt("originType")
deleterId=null!=(_ref=data.getAt("deletedBy"))?"function"==typeof _ref.getId?_ref.getId():void 0:void 0
origin={constructorName:originType,id:originId}
this.commentCount=new ActivityCommentCount({tooltip:{title:"Comments"},click:function(){}},data)
this.author=new ProfileLinkView({origin:origin})
this.avatar=new AvatarStaticView({tagName:"span",size:{width:20,height:20},origin:origin})
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(DiscussionActivityOpinionListItemView,_super)
DiscussionActivityOpinionListItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
DiscussionActivityOpinionListItemView.prototype.click=function(event){var originId,originType,_ref
if($(event.target).is("span.avatar a, a.user-fullname")){_ref=this.getData(),originType=_ref.originType,originId=_ref.originId
return KD.remote.cacheable(originType,originId,function(err,origin){return err?void 0:KD.getSingleton("router").handleRoute("/"+origin.profile.nickname,{state:origin})})}return KD.getSingleton("router").handleRoute("/Activity/"+this.parent.getData().slug,{state:this.parent.getData()})}
DiscussionActivityOpinionListItemView.prototype.pistachio=function(){return'  <div class=\'activity-opinion item-content-comment\'>\n    <span class="avatar">{{> this.avatar}}</span>\n    <footer class="activity-opinion-item-footer">\n     {{> this.author}} posted an answer\n     {{> this.timeAgoView}}\n     <span class="comment-count">'+(this.getData().repliesCount>0?this.utils.formatPlural(this.getData().repliesCount,"Comment"):"")+"</span>\n    </footer>\n</div>"}
return DiscussionActivityOpinionListItemView}(KDListItemView)

var TutorialActivityOpinionView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TutorialActivityOpinionView=function(_super){function TutorialActivityOpinionView(options,data){TutorialActivityOpinionView.__super__.constructor.apply(this,arguments)
this.setClass("activity-opinion-container opinion-container kdlistview-activity-opinions")
this.createSubViews(data)}__extends(TutorialActivityOpinionView,_super)
TutorialActivityOpinionView.prototype.createSubViews=function(data){var i,opinion,_i,_len,_ref
this.opinionList=new KDListView({type:"comments",itemClass:TutorialActivityOpinionListItemView,delegate:this},data)
this.opinionController=new OpinionListViewController({view:this.opinionList})
this.addSubView(this.opinionList)
if(data.opinions){_ref=data.opinions
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){opinion=_ref[i]
null!=opinion&&"object"==typeof opinion&&(i>1||this.opinionList.addItem(opinion))}}return this.addSubView(this.opinionHeader=new TutorialOpinionViewHeader({delegate:this.opinionList},data))}
TutorialActivityOpinionView.prototype.viewAppended=function(){TutorialActivityOpinionView.__super__.viewAppended.apply(this,arguments)
return this.getData().fake?this.hide():void 0}
return TutorialActivityOpinionView}(KDView)

var TutorialActivityOpinionListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TutorialActivityOpinionListItemView=function(_super){function TutorialActivityOpinionListItemView(options,data){var deleterId,origin,originId,originType,_ref,_this=this
options=$.extend({type:"opinion",cssClass:"kdlistitemview-activity-opinion",tooltip:{title:"Answer",offset:3,selector:"span.type-icon"}},options)
TutorialActivityOpinionListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
data.on("OpinionIsDeleted",function(){var opinionIndex,opinions
opinions=_this.parent.getData().opinions
opinionIndex=opinions.indexOf(data)
opinions.splice(opinionIndex,1)
return _this.destroy()})
originId=data.getAt("originId")
originType=data.getAt("originType")
deleterId=null!=(_ref=data.getAt("deletedBy"))?"function"==typeof _ref.getId?_ref.getId():void 0:void 0
origin={constructorName:originType,id:originId}
this.author=new ProfileLinkView({origin:origin})
this.avatar=new AvatarStaticView({tagName:"span",size:{width:20,height:20},origin:origin})
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(TutorialActivityOpinionListItemView,_super)
TutorialActivityOpinionListItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
TutorialActivityOpinionListItemView.prototype.click=function(event){var originId,originType,_ref
if($(event.target).is("span.avatar a, a.user-fullname")){_ref=this.getData(),originType=_ref.originType,originId=_ref.originId
return KD.remote.cacheable(originType,originId,function(err,origin){return err?void 0:KD.getSingleton("appManager").tell("Members","createContentDisplay",origin)})}return KD.getSingleton("appManager").tell("Activity","createContentDisplay",this.parent.getData())}
TutorialActivityOpinionListItemView.prototype.pistachio=function(){return'  <div class=\'activity-opinion item-content-comment\'>\n    <span class="avatar">{{> this.avatar}}</span>\n    <footer class="activity-opinion-item-footer">\n      {{> this.author}} posted an answer\n      {{> this.timeAgoView}}\n    </footer>\n</div>'}
return TutorialActivityOpinionListItemView}(KDListItemView)

var TutorialOpinionViewHeader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TutorialOpinionViewHeader=function(_super){function TutorialOpinionViewHeader(options,data){var list,_ref,_this=this
null==options&&(options={})
options.cssClass="show-more-opinions in"
options.itemTypeString=options.itemTypeString||"answers"
TutorialOpinionViewHeader.__super__.constructor.call(this,options,data)
data=this.getData()
this.maxCommentToShow=5
this.oldCount=data.repliesCount
this.newCount=0
this.onListCount=data.repliesCount>this.maxCommentToShow?this.maxCommentToShow:data.repliesCount
if((null!=(_ref=this.parent)?_ref.constructor:void 0)===!TutorialActivityOpinionView){if(!(null!=data.repliesCount&&data.repliesCount>this.maxCommentToShow)){this.onListCount=data.repliesCount
this.hide()}data.repliesCount<this.maxCommentToShow&&this.hide()}list=this.getDelegate()
list.on("AllOpinionsWereAdded",function(){_this.show()
_this.newCount=0
_this.onListCount=_this.getData().repliesCount
_this.updateNewCount()
_this.allItemsLink.unsetClass("in")
_this.newItemsLink.unsetClass("in")
_this.loader.hide()
return _this.newAnswers=0})
this.allItemsLink=new KDCustomHTMLView({tagName:"a",cssClass:"all-count",partial:"View "+this.maxCommentToShow+" more "+this.getOptions().itemTypeString,click:function(){_this.loader.show()
_this.newItemsLink.unsetClass("in")
return list.emit("AllOpinionsLinkWasClicked",_this)}},data)
list.on("RelativeOpinionsWereAdded",function(){_this.updateRemainingText()
if(_this.getDelegate().items.length<_this.getData().repliesCount)_this.loader.hide()
else{_this.loader.hide()
_this.allItemsLink.unsetClass("in")}_this.newItemsLink.unsetClass("in")
_this.newAnswers=0
return _this.show()})
this.loader=new KDLoaderView({cssClass:"opinion-loader hidden",size:{width:20},loaderOptions:{color:"#FD7E09",shape:"spiral",diameter:12,density:30,range:.4,speed:2,FPS:24}})
this.newItemsLink=new KDCustomHTMLView({tagName:"a",cssClass:"new-items",click:function(){return list.emit("AllOpinionsLinkWasClicked",_this)}})
this.newAnswers=0
list.on("NewOpinionHasArrived",function(){_this.newAnswers++
_this.updateRemainingText()
_this.newItemsLink.updatePartial(""+(0===_this.newAnswers?"No":_this.newAnswers)+" new Answer"+(1===_this.newAnswers?"":"s"))
_this.setClass("has-new-items")
_this.show()
_this.allItemsLink.show()
_this.allItemsLink.setClass("in")
_this.newItemsLink.show()
return _this.newItemsLink.setClass("in")})}__extends(TutorialOpinionViewHeader,_super)
TutorialOpinionViewHeader.prototype.hide=function(){this.unsetClass("in")
return TutorialOpinionViewHeader.__super__.hide.apply(this,arguments)}
TutorialOpinionViewHeader.prototype.show=function(){this.setClass("in")
return TutorialOpinionViewHeader.__super__.show.apply(this,arguments)}
TutorialOpinionViewHeader.prototype.viewAppended=function(){var _ref
this.setTemplate(this.pistachio())
this.template.update()
this.updateRemainingText()
return(null!=(_ref=this.parent)?_ref.constructor:void 0)===OpinionView&&0===this.getData().repliesCount?this.hide():void 0}
TutorialOpinionViewHeader.prototype.updateRemainingText=function(){var remainingOpinions
if(null==this.parent||this.parent.constructor===TutorialActivityOpinionView)return this.getData().repliesCount>1?this.allItemsLink.updatePartial("View all Answers"):1===this.getData().repliesCount?this.allItemsLink.updatePartial("View first Answer"):this.allItemsLink.updatePartial("No Answers yet")
remainingOpinions=this.getData().repliesCount-this.getDelegate().items.length
return remainingOpinions<this.maxCommentToShow?1===remainingOpinions?this.allItemsLink.updatePartial("View remaining answer"):remainingOpinions>1?this.allItemsLink.updatePartial("View remaining "+remainingOpinions+" "+this.getOptions().itemTypeString):0===this.newAnswers?this.allItemsLink.updatePartial(""):this.allItemsLink.updatePartial("View new answers"):void 0}
TutorialOpinionViewHeader.prototype.pistachio=function(){return"{{> this.allItemsLink}}{{> this.newItemsLink}}\n{{> this.loader}}"}
return TutorialOpinionViewHeader}(JView)

var OpinionViewHeader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionViewHeader=function(_super){function OpinionViewHeader(options,data){var list,_ref,_this=this
null==options&&(options={})
options.cssClass="show-more-opinions in"
options.itemTypeString=options.itemTypeString||"answers"
OpinionViewHeader.__super__.constructor.call(this,options,data)
data=this.getData()
this.maxCommentToShow=5
this.oldCount=data.opinionCount
this.newCount=0
this.newAnswers=0
this.onListCount=data.opinionCount>this.maxCommentToShow?this.maxCommentToShow:data.opinionCount
if((null!=(_ref=this.parent)?_ref.constructor:void 0)===!DiscussionActivityOpinionView){if(!(null!=data.opinionCount&&data.opinionCount>this.maxCommentToShow)){this.onListCount=data.opinionCount
this.hide()}data.opinionCount<this.maxCommentToShow&&this.hide()}list=this.getDelegate()
list.on("AllOpinionsWereAdded",function(){_this.show()
_this.newCount=0
_this.onListCount=_this.getData().opinionCount
_this.updateNewCount()
_this.allItemsLink.unsetClass("in")
_this.newItemsLink.unsetClass("in")
_this.loader.hide()
_this.newAnswers=0
return _this.updateRemainingText()})
this.allItemsLink=new KDCustomHTMLView({tagName:"a",cssClass:"all-count",partial:"View "+this.maxCommentToShow+" more "+this.getOptions().itemTypeString,click:function(event){var _ref1
event.preventDefault()
_this.resetCounts()
_this.newItemsLink.unsetClass("in")
if((null!=(_ref1=_this.parent)?_ref1.constructor:void 0)!==DiscussionActivityOpinionView){_this.loader.show()
return list.emit("AllOpinionsLinkWasClicked",_this)}return KD.getSingleton("router").handleRoute("/Activity/"+_this.getDelegate().getData().slug,{state:_this.getDelegate().getData()})}},data)
list.on("RelativeOpinionsWereAdded",function(){_this.updateRemainingText()
if(_this.getDelegate().items.length<_this.getData().opinionCount)_this.loader.hide()
else{_this.loader.hide()
_this.allItemsLink.unsetClass("in")}_this.newItemsLink.unsetClass("in")
_this.newAnswers=0
return _this.show()})
this.loader=new KDLoaderView({cssClass:"opinion-loader hidden",size:{width:20},loaderOptions:{color:"#FD7E09",shape:"spiral",diameter:12,density:30,range:.4,speed:2,FPS:24}})
this.newItemsLink=new KDCustomHTMLView({tagName:"a",cssClass:"new-items",click:function(event){var _ref1
event.preventDefault()
_this.resetCounts()
_this.newItemsLink.unsetClass("in")
list.emit("AllOpinionsLinkWasClicked",_this)
return(null!=(_ref1=_this.parent)?_ref1.constructor:void 0)===DiscussionActivityOpinionView?KD.getSingleton("router").handleRoute("/Activity/"+_this.getDelegate().getData().slug,{state:_this.getDelegate().getData()}):void 0}})
list.on("NewOpinionHasArrived",function(reply){var opinionCount,_ref1
opinionCount=_this.getData().opinionCount;(null!=reply?null!=(_ref1=reply.replier)?_ref1.id:void 0:void 0)!==KD.whoami().getId()&&(_this.newAnswers=opinionCount-(_this.oldCount||0))
_this.updateRemainingText()
return _this.updateNewItems()})
list.on("OpinionIsDeleted",function(){return _this.updateNewItems()})}__extends(OpinionViewHeader,_super)
OpinionViewHeader.prototype.resetCounts=function(){this.oldCount=this.getData().opinionCount
return this.newAnswers=0}
OpinionViewHeader.prototype.hide=function(){this.unsetClass("in")
return OpinionViewHeader.__super__.hide.apply(this,arguments)}
OpinionViewHeader.prototype.show=function(){this.setClass("in")
return OpinionViewHeader.__super__.show.apply(this,arguments)}
OpinionViewHeader.prototype.viewAppended=function(){var _ref
this.setTemplate(this.pistachio())
this.template.update()
this.updateRemainingText()
return(null!=(_ref=this.parent)?_ref.constructor:void 0)===OpinionView&&0===this.getData().opinionCount?this.hide():void 0}
OpinionViewHeader.prototype.render=function(){var _ref
this.updateRemainingText()
return(null!=(_ref=this.parent)?_ref.constructor:void 0)===OpinionView&&0===this.getData().opinionCount?this.hide():void 0}
OpinionViewHeader.prototype.updateRemainingText=function(){var commentText,opinionCount,remainingOpinions,repliesCount,_ref
_ref=this.getData(),opinionCount=_ref.opinionCount,repliesCount=_ref.repliesCount
commentText=repliesCount>0?" and "+repliesCount+" Comments":""
if(null!=this.allItemsLink){if(null==this.parent||this.parent.constructor===DiscussionActivityOpinionView)return opinionCount>1?this.allItemsLink.updatePartial("View "+this.getData().opinionCount+" Answers"+commentText):1===opinionCount?this.allItemsLink.updatePartial("View one Answer"+commentText):this.allItemsLink.updatePartial("No Answers yet"+(repliesCount>0?". View "+repliesCount+" Comment"+(1!==repliesCount?"s":""):""))
remainingOpinions=opinionCount-this.getDelegate().items.length
if(remainingOpinions<this.maxCommentToShow)return 1===remainingOpinions?this.allItemsLink.updatePartial("View remaining answer"):remainingOpinions>1?this.allItemsLink.updatePartial("View remaining "+remainingOpinions+" "+this.getOptions().itemTypeString):0===this.newAnswers?this.allItemsLink.updatePartial(""):this.allItemsLink.updatePartial("View new answers")}}
OpinionViewHeader.prototype.updateNewItems=function(){var _ref
if(this.getData().opinionCount>0&&this.newAnswers>0){null!=(_ref=this.newItemsLink)&&_ref.updatePartial(""+this.newAnswers+" new Answer"+(1===this.newAnswers?"":"s"))
this.setClass("has-new-items")
this.show()
this.allItemsLink.show()
this.allItemsLink.setClass("in")
this.newItemsLink.show()
return this.newItemsLink.setClass("in")}return this.newItemsLink.unsetClass("in")}
OpinionViewHeader.prototype.pistachio=function(){return"{{> this.allItemsLink}}{{> this.newItemsLink}}\n{{> this.loader}}"}
return OpinionViewHeader}(JView)

var OpinionListViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionListViewController=function(_super){function OpinionListViewController(){OpinionListViewController.__super__.constructor.apply(this,arguments)
this._hasBackgrounActivity=!1
this.startListeners()}__extends(OpinionListViewController,_super)
OpinionListViewController.prototype.instantiateListItems=function(items,keepDeletedOpinions){var i,newItems,nextOpinion,opinion,opinionView,skipOpinion,_i,_len
null==keepDeletedOpinions&&(keepDeletedOpinions=!1)
newItems=[]
items.sort(function(a,b){a=a.meta.createdAt
b=b.meta.createdAt
return b>a?-1:a>b?1:0})
for(i=_i=0,_len=items.length;_len>_i;i=++_i){opinion=items[i]
nextOpinion=items[i+1]
skipOpinion=!1
null!=nextOpinion&&opinion.deletedAt&&Date.parse(nextOpinion.meta.createdAt)>Date.parse(opinion.deletedAt)&&(skipOpinion=!0)
!nextOpinion&&opinion.deletedAt&&(skipOpinion=!0)
keepDeletedOpinions&&(skipOpinion=!1)
if(!skipOpinion){opinionView=this.getListView().addItem(opinion)
newItems.push(opinionView)}}return newItems}
OpinionListViewController.prototype.startListeners=function(){var listView,_this=this
listView=this.getListView()
listView.on("ItemWasAdded",function(view){return view.on("OpinionIsDeleted",function(data){return listView.emit("OpinionIsDeleted",data)})})
listView.on("OwnOpinionHasArrived",function(data){listView.addItem(data,null,{type:"slideDown",duration:100})
return this.getDelegate().resetDecoration()})
return listView.on("AllOpinionsLinkWasClicked",function(){var meta
if(!_this._hasBackgrounActivity){_this.utils.wait(5e3,function(){return listView.emit("BackgroundActivityFinished")})
meta=listView.getData().meta
listView.emit("BackgroundActivityStarted")
_this._hasBackgrounActivity=!0
_this._removedBefore=!1
return _this.fetchRelativeOpinions(5,listView.items.length,function(err,opinions){var opinion,_i,_len
for(_i=0,_len=opinions.length;_len>_i;_i++){opinion=opinions[_i]
listView.addItem(opinion,null,{type:"slideDown",duration:100})}return listView.emit("RelativeOpinionsWereAdded")})}})}
OpinionListViewController.prototype.fetchTeaser=function(){var listView,message
listView=this.getListView()
message=this.getListView().getData()
return message.updateTeaser(function(err){return err?log(err):void 0})}
OpinionListViewController.prototype.fetchOpinionsByRange=function(from,to,callback){var message,query,_ref,_this=this
callback||(_ref=[callback,to],to=_ref[0],callback=_ref[1])
query={from:from,to:to}
message=this.getListView().getData()
return message.opinionsByRange(query,function(err,opinions){_this.getListView().emit("BackgroundActivityFinished")
return callback(err,opinions)})}
OpinionListViewController.prototype.fetchAllOpinions=function(skipCount,callback){var listView,message
null==skipCount&&(skipCount=3)
null==callback&&(callback=noop)
listView=this.getListView()
listView.emit("BackgroundActivityStarted")
message=this.getListView().getData()
return message.restOpinions(skipCount,function(err,opinions){listView.emit("BackgroundActivityFinished")
listView.emit("AllOpinionsWereAdded")
return callback(err,opinions)})}
OpinionListViewController.prototype.fetchRelativeOpinions=function(_limit,_from,callback){var listView,message,_this=this
null==_limit&&(_limit=10)
null==callback&&(callback=noop)
listView=this.getListView()
message=this.getListView().getData()
return message.opinionsByRange({to:_limit+_from,from:_from},function(err,opinions){listView=_this.getListView()
listView.emit("BackgroundActivityFinished")
_this._hasBackgrounActivity=!1
return null!=callback?callback(err,opinions):void 0})}
OpinionListViewController.prototype.replaceAllOpinions=function(opinions){this.removeAllItems()
return this.instantiateListItems(opinions)}
return OpinionListViewController}(KDListViewController)

var OpinionBodyView,OpinionListItemView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionListItemView=function(_super){function OpinionListItemView(options,data){var deleterId,loggedInId,origin,originId,originType,_ref,_this=this
options=$.extend({type:"opinion",cssClass:"kdlistitemview kdlistitemview-comment"},options)
OpinionListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
this.commentBox=new CommentView(null,data)
data.repliesCount&&null==data.replies&&data.commentsByRange({from:0,to:5},function(err,comments){var comment,_i,_len,_results
if(err)return log(err)
comments=comments.reverse()
data.replies=comments
_this.commentBox.setData(comments)
_results=[]
for(_i=0,_len=comments.length;_len>_i;_i++){comment=comments[_i]
_results.push(_this.commentBox.commentList.addItem(comment))}return _results})
this.commentBox.on("RefreshTeaser",function(){return _this.parent.emit("RefreshTeaser")})
data.on("OpinionIsDeleted",function(){_this.hide()
return delete _this})
originId=data.getAt("originId")
originType=data.getAt("originType")
deleterId=null!=(_ref=data.getAt("deletedBy"))?"function"==typeof _ref.getId?_ref.getId():void 0:void 0
origin={constructorName:originType,id:originId}
this.needsToResize=!1
this.avatar=new AvatarView({size:{width:40,height:40},origin:origin})
this.author=new ProfileLinkView({origin:origin})
null!=deleterId&&deleterId!==originId&&(this.deleter=new ProfileLinkView({},data.getAt("deletedBy")))
this.deleteLink=new KDCustomHTMLView({tagName:"a",attributes:{title:"Delete your opinion",href:"#"},cssClass:"delete-link hidden"})
this.editLink=new KDCustomHTMLView({tagName:"a",attributes:{title:"Edit your opinion",href:"#"},cssClass:"edit-link hidden"})
this.actionLinks=new ActivityActionsView({delegate:this.commentBox.commentList,cssClass:"opinion-comment-header"},data)
this.bodyView=new OpinionBodyView({cssClass:"data-wrapper"},data)
this.tags=new ActivityChildViewTagGroup({itemsToShow:3,itemClass:TagLinkView},data.meta.tags)
this.smaller=new KDCustomHTMLView({tagName:"a",cssClass:"opinion-size-link hidden",attributes:{href:"#",title:"Show less"},partial:"See less…",click:function(event){event.preventDefault()
_this.markup.css({"max-height":"300px"})
_this.larger.show()
return _this.smaller.hide()}})
this.larger=new KDCustomHTMLView({tagName:"a",cssClass:"opinion-size-link hidden",attributes:{href:"#",title:"Show more"},partial:"See more…",click:function(){_this.markup.css({maxHeight:_this.textMaxHeight+20})
_this.smaller.show()
return _this.larger.hide()}})
this.textMaxHeight=0
loggedInId=KD.whoami().getId()
if(loggedInId===data.originId||KD.checkFlag("super-admin",KD.whoami())){this.editLink.on("click",function(){var _ref1
if(null!=_this.editForm){null!=(_ref1=_this.editForm)&&_ref1.destroy()
delete _this.editForm
_this.$("p.opinion-body").show()
_this.needsToResize&&_this.$(".opinion-size-links").show()}_this.editForm=new OpinionFormView({submitButtonTitle:"Save your changes",title:"edit-opinion",cssClass:"edit-opinion-form opinion-container",callback:function(data){return _this.getData().modify(data,function(err,opinion){_this.$("p.opinion-body").show()
"function"==typeof callback&&callback(err,opinion)
_this.editForm.reset()
_this.editForm.submitOpinionBtn.hideLoader()
if(err)return new KDNotificationView({title:"Your changes weren't saved.",type:"mini"})
_this.getDelegate().emit("RefreshTeaser",function(){})
_this.emit("OwnOpinionWasAdded",opinion)
_this.editForm.setClass("hidden")
_this.$("p.opinion-body").show()
return _this.needsToResize?_this.$(".opinion-size-links").show():void 0})}},data)
_this.addSubView(_this.editForm,"p.opinion-body-edit",!0)
_this.$("p.opinion-body").hide()
return _this.needsToResize?_this.$(".opinion-size-links").hide():void 0})
this.deleteLink.on("click",function(){return _this.confirmDeleteOpinion(data)})
this.editLink.unsetClass("hidden")
this.deleteLink.unsetClass("hidden")}this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(OpinionListItemView,_super)
OpinionListItemView.prototype.render=function(){OpinionListItemView.__super__.render.call(this)
return this.$("p.opinion-body span.data pre").each(function(i,element){return element=hljs.highlightBlock(element)})}
OpinionListItemView.prototype.viewAppended=function(){var maxHeight
this.setTemplate(this.pistachio())
this.template.update()
this.markup=this.$("p.opinion-body")
maxHeight=300
if(this.markup.height()>maxHeight){this.needsToResize=!0
this.textMaxHeight=this.markup.height()
this.markup.css({maxHeight:maxHeight})
this.larger.show()}return this.$("p.opinion-body span.data pre").each(function(i,element){return element=hljs.highlightBlock(element)})}
OpinionListItemView.prototype.click=function(event){var originId,originType,_ref
"_blank"!==$(event.target).attr("target")&&event.preventDefault()
if($(event.target).is("span.avatar a, a.user-fullname")){_ref=this.getData(),originType=_ref.originType,originId=_ref.originId
return KD.remote.cacheable(originType,originId,function(err,origin){return err?void 0:KD.getSingleton("router").handleRoute("/"+origin.profile.nickname,{state:origin})})}}
OpinionListItemView.prototype.confirmDeleteOpinion=function(data){var modal,_this=this
return modal=new KDModalView({title:"Delete opinion",content:"<div class='modalformline'>Are you sure you want to delete this opinion?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){_this.hide()
return data["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
if(err)_this.show()
else{_this.getDelegate().getData().emit("OpinionWasRemoved",!0)
_this.destroy()}return err?new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"}):void 0})}}}})}
OpinionListItemView.prototype.pistachio=function(){return"<div class='item-content-opinion clearfix'>\n  <span class='avatar'>{{> this.avatar}}</span>\n  <div class='opinion-contents clearfix'>\n    {{> this.deleteLink}}\n    {{> this.editLink}}\n    <p class=\"opinion-body-edit\"></p>\n    <p class='opinion-body has-markdown'>\n      {{> this.bodyView}}\n    </p>\n    <div class=\"opinion-size-links\">\n      {{> this.larger}}\n      {{> this.smaller}}\n    </div>\n</div>\n    <footer class='opinion-footer clearfix'>\n      <div class='type-and-time'>\n        <span class='type-icon'></span> answer by {{> this.author}} •\n        {{> this.timeAgoView}}\n        {{> this.tags}}\n        {{> this.actionLinks}}\n      </div>\n    </footer>\n</div>\n<div class='item-content-opinion-comments clearfix'>\n  <div class='opinion-comment'>\n    {{> this.commentBox}}\n  </div>\n</div>"}
return OpinionListItemView}(KDListItemView)
OpinionBodyView=function(_super){function OpinionBodyView(){_ref=OpinionBodyView.__super__.constructor.apply(this,arguments)
return _ref}__extends(OpinionBodyView,_super)
OpinionBodyView.prototype.pistachio=function(){return'{{this.utils.expandUsernames(this.utils.applyMarkdown(#(body)), "pre, code")}}'}
return OpinionBodyView}(JView)

var OpinionCommentListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionCommentListItemView=function(_super){function OpinionCommentListItemView(options,data){var activity,deleterId,origin,originId,originType,_ref,_this=this
null==options&&(options={})
options.type||(options.type="comment")
options.cssClass||(options.cssClass="kdlistitemview kdlistitemview-comment")
OpinionCommentListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
originId=data.getAt("originId")
originType=data.getAt("originType")
deleterId=null!=(_ref=data.getAt("deletedBy"))?"function"==typeof _ref.getId?_ref.getId():void 0:void 0
origin={constructorName:originType,id:originId}
this.avatar=new AvatarView({size:{width:30,height:30},origin:origin})
this.author=new ProfileLinkView({origin:origin})
null!=deleterId&&deleterId!==originId&&(this.deleter=new ProfileLinkView({},data.getAt("deletedBy")))
this.deleteLink=new KDCustomHTMLView({tagName:"a",attributes:{href:"#"},cssClass:"delete-link hidden"})
activity=this.getDelegate().getData()
KD.remote.cacheable("JAccount",data.originId,function(err,account){var loggedInId
loggedInId=KD.whoami().getId()
if(loggedInId===data.originId||loggedInId===activity.originId||KD.checkFlag("super-admin",account)){_this.deleteLink.unsetClass("hidden")
return _this.deleteLink.on("click",function(){return _this.confirmDeleteComment(data)})}})
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(OpinionCommentListItemView,_super)
OpinionCommentListItemView.prototype.render=function(){this.getData().getAt("deletedAt")&&this.emit("CommentIsDeleted")
this.setTemplate(this.pistachio())
return OpinionCommentListItemView.__super__.render.apply(this,arguments)}
OpinionCommentListItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
OpinionCommentListItemView.prototype.click=function(event){var originId,originType,_ref
if($(event.target).is("span.avatar a, a.user-fullname")){_ref=this.getData(),originType=_ref.originType,originId=_ref.originId
return KD.remote.cacheable(originType,originId,function(err,origin){return err?void 0:KD.getSingleton("appManager").tell("Members","createContentDisplay",origin)})}}
OpinionCommentListItemView.prototype.confirmDeleteComment=function(data){var modal
return modal=new KDModalView({title:"Delete comment",content:"<div class='modalformline'>Are you sure you want to delete this comment?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return data["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
return err?new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"}):void 0})}},cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}}})}
OpinionCommentListItemView.prototype.pistachio=function(){if(this.getData().getAt("deletedAt")){this.setClass("deleted")
return this.deleter?"<div class='item-content-comment clearfix'><span>{{> this.author}}'s comment has been deleted by {{> this.deleter}}.</span></div>":"<div class='item-content-comment clearfix'><span>{{> this.author}}'s comment has been deleted.</span></div>"}return"<div class='item-content-comment clearfix'>\n  <span class='avatar'>{{> this.avatar}}</span>\n  <div class=\"comment-header\">\n    {{> this.author}}\n  </div>\n  <div class='comment-contents clearfix'>\n    {{> this.deleteLink}}\n    <p class='comment-body'>\n      {{this.utils.applyTextExpansions(#(body))}}\n    </p>\n    {{> this.timeAgoView}}\n  </div>\n</div>"}
return OpinionCommentListItemView}(KDListItemView)

var OpinionFormView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionFormView=function(_super){function OpinionFormView(options,data){var profile,typeLabel,_this=this
this.preview=options.preview||{}
OpinionFormView.__super__.constructor.apply(this,arguments)
typeLabel=options.typeLabel||"discussion"
profile=KD.whoami().profile
this.submitOpinionBtn=new KDButtonView({title:options.submitButtonTitle||"Post your reply",type:"submit",cssClass:"clean-gray opinion-submit-button",loader:{diameter:12}})
this.cancelOpinionBtn=new KDButtonView({title:"Cancel",cssClass:"modal-cancel opinion-cancel",type:"button",style:"modal-cancel",callback:function(){var _ref
return null!=(_ref=_this.parent)?_ref.editLink.$().click():void 0}})
this.showMarkdownPreview=options.previewVisible
this.opinionBody=new KDInputViewWithPreview({preview:this.preview,cssClass:"opinion-body",name:"body",title:"your Opinion",type:"textarea",placeholder:"What do you want to contribute to the "+typeLabel+"?",validate:{rules:{required:!0},messages:{required:"Please provide an opinion..."}}})
this.heartBox=new HelpBox({subtitle:"About Answers and Opinions",tooltip:{title:"Click me for additional information"},click:function(){var modal
return modal=new KDModalView({title:"Additional information on Discussions",content:"<div class='modalformline signature'><p>Here you can edit your replies.</p></div>",height:"auto",overlay:!0,buttons:{Okay:{style:"modal-clean-gray",loader:{color:"#ffffff",diameter:16},callback:function(){modal.buttons.Okay.hideLoader()
return modal.destroy()}}}})}})
if(data instanceof KD.remote.api.JOpinion){this.opinionBody.setValue(Encoder.htmlDecode(data.body))
this.opinionBody.generatePreview()}}__extends(OpinionFormView,_super)
OpinionFormView.prototype.viewAppended=function(){this.setClass("update-options opinion")
this.setTemplate(this.pistachio())
return this.template.update()}
OpinionFormView.prototype.reset=function(){this.opinionBody.setValue("")
return OpinionFormView.__super__.reset.apply(this,arguments)}
OpinionFormView.prototype.submit=function(){var _this=this
this.on("FormValidationFailed",function(){return _this.submitOpinionBtn.hideLoader()})
return OpinionFormView.__super__.submit.apply(this,arguments)}
OpinionFormView.prototype.pistachio=function(){return'<div class="opinion-box" id="opinion-form-box">\n  <div class="opinion-form">\n    {{> this.opinionBody}}\n  </div>\n  <div class="opinion-buttons">\n    <div class="opinion-heart-box">\n      {{> this.heartBox}}\n    </div>\n    <div class="opinion-submit">\n      {{> this.submitOpinionBtn}}\n      {{> this.cancelOpinionBtn}}\n    </div>\n  </div>\n</div>'}
return OpinionFormView}(KDFormView)

var OpinionCommentView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpinionCommentView=function(_super){function OpinionCommentView(options,data){OpinionCommentView.__super__.constructor.apply(this,arguments)
this.setClass("comment-container")
this.createSubViews(data)
this.resetDecoration()
this.attachListeners()}__extends(OpinionCommentView,_super)
OpinionCommentView.prototype.render=function(){return this.resetDecoration()}
OpinionCommentView.prototype.createSubViews=function(data){var reply,showMore,_i,_len,_ref
this.commentList=new KDListView({type:"comments",itemClass:OpinionCommentListItemView,delegate:this},data)
this.commentController=new CommentListViewController({view:this.commentList})
this.addSubView(showMore=new CommentViewHeader({delegate:this.commentList,maxCommentToShow:1e4},data))
this.addSubView(this.commentList)
this.addSubView(this.commentForm=new NewCommentForm({delegate:this.commentList}))
this.commentList.on("OwnCommentHasArrived",function(){showMore.ownCommentArrived()
return this.getDelegate().emit("DiscussionTeaserShouldRefresh")})
this.commentList.on("CommentIsDeleted",function(){return showMore.ownCommentDeleted()})
if(data.replies){_ref=data.replies
for(_i=0,_len=_ref.length;_len>_i;_i++){reply=_ref[_i]
null!=reply&&"object"==typeof reply&&this.commentList.addItem(reply)}}return this.commentList.emit("BackgroundActivityFinished")}
OpinionCommentView.prototype.attachListeners=function(){var _this=this
this.commentList.on("commentInputReceivedFocus",this.bound("decorateActiveCommentState"))
this.commentList.on("CommentLinkReceivedClick",function(){return _this.commentForm.commentInput.setFocus()})
this.commentList.on("CommentCountClicked",function(){_this.commentList.emit("AllCommentsLinkWasClicked")
return _this.commentForm.commentInput.setFocus()})
return this.commentList.on("CommentViewShouldReset",this.bound("resetDecoration"))}
OpinionCommentView.prototype.resetDecoration=function(){var post
post=this.getData()
return 0===this.commentList.items.length?this.decorateNoCommentState():this.decorateCommentedState()}
OpinionCommentView.prototype.decorateNoCommentState=function(){this.unsetClass("active-comment")
this.unsetClass("commented")
return this.setClass("no-comment")}
OpinionCommentView.prototype.decorateCommentedState=function(){this.unsetClass("active-comment")
this.unsetClass("no-comment")
return this.setClass("commented")}
OpinionCommentView.prototype.decorateActiveCommentState=function(){this.unsetClass("commented")
this.unsetClass("no-comment")
return this.setClass("active-comment")}
OpinionCommentView.prototype.decorateItemAsLiked=function(likeObj){var _ref;(null!=likeObj?null!=(_ref=likeObj.results)?_ref.likeCount:void 0:void 0)>0?this.setClass("liked"):this.unsetClass("liked")
return this.ActivityActionsView.setLikedCount(likeObj)}
return OpinionCommentView}(KDView)

var DiscussionFormView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DiscussionFormView=function(_super){function DiscussionFormView(options,data){var profile,_this=this
DiscussionFormView.__super__.constructor.apply(this,arguments)
this.preview=options.preview||{}
profile=KD.whoami().profile
this.submitDiscussionBtn=new KDButtonView({title:"Save your changes",type:"submit",cssClass:"clean-gray discussion-submit-button",loader:{diameter:12}})
this.cancelDiscussionBtn=new KDButtonView({title:"Cancel",cssClass:"modal-cancel discussion-cancel",type:"button",style:"modal-cancel",callback:function(){var _ref
return null!=(_ref=_this.parent)?_ref.editDiscussionLink.$().click():void 0}})
this.discussionBody=new KDInputViewWithPreview({preview:this.preview,cssClass:"discussion-body",name:"body",title:"your Discussion Topic",type:"textarea",placeholder:"What do you want to contribute to the discussion?"})
this.discussionTitle=new KDInputView({cssClass:"discussion-title",name:"title",title:"your Opinion",type:"text",placeholder:"What do you want to talk about?"})
if(data instanceof KD.remote.api.JDiscussion){this.discussionBody.setValue(Encoder.htmlDecode(data.body))
this.discussionTitle.setValue(Encoder.htmlDecode(data.title))}}__extends(DiscussionFormView,_super)
DiscussionFormView.prototype.viewAppended=function(){this.setClass("update-options discussion")
this.setTemplate(this.pistachio())
return this.template.update()}
DiscussionFormView.prototype.submit=function(){return DiscussionFormView.__super__.submit.apply(this,arguments)}
DiscussionFormView.prototype.pistachio=function(){return'<div class="discussion-box">\n  <div class="discussion-form">\n    {{> this.discussionTitle}}\n    {{> this.discussionBody}}\n  </div>\n  <div class="discussion-buttons">\n    <div class="discussion-submit">\n      {{> this.submitDiscussionBtn}}\n      {{> this.cancelDiscussionBtn}}\n    </div>\n  </div>\n</div>'}
return DiscussionFormView}(KDFormView)

var TutorialFormView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TutorialFormView=function(_super){function TutorialFormView(options,data){var profile,_ref,_this=this
TutorialFormView.__super__.constructor.apply(this,arguments)
this.preview=options.preview||{}
profile=KD.whoami().profile
this.submitDiscussionBtn=new KDButtonView({title:"Save your changes",type:"submit",cssClass:"clean-gray tutorial-submit-button",loader:{diameter:12}})
this.cancelDiscussionBtn=new KDButtonView({title:"Cancel",cssClass:"modal-cancel tutorial-cancel",type:"button",style:"modal-cancel",callback:function(){var _ref
return null!=(_ref=_this.parent)?_ref.editDiscussionLink.$().click():void 0}})
this.discussionBody=new KDInputViewWithPreview({preview:this.preview,cssClass:"tutorial-body",name:"body",title:"your Tutorial",type:"textarea",placeholder:"What do you want to contribute to the tutorial?"})
this.discussionEmbedLink=new KDInputView({cssClass:"tutorial-title",name:"embed",title:"your Video",type:"text",placeholder:"The URL to your video",keyup:function(){return""===_this.discussionEmbedLink.getValue()?_this.getDelegate().embedBox.resetEmbedAndHide():void 0},paste:function(){return _this.utils.defer(function(){var embedOptions,url
_this.discussionEmbedLink.setValue(_this.sanitizeUrls(_this.discussionEmbedLink.getValue()))
url=_this.discussionEmbedLink.getValue()
if(/^((http(s)?\:)?\/\/)/.test(url)){embedOptions={maxWidth:540,maxHeight:200}
return _this.getDelegate().embedBox.embedUrl(url,embedOptions,_this.getDelegate().embedBox.show.bind(_this))}})}})
this.discussionTitle=new KDInputView({cssClass:"tutorial-title",name:"title",title:"your Tutorial title",type:"text",placeholder:"What do you want to talk about?"})
if(data instanceof KD.remote.api.JTutorial){this.discussionBody.setValue(Encoder.htmlDecode(data.body))
this.discussionEmbedLink.setValue(Encoder.htmlDecode(null!=(_ref=data.link)?_ref.link_url:void 0))
this.discussionTitle.setValue(Encoder.htmlDecode(data.title))}}__extends(TutorialFormView,_super)
TutorialFormView.prototype.sanitizeUrls=function(text){return text.replace(/(([a-zA-Z]+\:)\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g,function(url){var test
test=/^([a-zA-Z]+\:\/\/)/.test(url)
return test===!1?"http://"+url:url})}
TutorialFormView.prototype.viewAppended=function(){this.setClass("update-options tutorial")
this.setTemplate(this.pistachio())
return this.template.update()}
TutorialFormView.prototype.submit=function(){this.removeCustomData("link")
this.getDelegate().embedBox.hasValidContent&&this.addCustomData("link",{link_url:this.getDelegate().embedBox.url,link_embed:this.getDelegate().embedBox.getDataForSubmit()})
return TutorialFormView.__super__.submit.apply(this,arguments)}
TutorialFormView.prototype.pistachio=function(){return'<div class="tutorial-box">\n  <div class="tutorial-form">\n    {{> this.discussionTitle}}\n    {{> this.discussionEmbedLink}}\n    {{> this.discussionBody}}\n  </div>\n  <div class="tutorial-buttons">\n    <div class="tutorial-submit">\n      {{> this.submitDiscussionBtn}}\n      {{> this.cancelDiscussionBtn}}\n    </div>\n  </div>\n</div>'}
return TutorialFormView}(KDFormView)

var MarkdownModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MarkdownModal=function(_super){function MarkdownModal(options,data){var _this=this
null==options&&(options={})
options=$.extend({title:"How to use the <em>Markdown</em> syntax.",cssClass:"what-you-should-know-modal markdown-cheatsheet",height:"auto",overlay:!0,width:500,content:this.markdownText(),buttons:{Close:{title:"Close",style:"modal-clean-gray",callback:function(){return _this.destroy()}}}},options)
if(!KD._markdownHelpModal){KD._markdownHelpModal=this
MarkdownModal.__super__.constructor.call(this,options,data)}}__extends(MarkdownModal,_super)
MarkdownModal.prototype.destroy=function(){delete KD._markdownHelpModal
return MarkdownModal.__super__.destroy.apply(this,arguments)}
MarkdownModal.prototype.markdownText=function(){var text
return text=this.markdownTextHTML()}
MarkdownModal.prototype.markdownTextHTML=function(){return'<div class=\'modalformline\'>This form supports <a href="http://daringfireball.net/projects/markdown/" target="_blank" title="Markdown project homepage">Markdown</a> and <a href="http://github.github.com/github-flavored-markdown/" target="_blank">GitHub-flavored Markdown</a>. Here is how to use it:</div>\n\n<div class="modalformline markdown-cheatsheet">\n<div class="modal-block">\n<h3>Phrase Emphasis</h3>\n\n<pre><code>*italic*   **bold**\n_italic_   __bold__\n</code></pre>\n</div><div class="modal-block">\n\n<h3>Links</h3>\n\n<p>Inline:</p>\n\n<pre><code>An [example](http://url.com/ "Title")\n</code></pre>\n\n<p>Reference-style labels (titles are optional):</p>\n\n<pre><code>An [example][id]. Then, anywhere\nelse in the doc, define the link:\n\n  [id]: http://example.com/  "Title"\n</code></pre>\n</div><div class="modal-block">\n<h3>Images</h3>\n\n<p>Inline (titles are optional):</p>\n\n<pre><code>![alt text](/path/img.jpg "Title")\n</code></pre>\n\n<p>Reference-style:</p>\n\n<pre><code>![alt text][id]\n\n[id]: /url/to/img.jpg "Title"\n</code></pre>\n</div><div class="modal-block">\n<h3>Headers</h3>\n\n<p>Setext-style:</p>\n\n<pre><code>Header 1\n========\n\nHeader 2\n--------\n</code></pre>\n\n<p>atx-style (closing #\'s are optional):</p>\n\n<pre><code># Header 1 #\n\n## Header 2 ##\n\n###### Header 6\n</code></pre>\n</div><div class="modal-block">\n<h3>Lists</h3>\n\n<p>Ordered, without paragraphs:</p>\n\n<pre><code>1.  Foo\n2.  Bar\n</code></pre>\n\n<p>Unordered, with paragraphs:</p>\n\n<pre><code>*   A list item.\n\n    With multiple paragraphs.\n\n*   Bar\n</code></pre>\n\n<p>You can nest them:</p>\n\n<pre><code>*   Abacus\n    * answer\n*   Bubbles\n    1.  bunk\n    2.  bupkis\n        * BELITTLER\n    3. burper\n*   Cunning\n</code></pre>\n</div><div class="modal-block">\n<h3>Blockquotes</h3>\n\n<pre><code>&gt; Email-style angle brackets\n&gt; are used for blockquotes.\n\n&gt; &gt; And, they can be nested.\n\n&gt; #### Headers in blockquotes\n&gt;\n&gt; * You can quote a list.\n&gt; * Etc.\n</code></pre>\n</div><div class="modal-block">\n<h3>Code Spans</h3>\n\n<pre><code>`&lt;code&gt;` spans are delimited\nby backticks.\n\nYou can include literal backticks\nlike `` `this` ``.\n</code></pre>\n</div><div class="modal-block">\n<h3>Preformatted Code Blocks</h3>\n\n<p>Indent every line of a code block by at least 4 spaces or 1 tab.</p>\n\n<pre><code>This is a normal paragraph.\n\n    This is a preformatted\n    code block.\n</code></pre>\n</div><div class="modal-block">\n<h3>Horizontal Rules</h3>\n\n<p>Three or more dashes or asterisks:</p>\n\n<pre><code>---\n\n* * *\n\n- - - -\n</code></pre>\n</div><div class="modal-block">\n<h3>Manual Line Breaks</h3>\n\n<p>End a line with two or more spaces:</p>\n\n<pre><code>Roses are red,\nViolets are blue.\n</code></pre>\n</div>\n</div>\n</div>'}
return MarkdownModal}(KDModalView)

var DropboxDownloadItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DropboxDownloadItemView=function(_super){function DropboxDownloadItemView(options,data){var fileData
null==options&&(options={})
options.cssClass="dropbox-download-item"
DropboxDownloadItemView.__super__.constructor.call(this,options,data)
fileData=this.getData()
this.thumbnail=new KDCustomHTMLView({tagName:"image",attributes:{src:fileData.thumbnails["64x64"]||fileData.icon}})
this.fileName=new KDCustomHTMLView({cssClass:"file-name",partial:fileData.name})
this.fileSize=new KDCustomHTMLView({cssClass:"file-size",partial:KD.utils.formatBytesToHumanReadable(fileData.bytes)})
this.loader=new KDLoaderView({size:{width:24}})
this.success=new KDCustomHTMLView({cssClass:"done"})
this.success.hide()
this.on("FileNeedsToBeDownloaded",function(path){var _this=this
this.loader.show()
return KD.getSingleton("vmController").run({withArgs:"cd "+path+" ; wget "+fileData.link,vmName:this.getOptions().nodeView.getData().vmName},function(err){if(err)return warn(err)
_this.loader.hide()
_this.success.show()
return _this.emit("FileDownloadDone")})})}__extends(DropboxDownloadItemView,_super)
DropboxDownloadItemView.prototype.pistachio=function(){return'{{> this.thumbnail}}\n<div class="details">\n  {{> this.fileName}}\n  {{> this.fileSize}}\n</div>\n<div class="indicators">\n  {{> this.loader}}\n  {{> this.success}}\n</div>'}
return DropboxDownloadItemView}(JView)

var CommonVMUsageBar,VMDiskUsageBar,VMRamUsageBar,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommonVMUsageBar=function(_super){function CommonVMUsageBar(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("vm-usage-bar",options.cssClass)
CommonVMUsageBar.__super__.constructor.call(this,options,data)}__extends(CommonVMUsageBar,_super)
CommonVMUsageBar.prototype.decorateUsage=function(usage){var item,key,label,ratio,title
label=this.getOptions().label
ratio=(100*usage.current/usage.max).toFixed(2)
this.updateBar(ratio,"%",label)
if(0===usage.max)title="Failed to fetch "+label+" info"
else for(key in usage){item=usage[key]
usage[key]=KD.utils.formatBytesToHumanReadable(item)}return this.setTooltip({title:title||""+usage.current+" of "+usage.max,placement:"bottom",delayIn:300,offset:{top:2,left:-8}})}
CommonVMUsageBar.prototype.fetchUsage=function(){}
CommonVMUsageBar.prototype.viewAppended=function(){CommonVMUsageBar.__super__.viewAppended.apply(this,arguments)
return this.fetchUsage(this.bound("decorateUsage"))}
return CommonVMUsageBar}(KDProgressBarView)
VMRamUsageBar=function(_super){function VMRamUsageBar(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("ram",options.cssClass)
options.label="RAM"
VMRamUsageBar.__super__.constructor.call(this,options,data)}__extends(VMRamUsageBar,_super)
VMRamUsageBar.prototype.fetchUsage=function(callback){return KD.getSingleton("vmController").fetchRamUsage(this.getData(),callback)}
return VMRamUsageBar}(CommonVMUsageBar)
VMDiskUsageBar=function(_super){function VMDiskUsageBar(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("disk",options.cssClass)
options.label="DISK"
VMDiskUsageBar.__super__.constructor.call(this,options,data)}__extends(VMDiskUsageBar,_super)
VMDiskUsageBar.prototype.fetchUsage=function(callback){return KD.getSingleton("vmController").fetchDiskUsage(this.getData(),callback)}
return VMDiskUsageBar}(CommonVMUsageBar)

var IntroductionTooltip,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
IntroductionTooltip=function(_super){function IntroductionTooltip(options,data){var buttonTitle,parentView,tooltipView,_ref,_this=this
null==options&&(options={})
IntroductionTooltip.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),tooltipView=_ref.tooltipView,parentView=_ref.parentView
data=this.getData()
tooltipView.addSubView(this.closeButton=new KDCustomHTMLView({tagName:"span",cssClass:"close-icon",click:function(){return _this.close(!1,!1)}}))
if("stepByStep"===data.visibility){buttonTitle=data.nextItem?"Next":"Finish"
tooltipView.addSubView(this.navButton=new KDButtonView({title:buttonTitle,cssClass:"editor-button",callback:function(){var delayForNext
_this.close(!0,!0)
delayForNext=_this.getData().delayForNext
return delayForNext>0?_this.utils.wait(delayForNext,function(){return _this.emit("IntroductionTooltipNavigated",data)}):_this.emit("IntroductionTooltipNavigated",data)}}))}parentView.setTooltip({view:tooltipView,cssClass:"introduction-tooltip",sticky:!0,placement:data.placement})
this.utils.defer(function(){return parentView.tooltip.show()})}__extends(IntroductionTooltip,_super)
IntroductionTooltip.prototype.close=function(hasNext,processCallback){var callback,data
null==processCallback&&(processCallback=!0)
if(processCallback){data=this.getData()
callback=Encoder.htmlDecode(data.callback)
data.callback&&eval(callback)}this.emit("IntroductionTooltipClosed",hasNext)
return this.destroy()}
return IntroductionTooltip}(KDObject)

var IntroductionTooltipController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
IntroductionTooltipController=function(_super){function IntroductionTooltipController(options,data){var _this=this
null==options&&(options={})
IntroductionTooltipController.__super__.constructor.call(this,options,data)
this.currentTimestamp=Date.now()
this.shouldAddOverlay=!1
this.visibleTooltips=[]
this.displayedTooltips=[]
this.stepByStepGroups={}
KD.getSingleton("mainController").on("AppIsReady",function(){return _this.init()})
this.on("ShowIntroductionTooltip",function(view){return _this.createInstance(view)})}__extends(IntroductionTooltipController,_super)
IntroductionTooltipController.prototype.init=function(){var _this=this
return KD.whoami()instanceof KD.remote.api.JAccount?KD.remote.api.JIntroSnippet.fetchAll(function(err,snippets){var appStorages
if(err)return log(err)
appStorages=KD.getSingleton("appStorageController")
_this.appStorage=appStorages.storage("IntroductionTooltipStatus","1.0")
return _this.appStorage.fetchStorage(function(){var currentSnippets,i,item,snippet,_i,_len,_results
_this.introSnippets=snippets
_results=[]
for(_i=0,_len=snippets.length;_len>_i;_i++){snippet=snippets[_i]
"yes"===snippet.overlay&&(_this.shouldAddOverlay=!0)
currentSnippets=snippet.snippets
if("stepByStep"===snippet.visibility){_this.stepByStepGroups[snippet.title]=snippet
_this.stepByStepGroups[snippet.title].currentIndex=0}_results.push(function(){var _j,_len1,_results1
_results1=[]
for(i=_j=0,_len1=currentSnippets.length;_len1>_j;i=++_j){item=currentSnippets[i]
item.expiryDate=snippet.expiryDate
item.visibility=snippet.visibility
item.groupName=snippet.title
item.overlay=this.shouldAddOverlay
if("stepByStep"===snippet.visibility){item.index=i
item.nextItem=currentSnippets[i+1]
item.prevItem=currentSnippets[i-1]}_results1.push(this.createInstance(null,item))}return _results1}.call(_this))}return _results})}):void 0}
IntroductionTooltipController.prototype.createInstance=function(parentView,data){var assets,tooltip,tooltipView,_this=this
assets=this.getAssets(parentView,data)
data=assets.data
if(assets&&!this.isExpired(data.expiryDate)&&!("stepByStep"===data.visibility&&data.index>this.stepByStepGroups[data.groupName].currentIndex||this.displayedTooltips.indexOf(data.introId)>-1)){this.displayedTooltips.push(data.introId)
parentView=assets.parentView,tooltipView=assets.tooltipView
tooltip=new IntroductionTooltip({parentView:parentView,tooltipView:tooltipView},data);-1===this.visibleTooltips.indexOf(parentView.tooltip)&&this.visibleTooltips.push(parentView.tooltip)
tooltip.on("IntroductionTooltipClosed",function(hasNext){_this.close(parentView.getOptions().introId)
parentView.tooltip.destroy()
_this.visibleTooltips.splice(_this.visibleTooltips.indexOf(tooltip),1)
return 0!==_this.visibleTooltips.length||hasNext?void 0:_this.overlay.remove()})
tooltip.on("IntroductionTooltipNavigated",function(tooltipData){var nextItem
nextItem=tooltipData.nextItem
if(!nextItem)return _this.overlay.remove();++_this.stepByStepGroups[tooltipData.groupName].currentIndex
return _this.createInstance(null,nextItem)})
return data.overlay?this.addOverlay():this.addLayers()}}
IntroductionTooltipController.prototype.isExpired=function(expiryDate){return new Date(expiryDate).getTime()<this.currentTimestamp}
IntroductionTooltipController.prototype.getAssets=function(parentView,data){var err,introData,introId,tooltipView
if(!this.introSnippets)return!1
introData=data||this.getIntroData(parentView)
if(!data&&introData){this.setData(introData)
data=introData}if(!data)return!1
introId=data.introId
this.storage=this.appStorage
if(this.shouldNotDisplay(introId))return!1
parentView=parentView||this.getParentView(data)
if(!parentView)return!1
tooltipView=null
try{tooltipView=eval(Encoder.htmlDecode(data.snippet.split("@").join("this.")))}catch(_error){err=_error
log(err.message)}return tooltipView instanceof KDView?{parentView:parentView,tooltipView:tooltipView,data:data}:!1}
IntroductionTooltipController.prototype.shouldNotDisplay=function(introId){return this.storage.getValue(introId)===!0}
IntroductionTooltipController.prototype.getIntroData=function(parentView){var introId,introSnippet,introSnippets,ourSnippet,snippet,_i,_j,_len,_len1,_ref
introId=parentView.getOptions().introId
introSnippets=this.introSnippets
ourSnippet=null
for(_i=0,_len=introSnippets.length;_len>_i;_i++){introSnippet=introSnippets[_i]
_ref=introSnippet.snippets
for(_j=0,_len1=_ref.length;_len1>_j;_j++){snippet=_ref[_j]
introId===snippet.introId&&(ourSnippet=snippet)}}return ourSnippet}
IntroductionTooltipController.prototype.getParentView=function(data){return KD.introInstances[data.introId]||null}
IntroductionTooltipController.prototype.close=function(tooltipIntroId){return this.storage.setValue(tooltipIntroId,!0)}
IntroductionTooltipController.prototype.addOverlay=function(){var _this=this
if(!this.overlay){this.overlay=$("<div/>",{"class":"kdoverlay"})
this.overlay.hide()
this.overlay.appendTo("body")
this.overlay.fadeIn(200)
return this.overlay.bind("click",function(){var tooltipInstance,_i,_len,_ref
_ref=_this.visibleTooltips
for(_i=0,_len=_ref.length;_len>_i;_i++){tooltipInstance=_ref[_i]
tooltipInstance.destroy()}_this.overlay.remove()
return _this.visibleTooltips.length=0})}}
IntroductionTooltipController.prototype.addLayers=function(){var tooltip,windowController,_i,_len,_ref,_results,_this=this
windowController=KD.getSingleton("windowController")
_ref=this.visibleTooltips
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){tooltip=_ref[_i]
windowController.addLayer(tooltip)
_results.push(tooltip.on("ReceivedClickElsewhere",function(){var _j,_len1,_ref1
_ref1=_this.visibleTooltips
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){tooltip=_ref1[_j]
tooltip&&tooltip.destroy()}return _this.visibleTooltips.length=0}))}return _results}
return IntroductionTooltipController}(KDController)

var ModalViewWithTerminal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ModalViewWithTerminal=function(_super){function ModalViewWithTerminal(options,data){var terminalWrapper,_base,_base1,_ref,_this=this
this.options=null!=options?options:{}
ModalViewWithTerminal.__super__.constructor.call(this,options,data)
this.terminal=options.terminal
this.terminal||(this.terminal={});(_base=this.terminal).height||(_base.height=150);(_base1=this.terminal).screen||(_base1.screen=!1)
this.on("terminal.connected",function(remote){_this.on("terminal.input",function(command){remote.input(command)
return _this.webterm.$().click()})
return _this.terminal.command&&!_this.hidden?_this.run(_this.terminal.command):void 0})
terminalWrapper=new KDView({cssClass:"modal-terminal-wrapper",noScreen:!this.terminal.screen,vmName:this.terminal.vmName})
this.webterm=new WebTermView({delegate:terminalWrapper,cssClass:"webterm",advancedSettings:!1})
this.hidden=null!=(_ref=this.terminal.hidden)?_ref:!1
terminalWrapper.$().css("height",this.hidden?0:this.terminal.height)
this.webterm.on("WebTermEvent",function(data){return _this.emit("terminal.event",data)})
this.webterm.on("WebTermConnected",function(remote){return _this.emit("terminal.connected",remote)})
this.webterm.on("WebTerm.terminated",function(){return _this.emit("terminal.terminated")})
terminalWrapper.addSubView(this.webterm)
this.addSubView(terminalWrapper)}__extends(ModalViewWithTerminal,_super)
ModalViewWithTerminal.prototype.run=function(command){var _this=this
return this.hidden?this.showTerminal(function(){return _this.input(command)}):this.input(command)}
ModalViewWithTerminal.prototype.input=function(command){return this.emit("terminal.input",command+"\n")}
ModalViewWithTerminal.prototype.hideTerminal=function(){var _this=this
this.hidden=!0
return this.webterm.getDelegate().$().animate({height:0},100,function(){return _this.setPositions()})}
ModalViewWithTerminal.prototype.showTerminal=function(callback){var _this=this
this.hidden=!1
return this.webterm.getDelegate().$().animate({height:this.terminal.height},100,function(){_this.setPositions()
_this.terminal.command&&_this.run(_this.terminal.command)
_this.webterm.$().click()
return"function"==typeof callback?callback():void 0})}
ModalViewWithTerminal.prototype.toggleTerminal=function(callback){return this[this.hidden?"showTerminal":"hideTerminal"](callback)}
return ModalViewWithTerminal}(KDModalView)

var CloneRepoModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CloneRepoModal=function(_super){function CloneRepoModal(options,data){var _this=this
null==options&&(options={})
options.title="Clone Remote Repository"
options.cssClass="modal-with-text clone-repo-modal"
options.content="<p>Enter the URL of remote Git repository to clone.</p>"
options.overlay=!0
options.width=500
options.terminal={hidden:!0,vmName:options.vmName,height:300}
options.buttons={Clone:{title:"Clone",cssClass:"modal-clean-green",loader:{color:"#FFFFFF",diameter:14},callback:function(){return _this.repoPath.validate()?_this.cloneRepo():void 0}},Cancel:{title:"Cancel",cssClass:"modal-cancel",callback:function(){return _this.destroy()}}}
CloneRepoModal.__super__.constructor.call(this,options,data)
this.addSubView(this.repoPath=new KDHitEnterInputView({type:"text",placeholder:"Type a git repository URL...",validationNotifications:!0,validate:{rules:{required:!0},messages:{required:"Please enter a repo URL."}},callback:this.bound("cloneRepo")}))}__extends(CloneRepoModal,_super)
CloneRepoModal.prototype.cloneRepo=function(){var command
if(!this.cloning){this.buttons.Clone.showLoader()
command="cd "+FSHelper.plainPath(this.getOptions().path)+" ; git clone "+this.repoPath.getValue()+"; echo $?|kdevent;"
this.cloning=!0
this.setClass("running")
this.run(command)
return this.once("terminal.event",function(data){if("0"===data){this.destroy()
return this.emit("RepoClonedSuccessfully")}})}}
return CloneRepoModal}(ModalViewWithTerminal)

var KodingAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KodingAppController=function(_super){function KodingAppController(options,data){var view,_this=this
null==options&&(options={})
options.view=view=new KDView
KodingAppController.__super__.constructor.call(this,options,data)
view.on("ready",function(){return _this.emit("ready")})}__extends(KodingAppController,_super)
KodingAppController.prototype.handleQuery=function(query){var _this=this
return this.ready(function(){return _this.getView().emit("QueryPassedFromRouter",query)})}
KodingAppController.prototype.openFile=function(file){var _this=this
return this.ready(function(){return _this.getView().emit("FileNeedsToBeOpened",file)})}
return KodingAppController}(KDViewController)

var SidebarController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SidebarController=function(_super){function SidebarController(){var mainController
SidebarController.__super__.constructor.apply(this,arguments)
mainController=KD.getSingleton("mainController")
mainController.on("ManageRemotes",function(){return new ManageRemotesModal})
mainController.on("ManageDatabases",function(){return new ManageDatabasesModal})
mainController.on("AccountChanged",this.bound("accountChanged"))
mainController.ready(this.bound("accountChanged"))}__extends(SidebarController,_super)
SidebarController.prototype.accountChanged=function(account){var avatar,avatarAreaIconMenu,finderController,finderHeader,footerMenuController,navController,profile,resourcesController,sidebar
account||(account=KD.whoami())
profile=account.profile
sidebar=this.getView()
avatar=sidebar.avatar,finderHeader=sidebar.finderHeader,navController=sidebar.navController,avatarAreaIconMenu=sidebar.avatarAreaIconMenu,finderController=sidebar.finderController,footerMenuController=sidebar.footerMenuController,resourcesController=sidebar.resourcesController
avatar.setData(account)
finderHeader.setData(account)
avatar.render()
finderHeader.render()
navController.reset()
footerMenuController.reset()
this.resetAdminNavItems()
avatarAreaIconMenu.accountChanged(account)
return KD.isLoggedIn()?finderController.reset():void 0}
SidebarController.prototype.resetAdminNavItems=function(){var _base,_this=this
return"function"==typeof(_base=KD.whoami()).fetchRole?_base.fetchRole(function(err,role){return"super-admin"===role?_this.getView().navController.addItem({title:"Admin panel",type:"admin",loggedIn:!0,callback:function(){return new AdminModal}}):void 0}):void 0}
return SidebarController}(KDViewController)

var Sidebar,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Sidebar=function(_super){function Sidebar(options,data){var account,navAdditions,navItem,profile,_i,_len,_onDrag,_this=this
null==options&&(options={})
options.bind="dragleave"
Sidebar.__super__.constructor.call(this,options,data)
account=KD.whoami()
profile=account.profile
this._onDevelop=!1
this._finderExpanded=!1
this._popupIsActive=!1
this.avatar=new AvatarView({tagName:"div",cssClass:"avatar-image-wrapper",attributes:{title:"View your public profile"},size:{width:160,height:76}},account)
this.avatarAreaIconMenu=new AvatarAreaIconMenu({delegate:this})
this.navController=new MainNavController({view:new KDListView({type:"navigation",itemClass:NavigationLink,testPath:"navigation-list"}),wrapper:!1,scrollView:!1},{title:"navigation",items:[]})
navAdditions=[{type:"separator",order:65},{title:"Up to 16GB free!",order:66,type:"account promote",promote:!0,role:"member"},{title:"Docs / Jobs",order:67,type:"account docs",docs:!0},{type:"separator",order:99},{title:"Logout",order:100,path:"/Logout",type:"account",loggedIn:!0},{title:"Login",order:101,path:"/Login",type:"account",loggedIn:!1},{title:"Register",order:102,path:"/Register",type:"account",loggedIn:!1}]
for(_i=0,_len=navAdditions.length;_len>_i;_i++){navItem=navAdditions[_i]
KD.registerNavItem(navItem)}this.nav=this.navController.getView()
this.footerMenuController=new NavigationController({view:new NavigationList({type:"footer-menu",itemClass:FooterMenuItem}),wrapper:!1,scrollView:!1},footerMenuItems)
this.footerMenu=this.footerMenuController.getView()
this.finderHeader=new KDCustomHTMLView({tagName:"h2",pistachio:"{{#(profile.nickname)}}."+KD.config.userSitesDomain},account)
this.finderController=new NFinderController({useStorage:!0,addOrphansToRoot:!1,delegate:this})
this.dndUploadHolder=new KDView({domId:"finder-dnduploader",cssClass:"hidden"})
this.dndUploadHolder.addSubView(this.dnduploader=new DNDUploader({hoverDetect:!1}))
_onDrag=function(){if(!_this.finderController.treeController.internalDragging){_this.dndUploadHolder.show()
return _this.dnduploader.unsetClass("hover")}}
this.dnduploader.on("dragleave",function(){return _this.dndUploadHolder.hide()})
this.dnduploader.on("drop",function(){return _this.dndUploadHolder.hide()})
this.dnduploader.on("cancel",function(){_this.dnduploader.setPath()
return _this.dndUploadHolder.hide()})
this.finderController.treeController.on("dragEnter",_onDrag)
this.finderController.treeController.on("dragOver",_onDrag)
this.finder=this.finderController.getView()
KD.registerSingleton("finderController",this.finderController)
this.finderController.on("ShowEnvironments",function(){return _this.finderBottomControlPin.click()})
this.listenWindowResize()}var bottomControlsItems,footerMenuItems,_mouseenterTimeout,_mouseleaveTimeout
__extends(Sidebar,_super)
Sidebar.prototype.setListeners=function(){var $fp,cp,fpLastWidth,mainController,mainView,mainViewController,_this=this
mainController=KD.getSingleton("mainController")
mainViewController=KD.getSingleton("mainViewController")
mainView=KD.getSingleton("mainView")
this.contentPanel=mainView.contentPanel,this.sidebarPanel=mainView.sidebarPanel
$fp=this.$("#finder-panel")
cp=this.contentPanel
this.wc=KD.getSingleton("windowController")
fpLastWidth=null
mainController.on("AvatarPopupIsActive",function(){return _this._popupIsActive=!0})
mainController.on("AvatarPopupIsInactive",function(){return _this._popupIsActive=!1})
this.$("#main-nav").on("mouseenter",this.bound("animateLeftNavIn"))
this.$("#main-nav").on("mouseleave",this.bound("animateLeftNavOut"))
mainViewController.on("UILayoutNeedsToChange",this.bound("changeLayout"))
return this.bindTransitionEnd()}
Sidebar.prototype.changeLayout=function(options){var hideTabs,type,width,windowController,_this=this
type=options.type,hideTabs=options.hideTabs
windowController=KD.getSingleton("windowController")
this.$finderPanel||(this.$finderPanel=this.$("#finder-panel"))
this.$avatarPlaceholder||(this.$avatarPlaceholder=this.$(".avatar-placeholder"))
this._onDevelop="develop"===type
width=function(){switch(type){case"full":case"social":this.$finderPanel.removeClass("expanded")
return this.$avatarPlaceholder.removeClass("collapsed")
case"develop":this.$finderPanel.addClass("expanded")
return this.$avatarPlaceholder.addClass("collapsed")}}.call(this)
return this.utils.wait(300,function(){return _this.emit("NavigationPanelWillCollapse")})}
Sidebar.prototype.dragLeave=function(){Sidebar.__super__.dragLeave.apply(this,arguments)
return this.dndUploadHolder.hide()}
Sidebar.prototype.viewAppended=function(){Sidebar.__super__.viewAppended.apply(this,arguments)
return this.setListeners()}
Sidebar.prototype.pistachio=function(){return"<div id=\"main-nav\">\n  <div class=\"avatar-placeholder\">\n    <div id=\"avatar-area\">\n      {{> this.avatar}}\n    </div>\n  </div>\n  {{> this.avatarAreaIconMenu}}\n  {{> this.nav}}\n  {{> this.footerMenu}}\n</div>\n<div id='finder-panel'>\n  <div id='finder-header-holder'>\n    {{> this.finderHeader}}\n  </div>\n\n  {{> this.dndUploadHolder}}\n\n  <div id='finder-holder'>\n    {{> this.finder}}\n  </div>\n</div>"}
_mouseenterTimeout=null
_mouseleaveTimeout=null
Sidebar.prototype.animateLeftNavIn=function(){var _this=this
if(!$("body").hasClass("dragInAction")){_mouseleaveTimeout&&this.utils.killWait(_mouseleaveTimeout)
return _mouseenterTimeout=this.utils.wait(200,function(){_this._mouseentered=!0
return _this._onDevelop?_this.expandNavigationPanel():void 0})}}
Sidebar.prototype.animateLeftNavOut=function(){var _this=this
if(!this._popupIsActive&&!$("body").hasClass("dragInAction")){_mouseenterTimeout&&this.utils.killWait(_mouseenterTimeout)
return _mouseleaveTimeout=this.utils.wait(200,function(){return _this._mouseentered&&_this._onDevelop?_this.collapseNavigationPanel():void 0})}}
Sidebar.prototype.expandNavigationPanel=function(){this.$(".avatar-placeholder").removeClass("collapsed")
this.$("#finder-panel").removeClass("expanded")
parseInt(this.contentPanel.$().css("left"),10)<174&&this.contentPanel.setClass("mouse-on-nav")
return this.utils.wait(300,function(){return"function"==typeof callback?callback():void 0})}
Sidebar.prototype.collapseNavigationPanel=function(callback){var _this=this
this.$(".avatar-placeholder").addClass("collapsed")
this.$("#finder-panel").addClass("expanded")
this.contentPanel.unsetClass("mouse-on-nav")
return this.utils.wait(300,function(){"function"==typeof callback&&callback()
return _this.emit("NavigationPanelWillCollapse")})}
Sidebar.prototype.showBottomControls=function(){var $fbc
$fbc=this.$("#finder-bottom-controls")
$fbc.addClass("in")
return this._windowDidResize()}
Sidebar.prototype.hideBottomControls=function(){var $fbc
$fbc=this.$("#finder-bottom-controls")
$fbc.css({top:"100%"})
$fbc.removeClass("in")
return this._windowDidResize()}
Sidebar.prototype._resizeResourcesList=function(){var $fbc,$resList,fbch,h
$fbc=this.$("#finder-bottom-controls")
$resList=$fbc.find(".resources-list")
fbch=$fbc.height()
h=this.getHeight()
$resList.css({maxHeight:fbch>h?h/2:"none"})
if($fbc.hasClass("in")){$fbc.css({top:""+(100-100*(((fbch=$fbc.height())-27)/h))+"%"})
return fbch}return 27}
Sidebar.prototype._windowDidResize=function(){var $fbc,h
$fbc=this.$("#finder-bottom-controls")
h=this._resizeResourcesList()
return this.$("#finder-holder").height(this.getHeight()-h-26)}
bottomControlsItems={id:"finder-bottom-controls",items:[{title:"your servers",icon:"resources",action:"showEnvironments"}]}
footerMenuItems={id:"footer-menu",title:"footer-menu",items:[{title:"Help",callback:function(){return KD.getSingleton("mainController").emit("ShowInstructionsBook")}},{title:"About",callback:function(){return this.showAboutDisplay()}},{title:"Chat",callback:function(){return KD.getSingleton("mainController").emit("ToggleChatPanel")}}]}
return Sidebar}(JView)

var SidebarResizeHandle,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SidebarResizeHandle=function(_super){function SidebarResizeHandle(options,data){options.bind="mousemove"
options.partial="<span></span>"
SidebarResizeHandle.__super__.constructor.call(this,options,data)
this.setDraggable({axis:"x"})}__extends(SidebarResizeHandle,_super)
return SidebarResizeHandle}(KDView)

var StatusLED,VirtualizationControls,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VirtualizationControls=function(_super){function VirtualizationControls(){var options,_this=this
options={cssClass:"virt-controls"}
VirtualizationControls.__super__.constructor.call(this,options)
this.vm=KD.getSingleton("vmController")
this.vm.on("StateChanged",this.bound("checkVMState"))
this.statusLED=new StatusLED({labels:{green:"VM is running",red:"VM is turned off",yellow:"VM is initializing",off:"..."}})
this.statusLED.on("stateChanged",function(state){state="off"===state||"red"===state?!1:!0
return _this.vmToggle.setDefaultValue(state)})
this.vmToggle=new KDOnOffSwitch({cssClass:"tiny vm-toggle",callback:function(state){return state?_this.vm.start():_this.vm.stop()}})
this.vmResetButton=new KDButtonView({cssClass:"vmreinitialize-button",iconOnly:!0,iconClass:"cog",tooltip:{title:"Re-initialize your VM"},callback:function(){return _this.vm.reinitialize()}})}__extends(VirtualizationControls,_super)
VirtualizationControls.prototype.checkVMState=function(err,vm,info){if(err||!info){this.statusLED.setOff()
return warn(err)}switch(info.state){case"RUNNING":return this.statusLED.setOnline()
case"STOPPED":case"MAINTENANCE":return this.statusLED.setOffline()}}
VirtualizationControls.prototype.viewAppended=function(){VirtualizationControls.__super__.viewAppended.apply(this,arguments)
return this.vm.info(this.bound("checkVMState"))}
VirtualizationControls.prototype.pistachio=function(){return"{{> this.statusLED}}{{> this.vmToggle}}{{> this.vmResetButton}}"}
return VirtualizationControls}(JView)
StatusLED=function(_super){function StatusLED(options){null==options&&(options={})
options.cssClass=this.utils.curry("led-wrapper",options.cssClass)
StatusLED.__super__.constructor.call(this,options)
this.label=new KDCustomHTMLView({cssClass:"label"})
this.setOnline()}var states
__extends(StatusLED,_super)
states=["red","yellow","green","off"]
StatusLED.prototype.setCurrentState=function(state){var labels,_i,_len,_state
labels=this.getOptions().labels
this.currentState=state
for(_i=0,_len=states.length;_len>_i;_i++){_state=states[_i]
state!==_state?this.unsetClass(_state):this.setClass(_state)}labels&&this.label.updatePartial(labels[state])
return this.emit("stateChanged",state)}
StatusLED.prototype.setOff=function(){return this.setCurrentState("off")}
StatusLED.prototype.setOnline=function(){return this.setCurrentState("green")}
StatusLED.prototype.setOffline=function(){return this.setCurrentState("red")}
StatusLED.prototype.setWaiting=function(){return this.setCurrentState("yellow")}
StatusLED.prototype.show=function(){return this.unsetClass("fadeout")}
StatusLED.prototype.hide=function(){return this.setClass("fadeout")}
StatusLED.prototype.pistachio=function(){return"<div class='led'></div>{{> this.label}}"}
return StatusLED}(JView)

var FooterMenuItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FooterMenuItem=function(_super){function FooterMenuItem(options,data){null==options&&(options={})
options.tooltip=function(){switch(data.title.toLowerCase()){case"chat":return{title:"Chat",direction:"center",placement:"top",delay:500,offset:{top:5,left:0}}
case"about":return{title:"About Koding",placement:"top",direction:"center",delay:500,offset:{top:3,left:-3}}
case"help":return{title:"Instructions Book",placement:"top",direction:"right",delay:500,offset:{top:3,left:13}}}}()
FooterMenuItem.__super__.constructor.call(this,options,data)
this.icon=new KDCustomHTMLView({tagName:"span"})
this.setClass(""+this.utils.slugify(this.getData().title.toLowerCase()))}__extends(FooterMenuItem,_super)
FooterMenuItem.prototype.mouseDown=function(){var cb
cb=this.getData().callback
return cb?cb.call(this):void 0}
FooterMenuItem.prototype.viewAppended=function(){FooterMenuItem.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
return this.template.update()}
FooterMenuItem.prototype.pistachio=function(){return"{{> this.icon}}"}
FooterMenuItem.prototype.showAboutDisplay=function(){return KD.getSingleton("router").handleRoute("/About")}
return FooterMenuItem}(KDListItemView)

var IntroductionItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
IntroductionItem=function(_super){function IntroductionItem(options,data){null==options&&(options={})
options.cssClass=options.cssClass||"admin-introduction-item"
IntroductionItem.__super__.constructor.call(this,options,data)
this.createElements()}__extends(IntroductionItem,_super)
IntroductionItem.prototype.createElements=function(){var data,_this=this
data=this.getData()
this.title=new KDView({cssClass:"cell name",partial:data.title,click:function(){return _this.setupChilds()}})
this.title.addSubView(this.arrow=new KDCustomHTMLView({tagName:"span",cssClass:"arrow"}))
this.addLink=new KDCustomHTMLView({tagName:"span",partial:"<span class='icon add'></span>",click:function(){return _this.add()},tooltip:{title:"Add Into"}})
this.updateLink=new KDCustomHTMLView({tagName:"span",partial:"<span class='icon update'></span>",click:function(){return _this.update()},tooltip:{title:"Update"}})
return this.deleteLink=new KDCustomHTMLView({tagName:"span",partial:"<span class='icon delete'></span>",click:function(){return _this.remove()},tooltip:{title:"Delete"}})}
IntroductionItem.prototype.add=function(){return this.getDelegate().showForm("Item",this.getData())}
IntroductionItem.prototype.update=function(){return this.getDelegate().showForm("Group",this.getData(),"Update")}
IntroductionItem.prototype.remove=function(){var _this=this
this.getData()["delete"](function(){return _this.destroy()})
return this.getDelegate().emit("IntroductionItemDeleted",this.getData())}
IntroductionItem.prototype.setupChilds=function(){var snippet,_i,_len,_ref,_results
if(this.childContainer){if(this.isChildContainerVisible){this.childContainer.hide()
this.arrow.unsetClass("down")
return this.isChildContainerVisible=!1}this.childContainer.show()
this.arrow.setClass("down")
return this.isChildContainerVisible=!0}this.addSubView(this.childContainer=new KDView)
this.isChildContainerVisible=!0
this.arrow.setClass("down")
_ref=this.getData().snippets
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){snippet=_ref[_i]
_results.push(this.childContainer.addSubView(new IntroductionChildItem({delegate:this},snippet)))}return _results}
IntroductionItem.prototype.isExpired=function(expiryDate){return new Date(expiryDate).getTime()<this.getDelegate().currentTimestamp}
IntroductionItem.prototype.pistachio=function(){var data,hasOverlay,status,visibility
data=this.getData()
hasOverlay="yes"===data.overlay?"yep":"nope"
status=this.isExpired(data.expiryDate)===!0?"nope":"yep"
visibility="allTogether"===data.visibility?"allTogether":"stepByStep"
return'{{> this.title}}\n<div class="cell mini">'+data.snippets.length+'</div>\n<div class="cell icon '+status+'"></div>\n<div class="cell icon '+hasOverlay+'"></div>\n<div class="cell icon '+visibility+'"></div>\n<div class="introduction-actions cell">\n  {{> this.addLink}}{{> this.updateLink}}{{> this.deleteLink}}\n</div>'}
return IntroductionItem}(JView)

var IntroductionChildItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
IntroductionChildItem=function(_super){function IntroductionChildItem(options,data){null==options&&(options={})
options.cssClass="admin-introduction-child-item"
IntroductionChildItem.__super__.constructor.call(this,options,data)}__extends(IntroductionChildItem,_super)
IntroductionChildItem.prototype.remove=function(){var _this=this
return this.getDelegate().getData().deleteChild(this.getData().introId,function(){return _this.destroy()})}
IntroductionChildItem.prototype.update=function(){var data,introductionAdmin,introductionItem
introductionItem=this.getDelegate()
introductionAdmin=introductionItem.getDelegate()
data=this.getData()
data.introductionItem=introductionItem
return introductionAdmin.showForm("Item",data,"Update")}
IntroductionChildItem.prototype.pistachio=function(){var data
data=this.getData()
return'<div class="introItemText"><b>Intro Id</b>: '+data.introId+" <b>for</b>: "+data.introTitle+'</div>\n<div class="introduction-actions cell">\n  {{> this.updateLink}}{{> this.deleteLink}}\n</div>'}
return IntroductionChildItem}(IntroductionItem)

var IntroductionAdminForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
IntroductionAdminForm=function(_super){function IntroductionAdminForm(options,data){var actionType,groupFields,itemFields,partial,type,_ref,_this=this
null==options&&(options={})
null==data&&(data={})
this.parentData=data
this.timestamp=Date.now()
this.snippetType="Code"
groupFields={Title:{label:"Title",type:"text",placeholder:"Title of introduction group",defaultValue:data.title},ExpiryDate:{label:"Expiry Date",type:"text",placeholder:"Best before (YYYY-MM-DD)",defaultValue:data.expiryDate,nextElement:{info:{itemClass:KDView,partial:"Date format should be YYYY-MM-DD. e.g. 2013-05-03",cssClass:"help-text info"}}},Overlay:{label:"Overlay",type:"select",defaultValue:data.overlay,selectOptions:[{title:"Yes",value:"yes"},{title:"No",value:"no"}],nextElement:{warning:{itemClass:KDView,partial:"Please be careful when using no overlay option. It may cause UX problems.",cssClass:"help-text warning"}},change:function(){return _this.setVisibilityOfOverlayWarning("no"===_this.inputs.Overlay.getValue())}},Visibility:{label:"Visibility",type:"select",defaultValue:data.visibility,selectOptions:[{title:"Show all together",value:"allTogether"},{title:"Show step by step",value:"stepByStep"}]}}
itemFields={ItemInfo:{label:"",type:"hidden",nextElement:{GroupName:{itemClass:KDView,cssClass:"introduction-group-name",partial:'You\'re adding an item to: <span class="groupName">'+this.parentData.title+"</span>"}}},IntroTitle:{label:"Intro Title",type:"text",defaultValue:data.introTitle},IntroId:{label:"Intro Id",type:"text",placeholder:"Parent view's intro id",defaultValue:data.introId},Placement:{label:"Placement",type:"select",defaultValue:data.placement,selectOptions:[{title:"Top",value:"top"},{title:"Right",value:"right"},{title:"Bottom",value:"bottom"},{title:"Left",value:"left"}]},DelayForNext:{label:"Delay for next",type:"text",placeholder:"Parent view's intro id",tooltip:{title:"in ms (3000 for 3 sec.)",placement:"right"},defaultValue:data.delayForNext||0},Snippet:{label:"Intro Snippet",itemClass:KDView,cssClass:"introduction-ace-editor",domId:"introduction-ace"+this.timestamp,defaultValue:Encoder.htmlDecode(data.snippet),nextElement:{typeSwitch:{itemClass:KDView,partial:"Switch to Text Mode",cssClass:"introduction-snippet-switch snippet",click:function(){return _this.switchMode()}}}},Callback:{label:"Callback",itemClass:KDView,cssClass:"introduction-ace-editor",domId:"introduction-callback-ace"+this.timestamp,defaultValue:Encoder.htmlDecode(data.callback||"")}}
options.fields="Group"===options.type?groupFields:itemFields
options.buttons={Save:{title:"Save",style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){return _this.save()}},Cancel:{title:"Cancel",style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){_this.destroy()
_this.getDelegate().container.show()
return _this.getDelegate().buttonsContainer.show()}}}
IntroductionAdminForm.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),type=_ref.type,actionType=_ref.actionType
"Group"===type&&this.setVisibilityOfOverlayWarning("no"===this.parentData.overlay)
if("Item"===type){this.utils.defer(function(){_this.createAceEditor()
return _this.createCallbackAceEditor()})
if("Update"===actionType){partial='You\'re updating this item from: <span class="groupName">'+this.parentData.introductionItem.getData().title+"</span>"
this.inputs.GroupName.updatePartial(partial)}}}__extends(IntroductionAdminForm,_super)
IntroductionAdminForm.prototype.save=function(){var actionType,addingToAGroup,options
options=this.getOptions()
actionType=options.actionType,addingToAGroup=options.addingToAGroup
return"Group"===this.getOptions().type||addingToAGroup?"Insert"===actionType?this.insertParent():this.updateParent():"Insert"===actionType?this.insertChild():this.updateChild()}
IntroductionAdminForm.prototype.insertParent=function(){var data,_this=this
data=this.createPostData()
if(this.getOptions().addingToAGroup){this.parentData.snippets.push(data)
return KD.remote.api.JIntroSnippet.create(this.parentData,function(){_this.buttons.Save.hideLoader()
return _this.emit("IntroductionFormNeedsReload")})}this.destroy()
return this.getDelegate().showForm("Item",data,"Insert",!0)}
IntroductionAdminForm.prototype.insertChild=function(){var _this=this
return this.parentData.addChild(this.createPostData(),function(){_this.buttons.Save.hideLoader()
return _this.emit("IntroductionFormNeedsReload")})}
IntroductionAdminForm.prototype.updateParent=function(){var _this=this
return this.parentData.update(this.createPostData(),function(){return _this.emit("IntroductionFormNeedsReload")})}
IntroductionAdminForm.prototype.updateChild=function(){var data,_this=this
data=this.createPostData()
data.oldIntroId=this.parentData.introId
return this.parentData.introductionItem.getData().updateChild(data,function(){return _this.emit("IntroductionFormNeedsReload")})}
IntroductionAdminForm.prototype.createPostData=function(){var editorValue,groupData,inputs,itemData,snippet,snippets,_ref
inputs=this.inputs
snippets=(null!=(_ref=this.parentData.snippets)?_ref.length:void 0)?this.parentData.snippets:[]
if("Group"===this.getOptions().type){groupData={title:inputs.Title.getValue(),expiryDate:inputs.ExpiryDate.getValue(),visibility:inputs.Visibility.getValue(),overlay:inputs.Overlay.getValue(),snippets:snippets}
return groupData}editorValue=this.aceEditor.getValue()
"Text"===this.snippetType&&(snippet='new KDView({partial: "'+editorValue+'"});')
itemData={introId:inputs.IntroId.getValue(),introTitle:inputs.IntroTitle.getValue(),placement:inputs.Placement.getValue(),snippet:snippet||editorValue,delayForNext:inputs.DelayForNext.getValue(),callback:this.callbackEditor.getValue()}
return itemData}
IntroductionAdminForm.prototype.setVisibilityOfOverlayWarning=function(isShowing){var warning
warning=this.inputs.warning
return isShowing?null!=warning?warning.show():void 0:null!=warning?warning.hide():void 0}
IntroductionAdminForm.prototype.createAceEditor=function(){var _this=this
return require(["ace/ace"],function(ace){var text
_this.aceEditor=ace.edit(document.getElementById("introduction-ace"+_this.timestamp))
_this.setAceEditor(_this.aceEditor)
text='new KDView({\n  partial: ""\n});'
return _this.setEditorContent(_this.aceEditor,Encoder.htmlDecode(_this.parentData.snippet||text))})}
IntroductionAdminForm.prototype.createCallbackAceEditor=function(){var _this=this
return require(["ace/ace"],function(ace){_this.callbackEditor=ace.edit(document.getElementById("introduction-callback-ace"+_this.timestamp))
_this.setAceEditor(_this.callbackEditor)
return _this.setEditorContent(_this.callbackEditor,Encoder.htmlDecode(_this.parentData.callback||""))})}
IntroductionAdminForm.prototype.setAceEditor=function(aceInstance){aceInstance.setTheme("ace/theme/idle_fingers")
aceInstance.getSession().setMode("ace/mode/javascript")
aceInstance.getSession().setTabSize(2)
return aceInstance.commands.addCommand({name:"save",bindKey:{win:"Ctrl-S",mac:"Command-S"},exec:function(){}})}
IntroductionAdminForm.prototype.setEditorContent=function(editor,content){return editor.getSession().setValue(content)}
IntroductionAdminForm.prototype.switchMode=function(){var typeSwitch
typeSwitch=this.inputs.typeSwitch
if("Code"===this.snippetType){typeSwitch.updatePartial("Switch to Code Mode")
this.aceEditor.getSession().setMode("ace/mode/text")
this.snippetType="Text"
return this.aceEditor.getSession().setValue("")}typeSwitch.updatePartial("Switch to Text Mode")
this.aceEditor.getSession().setMode("ace/mode/javascript")
this.setSnippetEditorValue()
return this.snippetType="Code"}
return IntroductionAdminForm}(KDFormViewWithFields)

var IntroductionAdmin,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
IntroductionAdmin=function(_super){function IntroductionAdmin(options,data){var _this=this
null==options&&(options={})
IntroductionAdmin.__super__.constructor.call(this,options,data)
this.currentTimestamp=Date.now()
this.buttonsContainer=new KDView({cssClass:"introduction-admin-buttons"})
this.buttonsContainer.addSubView(this.addButton=new KDButtonView({cssClass:"editor-button",title:"Add New Introduction Group",callback:function(){return _this.showForm()}}))
this.container=new KDView({cssClass:"introduction-admin-content"})
this.container.addSubView(this.loader=new KDLoaderView({size:{width:36}}))
this.container.addSubView(this.notFoundText=new KDView({cssClass:"introduction-not-found",partial:"There is no introduction yet."}))
this.notFoundText.hide()
this.container.addSubView(this.introListContainer=new KDView)
this.fetchData()
this.on("IntroductionItemDeleted",function(snippet){_this.snippets.splice(_this.snippets.indexOf(snippet),1)
if(0===_this.snippets.length){_this.introListContainer.hide()
return _this.notFoundText.show()}})}__extends(IntroductionAdmin,_super)
IntroductionAdmin.prototype.reload=function(){var parentView
parentView=this.getOptions().parentView
parentView.addSubView(new IntroductionAdmin({parentView:parentView}))
return this.destroy()}
IntroductionAdmin.prototype.fetchData=function(){var _this=this
return KD.remote.api.JIntroSnippet.fetchAll(function(err,snippets){var snippet,_i,_len,_results
_this.loader.hide()
_this.snippets=snippets
if(0===snippets.length)return _this.notFoundText.show()
_this.introListContainer.addSubView(new KDView({cssClass:"admin-introduction-item admin-introduction-header",partial:'<div class="cell name">Title</div>\n<div class="cell mini">Count</div>\n<div class="cell mini">In Use</div>\n<div class="cell mini">Overlay</div>\n<div class="cell mini">Visibility</div>'}))
_results=[]
for(_i=0,_len=snippets.length;_len>_i;_i++){snippet=snippets[_i]
_results.push(_this.introListContainer.addSubView(new IntroductionItem({delegate:_this},snippet)))}return _results})}
IntroductionAdmin.prototype.showForm=function(type,data,actionType,addingToAGroup){var _this=this
null==type&&(type="Group")
null==data&&(data=this.getData())
null==actionType&&(actionType="Insert")
null==addingToAGroup&&(addingToAGroup=!1)
this.buttonsContainer.hide()
this.container.hide()
this.addSubView(this.form=new IntroductionAdminForm({type:type,actionType:actionType,addingToAGroup:addingToAGroup,delegate:this},data))
return this.form.on("IntroductionFormNeedsReload",function(){return _this.reload()})}
IntroductionAdmin.prototype.viewAppended=function(){IntroductionAdmin.__super__.viewAppended.apply(this,arguments)
return this.loader.show()}
IntroductionAdmin.prototype.pistachio=function(){return"{{> this.buttonsContainer}}\n{{> this.container}}"}
return IntroductionAdmin}(JView)

var AdminModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AdminModal=function(_super){function AdminModal(options,data){var buttons,inputs,preset,_ref,_this=this
null==options&&(options={})
options={title:"Admin panel",content:"<div class='modalformline'>With great power comes great responsibility. ~ Stan Lee</div>",overlay:!0,width:600,height:"auto",cssClass:"admin-kdmodal",tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{"User Details":{buttons:{Update:{title:"Update",style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){var account,accounts,buttons,flag,flags,inputs,_ref
_ref=_this.modalTabs.forms["User Details"],inputs=_ref.inputs,buttons=_ref.buttons
accounts=_this.userController.getSelectedItemData()
if(accounts.length>0){account=accounts[0]
flags=function(){var _i,_len,_ref1,_results
_ref1=inputs.Flags.getValue().split(",")
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){flag=_ref1[_i]
_results.push(flag.trim())}return _results}()
return account.updateFlags(flags,function(err){err&&error(err)
new KDNotificationView({title:"Done!"})
return buttons.Update.hideLoader()})}return new KDNotificationView({title:"Select a user first"})}}},fields:{Username:{label:"Dear User",type:"hidden",nextElement:{userWrapper:{itemClass:KDView,cssClass:"completed-items"}}},Flags:{label:"Flags",placeholder:"no flags assigned"},BlockUser:{label:"Block User",itemClass:KDButtonView,title:"Block",callback:function(){var accounts,activityController
accounts=_this.userController.getSelectedItemData()
if(accounts.length>0){activityController=KD.getSingleton("activityController")
return activityController.emit("ActivityItemBlockUserClicked",accounts[0].profile.nickname)}return new KDNotificationView({title:"Please select an account!"})}},Impersonate:{label:"Switch to User ",itemClass:KDButtonView,title:"Impersonate",callback:function(){var modal
return modal=new KDModalView({title:"Switch to this user?",content:"<div class='modalformline'>This action will reload Koding and log you in with this user.</div>",height:"auto",overlay:!0,buttons:{Impersonate:{style:"modal-clean-green",loader:{color:"#FFF",diameter:16},callback:function(){var accounts
accounts=_this.userController.getSelectedItemData()
return 0!==accounts.length?KD.impersonate(accounts[0].profile.nickname,function(){return modal.destroy()}):modal.destroy()}}}})}}}},"Broadcast Message":{buttons:{"Broadcast Message":{title:"Broadcast",style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){var buttons,inputs,_ref
_ref=_this.modalTabs.forms["Broadcast Message"],inputs=_ref.inputs,buttons=_ref.buttons
return KD.remote.api.JSystemStatus.create({scheduledAt:Date.now()+1e3*inputs.Duration.getValue(),title:inputs.Title.getValue(),content:inputs.Description.getValue(),type:inputs.Type.getValue()},function(){return buttons["Broadcast Message"].hideLoader()})}},"Cancel Restart":{title:"Cancel Restart",style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){var buttons,inputs,_ref
_ref=_this.modalTabs.forms["Broadcast Message"],inputs=_ref.inputs,buttons=_ref.buttons
return KD.remote.api.JSystemStatus.stopCurrentSystemStatus(function(){return buttons["Cancel Restart"].hideLoader()})}}},fields:{Presets:{label:"Use Preset",type:"select",cssClass:"preset-select",selectOptions:[{title:"No preset selected",value:"none"},{title:"Shutdown in...",value:"restart"},{title:"Please refresh...",value:"reload"}],defaultValue:"none",change:function(){var buttons,content,duration,inputs,msgMap,title,type,_ref,_ref1
msgMap={none:{title:"",content:"",duration:300,type:"restart"},restart:{title:"Shutdown in",content:"We are upgrading the platform. Please save your work.",duration:300,type:"restart"},reload:{title:"Koding is updated. Please refresh!",content:"Please refresh your browser to be able to use the newest features of Koding.",duration:10,type:"reload"}}
_ref=_this.modalTabs.forms["Broadcast Message"],inputs=_ref.inputs,buttons=_ref.buttons
_ref1=msgMap[inputs.Presets.getValue()],title=_ref1.title,content=_ref1.content,duration=_ref1.duration,type=_ref1.type
inputs.Title.setValue(title)
inputs.Description.setValue(content)
inputs.Duration.setValue(duration)
return inputs.Type.setValue(type)}},Title:{label:"Message Title",type:"text",placeholder:"Shutdown in",tooltip:{title:'When using type "Restart", end title with "in", since there will be a timer following the title.',placement:"right",direction:"center",offset:{top:2,left:0}}},Description:{label:"Message Details",type:"text",placeholder:"We are upgrading the platform. Please save your work."},Duration:{label:"Timer duration",type:"text",defaultValue:300,tooltip:{title:"in seconds",placement:"right",direction:"center",offset:{top:2,left:0}},placeholder:"Please enter a reasonable timeout."},Type:{label:"Type",type:"select",cssClass:"type-select",selectOptions:[{title:"Restart",value:"restart"},{title:"Info Text",value:"info"},{title:"Reload",value:"reload"}],defaultValue:"restart",change:function(){var buttons,inputs,type,_ref
_ref=_this.modalTabs.forms["Broadcast Message"],inputs=_ref.inputs,buttons=_ref.buttons
type=inputs.Type.getValue()
return inputs.presetExplanation.updatePartial(function(){switch(type){case"restart":return"This will show a timer."
default:return"No timer will be shown."}}())},nextElement:{presetExplanation:{cssClass:"type-explain",itemClass:KDView,partial:"This will show a timer."}}}}},Introduction:{fields:{}}}}}
AdminModal.__super__.constructor.call(this,options,data)
_ref=this.modalTabs.forms["Broadcast Message"],inputs=_ref.inputs,buttons=_ref.buttons
preset=inputs.Type.change()
this.hideConnectedFields()
this.initIntroductionTab()
this.createUserAutoComplete()}__extends(AdminModal,_super)
AdminModal.prototype.createUserAutoComplete=function(){var buttons,fields,inputs,userRequestLineEdit,_ref,_this=this
_ref=this.modalTabs.forms["User Details"],fields=_ref.fields,inputs=_ref.inputs,buttons=_ref.buttons
this.userController=new KDAutoCompleteController({form:this.modalTabs.forms["User Details"],name:"userController",itemClass:MemberAutoCompleteItemView,itemDataPath:"profile.nickname",outputWrapper:fields.userWrapper,selectedItemClass:MemberAutoCompletedItemView,listWrapperCssClass:"users",submitValuesAsText:!0,dataSource:function(args,callback){var blacklist,data,inputValue
inputValue=args.inputValue
blacklist=function(){var _i,_len,_ref1,_results
_ref1=this.userController.getSelectedItemData()
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){data=_ref1[_i]
_results.push(data.getId())}return _results}.call(_this)
return KD.remote.api.JAccount.byRelevance(inputValue,{blacklist:blacklist},function(err,accounts){return callback(accounts)})}})
this.userController.on("ItemListChanged",function(){var account,accounts,_ref1
accounts=_this.userController.getSelectedItemData()
if(accounts.length>0){account=accounts[0]
inputs.Flags.setValue(null!=(_ref1=account.globalFlags)?_ref1.join(","):void 0)
userRequestLineEdit.hide()
return _this.showConnectedFields()}userRequestLineEdit.show()
return _this.hideConnectedFields()})
return fields.Username.addSubView(userRequestLineEdit=this.userController.getView())}
AdminModal.prototype.hideConnectedFields=function(){var buttons,fields,inputs,_ref
_ref=this.modalTabs.forms["User Details"],fields=_ref.fields,inputs=_ref.inputs,buttons=_ref.buttons
fields.Impersonate.hide()
buttons.Update.hide()
fields.Flags.hide()
fields.Block.hide()
return inputs.Flags.setValue("")}
AdminModal.prototype.showConnectedFields=function(){var buttons,fields,inputs,_ref
_ref=this.modalTabs.forms["User Details"],fields=_ref.fields,inputs=_ref.inputs,buttons=_ref.buttons
fields.Impersonate.show()
fields.Flags.show()
fields.Block.show()
return buttons.Update.show()}
AdminModal.prototype.initIntroductionTab=function(){var parentView
parentView=this.modalTabs.forms.Introduction
return parentView.addSubView(new IntroductionAdmin({parentView:parentView}))}
return AdminModal}(KDModalViewWithForms)

var KiteSelectorModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KiteSelectorModal=function(_super){function KiteSelectorModal(options,data){null==options&&(options={})
options.title="Select kites"
KiteSelectorModal.__super__.constructor.call(this,options,data)
this.putTable()}var sanitizeHosts
__extends(KiteSelectorModal,_super)
sanitizeHosts=function(hosts){return hosts.map(function(host){return{value:host,title:host}})}
KiteSelectorModal.prototype.kiteIsChanged=function(kiteName,value){return KD.whoami().setKiteConnection(kiteName,value)}
KiteSelectorModal.prototype.createNewKiteModal=function(){var descriptions,form,loadBalancerDescription,modal,_this=this
descriptions={"Load Balancing Strategy":{none:"Single node",roundrobin:"Describe round robin",leastconnections:"Describe least connections",fanout:"Describe fanout",globalip:"Describe global ip",random:"Describe random"}}
loadBalancerDescription=new KDCustomHTMLView({tagName:"span",partial:descriptions["Load Balancing Strategy"].none})
modal=new KDModalViewWithForms({title:"Create a kite service",tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{"Create a service":{callback:function(){var kiteName
kiteName=form.getData().kiteName
return KD.remote.api.JKiteCluster.count({kiteName:kiteName},function(err,count){if(0!==count)return new KDNotificationView({title:"That kite name is not available; please choose another."})
_this.createNewPlanModal({kiteData:form.getData()})
return modal.destroy()})},buttons:{"Create a plan":{title:"Create a plan",style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12}}},fields:{"Kite Name":{label:"Kite name",name:"kiteName",itemClass:KDInputView,validate:{rules:{bareword:function(input){return input.setValidationResult(/^\w+$/.test(input.getValue()))}},messages:{bareword:"Kite name cannot have spaces or punctuation."}}},"Load Balancing Strategy":{label:"Load balancing strategy",itemClass:KDSelectBox,type:"select",name:"loadBalancing",defaultValue:"none",selectOptions:[{title:"None",value:"none"},{title:"Round-robin",value:"roundrobin"},{title:"Least connections",value:"leastconnections"},{title:"Fanout",value:"fanout"},{title:"Global IP",value:"globalip"},{title:"Random",value:"random"}],callback:function(value){return loadBalancerDescription.updatePartial(descriptions["Load Balancing Strategy"][value])}}}}}}})
form=modal.modalTabs.forms["Create a service"]
return form.fields["Load Balancing Strategy"].addSubView(loadBalancerDescription)}
KiteSelectorModal.prototype.createNewPlanModal=function(accumulator){var collectData,descriptions,form,intervalUnitDescription,modal,paidOnlyFields,planIdDescription,planTypeDescription,unitAmountDescription,_this=this
collectData=function(){null==accumulator.planData&&(accumulator.planData=[])
return accumulator.planData.push(modal.modalTabs.forms["Create a plan"].getData())}
descriptions={Type:{free:"Anyone can use this plan",paid:"Users must pay for this plan","protected":"Users must be invited to use this plan",custom:"You will define your own business logic for authenticating users"},"Interval Unit":{day:"days",month:"months"}}
planTypeDescription=new KDCustomHTMLView({tagName:"span",partial:descriptions.Type.free})
planIdDescription=new KDCustomHTMLView({tagName:"span",partial:"This can be any value.  You will use it for your own business logic."})
intervalUnitDescription=new KDCustomHTMLView({tagName:"span",partial:descriptions["Interval Unit"].day})
unitAmountDescription=new KDCustomHTMLView({tagName:"span",partial:"USD"})
paidOnlyFields=["Interval Unit","Interval Length","Unit Amount"]
modal=new KDModalViewWithForms({title:"Create a kite plan",tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{"Create a plan":{callback:function(){collectData()
return KD.remote.api.JKiteCluster.create(accumulator,function(err,cluster){err?new KDNotificationView({title:err.message}):_this.createClusterIsCreatedModal(cluster)
return modal.destroy()})},buttons:{"Create another plan":{title:"Create another plan",style:"modal-clean-gray",type:"button",loader:{color:"#444444",diameter:12},callback:function(){collectData()
_this.createNewPlanModal(accumulator)
return modal.destroy()}},"All done":{title:"All done",style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12}}},fields:{Title:{label:"Plan Name",itemClass:KDInputView,name:"planName"},"Plan ID":{label:"Plan Id",itemClass:KDInputView,name:"planId"},Type:{label:"Type",itemClass:KDSelectBox,type:"select",name:"type",defaultValue:"free",selectOptions:[{title:"Free",value:"free"},{title:"Paid",value:"paid"},{title:"Protected",value:"protected"},{title:"Custom",value:"custom"}],callback:function(value){paidOnlyFields.forEach("paid"===value?function(name){return form.fields[name].show()}:function(name){return form.fields[name].hide()})
return planTypeDescription.updatePartial(descriptions.Type[value])}},"Interval Unit":{label:"Interval unit",itemClass:KDSelectBox,type:"select",name:"intervalUnit",defaultValue:"day",selectOptions:[{title:"Daily",value:"day"},{title:"Monthly",value:"month"}],callback:function(value){return intervalUnitDescription.updatePartial(descriptions["Interval Unit"][value])}},"Interval Length":{label:"Interval length",itemClass:KDInputView,name:"intervalLength",defaultValue:1,attributes:{valueAsNumber:!0,size:3,min:1}},"Unit Amount":{label:"Unit amount",itemClass:KDInputView,name:"unitAmount",defaultValue:"1.00",attributes:{valueAsNumber:!0,size:3}}}}}}})
form=modal.modalTabs.forms["Create a plan"]
form.fields.Type.addSubView(planTypeDescription)
form.fields["Plan ID"].addSubView(planIdDescription)
form.fields["Interval Length"].addSubView(intervalUnitDescription)
form.fields["Unit Amount"].addSubView(unitAmountDescription)
return paidOnlyFields.forEach(function(name){return form.fields[name].hide()})}
KiteSelectorModal.prototype.createClusterIsCreatedModal=function(cluster){var modal
return modal=new KDModalView({title:"Kite service is created",content:"<p>The service was created!</p>\n<p>Kite name: <strong>"+cluster.getAt("kiteName")+"</strong></p>\n<p>Service key: <strong>"+cluster.getAt("serviceKey")+"</strong></p>\n<p>Keep it safe, and change it often!</p>"})}
KiteSelectorModal.prototype.putTable=function(){var _this=this
return KD.whoami().fetchAllKiteClusters(function(err,clusters){if(err){new KDNotificationView({title:err.message})
return _this.destroy()}clusters.forEach(function(cluster){var currentKiteUri,field,kiteName,kites,selectOptions
kiteName=cluster.kiteName,kites=cluster.kites,currentKiteUri=cluster.currentKiteUri
kites&&(selectOptions=sanitizeHosts(kites))
_this.addSubView(field=new KDView({cssClass:"modalformline"}))
field.addSubView(new KDLabelView({title:kiteName}))
return field.addSubView(new KDSelectBox({selectOptions:selectOptions,cssClass:"fr",defaultValue:currentKiteUri,callback:function(value){return _this.kiteIsChanged(kiteName,value)}}))})
return _this.addSubView(new KDButtonView({style:"clean-gray savebtn",title:"Create a kite service",callback:function(){_this.createNewKiteModal()
return _this.destroy()}}))})}
return KiteSelectorModal}(KDModalView)

var NavigationList,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationList=function(_super){function NavigationList(){_ref=NavigationList.__super__.constructor.apply(this,arguments)
return _ref}__extends(NavigationList,_super)
return NavigationList}(KDListView)

var NavigationLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationLink=function(_super){function NavigationLink(options,data){var ep,href
null==options&&(options={})
null==data&&(data={})
href=(ep=KD.config.entryPoint)?ep.slug+data.path:data.path
data.type||(data.type="")
options.tagName||(options.tagName="a")
options.type||(options.type="main-nav")
options.attributes={href:href}
options.cssClass=KD.utils.curry(this.utils.slugify(data.title),options.cssClass)
NavigationLink.__super__.constructor.call(this,options,data)
this.name=data.title
this.on("DragStarted",this.bound("dragStarted"))
this.on("DragInAction",this.bound("dragInAction"))
this.on("DragFinished",this.bound("dragFinished"))}__extends(NavigationLink,_super)
NavigationLink.prototype.click=function(event){var appPath,mc,path,title,topLevel,type,_ref
KD.utils.stopDOMEvent(event)
_ref=this.getData(),appPath=_ref.appPath,title=_ref.title,path=_ref.path,type=_ref.type,topLevel=_ref.topLevel
if(path){mc=KD.getSingleton("mainController")
return mc.emit("NavigationLinkTitleClick",{pageName:title,appPath:appPath||title,path:path,topLevel:topLevel,navItem:this})}}
NavigationLink.prototype.partial=function(data){return"<span class='icon'></span><cite>"+data.title+"</cite>"}
NavigationLink.prototype.dragInAction=function(){}
NavigationLink.prototype.dragStarted=function(){return this.setClass("no-anim")}
NavigationLink.prototype.dragFinished=function(){return this.unsetClass("no-anim")}
return NavigationLink}(KDListItemView)

var NavigationSeparator,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationSeparator=function(_super){function NavigationSeparator(options,data){null==options&&(options={})
options.tagName="hr"
NavigationSeparator.__super__.constructor.call(this,options,data)}__extends(NavigationSeparator,_super)
return NavigationSeparator}(KDCustomHTMLView)

var AdminNavigationLink,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AdminNavigationLink=function(_super){function AdminNavigationLink(){_ref=AdminNavigationLink.__super__.constructor.apply(this,arguments)
return _ref}__extends(AdminNavigationLink,_super)
AdminNavigationLink.prototype.click=function(){var cb
cb=this.getData().callback
return cb?cb.call(this):void 0}
return AdminNavigationLink}(NavigationLink)

var NavigationInviteLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationInviteLink=function(_super){function NavigationInviteLink(options,data){var _ref
null==options&&(options={})
options.tagName="a"
options.cssClass="title"
NavigationInviteLink.__super__.constructor.call(this,options,data)
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"main-nav-icon "+__utils.slugify(this.getData().title)});(null!=(_ref=KD.config.entryPoint)?_ref.slug:void 0)&&this.hide()}__extends(NavigationInviteLink,_super)
NavigationInviteLink.prototype.sendInvite=function(formData,modal){return KD.remote.api.JInvitation.inviteFriend(formData,function(err){var message
modal.modalTabs.forms["Invite Friends"].buttons.Send.hideLoader()
if(err){11e3===err.code&&(message="This e-mail is already invited!")
return new KDNotificationView({title:message||err.message||"Sorry, something bad happened.",content:message?void 0:"Please try again later!"})}new KDNotificationView({title:"Success!"})
modal.destroy()
return KD.track("Members","InvitationSentToFriend",formData.recipient)})}
NavigationInviteLink.prototype.viewAppended=JView.prototype.viewAppended
NavigationInviteLink.prototype.pistachio=function(){return"{{> this.icon}} "+this.getData().title}
NavigationInviteLink.prototype.click=function(event){var inviteForm,inviteHint,modal,modalHint,_this=this
event.stopPropagation()
event.preventDefault()
modal=new KDModalViewWithForms({title:"<span class='invite-icon'></span>Invite Friends to Koding",width:500,height:"auto",cssClass:"invitation-modal",tabs:{forms:{"Invite Friends":{callback:function(formData){return _this.sendInvite(formData,modal)},fields:{email:{label:"Send To:",placeholder:"Enter your friend's email address...",validate:{rules:{required:!0,email:!0},messages:{required:"An email address is required!",email:"That does not not seem to be a valid email address!"}}},customMessage:{label:"Message:",type:"textarea",placeholder:"Hi! You're invited to try out Koding, a new way for developers to work.",defaultValue:"Hi! You're invited to try out Koding, a new way for developers to work."}},buttons:{Send:{style:"modal-clean-gray",type:"submit",loader:{color:"#444444",diameter:12}},cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}}}}}})
inviteForm=modal.modalTabs.forms["Invite Friends"]
inviteForm.on("FormValidationFailed",function(){return inviteForm.buttons.Send.hideLoader()})
modalHint=new KDView({cssClass:"modal-hint",partial:"<p>Your friend will receive an invitation email from Koding.</p>                   <p><cite>* We take privacy seriously, we will not share any personal information.</cite></p>"})
modal.modalTabs.addSubView(modalHint,null,!0)
inviteHint=new KDView({cssClass:"invite-hint fl",pistachio:"{{#(quota) - #(usage)}} Invites remaining"},this.count.getData())
modal.modalTabs.panes[0].form.buttonField.addSubView(inviteHint,null,!0)
return!1}
return NavigationInviteLink}(KDCustomHTMLView)

var NavigationActivityLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationActivityLink=function(_super){function NavigationActivityLink(options,data){var appManager,mainController,_this=this
null==options&&(options={})
options.tagName="a"
options.cssClass="title"
NavigationActivityLink.__super__.constructor.call(this,options,data)
appManager=KD.getSingleton("appManager")
this.count=new KDCustomHTMLView({tagName:"span",cssClass:"main-nav-icon transparent",partial:"",click:function(){return _this.setActivityLinkToDefaultState()}})
this.count.hide()
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"main-nav-icon "+__utils.slugify(this.getData().title)})
mainController=KD.getSingleton("mainController")
mainController.ready(function(){var activityController
activityController=KD.getSingleton("activityController")
return activityController.on("ActivitiesArrived",function(){var newItemsCount
if("/Activity"!==KD.getSingleton("router").currentPath){newItemsCount=activityController.getNewItemsCount()
newItemsCount>0&&_this.updateNewItemsCount(newItemsCount)
return activityController.on("NewItemsCounterCleared",_this.bound("setActivityLinkToDefaultState"))}})})
mainController.on("NavigationLinkTitleClick",function(options){return"Activity"===options.appPath?KD.getSingleton("activityController").clearNewItemsCount():void 0})}__extends(NavigationActivityLink,_super)
NavigationActivityLink.prototype.updateNewItemsCount=function(itemCount){if(0!==itemCount){this.count.updatePartial(itemCount)
this.count.show()
return this.icon.hide()}}
NavigationActivityLink.prototype.setActivityLinkToDefaultState=function(){this.icon.show()
return this.count.hide()}
NavigationActivityLink.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
NavigationActivityLink.prototype.pistachio=function(){return"{{> this.count}} {{> this.icon}} "+this.getData().title}
return NavigationActivityLink}(KDCustomHTMLView)

var NavigationAppsLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationAppsLink=function(_super){function NavigationAppsLink(options,data){var _this=this
null==options&&(options={})
options.tagName="a"
options.cssClass="title"
NavigationAppsLink.__super__.constructor.call(this,options,data)
this.counter=0
this.appsController=KD.getSingleton("kodingAppsController")
this.count=new KDCustomHTMLView({tagName:"span",cssClass:"icon-top-badge",partial:"",click:function(e){e.preventDefault()
e.stopPropagation()
return KD.getSingleton("router").handleRoute("/Apps?filter=updates")}})
this.count.hide()
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"main-nav-icon "+__utils.slugify(this.getData().title)})
this.getUpdateRequiredAppsCount()
this.appsController.on("AnAppHasBeenUpdated",function(){if(0!==_this.counter){_this.counter--
return 0===_this.counter?_this.count.hide():_this.count.updatePartial(_this.counter)}})
this.appsController.on("AppsRefreshed",function(){return _this.setCounter(!0)})}__extends(NavigationAppsLink,_super)
NavigationAppsLink.prototype.getUpdateRequiredAppsCount=function(){var _this=this
return Object.keys(this.appsController.publishedApps).length?this.setCounter():this.appsController.on("UserAppModelsFetched",function(){return _this.setCounter()})}
NavigationAppsLink.prototype.setCounter=function(useTheForce){var _this=this
null==useTheForce&&(useTheForce=!1)
return this.appsController.fetchUpdateAvailableApps(function(err,availables){_this.counter=availables.length
_this.count.updatePartial(_this.counter)
return _this.counter>0?_this.count.show():_this.count.hide()},useTheForce)}
NavigationAppsLink.prototype.pistachio=function(){return"{{> this.count}} {{> this.icon}} "+this.getData().title}
return NavigationAppsLink}(JView)

var NavigationDocsJobsLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationDocsJobsLink=function(_super){function NavigationDocsJobsLink(options,data){null==options&&(options={})
options.tagName="span"
options.cssClass="title"
NavigationDocsJobsLink.__super__.constructor.call(this,options,data)
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"main-nav-icon "+__utils.slugify(this.getData().title)})
this.docsLink=new KDCustomHTMLView({tagName:"a",partial:"Docs",cssClass:"ext",attributes:{href:"http://koding.github.io/docs/",target:"_blank"}})
this.jobsLink=new KDCustomHTMLView({tagName:"a",partial:"Jobs",cssClass:"ext",attributes:{href:"http://koding.github.io/jobs/",target:"_blank"}})}__extends(NavigationDocsJobsLink,_super)
NavigationDocsJobsLink.prototype.click=function(){}
NavigationDocsJobsLink.prototype.viewAppended=JView.prototype.viewAppended
NavigationDocsJobsLink.prototype.pistachio=function(){return"{{> this.icon}} {{> this.docsLink}} / {{> this.jobsLink}}"}
return NavigationDocsJobsLink}(KDCustomHTMLView)

var NavigationPromoteLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationPromoteLink=function(_super){function NavigationPromoteLink(options,data){null==options&&(options={})
options.tagName="a"
options.cssClass="title"
options.tooltip={placement:"right",title:"If anyone registers with your referrer code,\nyou will get 250MB Free disk space for your VM.\nUp to 16GB!."}
NavigationPromoteLink.__super__.constructor.call(this,options,data)
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"main-nav-icon promote"})}__extends(NavigationPromoteLink,_super)
NavigationPromoteLink.prototype.click=function(event){var appManager
KD.utils.stopDOMEvent(event)
appManager=KD.getSingleton("appManager")
return appManager.tell("Account","showReferrerModal")}
NavigationPromoteLink.prototype.pistachio=function(){return"{{> this.icon}} {{#(title)}}"}
return NavigationPromoteLink}(JView)

var BookTableOfContents,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BookTableOfContents=function(_super){function BookTableOfContents(){_ref=BookTableOfContents.__super__.constructor.apply(this,arguments)
return _ref}__extends(BookTableOfContents,_super)
BookTableOfContents.prototype.pistachio=function(){var nr,page,tmpl,_i,_len
tmpl="<ul class='contents'>"
for(nr=_i=0,_len=__bookPages.length;_len>_i;nr=++_i){page=__bookPages[nr]
0===page.parent&&page.section>0&&(tmpl+="<li><a href='#'>"+page.title+"</a><span>"+(nr+1)+"</span></li>")}return tmpl}
BookTableOfContents.prototype.click=function(event){var nr
if($(event.target).is("a")){nr=parseInt($(event.target).next().text(),10)-1
this.getDelegate().fillPage(nr)
return!1}return!0}
return BookTableOfContents}(JView)

var BookUpdateWidget,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BookUpdateWidget=function(_super){function BookUpdateWidget(){_ref=BookUpdateWidget.__super__.constructor.apply(this,arguments)
return _ref}__extends(BookUpdateWidget,_super)
BookUpdateWidget.updateSent=!1
BookUpdateWidget.prototype.viewAppended=function(){var _this=this
this.setPartial("<span class='button'></span>")
this.addSubView(this.statusField=new KDHitEnterInputView({type:"text",defaultValue:"Hello World!",focus:function(){return _this.statusField.setKeyView()},validate:{rules:{required:!0}},callback:function(status){return _this.updateStatus(status)}}))
this.statusField.$().trigger("focus")
return this.statusField.on("click",function(event){return event.stopPropagation()})}
BookUpdateWidget.prototype.updateStatus=function(status){var _this=this
if(!this.constructor.updateSent){KD.getSingleton("appManager").open("Activity")
this.getDelegate().$().css({left:-1349})
return KD.remote.api.JStatusUpdate.create({body:status},function(err,reply){_this.utils.wait(2e3,function(){return _this.getDelegate().$().css({left:-700})})
if(err)return new KDNotificationView({type:"mini",title:"There was an error, try again later!"})
_this.constructor.updateSent=!0
KD.getSingleton("appManager").tell("Activity","ownActivityArrived",reply)
new KDNotificationView({type:"growl",cssClass:"mini",title:"Message posted!",duration:2e3})
_this.statusField.setValue("")
_this.statusField.setPlaceHolder(reply.body)
return _this.statusField.$().trigger("focus")})}new KDNotificationView({title:"You've already posted your activity :)",duration:3e3})}
return BookUpdateWidget}(KDView)

var BookTopics,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BookTopics=function(_super){function BookTopics(){_ref=BookTopics.__super__.constructor.apply(this,arguments)
return _ref}__extends(BookTopics,_super)
BookTopics.prototype.viewAppended=function(){var loader,_this=this
this.addSubView(loader=new KDLoaderView({size:{width:60},loaderOptions:{color:"#666666",shape:"spiral",diameter:60,density:60,range:.6,speed:2,FPS:25}}))
this.utils.defer(function(){return loader.show()})
return KD.getSingleton("appManager").tell("Topics","fetchSomeTopics",{limit:20},function(err,topics){loader.hide()
return err?warn(err):topics.forEach(function(topic){var topicLink
return _this.addSubView(topicLink=new TagLinkView({click:function(){_this.getDelegate().$().css({left:-1349})
return _this.utils.wait(4e3,function(){return _this.getDelegate().$().css({left:-700})})}},topic))})})}
return BookTopics}(KDView)

var StartTutorialButton,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
StartTutorialButton=function(_super){function StartTutorialButton(options,data){var _this=this
null==options&&(options={})
StartTutorialButton.__super__.constructor.call(this,options,data)
this.button=new KDButtonView({title:"Start tutorial",cssClass:"cta_button full_width",callback:function(){var welcomePageIndex
welcomePageIndex=10
return _this.getDelegate().fillPage(welcomePageIndex)}})}__extends(StartTutorialButton,_super)
StartTutorialButton.prototype.pistachio=function(){return"{{> this.button}}"}
return StartTutorialButton}(JView)

var BookDevelopButton,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BookDevelopButton=function(_super){function BookDevelopButton(){var options
options={style:"editor-advanced-settings-menu",icon:!0,iconOnly:!0,type:"contextmenu",itemClass:AceSettingsView,click:function(pubInst,event){return this.contextMenu(event)},menu:AceView.prototype.getAdvancedSettingsMenuItems}
BookDevelopButton.__super__.constructor.call(this,options)}__extends(BookDevelopButton,_super)
return BookDevelopButton}(KDButtonViewWithMenu)

var SocialShare,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SocialShare=function(_super){function SocialShare(){var _this=this
SocialShare.__super__.constructor.apply(this,arguments)
this.facebook=new KDCustomHTMLView({tagName:"iframe",attributes:{width:90,height:20,frameborder:0,scrolling:"no",allowtransparency:"true",src:"http://www.facebook.com/plugins/like.php?href=https%3A%2F%2Fkoding.com&width=40&height=21&colorscheme=light&layout=button_count&action=like&show_faces=false&send=false"}})
this.twitter=new KDCustomHTMLView({tagName:"a",cssClass:"twitter-follow-button",href:"https://twitter.com/koding",partial:""})
this.twitter.once("viewAppended",function(){var protocol
protocol=/^http:/.test(document.location)?"http":"https"
return require([""+protocol+"://platform.twitter.com/widgets.js"],function(){return twttr.widgets.createFollowButton("koding",_this.twitter.getElement(),noop)})})}__extends(SocialShare,_super)
SocialShare.prototype.pistachio=function(){return"{{> this.facebook}}\n{{> this.twitter}}"}
return SocialShare}(JView)

var __bookPages
__bookPages=[{title:"Table of Contents",embed:BookTableOfContents,section:-1},{title:"A Story",content:"Once upon a time, there were developers just like you<br/>Despite the sea between them, development had ensued",routeURL:"",section:11,parent:0},{cssClass:"a-story more-1",content:"Over time they noticed, that ‘how it’s done’ was slow<br/>“With 1,000 miles between us, problems start to show!”",routeURL:"",section:11,parent:1},{cssClass:"a-story more-2",content:"“Several different services for just a hello world?<br/>And each a different cost!” Their heads began to swirl.",routeURL:"",section:11,parent:2},{cssClass:"a-story more-3",content:"They made up their minds, “It’s time to leave the crowd</br>all of these environments should reside in the cloud!”",routeURL:"",section:11,parent:3},{cssClass:"a-story more-4",content:"“Then simplify the process, from several steps to one<br/>A terminal in a browser? That would help a ton!”",routeURL:"",section:11,parent:4},{cssClass:"a-story more-5",content:"Build it on a community, we'll teach and learn together<br/>Of course we'll charge nothing for it.",routeURL:"",section:11,parent:5},{cssClass:"a-story more-6",content:"“This sounds amazing!” They each began to sing,<br/>“Let’s package it together and call it Koding!”",routeURL:"",section:11,parent:5},{title:"Foreword",content:'<p>Koding is your new development computer in your browser.</p>\n<p>As an experienced developer you will find awesome tools to set up shop here.</p>\n<p>If you are new to programming, writing your first "Hello World" application literally is 5 minutes away from you.</p><p> Welcome home - This is going to be fun!</p>',routeURL:"",section:11,parent:0},{title:"Welcome to Koding!",content:'<p class="centered">It\'s probably your first time using Koding! Follow this quick tutorial to learn everything you can do with this amazing tool!</p>',routeURL:"/Activity",section:1,embed:StartTutorialButton,parent:0},{title:"Activity",content:"<p>Think of this as the town center of Koding. Ask questions, get answers, start a discussion...be social! The community is a great tool for development, and here is where you can get started. In fact, let’s start with your first status update! Just click the 'Show me how!' button at the top of this page!</p>",routeURL:"/Activity",section:3,parent:0,showHow:!0,howToSteps:["enterNewStatusUpdate"],menuItem:"Activity"},{title:"Members",content:"<h2>Welcome to the club!</h2>\n<p>Here you’ll find all of Koding’s members. To find another member, just enter a name in the search bar and hit enter! This is a place where you can connect and collaborate. Feel free to follow the whole Koding Team!</p>",routeURL:"/Members",section:2,parent:0},{title:"Topics",embed:BookTopics,content:"<p>Wouldn’t it be great if you could listen to only what you cared about? Well, you can! Topics let you filter content to your preferences. Select your Topics and if someone shares any information about your topic, you will be informed.</p>",routeURL:"/Topics",section:4,parent:0},{title:"Develop",content:"<p>This is where the magic happens! Your file tree, your Virtual Machines, your applications and more are located here in the Develop section</p>",routeURL:"/Develop",section:5,parent:0,showHow:!1},{cssClass:"develop more-1",content:"<h2>What are the folders in my Develop tab?</h2>\n<p>The Applications folder is a place where your koding applications are located. The Web Folder is where your http://{{#(profile.nickname)}}.kd.io adress is accessable at. Other folders do what they intend to. You can create new folders by right-clicking on your file tree!</p>",section:1,parent:5,showHow:!0,howToSteps:["showFileTreeFolderAndFileMenu"],menuItem:"Develop"},{cssClass:"develop more-5",content:"<h2>Need to upload files?</h2>\n<p>To upload your files, simply drag a file from your Desktop onto your FileTree!</p>\n<p>Your files will be uploaded into your Upload directory. It doesn't get much easier than that!</p>",version:1.1},{cssClass:"develop more-1",content:"<h2> Your default applications: </h2>\n<p><strong>Ace</strong> is your perfect text editor on cloud! Use it to edit documents in your file tree! </p>\n<p><strong>Terminal</strong> is a terminal for your Virtual Machine. You have full root access to the machine!\n   <div class='tip'><span>tip:</span> your root password is your koding password. </div>\n</p>",section:2,parent:5,showHow:!1,routeURL:"Develop"},{cssClass:"develop enviroments",content:"<h2>Control Your Virtual Machine!</h2>\n<p>It's easy to control your Virtual Machine(s)! Some basic actions you can perform are listed below:</p>\n<ul>\n  <li>Turn your Virtual Machine on and off</li>\n  <li>Re-Initialize your Virtual Machine</li>\n  <li>Delete your Virtual Machine and start with a fresh one</li>\n  <li>Checkout the Virtual Machine menu for more features</li>\n</ul>",section:3,parent:5,showHow:!0,howToSteps:["showVMMenu"],menuItem:"Develop"},{cssClass:"develop enviroments more",content:"<h2>Open Virtual Machines in your Terminal</h2>\n<p>If you have more than 1 Virtual Machine, you can open that Virtual Machine's\nmenu by clicking terminal icon on Virtual Machine menu.</p>",section:4,parent:5,showHow:!0,howToSteps:["openVMTerminal"],menuItem:"Develop"},{cssClass:"develop buy more-1",content:"<h2>Need more Virtual Machines?</h2>\n<p>It's easy to buy more Virtual Machines. If you need more space, just buy new one!</p>",section:6,parent:5,routeURL:"/Develop",showHow:!0,howToSteps:["showNewVMMenu"],menuItem:"Develop"},{cssClass:"develop more-1",content:"<p>It's easy to change your homepage! Currently: <a href= \"#\"> http://{{#(profile.nickname)}}.kd.io </a>\n<ol>\n  <li> Open your index.html file under Web folder on file tree.</li>\n  <li> change the content and save your file</li>\n  <li> Then save it with ⌘+S or clicking the save button to the right of your tabs </li>\n  <li>It's done!! No FTP no SSH no other stuff!! Just click and change</li>\n</ol>",section:7,parent:5,showHow:!0,howToSteps:["changeIndexFile"],menuItem:"Develop"},{cssClass:"develop more-2",content:"<p>When you open a new file from the file tree, a new tab is created. Use tabs to manage working on multiple files at the same time.</p>\n<p>You can also create a new file using either the “+” button on Tabs, or by right-clicking the file tree.</p>\n<p>Save the new file to your file tree by clicking the save button to the right of your tabs. </p>",section:9,parent:5},{cssClass:"develop more-4",content:"<p>There are some handy keybord bindings when working with Ace</p>\n<ul>\n  <li>save file <span>Ctrl-S</span></li>\n  <li>saveAs <span>Ctrl-Shift-S</span></li>\n  <li>find text <span>Ctrl-F</span></li>\n  <li>find and replace text <span>Ctrl-Shift-F</span></li>\n  <li>compile application <span>Ctrl-Shift-C</span></li>\n  <li>preview file Ctrl-Shift-P </li>\n</ul>",embed:BookDevelopButton,routeURL:"",section:5,parent:5},{cssClass:"develop more-3",content:"<p>Don't forget about your settings in the top corner.\nHere you can change the syntax, font, margins, and a whole\nlot of other features.</p>",routeURL:"",section:10,parent:5,showHow:!0,howToSteps:["showAceSettings"],menuItem:"Develop"},{title:"Terminal",content:"<p>Terminal is a very important aspect of development, that's why we have invested a lot of time to provide a fast, smooth and responsive console. It's an Ubuntu Virtual Machine that you can use to program Java,C++,Perl,Python,Ruby,Node,Erlang,Haskell and what not, out of the box. Everything is possible. This Virtual Machine is not a simulation, it is a real computer, and it's yours.</p>",routeURL:"/Develop/Terminal",section:11,parent:5},{cssClass:"terminal more-1",content:"<p> Let's test our terminal, type code below to see list files and folders on root and hit enter!.</p>\n<code> ls -la / </code>\n<p>You should see your file tree.. Now If you are okay with them lets get serious and be ROOT! </p>\n<code> sudo su </code>\n<p>Voila!! You are now root on your own Virtual Machine</p>\n<p>You can also install new packages. Search mySQL packages and install if you want! </p>\n<code> apt-cache search mysql </code>",section:12,parent:5},{title:"Apps",content:"<p>What makes Koding so useful are the apps provided by its users. Here you can perform one-click installs of incredibly useful applications provided by users and major web development tools. In addition to applications for the database, there are add-ons, and extensions to get your projects personalized, polished, and published faster.</p>",routeURL:"/Apps",section:6,parent:0},{title:"Chat",cssClass:"chats-intro",content:"<p class='centered'>You can chat with your friends or anyone from koding. Just type his/her name and hit enter thats all!</p>",section:8,parent:0,showHow:!0,howToSteps:["showConversationsPanel"]},{title:"Account",content:"<p class='centered'>Here is your control panel! Manage your personal settings, add your Facebook, Twitter, Github etc.. See payment history and more..</p>",routeURL:"/Account",menuItem:"Account",howToSteps:["showAccountPage"],section:9,parent:0},{title:"Etiquette",content:"<p>Seems like a fancy word, huh? Don’t worry, we’re not going to preach. This is more of a Koding Mission Statement. Sure, Koding is built around cloud development, but its second pillar is community.</p>\n<p>So what does that mean? That means that developers of all skill levels are going to grace your activity feed. Some need help, some will help others, some will guide the entire group, whatever your role is it’s important to remember one important word: help.</p>\n<p>Help by providing insight and not insult to people asking basic questions. Help by researching your question to see if it has had already been given an answer. And lastly, help us make this service the best it can be!</p>",section:-1},{title:"Share!",content:"<p>The best part about social development is that you can bring your friends along with you! By sharing Koding, you're inviting others to join our ever growing community, and inviting them to be a part of something great.</p>\n<p>Best of all, you get referral rewards for sharing Koding with others. So what do you say, share Koding today!</p>",section:-1},{title:"Enjoy!",content:"<span>book and illustrations by <a href='http://twitter.com/petorial' target='_blank'>@petorial</a></span>\n<p>That's it, we hope that you enjoy what we built.</p>",section:-1,embed:SocialShare}]

var PointerView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PointerView=function(_super){function PointerView(options,data){null==options&&(options={})
options.partial=""
options.cssClass="pointer"
PointerView.__super__.constructor.call(this,options,data)
this.bindTransitionEnd()}__extends(PointerView,_super)
PointerView.prototype.destroy=function(){this.once("transitionend",KDCustomHTMLView.prototype.destroy.bind(this))
return this.setClass("out")}
return PointerView}(KDCustomHTMLView)

var BookView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BookView=function(_super){function BookView(options,data){var _this=this
null==options&&(options={})
options.domId="instruction-book"
options.cssClass="book"
BookView.__super__.constructor.call(this,options,data)
this.mainView=this.getDelegate()
this.currentIndex=0
this.right=new KDView({cssClass:"right-page right-overflow",click:function(){return this.setClass("flipped")}})
this.left=new KDView({cssClass:"left-page fl"})
this.pagerWrapper=new KDCustomHTMLView({cssClass:"controls"})
this.pageNav=new KDCustomHTMLView({cssClass:"page-nav"})
this.pagerWrapper.addSubView(new KDCustomHTMLView({tagName:"a",partial:"Close Tutorial",testPath:"book-close",cssClass:"dismiss-button",click:function(){return _this.emit("OverlayWillBeRemoved")},tooltip:{title:"Press: Escape Key",gravity:"ne"}}))
this.showMeButton=new KDCustomHTMLView({tagName:"a",partial:"Show me how!",cssClass:"cta_button",click:function(){return _this.showMeButtonClicked()}})
this.pagerWrapper.addSubView(this.showMeButton)
this.pagerWrapper.addSubView(new KDCustomHTMLView({tagName:"a",partial:"Home",click:function(){BookView.navigateNewPages=!1
_this.fillPage(0)
return _this.checkBoundaries()}}))
this.pageNav.addSubView(this.prevButton=new KDCustomHTMLView({tagName:"a",partial:"<i class='prev'></i>",cssClass:"disabled",click:function(){return _this.fillPrevPage()},tooltip:{title:"Press: Left Arrow Key",gravity:"sw"}}))
this.pageNav.addSubView(this.nextButton=new KDCustomHTMLView({tagName:"a",partial:"<i class='next'></i>",cssClass:"disabled",click:function(){return _this.fillNextPage()},tooltip:{title:"Press: Right Arrow Key",gravity:"sw"}}))
this.pagerWrapper.addSubView(this.pageNav)
this.on("PageFill",function(){_this.checkBoundaries()
return BookView.navigateNewPages?_this.setClass("new-feature"):_this.unsetClass("new-feature")})
this.once("OverlayAdded",function(){return _this.$overlay.css({zIndex:999})})
this.once("OverlayWillBeRemoved",function(){if(BookView.navigateNewPages){BookView.navigateNewPages=!1
BookView.lastIndex=0}return _this.getStorage().setValue("lastReadVersion",_this.getVersion())})
this.once("OverlayWillBeRemoved",function(){_this.pointer&&_this.destroyPointer()
_this.unsetClass("in")
return _this.utils.wait(1e3,function(){var $spanElement
$spanElement=KD.singletons.mainView.sidebar.footerMenu.items[0].$("span")
$spanElement.addClass("opacity-up")
return _this.utils.wait(3e3,function(){return $spanElement.removeClass("opacity-up")})})})
this.once("OverlayRemoved",this.destroy.bind(this))
this.setKeyView()
cachePage(0)
KD.track("Read Tutorial Book",KD.nick())}var cachePage,cached
__extends(BookView,_super)
BookView.lastIndex=0
cached=[]
cachePage=function(index){var page
if(__bookPages[index]&&!cached[index]){page=new BookPage({},__bookPages[index])
page.appendToDomBody()
return __utils.wait(function(){cached[index]=!0
return page.destroy()})}}
BookView.prototype.pistachio=function(){return"{{> this.pagerWrapper}}\n{{> this.left}}\n{{> this.right}}"}
BookView.prototype.click=function(){return this.setKeyView()}
BookView.prototype.keyDown=function(event){var _this=this
switch(event.which){case 37:return this.fillPrevPage()
case 39:return this.fillNextPage()
case 27:this.unsetClass("in")
return this.utils.wait(600,function(){return _this.destroy()})}}
BookView.prototype.getPage=function(index){var page
null==index&&(index=0)
this.currentIndex=index
page=new BookPage({delegate:this},__bookPages[index])
return page}
BookView.prototype.changePageFromRoute=function(route){var index,page,_results
_results=[]
for(index in __bookPages)if(__hasProp.call(__bookPages,index)){page=__bookPages[index]
page.routeURL===route&&_results.push(this.fillPage(index))}return _results}
BookView.prototype.openFileWithPage=function(file){var fileName,user
user=KD.nick()
fileName="/home/"+user+file
return KD.getSingleton("appManager").openFile(FSHelper.createFileFromPath(fileName))}
BookView.prototype.toggleButton=function(button,isDisabled){return this[""+button+"Button"][isDisabled?"setClass":"unsetClass"]("disabled")}
BookView.prototype.checkBoundaries=function(pages){var _this=this
null==pages&&(pages=__bookPages)
if(BookView.navigateNewPages)return this.getNewPages(function(newPages){_this.toggleButton("prev",0===_this.newPagePointer)
return _this.toggleButton("next",_this.newPagePointer===newPages.length-1)})
this.toggleButton("prev",0===this.currentIndex)
return this.toggleButton("next",this.currentIndex===pages.length-1)}
BookView.prototype.fillPrevPage=function(){var _this=this
if(BookView.navigateNewPages)this.getNewPages(function(){var prev
prev=_this.prevUnreadPage()
return null!=prev?_this.fillPage(prev):void 0})
else if(!(this.currentIndex-1<0))return this.fillPage(this.currentIndex-1)}
BookView.prototype.fillNextPage=function(){var _this=this
if(BookView.navigateNewPages)this.getNewPages(function(){var next
next=_this.nextUnreadPage()
return null!=next?_this.fillPage(next):void 0})
else if(__bookPages.length!==this.currentIndex+1)return this.fillPage(parseInt(this.currentIndex,10)+1)}
BookView.prototype.fillPage=function(index){var _this=this
cachePage(index+1)
null==index&&(index=BookView.lastIndex)
BookView.lastIndex=index
this.page=this.getPage(index)
if(this.$().hasClass("in")){this.right.setClass("out")
this.utils.wait(300,function(){_this.right.destroySubViews()
_this.right.addSubView(_this.page)
return _this.right.unsetClass("out")})}else{this.right.destroySubViews()
this.right.addSubView(this.page)
this.right.unsetClass("out")
this.utils.wait(400,function(){return _this.setClass("in")})}this.emit("PageFill",index)
this.pointer&&this.destroyPointer()
return this.page.getData().howToSteps.length<1?this.showMeButton.hide():"Develop"===this.page.getData().menuItem&&null===KD.getSingleton("vmController").defaultVmName?this.showMeButton.hide():this.showMeButton.show()}
BookView.prototype.showMeButtonClicked=function(){var _ref
null!=(_ref=this.pointer)&&_ref.destroy()
this.mainView.addSubView(this.pointer=new PointerView)
if(this.page.getData().menuItem){this.navigateCursorToMenuItem(this.page.getData().menuItem)
return this.setClass("aside")}return this.continueNextMove()}
BookView.prototype.navigateCursorToMenuItem=function(menuItem){var filteredMenu,selectedMenuItemOffset,_this=this
this.pointer.once("transitionend",function(){_this.mainView.sidebar.animateLeftNavIn()
_this.selectedMenuItem.$().click()
_this.clickAnimation()
return _this.utils.wait(600,function(){return _this.continueNextMove()})})
filteredMenu=this.mainView.sidebar.nav.items.filter(function(x){return x.name===menuItem})
this.selectedMenuItem=filteredMenu[0]
selectedMenuItemOffset=this.selectedMenuItem.$().offset()
return this.pointer.$().offset(selectedMenuItemOffset)}
BookView.prototype.continueNextMove=function(){var parent,section,steps,_ref
steps=this.page.getData().howToSteps
_ref=this.page.getData(),section=_ref.section,parent=_ref.parent
3===section&&0===parent&&"enterNewStatusUpdate"===steps[0]&&this.navigateToStatusUpdateInput()
1===section&&5===parent&&"showFileTreeFolderAndFileMenu"===steps[0]&&this.clickFolderOnFileTree("Develop")
3===section&&5===parent&&"showVMMenu"===steps[0]&&this.showVMMenu()
4===section&&5===parent&&"openVMTerminal"===steps[0]&&this.showVMTerminal()
5===section&&5===parent&&"showRecentFiles"===steps[0]&&this.showRecentFilesMenu()
6===section&&5===parent&&"showNewVMMenu"===steps[0]&&this.showNewVMMenu()
8===section&&0===parent&&"showConversationsPanel"===steps[0]&&this.showConversationsPanel()
7===section&&5===parent&&"changeIndexFile"===steps[0]&&this.changeIndexFile()
10===section&&5===parent&&"showAceSettings"===steps[0]&&this.showAceSettings()
return"showAccountPage"===steps.first?this.destroyPointer():void 0}
BookView.prototype.navigateToStatusUpdateInput=function(){var _this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
return _this.utils.wait(1e3,function(){return _this.simulateNewStatusUpdate()})})
return this.utils.wait(500,function(){var smallInput
smallInput=_this.mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput.$()
return _this.pointer.$().offset(smallInput.offset())})}
BookView.prototype.simulateNewStatusUpdate=function(){var counter,helloWorldMessages,largeInput,repeater,smallInput,textToWrite,_this=this
smallInput=this.mainView.mainTabView.activePane.mainView.widgetController.updateWidget.smallInput
largeInput=this.mainView.mainTabView.activePane.mainView.widgetController.updateWidget.largeInput
smallInput.setFocus()
helloWorldMessages=["I'm really digging this!","This is cool","Yay! I made my first post","Hello, I've just arrived!","Hi all - this looks interesting...","Just got started Koding, I'm excited!","This is pretty nifty.","I like it here :)","Looking forward to try Koding","Just joined the Koding community","Checking out Koding.","Koding non-stop :)","So, whats up?","Alright. Let's try this","I'm here! What's next? ;)","Really digging Koding :)"]
textToWrite=helloWorldMessages[KD.utils.getRandomNumber(15,0)]
counter=0
return repeater=this.utils.repeat(121,function(){largeInput.setValue(textToWrite.slice(0,counter++))
if(counter===textToWrite.length+1){KD.utils.killRepeat(repeater)
return _this.pushSubmitButton()}})}
BookView.prototype.pushSubmitButton=function(){var submitButtonOffset,_this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
return _this.utils.wait(500,function(){new KDNotificationView({title:"Cool, it's ready! You can click submit or cancel.",duration:3e3})
return _this.utils.wait(1e3,function(){return _this.destroyPointer()})})})
submitButtonOffset=this.mainView.mainTabView.activePane.mainView.widgetController.updateWidget.submitBtn.$().offset()
return this.pointer.$().offset(submitButtonOffset)}
BookView.prototype.clickFolderOnFileTree=function(){var defaultVMName,user,userVmName,_this=this
this.mainView.sidebar.animateLeftNavOut()
this.pointer.once("transitionend",function(){_this.clickAnimation()
return _this.utils.wait(1e3,function(){var chevron,contextMenu
chevron=_this.defaultVm.$(".chevron")
chevron.click()
contextMenu=$(".jcontextmenu")
contextMenu.addClass("hidden")
return _this.utils.wait(500,function(){contextMenu.offset(chevron.offset())
contextMenu.removeClass("hidden")
return _this.destroyPointer()})})})
user=KD.nick()
defaultVMName=KD.singletons.vmController.defaultVmName
userVmName="["+defaultVMName+"]/home/"+user
return this.utils.wait(500,function(){var vmOffset
_this.defaultVm=KD.getSingleton("finderController").treeController.nodes[userVmName]
_this.defaultVm.setClass("selected")
vmOffset=_this.defaultVm.$(".chevron").offset()
return _this.pointer.$().offset(vmOffset)})}
BookView.prototype.showVMMenu=function(callback){var presentation,startTabView,toggle,_this=this
startTabView=KD.getSingleton("appManager").get("StartTab").getView()
presentation=function(){var chevron,defaultVMName,dia,id,machinesContainer,_ref,_results
defaultVMName=KD.getSingleton("vmController").defaultVmName
machinesContainer=startTabView.serverContainer.machinesContainer
_ref=machinesContainer.dias
_results=[]
for(id in _ref)if(__hasProp.call(_ref,id)){dia=_ref[id]
if(dia.getData().title===defaultVMName){chevron=dia.$(".chevron")
_this.pointer.once("transitionend",function(){var contextMenu
_this.clickAnimation()
chevron.click()
contextMenu=$(".jcontextmenu")
contextMenu.addClass("hidden")
return _this.utils.wait(500,function(){contextMenu.offset(chevron.offset())
contextMenu.removeClass("hidden")
chevron.addClass("hidden")
return callback?callback():_this.destroyPointer()})})
chevron.removeClass("hidden")
chevron.show()
_this.pointer.$().offset(chevron.offset())
break}_results.push(void 0)}return _results}
toggle=startTabView.serverContainerToggle
if("Hide environments"===toggle.getState().title)return presentation()
this.mainView.sidebar.animateLeftNavOut()
this.pointer.once("transitionend",function(){if("Show environments"===toggle.getState().title){_this.clickAnimation()
toggle.$().click()
return _this.utils.wait(2e3,function(){return presentation()})}return presentation()})
return this.mainView.once("transitionend",function(){return _this.utils.wait(1e3,function(){return _this.pointer.$().offset(toggle.$().offset())})})}
BookView.prototype.showVMTerminal=function(){var _this=this
return this.showVMMenu(function(){var openTerminal
openTerminal=$($(".jcontextmenu li")[3])
_this.pointer.once("transitionend",function(){return _this.utils.wait(1e3,function(){_this.clickAnimation()
return _this.utils.wait(500,function(){openTerminal.click()
return _this.destroyPointer()})})})
return _this.pointer.$().offset(openTerminal.offset())})}
BookView.prototype.showRecentFilesMenu=function(){var element,offsetTo,_this=this
this.pointer.once("transitionend",function(){return _this.utils.wait(500,function(){return _this.destroyPointer()})})
element=this.mainView.mainTabView.activePane.mainView.$(".start-tab-recent-container")
offsetTo=element.offset()
offsetTo.top-=30
this.setClass("moveUp")
return this.utils.wait(1e3,function(){return _this.pointer.$().offset(offsetTo)})}
BookView.prototype.showNewVMMenu=function(){var callback,toggle,_this=this
this.mainView.sidebar.animateLeftNavOut()
callback=function(){var button
button=KD.getSingleton("appManager").get("StartTab").getView().serverContainer.machinesContainer.newItemPlus.$()
_this.pointer.once("transitionend",function(){button.click()
_this.clickAnimation()
return _this.utils.wait(1e3,function(){return _this.destroyPointer()})})
return _this.pointer.$().offset(button.offset())}
toggle=KD.getSingleton("appManager").get("StartTab").getView().serverContainerToggle
this.pointer.once("transitionend",function(){if("Show environments"===toggle.getState().title){_this.clickAnimation()
toggle.$().click()
return _this.utils.wait(2e3,function(){return callback()})}return callback()})
return this.mainView.once("transitionend",function(){return _this.utils.wait(200,function(){return _this.pointer.$().offset(toggle.$().offset())})})}
BookView.prototype.showConversationsPanel=function(){var sidebar,_this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
KD.getSingleton("chatPanel").showPanel()
return _this.utils.wait(1e3,function(){return _this.startNewConversation()})})
this.setClass("moveUp")
sidebar=this.mainView.sidebar
sidebar.animateLeftNavIn()
return this.utils.wait(200,function(){var offsetTo
offsetTo=sidebar.footerMenu.$(".chat").offset()
return _this.pointer.$().offset(offsetTo)})}
BookView.prototype.startNewConversation=function(){var offsetTo,_this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
KD.getSingleton("chatPanel").header.newConversationButton.$().click()
new KDNotificationView({title:" Type your friends name",duration:3e3})
return _this.destroyPointer()})
offsetTo=KD.getSingleton("chatPanel").header.newConversationButton.$().offset()
return this.pointer.$().offset(offsetTo)}
BookView.prototype.changeIndexFile=function(){var defaultVmName,user,userVmName,_this=this
this.pointer.once("transitionend",function(){var fsFile,nodes
_this.clickAnimation()
_this.defaultVm.setClass("selected")
nodes=KD.singletons.finderController.treeController.data
fsFile=nodes.filter(function(x){return"Web"===x.name})
return fsFile?_this.navigateToFolder():void 0})
user=KD.nick()
defaultVmName=KD.singletons.vmController.defaultVmName
userVmName="["+defaultVmName+"]/home/"+user
return this.utils.wait(500,function(){var vmOffset
_this.defaultVm=KD.getSingleton("finderController").treeController.nodes[userVmName]
vmOffset=_this.defaultVm.$(".icon").offset()
_this.mainView.sidebar.animateLeftNavOut()
return _this.utils.wait(500,function(){return _this.pointer.$().offset(vmOffset)})})}
BookView.prototype.navigateToFolder=function(){var defaultVMName,offsetTo,user,webFolder,_this=this
this.pointer.once("transitionend",function(){var user
user=KD.nick()
return _this.utils.wait(1200,function(){_this.clickAnimation()
KD.getSingleton("finderController").treeController.expandFolder(_this.webFolderItem)
_this.webFolderItem.setClass("selected")
return _this.findAndOpenIndexFile()})})
user=KD.nick()
defaultVMName=KD.singletons.vmController.defaultVmName
webFolder="["+defaultVMName+"]/home/"+user+"/Web"
this.webFolderItem=KD.getSingleton("finderController").treeController.nodes[webFolder]
offsetTo=this.webFolderItem.$().offset()
return this.pointer.$().offset(offsetTo)}
BookView.prototype.findAndOpenIndexFile=function(){var _this=this
this.pointer.once("transitionend",function(){return _this.utils.wait(2200,function(){_this.webFolderItem.unsetClass("selected")
_this.indexFileItem.setClass("selected")
return _this.utils.wait(600,function(){_this.clickAnimation()
_this.openFileWithPage("/Web/index.html")
return _this.utils.wait(800,function(){return _this.simulateReplacingText()})})})})
return this.utils.wait(3e3,function(){var defaultVMName,indexFile,offsetTo,user
user=KD.nick()
defaultVMName=KD.singletons.vmController.defaultVmName
indexFile="["+defaultVMName+"]/home/"+user+"/Web/index.html"
_this.indexFileItem=KD.getSingleton("finderController").treeController.nodes[indexFile]
offsetTo=_this.indexFileItem.$().offset()
return _this.pointer.$().offset(offsetTo)})}
BookView.prototype.simulateReplacingText=function(){var aceViewName,offsetTo,range,user,_this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
new KDNotificationView({title:"change 'Hello World!' to 'KODING ROCKS!'",duration:3e3})
return _this.utils.wait(4e3,function(){_this.aceView.ace.editor.replace("<h1>KODING ROCKS!</h1>",{needle:"<h1>Hello World!</h1>"})
return _this.saveAndOpenPreview()})})
user=KD.nick()
aceViewName="/home/"+user+"/Web/index.html"
this.aceView=KD.getSingleton("appManager").frontApp.mainView.aceViews[aceViewName]
range=this.aceView.ace.editor.find("<h1>")
offsetTo=this.pointer.$().offset()
offsetTo.left+=500
return this.pointer.$().offset(offsetTo)}
BookView.prototype.saveAndOpenPreview=function(){var button,_this=this
button=this.mainView.appSettingsMenuButton
this.pointer.$().offset(button.$().offset())
return this.pointer.once("transitionend",function(){_this.clickAnimation()
button.$().click()
_this.pointer.$().offset($(button.contextMenu.$("li")[0]).offset())
return _this.utils.wait(2e3,function(){button.data.items[0].callback()
return _this.utils.wait(2e3,function(){return _this.openPreview()})})})}
BookView.prototype.openPreview=function(){var button,_this=this
new KDNotificationView({title:"Let's see what changed!",duration:3e3})
button=this.mainView.appSettingsMenuButton
this.pointer.$().offset(button.$().offset())
return this.utils.wait(2200,function(){button.$().click()
return _this.utils.wait(800,function(){_this.pointer.$().offset($(button.contextMenu.$("li")[7]).offset())
return _this.utils.wait(2200,function(){button.data.items[9].callback()
return _this.destroyPointer()})})})}
BookView.prototype.showAceSettings=function(){var offsetTo,_this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
_this.mainView.mainTabView.activePane.mainView.appIcons.Ace.$().click()
_this.utils.wait(800,function(){return _this.openAceMenu()})
return _this.setClass("aside")})
offsetTo=this.mainView.mainTabView.activePane.mainView.appIcons.Ace.$().offset()
return this.pointer.$().offset(offsetTo)}
BookView.prototype.openAceMenu=function(){var offsetTo,_this=this
this.pointer.once("transitionend",function(){_this.clickAnimation()
_this.mainView.appSettingsMenuButton.$().click()
return _this.utils.wait(200,function(){var advancedSettings,offsetTo
advancedSettings=_this.mainView.appSettingsMenuButton.contextMenu.treeController.nodes.advancedSettings
offsetTo=null!=advancedSettings?advancedSettings.$().offset():void 0
_this.pointer.once("transitionend",function(){return _this.utils.wait(1e3,function(){advancedSettings.setClass("selected")
advancedSettings.$().click()
_this.clickAnimation()
return _this.utils.wait(1e3,function(){_this.unsetClass("aside")
return _this.destroyPointer()})})})
return _this.pointer.$().offset(offsetTo)})})
offsetTo=this.mainView.appSettingsMenuButton.$().offset()
return this.pointer.$().offset(offsetTo)}
BookView.prototype.destroyPointer=function(){var _this=this
this.unsetClass("aside")
this.setKeyView()
return this.utils.wait(500,function(){return _this.pointer.destroy()})}
BookView.prototype.clickAnimation=function(){var _this=this
this.pointer.setClass("clickPulse")
return this.utils.wait(1e3,function(){return _this.pointer.unsetClass("clickPulse")})}
BookView.prototype.indexPages=function(){var index,page,_i,_len,_results
_results=[]
for(index=_i=0,_len=__bookPages.length;_len>_i;index=++_i){page=__bookPages[index]
page.index=index
_results.push(page.version||(page.version=0))}return _results}
BookView.prototype.getStorage=function(){return this.storage||(this.storage=new AppStorage("KodingBook",1))}
BookView.prototype.getVersion=function(){this.indexPages()
return Math.max.apply(Math,_.pluck(__bookPages,"version"))}
BookView.prototype.getNewerPages=function(version){return __bookPages.filter(function(page){return KD.utils.versionCompare(page.version,">",version)})}
BookView.prototype.nextUnreadPage=function(){if(this.newPagePointer+1!==this.unreadPages.length){this.newPagePointer++
return this.unreadPages[this.newPagePointer].index}}
BookView.prototype.prevUnreadPage=function(){if(0!==this.newPagePointer){--this.newPagePointer
return this.unreadPages[this.newPagePointer].index}}
BookView.prototype.getNewPages=function(callback){var _this=this
return this.unreadPages?callback(this.unreadPages):this.getStorage().fetchValue("lastReadVersion",function(lastReadVersion){var unreadPages
null==lastReadVersion&&(lastReadVersion=0)
if(_this.getVersion()>lastReadVersion){unreadPages=_this.getNewerPages(lastReadVersion)
if(0===unreadPages.length)return callback([])
null==_this.newPagePointer&&(_this.newPagePointer=0)
_this.unreadPages=unreadPages
return callback(unreadPages)}return callback([])})}
return BookView}(JView)

var BookPage,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BookPage=function(_super){function BookPage(options,data){var k,konstructor
null==options&&(options={})
data.cssClass||(data.cssClass="")
data.content||(data.content="")
data.menuItem||(data.menuItem="")
data.profile=KD.whoami().profile
data.routeURL||(data.routeURL="")
data.section||(data.section=0)
data.parent||(data.parent=0)
null==data.showHow&&(data.showHow=!1)
data.howToSteps||(data.howToSteps=[])
options.cssClass="page "+this.utils.slugify(data.title)+" "+data.cssClass+" "+(data.title?void 0:"no-header")
options.tagName="section"
BookPage.__super__.constructor.call(this,options,data)
this.header=new KDView({tagName:"header",partial:""+data.title,cssClass:data.title?void 0:"hidden"})
this.content=new KDView({tagName:"article",cssClass:"content-wrapper",pistachio:data.content},data)
konstructor=data.embed&&"function"==typeof(k=data.embed)?k:KDCustomHTMLView
this.embedded=new konstructor({delegate:this.getDelegate()})}__extends(BookPage,_super)
BookPage.prototype.pistachio=function(){return"{{> this.header}}\n{{> this.content}}\n<div class='embedded'>\n  {{> this.embedded}}\n</div>"}
return BookPage}(JView)

var MainTabView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MainTabView=function(_super){function MainTabView(options,data){var _this=this
options.resizeTabHandles=!0
options.lastTabHandleMargin=40
options.sortable=!0
this.visibleHandles=[]
this.totalSize=0
MainTabView.__super__.constructor.call(this,options,data)
this.router=KD.getSingleton("router")
this.appManager=KD.getSingleton("appManager")
this.appManager.on("AppIsBeingShown",function(controller,view,options){return view.parent?_this.showPane(view.parent):_this.createTabPane(options,view)})}__extends(MainTabView,_super)
MainTabView.prototype.handleClicked=function(index,event){var appInstance,appView,options,pane,quitOptions
pane=this.getPaneByIndex(index)
appView=pane.getMainView()
appInstance=this.appManager.getByView(appView)
options=appInstance.getOptions()
if($(event.target).hasClass("close-tab")){quitOptions=pane.mainView.quitOptions
quitOptions?this.warnClosingMultipleTabs(appInstance,quitOptions):this.appManager.quit(appInstance)
return!1}return this.appManager.showInstance(appInstance)}
MainTabView.prototype.showPane=function(pane){this.$("> .kdtabpaneview").removeClass("active")
this.$("> .kdtabpaneview").addClass("kdhiddentab")
MainTabView.__super__.showPane.call(this,pane)
this.emit("MainTabPaneShown",pane)
return pane}
MainTabView.prototype.removePane=function(pane){var handle,index,isActivePane,leftPane,rightPane,visibleIndex,visibles
index=this.getPaneIndex(pane)
visibles="function"==typeof this.getVisibleTabs?this.getVisibleTabs():void 0
visibleIndex=visibles.indexOf(pane)
leftPane=visibles[visibleIndex-1]
rightPane=visibles[visibleIndex+1]
pane.emit("KDTabPaneDestroy")
isActivePane=this.getActivePane()===pane
this.panes.splice(index,1)
pane.destroy()
handle=this.getHandleByIndex(index)
this.handles.splice(index,1)
handle.destroy()
this.emit("PaneRemoved")
return rightPane?this.appManager.showInstance(this.appManager.getByView(rightPane.mainView)):leftPane?this.appManager.showInstance(this.appManager.getByView(leftPane.mainView)):this.router.handleRoute("/Activity")}
MainTabView.prototype.createTabPane=function(options,mainView){var domId,o,paneInstance,_this=this
null==options&&(options={})
o={}
o.cssClass=this.utils.curry("content-area-pane",options.cssClass)
o["class"]||(o["class"]=KDView)
domId="maintabpane-"+this.utils.slugify(options.name)
document.getElementById(domId)&&(o.domId=domId)
o.name=options.name
o.behavior=options.behavior
o.hiddenHandle=options.hiddenHandle
o.view=mainView
paneInstance=new MainTabPane(o)
paneInstance.once("viewAppended",function(){var appController,appInfo
_this.applicationPaneReady(paneInstance,mainView)
appController=_this.appManager.getByView(mainView)
appInfo=appController.getOptions().appInfo
return(null!=appInfo?appInfo.title:void 0)?paneInstance.setTitle(appInfo.title):void 0})
this.addPane(paneInstance)
return paneInstance}
MainTabView.prototype.applicationPaneReady=function(pane,mainView){"application"===pane.getOption("behavior")&&mainView.setClass("application-page")
return mainView.on("KDObjectWillBeDestroyed",this.removePane.bind(this,pane))}
MainTabView.prototype.rearrangeVisibleHandlesArray=function(){var handle,_i,_len,_ref,_results
this.visibleHandles=[]
_ref=this.handles
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){handle=_ref[_i]
handle.getOptions().hidden?_results.push(void 0):_results.push(this.visibleHandles.push(handle))}return _results}
MainTabView.prototype.warnClosingMultipleTabs=function(appInstance,quitOptions){var content,modal,title,_this=this
title=quitOptions.title||"Do you want to close multiple tabs?"
content=quitOptions.message||"Please make sure that you saved all your work."
return modal=new KDModalView({cssClass:"modal-with-text",title:""+title,content:"<p>"+content+"</p>",overlay:!0,buttons:{Close:{cssClass:"modal-clean-gray",title:"Close",callback:function(){_this.appManager.quit(appInstance)
return modal.destroy()}},Cancel:{cssClass:"modal-cancel",title:"Cancel",callback:function(){return modal.destroy()}}}})}
return MainTabView}(KDTabView)

var MainTabPane,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MainTabPane=function(_super){function MainTabPane(options,data){this.id||(this.id=options.id)
options.type=options.behavior
MainTabPane.__super__.constructor.call(this,options,data)}__extends(MainTabPane,_super)
return MainTabPane}(KDTabPaneView)

var MainTabHandleHolder,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MainTabHandleHolder=function(_super){function MainTabHandleHolder(options,data){null==options&&(options={})
options.bind="mouseenter mouseleave"
MainTabHandleHolder.__super__.constructor.call(this,options,data)
this.userApps=[]}__extends(MainTabHandleHolder,_super)
MainTabHandleHolder.prototype.viewAppended=function(){var mainView,_this=this
mainView=this.getDelegate()
this.addPlusHandle()
mainView.mainTabView.on("PaneDidShow",function(event){return _this._repositionPlusHandle(event)})
mainView.mainTabView.on("PaneRemoved",function(){return _this._repositionPlusHandle()})
mainView.mainTabView.on("PaneAdded",function(pane){var tabHandle
tabHandle=pane.tabHandle
tabHandle.on("DragStarted",function(){return tabHandle.dragIsAllowed=_this.subViews.length<=2?!1:!0})
tabHandle.on("DragInAction",function(){return tabHandle.dragIsAllowed?_this.plusHandle.hide():void 0})
return tabHandle.on("DragFinished",function(){return _this.plusHandle.show()})})
return this.listenWindowResize()}
MainTabHandleHolder.prototype._windowDidResize=function(){var mainView
mainView=this.getDelegate()
return this.setWidth(mainView.mainTabView.getWidth())}
MainTabHandleHolder.prototype.addPlusHandle=function(){return this.addSubView(this.plusHandle=new KDCustomHTMLView({cssClass:"kdtabhandle add-editor-menu visible-tab-handle plus first last",partial:"<span class='icon'></span><b class='hidden'>Click here to start</b>",delegate:this,click:this.bound("createPlusHandleDropDown")}))}
MainTabHandleHolder.prototype.createPlusHandleDropDown=function(event){var appManager,appsController,contextMenu,index,offset
appsController=KD.getSingleton("kodingAppsController")
appManager=KD.getSingleton("appManager")
if(this.plusHandle.$().hasClass("first"))return KD.getSingleton("appManager").open("StartTab")
offset=this.plusHandle.$().offset()
contextMenu=new JContextMenu({event:event,delegate:this.plusHandle,x:offset.left-133,y:offset.top+22,arrow:{placement:"top",margin:-20}},{"Your Apps":{callback:function(){appManager.open("StartTab",{forceNew:!0})
return contextMenu.destroy()},separator:!0},"Ace Editor":{callback:function(){appManager.open("Ace",{forceNew:!0})
return contextMenu.destroy()}},Terminal:{callback:function(){appManager.open("Terminal",{forceNew:!0})
return contextMenu.destroy()}},Teamwork:{callback:function(){KD.getSingleton("router").handleRoute("/Develop/Teamwork")
return contextMenu.destroy()},separator:!0},"Search the App Store":{callback:function(){appManager.open("Apps")
return contextMenu.destroy()}},"Make your own app...":{callback:function(){return appsController.makeNewApp()}}})
index=4
return appsController.fetchApps(function(err,apps){var app,name,_results
_results=[]
for(name in apps)if(__hasProp.call(apps,name)){app=apps[name]
app.callback=appManager.open.bind(appManager,name,{forceNew:!0},contextMenu.bound("destroy"))
app.title=name
contextMenu.treeController.addNode(app,index)
_results.push(index++)}return _results})}
MainTabHandleHolder.prototype.removePlusHandle=function(){return this.plusHandle.destroy()}
MainTabHandleHolder.prototype._repositionPlusHandle=function(){var appTabCount,pane,visibleTabs,_i,_len,_ref
appTabCount=0
visibleTabs=[]
_ref=this.getDelegate().mainTabView.panes
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
if("application"===pane.options.type){visibleTabs.push(pane)
pane.tabHandle.unsetClass("first")
appTabCount++}}if(0===appTabCount){this.plusHandle.setClass("first last")
return this.plusHandle.$("b").removeClass("hidden")}visibleTabs[0].tabHandle.setClass("first")
this.removePlusHandle()
this.addPlusHandle()
this.plusHandle.unsetClass("first")
return this.plusHandle.setClass("last")}
return MainTabHandleHolder}(KDView)

var GlobalNotification,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GlobalNotification=function(_super){function GlobalNotification(options,data){var globalSticky,_this=this
null==options&&(options={})
""===options.title&&(options.title="Shutdown in")
null==options.endTitle&&(options.endTitle="Shutting down anytime now.")
null==options.messageType&&(options.messageType=options.type)
null==options.targetDate&&(options.targetDate=new Date(Date.now()+3e5))
options.duration=new Date(options.targetDate)-new Date(Date.now())
null==options.flashThresholdPercentage&&(options.flashThresholdPercentage=25)
null==options.flashThresholdSeconds&&(options.flashThresholdSeconds=60)
null==options.showTimer&&(options.showTimer=!0)
""===options.content&&(options.content="We are upgrading the platform. Please save your work.")
options.bind="mouseenter mouseleave"
GlobalNotification.__super__.constructor.call(this,options,data)
this.setClass("notification sticky hidden")
this.setType(this.getOptions().messageType)
this.on("mouseenter",function(){_this.show()
return _this.utils.wait(100,function(){return _this.notificationShowContent()})})
this.on("mouseleave",function(){return _this.$().hasClass("hidden")?void 0:_this.notificationHideContent()})
this.on("restartCanceled",function(){_this.stopTimer()
_this.recalculatePosition()
return _this.hide()})
this.timer=new KDView({cssClass:"notification-timer",duration:this.getOptions().duration})
this.title=new KDView({cssClass:"notification-title",partial:this.getOptions().title})
this.titleText=this.getOptions().title
this.contentText=new KDView({cssClass:"content",partial:this.getOptions().content})
this.content=new KDView({cssClass:"notification-content hidden"})
this.content.addSubView(this.contentText)
this.current=new KDView({cssClass:"current"})
this.startTime=new Date(Date.now())
this.endTime=new Date(this.getOptions().targetDate)
this.done=!1
globalSticky=KD.getSingleton("windowController").stickyNotification
if(globalSticky){globalSticky.done=!1
globalSticky.setType(this.getOptions().messageType)
globalSticky.endTime!==Date(this.getOptions().targetDate)&&globalSticky.show()
globalSticky.setTitle(this.getOptions().title)
globalSticky.setContent(this.getOptions().content)
globalSticky.startTime=Date.now()
globalSticky.endTime=new Date(this.getOptions().targetDate)
globalSticky.adjustTimer(this.getOptions().duration)}else{this.appendToDomBody()
KD.getSingleton("windowController").stickyNotification=this}}__extends(GlobalNotification,_super)
GlobalNotification.prototype.destroy=function(){return GlobalNotification.__super__.destroy.apply(this,arguments)}
GlobalNotification.prototype.show=function(){GlobalNotification.__super__.show.apply(this,arguments)
return this.getDomElement()[0].style.top=0}
GlobalNotification.prototype.hide=function(){var timerHeight
GlobalNotification.__super__.hide.apply(this,arguments)
timerHeight=this.$(".slider-wrapper").outerHeight(!0)
return this.$().css({top:-this.getHeight()+timerHeight})}
GlobalNotification.prototype.recalculatePosition=function(){var cachedWidth
cachedWidth=this.getWidth()
return this.$().css({marginLeft:-cachedWidth/2})}
GlobalNotification.prototype.setType=function(type){null==type&&(type="restart")
this.type=type
return this.showTimer="restart"===type?!0:!1}
GlobalNotification.prototype.setTitle=function(title){this.title.updatePartial(title)
this.title.render()
return this.titleText=title}
GlobalNotification.prototype.setContent=function(content){this.contentText.updatePartial(content)
return this.contentText.render()}
GlobalNotification.prototype.stopTimer=function(){clearInterval(this.notificationInterval)
this.$(".slider-wrapper").addClass("done")
return this.timer.updatePartial("Always pass on what you have learned - Yoda")}
GlobalNotification.prototype.adjustTimer=function(newDuration){if(this.showTimer){clearInterval(this.notificationInterval)
this.$(".slider-wrapper").removeClass("done")
this.$(".slider-wrapper").removeClass("disabled")
this.notificationStartTimer(newDuration)
return this.recalculatePosition()}this.stopTimer()
this.$(".slider-wrapper").addClass("disabled")
return this.timer.updatePartial(this.titleText)}
GlobalNotification.prototype.getCurrentTimeRemaining=function(){return this.endTime-Date.now()}
GlobalNotification.prototype.getCurrentTimePercentage=function(){var current,overall
overall=this.endTime-this.startTime
current=this.endTime-Date.now()
return 100*current/overall}
GlobalNotification.prototype.pistachio=function(){return"<div class='header'>\n{{> this.timer}}\n</div>\n{{> this.content}}\n<div class='slider-wrapper'>\n  <div class='slider'>\n   {{> this.current}}\n  </div>\n</div>"}
GlobalNotification.prototype.click=function(){var _ref
return(null!=(_ref=this.content)?_ref.$().hasClass("hidden"):void 0)?this.notificationShowContent():this.notificationHideContent()}
GlobalNotification.prototype.viewAppended=function(){var controller,_this=this
this.setTemplate(this.pistachio())
this.template.update()
controller=KD.getSingleton("windowController")
if(!controller.stickyNotification){this.utils.defer(function(){return _this.show()})
if(this.showTimer)return this.notificationStartTimer(this.getOptions().duration)
this.timer.updatePartial(this.getOptions().title)
return this.$(".slider-wrapper").addClass("done")}}
GlobalNotification.prototype.notificationShowContent=function(){var _ref,_this=this
null!=(_ref=this.content)&&_ref.show()
return this.utils.defer(function(){return _this.$(".notification-content").height(_this.contentText.getHeight())})}
GlobalNotification.prototype.notificationHideContent=function(){var _ref
null!=(_ref=this.content)&&_ref.hide()
return this.$(".notification-content").height(0)}
GlobalNotification.prototype.notificationStartTimer=function(duration){var options,timeText,_this=this
if(0!==duration){options=this.getOptions()
timeText=function(remaining,titleText){var minutes,seconds,text
null==remaining&&(remaining=3e5)
seconds=Math.floor(remaining/1e3)
minutes=Math.floor(seconds/60)
if(seconds>0){text=titleText+" "
if(minutes>0){text+=""+minutes+" Minute"+(1===minutes?"":"s")
0!==seconds-60*minutes&&(text+=" and "+(seconds-60*minutes)+" seconds")
return text}return text+=""+seconds+" second"+(1!==seconds?"s":"")}return options.endTitle}
this.timer.updatePartial(timeText(duration,this.titleText))
return this.notificationInterval=setInterval(function(){var currentTime,currentTimePercentage,_base
currentTimePercentage=_this.getCurrentTimePercentage()
options=_this.getOptions()
_this.current.getDomElement()[0].style.width=currentTimePercentage+"%"
currentTimePercentage<options.flashThresholdPercentage||_this.getCurrentTimeRemaining()/1e3<options.flashThresholdSeconds?_this.current.setClass("flash"):_this.current.unsetClass("flash")
currentTime=parseInt(_this.endTime-Date.now(),10)
_this.timer.updatePartial(timeText(currentTime,_this.titleText))
_this.recalculatePosition()
if(0>=currentTime){_this.done=!0
"function"==typeof(_base=_this.getOptions()).callback&&_base.callback()
clearInterval(_this.notificationInterval)
return _this.$(".slider-wrapper").addClass("done")}},1e3)}}
return GlobalNotification}(KDView)

var AvatarArea,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarArea=function(_super){function AvatarArea(options,data){var account,_this=this
null==options&&(options={})
options.cssClass||(options.cssClass="avatar-area")
AvatarArea.__super__.constructor.call(this,options,data)
account=this.getData()
this.avatar=new AvatarView({tagName:"div",cssClass:"avatar-image-wrapper",attributes:{title:"View your public profile"},size:{width:36,height:36}},account)
this.profileLink=new ProfileLinkView({},account)
this.groupSwitcherPopup=new AvatarPopupGroupSwitcher({cssClass:"group-switcher"})
this.groupsSwitcherIcon=new AvatarAreaIconLink({cssClass:"groups acc-dropdown-icon",attributes:{title:"Your groups"},delegate:this.groupSwitcherPopup})
this.once("viewAppended",function(){var mainView
mainView=KD.getSingleton("mainView")
mainView.addSubView(_this.groupSwitcherPopup)
return _this.groupSwitcherPopup.listControllerPending.on("PendingGroupsCountDidChange",function(count){count>0?_this.groupSwitcherPopup.invitesHeader.show():_this.groupSwitcherPopup.invitesHeader.hide()
return _this.groupsSwitcherIcon.updateCount(count)})})
KD.getSingleton("mainController").on("accountChanged",function(){_this.groupSwitcherPopup.listController.removeAllItems()
_this.groupSwitcherPopup.populateGroups()
return _this.groupSwitcherPopup.populatePendingGroups()})}__extends(AvatarArea,_super)
AvatarArea.prototype.viewAppended=JView.prototype.viewAppended
AvatarArea.prototype.pistachio=function(){return"{{> this.avatar}}\n<section>\n  <h2>{{> this.profileLink}}</h2>\n  <h3>Designer</h3>\n  {{> this.groupsSwitcherIcon}}\n</section>"}
return AvatarArea}(KDCustomHTMLView)

var AvatarPopup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarPopup=function(_super){function AvatarPopup(){var mainController
AvatarPopup.__super__.constructor.apply(this,arguments)
this.on("ReceivedClickElsewhere",this.bound("hide"))
mainController=KD.getSingleton("mainController")
mainController.on("accountChanged.to.loggedIn",this.bound("accountChanged"))
this._windowController=KD.getSingleton("windowController")
this.listenWindowResize()}__extends(AvatarPopup,_super)
AvatarPopup.prototype.show=function(){this.utils.killWait(this.loaderTimeout)
this._windowDidResize()
this._windowController.addLayer(this)
KD.getSingleton("mainController").emit("AvatarPopupIsActive")
this.setClass("active")
return this}
AvatarPopup.prototype.hide=function(){KD.getSingleton("mainController").emit("AvatarPopupIsInactive")
this.unsetClass("active")
return this}
AvatarPopup.prototype.viewAppended=function(){this.setClass("avatararea-popup")
this.addSubView(this.avatarPopupTab=new KDView({cssClass:"tab",partial:'<span class="avatararea-popup-close"></span>'}))
this.setPopupListener()
this.addSubView(this.avatarPopupContent=new KDView({cssClass:"content hidden"}))
this.addSubView(this.notLoggedInWarning=new KDView({height:"auto",cssClass:"content sublink",partial:this.notLoggedInMessage||"Login required."}))
return KD.isLoggedIn()?this.accountChanged():void 0}
AvatarPopup.prototype.setPopupListener=function(){var _this=this
return this.avatarPopupTab.on("click",function(){return _this.hide()})}
AvatarPopup.prototype._windowDidResize=function(){var avatarTopOffset,scrollView,windowHeight
if(this.listController){scrollView=this.listController.scrollView
windowHeight=$(window).height()
avatarTopOffset=this.$().offset().top
return this.listController.scrollView.$().css({maxHeight:windowHeight-avatarTopOffset-80})}}
AvatarPopup.prototype.accountChanged=function(){this.notLoggedInWarning.hide()
return this.avatarPopupContent.show()}
return AvatarPopup}(KDView)

var PopupList,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PopupList=function(_super){function PopupList(options,data){null==options&&(options={})
options.tagName||(options.tagName="ul")
options.cssClass||(options.cssClass="avatararea-popup-list")
PopupList.__super__.constructor.call(this,options,data)}__extends(PopupList,_super)
return PopupList}(KDListView)

var AvatarPopupGroupSwitcher,PopupGroupListItem,PopupGroupListItemPending,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
AvatarPopupGroupSwitcher=function(_super){function AvatarPopupGroupSwitcher(){this.notLoggedInMessage="Login required to switch groups"
AvatarPopupGroupSwitcher.__super__.constructor.apply(this,arguments)}__extends(AvatarPopupGroupSwitcher,_super)
AvatarPopupGroupSwitcher.prototype.viewAppended=function(){var groupsController
AvatarPopupGroupSwitcher.__super__.viewAppended.apply(this,arguments)
this.pending=0
this.notPopulated=!0
this.notPopulatedPending=!0
this._popupList=new PopupList({itemClass:PopupGroupListItem})
this._popupListPending=new PopupList({itemClass:PopupGroupListItemPending})
this._popupListPending.on("PendingCountDecreased",this.bound("decreasePendingCount"))
this._popupListPending.on("UpdateGroupList",this.bound("populateGroups"))
this.listControllerPending=new KDListViewController({view:this._popupListPending,startWithLazyLoader:!0})
this.listController=new KDListViewController({view:this._popupList,startWithLazyLoader:!0})
this.listController.on("AvatarPopupShouldBeHidden",this.bound("hide"))
this.avatarPopupContent.addSubView(this.invitesHeader=new KDView({height:"auto",cssClass:"sublink top hidden",partial:"You have pending group invitations:"}))
this.avatarPopupContent.addSubView(this.listControllerPending.getView())
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"span",cssClass:"icon help",tooltip:{title:"Here you'll find the groups that you are a member of, clicking one of them will take you to a new browser tab."}}))
this.avatarPopupContent.addSubView(this.listController.getView())
groupsController=KD.getSingleton("groupsController")
groupsController.once("GroupChanged",function(){var group
group=groupsController.getCurrentGroup()
return"koding"!==(null!=group?group.slug:void 0)?backToKodingView.updatePartial("<a class='right' target='_blank' href='/Activity'>Back to Koding</a>"):void 0})
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"/Account"},cssClass:"bottom seperator",partial:"Account settings",click:function(event){KD.utils.stopDOMEvent(event)
return KD.getSingleton("router").handleRoute("/Account")}}))
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"/Environments"},cssClass:"bottom",partial:"Environments",click:function(event){KD.utils.stopDOMEvent(event)
return KD.getSingleton("router").handleRoute("/Environments")}}))
return this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"/Logout"},cssClass:"bottom",partial:"Logout",click:function(event){KD.utils.stopDOMEvent(event)
return KD.getSingleton("router").handleRoute("/Logout")}}))}
AvatarPopupGroupSwitcher.prototype.populatePendingGroups=function(){var _this=this
this.listControllerPending.removeAllItems()
this.listControllerPending.hideLazyLoader()
return KD.isLoggedIn()?KD.whoami().fetchGroupsWithPendingInvitations(function(err,groups){var group,_i,_len
if(err)return warn(err)
if(null!=groups){_this.pending=0
for(_i=0,_len=groups.length;_len>_i;_i++){group=groups[_i]
if(group){_this.listControllerPending.addItem({group:group,roles:[],admin:!1})
_this.pending++}}_this.updatePendingCount()
return _this.notPopulatedPending=!1}}):void 0}
AvatarPopupGroupSwitcher.prototype.populateGroups=function(){var _this=this
this.listController.removeAllItems()
this.listController.showLazyLoader()
return KD.isLoggedIn()?KD.whoami().fetchGroups(null,function(err,groups){var stack
if(err)return warn(err)
if(null!=groups){stack=[]
groups.forEach(function(group){return stack.push(function(cb){return group.group.fetchMyRoles(function(err,roles){group.admin=!1
err||(group.admin=__indexOf.call(roles,"admin")>=0)
return cb(err,group)})})})
return async.parallel(stack,function(err,results){if(!err){results.sort(function(a,b){return a.admin===b.admin?a.group.slug>b.group.slug:!a.admin&&b.admin})
_this.listController.hideLazyLoader()
return _this.listController.instantiateListItems(results)}})}}):void 0}
AvatarPopupGroupSwitcher.prototype.decreasePendingCount=function(){this.pending--
return this.updatePendingCount()}
AvatarPopupGroupSwitcher.prototype.updatePendingCount=function(){return this.listControllerPending.emit("PendingGroupsCountDidChange",this.pending)}
AvatarPopupGroupSwitcher.prototype.show=function(){AvatarPopupGroupSwitcher.__super__.show.apply(this,arguments)
this.notPopulated&&this.populateGroups()
return this.notPopulatedPending?this.populatePendingGroups():void 0}
return AvatarPopupGroupSwitcher}(AvatarPopup)
PopupGroupListItem=function(_super){function PopupGroupListItem(options){var admin,avatar,roleClasses,roles,slug,title,_ref,_ref1
null==options&&(options={})
options.tagName||(options.tagName="li")
PopupGroupListItem.__super__.constructor.apply(this,arguments)
_ref=this.getData(),_ref1=_ref.group,title=_ref1.title,avatar=_ref1.avatar,slug=_ref1.slug,roles=_ref.roles,admin=_ref.admin
roleClasses=roles.map(function(role){return"role-"+role}).join(" ")
this.setClass("role "+roleClasses)
this.switchLink=new CustomLinkView({title:title,href:"/"+(slug===KD.defaultSlug?"":slug+"/")+"Activity",target:slug,icon:{cssClass:"new-page",placement:"right",tooltip:{title:"Opens in a new browser window.",delayIn:300}}})
this.adminLink=new CustomLinkView({title:"",href:"/"+(slug===KD.defaultSlug?"":slug+"/")+"Dashboard",target:slug,cssClass:"fr",iconOnly:!0,icon:{cssClass:"dashboard-page",placement:"right",tooltip:{title:"Opens admin dashboard in new browser window.",delayIn:300}}})
admin||this.adminLink.hide()}__extends(PopupGroupListItem,_super)
PopupGroupListItem.prototype.viewAppended=JView.prototype.viewAppended
PopupGroupListItem.prototype.pistachio=function(){return"<div class='right-overflow'>\n  {{> this.switchLink}}\n  {{> this.adminLink}}\n</div>"}
return PopupGroupListItem}(KDListItemView)
PopupGroupListItemPending=function(_super){function PopupGroupListItemPending(options){var group,_this=this
null==options&&(options={})
PopupGroupListItemPending.__super__.constructor.apply(this,arguments)
group=this.getData().group
this.setClass("role pending")
this.acceptButton=new KDButtonView({style:"clean-gray",title:"Accept Invitation",icon:!0,iconOnly:!0,iconClass:"accept",tooltip:{title:"Accept Invitation"},callback:function(){return KD.whoami().acceptInvitation(group,function(err){if(err)return warn(err)
_this.destroy()
_this.parent.emit("PendingCountDecreased")
return _this.parent.emit("UpdateGroupList")})}})
this.ignoreButton=new KDButtonView({style:"clean-gray",title:"Ignore Invitation",icon:!0,iconOnly:!0,iconClass:"ignore",tooltip:{title:"Ignore Invitation"},callback:function(){return KD.whoami().ignoreInvitation(group,function(err){if(err)return warn(err)
new KDNotificationView({title:"Ignored!",content:"If you change your mind, you can request access to the group anytime.",duration:2e3})
_this.destroy()
return _this.parent.emit("PendingCountDecreased")})}})}__extends(PopupGroupListItemPending,_super)
PopupGroupListItemPending.prototype.viewAppended=JView.prototype.viewAppended
PopupGroupListItemPending.prototype.pistachio=function(){return"<div class='right-overflow'>\n  <div class=\"buttons\">\n    {{> this.acceptButton}}\n    {{> this.ignoreButton}}\n  </div>\n  {{> this.switchLink}}\n</div>"}
return PopupGroupListItemPending}(PopupGroupListItem)

var AvatarAreaIconLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarAreaIconLink=function(_super){function AvatarAreaIconLink(options,data){options=$.extend({tagName:"a",partial:"<span class='count'>\n  <cite></cite>\n</span>\n<span class='icon'></span>",attributes:{href:"#"}},options)
AvatarAreaIconLink.__super__.constructor.call(this,options,data)
this.count=0}__extends(AvatarAreaIconLink,_super)
AvatarAreaIconLink.prototype.updateCount=function(newCount){null==newCount&&(newCount=0)
this.$(".count cite").text(newCount)
this.count=newCount
return 0===newCount?this.$(".count").removeClass("in"):this.$(".count").addClass("in")}
AvatarAreaIconLink.prototype.click=function(event){var popup
event.preventDefault()
event.stopPropagation()
popup=this.getDelegate()
return popup.show()}
return AvatarAreaIconLink}(KDCustomHTMLView)

var AvatarAreaIconMenu,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarAreaIconMenu=function(_super){function AvatarAreaIconMenu(){AvatarAreaIconMenu.__super__.constructor.apply(this,arguments)
this.setClass("account-menu")
this.notificationsPopup=new AvatarPopupNotifications({cssClass:"notifications"})
this.messagesPopup=new AvatarPopupMessages({cssClass:"messages"})
this.notificationsIcon=new AvatarAreaIconLink({cssClass:"notifications acc-dropdown-icon",attributes:{title:"Notifications"},delegate:this.notificationsPopup})
this.messagesIcon=new AvatarAreaIconLink({cssClass:"messages acc-dropdown-icon",testPath:"avatararea-messages-icon",attributes:{title:"Messages"},delegate:this.messagesPopup})}__extends(AvatarAreaIconMenu,_super)
AvatarAreaIconMenu.prototype.pistachio=function(){return"{{> this.messagesIcon}}\n{{> this.notificationsIcon}}"}
AvatarAreaIconMenu.prototype.viewAppended=function(){var mainView
AvatarAreaIconMenu.__super__.viewAppended.apply(this,arguments)
mainView=KD.getSingleton("mainView")
mainView.addSubView(this.notificationsPopup)
mainView.addSubView(this.messagesPopup)
return this.attachListeners()}
AvatarAreaIconMenu.prototype.attachListeners=function(){var _this=this
KD.getSingleton("notificationController").on("NotificationHasArrived",function(_arg){var event
event=_arg.event
return _this.notificationsPopup.listController.fetchNotificationTeasers(function(notifications){_this.notificationsPopup.noNotification.hide()
_this.notificationsPopup.listController.removeAllItems()
return _this.notificationsPopup.listController.instantiateListItems(notifications)})})
this.notificationsPopup.listController.on("NotificationCountDidChange",function(count){_this.utils.killWait(_this.notificationsPopup.loaderTimeout)
count>0?_this.notificationsPopup.noNotification.hide():_this.notificationsPopup.noNotification.show()
return _this.notificationsIcon.updateCount(count)})
return this.messagesPopup.listController.on("MessageCountDidChange",function(count){count>0?_this.messagesPopup.noMessage.hide():_this.messagesPopup.noMessage.show()
return _this.messagesIcon.updateCount(count)})}
AvatarAreaIconMenu.prototype.accountChanged=function(){var messagesPopup,notificationsPopup
notificationsPopup=this.notificationsPopup,messagesPopup=this.messagesPopup
messagesPopup.listController.removeAllItems()
notificationsPopup.listController.removeAllItems()
if(KD.isLoggedIn()){notificationsPopup.listController.fetchNotificationTeasers(function(teasers){return notificationsPopup.listController.instantiateListItems(teasers)})
return messagesPopup.listController.fetchMessages()}}
return AvatarAreaIconMenu}(JView)

var AvatarPopupMessages,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarPopupMessages=function(_super){function AvatarPopupMessages(){this.notLoggedInMessage="Login required to see messages"
AvatarPopupMessages.__super__.constructor.apply(this,arguments)}__extends(AvatarPopupMessages,_super)
AvatarPopupMessages.prototype.viewAppended=function(){var _this=this
AvatarPopupMessages.__super__.viewAppended.apply(this,arguments)
this._popupList=new PopupList({itemClass:PopupMessageListItem})
this.listController=new MessagesListController({view:this._popupList,maxItems:5})
KD.getSingleton("notificationController").on("NewMessageArrived",function(){return _this.listController.fetchMessages()})
this.listController.on("AvatarPopupShouldBeHidden",this.bound("hide"))
this.avatarPopupContent.addSubView(this.noMessage=new KDView({height:"auto",cssClass:"sublink top hidden",partial:"You have no new messages."}))
this.avatarPopupContent.addSubView(this.listController.getView())
return this.avatarPopupContent.addSubView(new KDView({height:"auto",cssClass:"sublink",partial:"<a href='#'>See all messages...</a>",click:function(){var appManager
appManager=KD.getSingleton("appManager")
appManager.open("Inbox")
appManager.tell("Inbox","goToMessages")
return _this.hide()}}))}
AvatarPopupMessages.prototype.show=function(){AvatarPopupMessages.__super__.show.apply(this,arguments)
return this.listController.fetchMessages()}
return AvatarPopupMessages}(AvatarPopup)

var AvatarPopupNotifications,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarPopupNotifications=function(_super){function AvatarPopupNotifications(){this.notLoggedInMessage="Login required to see notifications"
AvatarPopupNotifications.__super__.constructor.apply(this,arguments)}__extends(AvatarPopupNotifications,_super)
AvatarPopupNotifications.prototype.viewAppended=function(){var _this=this
AvatarPopupNotifications.__super__.viewAppended.apply(this,arguments)
this._popupList=new PopupList({itemClass:PopupNotificationListItem})
this.listController=new MessagesListController({view:this._popupList,maxItems:5})
this.listController.on("AvatarPopupShouldBeHidden",this.bound("hide"))
this.avatarPopupContent.addSubView(this.noNotification=new KDView({height:"auto",cssClass:"sublink top hidden",partial:"You have no new notifications."}))
this.avatarPopupContent.addSubView(this.listController.getView())
return this.avatarPopupContent.addSubView(new KDView({height:"auto",cssClass:"sublink",partial:"<a href='#'>View all of your activity notifications...</a>",click:function(){var appManager
appManager=KD.getSingleton("appManager")
appManager.open("Inbox")
appManager.tell("Inbox","goToNotifications")
return _this.hide()}}))}
AvatarPopupNotifications.prototype.hide=function(){var _this=this
KD.isLoggedIn()&&KD.whoami().glanceActivities(function(){var item,_i,_len,_ref
_ref=_this.listController.itemsOrdered
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
item.unsetClass("unread")}_this.noNotification.show()
return _this.listController.emit("NotificationCountDidChange",0)})
return AvatarPopupNotifications.__super__.hide.apply(this,arguments)}
return AvatarPopupNotifications}(AvatarPopup)

var PopupMessageListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PopupMessageListItem=function(_super){function PopupMessageListItem(options,data){var group
options=$.extend({tagName:"li"},options)
PopupMessageListItem.__super__.constructor.call(this,options,data)
this.initializeReadState()
data.participants||(group={})
group||(group=data.participants.map(function(participant){return{constructorName:participant.sourceName,id:participant.sourceId}}))
this.participants=new ProfileTextGroup({group:group})
this.avatar=new AvatarStaticView({size:{width:40,height:40},origin:group[0]})}__extends(PopupMessageListItem,_super)
PopupMessageListItem.prototype.initializeReadState=function(){return this.getData().getFlagValue("read")?this.unsetClass("unread"):this.setClass("unread")}
PopupMessageListItem.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
PopupMessageListItem.prototype.teaser=function(text){return __utils.shortenText(text,{minLength:40,maxLength:70})||""}
PopupMessageListItem.prototype.click=function(){var appManager,popupList
appManager=KD.getSingleton("appManager")
appManager.open("Inbox")
appManager.tell("Inbox","goToMessages",this)
popupList=this.getDelegate()
return popupList.emit("AvatarPopupShouldBeHidden")}
PopupMessageListItem.prototype.pistachio=function(){return"<span class='avatar'>{{> this.avatar}}</span>\n<div class='right-overflow'>\n  <a href='#'>{{#(subject) || '(No title)'}}</a><br/>\n  {{this.teaser(#(body))}}\n  <footer>\n    <time>{{> this.participants}} {{$.timeago(#(meta.createdAt))}}</time>\n  </footer>\n</div>"}
return PopupMessageListItem}(KDListItemView)

var PopupNotificationListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PopupNotificationListItem=function(_super){function PopupNotificationListItem(options,data){null==options&&(options={})
options.tagName||(options.tagName="li")
options.linkGroupClass||(options.linkGroupClass=LinkGroup)
options.avatarClass||(options.avatarClass=AvatarView)
PopupNotificationListItem.__super__.constructor.call(this,options,data)
this.initializeReadState()}__extends(PopupNotificationListItem,_super)
PopupNotificationListItem.prototype.initializeReadState=function(){return this.getData().getFlagValue("glanced")?this.unsetClass("unread"):this.setClass("unread")}
PopupNotificationListItem.prototype.pistachio=function(){return"<span class='icon notification-type'></span>\n<span class='avatar'>{{> this.avatar}}</span>\n<div class='right-overflow'>\n  <p>{{> this.participants}} {{this.getActionPhrase(#(dummy))}} {{this.getActivityPlot(#(dummy))}} {{> this.interactedGroups}}</p>\n  <footer>\n    <time>{{$.timeago(this.getLatestTimeStamp(#(dummy)))}}</time>\n  </footer>\n</div>"}
PopupNotificationListItem.prototype.click=function(){var popupList
popupList=this.getDelegate()
popupList.emit("AvatarPopupShouldBeHidden")
return PopupNotificationListItem.__super__.click.apply(this,arguments)}
return PopupNotificationListItem}(NotificationListItem)

var AvatarPopupShareStatus,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarPopupShareStatus=function(_super){function AvatarPopupShareStatus(){_ref=AvatarPopupShareStatus.__super__.constructor.apply(this,arguments)
return _ref}__extends(AvatarPopupShareStatus,_super)
AvatarPopupShareStatus.prototype.viewAppended=function(){var name,_this=this
AvatarPopupShareStatus.__super__.viewAppended.call(this)
this.loader=new KDLoaderView({cssClass:"avatar-popup-status-loader",size:{width:30},loaderOptions:{color:"#ff9200",shape:"spiral",diameter:30,density:30,range:.4,speed:1,FPS:24}})
this.avatarPopupContent.addSubView(this.loader)
name=KD.utils.getFullnameFromAccount(KD.whoami(),!0)
return this.avatarPopupContent.addSubView(this.statusField=new KDHitEnterInputView({type:"textarea",validate:{rules:{required:!0}},placeholder:"What's new, "+name+"?",callback:function(status){return _this.updateStatus(status)}}))}
AvatarPopupShareStatus.prototype.updateStatus=function(status){var _this=this
this.loader.show()
return KD.remote.api.JStatusUpdate.create({body:status},function(err,reply){if(err){new KDNotificationView({type:"mini",title:"There was an error, try again later!"})
_this.loader.hide()
return _this.hide()}KD.getSingleton("appManager").tell("Activity","ownActivityArrived",reply)
new KDNotificationView({type:"growl",cssClass:"mini",title:"Message posted!",duration:2e3})
_this.statusField.setValue("")
_this.loader.hide()
return _this.hide()})}
return AvatarPopupShareStatus}(AvatarPopup)

var GroupData,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupData=function(_super){function GroupData(){_ref=GroupData.__super__.constructor.apply(this,arguments)
return _ref}__extends(GroupData,_super)
GroupData.prototype.getAt=function(path){return JsPath.getAt(this.data,path)}
GroupData.prototype.setGroup=function(group){this.data=group
return this.emit("update")}
return GroupData}(KDEventEmitter)

var AppSettingsMenuButton,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppSettingsMenuButton=function(_super){function AppSettingsMenuButton(options,data){var _this=this
null==options&&(options={})
options.cssClass="app-settings-menu"
options.iconOnly=!0
options.callback=function(event){var menu,menuItems
menu=_this.getData()
if(menu.items){_this.menuWidth=menu.width||172
menuItems=menu.items.filter(function(item){var childItems,customView,menuWithoutChilds,parents,response,_ref
if(item.parentId){parents=_.filter(menu.items,function(menuItem){return menuItem.id===item.parentId})
parents.forEach(function(parentItem){return parentItem.children||(parentItem.children=[])})}if(item.condition){response=item.condition(getVisibleView())
if(!response)return}item.callback=function(contextmenu){var view
view=getVisibleView()
null!=view&&view.emit(""+item.eventName+"MenuItemClicked",item.eventName,item,contextmenu,_this.offset)
return item.eventName?_this.contextMenu.destroy():void 0}
if(0===(null!=(_ref=item.title)?_ref.indexOf("customView"):void 0)){customView=getCustomMenuView(item,_this)
if(customView instanceof KDView)item.view=customView
else{childItems=JContextMenuTreeViewController.convertToArray(customView,item.parentId)
menuWithoutChilds=_.filter(menu.items,function(menuItem){return menuItem.parentId!==item.parentId})
menu.items=menuWithoutChilds.concat(childItems)}}return item})
return _this.createMenu(event,menuItems)}}
AppSettingsMenuButton.__super__.constructor.call(this,options,data)}var getCustomMenuView,getVisibleView
__extends(AppSettingsMenuButton,_super)
getVisibleView=function(){var mainTabView,view,_ref
mainTabView=KD.getSingleton("mainView").mainTabView
view=null!=(_ref=mainTabView.activePane)?_ref.mainView:void 0
return view}
getCustomMenuView=function(item,obj){var customMenu,view,_name
view=getVisibleView()
item.type="customView"
return customMenu="function"==typeof view[_name="get"+item.title.replace(/^customView/,"")+"MenuView"]?view[_name](item,obj):void 0}
AppSettingsMenuButton.prototype.createMenu=function(event,menu){var _this=this
this.offset=this.$().offset()
this.contextMenu=new JContextMenu({cssClass:"app-settings",delegate:this,x:this.offset.left-this.menuWidth-3,y:this.offset.top-6,arrow:{placement:"right",margin:5}},menu)
return this.contextMenu.on("viewAppended",function(){return _this.menuWidth>172?_this.contextMenu.setWidth(_this.menuWidth):void 0})}
return AppSettingsMenuButton}(KDButtonView)

var MainView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MainView=function(_super){function MainView(){_ref=MainView.__super__.constructor.apply(this,arguments)
return _ref}var getStatus,getSticky,removePulsing
__extends(MainView,_super)
MainView.prototype.viewAppended=function(){var _this=this
this.bindPulsingRemove()
this.bindTransitionEnd()
this.createHeader()
this.createDock()
this.createAccountArea()
this.createMainPanels()
this.createMainTabView()
this.setStickyNotification()
return this.utils.defer(function(){return _this.emit("ready")})}
MainView.prototype.bindPulsingRemove=function(){var appManager,router
router=KD.getSingleton("router")
appManager=KD.getSingleton("appManager")
appManager.once("AppCouldntBeCreated",removePulsing)
return appManager.on("AppCreated",function(appInstance){var appEmitsReady,appView,checkedRoute,name,options,routeArr,title
options=appInstance.getOptions()
title=options.title,name=options.name,appEmitsReady=options.appEmitsReady
routeArr=location.pathname.split("/")
routeArr.shift()
checkedRoute="Develop"===routeArr.first?routeArr.last:routeArr.first
if(checkedRoute===name||checkedRoute===title){if(appEmitsReady){appView=appInstance.getView()
return appView.ready(removePulsing)}return removePulsing()}})}
MainView.prototype.addBook=function(){return this.addSubView(new BookView({delegate:this}))}
MainView.prototype._logoutAnimation=function(){var body,turnOffDot,turnOffLine
body=document.body
turnOffLine=new KDCustomHTMLView({cssClass:"turn-off-line"})
turnOffDot=new KDCustomHTMLView({cssClass:"turn-off-dot"})
turnOffLine.appendToDomBody()
turnOffDot.appendToDomBody()
body.style.background="#000"
return this.setClass("logout-tv")}
MainView.prototype.createMainPanels=function(){return this.addSubView(this.panelWrapper=new KDView({tagName:"section",domId:"main-panel-wrapper"}))}
MainView.prototype.createHeader=function(){var entryPoint
entryPoint=KD.config.entryPoint
this.addSubView(this.header=new KDView({tagName:"header",domId:"main-header"}))
this.header.clear()
return this.header.addSubView(this.logo=new KDCustomHTMLView({tagName:"a",domId:"koding-logo",cssClass:"group"===(null!=entryPoint?entryPoint.type:void 0)?"group":"",partial:"<cite></cite>",click:function(event){KD.utils.stopDOMEvent(event)
return KD.isLoggedIn()?KD.getSingleton("router").handleRoute("/Activity",{entryPoint:entryPoint}):location.replace("/")}}))}
MainView.prototype.createDock=function(){return this.header.addSubView(KD.singleton("dock").getView())}
MainView.prototype.createAccountArea=function(){var mc,_this=this
this.header.addSubView(this.accountArea=new KDCustomHTMLView({cssClass:"account-area"}))
if(KD.isLoggedIn())return this.createLoggedInAccountArea()
this.loginLink=new CustomLinkView({domId:"header-sign-in",title:"Login",attributes:{href:"/Login"},click:function(event){KD.utils.stopDOMEvent(event)
return KD.getSingleton("router").handleRoute("/Login")}})
this.accountArea.addSubView(this.loginLink)
mc=KD.getSingleton("mainController")
mc.on("accountChanged.to.loggedIn",function(){_this.loginLink.destroy()
return _this.createLoggedInAccountArea()})}
MainView.prototype.createLoggedInAccountArea=function(){var _this=this
this.accountArea.addSubView(this.accountMenu=new AvatarAreaIconMenu)
this.accountArea.addSubView(this.avatarArea=new AvatarArea({},KD.whoami()))
this.accountArea.addSubView(this.searchIcon=new KDCustomHTMLView({domId:"fatih-launcher",cssClass:"search acc-dropdown-icon",tagName:"a",attributes:{title:"Search",href:"#"},click:function(event){KD.utils.stopDOMEvent(event)
_this.accountArea.setClass("search-open")
_this.searchInput.setFocus()
KD.getSingleton("windowController").addLayer(_this.searchInput)
return _this.searchInput.once("ReceivedClickElsewhere",function(){return _this.searchInput.getValue()?void 0:_this.accountArea.unsetClass("search-open")})},partial:"<span class='icon'></span>"}))
this.accountArea.addSubView(this.searchForm=new KDCustomHTMLView({cssClass:"search-form-container"}))
return this.searchForm.addSubView(this.searchInput=new KDInputView({placeholder:"Search here...",keyup:{esc:function(){return _this.accountArea.unsetClass("search-open")}}}))}
MainView.prototype.createMainTabView=function(){var _this=this
this.appSettingsMenuButton=new AppSettingsMenuButton
this.appSettingsMenuButton.hide()
this.mainTabView=new MainTabView({domId:"main-tab-view",listenToFinder:!0,delegate:this,slidingPanes:!1,hideHandleContainer:!0})
this.mainTabView.on("PaneDidShow",function(){var appManager,appManifest,forntAppName,menu,_ref1,_ref2
appManager=KD.getSingleton("appManager")
if(appManager.getFrontApp()){appManifest=appManager.getFrontAppManifest()
forntAppName=appManager.getFrontApp().getOptions().name
menu=(null!=appManifest?appManifest.menu:void 0)||(null!=(_ref1=KD.getAppOptions(forntAppName))?_ref1.menu:void 0)
Array.isArray(menu)&&(menu={items:menu})
if(null!=menu?null!=(_ref2=menu.items)?_ref2.length:void 0:void 0){_this.appSettingsMenuButton.setData(menu)
return _this.appSettingsMenuButton.show()}return _this.appSettingsMenuButton.hide()}})
this.mainTabView.on("AllPanesClosed",function(){return KD.getSingleton("router").handleRoute("/Activity")})
this.panelWrapper.addSubView(this.mainTabView)
return this.panelWrapper.addSubView(this.appSettingsMenuButton)}
MainView.prototype.createSideBar=function(){var mc
this.sidebar=new Sidebar({domId:"sidebar",delegate:this})
mc=KD.getSingleton("mainController")
mc.sidebarController=new SidebarController({view:this.sidebar})
return this.sidebarPanel.addSubView(this.sidebar)}
MainView.prototype.createChatPanel=function(){this.addSubView(this.chatPanel=new MainChatPanel)
return this.chatHandler=new MainChatHandler}
MainView.prototype.setStickyNotification=function(){var JSystemStatus
if(KD.isLoggedIn()){this.utils.defer(function(){return getStatus()})
JSystemStatus=KD.remote.api.JSystemStatus
return JSystemStatus.on("restartScheduled",function(systemStatus){var sticky,_ref1,_ref2
sticky=null!=(_ref1=KD.getSingleton("windowController"))?_ref1.stickyNotification:void 0
if("active"!==systemStatus.status)return null!=(_ref2=getSticky())?_ref2.emit("restartCanceled"):void 0
systemStatus.on("restartCanceled",function(){var _ref3
return null!=(_ref3=getSticky())?_ref3.emit("restartCanceled"):void 0})
return new GlobalNotification({targetDate:systemStatus.scheduledAt,title:systemStatus.title,content:systemStatus.content,type:systemStatus.type})})}}
MainView.prototype.enableFullscreen=function(){this.setClass("fullscreen no-anim")
this.emit("fullscreen",!0)
return KD.getSingleton("windowController").notifyWindowResizeListeners()}
MainView.prototype.disableFullscreen=function(){this.unsetClass("fullscreen no-anim")
this.emit("fullscreen",!1)
return KD.getSingleton("windowController").notifyWindowResizeListeners()}
MainView.prototype.isFullscreen=function(){return this.hasClass("fullscreen")}
MainView.prototype.toggleFullscreen=function(){return this.isFullscreen()?this.disableFullscreen():this.enableFullscreen()}
getSticky=function(){var _ref1
return null!=(_ref1=KD.getSingleton("windowController"))?_ref1.stickyNotification:void 0}
getStatus=function(){return KD.remote.api.JSystemStatus.getCurrentSystemStatus(function(err,systemStatus){var _ref1
if(err)return"none_scheduled"===err.message?null!=(_ref1=getSticky())?_ref1.emit("restartCanceled"):void 0:log("current system status:",err)
systemStatus.on("restartCanceled",function(){var _ref2
return null!=(_ref2=getSticky())?_ref2.emit("restartCanceled"):void 0})
return new GlobalNotification({targetDate:systemStatus.scheduledAt,title:systemStatus.title,content:systemStatus.content,type:systemStatus.type})})}
removePulsing=function(){var loadingScreen,logo
loadingScreen=document.getElementById("main-loading")
if(loadingScreen){logo=loadingScreen.children[0]
logo.classList.add("out")
return KD.utils.wait(750,function(){loadingScreen.classList.add("out")
return KD.utils.wait(750,function(){var cdc,display,duration,id,mainView,top,_ref1,_results
loadingScreen.parentElement.removeChild(loadingScreen)
if(!KD.isLoggedIn()){cdc=KD.singleton("display")
mainView=KD.getSingleton("mainView")
if(Object.keys(cdc.displays).length){_ref1=cdc.displays
_results=[]
for(id in _ref1)if(__hasProp.call(_ref1,id)){display=_ref1[id]
top=display.$().offset().top
duration=400
KDScrollView.prototype.scrollTo.call(mainView,{top:top,duration:duration})
break}return _results}}})})}}
return MainView}.call(this,KDView)

var MainViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MainViewController=function(_super){function MainViewController(){var appManager,body,display,killRepeat,mainController,mainView,mainViewController,repeat,_ref,_this=this
MainViewController.__super__.constructor.apply(this,arguments)
_ref=KD.utils,repeat=_ref.repeat,killRepeat=_ref.killRepeat
body=document.body
mainView=this.getView()
mainController=KD.singleton("mainController")
appManager=KD.singleton("appManager")
display=KD.singleton("display")
this.registerSingleton("mainViewController",this,!0)
this.registerSingleton("mainView",mainView,!0)
warn("FIXME Add tell to Login app ~ GG @ kodingrouter (if needed)")
appManager.on("AppIsBeingShown",function(controller){return _this.setBodyClass(KD.utils.slugify(controller.getOption("name")))})
display.on("ContentDisplayWantsToBeShown",function(){var type
type=null
return function(view){return(type=view.getOption("type"))?_this.setBodyClass(type):void 0}}())
mainController.on("ShowInstructionsBook",function(index){var book
book=mainView.addBook()
book.fillPage(index)
return book.checkBoundaries()})
mainController.on("ToggleChatPanel",function(){return mainView.chatPanel.toggle()})
KD.checkFlag("super-admin")?KDView.setElementClass(body,"add","super"):KDView.setElementClass(body,"remove","super")
mainViewController=this
window.onscroll=function(){var currentHeight,lastScroll,threshold
threshold=50
lastScroll=0
currentHeight=0
return function(){var current,el,scrollHeight,scrollTop,_ref1
el=document.body
scrollHeight=el.scrollHeight,scrollTop=el.scrollTop
current=scrollTop+window.innerHeight
if(current>scrollHeight-threshold){if(lastScroll>0)return
null!=(_ref1=appManager.getFrontApp())&&_ref1.emit("LazyLoadThresholdReached")
lastScroll=current
currentHeight=scrollHeight}else lastScroll>current&&(lastScroll=0)
return scrollHeight!==currentHeight?lastScroll=0:void 0}}()}__extends(MainViewController,_super)
MainViewController.prototype.setBodyClass=function(){var previousClass
previousClass=null
return function(name){var body
body=document.body
previousClass&&KDView.setElementClass(body,"remove",previousClass)
KDView.setElementClass(body,"add",name)
return previousClass=name}}()
MainViewController.prototype.loadView=function(mainView){var _this=this
return mainView.mainTabView.on("MainTabPaneShown",function(pane){return _this.mainTabPaneChanged(mainView,pane)})}
MainViewController.prototype.mainTabPaneChanged=function(mainView,pane){var app,appManager,mainTabView,navController,title
appManager=KD.getSingleton("appManager")
app=appManager.getFrontApp()
mainTabView=mainView.mainTabView
navController=KD.singleton("dock").navController
pane?this.setViewState(pane.getOptions()):mainTabView.getActivePane().show()
title=null!=app?app.getOption("navItem").title:void 0
return title?navController.selectItemByName(title):navController.deselectAllItems()}
MainViewController.prototype.setViewState=function(){return function(options){var behavior,body,html,mainTabView,mainView,name,o,_ref,_ref1
null==options&&(options={})
behavior=options.behavior,name=options.name
body=document.body
html=document.getElementsByTagName("html")[0]
mainView=this.getView()
mainTabView=mainView.mainTabView
o={name:name}
KDView.setElementClass(html,"remove","app")
switch(behavior){case"hideTabs":o.hideTabs=!0
o.type="social"
break
case"application":o.hideTabs=!1
o.type="develop"
KDView.setElementClass(html,"add","app")
break
default:o.hideTabs=!1
o.type="social"}this.emit("UILayoutNeedsToChange",o)
KDView.setElementClass(body,"remove","intro")
mainView.unsetClass("home")
null!=(_ref=KD.introView)&&_ref.unsetClass("in")
return null!=(_ref1=KD.introView)?_ref1.setClass("out"):void 0}}()
return MainViewController}(KDViewController)

var DockController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DockController=function(_super){function DockController(options,data){var mainController,_this=this
null==options&&(options={})
options.view||(options.view=new KDCustomHTMLView({domId:"dock"}))
DockController.__super__.constructor.call(this,options,data)
this.storage=new AppStorage("Dock","1.0")
this.navController=new MainNavController({view:new NavigationList({domId:"main-nav",testPath:"navigation-list",type:"navigation",itemClass:NavigationLink,testPath:"navigation-list"}),wrapper:!1,scrollView:!1},{id:"navigation",title:"navigation",items:[]})
this.storage.fetchStorage(function(){var ourItem,ourNavItems,ourNavObj,usersItem,usersNavItems,usersNavObj,_i,_j,_len,_len1
usersNavItems=_this.storage.getValue("navItems")
ourNavItems=defaultItems
ourNavObj=createHash(ourNavItems)
KD.setNavItems(ourNavItems)
if(!usersNavItems){_this.navController.reset()
log(ourNavItems,"ready")
return _this.emit("ready")}usersNavObj=createHash(usersNavItems)
for(_i=0,_len=ourNavItems.length;_len>_i;_i++){ourItem=ourNavItems[_i]
if(usersItem=usersNavObj[ourItem.title]){log("changing order for:",ourItem.title)
ourItem.order=usersItem.order}}for(_j=0,_len1=usersNavItems.length;_len1>_j;_j++){usersItem=usersNavItems[_j]
ourNavObj[usersItem.title]||KD.registerNavItem(usersItem)}KD.setNavItems(KD.getNavItems())
_this.navController.reset()
return _this.emit("ready")})
mainController=KD.getSingleton("mainController")
mainController.ready(this.bound("accountChanged"))}var createHash,defaultItems
__extends(DockController,_super)
defaultItems=[{title:"Activity",path:"/Activity",order:10,type:""},{title:"Topics",path:"/Topics",order:20,type:""},{title:"Terminal",path:"/Terminal",order:30,type:""},{title:"Editor",path:"/Ace",order:40,type:""},{title:"Apps",path:"/Apps",order:50,type:""}]
createHash=function(arr){var hash
hash={}
arr.forEach(function(item){return hash[item.title]=item})
return hash}
DockController.prototype.setItemOrder=function(item,order){null==order&&(order=0)
item.order=order
return KD.setNavItems(KD.getNavItems())}
DockController.prototype.addItem=function(item){KD.registerNavItem(item)
return KD.setNavItems(KD.getNavItems())}
DockController.prototype.removeItem=function(item){var index
return(index=KD.getNavItems().indexOf(item>-1))?KD.getNavItems().splice(index,1):void 0}
DockController.prototype.accountChanged=function(){return this.navController.reset()}
DockController.prototype.loadView=function(dock){var _this=this
return this.ready(function(){return dock.addSubView(_this.navController.getView())})}
return DockController}(KDViewController)

var GroupsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
GroupsController=function(_super){function GroupsController(options,data){null==options&&(options={})
GroupsController.__super__.constructor.call(this,options,data)
this.isReady=!1
this.utils.defer(this.bound("init"))}__extends(GroupsController,_super)
GroupsController.prototype.init=function(){var entryPoint,mainController,router
mainController=KD.getSingleton("mainController")
router=KD.getSingleton("router")
entryPoint=KD.config.entryPoint
this.groups={}
this.currentGroupData=new GroupData
return mainController.on("NavigationLinkTitleClick",function(pageInfo){return pageInfo.path?pageInfo.topLevel?router.handleRoute(""+pageInfo.path):router.handleRoute(""+pageInfo.path,{entryPoint:entryPoint}):void 0})}
GroupsController.prototype.getCurrentGroup=function(){if(Array.isArray(this.currentGroupData.data))throw"FIXME: array should never be passed"
return this.currentGroupData.data}
GroupsController.prototype.openGroupChannel=function(group,callback){null==callback&&(callback=function(){})
this.groupChannel=KD.remote.subscribe("group."+group.slug,{serviceType:"group",group:group.slug,isExclusive:!0})
this.forwardEvent(this.groupChannel,"MemberJoinedGroup")
this.forwardEvent(this.groupChannel,"FollowHappened")
return this.groupChannel.once("setSecretNames",callback)}
GroupsController.prototype.changeGroup=function(groupName,callback){var oldGroupName,_this=this
null==groupName&&(groupName="")
null==callback&&(callback=function(){})
groupName||(groupName="koding")
if(this.currentGroupName===groupName)return callback()
oldGroupName=this.currentGroupName
this.currentGroupName=groupName
return groupName!==oldGroupName?KD.remote.cacheable(groupName,function(err,models){var group
if(err)return callback(err)
if(null!=models){group=models[0]
if("JGroup"!==group.bongo_.constructorName)return _this.isReady=!0
_this.setGroup(groupName)
_this.currentGroupData.setGroup(group)
_this.isReady=!0
callback(null,groupName,group)
_this.emit("GroupChanged",groupName,group)
return _this.openGroupChannel(group,function(){return _this.emit("GroupChannelReady")})}}):void 0}
GroupsController.prototype.getUserArea=function(){var _ref,_ref1
return null!=(_ref=this.userArea)?_ref:{group:"group"===(null!=(_ref1=KD.config.entryPoint)?_ref1.type:void 0)?KD.config.entryPoint.slug:KD.getSingleton("groupsController").currentGroupName}}
GroupsController.prototype.setUserArea=function(userArea){return this.userArea=userArea}
GroupsController.prototype.getGroupSlug=function(){return this.currentGroupName}
GroupsController.prototype.setGroup=function(groupName){this.currentGroupName=groupName
return this.setUserArea({group:groupName,user:KD.whoami().profile.nickname})}
GroupsController.prototype.joinGroup=function(group,callback){return group.join(function(err,response){if(!err){callback(err,response)
KD.track("Groups","JoinedGroup",group.slug)
return KD.getSingleton("mainController").emit("JoinedGroup")}})}
GroupsController.prototype.acceptInvitation=function(group,callback){var _this=this
return KD.whoami().acceptInvitation(group,function(err,res){var mainController
mainController=KD.getSingleton("mainController")
mainController.once("AccountChanged",callback.bind(_this,err,res))
return mainController.accountChanged(KD.whoami())})}
GroupsController.prototype.ignoreInvitation=function(group,callback){return KD.whoami().ignoreInvitation(group,callback)}
GroupsController.prototype.cancelGroupRequest=function(group,callback){return KD.whoami().cancelRequest(group,callback)}
GroupsController.prototype.cancelMembershipPolicyChange=function(policy,membershipPolicyView){return membershipPolicyView.enableInvitations.setValue(policy.invitationsEnabled)}
GroupsController.prototype.updateMembershipPolicy=function(group,policy,formData){return group.modifyMembershipPolicy(formData,function(err){if(!err){policy.emit("MembershipPolicyChangeSaved")
new KDNotificationView({title:"Membership policy has been updated."})}return KD.showError(err)})}
return GroupsController}(KDController)

var MainController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
MainController=function(_super){function MainController(options,data){null==options&&(options={})
options.failWait=1e4
MainController.__super__.constructor.call(this,options,data)
this.appStorages={}
this.createSingletons()
this.setFailTimer()
this.attachListeners()
this.introductionTooltipController=new IntroductionTooltipController}var connectedState
__extends(MainController,_super)
connectedState={connected:!1}
MainController.prototype.createSingletons=function(){var appManager,router,_this=this
KD.registerSingleton("mainController",this)
KD.registerSingleton("appManager",appManager=new ApplicationManager)
KD.registerSingleton("notificationController",new NotificationController)
KD.registerSingleton("linkController",new LinkController)
KD.registerSingleton("display",new ContentDisplayController)
KD.registerSingleton("kiteController",new KiteController)
KD.registerSingleton("router",router=new KodingRouter)
KD.registerSingleton("localStorageController",new LocalStorageController)
KD.registerSingleton("oauthController",new OAuthController)
KD.registerSingleton("groupsController",new GroupsController)
KD.registerSingleton("vmController",new VirtualizationController)
return this.ready(function(){router.listen()
KD.registerSingleton("activityController",new ActivityController)
KD.registerSingleton("appStorageController",new AppStorageController)
KD.registerSingleton("kodingAppsController",new KodingAppsController)
KD.registerSingleton("kontrol",new Kontrol)
_this.showInstructionsBook()
_this.emit("AppIsReady")
return console.timeEnd("Koding.com loaded")})}
MainController.prototype.accountChanged=function(account,firstLoad){var _this=this
null==firstLoad&&(firstLoad=!1)
this.userAccount=account
connectedState.connected=!0
return account.fetchMyPermissionsAndRoles(function(err,permissions,roles){var eventPrefix,eventSuffix
if(err)return warn(err)
KD.config.roles=roles
KD.config.permissions=permissions
_this.ready(_this.emit.bind(_this,"AccountChanged",account,firstLoad))
_this.mainViewController||_this.createMainViewController()
_this.emit("ready")
eventPrefix=firstLoad?"pageLoaded.as":"accountChanged.to"
eventSuffix=_this.isUserLoggedIn()?"loggedIn":"loggedOut"
return _this.emit(""+eventPrefix+"."+eventSuffix,account,connectedState,firstLoad)})}
MainController.prototype.createMainViewController=function(){var mainView
KD.registerSingleton("dock",new DockController)
this.mainViewController=new MainViewController({view:mainView=new MainView({domId:"kdmaincontainer"})})
return mainView.appendToDomBody()}
MainController.prototype.doLogout=function(){var mainView,storage
mainView=KD.getSingleton("mainView")
KD.logout()
storage=new LocalStorage("Koding")
return KD.remote.api.JUser.logout(function(err,account,replacementToken){mainView._logoutAnimation()
return KD.utils.wait(1e3,function(){replacementToken&&$.cookie("clientId",replacementToken)
storage.setValue("loggingOut","1")
return location.reload()})})}
MainController.prototype.attachListeners=function(){var wc,_this=this
wc=this.getSingleton("windowController")
this.utils.wait(15e3,function(){var _ref
return null!=(_ref=KD.remote.api)?_ref.JSystemStatus.on("forceReload",function(){window.removeEventListener("beforeunload",wc.bound("beforeUnload"))
return location.reload()}):void 0})
return this.utils.repeat(3e3,function(cookie){return function(){var cookieExists,cookieMatches
cookieExists=null!=cookie
cookieMatches=cookie===$.cookie("clientId")
cookie=$.cookie("clientId")
if(cookieExists&&!cookieMatches){if(_this.isLoggingIn()===!0)return _this.isLoggingIn(!1)
window.removeEventListener("beforeunload",wc.bound("beforeUnload"))
_this.emit("clientIdChanged")
return _this.utils.defer(function(){var firstRoute
firstRoute=KD.getSingleton("router").visitedRoutes.first
firstRoute&&/^\/Verify/.test(firstRoute)&&(firstRoute="/")
return window.location.pathname=firstRoute||"/"})}}}($.cookie("clientId")))}
MainController.prototype.setVisitor=function(visitor){return this.visitor=visitor}
MainController.prototype.getVisitor=function(){return this.visitor}
MainController.prototype.getAccount=function(){return KD.whoami()}
MainController.prototype.isUserLoggedIn=function(){return KD.isLoggedIn()}
MainController.prototype.isLoggingIn=function(isLoggingIn){var storage,_ref
storage=new LocalStorage("Koding")
if("1"===storage.getValue("loggingOut")){storage.unsetKey("loggingOut")
return!0}return null!=isLoggingIn?this._isLoggingIn=isLoggingIn:null!=(_ref=this._isLoggingIn)?_ref:!1}
MainController.prototype.showInstructionsBook=function(){var _this=this
if($.cookie("newRegister")){this.emit("ShowInstructionsBook",9)
return $.cookie("newRegister",{erase:!0})}return this.isUserLoggedIn()?BookView.prototype.getNewPages(function(pages){if(pages.length){BookView.navigateNewPages=!0
return _this.emit("ShowInstructionsBook",pages.first.index)}}):void 0}
MainController.prototype.setFailTimer=function(){var checkConnectionState,fail,modal
modal=null
fail=function(){return modal=new KDBlockingModalView({title:"Couldn't connect to the backend!",content:"<div class='modalformline'>                     We don't know why, but your browser couldn't reach our server.<br><br>Please try again.                   </div>",height:"auto",overlay:!0,buttons:{"Refresh Now":{style:"modal-clean-red",callback:function(){modal.destroy()
return location.reload(!0)}}}})}
checkConnectionState=function(){return connectedState.connected?void 0:fail()}
return function(){var _this=this
this.utils.wait(this.getOptions().failWait,checkConnectionState)
return this.on("AccountChanged",function(){if(modal){modal.setTitle("Connection Established")
modal.$(".modalformline").html("<b>It just connected</b>, don't worry about this warning.")
modal.buttons["Refresh Now"].destroy()
return _this.utils.wait(2500,function(){return null!=modal?modal.destroy():void 0})}})}}()
return MainController}(KDController)

var KiteChannel
KiteChannel=function(){function KiteChannel(kiteName){return KD.remote.mq.subscribe(this.getName(kiteName))}KiteChannel.prototype.getName=function(kiteName){var nickname,_ref,_ref1,_ref2
nickname=null!=(_ref=null!=(_ref1=KD.whoami())?null!=(_ref2=_ref1.profile)?_ref2.nickname:void 0:void 0)?_ref:"unknown"
return""+Bongo.createId(128)+"."+nickname+".kite-"+kiteName}
return KiteChannel}()
window.KiteChannel=KiteChannel

var ApplicationManager,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1},__slice=[].slice
ApplicationManager=function(_super){function ApplicationManager(){var wc,_this=this
ApplicationManager.__super__.constructor.apply(this,arguments)
this.appControllers={}
this.frontApp=null
this.defaultApps={text:"Ace",video:"Viewer",image:"Viewer",sound:"Viewer"}
this.on("AppIsBeingShown",this.bound("setFrontApp"))
wc=this.getSingleton("windowController")
wc.addUnloadListener("window",function(){var app,safeToUnload,_ref
_ref=_this.appControllers
for(app in _ref)if(__hasProp.call(_ref,app)&&("Ace"===app||"Terminal"===app)){safeToUnload=!1
break}return null!=safeToUnload?safeToUnload:!0})}var manifestsFetched,notification
__extends(ApplicationManager,_super)
manifestsFetched=!1
ApplicationManager.prototype.checkAppAvailability=function(name){null==name&&(name="")
return KD.config.apps[name]&&__indexOf.call(Object.keys(KD.appClasses),name)<0}
ApplicationManager.prototype.open=function(){var createOrShow
createOrShow=function(appOptions,appParams,callback){var appInstance,cb,name
null==appOptions&&(appOptions={})
null==callback&&(callback=noop)
name=null!=appOptions?appOptions.name:void 0
if(!name)return this.handleAppNotFound()
appInstance=this.get(name)
cb=appParams.background||appOptions.background?function(appInst){return KD.utils.defer(function(){return callback(appInst)})}:this.show.bind(this,name,appParams,callback)
return appInstance?cb(appInstance):this.create(name,appParams,cb)}
return function(name,options,callback){var appOptions,appParams,defaultCallback,kodingAppsController,_ref,_this=this
if(!name)return warn("ApplicationManager::open called without an app name!")
"function"==typeof options&&(_ref=[options,callback],callback=_ref[0],options=_ref[1])
options||(options={})
appOptions=KD.getAppOptions(name)
appParams=options.params||{}
appParams.label=name
defaultCallback=createOrShow.bind(this,appOptions,appParams,callback)
kodingAppsController=KD.getSingleton("kodingAppsController")
if(null==(null!=appOptions?appOptions.preCondition:void 0)||options.conditionPassed){if(null==appOptions&&null==options.avoidRecursion)return this.checkAppAvailability(name)?KodingAppsController.putAppScript(name,function(err){return err?warn(err):KD.utils.defer(function(){return _this.open(name,options,callback)})}):this.fetchManifests(name,function(err){options.avoidRecursion=!0
return err?defaultCallback():_this.open(name,options,callback)})
appParams=options.params||{}
if(null!=appOptions?!appOptions.multiple:!0)return defaultCallback()
if(options.forceNew||"forceNew"===appOptions.openWith)return this.create(name,appParams,function(appInstance){return _this.showInstance(appInstance,callback)})
switch(appOptions.openWith){case"lastActive":return defaultCallback()
case"prompt":return defaultCallback()}}else appOptions.preCondition.condition(appParams,function(state,newParams){var params,_base
if(state){options.conditionPassed=!0
newParams&&(options.params=newParams)
return _this.open(name,options,callback)}params=newParams||appParams
return"function"==typeof(_base=appOptions.preCondition).failure?_base.failure(params,callback):void 0})}}()
ApplicationManager.prototype.openFileWithApplication=function(appName,file){var _this=this
return this.open(appName,function(){return _this.utils.defer(function(){return _this.getFrontApp().openFile(file)})})}
ApplicationManager.prototype.fetchManifests=function(appName,callback){return KD.getSingleton("kodingAppsController").fetchApps(function(err,manifests){var manifest,name
manifestsFetched=!0
if(err||!manifests)return"function"==typeof callback?callback(!0):void 0
for(name in manifests)if(__hasProp.call(manifests,name)){manifest=manifests[name]
if(name===appName){err=!1
manifest.route={slug:"/Develop/"+encodeURIComponent(name)}
manifest.behavior||(manifest.behavior="application")
manifest.navItem={title:"Develop"}
null==manifest.thirdParty&&(manifest.thirdParty=!0)
KD.registerAppClass(KodingAppController,manifest)}}return"function"==typeof callback?callback():void 0})}
ApplicationManager.prototype.promptOpenFileWith=function(file){var finderController,treeController,view
finderController=KD.getSingleton("finderController")
treeController=finderController.treeController
view=new KDView({},file)
return treeController.showOpenWithModal(view)}
ApplicationManager.prototype.openFile=function(file){var defaultApp,extension,type
extension=file.getExtension()
type=FSItem.getFileType(extension)
defaultApp=this.defaultApps[extension]
if(defaultApp)return this.openFileWithApplication(defaultApp,file)
switch(type){case"unknown":return this.promptOpenFileWith(file)
case"code":case"text":log("open with a text editor")
return this.open(this.defaultApps.text,function(appController){return appController.openFile(file)})
case"image":return log("open with an image processing app")
case"video":return log("open with a video app")
case"sound":return log("open with a sound app")
case"archive":return log("extract the thing.")}}
ApplicationManager.prototype.tell=function(){var app,cb,command,name,rest
name=arguments[0],command=arguments[1],rest=3<=arguments.length?__slice.call(arguments,2):[]
if(!name)return warn("ApplicationManager::tell called without an app name!")
app=this.get(name)
cb=function(appInstance){return null!=appInstance?"function"==typeof appInstance[command]?appInstance[command].apply(appInstance,rest):void 0:void 0}
return app?this.utils.defer(function(){return cb(app)}):this.create(name,cb)}
ApplicationManager.prototype.create=function(name,params,callback){var AppClass,appInstance,appOptions,_ref,_this=this
callback||(_ref=[params,callback],callback=_ref[0],params=_ref[1])
AppClass=KD.getAppClass(name)
appOptions=$.extend({},!0,KD.getAppOptions(name))
appOptions.params=params
AppClass&&this.register(appInstance=new AppClass(appOptions))
if(appOptions.thirdParty&&KD.getSingleton("kodingAppsController").hasForceUpdate(appInstance)){this.emit("AppCouldntBeCreated",appInstance)
this.utils.defer(function(){return _this.quitByName(appOptions.name,!0)})
return!1}log("AppManager: opening an app",name)
if(this.checkAppAvailability(name)){log("AppManager: couldn't find",name)
return KodingAppsController.putAppScript(name,function(err){log("AppManager: loaded",name)
return err?warn(err):KD.utils.defer(function(){return _this.create(name,params,callback)})})}return this.utils.defer(function(){if(!appInstance)return _this.emit("AppCouldntBeCreated")
_this.emit("AppCreated",appInstance)
appOptions.thirdParty&&KD.getSingleton("kodingAppsController").putAppResources(appInstance,callback)
return"function"==typeof callback?callback(appInstance):void 0})}
ApplicationManager.prototype.show=function(name,appParams,callback){var appInstance,appOptions,appView
appOptions=KD.getAppOptions(name)
appInstance=this.get(name)
appView="function"==typeof appInstance.getView?appInstance.getView():void 0
if(appView){this.emit("AppIsBeingShown",appInstance,appView,appOptions)
"function"==typeof appInstance.appIsShown&&appInstance.appIsShown(appParams)
this.setLastActiveIndex(appInstance)
return this.utils.defer(function(){return"function"==typeof callback?callback(appInstance):void 0})}}
ApplicationManager.prototype.showInstance=function(appInstance,callback){var appOptions,appView
appView=("function"==typeof appInstance.getView?appInstance.getView():void 0)||null
appOptions=KD.getAppOptions(appInstance.getOption("name"))
if(!appOptions.background){this.emit("AppIsBeingShown",appInstance,appView,appOptions)
"function"==typeof appInstance.appIsShown&&appInstance.appIsShown()
this.setLastActiveIndex(appInstance)
return this.utils.defer(function(){return"function"==typeof callback?callback(appInstance):void 0})}}
ApplicationManager.prototype.quit=function(appInstance,callback){var destroyer,view
null==callback&&(callback=noop)
view="function"==typeof appInstance.getView?appInstance.getView():void 0
destroyer=null!=view?view:appInstance
destroyer.destroy()
return callback()}
ApplicationManager.prototype.quitAll=function(){var app,apps,name,_ref,_results
_ref=this.appControllers
_results=[]
for(name in _ref)if(__hasProp.call(_ref,name)){apps=_ref[name]
_results.push(function(){var _i,_len,_ref1,_results1
_ref1=apps.instances
_results1=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){app=_ref1[_i]
_results1.push(this.quit(app))}return _results1}.call(this))}return _results}
ApplicationManager.prototype.quitByName=function(name,closeAllInstances){var appController,instances,_results
null==closeAllInstances&&(closeAllInstances=!0)
appController=this.appControllers[name]
if(appController){if(closeAllInstances){instances=appController.instances
_results=[]
for(;instances.length>0;)_results.push(this.quit(instances.first))
return _results}return this.quit(appController.instances[appController.lastActiveIndex])}}
ApplicationManager.prototype.get=function(name){var apps
return(apps=this.appControllers[name])?apps.instances[apps.lastActiveIndex]||apps.instances.first:null}
ApplicationManager.prototype.getByView=function(view){var appController,appInstance,apps,name,_i,_len,_ref,_ref1,_ref2
appInstance=null
_ref=this.appControllers
for(name in _ref)if(__hasProp.call(_ref,name)){apps=_ref[name]
_ref1=apps.instances
for(_i=0,_len=_ref1.length;_len>_i;_i++){appController=_ref1[_i]
if(view.getId()===("function"==typeof appController.getView?null!=(_ref2=appController.getView())?_ref2.getId():void 0:void 0)){appInstance=appController
break}}if(appInstance)break}return appInstance}
ApplicationManager.prototype.getFrontApp=function(){return this.frontApp}
ApplicationManager.prototype.setFrontApp=function(appInstance){this.setLastActiveIndex(appInstance)
return this.frontApp=appInstance}
ApplicationManager.prototype.getFrontAppManifest=function(){var name
name=this.getFrontApp().getOptions().name
return KD.getAppOptions(name)}
ApplicationManager.prototype.register=function(appInstance){var name,_base
name=appInstance.getOption("name")
null==(_base=this.appControllers)[name]&&(_base[name]={instances:[],lastActiveIndex:null})
this.appControllers[name].instances.push(appInstance)
return this.setListeners(appInstance)}
ApplicationManager.prototype.unregister=function(appInstance){var index,name
name=appInstance.getOption("name")
index=this.appControllers[name].instances.indexOf(appInstance)
if(index>=0){this.appControllers[name].instances.splice(index,1)
if(0===this.appControllers[name].instances.length)return delete this.appControllers[name]}}
ApplicationManager.prototype.createPromptModal=function(appOptions,callback){var i,instance,modal,name,selectOptions
name=appOptions.name
selectOptions=function(){var _i,_len,_ref,_results
_ref=this.appControllers[name].instances
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){instance=_ref[i]
_results.push({title:""+instance.getOption("name")+" ("+(i+1)+")",value:i})}return _results}.call(this)
return modal=new KDModalViewWithForms({title:"Open with:",tabs:{navigable:!1,forms:{openWith:{callback:function(formOutput){var index,openNew
modal.destroy()
index=formOutput.index,openNew=formOutput.openNew
return callback(index,openNew)},fields:{instance:{label:"Instance:",itemClass:KDSelectBox,name:"index",type:"select",defaultValue:selectOptions.first.value,selectOptions:selectOptions},newOne:{label:"Open new app:",itemClass:KDOnOffSwitch,name:"openNew",defaultValue:!1}},buttons:{Open:{cssClass:"modal-clean-green",type:"submit"},Cancel:{cssClass:"modal-cancel",callback:function(){modal.cancel()
return callback(null)}}}}}}})}
ApplicationManager.prototype.setListeners=function(appInstance){var destroyer,view,_this=this
destroyer=(view="function"==typeof appInstance.getView?appInstance.getView():void 0)?view:appInstance
return destroyer.once("KDObjectWillBeDestroyed",function(){_this.unregister(appInstance)
appInstance.emit("AppDidQuit")
return KD.getSingleton("appManager").emit("AppDidQuit",appInstance)})}
ApplicationManager.prototype.setLastActiveIndex=function(appInstance){var index,optionSet
if(appInstance&&(optionSet=this.appControllers[appInstance.getOption("name")])){index=optionSet.instances.indexOf(appInstance)
return optionSet.lastActiveIndex=-1===index?null:index}}
notification=null
ApplicationManager.prototype.notify=function(msg){notification&&notification.destroy()
return notification=new KDNotificationView({title:msg||"Currently disabled!",type:"mini",duration:2500})}
ApplicationManager.prototype.handleAppNotFound=function(){KD.getSingleton("router").handleRoute("/Develop")
return new KDNotificationView({title:"You don't have this app installed!",type:"mini",cssClass:"error",duration:5e3})}
return ApplicationManager}(KDObject)

var AppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppController=function(_super){function AppController(){AppController.__super__.constructor.apply(this,arguments)
this.appStorage=new AppStorage(this.getOption("name"),"1.0")}__extends(AppController,_super)
AppController.prototype.createContentDisplay=function(){return warn("You need to override #createContentDisplay - "+this.constructor.name)}
AppController.prototype.handleQuery=function(query){var _this=this
return this.ready(function(){var _ref
return null!=(_ref=_this.feedController)?"function"==typeof _ref.handleQuery?_ref.handleQuery(query):void 0:void 0})}
return AppController}(KDViewController)

var KodingAppsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KodingAppsController=function(_super){function KodingAppsController(){var mainController,_this=this
KodingAppsController.__super__.constructor.apply(this,arguments)
this._loadedOnce=!1
this.appManager=KD.getSingleton("appManager")
this.vmController=KD.getSingleton("vmController")
mainController=KD.getSingleton("mainController")
this.manifests=KodingAppsController.manifests
this.publishedApps={}
this._fetchQueue=[]
this.appStorage=KD.getSingleton("appStorageController").storage("Finder","1.1")
this.watcher=new AppsWatcher
this.on("UpdateDefaultAppConfig",function(extension,appName){return _this.updateDefaultAppConfig(extension,appName)})
mainController.on("accountChanged.to.loggedIn",this.bound("getPublishedApps"))
this.watcher.on("NewAppIsAdded",function(app,change){var manifest,manifestPath
manifestPath=""+change.file.fullPath+"/manifest.json"
manifest=FSHelper.createFileFromPath(manifestPath)
return manifest.exists(function(err,exists){return exists?_this.fetchAppFromFs(app,function(){return _this.putAppsToAppStorage(null,function(){return _this.emit("UpdateAppData",app)})}):void 0})})
this.watcher.on("AppIsRemoved",function(app){return _this.invalidateDeletedApps([app],!1,function(){return _this.emit("InvalidateApp",app)})})
this.watcher.on("ManifestHasChanged",function(app){return _this.fetchAppFromFs(app,function(){return _this.putAppsToAppStorage(null,function(){return _this.emit("UpdateAppData",app)})})})}var defaultManifest,defaultShortcuts,getManifestFromPath,newAppModal,putStyleSheets,showError
__extends(KodingAppsController,_super)
KD.registerAppClass(KodingAppsController,{name:"KodingAppsController",background:!0})
KodingAppsController.putAppScript=function(name,callback){var app,message,script,style,_ref
null==callback&&(callback=noop)
if(!KD.config.apps[name]){warn(message=""+name+" is not available to run!")
return callback({message:message})}if(_ref=name.capitalize(),__indexOf.call(Object.keys(KD.appClasses),_ref)>=0){warn(""+name+" is already imported")
return callback(null)}app=KD.config.apps[name]
$("head .internal-"+app.identifier).remove()
style=new KDCustomHTMLView({tagName:"link",cssClass:"internal-"+app.identifier,bind:"load",load:function(){return log("Style loaded? for "+name+" # don't trust this ...")},attributes:{rel:"stylesheet",href:app.style}})
$("head")[0].appendChild(style.getElement())
script=new KDCustomHTMLView({tagName:"script",cssClass:"internal-"+app.identifier,bind:"load",load:function(){return callback(null)},attributes:{type:"text/javascript",src:app.script}})
return $("head")[0].appendChild(script.getElement())}
KodingAppsController.manifests={}
KodingAppsController.getManifestFromPath=getManifestFromPath=function(path){var app,folderName,manifest,name,p,_fn,_ref
folderName=function(){var _i,_len,_ref,_results
_ref=path.split("/")
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){p=_ref[_i];/\.kdapp/.test(p)&&_results.push(p)}return _results}()[0]
app=null
if(!folderName)return app
_ref=KodingAppsController.manifests
_fn=function(){return manifest.path.search(folderName)>-1?app=manifest:void 0}
for(name in _ref)if(__hasProp.call(_ref,name)){manifest=_ref[name]
_fn()}return app}
KodingAppsController.prototype.getAppPath=function(manifest,escaped){var path
null==escaped&&(escaped=!1)
path="string"==typeof manifest?manifest:manifest.path
path=/^~/.test(path)?"/home/"+KD.nick()+path.substr(1):path
return escaped?FSHelper.escapeFilePath(path):path.replace(/(\/+)$/,"")}
KodingAppsController.prototype.fetchApps=function(callback){var kb,_this=this
kb=function(manifests){callback(null,manifests)
return _this.watcher._trackedApps=manifests?Object.keys(manifests):[]}
return this.appStorage.ready(function(){var apps,manifests
manifests=_this.getManifests()
apps=Object.keys(manifests)
return apps.length>0?kb(manifests):_this.fetchAppsFromDb(function(err,apps){return err?_this.fetchAppsFromFs(function(err,apps){return err?"function"==typeof callback?callback(err):void 0:kb(apps)}):err?"function"==typeof callback?callback(err):void 0:kb(apps)})})}
KodingAppsController.prototype.fetchAppFromFs=function(appName,cb){var appsPath,manifest,manifests,suffix,_this=this
manifests=this.getManifests()
appsPath="/home/"+KD.nick()+"/Applications/"
suffix=".kdapp/manifest.json"
manifest=FSHelper.createFileFromPath(""+appsPath+appName+suffix)
return manifest.fetchContents(function(err,response){var e
if(err||!response)return cb(null)
try{manifest=JSON.parse(response)
manifests[manifest.name]=manifest}catch(_error){e=_error
warn("Manifest file is broken:",e)
return cb(null)}_this.constructor.manifests=manifests
return cb(null)})}
KodingAppsController.prototype.fetchAppsFromFsHelper=function(apps,callback){var stack,_this=this
stack=[]
apps.forEach(function(app){return stack.push(function(cb){return _this.fetchAppFromFs(app,cb)})})
return async.parallel(stack,callback)}
KodingAppsController.prototype.fetchAppsFromFs=function(cb){var _this=this
cb&&this._fetchQueue.push(cb)
return this._fetchQueue.length>1?void 0:this.watcher.watch(KD.utils.getTimedOutCallback(function(err,files){var apps,callback,_i,_len,_ref
_this._loadedOnce=!0
if(err||!Array.isArray(files||0===files.length)){_this.putAppsToAppStorage({})
_ref=_this._fetchQueue
for(_i=0,_len=_ref.length;_len>_i;_i++){callback=_ref[_i]
callback()}return _this._fetchQueue=[]}apps=_this.filterAppsFromFileList(files)
return _this.fetchAppsFromFsHelper(apps,function(){var _j,_len1,_ref1
_this.putAppsToAppStorage()
_ref1=_this._fetchQueue
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){callback=_ref1[_j]
callback(null,_this.getManifests())}return _this._fetchQueue=[]})},function(){var callback,msg,_i,_len,_ref
warn(msg="Timeout reached for kite request")
KD.isGuest()||KD.logToExternal(msg)
_ref=_this._fetchQueue
for(_i=0,_len=_ref.length;_len>_i;_i++){callback=_ref[_i]
callback()}return _this._fetchQueue=[]}))}
KodingAppsController.prototype.fetchAppsFromDb=function(callback){var _this=this
return this.appStorage.fetchValue("apps",function(apps){return _this.putDefaultShortcutsBack(function(){if(apps&&Object.keys(apps).length>0){_this.constructor.manifests=apps
return callback(null,apps)}return callback(new Error("There are no apps in the app storage."))})})}
KodingAppsController.prototype.syncAppStorageWithFS=function(force,callback){var currentApps,_this=this
null==force&&(force=!1)
null==callback&&(callback=noop)
currentApps=Object.keys(this.getManifests())
return this.watcher.watch(function(err,files){var app,existingApps,newApps,removedApps
if(err)return warn(err)
existingApps=_this.filterAppsFromFileList(files)
newApps=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=existingApps.length;_len>_i;_i++){app=existingApps[_i]
__indexOf.call(currentApps,app)<0&&_results.push(app)}return _results}()||[]
removedApps=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=currentApps.length;_len>_i;_i++){app=currentApps[_i]
__indexOf.call(existingApps,app)<0&&_results.push(app)}return _results}()||[]
_this.invalidateDeletedApps(removedApps,force,function(){var appsToFetch
appsToFetch=force?existingApps:newApps
return _this.fetchAppsFromFsHelper(appsToFetch,function(){return _this.emit("AppsDataChanged",{removedApps:removedApps,newApps:newApps,existingApps:existingApps,force:force})})})
_this._loadedOnce=!0
return"function"==typeof callback?callback():void 0})}
KodingAppsController.prototype.filterAppsFromFileList=function(files){var file
return function(){var _i,_len,_results
_results=[]
for(_i=0,_len=files.length;_len>_i;_i++){file=files[_i];/\.kdapp$/.test(file.name)&&"folder"===file.type&&_results.push(file.name.replace(/\.kdapp$/,""))}return _results}()}
KodingAppsController.prototype.fetchUpdateAvailableApps=function(callback,force){var publishedApps,_this=this
if(this.updateAvailableApps&&!force)return"function"==typeof callback?callback(null,this.updateAvailableApps):void 0
publishedApps=this.publishedApps
this.updateAvailableApps=[]
return this.fetchApps(function(err,apps){var app,appName
for(appName in apps)if(__hasProp.call(apps,appName)){app=apps[appName]
_this.isAppUpdateAvailable(app.name,app.version)&&_this.updateAvailableApps.push(publishedApps[app.name])}return"function"==typeof callback?callback(null,_this.updateAvailableApps):void 0})}
KodingAppsController.prototype.fetchCompiledAppSource=function(manifest,callback){var indexJs
indexJs=FSHelper.createFileFromPath(""+this.getAppPath(manifest)+"/index.js")
return indexJs.fetchContents(callback)}
KodingAppsController.prototype.removeShortcut=function(shortcut,callback){var _this=this
return this.appStorage.fetchValue("shortcuts",function(shortcuts){delete shortcuts[shortcut]
return _this.appStorage.setValue("shortcuts",shortcuts,function(err){return callback(err)})})}
KodingAppsController.prototype.putDefaultShortcutsBack=function(callback){return this.appStorage.setValue("shortcuts",defaultShortcuts,function(err){return"function"==typeof callback?callback(err):void 0})}
KodingAppsController.prototype.putAppsToAppStorage=function(apps,callback){apps||(apps=this.getManifests())
this.constructor.manifests=apps
return this.appStorage.setValue("apps",apps,function(err){return"function"==typeof callback?callback(err):void 0})}
KodingAppsController.prototype.invalidateDeletedApps=function(deletedApps,force,callback){var app,manifests,_i,_len
null==force&&(force=!1)
if(force){this.constructor.manifests={}
return this.putAppsToAppStorage(manifests,callback)}manifests=this.getManifests()
for(_i=0,_len=deletedApps.length;_len>_i;_i++){app=deletedApps[_i]
delete manifests[app]}return deletedApps.length>0?this.putAppsToAppStorage(manifests,callback):callback(null)}
KodingAppsController.prototype.defineApp=function(name,script){return script?KD.registerAppScript(name,script):void 0}
KodingAppsController.prototype.getAppScript=function(manifest,callback){var name,script,_this=this
null==callback&&(callback=noop)
name=manifest.name
return(script=KD.getAppScript(name))?callback(null,script):this.fetchCompiledAppSource(manifest,function(err,script){if(err)return _this.compileApp(name,callback)
_this.defineApp(name,script)
return callback(err,script)})}
KodingAppsController.prototype.getPublishedApps=function(callback){var JApp,appName,appNames,manifest,query,_this=this
appNames=function(){var _ref,_results
_ref=this.getManifests()
_results=[]
for(appName in _ref)if(__hasProp.call(_ref,appName)){manifest=_ref[appName]
_results.push(appName)}return _results}.call(this)||[]
query={"manifest.name":{$in:appNames}}
JApp=KD.remote.api.JApp
return JApp.fetchAllAppsData(query,function(err,apps){var map
_this.publishedApps=map={}
null!=apps&&apps.forEach(function(app){return map[app.manifest.name]=new JApp(app)})
_this.emit("UserAppModelsFetched",map)
return"function"==typeof callback?callback(map):void 0})}
KodingAppsController.prototype.isAppUpdateAvailable=function(appName,appVersion){return this.publishedApps[appName]?this.utils.versionCompare(appVersion,"lt",this.publishedApps[appName].manifest.version):void 0}
KodingAppsController.prototype.getAppUpdateType=function(appName){var app
app=this.publishedApps[appName]
return app?app.manifest.forceUpdate===!0?"required":"available":null}
KodingAppsController.prototype.updateAllApps=function(){var _this=this
return this.fetchUpdateAvailableApps(function(err,apps){var stack
if(err)return warn(err)
stack=[]
delete _this.notification
null!=apps&&apps.forEach(function(app){return stack.push(function(callback){return _this.updateUserApp(app.manifest,callback)})})
return async.series(stack)})}
KodingAppsController.prototype.refreshApps=function(callback){return this.syncAppStorageWithFS(!0,callback)}
KodingAppsController.prototype.updateUserApp=function(manifest,callback){var appName,folder,_this=this
appName=manifest.name
this.notification||(this.notification=new KDNotificationView({type:"mini",title:"Updating "+appName+": Deleting old app files",duration:1e4}))
folder=FSHelper.createFileFromPath(manifest.path,"folder")
return folder.remove(function(err){if(err){_this.notification.setClass("error")
_this.notification.notificationSetTitle("An error occured while updating "+appName+".")
return!1}return _this.refreshApps(function(){_this.notification.notificationSetTitle("Updating "+appName+": Fetching new app details")
return KD.remote.api.JApp.someWithRelationship({"manifest.name":appName},{},function(err,app){_this.notification.notificationSetTitle("Updating "+appName+": Updating app to latest version")
return _this.installApp(app[0],app[0].versions.last,function(){_this.refreshApps()
"function"==typeof callback&&callback()
_this.emit("AnAppHasBeenUpdated")
return _this.notification.notificationSetTitle(""+appName+" has been updated successfully")})})},!0)})}
KodingAppsController.prototype.hasForceUpdate=function(appInstance){var devMode,forceUpdate,hasUpdate,manifest,name,updateAvailable,version
manifest=this.constructor.manifests[appInstance.getOptions().name]
devMode=manifest.devMode,name=manifest.name,version=manifest.version
forceUpdate="required"===this.getAppUpdateType(name)
updateAvailable=this.isAppUpdateAvailable(name,version)
hasUpdate=updateAvailable&&!devMode&&forceUpdate
hasUpdate&&this.showUpdateRequiredModal(manifest)
return hasUpdate}
KodingAppsController.prototype.putAppResources=function(appInstance){var appView,loader,manifest,_this=this
if(appInstance){manifest=appInstance.getOptions()
if(manifest.thirdParty){appView=appInstance.getView()
appView.addSubView(loader=new KDLoaderView({loaderOptions:{color:"#ff9200",speed:2,range:.7,density:60},cssClass:"app-loading",size:{width:128}}))
appView.once("viewAppended",function(){return loader.show()})
putStyleSheets(manifest)
return this.getAppScript(manifest,function(err,appScript){var error,id
if(err)return warn(err)
loader.destroy()
id=appView.getId()
try{return function(appView){return eval('var appView = KD.instances["'+id+'"];\n\n'+appScript)}(appView)}catch(_error){error=_error
return showError(error)}})}}}
KodingAppsController.prototype.publishApp=function(path,callback){var appName,err,manifest,notification,_this=this
if(!KD.checkFlag("app-publisher")&&!KD.checkFlag("super-admin")){err="You are not authorized to publish apps."
log(err)
"function"==typeof callback&&callback(err)
return!1}manifest=getManifestFromPath(path)
appName=manifest.name
notification=new KDNotificationView({overlay:{transparent:!1,destroyOnClick:!1},loader:{color:"#ffffff"},title:"Please wait while we are publishing your app...",followUps:{duration:1e4,title:"We are still working on it. Your app will be published soon..."},duration:12e4})
return this.getAppScript(manifest,function(){var appPath,options
manifest=_this.getManifest(appName)
appPath=_this.getAppPath(manifest)
options={method:"app.publish",withArgs:{appPath:appPath}}
return _this.vmController.run(options,function(err){var jAppData
if(err){warn(err)
notification.destroy()
return"function"==typeof callback?callback(err):void 0}manifest.authorNick=KD.whoami().profile.nickname
jAppData={title:manifest.name||"Application Title",body:manifest.description||"Application description",identifier:manifest.identifier||"com.koding.apps."+__utils.slugify(manifest.name),manifest:manifest}
notification.destroy()
return _this.createApp(jAppData,function(err){if(err){warn(err)
return"function"==typeof callback?callback(err):void 0}_this.appManager.open("Apps")
_this.appManager.tell("Apps","updateApps")
return"function"==typeof callback?callback():void 0})})})}
KodingAppsController.prototype.createApp=function(formData,callback){return KD.remote.api.JApp.create(formData,function(err,app){return"function"==typeof callback?callback(err,app):void 0})}
KodingAppsController.prototype.compileApp=function(name,callback){var compileOnServer,_this=this
compileOnServer=function(app){var appPath,loader
if(!app)return warn(""+name+": No such application!")
appPath=_this.getAppPath(app)
loader=new KDNotificationView({duration:18e3,title:"Compiling "+name+"...",type:"mini"})
return _this.vmController.run("kdc "+appPath,function(err,response){var details,modal,nickname,publishPath
if(err){loader.destroy()
if("exit status 127"===err.message){modal=new ModalViewWithTerminal({title:"Koding app compiler is not installed in your VM.",width:500,overlay:!0,terminal:{hidden:!0},content:"<div class='modalformline'>\n  <p>\n    If you want to install it now, click <strong>Install Compiler</strong> button.\n  </p>\n  <p>\n    <strong>Remember to enter your password when asked.</strong>\n  </p>\n</div>",buttons:{"Install Compiler":{cssClass:"modal-clean-green",callback:function(){return modal.run("sudo npm install -g kdc; echo $?|kdevent;")}}}})
modal.on("terminal.event",function(data){if("0"===data){new KDNotificationView({title:"Installed successfully!"})
return modal.destroy()}return new KDNotificationView({title:"An error occured.",content:"Something went wrong while installing Koding App Compiler. Please try again."})})
"function"==typeof callback&&callback(err)
return}details=response?"<pre>"+response+"</pre>":""
new KDModalView({title:"An error occured while compiling the App!",width:500,overlay:!0,content:"<div class='modalformline'>\n  <p>"+err.message+"</p>\n  "+details+"\n</div>"})
return"function"==typeof callback?callback(err):void 0}nickname=KD.nick()
publishPath="/home/"+nickname+"/Web/.applications"
return _this.vmController.run({method:"fs.createDirectory",withArgs:{path:publishPath,recursive:!0}},function(){var linkFile
loader.notificationSetTitle("Publishing app static files...")
linkFile=""+publishPath+"/"+KD.utils.slugify(name)
return _this.vmController.run("rm "+linkFile+"; ln -s "+appPath+" "+linkFile,function(){loader.notificationSetTitle("Fetching compiled app...")
return _this.fetchCompiledAppSource(app,function(err,res){if(!err){_this.defineApp(name,res)
loader.notificationSetTitle("App compiled successfully")
loader.notificationSetTimer(2e3)}return"function"==typeof callback?callback(err,res):void 0})})})})}
return this.getManifest(name)?compileOnServer(this.getManifest(name)):this.fetchApps(function(err,apps){return compileOnServer(apps[name])})}
KodingAppsController.prototype.getManifests=function(){return this.constructor.manifests}
KodingAppsController.prototype.getManifest=function(appName){return this.constructor.manifests[appName]}
KodingAppsController.prototype.installApp=function(app,version,callback){var _this=this
return KD.requireMembership({onFailMsg:"Login required to install Apps",onFail:function(){return callback(!0)},callback:function(){return _this.fetchApps(function(err,manifests){var _ref
null==manifests&&(manifests={})
KD.showError(err,{KodingError:"Something went wrong while fetching apps"})
if(err)return"function"==typeof callback?callback(err):void 0
if(_ref=app.title,__indexOf.call(Object.keys(manifests),_ref)>=0){new KDNotificationView({type:"mini",title:"App is already installed!"})
return"function"==typeof callback?callback(!0):void 0}if(app.approved===!0||KD.checkFlag("app-publisher"))return app.fetchCreator(function(err,acc){KD.showError(err,{KodingError:"Failed to fetch app creator info"})
if(err)return"function"==typeof callback?callback(err):void 0
KD.mixpanel("User Installed Application",app.manifest.identifier)
return _this.vmController.run({method:"app.install",withArgs:{owner:acc.profile.nickname,identifier:app.manifest.identifier,appPath:_this.getAppPath(app.manifest),version:version}},function(err){if(err){KD.showError(err,{KodingError:"Something wrong with Apps server,\nplease try again later"})
return"function"==typeof callback?callback():void 0}return app.install(function(err){KD.showError(err)
_this.appManager.open("StartTab")
return"function"==typeof callback?callback():void 0})})})
KD.showError("This app is not approved, installation cancelled.")
return"function"==typeof callback?callback(err):void 0})}})}
newAppModal=null
KodingAppsController.prototype.makeNewApp=function(callback){var _this=this
if(newAppModal)return"function"==typeof callback?callback(!0):void 0
newAppModal=new KDModalViewWithForms({title:"Create a new Application",content:" <div class='modalformline'><p>\nPlease select the application type you want to start with.\nAlternatively, you can modify an existing app; all applications are installed under <code>~/Applications</code> folder,\nyou can right click on any of them, go to <b>Applications</b> menu, and click <b>Download source files</b> and start\nreading <code>manifest.json</code>\n</p></div>",overlay:!0,width:400,height:"auto",tabs:{navigable:!0,forms:{form:{buttons:{Create:{cssClass:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){var appPath,manifest,manifestStr,name,type
if(newAppModal.modalTabs.forms.form.inputs.name.validate()){name=newAppModal.modalTabs.forms.form.inputs.name.getValue()
type=newAppModal.modalTabs.forms.form.inputs.type.getValue()
name&&(name=name.replace(/[^a-zA-Z0-9\/\-.]/g,""))
manifestStr=defaultManifest(type,name)
manifest=JSON.parse(manifestStr)
appPath=_this.getAppPath(manifest)
return FSHelper.exists(appPath,null,function(err,exists){if(exists){newAppModal.modalTabs.forms.form.buttons.Create.hideLoader()
return new KDNotificationView({type:"mini",cssClass:"error",title:"App folder with that name is already exists, please choose a new name.",duration:3e3})}return _this.prepareApplication({isBlank:"blank"===type,name:name},function(err){"function"==typeof callback&&callback(err)
newAppModal.modalTabs.forms.form.buttons.Create.hideLoader()
return newAppModal.destroy()})})}newAppModal.modalTabs.forms.form.buttons.Create.hideLoader()}}},fields:{type:{label:"Type",itemClass:KDSelectBox,type:"select",name:"type",defaultValue:"sample",selectOptions:[{title:"Sample Application",value:"sample"},{title:"Blank Application",value:"blank"}]},name:{label:"Name:",name:"name",placeholder:"name your application...",validate:{rules:{regExp:/^[a-z\d]+([-][a-z\d]+)*$/i},messages:{regExp:"For Application name only lowercase letters and numbers are allowed!"}}}}}}}})
return newAppModal.once("KDObjectWillBeDestroyed",function(){newAppModal=null
return"function"==typeof callback?callback(!0):void 0})}
KodingAppsController.prototype._createChangeLog=function(name){var fullName,profile,today
today=(new Date).format("yyyy-mm-dd")
profile=KD.whoami().profile
fullName=KD.utils.getFullnameFromAccount()
return""+today+" "+fullName+" <@"+profile.nickname+">\n\n   * "+name+" (index.coffee): Application created."}
KodingAppsController.prototype.prepareApplication=function(_arg,callback){var appPath,changeLogFile,changeLogStr,isBlank,manifest,manifestFile,manifestStr,name,stack,type,_this=this
isBlank=_arg.isBlank,name=_arg.name
type=isBlank?"blank":"sample"
name=""===name?null:name
name&&(name=name.replace(/[^a-zA-Z0-9\/\-.]/g,""))
manifestStr=defaultManifest(type,name)
changeLogStr=this._createChangeLog(name)
manifest=JSON.parse(manifestStr)
appPath=this.getAppPath(manifest)
stack=[]
manifestFile=FSHelper.createFileFromPath(""+appPath+"/manifest.json")
changeLogFile=FSHelper.createFileFromPath(""+appPath+"/ChangeLog")
stack.push(function(cb){return _this.vmController.run({method:"app.skeleton",withArgs:{type:isBlank?"blank":"sample",appPath:appPath}},cb)})
stack.push(function(cb){return manifestFile.save(manifestStr,cb)})
stack.push(function(cb){return changeLogFile.save(changeLogStr,cb)})
return async.series(stack,function(err,result){err&&warn(err)
return"function"==typeof callback?callback(err,result):void 0})}
KodingAppsController.prototype.downloadAppSource=function(path,callback){var _this=this
return this.fetchApps(function(){var manifest
manifest=getManifestFromPath(path)
if(manifest)return _this.vmController.run({method:"app.download",withArgs:{owner:manifest.authorNick,identifier:manifest.identifier,appPath:_this.getAppPath(manifest),version:manifest.version}},function(err){if(err){warn(err)
return"function"==typeof callback?callback(err):void 0}return"function"==typeof callback?callback(null):void 0})
callback(new KDNotificationView({type:"mini",title:"Please refresh your apps and try again!"}))
return void 0})}
putStyleSheets=function(manifest){var devMode,identifier,name,stylesheets,version
name=manifest.name,devMode=manifest.devMode,version=manifest.version,identifier=manifest.identifier
manifest.source&&(stylesheets=manifest.source.stylesheets)
if(stylesheets){$("head .app-"+__utils.slugify(name)).remove()
return stylesheets.forEach(function(sheet){var urlToStyle
if(devMode){urlToStyle="https://"+KD.nick()+"."+KD.config.userSitesDomain+"/.applications/"+__utils.slugify(name)+"/"+__utils.stripTags(sheet)+"?"+Date.now()
return $("head").append("<link class='app-"+__utils.slugify(name)+"' rel='stylesheet' href='"+urlToStyle+"'>")}if(/(http)|(:\/\/)/.test(sheet))return warn("external sheets cannot be used")
sheet=sheet.replace(/(^\.\/)|(^\/+)/,"")
return $("head").append("<link class='app-"+__utils.slugify(name)+"' rel='stylesheet' href='"+KD.appsUri+"/"+(manifest.authorNick||KD.nick())+"/"+__utils.stripTags(identifier)+"/"+__utils.stripTags(version)+"/"+__utils.stripTags(sheet)+"'>")})}}
showError=function(error){new KDModalView({title:"An error occured while running the App!",width:500,overlay:!0,content:"<div class='modalformline'>\n  <h3>"+error.constructor.name+"</h3><br/>\n  <pre>"+error.message+"</pre>\n</div>\n<p class='modalformline'>\n  <cite>Check Console for more details.</cite>\n</p>"})
return console.warn(error.message,error)}
KodingAppsController.prototype.showUpdateRequiredModal=function(manifest){var modal,name,_this=this
name=manifest.name
return modal=new KDModalView({title:"Update Required for "+name,content:'<div class="app-update-modal">\n  <p>Author of '+name+' made this update required. You must update to keep on using the app.</p>\n  <p><span class="app-update-warning">Warning:</span> Updating an app will delete it\'s current folder to install new version. This cannot be undone. If you have updated files, back up them now.</p>\n</div>',overlay:!0,buttons:{Update:{style:"modal-clean-green",loader:{color:"#FFFFFF",diameter:12},callback:function(){return _this.updateUserApp(manifest,function(){modal.buttons.Update.hideLoader()
return modal.destroy()})}},Close:{style:"modal-cancel",callback:function(){return modal.destroy()}}}})}
KodingAppsController.prototype.createExtensionToAppMap=function(){var app,fileTypes,key,map,type,_i,_j,_len,_len1,_ref,_ref1,_results
this.extensionToApp=map={}
_ref=this.getManifests()
for(key in _ref)if(__hasProp.call(_ref,key)){app=_ref[key]
fileTypes=app.fileTypes
if(fileTypes)for(_i=0,_len=fileTypes.length;_len>_i;_i++){type=fileTypes[_i]
map[type]||(map[type]=[])
map[type].push(app.name)}}_ref1=KD.getAppOptions("Ace").fileTypes
_results=[]
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){type=_ref1[_j]
map[type]||(map[type]=[])
_results.push(map[type].push("Ace"))}return _results}
KodingAppsController.prototype.fetchUserDefaultAppConfig=function(){var _this=this
this.appConfigStorage=new AppStorage("DefaultAppConfig","1.0")
return this.appConfigStorage.fetchStorage(function(){var appName,extension,settings,_results
settings=_this.appConfigStorage.getValue("settings")
_results=[]
for(extension in settings)if(__hasProp.call(settings,extension)){appName=settings[extension]
_results.push(_this.appManager.defaultApps[extension]=appName)}return _results})}
KodingAppsController.prototype.updateDefaultAppConfig=function(extension,appName){var defaultApps
defaultApps=this.appManager.defaultApps
defaultApps[extension]=appName
return this.appConfigStorage.setValue("settings",defaultApps)}
defaultManifest=function(type,name){var fullName,json,profile,raw
profile=KD.whoami().profile
fullName=KD.utils.getFullnameFromAccount()
raw={devMode:!0,experimental:!1,multiple:!1,background:!1,hiddenHandle:!1,forceUpdate:!1,openWith:"lastActive",behavior:"application",version:"0.1",title:""+(name||type.capitalize()),name:""+(name||type.capitalize()),identifier:"com.koding.apps."+__utils.slugify(name||type),path:"~/Applications/"+(name||type.capitalize())+".kdapp",homepage:""+profile.nickname+"."+KD.config.userSitesDomain+"/"+__utils.slugify(name||type),author:""+fullName,authorNick:""+profile.nickname,repository:"git://github.com/"+profile.nickname+"/"+__utils.slugify(name||type)+".kdapp.git",description:""+(name||type)+" : a Koding application created with the "+type+" template.",category:"web-app",source:{blocks:{app:{files:["./index.coffee"]}},stylesheets:["./resources/style.css"]},options:{type:"tab"},icns:{128:"./resources/icon.128.png"},screenshots:[],menu:[],fileTypes:[]}
return json=JSON.stringify(raw,null,2)}
defaultShortcuts={Ace:{name:"Ace",type:"koding-app",icon:"icn-ace.png",description:"Code Editor",author:"Mozilla",route:"/Develop/Ace"},Terminal:{name:"Terminal",type:"koding-app",icon:"icn-terminal.png",description:"Koding Terminal",author:"Koding",route:"/Develop/Terminal"},Teamwork:{name:"Teamwork",type:"koding-app",icon:"teamwork/icon.256.png",description:"Koding's official collaboration app",author:"Koding",route:"/Develop/Teamwork"}}
return KodingAppsController}(KDController)

var AppStorage,AppStorageController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppStorage=function(_super){function AppStorage(appId,version){this._applicationID=appId
this._applicationVersion=version
this.reset()
AppStorage.__super__.constructor.apply(this,arguments)}__extends(AppStorage,_super)
AppStorage.prototype.fetchStorage=function(callback){var appId,version,_ref,_this=this
_ref=[this._applicationID,this._applicationVersion],appId=_ref[0],version=_ref[1]
if(this._storage){"function"==typeof callback&&callback(this._storage)
return KD.utils.defer(function(){_this.emit("storageFetched")
return _this.emit("ready")})}return KD.whoami().fetchAppStorage({appId:appId,version:version},function(error,storage){if(!error&&storage){_this._storage=storage
"function"==typeof callback&&callback(_this._storage)
_this.emit("storageFetched")
return _this.emit("ready")}return"function"==typeof callback?callback(null):void 0})}
AppStorage.prototype.fetchValue=function(key,callback,group){null==group&&(group="bucket")
this.reset()
return this.fetchStorage(function(storage){var _ref
return callback((null!=(_ref=storage[group])?_ref[key]:void 0)?storage[group][key]:void 0)})}
AppStorage.prototype.getValue=function(key,group){var _ref,_ref1
null==group&&(group="bucket")
return this._storage?null!=(null!=(_ref=this._storageData[group])?_ref[key]:void 0)?this._storageData[group][key]:null!=(null!=(_ref1=this._storage[group])?_ref1[key]:void 0)?this._storage[group][key]:void 0:void 0}
AppStorage.prototype.setValue=function(key,value,callback,group){var pack
null==group&&(group="bucket")
pack=this.zip(key,group,value)
null==this._storageData[group]&&(this._storageData[group]={})
this._storageData[group][key]=value
return this.fetchStorage(function(storage){return storage.update({$set:pack},function(){return"function"==typeof callback?callback():void 0})})}
AppStorage.prototype.unsetKey=function(key,callback,group){var pack,_this=this
null==group&&(group="bucket")
pack=this.zip(key,group,1)
return this.fetchStorage(function(storage){var _ref
null!=(_ref=_this._storageData[group])&&delete _ref[key]
return storage.update({$unset:pack},callback)})}
AppStorage.prototype.reset=function(){this._storage=null
return this._storageData={}}
AppStorage.prototype.zip=function(key,group,value){var pack,_key
pack={}
_key=group+"."+key
pack[_key]=value
return pack}
return AppStorage}(KDObject)
AppStorageController=function(_super){function AppStorageController(){AppStorageController.__super__.constructor.apply(this,arguments)
this.appStorages={}}__extends(AppStorageController,_super)
AppStorageController.prototype.storage=function(appName,version){var key,storage,_base
null==version&&(version="1.0")
key=""+appName+"-"+version;(_base=this.appStorages)[key]||(_base[key]=new AppStorage(appName,version))
storage=this.appStorages[key]
storage.fetchStorage()
return storage}
return AppStorageController}(KDController)
KD.classes.AppStorage=AppStorage

var LocalStorage,LocalStorageController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LocalStorage=function(_super){function LocalStorage(){_ref=LocalStorage.__super__.constructor.apply(this,arguments)
return _ref}var e,storage
__extends(LocalStorage,_super)
try{storage=window.localStorage}catch(_error){e=_error
warn(""+e.name+" occured while getting localStorage:",e.message)
storage={}}LocalStorage.prototype.fetchStorage=function(){var _this=this
return KD.utils.defer(function(){return _this.emit("ready")})}
LocalStorage.prototype.getValue=function(key){var data
data=this._storageData[key]
if(data)return data
data=storage[this.getSignature(key)]
if(data)try{data=JSON.parse(data)}catch(_error){e=_error
warn("parse failed",e)}return data}
LocalStorage.prototype.getAt=function(path){var data,keys
if(!path)return null
keys=path.split(".")
data=this.getValue(keys.shift())
return data?0===keys.length?data:JsPath.getAt(data,keys.join(".")):null}
LocalStorage.prototype.setAt=function(path,value,callback){var key,keys
if(!path||!value)return null
keys=path.split(".")
key=keys.shift()
return 0===keys.length?this.setValue(key,value,callback):this.setValue(key,JsPath.setAt({},keys.join("."),value),callback)}
LocalStorage.prototype.fetchValue=function(key,callback){return"function"==typeof callback?callback(this.getValue(key)):void 0}
LocalStorage.prototype.setValue=function(key,value,callback){this._storageData[key]=value||""
storage[this.getSignature(key)]=JSON.stringify(value)||""
return KD.utils.defer(function(){return"function"==typeof callback?callback(null):void 0})}
LocalStorage.prototype.unsetKey=function(key){delete storage[this.getSignature(key)]
return delete this._storageData[key]}
LocalStorage.prototype.getSignature=function(key){return"koding-"+this._applicationID+"-"+this._applicationVersion+"-"+key}
return LocalStorage}(AppStorage)
LocalStorageController=function(_super){function LocalStorageController(){LocalStorageController.__super__.constructor.apply(this,arguments)
this.localStorages={}}__extends(LocalStorageController,_super)
LocalStorageController.prototype.storage=function(appName,version){var key,_base
null==version&&(version="1.0")
key=""+appName+"-"+version
return(_base=this.localStorages)[key]||(_base[key]=new LocalStorage(appName,version))}
return LocalStorageController}(KDController)
KD.classes.LocalStorage=LocalStorage

var ContentDisplay,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplay=function(_super){function ContentDisplay(options){null==options&&(options={})
options.cssClass=KD.utils.curry("content-display-wrapper content-page",options.cssClass)
ContentDisplay.__super__.constructor.apply(this,arguments)}__extends(ContentDisplay,_super)
return ContentDisplay}(MainTabPane)

var ContentDisplayController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayController=function(_super){function ContentDisplayController(){ContentDisplayController.__super__.constructor.apply(this,arguments)
this.displays={}
this.attachListeners()}__extends(ContentDisplayController,_super)
ContentDisplayController.prototype.attachListeners=function(){var appManager,mc,_this=this
mc=KD.singleton("mainController")
appManager=KD.singleton("appManager")
this.on("ContentDisplayWantsToBeShown",function(view){return mc.ready(function(){return _this.showDisplay(view)})})
this.on("ContentDisplayWantsToBeHidden",function(view){return mc.ready(function(){return _this.hideDisplay(view)})})
this.on("ContentDisplaysShouldBeHidden",function(){return mc.ready(function(){return _this.hideAllDisplays()})})
return appManager.on("ApplicationShowedAView",function(){return mc.ready(function(){return _this.hideAllDisplays()})})}
ContentDisplayController.prototype.showDisplay=function(view){var tabPane,_this=this
this.mainTabView=KD.singleton("mainView").mainTabView
tabPane=new ContentDisplay({name:"content-display",type:"social"})
this.displays[view.id]=view
tabPane.addSubView(view)
this.mainTabView.addPane(tabPane)
KD.singleton("dock").navController.selectItemByName("Activity")
tabPane.on("KDTabPaneInactive",function(){return _this.hideDisplay(view)})
return tabPane}
ContentDisplayController.prototype.hideDisplay=function(view){var tabPane
tabPane=view.parent
this.destroyView(view)
return tabPane?this.mainTabView.removePane(tabPane):void 0}
ContentDisplayController.prototype.hideAllDisplays=function(exceptFor){var display,displayIds,id,lastId,_i,_len
displayIds=null!=exceptFor?function(){var _ref,_results
_ref=this.displays
_results=[]
for(id in _ref)if(__hasProp.call(_ref,id)){display=_ref[id]
exceptFor!==display&&_results.push(id)}return _results}.call(this):function(){var _ref,_results
_ref=this.displays
_results=[]
for(id in _ref)if(__hasProp.call(_ref,id)){display=_ref[id]
_results.push(id)}return _results}.call(this)
if(0!==displayIds.length){lastId=displayIds.pop()
for(_i=0,_len=displayIds.length;_len>_i;_i++){id=displayIds[_i]
this.destroyView(this.displays[id])}return this.hideDisplay(this.displays[lastId])}}
ContentDisplayController.prototype.destroyView=function(view){this.emit("DisplayIsDestroyed",view)
delete this.displays[view.id]
return view.destroy()}
return ContentDisplayController}(KDController)

var Pinger,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Pinger=function(_super){function Pinger(options,data){Pinger.__super__.constructor.call(this,options,data)}__extends(Pinger,_super)
Pinger.prototype.reset=function(){null!=this.unresponsiveTimeoutId&&clearTimeout(this.unresponsiveTimeoutId)
null!=this.pingTimeoutId&&clearTimeout(this.pingTimeoutId)
delete this.unresponsiveTimeoutId
return delete this.pingTimeoutId}
Pinger.prototype.handleChannelPublish=function(){var _this=this
this.reset()
return this.unresponsiveTimeoutId=setTimeout(function(){return _this.emit("possibleUnresponsive")},5e3)}
Pinger.prototype.handleMessageArrived=function(){var _this=this
this.reset()
this.unresponded=0
this.lastPong=Date.now()
return this.pingTimeoutId=setTimeout(function(){return _this.pingChannel()},1e4)}
Pinger.prototype.handleSuspectChannel=function(){this.unresponded||(this.unresponded=0)
log("broker possibleUnresponsive: "+this.unresponded+" times")
this.unresponded++
return this.unresponded>1?this.emit("unresponsive"):this.run()}
Pinger.prototype.setStartPinging=function(){return this.stopPinging=!1}
Pinger.prototype.setStopPinging=function(){return this.stopPinging=!0}
return Pinger}(KDObject)

var Kite,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
Kite=function(_super){function Kite(options){Kite.__super__.constructor.apply(this,arguments)
this.kiteName=options.kiteName,this.correlationName=options.correlationName,this.kiteKey=options.kiteKey
this.initChannel()
this.localStore=new Store
this.remoteStore=new Store
this.readyState=NOTREADY}var NOTREADY,READY,Scrubber,Store,_ref,_ref1
__extends(Kite,_super)
_ref=[0,1],NOTREADY=_ref[0],READY=_ref[1]
_ref1=Bongo.dnodeProtocol,Scrubber=_ref1.Scrubber,Store=_ref1.Store
Kite.prototype.createId=Bongo.createId
Kite.prototype.initChannel=function(){this.entropy=this.createId(128)
this.qualifiedName="kite-"+this.kiteName
this.channelName=this.getChannelName()
this.channel=KD.remote.mq.subscribe(this.channelName)
this.channel.setAuthenticationInfo({serviceType:"kite",name:this.qualifiedName,correlationName:this.correlationName,clientId:KD.remote.getSessionToken()})
this.channel.cycleChannel=this.bound("cycleChannel")
this.channel.ping=this.bound("pingChannel")
this.channel.setStartPinging=this.bound("setStartPinging")
this.channel.setStopPinging=this.bound("setStopPinging")
this.channel.on("message",this.bound("handleChannelMessage"))
this.channel.on("message",this.bound("handleMessageArrived"))
this.channel.on("publish",this.bound("handleChannelPublish"))
this.channel.on("possibleUnresponsive",this.bound("handleSuspectChannel"))
return this.channel.on("unresponsive",this.bound("handleUnresponsiveChannel"))}
Kite.prototype.handleBrokerSubscribed=function(){}
Kite.prototype.cycleChannel=function(){log("cycleChannel",this.channel.name)
this.setStopPinging()
this.channel.off()
this.initChannel()
return this.emit("destroy")}
Kite.prototype.pingChannel=function(callback){if(!this.stopPinging){this.channel.publish(JSON.stringify({method:"ping",arguments:[],callbacks:{}}))
return callback?this.channel.once("pong",callback):void 0}}
Kite.prototype.handleChannelMessage=function(args){var callback,method
method=args.method
callback=function(){var _ref2
switch(method){case"ready":return this.bound("handleReady")
case"error":return this.bound("handleError")
case"ping":return this.bound("handlePing")
case"pong":return this.bound("handlePong")
case"cycleChannel":return this.bound("cycleChannel")
default:return null!=(_ref2=this.localStore.get(method))?_ref2:function(){}}}.call(this)
return callback.apply(this,this.unscrub(args))}
Kite.prototype.handleUnresponsiveChannel=function(){log("unresponsive",this.channel.name)
return this.cycleChannel()}
Kite.prototype.ready=function(callback){return this.readyState===READY?KD.utils.defer(callback):this.once("ready",callback)}
Kite.prototype.handleReady=function(resourceName){this.readyState=READY
this.channel.exchange=resourceName
return this.emit("ready")}
Kite.prototype.handleError=function(err){error(err)
return this.emit("KiteError",err)}
Kite.prototype.handlePing=function(){return this.channel.publish(JSON.stringify({method:"pong",arguments:[],callbacks:{}}))}
Kite.prototype.handlePong=function(){this.channel.emit("pong")
return this.lastPong=Date.now()}
Kite.prototype.handleRequest=function(method,args){var _this=this
return this.scrub(method,args,function(scrubbed){var messageString
messageString=JSON.stringify(scrubbed)
return _this.ready(function(){return _this.channel.publish(messageString)})})}
Kite.prototype.scrub=function(method,args,callback){var scrubber
scrubber=new Scrubber(this.localStore)
return scrubber.scrub(args,function(){var scrubbed
scrubbed=scrubber.toDnodeProtocol()
scrubbed.method||(scrubbed.method=method)
return callback(scrubbed)})}
Kite.prototype.unscrub=function(args){var scrubber,_this=this
scrubber=new Scrubber(this.localStore)
return scrubber.unscrub(args,function(callbackId){_this.remoteStore.has(callbackId)||_this.remoteStore.add(callbackId,function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return _this.handleRequest(callbackId,rest)})
return _this.remoteStore.get(callbackId)})}
Kite.prototype.getChannelName=function(){var channelName,delegate,nickname,_ref2,_ref3
delegate=KD.whoami()
nickname=null!=(_ref2=null!=delegate?delegate.profile.nickname:void 0)?_ref2:delegate.guestId?null!=(_ref3="guest"+delegate.guestId)?_ref3:"unknown":void 0
channelName=""+this.entropy+"."+nickname+"."+this.qualifiedName
return channelName}
Kite.prototype.tell=function(options,callback){return this.handleRequest(options.method,[options,callback])}
return Kite}(Pinger)

var KiteController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KiteController=function(_super){function KiteController(){KiteController.__super__.constructor.apply(this,arguments)
this.kiteIds={}
this.status=!1
this.intervals={}
this.setListeners()
this.kites={}
this.channels={}
this.kiteInstances={}}var getKiteKey,notify,_attempt,_notifications,_tempCallback,_tempOptions
__extends(KiteController,_super)
_tempOptions=null
_tempCallback=null
_attempt=1
_notifications={"default":"Something went wrong",creatingEnv:"Creating your environment.",stillCreatingEnv:"...still busy with setting up your environment.",creationTookLong:"...still busy with it, there might be something wrong.",tookTooLong:"It seems like we couldn't set up your environment, please click here to try again.",envCreated:"Your server, terminal and files are ready, enjoy!",notResponding:"Backend is not responding, trying to fix...",checkingServers:"Checking if servers are back...",alive:"Shared hosting is alive!"}
getKiteKey=function(kiteName,correlationName){return"~"+kiteName+"~"+correlationName}
KiteController.prototype.getKite=function(kiteName,correlationName){var key,kite
key=getKiteKey(kiteName,correlationName)
kite=this.kiteInstances[key]
if(null!=kite)return kite
kite=this.createKite(kiteName,correlationName,key)
this.kiteInstances[key]=kite
return kite}
KiteController.prototype.destroyKite=function(kite){return delete this.kiteInstances[kite.kiteKey]}
KiteController.prototype.createKite=function(kiteName,correlationName,kiteKey){var kite,_this=this
kite=new Kite({kiteName:kiteName,correlationName:correlationName,kiteKey:kiteKey})
kite.on("destroy",function(){return _this.destroyKite(kite)})
this.forwardEvent(kite,"KiteError")
return kite}
notify=function(options){var notification
null==options&&(options={})
"string"==typeof options&&(options={msg:options})
options.msg||(options.msg=_notifications["default"])
options.duration||(options.duration=3303)
options.cssClass||(options.cssClass="")
options.click||(options.click=noop)
return notification=new KDNotificationView({title:"<span></span>"+options.msg,type:"tray",cssClass:"mini realtime "+options.cssClass,duration:options.duration,click:options.click})}
KiteController.prototype.addKite=function(name,channel){this.channels[name]=channel
this.kites[name]=channel
return this.emit("channelAdded",channel,name)}
KiteController.prototype.deleteKite=function(name){this.emit("channelDeleted",this.kites[name],name)
delete this.kites[name]
return delete this.channels[name]}
KiteController.prototype.run=function(options,callback){var command,correlationName,kite,vmc,_this=this
null==options&&(options={})
if("string"==typeof options){command=options
options={}}options.method||(options.method="exec")
options.kiteName||(options.kiteName="os")
correlationName=options.correlationName||""
if("os"===options.kiteName&&!correlationName){warn("THIS METHOD DEPRECATED, PLEASE USE vmController.run with vmName !")
warn("OS kite call requested without providing\ncorrelationName, using default if exists.")
vmc=KD.getSingleton("vmController")
correlationName=vmc.defaultVmName
options.kiteName="os-"+vmc.vmRegions[vmc.defaultVmName]}kite=this.getKite(options.kiteName,correlationName)
command?options.withArgs=command:options.withArgs||(options.withArgs={})
if(KD.logsEnabled&&KD.showKiteCalls){notify("Calling <b>"+options.method+"</b> method,\nfrom <b>"+options.kiteName+"</b> kite")
log("Kite Request:",options)}return kite.tell(options,function(err,response){return _this.parseKiteResponse({err:err,response:response},options,callback)})}
KiteController.prototype.setListeners=function(){var mainController
mainController=KD.getSingleton("mainController")
this.on("CreatingUserEnvironment",function(){var mainView
mainView=KD.getSingleton("mainView")
return mainView.contentPanel.putOverlay({isRemovable:!1,cssClass:"dummy",animated:!0,parent:".application-page.start-tab"})})
return this.on("UserEnvironmentIsCreated",function(){var mainView
if(1!==_attempt){notify(_notifications.envCreated)
mainView=KD.getSingleton("mainView")
mainView.removeOverlay()
mainView.contentPanel.removeOverlay()
return _attempt=1}})}
KiteController.prototype.accountChanged=function(){var kiteName,_this=this
kiteName="sharedHosting"
return KD.isLoggedIn()?this.resetKiteIds(kiteName,function(err){return err?void 0:_this.status=!0}):this.status=!1}
KiteController.prototype.parseKiteResponse=function(_arg,options,callback){var err,notification,response,_this=this
err=_arg.err,response=_arg.response
if(err&&response){"function"==typeof callback&&callback(err,response)
return warn("Command failed:",err)}if(err){if(503===err.code)return notification=notify({msg:error.message,duration:0,click:function(){return notification.destroy()}})
if(err.kiteNotPresent)return this.handleKiteNotPresent({err:err,response:response},options,callback)
if(/No\ssuch\suser/.test(err)){_tempOptions||(_tempOptions=options)
_tempCallback||(_tempCallback=callback)
return this.createSystemUser(callback)}if(/Entry\sAlready\sExists/.test(err))return this.utils.wait(5e3,function(){_attempt++
return _this.run(_tempOptions,_tempCallback)})
if(null!=err.message){"function"==typeof callback&&callback(err)
return warn("An error occured:",err.message)}"function"==typeof callback&&callback(err)
return warn("parsing kite response: we dont handle this yet",err)}this.status=!0
return"function"==typeof callback?callback(err,response):void 0}
KiteController.prototype.handleKiteNotPresent=function(_arg,options,callback){var err,response,_this=this
err=_arg.err,response=_arg.response
notify(_notifications.notResponding)
return this.resetKiteIds(options.kiteName,function(err,kiteIds){if(Array.isArray(kiteIds)&&kiteIds.length>0)return _this.run(options,callback)
notify("Backend is not responding, try again later.")
warn("handleKiteNotPresent: we dont handle this yet",err)
return"function"==typeof callback?callback("handleKiteNotPresent: we dont handle this yet"):void 0})}
KiteController.prototype.createSystemUser=function(callback){var _this=this
if(_attempt>1&&5>_attempt)notify(_notifications.stillCreatingEnv)
else if(_attempt>=5&&10>_attempt)notify({msg:_notifications.creationTookLong,duration:4500})
else{if(_attempt>=10){notify({msg:_notifications.tookTooLong,duration:0,click:function(){return _this.createSystemUser(callback)}})
return}this.emit("CreatingUserEnvironment")
notify(_notifications.creatingEnv)}return this.run({method:"createSystemUser",withArgs:{fullName:""+KD.whoami().getAt("profile.firstName")+" "+KD.whoami().getAt("profile.lastName"),password:__utils.getRandomHex().substr(1)}},function(err,res){log("Creating the user environment.")
"function"==typeof callback&&callback(err,res)
if(err)return error("createUserEnvironment",err)
notify(_notifications.envCreated)
return _this.emit("UserEnvironmentIsCreated")})}
KiteController.prototype.ping=function(kiteName,callback){var _this=this
log("pinging : "+kiteName)
return this.run({method:"_ping"},function(err){if(err){notify(_notifications.checkingServers)
_this.parseError(_this,err)}else{_this.status=!0
_this.pinger&&clearInterval(_this.pinger)
notify(_notifications.alive)}return"function"==typeof callback?callback():void 0})}
KiteController.prototype.setPinger=function(){var _this=this
if(!this.pinger){this.pinger=setInterval(function(){return _this.ping()},1e4)
return this.ping()}}
KiteController.prototype.resetKiteIds=function(kiteName){null==kiteName&&(kiteName="sharedHosting")}
return KiteController}(KDController)

var NewKite,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
NewKite=function(_super){function NewKite(options){NewKite.__super__.constructor.call(this,options)
this.addr=options.addr,this.name=options.name,this.token=options.token,this.publicIP=options.publicIP,this.port=options.port
this.localStore=new Store
this.remoteStore=new Store
this.tokenStore={}
this.autoReconnect=!0
this.readyState=NOTREADY
this.addr||(this.addr="")
options.publicIP&&options.port&&(this.addr=options.publicIP+":"+options.port)
this.token||(this.token="")
this.autoReconnect&&this.initBackoff(options)
this.connect()}var CLOSED,NOTREADY,READY,Scrubber,Store,_ref,_ref1
__extends(NewKite,_super)
_ref=Bongo.dnodeProtocol,Scrubber=_ref.Scrubber,Store=_ref.Store
_ref1=[0,1,3],NOTREADY=_ref1[0],READY=_ref1[1],CLOSED=_ref1[2]
NewKite.prototype.connect=function(){return this.addr?this.connectDirectly():this.getKiteAddr(!0)}
NewKite.prototype.bound=Bongo.bound
NewKite.prototype.connectDirectly=function(){log("trying to connect to "+this.addr)
this.ws=new WebSocket("ws://"+this.addr+"/sock")
this.ws.onopen=this.bound("onOpen")
this.ws.onclose=this.bound("onClose")
this.ws.onmessage=this.bound("onMessage")
return this.ws.onerror=this.bound("onError")}
NewKite.prototype.getKiteAddr=function(connect){var _this=this
null==connect&&(connect=!1)
return KD.getSingleton("kontrol").getKites(this.name,function(err,kites){var first,kite
if(err){log("kontrol request error",err)
return KD.utils.defer(function(){return _this.setBackoffTimeout(function(){return _this.getKiteAddr(!0)})})}first=kites[0]
kite=first.kite
_this.token=first.token
_this.addr=kite.publicIP+":"+kite.port
return connect?_this.connectDirectly():void 0})}
NewKite.prototype.disconnect=function(reconnect){null==reconnect&&(reconnect=!0)
null!=reconnect&&(this.autoReconnect=!!reconnect)
return this.ws.close()}
NewKite.prototype.onOpen=function(){log("I'm connected to "+this.name+" at "+this.addr+". Yayyy!")
this.clearBackoffTimeout()
this.readyState=READY
this.emit("connected",this.name)
return this.emit("ready")}
NewKite.prototype.onClose=function(){this.readyState=CLOSED
return this.emit("disconnected")}
NewKite.prototype.onMessage=function(evt){var args,callback,e,err,method
try{args=JSON.parse(evt.data)}catch(_error){e=_error
log("json parse error: ",e,evt.data)}if(args&&!e){err=args.arguments[0]
method=args.method
callback=function(){var _ref2
switch(method){case"ping":return this.bound("handlePing")
default:return null!=(_ref2=this.localStore.get(method))?_ref2:function(){}}}.call(this)
return callback.apply(this,this.unscrub(args))}}
NewKite.prototype.onError=function(){}
NewKite.prototype.handlePing=function(){return this.send(JSON.stringify({method:"pong",arguments:[],callbacks:{}}))}
NewKite.prototype.initBackoff=function(options){var backoff,initalDelayMs,maxDelayMs,maxReconnectAttempts,multiplyFactor,totalReconnectAttempts,_ref2,_ref3,_ref4,_ref5,_ref6,_this=this
backoff=null!=(_ref2=options.backoff)?_ref2:{}
totalReconnectAttempts=0
initalDelayMs=null!=(_ref3=backoff.initialDelayMs)?_ref3:700
multiplyFactor=null!=(_ref4=backoff.multiplyFactor)?_ref4:1.4
maxDelayMs=null!=(_ref5=backoff.maxDelayMs)?_ref5:15e3
maxReconnectAttempts=null!=(_ref6=backoff.maxReconnectAttempts)?_ref6:50
this.clearBackoffTimeout=function(){return totalReconnectAttempts=0}
return this.setBackoffTimeout=function(fn){var timeout
if(maxReconnectAttempts>totalReconnectAttempts){timeout=Math.min(initalDelayMs*Math.pow(multiplyFactor,totalReconnectAttempts),maxDelayMs)
setTimeout(fn,timeout)
return totalReconnectAttempts++}return _this.emit("connectionFailed")}}
NewKite.prototype.ready=function(callback){return this.readyState?KD.utils.defer(callback):this.once("ready",callback)}
NewKite.prototype.unscrub=function(args){var scrubber,_this=this
scrubber=new Scrubber(this.localStore)
return scrubber.unscrub(args,function(callbackId){_this.remoteStore.has(callbackId)||_this.remoteStore.add(callbackId,function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return _this.handleRequest(callbackId,rest)})
return _this.remoteStore.get(callbackId)})}
NewKite.prototype.handleRequest=function(method,args){var _this=this
return this.scrub(method,args,function(scrubbed){return _this.ready(function(){return _this.send(scrubbed)})})}
NewKite.prototype.scrub=function(method,args,callback){var scrubber
scrubber=new Scrubber(this.localStore)
return scrubber.scrub(args,function(){var scrubbed
scrubbed=scrubber.toDnodeProtocol()
scrubbed.method||(scrubbed.method=method)
return callback(scrubbed)})}
NewKite.prototype.tell=function(method,args,callback){var _this=this
return this.ready(function(){var options
options={token:_this.token,username:""+KD.nick(),withArgs:args}
return _this.handleRequest(method,[options,callback])})}
NewKite.prototype.send=function(data){var e
try{if(this.readyState===READY)return this.ws.send(JSON.stringify(data))}catch(_error){e=_error
return this.disconnect()}}
return NewKite}(KDObject)

var Kontrol,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Kontrol=function(_super){function Kontrol(){Kontrol.__super__.constructor.apply(this,arguments)
this.readyState=NOTREADY
this.addr="ws://"+KD.config.newkontrol.host+":"+KD.config.newkontrol.port+"/_moh_/pub"
this.kites={}}var CLOSED,NOTREADY,READY,SubscribePrefix,kontrolEndpoint,_ref
__extends(Kontrol,_super)
Kontrol.prototype.bound=Bongo.bound
_ref=[0,1,3],NOTREADY=_ref[0],READY=_ref[1],CLOSED=_ref[2]
kontrolEndpoint="http://"+KD.config.newkontrol.host+":"+KD.config.newkontrol.port+"/query"
SubscribePrefix="client"
Kontrol.prototype.getKites=function(options,callback){var name,queryData,region,xhr
name=options.name,region=options.region
queryData={username:""+KD.nick(),name:name,region:region,authentication:{type:"browser",key:KD.remote.getSessionToken()}}
xhr=new XMLHttpRequest
xhr.open("POST",kontrolEndpoint,!0)
xhr.setRequestHeader("Content-type","application/x-www-form-urlencoded")
xhr.send(JSON.stringify(queryData))
return xhr.onload=function(){var data
if(200===xhr.status){data=JSON.parse(xhr.responseText)
return callback(null,data)}return callback(xhr.responseText,null)}}
Kontrol.prototype.getKite=function(options,callback){var kite,_this=this
kite=this.kites[options.name]
return null!=kite?callback(null,kite):this.getKites(options,function(err,kites){if(err){log("kontrol request error",err)
return callback(err,null)}kite=_this.createKite(kites.first.kite)
kite.token=kites.first.token
_this.addKite(kite)
return callback(null,kite)})}
Kontrol.prototype.createKite=function(kite){kite=new NewKite({name:kite.name,token:kite.token,port:kite.port,publicIP:kite.publicIP})
return kite}
Kontrol.prototype.addKite=function(kite){return this.kites[kite.name]=kite}
Kontrol.prototype.removeKite=function(kite){return delete this.kites[kite.name]}
Kontrol.prototype.connect=function(){this.ws=new WebSocket(this.addr,KD.remote.getSessionToken())
this.ws.onopen=this.bound("onOpen")
this.ws.onclose=this.bound("onClose")
this.ws.onmessage=this.bound("onMessage")
return this.ws.onerror=this.bound("onError")}
Kontrol.prototype.onOpen=function(){log("I'm connected to "+this.addr+". Yayyy!")
this.readyState=READY
this.emit("ready")
return this.subscribe()}
Kontrol.prototype.onClose=function(){return this.readyState=CLOSED}
Kontrol.prototype.onMessage=function(evt){var _this=this
return this.blobToString(evt.data,function(msg){var e,kite
try{msg=JSON.parse(msg)
log("Message from Kontrol",{msg:msg})}catch(_error){e=_error
log("json parse error: ",e,msg)
return}switch(msg.type){case"KITE_REGISTERED":log("kite registered")
kite=_this.createKite(msg.args.kite)
_this.addKite(kite)
return _this.emit("KiteRegistered",msg.args.kite)
case"KITE_DISCONNECTED":log("kite disconnected")
_this.removeKite(msg.args.kite)
return _this.emit("KiteDisconnected",msg.args.kite)}})}
Kontrol.prototype.onError=function(evt){return log("kontrol: error "+evt.data)}
Kontrol.prototype.ready=function(callback){return this.readyState?KD.utils.defer(callback):this.once("ready",callback)}
Kontrol.prototype.subscribe=function(){return this.send({name:"subscribe",args:{key:""+SubscribePrefix+"."+KD.nick()}})}
Kontrol.prototype.send=function(data){var _this=this
return this.ready(function(){var e
try{return _this.ws.send(JSON.stringify(data))}catch(_error){e=_error
return log(e)}})}
Kontrol.prototype.blobToString=function(blob,callback){var reader
reader=new FileReader
reader.readAsText(blob)
return reader.onloadend=function(){return callback(reader.result)}}
return Kontrol}(KDObject)

var VirtualizationController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice,__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
VirtualizationController=function(_super){function VirtualizationController(){var _this=this
VirtualizationController.__super__.constructor.apply(this,arguments)
this.kc=KD.getSingleton("kiteController")
this.dialogIsOpen=!1
this.resetVMData()
KD.getSingleton("mainController").once("AppIsReady",this.bound("fetchVMs")).on("AccountChanged",function(){return _this.emit("VMListChanged")})
this.on("VMListChanged",this.bound("resetVMData"))}__extends(VirtualizationController,_super)
VirtualizationController.prototype.run=function(options,callback){var command,_ref,_this=this
null==callback&&(callback=noop)
callback||(_ref=[options,callback],callback=_ref[0],options=_ref[1])
null==options&&(options={})
if("string"==typeof options){command=options
options={withArgs:command}}return this.fetchVmName(options,function(err,vmName){if(null!=err)return callback(err)
options.correlationName=vmName
return _this.fetchRegion(vmName,function(region){options.kiteName="os-"+region
return _this.kc.run(options,function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return callback.apply(null,rest)})})})}
VirtualizationController.prototype._runWrapper=function(command,vm,callback){var _ref,_this=this
vm&&"string"!=typeof vm&&(_ref=[vm,callback],callback=_ref[0],vm=_ref[1])
return this.fetchDefaultVmName(function(defaultVm){vm||(vm=defaultVm)
return vm?_this.askForApprove(command,function(approved){var cb
if(approved){cb="vm.info"!==command?_this._cbWrapper(vm,callback):callback
return _this.run({method:command,vmName:vm},cb)}return"vm.info"!==command?_this.info(vm):void 0}):void 0})}
VirtualizationController.prototype.resizeDisk=function(vm,callback){return this._runWrapper("vm.resizeDisk",vm,callback)}
VirtualizationController.prototype.start=function(vm,callback){return this._runWrapper("vm.start",vm,callback)}
VirtualizationController.prototype.stop=function(vm,callback){return this._runWrapper("vm.shutdown",vm,callback)}
VirtualizationController.prototype.halt=function(vm,callback){return this._runWrapper("vm.stop",vm,callback)}
VirtualizationController.prototype.reinitialize=function(vm,callback){return this._runWrapper("vm.reinitialize",vm,callback)}
VirtualizationController.prototype.remove=function(){var deleteVM
deleteVM=function(vm,cb){return KD.remote.api.JVM.removeByHostname(vm,function(err){if(err)return cb(err)
KD.getSingleton("finderController").unmountVm(vm)
KD.getSingleton("vmController").emit("VMListChanged")
return cb(null)})}
return function(vm,callback){var _this=this
null==callback&&(callback=noop)
return KD.remote.api.JVM.fetchVmInfo(vm,function(err,vmInfo){var hostnameAlias,message,modal,paymentController,vmPrefix,_ref
if(vmInfo){if(vmInfo.underMaintenance===!0){message="Your VM is under maintenance, not allowed to delete."
new KDNotificationView({title:message})
return callback({message:message})}if("free"===vmInfo.planCode){hostnameAlias=vmInfo.hostnameAlias
vmPrefix=(null!=(_ref=_this.parseAlias(hostnameAlias))?_ref.prefix:void 0)||hostnameAlias
return modal=new VmDangerModalView({name:vmInfo.hostnameAlias,title:"Destroy '"+hostnameAlias+"'",action:"Destroy my VM",callback:function(){deleteVM(vm,callback)
new KDNotificationView({title:"Successfully destroyed!"})
return modal.destroy()}},vmPrefix)}paymentController=KD.getSingleton("paymentController")
return paymentController.deleteVM(vmInfo,function(state){return state?deleteVM(vm,callback):callback(null)})}new KDNotificationView({title:"Failed to remove!"})
return callback({message:"No such VM!"})})}}()
VirtualizationController.prototype.info=function(vm,callback){var _ref,_this=this
"function"==typeof vm&&(_ref=[vm,callback],callback=_ref[0],vm=_ref[1])
return this._runWrapper("vm.info",vm,function(err,info){err&&warn("[VM-"+vm+"]",err)
if("UnderMaintenanceError"===(null!=err?err.name:void 0)){info={state:"MAINTENANCE"}
err=null
delete _this.vmRegions[vm]}_this.emit("StateChanged",err,vm,info)
return"function"==typeof callback?callback(err,vm,info):void 0})}
VirtualizationController.prototype.fetchRegion=function(vmName,callback){var region,_this=this
return(region=this.vmRegions[vmName])?this.utils.defer(function(){return callback(region)}):KD.remote.api.JVM.fetchVmRegion(vmName,function(err,region){if(err||!region){err&&warn(err)
return callback("sj")}_this.vmRegions[vmName]=region
return callback(_this.vmRegions[vmName])})}
VirtualizationController.prototype.fetchVmName=function(options,callback){return null!=options.vmName?this.utils.defer(function(){return callback(null,options.vmName)}):this.fetchDefaultVmName(function(defaultVmName){return null!=defaultVmName?callback(null,defaultVmName):callback({message:"There is no VM for this account."})})}
VirtualizationController.prototype.fetchDefaultVmName=function(callback,force){var currentGroup,entryPoint,_this=this
null==callback&&(callback=noop)
null==force&&(force=!1)
if(this.defaultVmName&&!force)return this.utils.defer(function(){return callback(_this.defaultVmName)})
entryPoint=KD.config.entryPoint
currentGroup="group"===(null!=entryPoint?entryPoint.type:void 0)?entryPoint.slug:void 0
currentGroup||(currentGroup=KD.defaultSlug)
return this.fetchVMs(function(err,vmNames){return err||!vmNames?callback(null):1===vmNames.length?callback(_this.defaultVmName=vmNames.first):KD.remote.api.JVM.fetchDefaultVm(function(err,defaultVmName){var groupVMs,userVMs,vm,vmSort,vms,_i,_j,_k,_len,_len1,_len2,_ref
if("koding"===currentGroup&&defaultVmName)return callback(_this.defaultVmName=defaultVmName)
vmSort=function(x,y){return x.uid-y.uid}
vms=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=vmNames.length;_len>_i;_i++){vm=vmNames[_i]
_results.push(this.parseAlias(vm))}return _results}.call(_this)
userVMs=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=vms.length;_len>_i;_i++){vm=vms[_i]
"user"===(null!=vm?vm.type:void 0)&&_results.push(vm)}return _results}().sort(vmSort)
groupVMs=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=vms.length;_len>_i;_i++){vm=vms[_i]
"group"===(null!=vm?vm.type:void 0)&&_results.push(vm)}return _results}().sort(vmSort)
for(_i=0,_len=userVMs.length;_len>_i;_i++){vm=userVMs[_i]
if(vm.groupSlug===currentGroup)return callback(_this.defaultVmName=vm.alias)}for(_j=0,_len1=groupVMs.length;_len1>_j;_j++){vm=groupVMs[_j]
if(vm.groupSlug===currentGroup)return callback(_this.defaultVmName=vm.alias)}for(_k=0,_len2=userVMs.length;_len2>_k;_k++){vm=userVMs[_k]
if("koding"===(_ref=vm.groupSlug)||"guests"===_ref)return callback(_this.defaultVmName=vm.alias)}return callback(_this.defaultVmName=defaultVmName)})})}
VirtualizationController.prototype.createGroupVM=function(type,planCode,callback){var defaultVMOptions,group,vmCreateCallback
null==type&&(type="user")
null==callback&&(callback=function(){})
vmCreateCallback=function(err,vm){var vmController
vmController=KD.getSingleton("vmController")
if(err){warn(err)
return new KDNotificationView({title:err.message||"Something bad happened while creating VM"})}KD.getSingleton("finderController").mountVm(vm.hostnameAlias)
vmController.emit("VMListChanged")
return vmController.showVMDetails(vm)}
defaultVMOptions={planCode:planCode}
group=KD.getSingleton("groupsController").getCurrentGroup()
return group.createVM({type:type,planCode:planCode},vmCreateCallback)}
VirtualizationController.prototype.fetchVMs=function(waiting){return function(force,callback){var _ref,_this=this
null==callback&&(_ref=[force,callback],callback=_ref[0],force=_ref[1])
if(null!=callback){if(this.vms.length)return this.utils.defer(function(){return callback(null,_this.vms)})
if(force||!(waiting.push(callback)>1))return KD.remote.api.JVM.fetchVms(function(err,vms){var cb,_i,_len
err||(_this.vms=vms)
if(force)return callback(err,vms)
for(_i=0,_len=waiting.length;_len>_i;_i++){cb=waiting[_i]
cb(err,vms)}return waiting=[]})}}}([])
VirtualizationController.prototype.fetchGroupVMs=function(callback){var _this=this
null==callback&&(callback=noop)
return this.groupVms.length>0?this.utils.defer(function(){return callback(null,_this.groupVms)}):KD.remote.api.JVM.fetchVmsByContext(function(err,vms){err||(_this.groupVms=vms)
return"function"==typeof callback?callback(err,vms):void 0})}
VirtualizationController.prototype.fetchVMDomains=function(vmName,callback){var domains,_this=this
null==callback&&(callback=noop)
return(domains=this.vmDomains[vmName])?this.utils.defer(function(){return callback(null,domains)}):KD.remote.api.JVM.fetchDomains(vmName,function(err,domains){null==domains&&(domains=[])
if(err)return callback(err,domains)
_this.vmDomains[vmName]=domains.sort(function(x,y){return x.length>y.length})
return callback(null,_this.vmDomains[vmName])})}
VirtualizationController.prototype.resetVMData=function(){this.vms=[]
this.groupVms=[]
this.defaultVmName=null
this.vmDomains={}
return this.vmRegions={}}
VirtualizationController.prototype.fetchTotalVMCount=function(callback){return KD.remote.api.JVM.count(function(err,count){err&&warn(err)
return callback(null,null!=count?count:"0")})}
VirtualizationController.prototype.fetchTotalLoC=function(callback){return callback(null,"0")}
VirtualizationController.prototype._cbWrapper=function(vm,callback){var _this=this
return function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return _this.info(vm,"function"==typeof callback?callback.apply(null,rest):void 0)}}
VirtualizationController.prototype.fetchDiskUsage=function(vmName,callback){var command
null==callback&&(callback=noop)
command="df | grep aufs | awk '{print $2, $3}'"
return this.run({vmName:vmName,withArgs:command},function(err,res){var current,max,_ref,_ref1
err||!res?(_ref=[0,0],max=_ref[0],current=_ref[1]):(_ref1=res.trim().split(" "),max=_ref1[0],current=_ref1[1])
err&&warn(err)
return callback({max:1024*parseInt(max,10),current:1024*parseInt(current,10)})})}
VirtualizationController.prototype.fetchRamUsage=function(vmName,callback){null==callback&&(callback=noop)
return this.info(vmName,function(err,vm,info){var current,max,_ref,_ref1
err||"RUNNING"!==info.state?(_ref=[0,0],max=_ref[0],current=_ref[1]):(_ref1=[info.totalMemoryLimit,info.memoryUsage],max=_ref1[0],current=_ref1[1])
err&&warn(err)
return callback({max:max,current:current})})}
VirtualizationController.prototype.hasDefaultVM=function(callback){return KD.remote.api.JVM.fetchDefaultVm(callback)}
VirtualizationController.prototype.createDefaultVM=function(callback){return this.hasDefaultVM(function(err,state){var notify
if(state)return warn("Default VM already exists.")
notify=new KDNotificationView({title:"Creating your VM...",overlay:{transparent:!1,destroyOnClick:!1},loader:{color:"#ffffff"},duration:12e4})
return KD.remote.cacheable(KD.defaultSlug,function(err,group){var koding
if(err||!(null!=group?group.length:void 0))return warn(err)
koding=group.first
return koding.createVM({planCode:"free",type:"user"},function(err){var vmController
if(err){null!=notify&&notify.destroy()
return KD.showError(err)}vmController=KD.getSingleton("vmController")
return vmController.fetchDefaultVmName(function(defaultVmName){vmController.emit("VMListChanged")
KD.getSingleton("finderController").mountVm(defaultVmName)
notify.destroy()
return"function"==typeof callback?callback():void 0})})})})}
VirtualizationController.prototype.createNewVM=function(callback){var _this=this
return this.hasDefaultVM(function(err,state){return state?_this.createPaidVM():_this.createDefaultVM(callback)})}
VirtualizationController.prototype.showVMDetails=function(vm){var content,modal,url,vmName
vmName=vm.hostnameAlias
url="http://"+vm.hostnameAlias
content='<div class="item">\n  <span class="title">Name:</span>\n  <span class="value">'+vmName+'</span>\n</div>\n<div class="item">\n  <span class="title">Hostname:</span>\n  <span class="value">\n    <a target="_new" href="'+url+'">'+url+"</a>\n  </span>\n</div>"
return modal=new KDModalView({title:"Your VM is ready",content:"<div class='modalformline'>"+content+"</div>",cssClass:"vm-details-modal",overlay:!0,buttons:{OK:{title:"OK",cssClass:"modal-clean-green",callback:function(){return modal.destroy()}}}})}
VirtualizationController.prototype.createPaidVM=function(){var canCreatePersonalVM,canCreateSharedVM,content,group,paymentController,vmController,_this=this
if(!this.dialogIsOpen){vmController=KD.getSingleton("vmController")
paymentController=KD.getSingleton("paymentController")
canCreateSharedVM=__indexOf.call(KD.config.roles,"owner")>=0||__indexOf.call(KD.config.roles,"admin")>=0
canCreatePersonalVM=__indexOf.call(KD.config.roles,"member")>=0
group=KD.getSingleton("groupsController").getGroupSlug()
if(canCreateSharedVM)content="You can create a <b>Personal</b> or <b>Shared</b> VM for\n<b>"+group+"</b>. If you prefer to create a shared VM, all\nmembers in <b>"+group+"</b> will be able to use that VM."
else{if(!canCreatePersonalVM)return new KDNotificationView({title:"You are not authorized to create VMs in "+group+" group"})
content="You can create a <b>Personal</b> VM in <b>"+group+"</b>."}return vmController.fetchVMPlans(function(err,plans){var d,descPartial,descriptions,form,hideLoaders,hostTypes,modal,_i,_len,_ref
_this.paymentPlans=plans
_ref=vmController.sanitizeVMPlansForInputs(plans),descriptions=_ref.descriptions,hostTypes=_ref.hostTypes
descPartial=""
for(_i=0,_len=descriptions.length;_len>_i;_i++){d=descriptions[_i]
descPartial+="<section>\n  <p>\n    <i>Good for:</i>\n    <span>"+d.meta.goodFor+"</span>\n    <cite>users</cite>\n  </p>\n  "+d.description+"\n</section>"}modal=new KDModalViewWithForms({title:"Create a new VM",cssClass:"group-creation-modal",height:"auto",width:500,overlay:!0,tabs:{navigable:!1,forms:{"Create VM":{callback:function(formData){return paymentController.confirmPayment(formData.type,_this.paymentPlans[formData.host],function(){modal.destroy()
return KD.track("User Clicked Buy VM",KD.nick())})},buttons:{user:{title:"Create a <b>Personal</b> VM",style:"modal-clean-gray",type:"submit",loader:{color:"#ffffff",diameter:12},callback:function(){var form
form=modal.modalTabs.forms["Create VM"]
return form.inputs.type.setValue("user")}},group:{title:"Create a <b>Shared</b> VM",style:"modal-clean-gray hidden",type:"submit",loader:{color:"#ffffff",diameter:12},callback:function(){var form
form=modal.modalTabs.forms["Create VM"]
return form.inputs.type.setValue("group")}},cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}},fields:{intro:{itemClass:KDCustomHTMLView,partial:"<p>"+content+"</p>"},selector:{name:"host",itemClass:HostCreationSelector,cssClass:"host-type",radios:hostTypes,defaultValue:0,validate:{rules:{required:!0},messages:{required:"Please select a VM type!"}},change:function(){}},desc:{itemClass:KDCustomHTMLView,cssClass:"description-field hidden",partial:descPartial},type:{name:"type",type:"hidden"}}}}}})
canCreateSharedVM&&modal.modalTabs.forms["Create VM"].buttons.group.show()
_this.dialogIsOpen=!0
modal.once("KDModalViewDestroyed",function(){return _this.dialogIsOpen=!1})
form=modal.modalTabs.forms["Create VM"]
hideLoaders=function(){var user,_ref1
_ref1=form.buttons,group=_ref1.group,user=_ref1.user
user.hideLoader()
return group.hideLoader()}
vmController.on("PaymentModalDestroyed",hideLoaders)
return form.on("FormValidationFailed",hideLoaders)})}}
VirtualizationController.prototype.askForApprove=function(command,callback){var button,content,modal,_this=this
switch(command){case"vm.stop":case"vm.shutdown":content="<p>Turning off your VM will <b>stop</b> running Terminal\ninstances and all running proccesess that you have on\nyour VM. Do you want to continue?</p>"
button={title:"Turn off",style:"modal-clean-red"}
break
case"vm.reinitialize":content="<p>Re-initializing your VM will <b>reset</b> all of your\nsettings that you've done in root filesystem. This\nprocess will not remove any of your files under your\nhome directory. Do you want to continue?</p>"
button={title:"Re-initialize",style:"modal-clean-red"}
break
case"vm.remove":content="<p>Removing this VM will <b>destroy</b> all the data in\nthis VM including all other users in filesystem. <b>Please\nbe careful this process cannot be undone.</b></p>\n\n<p>Do you want to continue?</p>"
button={title:"Remove VM",style:"modal-clean-red"}
break
default:return callback(!0)}if(!this.dialogIsOpen){modal=new KDModalView({title:"Approval required",content:"<div class='modalformline'>"+content+"</div>",cssClass:"vm-approval",height:"auto",overlay:!0,buttons:{Action:{title:button.title,style:button.style,callback:function(){modal.destroy()
return callback(!0)}},Cancel:{style:"modal-clean-gray",callback:function(){modal.destroy()
return callback(!1)}}}})
modal.once("KDModalViewDestroyed",function(){return callback(!1)})
this.dialogIsOpen=!0
return modal.once("KDModalViewDestroyed",function(){return _this.dialogIsOpen=!1})}}
VirtualizationController.prototype.askToTurnOn=function(options,callback){var appName,content,modal,state,title,vmName,_ref,_runAppAfterStateChanged,_this=this
"function"==typeof options&&(_ref=[callback,options],options=_ref[0],callback=_ref[1])
appName=options.appName,vmName=options.vmName,state=options.state
if(!this.dialogIsOpen){title="Your VM is turned off"
content="To "+(appName?"run":"do this")+" <b>"+appName+"</b>\nyou need to turn on your VM first, you can do that by\nclicking '<b>Turn ON VM</b>' button below."
if(!this.defaultVmName){title="You don't have any VM"
content="To "+(appName?"use":"do this")+"\n<b>"+(appName||"")+"</b> you need to have at lease one VM\ncreated, you can do that by clicking '<b>Create Default\nVM</b>' button below."}if("MAINTENANCE"===state){title="Your VM is under maintenance"
content="Your VM <b>"+vmName+"</b> is <b>UNDER MAINTENANCE</b> now,\n"+(appName?"to run <b>"+appName+"</b> app":void 0)+" please try\nagain later."}_runAppAfterStateChanged=function(appName,vmName){var params
if(appName){vmName&&(params={params:{vmName:vmName}})
return _this.once("StateChanged",function(err,vm,info){return!err&&info&&"RUNNING"===info.state&&vm===vmName?KD.utils.wait(1200,function(){return KD.getSingleton("appManager").open(appName,params)}):void 0})}}
modal=new KDModalView({title:title,content:"<div class='modalformline'><p>"+content+"</p></div>",height:"auto",overlay:!0,buttons:{"Turn ON VM":{style:"modal-clean-green",callback:function(){_runAppAfterStateChanged(appName,vmName)
return _this.start(vmName,function(){modal.destroy()
return"function"==typeof callback?callback():void 0})}},"Create Default VM":{style:"modal-clean-green",callback:function(){_runAppAfterStateChanged(appName)
_this.createNewVM(callback)
return modal.destroy()}},Cancel:{style:"modal-cancel",callback:function(){modal.destroy()
return"function"==typeof callback?callback({cancel:!0}):void 0}}}})
this.defaultVmName?modal.buttons["Create Default VM"].destroy():modal.buttons["Turn ON VM"].destroy()
"MAINTENANCE"===state&&modal.setButtons({Ok:{style:"modal-clean-gray",callback:function(){modal.destroy()
return"function"==typeof callback?callback({cancel:!0}):void 0}}},!0)
modal.once("KDModalViewDestroyed",function(){return"function"==typeof callback?callback({destroy:!0}):void 0})
this.dialogIsOpen=!0
return modal.once("KDModalViewDestroyed",function(){return _this.dialogIsOpen=!1})}}
VirtualizationController.prototype.fetchVMPlans=function(callback){var _this=this
this.emit("VMPlansFetchStart")
return KD.remote.api.JRecurlyPlan.getPlans("group","vm",function(err,plans){err?warn(err):plans&&plans.sort(function(a,b){return a.feeMonthly-b.feeMonthly})
_this.emit("VMPlansFetchEnd")
return callback(err,plans)})}
VirtualizationController.prototype.sanitizeVMPlansForInputs=function(plans){var descriptions,hostTypes
descriptions=[]
hostTypes=plans.map(function(plan,i){var e,feeMonthly,item
descriptions.push(item=function(){try{return JSON.parse(plan.desc.replace(/&quot;/g,'"'))}catch(_error){e=_error
return{title:"",description:plan.desc,meta:{goodFor:0}}}}())
plans[i].item=item
feeMonthly=(plan.feeMonthly/100).toFixed(0)
return{title:item.title,value:i,feeMonthly:feeMonthly}})
return{descriptions:descriptions,hostTypes:hostTypes}}
VirtualizationController.prototype.parseAlias=function(alias){var groupSlug,nickname,prefix,rest,result,uid,_i,_j
if(/^shared\-[0-9]+/.test(alias)){result=alias.match(/(.*)\.([a-z0-9\-]+)\.kd\.io$/)
if(result){rest=3<=result.length?__slice.call(result,0,_i=result.length-2):(_i=0,[]),prefix=result[_i++],groupSlug=result[_i++]
uid=parseInt(prefix.split(/-/)[1],10)
return{groupSlug:groupSlug,prefix:prefix,uid:uid,type:"group",alias:alias}}}else if(/^vm\-[0-9]+/.test(alias)){result=alias.match(/(.*)\.([a-z0-9\-]+)\.([a-z0-9\-]+)\.kd\.io$/)
if(result){rest=4<=result.length?__slice.call(result,0,_j=result.length-3):(_j=0,[]),prefix=result[_j++],nickname=result[_j++],groupSlug=result[_j++]
uid=parseInt(prefix.split(/-/)[1],10)
return{groupSlug:groupSlug,prefix:prefix,nickname:nickname,uid:uid,type:"user",alias:alias}}}return null}
return VirtualizationController}(KDController)

var ModalAppsListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ModalAppsListItemView=function(_super){function ModalAppsListItemView(options,data){var _this=this
options.cssClass="topic-item"
ModalAppsListItemView.__super__.constructor.call(this,options,data)
this.titleLink=new AppLinkView({expandable:!1},data)
this.titleLink.on("click",function(){return _this.getDelegate().emit("CloseTopicsModal")})
this.img=KD.utils.getAppIcon(this.getData(),"modal-app-icon")}__extends(ModalAppsListItemView,_super)
ModalAppsListItemView.prototype.pistachio=function(){return'<div class="app-title">\n  {{> this.img}}\n  {{> this.titleLink}}\n</div>\n<div class="stats">\n  <p class="installs">\n    <span class="icon"></span>{{#(counts.installed) || 0}} Installs\n  </p>\n  <p class="fers">\n    <span class="icon"></span>{{#(counts.followers) || 0}} Followers\n  </p>\n</div>'}
ModalAppsListItemView.prototype.viewAppended=JView.prototype.viewAppended
return ModalAppsListItemView}(KDListItemView)

var Status,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Status=function(_super){function Status(){Status.__super__.constructor.apply(this,arguments)
this.registerSingleton("status",this)
this.state=NOTSTARTED
this.connectionState=DOWN
this.remote=KD.remote
this.remote.on("connected",this.bound("connected"))
this.remote.on("disconnected",this.bound("disconnected"))
this.remote.on("sessionTokenChanged",this.bound("sessionTokenChanged"))
this.remote.on("loggedInStateChanged",this.bound("loggedInStateChanged"))}var CONNECTED,DISCONNECTED,DOWN,NOTSTARTED,RECONNECTED,UP,_ref,_ref1
__extends(Status,_super)
_ref=[1,2,3,4],NOTSTARTED=_ref[0],CONNECTED=_ref[1],RECONNECTED=_ref[2],DISCONNECTED=_ref[3]
_ref1=[1,2,3],NOTSTARTED=_ref1[0],UP=_ref1[1],DOWN=_ref1[2]
Status.prototype.resetLocals=function(){return delete this.disconnectOptions}
Status.prototype.connect=function(){return this.remote.connect()}
Status.prototype.disconnect=function(options){var autoReconnect
null==options&&(options={})
"boolean"==typeof options&&(options={autoReconnect:options})
log("status",options)
autoReconnect=options.autoReconnect
this.remote.disconnect(autoReconnect)
this.disconnectOptions=options
return this.disconnected()}
Status.prototype.connected=function(){this.connectionState=UP
if(this.state===NOTSTARTED){this.state=CONNECTED
return this.emit("connected")}this.state=RECONNECTED
this.emit("reconnected",this.disconnectOptions)
this.startPingingKites()
return this.resetLocals()}
Status.prototype.startPingingKites=function(){return this.eachKite(function(channel){return channel.setStartPinging()})}
Status.prototype.disconnected=function(){if(this.connectionState===DOWN)return"already disconnected"
this.stopPingingKites()
this.connectionState=DOWN
this.state=DISCONNECTED
return this.emit("disconnected",this.disconnectOptions)}
Status.prototype.stopPingingKites=function(){return this.eachKite(function(channel){return channel.setStopPinging()})}
Status.prototype.eachKite=function(callback){var channel,channelName,kiteChannels,_results
kiteChannels=KD.getSingleton("kiteController").channels
_results=[]
for(channelName in kiteChannels)if(__hasProp.call(kiteChannels,channelName)){channel=kiteChannels[channelName]
_results.push(callback(channel))}return _results}
Status.prototype.internetUp=function(){return this.connectionState===DOWN?this.connected():void 0}
Status.prototype.internetDown=function(){return this.connectionState===UP?this.disconnect({autoReconnect:!0,reason:"internetDown"}):void 0}
Status.prototype.loggedInStateChanged=function(account){this.emit("bongoConnected",account)
this.registerBongoAndBroker()
return this.registerKites()}
Status.prototype.registerBongoAndBroker=function(){var bongo,broker,monitorItems
bongo=KD.remote
broker=KD.remote.mq
monitorItems=KD.getSingleton("monitorItems")
return monitorItems.register({bongo:bongo,broker:broker})}
Status.prototype.registerKites=function(){var kite,monitorItems
monitorItems=KD.getSingleton("monitorItems")
kite=KD.getSingleton("kiteController")
kite.on("channelAdded",function(channel,name){monitorItems.getItems()[name]=channel
return channel.on("unresponsive",function(){return KD.troubleshoot(!1)})})
return kite.on("channelDeleted",function(channel,name){return delete monitorItems.getItems()[name]})}
Status.prototype.sessionTokenChanged=function(token){return this.emit("sessionTokenChanged",token)}
return Status}(KDController)

!function(){var bigDisconnectedModal,bigReconnectedModal,currentModal,currentModalSize,destroyCurrentModal,firstLoad,mainController,modalTimerId,modals,showModal,smallDisconnectedModal,smallReconnectedModal,status
status=new Status
mainController=new MainController
modalTimerId=null
currentModal=null
currentModalSize=null
firstLoad=!0
mainController.tempStorage={}
status.on("bongoConnected",function(account){KD.socketConnected()
mainController.accountChanged(account,firstLoad)
return firstLoad=!1})
status.on("sessionTokenChanged",function(token){return $.cookie("clientId",token)})
status.on("connected",function(){destroyCurrentModal()
return log("kd remote connected")})
status.on("reconnected",function(options){var modalSize,notifyUser,state
null==options&&(options={})
destroyCurrentModal()
modalSize=options.modalSize||(options.modalSize="big")
notifyUser=options.notifyUser||(options.notifyUser="yes")
state="reconnected"
log("kd remote re-connected, modalSize: "+modalSize)
clearTimeout(modalTimerId)
modalTimerId=null
modalSize=currentModalSize||options.modalSize
notifyUser=options.notifyUser
return notifyUser||currentModal?showModal(modalSize,state):void 0})
status.on("disconnected",function(options){var modalSize,notifyUser,reason,state
null==options&&(options={})
reason=options.reason||(options.reason="unknown")
modalSize=options.modalSize||(options.modalSize="big")
notifyUser=options.notifyUser||(options.notifyUser="yes")
state="disconnected"
log("disconnected","reason: "+reason+", modalSize: "+modalSize+", notifyUser: "+notifyUser)
notifyUser&&(modalTimerId=setTimeout(function(){currentModalSize=modalSize
return showModal(modalSize,state)},2e3))
return currentModalSize="small"})
KD.remote.connect()
KD.exportKDFramework()
bigDisconnectedModal=function(){return currentModal=new KDBlockingModalView({title:"Something went wrong.",content:"<div class='modalformline'>\n  Your internet connection may be down or our servers are down temporarily.<br/><br/>\n  If you have unsaved work please close this dialog and <br/><strong>back up your unsaved work locally</strong> until the connection is re-established.<br/><br/>\n  <span class='small-loader fade in'></span> Trying to reconnect...\n</div>",height:"auto",overlay:!0,buttons:{"Close and work offline":{style:"modal-clean-red",callback:function(){return showModal("small","disconnected")}}}})}
smallDisconnectedModal=function(){return currentModal=new KDNotificationView({title:"Trying to reconnect...",type:"tray",closeManually:!1,content:"Server connection has been lost, changes will not be saved until server reconnects, please back up locally.",duration:0})}
bigReconnectedModal=function(){return currentModal=new KDNotificationView({title:"Reconnected",type:"tray",content:"Server connection has been reset, you can continue working.",duration:3e3})}
smallReconnectedModal=function(){return currentModal=new KDNotificationView({title:"<span></span>Reconnected, Welcome Back!",type:"tray",cssClass:"small realtime",duration:3303})}
modals={big:{disconnected:bigDisconnectedModal,reconnected:bigReconnectedModal},small:{disconnected:smallDisconnectedModal,reconnected:smallReconnectedModal,disconnectedMin:smallDisconnectedModal}}
showModal=function(size,state){var modal
destroyCurrentModal()
currentModalSize=size
modal=modals[size][state]
return"function"==typeof modal?modal():void 0}
return destroyCurrentModal=function(){null!=currentModal&&currentModal.destroy()
return currentModal=null}}()

var BrokerPing,ExternalPing,MonitorItems,MonitorStatus,Ping,brokerPing,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Ping=function(_super){function Ping(item,name,options){null==options&&(options={})
Ping.__super__.constructor.call(this,options)
this.item=item
this.name=name
this.identifier=options.identifier||Date.now()
this.status=NOTSTARTED}var FAILED,NOTSTARTED,SUCCESS,WAITING,_ref
__extends(Ping,_super)
_ref=[1,2,3,4],NOTSTARTED=_ref[0],WAITING=_ref[1],SUCCESS=_ref[2],FAILED=_ref[3]
Ping.prototype.run=function(){this.status=WAITING
this.startTime=Date.now()
this.setPingTimeout()
return this.item.ping(this.finish.bind(this))}
Ping.prototype.setPingTimeout=function(){var _this=this
return this.pingTimeout=setTimeout(function(){_this.status=FAILED
return _this.emit("failed",_this.item,_this.name)},5e3)}
Ping.prototype.finish=function(){this.status=SUCCESS
this.finishTime=Date.now()
clearTimeout(this.pingTimeout)
this.pingTimeout=null
return this.emit("finish",this.item,this.name)}
Ping.prototype.getResponseTime=function(){var status
status=function(){switch(this.status){case NOTSTARTED:return"not started"
case FAILED:return"failed"
case SUCCESS:return this.finishTime-this.startTime
case"WAITING":return"waiting"}}.call(this)
return status}
return Ping}(KDObject)
MonitorItems=function(_super){function MonitorItems(options){null==options&&(options={})
MonitorItems.__super__.constructor.call(this,this.options)
this.items={}
this.registerSingleton("monitorItems",this)}__extends(MonitorItems,_super)
MonitorItems.prototype.register=function(items){var item,name,_results
_results=[]
for(name in items)if(__hasProp.call(items,name)){item=items[name]
_results.push(this.items[name]=item)}return _results}
MonitorItems.prototype.getItems=function(){return this.items}
return MonitorItems}(KDObject)
MonitorStatus=function(_super){function MonitorStatus(items,options){null==options&&(options={})
MonitorStatus.__super__.constructor.call(this,this.options)
this.itemsToMonitor={}
this.reset()
this.copyItemsToMonitor(items)
this.setupListerners()}__extends(MonitorStatus,_super)
MonitorStatus.prototype.copyItemsToMonitor=function(items){var item,name,_results
_results=[]
for(name in items)if(__hasProp.call(items,name)){item=items[name]
_results.push(this.itemsToMonitor[name]=new Ping(item,name))}return _results}
MonitorStatus.prototype.setupListerners=function(){this.on("pingFailed",function(item,name){this.failedPings.push(name)
return this.emit("pingDone",item,name)})
this.on("pingDone",function(item,name){this.finishedPings.push(name)
return _.size(this.finishedPings)===_.size(this.itemsToMonitor)?this.emit("allDone"):void 0})
this.on("allDone",function(){this.emitStatus()
this.printReport()
return this.reset()})
return this.on("internetDown",function(){var status
status=KD.getSingleton("status")
return status.internetDown()})}
MonitorStatus.prototype.notify=function(reason){var msg,notification,notifications
if(this.showNotifications){notifications={internetUp:"All systems go!",internetDown:"Your internet is down.",brokerDown:"Broker is down.",kitesDown:"Kites are down.",bongoDown:"Bongo is down.",undefined:"Sorry, something went wrong."}
msg=notifications[reason]||notifications.undefined
return notification=new KDNotificationView({title:"<span></span>"+msg,type:"tray",cssClass:"mini realtime",duration:3303,click:noop})}}
MonitorStatus.prototype.reset=function(){this.finishedPings=[]
return this.failedPings=[]}
MonitorStatus.prototype.emitStatus=function(){if(0===_.size(this.failedPings)){this.internetUp()
return this.notify("internetUp")}return this.deductReasonForFailure()}
MonitorStatus.prototype.deductReasonForFailure=function(){var intersection,items,reason,reasons
reasons={}
reasons.internetDown=["bongo","broker","external"]
reasons.brokerDown=["broker"]
reasons.kitesDown=["os"]
reasons.bongoDown=["bongo"]
for(reason in reasons)if(__hasProp.call(reasons,reason)){items=reasons[reason]
intersection=_.intersection(items,this.failedPings)
if(_.size(intersection)===_.size(items)){this.emit(reason,_.first(this.failedPings))
this.notify(reason)
log(reason)
return reason}}}
MonitorStatus.prototype.internetUp=function(){log("all's well on western front")
return this.emit("internetUp")}
MonitorStatus.prototype.printReport=function(){var item,name,_ref,_results
_ref=this.itemsToMonitor
_results=[]
for(name in _ref)if(__hasProp.call(_ref,name)){item=_ref[name]
_results.push(log(name,item.getResponseTime()))}return _results}
MonitorStatus.prototype.run=function(){var item,name,_ref,_results,_this=this
_ref=this.itemsToMonitor
_results=[]
for(name in _ref)if(__hasProp.call(_ref,name)){item=_ref[name]
item.once("finish",function(i,n){return _this.emit("pingDone",i,n)})
item.once("failed",function(i,n){return _this.emit("pingFailed",i,n)})
_results.push(item.run())}return _results}
return MonitorStatus}(KDObject)
ExternalPing=function(_super){function ExternalPing(url){this.url=url
ExternalPing.__super__.constructor.apply(this,arguments)}__extends(ExternalPing,_super)
ExternalPing.prototype.ping=function(callback){this.callback=callback
KD.externalPong=this.pong.bind(this)
return $.ajax({url:this.url+"?callback"+KD.externalPong,timeout:5e3,dataType:"jsonp",error:function(){}})}
ExternalPing.prototype.pong=function(){return this.callback()}
return ExternalPing}(KDObject)
!function(){var external,monitorItems,url
url="https://s3.amazonaws.com/koding-ping/ping.json"
external=new ExternalPing(url)
monitorItems=new MonitorItems
monitorItems.register({external:external})
KD.troubleshoot=function(showNotifications){var monitor
null==showNotifications&&(showNotifications=!0)
monitorItems=KD.getSingleton("monitorItems").items
if(1!==monitorItems.length){monitor=new MonitorStatus(monitorItems)
monitor.showNotifications=showNotifications
return monitor.run()}log("no services connected; possible auth/social worker down")}
return window.jsonp=function(){return KD.externalPong()}}()
BrokerPing=function(_super){function BrokerPing(options,data){BrokerPing.__super__.constructor.call(this,options,data)
this.init()}__extends(BrokerPing,_super)
BrokerPing.prototype.init=function(){this.channel=KD.remote.mq
this.remote=KD.remote
this.channel.on("messageArrived",this.bound("handleMessageArrived"))
this.channel.on("messagePublished",this.bound("handleChannelPublish"))
this.remote.on("disconnected",this.bound("reset"))
this.remote.on("disconnected",this.bound("setStopPinging"))
this.remote.on("connected",this.bound("setStartPinging"))
return this.remote.on("connected",this.bound("pingChannel"))}
BrokerPing.prototype.handleUnresponsiveChannel=function(){return log("broker unresponsive since "+this.lastPong)}
BrokerPing.prototype.pingChannel=function(callback){return this.stopPinging?void 0:this.channel.ping(callback)}
return BrokerPing}(Pinger)
brokerPing=new BrokerPing
window.brokerPing=brokerPing

if("undefined"!=typeof _rollbar&&null!==_rollbar&&KD.config.logToExternal)!function(){KD.logToExternal=function(args){return _rollbar.push(args)}
return KD.getSingleton("mainController").on("AccountChanged",function(){var user
user=("function"==typeof KD.whoami?KD.whoami().profile:void 0)||KD.whoami()
return _rollbarParams.person={id:user.hash||user.nickname,name:KD.utils.getFullnameFromAccount(),username:user.nickname}})}()
else{KD.utils.stopRollbar()
KD.logToExternal=function(){}}
var KDMixpanel,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__slice=[].slice
KDMixpanel=function(){function KDMixpanel(){this.createEvent=__bind(this.createEvent,this)}KDMixpanel.prototype.createEvent=function(){var $activity,$user,activity,appTitle,eventData,eventName,group,options,privacy,rest,title,visibility
rest=1<=arguments.length?__slice.call(arguments,0):[]
eventName=rest.first
eventData=rest[1]
$user=KD.nick()
if("Login"!==eventName&&("Groups"!==eventName||"ChangeGroup"!==eventData)){if("Connected to backend"===eventName)return this.track(eventName,KD.nick())
if("New User Signed Up"===eventName)return this.track(eventName,KD.whoami().profile)
if("User Opened Ace"===eventName){title=eventData.title,privacy=eventData.privacy,visibility=eventData.visibility
options={title:title,privacy:privacy,visibility:visibility,$user:$user}
this.setOnce("First Time Ace Opened",Date.now())
return this.track(eventName,options)}if("userOpenedTerminal"===eventName){title=eventData.title,privacy=eventData.privacy,visibility=eventData.visibility
options={title:title,privacy:privacy,visibility:visibility,$user:$user}
this.setOnce("First Time Terminal Opened",Date.now())
return this.track("User Opened Terminal",options)}if("Apps"===eventName&&"Install"===eventData){appTitle=rest[2]
options={$user:$user,appTitle:appTitle}
return this.track("Application Installed",options)}if("User Clicked Buy VM"===eventName)return this.track(eventName,$user)
if("Read Tutorial Book"===eventName)return this.track(eventName,$user)
if("Activity"===eventName){eventName="User Post Activity"
activity="Status Updated"
switch(eventData){case"StatusUpdateSubmitted":activity="Status Updated"
break
case"BlogPostSubmitted":activity="Blog Post"
break
case"TutorialSubmitted":activity="Tutorial Submitted"
break
case"DiscussionSubmitted":activity="Discussion Started"}group=KD.getSingleton("groupsController").getCurrentGroup()
$activity=activity
title=group.title,privacy=group.privacy,visibility=group.visibility
options={title:title,privacy:privacy,visibility:visibility,$user:$user,$activity:$activity}
return this.track(eventName,options)}if("Groups"===eventName&&"JoinedGroup"===eventData)return this.track("User Joined Group",{group:rest[2]})
if("Groups"===eventName&&"CreateNewGroup"===eventData)return this.track("User Created Group",{group:rest[2]})
if("Members"===eventName&&"OwnProfileView"===eventData)return this.track("User Viewed Self Profile",{$username:rest[2]})
if("Members"===eventName&&"ProfileView"===eventData)return this.track("User Viewed Profile",{$username:rest[2]})
if("Apps"===eventName&&"ApplicationDelete"===eventData)return this.track("User Deleted Application",{$username:rest[2]})
if("GroupJoinRequest"===eventData){group=rest[3]
title=group.title,privacy=group.privacy,visibility=group.visibility
options={title:title,privacy:privacy,visibility:visibility,$user:$user}
return this.track("Group Join Request",options)}if("InvitationSentToFriend"===eventData){options={$user:$user,$recipient:rest[2]}
return this.track("Invitation Send",options)}return log("Warning: Unknown mixpanel event set",rest)}}
KDMixpanel.prototype.track=function(eventName,properties,callback){return mixpanel.track(eventName,properties,callback)}
KDMixpanel.prototype.trackPageView=function(pageURL){return mixpanel.track_pageview(pageURL)}
KDMixpanel.prototype.getProperty=function(name){return mixpanel.get_property(name)}
KDMixpanel.prototype.incrementUserProperty=function(property,incrementBy){null==incrementBy&&(incrementBy=1)
return mixpanel.people.increment(property,incrementBy)}
KDMixpanel.prototype.registerUser=function(){var user
if(KD.isLoggedIn()){user=KD.whoami()
mixpanel.identify(user.profile.nickname)
mixpanel.people.set({$username:user.profile.nickname,name:""+user.profile.firstName+" "+user.profile.lastName,$joinDate:user.meta.createdAt})
return mixpanel.name_tag(""+user.profile.nickname+".kd.io")}}
KDMixpanel.prototype.setOnce=function(property,value,callback){return mixpanel.people.set_once(property,value,callback)}
return KDMixpanel}()
mixpanel&&KD.config.logToExternal&&function(){return KD.getSingleton("mainController").on("AccountChanged",function(account){var createdAt,firstName,lastName,nickname,_ref
if(KD.isLoggedIn()){createdAt=account.meta.createdAt
_ref=account.profile,firstName=_ref.firstName,lastName=_ref.lastName,nickname=_ref.nickname
mixpanel.identify(nickname)
mixpanel.people.set({$username:nickname,name:""+firstName+" "+lastName,$joinDate:createdAt})
return mixpanel.name_tag(""+nickname+".kd.io")}})}()

var __slice=[].slice
!function(){var logToGoogle
KD.kdMixpanel=new KDMixpanel
KD.track=function(){var rest,_ref
rest=1<=arguments.length?__slice.call(arguments,0):[]
logToGoogle.apply(null,rest)
return(_ref=KD.kdMixpanel).createEvent.apply(_ref,rest)}
KD.mixpanel=mixpanel.track.bind(mixpanel)
KD.mixpanel.alias=mixpanel.alias.bind(mixpanel)
return logToGoogle=function(){var action,category,rest,trackArray
rest=1<=arguments.length?__slice.call(arguments,0):[]
category=action=rest.first
trackArray=["_trackEvent",category,action]
return _gaq.push(trackArray)}}()

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
return new NFinderController(options)}
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
this.on("drop",function(){return _this.unsetClass("hover")})}this.on("uploadFile",function(fsFile,percent){var filePath,_ref
filePath="["+fsFile.vmName+"]"+fsFile.path
return null!=(_ref=_this.finder.treeController.nodes[filePath])?_ref.showProgressView(percent):void 0})
this.on("uploadStart",function(fsFile){var bindAbort,filePath,nodeView,parentPath
filePath="["+fsFile.vmName+"]"+fsFile.path
parentPath="["+fsFile.vmName+"]"+fsFile.parentPath
bindAbort=function(nodeView){return nodeView.once("abortProgress",function(){return fsFile.abort(!0)})}
nodeView=_this.finder.treeController.nodes[filePath]
if(nodeView)return bindAbort(nodeView)
_this.finder.treeController.on("NodeWasAdded",function(nodeView){return nodeView.getData().path===filePath?bindAbort(nodeView):void 0})
return fsFile.save("",function(){return _this.finder.expandFolders(FSHelper.getPathHierarchy(parentPath))})})}__extends(DNDUploader,_super)
DNDUploader.prototype.viewAppended=function(){var tc
DNDUploader.__super__.viewAppended.apply(this,arguments)
this.finder=KD.getSingleton("finderController")
tc=this.finder.treeController
return this.notify=tc.notify.bind(tc)}
DNDUploader.prototype.reset=function(){var defaultPath,title,uploadToVM,_ref
_ref=this.getOptions(),uploadToVM=_ref.uploadToVM,defaultPath=_ref.defaultPath,title=_ref.title
this.setPath()
this.updatePartial('<div class="file-drop">\n  '+(title||"Drop files here!")+"\n  <small>"+(uploadToVM?defaultPath:"")+"</small>\n</div>")
return this._uploaded={}}
DNDUploader.prototype.drop=function(event){var entry,files,item,items,_i,_len,_ref,_ref1,_results,_this=this
DNDUploader.__super__.drop.apply(this,arguments)
_ref=event.originalEvent.dataTransfer,files=_ref.files,items=_ref.items
files.length>=20&&this.notify("Too many files to transfer!<br>\nArchive your files and try again.","error","Max 20 files allowed to upload at once.\nYou can archive your files and try again.")
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
if(sizeInMb>100&&this.getOptions().uploadToVM)this.notify("Too big file to upload.","error","Max 100MB allowed per file.")
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
this.path=null!=path?path:this.options.defaultPath
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
OpenWithModalItem.prototype.pistachio=function(){return"{{> this.img}}\n{div.app-name{#(name)}}"}
return OpenWithModalItem}(JView)

var OpenWithModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OpenWithModal=function(_super){function OpenWithModal(options,data){var appManager,appName,apps,appsController,extensionToApp,fileExtension,fileName,label,manifest,modal,nodeView,supportedApps,_i,_len,_ref,_this=this
null==options&&(options={})
OpenWithModal.__super__.constructor.call(this,options,data)
_ref=this.getData(),nodeView=_ref.nodeView,apps=_ref.apps
appsController=KD.getSingleton("kodingAppsController")
appManager=KD.getSingleton("appManager")
fileName=FSHelper.getFileNameFromPath(nodeView.getData().path)
fileExtension=FSItem.getFileExtension(fileName)
modal=new KDModalView({title:"Choose application to open "+fileName,cssClass:"open-with-modal",overlay:!0,width:400,buttons:{Open:{title:"Open",style:"modal-clean-green",callback:function(){var appName
appName=modal.selectedApp.getData().name
_this.alwaysOpenWith.getValue()&&appsController.emit("UpdateDefaultAppConfig",fileExtension,appName)
appManager.openFileWithApplication(appName,nodeView.getData())
return modal.destroy()}},Cancel:{title:"Cancel",style:"modal-cancel",callback:function(){return modal.destroy()}}}})
extensionToApp=appsController.extensionToApp
supportedApps=extensionToApp[fileExtension]||extensionToApp.txt
for(_i=0,_len=supportedApps.length;_len>_i;_i++){appName=supportedApps[_i]
modal.addSubView(new OpenWithModalItem({supported:!0,delegate:modal},"Ace"===appName?KD.getAppOptions("Ace"):apps[appName]))}modal.addSubView(new KDView({cssClass:"separator"}))
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
options.useStorage&&this.appStorage.ready(function(){_this.treeController.on("file.opened",_this.bound("setRecentFile"))
_this.treeController.on("folder.expanded",function(folder){return _this.setRecentFolder(folder.path)})
return _this.treeController.on("folder.collapsed",function(_arg){var path
path=_arg.path
_this.unsetRecentFolder(path)
return _this.stopWatching(path)})})
this.noVMFoundWidget=new VMMountStateWidget
this.cleanup()
KD.getSingleton("vmController").on("StateChanged",this.bound("checkVMState"))}__extends(NFinderController,_super)
NFinderController.prototype.watchers={}
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
this.vms.push(FSHelper.createFile({name:""+path,path:"["+vmName+"]"+path,type:"vm",vmName:vmName}))
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
NFinderTreeController.prototype.setDotFiles=function(nodeView,show){var finder,path,vmName,_ref
null==show&&(show=!0)
_ref=nodeView.getData(),vmName=_ref.vmName,path=_ref.path
finder=this.getDelegate()
return show?finder.showDotFiles(vmName):finder.hideDotFiles(vmName)}
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
return _this.hideNotification()},failCallback,1e4),!1)}"function"==typeof callback&&callback(null,nodeView)}}
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
return FSItem.create(path,type,vmName,function(err,file){return err?_this.notify(null,null,err):_this.refreshFolder(_this.nodes[parentPath],function(){var node
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
NFinderTreeController.prototype.compileApp=function(nodeView,callback){var folder,kodingAppsController,manifest,_this=this
folder=nodeView.getData()
folder.emit("fs.job.started")
kodingAppsController=KD.getSingleton("kodingAppsController")
manifest=KodingAppsController.getManifestFromPath(folder.path)
return kodingAppsController.compileApp(manifest.name,function(err){folder.emit("fs.job.finished")
if(!err){_this.notify("App compiled!","success")
_this.utils.wait(500,function(){return _this.refreshFolder(nodeView,function(){return _this.utils.defer(function(){return _this.selectNode(_this.nodes[""+folder.path+"/index.js"])})})})}return"function"==typeof callback?callback(err):void 0})}
NFinderTreeController.prototype.runApp=function(nodeView,callback){var folder,kodingAppsController,manifest
folder=nodeView.getData()
folder.emit("fs.job.started")
kodingAppsController=KD.getSingleton("kodingAppsController")
manifest=KodingAppsController.getManifestFromPath(folder.path)
return KD.getSingleton("appManager").open(manifest.name,function(){folder.emit("fs.job.finished")
return"function"==typeof callback?callback():void 0})}
NFinderTreeController.prototype.cloneRepo=function(nodeView){var folder,modal,_this=this
folder=nodeView.getData()
modal=new CloneRepoModal({vmName:folder.vmName,path:folder.path})
return modal.on("RepoClonedSuccessfully",function(){return _this.notify("Repo cloned successfully.","success")})}
NFinderTreeController.prototype.publishApp=function(nodeView){var folder,_this=this
folder=nodeView.getData()
folder.emit("fs.job.started")
return KD.getSingleton("kodingAppsController").publishApp(folder.path,function(err){var message,modal
folder.emit("fs.job.finished")
if(err){_this.notify("Publish failed!","error",err)
message=err.message||err
return modal=new KDModalView({title:"Publish failed!",overlay:!0,cssClass:"new-kdmodal",content:"<div class='modalformline'>"+message+"</div>",buttons:{Close:{style:"modal-clean-gray",callback:function(){return modal.destroy()}}}})}return _this.notify("App published!","success")})}
NFinderTreeController.prototype.makeNewApp=function(){return KD.getSingleton("kodingAppsController").makeNewApp()}
NFinderTreeController.prototype.downloadAppSource=function(nodeView){var folder,_this=this
folder=nodeView.getData()
folder.emit("fs.job.started")
return KD.getSingleton("kodingAppsController").downloadAppSource(folder.path,function(err){folder.emit("fs.job.finished")
_this.refreshFolder(_this.nodes[folder.parentPath])
return err?_this.notify("Download failed!","error",err):_this.notify("Source downloaded!","success")})}
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
NFinderTreeController.prototype.cmShowDotFiles=function(nodeView){return this.setDotFiles(nodeView,!0)}
NFinderTreeController.prototype.cmHideDotFiles=function(nodeView){return this.setDotFiles(nodeView,!1)}
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
NFinderTreeController.prototype.cmCompile=function(nodeView){return this.compileApp(nodeView)}
NFinderTreeController.prototype.cmRunApp=function(nodeView){return this.runApp(nodeView)}
NFinderTreeController.prototype.cmMakeNewApp=function(nodeView){return this.makeNewApp(nodeView)}
NFinderTreeController.prototype.cmDownloadApp=function(nodeView){return this.downloadAppSource(nodeView)}
NFinderTreeController.prototype.cmCloneRepo=function(nodeView){return this.cloneRepo(nodeView)}
NFinderTreeController.prototype.cmPublish=function(nodeView){return this.publishApp(nodeView)}
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
items={"Open File":{separator:!0,action:"openFile"},Delete:{action:"delete",separator:!0},Rename:{action:"rename"},Duplicate:{action:"duplicate"},"Set permissions":{children:{customView:new NSetPermissionsView({},fileData)}},Extract:{action:"extract"},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},Download:{separator:!0,action:"download",disabled:!0},"Public URL...":{separator:!0},"New File":{action:"createFile"},"New Folder":{action:"createFolder"},"Upload to Dropbox":{action:"dropboxSaver"}}
"archive"!==FSItem.getFileType(FSItem.getFileExtension(fileData.name))?delete items.Extract:delete items.Compress
FSHelper.isPublicPath(fileData.path)?items["Public URL..."].children={customView:new NCopyUrlView({},fileData)}:delete items["Public URL..."]
return items}
NFinderContextMenuController.prototype.getFolderMenu=function(fileView){var fileData,items,nickname
fileData=fileView.getData()
items={Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},"Make this top Folder":{action:"makeTopFolder",separator:!0},Delete:{action:"delete",separator:!0},Rename:{action:"rename"},Duplicate:{action:"duplicate"},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},"Set permissions":{separator:!0,children:{customView:new NSetPermissionsView({},fileData)}},"New File":{action:"createFile"},"New Folder":{action:"createFolder"},"Upload file...":{action:"upload"},"Clone a repo here":{action:"cloneRepo"},Download:{disabled:!0,action:"download",separator:!0},Dropbox:{children:{"Download from Dropbox":{action:"dropboxChooser"},"Upload to Dropbox":{action:"dropboxSaver"}},separator:!0},"Public URL...":{separator:!0},Refresh:{action:"refresh"}}
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
NFinderContextMenuController.prototype.getVmMenu=function(fileView){var fc,fileData,items
fileData=fileView.getData()
items={Refresh:{action:"refresh",separator:!0},"Unmount VM":{action:"unmountVm"},"Open VM Terminal":{action:"openVmTerminal",separator:!0},Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},"Hide Invisible Files":{action:"hideDotFiles",separator:!0},"Show Invisible Files":{action:"showDotFiles",separator:!0},"New File":{action:"createFile"},"New Folder":{action:"createFolder"},"Upload file...":{action:"upload"}}
fileView.expanded?delete items.Expand:delete items.Collapse
fc=KD.getSingleton("finderController")
fc.isNodesHiddenFor(fileData.vmName)?delete items["Hide Invisible Files"]:delete items["Show Invisible Files"]
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
items={Delete:{action:"delete",separator:!0},Duplicate:{action:"duplicate"},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},Download:{disabled:!0,action:"download"}}
return items}
NFinderContextMenuController.prototype.getMultipleFolderMenu=function(folderViews){var allCollapsed,allExpanded,folderView,items,multipleText,_i,_len
items={Expand:{action:"expand",separator:!0},Collapse:{action:"collapse",separator:!0},Delete:{action:"delete",separator:!0},Duplicate:{action:"duplicate"},"Set permissions":{children:{customView:new NSetPermissionsView({},{mode:"000",type:"multiple"})}},Compress:{children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},Download:{disabled:!0,action:"download"}}
multipleText="Delete "+folderViews.length+" folders"
items.Delete=items[multipleText]={action:"delete"}
allCollapsed=allExpanded=!0
for(_i=0,_len=folderViews.length;_len>_i;_i++){folderView=folderViews[_i]
folderView.expanded?allCollapsed=!1:allExpanded=!1}allCollapsed&&delete items.Collapse
allExpanded&&delete items.Expand
return items}
NFinderContextMenuController.prototype.getMultipleFileMenu=function(fileViews){var items,multipleText
items={"Open Files":{action:"openFile"},Delete:{action:"delete",separator:!0},Duplicate:{action:"duplicate"},"Set permissions":{children:{customView:new NSetPermissionsView({},{mode:"000"})}},Compress:{separator:!0,children:{"as .zip":{action:"zip"},"as .tar.gz":{action:"tarball"}}},Download:{disabled:!0,action:"download"}}
multipleText="Delete "+fileViews.length+" files"
items.Delete=items[multipleText]={action:"delete"}
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
NFileItemView=function(_super){function NFileItemView(options,data){var ev,fileData,_i,_len,_this=this
null==options&&(options={})
options.tagName||(options.tagName="div")
options.cssClass||(options.cssClass="file")
NFileItemView.__super__.constructor.call(this,options,data)
fileData=this.getData()
this.loader=new KDLoaderView({size:{width:16},loaderOptions:{color:"#222222",shape:"spiral",diameter:16,density:30,range:.4,speed:1.5,FPS:24}})
this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"icon"})
for(_i=0,_len=loaderRequiredEvents.length;_len>_i;_i++){ev=loaderRequiredEvents[_i]
data.on("fs."+ev+".started",function(){return _this.showLoader()})
data.on("fs."+ev+".finished",function(){return _this.hideLoader()})}}var loaderRequiredEvents
__extends(NFileItemView,_super)
loaderRequiredEvents=["job","remove","save","saveAs"]
NFileItemView.prototype.destroy=function(){var ev,_i,_len
for(_i=0,_len=loaderRequiredEvents.length;_len>_i;_i++){ev=loaderRequiredEvents[_i]
this.getData().off("fs."+ev+".started")
this.getData().off("fs."+ev+".finished")}return NFileItemView.__super__.destroy.apply(this,arguments)}
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
options.width=400
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
parseWatcherFile=function(vm,parentPath,file,user){var createdAt,group,mode,name,path,size,type
name=file.name,size=file.size,mode=file.mode
type=file.isBroken?"brokenLink":file.isDir?"folder":"file"
path=parentPath==="["+vm+"]/"?"["+vm+"]/"+name:""+parentPath+"/"+name
group=user
createdAt=file.time
return{size:size,user:user,group:group,createdAt:createdAt,mode:mode,type:type,parentPath:parentPath,path:path,name:name,vmName:vm}}
FSHelper.parseWatcher=function(vm,parentPath,files){var data,file,nickname,p,sortedFiles,x,z,_i,_j,_k,_len,_len1,_len2,_ref
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
data.push(FSHelper.createFile(parseWatcherFile(vm,parentPath,file,nickname)))}return data}
FSHelper.folderOnChange=function(vm,path,change,treeController){var file,node,npath,_ref,_ref1,_results
treeController||(treeController=null!=(_ref=KD.getSingleton("finderController"))?_ref.treeController:void 0)
if(treeController){file=this.parseWatcher(vm,path,change.file).first
switch(change.event){case"added":return treeController.addNode(file)
case"removed":_ref1=treeController.nodes
_results=[]
for(npath in _ref1)if(__hasProp.call(_ref1,npath)){node=_ref1[npath]
if(npath===file.path){treeController.removeNodeView(node)
break}_results.push(void 0)}return _results}}else warn("No treeController to update.")}
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
FSHelper.createFile=function(data){var constructor,instance
if(!(data&&data.type&&data.path))return warn("pass a path and type to create a file instance")
null==data.vmName&&(data.vmName=KD.getSingleton("vmController").defaultVmName)
if(this.registry[data.path]){instance=this.registry[data.path]
this.updateInstance(data)}else{constructor=function(){switch(data.type){case"vm":return FSVm
case"folder":return FSFolder
case"mount":return FSMount
case"symLink":return FSFolder
case"brokenLink":return FSBrokenLink
default:return FSFile}}()
instance=new constructor(data)
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
FSItem.create=function(path,type,vmName,callback){return FSHelper.ensureNonexistentPath(path,vmName,function(err,response){if(err){"function"==typeof callback&&callback(err,response)
return warn(err)}return KD.getSingleton("vmController").run({method:"folder"===type?"fs.createDirectory":"fs.writeFile",vmName:vmName,withArgs:{path:FSHelper.plainPath(response),content:"",donotoverwrite:!0}},function(err){var file
err?warn(err):file=FSHelper.createFile({path:response,type:type,vmName:vmName})
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
FSFolder.prototype.fetchContents=function(callback,dontWatch){var _this=this
null==dontWatch&&(dontWatch=!0)
this.emit("fs.job.started")
return this.vmController.run({method:"fs.readDirectory",vmName:this.vmName,withArgs:{onChange:dontWatch?null:function(change){return FSHelper.folderOnChange(_this.vmName,_this.path,change,_this.treeController)},path:FSHelper.plainPath(this.path)}},function(err,response){var files
if(!err&&(null!=response?response.files:void 0)){files=FSHelper.parseWatcher(_this.vmName,_this.path,response.files)
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

var LoginAppsController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginAppsController=function(_super){function LoginAppsController(options,data){null==options&&(options={})
options.view=new LoginView({testPath:"landing-login"})
options.appInfo={name:"Login"}
LoginAppsController.__super__.constructor.call(this,options,data)}__extends(LoginAppsController,_super)
KD.registerAppClass(LoginAppsController,{name:"Login",route:["/:name?/Login","/:name?/Redeem","/:name?/Register","/:name?/Recover","/:name?/ResendToken"],hiddenHandle:!0,labels:["Redeem","Register","Recover","ResendToken"],preCondition:{condition:function(options,cb){return cb(!KD.isLoggedIn())},failure:function(){return KD.getSingleton("router").handleRoute("/Activity")}}})
LoginAppsController.prototype.appIsShown=function(){}
LoginAppsController.prototype.handleQuery=function(){var currentPath
currentPath=KD.getSingleton("router").currentPath
return this.handleRoute(currentPath)}
LoginAppsController.prototype.handleRoute=function(route){var form,s,_this=this
form="login"
s=function(exp,tf){return route.match(exp)?form=tf:void 0}
s(/\/Login$/,"login")
s(/\/Redeem$/,"redeem")
s(/\/Register$/,"register")
s(/\/Recover$/,"recover")
s(/\/ResendToken$/,"resendEmail")
return this.utils.defer(function(){return _this.getView().animateToForm(form)})}
return LoginAppsController}(AppController)

var LoginView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginView=function(_super){function LoginView(options,data){var entryPoint,handler,homeHandler,loginHandler,mainController,recoverHandler,registerHandler,setValue,_this=this
null==options&&(options={})
entryPoint=KD.config.entryPoint
options.cssClass="hidden"
LoginView.__super__.constructor.call(this,options,data)
this.setCss("background-image","url('../images/unsplash/"+backgroundImageNr+".jpg')")
this.hidden=!0
handler=function(route,event){stop(event)
return KD.getSingleton("router").handleRoute(route,{entryPoint:entryPoint})}
homeHandler=handler.bind(null,"/")
loginHandler=handler.bind(null,"/Login")
registerHandler=handler.bind(null,"/Register")
recoverHandler=handler.bind(null,"/Recover")
this.logo=new KDCustomHTMLView({cssClass:"logo",partial:"Koding<cite></cite>",click:homeHandler})
this.backToLoginLink=new KDCustomHTMLView({tagName:"a",partial:"Sign In",click:loginHandler})
this.goToRecoverLink=new KDCustomHTMLView({tagName:"a",partial:"Forgot your password?",testPath:"landing-recover-password",click:recoverHandler})
this.goToRegisterLink=new KDCustomHTMLView({tagName:"a",partial:"Create Account",click:registerHandler})
this.github=new KDButtonView({title:"Sign in with GitHub",style:"solid",callback:function(){return KD.singletons.oauthController.openPopup("github")}})
this.loginForm=new LoginInlineForm({cssClass:"login-form",testPath:"login-form",callback:function(formData){formData.clientId=$.cookie("clientId")
return _this.doLogin(formData)}})
this.registerForm=new RegisterInlineForm({cssClass:"login-form",testPath:"register-form",callback:function(formData){_this.doRegister(formData)
return KD.mixpanel("RegisterButtonClicked")}})
this.redeemForm=new RedeemInlineForm({cssClass:"login-form",callback:function(formData){_this.doRedeem(formData)
return KD.mixpanel("RedeemButtonClicked")}})
this.recoverForm=new RecoverInlineForm({cssClass:"login-form",callback:function(formData){return _this.doRecover(formData)}})
this.resendForm=new ResendEmailConfirmationLinkInlineForm({cssClass:"login-form",callback:function(formData){_this.resendEmailConfirmationToken(formData)
return KD.track("Login","ResendEmailConfirmationTokenButtonClicked")}})
this.resetForm=new ResetInlineForm({cssClass:"login-form",callback:function(formData){formData.clientId=$.cookie("clientId")
return _this.doReset(formData)}})
this.headBanner=new KDCustomHTMLView({domId:"invite-recovery-notification-bar",cssClass:"invite-recovery-notification-bar hidden",partial:"..."})
KD.getSingleton("mainController").on("landingSidebarClicked",function(){return _this.unsetClass("landed")})
setValue=function(field,value){var _ref
return null!=(_ref=_this.registerForm[field].input)?_ref.setValue(value):void 0}
mainController=KD.getSingleton("mainController")
mainController.on("ForeignAuthCompleted",function(provider){var isUserLoggedIn,params
isUserLoggedIn=KD.isLoggedIn()
params={isUserLoggedIn:isUserLoggedIn,provider:provider}
return KD.remote.api.JUser.authenticateWithOauth(params,function(err,resp){var account,field,isNewUser,replacementToken,userInfo,value
if(err)return showError(err)
account=resp.account,replacementToken=resp.replacementToken,isNewUser=resp.isNewUser,userInfo=resp.userInfo
if(isNewUser){_this.animateToForm("register")
for(field in userInfo)if(__hasProp.call(userInfo,field)){value=userInfo[field]
setValue(field,value)}}else if(isUserLoggedIn){mainController.emit("ForeignAuthSuccess."+provider)
new KDNotificationView({title:"Your "+provider.capitalize()+" account has been linked.",type:"mini"})}else _this.afterLoginCallback(err,{account:account,replacementToken:replacementToken})
return KD.mixpanel("Authenticated oauth",{provider:provider})})})}var backgroundImageNr,runExternal,showError,stop
__extends(LoginView,_super)
stop=function(event){event.preventDefault()
return event.stopPropagation()}
backgroundImageNr=KD.utils.getRandomNumber(15)
LoginView.prototype.viewAppended=function(){this.setClass("login-screen login")
this.setTemplate(this.pistachio())
return this.template.update()}
LoginView.prototype.pistachio=function(){return'<div class="flex-wrapper">\n  <div class="login-box-header">\n    <a class="betatag">beta</a>\n    {{> this.logo}}\n  </div>\n  <div class="login-form-holder lf">\n    {{> this.loginForm}}\n  </div>\n  <div class="login-form-holder rf">\n    {{> this.registerForm}}\n  </div>\n  <div class="login-form-holder rdf">\n    {{> this.redeemForm}}\n  </div>\n  <div class="login-form-holder rcf">\n    {{> this.recoverForm}}\n  </div>\n  <div class="login-form-holder rsf">\n    {{> this.resetForm}}\n  </div>\n  <div class="login-form-holder resend-confirmation-form">\n    {{> this.resendForm}}\n  </div>\n  <div class="login-footer">\n    <div class=\'first-row clearfix\'>\n      <div class=\'fl\'>{{> this.goToRecoverLink}}</div><div class=\'fr\'>{{> this.goToRegisterLink}}<i>•</i>{{> this.backToLoginLink}}</div>\n    </div>\n    {{> this.github}}\n  </div>\n</div>\n<footer>\n  <a href="/tos.html" target="_blank">Terms of service</a><i>•</i><a href="/privacy.html" target="_blank">Privacy policy</a><i>•</i><a href="#" target="_blank"><span>photo by </span>some motherf*cker</a>\n</footer>'}
LoginView.prototype.doReset=function(_arg){var clientId,password,recoveryToken,_this=this
recoveryToken=_arg.recoveryToken,password=_arg.password,clientId=_arg.clientId
return KD.remote.api.JPasswordRecovery.resetPassword(recoveryToken,password,function(err,username){_this.resetForm.button.hideLoader()
_this.resetForm.reset()
_this.headBanner.hide()
return _this.doLogin({username:username,password:password,clientId:clientId})})}
LoginView.prototype.doRecover=function(formData){var _this=this
return KD.remote.api.JPasswordRecovery.recoverPassword(formData["username-or-email"],function(err){var entryPoint
_this.recoverForm.button.hideLoader()
if(err)return new KDNotificationView({title:"An error occurred: "+err.message})
_this.recoverForm.reset()
entryPoint=KD.config.entryPoint
KD.getSingleton("router").handleRoute("/Login",{entryPoint:entryPoint})
return new KDNotificationView({title:"Check your email",content:"We've sent you a password recovery token.",duration:4500})})}
LoginView.prototype.resendEmailConfirmationToken=function(formData){var _this=this
return KD.remote.api.JEmailConfirmation.resetToken(formData["username-or-email"],function(err){var entryPoint
_this.resendForm.button.hideLoader()
if(err)return new KDNotificationView({title:"An error occurred: "+err.message})
_this.resendForm.reset()
entryPoint=KD.config.entryPoint
KD.getSingleton("router").handleRoute("/Login",{entryPoint:entryPoint})
return new KDNotificationView({title:"Check your email",content:"We've sent you a confirmation mail.",duration:4500})})}
LoginView.prototype.doRegister=function(formData){var _ref,_ref1,_this=this
KD.getSingleton("mainController").isLoggingIn(!0)
formData.agree="on"
formData.referrer=$.cookie("referrer")
this.registerForm.notificationsDisabled=!0
null!=(_ref=this.registerForm.notification)&&_ref.destroy()
null!=(_ref1=KD.getSingleton("groupsController").groupChannel)&&_ref1.close()
return KD.remote.api.JUser.convert(formData,function(err,replacementToken){var account,message
account=KD.whoami()
_this.registerForm.button.hideLoader()
if(err){message=err.message
warn("An error occured while registering:",err)
_this.registerForm.notificationsDisabled=!1
return _this.registerForm.emit("SubmitFailed",message)}KD.mixpanel.alias(account.profile.nickname)
$.cookie("newRegister",!0)
$.cookie("clientId",replacementToken)
KD.getSingleton("mainController").accountChanged(account)
new KDNotificationView({cssClass:"login",title:"<span></span>Good to go, Enjoy!",duration:2e3})
KD.getSingleton("router").clear()
return setTimeout(function(){_this.hide()
_this.registerForm.reset()
return _this.registerForm.button.hideLoader()},1e3)})}
LoginView.prototype.doLogin=function(credentials){KD.getSingleton("mainController").isLoggingIn(!0)
credentials.username=credentials.username.toLowerCase().trim()
return KD.remote.api.JUser.login(credentials,this.bound("afterLoginCallback"))}
runExternal=function(token){KD.getSingleton("kiteController").run({kiteName:"externals",method:"import",correlationName:" ",withArgs:{value:token,serviceName:"github",userId:KD.whoami().getId()}})
return function(err,status){return console.log("Status of fetching stuff from external: "+status)}}
LoginView.prototype.afterLoginCallback=function(err,params){var account,entryPoint,firstRoute,mainController,mainView,replacementToken,_this=this
null==params&&(params={})
this.loginForm.button.hideLoader()
entryPoint=KD.config.entryPoint
if(err){showError(err)
return this.loginForm.resetDecoration()}account=params.account,replacementToken=params.replacementToken
replacementToken&&$.cookie("clientId",replacementToken)
mainController=KD.getSingleton("mainController")
mainView=mainController.mainViewController.getView()
mainController.accountChanged(account)
mainView.show()
mainView.$().css("opacity",1)
firstRoute=KD.getSingleton("router").visitedRoutes.first
firstRoute&&/^\/Verify/.test(firstRoute)&&(firstRoute="/")
KD.getSingleton("appManager").quitAll()
KD.getSingleton("router").handleRoute(firstRoute||"/Activity",{replaceState:!0,entryPoint:entryPoint})
KD.getSingleton("groupsController").on("GroupChanged",function(){new KDNotificationView({cssClass:"login",title:"<span></span>Happy Coding!",duration:2e3})
return _this.loginForm.reset()})
new KDNotificationView({cssClass:"login",title:"<span></span>Happy Coding!",duration:2e3})
this.loginForm.reset()
this.hide()
return KD.mixpanel("Logged in")}
LoginView.prototype.doRedeem=function(_arg){var inviteCode,_ref,_this=this
inviteCode=_arg.inviteCode
return(null!=(_ref=KD.config.entryPoint)?_ref.slug:void 0)||KD.isLoggedIn()?KD.remote.cacheable(KD.config.entryPoint.slug,function(err,_arg1){var group
group=_arg1[0]
return group.redeemInvitation(inviteCode,function(err){_this.redeemForm.button.hideLoader()
if(err)return KD.notify_(err.message||err)
KD.notify_("Success!")
return KD.getSingleton("mainController").accountChanged(KD.whoami())})}):void 0}
LoginView.prototype.showHeadBanner=function(message,callback){this.headBannerMsg=message
this.headBanner.updatePartial(this.headBannerMsg)
this.headBanner.unsetClass("hidden")
this.headBanner.setClass("show")
$("body").addClass("recovery")
return this.headBanner.click=callback}
LoginView.prototype.headBannerShowGoBackGroup=function(groupTitle){var _this=this
return this.showHeadBanner("<span>Go Back to</span> "+groupTitle,function(){_this.headBanner.hide()
$("#group-landing").css("height","100%")
return $("#group-landing").css("opacity",1)})}
LoginView.prototype.headBannerShowRecovery=function(recoveryToken){var _this=this
return this.showHeadBanner("Hi, seems like you came here to reclaim your account. <span>Click here when you're ready!</span>",function(){KD.getSingleton("router").clear("/Recover/Password")
_this.headBanner.updatePartial("You can now create a new password for your account")
_this.resetForm.addCustomData({recoveryToken:recoveryToken})
return _this.animateToForm("reset")})}
LoginView.prototype.headBannerShowInvitation=function(invite){var _this=this
return this.showHeadBanner("Cool! you got an invite! <span>Click here to register your account.</span>",function(){_this.headBanner.hide()
KD.getSingleton("router").clear(_this.getRouteWithEntryPoint("Register"))
$("body").removeClass("recovery")
return _this.show(function(){_this.animateToForm("register")
_this.$(".flex-wrapper").addClass("taller")
return KD.getSingleton("mainController").emit("InvitationReceived",invite)})})}
LoginView.prototype.hide=function(callback){this.$(".flex-wrapper").removeClass("expanded")
this.emit("LoginViewHidden")
this.setClass("hidden")
"function"==typeof callback&&callback()
return KD.mixpanel("Cancelled Login/Register")}
LoginView.prototype.show=function(callback){this.unsetClass("hidden")
this.emit("LoginViewShown")
this.hidden=!1
return"function"==typeof callback?callback():void 0}
LoginView.prototype.animateToForm=function(name){var _this=this
return this.show(function(){var _ref
switch(name){case"register":KD.remote.api.JUser.isRegistrationEnabled(function(status){if(status===!1){log("Registrations are disabled!!!")
_this.registerForm.$(".main-part").addClass("hidden")
return _this.registerForm.disabledNotice.show()}_this.registerForm.disabledNotice.hide()
return _this.registerForm.$(".main-part").removeClass("hidden")})
KD.mixpanel("Opened register form")
break
case"home":null!=(_ref=parent.notification)&&_ref.destroy()
if(null!=_this.headBannerMsg){_this.headBanner.updatePartial(_this.headBannerMsg)
_this.headBanner.show()}}_this.unsetClass("register recover login reset home resendEmail")
_this.emit("LoginViewAnimated",name)
_this.setClass(name)
_this.$(".flex-wrapper").removeClass("three one")
switch(name){case"register":_this.$(".flex-wrapper").addClass("three")
return _this.registerForm.firstName.input.setFocus()
case"redeem":_this.$(".flex-wrapper").addClass("one")
return _this.redeemForm.inviteCode.input.setFocus()
case"login":return _this.loginForm.username.input.setFocus()
case"recover":_this.$(".flex-wrapper").addClass("one")
return _this.recoverForm.usernameOrEmail.input.setFocus()
case"resendEmail":_this.$(".flex-wrapper").addClass("one")
return _this.resendForm.usernameOrEmail.input.setFocus()}})}
LoginView.prototype.getRouteWithEntryPoint=function(route){var entryPoint
entryPoint=KD.config.entryPoint
return entryPoint&&entryPoint.slug!==KD.defaultSlug?"/"+entryPoint.slug+"/"+route:"/"+route}
showError=function(err){var name,nickname,_ref
if("CONFIRMATION_WAITING"===err.message){_ref=err.data,name=_ref.name,nickname=_ref.nickname
return KD.getSingleton("appManager").tell("Account","displayConfirmEmailModal",name,nickname)}return err.message.length>50?new KDModalView({title:"Something is wrong!",width:500,overlay:!0,cssClass:"new-kdmodal",content:"<div class='modalformline'>"+err.message+"</div>"}):new KDNotificationView({title:err.message,duration:1e3})}
return LoginView}(KDScrollView)

var LoginInlineForm,LoginViewInlineForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginViewInlineForm=function(_super){function LoginViewInlineForm(){_ref=LoginViewInlineForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(LoginViewInlineForm,_super)
LoginViewInlineForm.prototype.viewAppended=function(){var _this=this
this.setTemplate(this.pistachio())
this.template.update()
return this.on("FormValidationFailed",function(){return _this.button.hideLoader()})}
LoginViewInlineForm.prototype.pistachio=function(){}
return LoginViewInlineForm}(KDFormView)
LoginInlineForm=function(_super){function LoginInlineForm(){LoginInlineForm.__super__.constructor.apply(this,arguments)
this.username=new LoginInputView({inputOptions:{name:"username",forceCase:"lowercase",placeholder:"username",testPath:"login-form-username",validate:{event:"blur",rules:{required:!0},messages:{required:"Please enter a username."}}}})
this.password=new LoginInputView({inputOptions:{name:"password",type:"password",placeholder:"••••••••",hint:"password",testPath:"login-form-password",validate:{event:"blur",rules:{required:!0},messages:{required:"Please enter your password."}}}})
this.button=new KDButtonView({title:"SIGN ME IN",style:"thin",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(LoginInlineForm,_super)
LoginInlineForm.prototype.resetDecoration=function(){this.username.resetDecoration()
return this.password.resetDecoration()}
LoginInlineForm.prototype.pistachio=function(){return"<div>{{> this.username}}</div>\n<div>{{> this.password}}</div>\n<div>{{> this.button}}</div>"}
return LoginInlineForm}(LoginViewInlineForm)

var LoginInputView,LoginInputViewWithLoader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginInputView=function(_super){function LoginInputView(options,data){var iconOptions,inputOptions,validate,_base,_base1,_this=this
null==options&&(options={})
inputOptions=options.inputOptions,iconOptions=options.iconOptions
options.cssClass=KD.utils.curry("login-input-view",options.cssClass)
inputOptions||(inputOptions={})
iconOptions||(iconOptions={})
inputOptions.keyup={enter:function(){return _this.parent.$().trigger("submit")}}
validate=inputOptions.validate
if(validate){validate.notifications||(validate.notifications={});(_base=validate.notifications).type||(_base.type="tooltip");(_base1=validate.notifications).direction||(_base1.direction="left")}iconOptions.tagName=iconOptions.tagName||"span"
iconOptions.cssClass=iconOptions.cssClass||"validation-icon"
iconOptions.bind="mouseenter"
delete options.inputOptions
delete options.iconOptions
LoginInputView.__super__.constructor.call(this,options,null)
this.input=new KDInputView(inputOptions,data)
this.icon=new KDCustomHTMLView(iconOptions,data)
this.icon.on("mouseenter",function(){return _this.$().hasClass("validation-error")?_this.input.validate():void 0})
this.input.on("ValidationError",function(err){return _this.decorateValidation(err)})
this.input.on("ValidationPassed",function(){return _this.decorateValidation()})
this.input.on("ValidationFeedbackCleared",function(){return _this.resetDecoration()})
this.placeholderHelper=new KDCustomHTMLView({cssClass:"placeholder-helper",partial:inputOptions.hint||inputOptions.placeholder||inputOptions.name})
this.input.on("focus",function(){return _this.placeholderHelper.setClass("in")})
this.input.on("blur",function(){return _this.placeholderHelper.unsetClass("in")})
this.img="<img src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAALCAYAAABLcGxfAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTdBRDIwREJBMkU1MTFFMUE5MTFEOEE4OEQ1MUI3NjgiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NTdBRDIwRENBMkU1MTFFMUE5MTFEOEE4OEQ1MUI3NjgiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo1N0FEMjBEOUEyRTUxMUUxQTkxMUQ4QTg4RDUxQjc2OCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo1N0FEMjBEQUEyRTUxMUUxQTkxMUQ4QTg4RDUxQjc2OCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pu5I9lIAAADBSURBVHjaYvz//z8DBpjM2AkkmRly/5egSzFiaJjMGAIkV0N5EUBNK3FrmMwoCCSPAbEiEP8D4kdAbAXU9A6mhAnNxgQg1gAqYAdiTiBbHYhTkRUwIZkuCyQLMD3EkAeUk8NmQx0Qy2HRIAXEDagaJjM6Q52DC8RC1TCwIJnOguQ8dA0guXog3sv4fxJDNJCxBEU69z8ujbEgnR5YIu4KkPwFxEZoMl4gDc1AzAoOb4giUPgLQ/13G0qzQeOnESDAADgWL1D1Oi1VAAAAAElFTkSuQmCC'/>"}__extends(LoginInputView,_super)
LoginInputView.prototype.resetDecoration=function(){return this.unsetClass("validation-error validation-passed")}
LoginInputView.prototype.decorateValidation=function(err){if(err){this.input.tooltip.show()
this.unsetClass("validation-passed")
return this.setClass("validation-error")}this.input.unsetTooltip()
this.unsetClass("validation-error")
return this.setClass("validation-passed")}
LoginInputView.prototype.pistachio=function(){return"{{> this.input}}{{> this.icon}}{{> this.placeholderHelper}}"}
return LoginInputView}(JView)
LoginInputViewWithLoader=function(_super){function LoginInputViewWithLoader(){LoginInputViewWithLoader.__super__.constructor.apply(this,arguments)
this.loader=new KDLoaderView({cssClass:"input-loader",size:{width:32,height:32},loaderOptions:{color:"#3E4F55"}})
this.loader.hide()}__extends(LoginInputViewWithLoader,_super)
LoginInputViewWithLoader.prototype.pistachio=function(){return"{{> this.input}}{{> this.icon}}{{> this.loader}}{{> this.placeholderHelper}}"}
return LoginInputViewWithLoader}(LoginInputView)

var LoginOptions,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LoginOptions=function(_super){function LoginOptions(){_ref=LoginOptions.__super__.constructor.apply(this,arguments)
return _ref}__extends(LoginOptions,_super)
LoginOptions.prototype.viewAppended=function(){var inFrame,optionsHolder
inFrame=KD.runningInFrame()
this.addSubView(new KDHeaderView({type:"small",title:"SIGN IN WITH:"}))
this.addSubView(optionsHolder=new KDCustomHTMLView({tagName:"ul",cssClass:"login-options"}))
optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"koding active",partial:"koding",tooltip:{title:"<p class='login-tip'>Sign in with Koding</p>"}}))
return optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"github "+(inFrame?"hidden":void 0),partial:"github",click:function(){return KD.singletons.oauthController.openPopup("github")},tooltip:{title:"<p class='login-tip'>Sign in with GitHub</p>"}}))}
return LoginOptions}(KDView)

var RegisterOptions,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RegisterOptions=function(_super){function RegisterOptions(){_ref=RegisterOptions.__super__.constructor.apply(this,arguments)
return _ref}__extends(RegisterOptions,_super)
RegisterOptions.prototype.viewAppended=function(){var inFrame,optionsHolder
inFrame=KD.runningInFrame()
this.addSubView(optionsHolder=new KDCustomHTMLView({tagName:"ul",cssClass:"login-options"}))
optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"koding active",partial:"koding",tooltip:{title:"<p class='login-tip'>Register with Koding</p>"}}))
return optionsHolder.addSubView(new KDCustomHTMLView({tagName:"li",cssClass:"github active "+(inFrame?"hidden":void 0),partial:"github",click:function(){return KD.getSingleton("oauthController").openPopup("github")},tooltip:{title:"<p class='login-tip'>Register with GitHub</p>"}}))}
return RegisterOptions}(KDView)

var ResendEmailConfirmationLinkInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ResendEmailConfirmationLinkInlineForm=function(_super){function ResendEmailConfirmationLinkInlineForm(){ResendEmailConfirmationLinkInlineForm.__super__.constructor.apply(this,arguments)
this.usernameOrEmail=new LoginInputView({inputOptions:{name:"username-or-email",placeholder:"username or email",testPath:"recover-password-input",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your username or email."}}}})
this.button=new KDButtonView({title:"RESEND EMAIL",style:"thin",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(ResendEmailConfirmationLinkInlineForm,_super)
ResendEmailConfirmationLinkInlineForm.prototype.pistachio=function(){return"<div>{{> this.usernameOrEmail}}</div>\n<div>{{> this.button}}</div>"}
return ResendEmailConfirmationLinkInlineForm}(LoginViewInlineForm)

var RegisterInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RegisterInlineForm=function(_super){function RegisterInlineForm(options,data){var _this=this
null==options&&(options={})
RegisterInlineForm.__super__.constructor.call(this,options,data)
this.firstName=new LoginInputView({cssClass:"half-size",inputOptions:{name:"firstName",placeholder:"first name",validate:{notifications:{type:"tooltip",placement:"left",direction:"right"},container:this,rules:{required:!0},messages:{required:"Please enter your first name."}},testPath:"register-form-firstname"}})
this.lastName=new LoginInputView({cssClass:"half-size",inputOptions:{name:"lastName",placeholder:"last name",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your last name."}},testPath:"register-form-lastname"}})
this.email=new LoginInputViewWithLoader({inputOptions:{name:"email",placeholder:"email address",testPath:"register-form-email",validate:{container:this,event:"blur",rules:{required:!0,email:!0,available:function(input,event){var email
if(9!==(null!=event?event.which:void 0)){input.setValidationResult("available",null)
email=input.getValue()
if(input.valid){_this.email.loader.show()
KD.remote.api.JUser.emailAvailable(email,function(err,response){_this.email.loader.hide()
if(err)return warn(err)
response?input.setValidationResult("available",null):input.setValidationResult("available",'Sorry, "'+email+'" is already in use!')
return _this.userAvatarFeedback(input)})}}}},messages:{required:"Please enter your email address.",email:"That doesn't seem like a valid email address."}},blur:function(input){return _this.utils.defer(function(){return _this.userAvatarFeedback(input)})}}})
this.avatar=new AvatarStaticView({size:{width:55,height:55}},{profile:{hash:md5.digest("there is no such email"),firstName:"New koding user"}})
this.avatar.hide()
this.username=new LoginInputViewWithLoader({inputOptions:{name:"username",forceCase:"lowercase",placeholder:"username",testPath:"register-form-username",validate:{container:this,rules:{required:!0,rangeLength:[4,25],regExp:/^[a-z\d]+([-][a-z\d]+)*$/i,usernameCheck:function(input,event){return _this.usernameCheck(input,event)},finalCheck:function(input,event){return _this.usernameCheck(input,event,0)}},messages:{required:"Please enter a username.",regExp:"For username only lowercase letters and numbers are allowed!",rangeLength:"Username should be minimum 4 maximum 25 chars!"},events:{required:"blur",rangeLength:"keyup",regExp:"keyup",usernameCheck:"keyup",finalCheck:"blur"}},iconOptions:{tooltip:{placement:"right",offset:2,title:"Only lowercase letters and numbers are allowed,\nmax 25 characters. Also keep in mind that the username you select will\nbe a part of your koding domain, and can't be changed later.\ni.e. http://username.kd.io <h1></h1>"}}}})
this.button=new KDButtonView({title:"CREATE ACCOUNT",type:"submit",style:"thin",loader:{color:"#ffffff",diameter:21}})
this.disabledNotice=new KDCustomHTMLView({tagName:"section",cssClass:"disabled-notice",partial:"<p>\n<b>REGISTRATIONS ARE CURRENTLY DISABLED</b>\nWe're sorry for that, please follow us on <a href='http://twitter.com/koding' target='_blank'>twitter</a>\nif you want to be notified when registrations are enabled again.\n</p>"})
this.invitationCode=new LoginInputView({cssClass:"hidden",inputOptions:{name:"inviteCode",type:"hidden"}})
this.on("SubmitFailed",function(){return _this.button.hideLoader()})}var usernameCheckTimer
__extends(RegisterInlineForm,_super)
usernameCheckTimer=null
RegisterInlineForm.prototype.reset=function(){var input,inputs,_i,_len
inputs=KDFormView.findChildInputs(this)
for(_i=0,_len=inputs.length;_len>_i;_i++){input=inputs[_i]
input.clearValidationFeedback()}return RegisterInlineForm.__super__.reset.apply(this,arguments)}
RegisterInlineForm.prototype.usernameCheck=function(input,event,delay){var name,_this=this
null==delay&&(delay=800)
if(9!==(null!=event?event.which:void 0)){clearTimeout(usernameCheckTimer)
input.setValidationResult("usernameCheck",null)
name=input.getValue()
return input.valid?usernameCheckTimer=setTimeout(function(){_this.username.loader.show()
return KD.remote.api.JUser.usernameAvailable(name,function(err,response){var forbidden,kodingUser
_this.username.loader.hide()
kodingUser=response.kodingUser,forbidden=response.forbidden
return err?(null!=response?response.kodingUser:void 0)?input.setValidationResult("usernameCheck",'Sorry, "'+name+'" is already taken!'):void 0:forbidden?input.setValidationResult("usernameCheck",'Sorry, "'+name+'" is forbidden to use!'):kodingUser?input.setValidationResult("usernameCheck",'Sorry, "'+name+'" is already taken!'):input.setValidationResult("usernameCheck",null)})},delay):void 0}}
RegisterInlineForm.prototype.userAvatarFeedback=function(input){if(input.valid){this.avatar.setData({profile:{hash:md5.digest(input.getValue()),firstName:"New koding user"}})
this.avatar.render()
return this.showUserAvatar()}return this.hideUserAvatar()}
RegisterInlineForm.prototype.showUserAvatar=function(){return this.avatar.show()}
RegisterInlineForm.prototype.hideUserAvatar=function(){return this.avatar.hide()}
RegisterInlineForm.prototype.viewAppended=function(){var _this=this
RegisterInlineForm.__super__.viewAppended.apply(this,arguments)
return KD.getSingleton("mainController").on("InvitationReceived",function(invite){var origin
_this.$(".invitation-field").addClass("hidden")
_this.$(".invited-by").removeClass("hidden")
origin=invite.origin
_this.invitationCode.input.setValue(invite.code)
_this.email.input.setValue(invite.email)
return"JAccount"===origin.constructorName?KD.remote.cacheable([origin],function(err,_arg){var account
account=_arg[0]
_this.addSubView(new AvatarStaticView({size:{width:30,height:30}},account),".invited-by .wrapper")
return _this.addSubView(new ProfileTextView({},account),".invited-by .wrapper")}):_this.$(".invited-by").addClass("hidden")})}
RegisterInlineForm.prototype.pistachio=function(){return"<section class='main-part'>\n  <div>{{> this.firstName}}{{> this.lastName}}</div>\n  <div>{{> this.email}}{{> this.avatar}}</div>\n  <div>{{> this.username}}</div>\n  <div class='invitation-field invited-by hidden'>\n    <span class='icon'></span>\n    Invited by:\n    <span class='wrapper'></span>\n  </div>\n  <div>{{> this.button}}</div>\n</section>\n{{> this.invitationCode}}\n{{> this.disabledNotice}}"}
return RegisterInlineForm}(LoginViewInlineForm)

var RecoverInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RecoverInlineForm=function(_super){function RecoverInlineForm(){RecoverInlineForm.__super__.constructor.apply(this,arguments)
this.usernameOrEmail=new LoginInputView({inputOptions:{name:"username-or-email",placeholder:"username or email",testPath:"recover-password-input",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your username or email."}}}})
this.button=new KDButtonView({title:"RECOVER PASSWORD",style:"thin",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(RecoverInlineForm,_super)
RecoverInlineForm.prototype.pistachio=function(){return"<div>{{> this.usernameOrEmail}}</div>\n<div>{{> this.button}}</div>"}
return RecoverInlineForm}(LoginViewInlineForm)

var ResetInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ResetInlineForm=function(_super){function ResetInlineForm(){ResetInlineForm.__super__.constructor.apply(this,arguments)
this.password=new LoginInputView({inputOptions:{name:"password",type:"password",testPath:"recover-password",placeholder:"Enter a new password",validate:{container:this,rules:{required:!0,minLength:8},messages:{required:"Please enter a password.",minLength:"Passwords should be at least 8 characters."}}}})
this.passwordConfirm=new LoginInputView({inputOptions:{name:"passwordConfirm",type:"password",testPath:"recover-password-confirm",placeholder:"Confirm your password",validate:{container:this,rules:{required:!0,match:this.password.input,minLength:8},messages:{required:"Please confirm your password.",match:"Password confirmation doesn't match!"}}}})
this.button=new KDButtonView({title:"RESET PASSWORD",style:"thin",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(ResetInlineForm,_super)
ResetInlineForm.prototype.pistachio=function(){return"<div class='login-hint'>Set your new password below.</div>\n<div>{{> this.password}}</div>\n<div>{{> this.passwordConfirm}}</div>\n<div>{{> this.button}}</div>"}
return ResetInlineForm}(LoginViewInlineForm)

var RedeemInlineForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
RedeemInlineForm=function(_super){function RedeemInlineForm(options,data){null==options&&(options={})
RedeemInlineForm.__super__.constructor.call(this,options,data)
this.inviteCode=new LoginInputView({inputOptions:{name:"inviteCode",placeholder:"Enter your invite code",validate:{container:this,rules:{required:!0},messages:{required:"Please enter your invite code."}}}})
this.button=new KDButtonView({title:"Redeem",style:"thin",type:"submit",loader:{color:"#ffffff",diameter:21}})}__extends(RedeemInlineForm,_super)
RedeemInlineForm.prototype.pistachio=function(){return"<div>{{> this.inviteCode}}</div>\n<div>{{> this.button}}</div>"}
return RedeemInlineForm}(LoginViewInlineForm)

KD.config.apps={HomeIntro:{style:"/css/introapp.0.0.1.css",script:"/js/introapp.0.0.1.js",identifier:"app.homeintro"},Landing:{style:"/css/__landingapp.0.0.1.css",script:"/js/__landingapp.0.0.1.js",identifier:"app.landing"},Activity:{style:"/css/__social.0.0.1.css",script:"/js/__social.0.0.1.js",identifier:"app.social"},Members:{style:"/css/__social.0.0.1.css",script:"/js/__social.0.0.1.js",identifier:"app.social"},Topics:{style:"/css/__social.0.0.1.css",script:"/js/__social.0.0.1.js",identifier:"app.social"},Feeder:{style:"/css/__app.feeder.0.0.1.css",script:"/js/__app.feeder.0.0.1.js",identifier:"app.feeder"},Account:{style:"/css/__app.account.0.0.1.css",script:"/js/__app.account.0.0.1.js",identifier:"app.account"},Login:{style:"/css/__koding.0.0.1.css",script:"/js/__koding.0.0.1.js",identifier:"app.koding"},Apps:{style:"/css/__app.apps.0.0.1.css",script:"/js/__app.apps.0.0.1.js",identifier:"app.apps"},Terminal:{style:"/css/__teamwork.0.0.1.css",script:"/js/__teamwork.0.0.1.js",identifier:"app.teamworkbundle"},Ace:{style:"/css/__teamwork.0.0.1.css",script:"/js/__teamwork.0.0.1.js",identifier:"app.teamworkbundle"},Finder:{style:"/css/__koding.0.0.1.css",script:"/js/__koding.0.0.1.js",identifier:"app.koding"},Viewer:{style:"/css/__teamwork.0.0.1.css",script:"/js/__teamwork.0.0.1.js",identifier:"app.teamworkbundle"},Workspace:{style:"/css/__teamwork.0.0.1.css",script:"/js/__teamwork.0.0.1.js",identifier:"app.teamworkbundle"},CollaborativeWorkspace:{style:"/css/__teamwork.0.0.1.css",script:"/js/__teamwork.0.0.1.js",identifier:"app.teamworkbundle"},Teamwork:{style:"/css/__teamwork.0.0.1.css",script:"/js/__teamwork.0.0.1.js",identifier:"app.teamworkbundle"},About:{style:"/css/__app.about.0.0.1.css",script:"/js/__app.about.0.0.1.js",identifier:"app.about"},Environments:{style:"/css/__app.environments.0.0.1.css",script:"/js/__app.environments.0.0.1.js",identifier:"app.environments"}}

//@ sourceMappingURL=/js/__koding.0.0.1.js.map