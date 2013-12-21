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
module.exports=Broker=function(_super){function Broker(ws,options){Broker.__super__.constructor.call(this)
this.sockURL=ws
this.autoReconnect=options.autoReconnect,this.authExchange=options.authExchange,this.overlapDuration=options.overlapDuration,this.servicesEndpoint=options.servicesEndpoint
null==this.overlapDuration&&(this.overlapDuration=3e3)
null==this.authExchange&&(this.authExchange="auth")
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
Broker.prototype.registerNamespacedEvent=function(name){var register
register=this.namespacedEvents
null==register[name]&&(register[name]=0)
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
listeners=null!=(_ref=this._e)?_ref[event]:void 0
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
state.isLeaf=0==state.keys.length
for(var i=0;i<parents.length;i++)if(parents[i].node_===node_){state.circular=parents[i]
break}}else{state.isLeaf=!0
state.keys=null}state.notLeaf=!state.isLeaf
state.notRoot=!state.isRoot}var node=immutable?copy(node_):node_,modifiers={},keepGoing=!0,state={node:node,node_:node_,path:[].concat(path),parent:parents[parents.length-1],parents:parents,key:path.slice(-1)[0],isRoot:0===path.length,level:path.length,circular:null,update:function(x,stopHere){state.isRoot||(state.parent.node[state.key]=x)
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
if("object"==typeof state.node&&null!==state.node&&!state.circular){parents.push(state)
updateState()
forEach(state.keys,function(key,i){path.push(key)
modifiers.pre&&modifiers.pre.call(state,state.node[key],key)
var child=walker(state.node[key])
immutable&&hasOwnProperty.call(state.node,key)&&(state.node[key]=child.node)
child.isLast=i==state.keys.length-1
child.isFirst=0==i
modifiers.post&&modifiers.post.call(state,child)
path.pop()})
parents.pop()}modifiers.after&&modifiers.after.call(state,state.node)
return state}(root).node}function copy(src){if("object"==typeof src&&null!==src){var dst
if(isArray(src))dst=[]
else if(isDate(src))dst=new Date(src.getTime?src.getTime():src)
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
if(!node||!hasOwnProperty.call(node,key)){node=void 0
break}node=node[key]}return node}
Traverse.prototype.has=function(ps){for(var node=this.value,i=0;i<ps.length;i++){var key=ps[i]
if(!node||!hasOwnProperty.call(node,key))return!1
node=node[key]}return!0}
Traverse.prototype.set=function(ps,value){for(var node=this.value,i=0;i<ps.length-1;i++){var key=ps[i]
hasOwnProperty.call(node,key)||(node[key]={})
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
return function clone(src){for(var i=0;i<parents.length;i++)if(parents[i]===src)return nodes[i]
if("object"==typeof src&&null!==src){var dst=copy(src)
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
return t[key].apply(t,args)}})
var hasOwnProperty=Object.hasOwnProperty||function(obj,key){return key in obj}})
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
Model.prototype.decoded="undefined"!=typeof Encoder&&null!==Encoder?function(path){return Encoder.htmlDecode(this.getAt(path))}:Model.prototype.getAt
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
return this.emit("update",Object.keys(fields.result))}
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
Bongo=function(_super){function Bongo(options){var _this=this
EventEmitter(this)
this.mq=options.mq,this.getSessionToken=options.getSessionToken,this.getUserArea=options.getUserArea,this.fetchName=options.fetchName,this.resourceName=options.resourceName,this.precompiledApi=options.precompiledApi
null==this.getUserArea&&(this.getUserArea=function(){})
this.localStore=new Store
this.remoteStore=new Store
this.readyState=NOTCONNECTED
this.stack=[]
this.eventBus=new EventBus(this.mq)
this.mq.on("message",this.bound("handleRequestString"))
this.mq.on("disconnected",this.emit.bind(this,"disconnected"))
this.opaqueTypes={}
this.on("newListener",function(event){return"ready"===event&&_this.readyState===CONNECTED?process.nextTick(function(){_this.emit("ready")
return _this.off("ready")}):void 0})}var CONNECTED,CONNECTING,DISCONNECTED,EventBus,JsPath,Model,NOTCONNECTED,OpaqueType,Scrubber,Store,Traverse,addGlobalListener,createBongoName,createId,dash,extend,getEventChannelName,getRevivingListener,race,sequence,slice,_ref,_ref1,_ref2,_ref3
__extends(Bongo,_super)
_ref=[0,1,2,3],NOTCONNECTED=_ref[0],CONNECTING=_ref[1],CONNECTED=_ref[2],DISCONNECTED=_ref[3]
Traverse=require("traverse")
createId=Bongo.createId=require("hat")
JsPath=Bongo.JsPath=require("jspath")
Bongo.dnodeProtocol=require("koding-dnode-protocol")
Bongo.dnodeProtocol.Scrubber=require("./src/scrubber")
_ref1=Bongo.dnodeProtocol,Store=_ref1.Store,Scrubber=_ref1.Scrubber
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
_ref2=require("sinkrow"),race=_ref2.race,sequence=_ref2.sequence,dash=_ref2.dash
_ref3=require("sinkrow"),Bongo.daisy=_ref3.daisy,Bongo.dash=_ref3.dash,Bongo.sequence=_ref3.sequence,Bongo.race=_ref3.race,Bongo.future=_ref3.future
Bongo.bound=require("koding-bound")
Bongo.prototype.bound=require("koding-bound")
createBongoName=function(resourceName){return""+createId(128)+".unknown.bongo-"+resourceName}
Bongo.prototype.cacheable=require("./src/cacheable")
Bongo.prototype.createRemoteApiShims=function(api){var instance,name,options,shimmedApi,statik,_ref4
shimmedApi={}
for(name in api)if(__hasProp.call(api,name)){_ref4=api[name],statik=_ref4.statik,instance=_ref4.instance,options=_ref4.options
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
Bongo.prototype.reviveType=function(type,shouldWrap){var revived,_base,_ref4,_ref5
if(Array.isArray(type))return this.reviveType(type[0],!0)
if("string"!=typeof type)return type
revived=null!=(_ref4=null!=(_ref5=this.api[type])?_ref5:window[type])?_ref4:null!=(_base=this.opaqueTypes)[type]?(_base=this.opaqueTypes)[type]:_base[type]=new OpaqueType(type)
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
return new Traverse(obj).map(function(node){var constructorName,instance,instanceId,konstructor,_ref4
if(null!=(null!=node?node.bongo_:void 0)){_ref4=node.bongo_,constructorName=_ref4.constructorName,instanceId=_ref4.instanceId
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
Bongo.prototype.subscribe=function(name,options,callback){var channel
null==options&&(options={})
null==options.serviceType&&(options.serviceType="application")
channel=this.mq.subscribe(name,options)
channel.setAuthenticationInfo({serviceType:options.serviceType,group:options.group,name:name,clientId:this.getSessionToken()})
null!=callback&&channel.once("broker.subscribed",function(){return callback(channel)})
return channel}
return Bongo}(EventEmitter)
!isBrowser&&module?module.exports=Bongo:"undefined"!=typeof window&&null!==window&&(window.Bongo=Bongo)})
require("/node_modules_koding/bongo-client/bongo.js")}()}()


//@ sourceMappingURL=/js/bongo.0.0.1.js.map