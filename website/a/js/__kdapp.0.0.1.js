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

!function(root){function isString(obj){return!!(""===obj||obj&&obj.charCodeAt&&obj.substr)}function isArray(obj){return nativeIsArray?nativeIsArray(obj):"[object Array]"===toString.call(obj)}function isObject(obj){return obj&&"[object Object]"===toString.call(obj)}function defaults(object,defs){var key
object=object||{}
defs=defs||{}
for(key in defs)defs.hasOwnProperty(key)&&null==object[key]&&(object[key]=defs[key])
return object}function map(obj,iterator,context){var i,j,results=[]
if(!obj)return results
if(nativeMap&&obj.map===nativeMap)return obj.map(iterator,context)
for(i=0,j=obj.length;j>i;i++)results[i]=iterator.call(context,obj[i],i,obj)
return results}function checkPrecision(val,base){val=Math.round(Math.abs(val))
return isNaN(val)?base:val}function checkCurrencyFormat(format){var defaults=lib.settings.currency.format
"function"==typeof format&&(format=format())
return isString(format)&&format.match("%v")?{pos:format,neg:format.replace("-","").replace("%v","-%v"),zero:format}:format&&format.pos&&format.pos.match("%v")?format:isString(defaults)?lib.settings.currency.format={pos:defaults,neg:defaults.replace("%v","-%v"),zero:defaults}:defaults}var lib={}
lib.version="0.3.2"
lib.settings={currency:{symbol:"$",format:"%s%v",decimal:".",thousand:",",precision:2,grouping:3},number:{precision:0,grouping:3,thousand:",",decimal:"."}}
var nativeMap=Array.prototype.map,nativeIsArray=Array.isArray,toString=Object.prototype.toString,unformat=lib.unformat=lib.parse=function(value,decimal){if(isArray(value))return map(value,function(val){return unformat(val,decimal)})
value=value||0
if("number"==typeof value)return value
decimal=decimal||lib.settings.number.decimal
var regex=new RegExp("[^0-9-"+decimal+"]",["g"]),unformatted=parseFloat((""+value).replace(/\((.*)\)/,"-$1").replace(regex,"").replace(decimal,"."))
return isNaN(unformatted)?0:unformatted},toFixed=lib.toFixed=function(value,precision){precision=checkPrecision(precision,lib.settings.number.precision)
var power=Math.pow(10,precision)
return(Math.round(lib.unformat(value)*power)/power).toFixed(precision)},formatNumber=lib.formatNumber=function(number,precision,thousand,decimal){if(isArray(number))return map(number,function(val){return formatNumber(val,precision,thousand,decimal)})
number=unformat(number)
var opts=defaults(isObject(precision)?precision:{precision:precision,thousand:thousand,decimal:decimal},lib.settings.number),usePrecision=checkPrecision(opts.precision),negative=0>number?"-":"",base=parseInt(toFixed(Math.abs(number||0),usePrecision),10)+"",mod=base.length>3?base.length%3:0
return negative+(mod?base.substr(0,mod)+opts.thousand:"")+base.substr(mod).replace(/(\d{3})(?=\d)/g,"$1"+opts.thousand)+(usePrecision?opts.decimal+toFixed(Math.abs(number),usePrecision).split(".")[1]:"")},formatMoney=lib.formatMoney=function(number,symbol,precision,thousand,decimal,format){if(isArray(number))return map(number,function(val){return formatMoney(val,symbol,precision,thousand,decimal,format)})
number=unformat(number)
var opts=defaults(isObject(symbol)?symbol:{symbol:symbol,precision:precision,thousand:thousand,decimal:decimal,format:format},lib.settings.currency),formats=checkCurrencyFormat(opts.format),useFormat=number>0?formats.pos:0>number?formats.neg:formats.zero
return useFormat.replace("%s",opts.symbol).replace("%v",formatNumber(Math.abs(number),checkPrecision(opts.precision),opts.thousand,opts.decimal))}
lib.formatColumn=function(list,symbol,precision,thousand,decimal,format){if(!list)return[]
var opts=defaults(isObject(symbol)?symbol:{symbol:symbol,precision:precision,thousand:thousand,decimal:decimal,format:format},lib.settings.currency),formats=checkCurrencyFormat(opts.format),padAfterSymbol=formats.pos.indexOf("%s")<formats.pos.indexOf("%v")?!0:!1,maxLength=0,formatted=map(list,function(val){if(isArray(val))return lib.formatColumn(val,opts)
val=unformat(val)
var useFormat=val>0?formats.pos:0>val?formats.neg:formats.zero,fVal=useFormat.replace("%s",opts.symbol).replace("%v",formatNumber(Math.abs(val),checkPrecision(opts.precision),opts.thousand,opts.decimal))
fVal.length>maxLength&&(maxLength=fVal.length)
return fVal})
return map(formatted,function(val){return isString(val)&&val.length<maxLength?padAfterSymbol?val.replace(opts.symbol,opts.symbol+new Array(maxLength-val.length+1).join(" ")):new Array(maxLength-val.length+1).join(" ")+val:val})}
root.accounting=lib}(this)

__utils.extend(__utils,{getPaymentMethodTitle:function(billing){var cardFirstName,cardLastName,cardNumber,cardType
null!=billing.billing&&(billing=billing.billing)
cardFirstName=billing.cardFirstName,cardLastName=billing.cardLastName,cardType=billing.cardType,cardNumber=billing.cardNumber
return""+cardFirstName+" "+cardLastName+" ("+cardType+" "+cardNumber+")"},botchedUrlRegExp:/(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g,webProtocolRegExp:/^((http(s)?\:)?\/\/)/,proxifyUrl:function(url,options){var endpoint
null==url&&(url="")
null==options&&(options={})
options.width||(options.width=-1)
options.height||(options.height=-1)
options.grow||(options.grow=!0)
if(""===url)return"data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";(options.width||options.height)&&(endpoint="/resize")
options.crop&&(endpoint="/crop")
return"https://i.embed.ly/1/display"+(endpoint||"")+"?grow="+options.grow+"&width="+options.width+"&height="+options.height+"&key="+KD.config.embedly.apiKey+"&url="+encodeURIComponent(url)},goBackToOldKoding:function(){return KD.whoami().modify({preferredKDProxyDomain:""},function(err){if(!err){$.cookie("kdproxy-preferred-domain",{erase:!0})
return location.reload(!0)}})},setPreferredDomain:function(account){var preferredDomainCookieName,preferredKDProxyDomain
preferredDomainCookieName="kdproxy-preferred-domain"
preferredKDProxyDomain=account.preferredKDProxyDomain
if(preferredKDProxyDomain&&""!==preferredKDProxyDomain){if($.cookie(preferredDomainCookieName)===preferredKDProxyDomain)return
$.cookie(preferredDomainCookieName,preferredKDProxyDomain)
return location.reload(!0)}},showMoreClickHandler:function(event){var $trg,less,more
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
return u.link("/"+username)})},expandUrls:function(text,replaceAndYieldLinks){var linkCount,links,urlGrabber
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
if(!longText)return""
minLength=options.minLength||450
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
return(null!=candidate?candidate.length:void 0)>minLength?candidate:longText}}(),expandTokens:function(str,data){var constructorName,domId,id,itemClass,match,prefix,tagMap,token,tokenMatches,tokenString,tokenView,viewParams,_i,_len,_ref,_ref1
null==str&&(str="")
if(!(tokenMatches=str.match(/\|.+?\|/g)))return str
tagMap={}
null!=(_ref=data.tags)&&_ref.forEach(function(tag){return tagMap[tag.getId()]=tag})
viewParams=[]
for(_i=0,_len=tokenMatches.length;_len>_i;_i++){tokenString=tokenMatches[_i];(match=tokenString.match(/^\|(.+)\|$/))&&(_ref1=match[1].split(/:/g),prefix=_ref1[0],constructorName=_ref1[1],id=_ref1[2])
switch(prefix){case"#":token=null!=tagMap?tagMap[id]:void 0
break
default:continue}if(token){domId=__utils.getUniqueId()
itemClass=__utils.getTokenClass(prefix)
tokenView=new TokenView({domId:domId,itemClass:itemClass},token)
tokenView.emit("viewAppended")
str=str.replace(tokenString,tokenView.getElement().outerHTML)
tokenView.destroy()
viewParams.push({options:{domId:domId,itemClass:itemClass},data:token})}}__utils.defer(function(){var options,_j,_len1,_ref2,_results
_results=[]
for(_j=0,_len1=viewParams.length;_len1>_j;_j++){_ref2=viewParams[_j],options=_ref2.options,data=_ref2.data
_results.push(new TokenView(options,data))}return _results})
return str},getTokenClass:function(prefix){switch(prefix){case"#":return TagLinkView}},getMonthOptions:function(){var i,_i,_results
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
return KD.remote.api.JUser.register(formData,function(){return location.reload(!0)})}},startRollbar:function(){return this.replaceFromTempStorage("_rollbar")},stopRollbar:function(){this.storeToTempStorage("_rollbar",window._rollbar)
return window._rollbar={push:function(){}}},startMixpanel:function(){return this.replaceFromTempStorage("mixpanel")},stopMixpanel:function(){this.storeToTempStorage("mixpanel",window.mixpanel)
return window.mixpanel={track:function(){}}},replaceFromTempStorage:function(name){var item
return(item=this.tempStorage[name])?window[item]=item:log("no "+name+" in mainController temp storage")},storeToTempStorage:function(name,item){return this.tempStorage[name]=item},tempStorage:function(){return KD.getSingleton("mainController").tempStorage},applyGradient:function(view,color1,color2){var rule,rules,_i,_len,_results
rules=["-moz-linear-gradient(100% 100% 90deg, "+color2+", "+color1+")","-webkit-gradient(linear, 0% 0%, 0% 100%, from("+color1+"), to("+color2+"))"]
_results=[]
for(_i=0,_len=rules.length;_len>_i;_i++){rule=rules[_i]
_results.push(view.setCss("backgroundImage",rule))}return _results},getAppIcon:function(name){var image,img,thumb
image="Ace"===name?"icn-ace":"default.app.thumb"
thumb=""+KD.apiUri+"/images/"+image+".png"
img=new KDCustomHTMLView({tagName:"img",bind:"error",error:function(){return this.getElement().setAttribute("src","/images/default.app.thumb.png")},attributes:{src:thumb}})
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
return finderWrapper.setHeight(200)},getEmbedType:function(type){switch(type){case"audio":case"xml":case"json":case"ppt":case"rss":case"atom":return"object"
case"photo":case"image":return"image"
case"link":case"html":return"link"
case"error":log("Embedding error ",data.error_type,data.error_message)
return"error"
default:log("Unhandled content type '"+type+"'")
return"error"}},getColorFromString:function(str){return["#37B298","#BA4B3A","#F1C42C","#DB4B00","#009BCB","#37B298","#35485F","#D35219","#FDAB2E","#19A2C4","#37B298","#BA4B3A","#F1C42C","#DB4B00","#009BCB"][parseInt(md5.digest(str)[0],16)]},formatMoney:accounting.formatMoney,postDummyStatusUpdate:function(){var body,group,_ref,_ref1
if("localhost"===location.hostname){body=KD.utils.generatePassword(KD.utils.getRandomNumber(50),!0)+" "+dateFormat(Date.now(),"dddd, mmmm dS, yyyy, h:MM:ss TT")
group="group"===(null!=(_ref=KD.config.entryPoint)?_ref.type:void 0)&&(null!=(_ref1=KD.config.entryPoint)?_ref1.slug:void 0)?KD.config.entryPoint.slug:"koding"
return KD.remote.api.JStatusUpdate.create({body:body,group:group},function(err,reply){return err?new KDNotificationView({type:"mini",title:"There was an error, try again later!"}):KD.getSingleton("appManager").tell("Activity","ownActivityArrived",reply)})}}})

var _ref,__hasProp={}.hasOwnProperty,__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1},__slice=[].slice
KD.extend({apiUri:KD.config.apiUri,appsUri:KD.config.appsUri,singleton:KD.getSingleton.bind(KD),appClasses:{},appScripts:{},appLabels:{},navItems:[],navItemIndex:{},socketConnected:function(){return this.backendIsConnected=!0},registerAppClass:function(fn,options){var handler,registerRoute,route,wrapHandler,_ref,_ref1,_this=this
null==options&&(options={})
if(!options.name)return error("AppClass is missing a name!")
if(KD.appClasses[options.name]){if(KD.config.apps[options.name])return warn("AppClass "+options.name+" cannot be used, since its conflicting with an internal Koding App.")
warn("AppClass "+options.name+" is already registered or the name is already taken!")
warn("Removing the old one. It was ",KD.appClasses[options.name])
this.unregisterAppClass(options.name)}null==options.multiple&&(options.multiple=!1)
null==options.background&&(options.background=!1)
null==options.hiddenHandle&&(options.hiddenHandle=!1)
options.openWith||(options.openWith="lastActive")
options.behavior||(options.behavior="")
null==options.thirdParty&&(options.thirdParty=!1)
options.menu||(options.menu=null)
options.navItem||(options.navItem={})
options.labels||(options.labels=[])
null==options.version&&(options.version="1.0")
options.route||(options.route=null)
options.routes||(options.routes=null)
options.styles||(options.styles=[])
wrapHandler=function(fn,options){return function(){var router
router=KD.getSingleton("router")
options.navItem.title&&"function"==typeof router.setPageTitle&&router.setPageTitle(options.navItem.title)
return fn.apply(this,arguments)}}
registerRoute=function(route,handler){var cb,slug
slug="string"==typeof route?route:route.slug
route={slug:slug||"/",handler:handler||route.handler||null}
if("/"!==route.slug){slug=route.slug,handler=route.handler
cb=function(router){handler=handler?wrapHandler(handler,options):function(_arg){var name,query,_ref
_ref=_arg.params,name=_ref.name,query=_arg.query
return router.openSection(options.name,name,query)}
return router.addRoute(slug,handler)}
return KD.singletons.router?_this.utils.defer(function(){return cb(KD.getSingleton("router"))}):KodingRouter.on("RouterReady",cb)}}
if(options.route)registerRoute(options.route)
else if(options.routes){_ref=options.routes
for(route in _ref)if(__hasProp.call(_ref,route)){handler=_ref[route]
registerRoute(route,handler)}}(null!=(_ref1=options.navItem)?_ref1.order:void 0)&&this.registerNavItem(options.navItem)
return Object.defineProperty(KD.appClasses,options.name,{configurable:!0,enumerable:!0,writable:!1,value:{fn:fn,options:options}})},resetNavItems:function(items){this.navItems=items
return this.navItemIndex=KD.utils.arrayToObject(items,"title")},registerNavItem:function(itemData){if(!this.navItemIndex[itemData.title]){this.navItemIndex[itemData.title]=itemData
this.navItems.push(itemData)
return!0}return!1},getNavItems:function(){return this.navItems.sort(function(a,b){return a.order-b.order})},setNavItems:function(navItems){var item,_i,_len,_ref,_results
_ref=navItems.sort(function(a,b){return a.order-b.order})
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
_results.push(this.registerNavItem(item))}return _results},unregisterAppClass:function(name){return delete KD.appClasses[name]},getAppClass:function(name){var _ref
return(null!=(_ref=KD.appClasses[name])?_ref.fn:void 0)||null},getAppOptions:function(name){var _ref
return(null!=(_ref=KD.appClasses[name])?_ref.options:void 0)||null},getAppScript:function(name){return this.appScripts[name]||null},registerAppScript:function(name,script){return this.appScripts[name]=script},unregisterAppScript:function(name){return delete this.appScripts[name]},resetAppScripts:function(){return this.appScripts={}},disableLogs:function(){var method,_i,_len,_ref
_ref=["log","warn","error","trace","time","timeEnd"]
for(_i=0,_len=_ref.length;_len>_i;_i++){method=_ref[_i]
window[method]=noop
KD[method]=noop}delete KD.logsEnabled
return"Logs are disabled now."},enableLogs:function(state){null==state&&(state=!0)
if(!state)return KD.disableLogs()
KD.log=window.log=console.log.bind(console)
KD.warn=window.warn=console.warn.bind(console)
KD.error=window.error=console.error.bind(console)
KD.time=window.time=console.time.bind(console)
KD.timeEnd=window.timeEnd=console.timeEnd.bind(console)
KD.logsEnabled=!0
return"Logs are enabled now."},impersonate:function(username){return KD.remote.api.JAccount.impersonate(username,function(err){return err?new KDNotificationView({title:err.message}):location.reload()})},notify_:function(message,type,duration){null==type&&(type="")
null==duration&&(duration=3500)
return new KDNotificationView({cssClass:type,title:message,duration:duration})},requireMembership:function(options){var callback,groupName,mainController,onFail,onFailMsg,silence,tryAgain,_this=this
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
if(!err)return!1
if("string"==typeof err){message=err
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
if("AccessDenied"!==err.name){warn("KodingError:",err.message)
error(err)}return null!=err},getPathInfo:function(fullPath){var basename,isPublic,parent,path,vmName
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
return""+(secure?"https":"http")+"://"+subdomain+vmName+"/"+publicPath}}},runningInFrame:function(){return window.top!==window.self},getGroup:function(){return KD.getSingleton("groupsController").getCurrentGroup()},getReferralUrl:function(username){return""+location.origin+"/R/"+username},tell:function(){var rest,_ref
rest=1<=arguments.length?__slice.call(arguments,0):[]
return(_ref=KD.getSingleton("appManager")).tell.apply(_ref,rest)},hasAccess:function(permission){return __indexOf.call(KD.config.roles,"admin")>=0?!0:__indexOf.call(KD.config.permissions,permission)>=0}})
Object.defineProperty(KD,"defaultSlug",{get:function(){return KD.isGuest()?"guests":"koding"}})
KD.enableLogs($.cookie("enableLogs")||!(null!=(_ref=KD.config)?_ref.suppressLogs:void 0))

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
name=name.split("?")[0]
log("handlingRoute",route,"for the",name,"app")
if(appManager.isAppInternal(name)){log("couldn't find",name)
return KodingAppsController.loadInternalApp(name,function(err){log("Router: loaded",name)
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
KodingRouter.prototype.getContentTitle=function(model){var JAccount,JGroup,JNewStatusUpdate,_ref
_ref=KD.remote.api,JAccount=_ref.JAccount,JNewStatusUpdate=_ref.JNewStatusUpdate,JGroup=_ref.JGroup
return this.utils.shortenText(function(){switch(model.constructor){case JAccount:return KD.utils.getFullnameFromAccount(model)
case JNewStatusUpdate:return model.body
case JGroup:return model.title
default:return""+model.title+getSectionName(model)}}(),{maxLength:100})}
KodingRouter.prototype.openContent=function(name,section,models,route,query,passOptions){var callback,currentGroup,groupName,groupsController,method,options,_this=this
null==passOptions&&(passOptions=!1)
method="createContentDisplay"
Array.isArray(models)&&(models=models[0])
this.setPageTitle(this.getContentTitle(models))
if(passOptions){method+="WithOptions"
options={model:models,route:route,query:query}}callback=function(){return KD.getSingleton("appManager").tell(section,method,null!=options?options:models,function(contentDisplay){var routeWithoutParams
if(contentDisplay){routeWithoutParams=route.split("?")[0]
_this.openRoutes[routeWithoutParams]=contentDisplay
_this.openRoutesById[contentDisplay.id]=routeWithoutParams
return contentDisplay.emit("handleQuery",query)}console.warn("no content display")})}
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
return requireLogin(function(){return mainController.doLogout()})},"/:name?/Topics/:slug":createContentHandler("Topics"),"/:name?/Activity/:slug":createContentHandler("Activity"),"/:name/Groups":createSectionHandler("Groups"),"/:name/Followers":createContentHandler("Members",!0),"/:name/Following":createContentHandler("Members",!0),"/:name/Likes":createContentHandler("Members",!0),"/:name?/Invitation/:inviteCode":function(_arg){var inviteCode
inviteCode=_arg.params.inviteCode
inviteCode=decodeURIComponent(inviteCode)
if(KD.isLoggedIn()){warn("FIXME Add tell to Login app ~ GG @ kodingrouter")
return _this.handleRoute("/",{entryPoint:KD.config.entryPoint})}return KD.remote.api.JInvitation.byCode(inviteCode,function(err,invite){var _ref
if(err||null==invite||"active"!==(_ref=invite.status)&&"sent"!==_ref){if(!KD.isLoggedIn()){err&&error(err)
new KDNotificationView({title:"Invalid invitation code!"})}}else warn("FIXME Add tell to Login app ~ GG @ kodingrouter")
return _this.clear("/")})},"/:name?/InviteFriends":function(){if(KD.isLoggedIn()){this.handleRoute("/Activity",{entryPoint:KD.config.entryPoint})
return KD.introView?KD.introView.once("transitionend",function(){return KD.utils.wait(1200,function(){return new ReferrerModal})}):new ReferrerModal}return this.handleRoute("/Login")},"/:name?/RegisterHostKey":KiteHelper.initiateRegistiration,"/member/:username":function(_arg){var username
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
case"JNewApp":return KodingAppsController.runApprovedApp(model,{dontUseRouter:!0})
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
subjectMap=function(){return{JNewStatusUpdate:"<a href='#'>status</a>",JCodeSnip:"<a href='#'>code snippet</a>",JQuestionActivity:"<a href='#'>question</a>",JDiscussion:"<a href='#'>discussion</a>",JLinkActivity:"<a href='#'>link</a>",JPrivateMessage:"<a href='#'>private message</a>",JOpinion:"<a href='#'>opinion</a>",JTutorial:"<a href='#'>tutorial</a>",JComment:"<a href='#'>comment</a>",JReview:"<a href='#'>review</a>"}}
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
if(actor){fetchSubjectObj=function(callback){var args,method,_ref1,_ref2
if(!subject||"JPrivateMessage"===subject.constructorName)return callback(null)
if("JComment"===(_ref1=subject.constructorName)||"JOpinion"===_ref1){method="fetchRelated"
args=subject.id}else{method="one"
args={_id:subject.id}}return null!=(_ref2=KD.remote.api[subject.constructorName])?_ref2[method](args,callback):void 0}
return KD.remote.cacheable(actor.constructorName,actor.id,function(err,actorAccount){return"unregistered"!==actorAccount.type?fetchSubjectObj(function(err,subjectObj){var actorName,originatorName,separator
if(!err&&subjectObj){actorName=KD.utils.getFullnameFromAccount(actorAccount)
options.actorAvatar=new AvatarView({size:{width:35,height:35}},actorAccount)
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
notification=new KDNotificationView({type:"tray",cssClass:"mini realtime "+options.type,duration:1e4,title:"<span></span>"+options.title,content:options.content||null})
options.actorAvatar&&notification.addSubView(options.actorAvatar)
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
return route+="/Activity/?tagged="+slug}}()
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

var OAuthController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
OAuthController=function(_super){function OAuthController(){_ref=OAuthController.__super__.constructor.apply(this,arguments)
return _ref}var notify
__extends(OAuthController,_super)
OAuthController.prototype.openPopup=function(provider){return KD.singleton("appManager").require("Login",function(){KD.getSingleton("mainController").isLoggingIn(!0)
return KD.remote.api.OAuth.getUrl(provider,function(err,url){var name,newWindow,size
if(err)return notify(err)
name="Login"
size="height=643,width=1143"
newWindow=window.open(url,name,size)
newWindow.onunload=function(){var mainController
mainController=KD.getSingleton("mainController")
return mainController.emit("ForeignAuthPopupClosed",provider)}
newWindow||notify("Please disable your popup blocker and try again.")
return newWindow.focus()})})}
OAuthController.prototype.authCompleted=function(err,provider){var mainController
mainController=KD.getSingleton("mainController")
if(err)return notify(err)
mainController.emit("ForeignAuthPopupClosed",provider)
return mainController.emit("ForeignAuthCompleted",provider)}
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
null==options.enableMoveTabHandle&&(options.enableMoveTabHandle=!1)
options.cssClass=KD.utils.curry("application-tabview",options.cssClass)
ApplicationTabView.__super__.constructor.call(this,options,data)
appManager=KD.getSingleton("appManager")
this.isSessionEnabled=options.saveSession&&options.sessionName
this.isSessionEnabled&&this.initSession()
this.on("PaneAdded",function(pane){var plusHandle,tabHandle,tabView
_this.tabHandleContainer.repositionPlusHandle(_this.handles)
_this.isSessionEnabled&&_this.sessionData&&_this.updateSession()
tabView=_this
pane.on("KDTabPaneDestroy",function(){if(0===tabView.panes.length-1){options.closeAppWhenAllTabsClosed&&appManager.quit(appManager.getFrontApp())
tabView.emit("AllTabsClosed")}return tabView.tabHandleContainer.repositionPlusHandle(tabView.handles)})
tabHandle=pane.tabHandle
plusHandle=_this.getOptions().tabHandleContainer.plusHandle
tabHandle.on("DragInAction",function(){return tabHandle.dragIsAllowed?null!=plusHandle?plusHandle.hide():void 0:void 0})
return tabHandle.on("DragFinished",function(){return null!=plusHandle?plusHandle.show():void 0})})
this.on("SaveSessionData",function(data){return _this.isSessionEnabled?_this.appStorage.setValue("sessions",data):void 0})
focusActivePane=function(pane){var mainView,tabView,_ref,_ref1
if(mainView=pane.getMainView()){tabView=pane.getMainView().tabView
if(_this===tabView)return null!=(_ref=_this.getActivePane())?null!=(_ref1=_ref.getHandle())?_ref1.$().click():void 0:void 0}}
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
ApplicationTabHandleHolder=function(_super){function ApplicationTabHandleHolder(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("application-tab-handle-holder",options.cssClass)
options.bind="mouseenter mouseleave"
null==options.addPlusHandle&&(options.addPlusHandle=!0)
ApplicationTabHandleHolder.__super__.constructor.call(this,options,data)
this.tabs=new KDCustomHTMLView({cssClass:"kdtabhandle-tabs"})}__extends(ApplicationTabHandleHolder,_super)
ApplicationTabHandleHolder.prototype.viewAppended=function(){this.addSubView(this.tabs)
return this.getOptions().addPlusHandle?this.addPlusHandle():void 0}
ApplicationTabHandleHolder.prototype.addPlusHandle=function(){var _ref,_this=this
null!=(_ref=this.plusHandle)&&_ref.destroy()
this.tabs.addSubView(this.plusHandle=new KDCustomHTMLView({cssClass:"kdtabhandle visible-tab-handle plus",partial:"<span class='icon'></span>",delegate:this,click:function(){return _this.emit("PlusHandleClicked")}}))
this.off("PlusHandleClicked")
return this.on("PlusHandleClicked",function(){return _this.getDelegate().addNewTab()})}
ApplicationTabHandleHolder.prototype.repositionPlusHandle=function(handles){var handlesLength,_ref
handlesLength=handles.length
return handlesLength?null!=(_ref=this.plusHandle)?_ref.$().insertAfter(handles[handlesLength-1].$()):void 0:void 0}
ApplicationTabHandleHolder.prototype.addHandle=function(handle){return this.tabs.addSubView(handle)}
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
this.linkedInShareLink=this.buildLinkedInShareLink()}__extends(SharePopup,_super)
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
SharePopup.prototype.pistachio=function(){return"{{> this.urlInput}}\n{{> this.twitterShareLink}}\n{{> this.facebookShareLink}}\n{{> this.linkedInShareLink}}"}
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
ProfileLinkView.prototype.render=function(fields){var nickname,_ref
nickname=null!=(_ref=this.getData().profile)?_ref.nickname:void 0
nickname&&this.setAttribute("href","/"+nickname)
return ProfileLinkView.__super__.render.call(this,fields)}
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

var ActivityLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityLinkView=function(_super){function ActivityLinkView(options,data){null==options&&(options={})
options.tagName||(options.tagName="a")
ActivityLinkView.__super__.constructor.call(this,options,data)}__extends(ActivityLinkView,_super)
ActivityLinkView.prototype.destroy=function(){ActivityLinkView.__super__.destroy.apply(this,arguments)
return KD.getSingleton("linkController").unregisterLink(this)}
ActivityLinkView.prototype.formatContent=function(str){null==str&&(str="")
str=this.utils.expandTokens(str,this.getData())
return str}
ActivityLinkView.prototype.pistachio=function(){var body,group,groupPath,slug,_ref
_ref=this.getData(),body=_ref.body,slug=_ref.slug,group=_ref.group
groupPath="koding"===group?"":"/"+group
return'<a href="'+groupPath+"/Activity/"+slug+'">{{this.formatContent(#(body))}}</a>'}
return ActivityLinkView}(JView)

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
return userInput?str?str=str.replace(RegExp(userInput,"gi"),function(match){isNick&&_this.setClass("nick-matches")
return"<b>"+match+"</b>"}):void 0:str}
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

var NominateModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NominateModal=function(_super){function NominateModal(options,data){null==options&&(options={})
options.cssClass="nominate-modal"
options.width=400
null==options.overlay&&(options.overlay=!0)
NominateModal.__super__.constructor.call(this,options,data)}__extends(NominateModal,_super)
NominateModal.prototype.viewAppended=function(){this.unsetClass("kdmodal")
return this.addSubView(new KDCustomHTMLView({partial:'<div class="logo"></div>\n<div class="header"></div>\n\n<h2>\n  Nominate Koding for\n</h2>\n<h1>\n  Best New Startup 2013\n</h1>\n\n<p>\n  The\n  <a href="http://techcrunch.com/events/7th-annual-crunchies-awards/" target="_blank">7th Annual Crunchies Awards</a> are here and we at Koding\n  would like to humbly ask for your nomination for\n  Best Startup 2013.\n</p>\n\n<p>\n  We are eternally grateful for your support.\n</p>\n\n<a href="http://crunchies2013.techcrunch.com/nominated/?MTk6S29kaW5n" target="_blank">\n  <div class="button">\n    Nominate Koding!\n  </div>\n</a>'}))}
return NominateModal}(KDModalView)

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

var BidirectionalNavigation,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BidirectionalNavigation=function(_super){function BidirectionalNavigation(){_ref=BidirectionalNavigation.__super__.constructor.apply(this,arguments)
return _ref}__extends(BidirectionalNavigation,_super)
BidirectionalNavigation.prototype.viewAppended=function(){this.setClass("navigation")
this.addSubView(this.createButton("Back"))
return this.addSubView(this.createButton("Next"))}
BidirectionalNavigation.prototype.createButton=function(action){var _this=this
return new KDButtonView({cssClass:action.toLowerCase(),title:action,callback:function(){return _this.emit(action)}})}
return BidirectionalNavigation}(KDView)

var KodingSwitch,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KodingSwitch=function(_super){function KodingSwitch(options,data){null==options&&(options={})
options.labels||(options.labels=["",""])
null==options.defaultValue&&(options.defaultValue=!1)
KodingSwitch.__super__.constructor.call(this,options,data)}__extends(KodingSwitch,_super)
KodingSwitch.prototype.setDomElement=function(cssClass){return this.domElement=$("<div class='kdinput koding-on-off off "+cssClass+"'><a href='#' class='knob' title='turn on'></a></div>")}
KodingSwitch.prototype.mouseDown=function(){return this.setValue(this.getValue()===!0?!1:!0)}
KodingSwitch.prototype.setOff=function(wCallback){null==wCallback&&(wCallback=!0)
if(this.getValue()||!wCallback){this.$("input").attr("checked",!1)
this.unsetClass("on")
this.setClass("off")
return wCallback?this.switchStateChanged():void 0}}
KodingSwitch.prototype.setOn=function(wCallback){null==wCallback&&(wCallback=!0)
if(!this.getValue()||!wCallback){this.$("input").attr("checked",!0)
this.unsetClass("off")
this.setClass("on")
return wCallback?this.switchStateChanged():void 0}}
return KodingSwitch}(KDOnOffSwitch)

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
TokenView.prototype.getIdentity=function(){var data
data=this.getData()
return""+data.bongo_.constructorName+":"+data.getId()}
TokenView.prototype.encodeValue=function(){var data,prefix
if(!(data=this.getData()))return""
prefix=this.getOptions().prefix
return"|"+prefix+":"+this.getIdentity()+"|"}
TokenView.prototype.pistachio=function(){return"{{> this.item}}"}
return TokenView}(JView)

var SuggestedTokenView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SuggestedTokenView=function(_super){function SuggestedTokenView(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("suggested",options.cssClass)
options.pistachio=""
SuggestedTokenView.__super__.constructor.call(this,options,data)}__extends(SuggestedTokenView,_super)
SuggestedTokenView.prototype.getPrefix=function(){return this.getOptions().prefix}
SuggestedTokenView.prototype.getKey=function(){return"$suggest"}
SuggestedTokenView.prototype.getIdentity=function(){var $suggest
$suggest=this.getData().$suggest
return""+this.getKey()+":"+$suggest}
SuggestedTokenView.prototype.pistachio=function(){var prefix
prefix=this.getOptions().prefix
return""+prefix+"{{#($suggest)}}"}
return SuggestedTokenView}(TokenView)

var TagContextMenuItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TagContextMenuItem=function(_super){function TagContextMenuItem(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("tag-context-menu-item",options.cssClass)
TagContextMenuItem.__super__.constructor.call(this,options,data)}__extends(TagContextMenuItem,_super)
TagContextMenuItem.prototype.pistachio=function(){return this.getData().$suggest?'Suggest <span class="ttag">{{#($suggest)}}</span> as a new topic?':"{{#(title)}}"}
return TagContextMenuItem}(JContextMenuItem)

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
AvatarView.prototype.getAvatar=function(){return this.bgImg}
AvatarView.prototype.getGravatarUri=function(){var profile,width
profile=this.getData().profile
width=this.getOptions().size.width
return profile.hash?"//gravatar.com/avatar/"+profile.hash+"?size="+width+"&d="+encodeURIComponent(this.fallbackUri):""+this.fallbackUri}
AvatarView.prototype.render=function(){var account,avatarURI,flags,height,key,onlineStatus,profile,resizedAvatar,type,value,width,_ref,_ref1
account=this.getData()
if(account){profile=account.profile,type=account.type
if("unregistered"===type)return this.setAvatar("url("+this.fallbackUri+")")
_ref=this.getOptions().size,width=_ref.width,height=_ref.height
height||(height=width)
avatarURI=this.getGravatarUri()
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

var ActivityWidgetItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityWidgetItem=function(_super){function ActivityWidgetItem(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("status-update-widget-item",options.cssClass)
ActivityWidgetItem.__super__.constructor.call(this,options,data)
this.createAuthor()
this.createCommentBox()
this.actionLinks=new ActivityActionsView({cssClass:"comment-header",delegate:this.commentBox.commentList},data)
this.timeAgo=new KDTimeAgoView(null,data.meta.createdAt)}__extends(ActivityWidgetItem,_super)
ActivityWidgetItem.prototype.createAuthor=function(){var avatarHeight,avatarWidth,origin,originId,originType,_ref,_ref1
_ref=this.getOptions(),avatarWidth=_ref.avatarWidth,avatarHeight=_ref.avatarHeight
_ref1=this.getData(),originId=_ref1.originId,originType=_ref1.originType
origin={id:originId,constructorName:originType}
this.avatar=new AvatarView({size:{width:avatarWidth||50,height:avatarHeight||50},origin:origin,showStatus:!0})
return this.author=new ProfileLinkView({origin:origin})}
ActivityWidgetItem.prototype.createCommentBox=function(){var commentSettings,_base
commentSettings=this.getOptions().commentSettings
commentSettings||(commentSettings={})
commentSettings.itemChildOptions||(commentSettings.itemChildOptions={})
null==(_base=commentSettings.itemChildOptions).showAvatar&&(_base.showAvatar=!1)
return this.commentBox=new CommentView(commentSettings,this.getData())}
ActivityWidgetItem.prototype.formatContent=function(str){null==str&&(str="")
str=this.utils.applyMarkdown(str)
str=this.utils.expandTokens(str,this.getData())
return str}
ActivityWidgetItem.prototype.pistachio=function(){return'<header>\n  {{> this.avatar}}\n  <div class="content">\n    {{> this.author}}\n    <span class="status-body">{{this.formatContent(#(body))}}</span>\n  </div>\n</header>\n<footer>\n  {{> this.actionLinks}}\n  {{> this.timeAgo}}\n</footer>\n{{> this.commentBox}}'}
return ActivityWidgetItem}(JView)

var ActivityWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityWidget=function(_super){function ActivityWidget(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("status-update-widget",options.cssClass)
options.showForm||(options.showForm=!0)
options.childOptions||(options.childOptions={})
ActivityWidget.__super__.constructor.call(this,options,data)
this.activity=null}__extends(ActivityWidget,_super)
ActivityWidget.prototype.showForm=function(callback){var _ref
null!=(_ref=this.inputWidget)&&_ref.show()
return this.inputWidget.once("Submit",callback)}
ActivityWidget.prototype.hideForm=function(){var _ref
return null!=(_ref=this.inputWidget)?_ref.hide():void 0}
ActivityWidget.prototype.display=function(id,callback){var _this=this
null==callback&&(callback=noop)
return KD.remote.cacheable("JNewStatusUpdate",id,function(err,activity){KD.showError(err)
callback(err,activity)
return activity.fetchTags(function(err,tags){activity.tags=tags
return activity&&!err?_this.addActivity(activity):void 0})})}
ActivityWidget.prototype.create=function(body,callback){var _this=this
null==callback&&(callback=noop)
return KD.remote.api.JNewStatusUpdate.create({body:body},function(err,activity){KD.showError(err)
callback(err,activity)
return activity&&!err?_this.addActivity(activity):void 0})}
ActivityWidget.prototype.reply=function(body,callback){var _ref
null==callback&&(callback=noop)
return null!=(_ref=this.activity)?_ref.reply(body,callback):void 0}
ActivityWidget.prototype.addActivity=function(activity){this.activity=activity
return this.addSubView(new ActivityWidgetItem(this.getOptions().childOptions,activity))}
ActivityWidget.prototype.setInputContent=function(str){var _ref
null==str&&(str="")
return null!=(_ref=this.inputWidget)?_ref.input.setContent(str):void 0}
ActivityWidget.prototype.viewAppended=function(){var defaultValue,showForm,_ref,_this=this
_ref=this.getOptions(),defaultValue=_ref.defaultValue,showForm=_ref.showForm
return KD.singleton("appManager").require("Activity",function(){_this.addSubView(_this.inputWidget=new ActivityInputWidget({defaultValue:defaultValue}))
return _this.inputWidget.once("Submit",function(err,activity){return err?KD.showError(err):activity?_this.addActivity(activity):void 0})})}
return ActivityWidget}(KDView)

var Junction,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
Junction=function(_super){function Junction(fields){var field,_i,_len
null==fields&&(fields=[])
Junction.__super__.constructor.call(this)
this.id=this.createId()
this.fields={}
this.children={}
this.ordered=[]
this.index=0
for(_i=0,_len=fields.length;_len>_i;_i++){field=fields[_i]
this.addField(field)}}var All,Any,_ref,_ref1
__extends(Junction,_super)
Junction.prototype.createId=KD.utils.createCounter()
Junction.prototype.isJunction=!0
Junction.prototype.getFields=function(isDeep){var child,fields,key,_,_ref,_ref1,_results
if(isDeep){fields=this.getFields()
_ref=this.children
for(_ in _ref)if(__hasProp.call(_ref,_)){child=_ref[_]
fields.push.apply(fields,child.getFields(isDeep))}return fields}_ref1=this.fields
_results=[]
for(key in _ref1)__hasProp.call(_ref1,key)&&(key in this.children||_results.push(key))
return _results}
Junction.prototype.iterate=function(){this.index++
return this.nextNode()}
Junction.prototype.nextNode=function(){var node
node=this.ordered[this.index]
if(null==node){this.index=0
return this.nextNode()}if(node.isJunction)return node.isSatisfied()?this.iterate():node.shouldPropagate()?node.nextNode():this.iterate()
this.index++
return node}
Junction.prototype.shouldPropagate=function(){return!0}
Junction.prototype.addChild=function(child){this.children[child]=child
return this}
Junction.prototype.removeChild=function(child){delete this.children[child]
return this}
Junction.prototype.addField=function(field){var satisfier
this.ordered.push(field)
satisfier=this.createSatisfier()
this.fields[field]=satisfier
if(field.isJunction){this.addChild(field)
field.on("status",function(isSatisfied){return isSatisfied?satisfier.satisfy():satisfier.cancel()})}return this}
Junction.prototype.removeKey=function(key){var child,_,_ref
if(key in this.fields){this.index=0
this.fields[key].cancel()}else{_ref=this.children
for(_ in _ref)if(__hasProp.call(_ref,_)){child=_ref[_]
child.removeKey(key)}}return this}
Junction.prototype.satisfy=function(field){var child,satisfier,_,_ref
null!=(satisfier=this.fields[field])&&satisfier.satisfy()
_ref=this.children
for(_ in _ref)if(__hasProp.call(_ref,_)){child=_ref[_]
child.satisfy(field)}return this}
Junction.prototype.createSatisfier=function(){var satisfier
satisfier=new Junction.Satisfier
satisfier.on("Satisfied",this.bound("report"))
satisfier.on("Canceled",this.bound("report"))
return satisfier}
Junction.prototype.report=function(){this.emit("status",this.isSatisfied())
return this}
Junction.prototype.kill=function(){return this.compliment(!1)}
Junction.prototype.compliment=function(value){return value}
Junction.prototype.isSatisfied=function(){var category,node,_,_i,_len,_ref
_ref=[this.fields,this.children]
for(_i=0,_len=_ref.length;_len>_i;_i++){category=_ref[_i]
for(_ in category)if(__hasProp.call(category,_)){node=category[_]
if(!this.compliment(node.isSatisfied()))return this.kill()}}return!this.kill()}
Junction.prototype.toString=function(){return"junction-"+this.id}
Junction.All=All=function(_super1){function All(){_ref=All.__super__.constructor.apply(this,arguments)
return _ref}__extends(All,_super1)
return All}(Junction)
Junction.Any=Any=function(_super1){function Any(){_ref1=Any.__super__.constructor.apply(this,arguments)
return _ref1}__extends(Any,_super1)
Any.prototype.compliment=function(value){return!value}
Any.prototype.createSatisfier=function(){return null!=this.satisfier?this.satisfier:this.satisfier=Any.__super__.createSatisfier.apply(this,arguments)}
return Any}(Junction)
Junction.all=function(){var fields
fields=1<=arguments.length?__slice.call(arguments,0):[]
return new All(fields)}
Junction.any=function(){var fields
fields=1<=arguments.length?__slice.call(arguments,0):[]
return new Any(fields)}
return Junction}(KDObject)

var __hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Junction.Satisfier=function(_super){function Satisfier(){Satisfier.__super__.constructor.call(this)
this.dirty=!1
this.satisfied=0}__extends(Satisfier,_super)
Satisfier.prototype.isSatisfied=function(){return this.satisfied>0}
Satisfier.prototype.isDirty=function(){return this.dirty}
Satisfier.prototype.satisfy=function(){this.dirty=!0
this.satisfied++
return this.emit("Satisfied")}
Satisfier.prototype.cancel=function(){this.dirty=!0
this.satisfied=Math.max(this.satisfied-1,0)
return this.emit("Canceled")}
return Satisfier}(KDEventEmitter)

var FormWorkflow,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FormWorkflow=function(_super){function FormWorkflow(options,data){null==options&&(options={})
FormWorkflow.__super__.constructor.call(this,options,data)
this.collector=new FormWorkflow.Collector
this.collector.on("Pending",this.bound("nextForm"))
this.forwardEvent(this.collector,"DataCollected")
this.forms={}
this.providers={}
this.active=null
this.history=new FormWorkflow.History}__extends(FormWorkflow,_super)
FormWorkflow.prototype.isWorkflow=!0
FormWorkflow.prototype.enter=function(){return this.ready(this.bound("nextForm"))}
FormWorkflow.prototype.go=function(direction){var provider
provider=this.history[direction]()
provider.isWorkflow&&(provider===this.active&&"back"===direction||"next"===direction)&&provider.go(direction)
return this.showForm(provider,!1)}
FormWorkflow.prototype.next=function(){return this.go("next")}
FormWorkflow.prototype.back=function(){return this.go("back")}
FormWorkflow.prototype.requireData=function(fields){this.collector.addRequirement(fields)
return this}
FormWorkflow.prototype.getFields=function(isDeep){return this.collector.getFields(isDeep)}
FormWorkflow.prototype.getData=function(){return this.collector.data}
FormWorkflow.prototype.isSatisfied=function(){return this.collector.gate.isSatisfied()}
FormWorkflow.prototype.collectData=function(data){this.collector.collectData(data)
return this}
FormWorkflow.prototype.clearData=function(key){this.collector.removeKey(key)
return this}
FormWorkflow.prototype.provideData=function(form,providers){var field,_base,_i,_len
for(_i=0,_len=providers.length;_len>_i;_i++){field=providers[_i]
null==(_base=this.providers)[field]&&(_base[field]=[])
this.providers[field].push("string"==typeof form?this.forms[form]:form)}return this}
FormWorkflow.prototype.nextForm=function(){var provider
provider=this.nextProvider()
return null!=provider?this.showForm(provider):void 0}
FormWorkflow.prototype.nextRequirement=function(){return this.collector.nextRequirement()}
FormWorkflow.prototype.nextProvider=function(key,from){var e,provider,providers,_ref
null==key&&(key=this.nextRequirement())
providers=this.providers[key]
providers.i=null!=(_ref=null!=from?from:providers.i)?_ref:0
provider=providers[providers.i++]
if(null!=provider)return provider
try{return this.nextProvider(key,0)}catch(_error){e=_error
if(!(e instanceof RangeError))throw e}}
FormWorkflow.prototype.addForm=function(formName,form,provides){null==provides&&(provides=[])
this.forms[formName]=form
this.addSubView(form)
form.hide()
this.forwardEvent(form,"Cancel")
this.provideData(formName,provides)
return this}
FormWorkflow.prototype.removeForm=function(form){form=this.getForm(form)
this.removeSubView(form)
delete this.forms[form]
return this}
FormWorkflow.prototype.getForm=function(form){return"string"==typeof form?this.forms[form]:form}
FormWorkflow.prototype.getFormNames=function(){return Object.keys(this.forms)}
FormWorkflow.prototype.hideForms=function(forms){var form,_i,_len,_ref
null==forms&&(forms=this.getFormNames())
for(_i=0,_len=forms.length;_len>_i;_i++){form=forms[_i]
null!=(_ref=this.forms[form])&&_ref.hide()}return this}
FormWorkflow.prototype.showForm=function(form,shouldPushState){null==shouldPushState&&(shouldPushState=!0)
this.hideForms()
form=this.getForm(form)
form.show()
"function"==typeof form.activate&&form.activate(this)
this.active=form
shouldPushState&&this.history.push(form)
return this}
FormWorkflow.prototype.viewAppended=function(){"function"==typeof this.prepareWorkflow&&this.prepareWorkflow()
return this.emit("ready")}
FormWorkflow.prototype.skip=function(data){var v,_this=this
v=new KDView
v.activate=function(){return _this.collectData(data)}
return v}
return FormWorkflow}(KDView)

var __hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FormWorkflow.History=function(_super){function History(){History.__super__.constructor.call(this)
this.state=-1
this.stack=[]}__extends(History,_super)
History.prototype.push=function(provider){this.stack[this.state+1]!==provider&&this.stack.push(provider)
this.emit("Push",provider)
return this.inc()}
History.prototype.lastIndex=function(){return this.stack.length-1}
History.prototype.inc=function(n){null==n&&(n=1)
this.state=Math.min(Math.max(0,this.state+n),this.lastIndex())
return this.state}
History.prototype.go=function(n){null==n&&(n=1)
return this.stack[this.inc(n)]}
History.prototype.back=function(){return this.go(-1)}
History.prototype.next=function(){return this.go(1)}
return History}(KDObject)

var __hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FormWorkflow.Collector=function(_super){function Collector(gate){var _this=this
this.gate=null!=gate?gate:new Junction
Collector.__super__.constructor.call(this)
this.data=KD.utils.dict()
this.gate.on("status",function(isSatisfied){return isSatisfied?_this.emit("DataCollected",_this.data):_this.emit("Pending")})}__extends(Collector,_super)
Collector.prototype.addRequirement=function(requirement){return this.gate.addField(requirement.isJunction?requirement:Junction.all.apply(Junction,requirement))}
Collector.prototype.nextRequirement=function(){return this.gate.nextNode()}
Collector.prototype.getFields=function(isDeep){return this.gate.getFields(isDeep)}
Collector.prototype.getData=function(){return this.data}
Collector.prototype.collectData=function(data){var key,val,_results
_results=[]
for(key in data)if(__hasProp.call(data,key)){val=data[key]
_results.push(this.defineKey(key,val))}return _results}
Collector.prototype.removeKey=function(key){delete this.data[key]
return this.gate.removeKey(key)}
Collector.prototype.defineKey=function(key,value){this.data[key]=value
return this.gate.satisfy(key)}
return Collector}(KDEventEmitter)

var FormWorkflowModal,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FormWorkflowModal=function(_super){function FormWorkflowModal(){_ref=FormWorkflowModal.__super__.constructor.apply(this,arguments)
return _ref}__extends(FormWorkflowModal,_super)
FormWorkflowModal.prototype.viewAppended=function(){var nav,workflow
this.setClass("workflow-modal")
nav=new BidirectionalNavigation
this.addSubView(nav,".kdmodal-title")
workflow=this.getOptions().view
nav.on("Back",workflow.bound("back"))
return nav.on("Next",workflow.bound("next"))}
return FormWorkflowModal}(KDModalView)

var MainNavController,NavigationController,_ref,_ref1,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
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
MainNavController=function(_super){function MainNavController(){_ref1=MainNavController.__super__.constructor.apply(this,arguments)
return _ref1}__extends(MainNavController,_super)
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
null==options.useTitle&&(options.useTitle=!0)
LikeView.__super__.constructor.call(this,options,data)
this._lastUpdatedCount=-1
this._currentState=!1
this.likeCount=new ActivityLikeCount({tooltip:{gravity:options.tooltipPosition,title:""},bind:"mouseenter",mouseenter:function(){return _this.fetchLikeInfo()},attributes:{href:"#"},click:function(){return data.meta.likes>0?data.fetchLikedByes({},{sort:{timestamp:-1}},function(err,likes){return new ShowMoreDataModalView({title:"Members who liked <cite>"+_this.utils.expandTokens(data.body,data)+"</cite>"},likes)}):void 0}},data)
this.likeLink=new ActivityActionLink
options.checkIfLikedBefore&&KD.isLoggedIn()&&data.checkIfLikedBefore(function(err,likedBefore){var useTitle
useTitle=_this.getOptions().useTitle
if(likedBefore){_this.setClass("liked")
useTitle&&_this.likeLink.updatePartial("Unlike")}else{_this.unsetClass("liked")
useTitle&&_this.likeLink.updatePartial("Like")}return _this._currentState=likedBefore})}__extends(LikeView,_super)
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
return $(event.target).is("a.action-link")?this.getData().like(function(err){var useTitle
KD.showError(err,{AccessDenied:"You are not allowed to like activities",KodingError:"Something went wrong while like"})
if(!err){_this._currentState=!_this._currentState
useTitle=_this.getOptions().useTitle
if(_this._currentState){_this.setClass("liked")
useTitle&&_this.likeLink.updatePartial("Unlike")
KD.mixpanel("Liked activity")
KD.getSingleton("badgeController").checkBadge({property:"likes",relType:"like",targetSelf:1})}else{_this.unsetClass("liked")
useTitle&&_this.likeLink.updatePartial("Like")
KD.mixpanel("Unliked activity")}return _this._lastUpdatedCount=-1}}):void 0}
LikeView.prototype.pistachio=function(){return"{{> this.likeLink}}{{> this.likeCount}}"}
return LikeView}(JView)
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
options.lazyLoaderOptions={partial:"",spinnerOptions:{loaderOptions:{color:"#6BB197"},size:{width:32}}}
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
this.setClass(bucketNameMap[data.bongo_.constructorName])
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
activityNameMap={JNewStatusUpdate:"your status update.",JCodeSnip:"your status update.",JAccount:"started following you.",JPrivateMessage:"your private message.",JComment:"your comment.",JDiscussion:"your discussion.",JOpinion:"your opinion.",JReview:"your review.",JGroup:"your group"}
bucketNameMap={CReplieeBucketActivity:"comment",CFolloweeBucketActivity:"follow",CLikeeBucketActivity:"like",CGroupJoineeBucketActivity:"groupJoined",CGroupLeaveeBucketActivity:"groupLeft"}
actionPhraseMap={comment:"commented on",reply:"replied to",like:"liked",follow:"",share:"shared",commit:"committed",member:"joined",groupJoined:"joined",groupLeft:"left"}
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
return actionPhraseMap.reply}return actionPhraseMap[bucketNameMap[data.bongo_.constructorName]]}
NotificationListItem.prototype.getActivityPlot=function(){var data
data=this.getData()
return activityNameMap[this.snapshot.anchor.constructorName]}
NotificationListItem.prototype.click=function(){var appManager,showPost,_ref1,_ref2
showPost=function(err,post){var internalApp
if(post){internalApp="JNewApp"===post.constructor.name?"Apps":"Activity"
return KD.getSingleton("router").handleRoute("/"+internalApp+"/"+post.slug,{state:post})}return new KDNotificationView({title:"This post has been deleted!",duration:1e3})}
switch(this.snapshot.anchor.constructorName){case"JPrivateMessage":appManager=KD.getSingleton("appManager")
appManager.open("Inbox")
return appManager.tell("Inbox","goToMessages")
case"JComment":case"JReview":case"JOpinion":return null!=(_ref1=KD.remote.api[this.snapshot.anchor.constructorName])?_ref1.fetchRelated(this.snapshot.anchor.id,showPost):void 0
case"JGroup":break
default:if("JAccount"!==this.snapshot.anchor.constructorName)return null!=(_ref2=KD.remote.api[this.snapshot.anchor.constructorName])?_ref2.one({_id:this.snapshot.anchor.id},showPost):void 0}}
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
options.tagName="aside"
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
CommonInnerNavigationListController=function(_super){function CommonInnerNavigationListController(options,data){var listView,_this=this
null==options&&(options={})
options.viewOptions||(options.viewOptions={itemClass:options.itemClass||CommonInnerNavigationListItem})
null==options.scrollView&&(options.scrollView=!1)
null==options.wrapper&&(options.wrapper=!1)
options.view||(options.view=new CommonInnerNavigationList(options.viewOptions))
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
options.tagName||(options.tagName="nav")
options.type="inner-nav"
CommonInnerNavigationList.__super__.constructor.call(this,options,data)}__extends(CommonInnerNavigationList,_super)
return CommonInnerNavigationList}(KDListView)
CommonInnerNavigationListItem=function(_super){function CommonInnerNavigationListItem(options,data){null==options&&(options={})
options.tagName||(options.tagName="a")
options.attributes={href:data.slug||"#"}
options.partial||(options.partial=data.title)
CommonInnerNavigationListItem.__super__.constructor.call(this,options,data)}__extends(CommonInnerNavigationListItem,_super)
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
options={title:"Please provide the PIN that we've emailed you",overlay:!0,width:568,height:"auto",tabs:{navigable:!0,forms:{form:{callback:function(){callback(_this.modalTabs.forms.form.inputs.pin.getValue())
return _this.destroy()},buttons:{Submit:{title:buttonTitle,cssClass:"modal-clean-green",type:"submit"}},fields:{pin:{name:"pin",placeholder:"PIN",testPath:"account-email-pin",validate:{rules:{required:!0},messages:{required:"PIN required!"}}}}}}}}
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
KD.getSingleton("badgeController").checkBadge({property:"following",relType:"follower",source:"JAccount",targetSelf:1})
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

var AdminModal,MemberAutoCompleteItemView,MemberAutoCompletedItemView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AdminModal=function(_super){function AdminModal(options,data){var buttons,inputs,preset,_ref,_this=this
null==options&&(options={})
if(KD.checkFlag("super-admin")){options={title:"Admin panel",content:"<div class='modalformline'>With great power comes great responsibility. ~ Stan Lee</div>",overlay:!0,width:600,height:"auto",cssClass:"admin-kdmodal",tabs:{navigable:!0,goToNextFormOnSubmit:!1,forms:{"User Details":{buttons:{Update:{title:"Update",style:"modal-clean-gray",loader:{color:"#444444",diameter:12},callback:function(){var account,accounts,buttons,flag,flags,inputs,_ref
_ref=_this.modalTabs.forms["User Details"],inputs=_ref.inputs,buttons=_ref.buttons
accounts=_this.userController.getSelectedItemData()
if(accounts.length>0){account=accounts[0]
flags=function(){var _i,_len,_ref1,_results
_ref1=inputs.Flags.getValue().split(",")
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){flag=_ref1[_i]
_results.push(flag.trim())}return _results}()
return account.updateFlags(flags,function(err){err&&error(err)
new KDNotificationView({title:err?"Failed!":"Done!"})
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
default:return"No timer will be shown."}}())},nextElement:{presetExplanation:{cssClass:"type-explain",itemClass:KDView,partial:"This will show a timer."}}}}}}}}
AdminModal.__super__.constructor.call(this,options,data)
_ref=this.modalTabs.forms["Broadcast Message"],inputs=_ref.inputs,buttons=_ref.buttons
preset=inputs.Type.change()
this.hideConnectedFields()
this.initIntroductionTab()
this.createUserAutoComplete()}}__extends(AdminModal,_super)
AdminModal.prototype.createUserAutoComplete=function(){var buttons,fields,inputs,userRequestLineEdit,_ref,_this=this
_ref=this.modalTabs.forms["User Details"],fields=_ref.fields,inputs=_ref.inputs,buttons=_ref.buttons
this.userController=new KDAutoCompleteController({form:this.modalTabs.forms["User Details"],name:"userController",itemClass:MemberAutoCompleteItemView,itemDataPath:"profile.nickname",outputWrapper:fields.userWrapper,selectedItemClass:MemberAutoCompletedItemView,listWrapperCssClass:"users",submitValuesAsText:!0,dataSource:function(args,callback){var inputValue,query
inputValue=args.inputValue
if(/^@/.test(inputValue)){query={"profile.nickname":inputValue.replace(/^@/,"")}
return KD.remote.api.JAccount.one(query,function(err,account){return account?callback([account]):_this.userController.showNoDataFound()})}return KD.remote.api.JAccount.byRelevance(inputValue,{},function(err,accounts){return callback(accounts)})}})
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
MemberAutoCompleteItemView=function(_super){function MemberAutoCompleteItemView(options,data){var userInput
options.cssClass="clearfix member-suggestion-item"
MemberAutoCompleteItemView.__super__.constructor.call(this,options,data)
userInput=options.userInput||this.getDelegate().userInput
this.addSubView(this.profileLink=new AutoCompleteProfileTextView({userInput:userInput,shouldShowNick:!0},data))}__extends(MemberAutoCompleteItemView,_super)
MemberAutoCompleteItemView.prototype.viewAppended=function(){return JView.prototype.viewAppended.call(this)}
return MemberAutoCompleteItemView}(KDAutoCompleteListItemView)
MemberAutoCompletedItemView=function(_super){function MemberAutoCompletedItemView(){_ref=MemberAutoCompletedItemView.__super__.constructor.apply(this,arguments)
return _ref}__extends(MemberAutoCompletedItemView,_super)
MemberAutoCompletedItemView.prototype.viewAppended=function(){this.addSubView(this.profileText=new AutoCompleteProfileTextView({},this.getData()))
return JView.prototype.viewAppended.call(this)}
return MemberAutoCompletedItemView}(KDAutoCompletedItem)

var NavigationList,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NavigationList=function(_super){function NavigationList(){var _this=this
NavigationList.__super__.constructor.apply(this,arguments)
this.viewWidth=55
this.on("ItemWasAdded",function(view){var lastChange
view.once("viewAppended",function(){null==view._index&&(view._index=_this.getItemIndex(view))
view.setX(view._index*_this.viewWidth)
return _this._width=_this.viewWidth*(_this.items.length+1)})
lastChange=0
view.on("DragInAction",function(x,y){var current
if(!(x+view._x>_this._width||x+view._x<0)){"persistent"!==view.data.type&&y>125?view.setClass("remove"):view.unsetClass("remove")
current=x>_this.viewWidth?Math.floor(x/_this.viewWidth):x<-_this.viewWidth?Math.ceil(x/_this.viewWidth):0
if(current>lastChange){_this.moveItemToIndex(view,view._index+1)
return lastChange=current}if(lastChange>current){_this.moveItemToIndex(view,view._index-1)
return lastChange=current}}})
return view.on("DragFinished",function(){view.unsetClass("no-anim remove")
if("persistent"!==view.data.type&&view.getY()>125){view.setClass("explode")
KD.utils.wait(500,function(){_this.removeItem(view)
_this.updateItemPositions()
return KD.singletons.dock.saveItemOrders(_this.items)})}else{KD.utils.wait(200,function(){return view.unsetClass("on-top")})
view.setX(view._index*_this.viewWidth)
view.setY(0)
KD.singletons.dock.saveItemOrders(_this.items)}return lastChange=0})})}__extends(NavigationList,_super)
NavigationList.prototype.updateItemPositions=function(exclude){var index,_i,_item,_len,_ref,_results
_ref=this.items
_results=[]
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){_item=_ref[index]
_item._index=index
exclude!==_item?_results.push(_item.setX(index*this.viewWidth)):_results.push(void 0)}return _results}
NavigationList.prototype.moveItemToIndex=function(item,index){NavigationList.__super__.moveItemToIndex.call(this,item,index)
return this.updateItemPositions(item)}
return NavigationList}(KDListView)

var NavigationLink,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
NavigationLink=function(_super){function NavigationLink(options,data){var appsHasIcon,ep,href,_ref
null==options&&(options={})
null==data&&(data={})
href=(ep=KD.config.entryPoint)?ep.slug+data.path:data.path
data.type||(data.type="")
options.tagName||(options.tagName="a")
options.type||(options.type="main-nav")
options.draggable=!0
options.attributes={href:href}
options.cssClass=KD.utils.curry(this.utils.slugify(data.title),options.cssClass)
NavigationLink.__super__.constructor.call(this,options,data)
this.name=data.title
this.icon=new KDCustomHTMLView({cssClass:"fake-icon",partial:"<span class='logo'>"+this.name[0]+"</span>"})
this.icon.setCss("backgroundColor",KD.utils.getColorFromString(this.name))
appsHasIcon=Object.keys(KD.config.apps)
appsHasIcon.push("Editor");(_ref=this.name,__indexOf.call(appsHasIcon,_ref)>=0)&&this.icon.hide()
this.on("DragStarted",this.bound("dragStarted"))}__extends(NavigationLink,_super)
NavigationLink.prototype.setState=function(state){var states
null==state&&(state="initial")
states="running failed loading"
this.unsetClass(states)
return __indexOf.call(states.split(" "),state)>=0?this.setClass(state):void 0}
NavigationLink.prototype.click=function(event){var appPath,mc,path,title,topLevel,type,_ref
KD.utils.stopDOMEvent(event)
_ref=this.getData(),appPath=_ref.appPath,title=_ref.title,path=_ref.path,type=_ref.type,topLevel=_ref.topLevel
if(!path||this.positionChanged())return!1
mc=KD.getSingleton("mainController")
return mc.emit("NavigationLinkTitleClick",{pageName:title,appPath:appPath||title,path:path,topLevel:topLevel,navItem:this})}
NavigationLink.prototype.viewAppended=function(){JView.prototype.viewAppended.call(this)
return this.keepCurrentPosition()}
NavigationLink.prototype.pistachio=function(){return"{{> this.icon}}\n<span class='icon'></span>\n<cite>"+this.name+"</cite>"}
NavigationLink.prototype.dragStarted=function(){this.keepCurrentPosition()
return this.setClass("no-anim on-top")}
NavigationLink.prototype.keepCurrentPosition=function(){this._x=this.getX()
this._y=this.getY()
this._rx=this.getRelativeX()
return this._ry=this.getRelativeY()}
NavigationLink.prototype.restoreLastPosition=function(){this.setX(this._rx)
return this.setY(this._ry)}
NavigationLink.prototype.positionChanged=function(){return this.getRelativeY()!==this._ry||this.getRelativeX()!==this._rx}
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
this.docsLink=new KDCustomHTMLView({tagName:"a",partial:"Docs",cssClass:"ext",attributes:{href:"http://learn.koding.com",target:"_blank"}})
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

var LocationController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LocationController=function(_super){function LocationController(){_ref=LocationController.__super__.constructor.apply(this,arguments)
return _ref}__extends(LocationController,_super)
LocationController.prototype.fetchCountryData=function(callback){var JPayment,ip,_this=this
JPayment=KD.remote.api.JPayment
if(this.countries||this.countryOfIp)return this.utils.defer(function(){return callback(null,_this.countries,_this.countryOfIp)})
ip=$.cookie("clientIPAddress")
return JPayment.fetchCountryDataByIp(ip,function(err,countries,countryOfIp){_this.countries=countries
_this.countryOfIp=countryOfIp
return callback(err,_this.countries,_this.countryOfIp)})}
LocationController.prototype.createLocationForm=function(options,data){var form
form=new LocationForm(options,data)
this.fetchCountryData(function(err,countries,countryOfIp){return KD.showError(err)?void 0:form.setCountryData({countries:countries,countryOfIp:countryOfIp})})
return form}
return LocationController}(KDController)

var LocationForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LocationForm=function(_super){function LocationForm(options,data){var _this=this
null==options&&(options={})
null==data&&(data={})
options.cssClass=KD.utils.curry("location-form",options.cssClass)
LocationForm.__super__.constructor.call(this,this.prepareOptions(options,data),data)
this.countryLoader=new KDLoaderView({size:{width:14},showLoader:!0})
this.on("FormValidationFailed",function(){return _this.buttons.Save.hideLoader()})}__extends(LocationForm,_super)
LocationForm.prototype.prepareOptions=function(options,data){var requirePhone,_base,_base1,_base2,_base3,_base4,_base5,_ref,_ref1
null==options.fields&&(options.fields={})
null==(_base=options.fields).company&&(_base.company={label:"Company & VAT",placeholder:"Company (optional)",defaultValue:data.company,nextElementFlat:{vatNumber:{placeholder:"VAT Number (optional)",defaultValue:data.vatNumber}}})
null==(_base1=options.fields).address1&&(_base1.address1={label:"Address & ZIP",placeholder:"Address",required:"Address is required",defaultValue:data.address1,nextElementFlat:{zip:{placeholder:"ZIP",defaultValue:data.zip,keyup:this.bound("handleZipCode"),required:"Zip is required"}}})
null==(_base2=options.fields).city&&(_base2.city={label:"City & State",placeholder:"City",defaultValue:data.city,required:"City is required",nextElementFlat:{state:{placeholder:"State",itemClass:KDSelectBox,defaultValue:data.state,required:"State is required"}}})
null==(_base3=options.fields).country&&(_base3.country={label:"Country",itemClass:KDSelectBox,defaultValue:data.country||"US"})
if((null!=(_ref=options.phone)?_ref.show:void 0)||(null!=(_ref1=options.phone)?_ref1.required:void 0)){requirePhone=options.phone.required
null==(_base4=options.fields).phone&&(_base4.phone={label:"Phone",placeholder:requirePhone?"":"(optional)",defaultValue:data.phone})
requirePhone&&(options.fields.phone.required="Phone number is required.")}if(options.buttons===!1)delete options.buttons
else{null==options.buttons&&(options.buttons={})
null==(_base5=options.buttons).Save&&(_base5.Save={style:"modal-clean-green",type:"submit",loader:{color:"#fff",diameter:12}})}return options}
LocationForm.prototype.handleZipCode=function(){var JLocation,city,country,locationSelector,state,zip,_ref,_this=this
JLocation=KD.remote.api.JLocation
_ref=this.inputs,city=_ref.city,state=_ref.state,country=_ref.country,zip=_ref.zip
locationSelector={zip:zip.getValue(),countryCode:country.getValue()}
return JLocation.one(locationSelector,function(err,location){return location?_this.setLocation(location):void 0})}
LocationForm.prototype.handleCountryCode=function(){var JLocation,actualState,country,countryCode,state,_ref,_ref1
JLocation=KD.remote.api.JLocation
_ref=this.inputs,country=_ref.country,state=_ref.state
_ref1=this.getData(),actualState=_ref1.actualState,countryCode=_ref1.country
if(this.countryCode!==countryCode){this.countryCode=countryCode
return JLocation.fetchStatesByCountryCode(countryCode,function(err,states){state.setSelectOptions(_.values(states))
return state.setValue(actualState)})}}
LocationForm.prototype.setLocation=function(location){var _this=this
return["city","stateCode","countryCode"].forEach(function(field){var input,inputName,value
value=location[field]
inputName=function(){switch(field){case"city":return"city"
case"stateCode":this.addCustomData("actualState",value)
return"state"
case"countryCode":return"country"}}.call(_this)
input=_this.inputs[inputName]
return null!=input?input.setValue(value):void 0})}
LocationForm.prototype.setCountryData=function(_arg){var countries,country,countryOfIp
countries=_arg.countries,countryOfIp=_arg.countryOfIp
country=this.inputs.country
country.setSelectOptions(_.values(countries))
country.setValue(countries[countryOfIp]?countryOfIp:"US")
this.handleCountryCode()
return this.emit("CountryDataPopulated")}
return LocationForm}(KDFormViewWithFields)

var BadgeController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BadgeController=function(_super){function BadgeController(){_ref=BadgeController.__super__.constructor.apply(this,arguments)
return _ref}__extends(BadgeController,_super)
BadgeController.prototype.checkBadge=function(options){var client
client=KD.whoami()
return client.updateCountAndCheckBadge(options,function(err,badges){var badge,_i,_len,_results
err&&warn(err)
_results=[]
for(_i=0,_len=badges.length;_len>_i;_i++){badge=badges[_i]
new KDNotificationView({title:"Congratz dude you got the "+badge.title+" badge!",subtitle:badge.description,content:"<img src='"+badge.iconURL+"'/>",type:"growl",duration:2e3})
_results.push(KD.mixpanel("Badge Gained",badge.title))}return _results})}
return BadgeController}(KDController)

var PaymentController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentController=function(_super){function PaymentController(){_ref=PaymentController.__super__.constructor.apply(this,arguments)
return _ref}__extends(PaymentController,_super)
PaymentController.prototype.fetchPaymentMethods=function(callback){var appStorage,dash,methods,preferredPaymentMethod,queue
dash=Bongo.dash
methods=null
preferredPaymentMethod=null
appStorage=new AppStorage("Account","1.0")
queue=[function(){return appStorage.fetchStorage(function(){preferredPaymentMethod=appStorage.getValue("preferredPaymentMethod")
return queue.fin()})},function(){return KD.whoami().fetchPaymentMethods(function(err,paymentMethods){methods=paymentMethods
return queue.fin(err)})}]
return dash(queue,function(err){return callback(err,{preferredPaymentMethod:preferredPaymentMethod,methods:methods,appStorage:appStorage})})}
PaymentController.prototype.observePaymentSave=function(modal,callback){var _this=this
return modal.on("PaymentInfoSubmitted",function(paymentMethodId,updatedPaymentInfo){return _this.updatePaymentInfo(paymentMethodId,updatedPaymentInfo,function(err,savedPaymentInfo){if(err)return callback(err)
callback(null,savedPaymentInfo)
return _this.emit("PaymentDataChanged")})})}
PaymentController.prototype.removePaymentMethod=function(paymentMethodId,callback){var JPayment,_this=this
JPayment=KD.remote.api.JPayment
return JPayment.removePaymentMethod(paymentMethodId,function(err){return err?callback(err):_this.emit("PaymentDataChanged")})}
PaymentController.prototype.fetchSubscription=function(){var fetchSubscription,findActiveSubscription
findActiveSubscription=function(subscriptions,planCode,callback){var paymentMethodId,sub,subs,_i,_len,_ref1
for(paymentMethodId in subscriptions)if(__hasProp.call(subscriptions,paymentMethodId)){subs=subscriptions[paymentMethodId]
for(_i=0,_len=subscriptions.length;_len>_i;_i++){sub=subscriptions[_i]
if(sub.planCode===planCode&&("canceled"===(_ref1=sub.status)||"active"===_ref1))return callback(null,sub)}}return callback(null)}
return fetchSubscription=function(type,planCode,callback){var JPaymentSubscription
JPaymentSubscription=KD.remote.api.JPaymentSubscription
return"group"===type?KD.getGroup().checkPayment(function(err,subs){return findActiveSubscription(subs,planCode,callback)}):JPaymentSubscription.fetchUserSubscriptions(function(err,subs){return findActiveSubscription(subs,planCode,callback)})}}()
PaymentController.prototype.fetchPlanByCode=function(planCode,callback){var JPaymentPlan
JPaymentPlan=KD.remote.api.JPaymentPlan
return JPaymentPlan.fetchPlanByCode(planCode,callback)}
PaymentController.prototype.fetchPaymentInfo=function(type,callback){var JPaymentPlan
JPaymentPlan=KD.remote.api.JPaymentPlan
switch(type){case"group":case"expensed":return KD.getGroup().fetchPaymentInfo(callback)
case"user":return JPaymentPlan.fetchAccountDetails(callback)}}
PaymentController.prototype.updatePaymentInfo=function(paymentMethodId,paymentMethod,callback){var JPayment
JPayment=KD.remote.api.JPayment
return JPayment.setPaymentInfo(paymentMethodId,paymentMethod,callback)}
PaymentController.prototype.createPaymentInfoModal=function(){return new PaymentFormModal}
PaymentController.prototype.createUpgradeForm=function(tag,options){var dash,form,_this=this
null==options&&(options={})
dash=Bongo.dash
form=new PlanUpgradeForm({tag:tag})
KD.getGroup().fetchProducts("plan",{tags:tag},function(err,plans){var queue,subscription
if(!KD.showError(err)){queue=plans.map(function(plan){return function(){return plan.fetchProducts(function(err,products){if(!KD.showError(err)){plan.childProducts=products
return queue.fin()}})}})
subscription=null
queue.push(function(){return _this.fetchSubscriptionsWithPlans({tags:tag},function(err,_arg){var subscription_
subscription_=_arg[0]
subscription=subscription_
return queue.fin()})})
return dash(queue,function(){form.setPlans(plans)
return subscription?form.setCurrentSubscription(subscription,options):void 0})}})
return form}
PaymentController.prototype.createUpgradeWorkflow=function(tag,options){var upgradeForm,workflow,_this=this
null==options&&(options={})
upgradeForm=this.createUpgradeForm(tag,options)
workflow=new PaymentWorkflow({productForm:upgradeForm,confirmForm:new PlanUpgradeConfirmForm})
upgradeForm.on("PlanSelected",function(plan){var oldSubscription,spend,_ref1
oldSubscription=workflow.collector.data.oldSubscription
spend=null!=(_ref1=null!=oldSubscription?oldSubscription.usage:void 0)?_ref1:{}
return plan.checkQuota({},spend,1,function(err){return KD.showError(err)?void 0:workflow.collectData({productData:{plan:plan}})})}).on("CurrentSubscriptionSet",function(oldSubscription){return workflow.collectData({oldSubscription:oldSubscription})})
workflow.on("DataCollected",function(data){return _this.transitionSubscription(data,function(err){return KD.showError(err)?void 0:workflow.emit("Finished")})}).enter()
return workflow}
PaymentController.prototype.confirmReactivation=function(subscription,callback){var modal
return modal=KDModalView.confirm({title:"Inactive subscription",description:"Your existing subscription for this plan has been canceled.  Would\nyou like to reactivate it?",subView:new SubscriptionView({},subscription),ok:{title:"Reactivate",callback:function(){return subscription.resume(function(err){if(err)return callback(err)
modal.destroy()
return callback(null,subscription)})}}})}
PaymentController.prototype.createSubscription=function(_arg,callback){var billing,createAccount,email,paymentMethod,paymentMethodId,plan,_this=this
plan=_arg.plan,email=_arg.email,paymentMethod=_arg.paymentMethod,createAccount=_arg.createAccount
paymentMethodId=paymentMethod.paymentMethodId,billing=paymentMethod.billing
return plan.subscribe(paymentMethodId,function(err,subscription){var JUser,existingSubscription,firstName,lastName
if("existing_subscription"===(null!=err?err.short:void 0)){existingSubscription=err.existingSubscription
if("active"===existingSubscription.status){new KDNotificationView({title:"You are already subscribed to this plan!"})
return KD.getSingleton("router").handleRoute("/Account/Subscriptions")}existingSubscription.plan=plan
return _this.confirmReactivation(existingSubscription,callback)}if(createAccount){JUser=KD.remote.api.JUser
firstName=billing.cardFirstName,lastName=billing.cardLastName
return JUser.convert({firstName:firstName,lastName:lastName,email:email},function(err){return err?callback(err):JUser.logout(function(err){return err?callback(err):callback(null)})})}return callback(err,subscription)})}
PaymentController.prototype.transitionSubscription=function(formData,callback){var createAccount,email,oldSubscription,paymentMethod,paymentMethodId,plan,planCode,productData
productData=formData.productData,oldSubscription=formData.oldSubscription,paymentMethod=formData.paymentMethod,createAccount=formData.createAccount,email=formData.email
plan=productData.plan
planCode=plan.planCode
paymentMethodId=paymentMethod.paymentMethodId
return oldSubscription?oldSubscription.transitionTo({planCode:planCode,paymentMethodId:paymentMethodId},callback):this.createSubscription({plan:plan,email:email,paymentMethod:paymentMethod,createAccount:createAccount},callback)}
PaymentController.prototype.debitSubscription=function(subscription,pack,callback){var _this=this
return subscription.debit(pack,function(err,nonce){if(!KD.showError(err)){_this.emit("SubscriptionDebited",subscription)
return callback(null,nonce)}})}
PaymentController.prototype.fetchSubscriptionsWithPlans=function(options,callback){var _ref1,_this=this
callback||(_ref1=[options,callback],callback=_ref1[0],options=_ref1[1])
null==options&&(options={})
return KD.whoami().fetchPlansAndSubscriptions(options,function(err,plansAndSubs){var subscriptions
if(err)return callback(err)
subscriptions=_this.groupPlansBySubscription(plansAndSubs).subscriptions
return callback(null,subscriptions)})}
PaymentController.prototype.groupPlansBySubscription=function(plansAndSubscriptions){var plans,plansByCode,subscription,subscriptions,_i,_len
null==plansAndSubscriptions&&(plansAndSubscriptions={})
plans=plansAndSubscriptions.plans,subscriptions=plansAndSubscriptions.subscriptions
plansByCode=plans.reduce(function(memo,plan){memo[plan.planCode]=plan
return memo},{})
for(_i=0,_len=subscriptions.length;_len>_i;_i++){subscription=subscriptions[_i]
subscription.plan=plansByCode[subscription.planCode]}return{plans:plans,subscriptions:subscriptions}}
return PaymentController}(KDController)

var PaymentMethodView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentMethodView=function(_super){function PaymentMethodView(options,data){PaymentMethodView.__super__.constructor.apply(this,arguments)
this.loader=new KDLoaderView({size:{width:14},showLoader:null==data})
this.paymentMethodInfo=new KDCustomHTMLView({cssClass:"billing-link"})
this.paymentMethodInfo.hide()
this.setPaymentInfo(data)}__extends(PaymentMethodView,_super)
PaymentMethodView.prototype.getCardInfoPartial=function(paymentMethod){var address,address1,address2,cardFirstName,cardLastName,cardMonth,cardNumber,cardType,cardYear,city,description,numberPrefix,postal,state,type,zip
if(!paymentMethod)return"Enter billing information"
description=paymentMethod.description,cardFirstName=paymentMethod.cardFirstName,cardLastName=paymentMethod.cardLastName,cardNumber=paymentMethod.cardNumber,cardType=paymentMethod.cardType,cardYear=paymentMethod.cardYear,cardMonth=paymentMethod.cardMonth,address1=paymentMethod.address1,address2=paymentMethod.address2,city=paymentMethod.city,state=paymentMethod.state,zip=paymentMethod.zip
type=KD.utils.slugify(cardType).toLowerCase()
this.setClass(type)
address=[address1,address2].filter(Boolean).join("<br>")
null==description&&(description=""+cardFirstName+"'s "+cardType)
postal=[city,state,zip].filter(Boolean).join(" ")
cardMonth=("0"+cardMonth).slice(-2)
cardYear=(""+cardYear).slice(-2)
numberPrefix="american-express"===type?"**** ****** *":"**** **** **** "
return"<pre>"+numberPrefix+cardNumber.slice(-4)+"</pre>\n<pre>"+cardFirstName+" "+cardLastName+" <span>"+cardMonth+"/"+cardYear+"</span></pre>"}
PaymentMethodView.prototype.setPaymentInfo=function(paymentMethod){this.loader.hide()
paymentMethod&&this.setData(paymentMethod)
this.paymentMethodInfo.updatePartial(this.getCardInfoPartial(null!=paymentMethod?paymentMethod.billing:void 0))
return this.paymentMethodInfo.show()}
PaymentMethodView.prototype.pistachio=function(){return"<figure></figure>\n{{> this.loader}}\n{{> this.paymentMethodInfo}}"}
return PaymentMethodView}(JView)

var SubscriptionView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SubscriptionView=function(_super){function SubscriptionView(){_ref=SubscriptionView.__super__.constructor.apply(this,arguments)
return _ref}var describeSubscription
__extends(SubscriptionView,_super)
describeSubscription=function(quantity,verbPhrase){return"Subscription for "+KD.utils.formatPlural(quantity,"plan")+" "+verbPhrase}
SubscriptionView.prototype.pistachio=function(){var dateNotice,displayAmount,expires,feeAmount,plan,quantity,renew,startsAt,status,statusNotice,usage,_ref1
_ref1=this.getData(),quantity=_ref1.quantity,plan=_ref1.plan,status=_ref1.status,renew=_ref1.renew,expires=_ref1.expires,usage=_ref1.usage,startsAt=_ref1.startsAt
feeAmount=plan.feeAmount
statusNotice=function(){switch(status){case"active":case"modified":return describeSubscription(quantity,"is active")
case"canceled":return describeSubscription(quantity,"will end soon")
case"future":return describeSubscription(quantity,"will begin soon")
default:return""}}()
dateNotice=function(){if("single"===plan.type)return""
switch(status){case"active":return"Plan will renew on "+dateFormat(renew)
case"canceled":return"Plan will be available till "+dateFormat(expires)
case"future":return"Plan will become available on "+dateFormat(startsAt)}}()
displayAmount=KD.utils.formatMoney(feeAmount/100)
return"<h4>{{#(plan.title)}} - "+displayAmount+"</h4>\n<span class='payment-type'>"+statusNotice+"</span>\n<p>"+dateNotice+"</p>"}
return SubscriptionView}(JView)

var SubscriptionUsageView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SubscriptionUsageView=function(_super){function SubscriptionUsageView(){_ref=SubscriptionUsageView.__super__.constructor.apply(this,arguments)
return _ref}__extends(SubscriptionUsageView,_super)
SubscriptionUsageView.prototype.getGauges=function(){var components,componentsByPlanCode,plan,subscription,usage,_ref1
_ref1=this.getOptions(),subscription=_ref1.subscription,components=_ref1.components
plan=subscription.plan
componentsByPlanCode=components.reduce(function(memo,component){memo[component.planCode]=component
return memo},{})
return usage=Object.keys(subscription.usage).map(function(key){usage={component:componentsByPlanCode[key],quota:plan.quantities[key],usage:subscription.usage[key]}
usage.usageRatio=usage.usage/usage.quota
return usage})}
SubscriptionUsageView.prototype.createGaugeListController=function(){var controller
controller=new KDListViewController({itemClass:SubscriptionGaugeItem})
controller.instantiateListItems(this.getGauges())
return controller}
SubscriptionUsageView.prototype.viewAppended=function(){this.setClass("subscription-gauges")
this.gaugeListController=this.createGaugeListController()
return this.addSubView(this.gaugeListController.getListView())}
return SubscriptionUsageView}(KDView)

var SubscriptionGaugeItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
SubscriptionGaugeItem=function(_super){function SubscriptionGaugeItem(options,data){null==options&&(options={})
SubscriptionGaugeItem.__super__.constructor.call(this,options,data)}__extends(SubscriptionGaugeItem,_super)
SubscriptionGaugeItem.prototype.partial=function(){var usage
usage=this.getData()
return"<h3>\n  Component:  "+usage.component.title+"\n</h3>\n<p>\n  Used:       <strong>"+usage.usage+"</strong>\n</p>\n<p>\n  Quota:      <strong>"+usage.quota+"</strong>\n</p>\n<p>\n  Ratio:      <strong>"+100*usage.usageRatio+"%</strong>\n</p>"}
return SubscriptionGaugeItem}(KDListItemView)

var PaymentMethodEntryForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentMethodEntryForm=function(_super){function PaymentMethodEntryForm(options){var expiresMonth,expiresYear,fields,thisYear,_this=this
null==options&&(options={})
thisYear=expiresYear=(new Date).getFullYear()
expiresMonth=(new Date).getMonth()+2
if(expiresMonth>12){expiresYear+=1
expiresMonth%=12}fields={cardFirstName:{label:"Name",placeholder:"First name",defaultValue:KD.whoami().profile.firstName,required:"First name is required!",keyup:this.bound("updateDescription"),nextElementFlat:{cardLastName:{placeholder:"Last name",defaultValue:KD.whoami().profile.lastName,required:"Last name is required!"}}},cardDescription:{label:"Description",cssClass:"hidden"},cardNumber:{label:"Credit card",placeholder:"Credit card number",blur:function(){this.oldValue=this.getValue()
return this.setValue(this.oldValue.replace(/\s|-/g,""))},focus:function(){return this.oldValue?this.setValue(this.oldValue):void 0},validate:{event:"blur",rules:{creditCard:!0,maxLength:16},messages:{maxLength:"Credit card number should be 12 to 16 digits long!"}},nextElementFlat:{cardCV:{placeholder:"CVC",validate:{rules:{required:!0,regExp:/[0-9]{3,4}/},messages:{required:"Card verification code (CVC) is required!",regExp:"Card verification code (CVC) should be a 3- or 4-digit number!"}}}}},cardMonth:{label:"Expires",itemClass:KDSelectBox,selectOptions:__utils.getMonthOptions(),defaultValue:expiresMonth,nextElementFlat:{cardYear:{itemClass:KDSelectBox,selectOptions:__utils.getYearOptions(thisYear,thisYear+25),defaultValue:expiresYear}}}}
PaymentMethodEntryForm.__super__.constructor.call(this,{cssClass:KD.utils.curry("payment-form",options.cssClass),fields:fields,callback:function(formData){return _this.emit("PaymentInfoSubmitted",_this.paymentMethodId,formData)},buttons:{Save:{title:"Save",style:"modal-clean-green",type:"submit",loader:{color:"#fff",diameter:12}}}})}__extends(PaymentMethodEntryForm,_super)
PaymentMethodEntryForm.prototype.viewAppended=function(){var cardNumberInput,_this=this
PaymentMethodEntryForm.__super__.viewAppended.call(this)
cardNumberInput=this.inputs.cardNumber
cardNumberInput.on("keyup",this.bound("handleCardKeyup"))
this.on("FormValidationFailed",function(){return _this.buttons.Save.hideLoader()})
cardNumberInput.on("ValidationError",function(){return this.parent.unsetClass("visa mastercard amex diners discover jcb")})
cardNumberInput.on("CreditCardTypeIdentified",function(type){var cardType
this.parent.unsetClass("visa mastercard amex diners discover jcb")
cardType=type.toLowerCase()
return this.parent.setClass(cardType)})
this.fields.cardNumber.addSubView(this.icon=new KDCustomHTMLView({tagName:"span",cssClass:"icon"}))
return this.updateDescription()}
PaymentMethodEntryForm.prototype.activate=function(){var cardFirstName,cardLastName,cardNumber,input,_i,_len,_ref,_ref1
_ref=this.inputs,cardFirstName=_ref.cardFirstName,cardLastName=_ref.cardLastName,cardNumber=_ref.cardNumber
_ref1=[cardFirstName,cardLastName,cardNumber]
for(_i=0,_len=_ref1.length;_len>_i;_i++){input=_ref1[_i]
if(!input.getValue())return input.setFocus()}}
PaymentMethodEntryForm.prototype.getCardInputValue=function(){return this.inputs.cardNumber.getValue().replace(/-|\s/g,"")}
PaymentMethodEntryForm.prototype.getCardType=function(value){null==value&&(value=this.getCardInputValue())
switch(!1){case!/^4/.test(value):return"Visa"
case!/^5[1-5]/.test(value):return"MasterCard"
case!/^3[47]/.test(value):return"Amex"
case!/^6(?:011|5[0-9]{2})/.test(value):return"Discover"
default:return"Unknown"}}
PaymentMethodEntryForm.prototype.updateCardTypeDisplay=function(cardType){var $icon
null==cardType&&(cardType=this.getCardType())
this.addCustomData("cardType",cardType)
cardType=cardType.toLowerCase()
$icon=this.icon.$()
if(!$icon.hasClass(cardType)){$icon.removeClass("visa mastercard discover amex unknown")
cardType&&$icon.addClass(cardType)}return this.updateDescription()}
PaymentMethodEntryForm.prototype.updateDescription=function(){var cardFirstName,cardOwner,cardType,formData,inputs
inputs=this.inputs
formData=this.getData()
cardFirstName=inputs.cardFirstName.getValue()
cardType=function(){switch(formData.cardType){case"Unknown":case void 0:return"credit card"
default:return formData.cardType}}()
cardOwner=cardFirstName?""+cardFirstName+"'s ":""
return inputs.cardDescription.setPlaceHolder(""+cardOwner+cardType)}
PaymentMethodEntryForm.prototype.handleCardKeyup=function(){return this.updateCardTypeDisplay()}
PaymentMethodEntryForm.prototype.setPaymentInfo=function(paymentMethod){var key,value,_ref,_ref1,_ref2,_results
this.paymentMethodId=paymentMethod.paymentMethodId
_ref=paymentMethod.billing
_results=[]
for(key in _ref)if(__hasProp.call(_ref,key)){value=_ref[key]
switch(key){case"state":_results.push(this.addCustomData("actualState",value))
break
case"cardType":_results.push(this.updateCardTypeDisplay(value))
break
case"cardNumber":case"cardCV":_results.push(null!=(_ref1=this.inputs[key])?_ref1.setPlaceHolder(value):void 0)
break
case"address2":break
default:_results.push(null!=(_ref2=this.inputs[key])?_ref2.setValue(value):void 0)}}return _results}
PaymentMethodEntryForm.prototype.clearValidation=function(){var input,inputs,_i,_len,_results
inputs=KDFormView.findChildInputs(this)
_results=[]
for(_i=0,_len=inputs.length;_len>_i;_i++){input=inputs[_i]
_results.push(input.clearValidationFeedback())}return _results}
return PaymentMethodEntryForm}(KDFormViewWithFields)

var PaymentChoiceForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentChoiceForm=function(_super){function PaymentChoiceForm(options,data){var _base,_base1,_base2,_base3,_this=this
null==options&&(options={})
options.callback=function(formData){return _this.emit("PaymentMethodChosen",formData.paymentMethod)}
null==options.fields&&(options.fields={})
null==(_base=options.fields).intro&&(_base.intro={itemClass:KDCustomHTMLView,partial:"<p>Please choose a payment method:</p>"})
null==(_base1=options.fields).paymentMethod&&(_base1.paymentMethod={itemClass:KDCustomHTMLView,title:"Payment method"})
null==options.buttons&&(options.buttons={})
null==(_base2=options.buttons).submit&&(_base2.submit={title:"Use <b>this</b> payment method",style:"modal-clean-gray",type:"submit",loader:{color:"#ffffff",diameter:12}})
null==(_base3=options.buttons).another&&(_base3.another={title:"Use <b>another</b> payment method",style:"modal-clean-gray",callback:function(){return _this.emit("PaymentMethodNotChosen")}})
PaymentChoiceForm.__super__.constructor.call(this,options,data)}__extends(PaymentChoiceForm,_super)
PaymentChoiceForm.prototype.activate=function(activator){return this.emit("Activated",activator)}
PaymentChoiceForm.prototype.setPaymentMethods=function(paymentMethods){var appStorage,defaultMethod,defaultPaymentMethod,methods,methodsByPaymentMethodId,paymentField,preferredPaymentMethod,select,_this=this
preferredPaymentMethod=paymentMethods.preferredPaymentMethod,methods=paymentMethods.methods,appStorage=paymentMethods.appStorage
paymentField=this.fields["Payment method"]
switch(methods.length){case 0:break
case 1:!function(_arg){var method
method=_arg[0]
paymentField.addSubView(new PaymentMethodView({},method))
return _this.addCustomData("paymentMethod",method)}(methods)
break
default:methodsByPaymentMethodId=methods.reduce(function(acc,method){acc[method.paymentMethodId]=method
return acc},{})
defaultPaymentMethod=null!=preferredPaymentMethod?preferredPaymentMethod:methods[0].paymentMethodId
defaultMethod=methodsByPaymentMethodId[defaultPaymentMethod]
this.addCustomData("paymentMethod",defaultMethod)
select=new KDSelectBox({defaultValue:defaultPaymentMethod,name:"paymentMethodId",selectOptions:methods.map(function(method){return{title:KD.utils.getPaymentMethodTitle(method),value:method.paymentMethodId}}),callback:function(paymentMethodId){var chosenMethod
chosenMethod=methodsByPaymentMethodId[paymentMethodId]
return _this.addCustomData("paymentMethod",chosenMethod)}})
paymentField.addSubView(select)}return this}
return PaymentChoiceForm}(KDFormViewWithFields)

var PaymentFormModal,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentFormModal=function(_super){function PaymentFormModal(options,data){null==options&&(options={})
null==data&&(data={})
options.title||(options.title="Billing information")
options.width||(options.width=779)
options.height||(options.height="auto")
options.cssClass||(options.cssClass="payments-modal")
null==options.overlay&&(options.overlay=!0)
PaymentFormModal.__super__.constructor.call(this,options,data)}__extends(PaymentFormModal,_super)
PaymentFormModal.prototype.viewAppended=function(){var _this=this
this.mainLoader=new KDLoaderView({showLoader:!0,size:{width:14}})
this.addSubView(this.mainLoader)
this.useExistingView=new PaymentChoiceForm
this.useExistingView.hide()
this.addSubView(this.useExistingView)
this.useExistingView.on("PaymentMethodNotChosen",function(){_this.useExistingView.hide()
return _this.paymentForm.show()})
this.forwardEvent(this.useExistingView,"PaymentMethodChosen")
this.paymentForm=new PaymentMethodEntryForm
this.paymentForm.hide()
this.addSubView(this.paymentForm)
this.forwardEvent(this.paymentForm,"PaymentInfoSubmitted")
return PaymentFormModal.__super__.viewAppended.call(this)}
PaymentFormModal.prototype.setState=function(state,data){this.mainLoader.hide()
switch(state){case"editExisting":this.paymentForm.setPaymentInfo(data)
return this.paymentForm.show()
case"selectPersonal":this.useExistingView.setPaymentMethods(data)
return this.useExistingView.show()
default:return this.paymentForm.show()}}
PaymentFormModal.prototype.setPaymentInfo=function(paymentMethod){return this.paymentForm.setPaymentInfo(paymentMethod)}
PaymentFormModal.prototype.handleRecurlyResponse=function(callback,err){var e,input,recurlyFieldMap,_i,_len,_ref,_results
this.paymentForm.buttons.Save.hideLoader()
recurlyFieldMap={first_name:"cardFirstName",last_name:"cardLastName",number:"cardNumber",verification_value:"cardCV"}
_results=[]
for(_i=0,_len=err.length;_len>_i;_i++){e=err[_i]
if(recurlyFieldMap[e.field]){input=this.paymentForm.inputs[recurlyFieldMap[e.field]]
input.giveValidationFeedback(!0)
_results.push(input.showValidationError(""+(null!=(_ref=input.inputLabel)?_ref.getTitle():void 0)+" "+e.message))}else{input=this.paymentForm.inputs.cardNumber
input.showValidationError(e.message)
e.message.indexOf("card")>-1?_results.push(input.giveValidationFeedback(!0)):_results.push(void 0)}}return _results}
PaymentFormModal.prototype.updateCardTypeDisplay=function(cardType){return this.paymentForm.updateCardTypeDisplay(cardType)}
return PaymentFormModal}(KDModalView)

var VmProductView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
VmProductView=function(_super){function VmProductView(options,data){null==options&&(options={})
VmProductView.__super__.constructor.call(this,options,data)}__extends(VmProductView,_super)
VmProductView.prototype.pistachio=function(){return'<h3>{{#(title)}}</h3>\n<div>\n  {span{this.utils.formatMoney(#(feeAmount) / 100)}}\n  <span class="per-month">/ mo</span>\n</div>'}
return VmProductView}(JView)

var PaymentWorkflow,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentWorkflow=function(_super){function PaymentWorkflow(options,data){null==options&&(options={})
if(!options.confirmForm)throw new Error("You must provide a confirmForm option!")
PaymentWorkflow.__super__.constructor.call(this,options,data)}__extends(PaymentWorkflow,_super)
PaymentWorkflow.prototype.preparePaymentMethods=function(){var paymentController,_this=this
paymentController=KD.getSingleton("paymentController")
return paymentController.fetchPaymentMethods(function(err,paymentMethods){return KD.showError(err)?void 0:paymentMethods.methods.length>0?_this.getForm("choice").setPaymentMethods(paymentMethods):_this.clearData("paymentMethod")})}
PaymentWorkflow.prototype.createChoiceForm=function(options,data){var form,_this=this
form=new PaymentChoiceForm(options,data)
form.once("Activated",function(){return _this.preparePaymentMethods()})
form.on("PaymentMethodChosen",function(paymentMethod){return _this.collectData({paymentMethod:paymentMethod})})
form.on("PaymentMethodNotChosen",function(){return _this.clearData("paymentMethod")})
return form}
PaymentWorkflow.prototype.createEntryForm=function(options,data){var form,payment,_this=this
form=new PaymentMethodEntryForm(options,data)
payment=KD.getSingleton("paymentController")
payment.observePaymentSave(form,function(err,paymentMethod){return KD.showError(err)?void 0:_this.collectData({paymentMethod:paymentMethod})})
return form}
PaymentWorkflow.prototype.prepareWorkflow=function(){var all,any,confirmForm,existingAccountWorkflow,productForm,_ref,_this=this
all=Junction.all,any=Junction.any
this.requireData(["productData","createAccount",any("paymentMethod","subscription"),"userConfirmation"])
if("unregistered"===KD.whoami().type){existingAccountWorkflow=new ExistingAccountWorkflow
existingAccountWorkflow.on("DataCollected",function(data){return _this.collectData({createAccount:data.createAccount})})
this.addForm("createAccount",existingAccountWorkflow,["createAccount"])}else this.addForm("existingAccount",this.skip({createAccount:!1}),["createAccount"])
_ref=this.getOptions(),productForm=_ref.productForm,confirmForm=_ref.confirmForm
if(null!=productForm){this.addForm("product",productForm,["productData","subscription"])
productForm.on("DataCollected",function(productData){var oldSubscription,subscription
_this.collectData({productData:productData})
subscription=productData.subscription,oldSubscription=productData.oldSubscription
subscription&&_this.collectData({subscription:subscription})
return oldSubscription?_this.collectData({oldSubscription:oldSubscription}):void 0})}this.addForm("choice",this.createChoiceForm(),["paymentMethod"])
this.addForm("entry",this.createEntryForm(),["paymentMethod"])
this.addForm("confirm",confirmForm,["userConfirmation"])
confirmForm.on("PaymentConfirmed",function(){return _this.collectData({userConfirmation:!0})})
this.forwardEvent(confirmForm,"Cancel")
return this}
return PaymentWorkflow}(FormWorkflow)

var PaymentConfirmForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PaymentConfirmForm=function(_super){function PaymentConfirmForm(options,data){var _this=this
null==options&&(options={})
PaymentConfirmForm.__super__.constructor.call(this,options,data)
this.buttonBar=new KDButtonBar({buttons:{Buy:{cssClass:"modal-clean-green",callback:function(){return _this.emit("PaymentConfirmed")}},cancel:{title:"cancel",cssClass:"modal-cancel",callback:function(){return _this.emit("Cancel")}}}})}__extends(PaymentConfirmForm,_super)
PaymentConfirmForm.prototype.getExplanation=function(){}
return PaymentConfirmForm}(JView)

var PlanUpgradeForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PlanUpgradeForm=function(_super){function PlanUpgradeForm(){_ref=PlanUpgradeForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(PlanUpgradeForm,_super)
PlanUpgradeForm.prototype.setPlans=function(plans){this.listController.instantiateListItems(plans)
return this}
PlanUpgradeForm.prototype.setCurrentSubscription=function(subscription,options){var code,lowerTier,view,_ref1
null==options&&(options={})
lowerTier=!0
_ref1=this.planViewsByCode
for(code in _ref1)if(__hasProp.call(_ref1,code)){view=_ref1[code]
if(code===subscription.planCode){"function"==typeof view.activate&&view.activate()
"function"==typeof view.disable&&view.disable()
lowerTier=!1}else options.forceUpgrade&&lowerTier&&"function"==typeof view.disable&&view.disable()}this.emit("CurrentSubscriptionSet",subscription)
return this}
PlanUpgradeForm.prototype.viewAppended=function(){var _this=this
this.listController=new KDListViewController({itemClass:GroupPlanListItem})
this.listView=this.listController.getListView()
this.planViewsByCode={}
this.listView.on("ItemWasAdded",function(item){var plan
plan=item.getData()
_this.planViewsByCode[plan.planCode]=item
return item.setControls(new KDButtonView({title:"Upgrade",callback:function(){return _this.emit("PlanSelected",plan)}}))})
return PlanUpgradeForm.__super__.viewAppended.call(this)}
PlanUpgradeForm.prototype.pistachio=function(){return"<h2>\n  Upgrade your plan:\n</h2>\n{{> this.listView}}"}
return PlanUpgradeForm}(JView)

var PlanUpgradeConfirmForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PlanUpgradeConfirmForm=function(_super){function PlanUpgradeConfirmForm(){_ref=PlanUpgradeConfirmForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(PlanUpgradeConfirmForm,_super)
PlanUpgradeConfirmForm.prototype.viewAppended=function(){var data
this.unsetClass("kdview")
data=this.getData()
this.plan=new KDView({cssClass:"payment-confirm-plan",partial:"<h3>Plan</h3>\n<p>\n  "+this.getExplanation("plan")+"\n</p>"})
this.payment=new KDView({cssClass:"payment-confirm-method",partial:"<h3>Payment method</h3>\n<p>"+this.getExplanation("payment")+"</p>"})
return PlanUpgradeConfirmForm.__super__.viewAppended.call(this)}
PlanUpgradeConfirmForm.prototype.getExplanation=function(key){switch(key){case"plan":return"You selected this plan:"
case"payment":return"This payment method will be charged:"
default:return PlanUpgradeConfirmForm.__super__.getExplanation.call(this,key)}}
PlanUpgradeConfirmForm.prototype.activate=function(activator){return this.setData(activator.getData())}
PlanUpgradeConfirmForm.prototype.setData=function(data){var _ref1
if(null!=(_ref1=data.productData)?_ref1.plan:void 0){this.plan.addSubView(new VmPlanView({},data.productData.plan))
if(null!=data.oldSubscription){this.plan.addSubView(new KDView({partial:"<p>Your old plan was:</p>"}))
this.plan.addSubView(new VmPlanView({},data.oldSubscription))}}else this.plan.hide()
data.paymentMethod?this.payment.addSubView(new PaymentMethodView({},data.paymentMethod)):this.payment.hide()
return PlanUpgradeConfirmForm.__super__.setData.call(this,data)}
PlanUpgradeConfirmForm.prototype.pistachio=function(){return"{{> this.plan}}\n{{> this.payment}}\n{{> this.buttonBar}}"}
return PlanUpgradeConfirmForm}(PaymentConfirmForm)

var PackChoiceForm,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
PackChoiceForm=function(_super){function PackChoiceForm(){_ref=PackChoiceForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(PackChoiceForm,_super)
PackChoiceForm.prototype.viewAppended=function(){var itemClass,title,_ref1,_this=this
_ref1=this.getOptions(),title=_ref1.title,itemClass=_ref1.itemClass
this.titleView=new KDView({tagName:"h2",partial:title})
this.listController=new KDListViewController({itemClass:itemClass})
this.list=this.listController.getListView()
this.list.on("ItemWasAdded",function(item){return item.on("PackSelected",function(){return _this.emit("PackSelected",item.getData())})})
return PackChoiceForm.__super__.viewAppended.call(this)}
PackChoiceForm.prototype.activate=function(activator){return this.emit("Activated",activator)}
PackChoiceForm.prototype.setContents=function(contents){return this.listController.instantiateListItems(contents)}
PackChoiceForm.prototype.pistachio=function(){return"{{> this.titleView}}\n{{> this.list}}"}
return PackChoiceForm}(JView)

var ExistingAccountForm,ExistingAccountWorkflow,_ref,_ref1,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ExistingAccountForm=function(_super){function ExistingAccountForm(){_ref=ExistingAccountForm.__super__.constructor.apply(this,arguments)
return _ref}__extends(ExistingAccountForm,_super)
ExistingAccountForm.prototype.viewAppended=function(){var _this=this
this.exitingAccountButton=new KDButtonView({title:"I have an account",callback:function(){return _this.emit("DataCollected",{createAccount:!1,email:!1})}})
this.createAccountButton=new KDButtonView({title:"I'll create an account",callback:function(){return _this.emit("DataCollected",{createAccount:!0,account:!0})}})
return ExistingAccountForm.__super__.viewAppended.call(this)}
ExistingAccountForm.prototype.pistachio=function(){return"Are you an existing user?\n{{> this.exitingAccountButton}}\n{{> this.createAccountButton}}"}
return ExistingAccountForm}(JView)
ExistingAccountWorkflow=function(_super){function ExistingAccountWorkflow(){_ref1=ExistingAccountWorkflow.__super__.constructor.apply(this,arguments)
return _ref1}__extends(ExistingAccountWorkflow,_super)
ExistingAccountWorkflow.prototype.prepareWorkflow=function(){var all,any,emailCollectionForm,existingAccountForm,loginForm,_this=this
all=Junction.all,any=Junction.any
this.requireData(all("createAccount","email","loggedIn"))
existingAccountForm=new ExistingAccountForm
existingAccountForm.on("DataCollected",function(data){return _this.collectData(data)})
this.addForm("existingAccount",existingAccountForm,["createAccount"])
emailCollectionForm=new KDFormViewWithFields({fields:{email:{cssClass:"thin",placeholder:"you@yourdomain.com",name:"email",testPath:"account-email-input"}},buttons:{Save:{type:"submit",style:"solid green fr"}},callback:function(_arg){var JUser,email
email=_arg.email
JUser=KD.remote.api.JUser
return JUser.changeEmail({email:email},function(err){return KD.showError(err)?void 0:_this.collectData({email:email,loggedIn:!1})})}})
emailCollectionForm.activate=function(){return this.inputs.email.setFocus()}
this.addForm("email",emailCollectionForm,["email"])
loginForm=new LoginInlineForm({cssClass:"login-form",testPath:"login-form",callback:function(credentials){return KD.getSingleton("mainController").handleLogin(credentials,function(err){loginForm.button.hideLoader()
return KD.showError(err)&&(null!=err?err.field:void 0)in loginForm?loginForm[err.field].decorateValidation(err):_this.collectData({loggedIn:!0})})}})
this.addForm("login",loginForm,["loggedIn"])
return this.enter()}
return ExistingAccountWorkflow}(FormWorkflow)

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
return KD.remote.api.JNewStatusUpdate.create({body:status},function(err,reply){_this.utils.wait(2e3,function(){return _this.getDelegate().$().css({left:-700})})
if(err)return new KDNotificationView({type:"mini",title:"There was an error, try again later!"})
_this.constructor.updateSent=!0
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
if(rightPane){if(rightPane.mainView)return this.appManager.showInstance(this.appManager.getByView(rightPane.mainView))}else{if(!leftPane)return this.router.handleRoute(this.router.currentPath)
if(leftPane.mainView)return this.appManager.showInstance(this.appManager.getByView(leftPane.mainView))}}
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
this.avatar=new AvatarView({tagName:"div",cssClass:"avatar-image-wrapper",attributes:{title:"View your public profile"},size:{width:25,height:25}},account)
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
AvatarArea.prototype.pistachio=function(){return"{{> this.avatar}}\n<section>\n  <h2>{{> this.profileLink}}</h2>\n  <h3>@{{#(profile.nickname)}}</h3>\n  {{> this.groupsSwitcherIcon}}\n</section>"}
return AvatarArea}(KDCustomHTMLView)

var AvatarPopup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarPopup=function(_super){function AvatarPopup(){var mainController
AvatarPopup.__super__.constructor.apply(this,arguments)
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
AvatarPopupGroupSwitcher.prototype.viewAppended=function(){var dashboard,groupsController,_this=this
AvatarPopupGroupSwitcher.__super__.viewAppended.apply(this,arguments)
this.pending=0
this.notPopulated=!0
this.notPopulatedPending=!0
this._popupList=new PopupList({itemClass:PopupGroupListItem})
this._popupListPending=new PopupList({itemClass:PopupGroupListItemPending})
this._popupListPending.on("PendingCountDecreased",this.bound("decreasePendingCount"))
this._popupListPending.on("UpdateGroupList",this.bound("populateGroups"))
this.listControllerPending=new KDListViewController({lazyLoaderOptions:{partial:"",spinnerOptions:{loaderOptions:{color:"#6BB197"},size:{width:32}}},view:this._popupListPending})
this.listController=new KDListViewController({lazyLoaderOptions:{partial:"",spinnerOptions:{loaderOptions:{color:"#6BB197"},size:{width:32}}},view:this._popupList})
this.listController.on("AvatarPopupShouldBeHidden",this.bound("hide"))
this.avatarPopupContent.addSubView(this.invitesHeader=new KDView({height:"auto",cssClass:"sublink top hidden",partial:"You have pending group invitations:"}))
this.avatarPopupContent.addSubView(this.listControllerPending.getView())
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"span",cssClass:"icon help",tooltip:{title:"Here you'll find the groups that you are a member of, clicking one of them will take you to a new browser tab."}}))
this.avatarPopupContent.addSubView(this.listController.getView())
groupsController=KD.getSingleton("groupsController")
groupsController.once("GroupChanged",function(){var group
group=groupsController.getCurrentGroup()
return"koding"!==(null!=group?group.slug:void 0)?backToKodingView.updatePartial("<a class='right' target='_blank' href='/Activity'>Back to Koding</a>"):void 0})
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"/Account"},cssClass:"bottom separator",partial:"Account settings",click:function(event){KD.utils.stopDOMEvent(event)
KD.getSingleton("router").handleRoute("/Account")
return _this.hide()}}))
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"/Environments"},cssClass:"bottom",partial:"Environments",click:function(event){KD.utils.stopDOMEvent(event)
KD.getSingleton("router").handleRoute("/Environments")
return _this.hide()}}))
this.avatarPopupContent.addSubView(dashboard=new KDCustomHTMLView({tagName:"a",attributes:{href:"/Dashboard"},cssClass:"bottom hidden",partial:"Dashboard"}))
KD.utils.wait(2e3,function(){var group
group=KD.getSingleton("groupsController").getCurrentGroup()
return null!=group?group.canEditGroup(function(err,success){if(success){dashboard.show()
return dashboard.on("click",function(event){KD.utils.stopDOMEvent(event)
KD.getSingleton("router").handleRoute("/Dashboard")
return _this.hide()})}}):void 0})
this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"#"},cssClass:"bottom",partial:"Go back to old Koding",click:function(event){var modal
KD.utils.stopDOMEvent(event)
modal=new KDModalView({title:"Go back to old Koding",cssClass:"go-back-survey",content:'Please take a short survey about <a href="http://bit.ly/1jsjlna">New Koding.</a><br><br>',buttons:{Switch:{cssClass:"modal-clean-gray",callback:function(){KD.mixpanel("Switched to old Koding")
KD.utils.goBackToOldKoding()
return modal.destroy()}},Cancel:{cssClass:"modal-cancel",callback:function(){return modal.destroy()}}}})
return _this.hide()}}))
return this.avatarPopupContent.addSubView(new KDCustomHTMLView({tagName:"a",attributes:{href:"/Logout"},cssClass:"bottom",partial:"Logout",click:function(event){KD.utils.stopDOMEvent(event)
KD.getSingleton("router").handleRoute("/Logout")
return _this.hide()}}))}
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
return KD.isLoggedIn()?KD.whoami().fetchGroups(null,function(err,groups){var stack
if(err)return warn(err)
if(null!=groups){stack=[]
groups.forEach(function(group){return stack.push(function(cb){return group.group.fetchMyRoles(function(err,roles){group.admin=err?!1:__indexOf.call(roles,"admin")>=0
return cb(err,group)})})})
return async.parallel(stack,function(err,results){var index
if(!err){results.sort(function(a,b){return a.admin===b.admin?a.group.slug>b.group.slug:!a.admin&&b.admin})
index=null
results.forEach(function(item,i){return"koding"===item.group.slug?index=i:void 0})
null!=index&&results.splice(index,1)
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
AvatarAreaIconLink.prototype.click=function(event){var delegate,windowController,_this=this
windowController=KD.singleton("windowController")
KD.utils.stopDOMEvent(event)
delegate=this.getDelegate()
if(delegate.hasClass("active")){this.delegate.hide()
return windowController.removeLayer(this.delegate)}this.delegate.show()
windowController.addLayer(this.delegate)
return this.delegate.once("ReceivedClickElsewhere",function(){return _this.delegate.hide()})}
return AvatarAreaIconLink}(KDCustomHTMLView)

var AvatarAreaIconMenu,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AvatarAreaIconMenu=function(_super){function AvatarAreaIconMenu(){AvatarAreaIconMenu.__super__.constructor.apply(this,arguments)
this.setClass("account-menu")
this.notificationsPopup=new AvatarPopupNotifications({cssClass:"notifications"})
this.notificationsIcon=new AvatarAreaIconLink({cssClass:"notifications acc-dropdown-icon",attributes:{title:"Notifications"},delegate:this.notificationsPopup})}__extends(AvatarAreaIconMenu,_super)
AvatarAreaIconMenu.prototype.pistachio=function(){return"{{> this.notificationsIcon}}"}
AvatarAreaIconMenu.prototype.viewAppended=function(){var mainView
AvatarAreaIconMenu.__super__.viewAppended.apply(this,arguments)
mainView=KD.getSingleton("mainView")
mainView.addSubView(this.notificationsPopup)
return this.attachListeners()}
AvatarAreaIconMenu.prototype.attachListeners=function(){var _this=this
KD.getSingleton("notificationController").on("NotificationHasArrived",function(_arg){var event
event=_arg.event
return _this.notificationsPopup.listController.fetchNotificationTeasers(function(notifications){_this.notificationsPopup.noNotification.hide()
_this.notificationsPopup.listController.removeAllItems()
return _this.notificationsPopup.listController.instantiateListItems(notifications)})})
return this.notificationsPopup.listController.on("NotificationCountDidChange",function(count){_this.utils.killWait(_this.notificationsPopup.loaderTimeout)
count>0?_this.notificationsPopup.noNotification.hide():_this.notificationsPopup.noNotification.show()
return _this.notificationsIcon.updateCount(count)})}
AvatarAreaIconMenu.prototype.accountChanged=function(){var notificationsPopup
notificationsPopup=this.notificationsPopup
notificationsPopup.listController.removeAllItems()
return KD.isLoggedIn()?notificationsPopup.listController.fetchNotificationTeasers(function(teasers){return notificationsPopup.listController.instantiateListItems(teasers)}):void 0}
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
AvatarPopupNotifications.prototype.viewAppended=function(){AvatarPopupNotifications.__super__.viewAppended.apply(this,arguments)
this._popupList=new PopupList({itemClass:PopupNotificationListItem})
this.listController=new MessagesListController({view:this._popupList,maxItems:5})
this.listController.on("AvatarPopupShouldBeHidden",this.bound("hide"))
this.avatarPopupContent.addSubView(this.noNotification=new KDView({height:"auto",cssClass:"sublink top hidden",partial:"You have no new notifications."}))
return this.avatarPopupContent.addSubView(this.listController.getView())}
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
PopupNotificationListItem.prototype.pistachio=function(){return"{{> this.avatar}}\n<p>{{> this.participants}} {{this.getActionPhrase(#(dummy))}} {{this.getActivityPlot(#(dummy))}} {{> this.interactedGroups}}</p>\n<time>{{$.timeago(this.getLatestTimeStamp(#(dummy)))}}</time>"}
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
return KD.remote.api.JNewStatusUpdate.create({body:status},function(err){if(err){new KDNotificationView({type:"mini",title:"There was an error, try again later!"})
_this.loader.hide()
return _this.hide()}new KDNotificationView({type:"growl",cssClass:"mini",title:"Message posted!",duration:2e3})
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
if(!customView)return
if(customView instanceof KDView)item.view=customView
else{childItems=JContextMenuTreeViewController.convertToArray(customView,item.parentId)
menuWithoutChilds=_.filter(menu.items,function(menuItem){return menuItem.parentId!==item.parentId})
menu.items=menuWithoutChilds.concat(childItems)}}return item})
return menuItems.length>0?_this.createMenu(event,menuItems):void 0}}
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
MainView.prototype.addBook=function(){}
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
this.header.addSubView(this.innerContainer=new KDCustomHTMLView({cssClass:"inner-container"}))
return this.innerContainer.addSubView(this.logo=new KDCustomHTMLView({tagName:"a",domId:"koding-logo",cssClass:"group"===(null!=entryPoint?entryPoint.type:void 0)?"group":"",partial:"<cite></cite>",click:function(event){KD.utils.stopDOMEvent(event)
return KD.isLoggedIn()?KD.getSingleton("router").handleRoute("/Activity",{entryPoint:entryPoint}):location.replace("/")}}))}
MainView.prototype.createDock=function(){return this.innerContainer.addSubView(KD.singleton("dock").getView())}
MainView.prototype.createAccountArea=function(){var mc,_this=this
this.innerContainer.addSubView(this.accountArea=new KDCustomHTMLView({cssClass:"account-area"}))
if(KD.isLoggedIn())return this.createLoggedInAccountArea()
this.loginLink=new CustomLinkView({domId:"header-sign-in",title:"Login",attributes:{href:"/Login"},click:function(event){KD.utils.stopDOMEvent(event)
return KD.getSingleton("router").handleRoute("/Login")}})
this.accountArea.addSubView(this.loginLink)
mc=KD.getSingleton("mainController")
mc.on("accountChanged.to.loggedIn",function(){_this.loginLink.destroy()
return _this.createLoggedInAccountArea()})}
MainView.prototype.createLoggedInAccountArea=function(){var _this=this
this.accountArea.addSubView(this.accountMenu=new AvatarAreaIconMenu)
this.accountMenu.accountChanged(KD.whoami())
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
MainViewController=function(_super){function MainViewController(){var appManager,body,display,killRepeat,mainController,mainView,repeat,windowController,_ref,_this=this
MainViewController.__super__.constructor.apply(this,arguments)
_ref=KD.utils,repeat=_ref.repeat,killRepeat=_ref.killRepeat
body=document.body
mainView=this.getView()
mainController=KD.singleton("mainController")
appManager=KD.singleton("appManager")
windowController=KD.singleton("windowController")
display=KD.singleton("display")
this.registerSingleton("mainViewController",this,!0)
this.registerSingleton("mainView",mainView,!0)
warn("FIXME Add tell to Login app ~ GG @ kodingrouter (if needed)")
appManager.on("AppIsBeingShown",function(controller){return _this.setBodyClass(KD.utils.slugify(controller.getOption("name")))})
display.on("ContentDisplayWantsToBeShown",function(){var type
type=null
return function(view){return(type=view.getOption("type"))?_this.setBodyClass(type):void 0}}())
mainController.on("ToggleChatPanel",function(){return mainView.chatPanel.toggle()})
KD.checkFlag("super-admin")?KDView.setElementClass(body,"add","super"):KDView.setElementClass(body,"remove","super")
windowController.on("ScrollHappened",function(){var currentHeight,lastScroll,threshold
threshold=50
lastScroll=0
currentHeight=0
return _.throttle(function(){var current,el,scrollHeight,scrollTop,_ref1
el=document.body
scrollHeight=el.scrollHeight,scrollTop=el.scrollTop
if(!(scrollHeight<=window.innerHeight||0>=scrollTop)){current=scrollTop+window.innerHeight
if(current>scrollHeight-threshold){if(lastScroll>0)return
null!=(_ref1=appManager.getFrontApp())&&_ref1.emit("LazyLoadThresholdReached")
lastScroll=current
currentHeight=scrollHeight}else lastScroll>current&&(lastScroll=0)
return scrollHeight!==currentHeight?lastScroll=0:void 0}},200)}())}__extends(MainViewController,_super)
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
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
DockController=function(_super){function DockController(options,data){var mainController,_this=this
null==options&&(options={})
options.view||(options.view=new KDCustomHTMLView({domId:"dock"}))
DockController.__super__.constructor.call(this,options,data)
this.storage=new AppStorage("Dock","1.0.1")
this.navController=new MainNavController({view:new NavigationList({domId:"main-nav",testPath:"navigation-list",type:"navigation",itemClass:NavigationLink,testPath:"navigation-list"}),wrapper:!1,scrollView:!1},{id:"navigation",title:"navigation",items:[]})
mainController=KD.getSingleton("mainController")
mainController.ready(this.bound("accountChanged"))
this.storage.fetchValue("navItems",function(usersNavItems){if(!usersNavItems){_this.setNavItems(defaultItems)
return _this.emit("ready")}_this.setNavItems(_this.buildNavItems(usersNavItems))
return _this.emit("ready")})}var defaultItems
__extends(DockController,_super)
defaultItems=[{title:"Activity",path:"/Activity",order:10,type:"persistent"},{title:"Teamwork",path:"/Teamwork",order:20,type:"persistent"},{title:"Terminal",path:"/Terminal",order:30,type:"persistent"},{title:"Editor",path:"/Ace",order:40,type:"persistent"},{title:"Apps",path:"/Apps",order:50,type:"persistent"}]
DockController.prototype.buildNavItems=function(sourceItems){var defaultItem,finalItems,sourceItem,_defaults,_i,_j,_len,_len1,_sources
finalItems=[]
_sources=KD.utils.arrayToObject(sourceItems,"title")
for(_i=0,_len=defaultItems.length;_len>_i;_i++){defaultItem=defaultItems[_i]
sourceItem=_sources[defaultItem.title]
if(sourceItem){if(sourceItem.deleted)continue
sourceItem.type=defaultItem.type
finalItems.push(sourceItem)}else finalItems.push(defaultItem)}_defaults=KD.utils.arrayToObject(defaultItems,"title")
for(_j=0,_len1=sourceItems.length;_len1>_j;_j++){sourceItem=sourceItems[_j]
defaultItem=_defaults[sourceItem.title]
defaultItem||finalItems.push(sourceItem)}return finalItems}
DockController.prototype.saveItemOrders=function(items){var data,index,item,navItems
items||(items=this.navController.itemsOrdered)
navItems=[]
for(index in items)if(__hasProp.call(items,index)){item=items[index]
data=item.data
data.order=index
navItems.push(data)}return this.storage.setValue("navItems",navItems,function(err){return err?warn("Failed to save navItems order",err):void 0})}
DockController.prototype.resetItemSettings=function(){var index,item,_this=this
for(index in defaultItems)if(__hasProp.call(defaultItems,index)){item=defaultItems[index]
item.order=index}return this.storage.unsetKey("navItems",function(err){err&&warn("Failed to reset navItems",err)
KD.resetNavItems(defaultItems)
_this.navController.reset()
return"Navigation items has been reset."})}
DockController.prototype.setNavItems=function(items){KD.setNavItems(items)
return this.navController.reset()}
DockController.prototype.addItem=function(item){if(KD.registerNavItem(item)){this.navController.addItem(item)
return this.saveItemOrders()}}
DockController.prototype.removeItem=function(item){var index
return(index=KD.getNavItems().indexOf(item>-1))?KD.getNavItems().splice(index,1):void 0}
DockController.prototype.accountChanged=function(){return this.navController.reset()}
DockController.prototype.setNavItemState=function(_arg,state){var hasNav,name,nav,options,route,_i,_len,_ref,_ref1
name=_arg.name,route=_arg.route,options=_arg.options
options||(options={})
route||(route=(null!=(_ref=options.navItem)?_ref.path:void 0)||"-")
_ref1=this.navController.itemsOrdered
for(_i=0,_len=_ref1.length;_len>_i;_i++){nav=_ref1[_i]
if(RegExp("^"+route).test(nav.data.path)||nav.data.path==="/"+name||"/"+name===nav.data.path){nav.setState(state)
hasNav=!0}}if(!hasNav&&__indexOf.call(Object.keys(KD.config.apps),name)<0){this.addItem({title:name,path:"/"+name,order:60+KD.utils.uniqueId(),type:""})
return this.setNavItemState({name:name},"running")}}
DockController.prototype.loadView=function(dock){var _this=this
return this.ready(function(){var appManager,kodingAppsController,_ref
dock.addSubView(_this.navController.getView())
_ref=KD.singletons,appManager=_ref.appManager,kodingAppsController=_ref.kodingAppsController
kodingAppsController.on("LoadingAppScript",function(name){return _this.setNavItemState({name:name},"loading")})
appManager.on("AppRegistered",function(name,options){return _this.setNavItemState({name:name,options:options},"running")})
return appManager.on("AppUnregistered",function(name,options){return _this.setNavItemState({name:name,options:options},"initial")})})}
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
this.forwardEvent(this.groupChannel,"LikeIsAdded")
this.forwardEvent(this.groupChannel,"PostIsCreated")
this.forwardEvent(this.groupChannel,"ReplyIsAdded")
this.forwardEvent(this.groupChannel,"PostIsDeleted")
return this.groupChannel.once("setSecretNames",callback)}
GroupsController.prototype.changeGroup=function(groupName,callback){var oldGroupName,_this=this
null==groupName&&(groupName="koding")
null==callback&&(callback=function(){})
if(this.currentGroupName===groupName)return callback()
oldGroupName=this.currentGroupName
this.currentGroupName=groupName
return KD.remote.cacheable(groupName,function(err,models){var group
if(err)return callback(err)
if(null!=models){group=models[0]
if("JGroup"!==group.bongo_.constructorName)return _this.isReady=!0
_this.setGroup(groupName)
_this.currentGroupData.setGroup(group)
_this.isReady=!0
callback(null,groupName,group)
_this.emit("GroupChanged",groupName,group)
return _this.openGroupChannel(group,function(){return _this.emit("GroupChannelReady")})}})}
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
GroupsController.prototype.cancelGroupRequest=function(group,callback){return KD.whoami().cancelRequest(group.slug,callback)}
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
KD.registerSingleton("paymentController",new PaymentController)
KD.registerSingleton("locationController",new LocationController)
KD.registerSingleton("badgeController",new BadgeController)
return this.ready(function(){router.listen()
KD.registerSingleton("activityController",new ActivityController)
KD.registerSingleton("appStorageController",new AppStorageController)
KD.registerSingleton("kodingAppsController",new KodingAppsController)
_this.emit("AppIsReady")
return console.timeEnd("Koding.com loaded")})}
MainController.prototype.accountChanged=function(account,firstLoad){var _this=this
null==firstLoad&&(firstLoad=!1)
this.userAccount=account
connectedState.connected=!0
this.on("pageLoaded.as.loggedIn",function(account){return account?KD.utils.setPreferredDomain(account):void 0})
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
MainController.prototype.attachListeners=function(){var wc
wc=KD.singleton("windowController")
return this.utils.wait(15e3,function(){var _ref
return null!=(_ref=KD.remote.api)?_ref.JSystemStatus.on("forceReload",function(){window.removeEventListener("beforeunload",wc.bound("beforeUnload"))
return location.reload()}):void 0})}
MainController.prototype.setVisitor=function(visitor){return this.visitor=visitor}
MainController.prototype.getVisitor=function(){return this.visitor}
MainController.prototype.getAccount=function(){return KD.whoami()}
MainController.prototype.swapAccount=function(options,callback){var account,replacementToken
if(!options)return{message:"Login failed!"}
account=options.account,replacementToken=options.replacementToken
replacementToken&&$.cookie("clientId",replacementToken)
this.accountChanged(account)
return this.once("AccountChanged",function(){return callback(null,options)})}
MainController.prototype.handleLogin=function(credentials,callback){var JUser,_this=this
JUser=KD.remote.api.JUser
this.isLoggingIn(!0)
credentials.username=credentials.username.toLowerCase().trim()
return JUser.login(credentials,function(err,result){return err?callback(err):_this.swapAccount(result,callback)})}
MainController.prototype.handleFinishRegistration=function(formData,callback){var JUser,_this=this
JUser=KD.remote.api.JUser
this.isLoggingIn(!0)
return JUser.finishRegistration(formData,function(err,result){return err?callback(err):_this.swapAccount(result,callback)})}
MainController.prototype.handleOauthAuth=function(formData,callback){var JUser,_this=this
JUser=KD.remote.api.JUser
this.isLoggingIn(!0)
return JUser.authenticateWithOauth(formData,function(err,result){return err?callback(err):result.isNewUser?callback(err,result):_this.swapAccount(result,callback)})}
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
wc=KD.singleton("windowController")
wc.addUnloadListener("window",function(){var app,safeToUnload,_ref
_ref=_this.appControllers
for(app in _ref)if(__hasProp.call(_ref,app)&&("Ace"===app||"Terminal"===app)){safeToUnload=!1
break}return null!=safeToUnload?safeToUnload:!0})}var manifestsFetched,notification
__extends(ApplicationManager,_super)
manifestsFetched=!1
ApplicationManager.prototype.isAppInternal=function(name){null==name&&(name="")
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
return function(name,options,callback){var appOptions,appParams,defaultCallback,_ref,_this=this
if(!name)return warn("ApplicationManager::open called without an app name!")
"function"==typeof options&&(_ref=[options,callback],callback=_ref[0],options=_ref[1])
options||(options={})
appOptions=KD.getAppOptions(name)
appParams=options.params||{}
defaultCallback=createOrShow.bind(this,appOptions,appParams,callback)
if(null==(null!=appOptions?appOptions.preCondition:void 0)||options.conditionPassed){if(null==appOptions&&null==options.avoidRecursion){if(this.isAppInternal(name))return KodingAppsController.loadInternalApp(name,function(err){return err?warn(err):KD.utils.defer(function(){return _this.open(name,options,callback)})})
options.avoidRecursion=!0
return defaultCallback()}appParams=options.params||{}
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
ApplicationManager.prototype.require=function(name,params,callback){var _ref
log("AppManager: requiring an app",name)
callback||(_ref=[params,callback],callback=_ref[0],params=_ref[1])
return this.get(name)?callback():this.create(name,params,callback)}
ApplicationManager.prototype.create=function(name,params,callback){var AppClass,appInstance,appOptions,_ref,_this=this
callback||(_ref=[params,callback],callback=_ref[0],params=_ref[1])
AppClass=KD.getAppClass(name)
appOptions=$.extend({},!0,KD.getAppOptions(name))
appOptions.params=params
AppClass&&this.register(appInstance=new AppClass(appOptions))
return this.isAppInternal(name)?KodingAppsController.loadInternalApp(name,function(err){return err?warn(err):KD.utils.defer(function(){return _this.create(name,params,callback)})}):this.utils.defer(function(){if(!appInstance)return _this.emit("AppCouldntBeCreated")
_this.emit("AppCreated",appInstance)
return appOptions.thirdParty?KD.getSingleton("kodingAppsController").putAppResources(appInstance,callback):"function"==typeof callback?callback(appInstance):void 0})}
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
this.setListeners(appInstance)
return this.emit("AppRegistered",name,appInstance.options)}
ApplicationManager.prototype.unregister=function(appInstance){var index,name
name=appInstance.getOption("name")
index=this.appControllers[name].instances.indexOf(appInstance)
if(index>=0){this.appControllers[name].instances.splice(index,1)
this.emit("AppUnregistered",name,appInstance.options)
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
ApplicationManager.prototype.handleAppNotFound=function(){return new KDNotificationView({title:"You don't have this app installed!",type:"mini",cssClass:"error",duration:5e3})}
return ApplicationManager}(KDObject)

var AppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
AppController=function(_super){function AppController(){var name,version,_ref
AppController.__super__.constructor.apply(this,arguments)
_ref=this.getOptions(),name=_ref.name,version=_ref.version
this.appStorage=KD.singletons.appStorageController.storage(name,version||"1.0")}__extends(AppController,_super)
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
KodingAppsController=function(_super){function KodingAppsController(){var appStorage,_this=this
KodingAppsController.__super__.constructor.apply(this,arguments)
appStorage=KD.getSingleton("appStorageController")
this.storage=appStorage.storage("Applications",version)
this.storage.fetchStorage(function(){_this.apps=_this.storage.getValue("installed")||{}
_this.apps||(_this.apps={})
return _this.emit("ready")})}var name,version
__extends(KodingAppsController,_super)
name="KodingAppsController"
version="0.1"
KD.registerAppClass(KodingAppsController,{name:name,version:version,background:!0})
KodingAppsController.loadInternalApp=function(name,callback){var app,message,_ref
if(!KD.config.apps[name]){warn(message=""+name+" is not available to run!")
return callback({message:message})}if(_ref=name.capitalize(),__indexOf.call(Object.keys(KD.appClasses),_ref)>=0){warn(""+name+" is already imported")
return callback(null)}KD.singletons.dock.setNavItemState({name:name,route:"/"+name},"loading")
app=KD.config.apps[name]
return this.putAppScript(app,callback)}
KodingAppsController.putAppScript=function(app,callback){var script,style
null==callback&&(callback=noop)
log("PUT APP",app)
if(0===$("head .internal-style-"+app.identifier).length&&app.style){style=new KDCustomHTMLView({tagName:"link",cssClass:"internal-style-"+app.identifier,bind:"load",load:function(){return log("Style loaded? for "+name+" # don't trust this ...")},attributes:{rel:"stylesheet",href:""+app.style+"?"+KD.utils.uniqueId()}})
$("head")[0].appendChild(style.getElement())}if(0===$("head .internal-script-"+app.identifier).length&&app.script){script=new KDCustomHTMLView({tagName:"script",cssClass:"internal-script-"+app.identifier,bind:"load",load:function(){return callback(null)},attributes:{type:"text/javascript",src:""+app.script+"?"+KD.utils.uniqueId()}})
return $("head")[0].appendChild(script.getElement())}}
KodingAppsController.unloadAppScript=function(app,callback){null==callback&&(callback=noop)
$("head .internal-style-"+app.identifier).remove()
return $("head .internal-script-"+app.identifier).remove()}
KodingAppsController.runApprovedApp=function(jApp,options,callback){var app,script,style,_ref
null==options&&(options={})
null==callback&&(callback=noop)
if(!jApp)return warn("JNewApp not found!")
_ref=jApp.urls,script=_ref.script,style=_ref.style
if(!script)return warn("Script not found! on "+jApp)
app={name:jApp.name,script:script,style:style,identifier:jApp.identifier}
return this.putAppScript(app,function(){return KD.utils.defer(function(){options.dontUseRouter?KD.singletons.appManager.open(jApp.name):KD.singletons.router.handleRoute("/"+jApp.name)
return callback()})})}
KodingAppsController.runExternalApp=function(jApp,callback){var modal,_this=this
null==callback&&(callback=noop)
return jApp.approved?this.runApprovedApp(jApp):modal=new KDModalView({title:"Run "+jApp.manifest.name,content:"This is <strong>DANGEROUS!!!</strong>\nIf you don't know this user, its recommended to not run this app!\nDo you still want to continue?",height:"auto",overlay:!0,buttons:{Run:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return _this.runApprovedApp(jApp,{},function(){return modal.destroy()})}},cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}}})}
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
this.kiteInstances={}
this.helper=new KiteHelper}var getKiteKey,notify,_attempt,_notifications,_tempCallback,_tempOptions
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
NewKite=function(_super){function NewKite(kite,authentication,options){var _this=this
null==options&&(options={})
NewKite.__super__.constructor.call(this,options)
this.kite=kite
this.authentication=authentication
this.readyState=NOTREADY
this.autoReconnect=!0
this.autoReconnect&&this.initBackoff(options)
this.handlers={log:function(options){log.apply(null,options.withArgs)
return options.responseCallback({withArgs:[{error:null,result:null}]})},alert:function(options){alert.apply(null,options.withArgs)
return options.responseCallback({withArgs:[{error:null,result:null}]})}}
this.proto=new Bongo.dnodeProtocol.Session(null,this.handlers)
this.proto.on("request",function(req){log("proto request",{req:req})
return _this.ready(function(){return _this.ws.send(JSON.stringify(req))})})
this.proto.on("fail",function(err){return log("proto fail",{err:err})})
this.proto.on("error",function(err){return log("proto error",{err:err})})
this.proto.on("remoteError",function(err){return log("proto remoteEerror",{err:err})})}var CLOSED,NOTREADY,READY,apply,setAt,_ref
__extends(NewKite,_super)
setAt=Bongo.JsPath.setAt
_ref=[0,1,3],NOTREADY=_ref[0],READY=_ref[1],CLOSED=_ref[2]
NewKite.prototype.connect=function(){var addr
addr=this.kite.publicIP+":"+this.kite.port
log("Trying to connect to "+addr)
this.ws=new WebSocket("ws://"+addr+"/dnode")
this.ws.onopen=this.bound("onOpen")
this.ws.onclose=this.bound("onClose")
this.ws.onmessage=this.bound("onMessage")
return this.ws.onerror=this.bound("onError")}
NewKite.prototype.disconnect=function(reconnect){null==reconnect&&(reconnect=!0)
null!=reconnect&&(this.autoReconnect=!!reconnect)
return this.ws.close()}
NewKite.prototype.tell=function(method,args,cb){var options,scrubber,_ref1,_this=this
cb||(_ref1=[[],args],args=_ref1[0],cb=_ref1[1])
Array.isArray(args)||(args=[args])
options={authentication:this.authentication,withArgs:args,responseCallback:cb}
scrubber=new Bongo.dnodeProtocol.Scrubber(this.proto.localStore)
return scrubber.scrub([options],function(){var fn,id,scrubbed
scrubbed=scrubber.toDnodeProtocol()
scrubbed.method=method
_this.proto.emit("request",scrubbed)
if(cb){id=Number(Object.keys(scrubbed.callbacks).last)
fn=_this.proto.localStore.items[id]
return _this.proto.localStore.items[id]=function(){var response
delete _this.proto.localStore.items[id]
response=arguments[0]
return fn.apply(null,[response.error,response.result])}}})}
NewKite.prototype.onOpen=function(){log("Connected to Kite: "+this.kite.name)
this.clearBackoffTimeout()
this.readyState=READY
this.emit("connected",this.name)
return this.emit("ready")}
NewKite.prototype.onClose=function(){var _this=this
log(""+this.kite.name+": disconnected, trying to reconnect...")
this.readyState=CLOSED
this.emit("disconnected")
return this.autoReconnect?KD.utils.defer(function(){return _this.setBackoffTimeout(_this.bound("connect"))}):void 0}
NewKite.prototype.onMessage=function(evt){var args,data,getCallback,method,req,_this=this
data=evt.data
log("onMessage",data)
req=JSON.parse(data)
getCallback=function(callbackId){var cb
_this.proto.remoteStore.has(callbackId)||_this.proto.remoteStore.add(callbackId,function(){return _this.proto.request(callbackId,[].slice.call(arguments))})
cb=_this.proto.remoteStore.get(callbackId)
return function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return cb({withArgs:rest})}}
args=req.arguments||[]
Object.keys(req.callbacks||{}).forEach(function(strId){var callback,id,path
id=parseInt(strId,10)
path=req.callbacks[id]
callback=getCallback(id)
callback.id=id
return setAt(args,path,callback)})
method=req.method
switch(method){case"methods":return this.proto.handleMethods(args[0])
case"error":return this.proto.emit("remoteError",args[0])
case"cull":return args.forEach(function(id){return _this.proto.remoteStore.cull(id)})
default:switch(typeof method){case"string":return this.proto.instance.propertyIsEnumerable(method)?apply(this.proto.instance[method],this.proto.instance,args):this.proto.emit("error",new Error("Request for non-enumerable method: "+method))
case"number":return apply(this.proto.localStore.get(method),this.proto.instance,args[0].withArgs)}}}
apply=function(fn,ctx,args){return fn.apply(ctx,args)}
NewKite.prototype.onError=function(evt){return log(""+this.kite.name+" error: "+evt.data)}
NewKite.prototype.initBackoff=function(options){var backoff,initalDelayMs,maxDelayMs,maxReconnectAttempts,multiplyFactor,totalReconnectAttempts,_ref1,_ref2,_ref3,_ref4,_ref5,_this=this
backoff=null!=(_ref1=options.backoff)?_ref1:{}
totalReconnectAttempts=0
initalDelayMs=null!=(_ref2=backoff.initialDelayMs)?_ref2:700
multiplyFactor=null!=(_ref3=backoff.multiplyFactor)?_ref3:1.4
maxDelayMs=null!=(_ref4=backoff.maxDelayMs)?_ref4:15e3
maxReconnectAttempts=null!=(_ref5=backoff.maxReconnectAttempts)?_ref5:50
this.clearBackoffTimeout=function(){return totalReconnectAttempts=0}
return this.setBackoffTimeout=function(fn){var timeout
if(maxReconnectAttempts>totalReconnectAttempts){timeout=Math.min(initalDelayMs*Math.pow(multiplyFactor,totalReconnectAttempts),maxDelayMs)
setTimeout(fn,timeout)
return totalReconnectAttempts++}return _this.emit("connectionFailed")}}
NewKite.prototype.ready=function(cb){return this.readyState?KD.utils.defer(cb):this.once("ready",cb)}
return NewKite}(KDObject)

var Kontrol,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
Kontrol=function(_super){function Kontrol(options){var authentication,kite
null==options&&(options={})
Kontrol.__super__.constructor.call(this,options)
kite={name:"kontrol",publicIP:""+KD.config.newkontrol.host,port:""+KD.config.newkontrol.port}
authentication={type:"sessionID",key:KD.remote.getSessionToken()}
this.kite=new NewKite(kite,authentication)
this.kite.connect()}__extends(Kontrol,_super)
Kontrol.prototype.getKites=function(query,callback){var _this=this
null==query&&(query={})
null==callback&&(callback=noop)
this._sanitizeQuery(query)
return this.kite.tell("getKites",[query],function(err,kites){var k
return err?callback(err,null):callback(null,function(){var _i,_len,_results
_results=[]
for(_i=0,_len=kites.length;_len>_i;_i++){k=kites[_i]
_results.push(this._createKite(k))}return _results}.call(_this))})}
Kontrol.prototype.watchKites=function(query,callback){var onEvent,_this=this
null==query&&(query={})
if(!callback)return warn("callback is not defined ")
this._sanitizeQuery(query)
onEvent=function(options){var e,kite,_ref,_ref1
e=options.withArgs[0]
kite={kite:e.kite,token:{key:null!=(_ref=e.token)?_ref.key:void 0,ttl:null!=(_ref1=e.token)?_ref1.ttl:void 0}}
return callback(null,{action:e.action,kite:_this._createKite(kite)})}
return this.kite.tell("getKites",[query,onEvent],function(err,kites){var kite,_i,_len,_results
if(err)return callback(err,null)
_results=[]
for(_i=0,_len=kites.length;_len>_i;_i++){kite=kites[_i]
_results.push(callback(null,{action:_this.KiteAction.Register,kite:_this._createKite(kite)}))}return _results})}
Kontrol.prototype._createKite=function(k){return new NewKite(k.kite,{type:"token",key:k.token.key})}
Kontrol.prototype._sanitizeQuery=function(query){query.username||(query.username=""+KD.nick())
return query.environment?void 0:query.environment="production"}
Kontrol.prototype.KiteAction={Register:"REGISTER",Deregister:"DEREGISTER"}
return Kontrol}(KDObject)

var KiteHelper,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KiteHelper=function(_super){function KiteHelper(){KiteHelper.__super__.constructor.apply(this,arguments)
this.attachListeners()}var clear,registerKodingClient_
__extends(KiteHelper,_super)
KiteHelper.prototype.attachListeners=function(){var mainController,_this=this
mainController=KD.getSingleton("mainController")
mainController.on("pageLoaded.as.loggedIn",function(){return _this.emit("changedToLoggedIn")})
mainController.on("accountChanged.to.loggedIn",function(){return _this.emit("changedToLoggedIn")})
return this.once("changedToLoggedIn",this.registerKodingClient)}
clear=function(){$.cookie("register-to-koding-client",{erase:!0})
return KD.getSingleton("router").clear()}
KiteHelper.initiateRegistiration=function(){var message,modal
$.cookie("register-to-koding-client",!0)
if(KD.isLoggedIn()){KD.getSingleton("router").clear()
return registerKodingClient_()}message="Please login to proceed to the next step"
return modal=new KDBlockingModalView({title:"Koding Client Registration",content:"<div class='modalformline'>"+message+"</div>",height:"auto",overlay:!0,buttons:{"Go to Login":{style:"modal-clean-gray",callback:function(){modal.destroy()
return KD.utils.wait(5e3,KD.getSingleton("router").handleRoute("/Login"))}},Cancel:{style:"modal-cancel",callback:function(){modal.destroy()
return clear()}}}})}
registerKodingClient_=function(){var handleInfo,k,registerToKodingClient,showErrorModal,showSuccessfulModal
if(registerToKodingClient=$.cookie("register-to-koding-client")){clear()
k=new NewKite({name:"kodingclient",publicIP:"127.0.0.1",port:"54321"})
k.connect()
showErrorModal=function(error,callback){var Cancel,Ok,Retry,code,message,modal
message=error.message,code=error.code
modal=new KDBlockingModalView({title:"Kite Registration",content:"<div class='modalformline'>"+message+"</div>",height:"auto",overlay:!0,buttons:{}})
Retry={style:"modal-clean-gray",callback:function(){modal.destroy()
return"function"==typeof callback?callback():void 0}}
Cancel={style:"modal-clean-red",callback:function(){modal.destroy()
return clear()}}
Ok={style:"modal-clean-gray",callback:function(){modal.destroy()
return clear()}}
return 201===code?modal.setButtons({Ok:Ok},!0):modal.setButtons({Retry:Retry,Cancel:Cancel},!0)}
showSuccessfulModal=function(message,callback){var modal
return modal=new KDBlockingModalView({title:"Koding Client Registration",content:"<div class='modalformline'>"+message+"</div>",height:"auto",overlay:!0,buttons:{Ok:{style:"modal-clean-green",callback:function(){modal.destroy()
return"function"==typeof callback?callback():void 0}}}})}
handleInfo=function(err,result){return KD.remote.api.JKodingKey.registerHostnameAndKey({key:result.key,hostname:result.hostID},function(err,res){var fn
fn=function(){return k.tell("info",handleInfo)}
return err?showErrorModal(err,fn):showSuccessfulModal(res,function(){result.cb(!0)
return KD.utils.wait(500,clear)})})}
return k.tell("info",handleInfo)}}
KiteHelper.prototype.registerKodingClient=registerKodingClient_
return KiteHelper}(KDEventEmitter)

var VirtualizationController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
VirtualizationController=function(_super){function VirtualizationController(){var _this=this
VirtualizationController.__super__.constructor.apply(this,arguments)
this.kc=KD.getSingleton("kiteController")
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
VirtualizationController.prototype.fetchVmInfo=function(vm,callback){var JVM
JVM=KD.remote.api.JVM
return JVM.fetchVmInfo(vm,callback)}
VirtualizationController.prototype.confirmVmDeletion=function(vmInfo,callback){var hostnameAlias,modal,vmPrefix,_ref,_this=this
null==callback&&(callback=function(){})
hostnameAlias=vmInfo.hostnameAlias
vmPrefix=(null!=(_ref=this.parseAlias(hostnameAlias))?_ref.prefix:void 0)||hostnameAlias
return modal=new VmDangerModalView({name:vmInfo.hostnameAlias,title:"Destroy '"+hostnameAlias+"'",action:"Destroy my VM",callback:function(){_this.deleteVmByHostname(hostnameAlias,function(err){return KD.showError(err)?void 0:new KDNotificationView({title:"Successfully destroyed!"})})
return modal.destroy()}},vmPrefix)}
VirtualizationController.prototype.deleteVmByHostname=function(hostnameAlias,callback){var JVM
JVM=KD.remote.api.JVM
return JVM.removeByHostname(hostnameAlias,function(err){if(err)return callback(err)
KD.getSingleton("vmController").emit("VMListChanged")
return callback(null)})}
VirtualizationController.prototype.remove=function(vm,callback){var _this=this
null==callback&&(callback=noop)
return this.fetchVmInfo(vm,function(err,vmInfo){var message
if(!KD.showError(err)){if(vmInfo){if(vmInfo.underMaintenance===!0){message="Your VM is under maintenance, not allowed to delete."
new KDNotificationView({title:message})
return callback({message:message})}return _this.confirmVmDeletion(vmInfo)}new KDNotificationView({title:"Failed to remove!"})
return callback({message:"No such VM!"})}})}
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
return new KDNotificationView({title:err.message||"Something bad happened while creating VM"})}vmController.emit("VMListChanged")
return vmController.showVMDetails(vm)}
defaultVMOptions={planCode:planCode}
group=KD.getSingleton("groupsController").getCurrentGroup()
return group.createVM({type:type,planCode:planCode},vmCreateCallback)}
VirtualizationController.prototype.fetchVMs=function(waiting){return function(force,callback){var _ref,_this=this
null==callback&&(_ref=[force,callback],callback=_ref[0],force=_ref[1])
if(null!=callback)if(this.vms.length)this.utils.defer(function(){return callback(null,_this.vms)})
else if(force||!(waiting.push(callback)>1))return KD.remote.api.JVM.fetchVms(function(err,vms){var cb,_i,_len
err||(_this.vms=vms)
if(force)return callback(err,vms)
for(_i=0,_len=waiting.length;_len>_i;_i++){cb=waiting[_i]
cb(err,vms)}return waiting=[]})}}([])
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
VirtualizationController.prototype.createDefaultVM=function(callback){return this.hasDefaultVM(function(err,state){var JVM,notify
if(state)return warn("Default VM already exists.")
notify=new KDNotificationView({title:"Creating your VM...",overlay:{transparent:!1,destroyOnClick:!1},loader:{color:"#ffffff"},duration:12e4})
JVM=KD.remote.api.JVM
return JVM.createFreeVm(function(err){var vmController
if(err){null!=notify&&notify.destroy()
return KD.showError(err)}vmController=KD.getSingleton("vmController")
return vmController.fetchDefaultVmName(function(){vmController.emit("VMListChanged")
notify.destroy()
return"function"==typeof callback?callback():void 0})})})}
VirtualizationController.prototype.createNewVM=function(callback){var _this=this
return this.hasDefaultVM(function(err,state){return state?new KDNotificationView({title:"Paid VMs will be available soon to purchase"}):_this.createDefaultVM(callback)})}
VirtualizationController.prototype.showVMDetails=function(vm){var content,modal,url,vmName
vmName=vm.hostnameAlias
url="http://"+vm.hostnameAlias
content='<div class="item">\n  <span class="title">Name:</span>\n  <span class="value">'+vmName+'</span>\n</div>\n<div class="item">\n  <span class="title">Hostname:</span>\n  <span class="value">\n    <a target="_new" href="'+url+'">'+url+"</a>\n  </span>\n</div>"
return modal=new KDModalView({title:"Your VM is ready",content:"<div class='modalformline'>"+content+"</div>",cssClass:"vm-details-modal",overlay:!0,buttons:{OK:{title:"OK",cssClass:"modal-clean-green",callback:function(){return modal.destroy()}}}})}
VirtualizationController.prototype.createPaidVM=function(){var modal,payment,productForm,workflow,_this=this
productForm=new VmProductForm
payment=KD.getSingleton("paymentController")
payment.fetchSubscriptionsWithPlans(["vm"],function(err,subscriptions){return productForm.setCurrentSubscriptions(subscriptions)})
productForm.on("PackOfferingRequested",function(){var options
options={targetOptions:{selector:{tags:"vm"}}}
return KD.getGroup().fetchProducts("pack",options,function(err,packs){return KD.showError(err)?void 0:productForm.setContents("packs",packs)})})
workflow=new PaymentWorkflow({productForm:productForm,confirmForm:new VmPaymentConfirmForm})
modal=new FormWorkflowModal({title:"Create a new VM",view:workflow,height:"auto",width:500,overlay:!0})
return workflow.on("DataCollected",function(data){_this.provisionVm(data)
return modal.destroy()}).on("Cancel",modal.bound("destroy")).enter()}
VirtualizationController.prototype.provisionVm=function(_arg){var JVM,pack,payment,paymentMethod,plan,productData,subscription,_this=this
subscription=_arg.subscription,paymentMethod=_arg.paymentMethod,productData=_arg.productData
JVM=KD.remote.api.JVM
plan=productData.plan,pack=productData.pack
payment=KD.getSingleton("paymentController")
if(!paymentMethod||subscription)return payment.debitSubscription(subscription,pack,function(err,nonce){return KD.showError(err)?void 0:JVM.createVmByNonce(nonce,function(err,vm){if(!KD.showError(err)){_this.emit("VMListChanged")
return _this.showVMDetails(vm)}})})
plan.subscribe(paymentMethod.paymentMethodId,function(err,subscription){return KD.showError(err)?void 0:_this.provisionVm({subscription:subscription,productData:productData})})
return void 0}
VirtualizationController.prototype.askForApprove=function(command,callback){var button,content,modal
switch(command){case"vm.stop":case"vm.shutdown":content="<p>Turning off your VM will <b>stop</b> running Terminal\ninstances and all running proccesess that you have on\nyour VM. Do you want to continue?</p>"
button={title:"Turn off",style:"modal-clean-red"}
break
case"vm.reinitialize":content="<p>Re-initializing your VM will <b>reset</b> all of your\nsettings that you've done in root filesystem. This\nprocess will not remove any of your files under your\nhome directory. Do you want to continue?</p>"
button={title:"Re-initialize",style:"modal-clean-red"}
break
case"vm.remove":content="<p>Removing this VM will <b>destroy</b> all the data in\nthis VM including all other users in filesystem. <b>Please\nbe careful this process cannot be undone.</b></p>\n\n<p>Do you want to continue?</p>"
button={title:"Remove VM",style:"modal-clean-red"}
break
default:return callback(!0)}return modal=new KDModalView({title:"Approval required",content:"<div class='modalformline'>"+content+"</div>",cssClass:"vm-approval",height:"auto",overlay:!0,buttons:{Action:{title:button.title,style:button.style,callback:function(){modal.destroy()
return callback(!0)}},Cancel:{style:"modal-clean-gray",callback:function(){modal.destroy()
return callback(!1)}}}})}
VirtualizationController.prototype.askToTurnOn=function(options,callback){var appName,content,modal,state,title,vmName,_ref,_runAppAfterStateChanged,_this=this
"function"==typeof options&&(_ref=[callback,options],options=_ref[0],callback=_ref[1])
appName=options.appName,vmName=options.vmName,state=options.state
title="Your VM is turned off"
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
return modal.once("KDModalViewDestroyed",function(){return"function"==typeof callback?callback({destroy:!0}):void 0})}
VirtualizationController.prototype.fetchVMPlans=function(callback){var JPaymentPlan,_this=this
JPaymentPlan=KD.remote.api.JPaymentPlan
this.emit("VMPlansFetchStart")
return JPaymentPlan.fetchPlans({tag:"vm"},function(err,plans){if(err)return warn(err)
plans&&plans.sort(function(a,b){return a.feeAmount-b.feeAmount})
_this.emit("VMPlansFetchEnd")
return callback(err,plans)})}
VirtualizationController.prototype.sanitizeVMPlansForInputs=function(plans){var descriptions,hostTypes
descriptions=plans.map(function(plan){return plan.description})
hostTypes=plans.map(function(plan,i){return{title:plan.description.title,value:i,feeAmount:(plan.feeAmount/100).toFixed(0)}})
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

if("undefined"!=typeof _rollbar&&null!==_rollbar&&KD.config.logToExternal)!function(){KD.logToExternal=function(args){return KD.isGuest()?void 0:_rollbar.push(args)}
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
mixpanel&&KD.config.logToExternal&&function(){return KD.getSingleton("mainController").on("AccountChanged",function(account){return KD.isLoggedIn()&&account?account.fetchEmail(function(err,email){var campaign,createdAt,firstName,lastName,meta,nickname,params,profile,type
err&&console.log(err)
type=account.type,meta=account.meta,profile=account.profile
createdAt=meta.createdAt
firstName=profile.firstName,lastName=profile.lastName,nickname=profile.nickname
mixpanel.identify(nickname)
mixpanel.people.set({$username:nickname,$first_name:firstName,$last_name:lastName,$email:email,$created:createdAt,Status:type,Randomizer:KD.utils.getRandomNumber(4)})
mixpanel.name_tag(""+nickname+".kd.io")
params=KD.utils.parseQuery(window.location.search.slice(1))
campaign=params.campaign
return campaign?mixpanel.track("User came from campaign",campaign):void 0}):void 0})}()

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

//@ sourceMappingURL=/js/__kdapp.0.0.1.js.map