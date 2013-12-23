document.write=document.writeln=function(){throw new Error("document.[write|writeln] is nisht-nisht")}

Encoder={EncodeType:"entity",isEmpty:function(val){return val?null===val||0==val.length||/^\s+$/.test(val):!0},arr1:["&nbsp;","&iexcl;","&cent;","&pound;","&curren;","&yen;","&brvbar;","&sect;","&uml;","&copy;","&ordf;","&laquo;","&not;","&shy;","&reg;","&macr;","&deg;","&plusmn;","&sup2;","&sup3;","&acute;","&micro;","&para;","&middot;","&cedil;","&sup1;","&ordm;","&raquo;","&frac14;","&frac12;","&frac34;","&iquest;","&Agrave;","&Aacute;","&Acirc;","&Atilde;","&Auml;","&Aring;","&AElig;","&Ccedil;","&Egrave;","&Eacute;","&Ecirc;","&Euml;","&Igrave;","&Iacute;","&Icirc;","&Iuml;","&ETH;","&Ntilde;","&Ograve;","&Oacute;","&Ocirc;","&Otilde;","&Ouml;","&times;","&Oslash;","&Ugrave;","&Uacute;","&Ucirc;","&Uuml;","&Yacute;","&THORN;","&szlig;","&agrave;","&aacute;","&acirc;","&atilde;","&auml;","&aring;","&aelig;","&ccedil;","&egrave;","&eacute;","&ecirc;","&euml;","&igrave;","&iacute;","&icirc;","&iuml;","&eth;","&ntilde;","&ograve;","&oacute;","&ocirc;","&otilde;","&ouml;","&divide;","&oslash;","&ugrave;","&uacute;","&ucirc;","&uuml;","&yacute;","&thorn;","&yuml;","&quot;","&amp;","&lt;","&gt;","&OElig;","&oelig;","&Scaron;","&scaron;","&Yuml;","&circ;","&tilde;","&ensp;","&emsp;","&thinsp;","&zwnj;","&zwj;","&lrm;","&rlm;","&ndash;","&mdash;","&lsquo;","&rsquo;","&sbquo;","&ldquo;","&rdquo;","&bdquo;","&dagger;","&Dagger;","&permil;","&lsaquo;","&rsaquo;","&euro;","&fnof;","&Alpha;","&Beta;","&Gamma;","&Delta;","&Epsilon;","&Zeta;","&Eta;","&Theta;","&Iota;","&Kappa;","&Lambda;","&Mu;","&Nu;","&Xi;","&Omicron;","&Pi;","&Rho;","&Sigma;","&Tau;","&Upsilon;","&Phi;","&Chi;","&Psi;","&Omega;","&alpha;","&beta;","&gamma;","&delta;","&epsilon;","&zeta;","&eta;","&theta;","&iota;","&kappa;","&lambda;","&mu;","&nu;","&xi;","&omicron;","&pi;","&rho;","&sigmaf;","&sigma;","&tau;","&upsilon;","&phi;","&chi;","&psi;","&omega;","&thetasym;","&upsih;","&piv;","&bull;","&hellip;","&prime;","&Prime;","&oline;","&frasl;","&weierp;","&image;","&real;","&trade;","&alefsym;","&larr;","&uarr;","&rarr;","&darr;","&harr;","&crarr;","&lArr;","&uArr;","&rArr;","&dArr;","&hArr;","&forall;","&part;","&exist;","&empty;","&nabla;","&isin;","&notin;","&ni;","&prod;","&sum;","&minus;","&lowast;","&radic;","&prop;","&infin;","&ang;","&and;","&or;","&cap;","&cup;","&int;","&there4;","&sim;","&cong;","&asymp;","&ne;","&equiv;","&le;","&ge;","&sub;","&sup;","&nsub;","&sube;","&supe;","&oplus;","&otimes;","&perp;","&sdot;","&lceil;","&rceil;","&lfloor;","&rfloor;","&lang;","&rang;","&loz;","&spades;","&clubs;","&hearts;","&diams;"],arr2:["&#160;","&#161;","&#162;","&#163;","&#164;","&#165;","&#166;","&#167;","&#168;","&#169;","&#170;","&#171;","&#172;","&#173;","&#174;","&#175;","&#176;","&#177;","&#178;","&#179;","&#180;","&#181;","&#182;","&#183;","&#184;","&#185;","&#186;","&#187;","&#188;","&#189;","&#190;","&#191;","&#192;","&#193;","&#194;","&#195;","&#196;","&#197;","&#198;","&#199;","&#200;","&#201;","&#202;","&#203;","&#204;","&#205;","&#206;","&#207;","&#208;","&#209;","&#210;","&#211;","&#212;","&#213;","&#214;","&#215;","&#216;","&#217;","&#218;","&#219;","&#220;","&#221;","&#222;","&#223;","&#224;","&#225;","&#226;","&#227;","&#228;","&#229;","&#230;","&#231;","&#232;","&#233;","&#234;","&#235;","&#236;","&#237;","&#238;","&#239;","&#240;","&#241;","&#242;","&#243;","&#244;","&#245;","&#246;","&#247;","&#248;","&#249;","&#250;","&#251;","&#252;","&#253;","&#254;","&#255;","&#34;","&#38;","&#60;","&#62;","&#338;","&#339;","&#352;","&#353;","&#376;","&#710;","&#732;","&#8194;","&#8195;","&#8201;","&#8204;","&#8205;","&#8206;","&#8207;","&#8211;","&#8212;","&#8216;","&#8217;","&#8218;","&#8220;","&#8221;","&#8222;","&#8224;","&#8225;","&#8240;","&#8249;","&#8250;","&#8364;","&#402;","&#913;","&#914;","&#915;","&#916;","&#917;","&#918;","&#919;","&#920;","&#921;","&#922;","&#923;","&#924;","&#925;","&#926;","&#927;","&#928;","&#929;","&#931;","&#932;","&#933;","&#934;","&#935;","&#936;","&#937;","&#945;","&#946;","&#947;","&#948;","&#949;","&#950;","&#951;","&#952;","&#953;","&#954;","&#955;","&#956;","&#957;","&#958;","&#959;","&#960;","&#961;","&#962;","&#963;","&#964;","&#965;","&#966;","&#967;","&#968;","&#969;","&#977;","&#978;","&#982;","&#8226;","&#8230;","&#8242;","&#8243;","&#8254;","&#8260;","&#8472;","&#8465;","&#8476;","&#8482;","&#8501;","&#8592;","&#8593;","&#8594;","&#8595;","&#8596;","&#8629;","&#8656;","&#8657;","&#8658;","&#8659;","&#8660;","&#8704;","&#8706;","&#8707;","&#8709;","&#8711;","&#8712;","&#8713;","&#8715;","&#8719;","&#8721;","&#8722;","&#8727;","&#8730;","&#8733;","&#8734;","&#8736;","&#8743;","&#8744;","&#8745;","&#8746;","&#8747;","&#8756;","&#8764;","&#8773;","&#8776;","&#8800;","&#8801;","&#8804;","&#8805;","&#8834;","&#8835;","&#8836;","&#8838;","&#8839;","&#8853;","&#8855;","&#8869;","&#8901;","&#8968;","&#8969;","&#8970;","&#8971;","&#9001;","&#9002;","&#9674;","&#9824;","&#9827;","&#9829;","&#9830;"],HTML2Numerical:function(s){return this.swapArrayVals(s,this.arr1,this.arr2)},NumericalToHTML:function(s){return this.swapArrayVals(s,this.arr2,this.arr1)},numEncode:function(s){if(this.isEmpty(s))return""
for(var e="",i=0;i<s.length;i++){var c=s.charAt(i);(" ">c||c>"~")&&(c="&#"+c.charCodeAt()+";")
e+=c}return e},htmlDecode:function(s){var c,m,d=s
if(this.isEmpty(d))return""
d=this.HTML2Numerical(d)
arr=d.match(/&#[0-9]{1,5};/g)
if(null!=arr)for(var x=0;x<arr.length;x++){m=arr[x]
c=m.substring(2,m.length-1)
d=c>=-32768&&65535>=c?d.replace(m,String.fromCharCode(c)):d.replace(m,"")}return d},htmlEncode:function(s,dbl){if(this.isEmpty(s))return""
dbl=dbl||!1
dbl&&(s="numerical"==this.EncodeType?s.replace(/&/g,"&#38;"):s.replace(/&/g,"&amp;"))
s=this.XSSEncode(s,!1)
"numerical"!=this.EncodeType&&dbl||(s=this.HTML2Numerical(s))
s=this.numEncode(s)
if(!dbl){s=s.replace(/&#/g,"##AMPHASH##")
s="numerical"==this.EncodeType?s.replace(/&/g,"&#38;"):s.replace(/&/g,"&amp;")
s=s.replace(/##AMPHASH##/g,"&#")}s=s.replace(/&#\d*([^\d;]|$)/g,"$1")
dbl||(s=this.correctEncoding(s))
"entity"==this.EncodeType&&(s=this.NumericalToHTML(s))
return s},XSSEncode:function(s,en){if(this.isEmpty(s))return""
en=en||!0
if(en){s=s.replace(/\'/g,"&#39;")
s=s.replace(/\"/g,"&quot;")
s=s.replace(/</g,"&lt;")
s=s.replace(/>/g,"&gt;")}else{s=s.replace(/\'/g,"&#39;")
s=s.replace(/\"/g,"&#34;")
s=s.replace(/</g,"&#60;")
s=s.replace(/>/g,"&#62;")}return s},hasEncoded:function(s){return/&#[0-9]{1,5};/g.test(s)?!0:/&[A-Z]{2,6};/gi.test(s)?!0:!1},stripUnicode:function(s){return s.replace(/[^\x20-\x7E]/g,"")},correctEncoding:function(s){return s.replace(/(&amp;)(amp;)+/,"$1")},swapArrayVals:function(s,arr1,arr2){if(this.isEmpty(s))return""
var re
if(arr1&&arr2&&arr1.length==arr2.length)for(var x=0,i=arr1.length;i>x;x++){re=new RegExp(arr1[x],"g")
s=s.replace(re,arr2[x])}return s},inArray:function(item,arr){for(var i=0,x=arr.length;x>i;i++)if(arr[i]===item)return i
return-1}}

!function(window,undefined){function isArraylike(obj){var length=obj.length,type=jQuery.type(obj)
return jQuery.isWindow(obj)?!1:1===obj.nodeType&&length?!0:"array"===type||"function"!==type&&(0===length||"number"==typeof length&&length>0&&length-1 in obj)}function createOptions(options){var object=optionsCache[options]={}
jQuery.each(options.match(core_rnotwhite)||[],function(_,flag){object[flag]=!0})
return object}function internalData(elem,name,data,pvt){if(jQuery.acceptData(elem)){var thisCache,ret,internalKey=jQuery.expando,getByName="string"==typeof name,isNode=elem.nodeType,cache=isNode?jQuery.cache:elem,id=isNode?elem[internalKey]:elem[internalKey]&&internalKey
if(id&&cache[id]&&(pvt||cache[id].data)||!getByName||data!==undefined){id||(isNode?elem[internalKey]=id=core_deletedIds.pop()||jQuery.guid++:id=internalKey)
if(!cache[id]){cache[id]={}
isNode||(cache[id].toJSON=jQuery.noop)}("object"==typeof name||"function"==typeof name)&&(pvt?cache[id]=jQuery.extend(cache[id],name):cache[id].data=jQuery.extend(cache[id].data,name))
thisCache=cache[id]
if(!pvt){thisCache.data||(thisCache.data={})
thisCache=thisCache.data}data!==undefined&&(thisCache[jQuery.camelCase(name)]=data)
if(getByName){ret=thisCache[name]
null==ret&&(ret=thisCache[jQuery.camelCase(name)])}else ret=thisCache
return ret}}}function internalRemoveData(elem,name,pvt){if(jQuery.acceptData(elem)){var i,l,thisCache,isNode=elem.nodeType,cache=isNode?jQuery.cache:elem,id=isNode?elem[jQuery.expando]:jQuery.expando
if(cache[id]){if(name){thisCache=pvt?cache[id]:cache[id].data
if(thisCache){if(jQuery.isArray(name))name=name.concat(jQuery.map(name,jQuery.camelCase))
else if(name in thisCache)name=[name]
else{name=jQuery.camelCase(name)
name=name in thisCache?[name]:name.split(" ")}for(i=0,l=name.length;l>i;i++)delete thisCache[name[i]]
if(!(pvt?isEmptyDataObject:jQuery.isEmptyObject)(thisCache))return}}if(!pvt){delete cache[id].data
if(!isEmptyDataObject(cache[id]))return}isNode?jQuery.cleanData([elem],!0):jQuery.support.deleteExpando||cache!=cache.window?delete cache[id]:cache[id]=null}}}function dataAttr(elem,key,data){if(data===undefined&&1===elem.nodeType){var name="data-"+key.replace(rmultiDash,"-$1").toLowerCase()
data=elem.getAttribute(name)
if("string"==typeof data){try{data="true"===data?!0:"false"===data?!1:"null"===data?null:+data+""===data?+data:rbrace.test(data)?jQuery.parseJSON(data):data}catch(e){}jQuery.data(elem,key,data)}else data=undefined}return data}function isEmptyDataObject(obj){var name
for(name in obj)if(("data"!==name||!jQuery.isEmptyObject(obj[name]))&&"toJSON"!==name)return!1
return!0}function returnTrue(){return!0}function returnFalse(){return!1}function sibling(cur,dir){do cur=cur[dir]
while(cur&&1!==cur.nodeType)
return cur}function winnow(elements,qualifier,keep){qualifier=qualifier||0
if(jQuery.isFunction(qualifier))return jQuery.grep(elements,function(elem,i){var retVal=!!qualifier.call(elem,i,elem)
return retVal===keep})
if(qualifier.nodeType)return jQuery.grep(elements,function(elem){return elem===qualifier===keep})
if("string"==typeof qualifier){var filtered=jQuery.grep(elements,function(elem){return 1===elem.nodeType})
if(isSimple.test(qualifier))return jQuery.filter(qualifier,filtered,!keep)
qualifier=jQuery.filter(qualifier,filtered)}return jQuery.grep(elements,function(elem){return jQuery.inArray(elem,qualifier)>=0===keep})}function createSafeFragment(document){var list=nodeNames.split("|"),safeFrag=document.createDocumentFragment()
if(safeFrag.createElement)for(;list.length;)safeFrag.createElement(list.pop())
return safeFrag}function findOrAppend(elem,tag){return elem.getElementsByTagName(tag)[0]||elem.appendChild(elem.ownerDocument.createElement(tag))}function disableScript(elem){var attr=elem.getAttributeNode("type")
elem.type=(attr&&attr.specified)+"/"+elem.type
return elem}function restoreScript(elem){var match=rscriptTypeMasked.exec(elem.type)
match?elem.type=match[1]:elem.removeAttribute("type")
return elem}function setGlobalEval(elems,refElements){for(var elem,i=0;null!=(elem=elems[i]);i++)jQuery._data(elem,"globalEval",!refElements||jQuery._data(refElements[i],"globalEval"))}function cloneCopyEvent(src,dest){if(1===dest.nodeType&&jQuery.hasData(src)){var type,i,l,oldData=jQuery._data(src),curData=jQuery._data(dest,oldData),events=oldData.events
if(events){delete curData.handle
curData.events={}
for(type in events)for(i=0,l=events[type].length;l>i;i++)jQuery.event.add(dest,type,events[type][i])}curData.data&&(curData.data=jQuery.extend({},curData.data))}}function fixCloneNodeIssues(src,dest){var nodeName,e,data
if(1===dest.nodeType){nodeName=dest.nodeName.toLowerCase()
if(!jQuery.support.noCloneEvent&&dest[jQuery.expando]){data=jQuery._data(dest)
for(e in data.events)jQuery.removeEvent(dest,e,data.handle)
dest.removeAttribute(jQuery.expando)}if("script"===nodeName&&dest.text!==src.text){disableScript(dest).text=src.text
restoreScript(dest)}else if("object"===nodeName){dest.parentNode&&(dest.outerHTML=src.outerHTML)
jQuery.support.html5Clone&&src.innerHTML&&!jQuery.trim(dest.innerHTML)&&(dest.innerHTML=src.innerHTML)}else if("input"===nodeName&&manipulation_rcheckableType.test(src.type)){dest.defaultChecked=dest.checked=src.checked
dest.value!==src.value&&(dest.value=src.value)}else"option"===nodeName?dest.defaultSelected=dest.selected=src.defaultSelected:("input"===nodeName||"textarea"===nodeName)&&(dest.defaultValue=src.defaultValue)}}function getAll(context,tag){var elems,elem,i=0,found=typeof context.getElementsByTagName!==core_strundefined?context.getElementsByTagName(tag||"*"):typeof context.querySelectorAll!==core_strundefined?context.querySelectorAll(tag||"*"):undefined
if(!found)for(found=[],elems=context.childNodes||context;null!=(elem=elems[i]);i++)!tag||jQuery.nodeName(elem,tag)?found.push(elem):jQuery.merge(found,getAll(elem,tag))
return tag===undefined||tag&&jQuery.nodeName(context,tag)?jQuery.merge([context],found):found}function fixDefaultChecked(elem){manipulation_rcheckableType.test(elem.type)&&(elem.defaultChecked=elem.checked)}function vendorPropName(style,name){if(name in style)return name
for(var capName=name.charAt(0).toUpperCase()+name.slice(1),origName=name,i=cssPrefixes.length;i--;){name=cssPrefixes[i]+capName
if(name in style)return name}return origName}function isHidden(elem,el){elem=el||elem
return"none"===jQuery.css(elem,"display")||!jQuery.contains(elem.ownerDocument,elem)}function showHide(elements,show){for(var display,elem,hidden,values=[],index=0,length=elements.length;length>index;index++){elem=elements[index]
if(elem.style){values[index]=jQuery._data(elem,"olddisplay")
display=elem.style.display
if(show){values[index]||"none"!==display||(elem.style.display="")
""===elem.style.display&&isHidden(elem)&&(values[index]=jQuery._data(elem,"olddisplay",css_defaultDisplay(elem.nodeName)))}else if(!values[index]){hidden=isHidden(elem);(display&&"none"!==display||!hidden)&&jQuery._data(elem,"olddisplay",hidden?display:jQuery.css(elem,"display"))}}}for(index=0;length>index;index++){elem=elements[index]
elem.style&&(show&&"none"!==elem.style.display&&""!==elem.style.display||(elem.style.display=show?values[index]||"":"none"))}return elements}function setPositiveNumber(elem,value,subtract){var matches=rnumsplit.exec(value)
return matches?Math.max(0,matches[1]-(subtract||0))+(matches[2]||"px"):value}function augmentWidthOrHeight(elem,name,extra,isBorderBox,styles){for(var i=extra===(isBorderBox?"border":"content")?4:"width"===name?1:0,val=0;4>i;i+=2){"margin"===extra&&(val+=jQuery.css(elem,extra+cssExpand[i],!0,styles))
if(isBorderBox){"content"===extra&&(val-=jQuery.css(elem,"padding"+cssExpand[i],!0,styles))
"margin"!==extra&&(val-=jQuery.css(elem,"border"+cssExpand[i]+"Width",!0,styles))}else{val+=jQuery.css(elem,"padding"+cssExpand[i],!0,styles)
"padding"!==extra&&(val+=jQuery.css(elem,"border"+cssExpand[i]+"Width",!0,styles))}}return val}function getWidthOrHeight(elem,name,extra){var valueIsBorderBox=!0,val="width"===name?elem.offsetWidth:elem.offsetHeight,styles=getStyles(elem),isBorderBox=jQuery.support.boxSizing&&"border-box"===jQuery.css(elem,"boxSizing",!1,styles)
if(0>=val||null==val){val=curCSS(elem,name,styles);(0>val||null==val)&&(val=elem.style[name])
if(rnumnonpx.test(val))return val
valueIsBorderBox=isBorderBox&&(jQuery.support.boxSizingReliable||val===elem.style[name])
val=parseFloat(val)||0}return val+augmentWidthOrHeight(elem,name,extra||(isBorderBox?"border":"content"),valueIsBorderBox,styles)+"px"}function css_defaultDisplay(nodeName){var doc=document,display=elemdisplay[nodeName]
if(!display){display=actualDisplay(nodeName,doc)
if("none"===display||!display){iframe=(iframe||jQuery("<iframe frameborder='0' width='0' height='0'/>").css("cssText","display:block !important")).appendTo(doc.documentElement)
doc=(iframe[0].contentWindow||iframe[0].contentDocument).document
doc.write("<!doctype html><html><body>")
doc.close()
display=actualDisplay(nodeName,doc)
iframe.detach()}elemdisplay[nodeName]=display}return display}function actualDisplay(name,doc){var elem=jQuery(doc.createElement(name)).appendTo(doc.body),display=jQuery.css(elem[0],"display")
elem.remove()
return display}function buildParams(prefix,obj,traditional,add){var name
if(jQuery.isArray(obj))jQuery.each(obj,function(i,v){traditional||rbracket.test(prefix)?add(prefix,v):buildParams(prefix+"["+("object"==typeof v?i:"")+"]",v,traditional,add)})
else if(traditional||"object"!==jQuery.type(obj))add(prefix,obj)
else for(name in obj)buildParams(prefix+"["+name+"]",obj[name],traditional,add)}function addToPrefiltersOrTransports(structure){return function(dataTypeExpression,func){if("string"!=typeof dataTypeExpression){func=dataTypeExpression
dataTypeExpression="*"}var dataType,i=0,dataTypes=dataTypeExpression.toLowerCase().match(core_rnotwhite)||[]
if(jQuery.isFunction(func))for(;dataType=dataTypes[i++];)if("+"===dataType[0]){dataType=dataType.slice(1)||"*";(structure[dataType]=structure[dataType]||[]).unshift(func)}else(structure[dataType]=structure[dataType]||[]).push(func)}}function inspectPrefiltersOrTransports(structure,options,originalOptions,jqXHR){function inspect(dataType){var selected
inspected[dataType]=!0
jQuery.each(structure[dataType]||[],function(_,prefilterOrFactory){var dataTypeOrTransport=prefilterOrFactory(options,originalOptions,jqXHR)
if("string"==typeof dataTypeOrTransport&&!seekingTransport&&!inspected[dataTypeOrTransport]){options.dataTypes.unshift(dataTypeOrTransport)
inspect(dataTypeOrTransport)
return!1}return seekingTransport?!(selected=dataTypeOrTransport):void 0})
return selected}var inspected={},seekingTransport=structure===transports
return inspect(options.dataTypes[0])||!inspected["*"]&&inspect("*")}function ajaxExtend(target,src){var deep,key,flatOptions=jQuery.ajaxSettings.flatOptions||{}
for(key in src)src[key]!==undefined&&((flatOptions[key]?target:deep||(deep={}))[key]=src[key])
deep&&jQuery.extend(!0,target,deep)
return target}function ajaxHandleResponses(s,jqXHR,responses){var firstDataType,ct,finalDataType,type,contents=s.contents,dataTypes=s.dataTypes,responseFields=s.responseFields
for(type in responseFields)type in responses&&(jqXHR[responseFields[type]]=responses[type])
for(;"*"===dataTypes[0];){dataTypes.shift()
ct===undefined&&(ct=s.mimeType||jqXHR.getResponseHeader("Content-Type"))}if(ct)for(type in contents)if(contents[type]&&contents[type].test(ct)){dataTypes.unshift(type)
break}if(dataTypes[0]in responses)finalDataType=dataTypes[0]
else{for(type in responses){if(!dataTypes[0]||s.converters[type+" "+dataTypes[0]]){finalDataType=type
break}firstDataType||(firstDataType=type)}finalDataType=finalDataType||firstDataType}if(finalDataType){finalDataType!==dataTypes[0]&&dataTypes.unshift(finalDataType)
return responses[finalDataType]}}function ajaxConvert(s,response){var conv2,current,conv,tmp,converters={},i=0,dataTypes=s.dataTypes.slice(),prev=dataTypes[0]
s.dataFilter&&(response=s.dataFilter(response,s.dataType))
if(dataTypes[1])for(conv in s.converters)converters[conv.toLowerCase()]=s.converters[conv]
for(;current=dataTypes[++i];)if("*"!==current){if("*"!==prev&&prev!==current){conv=converters[prev+" "+current]||converters["* "+current]
if(!conv)for(conv2 in converters){tmp=conv2.split(" ")
if(tmp[1]===current){conv=converters[prev+" "+tmp[0]]||converters["* "+tmp[0]]
if(conv){if(conv===!0)conv=converters[conv2]
else if(converters[conv2]!==!0){current=tmp[0]
dataTypes.splice(i--,0,current)}break}}}if(conv!==!0)if(conv&&s["throws"])response=conv(response)
else try{response=conv(response)}catch(e){return{state:"parsererror",error:conv?e:"No conversion from "+prev+" to "+current}}}prev=current}return{state:"success",data:response}}function createStandardXHR(){try{return new window.XMLHttpRequest}catch(e){}}function createActiveXHR(){try{return new window.ActiveXObject("Microsoft.XMLHTTP")}catch(e){}}function createFxNow(){setTimeout(function(){fxNow=undefined})
return fxNow=jQuery.now()}function createTweens(animation,props){jQuery.each(props,function(prop,value){for(var collection=(tweeners[prop]||[]).concat(tweeners["*"]),index=0,length=collection.length;length>index;index++)if(collection[index].call(animation,prop,value))return})}function Animation(elem,properties,options){var result,stopped,index=0,length=animationPrefilters.length,deferred=jQuery.Deferred().always(function(){delete tick.elem}),tick=function(){if(stopped)return!1
for(var currentTime=fxNow||createFxNow(),remaining=Math.max(0,animation.startTime+animation.duration-currentTime),temp=remaining/animation.duration||0,percent=1-temp,index=0,length=animation.tweens.length;length>index;index++)animation.tweens[index].run(percent)
deferred.notifyWith(elem,[animation,percent,remaining])
if(1>percent&&length)return remaining
deferred.resolveWith(elem,[animation])
return!1},animation=deferred.promise({elem:elem,props:jQuery.extend({},properties),opts:jQuery.extend(!0,{specialEasing:{}},options),originalProperties:properties,originalOptions:options,startTime:fxNow||createFxNow(),duration:options.duration,tweens:[],createTween:function(prop,end){var tween=jQuery.Tween(elem,animation.opts,prop,end,animation.opts.specialEasing[prop]||animation.opts.easing)
animation.tweens.push(tween)
return tween},stop:function(gotoEnd){var index=0,length=gotoEnd?animation.tweens.length:0
if(stopped)return this
stopped=!0
for(;length>index;index++)animation.tweens[index].run(1)
gotoEnd?deferred.resolveWith(elem,[animation,gotoEnd]):deferred.rejectWith(elem,[animation,gotoEnd])
return this}}),props=animation.props
propFilter(props,animation.opts.specialEasing)
for(;length>index;index++){result=animationPrefilters[index].call(animation,elem,props,animation.opts)
if(result)return result}createTweens(animation,props)
jQuery.isFunction(animation.opts.start)&&animation.opts.start.call(elem,animation)
jQuery.fx.timer(jQuery.extend(tick,{elem:elem,anim:animation,queue:animation.opts.queue}))
return animation.progress(animation.opts.progress).done(animation.opts.done,animation.opts.complete).fail(animation.opts.fail).always(animation.opts.always)}function propFilter(props,specialEasing){var value,name,index,easing,hooks
for(index in props){name=jQuery.camelCase(index)
easing=specialEasing[name]
value=props[index]
if(jQuery.isArray(value)){easing=value[1]
value=props[index]=value[0]}if(index!==name){props[name]=value
delete props[index]}hooks=jQuery.cssHooks[name]
if(hooks&&"expand"in hooks){value=hooks.expand(value)
delete props[name]
for(index in value)if(!(index in props)){props[index]=value[index]
specialEasing[index]=easing}}else specialEasing[name]=easing}}function defaultPrefilter(elem,props,opts){var prop,index,length,value,dataShow,toggle,tween,hooks,oldfire,anim=this,style=elem.style,orig={},handled=[],hidden=elem.nodeType&&isHidden(elem)
if(!opts.queue){hooks=jQuery._queueHooks(elem,"fx")
if(null==hooks.unqueued){hooks.unqueued=0
oldfire=hooks.empty.fire
hooks.empty.fire=function(){hooks.unqueued||oldfire()}}hooks.unqueued++
anim.always(function(){anim.always(function(){hooks.unqueued--
jQuery.queue(elem,"fx").length||hooks.empty.fire()})})}if(1===elem.nodeType&&("height"in props||"width"in props)){opts.overflow=[style.overflow,style.overflowX,style.overflowY]
"inline"===jQuery.css(elem,"display")&&"none"===jQuery.css(elem,"float")&&(jQuery.support.inlineBlockNeedsLayout&&"inline"!==css_defaultDisplay(elem.nodeName)?style.zoom=1:style.display="inline-block")}if(opts.overflow){style.overflow="hidden"
jQuery.support.shrinkWrapBlocks||anim.always(function(){style.overflow=opts.overflow[0]
style.overflowX=opts.overflow[1]
style.overflowY=opts.overflow[2]})}for(index in props){value=props[index]
if(rfxtypes.exec(value)){delete props[index]
toggle=toggle||"toggle"===value
if(value===(hidden?"hide":"show"))continue
handled.push(index)}}length=handled.length
if(length){dataShow=jQuery._data(elem,"fxshow")||jQuery._data(elem,"fxshow",{})
"hidden"in dataShow&&(hidden=dataShow.hidden)
toggle&&(dataShow.hidden=!hidden)
hidden?jQuery(elem).show():anim.done(function(){jQuery(elem).hide()})
anim.done(function(){var prop
jQuery._removeData(elem,"fxshow")
for(prop in orig)jQuery.style(elem,prop,orig[prop])})
for(index=0;length>index;index++){prop=handled[index]
tween=anim.createTween(prop,hidden?dataShow[prop]:0)
orig[prop]=dataShow[prop]||jQuery.style(elem,prop)
if(!(prop in dataShow)){dataShow[prop]=tween.start
if(hidden){tween.end=tween.start
tween.start="width"===prop||"height"===prop?1:0}}}}}function Tween(elem,options,prop,end,easing){return new Tween.prototype.init(elem,options,prop,end,easing)}function genFx(type,includeWidth){var which,attrs={height:type},i=0
includeWidth=includeWidth?1:0
for(;4>i;i+=2-includeWidth){which=cssExpand[i]
attrs["margin"+which]=attrs["padding"+which]=type}includeWidth&&(attrs.opacity=attrs.width=type)
return attrs}function getWindow(elem){return jQuery.isWindow(elem)?elem:9===elem.nodeType?elem.defaultView||elem.parentWindow:!1}var readyList,rootjQuery,core_strundefined=typeof undefined,document=window.document,location=window.location,_jQuery=window.jQuery,_$=window.$,class2type={},core_deletedIds=[],core_version="1.9.1",core_concat=core_deletedIds.concat,core_push=core_deletedIds.push,core_slice=core_deletedIds.slice,core_indexOf=core_deletedIds.indexOf,core_toString=class2type.toString,core_hasOwn=class2type.hasOwnProperty,core_trim=core_version.trim,jQuery=function(selector,context){return new jQuery.fn.init(selector,context,rootjQuery)},core_pnum=/[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/.source,core_rnotwhite=/\S+/g,rtrim=/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,rquickExpr=/^(?:(<[\w\W]+>)[^>]*|#([\w-]*))$/,rsingleTag=/^<(\w+)\s*\/?>(?:<\/\1>|)$/,rvalidchars=/^[\],:{}\s]*$/,rvalidbraces=/(?:^|:|,)(?:\s*\[)+/g,rvalidescape=/\\(?:["\\\/bfnrt]|u[\da-fA-F]{4})/g,rvalidtokens=/"[^"\\\r\n]*"|true|false|null|-?(?:\d+\.|)\d+(?:[eE][+-]?\d+|)/g,rmsPrefix=/^-ms-/,rdashAlpha=/-([\da-z])/gi,fcamelCase=function(all,letter){return letter.toUpperCase()},completed=function(event){if(document.addEventListener||"load"===event.type||"complete"===document.readyState){detach()
jQuery.ready()}},detach=function(){if(document.addEventListener){document.removeEventListener("DOMContentLoaded",completed,!1)
window.removeEventListener("load",completed,!1)}else{document.detachEvent("onreadystatechange",completed)
window.detachEvent("onload",completed)}}
jQuery.fn=jQuery.prototype={jquery:core_version,constructor:jQuery,init:function(selector,context,rootjQuery){var match,elem
if(!selector)return this
if("string"==typeof selector){match="<"===selector.charAt(0)&&">"===selector.charAt(selector.length-1)&&selector.length>=3?[null,selector,null]:rquickExpr.exec(selector)
if(!match||!match[1]&&context)return!context||context.jquery?(context||rootjQuery).find(selector):this.constructor(context).find(selector)
if(match[1]){context=context instanceof jQuery?context[0]:context
jQuery.merge(this,jQuery.parseHTML(match[1],context&&context.nodeType?context.ownerDocument||context:document,!0))
if(rsingleTag.test(match[1])&&jQuery.isPlainObject(context))for(match in context)jQuery.isFunction(this[match])?this[match](context[match]):this.attr(match,context[match])
return this}elem=document.getElementById(match[2])
if(elem&&elem.parentNode){if(elem.id!==match[2])return rootjQuery.find(selector)
this.length=1
this[0]=elem}this.context=document
this.selector=selector
return this}if(selector.nodeType){this.context=this[0]=selector
this.length=1
return this}if(jQuery.isFunction(selector))return rootjQuery.ready(selector)
if(selector.selector!==undefined){this.selector=selector.selector
this.context=selector.context}return jQuery.makeArray(selector,this)},selector:"",length:0,size:function(){return this.length},toArray:function(){return core_slice.call(this)},get:function(num){return null==num?this.toArray():0>num?this[this.length+num]:this[num]},pushStack:function(elems){var ret=jQuery.merge(this.constructor(),elems)
ret.prevObject=this
ret.context=this.context
return ret},each:function(callback,args){return jQuery.each(this,callback,args)},ready:function(fn){jQuery.ready.promise().done(fn)
return this},slice:function(){return this.pushStack(core_slice.apply(this,arguments))},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},eq:function(i){var len=this.length,j=+i+(0>i?len:0)
return this.pushStack(j>=0&&len>j?[this[j]]:[])},map:function(callback){return this.pushStack(jQuery.map(this,function(elem,i){return callback.call(elem,i,elem)}))},end:function(){return this.prevObject||this.constructor(null)},push:core_push,sort:[].sort,splice:[].splice}
jQuery.fn.init.prototype=jQuery.fn
jQuery.extend=jQuery.fn.extend=function(){var src,copyIsArray,copy,name,options,clone,target=arguments[0]||{},i=1,length=arguments.length,deep=!1
if("boolean"==typeof target){deep=target
target=arguments[1]||{}
i=2}"object"==typeof target||jQuery.isFunction(target)||(target={})
if(length===i){target=this;--i}for(;length>i;i++)if(null!=(options=arguments[i]))for(name in options){src=target[name]
copy=options[name]
if(target!==copy)if(deep&&copy&&(jQuery.isPlainObject(copy)||(copyIsArray=jQuery.isArray(copy)))){if(copyIsArray){copyIsArray=!1
clone=src&&jQuery.isArray(src)?src:[]}else clone=src&&jQuery.isPlainObject(src)?src:{}
target[name]=jQuery.extend(deep,clone,copy)}else copy!==undefined&&(target[name]=copy)}return target}
jQuery.extend({noConflict:function(deep){window.$===jQuery&&(window.$=_$)
deep&&window.jQuery===jQuery&&(window.jQuery=_jQuery)
return jQuery},isReady:!1,readyWait:1,holdReady:function(hold){hold?jQuery.readyWait++:jQuery.ready(!0)},ready:function(wait){if(wait===!0?!--jQuery.readyWait:!jQuery.isReady){if(!document.body)return setTimeout(jQuery.ready)
jQuery.isReady=!0
if(!(wait!==!0&&--jQuery.readyWait>0)){readyList.resolveWith(document,[jQuery])
jQuery.fn.trigger&&jQuery(document).trigger("ready").off("ready")}}},isFunction:function(obj){return"function"===jQuery.type(obj)},isArray:Array.isArray||function(obj){return"array"===jQuery.type(obj)},isWindow:function(obj){return null!=obj&&obj==obj.window},isNumeric:function(obj){return!isNaN(parseFloat(obj))&&isFinite(obj)},type:function(obj){return null==obj?String(obj):"object"==typeof obj||"function"==typeof obj?class2type[core_toString.call(obj)]||"object":typeof obj},isPlainObject:function(obj){if(!obj||"object"!==jQuery.type(obj)||obj.nodeType||jQuery.isWindow(obj))return!1
try{if(obj.constructor&&!core_hasOwn.call(obj,"constructor")&&!core_hasOwn.call(obj.constructor.prototype,"isPrototypeOf"))return!1}catch(e){return!1}var key
for(key in obj);return key===undefined||core_hasOwn.call(obj,key)},isEmptyObject:function(obj){var name
for(name in obj)return!1
return!0},error:function(msg){throw new Error(msg)},parseHTML:function(data,context,keepScripts){if(!data||"string"!=typeof data)return null
if("boolean"==typeof context){keepScripts=context
context=!1}context=context||document
var parsed=rsingleTag.exec(data),scripts=!keepScripts&&[]
if(parsed)return[context.createElement(parsed[1])]
parsed=jQuery.buildFragment([data],context,scripts)
scripts&&jQuery(scripts).remove()
return jQuery.merge([],parsed.childNodes)},parseJSON:function(data){if(window.JSON&&window.JSON.parse)return window.JSON.parse(data)
if(null===data)return data
if("string"==typeof data){data=jQuery.trim(data)
if(data&&rvalidchars.test(data.replace(rvalidescape,"@").replace(rvalidtokens,"]").replace(rvalidbraces,"")))return new Function("return "+data)()}jQuery.error("Invalid JSON: "+data)},parseXML:function(data){var xml,tmp
if(!data||"string"!=typeof data)return null
try{if(window.DOMParser){tmp=new DOMParser
xml=tmp.parseFromString(data,"text/xml")}else{xml=new ActiveXObject("Microsoft.XMLDOM")
xml.async="false"
xml.loadXML(data)}}catch(e){xml=undefined}xml&&xml.documentElement&&!xml.getElementsByTagName("parsererror").length||jQuery.error("Invalid XML: "+data)
return xml},noop:function(){},globalEval:function(data){data&&jQuery.trim(data)&&(window.execScript||function(data){window.eval.call(window,data)})(data)},camelCase:function(string){return string.replace(rmsPrefix,"ms-").replace(rdashAlpha,fcamelCase)},nodeName:function(elem,name){return elem.nodeName&&elem.nodeName.toLowerCase()===name.toLowerCase()},each:function(obj,callback,args){var value,i=0,length=obj.length,isArray=isArraylike(obj)
if(args)if(isArray)for(;length>i;i++){value=callback.apply(obj[i],args)
if(value===!1)break}else for(i in obj){value=callback.apply(obj[i],args)
if(value===!1)break}else if(isArray)for(;length>i;i++){value=callback.call(obj[i],i,obj[i])
if(value===!1)break}else for(i in obj){value=callback.call(obj[i],i,obj[i])
if(value===!1)break}return obj},trim:core_trim&&!core_trim.call("﻿ ")?function(text){return null==text?"":core_trim.call(text)}:function(text){return null==text?"":(text+"").replace(rtrim,"")},makeArray:function(arr,results){var ret=results||[]
null!=arr&&(isArraylike(Object(arr))?jQuery.merge(ret,"string"==typeof arr?[arr]:arr):core_push.call(ret,arr))
return ret},inArray:function(elem,arr,i){var len
if(arr){if(core_indexOf)return core_indexOf.call(arr,elem,i)
len=arr.length
i=i?0>i?Math.max(0,len+i):i:0
for(;len>i;i++)if(i in arr&&arr[i]===elem)return i}return-1},merge:function(first,second){var l=second.length,i=first.length,j=0
if("number"==typeof l)for(;l>j;j++)first[i++]=second[j]
else for(;second[j]!==undefined;)first[i++]=second[j++]
first.length=i
return first},grep:function(elems,callback,inv){var retVal,ret=[],i=0,length=elems.length
inv=!!inv
for(;length>i;i++){retVal=!!callback(elems[i],i)
inv!==retVal&&ret.push(elems[i])}return ret},map:function(elems,callback,arg){var value,i=0,length=elems.length,isArray=isArraylike(elems),ret=[]
if(isArray)for(;length>i;i++){value=callback(elems[i],i,arg)
null!=value&&(ret[ret.length]=value)}else for(i in elems){value=callback(elems[i],i,arg)
null!=value&&(ret[ret.length]=value)}return core_concat.apply([],ret)},guid:1,proxy:function(fn,context){var args,proxy,tmp
if("string"==typeof context){tmp=fn[context]
context=fn
fn=tmp}if(!jQuery.isFunction(fn))return undefined
args=core_slice.call(arguments,2)
proxy=function(){return fn.apply(context||this,args.concat(core_slice.call(arguments)))}
proxy.guid=fn.guid=fn.guid||jQuery.guid++
return proxy},access:function(elems,fn,key,value,chainable,emptyGet,raw){var i=0,length=elems.length,bulk=null==key
if("object"===jQuery.type(key)){chainable=!0
for(i in key)jQuery.access(elems,fn,i,key[i],!0,emptyGet,raw)}else if(value!==undefined){chainable=!0
jQuery.isFunction(value)||(raw=!0)
if(bulk)if(raw){fn.call(elems,value)
fn=null}else{bulk=fn
fn=function(elem,key,value){return bulk.call(jQuery(elem),value)}}if(fn)for(;length>i;i++)fn(elems[i],key,raw?value:value.call(elems[i],i,fn(elems[i],key)))}return chainable?elems:bulk?fn.call(elems):length?fn(elems[0],key):emptyGet},now:function(){return(new Date).getTime()}})
jQuery.ready.promise=function(obj){if(!readyList){readyList=jQuery.Deferred()
if("complete"===document.readyState)setTimeout(jQuery.ready)
else if(document.addEventListener){document.addEventListener("DOMContentLoaded",completed,!1)
window.addEventListener("load",completed,!1)}else{document.attachEvent("onreadystatechange",completed)
window.attachEvent("onload",completed)
var top=!1
try{top=null==window.frameElement&&document.documentElement}catch(e){}top&&top.doScroll&&function doScrollCheck(){if(!jQuery.isReady){try{top.doScroll("left")}catch(e){return setTimeout(doScrollCheck,50)}detach()
jQuery.ready()}}()}}return readyList.promise(obj)}
jQuery.each("Boolean Number String Function Array Date RegExp Object Error".split(" "),function(i,name){class2type["[object "+name+"]"]=name.toLowerCase()})
rootjQuery=jQuery(document)
var optionsCache={}
jQuery.Callbacks=function(options){options="string"==typeof options?optionsCache[options]||createOptions(options):jQuery.extend({},options)
var firing,memory,fired,firingLength,firingIndex,firingStart,list=[],stack=!options.once&&[],fire=function(data){memory=options.memory&&data
fired=!0
firingIndex=firingStart||0
firingStart=0
firingLength=list.length
firing=!0
for(;list&&firingLength>firingIndex;firingIndex++)if(list[firingIndex].apply(data[0],data[1])===!1&&options.stopOnFalse){memory=!1
break}firing=!1
list&&(stack?stack.length&&fire(stack.shift()):memory?list=[]:self.disable())},self={add:function(){if(list){var start=list.length
!function add(args){jQuery.each(args,function(_,arg){var type=jQuery.type(arg)
"function"===type?options.unique&&self.has(arg)||list.push(arg):arg&&arg.length&&"string"!==type&&add(arg)})}(arguments)
if(firing)firingLength=list.length
else if(memory){firingStart=start
fire(memory)}}return this},remove:function(){list&&jQuery.each(arguments,function(_,arg){for(var index;(index=jQuery.inArray(arg,list,index))>-1;){list.splice(index,1)
if(firing){firingLength>=index&&firingLength--
firingIndex>=index&&firingIndex--}}})
return this},has:function(fn){return fn?jQuery.inArray(fn,list)>-1:!(!list||!list.length)},empty:function(){list=[]
return this},disable:function(){list=stack=memory=undefined
return this},disabled:function(){return!list},lock:function(){stack=undefined
memory||self.disable()
return this},locked:function(){return!stack},fireWith:function(context,args){args=args||[]
args=[context,args.slice?args.slice():args]
!list||fired&&!stack||(firing?stack.push(args):fire(args))
return this},fire:function(){self.fireWith(this,arguments)
return this},fired:function(){return!!fired}}
return self}
jQuery.extend({Deferred:function(func){var tuples=[["resolve","done",jQuery.Callbacks("once memory"),"resolved"],["reject","fail",jQuery.Callbacks("once memory"),"rejected"],["notify","progress",jQuery.Callbacks("memory")]],state="pending",promise={state:function(){return state},always:function(){deferred.done(arguments).fail(arguments)
return this},then:function(){var fns=arguments
return jQuery.Deferred(function(newDefer){jQuery.each(tuples,function(i,tuple){var action=tuple[0],fn=jQuery.isFunction(fns[i])&&fns[i]
deferred[tuple[1]](function(){var returned=fn&&fn.apply(this,arguments)
returned&&jQuery.isFunction(returned.promise)?returned.promise().done(newDefer.resolve).fail(newDefer.reject).progress(newDefer.notify):newDefer[action+"With"](this===promise?newDefer.promise():this,fn?[returned]:arguments)})})
fns=null}).promise()},promise:function(obj){return null!=obj?jQuery.extend(obj,promise):promise}},deferred={}
promise.pipe=promise.then
jQuery.each(tuples,function(i,tuple){var list=tuple[2],stateString=tuple[3]
promise[tuple[1]]=list.add
stateString&&list.add(function(){state=stateString},tuples[1^i][2].disable,tuples[2][2].lock)
deferred[tuple[0]]=function(){deferred[tuple[0]+"With"](this===deferred?promise:this,arguments)
return this}
deferred[tuple[0]+"With"]=list.fireWith})
promise.promise(deferred)
func&&func.call(deferred,deferred)
return deferred},when:function(subordinate){var progressValues,progressContexts,resolveContexts,i=0,resolveValues=core_slice.call(arguments),length=resolveValues.length,remaining=1!==length||subordinate&&jQuery.isFunction(subordinate.promise)?length:0,deferred=1===remaining?subordinate:jQuery.Deferred(),updateFunc=function(i,contexts,values){return function(value){contexts[i]=this
values[i]=arguments.length>1?core_slice.call(arguments):value
values===progressValues?deferred.notifyWith(contexts,values):--remaining||deferred.resolveWith(contexts,values)}}
if(length>1){progressValues=new Array(length)
progressContexts=new Array(length)
resolveContexts=new Array(length)
for(;length>i;i++)resolveValues[i]&&jQuery.isFunction(resolveValues[i].promise)?resolveValues[i].promise().done(updateFunc(i,resolveContexts,resolveValues)).fail(deferred.reject).progress(updateFunc(i,progressContexts,progressValues)):--remaining}remaining||deferred.resolveWith(resolveContexts,resolveValues)
return deferred.promise()}})
jQuery.support=function(){var support,all,a,input,select,fragment,opt,eventName,isSupported,i,div=document.createElement("div")
div.setAttribute("className","t")
div.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>"
all=div.getElementsByTagName("*")
a=div.getElementsByTagName("a")[0]
if(!all||!a||!all.length)return{}
select=document.createElement("select")
opt=select.appendChild(document.createElement("option"))
input=div.getElementsByTagName("input")[0]
a.style.cssText="top:1px;float:left;opacity:.5"
support={getSetAttribute:"t"!==div.className,leadingWhitespace:3===div.firstChild.nodeType,tbody:!div.getElementsByTagName("tbody").length,htmlSerialize:!!div.getElementsByTagName("link").length,style:/top/.test(a.getAttribute("style")),hrefNormalized:"/a"===a.getAttribute("href"),opacity:/^0.5/.test(a.style.opacity),cssFloat:!!a.style.cssFloat,checkOn:!!input.value,optSelected:opt.selected,enctype:!!document.createElement("form").enctype,html5Clone:"<:nav></:nav>"!==document.createElement("nav").cloneNode(!0).outerHTML,boxModel:"CSS1Compat"===document.compatMode,deleteExpando:!0,noCloneEvent:!0,inlineBlockNeedsLayout:!1,shrinkWrapBlocks:!1,reliableMarginRight:!0,boxSizingReliable:!0,pixelPosition:!1}
input.checked=!0
support.noCloneChecked=input.cloneNode(!0).checked
select.disabled=!0
support.optDisabled=!opt.disabled
try{delete div.test}catch(e){support.deleteExpando=!1}input=document.createElement("input")
input.setAttribute("value","")
support.input=""===input.getAttribute("value")
input.value="t"
input.setAttribute("type","radio")
support.radioValue="t"===input.value
input.setAttribute("checked","t")
input.setAttribute("name","t")
fragment=document.createDocumentFragment()
fragment.appendChild(input)
support.appendChecked=input.checked
support.checkClone=fragment.cloneNode(!0).cloneNode(!0).lastChild.checked
if(div.attachEvent){div.attachEvent("onclick",function(){support.noCloneEvent=!1})
div.cloneNode(!0).click()}for(i in{submit:!0,change:!0,focusin:!0}){div.setAttribute(eventName="on"+i,"t")
support[i+"Bubbles"]=eventName in window||div.attributes[eventName].expando===!1}div.style.backgroundClip="content-box"
div.cloneNode(!0).style.backgroundClip=""
support.clearCloneStyle="content-box"===div.style.backgroundClip
jQuery(function(){var container,marginDiv,tds,divReset="padding:0;margin:0;border:0;display:block;box-sizing:content-box;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;",body=document.getElementsByTagName("body")[0]
if(body){container=document.createElement("div")
container.style.cssText="border:0;width:0;height:0;position:absolute;top:0;left:-9999px;margin-top:1px"
body.appendChild(container).appendChild(div)
div.innerHTML="<table><tr><td></td><td>t</td></tr></table>"
tds=div.getElementsByTagName("td")
tds[0].style.cssText="padding:0;margin:0;border:0;display:none"
isSupported=0===tds[0].offsetHeight
tds[0].style.display=""
tds[1].style.display="none"
support.reliableHiddenOffsets=isSupported&&0===tds[0].offsetHeight
div.innerHTML=""
div.style.cssText="box-sizing:border-box;-moz-box-sizing:border-box;-webkit-box-sizing:border-box;padding:1px;border:1px;display:block;width:4px;margin-top:1%;position:absolute;top:1%;"
support.boxSizing=4===div.offsetWidth
support.doesNotIncludeMarginInBodyOffset=1!==body.offsetTop
if(window.getComputedStyle){support.pixelPosition="1%"!==(window.getComputedStyle(div,null)||{}).top
support.boxSizingReliable="4px"===(window.getComputedStyle(div,null)||{width:"4px"}).width
marginDiv=div.appendChild(document.createElement("div"))
marginDiv.style.cssText=div.style.cssText=divReset
marginDiv.style.marginRight=marginDiv.style.width="0"
div.style.width="1px"
support.reliableMarginRight=!parseFloat((window.getComputedStyle(marginDiv,null)||{}).marginRight)}if(typeof div.style.zoom!==core_strundefined){div.innerHTML=""
div.style.cssText=divReset+"width:1px;padding:1px;display:inline;zoom:1"
support.inlineBlockNeedsLayout=3===div.offsetWidth
div.style.display="block"
div.innerHTML="<div></div>"
div.firstChild.style.width="5px"
support.shrinkWrapBlocks=3!==div.offsetWidth
support.inlineBlockNeedsLayout&&(body.style.zoom=1)}body.removeChild(container)
container=div=tds=marginDiv=null}})
all=select=fragment=opt=a=input=null
return support}()
var rbrace=/(?:\{[\s\S]*\}|\[[\s\S]*\])$/,rmultiDash=/([A-Z])/g
jQuery.extend({cache:{},expando:"jQuery"+(core_version+Math.random()).replace(/\D/g,""),noData:{embed:!0,object:"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000",applet:!0},hasData:function(elem){elem=elem.nodeType?jQuery.cache[elem[jQuery.expando]]:elem[jQuery.expando]
return!!elem&&!isEmptyDataObject(elem)},data:function(elem,name,data){return internalData(elem,name,data)},removeData:function(elem,name){return internalRemoveData(elem,name)},_data:function(elem,name,data){return internalData(elem,name,data,!0)},_removeData:function(elem,name){return internalRemoveData(elem,name,!0)},acceptData:function(elem){if(elem.nodeType&&1!==elem.nodeType&&9!==elem.nodeType)return!1
var noData=elem.nodeName&&jQuery.noData[elem.nodeName.toLowerCase()]
return!noData||noData!==!0&&elem.getAttribute("classid")===noData}})
jQuery.fn.extend({data:function(key,value){var attrs,name,elem=this[0],i=0,data=null
if(key===undefined){if(this.length){data=jQuery.data(elem)
if(1===elem.nodeType&&!jQuery._data(elem,"parsedAttrs")){attrs=elem.attributes
for(;i<attrs.length;i++){name=attrs[i].name
if(!name.indexOf("data-")){name=jQuery.camelCase(name.slice(5))
dataAttr(elem,name,data[name])}}jQuery._data(elem,"parsedAttrs",!0)}}return data}return"object"==typeof key?this.each(function(){jQuery.data(this,key)}):jQuery.access(this,function(value){if(value===undefined)return elem?dataAttr(elem,key,jQuery.data(elem,key)):null
this.each(function(){jQuery.data(this,key,value)})
return void 0},null,value,arguments.length>1,null,!0)},removeData:function(key){return this.each(function(){jQuery.removeData(this,key)})}})
jQuery.extend({queue:function(elem,type,data){var queue
if(elem){type=(type||"fx")+"queue"
queue=jQuery._data(elem,type)
data&&(!queue||jQuery.isArray(data)?queue=jQuery._data(elem,type,jQuery.makeArray(data)):queue.push(data))
return queue||[]}},dequeue:function(elem,type){type=type||"fx"
var queue=jQuery.queue(elem,type),startLength=queue.length,fn=queue.shift(),hooks=jQuery._queueHooks(elem,type),next=function(){jQuery.dequeue(elem,type)}
if("inprogress"===fn){fn=queue.shift()
startLength--}hooks.cur=fn
if(fn){"fx"===type&&queue.unshift("inprogress")
delete hooks.stop
fn.call(elem,next,hooks)}!startLength&&hooks&&hooks.empty.fire()},_queueHooks:function(elem,type){var key=type+"queueHooks"
return jQuery._data(elem,key)||jQuery._data(elem,key,{empty:jQuery.Callbacks("once memory").add(function(){jQuery._removeData(elem,type+"queue")
jQuery._removeData(elem,key)})})}})
jQuery.fn.extend({queue:function(type,data){var setter=2
if("string"!=typeof type){data=type
type="fx"
setter--}return arguments.length<setter?jQuery.queue(this[0],type):data===undefined?this:this.each(function(){var queue=jQuery.queue(this,type,data)
jQuery._queueHooks(this,type)
"fx"===type&&"inprogress"!==queue[0]&&jQuery.dequeue(this,type)})},dequeue:function(type){return this.each(function(){jQuery.dequeue(this,type)})},delay:function(time,type){time=jQuery.fx?jQuery.fx.speeds[time]||time:time
type=type||"fx"
return this.queue(type,function(next,hooks){var timeout=setTimeout(next,time)
hooks.stop=function(){clearTimeout(timeout)}})},clearQueue:function(type){return this.queue(type||"fx",[])},promise:function(type,obj){var tmp,count=1,defer=jQuery.Deferred(),elements=this,i=this.length,resolve=function(){--count||defer.resolveWith(elements,[elements])}
if("string"!=typeof type){obj=type
type=undefined}type=type||"fx"
for(;i--;){tmp=jQuery._data(elements[i],type+"queueHooks")
if(tmp&&tmp.empty){count++
tmp.empty.add(resolve)}}resolve()
return defer.promise(obj)}})
var nodeHook,boolHook,rclass=/[\t\r\n]/g,rreturn=/\r/g,rfocusable=/^(?:input|select|textarea|button|object)$/i,rclickable=/^(?:a|area)$/i,rboolean=/^(?:checked|selected|autofocus|autoplay|async|controls|defer|disabled|hidden|loop|multiple|open|readonly|required|scoped)$/i,ruseDefault=/^(?:checked|selected)$/i,getSetAttribute=jQuery.support.getSetAttribute,getSetInput=jQuery.support.input
jQuery.fn.extend({attr:function(name,value){return jQuery.access(this,jQuery.attr,name,value,arguments.length>1)},removeAttr:function(name){return this.each(function(){jQuery.removeAttr(this,name)})},prop:function(name,value){return jQuery.access(this,jQuery.prop,name,value,arguments.length>1)},removeProp:function(name){name=jQuery.propFix[name]||name
return this.each(function(){try{this[name]=undefined
delete this[name]}catch(e){}})},addClass:function(value){var classes,elem,cur,clazz,j,i=0,len=this.length,proceed="string"==typeof value&&value
if(jQuery.isFunction(value))return this.each(function(j){jQuery(this).addClass(value.call(this,j,this.className))})
if(proceed){classes=(value||"").match(core_rnotwhite)||[]
for(;len>i;i++){elem=this[i]
cur=1===elem.nodeType&&(elem.className?(" "+elem.className+" ").replace(rclass," "):" ")
if(cur){j=0
for(;clazz=classes[j++];)cur.indexOf(" "+clazz+" ")<0&&(cur+=clazz+" ")
elem.className=jQuery.trim(cur)}}}return this},removeClass:function(value){var classes,elem,cur,clazz,j,i=0,len=this.length,proceed=0===arguments.length||"string"==typeof value&&value
if(jQuery.isFunction(value))return this.each(function(j){jQuery(this).removeClass(value.call(this,j,this.className))})
if(proceed){classes=(value||"").match(core_rnotwhite)||[]
for(;len>i;i++){elem=this[i]
cur=1===elem.nodeType&&(elem.className?(" "+elem.className+" ").replace(rclass," "):"")
if(cur){j=0
for(;clazz=classes[j++];)for(;cur.indexOf(" "+clazz+" ")>=0;)cur=cur.replace(" "+clazz+" "," ")
elem.className=value?jQuery.trim(cur):""}}}return this},toggleClass:function(value,stateVal){var type=typeof value,isBool="boolean"==typeof stateVal
return jQuery.isFunction(value)?this.each(function(i){jQuery(this).toggleClass(value.call(this,i,this.className,stateVal),stateVal)}):this.each(function(){if("string"===type)for(var className,i=0,self=jQuery(this),state=stateVal,classNames=value.match(core_rnotwhite)||[];className=classNames[i++];){state=isBool?state:!self.hasClass(className)
self[state?"addClass":"removeClass"](className)}else if(type===core_strundefined||"boolean"===type){this.className&&jQuery._data(this,"__className__",this.className)
this.className=this.className||value===!1?"":jQuery._data(this,"__className__")||""}})},hasClass:function(selector){for(var className=" "+selector+" ",i=0,l=this.length;l>i;i++)if(1===this[i].nodeType&&(" "+this[i].className+" ").replace(rclass," ").indexOf(className)>=0)return!0
return!1},val:function(value){var ret,hooks,isFunction,elem=this[0]
if(arguments.length){isFunction=jQuery.isFunction(value)
return this.each(function(i){var val,self=jQuery(this)
if(1===this.nodeType){val=isFunction?value.call(this,i,self.val()):value
null==val?val="":"number"==typeof val?val+="":jQuery.isArray(val)&&(val=jQuery.map(val,function(value){return null==value?"":value+""}))
hooks=jQuery.valHooks[this.type]||jQuery.valHooks[this.nodeName.toLowerCase()]
hooks&&"set"in hooks&&hooks.set(this,val,"value")!==undefined||(this.value=val)}})}if(elem){hooks=jQuery.valHooks[elem.type]||jQuery.valHooks[elem.nodeName.toLowerCase()]
if(hooks&&"get"in hooks&&(ret=hooks.get(elem,"value"))!==undefined)return ret
ret=elem.value
return"string"==typeof ret?ret.replace(rreturn,""):null==ret?"":ret}}})
jQuery.extend({valHooks:{option:{get:function(elem){var val=elem.attributes.value
return!val||val.specified?elem.value:elem.text}},select:{get:function(elem){for(var value,option,options=elem.options,index=elem.selectedIndex,one="select-one"===elem.type||0>index,values=one?null:[],max=one?index+1:options.length,i=0>index?max:one?index:0;max>i;i++){option=options[i]
if(!(!option.selected&&i!==index||(jQuery.support.optDisabled?option.disabled:null!==option.getAttribute("disabled"))||option.parentNode.disabled&&jQuery.nodeName(option.parentNode,"optgroup"))){value=jQuery(option).val()
if(one)return value
values.push(value)}}return values},set:function(elem,value){var values=jQuery.makeArray(value)
jQuery(elem).find("option").each(function(){this.selected=jQuery.inArray(jQuery(this).val(),values)>=0})
values.length||(elem.selectedIndex=-1)
return values}}},attr:function(elem,name,value){var hooks,notxml,ret,nType=elem.nodeType
if(elem&&3!==nType&&8!==nType&&2!==nType){if(typeof elem.getAttribute===core_strundefined)return jQuery.prop(elem,name,value)
notxml=1!==nType||!jQuery.isXMLDoc(elem)
if(notxml){name=name.toLowerCase()
hooks=jQuery.attrHooks[name]||(rboolean.test(name)?boolHook:nodeHook)}if(value===undefined){if(hooks&&notxml&&"get"in hooks&&null!==(ret=hooks.get(elem,name)))return ret
typeof elem.getAttribute!==core_strundefined&&(ret=elem.getAttribute(name))
return null==ret?undefined:ret}if(null!==value){if(hooks&&notxml&&"set"in hooks&&(ret=hooks.set(elem,value,name))!==undefined)return ret
elem.setAttribute(name,value+"")
return value}jQuery.removeAttr(elem,name)}},removeAttr:function(elem,value){var name,propName,i=0,attrNames=value&&value.match(core_rnotwhite)
if(attrNames&&1===elem.nodeType)for(;name=attrNames[i++];){propName=jQuery.propFix[name]||name
rboolean.test(name)?!getSetAttribute&&ruseDefault.test(name)?elem[jQuery.camelCase("default-"+name)]=elem[propName]=!1:elem[propName]=!1:jQuery.attr(elem,name,"")
elem.removeAttribute(getSetAttribute?name:propName)}},attrHooks:{type:{set:function(elem,value){if(!jQuery.support.radioValue&&"radio"===value&&jQuery.nodeName(elem,"input")){var val=elem.value
elem.setAttribute("type",value)
val&&(elem.value=val)
return value}}}},propFix:{tabindex:"tabIndex",readonly:"readOnly","for":"htmlFor","class":"className",maxlength:"maxLength",cellspacing:"cellSpacing",cellpadding:"cellPadding",rowspan:"rowSpan",colspan:"colSpan",usemap:"useMap",frameborder:"frameBorder",contenteditable:"contentEditable"},prop:function(elem,name,value){var ret,hooks,notxml,nType=elem.nodeType
if(elem&&3!==nType&&8!==nType&&2!==nType){notxml=1!==nType||!jQuery.isXMLDoc(elem)
if(notxml){name=jQuery.propFix[name]||name
hooks=jQuery.propHooks[name]}return value!==undefined?hooks&&"set"in hooks&&(ret=hooks.set(elem,value,name))!==undefined?ret:elem[name]=value:hooks&&"get"in hooks&&null!==(ret=hooks.get(elem,name))?ret:elem[name]}},propHooks:{tabIndex:{get:function(elem){var attributeNode=elem.getAttributeNode("tabindex")
return attributeNode&&attributeNode.specified?parseInt(attributeNode.value,10):rfocusable.test(elem.nodeName)||rclickable.test(elem.nodeName)&&elem.href?0:undefined}}}})
boolHook={get:function(elem,name){var prop=jQuery.prop(elem,name),attr="boolean"==typeof prop&&elem.getAttribute(name),detail="boolean"==typeof prop?getSetInput&&getSetAttribute?null!=attr:ruseDefault.test(name)?elem[jQuery.camelCase("default-"+name)]:!!attr:elem.getAttributeNode(name)
return detail&&detail.value!==!1?name.toLowerCase():undefined},set:function(elem,value,name){value===!1?jQuery.removeAttr(elem,name):getSetInput&&getSetAttribute||!ruseDefault.test(name)?elem.setAttribute(!getSetAttribute&&jQuery.propFix[name]||name,name):elem[jQuery.camelCase("default-"+name)]=elem[name]=!0
return name}}
getSetInput&&getSetAttribute||(jQuery.attrHooks.value={get:function(elem,name){var ret=elem.getAttributeNode(name)
return jQuery.nodeName(elem,"input")?elem.defaultValue:ret&&ret.specified?ret.value:undefined},set:function(elem,value,name){if(!jQuery.nodeName(elem,"input"))return nodeHook&&nodeHook.set(elem,value,name)
elem.defaultValue=value
return void 0}})
if(!getSetAttribute){nodeHook=jQuery.valHooks.button={get:function(elem,name){var ret=elem.getAttributeNode(name)
return ret&&("id"===name||"name"===name||"coords"===name?""!==ret.value:ret.specified)?ret.value:undefined},set:function(elem,value,name){var ret=elem.getAttributeNode(name)
ret||elem.setAttributeNode(ret=elem.ownerDocument.createAttribute(name))
ret.value=value+=""
return"value"===name||value===elem.getAttribute(name)?value:undefined}}
jQuery.attrHooks.contenteditable={get:nodeHook.get,set:function(elem,value,name){nodeHook.set(elem,""===value?!1:value,name)}}
jQuery.each(["width","height"],function(i,name){jQuery.attrHooks[name]=jQuery.extend(jQuery.attrHooks[name],{set:function(elem,value){if(""===value){elem.setAttribute(name,"auto")
return value}}})})}if(!jQuery.support.hrefNormalized){jQuery.each(["href","src","width","height"],function(i,name){jQuery.attrHooks[name]=jQuery.extend(jQuery.attrHooks[name],{get:function(elem){var ret=elem.getAttribute(name,2)
return null==ret?undefined:ret}})})
jQuery.each(["href","src"],function(i,name){jQuery.propHooks[name]={get:function(elem){return elem.getAttribute(name,4)}}})}jQuery.support.style||(jQuery.attrHooks.style={get:function(elem){return elem.style.cssText||undefined},set:function(elem,value){return elem.style.cssText=value+""}})
jQuery.support.optSelected||(jQuery.propHooks.selected=jQuery.extend(jQuery.propHooks.selected,{get:function(elem){var parent=elem.parentNode
if(parent){parent.selectedIndex
parent.parentNode&&parent.parentNode.selectedIndex}return null}}))
jQuery.support.enctype||(jQuery.propFix.enctype="encoding")
jQuery.support.checkOn||jQuery.each(["radio","checkbox"],function(){jQuery.valHooks[this]={get:function(elem){return null===elem.getAttribute("value")?"on":elem.value}}})
jQuery.each(["radio","checkbox"],function(){jQuery.valHooks[this]=jQuery.extend(jQuery.valHooks[this],{set:function(elem,value){return jQuery.isArray(value)?elem.checked=jQuery.inArray(jQuery(elem).val(),value)>=0:void 0}})})
var rformElems=/^(?:input|select|textarea)$/i,rkeyEvent=/^key/,rmouseEvent=/^(?:mouse|contextmenu)|click/,rfocusMorph=/^(?:focusinfocus|focusoutblur)$/,rtypenamespace=/^([^.]*)(?:\.(.+)|)$/
jQuery.event={global:{},add:function(elem,types,handler,data,selector){var tmp,events,t,handleObjIn,special,eventHandle,handleObj,handlers,type,namespaces,origType,elemData=jQuery._data(elem)
if(elemData){if(handler.handler){handleObjIn=handler
handler=handleObjIn.handler
selector=handleObjIn.selector}handler.guid||(handler.guid=jQuery.guid++);(events=elemData.events)||(events=elemData.events={})
if(!(eventHandle=elemData.handle)){eventHandle=elemData.handle=function(e){return typeof jQuery===core_strundefined||e&&jQuery.event.triggered===e.type?undefined:jQuery.event.dispatch.apply(eventHandle.elem,arguments)}
eventHandle.elem=elem}types=(types||"").match(core_rnotwhite)||[""]
t=types.length
for(;t--;){tmp=rtypenamespace.exec(types[t])||[]
type=origType=tmp[1]
namespaces=(tmp[2]||"").split(".").sort()
special=jQuery.event.special[type]||{}
type=(selector?special.delegateType:special.bindType)||type
special=jQuery.event.special[type]||{}
handleObj=jQuery.extend({type:type,origType:origType,data:data,handler:handler,guid:handler.guid,selector:selector,needsContext:selector&&jQuery.expr.match.needsContext.test(selector),namespace:namespaces.join(".")},handleObjIn)
if(!(handlers=events[type])){handlers=events[type]=[]
handlers.delegateCount=0
special.setup&&special.setup.call(elem,data,namespaces,eventHandle)!==!1||(elem.addEventListener?elem.addEventListener(type,eventHandle,!1):elem.attachEvent&&elem.attachEvent("on"+type,eventHandle))}if(special.add){special.add.call(elem,handleObj)
handleObj.handler.guid||(handleObj.handler.guid=handler.guid)}selector?handlers.splice(handlers.delegateCount++,0,handleObj):handlers.push(handleObj)
jQuery.event.global[type]=!0}elem=null}},remove:function(elem,types,handler,selector,mappedTypes){var j,handleObj,tmp,origCount,t,events,special,handlers,type,namespaces,origType,elemData=jQuery.hasData(elem)&&jQuery._data(elem)
if(elemData&&(events=elemData.events)){types=(types||"").match(core_rnotwhite)||[""]
t=types.length
for(;t--;){tmp=rtypenamespace.exec(types[t])||[]
type=origType=tmp[1]
namespaces=(tmp[2]||"").split(".").sort()
if(type){special=jQuery.event.special[type]||{}
type=(selector?special.delegateType:special.bindType)||type
handlers=events[type]||[]
tmp=tmp[2]&&new RegExp("(^|\\.)"+namespaces.join("\\.(?:.*\\.|)")+"(\\.|$)")
origCount=j=handlers.length
for(;j--;){handleObj=handlers[j]
if(!(!mappedTypes&&origType!==handleObj.origType||handler&&handler.guid!==handleObj.guid||tmp&&!tmp.test(handleObj.namespace)||selector&&selector!==handleObj.selector&&("**"!==selector||!handleObj.selector))){handlers.splice(j,1)
handleObj.selector&&handlers.delegateCount--
special.remove&&special.remove.call(elem,handleObj)}}if(origCount&&!handlers.length){special.teardown&&special.teardown.call(elem,namespaces,elemData.handle)!==!1||jQuery.removeEvent(elem,type,elemData.handle)
delete events[type]}}else for(type in events)jQuery.event.remove(elem,type+types[t],handler,selector,!0)}if(jQuery.isEmptyObject(events)){delete elemData.handle
jQuery._removeData(elem,"events")}}},trigger:function(event,data,elem,onlyHandlers){var handle,ontype,cur,bubbleType,special,tmp,i,eventPath=[elem||document],type=core_hasOwn.call(event,"type")?event.type:event,namespaces=core_hasOwn.call(event,"namespace")?event.namespace.split("."):[]
cur=tmp=elem=elem||document
if(3!==elem.nodeType&&8!==elem.nodeType&&!rfocusMorph.test(type+jQuery.event.triggered)){if(type.indexOf(".")>=0){namespaces=type.split(".")
type=namespaces.shift()
namespaces.sort()}ontype=type.indexOf(":")<0&&"on"+type
event=event[jQuery.expando]?event:new jQuery.Event(type,"object"==typeof event&&event)
event.isTrigger=!0
event.namespace=namespaces.join(".")
event.namespace_re=event.namespace?new RegExp("(^|\\.)"+namespaces.join("\\.(?:.*\\.|)")+"(\\.|$)"):null
event.result=undefined
event.target||(event.target=elem)
data=null==data?[event]:jQuery.makeArray(data,[event])
special=jQuery.event.special[type]||{}
if(onlyHandlers||!special.trigger||special.trigger.apply(elem,data)!==!1){if(!onlyHandlers&&!special.noBubble&&!jQuery.isWindow(elem)){bubbleType=special.delegateType||type
rfocusMorph.test(bubbleType+type)||(cur=cur.parentNode)
for(;cur;cur=cur.parentNode){eventPath.push(cur)
tmp=cur}tmp===(elem.ownerDocument||document)&&eventPath.push(tmp.defaultView||tmp.parentWindow||window)}i=0
for(;(cur=eventPath[i++])&&!event.isPropagationStopped();){event.type=i>1?bubbleType:special.bindType||type
handle=(jQuery._data(cur,"events")||{})[event.type]&&jQuery._data(cur,"handle")
handle&&handle.apply(cur,data)
handle=ontype&&cur[ontype]
handle&&jQuery.acceptData(cur)&&handle.apply&&handle.apply(cur,data)===!1&&event.preventDefault()}event.type=type
if(!(onlyHandlers||event.isDefaultPrevented()||special._default&&special._default.apply(elem.ownerDocument,data)!==!1||"click"===type&&jQuery.nodeName(elem,"a")||!jQuery.acceptData(elem)||!ontype||!elem[type]||jQuery.isWindow(elem))){tmp=elem[ontype]
tmp&&(elem[ontype]=null)
jQuery.event.triggered=type
try{elem[type]()}catch(e){}jQuery.event.triggered=undefined
tmp&&(elem[ontype]=tmp)}return event.result}}},dispatch:function(event){event=jQuery.event.fix(event)
var i,ret,handleObj,matched,j,handlerQueue=[],args=core_slice.call(arguments),handlers=(jQuery._data(this,"events")||{})[event.type]||[],special=jQuery.event.special[event.type]||{}
args[0]=event
event.delegateTarget=this
if(!special.preDispatch||special.preDispatch.call(this,event)!==!1){handlerQueue=jQuery.event.handlers.call(this,event,handlers)
i=0
for(;(matched=handlerQueue[i++])&&!event.isPropagationStopped();){event.currentTarget=matched.elem
j=0
for(;(handleObj=matched.handlers[j++])&&!event.isImmediatePropagationStopped();)if(!event.namespace_re||event.namespace_re.test(handleObj.namespace)){event.handleObj=handleObj
event.data=handleObj.data
ret=((jQuery.event.special[handleObj.origType]||{}).handle||handleObj.handler).apply(matched.elem,args)
if(ret!==undefined&&(event.result=ret)===!1){event.preventDefault()
event.stopPropagation()}}}special.postDispatch&&special.postDispatch.call(this,event)
return event.result}},handlers:function(event,handlers){var sel,handleObj,matches,i,handlerQueue=[],delegateCount=handlers.delegateCount,cur=event.target
if(delegateCount&&cur.nodeType&&(!event.button||"click"!==event.type))for(;cur!=this;cur=cur.parentNode||this)if(1===cur.nodeType&&(cur.disabled!==!0||"click"!==event.type)){matches=[]
for(i=0;delegateCount>i;i++){handleObj=handlers[i]
sel=handleObj.selector+" "
matches[sel]===undefined&&(matches[sel]=handleObj.needsContext?jQuery(sel,this).index(cur)>=0:jQuery.find(sel,this,null,[cur]).length)
matches[sel]&&matches.push(handleObj)}matches.length&&handlerQueue.push({elem:cur,handlers:matches})}delegateCount<handlers.length&&handlerQueue.push({elem:this,handlers:handlers.slice(delegateCount)})
return handlerQueue},fix:function(event){if(event[jQuery.expando])return event
var i,prop,copy,type=event.type,originalEvent=event,fixHook=this.fixHooks[type]
fixHook||(this.fixHooks[type]=fixHook=rmouseEvent.test(type)?this.mouseHooks:rkeyEvent.test(type)?this.keyHooks:{})
copy=fixHook.props?this.props.concat(fixHook.props):this.props
event=new jQuery.Event(originalEvent)
i=copy.length
for(;i--;){prop=copy[i]
event[prop]=originalEvent[prop]}event.target||(event.target=originalEvent.srcElement||document)
3===event.target.nodeType&&(event.target=event.target.parentNode)
event.metaKey=!!event.metaKey
return fixHook.filter?fixHook.filter(event,originalEvent):event},props:"altKey bubbles cancelable ctrlKey currentTarget eventPhase metaKey relatedTarget shiftKey target timeStamp view which".split(" "),fixHooks:{},keyHooks:{props:"char charCode key keyCode".split(" "),filter:function(event,original){null==event.which&&(event.which=null!=original.charCode?original.charCode:original.keyCode)
return event}},mouseHooks:{props:"button buttons clientX clientY fromElement offsetX offsetY pageX pageY screenX screenY toElement".split(" "),filter:function(event,original){var body,eventDoc,doc,button=original.button,fromElement=original.fromElement
if(null==event.pageX&&null!=original.clientX){eventDoc=event.target.ownerDocument||document
doc=eventDoc.documentElement
body=eventDoc.body
event.pageX=original.clientX+(doc&&doc.scrollLeft||body&&body.scrollLeft||0)-(doc&&doc.clientLeft||body&&body.clientLeft||0)
event.pageY=original.clientY+(doc&&doc.scrollTop||body&&body.scrollTop||0)-(doc&&doc.clientTop||body&&body.clientTop||0)}!event.relatedTarget&&fromElement&&(event.relatedTarget=fromElement===event.target?original.toElement:fromElement)
event.which||button===undefined||(event.which=1&button?1:2&button?3:4&button?2:0)
return event}},special:{load:{noBubble:!0},click:{trigger:function(){if(jQuery.nodeName(this,"input")&&"checkbox"===this.type&&this.click){this.click()
return!1}}},focus:{trigger:function(){if(this!==document.activeElement&&this.focus)try{this.focus()
return!1}catch(e){}},delegateType:"focusin"},blur:{trigger:function(){if(this===document.activeElement&&this.blur){this.blur()
return!1}},delegateType:"focusout"},beforeunload:{postDispatch:function(event){event.result!==undefined&&(event.originalEvent.returnValue=event.result)}}},simulate:function(type,elem,event,bubble){var e=jQuery.extend(new jQuery.Event,event,{type:type,isSimulated:!0,originalEvent:{}})
bubble?jQuery.event.trigger(e,null,elem):jQuery.event.dispatch.call(elem,e)
e.isDefaultPrevented()&&event.preventDefault()}}
jQuery.removeEvent=document.removeEventListener?function(elem,type,handle){elem.removeEventListener&&elem.removeEventListener(type,handle,!1)}:function(elem,type,handle){var name="on"+type
if(elem.detachEvent){typeof elem[name]===core_strundefined&&(elem[name]=null)
elem.detachEvent(name,handle)}}
jQuery.Event=function(src,props){if(!(this instanceof jQuery.Event))return new jQuery.Event(src,props)
if(src&&src.type){this.originalEvent=src
this.type=src.type
this.isDefaultPrevented=src.defaultPrevented||src.returnValue===!1||src.getPreventDefault&&src.getPreventDefault()?returnTrue:returnFalse}else this.type=src
props&&jQuery.extend(this,props)
this.timeStamp=src&&src.timeStamp||jQuery.now()
this[jQuery.expando]=!0}
jQuery.Event.prototype={isDefaultPrevented:returnFalse,isPropagationStopped:returnFalse,isImmediatePropagationStopped:returnFalse,preventDefault:function(){var e=this.originalEvent
this.isDefaultPrevented=returnTrue
e&&(e.preventDefault?e.preventDefault():e.returnValue=!1)},stopPropagation:function(){var e=this.originalEvent
this.isPropagationStopped=returnTrue
if(e){e.stopPropagation&&e.stopPropagation()
e.cancelBubble=!0}},stopImmediatePropagation:function(){this.isImmediatePropagationStopped=returnTrue
this.stopPropagation()}}
jQuery.each({mouseenter:"mouseover",mouseleave:"mouseout"},function(orig,fix){jQuery.event.special[orig]={delegateType:fix,bindType:fix,handle:function(event){var ret,target=this,related=event.relatedTarget,handleObj=event.handleObj
if(!related||related!==target&&!jQuery.contains(target,related)){event.type=handleObj.origType
ret=handleObj.handler.apply(this,arguments)
event.type=fix}return ret}}})
jQuery.support.submitBubbles||(jQuery.event.special.submit={setup:function(){if(jQuery.nodeName(this,"form"))return!1
jQuery.event.add(this,"click._submit keypress._submit",function(e){var elem=e.target,form=jQuery.nodeName(elem,"input")||jQuery.nodeName(elem,"button")?elem.form:undefined
if(form&&!jQuery._data(form,"submitBubbles")){jQuery.event.add(form,"submit._submit",function(event){event._submit_bubble=!0})
jQuery._data(form,"submitBubbles",!0)}})
return void 0},postDispatch:function(event){if(event._submit_bubble){delete event._submit_bubble
this.parentNode&&!event.isTrigger&&jQuery.event.simulate("submit",this.parentNode,event,!0)}},teardown:function(){if(jQuery.nodeName(this,"form"))return!1
jQuery.event.remove(this,"._submit")
return void 0}})
jQuery.support.changeBubbles||(jQuery.event.special.change={setup:function(){if(rformElems.test(this.nodeName)){if("checkbox"===this.type||"radio"===this.type){jQuery.event.add(this,"propertychange._change",function(event){"checked"===event.originalEvent.propertyName&&(this._just_changed=!0)})
jQuery.event.add(this,"click._change",function(event){this._just_changed&&!event.isTrigger&&(this._just_changed=!1)
jQuery.event.simulate("change",this,event,!0)})}return!1}jQuery.event.add(this,"beforeactivate._change",function(e){var elem=e.target
if(rformElems.test(elem.nodeName)&&!jQuery._data(elem,"changeBubbles")){jQuery.event.add(elem,"change._change",function(event){!this.parentNode||event.isSimulated||event.isTrigger||jQuery.event.simulate("change",this.parentNode,event,!0)})
jQuery._data(elem,"changeBubbles",!0)}})},handle:function(event){var elem=event.target
return this!==elem||event.isSimulated||event.isTrigger||"radio"!==elem.type&&"checkbox"!==elem.type?event.handleObj.handler.apply(this,arguments):void 0},teardown:function(){jQuery.event.remove(this,"._change")
return!rformElems.test(this.nodeName)}})
jQuery.support.focusinBubbles||jQuery.each({focus:"focusin",blur:"focusout"},function(orig,fix){var attaches=0,handler=function(event){jQuery.event.simulate(fix,event.target,jQuery.event.fix(event),!0)}
jQuery.event.special[fix]={setup:function(){0===attaches++&&document.addEventListener(orig,handler,!0)},teardown:function(){0===--attaches&&document.removeEventListener(orig,handler,!0)}}})
jQuery.fn.extend({on:function(types,selector,data,fn,one){var type,origFn
if("object"==typeof types){if("string"!=typeof selector){data=data||selector
selector=undefined}for(type in types)this.on(type,selector,data,types[type],one)
return this}if(null==data&&null==fn){fn=selector
data=selector=undefined}else if(null==fn)if("string"==typeof selector){fn=data
data=undefined}else{fn=data
data=selector
selector=undefined}if(fn===!1)fn=returnFalse
else if(!fn)return this
if(1===one){origFn=fn
fn=function(event){jQuery().off(event)
return origFn.apply(this,arguments)}
fn.guid=origFn.guid||(origFn.guid=jQuery.guid++)}return this.each(function(){jQuery.event.add(this,types,fn,data,selector)})},one:function(types,selector,data,fn){return this.on(types,selector,data,fn,1)},off:function(types,selector,fn){var handleObj,type
if(types&&types.preventDefault&&types.handleObj){handleObj=types.handleObj
jQuery(types.delegateTarget).off(handleObj.namespace?handleObj.origType+"."+handleObj.namespace:handleObj.origType,handleObj.selector,handleObj.handler)
return this}if("object"==typeof types){for(type in types)this.off(type,selector,types[type])
return this}if(selector===!1||"function"==typeof selector){fn=selector
selector=undefined}fn===!1&&(fn=returnFalse)
return this.each(function(){jQuery.event.remove(this,types,fn,selector)})},bind:function(types,data,fn){return this.on(types,null,data,fn)},unbind:function(types,fn){return this.off(types,null,fn)},delegate:function(selector,types,data,fn){return this.on(types,selector,data,fn)},undelegate:function(selector,types,fn){return 1===arguments.length?this.off(selector,"**"):this.off(types,selector||"**",fn)},trigger:function(type,data){return this.each(function(){jQuery.event.trigger(type,data,this)})},triggerHandler:function(type,data){var elem=this[0]
return elem?jQuery.event.trigger(type,data,elem,!0):void 0}})
!function(window,undefined){function isNative(fn){return rnative.test(fn+"")}function createCache(){var cache,keys=[]
return cache=function(key,value){keys.push(key+=" ")>Expr.cacheLength&&delete cache[keys.shift()]
return cache[key]=value}}function markFunction(fn){fn[expando]=!0
return fn}function assert(fn){var div=document.createElement("div")
try{return fn(div)}catch(e){return!1}finally{div=null}}function Sizzle(selector,context,results,seed){var match,elem,m,nodeType,i,groups,old,nid,newContext,newSelector;(context?context.ownerDocument||context:preferredDoc)!==document&&setDocument(context)
context=context||document
results=results||[]
if(!selector||"string"!=typeof selector)return results
if(1!==(nodeType=context.nodeType)&&9!==nodeType)return[]
if(!documentIsXML&&!seed){if(match=rquickExpr.exec(selector))if(m=match[1]){if(9===nodeType){elem=context.getElementById(m)
if(!elem||!elem.parentNode)return results
if(elem.id===m){results.push(elem)
return results}}else if(context.ownerDocument&&(elem=context.ownerDocument.getElementById(m))&&contains(context,elem)&&elem.id===m){results.push(elem)
return results}}else{if(match[2]){push.apply(results,slice.call(context.getElementsByTagName(selector),0))
return results}if((m=match[3])&&support.getByClassName&&context.getElementsByClassName){push.apply(results,slice.call(context.getElementsByClassName(m),0))
return results}}if(support.qsa&&!rbuggyQSA.test(selector)){old=!0
nid=expando
newContext=context
newSelector=9===nodeType&&selector
if(1===nodeType&&"object"!==context.nodeName.toLowerCase()){groups=tokenize(selector);(old=context.getAttribute("id"))?nid=old.replace(rescape,"\\$&"):context.setAttribute("id",nid)
nid="[id='"+nid+"'] "
i=groups.length
for(;i--;)groups[i]=nid+toSelector(groups[i])
newContext=rsibling.test(selector)&&context.parentNode||context
newSelector=groups.join(",")}if(newSelector)try{push.apply(results,slice.call(newContext.querySelectorAll(newSelector),0))
return results}catch(qsaError){}finally{old||context.removeAttribute("id")}}}return select(selector.replace(rtrim,"$1"),context,results,seed)}function siblingCheck(a,b){var cur=b&&a,diff=cur&&(~b.sourceIndex||MAX_NEGATIVE)-(~a.sourceIndex||MAX_NEGATIVE)
if(diff)return diff
if(cur)for(;cur=cur.nextSibling;)if(cur===b)return-1
return a?1:-1}function createInputPseudo(type){return function(elem){var name=elem.nodeName.toLowerCase()
return"input"===name&&elem.type===type}}function createButtonPseudo(type){return function(elem){var name=elem.nodeName.toLowerCase()
return("input"===name||"button"===name)&&elem.type===type}}function createPositionalPseudo(fn){return markFunction(function(argument){argument=+argument
return markFunction(function(seed,matches){for(var j,matchIndexes=fn([],seed.length,argument),i=matchIndexes.length;i--;)seed[j=matchIndexes[i]]&&(seed[j]=!(matches[j]=seed[j]))})})}function tokenize(selector,parseOnly){var matched,match,tokens,type,soFar,groups,preFilters,cached=tokenCache[selector+" "]
if(cached)return parseOnly?0:cached.slice(0)
soFar=selector
groups=[]
preFilters=Expr.preFilter
for(;soFar;){if(!matched||(match=rcomma.exec(soFar))){match&&(soFar=soFar.slice(match[0].length)||soFar)
groups.push(tokens=[])}matched=!1
if(match=rcombinators.exec(soFar)){matched=match.shift()
tokens.push({value:matched,type:match[0].replace(rtrim," ")})
soFar=soFar.slice(matched.length)}for(type in Expr.filter)if((match=matchExpr[type].exec(soFar))&&(!preFilters[type]||(match=preFilters[type](match)))){matched=match.shift()
tokens.push({value:matched,type:type,matches:match})
soFar=soFar.slice(matched.length)}if(!matched)break}return parseOnly?soFar.length:soFar?Sizzle.error(selector):tokenCache(selector,groups).slice(0)}function toSelector(tokens){for(var i=0,len=tokens.length,selector="";len>i;i++)selector+=tokens[i].value
return selector}function addCombinator(matcher,combinator,base){var dir=combinator.dir,checkNonElements=base&&"parentNode"===dir,doneName=done++
return combinator.first?function(elem,context,xml){for(;elem=elem[dir];)if(1===elem.nodeType||checkNonElements)return matcher(elem,context,xml)}:function(elem,context,xml){var data,cache,outerCache,dirkey=dirruns+" "+doneName
if(xml){for(;elem=elem[dir];)if((1===elem.nodeType||checkNonElements)&&matcher(elem,context,xml))return!0}else for(;elem=elem[dir];)if(1===elem.nodeType||checkNonElements){outerCache=elem[expando]||(elem[expando]={})
if((cache=outerCache[dir])&&cache[0]===dirkey){if((data=cache[1])===!0||data===cachedruns)return data===!0}else{cache=outerCache[dir]=[dirkey]
cache[1]=matcher(elem,context,xml)||cachedruns
if(cache[1]===!0)return!0}}}}function elementMatcher(matchers){return matchers.length>1?function(elem,context,xml){for(var i=matchers.length;i--;)if(!matchers[i](elem,context,xml))return!1
return!0}:matchers[0]}function condense(unmatched,map,filter,context,xml){for(var elem,newUnmatched=[],i=0,len=unmatched.length,mapped=null!=map;len>i;i++)if((elem=unmatched[i])&&(!filter||filter(elem,context,xml))){newUnmatched.push(elem)
mapped&&map.push(i)}return newUnmatched}function setMatcher(preFilter,selector,matcher,postFilter,postFinder,postSelector){postFilter&&!postFilter[expando]&&(postFilter=setMatcher(postFilter))
postFinder&&!postFinder[expando]&&(postFinder=setMatcher(postFinder,postSelector))
return markFunction(function(seed,results,context,xml){var temp,i,elem,preMap=[],postMap=[],preexisting=results.length,elems=seed||multipleContexts(selector||"*",context.nodeType?[context]:context,[]),matcherIn=!preFilter||!seed&&selector?elems:condense(elems,preMap,preFilter,context,xml),matcherOut=matcher?postFinder||(seed?preFilter:preexisting||postFilter)?[]:results:matcherIn
matcher&&matcher(matcherIn,matcherOut,context,xml)
if(postFilter){temp=condense(matcherOut,postMap)
postFilter(temp,[],context,xml)
i=temp.length
for(;i--;)(elem=temp[i])&&(matcherOut[postMap[i]]=!(matcherIn[postMap[i]]=elem))}if(seed){if(postFinder||preFilter){if(postFinder){temp=[]
i=matcherOut.length
for(;i--;)(elem=matcherOut[i])&&temp.push(matcherIn[i]=elem)
postFinder(null,matcherOut=[],temp,xml)}i=matcherOut.length
for(;i--;)(elem=matcherOut[i])&&(temp=postFinder?indexOf.call(seed,elem):preMap[i])>-1&&(seed[temp]=!(results[temp]=elem))}}else{matcherOut=condense(matcherOut===results?matcherOut.splice(preexisting,matcherOut.length):matcherOut)
postFinder?postFinder(null,results,matcherOut,xml):push.apply(results,matcherOut)}})}function matcherFromTokens(tokens){for(var checkContext,matcher,j,len=tokens.length,leadingRelative=Expr.relative[tokens[0].type],implicitRelative=leadingRelative||Expr.relative[" "],i=leadingRelative?1:0,matchContext=addCombinator(function(elem){return elem===checkContext},implicitRelative,!0),matchAnyContext=addCombinator(function(elem){return indexOf.call(checkContext,elem)>-1},implicitRelative,!0),matchers=[function(elem,context,xml){return!leadingRelative&&(xml||context!==outermostContext)||((checkContext=context).nodeType?matchContext(elem,context,xml):matchAnyContext(elem,context,xml))}];len>i;i++)if(matcher=Expr.relative[tokens[i].type])matchers=[addCombinator(elementMatcher(matchers),matcher)]
else{matcher=Expr.filter[tokens[i].type].apply(null,tokens[i].matches)
if(matcher[expando]){j=++i
for(;len>j&&!Expr.relative[tokens[j].type];j++);return setMatcher(i>1&&elementMatcher(matchers),i>1&&toSelector(tokens.slice(0,i-1)).replace(rtrim,"$1"),matcher,j>i&&matcherFromTokens(tokens.slice(i,j)),len>j&&matcherFromTokens(tokens=tokens.slice(j)),len>j&&toSelector(tokens))}matchers.push(matcher)}return elementMatcher(matchers)}function matcherFromGroupMatchers(elementMatchers,setMatchers){var matcherCachedRuns=0,bySet=setMatchers.length>0,byElement=elementMatchers.length>0,superMatcher=function(seed,context,xml,results,expandContext){var elem,j,matcher,setMatched=[],matchedCount=0,i="0",unmatched=seed&&[],outermost=null!=expandContext,contextBackup=outermostContext,elems=seed||byElement&&Expr.find.TAG("*",expandContext&&context.parentNode||context),dirrunsUnique=dirruns+=null==contextBackup?1:Math.random()||.1
if(outermost){outermostContext=context!==document&&context
cachedruns=matcherCachedRuns}for(;null!=(elem=elems[i]);i++){if(byElement&&elem){j=0
for(;matcher=elementMatchers[j++];)if(matcher(elem,context,xml)){results.push(elem)
break}if(outermost){dirruns=dirrunsUnique
cachedruns=++matcherCachedRuns}}if(bySet){(elem=!matcher&&elem)&&matchedCount--
seed&&unmatched.push(elem)}}matchedCount+=i
if(bySet&&i!==matchedCount){j=0
for(;matcher=setMatchers[j++];)matcher(unmatched,setMatched,context,xml)
if(seed){if(matchedCount>0)for(;i--;)unmatched[i]||setMatched[i]||(setMatched[i]=pop.call(results))
setMatched=condense(setMatched)}push.apply(results,setMatched)
outermost&&!seed&&setMatched.length>0&&matchedCount+setMatchers.length>1&&Sizzle.uniqueSort(results)}if(outermost){dirruns=dirrunsUnique
outermostContext=contextBackup}return unmatched}
return bySet?markFunction(superMatcher):superMatcher}function multipleContexts(selector,contexts,results){for(var i=0,len=contexts.length;len>i;i++)Sizzle(selector,contexts[i],results)
return results}function select(selector,context,results,seed){var i,tokens,token,type,find,match=tokenize(selector)
if(!seed&&1===match.length){tokens=match[0]=match[0].slice(0)
if(tokens.length>2&&"ID"===(token=tokens[0]).type&&9===context.nodeType&&!documentIsXML&&Expr.relative[tokens[1].type]){context=Expr.find.ID(token.matches[0].replace(runescape,funescape),context)[0]
if(!context)return results
selector=selector.slice(tokens.shift().value.length)}i=matchExpr.needsContext.test(selector)?0:tokens.length
for(;i--;){token=tokens[i]
if(Expr.relative[type=token.type])break
if((find=Expr.find[type])&&(seed=find(token.matches[0].replace(runescape,funescape),rsibling.test(tokens[0].type)&&context.parentNode||context))){tokens.splice(i,1)
selector=seed.length&&toSelector(tokens)
if(!selector){push.apply(results,slice.call(seed,0))
return results}break}}}compile(selector,match)(seed,context,documentIsXML,results,rsibling.test(selector))
return results}function setFilters(){}var i,cachedruns,Expr,getText,isXML,compile,hasDuplicate,outermostContext,setDocument,document,docElem,documentIsXML,rbuggyQSA,rbuggyMatches,matches,contains,sortOrder,expando="sizzle"+-new Date,preferredDoc=window.document,support={},dirruns=0,done=0,classCache=createCache(),tokenCache=createCache(),compilerCache=createCache(),strundefined=typeof undefined,MAX_NEGATIVE=1<<31,arr=[],pop=arr.pop,push=arr.push,slice=arr.slice,indexOf=arr.indexOf||function(elem){for(var i=0,len=this.length;len>i;i++)if(this[i]===elem)return i
return-1},whitespace="[\\x20\\t\\r\\n\\f]",characterEncoding="(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",identifier=characterEncoding.replace("w","w#"),operators="([*^$|!~]?=)",attributes="\\["+whitespace+"*("+characterEncoding+")"+whitespace+"*(?:"+operators+whitespace+"*(?:(['\"])((?:\\\\.|[^\\\\])*?)\\3|("+identifier+")|)|)"+whitespace+"*\\]",pseudos=":("+characterEncoding+")(?:\\(((['\"])((?:\\\\.|[^\\\\])*?)\\3|((?:\\\\.|[^\\\\()[\\]]|"+attributes.replace(3,8)+")*)|.*)\\)|)",rtrim=new RegExp("^"+whitespace+"+|((?:^|[^\\\\])(?:\\\\.)*)"+whitespace+"+$","g"),rcomma=new RegExp("^"+whitespace+"*,"+whitespace+"*"),rcombinators=new RegExp("^"+whitespace+"*([\\x20\\t\\r\\n\\f>+~])"+whitespace+"*"),rpseudo=new RegExp(pseudos),ridentifier=new RegExp("^"+identifier+"$"),matchExpr={ID:new RegExp("^#("+characterEncoding+")"),CLASS:new RegExp("^\\.("+characterEncoding+")"),NAME:new RegExp("^\\[name=['\"]?("+characterEncoding+")['\"]?\\]"),TAG:new RegExp("^("+characterEncoding.replace("w","w*")+")"),ATTR:new RegExp("^"+attributes),PSEUDO:new RegExp("^"+pseudos),CHILD:new RegExp("^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\("+whitespace+"*(even|odd|(([+-]|)(\\d*)n|)"+whitespace+"*(?:([+-]|)"+whitespace+"*(\\d+)|))"+whitespace+"*\\)|)","i"),needsContext:new RegExp("^"+whitespace+"*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\("+whitespace+"*((?:-\\d)?\\d*)"+whitespace+"*\\)|)(?=[^-]|$)","i")},rsibling=/[\x20\t\r\n\f]*[+~]/,rnative=/^[^{]+\{\s*\[native code/,rquickExpr=/^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,rinputs=/^(?:input|select|textarea|button)$/i,rheader=/^h\d$/i,rescape=/'|\\/g,rattributeQuotes=/\=[\x20\t\r\n\f]*([^'"\]]*)[\x20\t\r\n\f]*\]/g,runescape=/\\([\da-fA-F]{1,6}[\x20\t\r\n\f]?|.)/g,funescape=function(_,escaped){var high="0x"+escaped-65536
return high!==high?escaped:0>high?String.fromCharCode(high+65536):String.fromCharCode(55296|high>>10,56320|1023&high)}
try{slice.call(preferredDoc.documentElement.childNodes,0)[0].nodeType}catch(e){slice=function(i){for(var elem,results=[];elem=this[i++];)results.push(elem)
return results}}isXML=Sizzle.isXML=function(elem){var documentElement=elem&&(elem.ownerDocument||elem).documentElement
return documentElement?"HTML"!==documentElement.nodeName:!1}
setDocument=Sizzle.setDocument=function(node){var doc=node?node.ownerDocument||node:preferredDoc
if(doc===document||9!==doc.nodeType||!doc.documentElement)return document
document=doc
docElem=doc.documentElement
documentIsXML=isXML(doc)
support.tagNameNoComments=assert(function(div){div.appendChild(doc.createComment(""))
return!div.getElementsByTagName("*").length})
support.attributes=assert(function(div){div.innerHTML="<select></select>"
var type=typeof div.lastChild.getAttribute("multiple")
return"boolean"!==type&&"string"!==type})
support.getByClassName=assert(function(div){div.innerHTML="<div class='hidden e'></div><div class='hidden'></div>"
if(!div.getElementsByClassName||!div.getElementsByClassName("e").length)return!1
div.lastChild.className="e"
return 2===div.getElementsByClassName("e").length})
support.getByName=assert(function(div){div.id=expando+0
div.innerHTML="<a name='"+expando+"'></a><div name='"+expando+"'></div>"
docElem.insertBefore(div,docElem.firstChild)
var pass=doc.getElementsByName&&doc.getElementsByName(expando).length===2+doc.getElementsByName(expando+0).length
support.getIdNotName=!doc.getElementById(expando)
docElem.removeChild(div)
return pass})
Expr.attrHandle=assert(function(div){div.innerHTML="<a href='#'></a>"
return div.firstChild&&typeof div.firstChild.getAttribute!==strundefined&&"#"===div.firstChild.getAttribute("href")})?{}:{href:function(elem){return elem.getAttribute("href",2)},type:function(elem){return elem.getAttribute("type")}}
if(support.getIdNotName){Expr.find.ID=function(id,context){if(typeof context.getElementById!==strundefined&&!documentIsXML){var m=context.getElementById(id)
return m&&m.parentNode?[m]:[]}}
Expr.filter.ID=function(id){var attrId=id.replace(runescape,funescape)
return function(elem){return elem.getAttribute("id")===attrId}}}else{Expr.find.ID=function(id,context){if(typeof context.getElementById!==strundefined&&!documentIsXML){var m=context.getElementById(id)
return m?m.id===id||typeof m.getAttributeNode!==strundefined&&m.getAttributeNode("id").value===id?[m]:undefined:[]}}
Expr.filter.ID=function(id){var attrId=id.replace(runescape,funescape)
return function(elem){var node=typeof elem.getAttributeNode!==strundefined&&elem.getAttributeNode("id")
return node&&node.value===attrId}}}Expr.find.TAG=support.tagNameNoComments?function(tag,context){return typeof context.getElementsByTagName!==strundefined?context.getElementsByTagName(tag):void 0}:function(tag,context){var elem,tmp=[],i=0,results=context.getElementsByTagName(tag)
if("*"===tag){for(;elem=results[i++];)1===elem.nodeType&&tmp.push(elem)
return tmp}return results}
Expr.find.NAME=support.getByName&&function(tag,context){return typeof context.getElementsByName!==strundefined?context.getElementsByName(name):void 0}
Expr.find.CLASS=support.getByClassName&&function(className,context){return typeof context.getElementsByClassName===strundefined||documentIsXML?void 0:context.getElementsByClassName(className)}
rbuggyMatches=[]
rbuggyQSA=[":focus"]
if(support.qsa=isNative(doc.querySelectorAll)){assert(function(div){div.innerHTML="<select><option selected=''></option></select>"
div.querySelectorAll("[selected]").length||rbuggyQSA.push("\\["+whitespace+"*(?:checked|disabled|ismap|multiple|readonly|selected|value)")
div.querySelectorAll(":checked").length||rbuggyQSA.push(":checked")})
assert(function(div){div.innerHTML="<input type='hidden' i=''/>"
div.querySelectorAll("[i^='']").length&&rbuggyQSA.push("[*^$]="+whitespace+"*(?:\"\"|'')")
div.querySelectorAll(":enabled").length||rbuggyQSA.push(":enabled",":disabled")
div.querySelectorAll("*,:x")
rbuggyQSA.push(",.*:")})}(support.matchesSelector=isNative(matches=docElem.matchesSelector||docElem.mozMatchesSelector||docElem.webkitMatchesSelector||docElem.oMatchesSelector||docElem.msMatchesSelector))&&assert(function(div){support.disconnectedMatch=matches.call(div,"div")
matches.call(div,"[s!='']:x")
rbuggyMatches.push("!=",pseudos)})
rbuggyQSA=new RegExp(rbuggyQSA.join("|"))
rbuggyMatches=new RegExp(rbuggyMatches.join("|"))
contains=isNative(docElem.contains)||docElem.compareDocumentPosition?function(a,b){var adown=9===a.nodeType?a.documentElement:a,bup=b&&b.parentNode
return a===bup||!(!bup||1!==bup.nodeType||!(adown.contains?adown.contains(bup):a.compareDocumentPosition&&16&a.compareDocumentPosition(bup)))}:function(a,b){if(b)for(;b=b.parentNode;)if(b===a)return!0
return!1}
sortOrder=docElem.compareDocumentPosition?function(a,b){var compare
if(a===b){hasDuplicate=!0
return 0}return(compare=b.compareDocumentPosition&&a.compareDocumentPosition&&a.compareDocumentPosition(b))?1&compare||a.parentNode&&11===a.parentNode.nodeType?a===doc||contains(preferredDoc,a)?-1:b===doc||contains(preferredDoc,b)?1:0:4&compare?-1:1:a.compareDocumentPosition?-1:1}:function(a,b){var cur,i=0,aup=a.parentNode,bup=b.parentNode,ap=[a],bp=[b]
if(a===b){hasDuplicate=!0
return 0}if(!aup||!bup)return a===doc?-1:b===doc?1:aup?-1:bup?1:0
if(aup===bup)return siblingCheck(a,b)
cur=a
for(;cur=cur.parentNode;)ap.unshift(cur)
cur=b
for(;cur=cur.parentNode;)bp.unshift(cur)
for(;ap[i]===bp[i];)i++
return i?siblingCheck(ap[i],bp[i]):ap[i]===preferredDoc?-1:bp[i]===preferredDoc?1:0}
hasDuplicate=!1;[0,0].sort(sortOrder)
support.detectDuplicates=hasDuplicate
return document}
Sizzle.matches=function(expr,elements){return Sizzle(expr,null,null,elements)}
Sizzle.matchesSelector=function(elem,expr){(elem.ownerDocument||elem)!==document&&setDocument(elem)
expr=expr.replace(rattributeQuotes,"='$1']")
if(!(!support.matchesSelector||documentIsXML||rbuggyMatches&&rbuggyMatches.test(expr)||rbuggyQSA.test(expr)))try{var ret=matches.call(elem,expr)
if(ret||support.disconnectedMatch||elem.document&&11!==elem.document.nodeType)return ret}catch(e){}return Sizzle(expr,document,null,[elem]).length>0}
Sizzle.contains=function(context,elem){(context.ownerDocument||context)!==document&&setDocument(context)
return contains(context,elem)}
Sizzle.attr=function(elem,name){var val;(elem.ownerDocument||elem)!==document&&setDocument(elem)
documentIsXML||(name=name.toLowerCase())
return(val=Expr.attrHandle[name])?val(elem):documentIsXML||support.attributes?elem.getAttribute(name):((val=elem.getAttributeNode(name))||elem.getAttribute(name))&&elem[name]===!0?name:val&&val.specified?val.value:null}
Sizzle.error=function(msg){throw new Error("Syntax error, unrecognized expression: "+msg)}
Sizzle.uniqueSort=function(results){var elem,duplicates=[],i=1,j=0
hasDuplicate=!support.detectDuplicates
results.sort(sortOrder)
if(hasDuplicate){for(;elem=results[i];i++)elem===results[i-1]&&(j=duplicates.push(i))
for(;j--;)results.splice(duplicates[j],1)}return results}
getText=Sizzle.getText=function(elem){var node,ret="",i=0,nodeType=elem.nodeType
if(nodeType){if(1===nodeType||9===nodeType||11===nodeType){if("string"==typeof elem.textContent)return elem.textContent
for(elem=elem.firstChild;elem;elem=elem.nextSibling)ret+=getText(elem)}else if(3===nodeType||4===nodeType)return elem.nodeValue}else for(;node=elem[i];i++)ret+=getText(node)
return ret}
Expr=Sizzle.selectors={cacheLength:50,createPseudo:markFunction,match:matchExpr,find:{},relative:{">":{dir:"parentNode",first:!0}," ":{dir:"parentNode"},"+":{dir:"previousSibling",first:!0},"~":{dir:"previousSibling"}},preFilter:{ATTR:function(match){match[1]=match[1].replace(runescape,funescape)
match[3]=(match[4]||match[5]||"").replace(runescape,funescape)
"~="===match[2]&&(match[3]=" "+match[3]+" ")
return match.slice(0,4)},CHILD:function(match){match[1]=match[1].toLowerCase()
if("nth"===match[1].slice(0,3)){match[3]||Sizzle.error(match[0])
match[4]=+(match[4]?match[5]+(match[6]||1):2*("even"===match[3]||"odd"===match[3]))
match[5]=+(match[7]+match[8]||"odd"===match[3])}else match[3]&&Sizzle.error(match[0])
return match},PSEUDO:function(match){var excess,unquoted=!match[5]&&match[2]
if(matchExpr.CHILD.test(match[0]))return null
if(match[4])match[2]=match[4]
else if(unquoted&&rpseudo.test(unquoted)&&(excess=tokenize(unquoted,!0))&&(excess=unquoted.indexOf(")",unquoted.length-excess)-unquoted.length)){match[0]=match[0].slice(0,excess)
match[2]=unquoted.slice(0,excess)}return match.slice(0,3)}},filter:{TAG:function(nodeName){if("*"===nodeName)return function(){return!0}
nodeName=nodeName.replace(runescape,funescape).toLowerCase()
return function(elem){return elem.nodeName&&elem.nodeName.toLowerCase()===nodeName}},CLASS:function(className){var pattern=classCache[className+" "]
return pattern||(pattern=new RegExp("(^|"+whitespace+")"+className+"("+whitespace+"|$)"))&&classCache(className,function(elem){return pattern.test(elem.className||typeof elem.getAttribute!==strundefined&&elem.getAttribute("class")||"")})},ATTR:function(name,operator,check){return function(elem){var result=Sizzle.attr(elem,name)
if(null==result)return"!="===operator
if(!operator)return!0
result+=""
return"="===operator?result===check:"!="===operator?result!==check:"^="===operator?check&&0===result.indexOf(check):"*="===operator?check&&result.indexOf(check)>-1:"$="===operator?check&&result.slice(-check.length)===check:"~="===operator?(" "+result+" ").indexOf(check)>-1:"|="===operator?result===check||result.slice(0,check.length+1)===check+"-":!1}},CHILD:function(type,what,argument,first,last){var simple="nth"!==type.slice(0,3),forward="last"!==type.slice(-4),ofType="of-type"===what
return 1===first&&0===last?function(elem){return!!elem.parentNode}:function(elem,context,xml){var cache,outerCache,node,diff,nodeIndex,start,dir=simple!==forward?"nextSibling":"previousSibling",parent=elem.parentNode,name=ofType&&elem.nodeName.toLowerCase(),useCache=!xml&&!ofType
if(parent){if(simple){for(;dir;){node=elem
for(;node=node[dir];)if(ofType?node.nodeName.toLowerCase()===name:1===node.nodeType)return!1
start=dir="only"===type&&!start&&"nextSibling"}return!0}start=[forward?parent.firstChild:parent.lastChild]
if(forward&&useCache){outerCache=parent[expando]||(parent[expando]={})
cache=outerCache[type]||[]
nodeIndex=cache[0]===dirruns&&cache[1]
diff=cache[0]===dirruns&&cache[2]
node=nodeIndex&&parent.childNodes[nodeIndex]
for(;node=++nodeIndex&&node&&node[dir]||(diff=nodeIndex=0)||start.pop();)if(1===node.nodeType&&++diff&&node===elem){outerCache[type]=[dirruns,nodeIndex,diff]
break}}else if(useCache&&(cache=(elem[expando]||(elem[expando]={}))[type])&&cache[0]===dirruns)diff=cache[1]
else for(;node=++nodeIndex&&node&&node[dir]||(diff=nodeIndex=0)||start.pop();)if((ofType?node.nodeName.toLowerCase()===name:1===node.nodeType)&&++diff){useCache&&((node[expando]||(node[expando]={}))[type]=[dirruns,diff])
if(node===elem)break}diff-=last
return diff===first||0===diff%first&&diff/first>=0}}},PSEUDO:function(pseudo,argument){var args,fn=Expr.pseudos[pseudo]||Expr.setFilters[pseudo.toLowerCase()]||Sizzle.error("unsupported pseudo: "+pseudo)
if(fn[expando])return fn(argument)
if(fn.length>1){args=[pseudo,pseudo,"",argument]
return Expr.setFilters.hasOwnProperty(pseudo.toLowerCase())?markFunction(function(seed,matches){for(var idx,matched=fn(seed,argument),i=matched.length;i--;){idx=indexOf.call(seed,matched[i])
seed[idx]=!(matches[idx]=matched[i])}}):function(elem){return fn(elem,0,args)}}return fn}},pseudos:{not:markFunction(function(selector){var input=[],results=[],matcher=compile(selector.replace(rtrim,"$1"))
return matcher[expando]?markFunction(function(seed,matches,context,xml){for(var elem,unmatched=matcher(seed,null,xml,[]),i=seed.length;i--;)(elem=unmatched[i])&&(seed[i]=!(matches[i]=elem))}):function(elem,context,xml){input[0]=elem
matcher(input,null,xml,results)
return!results.pop()}}),has:markFunction(function(selector){return function(elem){return Sizzle(selector,elem).length>0}}),contains:markFunction(function(text){return function(elem){return(elem.textContent||elem.innerText||getText(elem)).indexOf(text)>-1}}),lang:markFunction(function(lang){ridentifier.test(lang||"")||Sizzle.error("unsupported lang: "+lang)
lang=lang.replace(runescape,funescape).toLowerCase()
return function(elem){var elemLang
do if(elemLang=documentIsXML?elem.getAttribute("xml:lang")||elem.getAttribute("lang"):elem.lang){elemLang=elemLang.toLowerCase()
return elemLang===lang||0===elemLang.indexOf(lang+"-")}while((elem=elem.parentNode)&&1===elem.nodeType)
return!1}}),target:function(elem){var hash=window.location&&window.location.hash
return hash&&hash.slice(1)===elem.id},root:function(elem){return elem===docElem},focus:function(elem){return elem===document.activeElement&&(!document.hasFocus||document.hasFocus())&&!!(elem.type||elem.href||~elem.tabIndex)},enabled:function(elem){return elem.disabled===!1},disabled:function(elem){return elem.disabled===!0},checked:function(elem){var nodeName=elem.nodeName.toLowerCase()
return"input"===nodeName&&!!elem.checked||"option"===nodeName&&!!elem.selected},selected:function(elem){elem.parentNode&&elem.parentNode.selectedIndex
return elem.selected===!0},empty:function(elem){for(elem=elem.firstChild;elem;elem=elem.nextSibling)if(elem.nodeName>"@"||3===elem.nodeType||4===elem.nodeType)return!1
return!0},parent:function(elem){return!Expr.pseudos.empty(elem)},header:function(elem){return rheader.test(elem.nodeName)},input:function(elem){return rinputs.test(elem.nodeName)},button:function(elem){var name=elem.nodeName.toLowerCase()
return"input"===name&&"button"===elem.type||"button"===name},text:function(elem){var attr
return"input"===elem.nodeName.toLowerCase()&&"text"===elem.type&&(null==(attr=elem.getAttribute("type"))||attr.toLowerCase()===elem.type)},first:createPositionalPseudo(function(){return[0]}),last:createPositionalPseudo(function(matchIndexes,length){return[length-1]}),eq:createPositionalPseudo(function(matchIndexes,length,argument){return[0>argument?argument+length:argument]}),even:createPositionalPseudo(function(matchIndexes,length){for(var i=0;length>i;i+=2)matchIndexes.push(i)
return matchIndexes}),odd:createPositionalPseudo(function(matchIndexes,length){for(var i=1;length>i;i+=2)matchIndexes.push(i)
return matchIndexes}),lt:createPositionalPseudo(function(matchIndexes,length,argument){for(var i=0>argument?argument+length:argument;--i>=0;)matchIndexes.push(i)
return matchIndexes}),gt:createPositionalPseudo(function(matchIndexes,length,argument){for(var i=0>argument?argument+length:argument;++i<length;)matchIndexes.push(i)
return matchIndexes})}}
for(i in{radio:!0,checkbox:!0,file:!0,password:!0,image:!0})Expr.pseudos[i]=createInputPseudo(i)
for(i in{submit:!0,reset:!0})Expr.pseudos[i]=createButtonPseudo(i)
compile=Sizzle.compile=function(selector,group){var i,setMatchers=[],elementMatchers=[],cached=compilerCache[selector+" "]
if(!cached){group||(group=tokenize(selector))
i=group.length
for(;i--;){cached=matcherFromTokens(group[i])
cached[expando]?setMatchers.push(cached):elementMatchers.push(cached)}cached=compilerCache(selector,matcherFromGroupMatchers(elementMatchers,setMatchers))}return cached}
Expr.pseudos.nth=Expr.pseudos.eq
Expr.filters=setFilters.prototype=Expr.pseudos
Expr.setFilters=new setFilters
setDocument()
Sizzle.attr=jQuery.attr
jQuery.find=Sizzle
jQuery.expr=Sizzle.selectors
jQuery.expr[":"]=jQuery.expr.pseudos
jQuery.unique=Sizzle.uniqueSort
jQuery.text=Sizzle.getText
jQuery.isXMLDoc=Sizzle.isXML
jQuery.contains=Sizzle.contains}(window)
var runtil=/Until$/,rparentsprev=/^(?:parents|prev(?:Until|All))/,isSimple=/^.[^:#\[\.,]*$/,rneedsContext=jQuery.expr.match.needsContext,guaranteedUnique={children:!0,contents:!0,next:!0,prev:!0}
jQuery.fn.extend({find:function(selector){var i,ret,self,len=this.length
if("string"!=typeof selector){self=this
return this.pushStack(jQuery(selector).filter(function(){for(i=0;len>i;i++)if(jQuery.contains(self[i],this))return!0}))}ret=[]
for(i=0;len>i;i++)jQuery.find(selector,this[i],ret)
ret=this.pushStack(len>1?jQuery.unique(ret):ret)
ret.selector=(this.selector?this.selector+" ":"")+selector
return ret},has:function(target){var i,targets=jQuery(target,this),len=targets.length
return this.filter(function(){for(i=0;len>i;i++)if(jQuery.contains(this,targets[i]))return!0})},not:function(selector){return this.pushStack(winnow(this,selector,!1))},filter:function(selector){return this.pushStack(winnow(this,selector,!0))},is:function(selector){return!!selector&&("string"==typeof selector?rneedsContext.test(selector)?jQuery(selector,this.context).index(this[0])>=0:jQuery.filter(selector,this).length>0:this.filter(selector).length>0)},closest:function(selectors,context){for(var cur,i=0,l=this.length,ret=[],pos=rneedsContext.test(selectors)||"string"!=typeof selectors?jQuery(selectors,context||this.context):0;l>i;i++){cur=this[i]
for(;cur&&cur.ownerDocument&&cur!==context&&11!==cur.nodeType;){if(pos?pos.index(cur)>-1:jQuery.find.matchesSelector(cur,selectors)){ret.push(cur)
break}cur=cur.parentNode}}return this.pushStack(ret.length>1?jQuery.unique(ret):ret)},index:function(elem){return elem?"string"==typeof elem?jQuery.inArray(this[0],jQuery(elem)):jQuery.inArray(elem.jquery?elem[0]:elem,this):this[0]&&this[0].parentNode?this.first().prevAll().length:-1},add:function(selector,context){var set="string"==typeof selector?jQuery(selector,context):jQuery.makeArray(selector&&selector.nodeType?[selector]:selector),all=jQuery.merge(this.get(),set)
return this.pushStack(jQuery.unique(all))},addBack:function(selector){return this.add(null==selector?this.prevObject:this.prevObject.filter(selector))}})
jQuery.fn.andSelf=jQuery.fn.addBack
jQuery.each({parent:function(elem){var parent=elem.parentNode
return parent&&11!==parent.nodeType?parent:null},parents:function(elem){return jQuery.dir(elem,"parentNode")},parentsUntil:function(elem,i,until){return jQuery.dir(elem,"parentNode",until)},next:function(elem){return sibling(elem,"nextSibling")},prev:function(elem){return sibling(elem,"previousSibling")},nextAll:function(elem){return jQuery.dir(elem,"nextSibling")},prevAll:function(elem){return jQuery.dir(elem,"previousSibling")},nextUntil:function(elem,i,until){return jQuery.dir(elem,"nextSibling",until)},prevUntil:function(elem,i,until){return jQuery.dir(elem,"previousSibling",until)},siblings:function(elem){return jQuery.sibling((elem.parentNode||{}).firstChild,elem)},children:function(elem){return jQuery.sibling(elem.firstChild)},contents:function(elem){return jQuery.nodeName(elem,"iframe")?elem.contentDocument||elem.contentWindow.document:jQuery.merge([],elem.childNodes)}},function(name,fn){jQuery.fn[name]=function(until,selector){var ret=jQuery.map(this,fn,until)
runtil.test(name)||(selector=until)
selector&&"string"==typeof selector&&(ret=jQuery.filter(selector,ret))
ret=this.length>1&&!guaranteedUnique[name]?jQuery.unique(ret):ret
this.length>1&&rparentsprev.test(name)&&(ret=ret.reverse())
return this.pushStack(ret)}})
jQuery.extend({filter:function(expr,elems,not){not&&(expr=":not("+expr+")")
return 1===elems.length?jQuery.find.matchesSelector(elems[0],expr)?[elems[0]]:[]:jQuery.find.matches(expr,elems)},dir:function(elem,dir,until){for(var matched=[],cur=elem[dir];cur&&9!==cur.nodeType&&(until===undefined||1!==cur.nodeType||!jQuery(cur).is(until));){1===cur.nodeType&&matched.push(cur)
cur=cur[dir]}return matched},sibling:function(n,elem){for(var r=[];n;n=n.nextSibling)1===n.nodeType&&n!==elem&&r.push(n)
return r}})
var nodeNames="abbr|article|aside|audio|bdi|canvas|data|datalist|details|figcaption|figure|footer|header|hgroup|mark|meter|nav|output|progress|section|summary|time|video",rinlinejQuery=/ jQuery\d+="(?:null|\d+)"/g,rnoshimcache=new RegExp("<(?:"+nodeNames+")[\\s/>]","i"),rleadingWhitespace=/^\s+/,rxhtmlTag=/<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:]+)[^>]*)\/>/gi,rtagName=/<([\w:]+)/,rtbody=/<tbody/i,rhtml=/<|&#?\w+;/,rnoInnerhtml=/<(?:script|style|link)/i,manipulation_rcheckableType=/^(?:checkbox|radio)$/i,rchecked=/checked\s*(?:[^=]|=\s*.checked.)/i,rscriptType=/^$|\/(?:java|ecma)script/i,rscriptTypeMasked=/^true\/(.*)/,rcleanScript=/^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,wrapMap={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],area:[1,"<map>","</map>"],param:[1,"<object>","</object>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],_default:jQuery.support.htmlSerialize?[0,"",""]:[1,"X<div>","</div>"]},safeFragment=createSafeFragment(document),fragmentDiv=safeFragment.appendChild(document.createElement("div"))
wrapMap.optgroup=wrapMap.option
wrapMap.tbody=wrapMap.tfoot=wrapMap.colgroup=wrapMap.caption=wrapMap.thead
wrapMap.th=wrapMap.td
jQuery.fn.extend({text:function(value){return jQuery.access(this,function(value){return value===undefined?jQuery.text(this):this.empty().append((this[0]&&this[0].ownerDocument||document).createTextNode(value))},null,value,arguments.length)},wrapAll:function(html){if(jQuery.isFunction(html))return this.each(function(i){jQuery(this).wrapAll(html.call(this,i))})
if(this[0]){var wrap=jQuery(html,this[0].ownerDocument).eq(0).clone(!0)
this[0].parentNode&&wrap.insertBefore(this[0])
wrap.map(function(){for(var elem=this;elem.firstChild&&1===elem.firstChild.nodeType;)elem=elem.firstChild
return elem}).append(this)}return this},wrapInner:function(html){return jQuery.isFunction(html)?this.each(function(i){jQuery(this).wrapInner(html.call(this,i))}):this.each(function(){var self=jQuery(this),contents=self.contents()
contents.length?contents.wrapAll(html):self.append(html)})},wrap:function(html){var isFunction=jQuery.isFunction(html)
return this.each(function(i){jQuery(this).wrapAll(isFunction?html.call(this,i):html)})},unwrap:function(){return this.parent().each(function(){jQuery.nodeName(this,"body")||jQuery(this).replaceWith(this.childNodes)}).end()},append:function(){return this.domManip(arguments,!0,function(elem){(1===this.nodeType||11===this.nodeType||9===this.nodeType)&&this.appendChild(elem)})},prepend:function(){return this.domManip(arguments,!0,function(elem){(1===this.nodeType||11===this.nodeType||9===this.nodeType)&&this.insertBefore(elem,this.firstChild)})},before:function(){return this.domManip(arguments,!1,function(elem){this.parentNode&&this.parentNode.insertBefore(elem,this)})},after:function(){return this.domManip(arguments,!1,function(elem){this.parentNode&&this.parentNode.insertBefore(elem,this.nextSibling)})},remove:function(selector,keepData){for(var elem,i=0;null!=(elem=this[i]);i++)if(!selector||jQuery.filter(selector,[elem]).length>0){keepData||1!==elem.nodeType||jQuery.cleanData(getAll(elem))
if(elem.parentNode){keepData&&jQuery.contains(elem.ownerDocument,elem)&&setGlobalEval(getAll(elem,"script"))
elem.parentNode.removeChild(elem)}}return this},empty:function(){for(var elem,i=0;null!=(elem=this[i]);i++){1===elem.nodeType&&jQuery.cleanData(getAll(elem,!1))
for(;elem.firstChild;)elem.removeChild(elem.firstChild)
elem.options&&jQuery.nodeName(elem,"select")&&(elem.options.length=0)}return this},clone:function(dataAndEvents,deepDataAndEvents){dataAndEvents=null==dataAndEvents?!1:dataAndEvents
deepDataAndEvents=null==deepDataAndEvents?dataAndEvents:deepDataAndEvents
return this.map(function(){return jQuery.clone(this,dataAndEvents,deepDataAndEvents)})},html:function(value){return jQuery.access(this,function(value){var elem=this[0]||{},i=0,l=this.length
if(value===undefined)return 1===elem.nodeType?elem.innerHTML.replace(rinlinejQuery,""):undefined
if(!("string"!=typeof value||rnoInnerhtml.test(value)||!jQuery.support.htmlSerialize&&rnoshimcache.test(value)||!jQuery.support.leadingWhitespace&&rleadingWhitespace.test(value)||wrapMap[(rtagName.exec(value)||["",""])[1].toLowerCase()])){value=value.replace(rxhtmlTag,"<$1></$2>")
try{for(;l>i;i++){elem=this[i]||{}
if(1===elem.nodeType){jQuery.cleanData(getAll(elem,!1))
elem.innerHTML=value}}elem=0}catch(e){}}elem&&this.empty().append(value)},null,value,arguments.length)},replaceWith:function(value){var isFunc=jQuery.isFunction(value)
isFunc||"string"==typeof value||(value=jQuery(value).not(this).detach())
return this.domManip([value],!0,function(elem){var next=this.nextSibling,parent=this.parentNode
if(parent){jQuery(this).remove()
parent.insertBefore(elem,next)}})},detach:function(selector){return this.remove(selector,!0)},domManip:function(args,table,callback){args=core_concat.apply([],args)
var first,node,hasScripts,scripts,doc,fragment,i=0,l=this.length,set=this,iNoClone=l-1,value=args[0],isFunction=jQuery.isFunction(value)
if(isFunction||!(1>=l||"string"!=typeof value||jQuery.support.checkClone)&&rchecked.test(value))return this.each(function(index){var self=set.eq(index)
isFunction&&(args[0]=value.call(this,index,table?self.html():undefined))
self.domManip(args,table,callback)})
if(l){fragment=jQuery.buildFragment(args,this[0].ownerDocument,!1,this)
first=fragment.firstChild
1===fragment.childNodes.length&&(fragment=first)
if(first){table=table&&jQuery.nodeName(first,"tr")
scripts=jQuery.map(getAll(fragment,"script"),disableScript)
hasScripts=scripts.length
for(;l>i;i++){node=fragment
if(i!==iNoClone){node=jQuery.clone(node,!0,!0)
hasScripts&&jQuery.merge(scripts,getAll(node,"script"))}callback.call(table&&jQuery.nodeName(this[i],"table")?findOrAppend(this[i],"tbody"):this[i],node,i)}if(hasScripts){doc=scripts[scripts.length-1].ownerDocument
jQuery.map(scripts,restoreScript)
for(i=0;hasScripts>i;i++){node=scripts[i]
rscriptType.test(node.type||"")&&!jQuery._data(node,"globalEval")&&jQuery.contains(doc,node)&&(node.src?jQuery.ajax({url:node.src,type:"GET",dataType:"script",async:!1,global:!1,"throws":!0}):jQuery.globalEval((node.text||node.textContent||node.innerHTML||"").replace(rcleanScript,"")))}}fragment=first=null}}return this}})
jQuery.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(name,original){jQuery.fn[name]=function(selector){for(var elems,i=0,ret=[],insert=jQuery(selector),last=insert.length-1;last>=i;i++){elems=i===last?this:this.clone(!0)
jQuery(insert[i])[original](elems)
core_push.apply(ret,elems.get())}return this.pushStack(ret)}})
jQuery.extend({clone:function(elem,dataAndEvents,deepDataAndEvents){var destElements,node,clone,i,srcElements,inPage=jQuery.contains(elem.ownerDocument,elem)
if(jQuery.support.html5Clone||jQuery.isXMLDoc(elem)||!rnoshimcache.test("<"+elem.nodeName+">"))clone=elem.cloneNode(!0)
else{fragmentDiv.innerHTML=elem.outerHTML
fragmentDiv.removeChild(clone=fragmentDiv.firstChild)}if(!(jQuery.support.noCloneEvent&&jQuery.support.noCloneChecked||1!==elem.nodeType&&11!==elem.nodeType||jQuery.isXMLDoc(elem))){destElements=getAll(clone)
srcElements=getAll(elem)
for(i=0;null!=(node=srcElements[i]);++i)destElements[i]&&fixCloneNodeIssues(node,destElements[i])}if(dataAndEvents)if(deepDataAndEvents){srcElements=srcElements||getAll(elem)
destElements=destElements||getAll(clone)
for(i=0;null!=(node=srcElements[i]);i++)cloneCopyEvent(node,destElements[i])}else cloneCopyEvent(elem,clone)
destElements=getAll(clone,"script")
destElements.length>0&&setGlobalEval(destElements,!inPage&&getAll(elem,"script"))
destElements=srcElements=node=null
return clone},buildFragment:function(elems,context,scripts,selection){for(var j,elem,contains,tmp,tag,tbody,wrap,l=elems.length,safe=createSafeFragment(context),nodes=[],i=0;l>i;i++){elem=elems[i]
if(elem||0===elem)if("object"===jQuery.type(elem))jQuery.merge(nodes,elem.nodeType?[elem]:elem)
else if(rhtml.test(elem)){tmp=tmp||safe.appendChild(context.createElement("div"))
tag=(rtagName.exec(elem)||["",""])[1].toLowerCase()
wrap=wrapMap[tag]||wrapMap._default
tmp.innerHTML=wrap[1]+elem.replace(rxhtmlTag,"<$1></$2>")+wrap[2]
j=wrap[0]
for(;j--;)tmp=tmp.lastChild
!jQuery.support.leadingWhitespace&&rleadingWhitespace.test(elem)&&nodes.push(context.createTextNode(rleadingWhitespace.exec(elem)[0]))
if(!jQuery.support.tbody){elem="table"!==tag||rtbody.test(elem)?"<table>"!==wrap[1]||rtbody.test(elem)?0:tmp:tmp.firstChild
j=elem&&elem.childNodes.length
for(;j--;)jQuery.nodeName(tbody=elem.childNodes[j],"tbody")&&!tbody.childNodes.length&&elem.removeChild(tbody)}jQuery.merge(nodes,tmp.childNodes)
tmp.textContent=""
for(;tmp.firstChild;)tmp.removeChild(tmp.firstChild)
tmp=safe.lastChild}else nodes.push(context.createTextNode(elem))}tmp&&safe.removeChild(tmp)
jQuery.support.appendChecked||jQuery.grep(getAll(nodes,"input"),fixDefaultChecked)
i=0
for(;elem=nodes[i++];)if(!selection||-1===jQuery.inArray(elem,selection)){contains=jQuery.contains(elem.ownerDocument,elem)
tmp=getAll(safe.appendChild(elem),"script")
contains&&setGlobalEval(tmp)
if(scripts){j=0
for(;elem=tmp[j++];)rscriptType.test(elem.type||"")&&scripts.push(elem)}}tmp=null
return safe},cleanData:function(elems,acceptData){for(var elem,type,id,data,i=0,internalKey=jQuery.expando,cache=jQuery.cache,deleteExpando=jQuery.support.deleteExpando,special=jQuery.event.special;null!=(elem=elems[i]);i++)if(acceptData||jQuery.acceptData(elem)){id=elem[internalKey]
data=id&&cache[id]
if(data){if(data.events)for(type in data.events)special[type]?jQuery.event.remove(elem,type):jQuery.removeEvent(elem,type,data.handle)
if(cache[id]){delete cache[id]
deleteExpando?delete elem[internalKey]:typeof elem.removeAttribute!==core_strundefined?elem.removeAttribute(internalKey):elem[internalKey]=null
core_deletedIds.push(id)}}}}})
var iframe,getStyles,curCSS,ralpha=/alpha\([^)]*\)/i,ropacity=/opacity\s*=\s*([^)]*)/,rposition=/^(top|right|bottom|left)$/,rdisplayswap=/^(none|table(?!-c[ea]).+)/,rmargin=/^margin/,rnumsplit=new RegExp("^("+core_pnum+")(.*)$","i"),rnumnonpx=new RegExp("^("+core_pnum+")(?!px)[a-z%]+$","i"),rrelNum=new RegExp("^([+-])=("+core_pnum+")","i"),elemdisplay={BODY:"block"},cssShow={position:"absolute",visibility:"hidden",display:"block"},cssNormalTransform={letterSpacing:0,fontWeight:400},cssExpand=["Top","Right","Bottom","Left"],cssPrefixes=["Webkit","O","Moz","ms"]
jQuery.fn.extend({css:function(name,value){return jQuery.access(this,function(elem,name,value){var len,styles,map={},i=0
if(jQuery.isArray(name)){styles=getStyles(elem)
len=name.length
for(;len>i;i++)map[name[i]]=jQuery.css(elem,name[i],!1,styles)
return map}return value!==undefined?jQuery.style(elem,name,value):jQuery.css(elem,name)},name,value,arguments.length>1)},show:function(){return showHide(this,!0)},hide:function(){return showHide(this)},toggle:function(state){var bool="boolean"==typeof state
return this.each(function(){(bool?state:isHidden(this))?jQuery(this).show():jQuery(this).hide()})}})
jQuery.extend({cssHooks:{opacity:{get:function(elem,computed){if(computed){var ret=curCSS(elem,"opacity")
return""===ret?"1":ret}}}},cssNumber:{columnCount:!0,fillOpacity:!0,fontWeight:!0,lineHeight:!0,opacity:!0,orphans:!0,widows:!0,zIndex:!0,zoom:!0},cssProps:{"float":jQuery.support.cssFloat?"cssFloat":"styleFloat"},style:function(elem,name,value,extra){if(elem&&3!==elem.nodeType&&8!==elem.nodeType&&elem.style){var ret,type,hooks,origName=jQuery.camelCase(name),style=elem.style
name=jQuery.cssProps[origName]||(jQuery.cssProps[origName]=vendorPropName(style,origName))
hooks=jQuery.cssHooks[name]||jQuery.cssHooks[origName]
if(value===undefined)return hooks&&"get"in hooks&&(ret=hooks.get(elem,!1,extra))!==undefined?ret:style[name]
type=typeof value
if("string"===type&&(ret=rrelNum.exec(value))){value=(ret[1]+1)*ret[2]+parseFloat(jQuery.css(elem,name))
type="number"}if(!(null==value||"number"===type&&isNaN(value))){"number"!==type||jQuery.cssNumber[origName]||(value+="px")
jQuery.support.clearCloneStyle||""!==value||0!==name.indexOf("background")||(style[name]="inherit")
if(!(hooks&&"set"in hooks&&(value=hooks.set(elem,value,extra))===undefined))try{style[name]=value}catch(e){}}}},css:function(elem,name,extra,styles){var num,val,hooks,origName=jQuery.camelCase(name)
name=jQuery.cssProps[origName]||(jQuery.cssProps[origName]=vendorPropName(elem.style,origName))
hooks=jQuery.cssHooks[name]||jQuery.cssHooks[origName]
hooks&&"get"in hooks&&(val=hooks.get(elem,!0,extra))
val===undefined&&(val=curCSS(elem,name,styles))
"normal"===val&&name in cssNormalTransform&&(val=cssNormalTransform[name])
if(""===extra||extra){num=parseFloat(val)
return extra===!0||jQuery.isNumeric(num)?num||0:val}return val},swap:function(elem,options,callback,args){var ret,name,old={}
for(name in options){old[name]=elem.style[name]
elem.style[name]=options[name]}ret=callback.apply(elem,args||[])
for(name in options)elem.style[name]=old[name]
return ret}})
if(window.getComputedStyle){getStyles=function(elem){return window.getComputedStyle(elem,null)}
curCSS=function(elem,name,_computed){var width,minWidth,maxWidth,computed=_computed||getStyles(elem),ret=computed?computed.getPropertyValue(name)||computed[name]:undefined,style=elem.style
if(computed){""!==ret||jQuery.contains(elem.ownerDocument,elem)||(ret=jQuery.style(elem,name))
if(rnumnonpx.test(ret)&&rmargin.test(name)){width=style.width
minWidth=style.minWidth
maxWidth=style.maxWidth
style.minWidth=style.maxWidth=style.width=ret
ret=computed.width
style.width=width
style.minWidth=minWidth
style.maxWidth=maxWidth}}return ret}}else if(document.documentElement.currentStyle){getStyles=function(elem){return elem.currentStyle}
curCSS=function(elem,name,_computed){var left,rs,rsLeft,computed=_computed||getStyles(elem),ret=computed?computed[name]:undefined,style=elem.style
null==ret&&style&&style[name]&&(ret=style[name])
if(rnumnonpx.test(ret)&&!rposition.test(name)){left=style.left
rs=elem.runtimeStyle
rsLeft=rs&&rs.left
rsLeft&&(rs.left=elem.currentStyle.left)
style.left="fontSize"===name?"1em":ret
ret=style.pixelLeft+"px"
style.left=left
rsLeft&&(rs.left=rsLeft)}return""===ret?"auto":ret}}jQuery.each(["height","width"],function(i,name){jQuery.cssHooks[name]={get:function(elem,computed,extra){return computed?0===elem.offsetWidth&&rdisplayswap.test(jQuery.css(elem,"display"))?jQuery.swap(elem,cssShow,function(){return getWidthOrHeight(elem,name,extra)}):getWidthOrHeight(elem,name,extra):void 0},set:function(elem,value,extra){var styles=extra&&getStyles(elem)
return setPositiveNumber(elem,value,extra?augmentWidthOrHeight(elem,name,extra,jQuery.support.boxSizing&&"border-box"===jQuery.css(elem,"boxSizing",!1,styles),styles):0)}}})
jQuery.support.opacity||(jQuery.cssHooks.opacity={get:function(elem,computed){return ropacity.test((computed&&elem.currentStyle?elem.currentStyle.filter:elem.style.filter)||"")?.01*parseFloat(RegExp.$1)+"":computed?"1":""},set:function(elem,value){var style=elem.style,currentStyle=elem.currentStyle,opacity=jQuery.isNumeric(value)?"alpha(opacity="+100*value+")":"",filter=currentStyle&&currentStyle.filter||style.filter||""
style.zoom=1
if((value>=1||""===value)&&""===jQuery.trim(filter.replace(ralpha,""))&&style.removeAttribute){style.removeAttribute("filter")
if(""===value||currentStyle&&!currentStyle.filter)return}style.filter=ralpha.test(filter)?filter.replace(ralpha,opacity):filter+" "+opacity}})
jQuery(function(){jQuery.support.reliableMarginRight||(jQuery.cssHooks.marginRight={get:function(elem,computed){return computed?jQuery.swap(elem,{display:"inline-block"},curCSS,[elem,"marginRight"]):void 0}})
!jQuery.support.pixelPosition&&jQuery.fn.position&&jQuery.each(["top","left"],function(i,prop){jQuery.cssHooks[prop]={get:function(elem,computed){if(computed){computed=curCSS(elem,prop)
return rnumnonpx.test(computed)?jQuery(elem).position()[prop]+"px":computed}}}})})
if(jQuery.expr&&jQuery.expr.filters){jQuery.expr.filters.hidden=function(elem){return elem.offsetWidth<=0&&elem.offsetHeight<=0||!jQuery.support.reliableHiddenOffsets&&"none"===(elem.style&&elem.style.display||jQuery.css(elem,"display"))}
jQuery.expr.filters.visible=function(elem){return!jQuery.expr.filters.hidden(elem)}}jQuery.each({margin:"",padding:"",border:"Width"},function(prefix,suffix){jQuery.cssHooks[prefix+suffix]={expand:function(value){for(var i=0,expanded={},parts="string"==typeof value?value.split(" "):[value];4>i;i++)expanded[prefix+cssExpand[i]+suffix]=parts[i]||parts[i-2]||parts[0]
return expanded}}
rmargin.test(prefix)||(jQuery.cssHooks[prefix+suffix].set=setPositiveNumber)})
var r20=/%20/g,rbracket=/\[\]$/,rCRLF=/\r?\n/g,rsubmitterTypes=/^(?:submit|button|image|reset|file)$/i,rsubmittable=/^(?:input|select|textarea|keygen)/i
jQuery.fn.extend({serialize:function(){return jQuery.param(this.serializeArray())},serializeArray:function(){return this.map(function(){var elements=jQuery.prop(this,"elements")
return elements?jQuery.makeArray(elements):this}).filter(function(){var type=this.type
return this.name&&!jQuery(this).is(":disabled")&&rsubmittable.test(this.nodeName)&&!rsubmitterTypes.test(type)&&(this.checked||!manipulation_rcheckableType.test(type))}).map(function(i,elem){var val=jQuery(this).val()
return null==val?null:jQuery.isArray(val)?jQuery.map(val,function(val){return{name:elem.name,value:val.replace(rCRLF,"\r\n")}}):{name:elem.name,value:val.replace(rCRLF,"\r\n")}}).get()}})
jQuery.param=function(a,traditional){var prefix,s=[],add=function(key,value){value=jQuery.isFunction(value)?value():null==value?"":value
s[s.length]=encodeURIComponent(key)+"="+encodeURIComponent(value)}
traditional===undefined&&(traditional=jQuery.ajaxSettings&&jQuery.ajaxSettings.traditional)
if(jQuery.isArray(a)||a.jquery&&!jQuery.isPlainObject(a))jQuery.each(a,function(){add(this.name,this.value)})
else for(prefix in a)buildParams(prefix,a[prefix],traditional,add)
return s.join("&").replace(r20,"+")}
jQuery.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error contextmenu".split(" "),function(i,name){jQuery.fn[name]=function(data,fn){return arguments.length>0?this.on(name,null,data,fn):this.trigger(name)}})
jQuery.fn.hover=function(fnOver,fnOut){return this.mouseenter(fnOver).mouseleave(fnOut||fnOver)}
var ajaxLocParts,ajaxLocation,ajax_nonce=jQuery.now(),ajax_rquery=/\?/,rhash=/#.*$/,rts=/([?&])_=[^&]*/,rheaders=/^(.*?):[ \t]*([^\r\n]*)\r?$/gm,rlocalProtocol=/^(?:about|app|app-storage|.+-extension|file|res|widget):$/,rnoContent=/^(?:GET|HEAD)$/,rprotocol=/^\/\//,rurl=/^([\w.+-]+:)(?:\/\/([^\/?#:]*)(?::(\d+)|)|)/,_load=jQuery.fn.load,prefilters={},transports={},allTypes="*/".concat("*")
try{ajaxLocation=location.href}catch(e){ajaxLocation=document.createElement("a")
ajaxLocation.href=""
ajaxLocation=ajaxLocation.href}ajaxLocParts=rurl.exec(ajaxLocation.toLowerCase())||[]
jQuery.fn.load=function(url,params,callback){if("string"!=typeof url&&_load)return _load.apply(this,arguments)
var selector,response,type,self=this,off=url.indexOf(" ")
if(off>=0){selector=url.slice(off,url.length)
url=url.slice(0,off)}if(jQuery.isFunction(params)){callback=params
params=undefined}else params&&"object"==typeof params&&(type="POST")
self.length>0&&jQuery.ajax({url:url,type:type,dataType:"html",data:params}).done(function(responseText){response=arguments
self.html(selector?jQuery("<div>").append(jQuery.parseHTML(responseText)).find(selector):responseText)}).complete(callback&&function(jqXHR,status){self.each(callback,response||[jqXHR.responseText,status,jqXHR])})
return this}
jQuery.each(["ajaxStart","ajaxStop","ajaxComplete","ajaxError","ajaxSuccess","ajaxSend"],function(i,type){jQuery.fn[type]=function(fn){return this.on(type,fn)}})
jQuery.each(["get","post"],function(i,method){jQuery[method]=function(url,data,callback,type){if(jQuery.isFunction(data)){type=type||callback
callback=data
data=undefined}return jQuery.ajax({url:url,type:method,dataType:type,data:data,success:callback})}})
jQuery.extend({active:0,lastModified:{},etag:{},ajaxSettings:{url:ajaxLocation,type:"GET",isLocal:rlocalProtocol.test(ajaxLocParts[1]),global:!0,processData:!0,async:!0,contentType:"application/x-www-form-urlencoded; charset=UTF-8",accepts:{"*":allTypes,text:"text/plain",html:"text/html",xml:"application/xml, text/xml",json:"application/json, text/javascript"},contents:{xml:/xml/,html:/html/,json:/json/},responseFields:{xml:"responseXML",text:"responseText"},converters:{"* text":window.String,"text html":!0,"text json":jQuery.parseJSON,"text xml":jQuery.parseXML},flatOptions:{url:!0,context:!0}},ajaxSetup:function(target,settings){return settings?ajaxExtend(ajaxExtend(target,jQuery.ajaxSettings),settings):ajaxExtend(jQuery.ajaxSettings,target)},ajaxPrefilter:addToPrefiltersOrTransports(prefilters),ajaxTransport:addToPrefiltersOrTransports(transports),ajax:function(url,options){function done(status,nativeStatusText,responses,headers){var isSuccess,success,error,response,modified,statusText=nativeStatusText
if(2!==state){state=2
timeoutTimer&&clearTimeout(timeoutTimer)
transport=undefined
responseHeadersString=headers||""
jqXHR.readyState=status>0?4:0
responses&&(response=ajaxHandleResponses(s,jqXHR,responses))
if(status>=200&&300>status||304===status){if(s.ifModified){modified=jqXHR.getResponseHeader("Last-Modified")
modified&&(jQuery.lastModified[cacheURL]=modified)
modified=jqXHR.getResponseHeader("etag")
modified&&(jQuery.etag[cacheURL]=modified)}if(204===status){isSuccess=!0
statusText="nocontent"}else if(304===status){isSuccess=!0
statusText="notmodified"}else{isSuccess=ajaxConvert(s,response)
statusText=isSuccess.state
success=isSuccess.data
error=isSuccess.error
isSuccess=!error}}else{error=statusText
if(status||!statusText){statusText="error"
0>status&&(status=0)}}jqXHR.status=status
jqXHR.statusText=(nativeStatusText||statusText)+""
isSuccess?deferred.resolveWith(callbackContext,[success,statusText,jqXHR]):deferred.rejectWith(callbackContext,[jqXHR,statusText,error])
jqXHR.statusCode(statusCode)
statusCode=undefined
fireGlobals&&globalEventContext.trigger(isSuccess?"ajaxSuccess":"ajaxError",[jqXHR,s,isSuccess?success:error])
completeDeferred.fireWith(callbackContext,[jqXHR,statusText])
if(fireGlobals){globalEventContext.trigger("ajaxComplete",[jqXHR,s]);--jQuery.active||jQuery.event.trigger("ajaxStop")}}}if("object"==typeof url){options=url
url=undefined}options=options||{}
var parts,i,cacheURL,responseHeadersString,timeoutTimer,fireGlobals,transport,responseHeaders,s=jQuery.ajaxSetup({},options),callbackContext=s.context||s,globalEventContext=s.context&&(callbackContext.nodeType||callbackContext.jquery)?jQuery(callbackContext):jQuery.event,deferred=jQuery.Deferred(),completeDeferred=jQuery.Callbacks("once memory"),statusCode=s.statusCode||{},requestHeaders={},requestHeadersNames={},state=0,strAbort="canceled",jqXHR={readyState:0,getResponseHeader:function(key){var match
if(2===state){if(!responseHeaders){responseHeaders={}
for(;match=rheaders.exec(responseHeadersString);)responseHeaders[match[1].toLowerCase()]=match[2]}match=responseHeaders[key.toLowerCase()]}return null==match?null:match},getAllResponseHeaders:function(){return 2===state?responseHeadersString:null},setRequestHeader:function(name,value){var lname=name.toLowerCase()
if(!state){name=requestHeadersNames[lname]=requestHeadersNames[lname]||name
requestHeaders[name]=value}return this},overrideMimeType:function(type){state||(s.mimeType=type)
return this},statusCode:function(map){var code
if(map)if(2>state)for(code in map)statusCode[code]=[statusCode[code],map[code]]
else jqXHR.always(map[jqXHR.status])
return this},abort:function(statusText){var finalText=statusText||strAbort
transport&&transport.abort(finalText)
done(0,finalText)
return this}}
deferred.promise(jqXHR).complete=completeDeferred.add
jqXHR.success=jqXHR.done
jqXHR.error=jqXHR.fail
s.url=((url||s.url||ajaxLocation)+"").replace(rhash,"").replace(rprotocol,ajaxLocParts[1]+"//")
s.type=options.method||options.type||s.method||s.type
s.dataTypes=jQuery.trim(s.dataType||"*").toLowerCase().match(core_rnotwhite)||[""]
if(null==s.crossDomain){parts=rurl.exec(s.url.toLowerCase())
s.crossDomain=!(!parts||parts[1]===ajaxLocParts[1]&&parts[2]===ajaxLocParts[2]&&(parts[3]||("http:"===parts[1]?80:443))==(ajaxLocParts[3]||("http:"===ajaxLocParts[1]?80:443)))}s.data&&s.processData&&"string"!=typeof s.data&&(s.data=jQuery.param(s.data,s.traditional))
inspectPrefiltersOrTransports(prefilters,s,options,jqXHR)
if(2===state)return jqXHR
fireGlobals=s.global
fireGlobals&&0===jQuery.active++&&jQuery.event.trigger("ajaxStart")
s.type=s.type.toUpperCase()
s.hasContent=!rnoContent.test(s.type)
cacheURL=s.url
if(!s.hasContent){if(s.data){cacheURL=s.url+=(ajax_rquery.test(cacheURL)?"&":"?")+s.data
delete s.data}s.cache===!1&&(s.url=rts.test(cacheURL)?cacheURL.replace(rts,"$1_="+ajax_nonce++):cacheURL+(ajax_rquery.test(cacheURL)?"&":"?")+"_="+ajax_nonce++)}if(s.ifModified){jQuery.lastModified[cacheURL]&&jqXHR.setRequestHeader("If-Modified-Since",jQuery.lastModified[cacheURL])
jQuery.etag[cacheURL]&&jqXHR.setRequestHeader("If-None-Match",jQuery.etag[cacheURL])}(s.data&&s.hasContent&&s.contentType!==!1||options.contentType)&&jqXHR.setRequestHeader("Content-Type",s.contentType)
jqXHR.setRequestHeader("Accept",s.dataTypes[0]&&s.accepts[s.dataTypes[0]]?s.accepts[s.dataTypes[0]]+("*"!==s.dataTypes[0]?", "+allTypes+"; q=0.01":""):s.accepts["*"])
for(i in s.headers)jqXHR.setRequestHeader(i,s.headers[i])
if(s.beforeSend&&(s.beforeSend.call(callbackContext,jqXHR,s)===!1||2===state))return jqXHR.abort()
strAbort="abort"
for(i in{success:1,error:1,complete:1})jqXHR[i](s[i])
transport=inspectPrefiltersOrTransports(transports,s,options,jqXHR)
if(transport){jqXHR.readyState=1
fireGlobals&&globalEventContext.trigger("ajaxSend",[jqXHR,s])
s.async&&s.timeout>0&&(timeoutTimer=setTimeout(function(){jqXHR.abort("timeout")},s.timeout))
try{state=1
transport.send(requestHeaders,done)}catch(e){if(!(2>state))throw e
done(-1,e)}}else done(-1,"No Transport")
return jqXHR},getScript:function(url,callback){return jQuery.get(url,undefined,callback,"script")},getJSON:function(url,data,callback){return jQuery.get(url,data,callback,"json")}})
jQuery.ajaxSetup({accepts:{script:"text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"},contents:{script:/(?:java|ecma)script/},converters:{"text script":function(text){jQuery.globalEval(text)
return text}}})
jQuery.ajaxPrefilter("script",function(s){s.cache===undefined&&(s.cache=!1)
if(s.crossDomain){s.type="GET"
s.global=!1}})
jQuery.ajaxTransport("script",function(s){if(s.crossDomain){var script,head=document.head||jQuery("head")[0]||document.documentElement
return{send:function(_,callback){script=document.createElement("script")
script.async=!0
s.scriptCharset&&(script.charset=s.scriptCharset)
script.src=s.url
script.onload=script.onreadystatechange=function(_,isAbort){if(isAbort||!script.readyState||/loaded|complete/.test(script.readyState)){script.onload=script.onreadystatechange=null
script.parentNode&&script.parentNode.removeChild(script)
script=null
isAbort||callback(200,"success")}}
head.insertBefore(script,head.firstChild)},abort:function(){script&&script.onload(undefined,!0)}}}})
var oldCallbacks=[],rjsonp=/(=)\?(?=&|$)|\?\?/
jQuery.ajaxSetup({jsonp:"callback",jsonpCallback:function(){var callback=oldCallbacks.pop()||jQuery.expando+"_"+ajax_nonce++
this[callback]=!0
return callback}})
jQuery.ajaxPrefilter("json jsonp",function(s,originalSettings,jqXHR){var callbackName,overwritten,responseContainer,jsonProp=s.jsonp!==!1&&(rjsonp.test(s.url)?"url":"string"==typeof s.data&&!(s.contentType||"").indexOf("application/x-www-form-urlencoded")&&rjsonp.test(s.data)&&"data")
if(jsonProp||"jsonp"===s.dataTypes[0]){callbackName=s.jsonpCallback=jQuery.isFunction(s.jsonpCallback)?s.jsonpCallback():s.jsonpCallback
jsonProp?s[jsonProp]=s[jsonProp].replace(rjsonp,"$1"+callbackName):s.jsonp!==!1&&(s.url+=(ajax_rquery.test(s.url)?"&":"?")+s.jsonp+"="+callbackName)
s.converters["script json"]=function(){responseContainer||jQuery.error(callbackName+" was not called")
return responseContainer[0]}
s.dataTypes[0]="json"
overwritten=window[callbackName]
window[callbackName]=function(){responseContainer=arguments}
jqXHR.always(function(){window[callbackName]=overwritten
if(s[callbackName]){s.jsonpCallback=originalSettings.jsonpCallback
oldCallbacks.push(callbackName)}responseContainer&&jQuery.isFunction(overwritten)&&overwritten(responseContainer[0])
responseContainer=overwritten=undefined})
return"script"}})
var xhrCallbacks,xhrSupported,xhrId=0,xhrOnUnloadAbort=window.ActiveXObject&&function(){var key
for(key in xhrCallbacks)xhrCallbacks[key](undefined,!0)}
jQuery.ajaxSettings.xhr=window.ActiveXObject?function(){return!this.isLocal&&createStandardXHR()||createActiveXHR()}:createStandardXHR
xhrSupported=jQuery.ajaxSettings.xhr()
jQuery.support.cors=!!xhrSupported&&"withCredentials"in xhrSupported
xhrSupported=jQuery.support.ajax=!!xhrSupported
xhrSupported&&jQuery.ajaxTransport(function(s){if(!s.crossDomain||jQuery.support.cors){var callback
return{send:function(headers,complete){var handle,i,xhr=s.xhr()
s.username?xhr.open(s.type,s.url,s.async,s.username,s.password):xhr.open(s.type,s.url,s.async)
if(s.xhrFields)for(i in s.xhrFields)xhr[i]=s.xhrFields[i]
s.mimeType&&xhr.overrideMimeType&&xhr.overrideMimeType(s.mimeType)
s.crossDomain||headers["X-Requested-With"]||(headers["X-Requested-With"]="XMLHttpRequest")
try{for(i in headers)xhr.setRequestHeader(i,headers[i])}catch(err){}xhr.send(s.hasContent&&s.data||null)
callback=function(_,isAbort){var status,responseHeaders,statusText,responses
try{if(callback&&(isAbort||4===xhr.readyState)){callback=undefined
if(handle){xhr.onreadystatechange=jQuery.noop
xhrOnUnloadAbort&&delete xhrCallbacks[handle]}if(isAbort)4!==xhr.readyState&&xhr.abort()
else{responses={}
status=xhr.status
responseHeaders=xhr.getAllResponseHeaders()
"string"==typeof xhr.responseText&&(responses.text=xhr.responseText)
try{statusText=xhr.statusText}catch(e){statusText=""}status||!s.isLocal||s.crossDomain?1223===status&&(status=204):status=responses.text?200:404}}}catch(firefoxAccessException){isAbort||complete(-1,firefoxAccessException)}responses&&complete(status,statusText,responses,responseHeaders)}
if(s.async)if(4===xhr.readyState)setTimeout(callback)
else{handle=++xhrId
if(xhrOnUnloadAbort){if(!xhrCallbacks){xhrCallbacks={}
jQuery(window).unload(xhrOnUnloadAbort)}xhrCallbacks[handle]=callback}xhr.onreadystatechange=callback}else callback()},abort:function(){callback&&callback(undefined,!0)}}}})
var fxNow,timerId,rfxtypes=/^(?:toggle|show|hide)$/,rfxnum=new RegExp("^(?:([+-])=|)("+core_pnum+")([a-z%]*)$","i"),rrun=/queueHooks$/,animationPrefilters=[defaultPrefilter],tweeners={"*":[function(prop,value){var end,unit,tween=this.createTween(prop,value),parts=rfxnum.exec(value),target=tween.cur(),start=+target||0,scale=1,maxIterations=20
if(parts){end=+parts[2]
unit=parts[3]||(jQuery.cssNumber[prop]?"":"px")
if("px"!==unit&&start){start=jQuery.css(tween.elem,prop,!0)||end||1
do{scale=scale||".5"
start/=scale
jQuery.style(tween.elem,prop,start+unit)}while(scale!==(scale=tween.cur()/target)&&1!==scale&&--maxIterations)}tween.unit=unit
tween.start=start
tween.end=parts[1]?start+(parts[1]+1)*end:end}return tween}]}
jQuery.Animation=jQuery.extend(Animation,{tweener:function(props,callback){if(jQuery.isFunction(props)){callback=props
props=["*"]}else props=props.split(" ")
for(var prop,index=0,length=props.length;length>index;index++){prop=props[index]
tweeners[prop]=tweeners[prop]||[]
tweeners[prop].unshift(callback)}},prefilter:function(callback,prepend){prepend?animationPrefilters.unshift(callback):animationPrefilters.push(callback)}})
jQuery.Tween=Tween
Tween.prototype={constructor:Tween,init:function(elem,options,prop,end,easing,unit){this.elem=elem
this.prop=prop
this.easing=easing||"swing"
this.options=options
this.start=this.now=this.cur()
this.end=end
this.unit=unit||(jQuery.cssNumber[prop]?"":"px")},cur:function(){var hooks=Tween.propHooks[this.prop]
return hooks&&hooks.get?hooks.get(this):Tween.propHooks._default.get(this)},run:function(percent){var eased,hooks=Tween.propHooks[this.prop]
this.pos=eased=this.options.duration?jQuery.easing[this.easing](percent,this.options.duration*percent,0,1,this.options.duration):percent
this.now=(this.end-this.start)*eased+this.start
this.options.step&&this.options.step.call(this.elem,this.now,this)
hooks&&hooks.set?hooks.set(this):Tween.propHooks._default.set(this)
return this}}
Tween.prototype.init.prototype=Tween.prototype
Tween.propHooks={_default:{get:function(tween){var result
if(null!=tween.elem[tween.prop]&&(!tween.elem.style||null==tween.elem.style[tween.prop]))return tween.elem[tween.prop]
result=jQuery.css(tween.elem,tween.prop,"")
return result&&"auto"!==result?result:0},set:function(tween){jQuery.fx.step[tween.prop]?jQuery.fx.step[tween.prop](tween):tween.elem.style&&(null!=tween.elem.style[jQuery.cssProps[tween.prop]]||jQuery.cssHooks[tween.prop])?jQuery.style(tween.elem,tween.prop,tween.now+tween.unit):tween.elem[tween.prop]=tween.now}}}
Tween.propHooks.scrollTop=Tween.propHooks.scrollLeft={set:function(tween){tween.elem.nodeType&&tween.elem.parentNode&&(tween.elem[tween.prop]=tween.now)}}
jQuery.each(["toggle","show","hide"],function(i,name){var cssFn=jQuery.fn[name]
jQuery.fn[name]=function(speed,easing,callback){return null==speed||"boolean"==typeof speed?cssFn.apply(this,arguments):this.animate(genFx(name,!0),speed,easing,callback)}})
jQuery.fn.extend({fadeTo:function(speed,to,easing,callback){return this.filter(isHidden).css("opacity",0).show().end().animate({opacity:to},speed,easing,callback)},animate:function(prop,speed,easing,callback){var empty=jQuery.isEmptyObject(prop),optall=jQuery.speed(speed,easing,callback),doAnimation=function(){var anim=Animation(this,jQuery.extend({},prop),optall)
doAnimation.finish=function(){anim.stop(!0)};(empty||jQuery._data(this,"finish"))&&anim.stop(!0)}
doAnimation.finish=doAnimation
return empty||optall.queue===!1?this.each(doAnimation):this.queue(optall.queue,doAnimation)},stop:function(type,clearQueue,gotoEnd){var stopQueue=function(hooks){var stop=hooks.stop
delete hooks.stop
stop(gotoEnd)}
if("string"!=typeof type){gotoEnd=clearQueue
clearQueue=type
type=undefined}clearQueue&&type!==!1&&this.queue(type||"fx",[])
return this.each(function(){var dequeue=!0,index=null!=type&&type+"queueHooks",timers=jQuery.timers,data=jQuery._data(this)
if(index)data[index]&&data[index].stop&&stopQueue(data[index])
else for(index in data)data[index]&&data[index].stop&&rrun.test(index)&&stopQueue(data[index])
for(index=timers.length;index--;)if(timers[index].elem===this&&(null==type||timers[index].queue===type)){timers[index].anim.stop(gotoEnd)
dequeue=!1
timers.splice(index,1)}(dequeue||!gotoEnd)&&jQuery.dequeue(this,type)})},finish:function(type){type!==!1&&(type=type||"fx")
return this.each(function(){var index,data=jQuery._data(this),queue=data[type+"queue"],hooks=data[type+"queueHooks"],timers=jQuery.timers,length=queue?queue.length:0
data.finish=!0
jQuery.queue(this,type,[])
hooks&&hooks.cur&&hooks.cur.finish&&hooks.cur.finish.call(this)
for(index=timers.length;index--;)if(timers[index].elem===this&&timers[index].queue===type){timers[index].anim.stop(!0)
timers.splice(index,1)}for(index=0;length>index;index++)queue[index]&&queue[index].finish&&queue[index].finish.call(this)
delete data.finish})}})
jQuery.each({slideDown:genFx("show"),slideUp:genFx("hide"),slideToggle:genFx("toggle"),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"},fadeToggle:{opacity:"toggle"}},function(name,props){jQuery.fn[name]=function(speed,easing,callback){return this.animate(props,speed,easing,callback)}})
jQuery.speed=function(speed,easing,fn){var opt=speed&&"object"==typeof speed?jQuery.extend({},speed):{complete:fn||!fn&&easing||jQuery.isFunction(speed)&&speed,duration:speed,easing:fn&&easing||easing&&!jQuery.isFunction(easing)&&easing}
opt.duration=jQuery.fx.off?0:"number"==typeof opt.duration?opt.duration:opt.duration in jQuery.fx.speeds?jQuery.fx.speeds[opt.duration]:jQuery.fx.speeds._default;(null==opt.queue||opt.queue===!0)&&(opt.queue="fx")
opt.old=opt.complete
opt.complete=function(){jQuery.isFunction(opt.old)&&opt.old.call(this)
opt.queue&&jQuery.dequeue(this,opt.queue)}
return opt}
jQuery.easing={linear:function(p){return p},swing:function(p){return.5-Math.cos(p*Math.PI)/2}}
jQuery.timers=[]
jQuery.fx=Tween.prototype.init
jQuery.fx.tick=function(){var timer,timers=jQuery.timers,i=0
fxNow=jQuery.now()
for(;i<timers.length;i++){timer=timers[i]
timer()||timers[i]!==timer||timers.splice(i--,1)}timers.length||jQuery.fx.stop()
fxNow=undefined}
jQuery.fx.timer=function(timer){timer()&&jQuery.timers.push(timer)&&jQuery.fx.start()}
jQuery.fx.interval=13
jQuery.fx.start=function(){timerId||(timerId=setInterval(jQuery.fx.tick,jQuery.fx.interval))}
jQuery.fx.stop=function(){clearInterval(timerId)
timerId=null}
jQuery.fx.speeds={slow:600,fast:200,_default:400}
jQuery.fx.step={}
jQuery.expr&&jQuery.expr.filters&&(jQuery.expr.filters.animated=function(elem){return jQuery.grep(jQuery.timers,function(fn){return elem===fn.elem}).length})
jQuery.fn.offset=function(options){if(arguments.length)return options===undefined?this:this.each(function(i){jQuery.offset.setOffset(this,options,i)})
var docElem,win,box={top:0,left:0},elem=this[0],doc=elem&&elem.ownerDocument
if(doc){docElem=doc.documentElement
if(!jQuery.contains(docElem,elem))return box
typeof elem.getBoundingClientRect!==core_strundefined&&(box=elem.getBoundingClientRect())
win=getWindow(doc)
return{top:box.top+(win.pageYOffset||docElem.scrollTop)-(docElem.clientTop||0),left:box.left+(win.pageXOffset||docElem.scrollLeft)-(docElem.clientLeft||0)}}}
jQuery.offset={setOffset:function(elem,options,i){var position=jQuery.css(elem,"position")
"static"===position&&(elem.style.position="relative")
var curTop,curLeft,curElem=jQuery(elem),curOffset=curElem.offset(),curCSSTop=jQuery.css(elem,"top"),curCSSLeft=jQuery.css(elem,"left"),calculatePosition=("absolute"===position||"fixed"===position)&&jQuery.inArray("auto",[curCSSTop,curCSSLeft])>-1,props={},curPosition={}
if(calculatePosition){curPosition=curElem.position()
curTop=curPosition.top
curLeft=curPosition.left}else{curTop=parseFloat(curCSSTop)||0
curLeft=parseFloat(curCSSLeft)||0}jQuery.isFunction(options)&&(options=options.call(elem,i,curOffset))
null!=options.top&&(props.top=options.top-curOffset.top+curTop)
null!=options.left&&(props.left=options.left-curOffset.left+curLeft)
"using"in options?options.using.call(elem,props):curElem.css(props)}}
jQuery.fn.extend({position:function(){if(this[0]){var offsetParent,offset,parentOffset={top:0,left:0},elem=this[0]
if("fixed"===jQuery.css(elem,"position"))offset=elem.getBoundingClientRect()
else{offsetParent=this.offsetParent()
offset=this.offset()
jQuery.nodeName(offsetParent[0],"html")||(parentOffset=offsetParent.offset())
parentOffset.top+=jQuery.css(offsetParent[0],"borderTopWidth",!0)
parentOffset.left+=jQuery.css(offsetParent[0],"borderLeftWidth",!0)}return{top:offset.top-parentOffset.top-jQuery.css(elem,"marginTop",!0),left:offset.left-parentOffset.left-jQuery.css(elem,"marginLeft",!0)}}},offsetParent:function(){return this.map(function(){for(var offsetParent=this.offsetParent||document.documentElement;offsetParent&&!jQuery.nodeName(offsetParent,"html")&&"static"===jQuery.css(offsetParent,"position");)offsetParent=offsetParent.offsetParent
return offsetParent||document.documentElement})}})
jQuery.each({scrollLeft:"pageXOffset",scrollTop:"pageYOffset"},function(method,prop){var top=/Y/.test(prop)
jQuery.fn[method]=function(val){return jQuery.access(this,function(elem,method,val){var win=getWindow(elem)
if(val===undefined)return win?prop in win?win[prop]:win.document.documentElement[method]:elem[method]
win?win.scrollTo(top?jQuery(win).scrollLeft():val,top?val:jQuery(win).scrollTop()):elem[method]=val
return void 0},method,val,arguments.length,null)}})
jQuery.each({Height:"height",Width:"width"},function(name,type){jQuery.each({padding:"inner"+name,content:type,"":"outer"+name},function(defaultExtra,funcName){jQuery.fn[funcName]=function(margin,value){var chainable=arguments.length&&(defaultExtra||"boolean"!=typeof margin),extra=defaultExtra||(margin===!0||value===!0?"margin":"border")
return jQuery.access(this,function(elem,type,value){var doc
if(jQuery.isWindow(elem))return elem.document.documentElement["client"+name]
if(9===elem.nodeType){doc=elem.documentElement
return Math.max(elem.body["scroll"+name],doc["scroll"+name],elem.body["offset"+name],doc["offset"+name],doc["client"+name])}return value===undefined?jQuery.css(elem,type,extra):jQuery.style(elem,type,value,extra)},type,chainable?margin:undefined,chainable,null)}})})
window.jQuery=window.$=jQuery
"function"==typeof define&&define.amd&&define.amd.jQuery&&define("jquery",[],function(){return jQuery})}(window)

!function(){function r(a,c,d){if(a===c)return 0!==a||1/a==1/c
if(null==a||null==c)return a===c
a._chain&&(a=a._wrapped)
c._chain&&(c=c._wrapped)
if(a.isEqual&&b.isFunction(a.isEqual))return a.isEqual(c)
if(c.isEqual&&b.isFunction(c.isEqual))return c.isEqual(a)
var e=l.call(a)
if(e!=l.call(c))return!1
switch(e){case"[object String]":return a==""+c
case"[object Number]":return a!=+a?c!=+c:0==a?1/a==1/c:a==+c
case"[object Date]":case"[object Boolean]":return+a==+c
case"[object RegExp]":return a.source==c.source&&a.global==c.global&&a.multiline==c.multiline&&a.ignoreCase==c.ignoreCase}if("object"!=typeof a||"object"!=typeof c)return!1
for(var f=d.length;f--;)if(d[f]==a)return!0
d.push(a)
var f=0,g=!0
if("[object Array]"==e){if(f=a.length,g=f==c.length)for(;f--&&(g=f in a==f in c&&r(a[f],c[f],d)););}else{if("constructor"in a!="constructor"in c||a.constructor!=c.constructor)return!1
for(var h in a)if(b.has(a,h)&&(f++,!(g=b.has(c,h)&&r(a[h],c[h],d))))break
if(g){for(h in c)if(b.has(c,h)&&!f--)break
g=!f}}d.pop()
return g}var s=this,I=s._,o={},k=Array.prototype,p=Object.prototype,i=k.slice,J=k.unshift,l=p.toString,K=p.hasOwnProperty,y=k.forEach,z=k.map,A=k.reduce,B=k.reduceRight,C=k.filter,D=k.every,E=k.some,q=k.indexOf,F=k.lastIndexOf,p=Array.isArray,L=Object.keys,t=Function.prototype.bind,b=function(a){return new m(a)}
"undefined"!=typeof exports?("undefined"!=typeof module&&module.exports&&(exports=module.exports=b),exports._=b):s._=b
b.VERSION="1.3.3"
var j=b.each=b.forEach=function(a,c,d){if(null!=a)if(y&&a.forEach===y)a.forEach(c,d)
else if(a.length===+a.length)for(var e=0,f=a.length;f>e&&!(e in a&&c.call(d,a[e],e,a)===o);e++);else for(e in a)if(b.has(a,e)&&c.call(d,a[e],e,a)===o)break}
b.map=b.collect=function(a,c,b){var e=[]
if(null==a)return e
if(z&&a.map===z)return a.map(c,b)
j(a,function(a,g,h){e[e.length]=c.call(b,a,g,h)})
a.length===+a.length&&(e.length=a.length)
return e}
b.reduce=b.foldl=b.inject=function(a,c,d,e){var f=arguments.length>2
null==a&&(a=[])
if(A&&a.reduce===A){e&&(c=b.bind(c,e))
return f?a.reduce(c,d):a.reduce(c)}j(a,function(a,b,i){if(f)d=c.call(e,d,a,b,i)
else{d=a
f=!0}})
if(!f)throw new TypeError("Reduce of empty array with no initial value")
return d}
b.reduceRight=b.foldr=function(a,c,d,e){var f=arguments.length>2
null==a&&(a=[])
if(B&&a.reduceRight===B){e&&(c=b.bind(c,e))
return f?a.reduceRight(c,d):a.reduceRight(c)}var g=b.toArray(a).reverse()
e&&!f&&(c=b.bind(c,e))
return f?b.reduce(g,c,d,e):b.reduce(g,c)}
b.find=b.detect=function(a,c,b){var e
G(a,function(a,g,h){if(c.call(b,a,g,h)){e=a
return!0}})
return e}
b.filter=b.select=function(a,c,b){var e=[]
if(null==a)return e
if(C&&a.filter===C)return a.filter(c,b)
j(a,function(a,g,h){c.call(b,a,g,h)&&(e[e.length]=a)})
return e}
b.reject=function(a,c,b){var e=[]
if(null==a)return e
j(a,function(a,g,h){c.call(b,a,g,h)||(e[e.length]=a)})
return e}
b.every=b.all=function(a,c,b){var e=!0
if(null==a)return e
if(D&&a.every===D)return a.every(c,b)
j(a,function(a,g,h){return(e=e&&c.call(b,a,g,h))?void 0:o})
return!!e}
var G=b.some=b.any=function(a,c,d){c||(c=b.identity)
var e=!1
if(null==a)return e
if(E&&a.some===E)return a.some(c,d)
j(a,function(a,b,h){return e||(e=c.call(d,a,b,h))?o:void 0})
return!!e}
b.include=b.contains=function(a,c){var b=!1
return null==a?b:q&&a.indexOf===q?-1!=a.indexOf(c):b=G(a,function(a){return a===c})}
b.invoke=function(a,c){var d=i.call(arguments,2)
return b.map(a,function(a){return(b.isFunction(c)?c||a:a[c]).apply(a,d)})}
b.pluck=function(a,c){return b.map(a,function(a){return a[c]})}
b.max=function(a,c,d){if(!c&&b.isArray(a)&&a[0]===+a[0])return Math.max.apply(Math,a)
if(!c&&b.isEmpty(a))return-1/0
var e={computed:-1/0}
j(a,function(a,b,h){b=c?c.call(d,a,b,h):a
b>=e.computed&&(e={value:a,computed:b})})
return e.value}
b.min=function(a,c,d){if(!c&&b.isArray(a)&&a[0]===+a[0])return Math.min.apply(Math,a)
if(!c&&b.isEmpty(a))return 1/0
var e={computed:1/0}
j(a,function(a,b,h){b=c?c.call(d,a,b,h):a
b<e.computed&&(e={value:a,computed:b})})
return e.value}
b.shuffle=function(a){var d,b=[]
j(a,function(a,f){d=Math.floor(Math.random()*(f+1))
b[f]=b[d]
b[d]=a})
return b}
b.sortBy=function(a,c,d){var e=b.isFunction(c)?c:function(a){return a[c]}
return b.pluck(b.map(a,function(a,b,c){return{value:a,criteria:e.call(d,a,b,c)}}).sort(function(a,b){var c=a.criteria,d=b.criteria
return void 0===c?1:void 0===d?-1:d>c?-1:c>d?1:0}),"value")}
b.groupBy=function(a,c){var d={},e=b.isFunction(c)?c:function(a){return a[c]}
j(a,function(a,b){var c=e(a,b);(d[c]||(d[c]=[])).push(a)})
return d}
b.sortedIndex=function(a,c,d){d||(d=b.identity)
for(var e=0,f=a.length;f>e;){var g=e+f>>1
d(a[g])<d(c)?e=g+1:f=g}return e}
b.toArray=function(a){return a?b.isArray(a)||b.isArguments(a)?i.call(a):a.toArray&&b.isFunction(a.toArray)?a.toArray():b.values(a):[]}
b.size=function(a){return b.isArray(a)?a.length:b.keys(a).length}
b.first=b.head=b.take=function(a,b,d){return null==b||d?a[0]:i.call(a,0,b)}
b.initial=function(a,b,d){return i.call(a,0,a.length-(null==b||d?1:b))}
b.last=function(a,b,d){return null==b||d?a[a.length-1]:i.call(a,Math.max(a.length-b,0))}
b.rest=b.tail=function(a,b,d){return i.call(a,null==b||d?1:b)}
b.compact=function(a){return b.filter(a,function(a){return!!a})}
b.flatten=function(a,c){return b.reduce(a,function(a,e){if(b.isArray(e))return a.concat(c?e:b.flatten(e))
a[a.length]=e
return a},[])}
b.without=function(a){return b.difference(a,i.call(arguments,1))}
b.uniq=b.unique=function(a,c,d){var d=d?b.map(a,d):a,e=[]
a.length<3&&(c=!0)
b.reduce(d,function(d,g,h){if(c?b.last(d)!==g||!d.length:!b.include(d,g)){d.push(g)
e.push(a[h])}return d},[])
return e}
b.union=function(){return b.uniq(b.flatten(arguments,!0))}
b.intersection=b.intersect=function(a){var c=i.call(arguments,1)
return b.filter(b.uniq(a),function(a){return b.every(c,function(c){return b.indexOf(c,a)>=0})})}
b.difference=function(a){var c=b.flatten(i.call(arguments,1),!0)
return b.filter(a,function(a){return!b.include(c,a)})}
b.zip=function(){for(var a=i.call(arguments),c=b.max(b.pluck(a,"length")),d=Array(c),e=0;c>e;e++)d[e]=b.pluck(a,""+e)
return d}
b.indexOf=function(a,c,d){if(null==a)return-1
var e
if(d){d=b.sortedIndex(a,c)
return a[d]===c?d:-1}if(q&&a.indexOf===q)return a.indexOf(c)
d=0
for(e=a.length;e>d;d++)if(d in a&&a[d]===c)return d
return-1}
b.lastIndexOf=function(a,b){if(null==a)return-1
if(F&&a.lastIndexOf===F)return a.lastIndexOf(b)
for(var d=a.length;d--;)if(d in a&&a[d]===b)return d
return-1}
b.range=function(a,b,d){if(arguments.length<=1){b=a||0
a=0}for(var d=arguments[2]||1,e=Math.max(Math.ceil((b-a)/d),0),f=0,g=Array(e);e>f;){g[f++]=a
a+=d}return g}
var H=function(){}
b.bind=function(a,c){var d,e
if(a.bind===t&&t)return t.apply(a,i.call(arguments,1))
if(!b.isFunction(a))throw new TypeError
e=i.call(arguments,2)
return d=function(){if(!(this instanceof d))return a.apply(c,e.concat(i.call(arguments)))
H.prototype=a.prototype
var b=new H,g=a.apply(b,e.concat(i.call(arguments)))
return Object(g)===g?g:b}}
b.bindAll=function(a){var c=i.call(arguments,1)
0==c.length&&(c=b.functions(a))
j(c,function(c){a[c]=b.bind(a[c],a)})
return a}
b.memoize=function(a,c){var d={}
c||(c=b.identity)
return function(){var e=c.apply(this,arguments)
return b.has(d,e)?d[e]:d[e]=a.apply(this,arguments)}}
b.delay=function(a,b){var d=i.call(arguments,2)
return setTimeout(function(){return a.apply(null,d)},b)}
b.defer=function(a){return b.delay.apply(b,[a,1].concat(i.call(arguments,1)))}
b.throttle=function(a,c){var d,e,f,g,h,i,j=b.debounce(function(){h=g=!1},c)
return function(){d=this
e=arguments
f||(f=setTimeout(function(){f=null
h&&a.apply(d,e)
j()},c))
g?h=!0:i=a.apply(d,e)
j()
g=!0
return i}}
b.debounce=function(a,b,d){var e
return function(){var f=this,g=arguments
d&&!e&&a.apply(f,g)
clearTimeout(e)
e=setTimeout(function(){e=null
d||a.apply(f,g)},b)}}
b.once=function(a){var d,b=!1
return function(){if(b)return d
b=!0
return d=a.apply(this,arguments)}}
b.wrap=function(a,b){return function(){var d=[a].concat(i.call(arguments,0))
return b.apply(this,d)}}
b.compose=function(){var a=arguments
return function(){for(var b=arguments,d=a.length-1;d>=0;d--)b=[a[d].apply(this,b)]
return b[0]}}
b.after=function(a,b){return 0>=a?b():function(){return--a<1?b.apply(this,arguments):void 0}}
b.keys=L||function(a){if(a!==Object(a))throw new TypeError("Invalid object")
var d,c=[]
for(d in a)b.has(a,d)&&(c[c.length]=d)
return c}
b.values=function(a){return b.map(a,b.identity)}
b.functions=b.methods=function(a){var d,c=[]
for(d in a)b.isFunction(a[d])&&c.push(d)
return c.sort()}
b.extend=function(a){j(i.call(arguments,1),function(b){for(var d in b)a[d]=b[d]})
return a}
b.pick=function(a){var c={}
j(b.flatten(i.call(arguments,1)),function(b){b in a&&(c[b]=a[b])})
return c}
b.defaults=function(a){j(i.call(arguments,1),function(b){for(var d in b)null==a[d]&&(a[d]=b[d])})
return a}
b.clone=function(a){return b.isObject(a)?b.isArray(a)?a.slice():b.extend({},a):a}
b.tap=function(a,b){b(a)
return a}
b.isEqual=function(a,b){return r(a,b,[])}
b.isEmpty=function(a){if(null==a)return!0
if(b.isArray(a)||b.isString(a))return 0===a.length
for(var c in a)if(b.has(a,c))return!1
return!0}
b.isElement=function(a){return!(!a||1!=a.nodeType)}
b.isArray=p||function(a){return"[object Array]"==l.call(a)}
b.isObject=function(a){return a===Object(a)}
b.isArguments=function(a){return"[object Arguments]"==l.call(a)}
b.isArguments(arguments)||(b.isArguments=function(a){return!(!a||!b.has(a,"callee"))})
b.isFunction=function(a){return"[object Function]"==l.call(a)}
b.isString=function(a){return"[object String]"==l.call(a)}
b.isNumber=function(a){return"[object Number]"==l.call(a)}
b.isFinite=function(a){return b.isNumber(a)&&isFinite(a)}
b.isNaN=function(a){return a!==a}
b.isBoolean=function(a){return a===!0||a===!1||"[object Boolean]"==l.call(a)}
b.isDate=function(a){return"[object Date]"==l.call(a)}
b.isRegExp=function(a){return"[object RegExp]"==l.call(a)}
b.isNull=function(a){return null===a}
b.isUndefined=function(a){return void 0===a}
b.has=function(a,b){return K.call(a,b)}
b.noConflict=function(){s._=I
return this}
b.identity=function(a){return a}
b.times=function(a,b,d){for(var e=0;a>e;e++)b.call(d,e)}
b.escape=function(a){return(""+a).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#x27;").replace(/\//g,"&#x2F;")}
b.result=function(a,c){if(null==a)return null
var d=a[c]
return b.isFunction(d)?d.call(a):d}
b.mixin=function(a){j(b.functions(a),function(c){M(c,b[c]=a[c])})}
var N=0
b.uniqueId=function(a){var b=N++
return a?a+b:b}
b.templateSettings={evaluate:/<%([\s\S]+?)%>/g,interpolate:/<%=([\s\S]+?)%>/g,escape:/<%-([\s\S]+?)%>/g}
var v,u=/.^/,n={"\\":"\\","'":"'",r:"\r",n:"\n",t:"	",u2028:"\u2028",u2029:"\u2029"}
for(v in n)n[n[v]]=v
var O=/\\|'|\r|\n|\t|\u2028|\u2029/g,P=/\\(\\|'|r|n|t|u2028|u2029)/g,w=function(a){return a.replace(P,function(a,b){return n[b]})}
b.template=function(a,c,d){d=b.defaults(d||{},b.templateSettings)
a="__p+='"+a.replace(O,function(a){return"\\"+n[a]}).replace(d.escape||u,function(a,b){return"'+\n_.escape("+w(b)+")+\n'"}).replace(d.interpolate||u,function(a,b){return"'+\n("+w(b)+")+\n'"}).replace(d.evaluate||u,function(a,b){return"';\n"+w(b)+"\n;__p+='"})+"';\n"
d.variable||(a="with(obj||{}){\n"+a+"}\n")
var a="var __p='';var print=function(){__p+=Array.prototype.join.call(arguments, '')};\n"+a+"return __p;\n",e=new Function(d.variable||"obj","_",a)
if(c)return e(c,b)
c=function(a){return e.call(this,a,b)}
c.source="function("+(d.variable||"obj")+"){\n"+a+"}"
return c}
b.chain=function(a){return b(a).chain()}
var m=function(a){this._wrapped=a}
b.prototype=m.prototype
var x=function(a,c){return c?b(a).chain():a},M=function(a,c){m.prototype[a]=function(){var a=i.call(arguments)
J.call(a,this._wrapped)
return x(c.apply(b,a),this._chain)}}
b.mixin(b)
j("pop,push,reverse,shift,sort,splice,unshift".split(","),function(a){var b=k[a]
m.prototype[a]=function(){var d=this._wrapped
b.apply(d,arguments)
var e=d.length;("shift"==a||"splice"==a)&&0===e&&delete d[0]
return x(d,this._chain)}})
j(["concat","join","slice"],function(a){var b=k[a]
m.prototype[a]=function(){return x(b.apply(this._wrapped,arguments),this._chain)}})
m.prototype.chain=function(){this._chain=!0
return this}
m.prototype.value=function(){return this._wrapped}}.call(this)

!function($){function stringify(value){return $.toJSON?$.toJSON(value):JSON&&"function"==typeof JSON.stringify?JSON.stringify(value):value+""}function parse(value){if($.evalJSON)return $.evalJSON(value)
if(JSON&&"function"==typeof JSON.parse)try{return JSON.parse(value)}catch(e){return value}else try{return Function("return "+value)()}catch(e){return null}}function createCookie(name,value,days){var expires
if(days){var date=new Date
date.setTime(date.getTime()+1e3*60*60*24*days)
expires="; expires="+date.toGMTString()}else expires=""
document.cookie=name+"="+stringify(value)+expires+"; path=/"}function eraseCookie(name){createCookie(name,"",-1)}function readCookie(name){for(var nameEQ=name+"=",ca=document.cookie.split(";"),i=0;i<ca.length;i++){for(var c=ca[i];" "==c.charAt(0);)c=c.substring(1,c.length)
if(0==c.indexOf(nameEQ))return parse(c.substring(nameEQ.length,c.length))}return null}$.cookie=function(){var a=arguments
return a[1]&&a[1].erase?eraseCookie(a[0]):a.length>1?createCookie(a[0],a[1],a[2]):readCookie(a[0])}}(jQuery)

!function($){function refresh(){var data=prepareData(this)
isNaN(data.datetime)||$(this).text(inWords(data.datetime))
return this}function prepareData(element){element=$(element)
if(!element.data("timeago")){element.data("timeago",{datetime:$t.datetime(element)})
var text=$.trim(element.text())
text.length>0&&element.attr("title",text)}return element.data("timeago")}function inWords(date){return $t.inWords(distance(date))}function distance(date){return(new Date).getTime()-date.getTime()}$.timeago=function(timestamp){return timestamp instanceof Date?inWords(timestamp):"string"==typeof timestamp?inWords($.timeago.parse(timestamp)):inWords($.timeago.datetime(timestamp))}
var $t=$.timeago
$.extend($.timeago,{settings:{refreshMillis:6e4,allowFuture:!1,strings:{prefixAgo:null,prefixFromNow:null,suffixAgo:"ago",suffixFromNow:"from now",seconds:"less than a minute",minute:"a minute",minutes:"%d minutes",hour:"an hour",hours:"%d hours",day:"a day",days:"%d days",month:"a month",months:"%d months",year:"a year",years:"%d years",numbers:[]}},inWords:function(distanceMillis){function substitute(stringOrFunction,number){var string=$.isFunction(stringOrFunction)?stringOrFunction(number,distanceMillis):stringOrFunction,value=$l.numbers&&$l.numbers[number]||number
return string.replace(/%d/i,value)}var $l=this.settings.strings,prefix=$l.prefixAgo,suffix=$l.suffixAgo
if(this.settings.allowFuture){if(0>distanceMillis){prefix=$l.prefixFromNow
suffix=$l.suffixFromNow}distanceMillis=Math.abs(distanceMillis)}var seconds=distanceMillis/1e3,minutes=seconds/60,hours=minutes/60,days=hours/24,years=days/365,words=45>seconds&&substitute($l.seconds,Math.round(seconds))||90>seconds&&substitute($l.minute,1)||45>minutes&&substitute($l.minutes,Math.round(minutes))||90>minutes&&substitute($l.hour,1)||24>hours&&substitute($l.hours,Math.round(hours))||48>hours&&substitute($l.day,1)||30>days&&substitute($l.days,Math.floor(days))||60>days&&substitute($l.month,1)||365>days&&substitute($l.months,Math.floor(days/30))||2>years&&substitute($l.year,1)||substitute($l.years,Math.floor(years))
return $.trim([prefix,words,suffix].join(" "))},parse:function(iso8601){var s=$.trim(iso8601)
s=s.replace(/\.\d\d\d+/,"")
s=s.replace(/-/,"/").replace(/-/,"/")
s=s.replace(/T/," ").replace(/Z/," UTC")
s=s.replace(/([\+\-]\d\d)\:?(\d\d)/," $1$2")
return new Date(s)},datetime:function(elem){var isTime="time"===$(elem).get(0).tagName.toLowerCase(),iso8601=isTime?$(elem).attr("datetime"):$(elem).attr("title")
return $t.parse(iso8601)}})
$.fn.timeago=function(){var self=this
self.each(refresh)
var $s=$t.settings
$s.refreshMillis>0&&setInterval(function(){self.each(refresh)},$s.refreshMillis)
return self}
document.createElement("abbr")
document.createElement("time")}(jQuery)

var dateFormat=function(){var token=/d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'/g,timezone=/\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[-+]\d{4})?)\b/g,timezoneClip=/[^-+\dA-Z]/g,pad=function(val,len){val=String(val)
len=len||2
for(;val.length<len;)val="0"+val
return val}
return function(date,mask,utc){var dF=dateFormat
if(1==arguments.length&&"[object String]"==Object.prototype.toString.call(date)&&!/\d/.test(date)){mask=date
date=void 0}date=date?new Date(date):new Date
if(isNaN(date))throw SyntaxError("invalid date")
mask=String(dF.masks[mask]||mask||dF.masks["default"])
if("UTC:"==mask.slice(0,4)){mask=mask.slice(4)
utc=!0}var _=utc?"getUTC":"get",d=date[_+"Date"](),D=date[_+"Day"](),m=date[_+"Month"](),y=date[_+"FullYear"](),H=date[_+"Hours"](),M=date[_+"Minutes"](),s=date[_+"Seconds"](),L=date[_+"Milliseconds"](),o=utc?0:date.getTimezoneOffset(),flags={d:d,dd:pad(d),ddd:dF.i18n.dayNames[D],dddd:dF.i18n.dayNames[D+7],m:m+1,mm:pad(m+1),mmm:dF.i18n.monthNames[m],mmmm:dF.i18n.monthNames[m+12],yy:String(y).slice(2),yyyy:y,h:H%12||12,hh:pad(H%12||12),H:H,HH:pad(H),M:M,MM:pad(M),s:s,ss:pad(s),l:pad(L,3),L:pad(L>99?Math.round(L/10):L),t:12>H?"a":"p",tt:12>H?"am":"pm",T:12>H?"A":"P",TT:12>H?"AM":"PM",Z:utc?"UTC":(String(date).match(timezone)||[""]).pop().replace(timezoneClip,""),o:(o>0?"-":"+")+pad(100*Math.floor(Math.abs(o)/60)+Math.abs(o)%60,4),S:["th","st","nd","rd"][d%10>3?0:(10!=d%100-d%10)*d%10]}
return mask.replace(token,function($0){return $0 in flags?flags[$0]:$0.slice(1,$0.length-1)})}}()
dateFormat.masks={"default":"ddd mmm dd yyyy HH:MM:ss",shortDate:"m/d/yy",mediumDate:"mmm d, yyyy",longDate:"mmmm d, yyyy",fullDate:"dddd, mmmm d, yyyy",shortTime:"h:MM TT",mediumTime:"h:MM:ss TT",longTime:"h:MM:ss TT Z",isoDate:"yyyy-mm-dd",isoTime:"HH:MM:ss",isoDateTime:"yyyy-mm-dd'T'HH:MM:ss",isoUtcDateTime:"UTC:yyyy-mm-dd'T'HH:MM:ss'Z'"}
dateFormat.i18n={dayNames:["Sun","Mon","Tue","Wed","Thu","Fri","Sat","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],monthNames:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec","January","February","March","April","May","June","July","August","September","October","November","December"]}
Date.prototype.format=function(mask,utc){return dateFormat(this,mask,utc)}

var hljs=new function(){function l(o){return o.replace(/&/gm,"&amp;").replace(/</gm,"&lt;").replace(/>/gm,"&gt;")}function b(p){for(var o=p.firstChild;o;o=o.nextSibling){if("CODE"==o.nodeName)return o
if(3!=o.nodeType||!o.nodeValue.match(/\s+/))break}}function h(p,o){return Array.prototype.map.call(p.childNodes,function(q){return 3==q.nodeType?o?q.nodeValue.replace(/\n/g,""):q.nodeValue:"BR"==q.nodeName?"\n":h(q,o)}).join("")}function a(q){var p=(q.className+" "+q.parentNode.className).split(/\s+/)
p=p.map(function(r){return r.replace(/^language-/,"")})
for(var o=0;o<p.length;o++)if(e[p[o]]||"no-highlight"==p[o])return p[o]}function c(q){var o=[]
!function p(r,s){for(var t=r.firstChild;t;t=t.nextSibling)if(3==t.nodeType)s+=t.nodeValue.length
else if("BR"==t.nodeName)s+=1
else if(1==t.nodeType){o.push({event:"start",offset:s,node:t})
s=p(t,s)
o.push({event:"stop",offset:s,node:t})}return s}(q,0)
return o}function j(x,v,w){function t(){return x.length&&v.length?x[0].offset!=v[0].offset?x[0].offset<v[0].offset?x:v:"start"==v[0].event?x:v:x.length?x:v}function s(A){function z(B){return" "+B.nodeName+'="'+l(B.value)+'"'}return"<"+A.nodeName+Array.prototype.map.call(A.attributes,z).join("")+">"}for(var p=0,y="",r=[];x.length||v.length;){var u=t().splice(0,1)[0]
y+=l(w.substr(p,u.offset-p))
p=u.offset
if("start"==u.event){y+=s(u.node)
r.push(u.node)}else if("stop"==u.event){var o,q=r.length
do{q--
o=r[q]
y+="</"+o.nodeName.toLowerCase()+">"}while(o!=u.node)
r.splice(q,1)
for(;q<r.length;){y+=s(r[q])
q++}}}return y+l(w.substr(p))}function f(q){function o(s,r){return RegExp(s,"m"+(q.cI?"i":"")+(r?"g":""))}function p(y,w){function z(A,t){t.split(" ").forEach(function(B){var C=B.split("|")
r[C[0]]=[A,C[1]?Number(C[1]):1]
s.push(C[0])})}if(!y.compiled){y.compiled=!0
var s=[]
if(y.k){var r={}
y.lR=o(y.l||hljs.IR,!0)
if("string"==typeof y.k)z("keyword",y.k)
else for(var x in y.k)y.k.hasOwnProperty(x)&&z(x,y.k[x])
y.k=r}if(w){y.bWK&&(y.b="\\b("+s.join("|")+")\\s")
y.bR=o(y.b?y.b:"\\B|\\b")
y.e||y.eW||(y.e="\\B|\\b")
y.e&&(y.eR=o(y.e))
y.tE=y.e||""
y.eW&&w.tE&&(y.tE+=(y.e?"|":"")+w.tE)}y.i&&(y.iR=o(y.i))
void 0===y.r&&(y.r=1)
y.c||(y.c=[])
for(var v=0;v<y.c.length;v++){"self"==y.c[v]&&(y.c[v]=y)
p(y.c[v],y)}y.starts&&p(y.starts,w)
for(var u=[],v=0;v<y.c.length;v++)u.push(y.c[v].b)
y.tE&&u.push(y.tE)
y.i&&u.push(y.i)
y.t=u.length?o(u.join("|"),!0):{exec:function(){return null}}}}p(q)}function d(D,E){function o(r,M){for(var L=0;L<M.c.length;L++){var K=M.c[L].bR.exec(r)
if(K&&0==K.index)return M.c[L]}}function s(K,r){return K.e&&K.eR.test(r)?K:K.eW?s(K.parent,r):void 0}function t(r,K){return K.i&&K.iR.test(r)}function y(L,r){var K=F.cI?r[0].toLowerCase():r[0]
return L.k.hasOwnProperty(K)&&L.k[K]}function G(){var K=l(w)
if(!A.k)return K
var r="",N=0
A.lR.lastIndex=0
for(var L=A.lR.exec(K);L;){r+=K.substr(N,L.index-N)
var M=y(A,L)
if(M){v+=M[1]
r+='<span class="'+M[0]+'">'+L[0]+"</span>"}else r+=L[0]
N=A.lR.lastIndex
L=A.lR.exec(K)}return r+K.substr(N)}function z(){if(A.sL&&!e[A.sL])return l(w)
var r=A.sL?d(A.sL,w):g(w)
if(A.r>0){v+=r.keyword_count
B+=r.r}return'<span class="'+r.language+'">'+r.value+"</span>"}function J(){return void 0!==A.sL?z():G()}function I(L,r){var K=L.cN?'<span class="'+L.cN+'">':""
if(L.rB){x+=K
w=""}else if(L.eB){x+=l(r)+K
w=""}else{x+=K
w=r}A=Object.create(L,{parent:{value:A}})
B+=L.r}function C(K,r){w+=K
if(void 0===r){x+=J()
return 0}var L=o(r,A)
if(L){x+=J()
I(L,r)
return L.rB?0:r.length}var M=s(A,r)
if(M){M.rE||M.eE||(w+=r)
x+=J()
do{A.cN&&(x+="</span>")
A=A.parent}while(A!=M.parent)
M.eE&&(x+=l(r))
w=""
M.starts&&I(M.starts,"")
return M.rE?0:r.length}if(t(r,A))throw"Illegal"
w+=r
return r.length||1}var F=e[D]
f(F)
var A=F,w="",B=0,v=0,x=""
try{for(var u,q,p=0;;){A.t.lastIndex=p
u=A.t.exec(E)
if(!u)break
q=C(E.substr(p,u.index-p),u[0])
p=u.index+q}C(E.substr(p))
return{r:B,keyword_count:v,value:x,language:D}}catch(H){if("Illegal"==H)return{r:0,keyword_count:0,value:l(E)}
throw H}}function g(s){var o={keyword_count:0,r:0,value:l(s)},q=o
for(var p in e)if(e.hasOwnProperty(p)){var r=d(p,s)
r.language=p
r.keyword_count+r.r>q.keyword_count+q.r&&(q=r)
if(r.keyword_count+r.r>o.keyword_count+o.r){q=o
o=r}}q.language&&(o.second_best=q)
return o}function i(q,p,o){p&&(q=q.replace(/^((<[^>]+>|\t)+)/gm,function(r,v){return v.replace(/\t/g,p)}))
o&&(q=q.replace(/\n/g,"<br>"))
return q}function m(r,u,p){var v=h(r,p),t=a(r)
if("no-highlight"!=t){var w=t?d(t,v):g(v)
t=w.language
var o=c(r)
if(o.length){var q=document.createElement("pre")
q.innerHTML=w.value
w.value=j(o,c(q),v)}w.value=i(w.value,u,p)
var s=r.className
s.match("(\\s|^)(language-)?"+t+"(\\s|$)")||(s=s?s+" "+t:t)
r.innerHTML=w.value
r.className=s
r.result={language:t,kw:w.keyword_count,re:w.r}
w.second_best&&(r.second_best={language:w.second_best.language,kw:w.second_best.keyword_count,re:w.second_best.r})}}function n(){if(!n.called){n.called=!0
Array.prototype.map.call(document.getElementsByTagName("pre"),b).filter(Boolean).forEach(function(o){m(o,hljs.tabReplace)})}}function k(){window.addEventListener("DOMContentLoaded",n,!1)
window.addEventListener("load",n,!1)}var e={}
this.LANGUAGES=e
this.highlight=d
this.highlightAuto=g
this.fixMarkup=i
this.highlightBlock=m
this.initHighlighting=n
this.initHighlightingOnLoad=k
this.IR="[a-zA-Z][a-zA-Z0-9_]*"
this.UIR="[a-zA-Z_][a-zA-Z0-9_]*"
this.NR="\\b\\d+(\\.\\d+)?"
this.CNR="(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)"
this.BNR="\\b(0b[01]+)"
this.RSR="!|!=|!==|%|%=|&|&&|&=|\\*|\\*=|\\+|\\+=|,|\\.|-|-=|/|/=|:|;|<|<<|<<=|<=|=|==|===|>|>=|>>|>>=|>>>|>>>=|\\?|\\[|\\{|\\(|\\^|\\^=|\\||\\|=|\\|\\||~"
this.BE={b:"\\\\[\\s\\S]",r:0}
this.ASM={cN:"string",b:"'",e:"'",i:"\\n",c:[this.BE],r:0}
this.QSM={cN:"string",b:'"',e:'"',i:"\\n",c:[this.BE],r:0}
this.CLCM={cN:"comment",b:"//",e:"$"}
this.CBLCLM={cN:"comment",b:"/\\*",e:"\\*/"}
this.HCM={cN:"comment",b:"#",e:"$"}
this.NM={cN:"number",b:this.NR,r:0}
this.CNM={cN:"number",b:this.CNR,r:0}
this.BNM={cN:"number",b:this.BNR,r:0}
this.inherit=function(q,r){var o={}
for(var p in q)o[p]=q[p]
if(r)for(var p in r)o[p]=r[p]
return o}}
hljs.LANGUAGES.bash=function(a){var g="true false",e="if then else elif fi for break continue while in do done echo exit return set declare",c={cN:"variable",b:"\\$[a-zA-Z0-9_#]+"},b={cN:"variable",b:"\\${([^}]|\\\\})+}"},h={cN:"string",b:'"',e:'"',i:"\\n",c:[a.BE,c,b],r:0},d={cN:"string",b:"'",e:"'",c:[{b:"''"}],r:0},f={cN:"test_condition",b:"",e:"",c:[h,d,c,b],k:{literal:g},r:0}
return{k:{keyword:e,literal:g},c:[{cN:"shebang",b:"(#!\\/bin\\/bash)|(#!\\/bin\\/sh)",r:10},c,b,a.HCM,h,d,a.inherit(f,{b:"\\[ ",e:" \\]",r:0}),a.inherit(f,{b:"\\[\\[ ",e:" \\]\\]"})]}}(hljs)
hljs.LANGUAGES.erlang=function(i){var c="[a-z'][a-zA-Z0-9_']*",o="("+c+":"+c+"|"+c+")",f={keyword:"after and andalso|10 band begin bnot bor bsl bzr bxor case catch cond div end fun let not of orelse|10 query receive rem try when xor",literal:"false true"},l={cN:"comment",b:"%",e:"$",r:0},e={cN:"number",b:"\\b(\\d+#[a-fA-F0-9]+|\\d+(\\.\\d+)?([eE][-+]?\\d+)?)",r:0},g={b:"fun\\s+"+c+"/\\d+"},n={b:o+"\\(",e:"\\)",rB:!0,r:0,c:[{cN:"function_name",b:o,r:0},{b:"\\(",e:"\\)",eW:!0,rE:!0,r:0}]},h={cN:"tuple",b:"{",e:"}",r:0},a={cN:"variable",b:"\\b_([A-Z][A-Za-z0-9_]*)?",r:0},m={cN:"variable",b:"[A-Z][a-zA-Z0-9_]*",r:0},b={b:"#",e:"}",i:".",r:0,rB:!0,c:[{cN:"record_name",b:"#"+i.UIR,r:0},{b:"{",eW:!0,r:0}]},k={k:f,b:"(fun|receive|if|try|case)",e:"end"}
k.c=[l,g,i.inherit(i.ASM,{cN:""}),k,n,i.QSM,e,h,a,m,b]
var j=[l,g,k,n,i.QSM,e,h,a,m,b]
n.c[1].c=j
h.c=j
b.c[1].c=j
var d={cN:"params",b:"\\(",e:"\\)",c:j}
return{k:f,i:"(</|\\*=|\\+=|-=|/=|/\\*|\\*/|\\(\\*|\\*\\))",c:[{cN:"function",b:"^"+c+"\\s*\\(",e:"->",rB:!0,i:"\\(|#|//|/\\*|\\\\|:",c:[d,{cN:"title",b:c}],starts:{e:";|\\.",k:f,c:j}},l,{cN:"pp",b:"^-",e:"\\.",r:0,eE:!0,rB:!0,l:"-"+i.IR,k:"-module -record -undef -export -ifdef -ifndef -author -copyright -doc -vsn -import -include -include_lib -compile -define -else -endif -file -behaviour -behavior",c:[d]},e,i.QSM,b,a,m,h]}}(hljs)
hljs.LANGUAGES.cs=function(a){return{k:"abstract as base bool break byte case catch char checked class const continue decimal default delegate do double else enum event explicit extern false finally fixed float for foreach goto if implicit in int interface internal is lock long namespace new null object operator out override params private protected public readonly ref return sbyte sealed short sizeof stackalloc static string struct switch this throw true try typeof uint ulong unchecked unsafe ushort using virtual volatile void while ascending descending from get group into join let orderby partial select set value var where yield",c:[{cN:"comment",b:"///",e:"$",rB:!0,c:[{cN:"xmlDocTag",b:"///|<!--|-->"},{cN:"xmlDocTag",b:"</?",e:">"}]},a.CLCM,a.CBLCLM,{cN:"preprocessor",b:"#",e:"$",k:"if else elif endif define undef warning error line region endregion pragma checksum"},{cN:"string",b:'@"',e:'"',c:[{b:'""'}]},a.ASM,a.QSM,a.CNM]}}(hljs)
hljs.LANGUAGES.brainfuck=function(){return{c:[{cN:"comment",b:"[^\\[\\]\\.,\\+\\-<> \r\n]",eE:!0,e:"[\\[\\]\\.,\\+\\-<> \r\n]",r:0},{cN:"title",b:"[\\[\\]]",r:0},{cN:"string",b:"[\\.,]"},{cN:"literal",b:"[\\+\\-]"}]}}(hljs)
hljs.LANGUAGES.ruby=function(e){var a="[a-zA-Z_][a-zA-Z0-9_]*(\\!|\\?)?",j="[a-zA-Z_]\\w*[!?=]?|[-+~]\\@|<<|>>|=~|===?|<=>|[<>]=?|\\*\\*|[-/+%^&*~`|]|\\[\\]=?",g={keyword:"and false then defined module in return redo if BEGIN retry end for true self when next until do begin unless END rescue nil else break undef not super class case require yield alias while ensure elsif or include"},c={cN:"yardoctag",b:"@[A-Za-z]+"},k=[{cN:"comment",b:"#",e:"$",c:[c]},{cN:"comment",b:"^\\=begin",e:"^\\=end",c:[c],r:10},{cN:"comment",b:"^__END__",e:"\\n$"}],d={cN:"subst",b:"#\\{",e:"}",l:a,k:g},i=[e.BE,d],b=[{cN:"string",b:"'",e:"'",c:i,r:0},{cN:"string",b:'"',e:'"',c:i,r:0},{cN:"string",b:"%[qw]?\\(",e:"\\)",c:i},{cN:"string",b:"%[qw]?\\[",e:"\\]",c:i},{cN:"string",b:"%[qw]?{",e:"}",c:i},{cN:"string",b:"%[qw]?<",e:">",c:i,r:10},{cN:"string",b:"%[qw]?/",e:"/",c:i,r:10},{cN:"string",b:"%[qw]?%",e:"%",c:i,r:10},{cN:"string",b:"%[qw]?-",e:"-",c:i,r:10},{cN:"string",b:"%[qw]?\\|",e:"\\|",c:i,r:10}],h={cN:"function",bWK:!0,e:" |$|;",k:"def",c:[{cN:"title",b:j,l:a,k:g},{cN:"params",b:"\\(",e:"\\)",l:a,k:g}].concat(k)},f=k.concat(b.concat([{cN:"class",bWK:!0,e:"$|;",k:"class module",c:[{cN:"title",b:"[A-Za-z_]\\w*(::\\w+)*(\\?|\\!)?",r:0},{cN:"inheritance",b:"<\\s*",c:[{cN:"parent",b:"("+e.IR+"::)?"+e.IR}]}].concat(k)},h,{cN:"constant",b:"(::)?(\\b[A-Z]\\w*(::)?)+",r:0},{cN:"symbol",b:":",c:b.concat([{b:j}]),r:0},{cN:"symbol",b:a+":",r:0},{cN:"number",b:"(\\b0[0-7_]+)|(\\b0x[0-9a-fA-F_]+)|(\\b[1-9][0-9_]*(\\.[0-9_]+)?)|[0_]\\b",r:0},{cN:"number",b:"\\?\\w"},{cN:"variable",b:"(\\$\\W)|((\\$|\\@\\@?)(\\w+))"},{b:"("+e.RSR+")\\s*",c:k.concat([{cN:"regexp",b:"/",e:"/[a-z]*",i:"\\n",c:[e.BE,d]}]),r:0}]))
d.c=f
h.c[1].c=f
return{l:a,k:g,c:f}}(hljs)
hljs.LANGUAGES.rust=function(b){var d={cN:"title",b:b.UIR},c={cN:"number",b:"\\b(0[xb][A-Za-z0-9_]+|[0-9_]+(\\.[0-9_]+)?([uif](8|16|32|64)?)?)",r:0},a="alt any as assert be bind block bool break char check claim const cont dir do else enum export f32 f64 fail false float fn for i16 i32 i64 i8 if iface impl import in int let log mod mutable native note of prove pure resource ret self str syntax true type u16 u32 u64 u8 uint unchecked unsafe use vec while"
return{k:a,i:"</",c:[b.CLCM,b.CBLCLM,b.inherit(b.QSM,{i:null}),b.ASM,c,{cN:"function",bWK:!0,e:"(\\(|<)",k:"fn",c:[d]},{cN:"preprocessor",b:"#\\[",e:"\\]"},{bWK:!0,e:"(=|<)",k:"type",c:[d],i:"\\S"},{bWK:!0,e:"({|<)",k:"iface enum",c:[d],i:"\\S"}]}}(hljs)
hljs.LANGUAGES.rib=function(a){return{k:"ArchiveRecord AreaLightSource Atmosphere Attribute AttributeBegin AttributeEnd Basis Begin Blobby Bound Clipping ClippingPlane Color ColorSamples ConcatTransform Cone CoordinateSystem CoordSysTransform CropWindow Curves Cylinder DepthOfField Detail DetailRange Disk Displacement Display End ErrorHandler Exposure Exterior Format FrameAspectRatio FrameBegin FrameEnd GeneralPolygon GeometricApproximation Geometry Hider Hyperboloid Identity Illuminate Imager Interior LightSource MakeCubeFaceEnvironment MakeLatLongEnvironment MakeShadow MakeTexture Matte MotionBegin MotionEnd NuPatch ObjectBegin ObjectEnd ObjectInstance Opacity Option Orientation Paraboloid Patch PatchMesh Perspective PixelFilter PixelSamples PixelVariance Points PointsGeneralPolygons PointsPolygons Polygon Procedural Projection Quantize ReadArchive RelativeDetail ReverseOrientation Rotate Scale ScreenWindow ShadingInterpolation ShadingRate Shutter Sides Skew SolidBegin SolidEnd Sphere SubdivisionMesh Surface TextureCoordinates Torus Transform TransformBegin TransformEnd TransformPoints Translate TrimCurve WorldBegin WorldEnd",i:"</",c:[a.HCM,a.CNM,a.ASM,a.QSM]}}(hljs)
hljs.LANGUAGES.diff=function(){return{c:[{cN:"chunk",b:"^\\@\\@ +\\-\\d+,\\d+ +\\+\\d+,\\d+ +\\@\\@$",r:10},{cN:"chunk",b:"^\\*\\*\\* +\\d+,\\d+ +\\*\\*\\*\\*$",r:10},{cN:"chunk",b:"^\\-\\-\\- +\\d+,\\d+ +\\-\\-\\-\\-$",r:10},{cN:"header",b:"Index: ",e:"$"},{cN:"header",b:"=====",e:"=====$"},{cN:"header",b:"^\\-\\-\\-",e:"$"},{cN:"header",b:"^\\*{3} ",e:"$"},{cN:"header",b:"^\\+\\+\\+",e:"$"},{cN:"header",b:"\\*{5}",e:"\\*{5}$"},{cN:"addition",b:"^\\+",e:"$"},{cN:"deletion",b:"^\\-",e:"$"},{cN:"change",b:"^\\!",e:"$"}]}}(hljs)
hljs.LANGUAGES.javascript=function(a){return{k:{keyword:"in if for while finally var new function do return void else break catch instanceof with throw case default try this switch continue typeof delete let yield const",literal:"true false null undefined NaN Infinity"},c:[a.ASM,a.QSM,a.CLCM,a.CBLCLM,a.CNM,{b:"("+a.RSR+"|\\b(case|return|throw)\\b)\\s*",k:"return throw case",c:[a.CLCM,a.CBLCLM,{cN:"regexp",b:"/",e:"/[gim]*",i:"\\n",c:[{b:"\\\\/"}]},{b:"<",e:">;",sL:"xml"}],r:0},{cN:"function",bWK:!0,e:"{",k:"function",c:[{cN:"title",b:"[A-Za-z$_][0-9A-Za-z$_]*"},{cN:"params",b:"\\(",e:"\\)",c:[a.CLCM,a.CBLCLM],i:"[\"'\\(]"}],i:"\\[|%"}]}}(hljs)
hljs.LANGUAGES.glsl=function(a){return{k:{keyword:"atomic_uint attribute bool break bvec2 bvec3 bvec4 case centroid coherent const continue default discard dmat2 dmat2x2 dmat2x3 dmat2x4 dmat3 dmat3x2 dmat3x3 dmat3x4 dmat4 dmat4x2 dmat4x3 dmat4x4 do double dvec2 dvec3 dvec4 else flat float for highp if iimage1D iimage1DArray iimage2D iimage2DArray iimage2DMS iimage2DMSArray iimage2DRect iimage3D iimageBuffer iimageCube iimageCubeArray image1D image1DArray image2D image2DArray image2DMS image2DMSArray image2DRect image3D imageBuffer imageCube imageCubeArray in inout int invariant isampler1D isampler1DArray isampler2D isampler2DArray isampler2DMS isampler2DMSArray isampler2DRect isampler3D isamplerBuffer isamplerCube isamplerCubeArray ivec2 ivec3 ivec4 layout lowp mat2 mat2x2 mat2x3 mat2x4 mat3 mat3x2 mat3x3 mat3x4 mat4 mat4x2 mat4x3 mat4x4 mediump noperspective out patch precision readonly restrict return sample sampler1D sampler1DArray sampler1DArrayShadow sampler1DShadow sampler2D sampler2DArray sampler2DArrayShadow sampler2DMS sampler2DMSArray sampler2DRect sampler2DRectShadow sampler2DShadow sampler3D samplerBuffer samplerCube samplerCubeArray samplerCubeArrayShadow samplerCubeShadow smooth struct subroutine switch uimage1D uimage1DArray uimage2D uimage2DArray uimage2DMS uimage2DMSArray uimage2DRect uimage3D uimageBuffer uimageCube uimageCubeArray uint uniform usampler1D usampler1DArray usampler2D usampler2DArray usampler2DMS usampler2DMSArray usampler2DRect usampler3D usamplerBuffer usamplerCube usamplerCubeArray uvec2 uvec3 uvec4 varying vec2 vec3 vec4 void volatile while writeonly",built_in:"gl_BackColor gl_BackLightModelProduct gl_BackLightProduct gl_BackMaterial gl_BackSecondaryColor gl_ClipDistance gl_ClipPlane gl_ClipVertex gl_Color gl_DepthRange gl_EyePlaneQ gl_EyePlaneR gl_EyePlaneS gl_EyePlaneT gl_Fog gl_FogCoord gl_FogFragCoord gl_FragColor gl_FragCoord gl_FragData gl_FragDepth gl_FrontColor gl_FrontFacing gl_FrontLightModelProduct gl_FrontLightProduct gl_FrontMaterial gl_FrontSecondaryColor gl_InstanceID gl_InvocationID gl_Layer gl_LightModel gl_LightSource gl_MaxAtomicCounterBindings gl_MaxAtomicCounterBufferSize gl_MaxClipDistances gl_MaxClipPlanes gl_MaxCombinedAtomicCounterBuffers gl_MaxCombinedAtomicCounters gl_MaxCombinedImageUniforms gl_MaxCombinedImageUnitsAndFragmentOutputs gl_MaxCombinedTextureImageUnits gl_MaxDrawBuffers gl_MaxFragmentAtomicCounterBuffers gl_MaxFragmentAtomicCounters gl_MaxFragmentImageUniforms gl_MaxFragmentInputComponents gl_MaxFragmentUniformComponents gl_MaxFragmentUniformVectors gl_MaxGeometryAtomicCounterBuffers gl_MaxGeometryAtomicCounters gl_MaxGeometryImageUniforms gl_MaxGeometryInputComponents gl_MaxGeometryOutputComponents gl_MaxGeometryOutputVertices gl_MaxGeometryTextureImageUnits gl_MaxGeometryTotalOutputComponents gl_MaxGeometryUniformComponents gl_MaxGeometryVaryingComponents gl_MaxImageSamples gl_MaxImageUnits gl_MaxLights gl_MaxPatchVertices gl_MaxProgramTexelOffset gl_MaxTessControlAtomicCounterBuffers gl_MaxTessControlAtomicCounters gl_MaxTessControlImageUniforms gl_MaxTessControlInputComponents gl_MaxTessControlOutputComponents gl_MaxTessControlTextureImageUnits gl_MaxTessControlTotalOutputComponents gl_MaxTessControlUniformComponents gl_MaxTessEvaluationAtomicCounterBuffers gl_MaxTessEvaluationAtomicCounters gl_MaxTessEvaluationImageUniforms gl_MaxTessEvaluationInputComponents gl_MaxTessEvaluationOutputComponents gl_MaxTessEvaluationTextureImageUnits gl_MaxTessEvaluationUniformComponents gl_MaxTessGenLevel gl_MaxTessPatchComponents gl_MaxTextureCoords gl_MaxTextureImageUnits gl_MaxTextureUnits gl_MaxVaryingComponents gl_MaxVaryingFloats gl_MaxVaryingVectors gl_MaxVertexAtomicCounterBuffers gl_MaxVertexAtomicCounters gl_MaxVertexAttribs gl_MaxVertexImageUniforms gl_MaxVertexOutputComponents gl_MaxVertexTextureImageUnits gl_MaxVertexUniformComponents gl_MaxVertexUniformVectors gl_MaxViewports gl_MinProgramTexelOffsetgl_ModelViewMatrix gl_ModelViewMatrixInverse gl_ModelViewMatrixInverseTranspose gl_ModelViewMatrixTranspose gl_ModelViewProjectionMatrix gl_ModelViewProjectionMatrixInverse gl_ModelViewProjectionMatrixInverseTranspose gl_ModelViewProjectionMatrixTranspose gl_MultiTexCoord0 gl_MultiTexCoord1 gl_MultiTexCoord2 gl_MultiTexCoord3 gl_MultiTexCoord4 gl_MultiTexCoord5 gl_MultiTexCoord6 gl_MultiTexCoord7 gl_Normal gl_NormalMatrix gl_NormalScale gl_ObjectPlaneQ gl_ObjectPlaneR gl_ObjectPlaneS gl_ObjectPlaneT gl_PatchVerticesIn gl_PerVertex gl_Point gl_PointCoord gl_PointSize gl_Position gl_PrimitiveID gl_PrimitiveIDIn gl_ProjectionMatrix gl_ProjectionMatrixInverse gl_ProjectionMatrixInverseTranspose gl_ProjectionMatrixTranspose gl_SampleID gl_SampleMask gl_SampleMaskIn gl_SamplePosition gl_SecondaryColor gl_TessCoord gl_TessLevelInner gl_TessLevelOuter gl_TexCoord gl_TextureEnvColor gl_TextureMatrixInverseTranspose gl_TextureMatrixTranspose gl_Vertex gl_VertexID gl_ViewportIndex gl_in gl_out EmitStreamVertex EmitVertex EndPrimitive EndStreamPrimitive abs acos acosh all any asin asinh atan atanh atomicCounter atomicCounterDecrement atomicCounterIncrement barrier bitCount bitfieldExtract bitfieldInsert bitfieldReverse ceil clamp cos cosh cross dFdx dFdy degrees determinant distance dot equal exp exp2 faceforward findLSB findMSB floatBitsToInt floatBitsToUint floor fma fract frexp ftransform fwidth greaterThan greaterThanEqual imageAtomicAdd imageAtomicAnd imageAtomicCompSwap imageAtomicExchange imageAtomicMax imageAtomicMin imageAtomicOr imageAtomicXor imageLoad imageStore imulExtended intBitsToFloat interpolateAtCentroid interpolateAtOffset interpolateAtSample inverse inversesqrt isinf isnan ldexp length lessThan lessThanEqual log log2 matrixCompMult max memoryBarrier min mix mod modf noise1 noise2 noise3 noise4 normalize not notEqual outerProduct packDouble2x32 packHalf2x16 packSnorm2x16 packSnorm4x8 packUnorm2x16 packUnorm4x8 pow radians reflect refract round roundEven shadow1D shadow1DLod shadow1DProj shadow1DProjLod shadow2D shadow2DLod shadow2DProj shadow2DProjLod sign sin sinh smoothstep sqrt step tan tanh texelFetch texelFetchOffset texture texture1D texture1DLod texture1DProj texture1DProjLod texture2D texture2DLod texture2DProj texture2DProjLod texture3D texture3DLod texture3DProj texture3DProjLod textureCube textureCubeLod textureGather textureGatherOffset textureGatherOffsets textureGrad textureGradOffset textureLod textureLodOffset textureOffset textureProj textureProjGrad textureProjGradOffset textureProjLod textureProjLodOffset textureProjOffset textureQueryLod textureSize transpose trunc uaddCarry uintBitsToFloat umulExtended unpackDouble2x32 unpackHalf2x16 unpackSnorm2x16 unpackSnorm4x8 unpackUnorm2x16 unpackUnorm4x8 usubBorrow gl_TextureMatrix gl_TextureMatrixInverse",literal:"true false"},i:'"',c:[a.CLCM,a.CBLCLM,a.CNM,{cN:"preprocessor",b:"#",e:"$"}]}}(hljs)
hljs.LANGUAGES.rsl=function(a){return{k:{keyword:"float color point normal vector matrix while for if do return else break extern continue",built_in:"abs acos ambient area asin atan atmosphere attribute calculatenormal ceil cellnoise clamp comp concat cos degrees depth Deriv diffuse distance Du Dv environment exp faceforward filterstep floor format fresnel incident length lightsource log match max min mod noise normalize ntransform opposite option phong pnoise pow printf ptlined radians random reflect refract renderinfo round setcomp setxcomp setycomp setzcomp shadow sign sin smoothstep specular specularbrdf spline sqrt step tan texture textureinfo trace transform vtransform xcomp ycomp zcomp"},i:"</",c:[a.CLCM,a.CBLCLM,a.QSM,a.ASM,a.CNM,{cN:"preprocessor",b:"#",e:"$"},{cN:"shader",bWK:!0,e:"\\(",k:"surface displacement light volume imager"},{cN:"shading",bWK:!0,e:"\\(",k:"illuminate illuminance gather"}]}}(hljs)
hljs.LANGUAGES.lua=function(b){var a="\\[=*\\[",e="\\]=*\\]",c={b:a,e:e,c:["self"]},d=[{cN:"comment",b:"--(?!"+a+")",e:"$"},{cN:"comment",b:"--"+a,e:e,c:[c],r:10}]
return{l:b.UIR,k:{keyword:"and break do else elseif end false for if in local nil not or repeat return then true until while",built_in:"_G _VERSION assert collectgarbage dofile error getfenv getmetatable ipairs load loadfile loadstring module next pairs pcall print rawequal rawget rawset require select setfenv setmetatable tonumber tostring type unpack xpcall coroutine debug io math os package string table"},c:d.concat([{cN:"function",bWK:!0,e:"\\)",k:"function",c:[{cN:"title",b:"([_a-zA-Z]\\w*\\.)*([_a-zA-Z]\\w*:)?[_a-zA-Z]\\w*"},{cN:"params",b:"\\(",eW:!0,c:d}].concat(d)},b.CNM,b.ASM,b.QSM,{cN:"string",b:a,e:e,c:[c],r:10}])}}(hljs)
hljs.LANGUAGES.xml=function(){var c="[A-Za-z0-9\\._:-]+",b={eW:!0,c:[{cN:"attribute",b:c,r:0},{b:'="',rB:!0,e:'"',c:[{cN:"value",b:'"',eW:!0}]},{b:"='",rB:!0,e:"'",c:[{cN:"value",b:"'",eW:!0}]},{b:"=",c:[{cN:"value",b:"[^\\s/>]+"}]}]}
return{cI:!0,c:[{cN:"pi",b:"<\\?",e:"\\?>",r:10},{cN:"doctype",b:"<!DOCTYPE",e:">",r:10,c:[{b:"\\[",e:"\\]"}]},{cN:"comment",b:"<!--",e:"-->",r:10},{cN:"cdata",b:"<\\!\\[CDATA\\[",e:"\\]\\]>",r:10},{cN:"tag",b:"<style(?=\\s|>|$)",e:">",k:{title:"style"},c:[b],starts:{e:"</style>",rE:!0,sL:"css"}},{cN:"tag",b:"<script(?=\\s|>|$)",e:">",k:{title:"script"},c:[b],starts:{e:"</script>",rE:!0,sL:"javascript"}},{b:"<%",e:"%>",sL:"vbscript"},{cN:"tag",b:"</?",e:"/?>",c:[{cN:"title",b:"[^ />]+"},b]}]}}(hljs)
hljs.LANGUAGES.markdown=function(){return{c:[{cN:"header",b:"^#{1,3}",e:"$"},{cN:"header",b:"^.+?\\n[=-]{2,}$"},{b:"<",e:">",sL:"xml",r:0},{cN:"bullet",b:"^([*+-]|(\\d+\\.))\\s+"},{cN:"strong",b:"[*_]{2}.+?[*_]{2}"},{cN:"emphasis",b:"\\*.+?\\*"},{cN:"emphasis",b:"_.+?_",r:0},{cN:"blockquote",b:"^>\\s+",e:"$"},{cN:"code",b:"`.+?`"},{cN:"code",b:"^    ",e:"$",r:0},{cN:"horizontal_rule",b:"^-{3,}",e:"$"},{b:"\\[.+?\\]\\(.+?\\)",rB:!0,c:[{cN:"link_label",b:"\\[.+\\]"},{cN:"link_url",b:"\\(",e:"\\)",eB:!0,eE:!0}]}]}}(hljs)
hljs.LANGUAGES.css=function(a){var b={cN:"function",b:a.IR+"\\(",e:"\\)",c:[a.NM,a.ASM,a.QSM]}
return{cI:!0,i:"[=/|']",c:[a.CBLCLM,{cN:"id",b:"\\#[A-Za-z0-9_-]+"},{cN:"class",b:"\\.[A-Za-z0-9_-]+",r:0},{cN:"attr_selector",b:"\\[",e:"\\]",i:"$"},{cN:"pseudo",b:":(:)?[a-zA-Z0-9\\_\\-\\+\\(\\)\\\"\\']+"},{cN:"at_rule",b:"@(font-face|page)",l:"[a-z-]+",k:"font-face page"},{cN:"at_rule",b:"@",e:"[{;]",eE:!0,k:"import page media charset",c:[b,a.ASM,a.QSM,a.NM]},{cN:"tag",b:a.IR,r:0},{cN:"rules",b:"{",e:"}",i:"[^\\s]",r:0,c:[a.CBLCLM,{cN:"rule",b:"[^\\s]",rB:!0,e:";",eW:!0,c:[{cN:"attribute",b:"[A-Z\\_\\.\\-]+",e:":",eE:!0,i:"[^\\s]",starts:{cN:"value",eW:!0,eE:!0,c:[b,a.NM,a.QSM,a.ASM,a.CBLCLM,{cN:"hexcolor",b:"\\#[0-9A-F]+"},{cN:"important",b:"!important"}]}}]}]}]}}(hljs)
hljs.LANGUAGES.lisp=function(i){var k="[a-zA-Z_\\-\\+\\*\\/\\<\\=\\>\\&\\#][a-zA-Z0-9_\\-\\+\\*\\/\\<\\=\\>\\&\\#]*",l="(\\-|\\+)?\\d+(\\.\\d+|\\/\\d+)?((d|e|f|l|s)(\\+|\\-)?\\d+)?",a={cN:"literal",b:"\\b(t{1}|nil)\\b"},d=[{cN:"number",b:l},{cN:"number",b:"#b[0-1]+(/[0-1]+)?"},{cN:"number",b:"#o[0-7]+(/[0-7]+)?"},{cN:"number",b:"#x[0-9a-f]+(/[0-9a-f]+)?"},{cN:"number",b:"#c\\("+l+" +"+l,e:"\\)"}],h={cN:"string",b:'"',e:'"',c:[i.BE],r:0},m={cN:"comment",b:";",e:"$"},g={cN:"variable",b:"\\*",e:"\\*"},n={cN:"keyword",b:"[:&]"+k},b={b:"\\(",e:"\\)",c:["self",a,h].concat(d)},e={cN:"quoted",b:"['`]\\(",e:"\\)",c:d.concat([h,g,n,b])},c={cN:"quoted",b:"\\(quote ",e:"\\)",k:{title:"quote"},c:d.concat([h,g,n,b])},j={cN:"list",b:"\\(",e:"\\)"},f={cN:"body",eW:!0,eE:!0}
j.c=[{cN:"title",b:k},f]
f.c=[e,c,j,a].concat(d).concat([h,m,g,n])
return{i:"[^\\s]",c:d.concat([a,h,m,e,c,j])}}(hljs)
hljs.LANGUAGES.profile=function(a){return{c:[a.CNM,{cN:"builtin",b:"{",e:"}$",eB:!0,eE:!0,c:[a.ASM,a.QSM],r:0},{cN:"filename",b:"[a-zA-Z_][\\da-zA-Z_]+\\.[\\da-zA-Z_]{1,3}",e:":",eE:!0},{cN:"header",b:"(ncalls|tottime|cumtime)",e:"$",k:"ncalls tottime|10 cumtime|10 filename",r:10},{cN:"summary",b:"function calls",e:"$",c:[a.CNM],r:10},a.ASM,a.QSM,{cN:"function",b:"\\(",e:"\\)$",c:[{cN:"title",b:a.UIR,r:0}],r:0}]}}(hljs)
hljs.LANGUAGES.http=function(){return{i:"\\S",c:[{cN:"status",b:"^HTTP/[0-9\\.]+",e:"$",c:[{cN:"number",b:"\\b\\d{3}\\b"}]},{cN:"request",b:"^[A-Z]+ (.*?) HTTP/[0-9\\.]+$",rB:!0,e:"$",c:[{cN:"string",b:" ",e:" ",eB:!0,eE:!0}]},{cN:"attribute",b:"^\\w",e:": ",eE:!0,i:"\\n|\\s|=",starts:{cN:"string",e:"$"}},{b:"\\n\\n",starts:{sL:"",eW:!0}}]}}(hljs)
hljs.LANGUAGES.java=function(a){return{k:"false synchronized int abstract float private char boolean static null if const for true while long throw strictfp finally protected import native final return void enum else break transient new catch instanceof byte super volatile case assert short package default double public try this switch continue throws",c:[{cN:"javadoc",b:"/\\*\\*",e:"\\*/",c:[{cN:"javadoctag",b:"@[A-Za-z]+"}],r:10},a.CLCM,a.CBLCLM,a.ASM,a.QSM,{cN:"class",bWK:!0,e:"{",k:"class interface",i:":",c:[{bWK:!0,k:"extends implements",r:10},{cN:"title",b:a.UIR}]},a.CNM,{cN:"annotation",b:"@[A-Za-z]+"}]}}(hljs)
hljs.LANGUAGES.php=function(a){var e={cN:"variable",b:"\\$+[a-zA-Z_-ÿ][a-zA-Z0-9_-ÿ]*"},b=[a.inherit(a.ASM,{i:null}),a.inherit(a.QSM,{i:null}),{cN:"string",b:'b"',e:'"',c:[a.BE]},{cN:"string",b:"b'",e:"'",c:[a.BE]}],c=[a.BNM,a.CNM],d={cN:"title",b:a.UIR}
return{cI:!0,k:"and include_once list abstract global private echo interface as static endswitch array null if endwhile or const for endforeach self var while isset public protected exit foreach throw elseif include __FILE__ empty require_once do xor return implements parent clone use __CLASS__ __LINE__ else break print eval new catch __METHOD__ case exception php_user_filter default die require __FUNCTION__ enddeclare final try this switch continue endfor endif declare unset true false namespace trait goto instanceof insteadof __DIR__ __NAMESPACE__ __halt_compiler",c:[a.CLCM,a.HCM,{cN:"comment",b:"/\\*",e:"\\*/",c:[{cN:"phpdoc",b:"\\s@[A-Za-z]+"}]},{cN:"comment",eB:!0,b:"__halt_compiler.+?;",eW:!0},{cN:"string",b:"<<<['\"]?\\w+['\"]?$",e:"^\\w+;",c:[a.BE]},{cN:"preprocessor",b:"<\\?php",r:10},{cN:"preprocessor",b:"\\?>"},e,{cN:"function",bWK:!0,e:"{",k:"function",i:"\\$|\\[|%",c:[d,{cN:"params",b:"\\(",e:"\\)",c:["self",e,a.CBLCLM].concat(b).concat(c)}]},{cN:"class",bWK:!0,e:"{",k:"class",i:"[:\\(\\$]",c:[{bWK:!0,eW:!0,k:"extends",c:[d]},d]},{b:"=>"}].concat(b).concat(c)}}(hljs)
hljs.LANGUAGES.haskell=function(a){var d={cN:"type",b:"\\b[A-Z][\\w']*",r:0},c={cN:"container",b:"\\(",e:"\\)",c:[{cN:"type",b:"\\b[A-Z][\\w]*(\\((\\.\\.|,|\\w+)\\))?"},{cN:"title",b:"[_a-z][\\w']*"}]},b={cN:"container",b:"{",e:"}",c:c.c}
return{k:"let in if then else case of where do module import hiding qualified type data newtype deriving class instance not as foreign ccall safe unsafe",c:[{cN:"comment",b:"--",e:"$"},{cN:"preprocessor",b:"{-#",e:"#-}"},{cN:"comment",c:["self"],b:"{-",e:"-}"},{cN:"string",b:"\\s+'",e:"'",c:[a.BE],r:0},a.QSM,{cN:"import",b:"\\bimport",e:"$",k:"import qualified as hiding",c:[c],i:"\\W\\.|;"},{cN:"module",b:"\\bmodule",e:"where",k:"module where",c:[c],i:"\\W\\.|;"},{cN:"class",b:"\\b(class|instance)",e:"where",k:"class where instance",c:[d]},{cN:"typedef",b:"\\b(data|(new)?type)",e:"$",k:"data type newtype deriving",c:[d,c,b]},a.CNM,{cN:"shebang",b:"#!\\/usr\\/bin\\/env runhaskell",e:"$"},d,{cN:"title",b:"^[_a-z][\\w']*"}]}}(hljs)
hljs.LANGUAGES["1c"]=function(b){var f="[a-zA-Zа-яА-Я][a-zA-Z0-9_а-яА-Я]*",c="возврат дата для если и или иначе иначеесли исключение конецесли конецпопытки конецпроцедуры конецфункции конеццикла константа не перейти перем перечисление по пока попытка прервать продолжить процедура строка тогда фс функция цикл число экспорт",e="ansitooem oemtoansi ввестивидсубконто ввестидату ввестизначение ввестиперечисление ввестипериод ввестиплансчетов ввестистроку ввестичисло вопрос восстановитьзначение врег выбранныйплансчетов вызватьисключение датагод датамесяц датачисло добавитьмесяц завершитьработусистемы заголовоксистемы записьжурналарегистрации запуститьприложение зафиксироватьтранзакцию значениевстроку значениевстрокувнутр значениевфайл значениеизстроки значениеизстрокивнутр значениеизфайла имякомпьютера имяпользователя каталогвременныхфайлов каталогиб каталогпользователя каталогпрограммы кодсимв командасистемы конгода конецпериодаби конецрассчитанногопериодаби конецстандартногоинтервала конквартала конмесяца коннедели лев лог лог10 макс максимальноеколичествосубконто мин монопольныйрежим названиеинтерфейса названиенабораправ назначитьвид назначитьсчет найти найтипомеченныенаудаление найтиссылки началопериодаби началостандартногоинтервала начатьтранзакцию начгода начквартала начмесяца начнедели номерднягода номерднянедели номернеделигода нрег обработкаожидания окр описаниеошибки основнойжурналрасчетов основнойплансчетов основнойязык открытьформу открытьформумодально отменитьтранзакцию очиститьокносообщений периодстр полноеимяпользователя получитьвремята получитьдатута получитьдокументта получитьзначенияотбора получитьпозициюта получитьпустоезначение получитьта прав праводоступа предупреждение префиксавтонумерации пустаястрока пустоезначение рабочаядаттьпустоезначение рабочаядата разделительстраниц разделительстрок разм разобратьпозициюдокумента рассчитатьрегистрына рассчитатьрегистрыпо сигнал симв символтабуляции создатьобъект сокрл сокрлп сокрп сообщить состояние сохранитьзначение сред статусвозврата стрдлина стрзаменить стрколичествострок стрполучитьстроку  стрчисловхождений сформироватьпозициюдокумента счетпокоду текущаядата текущеевремя типзначения типзначениястр удалитьобъекты установитьтана установитьтапо фиксшаблон формат цел шаблон",a={cN:"dquote",b:'""'},d={cN:"string",b:'"',e:'"|$',c:[a],r:0},g={cN:"string",b:"\\|",e:'"|$',c:[a]}
return{cI:!0,l:f,k:{keyword:c,built_in:e},c:[b.CLCM,b.NM,d,g,{cN:"function",b:"(процедура|функция)",e:"$",l:f,k:"процедура функция",c:[{cN:"title",b:f},{cN:"tail",eW:!0,c:[{cN:"params",b:"\\(",e:"\\)",l:f,k:"знач",c:[d,g]},{cN:"export",b:"экспорт",eW:!0,l:f,k:"экспорт",c:[b.CLCM]}]},b.CLCM]},{cN:"preprocessor",b:"#",e:"$"},{cN:"date",b:"'\\d{2}\\.\\d{2}\\.(\\d{2}|\\d{4})'"}]}}(hljs)
hljs.LANGUAGES.python=function(a){var f={cN:"prompt",b:"^(>>>|\\.\\.\\.) "},c=[{cN:"string",b:"(u|b)?r?'''",e:"'''",c:[f],r:10},{cN:"string",b:'(u|b)?r?"""',e:'"""',c:[f],r:10},{cN:"string",b:"(u|r|ur)'",e:"'",c:[a.BE],r:10},{cN:"string",b:'(u|r|ur)"',e:'"',c:[a.BE],r:10},{cN:"string",b:"(b|br)'",e:"'",c:[a.BE]},{cN:"string",b:'(b|br)"',e:'"',c:[a.BE]}].concat([a.ASM,a.QSM]),e={cN:"title",b:a.UIR},d={cN:"params",b:"\\(",e:"\\)",c:["self",a.CNM,f].concat(c)},b={bWK:!0,e:":",i:"[${=;\\n]",c:[e,d],r:10}
return{k:{keyword:"and elif is global as in if from raise for except finally print import pass return exec else break not with class assert yield try while continue del or def lambda nonlocal|10",built_in:"None True False Ellipsis NotImplemented"},i:"(</|->|\\?)",c:c.concat([f,a.HCM,a.inherit(b,{cN:"function",k:"def"}),a.inherit(b,{cN:"class",k:"class"}),a.CNM,{cN:"decorator",b:"@",e:"$"},{b:"\\b(print|exec)\\("}])}}(hljs)
hljs.LANGUAGES.smalltalk=function(a){var b="[a-z][a-zA-Z0-9_]*",d={cN:"char",b:"\\$.{1}"},c={cN:"symbol",b:"#"+a.UIR}
return{k:"self super nil true false thisContext",c:[{cN:"comment",b:'"',e:'"',r:0},a.ASM,{cN:"class",b:"\\b[A-Z][A-Za-z0-9_]*",r:0},{cN:"method",b:b+":"},a.CNM,c,d,{cN:"localvars",b:"\\|\\s*(("+b+")\\s*)+\\|"},{cN:"array",b:"\\#\\(",e:"\\)",c:[a.ASM,d,a.CNM,c]}]}}(hljs)
hljs.LANGUAGES.tex=function(){var d={cN:"command",b:"\\\\[a-zA-Zа-яА-я]+[\\*]?"},c={cN:"command",b:"\\\\[^a-zA-Zа-яА-я0-9]"},b={cN:"special",b:"[{}\\[\\]\\&#~]",r:0}
return{c:[{b:"\\\\[a-zA-Zа-яА-я]+[\\*]? *= *-?\\d*\\.?\\d+(pt|pc|mm|cm|in|dd|cc|ex|em)?",rB:!0,c:[d,c,{cN:"number",b:" *=",e:"-?\\d*\\.?\\d+(pt|pc|mm|cm|in|dd|cc|ex|em)?",eB:!0}],r:10},d,c,b,{cN:"formula",b:"\\$\\$",e:"\\$\\$",c:[d,c,b],r:0},{cN:"formula",b:"\\$",e:"\\$",c:[d,c,b],r:0},{cN:"comment",b:"%",e:"$",r:0}]}}(hljs)
hljs.LANGUAGES.actionscript=function(a){var d="[a-zA-Z_$][a-zA-Z0-9_$]*",c="([*]|[a-zA-Z_$][a-zA-Z0-9_$]*)",e={cN:"rest_arg",b:"[.]{3}",e:d,r:10},b={cN:"title",b:d}
return{k:{keyword:"as break case catch class const continue default delete do dynamic each else extends final finally for function get if implements import in include instanceof interface internal is namespace native new override package private protected public return set static super switch this throw try typeof use var void while with",literal:"true false null undefined"},c:[a.ASM,a.QSM,a.CLCM,a.CBLCLM,a.CNM,{cN:"package",bWK:!0,e:"{",k:"package",c:[b]},{cN:"class",bWK:!0,e:"{",k:"class interface",c:[{bWK:!0,k:"extends implements"},b]},{cN:"preprocessor",bWK:!0,e:";",k:"import include"},{cN:"function",bWK:!0,e:"[{;]",k:"function",i:"\\S",c:[b,{cN:"params",b:"\\(",e:"\\)",c:[a.ASM,a.QSM,a.CLCM,a.CBLCLM,e]},{cN:"type",b:":",e:c,r:10}]}]}}(hljs)
hljs.LANGUAGES.sql=function(a){return{cI:!0,c:[{cN:"operator",b:"(begin|start|commit|rollback|savepoint|lock|alter|create|drop|rename|call|delete|do|handler|insert|load|replace|select|truncate|update|set|show|pragma|grant)\\b(?!:)",e:";",eW:!0,k:{keyword:"all partial global month current_timestamp using go revoke smallint indicator end-exec disconnect zone with character assertion to add current_user usage input local alter match collate real then rollback get read timestamp session_user not integer bit unique day minute desc insert execute like ilike|2 level decimal drop continue isolation found where constraints domain right national some module transaction relative second connect escape close system_user for deferred section cast current sqlstate allocate intersect deallocate numeric public preserve full goto initially asc no key output collation group by union session both last language constraint column of space foreign deferrable prior connection unknown action commit view or first into float year primary cascaded except restrict set references names table outer open select size are rows from prepare distinct leading create only next inner authorization schema corresponding option declare precision immediate else timezone_minute external varying translation true case exception join hour default double scroll value cursor descriptor values dec fetch procedure delete and false int is describe char as at in varchar null trailing any absolute current_time end grant privileges when cross check write current_date pad begin temporary exec time update catalog user sql date on identity timezone_hour natural whenever interval work order cascade diagnostics nchar having left call do handler load replace truncate start lock show pragma exists number",aggregate:"count sum min max avg"},c:[{cN:"string",b:"'",e:"'",c:[a.BE,{b:"''"}],r:0},{cN:"string",b:'"',e:'"',c:[a.BE,{b:'""'}],r:0},{cN:"string",b:"`",e:"`",c:[a.BE]},a.CNM]},a.CBLCLM,{cN:"comment",b:"--",e:"$"}]}}(hljs)
hljs.LANGUAGES.vala=function(a){return{k:{keyword:"char uchar unichar int uint long ulong short ushort int8 int16 int32 int64 uint8 uint16 uint32 uint64 float double bool struct enum string void weak unowned owned async signal static abstract interface override while do for foreach else switch case break default return try catch public private protected internal using new this get set const stdout stdin stderr var",built_in:"DBus GLib CCode Gee Object",literal:"false true null"},c:[{cN:"class",bWK:!0,e:"{",k:"class interface delegate namespace",c:[{bWK:!0,k:"extends implements"},{cN:"title",b:a.UIR}]},a.CLCM,a.CBLCLM,{cN:"string",b:'"""',e:'"""',r:5},a.ASM,a.QSM,a.CNM,{cN:"preprocessor",b:"^#",e:"$",r:2},{cN:"constant",b:" [A-Z_]+ ",r:0}]}}(hljs)
hljs.LANGUAGES.ini=function(a){return{cI:!0,i:"[^\\s]",c:[{cN:"comment",b:";",e:"$"},{cN:"title",b:"^\\[",e:"\\]"},{cN:"setting",b:"^[a-z0-9\\[\\]_-]+[ \\t]*=[ \\t]*",e:"$",c:[{cN:"value",eW:!0,k:"on off true false yes no",c:[a.QSM,a.NM]}]}]}}(hljs)
hljs.LANGUAGES.d=function(x){var b={keyword:"abstract alias align asm assert auto body break byte case cast catch class const continue debug default delete deprecated do else enum export extern final finally for foreach foreach_reverse|10 goto if immutable import in inout int interface invariant is lazy macro mixin module new nothrow out override package pragma private protected public pure ref return scope shared static struct super switch synchronized template this throw try typedef typeid typeof union unittest version void volatile while with __FILE__ __LINE__ __gshared|10 __thread __traits __DATE__ __EOF__ __TIME__ __TIMESTAMP__ __VENDOR__ __VERSION__",built_in:"bool cdouble cent cfloat char creal dchar delegate double dstring float function idouble ifloat ireal long real short string ubyte ucent uint ulong ushort wchar wstring",literal:"false null true"},c="(0|[1-9][\\d_]*)",q="(0|[1-9][\\d_]*|\\d[\\d_]*|[\\d_]+?\\d)",h="0[bB][01_]+",v="([\\da-fA-F][\\da-fA-F_]*|_[\\da-fA-F][\\da-fA-F_]*)",y="0[xX]"+v,p="([eE][+-]?"+q+")",o="("+q+"(\\.\\d*|"+p+")|\\d+\\."+q+q+"|\\."+c+p+"?)",k="(0[xX]("+v+"\\."+v+"|\\.?"+v+")[pP][+-]?"+q+")",l="("+c+"|"+h+"|"+y+")",n="("+k+"|"+o+")",z="\\\\(['\"\\?\\\\abfnrtv]|u[\\dA-Fa-f]{4}|[0-7]{1,3}|x[\\dA-Fa-f]{2}|U[\\dA-Fa-f]{8})|&[a-zA-Z\\d]{2,};",m={cN:"number",b:"\\b"+l+"(L|u|U|Lu|LU|uL|UL)?",r:0},j={cN:"number",b:"\\b("+n+"([fF]|L|i|[fF]i|Li)?|"+l+"(i|[fF]i|Li))",r:0},s={cN:"string",b:"'("+z+"|.)",e:"'",i:"."},r={b:z,r:0},w={cN:"string",b:'"',c:[r],e:'"[cwd]?',r:0},f={cN:"string",b:'[rq]"',e:'"[cwd]?',r:5},u={cN:"string",b:"`",e:"`[cwd]?"},i={cN:"string",b:'x"[\\da-fA-F\\s\\n\\r]*"[cwd]?',r:10},t={cN:"string",b:'q"\\{',e:'\\}"'},e={cN:"shebang",b:"^#!",e:"$",r:5},g={cN:"preprocessor",b:"#(line)",e:"$",r:5},d={cN:"keyword",b:"@[a-zA-Z_][a-zA-Z_\\d]*"},a={cN:"comment",b:"\\/\\+",c:["self"],e:"\\+\\/",r:10}
return{l:x.UIR,k:b,c:[x.CLCM,x.CBLCLM,a,i,w,f,u,t,j,m,s,e,g,d]}}(hljs)
hljs.LANGUAGES.axapta=function(a){return{k:"false int abstract private char interface boolean static null if for true while long throw finally protected extends final implements return void enum else break new catch byte super class case short default double public try this switch continue reverse firstfast firstonly forupdate nofetch sum avg minof maxof count order group by asc desc index hint like dispaly edit client server ttsbegin ttscommit str real date container anytype common div mod",c:[a.CLCM,a.CBLCLM,a.ASM,a.QSM,a.CNM,{cN:"preprocessor",b:"#",e:"$"},{cN:"class",bWK:!0,e:"{",i:":",k:"class interface",c:[{cN:"inheritance",bWK:!0,k:"extends implements",r:10},{cN:"title",b:a.UIR}]}]}}(hljs)
hljs.LANGUAGES.perl=function(e){var a="getpwent getservent quotemeta msgrcv scalar kill dbmclose undef lc ma syswrite tr send umask sysopen shmwrite vec qx utime local oct semctl localtime readpipe do return format read sprintf dbmopen pop getpgrp not getpwnam rewinddir qqfileno qw endprotoent wait sethostent bless s|0 opendir continue each sleep endgrent shutdown dump chomp connect getsockname die socketpair close flock exists index shmgetsub for endpwent redo lstat msgctl setpgrp abs exit select print ref gethostbyaddr unshift fcntl syscall goto getnetbyaddr join gmtime symlink semget splice x|0 getpeername recv log setsockopt cos last reverse gethostbyname getgrnam study formline endhostent times chop length gethostent getnetent pack getprotoent getservbyname rand mkdir pos chmod y|0 substr endnetent printf next open msgsnd readdir use unlink getsockopt getpriority rindex wantarray hex system getservbyport endservent int chr untie rmdir prototype tell listen fork shmread ucfirst setprotoent else sysseek link getgrgid shmctl waitpid unpack getnetbyname reset chdir grep split require caller lcfirst until warn while values shift telldir getpwuid my getprotobynumber delete and sort uc defined srand accept package seekdir getprotobyname semop our rename seek if q|0 chroot sysread setpwent no crypt getc chown sqrt write setnetent setpriority foreach tie sin msgget map stat getlogin unless elsif truncate exec keys glob tied closedirioctl socket readlink eval xor readline binmode setservent eof ord bind alarm pipe atan2 getgrent exp time push setgrent gt lt or ne m|0 break given say state when",d={cN:"subst",b:"[$@]\\{",e:"\\}",k:a,r:10},b={cN:"variable",b:"\\$\\d"},i={cN:"variable",b:"[\\$\\%\\@\\*](\\^\\w\\b|#\\w+(\\:\\:\\w+)*|[^\\s\\w{]|{\\w+}|\\w+(\\:\\:\\w*)*)"},f=[e.BE,d,b,i],h={b:"->",c:[{b:e.IR},{b:"{",e:"}"}]},g={cN:"comment",b:"^(__END__|__DATA__)",e:"\\n$",r:5},c=[b,i,e.HCM,g,{cN:"comment",b:"^\\=\\w",e:"\\=cut",eW:!0},h,{cN:"string",b:"q[qwxr]?\\s*\\(",e:"\\)",c:f,r:5},{cN:"string",b:"q[qwxr]?\\s*\\[",e:"\\]",c:f,r:5},{cN:"string",b:"q[qwxr]?\\s*\\{",e:"\\}",c:f,r:5},{cN:"string",b:"q[qwxr]?\\s*\\|",e:"\\|",c:f,r:5},{cN:"string",b:"q[qwxr]?\\s*\\<",e:"\\>",c:f,r:5},{cN:"string",b:"qw\\s+q",e:"q",c:f,r:5},{cN:"string",b:"'",e:"'",c:[e.BE],r:0},{cN:"string",b:'"',e:'"',c:f,r:0},{cN:"string",b:"`",e:"`",c:[e.BE]},{cN:"string",b:"{\\w+}",r:0},{cN:"string",b:"-?\\w+\\s*\\=\\>",r:0},{cN:"number",b:"(\\b0[0-7_]+)|(\\b0x[0-9a-fA-F_]+)|(\\b[1-9][0-9_]*(\\.[0-9_]+)?)|[0_]\\b",r:0},{b:"("+e.RSR+"|\\b(split|return|print|reverse|grep)\\b)\\s*",k:"split return print reverse grep",r:0,c:[e.HCM,g,{cN:"regexp",b:"(s|tr|y)/(\\\\.|[^/])*/(\\\\.|[^/])*/[a-z]*",r:10},{cN:"regexp",b:"(m|qr)?/",e:"/[a-z]*",c:[e.BE],r:0}]},{cN:"sub",bWK:!0,e:"(\\s*\\(.*?\\))?[;{]",k:"sub",r:5},{cN:"operator",b:"-\\w\\b",r:0}]
d.c=c
h.c[1].c=c
return{k:a,c:c}}(hljs)
hljs.LANGUAGES.scala=function(a){var c={cN:"annotation",b:"@[A-Za-z]+"},b={cN:"string",b:'u?r?"""',e:'"""',r:10}
return{k:"type yield lazy override def with val var false true sealed abstract private trait object null if for while throw finally protected extends import final return else break new catch super class case package default try this match continue throws",c:[{cN:"javadoc",b:"/\\*\\*",e:"\\*/",c:[{cN:"javadoctag",b:"@[A-Za-z]+"}],r:10},a.CLCM,a.CBLCLM,a.ASM,a.QSM,b,{cN:"class",b:"((case )?class |object |trait )",e:"({|$)",i:":",k:"case class trait object",c:[{bWK:!0,k:"extends with",r:10},{cN:"title",b:a.UIR},{cN:"params",b:"\\(",e:"\\)",c:[a.ASM,a.QSM,b,c]}]},a.CNM,c]}}(hljs)
hljs.LANGUAGES.cmake=function(a){return{cI:!0,k:"add_custom_command add_custom_target add_definitions add_dependencies add_executable add_library add_subdirectory add_test aux_source_directory break build_command cmake_minimum_required cmake_policy configure_file create_test_sourcelist define_property else elseif enable_language enable_testing endforeach endfunction endif endmacro endwhile execute_process export find_file find_library find_package find_path find_program fltk_wrap_ui foreach function get_cmake_property get_directory_property get_filename_component get_property get_source_file_property get_target_property get_test_property if include include_directories include_external_msproject include_regular_expression install link_directories load_cache load_command macro mark_as_advanced message option output_required_files project qt_wrap_cpp qt_wrap_ui remove_definitions return separate_arguments set set_directory_properties set_property set_source_files_properties set_target_properties set_tests_properties site_name source_group string target_link_libraries try_compile try_run unset variable_watch while build_name exec_program export_library_dependencies install_files install_programs install_targets link_libraries make_directory remove subdir_depends subdirs use_mangled_mesa utility_source variable_requires write_file",c:[{cN:"envvar",b:"\\${",e:"}"},a.HCM,a.QSM,a.NM]}}(hljs)
hljs.LANGUAGES.objectivec=function(a){var b={keyword:"int float while private char catch export sizeof typedef const struct for union unsigned long volatile static protected bool mutable if public do return goto void enum else break extern class asm case short default double throw register explicit signed typename try this switch continue wchar_t inline readonly assign property protocol self synchronized end synthesize id optional required implementation nonatomic interface super unichar finally dynamic IBOutlet IBAction selector strong weak readonly",literal:"false true FALSE TRUE nil YES NO NULL",built_in:"NSString NSDictionary CGRect CGPoint UIButton UILabel UITextView UIWebView MKMapView UISegmentedControl NSObject UITableViewDelegate UITableViewDataSource NSThread UIActivityIndicator UITabbar UIToolBar UIBarButtonItem UIImageView NSAutoreleasePool UITableView BOOL NSInteger CGFloat NSException NSLog NSMutableString NSMutableArray NSMutableDictionary NSURL NSIndexPath CGSize UITableViewCell UIView UIViewController UINavigationBar UINavigationController UITabBarController UIPopoverController UIPopoverControllerDelegate UIImage NSNumber UISearchBar NSFetchedResultsController NSFetchedResultsChangeType UIScrollView UIScrollViewDelegate UIEdgeInsets UIColor UIFont UIApplication NSNotFound NSNotificationCenter NSNotification UILocalNotification NSBundle NSFileManager NSTimeInterval NSDate NSCalendar NSUserDefaults UIWindow NSRange NSArray NSError NSURLRequest NSURLConnection class UIInterfaceOrientation MPMoviePlayerController dispatch_once_t dispatch_queue_t dispatch_sync dispatch_async dispatch_once"}
return{k:b,i:"</",c:[a.CLCM,a.CBLCLM,a.CNM,a.QSM,{cN:"string",b:"'",e:"[^\\\\]'",i:"[^\\\\][^']"},{cN:"preprocessor",b:"#import",e:"$",c:[{cN:"title",b:'"',e:'"'},{cN:"title",b:"<",e:">"}]},{cN:"preprocessor",b:"#",e:"$"},{cN:"class",bWK:!0,e:"({|$)",k:"interface class protocol implementation",c:[{cN:"id",b:a.UIR}]},{cN:"variable",b:"\\."+a.UIR}]}}(hljs)
hljs.LANGUAGES.avrasm=function(a){return{cI:!0,k:{keyword:"adc add adiw and andi asr bclr bld brbc brbs brcc brcs break breq brge brhc brhs brid brie brlo brlt brmi brne brpl brsh brtc brts brvc brvs bset bst call cbi cbr clc clh cli cln clr cls clt clv clz com cp cpc cpi cpse dec eicall eijmp elpm eor fmul fmuls fmulsu icall ijmp in inc jmp ld ldd ldi lds lpm lsl lsr mov movw mul muls mulsu neg nop or ori out pop push rcall ret reti rjmp rol ror sbc sbr sbrc sbrs sec seh sbi sbci sbic sbis sbiw sei sen ser ses set sev sez sleep spm st std sts sub subi swap tst wdr",built_in:"r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16 r17 r18 r19 r20 r21 r22 r23 r24 r25 r26 r27 r28 r29 r30 r31 x|0 xh xl y|0 yh yl z|0 zh zl ucsr1c udr1 ucsr1a ucsr1b ubrr1l ubrr1h ucsr0c ubrr0h tccr3c tccr3a tccr3b tcnt3h tcnt3l ocr3ah ocr3al ocr3bh ocr3bl ocr3ch ocr3cl icr3h icr3l etimsk etifr tccr1c ocr1ch ocr1cl twcr twdr twar twsr twbr osccal xmcra xmcrb eicra spmcsr spmcr portg ddrg ping portf ddrf sreg sph spl xdiv rampz eicrb eimsk gimsk gicr eifr gifr timsk tifr mcucr mcucsr tccr0 tcnt0 ocr0 assr tccr1a tccr1b tcnt1h tcnt1l ocr1ah ocr1al ocr1bh ocr1bl icr1h icr1l tccr2 tcnt2 ocr2 ocdr wdtcr sfior eearh eearl eedr eecr porta ddra pina portb ddrb pinb portc ddrc pinc portd ddrd pind spdr spsr spcr udr0 ucsr0a ucsr0b ubrr0l acsr admux adcsr adch adcl porte ddre pine pinf"},c:[a.CBLCLM,{cN:"comment",b:";",e:"$"},a.CNM,a.BNM,{cN:"number",b:"\\b(\\$[a-zA-Z0-9]+|0o[0-7]+)"},a.QSM,{cN:"string",b:"'",e:"[^\\\\]'",i:"[^\\\\][^']"},{cN:"label",b:"^[A-Za-z0-9_.$]+:"},{cN:"preprocessor",b:"#",e:"$"},{cN:"preprocessor",b:"\\.[a-zA-Z]+"},{cN:"localvars",b:"@[0-9]+"}]}}(hljs)
hljs.LANGUAGES.vhdl=function(a){return{cI:!0,k:{keyword:"abs access after alias all and architecture array assert attribute begin block body buffer bus case component configuration constant context cover disconnect downto default else elsif end entity exit fairness file for force function generate generic group guarded if impure in inertial inout is label library linkage literal loop map mod nand new next nor not null of on open or others out package port postponed procedure process property protected pure range record register reject release rem report restrict restrict_guarantee return rol ror select sequence severity shared signal sla sll sra srl strong subtype then to transport type unaffected units until use variable vmode vprop vunit wait when while with xnor xor",typename:"boolean bit character severity_level integer time delay_length natural positive string bit_vector file_open_kind file_open_status std_ulogic std_ulogic_vector std_logic std_logic_vector unsigned signed boolean_vector integer_vector real_vector time_vector"},i:"{",c:[a.CBLCLM,{cN:"comment",b:"--",e:"$"},a.QSM,a.CNM,{cN:"literal",b:"'(U|X|0|1|Z|W|L|H|-)'",c:[a.BE]},{cN:"attribute",b:"'[A-Za-z](_?[A-Za-z0-9])*",c:[a.BE]}]}}(hljs)
hljs.LANGUAGES.coffeescript=function(c){var b={keyword:"in if for while finally new do return else break catch instanceof throw try this switch continue typeof delete debugger super then unless until loop of by when and or is isnt not",literal:"true false null undefined yes no on off ",reserved:"case default function var void with const let enum export import native __hasProp __extends __slice __bind __indexOf"},a="[A-Za-z$_][0-9A-Za-z$_]*",e={cN:"title",b:a},d={cN:"subst",b:"#\\{",e:"}",k:b,c:[c.BNM,c.CNM]}
return{k:b,c:[c.BNM,c.CNM,c.ASM,{cN:"string",b:'"""',e:'"""',c:[c.BE,d]},{cN:"string",b:'"',e:'"',c:[c.BE,d],r:0},{cN:"comment",b:"###",e:"###"},c.HCM,{cN:"regexp",b:"///",e:"///",c:[c.HCM]},{cN:"regexp",b:"//[gim]*"},{cN:"regexp",b:"/\\S(\\\\.|[^\\n])*/[gim]*"},{b:"`",e:"`",eB:!0,eE:!0,sL:"javascript"},{cN:"function",b:a+"\\s*=\\s*(\\(.+\\))?\\s*[-=]>",rB:!0,c:[e,{cN:"params",b:"\\(",e:"\\)"}]},{cN:"class",bWK:!0,k:"class",e:"$",i:":",c:[{bWK:!0,k:"extends",eW:!0,i:":",c:[e]},e]},{cN:"property",b:"@"+a}]}}(hljs)
hljs.LANGUAGES.nginx=function(b){var c=[{cN:"variable",b:"\\$\\d+"},{cN:"variable",b:"\\${",e:"}"},{cN:"variable",b:"[\\$\\@]"+b.UIR}],a={eW:!0,l:"[a-z/_]+",k:{built_in:"on off yes no true false none blocked debug info notice warn error crit select break last permanent redirect kqueue rtsig epoll poll /dev/poll"},r:0,i:"=>",c:[b.HCM,{cN:"string",b:'"',e:'"',c:[b.BE].concat(c),r:0},{cN:"string",b:"'",e:"'",c:[b.BE].concat(c),r:0},{cN:"url",b:"([a-z]+):/",e:"\\s",eW:!0,eE:!0},{cN:"regexp",b:"\\s\\^",e:"\\s|{|;",rE:!0,c:[b.BE].concat(c)},{cN:"regexp",b:"~\\*?\\s+",e:"\\s|{|;",rE:!0,c:[b.BE].concat(c)},{cN:"regexp",b:"\\*(\\.[a-z\\-]+)+",c:[b.BE].concat(c)},{cN:"regexp",b:"([a-z\\-]+\\.)+\\*",c:[b.BE].concat(c)},{cN:"number",b:"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(:\\d{1,5})?\\b"},{cN:"number",b:"\\b\\d+[kKmMgGdshdwy]*\\b",r:0}].concat(c)}
return{c:[b.HCM,{b:b.UIR+"\\s",e:";|{",rB:!0,c:[{cN:"title",b:b.UIR,starts:a}]}],i:"[^\\s\\}]"}}(hljs)
hljs.LANGUAGES["erlang-repl"]=function(a){return{k:{special_functions:"spawn spawn_link self",reserved:"after and andalso|10 band begin bnot bor bsl bsr bxor case catch cond div end fun if let not of or orelse|10 query receive rem try when xor"},c:[{cN:"prompt",b:"^[0-9]+> ",r:10},{cN:"comment",b:"%",e:"$"},{cN:"number",b:"\\b(\\d+#[a-fA-F0-9]+|\\d+(\\.\\d+)?([eE][-+]?\\d+)?)",r:0},a.ASM,a.QSM,{cN:"constant",b:"\\?(::)?([A-Z]\\w*(::)?)+"},{cN:"arrow",b:"->"},{cN:"ok",b:"ok"},{cN:"exclamation_mark",b:"!"},{cN:"function_or_atom",b:"(\\b[a-z'][a-zA-Z0-9_']*:[a-z'][a-zA-Z0-9_']*)|(\\b[a-z'][a-zA-Z0-9_']*)",r:0},{cN:"variable",b:"[A-Z][a-zA-Z0-9_']*",r:0}]}}(hljs)
hljs.LANGUAGES.r=function(a){var b="([a-zA-Z]|\\.[a-zA-Z.])[a-zA-Z0-9._]*"
return{c:[a.HCM,{b:b,l:b,k:{keyword:"function if in break next repeat else for return switch while try tryCatch|10 stop warning require library attach detach source setMethod setGeneric setGroupGeneric setClass ...|10",literal:"NULL NA TRUE FALSE T F Inf NaN NA_integer_|10 NA_real_|10 NA_character_|10 NA_complex_|10"},r:0},{cN:"number",b:"0[xX][0-9a-fA-F]+[Li]?\\b",r:0},{cN:"number",b:"\\d+(?:[eE][+\\-]?\\d*)?L\\b",r:0},{cN:"number",b:"\\d+\\.(?!\\d)(?:i\\b)?",r:0},{cN:"number",b:"\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d*)?i?\\b",r:0},{cN:"number",b:"\\.\\d+(?:[eE][+\\-]?\\d*)?i?\\b",r:0},{b:"`",e:"`",r:0},{cN:"string",b:'"',e:'"',c:[a.BE],r:0},{cN:"string",b:"'",e:"'",c:[a.BE],r:0}]}}(hljs)
hljs.LANGUAGES.json=function(a){var e={literal:"true false null"},d=[a.QSM,a.CNM],c={cN:"value",e:",",eW:!0,eE:!0,c:d,k:e},b={b:"{",e:"}",c:[{cN:"attribute",b:'\\s*"',e:'"\\s*:\\s*',eB:!0,eE:!0,c:[a.BE],i:"\\n",starts:c}],i:"\\S"},f={b:"\\[",e:"\\]",c:[a.inherit(c,{cN:null})],i:"\\S"}
d.splice(d.length,0,b,f)
return{c:d,k:e,i:"\\S"}}(hljs)
hljs.LANGUAGES.django=function(c){function e(h,g){return void 0==g||!h.cN&&"tag"==g.cN||"value"==h.cN}function f(l,k){var g={}
for(var j in l){"contains"!=j&&(g[j]=l[j])
for(var m=[],h=0;l.c&&h<l.c.length;h++)m.push(f(l.c[h],l))
e(l,k)&&(m=b.concat(m))
m.length&&(g.c=m)}return g}var d={cN:"filter",b:"\\|[A-Za-z]+\\:?",eE:!0,k:"truncatewords removetags linebreaksbr yesno get_digit timesince random striptags filesizeformat escape linebreaks length_is ljust rjust cut urlize fix_ampersands title floatformat capfirst pprint divisibleby add make_list unordered_list urlencode timeuntil urlizetrunc wordcount stringformat linenumbers slice date dictsort dictsortreversed default_if_none pluralize lower join center default truncatewords_html upper length phone2numeric wordwrap time addslashes slugify first escapejs force_escape iriencode last safe safeseq truncatechars localize unlocalize localtime utc timezone",c:[{cN:"argument",b:'"',e:'"'}]},b=[{cN:"template_comment",b:"{%\\s*comment\\s*%}",e:"{%\\s*endcomment\\s*%}"},{cN:"template_comment",b:"{#",e:"#}"},{cN:"template_tag",b:"{%",e:"%}",k:"comment endcomment load templatetag ifchanged endifchanged if endif firstof for endfor in ifnotequal endifnotequal widthratio extends include spaceless endspaceless regroup by as ifequal endifequal ssi now with cycle url filter endfilter debug block endblock else autoescape endautoescape csrf_token empty elif endwith static trans blocktrans endblocktrans get_static_prefix get_media_prefix plural get_current_language language get_available_languages get_current_language_bidi get_language_info get_language_info_list localize endlocalize localtime endlocaltime timezone endtimezone get_current_timezone",c:[d]},{cN:"variable",b:"{{",e:"}}",c:[d]}],a=f(c.LANGUAGES.xml)
a.cI=!0
return a}(hljs)
hljs.LANGUAGES.delphi=function(b){var f="and safecall cdecl then string exports library not pascal set virtual file in array label packed end. index while const raise for to implementation with except overload destructor downto finally program exit unit inherited override if type until function do begin repeat goto nil far initialization object else var uses external resourcestring interface end finalization class asm mod case on shr shl of register xorwrite threadvar try record near stored constructor stdcall inline div out or procedure",e="safecall stdcall pascal stored const implementation finalization except to finally program inherited override then exports string read not mod shr try div shl set library message packed index for near overload label downto exit public goto interface asm on of constructor or private array unit raise destructor var type until function else external with case default record while protected property procedure published and cdecl do threadvar file in if end virtual write far out begin repeat nil initialization object uses resourcestring class register xorwrite inline static",a={cN:"comment",b:"{",e:"}",r:0},g={cN:"comment",b:"\\(\\*",e:"\\*\\)",r:10},c={cN:"string",b:"'",e:"'",c:[{b:"''"}],r:0},d={cN:"string",b:"(#\\d+)+"},h={cN:"function",bWK:!0,e:"[:;]",k:"function constructor|10 destructor|10 procedure|10",c:[{cN:"title",b:b.IR},{cN:"params",b:"\\(",e:"\\)",k:f,c:[c,d]},a,g]}
return{cI:!0,k:f,i:'("|\\$[G-Zg-z]|\\/\\*|</)',c:[a,g,b.CLCM,c,d,b.NM,h,{cN:"class",b:"=\\bclass\\b",e:"end;",k:e,c:[c,d,a,g,b.CLCM,h]}]}}(hljs)
hljs.LANGUAGES.vbscript=function(a){return{cI:!0,k:{keyword:"call class const dim do loop erase execute executeglobal exit for each next function if then else on error option explicit new private property let get public randomize redim rem select case set stop sub while wend with end to elseif is or xor and not class_initialize class_terminate default preserve in me byval byref step resume goto",built_in:"lcase month vartype instrrev ubound setlocale getobject rgb getref string weekdayname rnd dateadd monthname now day minute isarray cbool round formatcurrency conversions csng timevalue second year space abs clng timeserial fixs len asc isempty maths dateserial atn timer isobject filter weekday datevalue ccur isdate instr datediff formatdatetime replace isnull right sgn array snumeric log cdbl hex chr lbound msgbox ucase getlocale cos cdate cbyte rtrim join hour oct typename trim strcomp int createobject loadpicture tan formatnumber mid scriptenginebuildversion scriptengine split scriptengineminorversion cint sin datepart ltrim sqr scriptenginemajorversion time derived eval date formatpercent exp inputbox left ascw chrw regexp server response request cstr err",literal:"true false null nothing empty"},i:"//",c:[a.inherit(a.QSM,{c:[{b:'""'}]}),{cN:"comment",b:"'",e:"$"},a.CNM]}}(hljs)
hljs.LANGUAGES.mel=function(a){return{k:"int float string vector matrix if else switch case default while do for in break continue global proc return about abs addAttr addAttributeEditorNodeHelp addDynamic addNewShelfTab addPP addPanelCategory addPrefixToName advanceToNextDrivenKey affectedNet affects aimConstraint air alias aliasAttr align alignCtx alignCurve alignSurface allViewFit ambientLight angle angleBetween animCone animCurveEditor animDisplay animView annotate appendStringArray applicationName applyAttrPreset applyTake arcLenDimContext arcLengthDimension arclen arrayMapper art3dPaintCtx artAttrCtx artAttrPaintVertexCtx artAttrSkinPaintCtx artAttrTool artBuildPaintMenu artFluidAttrCtx artPuttyCtx artSelectCtx artSetPaintCtx artUserPaintCtx assignCommand assignInputDevice assignViewportFactories attachCurve attachDeviceAttr attachSurface attrColorSliderGrp attrCompatibility attrControlGrp attrEnumOptionMenu attrEnumOptionMenuGrp attrFieldGrp attrFieldSliderGrp attrNavigationControlGrp attrPresetEditWin attributeExists attributeInfo attributeMenu attributeQuery autoKeyframe autoPlace bakeClip bakeFluidShading bakePartialHistory bakeResults bakeSimulation basename basenameEx batchRender bessel bevel bevelPlus binMembership bindSkin blend2 blendShape blendShapeEditor blendShapePanel blendTwoAttr blindDataType boneLattice boundary boxDollyCtx boxZoomCtx bufferCurve buildBookmarkMenu buildKeyframeMenu button buttonManip CBG cacheFile cacheFileCombine cacheFileMerge cacheFileTrack camera cameraView canCreateManip canvas capitalizeString catch catchQuiet ceil changeSubdivComponentDisplayLevel changeSubdivRegion channelBox character characterMap characterOutlineEditor characterize chdir checkBox checkBoxGrp checkDefaultRenderGlobals choice circle circularFillet clamp clear clearCache clip clipEditor clipEditorCurrentTimeCtx clipSchedule clipSchedulerOutliner clipTrimBefore closeCurve closeSurface cluster cmdFileOutput cmdScrollFieldExecuter cmdScrollFieldReporter cmdShell coarsenSubdivSelectionList collision color colorAtPoint colorEditor colorIndex colorIndexSliderGrp colorSliderButtonGrp colorSliderGrp columnLayout commandEcho commandLine commandPort compactHairSystem componentEditor compositingInterop computePolysetVolume condition cone confirmDialog connectAttr connectControl connectDynamic connectJoint connectionInfo constrain constrainValue constructionHistory container containsMultibyte contextInfo control convertFromOldLayers convertIffToPsd convertLightmap convertSolidTx convertTessellation convertUnit copyArray copyFlexor copyKey copySkinWeights cos cpButton cpCache cpClothSet cpCollision cpConstraint cpConvClothToMesh cpForces cpGetSolverAttr cpPanel cpProperty cpRigidCollisionFilter cpSeam cpSetEdit cpSetSolverAttr cpSolver cpSolverTypes cpTool cpUpdateClothUVs createDisplayLayer createDrawCtx createEditor createLayeredPsdFile createMotionField createNewShelf createNode createRenderLayer createSubdivRegion cross crossProduct ctxAbort ctxCompletion ctxEditMode ctxTraverse currentCtx currentTime currentTimeCtx currentUnit currentUnit curve curveAddPtCtx curveCVCtx curveEPCtx curveEditorCtx curveIntersect curveMoveEPCtx curveOnSurface curveSketchCtx cutKey cycleCheck cylinder dagPose date defaultLightListCheckBox defaultNavigation defineDataServer defineVirtualDevice deformer deg_to_rad delete deleteAttr deleteShadingGroupsAndMaterials deleteShelfTab deleteUI deleteUnusedBrushes delrandstr detachCurve detachDeviceAttr detachSurface deviceEditor devicePanel dgInfo dgdirty dgeval dgtimer dimWhen directKeyCtx directionalLight dirmap dirname disable disconnectAttr disconnectJoint diskCache displacementToPoly displayAffected displayColor displayCull displayLevelOfDetail displayPref displayRGBColor displaySmoothness displayStats displayString displaySurface distanceDimContext distanceDimension doBlur dolly dollyCtx dopeSheetEditor dot dotProduct doubleProfileBirailSurface drag dragAttrContext draggerContext dropoffLocator duplicate duplicateCurve duplicateSurface dynCache dynControl dynExport dynExpression dynGlobals dynPaintEditor dynParticleCtx dynPref dynRelEdPanel dynRelEditor dynamicLoad editAttrLimits editDisplayLayerGlobals editDisplayLayerMembers editRenderLayerAdjustment editRenderLayerGlobals editRenderLayerMembers editor editorTemplate effector emit emitter enableDevice encodeString endString endsWith env equivalent equivalentTol erf error eval eval evalDeferred evalEcho event exactWorldBoundingBox exclusiveLightCheckBox exec executeForEachObject exists exp expression expressionEditorListen extendCurve extendSurface extrude fcheck fclose feof fflush fgetline fgetword file fileBrowserDialog fileDialog fileExtension fileInfo filetest filletCurve filter filterCurve filterExpand filterStudioImport findAllIntersections findAnimCurves findKeyframe findMenuItem findRelatedSkinCluster finder firstParentOf fitBspline flexor floatEq floatField floatFieldGrp floatScrollBar floatSlider floatSlider2 floatSliderButtonGrp floatSliderGrp floor flow fluidCacheInfo fluidEmitter fluidVoxelInfo flushUndo fmod fontDialog fopen formLayout format fprint frameLayout fread freeFormFillet frewind fromNativePath fwrite gamma gauss geometryConstraint getApplicationVersionAsFloat getAttr getClassification getDefaultBrush getFileList getFluidAttr getInputDeviceRange getMayaPanelTypes getModifiers getPanel getParticleAttr getPluginResource getenv getpid glRender glRenderEditor globalStitch gmatch goal gotoBindPose grabColor gradientControl gradientControlNoAttr graphDollyCtx graphSelectContext graphTrackCtx gravity grid gridLayout group groupObjectsByName HfAddAttractorToAS HfAssignAS HfBuildEqualMap HfBuildFurFiles HfBuildFurImages HfCancelAFR HfConnectASToHF HfCreateAttractor HfDeleteAS HfEditAS HfPerformCreateAS HfRemoveAttractorFromAS HfSelectAttached HfSelectAttractors HfUnAssignAS hardenPointCurve hardware hardwareRenderPanel headsUpDisplay headsUpMessage help helpLine hermite hide hilite hitTest hotBox hotkey hotkeyCheck hsv_to_rgb hudButton hudSlider hudSliderButton hwReflectionMap hwRender hwRenderLoad hyperGraph hyperPanel hyperShade hypot iconTextButton iconTextCheckBox iconTextRadioButton iconTextRadioCollection iconTextScrollList iconTextStaticLabel ikHandle ikHandleCtx ikHandleDisplayScale ikSolver ikSplineHandleCtx ikSystem ikSystemInfo ikfkDisplayMethod illustratorCurves image imfPlugins inheritTransform insertJoint insertJointCtx insertKeyCtx insertKnotCurve insertKnotSurface instance instanceable instancer intField intFieldGrp intScrollBar intSlider intSliderGrp interToUI internalVar intersect iprEngine isAnimCurve isConnected isDirty isParentOf isSameObject isTrue isValidObjectName isValidString isValidUiName isolateSelect itemFilter itemFilterAttr itemFilterRender itemFilterType joint jointCluster jointCtx jointDisplayScale jointLattice keyTangent keyframe keyframeOutliner keyframeRegionCurrentTimeCtx keyframeRegionDirectKeyCtx keyframeRegionDollyCtx keyframeRegionInsertKeyCtx keyframeRegionMoveKeyCtx keyframeRegionScaleKeyCtx keyframeRegionSelectKeyCtx keyframeRegionSetKeyCtx keyframeRegionTrackCtx keyframeStats lassoContext lattice latticeDeformKeyCtx launch launchImageEditor layerButton layeredShaderPort layeredTexturePort layout layoutDialog lightList lightListEditor lightListPanel lightlink lineIntersection linearPrecision linstep listAnimatable listAttr listCameras listConnections listDeviceAttachments listHistory listInputDeviceAxes listInputDeviceButtons listInputDevices listMenuAnnotation listNodeTypes listPanelCategories listRelatives listSets listTransforms listUnselected listerEditor loadFluid loadNewShelf loadPlugin loadPluginLanguageResources loadPrefObjects localizedPanelLabel lockNode loft log longNameOf lookThru ls lsThroughFilter lsType lsUI Mayatomr mag makeIdentity makeLive makePaintable makeRoll makeSingleSurface makeTubeOn makebot manipMoveContext manipMoveLimitsCtx manipOptions manipRotateContext manipRotateLimitsCtx manipScaleContext manipScaleLimitsCtx marker match max memory menu menuBarLayout menuEditor menuItem menuItemToShelf menuSet menuSetPref messageLine min minimizeApp mirrorJoint modelCurrentTimeCtx modelEditor modelPanel mouse movIn movOut move moveIKtoFK moveKeyCtx moveVertexAlongDirection multiProfileBirailSurface mute nParticle nameCommand nameField namespace namespaceInfo newPanelItems newton nodeCast nodeIconButton nodeOutliner nodePreset nodeType noise nonLinear normalConstraint normalize nurbsBoolean nurbsCopyUVSet nurbsCube nurbsEditUV nurbsPlane nurbsSelect nurbsSquare nurbsToPoly nurbsToPolygonsPref nurbsToSubdiv nurbsToSubdivPref nurbsUVSet nurbsViewDirectionVector objExists objectCenter objectLayer objectType objectTypeUI obsoleteProc oceanNurbsPreviewPlane offsetCurve offsetCurveOnSurface offsetSurface openGLExtension openMayaPref optionMenu optionMenuGrp optionVar orbit orbitCtx orientConstraint outlinerEditor outlinerPanel overrideModifier paintEffectsDisplay pairBlend palettePort paneLayout panel panelConfiguration panelHistory paramDimContext paramDimension paramLocator parent parentConstraint particle particleExists particleInstancer particleRenderInfo partition pasteKey pathAnimation pause pclose percent performanceOptions pfxstrokes pickWalk picture pixelMove planarSrf plane play playbackOptions playblast plugAttr plugNode pluginInfo pluginResourceUtil pointConstraint pointCurveConstraint pointLight pointMatrixMult pointOnCurve pointOnSurface pointPosition poleVectorConstraint polyAppend polyAppendFacetCtx polyAppendVertex polyAutoProjection polyAverageNormal polyAverageVertex polyBevel polyBlendColor polyBlindData polyBoolOp polyBridgeEdge polyCacheMonitor polyCheck polyChipOff polyClipboard polyCloseBorder polyCollapseEdge polyCollapseFacet polyColorBlindData polyColorDel polyColorPerVertex polyColorSet polyCompare polyCone polyCopyUV polyCrease polyCreaseCtx polyCreateFacet polyCreateFacetCtx polyCube polyCut polyCutCtx polyCylinder polyCylindricalProjection polyDelEdge polyDelFacet polyDelVertex polyDuplicateAndConnect polyDuplicateEdge polyEditUV polyEditUVShell polyEvaluate polyExtrudeEdge polyExtrudeFacet polyExtrudeVertex polyFlipEdge polyFlipUV polyForceUV polyGeoSampler polyHelix polyInfo polyInstallAction polyLayoutUV polyListComponentConversion polyMapCut polyMapDel polyMapSew polyMapSewMove polyMergeEdge polyMergeEdgeCtx polyMergeFacet polyMergeFacetCtx polyMergeUV polyMergeVertex polyMirrorFace polyMoveEdge polyMoveFacet polyMoveFacetUV polyMoveUV polyMoveVertex polyNormal polyNormalPerVertex polyNormalizeUV polyOptUvs polyOptions polyOutput polyPipe polyPlanarProjection polyPlane polyPlatonicSolid polyPoke polyPrimitive polyPrism polyProjection polyPyramid polyQuad polyQueryBlindData polyReduce polySelect polySelectConstraint polySelectConstraintMonitor polySelectCtx polySelectEditCtx polySeparate polySetToFaceNormal polySewEdge polyShortestPathCtx polySmooth polySoftEdge polySphere polySphericalProjection polySplit polySplitCtx polySplitEdge polySplitRing polySplitVertex polyStraightenUVBorder polySubdivideEdge polySubdivideFacet polyToSubdiv polyTorus polyTransfer polyTriangulate polyUVSet polyUnite polyWedgeFace popen popupMenu pose pow preloadRefEd print progressBar progressWindow projFileViewer projectCurve projectTangent projectionContext projectionManip promptDialog propModCtx propMove psdChannelOutliner psdEditTextureFile psdExport psdTextureFile putenv pwd python querySubdiv quit rad_to_deg radial radioButton radioButtonGrp radioCollection radioMenuItemCollection rampColorPort rand randomizeFollicles randstate rangeControl readTake rebuildCurve rebuildSurface recordAttr recordDevice redo reference referenceEdit referenceQuery refineSubdivSelectionList refresh refreshAE registerPluginResource rehash reloadImage removeJoint removeMultiInstance removePanelCategory rename renameAttr renameSelectionList renameUI render renderGlobalsNode renderInfo renderLayerButton renderLayerParent renderLayerPostProcess renderLayerUnparent renderManip renderPartition renderQualityNode renderSettings renderThumbnailUpdate renderWindowEditor renderWindowSelectContext renderer reorder reorderDeformers requires reroot resampleFluid resetAE resetPfxToPolyCamera resetTool resolutionNode retarget reverseCurve reverseSurface revolve rgb_to_hsv rigidBody rigidSolver roll rollCtx rootOf rot rotate rotationInterpolation roundConstantRadius rowColumnLayout rowLayout runTimeCommand runup sampleImage saveAllShelves saveAttrPreset saveFluid saveImage saveInitialState saveMenu savePrefObjects savePrefs saveShelf saveToolSettings scale scaleBrushBrightness scaleComponents scaleConstraint scaleKey scaleKeyCtx sceneEditor sceneUIReplacement scmh scriptCtx scriptEditorInfo scriptJob scriptNode scriptTable scriptToShelf scriptedPanel scriptedPanelType scrollField scrollLayout sculpt searchPathArray seed selLoadSettings select selectContext selectCurveCV selectKey selectKeyCtx selectKeyframeRegionCtx selectMode selectPref selectPriority selectType selectedNodes selectionConnection separator setAttr setAttrEnumResource setAttrMapping setAttrNiceNameResource setConstraintRestPosition setDefaultShadingGroup setDrivenKeyframe setDynamic setEditCtx setEditor setFluidAttr setFocus setInfinity setInputDeviceMapping setKeyCtx setKeyPath setKeyframe setKeyframeBlendshapeTargetWts setMenuMode setNodeNiceNameResource setNodeTypeFlag setParent setParticleAttr setPfxToPolyCamera setPluginResource setProject setStampDensity setStartupMessage setState setToolTo setUITemplate setXformManip sets shadingConnection shadingGeometryRelCtx shadingLightRelCtx shadingNetworkCompare shadingNode shapeCompare shelfButton shelfLayout shelfTabLayout shellField shortNameOf showHelp showHidden showManipCtx showSelectionInTitle showShadingGroupAttrEditor showWindow sign simplify sin singleProfileBirailSurface size sizeBytes skinCluster skinPercent smoothCurve smoothTangentSurface smoothstep snap2to2 snapKey snapMode snapTogetherCtx snapshot soft softMod softModCtx sort sound soundControl source spaceLocator sphere sphrand spotLight spotLightPreviewPort spreadSheetEditor spring sqrt squareSurface srtContext stackTrace startString startsWith stitchAndExplodeShell stitchSurface stitchSurfacePoints strcmp stringArrayCatenate stringArrayContains stringArrayCount stringArrayInsertAtIndex stringArrayIntersector stringArrayRemove stringArrayRemoveAtIndex stringArrayRemoveDuplicates stringArrayRemoveExact stringArrayToString stringToStringArray strip stripPrefixFromName stroke subdAutoProjection subdCleanTopology subdCollapse subdDuplicateAndConnect subdEditUV subdListComponentConversion subdMapCut subdMapSewMove subdMatchTopology subdMirror subdToBlind subdToPoly subdTransferUVsToCache subdiv subdivCrease subdivDisplaySmoothness substitute substituteAllString substituteGeometry substring surface surfaceSampler surfaceShaderList swatchDisplayPort switchTable symbolButton symbolCheckBox sysFile system tabLayout tan tangentConstraint texLatticeDeformContext texManipContext texMoveContext texMoveUVShellContext texRotateContext texScaleContext texSelectContext texSelectShortestPathCtx texSmudgeUVContext texWinToolCtx text textCurves textField textFieldButtonGrp textFieldGrp textManip textScrollList textToShelf textureDisplacePlane textureHairColor texturePlacementContext textureWindow threadCount threePointArcCtx timeControl timePort timerX toNativePath toggle toggleAxis toggleWindowVisibility tokenize tokenizeList tolerance tolower toolButton toolCollection toolDropped toolHasOptions toolPropertyWindow torus toupper trace track trackCtx transferAttributes transformCompare transformLimits translator trim trunc truncateFluidCache truncateHairCache tumble tumbleCtx turbulence twoPointArcCtx uiRes uiTemplate unassignInputDevice undo undoInfo ungroup uniform unit unloadPlugin untangleUV untitledFileName untrim upAxis updateAE userCtx uvLink uvSnapshot validateShelfName vectorize view2dToolCtx viewCamera viewClipPlane viewFit viewHeadOn viewLookAt viewManip viewPlace viewSet visor volumeAxis vortex waitCursor warning webBrowser webBrowserPrefs whatIs window windowPref wire wireContext workspace wrinkle wrinkleContext writeTake xbmLangPathList xform",i:"</",c:[a.CNM,a.ASM,a.QSM,{cN:"string",b:"`",e:"`",c:[a.BE]},{cN:"variable",b:"\\$\\d",r:5},{cN:"variable",b:"[\\$\\%\\@\\*](\\^\\w\\b|#\\w+|[^\\s\\w{]|{\\w+}|\\w+)"},a.CLCM,a.CBLCLM]}}(hljs)
hljs.LANGUAGES.dos=function(){return{cI:!0,k:{flow:"if else goto for in do call exit not exist errorlevel defined equ neq lss leq gtr geq",keyword:"shift cd dir echo setlocal endlocal set pause copy",stream:"prn nul lpt3 lpt2 lpt1 con com4 com3 com2 com1 aux",winutils:"ping net ipconfig taskkill xcopy ren del"},c:[{cN:"envvar",b:"%%[^ ]"},{cN:"envvar",b:"%[^ ]+?%"},{cN:"envvar",b:"![^ ]+?!"},{cN:"number",b:"\\b\\d+",r:0},{cN:"comment",b:"@?rem",e:"$"}]}}(hljs)
hljs.LANGUAGES.apache=function(a){var b={cN:"number",b:"[\\$%]\\d+"}
return{cI:!0,k:{keyword:"acceptfilter acceptmutex acceptpathinfo accessfilename action addalt addaltbyencoding addaltbytype addcharset adddefaultcharset adddescription addencoding addhandler addicon addiconbyencoding addiconbytype addinputfilter addlanguage addmoduleinfo addoutputfilter addoutputfilterbytype addtype alias aliasmatch allow allowconnect allowencodedslashes allowoverride anonymous anonymous_logemail anonymous_mustgiveemail anonymous_nouserid anonymous_verifyemail authbasicauthoritative authbasicprovider authdbduserpwquery authdbduserrealmquery authdbmgroupfile authdbmtype authdbmuserfile authdefaultauthoritative authdigestalgorithm authdigestdomain authdigestnccheck authdigestnonceformat authdigestnoncelifetime authdigestprovider authdigestqop authdigestshmemsize authgroupfile authldapbinddn authldapbindpassword authldapcharsetconfig authldapcomparednonserver authldapdereferencealiases authldapgroupattribute authldapgroupattributeisdn authldapremoteuserattribute authldapremoteuserisdn authldapurl authname authnprovideralias authtype authuserfile authzdbmauthoritative authzdbmtype authzdefaultauthoritative authzgroupfileauthoritative authzldapauthoritative authzownerauthoritative authzuserauthoritative balancermember browsermatch browsermatchnocase bufferedlogs cachedefaultexpire cachedirlength cachedirlevels cachedisable cacheenable cachefile cacheignorecachecontrol cacheignoreheaders cacheignorenolastmod cacheignorequerystring cachelastmodifiedfactor cachemaxexpire cachemaxfilesize cacheminfilesize cachenegotiateddocs cacheroot cachestorenostore cachestoreprivate cgimapextension charsetdefault charsetoptions charsetsourceenc checkcaseonly checkspelling chrootdir contentdigest cookiedomain cookieexpires cookielog cookiename cookiestyle cookietracking coredumpdirectory customlog dav davdepthinfinity davgenericlockdb davlockdb davmintimeout dbdexptime dbdkeep dbdmax dbdmin dbdparams dbdpersist dbdpreparesql dbdriver defaulticon defaultlanguage defaulttype deflatebuffersize deflatecompressionlevel deflatefilternote deflatememlevel deflatewindowsize deny directoryindex directorymatch directoryslash documentroot dumpioinput dumpiologlevel dumpiooutput enableexceptionhook enablemmap enablesendfile errordocument errorlog example expiresactive expiresbytype expiresdefault extendedstatus extfilterdefine extfilteroptions fileetag filterchain filterdeclare filterprotocol filterprovider filtertrace forcelanguagepriority forcetype forensiclog gracefulshutdowntimeout group header headername hostnamelookups identitycheck identitychecktimeout imapbase imapdefault imapmenu include indexheadinsert indexignore indexoptions indexorderdefault indexstylesheet isapiappendlogtoerrors isapiappendlogtoquery isapicachefile isapifakeasync isapilognotsupported isapireadaheadbuffer keepalive keepalivetimeout languagepriority ldapcacheentries ldapcachettl ldapconnectiontimeout ldapopcacheentries ldapopcachettl ldapsharedcachefile ldapsharedcachesize ldaptrustedclientcert ldaptrustedglobalcert ldaptrustedmode ldapverifyservercert limitinternalrecursion limitrequestbody limitrequestfields limitrequestfieldsize limitrequestline limitxmlrequestbody listen listenbacklog loadfile loadmodule lockfile logformat loglevel maxclients maxkeepaliverequests maxmemfree maxrequestsperchild maxrequestsperthread maxspareservers maxsparethreads maxthreads mcachemaxobjectcount mcachemaxobjectsize mcachemaxstreamingbuffer mcacheminobjectsize mcacheremovalalgorithm mcachesize metadir metafiles metasuffix mimemagicfile minspareservers minsparethreads mmapfile mod_gzip_on mod_gzip_add_header_count mod_gzip_keep_workfiles mod_gzip_dechunk mod_gzip_min_http mod_gzip_minimum_file_size mod_gzip_maximum_file_size mod_gzip_maximum_inmem_size mod_gzip_temp_dir mod_gzip_item_include mod_gzip_item_exclude mod_gzip_command_version mod_gzip_can_negotiate mod_gzip_handle_methods mod_gzip_static_suffix mod_gzip_send_vary mod_gzip_update_static modmimeusepathinfo multiviewsmatch namevirtualhost noproxy nwssltrustedcerts nwsslupgradeable options order passenv pidfile protocolecho proxybadheader proxyblock proxydomain proxyerroroverride proxyftpdircharset proxyiobuffersize proxymaxforwards proxypass proxypassinterpolateenv proxypassmatch proxypassreverse proxypassreversecookiedomain proxypassreversecookiepath proxypreservehost proxyreceivebuffersize proxyremote proxyremotematch proxyrequests proxyset proxystatus proxytimeout proxyvia readmename receivebuffersize redirect redirectmatch redirectpermanent redirecttemp removecharset removeencoding removehandler removeinputfilter removelanguage removeoutputfilter removetype requestheader require rewritebase rewritecond rewriteengine rewritelock rewritelog rewriteloglevel rewritemap rewriteoptions rewriterule rlimitcpu rlimitmem rlimitnproc satisfy scoreboardfile script scriptalias scriptaliasmatch scriptinterpretersource scriptlog scriptlogbuffer scriptloglength scriptsock securelisten seerequesttail sendbuffersize serveradmin serveralias serverlimit servername serverpath serverroot serversignature servertokens setenv setenvif setenvifnocase sethandler setinputfilter setoutputfilter ssienableaccess ssiendtag ssierrormsg ssistarttag ssitimeformat ssiundefinedecho sslcacertificatefile sslcacertificatepath sslcadnrequestfile sslcadnrequestpath sslcarevocationfile sslcarevocationpath sslcertificatechainfile sslcertificatefile sslcertificatekeyfile sslciphersuite sslcryptodevice sslengine sslhonorciperorder sslmutex ssloptions sslpassphrasedialog sslprotocol sslproxycacertificatefile sslproxycacertificatepath sslproxycarevocationfile sslproxycarevocationpath sslproxyciphersuite sslproxyengine sslproxymachinecertificatefile sslproxymachinecertificatepath sslproxyprotocol sslproxyverify sslproxyverifydepth sslrandomseed sslrequire sslrequiressl sslsessioncache sslsessioncachetimeout sslusername sslverifyclient sslverifydepth startservers startthreads substitute suexecusergroup threadlimit threadsperchild threadstacksize timeout traceenable transferlog typesconfig unsetenv usecanonicalname usecanonicalphysicalport user userdir virtualdocumentroot virtualdocumentrootip virtualscriptalias virtualscriptaliasip win32disableacceptex xbithack",literal:"on off"},c:[a.HCM,{cN:"sqbracket",b:"\\s\\[",e:"\\]$"},{cN:"cbracket",b:"[\\$%]\\{",e:"\\}",c:["self",b]},b,{cN:"tag",b:"</?",e:">"},a.QSM]}}(hljs)
hljs.LANGUAGES.applescript=function(a){var b=a.inherit(a.QSM,{i:""}),e={cN:"title",b:a.UIR},d={cN:"params",b:"\\(",e:"\\)",c:["self",a.CNM,b]},c=[{cN:"comment",b:"--",e:"$"},{cN:"comment",b:"\\(\\*",e:"\\*\\)",c:["self",{b:"--",e:"$"}]},a.HCM]
return{k:{keyword:"about above after against and around as at back before beginning behind below beneath beside between but by considering contain contains continue copy div does eighth else end equal equals error every exit fifth first for fourth from front get given global if ignoring in into is it its last local me middle mod my ninth not of on onto or over prop property put ref reference repeat returning script second set seventh since sixth some tell tenth that the then third through thru timeout times to transaction try until where while whose with without",constant:"AppleScript false linefeed return pi quote result space tab true",type:"alias application boolean class constant date file integer list number real record string text",command:"activate beep count delay launch log offset read round run say summarize write",property:"character characters contents day frontmost id item length month name paragraph paragraphs rest reverse running time version weekday word words year"},c:[b,a.CNM,{cN:"type",b:"\\bPOSIX file\\b"},{cN:"command",b:"\\b(clipboard info|the clipboard|info for|list (disks|folder)|mount volume|path to|(close|open for) access|(get|set) eof|current date|do shell script|get volume settings|random number|set volume|system attribute|system info|time to GMT|(load|run|store) script|scripting components|ASCII (character|number)|localized string|choose (application|color|file|file name|folder|from list|remote application|URL)|display (alert|dialog))\\b|^\\s*return\\b"},{cN:"constant",b:"\\b(text item delimiters|current application|missing value)\\b"},{cN:"keyword",b:"\\b(apart from|aside from|instead of|out of|greater than|isn't|(doesn't|does not) (equal|come before|come after|contain)|(greater|less) than( or equal)?|(starts?|ends|begins?) with|contained by|comes (before|after)|a (ref|reference))\\b"},{cN:"property",b:"\\b(POSIX path|(date|time) string|quoted form)\\b"},{cN:"function_start",bWK:!0,k:"on",i:"[${=;\\n]",c:[e,d]}].concat(c)}}(hljs)
hljs.LANGUAGES.cpp=function(a){var b={keyword:"false int float while private char catch export virtual operator sizeof dynamic_cast|10 typedef const_cast|10 const struct for static_cast|10 union namespace unsigned long throw volatile static protected bool template mutable if public friend do return goto auto void enum else break new extern using true class asm case typeid short reinterpret_cast|10 default double register explicit signed typename try this switch continue wchar_t inline delete alignof char16_t char32_t constexpr decltype noexcept nullptr static_assert thread_local restrict _Bool complex",built_in:"std string cin cout cerr clog stringstream istringstream ostringstream auto_ptr deque list queue stack vector map set bitset multiset multimap unordered_set unordered_map unordered_multiset unordered_multimap array shared_ptr"}
return{k:b,i:"</",c:[a.CLCM,a.CBLCLM,a.QSM,{cN:"string",b:"'\\\\?.",e:"'",i:"."},{cN:"number",b:"\\b(\\d+(\\.\\d*)?|\\.\\d+)(u|U|l|L|ul|UL|f|F)"},a.CNM,{cN:"preprocessor",b:"#",e:"$"},{cN:"stl_container",b:"\\b(deque|list|queue|stack|vector|map|set|bitset|multiset|multimap|unordered_map|unordered_set|unordered_multiset|unordered_multimap|array)\\s*<",e:">",k:b,r:10,c:["self"]}]}}(hljs)
hljs.LANGUAGES.matlab=function(a){var b=[a.CNM,{cN:"string",b:"'",e:"'",c:[a.BE,{b:"''"}],r:0}]
return{k:{keyword:"break case catch classdef continue else elseif end enumerated events for function global if methods otherwise parfor persistent properties return spmd switch try while",built_in:"sin sind sinh asin asind asinh cos cosd cosh acos acosd acosh tan tand tanh atan atand atan2 atanh sec secd sech asec asecd asech csc cscd csch acsc acscd acsch cot cotd coth acot acotd acoth hypot exp expm1 log log1p log10 log2 pow2 realpow reallog realsqrt sqrt nthroot nextpow2 abs angle complex conj imag real unwrap isreal cplxpair fix floor ceil round mod rem sign airy besselj bessely besselh besseli besselk beta betainc betaln ellipj ellipke erf erfc erfcx erfinv expint gamma gammainc gammaln psi legendre cross dot factor isprime primes gcd lcm rat rats perms nchoosek factorial cart2sph cart2pol pol2cart sph2cart hsv2rgb rgb2hsv zeros ones eye repmat rand randn linspace logspace freqspace meshgrid accumarray size length ndims numel disp isempty isequal isequalwithequalnans cat reshape diag blkdiag tril triu fliplr flipud flipdim rot90 find sub2ind ind2sub bsxfun ndgrid permute ipermute shiftdim circshift squeeze isscalar isvector ans eps realmax realmin pi i inf nan isnan isinf isfinite j why compan gallery hadamard hankel hilb invhilb magic pascal rosser toeplitz vander wilkinson"},i:'(//|"|#|/\\*|\\s+/\\w+)',c:[{cN:"function",bWK:!0,e:"$",k:"function",c:[{cN:"title",b:a.UIR},{cN:"params",b:"\\(",e:"\\)"},{cN:"params",b:"\\[",e:"\\]"}]},{cN:"transposed_variable",b:"[a-zA-Z_][a-zA-Z_0-9]*('+[\\.']*|[\\.']+)",e:""},{cN:"matrix",b:"\\[",e:"\\]'*[\\.']*",c:b},{cN:"cell",b:"\\{",e:"\\}'*[\\.']*",c:b},{cN:"comment",b:"\\%",e:"$"}].concat(b)}}(hljs)
hljs.LANGUAGES.parser3=function(a){return{sL:"xml",c:[{cN:"comment",b:"^#",e:"$"},{cN:"comment",b:"\\^rem{",e:"}",r:10,c:[{b:"{",e:"}",c:["self"]}]},{cN:"preprocessor",b:"^@(?:BASE|USE|CLASS|OPTIONS)$",r:10},{cN:"title",b:"@[\\w\\-]+\\[[\\w^;\\-]*\\](?:\\[[\\w^;\\-]*\\])?(?:.*)$"},{cN:"variable",b:"\\$\\{?[\\w\\-\\.\\:]+\\}?"},{cN:"keyword",b:"\\^[\\w\\-\\.\\:]+"},{cN:"number",b:"\\^#[0-9a-fA-F]+"},a.CNM]}}(hljs)
hljs.LANGUAGES.clojure=function(l){var e={built_in:"def cond apply if-not if-let if not not= = &lt; < > &lt;= <= >= == + / * - rem quot neg? pos? delay? symbol? keyword? true? false? integer? empty? coll? list? set? ifn? fn? associative? sequential? sorted? counted? reversible? number? decimal? class? distinct? isa? float? rational? reduced? ratio? odd? even? char? seq? vector? string? map? nil? contains? zero? instance? not-every? not-any? libspec? -> ->> .. . inc compare do dotimes mapcat take remove take-while drop letfn drop-last take-last drop-while while intern condp case reduced cycle split-at split-with repeat replicate iterate range merge zipmap declare line-seq sort comparator sort-by dorun doall nthnext nthrest partition eval doseq await await-for let agent atom send send-off release-pending-sends add-watch mapv filterv remove-watch agent-error restart-agent set-error-handler error-handler set-error-mode! error-mode shutdown-agents quote var fn loop recur throw try monitor-enter monitor-exit defmacro defn defn- macroexpand macroexpand-1 for doseq dosync dotimes and or when when-not when-let comp juxt partial sequence memoize constantly complement identity assert peek pop doto proxy defstruct first rest cons defprotocol cast coll deftype defrecord last butlast sigs reify second ffirst fnext nfirst nnext defmulti defmethod meta with-meta ns in-ns create-ns import intern refer keys select-keys vals key val rseq name namespace promise into transient persistent! conj! assoc! dissoc! pop! disj! import use class type num float double short byte boolean bigint biginteger bigdec print-method print-dup throw-if throw printf format load compile get-in update-in pr pr-on newline flush read slurp read-line subvec with-open memfn time ns assert re-find re-groups rand-int rand mod locking assert-valid-fdecl alias namespace resolve ref deref refset swap! reset! set-validator! compare-and-set! alter-meta! reset-meta! commute get-validator alter ref-set ref-history-count ref-min-history ref-max-history ensure sync io! new next conj set! memfn to-array future future-call into-array aset gen-class reduce merge map filter find empty hash-map hash-set sorted-map sorted-map-by sorted-set sorted-set-by vec vector seq flatten reverse assoc dissoc list disj get union difference intersection extend extend-type extend-protocol int nth delay count concat chunk chunk-buffer chunk-append chunk-first chunk-rest max min dec unchecked-inc-int unchecked-inc unchecked-dec-inc unchecked-dec unchecked-negate unchecked-add-int unchecked-add unchecked-subtract-int unchecked-subtract chunk-next chunk-cons chunked-seq? prn vary-meta lazy-seq spread list* str find-keyword keyword symbol gensym force rationalize"},f="[a-zA-Z_0-9\\!\\.\\?\\-\\+\\*\\/\\<\\=\\>\\&\\#\\$';]+",a="[\\s:\\(\\{]+\\d+(\\.\\d+)?",d={cN:"number",b:a,r:0},j={cN:"string",b:'"',e:'"',c:[l.BE],r:0},o={cN:"comment",b:";",e:"$",r:0},n={cN:"collection",b:"[\\[\\{]",e:"[\\]\\}]"},c={cN:"comment",b:"\\^"+f},b={cN:"comment",b:"\\^\\{",e:"\\}"},h={cN:"attribute",b:"[:]"+f},m={cN:"list",b:"\\(",e:"\\)",r:0},g={eW:!0,eE:!0,k:{literal:"true false nil"},r:0},i={k:e,l:f,cN:"title",b:f,starts:g}
m.c=[{cN:"comment",b:"comment"},i]
g.c=[m,j,c,b,o,h,n,d]
n.c=[m,j,c,o,h,n,d]
return{i:"\\S",c:[o,m]}}(hljs)
hljs.LANGUAGES.go=function(a){var b={keyword:"break default func interface select case map struct chan else goto package switch const fallthrough if range type continue for import return var go defer",constant:"true false iota nil",typename:"bool byte complex64 complex128 float32 float64 int8 int16 int32 int64 string uint8 uint16 uint32 uint64 int uint uintptr rune",built_in:"append cap close complex copy imag len make new panic print println real recover delete"}
return{k:b,i:"</",c:[a.CLCM,a.CBLCLM,a.QSM,{cN:"string",b:"'",e:"[^\\\\]'",r:0},{cN:"string",b:"`",e:"`"},{cN:"number",b:"[^a-zA-Z_0-9](\\-|\\+)?\\d+(\\.\\d+|\\/\\d+)?((d|e|f|l|s)(\\+|\\-)?\\d+)?",r:0},a.CNM]}}(hljs)

var Inflector
Inflector=function(){function Inflector(value){if(!(this instanceof Inflector))return new Inflector(value)
this.value=value
return void 0}var inflection,InflectionJS,__slice=Array.prototype.slice
InflectionJS={uncountable_words:["equipment","information","rice","money","species","series","fish","sheep","moose","deer","news"],plural_rules:[[new RegExp("(m)an$","gi"),"$1en"],[new RegExp("(pe)rson$","gi"),"$1ople"],[new RegExp("(child)$","gi"),"$1ren"],[new RegExp("^(ox)$","gi"),"$1en"],[new RegExp("(ax|test)is$","gi"),"$1es"],[new RegExp("(octop|vir)us$","gi"),"$1i"],[new RegExp("(alias|status|by)$","gi"),"$1es"],[new RegExp("(bu)s$","gi"),"$1ses"],[new RegExp("(buffal|tomat|potat)o$","gi"),"$1oes"],[new RegExp("([ti])um$","gi"),"$1a"],[new RegExp("sis$","gi"),"ses"],[new RegExp("(?:([^f])fe|([lr])f)$","gi"),"$1$2ves"],[new RegExp("(hive)$","gi"),"$1s"],[new RegExp("([^aeiouy]|qu)y$","gi"),"$1ies"],[new RegExp("(x|ch|ss|sh)$","gi"),"$1es"],[new RegExp("(matr|vert|ind)ix|ex$","gi"),"$1ices"],[new RegExp("([m|l])ouse$","gi"),"$1ice"],[new RegExp("(quiz)$","gi"),"$1zes"],[new RegExp("s$","gi"),"s"],[new RegExp("$","gi"),"s"]],singular_rules:[[new RegExp("(m)en$","gi"),"$1an"],[new RegExp("(pe)ople$","gi"),"$1rson"],[new RegExp("(child)ren$","gi"),"$1"],[new RegExp("([ti])a$","gi"),"$1um"],[new RegExp("((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$","gi"),"$1$2sis"],[new RegExp("(hive)s$","gi"),"$1"],[new RegExp("(tive)s$","gi"),"$1"],[new RegExp("(curve)s$","gi"),"$1"],[new RegExp("([lr])ves$","gi"),"$1f"],[new RegExp("([^fo])ves$","gi"),"$1fe"],[new RegExp("([^aeiouy]|qu)ies$","gi"),"$1y"],[new RegExp("(s)eries$","gi"),"$1eries"],[new RegExp("(m)ovies$","gi"),"$1ovie"],[new RegExp("(x|ch|ss|sh)es$","gi"),"$1"],[new RegExp("([m|l])ice$","gi"),"$1ouse"],[new RegExp("(bus)es$","gi"),"$1"],[new RegExp("(o)es$","gi"),"$1"],[new RegExp("(shoe)s$","gi"),"$1"],[new RegExp("(cris|ax|test)es$","gi"),"$1is"],[new RegExp("(octop|vir)i$","gi"),"$1us"],[new RegExp("(alias|status)es$","gi"),"$1"],[new RegExp("^(ox)en","gi"),"$1"],[new RegExp("(vert|ind)ices$","gi"),"$1ex"],[new RegExp("(matr)ices$","gi"),"$1ix"],[new RegExp("(quiz)zes$","gi"),"$1"],[new RegExp("s$","gi"),""]],non_titlecased_words:["and","or","nor","a","an","the","so","but","to","of","at","by","from","into","on","onto","off","out","in","over","with","for"],id_suffix:new RegExp("(_ids|_id)$","g"),underbar:new RegExp("_","g"),space_or_underbar:new RegExp("[ _]","g"),uppercase:new RegExp("([A-Z])","g"),underbar_prefix:new RegExp("^_"),apply_rules:function(str,rules,skip,override){if(override)str=override
else{var ignore=skip.indexOf(str.toLowerCase())>-1
if(!ignore)for(var x=0;x<rules.length;x++)if(str.match(rules[x][0])){str=str.replace(rules[x][0],rules[x][1])
break}}return str}}
InflectionJS.pluralize=function(string,plural){return this.apply_rules(string,this.plural_rules,this.uncountable_words,plural)}
InflectionJS.singularize=function(string,singular){return this.apply_rules(string,this.singular_rules,this.uncountable_words,singular)}
InflectionJS.camelize=function(string,lowFirstLetter,dontLowercaseBefore){dontLowercaseBefore||(string=string.toLowerCase())
for(var str_path=string.split("/"),i=0;i<str_path.length;i++){for(var str_arr=str_path[i].split("_"),initX=lowFirstLetter&&i+1===str_path.length?1:0,x=initX;x<str_arr.length;x++)str_arr[x]=str_arr[x].charAt(0).toUpperCase()+str_arr[x].substring(1)
str_path[i]=str_arr.join("")}string=str_path.join("::")
return string}
InflectionJS.underscore=function(string){for(var str_path=string.split("::"),i=0;i<str_path.length;i++){str_path[i]=str_path[i].replace(this.uppercase,"_$1")
str_path[i]=str_path[i].replace(this.underbar_prefix,"")}string=str_path.join("/").toLowerCase()
return string}
InflectionJS.humanize=function(string,lowFirstLetter){string=string.toLowerCase()
string=string.replace(this.id_suffix,"")
string=string.replace(this.underbar," ")
lowFirstLetter||(string=this.capitalize(string))
return string}
InflectionJS.capitalize=function(string,dontLowercaseFirst){dontLowercaseFirst||(string=string.toLowerCase())
string=string.substring(0,1).toUpperCase()+string.substring(1)
return string}
InflectionJS.decapitalize=function(string){string=string.substring(0,1).toLowerCase()+string.substring(1)
return string}
InflectionJS.dasherize=function(string){string=string.replace(this.space_or_underbar,"-")
return string}
InflectionJS.titleize=function(string){string=string.toLowerCase()
string=string.replace(this.underbar," ")
for(var str_arr=string.split(" "),x=0;x<str_arr.length;x++){for(var d=str_arr[x].split("-"),i=0;i<d.length;i++)this.non_titlecased_words.indexOf(d[i].toLowerCase())<0&&(d[i]=this.capitalize(d[i]))
str_arr[x]=d.join("-")}string=str_arr.join(" ")
string=string.substring(0,1).toUpperCase()+string.substring(1)
return string}
InflectionJS.demodulize=function(string){var str_arr=string.split("::")
string=str_arr[str_arr.length-1]
return string}
InflectionJS.tableize=function(string){string=this.pluralize(this.underscore(string))
return string}
InflectionJS.classify=function(string){string=this.singularize(this.camelize(string))
return string}
InflectionJS.foreign_key=function(string,dropIdUbar){string=this.underscore(this.demodulize(string))+(dropIdUbar?"":"_")+"id"
return string}
InflectionJS.ordinalize=function(string){for(var str_arr=string.split(" "),x=0;x<str_arr.length;x++){var i=parseInt(str_arr[x])
if(0/0===i){var ltd=str_arr[x].substring(str_arr[x].length-2),ld=str_arr[x].substring(str_arr[x].length-1),suf="th"
"11"!=ltd&&"12"!=ltd&&"13"!=ltd&&("1"===ld?suf="st":"2"===ld?suf="nd":"3"===ld&&(suf="rd"))
str_arr[x]+=suf}}string=str_arr.join(" ")
return string}
inflection=InflectionJS
Object.keys(inflection).forEach(function(key){Inflector[key]=inflection[key]
return Inflector.prototype[key]=function(){this.value=Inflector[key].apply(Inflector,[this.value].concat(__slice.call(arguments)))
return this}})
Inflector.prototype.tap=function(callback){callback(this.value)
return this}
Inflector.prototype.inspect=function(){return this+""}
Inflector.prototype.toString=function(){return this.value}
Inflector.prototype.valueOf=function(){return this.value}
return Inflector}()

!function(window){"use strict"
var engine,CanvasLoader=function(parentElm,opt){"undefined"==typeof opt&&(opt={})
this.init(parentElm,opt)},p=CanvasLoader.prototype,engines=["canvas","vml"],shapes=["oval","spiral","square","rect","roundRect"],cRX=/^\#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$/,ie8=-1!==navigator.appVersion.indexOf("MSIE")&&8===parseFloat(navigator.appVersion.split("MSIE")[1])?!0:!1,canSup=!!document.createElement("canvas").getContext,safeDensity=40,safeVML=!0,addEl=function(tag,par,opt){var n,el=document.createElement(tag)
for(n in opt)el[n]=opt[n]
"undefined"!=typeof par&&par.appendChild(el)
return el},setCSS=function(el,opt){for(var n in opt)el.style[n]=opt[n]
return el},setAttr=function(el,opt){for(var n in opt)el.setAttribute(n,opt[n])
return el},transCon=function(c,x,y,r){c.save()
c.translate(x,y)
c.rotate(r)
c.translate(-x,-y)
c.beginPath()}
p.init=function(parentElm,opt){"boolean"==typeof opt.safeVML&&(safeVML=opt.safeVML)
try{this.mum=void 0!==parentElm?parentElm:document.body}catch(error){this.mum=document.body}opt.id="undefined"!=typeof opt.id?opt.id:"canvasLoader"
this.cont=addEl("span",this.mum,{id:opt.id})
this.cont.setAttribute("class","canvas-loader")
if(canSup){engine=engines[0]
this.can=addEl("canvas",this.cont)
this.con=this.can.getContext("2d")
this.cCan=setCSS(addEl("canvas",this.cont),{display:"none"})
this.cCon=this.cCan.getContext("2d")}else{engine=engines[1]
if("undefined"==typeof CanvasLoader.vmlSheet){document.getElementsByTagName("head")[0].appendChild(addEl("style"))
CanvasLoader.vmlSheet=document.styleSheets[document.styleSheets.length-1]
var n,a=["group","oval","roundrect","fill"]
for(n in a)CanvasLoader.vmlSheet.addRule(a[n],"behavior:url(#default#VML); position:absolute;")}this.vml=addEl("group",this.cont)}this.setColor(this.color)
this.draw()
setCSS(this.cont,{display:"none"})}
p.cont={}
p.can={}
p.con={}
p.cCan={}
p.cCon={}
p.timer={}
p.activeId=0
p.diameter=40
p.setDiameter=function(diameter){this.diameter=Math.round(Math.abs(diameter))
this.redraw()}
p.getDiameter=function(){return this.diameter}
p.cRGB={}
p.color="#000000"
p.setColor=function(color){this.color=cRX.test(color)?color:"#000000"
this.cRGB=this.getRGB(this.color)
this.redraw()}
p.getColor=function(){return this.color}
p.shape=shapes[0]
p.setShape=function(shape){var n
for(n in shapes)if(shape===shapes[n]){this.shape=shape
this.redraw()
break}}
p.getShape=function(){return this.shape}
p.density=40
p.setDensity=function(density){this.density=safeVML&&engine===engines[1]?Math.round(Math.abs(density))<=safeDensity?Math.round(Math.abs(density)):safeDensity:Math.round(Math.abs(density))
this.density>360&&(this.density=360)
this.activeId=0
this.redraw()}
p.getDensity=function(){return this.density}
p.range=1.3
p.setRange=function(range){this.range=Math.abs(range)
this.redraw()}
p.getRange=function(){return this.range}
p.speed=2
p.setSpeed=function(speed){this.speed=Math.round(Math.abs(speed))}
p.getSpeed=function(){return this.speed}
p.fps=24
p.setFPS=function(fps){this.fps=Math.round(Math.abs(fps))
this.reset()}
p.getFPS=function(){return this.fps}
p.getRGB=function(c){c="#"===c.charAt(0)?c.substring(1,7):c
return{r:parseInt(c.substring(0,2),16),g:parseInt(c.substring(2,4),16),b:parseInt(c.substring(4,6),16)}}
p.draw=function(){var size,w,h,x,y,ang,rads,rad,bitMod,s,g,sh,f,i=0,de=this.density,animBits=Math.round(de*this.range),minBitMod=0,d=1e3,arc=0,c=this.cCon,di=this.diameter,e=.47
if(engine===engines[0]){c.clearRect(0,0,d,d)
setAttr(this.can,{width:di,height:di})
setAttr(this.cCan,{width:di,height:di})
for(;de>i;){bitMod=animBits>=i?1-(1-minBitMod)/animBits*i:bitMod=minBitMod
ang=270-360/de*i
rads=ang/180*Math.PI
c.fillStyle="rgba("+this.cRGB.r+","+this.cRGB.g+","+this.cRGB.b+","+bitMod.toString()+")"
switch(this.shape){case shapes[0]:case shapes[1]:size=.07*di
x=di*e+Math.cos(rads)*(di*e-size)-di*e
y=di*e+Math.sin(rads)*(di*e-size)-di*e
c.beginPath()
this.shape===shapes[1]?c.arc(.5*di+x,.5*di+y,size*bitMod,0,2*Math.PI,!1):c.arc(.5*di+x,.5*di+y,size,0,2*Math.PI,!1)
break
case shapes[2]:size=.12*di
x=Math.cos(rads)*(di*e-size)+.5*di
y=Math.sin(rads)*(di*e-size)+.5*di
transCon(c,x,y,rads)
c.fillRect(x,y-.5*size,size,size)
break
case shapes[3]:case shapes[4]:w=.3*di
h=.27*w
x=Math.cos(rads)*(h+.13*(di-h))+.5*di
y=Math.sin(rads)*(h+.13*(di-h))+.5*di
transCon(c,x,y,rads)
if(this.shape===shapes[3])c.fillRect(x,y-.5*h,w,h)
else{rad=.55*h
c.moveTo(x+rad,y-.5*h)
c.lineTo(x+w-rad,y-.5*h)
c.quadraticCurveTo(x+w,y-.5*h,x+w,y-.5*h+rad)
c.lineTo(x+w,y-.5*h+h-rad)
c.quadraticCurveTo(x+w,y-.5*h+h,x+w-rad,y-.5*h+h)
c.lineTo(x+rad,y-.5*h+h)
c.quadraticCurveTo(x,y-.5*h+h,x,y-.5*h+h-rad)
c.lineTo(x,y-.5*h+rad)
c.quadraticCurveTo(x,y-.5*h,x+rad,y-.5*h)}}c.closePath()
c.fill()
c.restore();++i}}else{setCSS(this.cont,{width:di,height:di})
setCSS(this.vml,{width:di,height:di})
switch(this.shape){case shapes[0]:case shapes[1]:sh="oval"
size=.14*d
break
case shapes[2]:sh="roundrect"
size=.12*d
break
case shapes[3]:case shapes[4]:sh="roundrect"
size=.3*d}w=h=size
x=.5*d-h
y=.5*-h
for(;de>i;){bitMod=animBits>=i?1-(1-minBitMod)/animBits*i:bitMod=minBitMod
ang=270-360/de*i
switch(this.shape){case shapes[1]:w=h=size*bitMod
x=.5*d-.5*size-.5*size*bitMod
y=.5*(size-size*bitMod)
break
case shapes[0]:case shapes[2]:if(ie8){y=0
this.shape===shapes[2]&&(x=.5*d-.5*h)}break
case shapes[3]:case shapes[4]:w=.95*size
h=.28*w
if(ie8){x=0
y=.5*d-.5*h}else{x=.5*d-w
y=.5*-h}arc=this.shape===shapes[4]?.6:0}g=setAttr(setCSS(addEl("group",this.vml),{width:d,height:d,rotation:ang}),{coordsize:d+","+d,coordorigin:.5*-d+","+.5*-d})
s=setCSS(addEl(sh,g,{stroked:!1,arcSize:arc}),{width:w,height:h,top:y,left:x})
f=addEl("fill",s,{color:this.color,opacity:bitMod});++i}}this.tick(!0)}
p.clean=function(){if(engine===engines[0])this.con.clearRect(0,0,1e3,1e3)
else{var v=this.vml
if(v.hasChildNodes())for(;v.childNodes.length>=1;)v.removeChild(v.firstChild)}}
p.redraw=function(){this.clean()
this.draw()}
p.reset=function(){if("number"==typeof this.timer){this.hide()
this.show()}}
p.tick=function(init){var c=this.con,di=this.diameter
init||(this.activeId+=360/this.density*this.speed)
if(engine===engines[0]){c.clearRect(0,0,di,di)
transCon(c,.5*di,.5*di,this.activeId/180*Math.PI)
c.drawImage(this.cCan,0,0,di,di)
c.restore()}else{this.activeId>=360&&(this.activeId-=360)
setCSS(this.vml,{rotation:this.activeId})}}
p.show=function(){if("number"!=typeof this.timer){var t=this
this.timer=self.setInterval(function(){t.tick()},Math.round(1e3/this.fps))
setCSS(this.cont,{display:"block"})}}
p.hide=function(){if("number"==typeof this.timer){clearInterval(this.timer)
delete this.timer
setCSS(this.cont,{display:"none"})}}
p.kill=function(){var c=this.cont
"number"==typeof this.timer&&this.hide()
if(engine===engines[0]){c.removeChild(this.can)
c.removeChild(this.cCan)}else c.removeChild(this.vml)
var n
for(n in this)delete this[n]}
window.CanvasLoader=CanvasLoader}(window)

!function(){function _addEvent(object,type,callback){object.addEventListener?object.addEventListener(type,callback,!1):object.attachEvent("on"+type,callback)}function _characterFromEvent(e){return"keypress"==e.type?String.fromCharCode(e.which):_MAP[e.which]?_MAP[e.which]:_KEYCODE_MAP[e.which]?_KEYCODE_MAP[e.which]:String.fromCharCode(e.which).toLowerCase()}function _modifiersMatch(modifiers1,modifiers2){return modifiers1.sort().join(",")===modifiers2.sort().join(",")}function _resetSequences(do_not_reset){do_not_reset=do_not_reset||{}
var key,active_sequences=!1
for(key in _sequence_levels)do_not_reset[key]?active_sequences=!0:_sequence_levels[key]=0
active_sequences||(_inside_sequence=!1)}function _getMatches(character,modifiers,e,remove,combination){var i,callback,matches=[],action=e.type
if(!_callbacks[character])return[]
"keyup"==action&&_isModifier(character)&&(modifiers=[character])
for(i=0;i<_callbacks[character].length;++i){callback=_callbacks[character][i]
if(!(callback.seq&&_sequence_levels[callback.seq]!=callback.level||action!=callback.action||("keypress"!=action||e.metaKey||e.ctrlKey)&&!_modifiersMatch(modifiers,callback.modifiers))){remove&&callback.combo==combination&&_callbacks[character].splice(i,1)
matches.push(callback)}}return matches}function _eventModifiers(e){var modifiers=[]
e.shiftKey&&modifiers.push("shift")
e.altKey&&modifiers.push("alt")
e.ctrlKey&&modifiers.push("ctrl")
e.metaKey&&modifiers.push("meta")
return modifiers}function _fireCallback(callback,e,combo){if(!Mousetrap.stopCallback(e,e.target||e.srcElement,combo)&&callback(e,combo)===!1){e.preventDefault&&e.preventDefault()
e.stopPropagation&&e.stopPropagation()
e.returnValue=!1
e.cancelBubble=!0}}function _handleCharacter(character,e){var i,callbacks=_getMatches(character,_eventModifiers(e),e),do_not_reset={},processed_sequence_callback=!1
for(i=0;i<callbacks.length;++i)if(callbacks[i].seq){processed_sequence_callback=!0
do_not_reset[callbacks[i].seq]=1
_fireCallback(callbacks[i].callback,e,callbacks[i].combo)}else processed_sequence_callback||_inside_sequence||_fireCallback(callbacks[i].callback,e,callbacks[i].combo)
e.type!=_inside_sequence||_isModifier(character)||_resetSequences(do_not_reset)}function _handleKey(e){"number"!=typeof e.which&&(e.which=e.keyCode)
var character=_characterFromEvent(e)
character&&("keyup"!=e.type||_ignore_next_keyup!=character?_handleCharacter(character,e):_ignore_next_keyup=!1)}function _isModifier(key){return"shift"==key||"ctrl"==key||"alt"==key||"meta"==key}function _resetSequenceTimer(){clearTimeout(_reset_timer)
_reset_timer=setTimeout(_resetSequences,1e3)}function _getReverseMap(){if(!_REVERSE_MAP){_REVERSE_MAP={}
for(var key in _MAP)key>95&&112>key||_MAP.hasOwnProperty(key)&&(_REVERSE_MAP[_MAP[key]]=key)}return _REVERSE_MAP}function _pickBestAction(key,modifiers,action){action||(action=_getReverseMap()[key]?"keydown":"keypress")
"keypress"==action&&modifiers.length&&(action="keydown")
return action}function _bindSequence(combo,keys,callback,action){_sequence_levels[combo]=0
action||(action=_pickBestAction(keys[0],[]))
var i,_increaseSequence=function(){_inside_sequence=action;++_sequence_levels[combo]
_resetSequenceTimer()},_callbackAndReset=function(e){_fireCallback(callback,e,combo)
"keyup"!==action&&(_ignore_next_keyup=_characterFromEvent(e))
setTimeout(_resetSequences,10)}
for(i=0;i<keys.length;++i)_bindSingle(keys[i],i<keys.length-1?_increaseSequence:_callbackAndReset,action,combo,i)}function _bindSingle(combination,callback,action,sequence_name,level){combination=combination.replace(/\s+/g," ")
var i,key,keys,sequence=combination.split(" "),modifiers=[]
if(sequence.length>1)_bindSequence(combination,sequence,callback,action)
else{keys="+"===combination?["+"]:combination.split("+")
for(i=0;i<keys.length;++i){key=keys[i]
_SPECIAL_ALIASES[key]&&(key=_SPECIAL_ALIASES[key])
if(action&&"keypress"!=action&&_SHIFT_MAP[key]){key=_SHIFT_MAP[key]
modifiers.push("shift")}_isModifier(key)&&modifiers.push(key)}action=_pickBestAction(key,modifiers,action)
_callbacks[key]||(_callbacks[key]=[])
_getMatches(key,modifiers,{type:action},!sequence_name,combination)
_callbacks[key][sequence_name?"unshift":"push"]({callback:callback,modifiers:modifiers,action:action,seq:sequence_name,level:level,combo:combination})}}function _bindMultiple(combinations,callback,action){for(var i=0;i<combinations.length;++i)_bindSingle(combinations[i],callback,action)}for(var _REVERSE_MAP,_reset_timer,_MAP={8:"backspace",9:"tab",13:"enter",16:"shift",17:"ctrl",18:"alt",20:"capslock",27:"esc",32:"space",33:"pageup",34:"pagedown",35:"end",36:"home",37:"left",38:"up",39:"right",40:"down",45:"ins",46:"del",91:"meta",93:"meta",224:"meta"},_KEYCODE_MAP={106:"*",107:"+",109:"-",110:".",111:"/",186:";",187:"=",188:",",189:"-",190:".",191:"/",192:"`",219:"[",220:"\\",221:"]",222:"'"},_SHIFT_MAP={"~":"`","!":"1","@":"2","#":"3",$:"4","%":"5","^":"6","&":"7","*":"8","(":"9",")":"0",_:"-","+":"=",":":";",'"':"'","<":",",">":".","?":"/","|":"\\"},_SPECIAL_ALIASES={option:"alt",command:"meta","return":"enter",escape:"esc"},_callbacks={},_direct_map={},_sequence_levels={},_ignore_next_keyup=!1,_inside_sequence=!1,i=1;20>i;++i)_MAP[111+i]="f"+i
for(i=0;9>=i;++i)_MAP[i+96]=i
_addEvent(document,"keypress",_handleKey)
_addEvent(document,"keydown",_handleKey)
_addEvent(document,"keyup",_handleKey)
var Mousetrap={bind:function(keys,callback,action){_bindMultiple(keys instanceof Array?keys:[keys],callback,action)
_direct_map[keys+":"+action]=callback
return this},unbind:function(keys,action){if(_direct_map[keys+":"+action]){delete _direct_map[keys+":"+action]
this.bind(keys,function(){},action)}return this},trigger:function(keys,action){_direct_map[keys+":"+action]()
return this},reset:function(){_callbacks={}
_direct_map={}
return this},stopCallback:function(e,element){return(" "+element.className+" ").indexOf(" mousetrap ")>-1?!1:"INPUT"==element.tagName||"SELECT"==element.tagName||"TEXTAREA"==element.tagName||element.contentEditable&&"true"==element.contentEditable}}
window.Mousetrap=Mousetrap
"function"==typeof define&&define.amd&&define("mousetrap",function(){return Mousetrap})}()

!function(){function outputLink(cap,link){return"!"!==cap[0][0]?'<a href="'+escape(link.href)+'"'+(link.title?' title="'+escape(link.title)+'"':"")+">"+inline.lexer(cap[1])+"</a>":'<img src="'+escape(link.href)+'" alt="'+escape(cap[1])+'"'+(link.title?' title="'+escape(link.title)+'"':"")+">"}function next(){return token=tokens.pop()}function tok(){switch(token.type){case"space":return""
case"hr":return"<hr>\n"
case"heading":return"<h"+token.depth+">"+inline.lexer(token.text)+"</h"+token.depth+">\n"
case"code":if(options.highlight){token.code=options.highlight(token.text,token.lang)
if(null!=token.code&&token.code!==token.text){token.escaped=!0
token.text=token.code}}token.escaped||(token.text=escape(token.text,!0))
return"<pre><code"+(token.lang?' class="lang-'+token.lang+'"':"")+">"+token.text+"</code></pre>\n"
case"blockquote_start":for(var body="";"blockquote_end"!==next().type;)body+=tok()
return"<blockquote>\n"+body+"</blockquote>\n"
case"list_start":for(var type=token.ordered?"ol":"ul",body="";"list_end"!==next().type;)body+=tok()
return"<"+type+">\n"+body+"</"+type+">\n"
case"list_item_start":for(var body="";"list_item_end"!==next().type;)body+="text"===token.type?parseText():tok()
return"<li>"+body+"</li>\n"
case"loose_item_start":for(var body="";"list_item_end"!==next().type;)body+=tok()
return"<li>"+body+"</li>\n"
case"html":return token.pre||options.pedantic?token.text:inline.lexer(token.text)
case"paragraph":return"<p>"+inline.lexer(token.text)+"</p>\n"
case"text":return"<p>"+parseText()+"</p>\n"}}function parseText(){for(var top,body=token.text;(top=tokens[tokens.length-1])&&"text"===top.type;)body+="\n"+next().text
return inline.lexer(body)}function parse(src){tokens=src.reverse()
for(var out="";next();)out+=tok()
tokens=null
token=null
return out}function escape(html,encode){return html.replace(encode?/&/g:/&(?!#?\w+;)/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#39;")}function mangle(text){for(var ch,out="",l=text.length,i=0;l>i;i++){ch=text.charCodeAt(i)
Math.random()>.5&&(ch="x"+ch.toString(16))
out+="&#"+ch+";"}return out}function tag(){var tag="(?!(?:a|em|strong|small|s|cite|q|dfn|abbr|data|time|code|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo|span|br|wbr|ins|del|img)\\b)\\w+(?!:/|@)\\b"
return tag}function replace(regex,opt){regex=regex.source
opt=opt||""
return function self(name,val){if(!name)return new RegExp(regex,opt)
val=val.source||val
val=val.replace(/(^|[^\[])\^/g,"$1")
regex=regex.replace(name,val)
return self}}function noop(){}function marked(src,opt){setOptions(opt)
return parse(block.lexer(src))}function setOptions(opt){opt||(opt=defaults)
if(options!==opt){options=opt
if(options.gfm){block.fences=block.gfm.fences
block.paragraph=block.gfm.paragraph
inline.text=inline.gfm.text
inline.url=inline.gfm.url}else{block.fences=block.normal.fences
block.paragraph=block.normal.paragraph
inline.text=inline.normal.text
inline.url=inline.normal.url}if(options.pedantic){inline.em=inline.pedantic.em
inline.strong=inline.pedantic.strong}else{inline.em=inline.normal.em
inline.strong=inline.normal.strong}}}var block={newline:/^\n+/,code:/^( {4}[^\n]+\n*)+/,fences:noop,hr:/^( *[-*_]){3,} *(?:\n+|$)/,heading:/^ *(#{1,6}) *([^\n]+?) *#* *(?:\n+|$)/,lheading:/^([^\n]+)\n *(=|-){3,} *\n*/,blockquote:/^( *>[^\n]+(\n[^\n]+)*\n*)+/,list:/^( *)(bull) [^\0]+?(?:hr|\n{2,}(?! )(?!\1bull )\n*|\s*$)/,html:/^ *(?:comment|closed|closing) *(?:\n{2,}|\s*$)/,def:/^ *\[([^\]]+)\]: *([^\s]+)(?: +["(]([^\n]+)[")])? *(?:\n+|$)/,paragraph:/^([^\n]+\n?(?!hr|heading|lheading|blockquote|tag|def))+\n*/,text:/^[^\n]+/}
block.bullet=/(?:[*+-]|\d+\.)/
block.item=/^( *)(bull) [^\n]*(?:\n(?!\1bull )[^\n]*)*/
block.item=replace(block.item,"gm")(/bull/g,block.bullet)()
block.list=replace(block.list)(/bull/g,block.bullet)("hr",/\n+(?=(?: *[-*_]){3,} *(?:\n+|$))/)()
block.html=replace(block.html)("comment",/<!--[^\0]*?-->/)("closed",/<(tag)[^\0]+?<\/\1>/)("closing",/<tag(?:"[^"]*"|'[^']*'|[^'">])*?>/)(/tag/g,tag())()
block.paragraph=replace(block.paragraph)("hr",block.hr)("heading",block.heading)("lheading",block.lheading)("blockquote",block.blockquote)("tag","<"+tag())("def",block.def)()
block.normal={fences:block.fences,paragraph:block.paragraph}
block.gfm={fences:/^ *(```|~~~) *(\w+)? *\n([^\0]+?)\s*\1 *(?:\n+|$)/,paragraph:/^/}
block.gfm.paragraph=replace(block.paragraph)("(?!","(?!"+block.gfm.fences.source.replace("\\1","\\2")+"|")()
block.lexer=function(src){var tokens=[]
tokens.links={}
src=src.replace(/\r\n|\r/g,"\n").replace(/\t/g,"    ")
return block.token(src,tokens,!0)}
block.token=function(src,tokens,top){for(var next,loose,cap,item,space,i,l,src=src.replace(/^ +$/gm,"");src;){if(cap=block.newline.exec(src)){src=src.substring(cap[0].length)
cap[0].length>1&&tokens.push({type:"space"})}if(cap=block.code.exec(src)){src=src.substring(cap[0].length)
cap=cap[0].replace(/^ {4}/gm,"")
tokens.push({type:"code",text:options.pedantic?cap:cap.replace(/\n+$/,"")})}else if(cap=block.fences.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"code",lang:cap[2],text:cap[3]})}else if(cap=block.heading.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"heading",depth:cap[1].length,text:cap[2]})}else if(cap=block.lheading.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"heading",depth:"="===cap[2]?1:2,text:cap[1]})}else if(cap=block.hr.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"hr"})}else if(cap=block.blockquote.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"blockquote_start"})
cap=cap[0].replace(/^ *> ?/gm,"")
block.token(cap,tokens,top)
tokens.push({type:"blockquote_end"})}else if(cap=block.list.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"list_start",ordered:isFinite(cap[2])})
cap=cap[0].match(block.item)
next=!1
l=cap.length
i=0
for(;l>i;i++){item=cap[i]
space=item.length
item=item.replace(/^ *([*+-]|\d+\.) +/,"")
if(~item.indexOf("\n ")){space-=item.length
item=options.pedantic?item.replace(/^ {1,4}/gm,""):item.replace(new RegExp("^ {1,"+space+"}","gm"),"")}loose=next||/\n\n(?!\s*$)/.test(item)
if(i!==l-1){next="\n"===item[item.length-1]
loose||(loose=next)}tokens.push({type:loose?"loose_item_start":"list_item_start"})
block.token(item,tokens)
tokens.push({type:"list_item_end"})}tokens.push({type:"list_end"})}else if(cap=block.html.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:options.sanitize?"paragraph":"html",pre:"pre"===cap[1],text:cap[0]})}else if(top&&(cap=block.def.exec(src))){src=src.substring(cap[0].length)
tokens.links[cap[1].toLowerCase()]={href:cap[2],title:cap[3]}}else if(top&&(cap=block.paragraph.exec(src))){src=src.substring(cap[0].length)
tokens.push({type:"paragraph",text:cap[0]})}else if(cap=block.text.exec(src)){src=src.substring(cap[0].length)
tokens.push({type:"text",text:cap[0]})}else;}return tokens}
var inline={escape:/^\\([\\`*{}\[\]()#+\-.!_>])/,autolink:/^<([^ >]+(@|:\/)[^ >]+)>/,url:noop,tag:/^<!--[^\0]*?-->|^<\/?\w+(?:"[^"]*"|'[^']*'|[^'">])*?>/,link:/^!?\[(inside)\]\(href\)/,reflink:/^!?\[(inside)\]\s*\[([^\]]*)\]/,nolink:/^!?\[((?:\[[^\]]*\]|[^\[\]])*)\]/,strong:/^__([^\0]+?)__(?!_)|^\*\*([^\0]+?)\*\*(?!\*)/,em:/^\b_((?:__|[^\0])+?)_\b|^\*((?:\*\*|[^\0])+?)\*(?!\*)/,code:/^(`+)([^\0]*?[^`])\1(?!`)/,br:/^ {2,}\n(?!\s*$)/,text:/^[^\0]+?(?=[\\<!\[_*`]| {2,}\n|$)/}
inline._linkInside=/(?:\[[^\]]*\]|[^\]]|\](?=[^\[]*\]))*/
inline._linkHref=/\s*<?([^\s]*?)>?(?:\s+['"]([^\0]*?)['"])?\s*/
inline.link=replace(inline.link)("inside",inline._linkInside)("href",inline._linkHref)()
inline.reflink=replace(inline.reflink)("inside",inline._linkInside)()
inline.normal={url:inline.url,strong:inline.strong,em:inline.em,text:inline.text}
inline.pedantic={strong:/^__(?=\S)([^\0]*?\S)__(?!_)|^\*\*(?=\S)([^\0]*?\S)\*\*(?!\*)/,em:/^_(?=\S)([^\0]*?\S)_(?!_)|^\*(?=\S)([^\0]*?\S)\*(?!\*)/}
inline.gfm={url:/^(https?:\/\/[^\s]+[^.,:;"')\]\s])/,text:/^[^\0]+?(?=[\\<!\[_*`]|https?:\/\/| {2,}\n|$)/}
inline.lexer=function(src){for(var link,text,href,cap,out="",links=tokens.links;src;)if(cap=inline.escape.exec(src)){src=src.substring(cap[0].length)
out+=cap[1]}else if(cap=inline.autolink.exec(src)){src=src.substring(cap[0].length)
if("@"===cap[2]){text=":"===cap[1][6]?mangle(cap[1].substring(7)):mangle(cap[1])
href=mangle("mailto:")+text}else{text=escape(cap[1])
href=text}out+='<a href="'+href+'">'+text+"</a>"}else if(cap=inline.url.exec(src)){src=src.substring(cap[0].length)
text=escape(cap[1])
href=text
out+='<a href="'+href+'">'+text+"</a>"}else if(cap=inline.tag.exec(src)){src=src.substring(cap[0].length)
out+=options.sanitize?escape(cap[0]):cap[0]}else if(cap=inline.link.exec(src)){src=src.substring(cap[0].length)
out+=outputLink(cap,{href:cap[2],title:cap[3]})}else if((cap=inline.reflink.exec(src))||(cap=inline.nolink.exec(src))){src=src.substring(cap[0].length)
link=(cap[2]||cap[1]).replace(/\s+/g," ")
link=links[link.toLowerCase()]
if(!link||!link.href){out+=cap[0][0]
src=cap[0].substring(1)+src
continue}out+=outputLink(cap,link)}else if(cap=inline.strong.exec(src)){src=src.substring(cap[0].length)
out+="<strong>"+inline.lexer(cap[2]||cap[1])+"</strong>"}else if(cap=inline.em.exec(src)){src=src.substring(cap[0].length)
out+="<em>"+inline.lexer(cap[2]||cap[1])+"</em>"}else if(cap=inline.code.exec(src)){src=src.substring(cap[0].length)
out+="<code>"+escape(cap[2],!0)+"</code>"}else if(cap=inline.br.exec(src)){src=src.substring(cap[0].length)
out+="<br>"}else if(cap=inline.text.exec(src)){src=src.substring(cap[0].length)
out+=escape(cap[0])}else;return out}
var tokens,token
noop.exec=noop
var options,defaults
marked.options=marked.setOptions=function(opt){defaults=opt
setOptions(opt)
return marked}
marked.setOptions({gfm:!0,pedantic:!1,sanitize:!1,highlight:null})
marked.parser=function(src,opt){setOptions(opt)
return parse(src)}
marked.lexer=function(src,opt){setOptions(opt)
return block.lexer(src)}
marked.parse=marked
"undefined"!=typeof module?module.exports=marked:this.marked=marked}.call(function(){return this||("undefined"!=typeof window?window:global)}())

!function(){var __slice=Array.prototype.slice
this.JsPath=function(){function JsPath(path,val){return JsPath.setAt({},path,val||{})}var primTypes
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
if(obj=this.getAt(ref,path))return obj
this.setAt(ref,path,initializer)
return initializer}
JsPath.deleteAt=function(ref,path){var component,last,prev
path="function"==typeof path.split?path.split("."):path.slice()
prev=[]
last=path.pop()
for(;component=path.shift();){if(primTypes.test(typeof ref[component]))throw new Error(""+prev.concat(component).join(".")+" is\nprimitive; cannot drill any deeper.")
if(!(ref=ref[component]))return!1
prev.push(component)}return delete ref[last]}
return JsPath}.call(this)}.call(this)

!function(window,undefined){"use strict"
function setup(){if(!Hammer.READY){Hammer.event.determineEventTypes()
for(var name in Hammer.gestures)Hammer.gestures.hasOwnProperty(name)&&Hammer.detection.register(Hammer.gestures[name])
Hammer.event.onTouch(Hammer.DOCUMENT,Hammer.EVENT_MOVE,Hammer.detection.detect)
Hammer.event.onTouch(Hammer.DOCUMENT,Hammer.EVENT_END,Hammer.detection.detect)
Hammer.READY=!0}}var Hammer=function(element,options){return new Hammer.Instance(element,options||{})}
Hammer.defaults={stop_browser_behavior:{userSelect:"none",touchAction:"none",touchCallout:"none",contentZooming:"none",userDrag:"none",tapHighlightColor:"rgba(0,0,0,0)"}}
Hammer.HAS_POINTEREVENTS=navigator.pointerEnabled||navigator.msPointerEnabled
Hammer.HAS_TOUCHEVENTS="ontouchstart"in window
Hammer.MOBILE_REGEX=/mobile|tablet|ip(ad|hone|od)|android/i
Hammer.NO_MOUSEEVENTS=Hammer.HAS_TOUCHEVENTS&&navigator.userAgent.match(Hammer.MOBILE_REGEX)
Hammer.EVENT_TYPES={}
Hammer.DIRECTION_DOWN="down"
Hammer.DIRECTION_LEFT="left"
Hammer.DIRECTION_UP="up"
Hammer.DIRECTION_RIGHT="right"
Hammer.POINTER_MOUSE="mouse"
Hammer.POINTER_TOUCH="touch"
Hammer.POINTER_PEN="pen"
Hammer.EVENT_START="start"
Hammer.EVENT_MOVE="move"
Hammer.EVENT_END="end"
Hammer.DOCUMENT=document
Hammer.plugins={}
Hammer.READY=!1
Hammer.Instance=function(element,options){var self=this
setup()
this.element=element
this.enabled=!0
this.options=Hammer.utils.extend(Hammer.utils.extend({},Hammer.defaults),options||{})
this.options.stop_browser_behavior&&Hammer.utils.stopDefaultBrowserBehavior(this.element,this.options.stop_browser_behavior)
Hammer.event.onTouch(element,Hammer.EVENT_START,function(ev){self.enabled&&Hammer.detection.startDetect(self,ev)})
return this}
Hammer.Instance.prototype={on:function(gesture,handler){for(var gestures=gesture.split(" "),t=0;t<gestures.length;t++)this.element.addEventListener(gestures[t],handler,!1)
return this},off:function(gesture,handler){for(var gestures=gesture.split(" "),t=0;t<gestures.length;t++)this.element.removeEventListener(gestures[t],handler,!1)
return this},trigger:function(gesture,eventData){var event=Hammer.DOCUMENT.createEvent("Event")
event.initEvent(gesture,!0,!0)
event.gesture=eventData
var element=this.element
Hammer.utils.hasParent(eventData.target,element)&&(element=eventData.target)
element.dispatchEvent(event)
return this},enable:function(state){this.enabled=state
return this}}
var last_move_event=null,enable_detect=!1,touch_triggered=!1
Hammer.event={bindDom:function(element,type,handler){for(var types=type.split(" "),t=0;t<types.length;t++)element.addEventListener(types[t],handler,!1)},onTouch:function(element,eventType,handler){var self=this
this.bindDom(element,Hammer.EVENT_TYPES[eventType],function(ev){var sourceEventType=ev.type.toLowerCase()
if(!sourceEventType.match(/mouse/)||!touch_triggered){(sourceEventType.match(/touch/)||sourceEventType.match(/pointerdown/)||sourceEventType.match(/mouse/)&&1===ev.which)&&(enable_detect=!0)
sourceEventType.match(/touch|pointer/)&&(touch_triggered=!0)
var count_touches=0
if(enable_detect){Hammer.HAS_POINTEREVENTS&&eventType!=Hammer.EVENT_END?count_touches=Hammer.PointerEvent.updatePointer(eventType,ev):sourceEventType.match(/touch/)?count_touches=ev.touches.length:touch_triggered||(count_touches=sourceEventType.match(/up/)?0:1)
count_touches>0&&eventType==Hammer.EVENT_END?eventType=Hammer.EVENT_MOVE:count_touches||(eventType=Hammer.EVENT_END)
count_touches||null===last_move_event?last_move_event=ev:ev=last_move_event
handler.call(Hammer.detection,self.collectEventData(element,eventType,ev))
Hammer.HAS_POINTEREVENTS&&eventType==Hammer.EVENT_END&&(count_touches=Hammer.PointerEvent.updatePointer(eventType,ev))}if(!count_touches){last_move_event=null
enable_detect=!1
touch_triggered=!1
Hammer.PointerEvent.reset()}}})},determineEventTypes:function(){var types
types=Hammer.HAS_POINTEREVENTS?Hammer.PointerEvent.getEvents():Hammer.NO_MOUSEEVENTS?["touchstart","touchmove","touchend touchcancel"]:["touchstart mousedown","touchmove mousemove","touchend touchcancel mouseup"]
Hammer.EVENT_TYPES[Hammer.EVENT_START]=types[0]
Hammer.EVENT_TYPES[Hammer.EVENT_MOVE]=types[1]
Hammer.EVENT_TYPES[Hammer.EVENT_END]=types[2]},getTouchList:function(ev){return Hammer.HAS_POINTEREVENTS?Hammer.PointerEvent.getTouchList():ev.touches?ev.touches:[{identifier:1,pageX:ev.pageX,pageY:ev.pageY,target:ev.target}]},collectEventData:function(element,eventType,ev){var touches=this.getTouchList(ev,eventType),pointerType=Hammer.POINTER_TOUCH;(ev.type.match(/mouse/)||Hammer.PointerEvent.matchType(Hammer.POINTER_MOUSE,ev))&&(pointerType=Hammer.POINTER_MOUSE)
return{center:Hammer.utils.getCenter(touches),timeStamp:(new Date).getTime(),target:ev.target,touches:touches,eventType:eventType,pointerType:pointerType,srcEvent:ev,preventDefault:function(){this.srcEvent.preventManipulation&&this.srcEvent.preventManipulation()
this.srcEvent.preventDefault&&this.srcEvent.preventDefault()},stopPropagation:function(){this.srcEvent.stopPropagation()},stopDetect:function(){return Hammer.detection.stopDetect()}}}}
Hammer.PointerEvent={pointers:{},getTouchList:function(){var self=this,touchlist=[]
Object.keys(self.pointers).sort().forEach(function(id){touchlist.push(self.pointers[id])})
return touchlist},updatePointer:function(type,pointerEvent){if(type==Hammer.EVENT_END)this.pointers={}
else{pointerEvent.identifier=pointerEvent.pointerId
this.pointers[pointerEvent.pointerId]=pointerEvent}return Object.keys(this.pointers).length},matchType:function(pointerType,ev){if(!ev.pointerType)return!1
var types={}
types[Hammer.POINTER_MOUSE]=ev.pointerType==ev.MSPOINTER_TYPE_MOUSE||ev.pointerType==Hammer.POINTER_MOUSE
types[Hammer.POINTER_TOUCH]=ev.pointerType==ev.MSPOINTER_TYPE_TOUCH||ev.pointerType==Hammer.POINTER_TOUCH
types[Hammer.POINTER_PEN]=ev.pointerType==ev.MSPOINTER_TYPE_PEN||ev.pointerType==Hammer.POINTER_PEN
return types[pointerType]},getEvents:function(){return["pointerdown MSPointerDown","pointermove MSPointerMove","pointerup pointercancel MSPointerUp MSPointerCancel"]},reset:function(){this.pointers={}}}
Hammer.utils={extend:function(dest,src,merge){for(var key in src)dest[key]!==undefined&&merge||(dest[key]=src[key])
return dest},hasParent:function(node,parent){for(;node;){if(node==parent)return!0
node=node.parentNode}return!1},getCenter:function(touches){for(var valuesX=[],valuesY=[],t=0,len=touches.length;len>t;t++){valuesX.push(touches[t].pageX)
valuesY.push(touches[t].pageY)}return{pageX:(Math.min.apply(Math,valuesX)+Math.max.apply(Math,valuesX))/2,pageY:(Math.min.apply(Math,valuesY)+Math.max.apply(Math,valuesY))/2}},getVelocity:function(delta_time,delta_x,delta_y){return{x:Math.abs(delta_x/delta_time)||0,y:Math.abs(delta_y/delta_time)||0}},getAngle:function(touch1,touch2){var y=touch2.pageY-touch1.pageY,x=touch2.pageX-touch1.pageX
return 180*Math.atan2(y,x)/Math.PI},getDirection:function(touch1,touch2){var x=Math.abs(touch1.pageX-touch2.pageX),y=Math.abs(touch1.pageY-touch2.pageY)
return x>=y?touch1.pageX-touch2.pageX>0?Hammer.DIRECTION_LEFT:Hammer.DIRECTION_RIGHT:touch1.pageY-touch2.pageY>0?Hammer.DIRECTION_UP:Hammer.DIRECTION_DOWN},getDistance:function(touch1,touch2){var x=touch2.pageX-touch1.pageX,y=touch2.pageY-touch1.pageY
return Math.sqrt(x*x+y*y)},getScale:function(start,end){return start.length>=2&&end.length>=2?this.getDistance(end[0],end[1])/this.getDistance(start[0],start[1]):1},getRotation:function(start,end){return start.length>=2&&end.length>=2?this.getAngle(end[1],end[0])-this.getAngle(start[1],start[0]):0},isVertical:function(direction){return direction==Hammer.DIRECTION_UP||direction==Hammer.DIRECTION_DOWN},stopDefaultBrowserBehavior:function(element,css_props){var prop,vendors=["webkit","khtml","moz","ms","o",""]
if(css_props&&element.style){for(var i=0;i<vendors.length;i++)for(var p in css_props)if(css_props.hasOwnProperty(p)){prop=p
vendors[i]&&(prop=vendors[i]+prop.substring(0,1).toUpperCase()+prop.substring(1))
element.style[prop]=css_props[p]}"none"==css_props.userSelect&&(element.onselectstart=function(){return!1})}}}
Hammer.detection={gestures:[],current:null,previous:null,stopped:!1,startDetect:function(inst,eventData){if(!this.current){this.stopped=!1
this.current={inst:inst,startEvent:Hammer.utils.extend({},eventData),lastEvent:!1,name:""}
this.detect(eventData)}},detect:function(eventData){if(this.current&&!this.stopped){eventData=this.extendEventData(eventData)
for(var inst_options=this.current.inst.options,g=0,len=this.gestures.length;len>g;g++){var gesture=this.gestures[g]
if(!this.stopped&&inst_options[gesture.name]!==!1&&gesture.handler.call(gesture,eventData,this.current.inst)===!1){this.stopDetect()
break}}this.current&&(this.current.lastEvent=eventData)
eventData.eventType==Hammer.EVENT_END&&!eventData.touches.length-1&&this.stopDetect()
return eventData}},stopDetect:function(){this.previous=Hammer.utils.extend({},this.current)
this.current=null
this.stopped=!0},extendEventData:function(ev){var startEv=this.current.startEvent
if(startEv&&(ev.touches.length!=startEv.touches.length||ev.touches===startEv.touches)){startEv.touches=[]
for(var i=0,len=ev.touches.length;len>i;i++)startEv.touches.push(Hammer.utils.extend({},ev.touches[i]))}var delta_time=ev.timeStamp-startEv.timeStamp,delta_x=ev.center.pageX-startEv.center.pageX,delta_y=ev.center.pageY-startEv.center.pageY,velocity=Hammer.utils.getVelocity(delta_time,delta_x,delta_y)
Hammer.utils.extend(ev,{deltaTime:delta_time,deltaX:delta_x,deltaY:delta_y,velocityX:velocity.x,velocityY:velocity.y,distance:Hammer.utils.getDistance(startEv.center,ev.center),angle:Hammer.utils.getAngle(startEv.center,ev.center),direction:Hammer.utils.getDirection(startEv.center,ev.center),scale:Hammer.utils.getScale(startEv.touches,ev.touches),rotation:Hammer.utils.getRotation(startEv.touches,ev.touches),startEvent:startEv})
return ev},register:function(gesture){var options=gesture.defaults||{}
options[gesture.name]===undefined&&(options[gesture.name]=!0)
Hammer.utils.extend(Hammer.defaults,options,!0)
gesture.index=gesture.index||1e3
this.gestures.push(gesture)
this.gestures.sort(function(a,b){return a.index<b.index?-1:a.index>b.index?1:0})
return this.gestures}}
Hammer.gestures=Hammer.gestures||{}
Hammer.gestures.Hold={name:"hold",index:10,defaults:{hold_timeout:500,hold_threshold:1},timer:null,handler:function(ev,inst){switch(ev.eventType){case Hammer.EVENT_START:clearTimeout(this.timer)
Hammer.detection.current.name=this.name
this.timer=setTimeout(function(){"hold"==Hammer.detection.current.name&&inst.trigger("hold",ev)},inst.options.hold_timeout)
break
case Hammer.EVENT_MOVE:ev.distance>inst.options.hold_threshold&&clearTimeout(this.timer)
break
case Hammer.EVENT_END:clearTimeout(this.timer)}}}
Hammer.gestures.Tap={name:"tap",index:100,defaults:{tap_max_touchtime:250,tap_max_distance:10,tap_always:!0,doubletap_distance:20,doubletap_interval:300},handler:function(ev,inst){if(ev.eventType==Hammer.EVENT_END){var prev=Hammer.detection.previous,did_doubletap=!1
if(ev.deltaTime>inst.options.tap_max_touchtime||ev.distance>inst.options.tap_max_distance)return
if(prev&&"tap"==prev.name&&ev.timeStamp-prev.lastEvent.timeStamp<inst.options.doubletap_interval&&ev.distance<inst.options.doubletap_distance){inst.trigger("doubletap",ev)
did_doubletap=!0}if(!did_doubletap||inst.options.tap_always){Hammer.detection.current.name="tap"
inst.trigger(Hammer.detection.current.name,ev)}}}}
Hammer.gestures.Swipe={name:"swipe",index:40,defaults:{swipe_max_touches:1,swipe_velocity:.7},handler:function(ev,inst){if(ev.eventType==Hammer.EVENT_END){if(inst.options.swipe_max_touches>0&&ev.touches.length>inst.options.swipe_max_touches)return
if(ev.velocityX>inst.options.swipe_velocity||ev.velocityY>inst.options.swipe_velocity){inst.trigger(this.name,ev)
inst.trigger(this.name+ev.direction,ev)}}}}
Hammer.gestures.Drag={name:"drag",index:50,defaults:{drag_min_distance:10,drag_max_touches:1,drag_block_horizontal:!1,drag_block_vertical:!1,drag_lock_to_axis:!1,drag_lock_min_distance:25},triggered:!1,handler:function(ev,inst){if(Hammer.detection.current.name!=this.name&&this.triggered){inst.trigger(this.name+"end",ev)
this.triggered=!1}else if(!(inst.options.drag_max_touches>0&&ev.touches.length>inst.options.drag_max_touches))switch(ev.eventType){case Hammer.EVENT_START:this.triggered=!1
break
case Hammer.EVENT_MOVE:if(ev.distance<inst.options.drag_min_distance&&Hammer.detection.current.name!=this.name)return
Hammer.detection.current.name=this.name;(Hammer.detection.current.lastEvent.drag_locked_to_axis||inst.options.drag_lock_to_axis&&inst.options.drag_lock_min_distance<=ev.distance)&&(ev.drag_locked_to_axis=!0)
var last_direction=Hammer.detection.current.lastEvent.direction
ev.drag_locked_to_axis&&last_direction!==ev.direction&&(ev.direction=Hammer.utils.isVertical(last_direction)?ev.deltaY<0?Hammer.DIRECTION_UP:Hammer.DIRECTION_DOWN:ev.deltaX<0?Hammer.DIRECTION_LEFT:Hammer.DIRECTION_RIGHT)
if(!this.triggered){inst.trigger(this.name+"start",ev)
this.triggered=!0}inst.trigger(this.name,ev)
inst.trigger(this.name+ev.direction,ev);(inst.options.drag_block_vertical&&Hammer.utils.isVertical(ev.direction)||inst.options.drag_block_horizontal&&!Hammer.utils.isVertical(ev.direction))&&ev.preventDefault()
break
case Hammer.EVENT_END:this.triggered&&inst.trigger(this.name+"end",ev)
this.triggered=!1}}}
Hammer.gestures.Transform={name:"transform",index:45,defaults:{transform_min_scale:.01,transform_min_rotation:1,transform_always_block:!1},triggered:!1,handler:function(ev,inst){if(Hammer.detection.current.name!=this.name&&this.triggered){inst.trigger(this.name+"end",ev)
this.triggered=!1}else if(!(ev.touches.length<2)){inst.options.transform_always_block&&ev.preventDefault()
switch(ev.eventType){case Hammer.EVENT_START:this.triggered=!1
break
case Hammer.EVENT_MOVE:var scale_threshold=Math.abs(1-ev.scale),rotation_threshold=Math.abs(ev.rotation)
if(scale_threshold<inst.options.transform_min_scale&&rotation_threshold<inst.options.transform_min_rotation)return
Hammer.detection.current.name=this.name
if(!this.triggered){inst.trigger(this.name+"start",ev)
this.triggered=!0}inst.trigger(this.name,ev)
rotation_threshold>inst.options.transform_min_rotation&&inst.trigger("rotate",ev)
if(scale_threshold>inst.options.transform_min_scale){inst.trigger("pinch",ev)
inst.trigger("pinch"+(ev.scale<1?"in":"out"),ev)}break
case Hammer.EVENT_END:this.triggered&&inst.trigger(this.name+"end",ev)
this.triggered=!1}}}}
Hammer.gestures.Touch={name:"touch",index:-1/0,defaults:{prevent_default:!1,prevent_mouseevents:!1},handler:function(ev,inst){if(inst.options.prevent_mouseevents&&ev.pointerType==Hammer.POINTER_MOUSE)ev.stopDetect()
else{inst.options.prevent_default&&ev.preventDefault()
ev.eventType==Hammer.EVENT_START&&inst.trigger(this.name,ev)}}}
Hammer.gestures.Release={name:"release",index:1/0,handler:function(ev,inst){ev.eventType==Hammer.EVENT_END&&inst.trigger(this.name,ev)}}
if("object"==typeof module&&"object"==typeof module.exports)module.exports=Hammer
else{window.Hammer=Hammer
"function"==typeof window.define&&window.define.amd&&window.define("hammer",[],function(){return Hammer})}}(this)

!function(){var Pistachio,__slice=Array.prototype.slice
Pistachio=function(){function Pistachio(view,template,options){var _ref
this.view=view
this.template=template
this.options=null!=options?options:{}
_ref=this.options,this.prefix=_ref.prefix,this.params=_ref.params
this.params||(this.params={})
this.symbols={}
this.dataPaths={}
this.subViewNames={}
this.prefix||(this.prefix="")
this.html=this.init()}var cleanSubviewNames,pistachios
Pistachio.createId=function(){var counter
counter=0
return function(prefix){return""+prefix+"el-"+counter++}}()
Pistachio.getAt=function(ref,path){var prop
path="function"==typeof path.split?path.split("."):path.slice()
for(;null!=ref&&(prop=path.shift());)ref=ref[prop]
return ref}
pistachios=/\{([\w|-]*)?(\#[\w|-]*)?((?:\.[\w|-]*)*)(\[(?:\b[\w|-]*\b)(?:\=[\"|\']?.*[\"|\']?)\])*\{([^{}]*)\}\s*\}/g
Pistachio.prototype.createId=Pistachio.createId
Pistachio.prototype.toString=function(){return this.template}
Pistachio.prototype.init=function(){var dataGetter,getEmbedderFn,init
dataGetter=function(prop){var data
data="function"==typeof this.getData?this.getData():void 0
return null!=data?("function"==typeof data.getAt?data.getAt(prop):void 0)||Pistachio.getAt(data,prop):void 0}
getEmbedderFn=function(pistachio,view,id,symbol){return function(childView){view.embedChild(id,childView,symbol.isCustom)
if(!symbol.isCustom){symbol.id=childView.id
symbol.tagName="function"==typeof childView.getTagName?childView.getTagName():void 0
delete pistachio.symbols[id]
return pistachio.symbols[childView.id]=symbol}}}
return init=function(){var createId,prefix,view,_this=this
prefix=this.prefix,view=this.view,createId=this.createId
return this.template.replace(pistachios,function(_,tagName,id,classes,attrs,expression){var classAttr,classNames,code,dataPaths,dataPathsAttr,embedChild,formalParams,isCustom,js,paramKeys,paramValues,render,subViewNames,subViewNamesAttr,symbol
id=null!=id?id.split("#")[1]:void 0
classNames=(null!=classes?classes.split(".").slice(1):void 0)||[]
attrs=(null!=attrs?attrs.replace(/\]\[/g," ").replace(/\[|\]/g,""):void 0)||""
isCustom=!!(tagName||id||classes.length||attrs.length)
tagName||(tagName="span")
dataPaths=[]
subViewNames=[]
expression=expression.replace(/#\(([^)]*)\)/g,function(_,dataPath){dataPaths.push(dataPath)
return"data('"+dataPath+"')"}).replace(/^(?:> ?|embedChild )(.+)/,function(_,subViewName){subViewNames.push(subViewName.replace(/\@\.?|this\./,""))
return"embedChild("+subViewName+")"})
_this.registerDataPaths(dataPaths)
_this.registerSubViewNames(subViewNames)
js="return "+expression
if("debug"===tagName){console.debug(js)
tagName="span"}paramKeys=Object.keys(_this.params)
paramValues=paramKeys.map(function(key){return _this.params[key]})
formalParams=["data","embedChild"].concat(__slice.call(paramKeys))
try{code=Function.apply(null,__slice.call(formalParams).concat([js]))}catch(e){throw new Error("Pistachio encountered an error: "+e+"\nSource: "+js)}id||(id=createId(prefix))
render=function(){return code.apply(view,[dataGetter.bind(view),embedChild].concat(__slice.call(paramValues)))}
symbol=_this.symbols[id]={tagName:tagName,id:id,isCustom:isCustom,js:js,code:code,render:render}
embedChild=getEmbedderFn(_this,view,id,symbol)
dataPathsAttr=dataPaths.length?" data-"+prefix+"paths='"+dataPaths.join(" ")+"'":""
subViewNamesAttr=subViewNames.length?(classNames.push(""+prefix+"subview")," data-"+prefix+"subviews='"+cleanSubviewNames(subViewNames.join(" "))+"'"):""
classAttr=classNames.length?" class='"+classNames.join(" ")+"'":""
return"<"+tagName+classAttr+dataPathsAttr+subViewNamesAttr+" "+attrs+" id='"+id+"'></"+tagName+">"})}}()
Pistachio.prototype.addSymbol=function(childView){return this.symbols[childView.id]={id:childView.id,tagName:"function"==typeof childView.getTagName?childView.getTagName():void 0}}
Pistachio.prototype.appendChild=function(childView){return this.addSymbol(childView)}
Pistachio.prototype.prependChild=function(childView){return this.addSymbol(childView)}
Pistachio.prototype.registerDataPaths=function(paths){var path,_i,_len,_results
_results=[]
for(_i=0,_len=paths.length;_len>_i;_i++){path=paths[_i]
_results.push(this.dataPaths[path]=!0)}return _results}
Pistachio.prototype.registerSubViewNames=function(subViewNames){var subViewName,_i,_len,_results
_results=[]
for(_i=0,_len=subViewNames.length;_len>_i;_i++){subViewName=subViewNames[_i]
_results.push(this.subViewNames[subViewName]=!0)}return _results}
Pistachio.prototype.getDataPaths=function(){return Object.keys(this.dataPaths)}
Pistachio.prototype.getSubViewNames=function(){return Object.keys(this.subViewNames)}
cleanSubviewNames=function(name){return name.replace(/(this\["|\"])/g,"")}
Pistachio.prototype.refreshChildren=function(childType,items,forEach){var $els,item,symbols
symbols=this.symbols
$els=this.view.$(function(){var _i,_len,_results
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
_results.push("[data-"+childType+'s~="'+cleanSubviewNames(item)+'"]')}return _results}().join(","))
return $els.each(function(){var out,_ref
out=null!=(_ref=symbols[this.id])?_ref.render():void 0
return null!=out?null!=forEach?forEach.call(this,out):void 0:void 0})}
Pistachio.prototype.embedSubViews=function(subviews){null==subviews&&(subviews=this.getSubViewNames())
return this.refreshChildren("subview",subviews)}
Pistachio.prototype.update=function(paths){null==paths&&(paths=this.getDataPaths())
return this.refreshChildren("path",paths,function(html){return this.innerHTML=html})}
return Pistachio}()
"undefined"!=typeof module&&null!==module&&(module.exports=Pistachio)
"undefined"!=typeof window&&null!==window&&(window.Pistachio=Pistachio)}.call(this)

var createCounter,__utils,__slice=[].slice
__utils={idCounter:0,extend:function(){var key,source,sources,target,val,_i,_len
target=arguments[0],sources=2<=arguments.length?__slice.call(arguments,1):[]
for(_i=0,_len=sources.length;_len>_i;_i++){source=sources[_i]
for(key in source){val=source[key]
target[key]=val}}return target},dict:Object.create.bind(null,null,Object.create(null)),formatPlural:function(count,noun,showCount){null==showCount&&(showCount=!0)
return""+(showCount?""+(count||0)+" ":"")+(1===count?noun:Inflector.pluralize(noun))},getSelection:function(){return window.getSelection()},getSelectionRange:function(){var selection
selection=__utils.getSelection()
return"None"!==selection.type?selection.getRangeAt(0):void 0},getCursorNode:function(){return __utils.getSelectionRange().commonAncestorContainer},addRange:function(range){var selection
selection=window.getSelection()
selection.removeAllRanges()
return selection.addRange(range)},selectText:function(element,start,end){var doc,range,selection
null==end&&(end=start)
doc=document
if(doc.body.createTextRange){range=document.body.createTextRange()
range.moveToElementText(element)
return range.select()}if(window.getSelection){selection=window.getSelection()
range=document.createRange()
range.selectNodeContents(element)
null!=start&&range.setStart(element,start)
null!=end&&range.setEnd(element,end)
selection.removeAllRanges()
return selection.addRange(range)}},selectEnd:function(element,range){range||(range=document.createRange())
element||(element=__utils.getSelection().focusNode)
if(element){range.setStartAfter(element)
range.collapse(!1)
return __utils.addRange(range)}},replaceRange:function(node,replacement,start,end,appendTrailingSpace){var range,trailingSpace
null==end&&(end=start)
null==appendTrailingSpace&&(appendTrailingSpace=!0)
trailingSpace=document.createTextNode(" ")
range=new Range
if(null!=start){range.setStart(node,start)
range.setEnd(node,end)}else range.selectNode(node)
range.deleteContents()
range.insertNode(replacement)
__utils.selectEnd(replacement,range)
if(appendTrailingSpace){range.insertNode(trailingSpace)
return __utils.selectEnd(trailingSpace,range)}},getCallerChain:function(args,depth){var caller,chain
caller=args.callee.caller
chain=[caller]
for(;depth--&&(caller=null!=caller?caller.caller:void 0);)chain.push(caller)
return chain},createCounter:createCounter=function(i){null==i&&(i=0)
return function(){return i++}},getUniqueId:function(inc){return function(){return"kd-"+inc()}}(createCounter()),getRandomNumber:function(range,min){var res
null==range&&(range=1e6)
null==min&&(min=0)
res=Math.floor(Math.random()*range+1)
return res>min?res:res+min},uniqueId:function(prefix){var id
id=__utils.idCounter++
return null!=prefix?""+prefix+id:id},getRandomRGB:function(){var getRandomNumber
getRandomNumber=this.getRandomNumber
return"rgb("+getRandomNumber(255)+","+getRandomNumber(255)+","+getRandomNumber(255)+")"},getRandomHex:function(){var hex
hex=(10066329*Math.random()<<0).toString(16)
for(;hex.length<6;)hex+="0"
return"#"+hex},curry:function(obligatory,optional){return obligatory+(optional?" "+optional:"")},parseQuery:function(){var decode,params,parseQuery,plusses
params=/([^&=]+)=?([^&]*)/g
plusses=/\+/g
decode=function(str){return decodeURIComponent(str.replace(plusses," "))}
return parseQuery=function(queryString){var m,result
null==queryString&&(queryString=location.search.substring(1))
result={}
for(;m=params.exec(queryString);)result[decode(m[1])]=decode(m[2])
return result}}(),stringifyQuery:function(){var encode,spaces,stringifyQuery
spaces=/\s/g
encode=function(str){return encodeURIComponent(str.replace(spaces,"+"))}
return stringifyQuery=function(obj){return Object.keys(obj).map(function(key){return""+encode(key)+"="+encode(obj[key])}).join("&").trim()}}(),capAndRemovePeriods:function(path){var arg,newPath
newPath=function(){var _i,_len,_ref,_results
_ref=path.split(".")
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){arg=_ref[_i]
_results.push(arg.capitalize())}return _results}()
return newPath.join("")},slugify:function(title){var url
null==title&&(title="")
return url=String(title).toLowerCase().replace(/^\s+|\s+$/g,"").replace(/[_|\s]+/g,"-").replace(/[^a-z0-9-]+/g,"").replace(/[-]+/g,"-").replace(/^-+|-+$/g,"")},stripTags:function(value){return value.replace(/<(?:.|\n)*?>/gm,"")},decimalToAnother:function(n,radix){var a,b,hex,i,s,t,_i,_j
hex=[]
for(i=_i=0;10>=_i;i=++_i)hex[i+1]=i
s=""
a=n
for(;a>=radix;){b=a%radix
a=Math.floor(a/radix)
s+=hex[b+1]}s+=hex[a+1]
n=s.length
t=""
for(i=_j=0;n>=0?n>_j:_j>n;i=n>=0?++_j:--_j)t+=s.substring(n-i-1,n-i)
s=t
return s},applyMarkdown:function(text){return text?marked(text,{gfm:!0,pedantic:!1,sanitize:!0,highlight:function(text,lang){return null!=hljs.LANGUAGES[lang]?hljs.highlight(lang,text).value:text}}):null},createExternalLink:function(href){var tag
tag=document.createElement("a")
tag.href=href.indexOf("http")>-1?href:"http://"+href
tag.target="_blank"
document.body.appendChild(tag)
tag.click()
return document.body.removeChild(tag)},wait:function(duration,fn){if("function"==typeof duration){fn=duration
duration=0}return setTimeout(fn,duration)},killWait:function(id){id&&clearTimeout(id)
return null},repeat:function(duration,fn){if("function"==typeof duration){fn=duration
duration=500}return setInterval(fn,duration)},killRepeat:function(id){return clearInterval(id)},defer:function(queue){if(("undefined"!=typeof window&&null!==window?window.postMessage:void 0)&&window.addEventListener){window.addEventListener("message",function(ev){if(ev.source===window&&"kd-tick"===ev.data){ev.stopPropagation()
if(queue.length>0)return queue.shift()()}},!0)
return function(fn){queue.push(fn)
return window.postMessage("kd-tick","*")}}return function(fn){return setTimeout(fn,1)}}([]),getCancellableCallback:function(callback){var cancelled,kallback
cancelled=!1
kallback=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
return cancelled?void 0:callback.apply(null,rest)}
kallback.cancel=function(){return cancelled=!0}
return kallback},getTimedOutCallback:function(callback,failcallback,timeout){var cancelled,fallback,fallbackTimer,kallback
null==timeout&&(timeout=5e3)
cancelled=!1
kallback=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
clearTimeout(fallbackTimer)
return cancelled?void 0:callback.apply(null,rest)}
fallback=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
cancelled||failcallback.apply(null,rest)
return cancelled=!0}
fallbackTimer=setTimeout(fallback,timeout)
return kallback},getTimedOutCallbackOne:function(options){var fallback,fallbackTimer,kallback,onResult,onSuccess,onTimeout,timedOut,timeout,timerName,_this=this
null==options&&(options={})
timerName=options.name||"undefined"
timeout=options.timeout||1e4
onSuccess=options.onSuccess||function(){}
onTimeout=options.onTimeout||function(){}
onResult=options.onResult||function(){}
timedOut=!1
kallback=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
clearTimeout(fallbackTimer)
_this.updateLogTimer(timerName,fallbackTimer,Date.now())
return timedOut?onResult.apply(null,rest):onSuccess.apply(null,rest)}
fallback=function(){var rest
rest=1<=arguments.length?__slice.call(arguments,0):[]
timedOut=!0
_this.updateLogTimer(timerName,fallbackTimer)
return onTimeout.apply(null,rest)}
fallbackTimer=setTimeout(fallback,timeout)
this.logTimer(timerName,fallbackTimer,Date.now())
kallback.cancel=function(){return clearTimeout(fallbackTimer)}
return kallback},logTimer:function(timerName,timerNumber,startTime){var _base
log("logTimer name:"+timerName);(_base=this.timers)[timerName]||(_base[timerName]={})
return this.timers[timerName][timerNumber]={start:startTime,status:"started"}},updateLogTimer:function(timerName,timerNumber,endTime){var elapsed,startTime,status,timer
timer=this.timers[timerName][timerNumber]
status=endTime?"ended":"failed"
startTime=timer.start
elapsed=endTime-startTime
timer={start:startTime,end:endTime,status:status,elapsed:elapsed}
this.timers[timerName][timerNumber]=timer
return log("updateLogTimer name:"+timerName+", status:"+status+" elapsed:"+elapsed)},timers:{},stopDOMEvent:function(event){if(!event)return!1
event.preventDefault()
event.stopPropagation()
return!1},utf8Encode:function(string){var c,n,utftext
string=string.replace(/\r\n/g,"\n")
utftext=""
n=0
for(;n<string.length;){c=string.charCodeAt(n)
if(128>c)utftext+=String.fromCharCode(c)
else if(c>127&&2048>c){utftext+=String.fromCharCode(192|c>>6)
utftext+=String.fromCharCode(128|63&c)}else{utftext+=String.fromCharCode(224|c>>12)
utftext+=String.fromCharCode(128|63&c>>6)
utftext+=String.fromCharCode(128|63&c)}n++}return utftext},utf8Decode:function(utftext){var c,c1,c2,c3,i,string
string=""
i=0
c=c1=c2=0
for(;i<utftext.length;){c=utftext.charCodeAt(i)
if(128>c){string+=String.fromCharCode(c)
i++}else if(c>191&&224>c){c2=utftext.charCodeAt(i+1)
string+=String.fromCharCode((31&c)<<6|63&c2)
i+=2}else{c2=utftext.charCodeAt(i+1)
c3=utftext.charCodeAt(i+2)
string+=String.fromCharCode((15&c)<<12|(63&c2)<<6|63&c3)
i+=3}}return string},runXpercent:function(percent){var chance
chance=Math.floor(100*Math.random())
return percent>=chance},shortenUrl:function(url,callback){var request
request=$.ajax("https://www.googleapis.com/urlshortener/v1/url",{type:"POST",contentType:"application/json",data:JSON.stringify({longUrl:url}),timeout:4e3,dataType:"json"})
request.done(function(data){return callback((null!=data?data.id:void 0)||url,data)})
return request.error(function(_arg){var responseText,status,statusText
status=_arg.status,statusText=_arg.statusText,responseText=_arg.responseText
error("URL shorten error, returning self as fallback.",status,statusText,responseText)
return callback(url)})},formatBytesToHumanReadable:function(bytes){var minus,thresh,unitIndex,units
minus=""
if(0>bytes){minus="-"
bytes*=-1}thresh=1024
units=["kB","MB","GB","TB","PB","EB","ZB","YB"]
unitIndex=-1
if(thresh>bytes)return""+bytes+" B"
for(;;){bytes/=thresh;++unitIndex
if(!(bytes>=thresh))break}return""+minus+bytes.toFixed(2)+" "+units[unitIndex]},splitTrim:function(str,delim,filterEmpty){var arr,_ref
null==delim&&(delim=",")
null==filterEmpty&&(filterEmpty=!0)
arr=null!=(_ref=null!=str?str.split(delim).map(function(part){return part.trim()}):void 0)?_ref:[]
filterEmpty&&(arr=arr.filter(Boolean))
return arr},objectToArray:function(options){var key,option,_results
_results=[]
for(key in options){option=options[key]
null==option.title&&(option.title=key)
option.key=key
_results.push(option)}return _results},partition:function(list,fn){var item,result,_i,_len
result=[[],[]]
for(_i=0,_len=list.length;_len>_i;_i++){item=list[_i]
result[+!fn(item)].push(item)}return result}}
__utils.throttle=function(func,wait){var context,args,timeout,throttling,more,whenDone=__utils.debounce(function(){more=throttling=!1},wait)
return function(){context=this
args=arguments
var later=function(){timeout=null
more&&func.apply(context,args)
whenDone()}
timeout||(timeout=setTimeout(later,wait))
throttling?more=!0:func.apply(context,args)
whenDone()
throttling=!0}}
__utils.debounce=function(func,wait){var timeout
return function(){var context=this,args=arguments,later=function(){timeout=null
func.apply(context,args)}
clearTimeout(timeout)
timeout=setTimeout(later,wait)}}

var KD,e,error,log,noop,prettyPrint,warn,_base,_ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,__slice=[].slice,__hasProp={}.hasOwnProperty,__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1};(_base=Function.prototype).bind||(_base.bind=function(context){var args,_this=this
if(1<arguments.length){args=[].slice.call(arguments,1)
return function(){return _this.apply(context,arguments.length?args.concat([].slice.call(arguments)):args)}}return function(){return arguments.length?_this.apply(context,arguments):_this.call(context)}})
Function.prototype.swiss=function(){var name,names,parent,_i,_len
parent=arguments[0],names=2<=arguments.length?__slice.call(arguments,1):[]
for(_i=0,_len=names.length;_len>_i;_i++){name=names[_i]
this.prototype[name]=parent.prototype[name]}return this}
null==window.URL&&(window.URL=null!=(_ref=window.webkitURL)?_ref:null)
null==window.BlobBuilder&&(window.BlobBuilder=null!=(_ref1=null!=(_ref2=window.WebKitBlobBuilder)?_ref2:window.MozBlobBuilder)?_ref1:null)
null==window.requestFileSystem&&(window.requestFileSystem=null!=(_ref3=window.webkitRequestFileSystem)?_ref3:null)
null==window.requestAnimationFrame&&(window.requestAnimationFrame=null!=(_ref4=null!=(_ref5=window.webkitRequestAnimationFrame)?_ref5:window.mozRequestAnimationFrame)?_ref4:null)
String.prototype.capitalize=function(){return this.charAt(0).toUpperCase()+this.slice(1)}
String.prototype.decapitalize=function(){return this.charAt(0).toLowerCase()+this.slice(1)}
String.prototype.trim=function(){return this.replace(/^\s+|\s+$/g,"")}
!function(arrayProto,_arg){var defineProperty
defineProperty=_arg.defineProperty
"last"in arrayProto||defineProperty(arrayProto,"last",{get:function(){return this[this.length-1]}})
return"first"in arrayProto||defineProperty(arrayProto,"first",{get:function(){return this[0]}})}(Array.prototype,Object)
KD=this.KD||{}
noop=function(){}
KD.log=log=noop
KD.warn=warn=noop
KD.error=error=noop
if(null==window.event)try{Object.defineProperty(window,"event",{get:function(){return KD.warn('Global "event" property is accessed. Did you forget a parameter in a DOM event handler?')}})}catch(_error){e=_error
log("we fail silently!",e)}try{Object.defineProperty(window,"appManager",{get:function(){console.trace()
return KD.warn('window.appManager is deprecated, use KD.getSingleton("appManager") instead!')}})}catch(_error){e=_error
log("we fail silently!",e)}this.KD=$.extend(KD,function(){var create
create=function(constructorName,options,data){var konstructor,_ref6
konstructor=null!=(_ref6=this.classes[constructorName])?_ref6:this.classes["KD"+constructorName]
return null!=konstructor?new konstructor(options,data):void 0}
return{create:create,"new":create,debugStates:{},instances:{},introInstances:{},singletons:{},subscriptions:[],classes:{},utils:__utils,appClasses:{},appScripts:{},appLabels:{},lastFuncCall:null,navItems:[],instancesToBeTested:{},socketConnected:function(){return this.backendIsConnected=!0},setApplicationPartials:function(appPartials){this.appPartials=appPartials},registerInstance:function(anInstance){var introId
this.instances[anInstance.id]&&warn("Instance being overwritten!!",anInstance)
this.instances[anInstance.id]=anInstance
introId=anInstance.getOptions().introId
return introId?this.introInstances[introId]=anInstance:void 0},unregisterInstance:function(anInstanceId){return delete this.instances[anInstanceId]},deleteInstance:function(anInstanceId){return this.unregisterInstance(anInstanceId)},extend:function(obj){var key,val,_results
_results=[]
for(key in obj){val=obj[key]
if(this[key])throw new Error(""+key+" is already registered")
_results.push(this[key]=val)}return _results},registerSingleton:function(singletonName,object,override){var existingSingleton
null==override&&(override=!1)
if(null!=(existingSingleton=KD.singletons[singletonName])){if(override){warn('singleton overriden! KD.singletons["'+singletonName+'"]')
"function"==typeof existingSingleton.destroy&&existingSingleton.destroy()
KD.singletons[singletonName]=object}else{error('KD.singletons["'+singletonName+'"] singleton exists! if you want to override set override param to true]')
KD.singletons[singletonName]}return KDObject.emit("singleton."+singletonName+".registered")}return KD.singletons[singletonName]=object},getSingleton:function(singletonName){if(null!=KD.singletons[singletonName])return KD.singletons[singletonName]
warn('"'+singletonName+"\" singleton doesn't exist!")
return null},registerAppClass:function(fn,options){var registerRoute,route,_i,_len,_ref6,_ref7,_this=this
null==options&&(options={})
if(!options.name)return error("AppClass is missing a name!")
if(KD.appClasses[options.name])return warn("AppClass "+options.name+" is already registered or the name is already taken!")
null==options.multiple&&(options.multiple=!1)
null==options.background&&(options.background=!1)
null==options.hiddenHandle&&(options.hiddenHandle=!1)
options.openWith||(options.openWith="lastActive")
options.behavior||(options.behavior="")
null==options.thirdParty&&(options.thirdParty=!1)
options.menu||(options.menu=null)
options.navItem||(options.navItem={})
options.labels||(options.labels=[])
null==options.version&&(options.version="1.0")
options.route||(options.route={})
registerRoute=function(route){var cb,handler,slug
slug="string"==typeof route?route:route.slug
route={slug:slug||"/",handler:route.handler||null}
if("/"!==route.slug){slug=route.slug,handler=route.handler
cb=function(router){handler||(handler=function(_arg){var name,query,_ref6
_ref6=_arg.params,name=_ref6.name,query=_arg.query
return router.openSection(options.name,name,query)})
return router.addRoute(slug,handler)}
return KD.singletons.router?_this.utils.defer(function(){return cb(KD.getSingleton("router"))}):KodingRouter.on("RouterReady",cb)}}
Array.isArray(options.route)||(options.route=[options.route])
_ref6=options.route
for(_i=0,_len=_ref6.length;_len>_i;_i++){route=_ref6[_i]
registerRoute(route)}(null!=(_ref7=options.navItem)?_ref7.order:void 0)&&this.registerNavItem(options.navItem)
Object.defineProperty(KD.appClasses,options.name,{configurable:!0,enumerable:!0,writable:!1,value:{fn:fn,options:options}})
return options.labels.length>0?this.setAppLabels(options.name,options.labels):void 0},setAppLabels:function(name,labels){return this.appLabels[name]=labels},getAppName:function(name){var app,labels,_ref6
_ref6=this.appLabels
for(app in _ref6)if(__hasProp.call(_ref6,app)){labels=_ref6[app]
if(__indexOf.call(labels,name)>=0||name===app)return app}return name},registerNavItem:function(itemData){return this.navItems.push(itemData)},getNavItems:function(){return this.navItems.sort(function(a,b){return a.order-b.order})},setNavItems:function(navItems){return this.navItems=navItems.sort(function(a,b){return a.order-b.order})},unregisterAppClass:function(name){return delete KD.appClasses[this.getAppName(name)]},getAppClass:function(name){var _ref6
return(null!=(_ref6=KD.appClasses[this.getAppName(name)])?_ref6.fn:void 0)||null},getAppOptions:function(name){var _ref6
return(null!=(_ref6=KD.appClasses[this.getAppName(name)])?_ref6.options:void 0)||null},getAppScript:function(name){return this.appScripts[this.getAppName(name)]||null},registerAppScript:function(name,script){return this.appScripts[this.getAppName(name)]=script},unregisterAppScript:function(name){return delete this.appScripts[this.getAppName(name)]},resetAppScripts:function(){return this.appScripts={}},getAllKDInstances:function(){return KD.instances},getKDViewInstanceFromDomElement:function(el){return this.instances[el.getAttribute("data-id")]},enableLogs:function(){var enableLogs,method,oldConsole,_i,_len,_ref6
oldConsole=window.console
window.console={}
_ref6=["log","warn","error","trace","time","timeEnd"]
for(_i=0,_len=_ref6.length;_len>_i;_i++){method=_ref6[_i]
console[method]=noop}return enableLogs=function(){var time,timeEnd
window.console=oldConsole
KD.log=log=("undefined"!=typeof console&&null!==console?console.log:void 0)?console.log.bind(console):noop
KD.warn=warn=("undefined"!=typeof console&&null!==console?console.warn:void 0)?console.warn.bind(console):noop
KD.error=error=("undefined"!=typeof console&&null!==console?console.error:void 0)?console.error.bind(console):noop
KD.time=time=("undefined"!=typeof console&&null!==console?console.time:void 0)?console.time.bind(console):noop
KD.timeEnd=timeEnd=("undefined"!=typeof console&&null!==console?console.timeEnd:void 0)?console.timeEnd.bind(console):noop
KD.logsEnabled=!0
return"Logs are enabled now."}}(),exportKDFramework:function(){var item,_ref6
_ref6=KD.classes
for(item in _ref6)__hasProp.call(_ref6,item)&&(window[item]=KD.classes[item])
KD.exportKDFramework=function(){return"Already exported."}
return"KDFramework loaded successfully."},registerInstanceForTesting:function(instance){var key,_this=this
key=instance.getOption("testPath")
this.instancesToBeTested[key]=instance
return instance.on("KDObjectWillBeDestroyed",function(){return delete _this.instancesToBeTested[key]})},getInstanceForTesting:function(key){return this.instancesToBeTested[key]}}}());(null!=(_ref6=KD.config)?_ref6.suppressLogs:void 0)||KD.enableLogs()
prettyPrint=noop

var KD
KD.dom=KD.dom||{}
!function(global){var globalDocument=global.document,isHostObjectProperty=function(object,property){var objectProperty=object[property]
return"object"==typeof objectProperty&&null!==objectProperty},isHostMethod=function(object,method){var objectMethod=object[method],type=typeof objectMethod
return"function"==type||"object"==type&&null!==objectMethod||"unknown"==type},areFeatures=function(){for(var i=arguments.length;i--;)if(!KD.dom[arguments[i]])return!1
return!0},html=isHostObjectProperty(globalDocument,"documentElement")&&globalDocument.documentElement,canCall=!!Function.prototype.call
!(!html||!isHostObjectProperty(html,"style"))
var toArray
toArray=function(a){for(var result=[],i=0,l=a.length;l>i;i++)result[i]=a[i]
return result}
var detachListener
html&&isHostMethod(html,"removeEventListener")&&(detachListener=function(el,eventType,fn){el.removeEventListener(eventType,fn,!1)})
var getEventTarget
html&&isHostMethod(html,"addEventListener")&&(getEventTarget=function(e){var target=e.target
1!=target.nodeType&&(target=target.parentNode)
return target})
var attachListener
html&&isHostMethod(html,"addEventListener")&&(attachListener=function(el,eventType,fn){var listener=function(e){fn.call(el,e)}
el.addEventListener(eventType,listener,!1)
return listener})
var query
globalDocument&&isHostMethod(globalDocument,"querySelectorAll")&&toArray&&(query=function(selector,doc){return toArray((doc||document).querySelectorAll(selector))})
var queryOne
globalDocument&&isHostMethod(globalDocument,"querySelector")&&(queryOne=function(selector,doc){return(doc||document).querySelector(selector)})
var isNodeInNodeList
isNodeInNodeList=function(node,nodeList){for(var isInNodeList=!1,i=0,l=nodeList.length;l>i;i++)if(nodeList[i]===node){isInNodeList=!0
break}return isInNodeList}
var bind
canCall&&Function.prototype.bind&&(bind=function(fn){return fn.bind.apply(fn,Array.prototype.slice.call(arguments,1))})
var undelegateListener
detachListener&&(undelegateListener=function(el,eventType,delegateListener){return detachListener(el,eventType,delegateListener)})
var delegateListener
attachListener&&getEventTarget&&canCall&&(delegateListener=function(el,eventType,fn,fnDelegate){var listener=function(e){var currentTarget=fnDelegate(el,getEventTarget(e))
currentTarget&&fn.call(currentTarget,e,currentTarget,el)}
return attachListener(el,eventType,listener)})
var getElementTagName
getElementTagName=function(el){var tagName=(el.tagName||el.nodeName).toLowerCase()
return tagName.indexOf("html:")>-1?tagName.substring(5):tagName}
var getElementParentElement
html&&isHostObjectProperty(html,"parentNode")&&(getElementParentElement=function(el){var parentNode=el.parentNode,parentElement=null
parentNode&&(parentNode.tagName||1==parentNode.nodeType)&&(parentElement=parentNode)
return parentElement})
var isInQuery
isNodeInNodeList&&query&&(isInQuery=function(el,selector){return isNodeInNodeList(el,query(selector))})
var isDescendant
html&&"undefined"!=typeof html.parentNode&&(isDescendant=function(el,elDescendant){for(var parent=elDescendant.parentNode;parent&&parent!=el;)parent=parent.parentNode
return parent==el})
var delegateBoundListener
attachListener&&bind&&getEventTarget&&canCall&&(delegateBoundListener=function(el,eventType,fn,fnDelegate,thisObject){var listener=bind(function(e){var currentTarget=fnDelegate(el,getEventTarget(e))
currentTarget&&fn.call(thisObject,e,currentTarget)},thisObject)
return attachListener(el,eventType,listener)})
var hasClass
html&&isHostObjectProperty(html,"classList")&&isHostMethod(html.classList,"contains")&&(hasClass=function(el,className){return el.classList.contains(className)})
var attachWindowListener
window&&isHostMethod(window,"addEventListener")&&(attachWindowListener=function(eventType,fn){var listener=function(e){fn.call(window,e)}
window.addEventListener(eventType,listener,!1)
return listener})
var getViewportScrollPosition
"number"==typeof window.pageXOffset&&"number"==typeof window.pageYOffset&&(getViewportScrollPosition=function(){return[window.pageXOffset,window.pageYOffset]})
var getPositionRelativeToViewport
html&&isHostMethod(html,"getBoundingClientRect")&&(getPositionRelativeToViewport=function(el){var rect=el.getBoundingClientRect()
return[rect.left,rect.top]})
var getElement
isHostMethod(document,"getElementById")&&(getElement=function(id,doc){return(doc||document).getElementById(id)})
var undelegateQueryListener
undelegateListener&&(undelegateQueryListener=function(el,eventType,listener){return undelegateListener(el,eventType,listener)})
var setViewportScrollPosition
isHostMethod(global,"scrollTo")&&(setViewportScrollPosition=function(x,y){window.scrollTo(x,y)})
var setInputValue
setInputValue=function(elInput,value){elInput.value=value}
var getViewportSize
"number"==typeof global.innerWidth&&(getViewportSize=function(win){win||(win=window)
return[win.innerWidth,win.innerHeight]})
var getEventTargetRelated
html&&isHostMethod(html,"addEventListener")&&(getEventTargetRelated=function(e){var target=e.relatedTarget
1!=target.nodeType&&(target=target.parentNode)
return target})
var detachWindowListener
window&&isHostMethod(window,"removeEventListener")&&(detachWindowListener=function(eventType,fn){return window.removeEventListener(eventType,fn)})
var detachBoundListener
detachListener&&(detachBoundListener=function(el,eventType,boundListener){return detachListener(el,eventType,boundListener)})
var delegateTagNameListener
delegateListener&&getElementTagName&&(delegateTagNameListener=function(el,eventType,tagName,fn){var fnDelegate=function(el,target){var sourceNode,descendant
if(getElementTagName(target)===tagName)sourceNode=target
else{descendant=getElementParentElement(target)
for(;null!==descendant&&descendant!==el;){if(getElementTagName(descendant)===tagName){sourceNode=descendant
break}descendant=getElementParentElement(descendant)}}return sourceNode}
return delegateListener(el,eventType,fn,fnDelegate)})
var delegateQueryListener
isNodeInNodeList&&delegateListener&&query&&isDescendant&&(delegateQueryListener=function(el,eventType,selector,fn){function fnDelegate(target){var l,el,elements=query(selector),i=0
if(isNodeInNodeList(target,elements))return target
for(l=elements.length;l>i;i++){el=elements[i]
if(isDescendant(el,target))return el}}return delegateListener(el,eventType,fn,fnDelegate)})
var delegateBoundQueryListener
delegateBoundListener&&query&&isDescendant&&(delegateBoundQueryListener=function(el,eventType,selector,fn,thisObject){var fnDelegate=function(el,target){if(isInQuery(target,selector))return target
for(var elements=jessie.query(selector),i=0;i<elements.length;i++)if(isDescendant(elements[i],target))return elements[i]}
return delegateBoundListener(el,eventType,fn,fnDelegate,thisObject)})
var delegateBoundClassNameListener
delegateBoundListener&&hasClass&&getElementParentElement&&(delegateBoundClassNameListener=function(el,eventType,className,fn,thisObject){var fnDelegate=function(el,target){var currentTarget=target
el===currentTarget&&(currentTarget=null)
for(;currentTarget&&currentTarget!==el&&!hasClass(currentTarget,className);){currentTarget=getElementParentElement(currentTarget)
el===currentTarget&&(currentTarget=null)}return currentTarget}
return delegateBoundListener(el,eventType,fn,fnDelegate,thisObject)})
var cancelPropagation
html&&isHostMethod(html,"addEventListener")&&(cancelPropagation=function(e){e.stopPropagation()})
var cancelDefault
html&&isHostMethod(html,"addEventListener")&&(cancelDefault=function(e){e.preventDefault()})
var attachDocumentListener
globalDocument&&isHostMethod(globalDocument,"addEventListener")&&attachListener&&(attachDocumentListener=function(eventType,fn){return attachListener(document,eventType,fn)})
var attachBoundWindowListener
attachWindowListener&&bind&&(attachBoundWindowListener=function(eventType,fn,thisObject){var listener=bind(fn,thisObject)
return attachWindowListener(eventType,listener)})
var attachBoundListener
bind&&attachListener&&(attachBoundListener=function(el,eventType,fn,thisObject){var listener=bind(fn,thisObject)
thisObject=null
return attachListener(el,eventType,listener)})
var setText
html&&"string"==typeof html.textContent?setText=function(el,text){el.textContent=text}:html&&"string"==typeof html.innerText&&(setText=function(el,text){el.innerText=text})
var setSize
html&&isHostObjectProperty(html,"style")&&(setSize=function(){var px="number"==typeof html.style.top?0:"px"
return function(el,h,w){null!==h&&h>=0&&(el.style.height=h+px)
null!==w&&w>=0&&(el.style.width=w+px)}}())
var setPosition
html&&isHostObjectProperty(html,"style")&&(setPosition=function(){var px="number"==typeof html.style.top?0:"px"
return function(el,x,y){null!==x&&(el.style.left=x+px)
null!==y&&(el.style.top=y+px)}}())
var setHtml
html&&"string"==typeof html.innerHTML&&(setHtml=function(el,html){el.innerHTML=html})
var removeClass
html&&isHostObjectProperty(html,"classList")&&isHostMethod(html.classList,"remove")&&(removeClass=function(el,className){return el.classList.remove(className)})
var removeChild
html&&isHostMethod(html,"removeChild")&&(removeChild=function(el,childNode){return el.removeChild(childNode)})
var prependHtml
html&&isHostMethod(html,"insertAdjacentHTML")&&(prependHtml=function(el,html){el.insertAdjacentHTML("afterBegin",html)})
var getText
html&&"string"==typeof html.textContent?getText=function(el){return el.textContent}:html&&"string"==typeof html.innerText&&(getText=function(el){return el.innerText})
var getStyleComputed
isHostObjectProperty(globalDocument,"defaultView")&&isHostMethod(globalDocument.defaultView,"getComputedStyle")&&(getStyleComputed=function(el,style){return document.defaultView.getComputedStyle(el,null)[style]})
var getPositionRelativeToDocument
getPositionRelativeToViewport&&getViewportScrollPosition&&(getPositionRelativeToDocument=function(el){var position=getPositionRelativeToViewport(el),scrollPosition=getViewportScrollPosition(),x=position[0]+scrollPosition[0],y=position[1]+scrollPosition[1]
return[x,y]})
var getOuterSize
html&&"number"==typeof html.offsetWidth&&(getOuterSize=function(el){return[el.offsetHeight,el.offsetWidth]})
var getInnerSize
html&&"number"==typeof html.clientWidth&&(getInnerSize=function(el){return[el.clientHeight,el.clientWidth]})
var getHtml
html&&"string"==typeof html.innerHTML&&(getHtml=function(el){return el.innerHTML})
var getDescendantsByTagName
globalDocument&&isHostMethod(globalDocument,"getElementsByTagName")&&toArray&&(getDescendantsByTagName=function(el,tagName){return toArray((el||document).getElementsByTagName(tagName))})
var getDescendantsByClassName
globalDocument&&isHostMethod(globalDocument,"getElementsByClassName")&&toArray&&(getDescendantsByClassName=function(el,className){return toArray((el||document).getElementsByClassName(className))})
var getAncestorByTagName
getElementParentElement&&getElementTagName&&(getAncestorByTagName=function(el,tagName){el=getElementParentElement(el)
for(;el&&tagName&&getElementTagName(el)!=tagName;)el=getElementParentElement(el)
return el})
var getAncestorByClassName
html&&"string"==typeof html.className&&getElementParentElement&&hasClass&&(getAncestorByClassName=function(el,className){el=getElementParentElement(el)
for(;el&&!hasClass(el,className);)el=getElementParentElement(el)
return el})
var findProprietaryStyle
html&&isHostObjectProperty(html,"style")&&(findProprietaryStyle=function(style,el){if("string"!=typeof el.style[style]){var prefixes=["Moz","O","Khtml","Webkit","Ms"],i=prefixes.length
style=style.charAt(0).toUpperCase()+style.substring(1)
for(;i--;)if("undefined"!=typeof el.style[prefixes[i]+style])return prefixes[i]+style
return null}return style})
var createElement
globalDocument&&isHostMethod(globalDocument,"createElement")&&(createElement=function(tagName,doc){return(doc||document).createElement(tagName)})
var htmlToNodes
setHtml&&createElement&&(htmlToNodes=function(html,docNode){var c
elTemp=createElement("div",docNode)
if(elTemp){setHtml(html)
c=elTemp.childNodes
elTemp=null}return c})
var appendHtml
html&&isHostMethod(html,"insertAdjacentHTML")&&(appendHtml=function(el,html){el.insertAdjacentHTML("beforeEnd",html)})
var appendChild
html&&isHostMethod(html,"appendChild")&&(appendChild=function(el,appendEl){return el.appendChild(appendEl)})
var addClass
html&&isHostObjectProperty(html,"classList")&&isHostMethod(html.classList,"add")&&(addClass=function(el,className){return el.classList.add(className)})
KD.dom.isHostMethod=isHostMethod
KD.dom.isHostObjectProperty=isHostObjectProperty
KD.dom.areFeatures=areFeatures
KD.dom.toArray=toArray
KD.dom.detachListener=detachListener
KD.dom.getEventTarget=getEventTarget
KD.dom.attachListener=attachListener
KD.dom.query=query
KD.dom.queryOne=queryOne
KD.dom.isNodeInNodeList=isNodeInNodeList
KD.dom.bind=bind
KD.dom.undelegateListener=undelegateListener
KD.dom.delegateListener=delegateListener
KD.dom.getElementTagName=getElementTagName
KD.dom.getElementParentElement=getElementParentElement
KD.dom.isInQuery=isInQuery
KD.dom.isDescendant=isDescendant
KD.dom.delegateBoundListener=delegateBoundListener
KD.dom.hasClass=hasClass
KD.dom.attachWindowListener=attachWindowListener
KD.dom.getViewportScrollPosition=getViewportScrollPosition
KD.dom.getPositionRelativeToViewport=getPositionRelativeToViewport
KD.dom.getElement=getElement
KD.dom.undelegateQueryListener=undelegateQueryListener
KD.dom.setViewportScrollPosition=setViewportScrollPosition
KD.dom.setInputValue=setInputValue
KD.dom.getViewportSize=getViewportSize
KD.dom.getEventTargetRelated=getEventTargetRelated
KD.dom.detachWindowListener=detachWindowListener
KD.dom.detachBoundListener=detachBoundListener
KD.dom.delegateTagNameListener=delegateTagNameListener
KD.dom.delegateQueryListener=delegateQueryListener
KD.dom.delegateBoundQueryListener=delegateBoundQueryListener
KD.dom.delegateBoundClassNameListener=delegateBoundClassNameListener
KD.dom.cancelPropagation=cancelPropagation
KD.dom.cancelDefault=cancelDefault
KD.dom.attachDocumentListener=attachDocumentListener
KD.dom.attachBoundWindowListener=attachBoundWindowListener
KD.dom.attachBoundListener=attachBoundListener
KD.dom.setText=setText
KD.dom.setSize=setSize
KD.dom.setPosition=setPosition
KD.dom.setHtml=setHtml
KD.dom.removeClass=removeClass
KD.dom.removeChild=removeChild
KD.dom.prependHtml=prependHtml
KD.dom.getText=getText
KD.dom.getStyleComputed=getStyleComputed
KD.dom.getPositionRelativeToDocument=getPositionRelativeToDocument
KD.dom.getOuterSize=getOuterSize
KD.dom.getInnerSize=getInnerSize
KD.dom.getHtml=getHtml
KD.dom.getDescendantsByTagName=getDescendantsByTagName
KD.dom.getDescendantsByClassName=getDescendantsByClassName
KD.dom.getAncestorByTagName=getAncestorByTagName
KD.dom.getAncestorByClassName=getAncestorByClassName
KD.dom.findProprietaryStyle=findProprietaryStyle
KD.dom.createElement=createElement
KD.dom.htmlToNodes=htmlToNodes
KD.dom.appendHtml=appendHtml
KD.dom.appendChild=appendChild
KD.dom.addClass=addClass
globalDocument=html=null}(this)

var KDEventEmitter,__hasProp={}.hasOwnProperty,__slice=[].slice,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDEventEmitter=function(){function KDEventEmitter(options){var maxListeners
null==options&&(options={})
maxListeners=options.maxListeners
this._e={}
this._maxListeners=maxListeners>0?maxListeners:10}var _off,_on,_registerEvent,_unregisterEvent
KDEventEmitter.registerWildcardEmitter=function(){var prop,source,val,_results
source=this.Wildcard.prototype
_results=[]
for(prop in source)if(__hasProp.call(source,prop)){val=source[prop]
"constructor"!==prop&&_results.push(this.prototype[prop]=val)}return _results}
KDEventEmitter.registerStaticEmitter=function(){return this._e={}}
_registerEvent=function(registry,eventName,listener){null==registry[eventName]&&(registry[eventName]=[])
return registry[eventName].push(listener)}
_unregisterEvent=function(registry,eventName,listener){var cbIndex
if(!eventName||"*"===eventName)return registry={}
if(!listener||!registry[eventName])return registry[eventName]=[]
cbIndex=registry[eventName].indexOf(listener)
return cbIndex>=0?registry[eventName].splice(cbIndex,1):void 0}
_on=function(registry,eventName,listener){var name,_i,_len,_results
if(null==eventName)throw new Error("Try passing an event, genius!")
if(null==listener)throw new Error("Try passing a listener, genius!")
if(Array.isArray(eventName)){_results=[]
for(_i=0,_len=eventName.length;_len>_i;_i++){name=eventName[_i]
_results.push(_registerEvent(registry,name,listener))}return _results}return _registerEvent(registry,eventName,listener)}
_off=function(registry,eventName,listener){var name,_i,_len,_results
if(Array.isArray(eventName)){_results=[]
for(_i=0,_len=eventName.length;_len>_i;_i++){name=eventName[_i]
_results.push(_unregisterEvent(registry,name,listener))}return _results}return _unregisterEvent(registry,eventName,listener)}
KDEventEmitter.emit=function(){var args,eventName,listener,listeners,_base,_i,_len
if(null==this._e)throw new Error("Static events are not enabled for this constructor.")
eventName=arguments[0],args=2<=arguments.length?__slice.call(arguments,1):[]
listeners=null!=(_base=this._e)[eventName]?(_base=this._e)[eventName]:_base[eventName]=[]
for(_i=0,_len=listeners.length;_len>_i;_i++){listener=listeners[_i]
listener.apply(null,args)}return this}
KDEventEmitter.on=function(eventName,listener){if("function"!=typeof listener)throw new Error("listener is not a function")
if(null==this._e)throw new Error("Static events are not enabled for this constructor.")
this.emit("newListener",listener)
_on(this._e,eventName,listener)
return this}
KDEventEmitter.off=function(eventName,listener){this.emit("listenerRemoved",eventName,listener)
_off(this._e,eventName,listener)
return this}
KDEventEmitter.prototype.emit=function(){var args,eventName,listenerStack,_base,_this=this
eventName=arguments[0],args=2<=arguments.length?__slice.call(arguments,1):[]
null==(_base=this._e)[eventName]&&(_base[eventName]=[])
listenerStack=[]
listenerStack=listenerStack.concat(this._e[eventName].slice(0))
listenerStack.forEach(function(listener){return listener.apply(_this,args)})
return this}
KDEventEmitter.prototype.on=function(eventName,listener){if("function"!=typeof listener)throw new Error("listener is not a function")
this.emit("newListener",eventName,listener)
_on(this._e,eventName,listener)
return this}
KDEventEmitter.prototype.off=function(eventName,listener){this.emit("listenerRemoved",eventName,listener)
_off(this._e,eventName,listener)
return this}
KDEventEmitter.prototype.once=function(eventName,listener){var _listener,_this=this
_listener=function(){var args
args=[].slice.call(arguments)
_this.off(eventName,_listener)
return listener.apply(_this,args)}
this.on(eventName,_listener)
return this}
return KDEventEmitter}()
KDEventEmitter.Wildcard=function(_super){function Wildcard(options){null==options&&(options={})
Wildcard.__super__.constructor.apply(this,arguments)
this._delim=options.delimiter||"."}var getAllListeners,listenerKey,removeAllListeners,wildcardKey
__extends(Wildcard,_super)
wildcardKey="*"
listenerKey="_listeners"
Wildcard.prototype.setMaxListeners=function(n){return this._maxListeners=n}
getAllListeners=function(node,edges,i){var listeners,nextNode,straight,wild
null==i&&(i=0)
listeners=[]
i===edges.length&&(straight=node[listenerKey])
wild=node[wildcardKey]
nextNode=node[edges[i]]
null!=straight&&(listeners=listeners.concat(straight))
null!=wild&&(listeners=listeners.concat(getAllListeners(wild,edges,i+1)))
null!=nextNode&&(listeners=listeners.concat(getAllListeners(nextNode,edges,i+1)))
return listeners}
removeAllListeners=function(node,edges,it,i){var edge,listener,listeners,nextNode
null==i&&(i=0)
edge=edges[i]
nextNode=node[edge]
if(null!=nextNode)return removeAllListeners(nextNode,edges,it,i+1)
node[listenerKey]=null!=it&&null!=(listeners=node[listenerKey])?function(){var _i,_len,_results
_results=[]
for(_i=0,_len=listeners.length;_len>_i;_i++){listener=listeners[_i]
listener!==it&&_results.push(listener)}return _results}():[]
return void 0}
Wildcard.prototype.emit=function(){var eventName,listener,listeners,oldEvent,rest,_i,_len
eventName=arguments[0],rest=2<=arguments.length?__slice.call(arguments,1):[]
this.hasOwnProperty("event")&&(oldEvent=this.event)
this.event=eventName
listeners=getAllListeners(this._e,eventName.split(this._delim))
for(_i=0,_len=listeners.length;_len>_i;_i++){listener=listeners[_i]
listener.apply(this,rest)}null!=oldEvent?this.event=oldEvent:delete this.event
return this}
Wildcard.prototype.off=function(eventName,listener){removeAllListeners(this._e,(null!=eventName?eventName:"*").split(this._delim),listener)
return this}
Wildcard.prototype.on=function(eventName,listener){var edge,edges,listeners,node,_i,_len
if("function"!=typeof listener)throw new Error("listener is not a function")
this.emit("newListener",eventName,listener)
edges=eventName.split(".")
node=this._e
for(_i=0,_len=edges.length;_len>_i;_i++){edge=edges[_i]
node=null!=node[edge]?node[edge]:node[edge]={}}listeners=null!=node[listenerKey]?node[listenerKey]:node[listenerKey]=[]
listeners.push(listener)
return this}
return Wildcard}(KDEventEmitter)

var KDObject,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
KDObject=function(_super){function KDObject(options,data){var _this=this
null==options&&(options={})
this.id||(this.id=options.id||__utils.getUniqueId())
this.setOptions(options)
data&&this.setData(data)
options.delegate&&this.setDelegate(options.delegate)
this.registerKDObjectInstance()
KDObject.__super__.constructor.apply(this,arguments)
options.testPath&&KD.registerInstanceForTesting(this)
this.on("error",error)
this.once("ready",function(){return _this.readyState=READY})}var NOTREADY,READY,_ref
__extends(KDObject,_super)
_ref=[0,1],NOTREADY=_ref[0],READY=_ref[1]
KDObject.prototype.utils=__utils
KDObject.prototype.bound=function(method){var boundMethod
if(null==this[method])throw new Error("@bound: unknown method! "+method)
boundMethod="__bound__"+method
boundMethod in this||Object.defineProperty(this,boundMethod,{value:this[method].bind(this)})
return this[boundMethod]}
KDObject.prototype.lazyBound=function(){var method,rest,_ref1
method=arguments[0],rest=2<=arguments.length?__slice.call(arguments,1):[]
return(_ref1=this[method]).bind.apply(_ref1,[this].concat(__slice.call(rest)))}
KDObject.prototype.forwardEvent=function(target,eventName,prefix){null==prefix&&(prefix="")
return target.on(eventName,this.lazyBound("emit",prefix+eventName))}
KDObject.prototype.forwardEvents=function(target,eventNames,prefix){var eventName,_i,_len,_results
null==prefix&&(prefix="")
_results=[]
for(_i=0,_len=eventNames.length;_len>_i;_i++){eventName=eventNames[_i]
_results.push(this.forwardEvent(target,eventName,prefix))}return _results}
KDObject.prototype.ready=function(listener){return this.readyState===READY?this.utils.defer(listener):this.once("ready",listener)}
KDObject.prototype.registerSingleton=KD.registerSingleton
KDObject.prototype.getSingleton=KD.getSingleton
KDObject.prototype.getInstance=function(instanceId){var _ref1
return null!=(_ref1=KD.getAllKDInstances()[instanceId])?_ref1:null}
KDObject.prototype.requireMembership=KD.requireMembership
KDObject.prototype.registerKDObjectInstance=function(){return KD.registerInstance(this)}
KDObject.prototype.setData=function(data){if(null==data)return warn("setData called with null or undefined!")
this.data=data
return"function"==typeof data.emit?data.emit("update"):void 0}
KDObject.prototype.getData=function(){return this.data}
KDObject.prototype.setOptions=function(options){this.options=null!=options?options:{}}
KDObject.prototype.setOption=function(option,value){return this.options[option]=value}
KDObject.prototype.unsetOption=function(option){return this.options[option]?delete this.options[option]:void 0}
KDObject.prototype.getOptions=function(){return this.options}
KDObject.prototype.getOption=function(key){var _ref1
return null!=(_ref1=this.options[key])?_ref1:null}
KDObject.prototype.changeId=function(id){KD.deleteInstance(id)
this.id=id
return KD.registerInstance(this)}
KDObject.prototype.getId=function(){return this.id}
KDObject.prototype.setDelegate=function(delegate){this.delegate=delegate}
KDObject.prototype.getDelegate=function(){return this.delegate}
KDObject.prototype.destroy=function(){this.isDestroyed=!0
this.emit("KDObjectWillBeDestroyed")
return KD.deleteInstance(this.id)}
KDObject.prototype.inheritanceChain=function(options){var chain,method,methodArray,newChain,proto,_i,_j,_len,_len1
methodArray=options.method.split(".")
options.callback
proto=this.__proto__
chain=this
for(_i=0,_len=methodArray.length;_len>_i;_i++){method=methodArray[_i]
chain=chain[method]}for(;proto=proto.__proto__;){newChain=proto
for(_j=0,_len1=methodArray.length;_len1>_j;_j++){method=methodArray[_j]
newChain=newChain[method]}chain=options.callback({chain:chain,newLink:newChain})}return chain}
KDObject.prototype.chainNames=function(options){options.chain
options.newLink
return""+options.chain+"."+options.newLink}
return KDObject}(KDEventEmitter)

var KDView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDView=function(_super){function KDView(options,data){var o,_this=this
null==options&&(options={})
o=options
o.tagName||(o.tagName="div")
o.domId||(o.domId=null)
o.cssClass||(o.cssClass="")
o.parent||(o.parent=null)
o.partial||(o.partial=null)
o.pistachio||(o.pistachio=null)
o.delegate||(o.delegate=null)
o.bind||(o.bind="")
o.draggable||(o.draggable=null)
o.droppable||(o.droppable=null)
o.size||(o.size=null)
o.position||(o.position=null)
o.attributes||(o.attributes=null)
o.prefix||(o.prefix="")
o.suffix||(o.suffix="")
o.tooltip||(o.tooltip=null)
o.resizable||(o.resizable=null)
KDView.__super__.constructor.call(this,o,data)
null!=data&&"function"==typeof data.on&&data.on("update",this.bound("render"))
this.setInstanceVariables(options)
this.defaultInit(options,data)
o.draggable&&this.setClass("kddraggable")
this.on("childAppended",this.childAppended.bind(this))
this.on("viewAppended",function(){var child,fireViewAppended,key,mainController,subViews,_i,_len
_this.setViewReady()
_this.viewAppended()
_this.childAppended(_this)
_this.parentIsInDom=!0
subViews=_this.getSubViews()
fireViewAppended=function(child){if(!child.parentIsInDom){child.parentIsInDom=!0
if(!child.lazy)return child.emit("viewAppended")}}
if(Array.isArray(subViews))for(_i=0,_len=subViews.length;_len>_i;_i++){child=subViews[_i]
fireViewAppended(child)}else if(null!=subViews&&"object"==typeof subViews)for(key in subViews)if(__hasProp.call(subViews,key)){child=subViews[key]
fireViewAppended(child)}if(_this.getOptions().introId){mainController=KD.getSingleton("mainController")
return mainController.introductionTooltipController.emit("ShowIntroductionTooltip",_this)}})
"localhost"===location.hostname&&this.on("click",function(event){if(event){if(event.metaKey&&event.altKey&&event.ctrlKey){log(_this.getData())
"function"==typeof event.stopPropagation&&event.stopPropagation()
"function"==typeof event.preventDefault&&event.preventDefault()
return!1}if(event.altKey&&(event.metaKey||event.ctrlKey)){log(_this)
return!1}}})}var defineProperty,deprecated,eventNames,eventToMethodMap,overrideAndMergeObjects
__extends(KDView,_super)
defineProperty=Object.defineProperty
deprecated=function(methodName){return warn(""+methodName+" is deprecated from KDView if you need it override in your subclass")}
eventNames=/^((dbl)?click|key(up|down|press)|mouse(up|down|over|enter|leave|move)|drag(start|end|enter|leave|over)|blur|change|focus|drop|contextmenu|scroll|paste|error|load)$/
eventToMethodMap=function(){return{dblclick:"dblClick",keyup:"keyUp",keydown:"keyDown",keypress:"keyPress",mouseup:"mouseUp",mousedown:"mouseDown",mouseenter:"mouseEnter",mouseleave:"mouseLeave",mousemove:"mouseMove",mousewheel:"mouseWheel",wheel:"mouseWheel",mouseover:"mouseOver",contextmenu:"contextMenu",dragstart:"dragStart",dragenter:"dragEnter",dragleave:"dragLeave",dragover:"dragOver",paste:"paste",transitionend:"transitionEnd"}}
overrideAndMergeObjects=function(objects){var item,title,_ref
_ref=objects.overridden
for(title in _ref)if(__hasProp.call(_ref,title)){item=_ref[title]
objects.overrider[title]||(objects.overrider[title]=item)}return objects.overrider}
KDView.prototype.appendToDomBody=function(){var _this=this
this.parentIsInDom=!0
if(!this.lazy){$("body").append(this.$())
return this.utils.defer(function(){return _this.emit("viewAppended")})}}
KDView.appendToDOMBody=function(view){console.warn("KDView.appendToDOMBody is deprecated; use #appendToDomBody instead")
return view.appendToDomBody()}
KDView.prototype.setInstanceVariables=function(options){this.domId=options.domId,this.parent=options.parent
return this.subViews=[]}
KDView.prototype.defaultInit=function(options){this.setDomElement(options.cssClass)
this.setDataId()
options.domId&&this.setDomId(options.domId)
options.attributes&&this.setAttributes(options.attributes)
options.size&&this.setSize(options.size)
options.position&&this.setPosition(options.position)
options.partial&&this.updatePartial(options.partial)
this.addEventHandlers(options)
options.lazyLoadThreshold&&this.setLazyLoader(options.lazyLoadThreshold)
options.tooltip&&this.setTooltip(options.tooltip)
options.draggable&&this.setDraggable(options.draggable)
return this.bindEvents()}
KDView.prototype.getDomId=function(){return this.domElement.attr("id")}
KDView.prototype.setDomElement=function(cssClass){var domId,el,klass,tagName,_i,_len,_ref,_ref1,_this=this
null==cssClass&&(cssClass="")
_ref=this.getOptions(),domId=_ref.domId,tagName=_ref.tagName
domId&&(el=document.getElementById(domId))
this.lazy=null==el?(el=document.createElement(tagName),domId?el.id=domId:void 0,!1):!0
_ref1=("kdview "+cssClass).split(" ")
for(_i=0,_len=_ref1.length;_len>_i;_i++){klass=_ref1[_i]
klass.length&&el.classList.add(klass)}this.domElement=$(el)
return this.lazy?this.utils.defer(function(){return _this.emit("viewAppended")}):void 0}
KDView.prototype.setDomId=function(id){return this.domElement.attr("id",id)}
KDView.prototype.setDataId=function(){return this.domElement.data("data-id",this.getId())}
KDView.prototype.getAttribute=function(attr){return this.getElement().getAttribute(attr)}
KDView.prototype.setAttribute=function(attr,val){return this.getElement().setAttribute(attr,val)}
KDView.prototype.setAttributes=function(attributes){var attr,val,_results
_results=[]
for(attr in attributes)if(__hasProp.call(attributes,attr)){val=attributes[attr]
_results.push(this.setAttribute(attr,val))}return _results}
KDView.prototype.isInDom=function(){var findUltimateAncestor
findUltimateAncestor=function(el){var ancestor
ancestor=el
for(;ancestor.parentNode;)ancestor=ancestor.parentNode
return ancestor}
return function(){return null!=findUltimateAncestor(this.$()[0]).body}}()
Object.defineProperty(KDView.prototype,"$$",{get:KDView.prototype.$})
Object.defineProperty(KDView.prototype,"el",{get:KDView.prototype.getElement})
KDView.prototype.getDomElement=function(){return this.domElement}
KDView.prototype.getElement=function(){return this.getDomElement()[0]}
KDView.prototype.getTagName=function(){return this.options.tagName||"div"}
KDView.prototype.$=function(selector){return selector?this.getDomElement().find(selector):this.getDomElement()}
KDView.prototype.append=function(child,selector){this.$(selector).append(child.$())
this.parentIsInDom&&child.emit("viewAppended")
return this}
KDView.prototype.appendTo=function(parent,selector){this.$().appendTo(parent.$(selector))
this.parentIsInDom&&this.emit("viewAppended")
return this}
KDView.prototype.appendToSelector=function(selector){$(selector).append(this.$())
return this.emit("viewAppended")}
KDView.prototype.prepend=function(child,selector){this.$(selector).prepend(child.$())
this.parentIsInDom&&child.emit("viewAppended")
return this}
KDView.prototype.prependTo=function(parent,selector){this.$().prependTo(parent.$(selector))
this.parentIsInDom&&this.emit("viewAppended")
return this}
KDView.prototype.prependToSelector=function(selector){$(selector).prepend(this.$())
return this.emit("viewAppended")}
KDView.prototype.setPartial=function(partial,selector){this.$(selector).append(partial)
return this}
KDView.prototype.updatePartial=function(partial,selector){return this.$(selector).html(partial)}
KDView.prototype.clear=function(){return this.getElement().innerHTML=""}
KDView.setElementClass=function(el,addOrRemove,cssClass){var cl,_i,_len,_ref,_results
_ref=cssClass.split(" ")
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){cl=_ref[_i]
""!==cl&&_results.push(el.classList[addOrRemove](cl))}return _results}
KDView.prototype.setCss=function(property,value){return this.$().css(property,value)}
KDView.prototype.setStyle=function(properties){var property,value,_results
_results=[]
for(property in properties)if(__hasProp.call(properties,property)){value=properties[property]
_results.push(this.$().css(property,value))}return _results}
KDView.prototype.setClass=function(cssClass){if(cssClass){KDView.setElementClass(this.getElement(),"add",cssClass)
return this}}
KDView.prototype.unsetClass=function(cssClass){if(cssClass){KDView.setElementClass(this.getElement(),"remove",cssClass)
return this}}
KDView.prototype.toggleClass=function(cssClass){this.$().toggleClass(cssClass)
return this}
KDView.prototype.hasClass=function(cssClass){return this.getElement().classList.contains(cssClass)}
KDView.prototype.getBounds=function(){var bounds
return bounds={x:this.getX(),y:this.getY(),w:this.getWidth(),h:this.getHeight(),n:this.constructor.name}}
KDView.prototype.setRandomBG=function(){return this.getDomElement().css("background-color",__utils.getRandomRGB())}
KDView.prototype.hide=function(){return this.setClass("hidden")}
KDView.prototype.show=function(){return this.unsetClass("hidden")}
KDView.prototype.setSize=function(sizes){null!=sizes.width&&this.setWidth(sizes.width)
return null!=sizes.height?this.setHeight(sizes.height):void 0}
KDView.prototype.setPosition=function(){var positionOptions
positionOptions=this.getOptions().position
positionOptions.position="absolute"
return this.$().css(positionOptions)}
KDView.prototype.getWidth=function(){return this.$().width()}
KDView.prototype.setWidth=function(w,unit){null==unit&&(unit="px")
this.getElement().style.width=""+w+unit
return this.emit("ViewResized",{newWidth:w,unit:unit})}
KDView.prototype.getHeight=function(){return this.getDomElement().outerHeight(!1)}
KDView.prototype.setHeight=function(h,unit){null==unit&&(unit="px")
this.getElement().style.height=""+h+unit
return this.emit("ViewResized",{newHeight:h,unit:unit})}
KDView.prototype.setX=function(x){return this.$().css({left:x})}
KDView.prototype.setY=function(y){return this.$().css({top:y})}
KDView.prototype.getX=function(){return this.$().offset().left}
KDView.prototype.getY=function(){return this.$().offset().top}
KDView.prototype.getRelativeX=function(){return this.$().position().left}
KDView.prototype.getRelativeY=function(){return this.$().position().top}
KDView.prototype.destroyChild=function(prop){var _base
if(null!=this[prop]){"function"==typeof(_base=this[prop]).destroy&&_base.destroy()
delete this[prop]
return!0}return!1}
KDView.prototype.destroy=function(){var index,_ref
this.getSubViews().length>0&&this.destroySubViews()
if((null!=(_ref=this.parent)?_ref.subViews:void 0)&&(index=this.parent.subViews.indexOf(this))>=0){this.parent.subViews.splice(index,1)
this.unsetParent()}this.getDomElement().remove()
null!=this.$overlay&&this.removeOverlay()
return KDView.__super__.destroy.apply(this,arguments)}
KDView.prototype.destroySubViews=function(){var view,_i,_len,_ref
_ref=this.getSubViews().slice()
for(_i=0,_len=_ref.length;_len>_i;_i++){view=_ref[_i]
"function"==typeof view.destroy&&view.destroy()}}
KDView.prototype.addSubView=function(subView,selector,shouldPrepend){if(null==subView)throw new Error("no subview was specified")
this.subViews.push(subView)
subView.setParent(this)
subView.parentIsInDom=this.parentIsInDom
subView.lazy||(shouldPrepend?this.prepend(subView,selector):this.append(subView,selector))
subView.on("ViewResized",function(){return subView.parentDidResize()})
null!=this.template&&this.template.addSymbol(subView)
return subView}
KDView.prototype.removeSubView=function(subView){return subView.destroy()}
KDView.prototype.getSubViews=function(){var subViews
subViews=this.subViews
null!=this.items&&(subViews=subViews.concat([].slice.call(this.items)))
return subViews}
KDView.prototype.setTemplate=function(tmpl,params){var options,_ref
null==params&&(params=null!=(_ref=this.getOptions())?_ref.pistachioParams:void 0)
options=null!=params?{params:params}:void 0
this.template=new Pistachio(this,tmpl,options)
this.updatePartial(this.template.html)
return this.template.embedSubViews()}
KDView.prototype.pistachio=function(tmpl){return tmpl?""+this.options.prefix+tmpl+this.options.suffix:void 0}
KDView.prototype.setParent=function(parent){return null!=this.parent?error("View already has a parent",this,this.parent):defineProperty?defineProperty(this,"parent",{value:parent,configurable:!0}):this.parent=parent}
KDView.prototype.unsetParent=function(){return delete this.parent}
KDView.prototype.embedChild=function(placeholderId,child,isCustom){this.addSubView(child,"#"+placeholderId,!1)
return isCustom?void 0:this.$("#"+placeholderId).replaceWith(child.$())}
KDView.prototype.render=function(){null!=this.template&&this.template.update()}
KDView.prototype.parentDidResize=function(parent,event){var subView,_i,_len,_ref,_results
if(this.getSubViews()){_ref=this.getSubViews()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){subView=_ref[_i]
_results.push(subView.parentDidResize(parent,event))}return _results}}
KDView.prototype.setLazyLoader=function(threshold){var view
null==threshold&&(threshold=.75);/\bscroll\b/.test(this.getOptions().bind)||(this.getOptions().bind+=" scroll")
view=this
return this.on("scroll",function(){var lastRatio
lastRatio=0
return function(){var dynamicThreshold,el,ratio,scrollHeight,scrollTop
el=view.$()[0]
scrollHeight=el.scrollHeight,scrollTop=el.scrollTop
dynamicThreshold=threshold>1?(scrollHeight-threshold)/scrollHeight:threshold
ratio=(scrollTop+view.getHeight())/scrollHeight
ratio>dynamicThreshold&&ratio>lastRatio&&this.emit("LazyLoadThresholdReached",{ratio:ratio})
return lastRatio=ratio}}())}
KDView.prototype.bindEvents=function($elm){var defaultEvents,event,eventsToBeBound,instanceEvents,_this=this
$elm||($elm=this.getDomElement())
defaultEvents="mousedown mouseup click dblclick"
instanceEvents=this.getOptions().bind
eventsToBeBound=function(){var _i,_len
if(instanceEvents){eventsToBeBound=defaultEvents.trim().split(" ")
instanceEvents=instanceEvents.trim().split(" ")
for(_i=0,_len=instanceEvents.length;_len>_i;_i++){event=instanceEvents[_i]
__indexOf.call(eventsToBeBound,event)<0&&eventsToBeBound.push(event)}return eventsToBeBound.join(" ")}return defaultEvents}()
$elm.bind(eventsToBeBound,function(event){var willPropagateToDOM
willPropagateToDOM=_this.handleEvent(event)
willPropagateToDOM||event.stopPropagation()
return!0})
return eventsToBeBound}
KDView.prototype.bindTransitionEnd=function(){var el,key,transitionEvent,transitions,val
el=document.createElement("fakeelement")
transitions={OTransition:"oTransitionEnd",MozTransition:"transitionend",webkitTransition:"webkitTransitionEnd"}
transitionEvent="transitionend"
for(key in transitions)if(__hasProp.call(transitions,key)){val=transitions[key]
if(key in el.style){transitionEvent=val
break}}this.bindEvent(transitionEvent)
return"transitionend"!==transitionEvent?this.on(transitionEvent,this.emit.bind(this,"transitionend")):void 0}
KDView.prototype.bindEvent=function($elm,eventName){var _ref,_this=this
eventName||(_ref=[$elm,this.$()],eventName=_ref[0],$elm=_ref[1])
return $elm.bind(eventName,function(event){var shouldPropagate
shouldPropagate=_this.handleEvent(event)
shouldPropagate||event.stopPropagation()
return!0})}
KDView.prototype.handleEvent=function(event){var methodName,shouldPropagate
methodName=eventToMethodMap()[event.type]||event.type
shouldPropagate=null!=this[methodName]?this[methodName](event):!0
shouldPropagate!==!1&&this.emit(event.type,event)
return shouldPropagate}
KDView.prototype.scroll=function(){return!0}
KDView.prototype.load=function(){return!0}
KDView.prototype.error=function(){return!0}
KDView.prototype.keyUp=function(){return!0}
KDView.prototype.keyDown=function(){return!0}
KDView.prototype.keyPress=function(){return!0}
KDView.prototype.dblClick=function(){return!0}
KDView.prototype.click=function(){return!0}
KDView.prototype.contextMenu=function(){return!0}
KDView.prototype.mouseMove=function(){return!0}
KDView.prototype.mouseEnter=function(){return!0}
KDView.prototype.mouseLeave=function(){return!0}
KDView.prototype.mouseUp=function(){return!0}
KDView.prototype.mouseOver=function(){return!0}
KDView.prototype.mouseWheel=function(){return!0}
KDView.prototype.mouseDown=function(){KD.getSingleton("windowController").setKeyView(null)
return!0}
KDView.prototype.paste=function(){return!0}
KDView.prototype.dragEnter=function(e){e.preventDefault()
return e.stopPropagation()}
KDView.prototype.dragOver=function(e){e.preventDefault()
return e.stopPropagation()}
KDView.prototype.dragLeave=function(e){e.preventDefault()
return e.stopPropagation()}
KDView.prototype.drop=function(event){event.preventDefault()
return event.stopPropagation()}
KDView.prototype.submit=function(){return!1}
KDView.prototype.addEventHandlers=function(options){var cb,eventName,_results
_results=[]
for(eventName in options)if(__hasProp.call(options,eventName)){cb=options[eventName]
eventNames.test(eventName)&&"function"==typeof cb?_results.push(this.on(eventName,cb)):_results.push(void 0)}return _results}
KDView.prototype.setEmptyDragState=function(moveBacktoInitialPosition){var el
null==moveBacktoInitialPosition&&(moveBacktoInitialPosition=!1)
if(moveBacktoInitialPosition&&this.dragState){el=this.$()
el.css("left",0)
el.css("top",0)}return this.dragState={containment:null,handle:null,axis:null,direction:{current:{x:null,y:null},global:{x:null,y:null}},position:{relative:{x:0,y:0},initial:{x:0,y:0},global:{x:0,y:0}},meta:{top:0,right:0,bottom:0,left:0}}}
KDView.prototype.setDraggable=function(options){var handle,_this=this
null==options&&(options={})
options===!0&&(options={})
this.setEmptyDragState()
handle=options.handle instanceof KDView?options.handle:this
this.on("DragFinished",function(){return _this.beingDragged=!1})
return handle.on("mousedown",function(event){var bounds,dragEl,dragMeta,dragPos,dragState,oPad,p,padding,v,view
if("string"!=typeof options.handle||0!==$(event.target).closest(options.handle).length){_this.dragIsAllowed=!0
_this.setEmptyDragState()
dragState=_this.dragState
if(options.containment){dragState.containment={}
view=options.containment.view
bounds="string"==typeof view?_this[view].getBounds():view instanceof KDView?view.getBounds():_this.parent.getBounds()
dragState.containment.viewBounds=bounds
padding={top:0,right:0,bottom:0,left:0}
oPad=options.containment.padding
if("number"==typeof oPad){for(p in padding)if(__hasProp.call(padding,p)){v=padding[p]
v=oPad}}else"object"==typeof oPad&&KD.utils.extend(padding,oPad)
dragState.containment.padding=padding}dragState.handle=options.handle
dragState.axis=options.axis
dragMeta=dragState.meta
dragEl=_this.getElement()
dragMeta.top=parseInt(dragEl.style.top,10)||0
dragMeta.right=parseInt(dragEl.style.right,10)||0
dragMeta.bottom=parseInt(dragEl.style.bottom,10)||0
dragMeta.left=parseInt(dragEl.style.left,10)||0
dragPos=_this.dragState.position
dragPos.initial.x=event.pageX
dragPos.initial.y=event.pageY
KD.getSingleton("windowController").setDragView(_this)
_this.emit("DragStarted",event,_this.dragState)
event.stopPropagation()
event.preventDefault()
return!1}})}
KDView.prototype.drag=function(event,delta){var axis,containment,cp,directionX,directionY,dragCurDir,dragDir,dragGlobDir,dragGlobPos,dragInitPos,dragMeta,dragPos,dragRelPos,draggedDistance,el,m,newX,newY,p,targetPosX,targetPosY,x,y,_ref
_ref=this.dragState,directionX=_ref.directionX,directionY=_ref.directionY,axis=_ref.axis,containment=_ref.containment
x=delta.x,y=delta.y
dragPos=this.dragState.position
dragRelPos=dragPos.relative
dragInitPos=dragPos.initial
dragGlobPos=dragPos.global
dragDir=this.dragState.direction
dragGlobDir=dragDir.global
dragCurDir=dragDir.current
axis=this.getOptions().draggable.axis
draggedDistance=axis?"x"===axis?Math.abs(x):Math.abs(y):Math.max(Math.abs(x),Math.abs(y))
this.dragIsAllowed=this.beingDragged=!(20>draggedDistance&&!this.beingDragged)
x>dragRelPos.x?dragCurDir.x="right":x<dragRelPos.x&&(dragCurDir.x="left")
y>dragRelPos.y?dragCurDir.y="bottom":y<dragRelPos.y&&(dragCurDir.y="top")
dragGlobPos.x=dragInitPos.x+x
dragGlobPos.y=dragInitPos.y+y
dragGlobDir.x=x>0?"right":"left"
dragGlobDir.y=y>0?"bottom":"top"
if(this.dragIsAllowed){el=this.$()
dragMeta=this.dragState.meta
targetPosX=dragMeta.right&&!dragMeta.left?"right":"left"
targetPosY=dragMeta.bottom&&!dragMeta.top?"bottom":"top"
newX="left"===targetPosX?dragMeta.left+dragRelPos.x:dragMeta.right-dragRelPos.x
newY="top"===targetPosY?dragMeta.top+dragRelPos.y:dragMeta.bottom-dragRelPos.y
if(containment){m={w:this.getWidth(),h:this.getHeight()}
p=containment.viewBounds
cp=containment.padding
newX<=cp.left&&(newX=cp.left)
newY<=cp.top&&(newY=cp.top)
newX+m.w>=p.w-cp.right&&(newX=p.w-m.w-cp.right)
newY+m.h>=p.h-cp.bottom&&(newY=p.h-m.h-cp.bottom)}"y"!==axis&&el.css(targetPosX,newX)
"x"!==axis&&el.css(targetPosY,newY)}dragRelPos.x=x
dragRelPos.y=y
return this.emit("DragInAction",x,y)}
KDView.prototype.viewAppended=function(){var pistachio
pistachio=this.getOptions().pistachio
if(pistachio&&null==this.template){this.setTemplate(pistachio)
return this.template.update()}}
KDView.prototype.childAppended=function(child){var _ref
return null!=(_ref=this.parent)?_ref.emit("childAppended",child):void 0}
KDView.prototype.setViewReady=function(){return this.viewIsReady=!0}
KDView.prototype.isViewReady=function(){return this.viewIsReady||!1}
KDView.prototype.putOverlay=function(options){var animated,color,cssClass,isRemovable,parent,_this=this
null==options&&(options={})
isRemovable=options.isRemovable,cssClass=options.cssClass,parent=options.parent,animated=options.animated,color=options.color
null==isRemovable&&(isRemovable=!0)
null==cssClass&&(cssClass="transparent")
null==parent&&(parent="body")
this.$overlay=$("<div />",{"class":"kdoverlay "+cssClass+(animated?" animated":"")})
color&&this.$overlay.css({"background-color":color})
if("string"==typeof parent)this.$overlay.appendTo($(parent))
else if(parent instanceof KDView){this.__zIndex=parseInt(this.$().css("z-index"),10)||0
this.$overlay.css("z-index",this.__zIndex+1)
this.$overlay.appendTo(parent.$())}if(animated){this.utils.defer(function(){return _this.$overlay.addClass("in")})
this.utils.wait(300,function(){return _this.emit("OverlayAdded",_this)})}else this.emit("OverlayAdded",this)
return isRemovable?this.$overlay.on("click.overlay",this.removeOverlay.bind(this)):void 0}
KDView.prototype.removeOverlay=function(){var kallback,_this=this
if(this.$overlay){this.emit("OverlayWillBeRemoved")
kallback=function(){_this.$overlay.off("click.overlay")
_this.$overlay.remove()
delete _this.__zIndex
delete _this.$overlay
return _this.emit("OverlayRemoved",_this)}
if(this.$overlay.hasClass("animated")){this.$overlay.removeClass("in")
return this.utils.wait(300,function(){return kallback()})}return kallback()}}
KDView.prototype.unsetTooltip=function(o){var _ref
null==o&&(o={})
null!=(_ref=this.tooltip)&&_ref.destroy()
return delete this.tooltip}
KDView.prototype.setTooltip=function(o){var placementMap
null==o&&(o={})
placementMap={above:"s",below:"n",left:"e",right:"w"}
o.title||(o.title="")
o.cssClass||(o.cssClass="")
o.placement||(o.placement="top")
o.direction||(o.direction="center")
o.offset||(o.offset={top:0,left:0})
o.delayIn||(o.delayIn=0)
o.delayOut||(o.delayOut=0)
null==o.html&&(o.html=!0)
null==o.animate&&(o.animate=!1)
o.selector||(o.selector=null)
o.gravity||(o.gravity=placementMap[o.placement])
o.fade||(o.fade=o.animate)
o.fallback||(o.fallback=o.title)
o.view||(o.view=null)
null==o.sticky&&(o.sticky=!1)
o.delegate||(o.delegate=this)
o.events||(o.events=["mouseenter","mouseleave","mousemove"])
this.unsetTooltip()
return this.tooltip=new KDTooltip(o,{})}
KDView.prototype.getTooltip=function(){return this.tooltip}
KDView.prototype._windowDidResize=function(){}
KDView.prototype.listenWindowResize=function(state){null==state&&(state=!0)
return state?KD.getSingleton("windowController").registerWindowResizeListener(this):KD.getSingleton("windowController").unregisterWindowResizeListener(this)}
KDView.prototype.notifyResizeListeners=function(){return KD.getSingleton("windowController").notifyWindowResizeListeners()}
KDView.prototype.setKeyView=function(){return KD.getSingleton("windowController").setKeyView(this)}
return KDView}(KDObject)

var KDOverlayView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDOverlayView=function(_super){function KDOverlayView(options){var animated,color,cssClass,isRemovable,opacity,parent,transparent,_this=this
null==options&&(options={})
isRemovable=options.isRemovable,animated=options.animated,color=options.color,transparent=options.transparent,parent=options.parent,opacity=options.opacity
cssClass=["kdoverlay"]
animated&&cssClass.push("animated")
transparent&&cssClass.push("transparent")
options.cssClass=cssClass.join(" ")
KDOverlayView.__super__.constructor.apply(this,arguments)
null==isRemovable&&(isRemovable=!0)
color&&this.$().css({backgroundColor:color,opacity:null!=opacity?opacity:.5})
"string"==typeof parent?this.$().appendTo($(parent)):parent instanceof KDView&&this.$().appendTo(parent.$())
if(animated){this.utils.defer(function(){return _this.$().addClass("in")})
this.utils.wait(300,function(){return _this.emit("OverlayAdded",_this)})}else this.emit("OverlayAdded",this)
isRemovable&&this.$().on("click.overlay",this.removeOverlay.bind(this))}__extends(KDOverlayView,_super)
KDOverlayView.prototype.removeOverlay=function(){var callback,_this=this
this.emit("OverlayWillBeRemoved")
callback=function(){_this.$().off("click.overlay")
_this.destroy()
return _this.emit("OverlayRemoved",_this)}
if(this.$().hasClass("animated")){this.$().removeClass("in")
return this.utils.wait(300,function(){return callback()})}return callback()}
return KDOverlayView}(KDView)

var JView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JView=function(_super){function JView(){_ref=JView.__super__.constructor.apply(this,arguments)
return _ref}__extends(JView,_super)
JView.prototype.viewAppended=function(){var template
template=this.getOptions().pistachio||this.pistachio
"function"==typeof template&&(template=template.call(this))
if(null!=template){this.setTemplate(template)
return this.template.update()}}
JView.prototype.pistachio=function(){return""}
return JView}(KDView)

var KDCustomHTMLView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDCustomHTMLView=function(_super){function KDCustomHTMLView(options,data){var _ref,_ref1
null==options&&(options={})
"string"==typeof options&&(this.tagName=options)
null==this.tagName&&(this.tagName=null!=(_ref=options.tagName)?_ref:"div")
if("a"===this.tagName&&null==(null!=(_ref1=options.attributes)?_ref1.href:void 0)){options.attributes||(options.attributes={})
options.attributes.href="#"}KDCustomHTMLView.__super__.constructor.call(this,options,data)}__extends(KDCustomHTMLView,_super)
KDCustomHTMLView.prototype.setDomElement=function(){KDCustomHTMLView.__super__.setDomElement.apply(this,arguments)
return this.unsetClass("kdview")}
return KDCustomHTMLView}(KDView)

var KDScrollThumb,KDScrollView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDScrollView=function(_super){function KDScrollView(options,data){null==options&&(options={})
null==options.ownScrollBars&&(options.ownScrollBars=!1)
options.bind||(options.bind="mouseenter")
options.cssClass=KD.utils.curry("kdscrollview",options.cssClass)
KDScrollView.__super__.constructor.call(this,options,data)
this.on("click",function(){return KD.getSingleton("windowController").enableScroll()})}__extends(KDScrollView,_super)
KDScrollView.prototype.bindEvents=function(){var _this=this
this.$().bind("scroll mousewheel",function(event,delta,deltaX,deltaY){delta&&(event._delta={delta:delta,deltaX:deltaX,deltaY:deltaY})
return _this.handleEvent(event)})
return KDScrollView.__super__.bindEvents.apply(this,arguments)}
KDScrollView.prototype.hasScrollBars=function(){return this.getScrollHeight()>this.getHeight()}
KDScrollView.prototype.getScrollHeight=function(){return this.$()[0].scrollHeight}
KDScrollView.prototype.getScrollWidth=function(){return this.$()[0].scrollWidth}
KDScrollView.prototype.getScrollTop=function(){return this.$().scrollTop()}
KDScrollView.prototype.getScrollLeft=function(){return this.$().scrollLeft()}
KDScrollView.prototype.scrollTo=function(_arg,callback){var duration,left,top
top=_arg.top,left=_arg.left,duration=_arg.duration
top||(top=0)
left||(left=0)
duration||(duration=null)
if(duration)return this.$().animate({scrollTop:top,scrollLeft:left},duration,function(){return"function"==typeof callback?callback():void 0})
this.$().scrollTop(top)
this.$().scrollLeft(left)
return"function"==typeof callback?callback():void 0}
KDScrollView.prototype.scrollToSubView=function(subView){var subViewHeight,subViewRelTop,subViewTop,viewHeight,viewScrollTop,viewTop
viewTop=this.getY()
viewHeight=this.getHeight()
viewScrollTop=this.getScrollTop()
subViewTop=subView.getY()
subViewHeight=subView.getHeight()
subViewRelTop=subViewTop-viewTop+viewScrollTop
if(viewHeight>subViewTop-viewTop+subViewHeight&&subViewTop-viewTop>=0);else{if(0>subViewTop-viewTop)return this.scrollTo({top:subViewRelTop})
if(subViewTop-viewTop+subViewHeight>viewHeight)return this.scrollTo({top:subViewRelTop-viewHeight+subViewHeight})}}
KDScrollView.prototype.fractionOfHeightBelowFold=function(_arg){var scrollViewGlobalOffset,view,viewGlobalOffset,viewHeight,viewOffsetFromScrollView
view=_arg.view
viewHeight=view.getHeight()
viewGlobalOffset=view.$().offset().top
scrollViewGlobalOffset=this.$().offset().top
viewOffsetFromScrollView=viewGlobalOffset-scrollViewGlobalOffset
return(viewHeight+viewOffsetFromScrollView-this.getHeight())/this.getHeight()}
KDScrollView.prototype.mouseWheel=function(event){var direction
if($(event.target).attr("data-id")===this.getId()&&this.ownScrollBars){direction=event._delta.delta>0?"up":"down"
this._scrollUponVelocity(event._delta.delta,direction)
return!1}return KD.getSingleton("windowController").emit("ScrollHappened",this,event)}
KDScrollView.prototype._scrollUponVelocity=function(velocity,direction){var actInnerPosition,newInnerPosition,stepInPixels
log(direction,velocity,this.getScrollHeight())
stepInPixels=50*velocity
actInnerPosition=this.$().scrollTop()
newInnerPosition=stepInPixels+actInnerPosition
log(stepInPixels,actInnerPosition,newInnerPosition)
return this.$().scrollTop(newInnerPosition)}
KDScrollView.prototype._createScrollBars=function(){log("has-own-scrollbars")
this.setClass("has-own-scrollbars")
this.addSubView(this._vTrack=new KDView({cssClass:"kdscrolltrack ver",delegate:this}))
this._vTrack.setRandomBG()
this._vTrack.addSubView(this._vThumb=new KDScrollThumb({cssClass:"kdscrollthumb",type:"vertical",delegate:this._vTrack}))
this.scrollBarsCreated=!0
return this.ownScrollBars=!0}
return KDScrollView}(KDView)
KDScrollThumb=function(_super){function KDScrollThumb(options,data){options=$.extend({type:"vertical"},options)
KDScrollThumb.__super__.constructor.call(this,options,data)
this._track=this.getDelegate()
this._view=this._track.getDelegate()
this.on("viewAppended",this._calculateSize.bind(this))
this._view.on("scroll",this.bound("_calculatePosition"))}__extends(KDScrollThumb,_super)
KDScrollThumb.prototype.isDraggable=function(){return!0}
KDScrollThumb.prototype.dragOptions=function(){var dragOptions,o
o=this.getOptions()
dragOptions={drag:this._drag}
dragOptions.axis=(o.type="vertical")?"y":"x"
return dragOptions}
KDScrollThumb.prototype._drag=function(){return log("dragged")}
KDScrollThumb.prototype._setSize=function(size){var o
o=this.getOptions()
return(o.type="vertical")?this.setHeight(size):this.setWidth(size)}
KDScrollThumb.prototype._setOffset=function(offset){var o
o=this.getOptions()
return(o.type="vertical")?this.$().css({marginTop:offset}):this.$().css({marginLeft:offset})}
KDScrollThumb.prototype._calculateSize=function(){var o
o=this.getOptions()
if(o.type="vertical"){this._trackSize=this._view.getHeight()
this._scrollSize=this._view.getScrollHeight()
this._thumbMargin=this.getY()-this._track.getY()}else{this._scrollSize=this.parent.parent.getScrollWidth()
this._thumbMargin=this.getX()-this._track.getX()
this._trackSize=this.parent.getWidth()}log(this._trackSize,this._scrollSize)
this._trackSize>=this._scrollSize&&this._track.hide()
this._thumbRatio=this._trackSize/this._scrollSize
this._thumbSize=this._trackSize*this._thumbRatio-2*this._thumbMargin
return this._setSize(this._thumbSize)}
KDScrollThumb.prototype._calculatePosition=function(){var thumbTopOffset,viewScrollTop
viewScrollTop=this._view.$().scrollTop()
thumbTopOffset=viewScrollTop*this._thumbRatio+this._thumbMargin
return this._setOffset(thumbTopOffset)}
return KDScrollThumb}(KDView)

var KDRouter,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1},__slice=[].slice
KDRouter=function(_super){function KDRouter(routes){KDRouter.__super__.constructor.call(this)
this.tree={}
this.routes={}
this.visitedRoutes=[]
routes&&this.addRoutes(routes)}var createObjectRef,history,listenerKey,revive,routeWithoutEdgeAtIndex
__extends(KDRouter,_super)
history=window.history
listenerKey="ಠ_ಠ"
createObjectRef=function(obj){var _ref
return null!=(null!=obj?obj.bongo_:void 0)&&null!=obj.getId?{constructorName:null!=(_ref=obj.bongo_)?_ref.constructorName:void 0,id:obj.getId()}:void 0}
revive=function(objRef,callback){return null==(null!=objRef?objRef.constructorName:void 0)||null==objRef.id?callback(null):KD.remote.cacheable(objRef.constructorName,objRef.id,callback)}
KDRouter.prototype.listen=function(){var hashFragment,_this=this
if(location.hash.length){hashFragment=location.hash.substr(1)
this.userRoute=hashFragment
this.utils.defer(function(){return _this.handleRoute(hashFragment,{shouldPushState:!0,replaceState:!0})})}return this.startListening()}
KDRouter.prototype.popState=function(event){var _this=this
return revive(event.state,function(err,state){return err?KD.showError(err):_this.handleRoute(""+location.pathname+location.search,{shouldPushState:!1,state:state})})}
KDRouter.prototype.clear=function(route,replaceState){null==route&&(route="/")
null==replaceState&&(replaceState=!0)
delete this.userRoute
return this.handleRoute(route,{replaceState:replaceState})}
KDRouter.prototype.back=function(){return this.visitedRoutes.length<=1?this.clear():history.back()}
KDRouter.prototype.startListening=function(){if(this.isListening)return!1
this.isListening=!0
window.addEventListener("popstate",this.bound("popState"))
return!0}
KDRouter.prototype.stopListening=function(){if(!this.isListening)return!1
this.isListening=!1
window.removeEventListener("popstate",this.bound("popState"))
return!0}
KDRouter.handleNotFound=function(route){console.trace()
return log("The route "+route+" was not found!")}
KDRouter.prototype.getCurrentPath=function(){return this.currentPath}
KDRouter.prototype.handleNotFound=function(route){delete this.userRoute
this.clear()
log("The route "+route+" was not found!")
return new KDNotificationView({title:"404 Not found! "+route})}
routeWithoutEdgeAtIndex=function(route,i){return"/"+route.slice(0,i).concat(route.slice(i+1)).join("/")}
KDRouter.prototype.addRoute=function(route,listener){var edge,i,last,node,_i,_len
this.routes[route]=listener
node=this.tree
route=route.split("/")
route.shift()
for(i=_i=0,_len=route.length;_len>_i;i=++_i){edge=route[i]
last=edge.length-1
if("?"===edge.charAt(last)){this.addRoute(routeWithoutEdgeAtIndex(route,i),listener)
edge=edge.substr(0,last)}if(/^:/.test(edge)){node[":"]||(node[":"]={name:edge.substr(1)})
node=node[":"]}else{node[edge]||(node[edge]={})
node=node[edge]}}node[listenerKey]||(node[listenerKey]=[])
return __indexOf.call(node[listenerKey],listener)<0?node[listenerKey].push(listener):void 0}
KDRouter.prototype.addRoutes=function(routes){var listener,route,_results
_results=[]
for(route in routes)if(__hasProp.call(routes,route)){listener=routes[route]
_results.push(this.addRoute(route,listener))}return _results}
KDRouter.prototype.handleRoute=function(userRoute,options){var edge,frag,listener,listeners,method,node,objRef,param,params,path,qs,query,replaceState,routeInfo,shouldPushState,state,suppressListeners,_i,_j,_len,_len1,_ref,_ref1
null==options&&(options={})
0===userRoute.indexOf("!")&&(userRoute=userRoute.slice(1))
this.visitedRoutes.push(userRoute)
_ref1=(null!=(_ref=null!=userRoute?userRoute:"function"==typeof this.getDefaultRoute?this.getDefaultRoute():void 0)?_ref:"/").split("?"),frag=_ref1[0],query=2<=_ref1.length?__slice.call(_ref1,1):[]
query=this.utils.parseQuery(query.join("&"))
shouldPushState=options.shouldPushState,replaceState=options.replaceState,state=options.state,suppressListeners=options.suppressListeners
null==shouldPushState&&(shouldPushState=!0)
objRef=createObjectRef(state)
node=this.tree
params={}
frag=frag.split("/")
frag.shift()
frag=frag.filter(Boolean)
path="/"+frag.join("/")
qs=this.utils.stringifyQuery(query)
qs.length&&(path+="?"+qs)
if(suppressListeners||!shouldPushState||replaceState||path!==this.currentPath){this.currentPath=path
if(shouldPushState){method=replaceState?"replaceState":"pushState"
history[method](objRef,path,path)}for(_i=0,_len=frag.length;_len>_i;_i++){edge=frag[_i]
if(node[edge])node=node[edge]
else{param=node[":"]
if(null!=param){params[param.name]=edge
node=param}else this.handleNotFound(frag.join("/"))}}routeInfo={params:params,query:query}
this.emit("Params",{params:params,query:query})
if(!suppressListeners){listeners=node[listenerKey]
if(null!=listeners?listeners.length:void 0)for(_j=0,_len1=listeners.length;_len1>_j;_j++){listener=listeners[_j]
listener.call(this,routeInfo,state,path)}}return this}this.emit("AlreadyHere",path)}
KDRouter.prototype.handleQuery=function(query){var nextRoute
"string"!=typeof query&&(query=this.utils.stringifyQuery(query))
if(query.length){nextRoute=""+this.currentPath+"?"+query
return this.handleRoute(nextRoute)}}
return KDRouter}(KDObject)

var KDController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDController=function(_super){function KDController(){_ref=KDController.__super__.constructor.apply(this,arguments)
return _ref}__extends(KDController,_super)
return KDController}(KDObject)

var KDWindowController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDWindowController=function(_super){function KDWindowController(options,data){this.windowResizeListeners={}
this.keyEventsToBeListened=["keydown","keyup","keypress"]
this.currentCombos={}
this.keyView=null
this.dragView=null
this.scrollingEnabled=!0
this.layers=[]
this.unloadListeners={}
this.focusListeners=[]
this.bindEvents()
this.setWindowProperties()
KDWindowController.__super__.constructor.call(this,options,data)}var addListener,getVisibilityEventName,getVisibilityProperty,superKey,superizeCombos
__extends(KDWindowController,_super)
KDWindowController.keyViewHistory=[]
superKey=-1===navigator.userAgent.indexOf("Mac OS X")?"ctrl":"command"
addListener=function(eventName,listener,capturePhase){null==capturePhase&&(capturePhase=!0)
return document.body.addEventListener(eventName,listener,capturePhase)}
getVisibilityProperty=function(){var prefix,prefixes,_i,_len
prefixes=["webkit","moz","o"]
if("hidden"in document)return"hidden"
for(_i=0,_len=prefixes.length;_len>_i;_i++){prefix=prefixes[_i]
if(prefix+"Hidden"in document)return""+prefix+"Hidden"}return""}
getVisibilityEventName=function(){return""+getVisibilityProperty().replace(/[Hh]idden/,"")+"visibilitychange"}
KDWindowController.prototype.addLayer=function(layer){var _this=this
if(__indexOf.call(this.layers,layer)<0){this.layers.push(layer)
return layer.on("KDObjectWillBeDestroyed",function(){return _this.removeLayer(layer)})}}
KDWindowController.prototype.removeLayer=function(layer){var index
if(__indexOf.call(this.layers,layer)>=0){index=this.layers.indexOf(layer)
return this.layers.splice(index,1)}}
KDWindowController.prototype.bindEvents=function(){var documentBody,layers,timer,_this=this
$(window).bind(this.keyEventsToBeListened.join(" "),this.bound("key"))
$(window).bind("resize",function(event){_this.setWindowProperties(event)
return _this.notifyWindowResizeListeners(event)})
timer=null
documentBody=document.body
document.onscroll=function(){clearTimeout(timer)
document.body.classList.contains("onscroll")||documentBody.classList.add("onscroll")
return timer=KD.utils.wait(200,function(){return documentBody.classList.remove("onscroll")})}
addListener("dragenter",function(event){if(!_this.dragInAction){_this.emit("DragEnterOnWindow",event)
return _this.setDragInAction(!0)}})
addListener("dragleave",function(event){var _ref,_ref1
if(!(0<(_ref=event.clientX)&&_ref<_this.winWidth&&0<(_ref1=event.clientY)&&_ref1<_this.winHeight)){_this.emit("DragExitOnWindow",event)
return _this.setDragInAction(!1)}})
addListener("drop",function(event){_this.emit("DragExitOnWindow",event)
_this.emit("DropOnWindow",event)
return _this.setDragInAction(!1)})
layers=this.layers
addListener("mousedown",function(e){var lastLayer
lastLayer=layers.last
if(lastLayer&&0===$(e.target).closest(null!=lastLayer?lastLayer.$():void 0).length){lastLayer.emit("ReceivedClickElsewhere",e)
return _this.removeLayer(lastLayer)}})
addListener("mouseup",function(e){_this.dragView&&_this.unsetDragView(e)
return _this.emit("ReceivedMouseUpElsewhere",e)})
addListener("mousemove",function(e){return _this.dragView?_this.redirectMouseMoveEvent(e):void 0})
addListener("click",function(e){var href,isHttp,isInternalLink,_ref,_ref1
isInternalLink="a"===(null!=(_ref=e.target)?_ref.nodeName.toLowerCase():void 0)&&0===(null!=(_ref1=e.target.target)?_ref1.length:void 0)
if(isInternalLink){href=e.target.getAttribute("href")
isHttp=0===(null!=href?href.indexOf("http"):void 0)
if(isHttp)return e.target.target="_blank"
e.preventDefault()
if(href&&!/^#/.test(href))return KD.getSingleton("router").handleRoute(href)}})
"localhost"!==location.hostname&&window.addEventListener("beforeunload",this.bound("beforeUnload"))
return document.addEventListener(getVisibilityEventName(),function(event){return _this.focusChange(event,_this.isFocused())})}
KDWindowController.prototype.addUnloadListener=function(key,listener){var _base;(_base=this.unloadListeners)[key]||(_base[key]=[])
return this.unloadListeners[key].push(listener)}
KDWindowController.prototype.clearUnloadListeners=function(key){return key?this.unloadListeners[key]=[]:this.unloadListeners={}}
KDWindowController.prototype.isFocused=function(){return!Boolean(document[getVisibilityProperty()])}
KDWindowController.prototype.addFocusListener=function(listener){return this.focusListeners.push(listener)}
KDWindowController.prototype.focusChange=function(event,state){var listener,_i,_len,_ref,_results
if(event){_ref=this.focusListeners
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){listener=_ref[_i]
_results.push(listener(state,event))}return _results}}
KDWindowController.prototype.beforeUnload=function(event){var key,listener,listeners,message,_i,_len,_ref
if(event){_ref=this.unloadListeners
for(key in _ref)if(__hasProp.call(_ref,key)){listeners=_ref[key]
for(_i=0,_len=listeners.length;_len>_i;_i++){listener=listeners[_i]
if(listener()===!1){message="window"!==key?" on "+key:""
return"Please make sure that you saved all your work"+message+"."}}}}}
KDWindowController.prototype.setDragInAction=function(dragInAction){this.dragInAction=null!=dragInAction?dragInAction:!1
return $("body")[this.dragInAction?"addClass":"removeClass"]("dragInAction")}
KDWindowController.prototype.setMainView=function(mainView){this.mainView=mainView}
KDWindowController.prototype.getMainView=function(){return this.mainView}
KDWindowController.prototype.revertKeyView=function(view){if(view)return view===this.keyView&&this.keyView!==this.oldKeyView?this.setKeyView(this.oldKeyView):void 0
warn("you must pass the view as a param, which doesn't want to be keyview anymore!")
return void 0}
superizeCombos=function(combos){var cb,combo,safeCombos
safeCombos={}
for(combo in combos)if(__hasProp.call(combos,combo)){cb=combos[combo];/\bsuper(\+|\s)/.test(combo)&&(combo=combo.replace(/super/g,superKey))
safeCombos[combo]=cb}return safeCombos}
KDWindowController.prototype.viewHasKeyCombos=function(view){var cb,combo,combos,e,o,_i,_len,_ref,_ref1
if(view){o=view.getOptions()
combos={}
_ref=this.keyEventsToBeListened
for(_i=0,_len=_ref.length;_len>_i;_i++){e=_ref[_i]
if("object"==typeof o[e]){_ref1=o[e]
for(combo in _ref1)if(__hasProp.call(_ref1,combo)){cb=_ref1[combo]
combos[combo]=cb}}}return Object.keys(combos).length>0?combos:!1}}
KDWindowController.prototype.registerKeyCombos=function(view){var cb,combo,combos,_ref,_results
if(combos=this.viewHasKeyCombos(view)){view.setClass("mousetrap")
this.currentCombos=superizeCombos(combos)
_ref=this.currentCombos
_results=[]
for(combo in _ref)if(__hasProp.call(_ref,combo)){cb=_ref[combo]
_results.push(Mousetrap.bind(combo,cb,"keydown"))}return _results}}
KDWindowController.prototype.unregisterKeyCombos=function(){this.currentCombos={}
Mousetrap.reset()
return this.keyView?this.keyView.unsetClass("mousetrap"):void 0}
KDWindowController.prototype.setKeyView=function(newKeyView){if(newKeyView!==this.keyView){this.unregisterKeyCombos()
this.oldKeyView=this.keyView
this.keyView=newKeyView
this.registerKeyCombos(newKeyView)
this.constructor.keyViewHistory.push(newKeyView)
null!=newKeyView&&newKeyView.emit("KDViewBecameKeyView")
return this.emit("WindowChangeKeyView",newKeyView)}}
KDWindowController.prototype.setDragView=function(dragView){this.setDragInAction(!0)
return this.dragView=dragView}
KDWindowController.prototype.unsetDragView=function(e){this.setDragInAction(!1)
this.dragView.emit("DragFinished",e)
return this.dragView=null}
KDWindowController.prototype.redirectMouseMoveEvent=function(event){var delta,initial,initialX,initialY,pageX,pageY,view
view=this.dragView
pageX=event.pageX,pageY=event.pageY
initial=view.dragState.position.initial
initialX=initial.x
initialY=initial.y
delta={x:pageX-initialX,y:pageY-initialY}
return view.drag(event,delta)}
KDWindowController.prototype.getKeyView=function(){return this.keyView}
KDWindowController.prototype.key=function(event){var _ref
this.emit(event.type,event)
return null!=(_ref=this.keyView)?_ref.handleEvent(event):void 0}
KDWindowController.prototype.enableScroll=function(){return this.scrollingEnabled=!0}
KDWindowController.prototype.disableScroll=function(){return this.scrollingEnabled=!1}
KDWindowController.prototype.registerWindowResizeListener=function(instance){var _this=this
this.windowResizeListeners[instance.id]=instance
return instance.on("KDObjectWillBeDestroyed",function(){return delete _this.windowResizeListeners[instance.id]})}
KDWindowController.prototype.unregisterWindowResizeListener=function(instance){return delete this.windowResizeListeners[instance.id]}
KDWindowController.prototype.setWindowProperties=function(){this.winWidth=window.innerWidth
return this.winHeight=window.innerHeight}
KDWindowController.prototype.notifyWindowResizeListeners=function(event,throttle,duration){var fireResizeHandlers,_this=this
null==throttle&&(throttle=!1)
null==duration&&(duration=17)
event||(event={type:"resize"})
fireResizeHandlers=function(){var instance,key,_ref,_results
_ref=_this.windowResizeListeners
_results=[]
for(key in _ref)if(__hasProp.call(_ref,key)){instance=_ref[key]
instance._windowDidResize&&_results.push(instance._windowDidResize(event))}return _results}
if(throttle){KD.utils.killWait(this.resizeNotifiersTimer)
return this.resizeNotifiersTimer=KD.utils.wait(duration,fireResizeHandlers)}return fireResizeHandlers()}
return KDWindowController}(KDController)

var KDViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDViewController=function(_super){function KDViewController(options,data){null==options&&(options={})
options.view||(options.view=new KDView)
KDViewController.__super__.constructor.call(this,options,data)
this.getOptions().view&&this.setView(this.getOptions().view)}__extends(KDViewController,_super)
KDViewController.prototype.loadView=function(){}
KDViewController.prototype.getView=function(){return this.mainView}
KDViewController.prototype.setView=function(aViewInstance){var cb,_this=this
this.mainView=aViewInstance
this.emit("ControllerHasSetItsView")
cb=this.loadView.bind(this,aViewInstance)
if(aViewInstance.isViewReady())return cb()
aViewInstance.once("viewAppended",cb)
return aViewInstance.once("KDObjectWillBeDestroyed",function(){return KD.utils.defer(_this.bound("destroy"))})}
return KDViewController}(KDController)

var KDSplitView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSplitView=function(_super){function KDSplitView(options,data){null==options&&(options={})
options.type||(options.type="vertical")
null==options.resizable&&(options.resizable=!0)
options.sizes||(options.sizes=["50%","50%"])
options.minimums||(options.minimums=null)
options.maximums||(options.maximums=null)
options.views||(options.views=null)
options.fixed||(options.fixed=[])
options.duration||(options.duration=200)
options.separator||(options.separator=null)
null==options.colored&&(options.colored=!1)
null==options.animated&&(options.animated=!0)
options.type=options.type.toLowerCase()
KDSplitView.__super__.constructor.call(this,options,data)
this.setClass("kdsplitview kdsplitview-"+this.getOptions().type+" "+this.getOptions().cssClass)
this.panels=[]
this.panelsBounds=[]
this.resizers=[]
this.sizes=[]}__extends(KDSplitView,_super)
KDSplitView.prototype.viewAppended=function(){this._sanitizeSizes()
this._createPanels()
this._calculatePanelBounds()
this._putPanels()
this._setPanelPositions()
this._putViews()
this.getOptions().resizable&&this.panels.length&&this._createResizers()
return this.listenWindowResize()}
KDSplitView.prototype._createPanels=function(){var i,panelCount
panelCount=this.getOptions().sizes.length
return this.panels=function(){var _i,_results
_results=[]
for(i=_i=0;panelCount>=0?panelCount>_i:_i>panelCount;i=panelCount>=0?++_i:--_i)_results.push(this._createPanel(i))
return _results}.call(this)}
KDSplitView.prototype._createPanel=function(index){var fixed,maximums,minimums,panel,type,_ref,_this=this
_ref=this.getOptions(),type=_ref.type,fixed=_ref.fixed,minimums=_ref.minimums,maximums=_ref.maximums
panel=new KDSplitViewPanel({cssClass:"kdsplitview-panel panel-"+index,index:index,type:type,size:this._sanitizeSize(this.sizes[index]),fixed:fixed[index]?!0:void 0,minimum:minimums?this._sanitizeSize(minimums[index]):void 0,maximum:maximums?this._sanitizeSize(maximums[index]):void 0})
panel.on("KDObjectWillBeDestroyed",function(){return _this._panelIsBeingDestroyed(panel)})
this.emit("SplitPanelCreated",panel)
return panel}
KDSplitView.prototype._calculatePanelBounds=function(){var i,offset,prevSize,size
return this.panelsBounds=function(){var _i,_j,_len,_ref,_results
_ref=this.sizes
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){size=_ref[i]
if(0===i)_results.push(0)
else{offset=0
for(prevSize=_j=0;i>=0?i>_j:_j>i;prevSize=i>=0?++_j:--_j)offset+=this.sizes[prevSize]
_results.push(offset)}}return _results}.call(this)}
KDSplitView.prototype._putPanels=function(){var panel,_i,_len,_ref,_results
_ref=this.panels
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){panel=_ref[_i]
this.addSubView(panel)
this.getOptions().colored?_results.push(panel.$().css({backgroundColor:__utils.getRandomRGB()})):_results.push(void 0)}return _results}
KDSplitView.prototype._setPanelPositions=function(){var i,panel,_i,_len,_ref
_ref=this.panels
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){panel=_ref[i]
panel._setSize(this.sizes[i])
panel._setOffset(this.panelsBounds[i])}return!1}
KDSplitView.prototype._panelIsBeingDestroyed=function(panel){var index,o
index=this.getPanelIndex(panel)
o=this.getOptions()
this.panels=this.panels.slice(0,index).concat(this.panels.slice(index+1))
this.sizes=this.sizes.slice(0,index).concat(this.sizes.slice(index+1))
this.panelsBounds=this.panelsBounds.slice(0,index).concat(this.panelsBounds.slice(index+1))
o.minimums.splice(index,1)
o.maximums.splice(index,1)
return null!=o.views[index]?o.views.splice(index,1):void 0}
KDSplitView.prototype._createResizers=function(){var i
this.resizers=function(){var _i,_ref,_results
_results=[]
for(i=_i=1,_ref=this.sizes.length;_ref>=1?_ref>_i:_i>_ref;i=_ref>=1?++_i:--_i)_results.push(this._createResizer(i))
return _results}.call(this)
return this._repositionResizers()}
KDSplitView.prototype._createResizer=function(index){var resizer
this.addSubView(resizer=new KDSplitResizer({cssClass:"kdsplitview-resizer "+this.getOptions().type,type:this.getOptions().type,panel0:this.panels[index-1],panel1:this.panels[index]}))
return resizer}
KDSplitView.prototype._repositionResizers=function(){var i,resizer,_i,_len,_ref,_results
_ref=this.resizers
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){resizer=_ref[i]
_results.push(resizer._setOffset(this.panelsBounds[i+1]))}return _results}
KDSplitView.prototype._putViews=function(){var i,view,_base,_i,_len,_ref,_results
null==(_base=this.getOptions()).views&&(_base.views=[])
_ref=this.getOptions().views
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){view=_ref[i]
view instanceof KDView?_results.push(this.setView(view,i)):_results.push(void 0)}return _results}
KDSplitView.prototype._sanitizeSizes=function(){var i,newSizes,nullCount,nullSize,o,panelSize,size,splitSize,totalOccupied
this._setMinsAndMaxs()
o=this.getOptions()
nullCount=0
totalOccupied=0
splitSize=this._getSize()
newSizes=function(){var _i,_len,_ref,_results
_ref=o.sizes
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){size=_ref[i]
if(null===size){nullCount++
_results.push(null)}else{panelSize=this._sanitizeSize(size)
this._getLegitPanelSize(size,i)
totalOccupied+=panelSize
_results.push(panelSize)}}return _results}.call(this)
this.sizes=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=newSizes.length;_len>_i;_i++){size=newSizes[_i]
if(null===size){nullSize=(splitSize-totalOccupied)/nullCount
_results.push(Math.round(nullSize))}else _results.push(Math.round(size))}return _results}()
return this.sizes}
KDSplitView.prototype._sanitizeSize=function(size){var splitSize
if("number"==typeof size||/px$/.test(size))return parseInt(size,10)
if(/%$/.test(size)){splitSize=this._getSize()
return splitSize/100*parseInt(size,10)}}
KDSplitView.prototype._setMinsAndMaxs=function(){var i,panelAmount,_base,_base1,_i,_results
null==(_base=this.getOptions()).minimums&&(_base.minimums=[])
null==(_base1=this.getOptions()).maximums&&(_base1.maximums=[])
panelAmount=this.getOptions().sizes.length||2
_results=[]
for(i=_i=0;panelAmount>=0?panelAmount>_i:_i>panelAmount;i=panelAmount>=0?++_i:--_i){this.getOptions().minimums[i]=this.getOptions().minimums[i]?this._sanitizeSize(this.getOptions().minimums[i]):-1
_results.push(this.getOptions().maximums[i]=this.getOptions().maximums[i]?this._sanitizeSize(this.getOptions().maximums[i]):99999)}return _results}
KDSplitView.prototype._getSize=function(){return"vertical"===this.getOptions().type?this.getWidth():this.getHeight()}
KDSplitView.prototype._setSize=function(size){return"vertical"===this.getOptions().type?this.setWidth(size):this.setHeight(size)}
KDSplitView.prototype._getParentSize=function(){var $parent,type
type=this.getOptions().type
$parent=this.$().parent()
return"vertical"===type?$parent.width():$parent.height()}
KDSplitView.prototype._getLegitPanelSize=function(size,index){return size=this.getOptions().minimums[index]>size?this.getOptions().minimums[index]:this.getOptions().maximums[index]<size?this.getOptions().maximums[index]:size}
KDSplitView.prototype._resizePanels=function(){return this._sanitizeSizes()}
KDSplitView.prototype._repositionPanels=function(){this._calculatePanelBounds()
return this._setPanelPositions()}
KDSplitView.prototype._windowDidResize=function(){this._setSize(this._getParentSize())
this._resizePanels()
this._repositionPanels()
this._setPanelPositions()
return this.getOptions().resizable?this._repositionResizers():void 0}
KDSplitView.prototype.mouseUp=function(event){this.$().unbind("mousemove.resizeHandle")
return this._resizeDidStop(event)}
KDSplitView.prototype._panelReachedMinimum=function(panelIndex){this.panels[panelIndex].emit("PanelReachedMinimum")
return this.emit("PanelReachedMinimum",{panel:this.panels[panelIndex]})}
KDSplitView.prototype._panelReachedMaximum=function(panelIndex){this.panels[panelIndex].emit("PanelReachedMaximum")
return this.emit("PanelReachedMaximum",{panel:this.panels[panelIndex]})}
KDSplitView.prototype._resizeDidStart=function(event){$("body").addClass("resize-in-action")
return this.emit("ResizeDidStart",{orgEvent:event})}
KDSplitView.prototype._resizeDidStop=function(event){this.emit("ResizeDidStop",{orgEvent:event})
return this.utils.wait(300,function(){return $("body").removeClass("resize-in-action")})}
KDSplitView.prototype.isVertical=function(){return"vertical"===this.getOptions().type}
KDSplitView.prototype.getPanelIndex=function(panel){var i,p,_i,_len,_ref
_ref=this.panels
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){p=_ref[i]
if(p.getId()===panel.getId())return i}}
KDSplitView.prototype.hidePanel=function(panelIndex,callback){var panel,_this=this
null==callback&&(callback=noop)
panel=this.panels[panelIndex]
panel._lastSize=panel._getSize()
return this.resizePanel(0,panelIndex,function(){return callback.call(_this,{panel:panel,index:panelIndex})})}
KDSplitView.prototype.showPanel=function(panelIndex,callback){var newSize,panel
null==callback&&(callback=noop)
panel=this.panels[panelIndex]
newSize=panel._lastSize||this.getOptions().sizes[panelIndex]||200
panel._lastSize=null
return this.resizePanel(newSize,panelIndex,function(){return callback.call(this,{panel:panel,index:panelIndex})})}
KDSplitView.prototype.resizePanel=function(value,panelIndex,callback){var isReverse,p0offset,p0size,p1index,p1newSize,p1offset,p1size,panel0,panel1,race,raceCounter,resizer,surplus,totalActionArea,_this=this
null==value&&(value=0)
null==panelIndex&&(panelIndex=0)
null==callback&&(callback=noop)
this._resizeDidStart()
value=this._sanitizeSize(value)
panel0=this.panels[panelIndex]
isReverse=!1
if(panel0.size!==value){panel1=this.panels.length-1!==panelIndex?(p1index=panelIndex+1,this.getOptions().resizable?resizer=this.resizers[panelIndex]:void 0,this.panels[p1index]):(isReverse=!0,p1index=panelIndex-1,this.getOptions().resizable?resizer=this.resizers[p1index]:void 0,this.panels[p1index])
totalActionArea=panel0.size+panel1.size
if(value>totalActionArea)return!1
p0size=this._getLegitPanelSize(value,panelIndex)
surplus=panel0.size-p0size
p1newSize=panel1.size+surplus
p1size=this._getLegitPanelSize(p1newSize,p1index)
raceCounter=0
race=function(){raceCounter++
if(2===raceCounter){_this._resizeDidStop()
return callback()}}
if(isReverse){p0offset=panel0._getOffset()+surplus
if(this.getOptions().animated){panel0._animateTo(p0size,p0offset,race)
panel1._animateTo(p1size,race)
if(resizer)return resizer._animateTo(p0offset)}else{panel0._setSize(p0size)
panel0._setOffset(p0offset)
race()
panel1._setSize(p1size)
race()
if(resizer)return resizer._setOffset(p0offset)}}else{p1offset=panel1._getOffset()-surplus
if(this.getOptions().animated){panel0._animateTo(p0size,race)
panel1._animateTo(p1size,p1offset,race)
if(resizer)return resizer._animateTo(p1offset)}else{panel0._setSize(p0size)
race()
panel1._setSize(p1size,panel1._setOffset(p1offset))
race()
if(resizer)return resizer._setOffset(p1offset)}}}else{this._resizeDidStop()
callback()}}
KDSplitView.prototype.splitPanel=function(index){var i,isLastPanel,newIndex,newPanel,newPanelOptions,newResizer,newSize,o,oldResizer,panel,panelToBeSplitted,_i,_len,_ref
newPanelOptions={}
o=this.getOptions()
isLastPanel=this.resizers[index]?!1:!0
panelToBeSplitted=this.panels[index]
this.panels.splice(index+1,0,newPanel=this._createPanel(index))
this.sizes.splice(index+1,0,this.sizes[index]/2)
this.sizes[index]=this.sizes[index]/2
o.minimums.splice(index+1,0,newPanelOptions.minimum)
o.maximums.splice(index+1,0,newPanelOptions.maximum)
o.views.splice(index+1,0,newPanelOptions.view)
o.sizes=this.sizes
this.subViews.push(newPanel)
newPanel.setParent(this)
panelToBeSplitted.$().after(newPanel.$())
newPanel.emit("viewAppended")
newSize=panelToBeSplitted._getSize()/2
panelToBeSplitted._setSize(newSize)
newPanel._setSize(newSize)
newPanel._setOffset(panelToBeSplitted._getOffset()+newSize)
this._calculatePanelBounds()
_ref=this.panels.slice(index+1,this.panels.length)
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){panel=_ref[i]
panel.index=newIndex=index+1+i
panel.unsetClass("panel-"+(index+i)).setClass("panel-"+newIndex)}if(this.getOptions().resizable)if(isLastPanel){this.resizers.push(newResizer=this._createResizer(index+1))
newResizer._setOffset(this.panelsBounds[index+1])}else{oldResizer=this.resizers[index]
oldResizer._setOffset(this.panelsBounds[index+1])
oldResizer.panel0=panelToBeSplitted
oldResizer.panel1=newPanel
this.resizers.splice(index+1,0,newResizer=this._createResizer(index+2))
newResizer._setOffset(this.panelsBounds[index+2])}this.emit("panelSplitted",newPanel)
return newPanel}
KDSplitView.prototype.removePanel=function(index){var l,panel,r,res
l=this.panels.length
if(1===l){warn("this is the only panel left")
return!1}panel=this.panels[index]
panel.destroy()
if(0===index){r=this.resizers.shift()
r.destroy()
if(res=this.resizers[0]){res.panel0=this.panels[0]
res.panel1=this.panels[1]}}else if(index===l-1){r=this.resizers.pop()
r.destroy()
if(res=this.resizers[l-2]){res.panel0=this.panels[l-2]
res.panel1=this.panels[l-1]}}else{r=this.resizers.splice(index-1,1)[0]
r.destroy()
this.resizers[index-1].panel0=this.panels[index-1]
this.resizers[index-1].panel1=this.panels[index]}return!0}
KDSplitView.prototype.setView=function(view,index){if(!(index>this.panels.length)&&view)return this.panels[index].addSubView(view)
warn("Either 'view' or 'index' is missing at KDSplitView::setView!")
return void 0}
return KDSplitView}(KDView)

var KDSplitResizer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSplitResizer=function(_super){function KDSplitResizer(options,data){var axis,_ref
null==options&&(options={})
this.isVertical="vertical"===options.type.toLowerCase()
axis=this.isVertical?"x":"y"
null==options.draggable&&(options.draggable={axis:axis})
KDSplitResizer.__super__.constructor.call(this,options,data)
_ref=this.getOptions(),this.panel0=_ref.panel0,this.panel1=_ref.panel1
this.on("DragFinished",this.dragFinished)
this.on("DragInAction",this.dragInAction)
this.on("DragStarted",this.dragStarted)}__extends(KDSplitResizer,_super)
KDSplitResizer.prototype._setOffset=function(offset){0>offset&&(offset=0)
return this.isVertical?this.$().css({left:offset-5}):this.$().css({top:offset-5})}
KDSplitResizer.prototype._getOffset=function(){return this.isVertical?this.getRelativeX():this.getRelativeY()}
KDSplitResizer.prototype._animateTo=function(offset){var d
d=this.parent.options.duration
if(this.isVertical){offset-=this.getWidth()/2
return this.$().animate({left:offset},d)}offset-=this.getHeight()/2
return this.$().animate({top:offset},d)}
KDSplitResizer.prototype.dragFinished=function(event){return this.parent._resizeDidStop(event)}
KDSplitResizer.prototype.dragStarted=function(){this.parent._resizeDidStart()
this.rOffset=this._getOffset()
this.p0Size=this.panel0._getSize()
this.p1Size=this.panel1._getSize()
return this.p1Offset=this.panel1._getOffset()}
KDSplitResizer.prototype.dragInAction=function(x,y){var p0DidResize,p0WouldResize,p1DidResize,p1WouldResize
if(this.isVertical){p0WouldResize=this.panel0._wouldResize(x+this.p0Size)
p0WouldResize&&(p1WouldResize=this.panel1._wouldResize(-x+this.p1Size))
this.dragIsAllowed=p1WouldResize?(this.panel0._setSize(x+this.p0Size),this.panel1._setSize(-x+this.p1Size),!0):(this._setOffset(this.panel1._getOffset()),!1)
if(this.dragIsAllowed)return this.panel1._setOffset(x+this.p1Offset)}else{p0WouldResize=this.panel0._wouldResize(y+this.p0Size)
p1WouldResize=this.panel1._wouldResize(-y+this.p1Size)
p0DidResize=p0WouldResize&&p1WouldResize?this.panel0._setSize(y+this.p0Size):!1
p1DidResize=p0WouldResize&&p1WouldResize?this.panel1._setSize(-y+this.p1Size):!1
if(p0DidResize&&p1DidResize)return this.panel1._setOffset(y+this.p1Offset)}}
return KDSplitResizer}(KDView)

var KDSplitViewPanel,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSplitViewPanel=function(_super){function KDSplitViewPanel(options,data){var _ref
null==options&&(options={})
null==options.fixed&&(options.fixed=!1)
options.minimum||(options.minimum=null)
options.maximum||(options.maximum=null)
options.view||(options.view=null)
KDSplitViewPanel.__super__.constructor.call(this,options,data)
this.isVertical="vertical"===this.getOptions().type.toLowerCase()
this.isFixed=this.getOptions().fixed
_ref=this.options,this.size=_ref.size,this.minimum=_ref.minimum,this.maximum=_ref.maximum}__extends(KDSplitViewPanel,_super)
KDSplitViewPanel.prototype._getIndex=function(){return this.parent.getPanelIndex(this)}
KDSplitViewPanel.prototype._getSize=function(){return this.isVertical?this.getWidth():this.getHeight()}
KDSplitViewPanel.prototype._setSize=function(size){if(this._wouldResize(size)){0>size&&(size=0)
this.isVertical?this.setWidth(size):this.setHeight(size)
this.parent.sizes[this._getIndex()]=this.size=size
this.parent.emit("PanelDidResize",{panel:this})
this.emit("PanelDidResize",{newSize:size})
return size}return!1}
KDSplitViewPanel.prototype._wouldResize=function(size){null==this.minimum&&(this.minimum=-1)
null==this.maximum&&(this.maximum=99999)
if(size>this.minimum&&size<this.maximum)return!0
size<this.minimum?this.parent._panelReachedMinimum(this._getIndex()):size>this.maximum&&this.parent._panelReachedMaximum(this._getIndex())
return!1}
KDSplitViewPanel.prototype._setOffset=function(offset){0>offset&&(offset=0)
this.isVertical?this.$().css({left:offset}):this.$().css({top:offset})
return this.parent.panelsBounds[this._getIndex()]=offset}
KDSplitViewPanel.prototype._getOffset=function(){return this.isVertical?this.getRelativeX():this.getRelativeY()}
KDSplitViewPanel.prototype._animateTo=function(size,offset,callback){var cb,d,options,panel,properties
"undefined"==typeof callback&&"function"==typeof offset&&(callback=offset)
callback||(callback=noop)
panel=this
d=panel.parent.options.duration
cb=function(){var newSize
newSize=panel._getSize()
panel.parent.sizes[panel.index]=panel.size=newSize
panel.parent.emit("PanelDidResize",{panel:panel})
panel.emit("PanelDidResize",{newSize:newSize})
return callback.call(panel)}
properties={}
0>size&&(size=0)
if(panel.isVertical){properties.width=size
null!=offset&&(properties.left=offset)}else{properties.height=size
null!=offset&&(properties.top=offset)}options={duration:d,complete:cb}
panel.$().stop()
return panel.$().animate(properties,options)}
return KDSplitViewPanel}(KDScrollView)

var KDSplitComboView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSplitComboView=function(_super){function KDSplitComboView(options,data){null==options&&(options={})
options.cssClass||(options.cssClass="kdsplitcomboview")
KDSplitComboView.__super__.constructor.call(this,options,data)
this.init(options)}__extends(KDSplitComboView,_super)
KDSplitComboView.prototype.init=function(options){return this.addSubView(this.createSplitView(options.direction,options.sizes,options.views))}
KDSplitComboView.prototype.createSplitView=function(type,sizes,viewsConfig){var config,index,options,views,_i,_len
views=[]
for(index=_i=0,_len=viewsConfig.length;_len>_i;index=++_i){config=viewsConfig[index]
if("split"===config.type){options=config.options
views.push(this.createSplitView(options.direction,options.sizes,config.views))}else views.push(config)}return new KDSplitView({type:type,sizes:sizes,views:views})}
return KDSplitComboView}(KDView)

var KDHeaderView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDHeaderView=function(_super){function KDHeaderView(options,data){var _ref
options=null!=options?options:{}
options.type=null!=(_ref=options.type)?_ref:"default"
KDHeaderView.__super__.constructor.call(this,options,data)
null!=options.title&&(this.lazy?this.updateTitle(options.title):this.setTitle(options.title))}__extends(KDHeaderView,_super)
KDHeaderView.prototype.setTitle=function(title){return this.getDomElement().append("<span>"+title+"</span>")}
KDHeaderView.prototype.updateTitle=function(title){return this.$().find("span").html(title)}
KDHeaderView.prototype.setDomElement=function(cssClass){var type
null==cssClass&&(cssClass="")
type=this.getOptions().type
this.setOption("tagName",function(){switch(type){case"big":return"h1"
case"medium":return"h2"
case"small":return"h3"
default:return"h4"}}())
return KDHeaderView.__super__.setDomElement.call(this,this.utils.curry("kdheaderview",cssClass))}
return KDHeaderView}(KDView)

var KDLoaderView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDLoaderView=function(_super){function KDLoaderView(options,data){var o
o=options||{}
o.loaderOptions||(o.loaderOptions={})
o.size||(o.size={})
options={tagName:o.tagName||"span",bind:o.bind||"mouseenter mouseleave",showLoader:o.showLoader||!1,size:{width:o.size.width||12,height:o.size.height||12},loaderOptions:{color:o.loaderOptions.color||"#000000",shape:o.loaderOptions.shape||"rect",diameter:o.loaderOptions.diameter||20,density:o.loaderOptions.density||12,range:o.loaderOptions.range||1,speed:o.loaderOptions.speed||1,FPS:o.loaderOptions.FPS||24}}
options.loaderOptions.diameter=options.size.height=options.size.width
options.cssClass=o.cssClass?""+o.cssClass+" kdloader":"kdloader"
KDLoaderView.__super__.constructor.call(this,options,data)}__extends(KDLoaderView,_super)
KDLoaderView.prototype.viewAppended=function(){var loaderOptions,option,showLoader,value,_ref
this.canvas=new CanvasLoader(this.getElement(),{id:"cl_"+this.id})
_ref=this.getOptions(),loaderOptions=_ref.loaderOptions,showLoader=_ref.showLoader
for(option in loaderOptions)if(__hasProp.call(loaderOptions,option)){value=loaderOptions[option]
this.canvas["set"+option.capitalize()](value)}return showLoader?this.show():void 0}
KDLoaderView.prototype.show=function(){KDLoaderView.__super__.show.apply(this,arguments)
this.active=!0
return this.canvas?this.canvas.show():void 0}
KDLoaderView.prototype.hide=function(){KDLoaderView.__super__.hide.apply(this,arguments)
this.active=!1
return this.canvas?this.canvas.hide():void 0}
KDLoaderView.prototype.mouseEnter=function(){this.canvas.setSpeed(2)
return this.canvas.setColor(this.utils.getRandomHex())}
KDLoaderView.prototype.mouseLeave=function(){this.canvas.setColor(this.getOptions().loaderOptions.color)
return this.canvas.setSpeed(this.getOptions().loaderOptions.speed)}
return KDLoaderView}(KDView)

var KDListViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDListViewController=function(_super){function KDListViewController(options,data){var listView,noItemFoundWidget,viewOptions,_this=this
null==options&&(options={})
null==options.wrapper&&(options.wrapper=!0)
null==options.scrollView&&(options.scrollView=!0)
null==options.keyNav&&(options.keyNav=!1)
null==options.multipleSelection&&(options.multipleSelection=!1)
null==options.selection&&(options.selection=!0)
null==options.startWithLazyLoader&&(options.startWithLazyLoader=!1)
options.itemChildClass||(options.itemChildClass=null)
options.itemChildOptions||(options.itemChildOptions={})
options.noItemFoundWidget||(options.noItemFoundWidget=null)
options.noMoreItemFoundWidget||(options.noMoreItemFoundWidget=null)
this.itemsOrdered||(this.itemsOrdered=[])
this.itemsIndexed={}
this.selectedItems=[]
this.lazyLoader=null
if(options.view)this.setListView(listView=options.view)
else{viewOptions=options.viewOptions||{}
viewOptions.lastToFirst||(viewOptions.lastToFirst=options.lastToFirst)
viewOptions.itemClass||(viewOptions.itemClass=options.itemClass)
viewOptions.itemChildClass||(viewOptions.itemChildClass=options.itemChildClass)
viewOptions.itemChildOptions||(viewOptions.itemChildOptions=options.itemChildOptions)
this.setListView(listView=new KDListView(viewOptions))}options.scrollView&&(this.scrollView=new KDScrollView({lazyLoadThreshold:options.lazyLoadThreshold,ownScrollBars:options.ownScrollBars}))
options.view=options.wrapper?new KDView({cssClass:"listview-wrapper"}):listView
KDListViewController.__super__.constructor.call(this,options,data)
noItemFoundWidget=this.getOptions().noItemFoundWidget
listView.on("ItemWasAdded",function(view,index){_this.registerItem(view,index)
return noItemFoundWidget?_this.hideNoItemWidget():void 0})
listView.on("ItemIsBeingDestroyed",function(itemInfo){_this.unregisterItem(itemInfo)
return noItemFoundWidget?_this.showNoItemWidget():void 0})
options.keyNav&&listView.on("KeyDownOnList",function(event){return _this.keyDownPerformed(listView,event)})}__extends(KDListViewController,_super)
KDListViewController.prototype.loadView=function(mainView){var options,_ref,_this=this
options=this.getOptions()
if(options.scrollView){mainView.addSubView(this.scrollView)
this.scrollView.addSubView(this.getListView())
options.startWithLazyLoader&&this.showLazyLoader(!1)
this.scrollView.on("LazyLoadThresholdReached",this.bound("showLazyLoader"))}options.noItemFoundWidget&&this.putNoItemView()
this.instantiateListItems((null!=(_ref=this.getData())?_ref.items:void 0)||[])
return KD.getSingleton("windowController").on("ReceivedMouseUpElsewhere",function(event){return _this.mouseUpHappened(event)})}
KDListViewController.prototype.instantiateListItems=function(items){var itemData,newItems
newItems=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){itemData=items[_i]
_results.push(this.getListView().addItem(itemData))}return _results}.call(this)
this.emit("AllItemsAddedToList")
return newItems}
KDListViewController.prototype.itemForId=function(id){return this.itemsIndexed[id]}
KDListViewController.prototype.getItemsOrdered=function(){return this.itemsOrdered}
KDListViewController.prototype.getItemCount=function(){return this.itemsOrdered.length}
KDListViewController.prototype.setListView=function(listView){return this.listView=listView}
KDListViewController.prototype.getListView=function(){return this.listView}
KDListViewController.prototype.forEachItemByIndex=function(ids,callback){var _ref,_this=this
callback||(_ref=[ids,callback],callback=_ref[0],ids=_ref[1])
Array.isArray(ids)||(ids=[ids])
return ids.forEach(function(id){var item
item=_this.itemsIndexed[id]
return null!=item?callback(item):void 0})}
KDListViewController.prototype.putNoItemView=function(){var noItemFoundWidget
noItemFoundWidget=this.getOptions().noItemFoundWidget
return this.getListView().addSubView(this.noItemView=noItemFoundWidget)}
KDListViewController.prototype.showNoItemWidget=function(){return 0===this.itemsOrdered.length?this.noItemView.show():void 0}
KDListViewController.prototype.hideNoItemWidget=function(){return this.noItemView.hide()}
KDListViewController.prototype.showNoMoreItemWidget=function(){var noMoreItemFoundWidget
noMoreItemFoundWidget=this.getOptions().noMoreItemFoundWidget
return noMoreItemFoundWidget?this.scrollView.addSubView(noMoreItemFoundWidget):void 0}
KDListViewController.prototype.addItem=function(itemData,index,animation){return this.getListView().addItem(itemData,index,animation)}
KDListViewController.prototype.removeItem=function(itemInstance,itemData,index){return this.getListView().removeItem(itemInstance,itemData,index)}
KDListViewController.prototype.registerItem=function(view,index){var actualIndex,options,_this=this
options=this.getOptions()
if(null!=index){actualIndex=this.getOptions().lastToFirst?this.getListView().items.length-index-1:index
this.itemsOrdered.splice(actualIndex,0,view)}else this.itemsOrdered[this.getOptions().lastToFirst?"unshift":"push"](view)
null!=view.getData()&&(this.itemsIndexed[view.getItemDataId()]=view)
options.selection&&view.on("click",function(event){return _this.selectItem(view,event)})
if(options.keyNav||options.multipleSelection){view.on("mousedown",function(event){return _this.mouseDownHappenedOnItem(view,event)})
return view.on("mouseenter",function(event){return _this.mouseEnterHappenedOnItem(view,event)})}}
KDListViewController.prototype.unregisterItem=function(itemInfo){var actualIndex,index,view
this.emit("UnregisteringItem",itemInfo)
index=itemInfo.index,view=itemInfo.view
actualIndex=this.getOptions().lastToFirst?this.getListView().items.length-index-1:index
this.itemsOrdered.splice(actualIndex,1)
return null!=view.getData()?delete this.itemsIndexed[view.getItemDataId()]:void 0}
KDListViewController.prototype.replaceAllItems=function(items){this.removeAllItems()
return this.instantiateListItems(items)}
KDListViewController.prototype.removeAllItems=function(){var itemsOrdered,listView
itemsOrdered=this.itemsOrdered
this.itemsOrdered.length=0
this.itemsIndexed={}
listView=this.getListView()
listView.items.length&&listView.empty()
return itemsOrdered}
KDListViewController.prototype.moveItemToIndex=function(item,newIndex){newIndex=Math.max(0,Math.min(this.itemsOrdered.length-1,newIndex))
return this.itemsOrdered=this.getListView().moveItemToIndex(item,newIndex)}
KDListViewController.prototype.mouseDownHappenedOnItem=function(item,event){var _this=this
this.getOptions().keyNav&&KD.getSingleton("windowController").setKeyView(this.getListView())
this.lastEvent=event
if(__indexOf.call(this.selectedItems,item)<0){this.mouseDown=!0
this.mouseDownTempItem=item
return this.mouseDownTimer=setTimeout(function(){_this.mouseDown=!1
_this.mouseDownTempItem=null
return _this.selectItem(item,event)},300)}this.mouseDown=!1
return this.mouseDownTempItem=null}
KDListViewController.prototype.mouseUpHappened=function(){clearTimeout(this.mouseDownTimer)
this.mouseDown=!1
return this.mouseDownTempItem=null}
KDListViewController.prototype.mouseEnterHappenedOnItem=function(item,event){clearTimeout(this.mouseDownTimer)
if(this.mouseDown){event.metaKey||event.ctrlKey||event.shiftKey||this.deselectAllItems()
return this.selectItemsByRange(this.mouseDownTempItem,item)}return this.emit("MouseEnterHappenedOnItem",item)}
KDListViewController.prototype.keyDownPerformed=function(mainView,event){switch(event.which){case 40:case 38:this.selectItemBelowOrAbove(event)
return this.emit("KeyDownOnListHandled",this.selectedItems)}}
KDListViewController.prototype.selectItem=function(item,event){var ctrlKey,metaKey,multipleSelection,selectable,shiftKey
null==event&&(event={})
if(null!=item){this.lastEvent=event
selectable=item.getOptions().selectable
multipleSelection=this.getOptions().multipleSelection
metaKey=event.metaKey,ctrlKey=event.ctrlKey,shiftKey=event.shiftKey
multipleSelection||this.deselectAllItems()
!selectable||metaKey||ctrlKey||shiftKey||this.deselectAllItems()
event.shiftKey&&this.selectedItems.length>0?this.selectItemsByRange(this.selectedItems[0],item):__indexOf.call(this.selectedItems,item)<0?this.selectSingleItem(item):this.deselectSingleItem(item)
return this.selectedItems}}
KDListViewController.prototype.selectItemBelowOrAbove=function(event){var addend,direction,lastSelectedIndex,selectedIndex
direction=40===event.which?"down":"up"
addend=40===event.which?1:-1
selectedIndex=this.itemsOrdered.indexOf(this.selectedItems[0])
lastSelectedIndex=this.itemsOrdered.indexOf(this.selectedItems[this.selectedItems.length-1])
if(this.itemsOrdered[selectedIndex+addend]){if(!(event.metaKey||event.ctrlKey||event.shiftKey))return this.selectItem(this.itemsOrdered[selectedIndex+addend])
if(-1!==this.selectedItems.indexOf(this.itemsOrdered[lastSelectedIndex+addend])){if(this.itemsOrdered[lastSelectedIndex])return this.deselectSingleItem(this.itemsOrdered[lastSelectedIndex])}else if(this.itemsOrdered[lastSelectedIndex+addend])return this.selectSingleItem(this.itemsOrdered[lastSelectedIndex+addend])}}
KDListViewController.prototype.selectNextItem=function(item){var selectedIndex
item||(item=this.selectedItems[0])
selectedIndex=this.itemsOrdered.indexOf(item)
return this.selectItem(this.itemsOrdered[selectedIndex+1])}
KDListViewController.prototype.selectPrevItem=function(item){var selectedIndex
item||(item=this.selectedItems[0])
selectedIndex=this.itemsOrdered.indexOf(item)
return this.selectItem(this.itemsOrdered[selectedIndex+-1])}
KDListViewController.prototype.deselectAllItems=function(){var deselectedItems,selectedItem,_i,_len,_ref,_results
_ref=this.selectedItems
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){selectedItem=_ref[_i]
selectedItem.removeHighlight()
deselectedItems=this.selectedItems.concat([])
this.selectedItems=[]
this.getListView().unsetClass("last-item-selected")
_results.push(this.itemDeselectionPerformed(deselectedItems))}return _results}
KDListViewController.prototype.deselectSingleItem=function(item){item.removeHighlight()
this.selectedItems.splice(this.selectedItems.indexOf(item),1)
item===this.itemsOrdered[this.itemsOrdered.length-1]&&this.getListView().unsetClass("last-item-selected")
return this.itemDeselectionPerformed([item])}
KDListViewController.prototype.selectSingleItem=function(item){if(item.getOption("selectable")&&!(__indexOf.call(this.selectedItems,item)>=0)){item.highlight()
this.selectedItems.push(item)
item===this.itemsOrdered[this.itemsOrdered.length-1]&&this.getListView().setClass("last-item-selected")
return this.itemSelectionPerformed()}}
KDListViewController.prototype.selectAllItems=function(){var item,_i,_len,_ref,_results
_ref=this.itemsOrdered
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
_results.push(this.selectSingleItem(item))}return _results}
KDListViewController.prototype.selectItemsByRange=function(item1,item2){var indicesToBeSliced,item,itemsToBeSelected,_i,_len
indicesToBeSliced=[this.itemsOrdered.indexOf(item1),this.itemsOrdered.indexOf(item2)]
indicesToBeSliced.sort(function(a,b){return a-b})
itemsToBeSelected=this.itemsOrdered.slice(indicesToBeSliced[0],indicesToBeSliced[1]+1)
for(_i=0,_len=itemsToBeSelected.length;_len>_i;_i++){item=itemsToBeSelected[_i]
this.selectSingleItem(item)}return this.itemSelectionPerformed()}
KDListViewController.prototype.itemSelectionPerformed=function(){return this.emit("ItemSelectionPerformed",this,{event:this.lastEvent,items:this.selectedItems})}
KDListViewController.prototype.itemDeselectionPerformed=function(deselectedItems){return this.emit("ItemDeselectionPerformed",this,{event:this.lastEvent,items:deselectedItems})}
KDListViewController.prototype.showLazyLoader=function(emitWhenReached){var wrapper
null==emitWhenReached&&(emitWhenReached=!0)
this.noItemView&&this.getOptions().noItemFoundWidget&&this.hideNoItemWidget()
if(!this.lazyLoader){wrapper=this.scrollView||this.getView()
wrapper.addSubView(this.lazyLoader=new KDCustomHTMLView({cssClass:"lazy-loader",partial:"Loading..."}))
this.lazyLoader.addSubView(this.lazyLoader.spinner=new KDLoaderView({size:{width:16},loaderOptions:{color:"#5f5f5f",diameter:16,density:60,range:.4,speed:3,FPS:24}}))
this.lazyLoader.spinner.show()
if(emitWhenReached)return this.emit("LazyLoadThresholdReached")}}
KDListViewController.prototype.hideLazyLoader=function(){this.noItemView&&this.getOptions().noItemFoundWidget&&this.showNoItemWidget()
if(this.lazyLoader){this.lazyLoader.spinner.hide()
this.lazyLoader.destroy()
return this.lazyLoader=null}}
return KDListViewController}(KDViewController)

var KDListView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDListView=function(_super){function KDListView(options,data){null==options&&(options={})
options.type||(options.type="default")
null==options.lastToFirst&&(options.lastToFirst=!1)
options.cssClass=null!=options.cssClass?"kdlistview kdlistview-"+options.type+" "+options.cssClass:"kdlistview kdlistview-"+options.type
this.items||(this.items=[])
KDListView.__super__.constructor.call(this,options,data)}__extends(KDListView,_super)
KDListView.prototype.empty=function(){var i,item,_i,_len,_ref
_ref=this.items
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){item=_ref[i]
null!=item&&item.destroy()}return this.items=[]}
KDListView.prototype.keyDown=function(event){event.stopPropagation()
event.preventDefault()
return this.emit("KeyDownOnList",event)}
KDListView.prototype._addItemHelper=function(itemData,options){var animation,index,itemChildClass,itemChildOptions,itemInstance,viewOptions,_ref,_ref1,_ref2
index=options.index,animation=options.animation,viewOptions=options.viewOptions
_ref=this.getOptions(),itemChildClass=_ref.itemChildClass,itemChildOptions=_ref.itemChildOptions
viewOptions||(viewOptions=("function"==typeof this.customizeItemOptions?this.customizeItemOptions(options,itemData):void 0)||{})
viewOptions.delegate=this
viewOptions.childClass||(viewOptions.childClass=itemChildClass)
viewOptions.childOptions=itemChildOptions
itemInstance=new(null!=(_ref1=null!=(_ref2=viewOptions.itemClass)?_ref2:this.getOptions().itemClass)?_ref1:KDListItemView)(viewOptions,itemData)
this.addItemView(itemInstance,index,animation)
return itemInstance}
KDListView.prototype.addHiddenItem=function(item,index,animation){return this._addItemHelper(item,{viewOptions:{isHidden:!0,cssClass:"hidden-item"},index:index,animation:animation})}
KDListView.prototype.addItem=function(itemData,index,animation){return this._addItemHelper(itemData,{index:index,animation:animation})}
KDListView.prototype.removeItem=function(itemInstance,itemData,index){var i,item,_i,_len,_ref
if(null!=index){this.emit("ItemIsBeingDestroyed",{view:this.items[index],index:index})
item=this.items.splice(index,1)
item[0].destroy()}else{_ref=this.items
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){item=_ref[i]
if(itemInstance===item||itemData===item.getData()){this.emit("ItemIsBeingDestroyed",{view:item,index:i})
this.items.splice(i,1)
item.destroy()
return}}}}
KDListView.prototype.removeItemByData=function(itemData){return this.removeItem(null,itemData)}
KDListView.prototype.removeItemByIndex=function(index){return this.removeItem(null,null,index)}
KDListView.prototype.destroy=function(animated,animationType,duration){var item,_i,_len,_ref
null==animated&&(animated=!1)
null==animationType&&(animationType="slideUp")
null==duration&&(duration=100)
_ref=this.items
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
item.destroy()}return KDListView.__super__.destroy.call(this)}
KDListView.prototype.addItemView=function(itemInstance,index,animation){var actualIndex
this.emit("ItemWasAdded",itemInstance,index)
if(null!=index){actualIndex=this.getOptions().lastToFirst?this.items.length-index-1:index
this.items.splice(actualIndex,0,itemInstance)
this.appendItemAtIndex(itemInstance,index,animation)}else{this.items[this.getOptions().lastToFirst?"unshift":"push"](itemInstance)
this.appendItem(itemInstance,animation)}return itemInstance}
KDListView.prototype.appendItem=function(itemInstance,animation){var scroll
itemInstance.setParent(this)
scroll=this.doIHaveToScroll()
if(null!=animation){itemInstance.$().hide()
this.$()[this.getOptions().lastToFirst?"prepend":"append"](itemInstance.$())
itemInstance.$()[animation.type](animation.duration,function(){return itemInstance.emit("introEffectCompleted")})}else this.$()[this.getOptions().lastToFirst?"prepend":"append"](itemInstance.$())
scroll&&this.scrollDown()
this.parentIsInDom&&itemInstance.emit("viewAppended")
return null}
KDListView.prototype.appendItemAtIndex=function(itemInstance,index,animation){var actualIndex
itemInstance.setParent(this)
actualIndex=this.getOptions().lastToFirst?this.items.length-index-1:index
if(null!=animation){itemInstance.$().hide()
0===index&&this.$()[this.getOptions().lastToFirst?"append":"prepend"](itemInstance.$())
index>0&&this.items[actualIndex-1].$()[this.getOptions().lastToFirst?"before":"after"](itemInstance.$())
itemInstance.$()[animation.type](animation.duration,function(){return itemInstance.emit("introEffectCompleted")})}else{0===index&&this.$()[this.getOptions().lastToFirst?"append":"prepend"](itemInstance.$())
index>0&&this.items[actualIndex-1].$()[this.getOptions().lastToFirst?"before":"after"](itemInstance.$())}this.parentIsInDom&&itemInstance.emit("viewAppended")
return null}
KDListView.prototype.getItemIndex=function(targetItem){var index,item,_i,_len,_ref
_ref=this.items
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){item=_ref[index]
if(item===targetItem)return index}return-1}
KDListView.prototype.moveItemToIndex=function(item,newIndex){var currentIndex,diff,targetItem
currentIndex=this.getItemIndex(item)
if(0>currentIndex){warn("Item doesn't exists",item)
return this.items}newIndex=Math.max(0,Math.min(this.items.length-1,newIndex))
if(newIndex>=this.items.length-1){targetItem=this.items.last
targetItem.$().after(item.$())}else{diff=newIndex>currentIndex?1:0
targetItem=this.items[newIndex+diff]
targetItem.$().before(item.$())}this.items.splice(currentIndex,1)
this.items.splice(newIndex,0,item)
return this.items}
KDListView.prototype.scrollDown=function(){var _this=this
clearTimeout(this._scrollDownTimeout)
return this._scrollDownTimeout=setTimeout(function(){var scrollView,slidingHeight,slidingView
scrollView=_this.$().closest(".kdscrollview")
slidingView=scrollView.find("> .kdview")
slidingHeight=slidingView.height()
return scrollView.animate({scrollTop:slidingHeight},{duration:200,queue:!1})},50)}
KDListView.prototype.doIHaveToScroll=function(){var scrollView
scrollView=this.$().closest(".kdscrollview")
return this.getOptions().autoScroll?scrollView.length&&scrollView[0].scrollHeight<=scrollView.height()?!0:this.isScrollAtBottom():!1}
KDListView.prototype.isScrollAtBottom=function(){var scrollTop,scrollView,scrollViewheight,slidingHeight,slidingView
scrollView=this.$().closest(".kdscrollview")
slidingView=scrollView.find("> .kdview")
scrollTop=scrollView.scrollTop()
slidingHeight=slidingView.height()
scrollViewheight=scrollView.height()
return slidingHeight-scrollViewheight===scrollTop?!0:!1}
return KDListView}(KDView)

var KDListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDListItemView=function(_super){function KDListItemView(options,data){var _ref,_ref1
null==options&&(options={})
options.type=null!=(_ref=options.type)?_ref:"default"
options.cssClass="kdlistitemview kdlistitemview-"+options.type+" "+(null!=(_ref1=options.cssClass)?_ref1:"")
options.bind||(options.bind="mouseenter mouseleave")
options.childClass||(options.childClass=null)
options.childOptions||(options.childOptions={})
null==options.selectable&&(options.selectable=!0)
KDListItemView.__super__.constructor.call(this,options,data)
this.content={}}__extends(KDListItemView,_super)
KDListItemView.prototype.viewAppended=function(){var childClass,childOptions,_ref
_ref=this.getOptions(),childClass=_ref.childClass,childOptions=_ref.childOptions
return childClass?this.addSubView(this.child=new childClass(childOptions,this.getData())):this.setPartial(this.partial(this.data))}
KDListItemView.prototype.partial=function(){return"<div class='kdlistitemview-default-content'>      <p>This is a default partial of <b>KDListItemView</b>,      you need to override this partial to have your custom content here.</p>    </div>"}
KDListItemView.prototype.dim=function(){return this.getDomElement().addClass("dimmed")}
KDListItemView.prototype.undim=function(){return this.getDomElement().removeClass("dimmed")}
KDListItemView.prototype.highlight=function(){this.setClass("selected")
return this.unsetClass("dimmed")}
KDListItemView.prototype.removeHighlight=function(){this.unsetClass("selected")
return this.unsetClass("dimmed")}
KDListItemView.prototype.getItemDataId=function(){var _base
return("function"==typeof(_base=this.getData()).getId?_base.getId():void 0)||this.getData().id||this.getData()._id}
return KDListItemView}(KDView)

var JTreeViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
JTreeViewController=function(_super){function JTreeViewController(options,data){var o
null==options&&(options={})
o=options
o.view||(o.view=new KDScrollView({cssClass:"jtreeview-wrapper"}))
o.listViewControllerClass||(o.listViewControllerClass=KDListViewController)
o.treeItemClass||(o.treeItemClass=JTreeItemView)
o.listViewClass||(o.listViewClass=JTreeView)
o.itemChildClass||(o.itemChildClass=null)
o.itemChildOptions||(o.itemChildOptions={})
o.nodeIdPath||(o.nodeIdPath="id")
o.nodeParentIdPath||(o.nodeParentIdPath="parentId")
null==o.contextMenu&&(o.contextMenu=!1)
null==o.multipleSelection&&(o.multipleSelection=!1)
null==o.addListsCollapsed&&(o.addListsCollapsed=!1)
null==o.sortable&&(o.sortable=!1)
null==o.putDepthInfo&&(o.putDepthInfo=!0)
null==o.addOrphansToRoot&&(o.addOrphansToRoot=!0)
null==o.dragdrop&&(o.dragdrop=!1)
JTreeViewController.__super__.constructor.call(this,o,data)
this.listData={}
this.listControllers={}
this.nodes={}
this.indexedNodes=[]
this.selectedNodes=[]}var cacheDragHelper,dragHelper,keyMap
__extends(JTreeViewController,_super)
keyMap=function(){return{37:"left",38:"up",39:"right",40:"down",8:"backspace",9:"tab",13:"enter",27:"escape"}}
dragHelper=null
cacheDragHelper=function(){dragHelper=document.createElement("img")
dragHelper.src="/images/multiple-item-drag-helper.png"
return dragHelper.width=110}()
JTreeViewController.prototype.loadView=function(){this.initTree(this.getData())
this.setKeyView()
this.setMainListeners()
return this.registerBoundaries()}
JTreeViewController.prototype.registerBoundaries=function(){return this.boundaries={top:this.getView().getY(),left:this.getView().getX(),width:this.getView().getWidth(),height:this.getView().getHeight()}}
JTreeViewController.prototype.initTree=function(nodes){this.removeAllNodes()
return this.addNodes(nodes)}
JTreeViewController.prototype.logTreeStructure=function(){var index,node,o,_ref,_results
o=this.getOptions()
_ref=this.indexedNodes
_results=[]
for(index in _ref)if(__hasProp.call(_ref,index)){node=_ref[index]
_results.push(log(index,this.getNodeId(node),this.getNodePId(node),node.depth))}return _results}
JTreeViewController.prototype.getNodeId=function(nodeData){return nodeData[this.getOptions().nodeIdPath]}
JTreeViewController.prototype.getNodePId=function(nodeData){return nodeData[this.getOptions().nodeParentIdPath]}
JTreeViewController.prototype.getPathIndex=function(targetPath){var index,node,_i,_len,_ref
_ref=this.indexedNodes
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){node=_ref[index]
if(this.getNodeId(node)===targetPath)return index}return-1}
JTreeViewController.prototype.repairIds=function(nodeData){var idPath,options,pIdPath
options=this.getOptions()
idPath=options.nodeIdPath
pIdPath=options.nodeParentIdPath
nodeData[idPath]||(nodeData[idPath]=this.utils.getUniqueId())
nodeData[idPath]=""+this.getNodeId(nodeData)
nodeData[pIdPath]=this.getNodePId(nodeData)?""+this.getNodePId(nodeData):"0"
this.nodes[this.getNodeId(nodeData)]={}
options.putDepthInfo&&(nodeData.depth=this.nodes[nodeData[pIdPath]]?this.nodes[nodeData[pIdPath]].getData().depth+1:0)
"0"===nodeData[pIdPath]||this.nodes[nodeData[pIdPath]]||(options.addOrphansToRoot?nodeData[pIdPath]="0":nodeData=!1)
return nodeData}
JTreeViewController.prototype.isNodeVisible=function(nodeView){var nodeData,parentNode
nodeData=nodeView.getData()
parentNode=this.nodes[this.getNodePId(nodeData)]
return parentNode?parentNode.expanded?this.isNodeVisible(parentNode):!1:!0}
JTreeViewController.prototype.areSibling=function(node1,node2){var node1PId,node2PId
node1PId=this.getNodePId(node1.getData())
node2PId=this.getNodePId(node2.getData())
return node1PId===node2PId}
JTreeViewController.prototype.setFocusState=function(){var view
view=this.getView()
KD.getSingleton("windowController").addLayer(view)
return view.unsetClass("dim")}
JTreeViewController.prototype.setBlurState=function(){var view
view=this.getView()
KD.getSingleton("windowController").removeLayer(view)
return view.setClass("dim")}
JTreeViewController.prototype.addNode=function(nodeData){var list,node,parentId
if(!this.nodes[this.getNodeId(nodeData)]){nodeData=this.repairIds(nodeData)
if(nodeData){__indexOf.call(this.getData(),nodeData)<0&&this.getData().push(nodeData)
this.registerListData(nodeData)
parentId=this.getNodePId(nodeData)
if(null!=this.listControllers[parentId])list=this.listControllers[parentId].getListView()
else{list=this.createList(parentId).getListView()
this.addSubList(this.nodes[parentId],parentId)}node=list.addItem(nodeData)
this.emit("NodeWasAdded",node)
this.addIndexedNode(nodeData)
return node}}}
JTreeViewController.prototype.addNodes=function(nodes){var node,_i,_len,_results
_results=[]
for(_i=0,_len=nodes.length;_len>_i;_i++){node=nodes[_i]
_results.push(this.addNode(node))}return _results}
JTreeViewController.prototype.removeNode=function(id){var index,nodeData,nodeIndexToRemove,nodeToRemove,parentId,_i,_len,_ref
nodeIndexToRemove=null
_ref=this.getData()
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){nodeData=_ref[index]
if(this.getNodeId(nodeData)===id){this.removeIndexedNode(nodeData)
nodeIndexToRemove=index}}if(null!=nodeIndexToRemove){nodeToRemove=this.getData().splice(nodeIndexToRemove,1)[0]
this.removeChildNodes(id)
parentId=this.getNodePId(nodeToRemove)
this.listControllers[parentId].getListView().removeItem(this.nodes[id])
return delete this.nodes[id]}}
JTreeViewController.prototype.removeNodeView=function(nodeView){return this.removeNode(this.getNodeId(nodeView.getData()))}
JTreeViewController.prototype.removeAllNodes=function(){var id,listController,_ref
_ref=this.listControllers
for(id in _ref)if(__hasProp.call(_ref,id)){listController=_ref[id]
listController.itemsOrdered.forEach(this.bound("removeNodeView"))
null!=listController&&listController.getView().destroy()
delete this.listControllers[id]
delete this.listData[id]}this.nodes={}
this.listData={}
this.indexedNodes=[]
this.selectedNodes=[]
return this.listControllers={}}
JTreeViewController.prototype.removeChildNodes=function(id){var childNodeId,childNodeIdsToRemove,index,nodeData,_i,_j,_len,_len1,_ref,_ref1
childNodeIdsToRemove=[]
_ref=this.getData()
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){nodeData=_ref[index]
this.getNodePId(nodeData)===id&&childNodeIdsToRemove.push(this.getNodeId(nodeData))}for(_j=0,_len1=childNodeIdsToRemove.length;_len1>_j;_j++){childNodeId=childNodeIdsToRemove[_j]
this.removeNode(childNodeId)}null!=(_ref1=this.listControllers[id])&&_ref1.getView().destroy()
delete this.listControllers[id]
return delete this.listData[id]}
JTreeViewController.prototype.nodeWasAdded=function(nodeView){var id,nodeData,parentId
nodeData=nodeView.getData()
this.getOptions().dragdrop&&nodeView.$().attr("draggable","true")
id=nodeData.id,parentId=nodeData.parentId
this.nodes[this.getNodeId(nodeData)]=nodeView
if(this.nodes[this.getNodePId(nodeData)]){this.getOptions().addListsCollapsed||this.expand(this.nodes[this.getNodePId(nodeData)])
this.nodes[this.getNodePId(nodeData)].decorateSubItemsState()}return this.listControllers[id]?this.addSubList(nodeView,id):void 0}
JTreeViewController.prototype.getChildNodes=function(aParentNode){var children,_this=this
children=[]
this.indexedNodes.forEach(function(node,index){return _this.getNodePId(node)===_this.getNodeId(aParentNode)?children.push({node:node,index:index}):void 0})
return children.length?children:!1}
JTreeViewController.prototype.getPreviousNeighbor=function(aParentNode){var children,lastChild,neighbor
neighbor=aParentNode
children=this.getChildNodes(aParentNode)
if(children){lastChild=children.last
neighbor=this.getPreviousNeighbor(lastChild.node)}return neighbor}
JTreeViewController.prototype.addIndexedNode=function(nodeData,index){var neighborIndex,parentNodeView,prevNeighbor
if(!(index>=0)){parentNodeView=this.nodes[this.getNodePId(nodeData)]
if(parentNodeView){prevNeighbor=this.getPreviousNeighbor(parentNodeView.getData())
neighborIndex=this.indexedNodes.indexOf(prevNeighbor)
return this.indexedNodes.splice(neighborIndex+1,0,nodeData)}return this.indexedNodes.push(nodeData)}this.indexedNodes.splice(index+1,0,nodeData)}
JTreeViewController.prototype.removeIndexedNode=function(nodeData){var index
if(__indexOf.call(this.indexedNodes,nodeData)>=0){index=this.indexedNodes.indexOf(nodeData)
this.indexedNodes.splice(index,1)
if(this.nodes[this.getNodePId(nodeData)]&&!this.getChildNodes(this.nodes[this.getNodePId(nodeData)].getData()))return this.nodes[this.getNodePId(nodeData)].decorateSubItemsState(!1)}}
JTreeViewController.prototype.registerListData=function(node){var parentId,_base
parentId=this.getNodePId(node);(_base=this.listData)[parentId]||(_base[parentId]=[])
return this.listData[parentId].push(node)}
JTreeViewController.prototype.createList=function(listId,listItems){var options,_ref,_ref1
options=this.getOptions()
this.listControllers[listId]=new options.listViewControllerClass({id:""+this.getId()+"_"+listId,wrapper:!1,scrollView:!1,selection:null!=(_ref=options.selection)?_ref:!1,multipleSelection:null!=(_ref1=options.multipleSelection)?_ref1:!1,view:new options.listViewClass({tagName:"ul",type:options.type,itemClass:options.treeItemClass,itemChildClass:options.itemChildClass,itemChildOptions:options.itemChildOptions})},{items:listItems})
this.setListenersForList(listId)
return this.listControllers[listId]}
JTreeViewController.prototype.addSubList=function(nodeView,id){var listToBeAdded,o
o=this.getOptions()
listToBeAdded=this.listControllers[id].getView()
if(nodeView){nodeView.$().after(listToBeAdded.$())
listToBeAdded.parentIsInDom=!0
listToBeAdded.emit("viewAppended")
return o.addListsCollapsed?this.collapse(nodeView):this.expand(nodeView)}return this.getView().addSubView(listToBeAdded)}
JTreeViewController.prototype.setMainListeners=function(){var _this=this
KD.getSingleton("windowController").on("ReceivedMouseUpElsewhere",function(event){return _this.mouseUp(event)})
return this.getView().on("ReceivedClickElsewhere",function(){return _this.setBlurState()})}
JTreeViewController.prototype.setListenersForList=function(listId){var _this=this
this.listControllers[listId].getView().on("ItemWasAdded",function(view,index){return _this.setItemListeners(view,index)})
this.listControllers[listId].on("ItemSelectionPerformed",function(listController,_arg){var event,items
event=_arg.event,items=_arg.items
return _this.organizeSelectedNodes(listController,items,event)})
this.listControllers[listId].on("ItemDeselectionPerformed",function(listController,_arg){var event,items
event=_arg.event,items=_arg.items
return _this.deselectNodes(listController,items,event)})
return this.listControllers[listId].getListView().on("KeyDownOnTreeView",function(event){return _this.keyEventHappened(event)})}
JTreeViewController.prototype.setItemListeners=function(view){var mouseEvents,_this=this
view.on("viewAppended",this.nodeWasAdded.bind(this,view))
mouseEvents=["dblclick","click","mousedown","mouseup","mouseenter","mousemove"]
this.getOptions().contextMenu&&mouseEvents.push("contextmenu")
this.getOptions().dragdrop&&(mouseEvents=mouseEvents.concat(["dragstart","dragenter","dragleave","dragend","dragover","drop"]))
return view.on(mouseEvents,function(event){return _this.mouseEventHappened(view,event)})}
JTreeViewController.prototype.organizeSelectedNodes=function(listController,nodes,event){var node,_i,_len,_results
null==event&&(event={});(event.metaKey||event.ctrlKey||event.shiftKey)&&this.getOptions().multipleSelection||this.deselectAllNodes(listController)
_results=[]
for(_i=0,_len=nodes.length;_len>_i;_i++){node=nodes[_i]
__indexOf.call(this.selectedNodes,node)<0?_results.push(this.selectedNodes.push(node)):_results.push(void 0)}return _results}
JTreeViewController.prototype.deselectNodes=function(listController,nodes){var node,_i,_len,_results
_results=[]
for(_i=0,_len=nodes.length;_len>_i;_i++){node=nodes[_i]
__indexOf.call(this.selectedNodes,node)>=0?_results.push(this.selectedNodes.splice(this.selectedNodes.indexOf(node),1)):_results.push(void 0)}return _results}
JTreeViewController.prototype.deselectAllNodes=function(exceptThisController){var id,listController,_ref
_ref=this.listControllers
for(id in _ref)if(__hasProp.call(_ref,id)){listController=_ref[id]
listController!==exceptThisController&&listController.deselectAllItems()}return this.selectedNodes=[]}
JTreeViewController.prototype.selectNode=function(nodeView,event,setFocus){null==setFocus&&(setFocus=!0)
if(nodeView){setFocus&&this.setFocusState()
return this.listControllers[this.getNodePId(nodeView.getData())].selectItem(nodeView,event)}}
JTreeViewController.prototype.deselectNode=function(nodeView,event){return this.listControllers[this.getNodePId(nodeView.getData())].deselectSingleItem(nodeView,event)}
JTreeViewController.prototype.selectFirstNode=function(){return this.selectNode(this.nodes[this.getNodeId(this.indexedNodes[0])])}
JTreeViewController.prototype.selectNodesByRange=function(node1,node2){var indicesToBeSliced,itemsToBeSelected,node,_i,_len,_results
indicesToBeSliced=[this.indexedNodes.indexOf(node1.getData()),this.indexedNodes.indexOf(node2.getData())]
indicesToBeSliced.sort(function(a,b){return a-b})
itemsToBeSelected=this.indexedNodes.slice(indicesToBeSliced[0],indicesToBeSliced[1]+1)
_results=[]
for(_i=0,_len=itemsToBeSelected.length;_len>_i;_i++){node=itemsToBeSelected[_i]
_results.push(this.selectNode(this.nodes[this.getNodeId(node)],{shiftKey:!0}))}return _results}
JTreeViewController.prototype.toggle=function(nodeView){return nodeView.expanded?this.collapse(nodeView):this.expand(nodeView)}
JTreeViewController.prototype.expand=function(nodeView){var nodeData,_ref
nodeData=nodeView.getData()
nodeView.expand()
return null!=(_ref=this.listControllers[this.getNodeId(nodeData)])?_ref.getView().expand():void 0}
JTreeViewController.prototype.collapse=function(nodeView){var nodeData,_ref
nodeData=nodeView.getData()
return null!=(_ref=this.listControllers[this.getNodeId(nodeData)])?_ref.getView().collapse(function(){return nodeView.collapse()}):void 0}
JTreeViewController.prototype.showDragOverFeedback=function(){return _.throttle(function(nodeView){var nodeData,_ref,_ref1
nodeData=nodeView.getData()
if("file"!==nodeData.type)nodeView.setClass("drop-target")
else{null!=(_ref=this.nodes[nodeData.parentPath])&&_ref.setClass("drop-target")
null!=(_ref1=this.listControllers[nodeData.parentPath])&&_ref1.getListView().setClass("drop-target")}return nodeView.setClass("items-hovering")},100)}()
JTreeViewController.prototype.clearDragOverFeedback=function(){return _.throttle(function(nodeView){var nodeData,_ref,_ref1
nodeData=nodeView.getData()
if("file"!==nodeData.type)nodeView.unsetClass("drop-target")
else{null!=(_ref=this.nodes[nodeData.parentPath])&&_ref.unsetClass("drop-target")
null!=(_ref1=this.listControllers[nodeData.parentPath])&&_ref1.getListView().unsetClass("drop-target")}return nodeView.unsetClass("items-hovering")},100)}()
JTreeViewController.prototype.clearAllDragFeedback=function(){var _this=this
return this.utils.wait(101,function(){var listController,nodeView,path,_ref,_ref1,_results
_this.getView().$(".drop-target").removeClass("drop-target")
_this.getView().$(".items-hovering").removeClass("items-hovering")
_ref=_this.listControllers
for(path in _ref)if(__hasProp.call(_ref,path)){listController=_ref[path]
listController.getListView().unsetClass("drop-target")}_ref1=_this.nodes
_results=[]
for(path in _ref1)if(__hasProp.call(_ref1,path)){nodeView=_ref1[path]
_results.push(nodeView.unsetClass("items-hovering drop-target"))}return _results})}
JTreeViewController.prototype.mouseEventHappened=function(nodeView,event){switch(event.type){case"mouseenter":return this.mouseEnter(nodeView,event)
case"dblclick":return this.dblClick(nodeView,event)
case"click":return this.click(nodeView,event)
case"mousedown":return this.mouseDown(nodeView,event)
case"mouseup":return this.mouseUp(nodeView,event)
case"mousemove":return this.mouseMove(nodeView,event)
case"contextmenu":return this.contextMenu(nodeView,event)
case"dragstart":return this.dragStart(nodeView,event)
case"dragenter":return this.dragEnter(nodeView,event)
case"dragleave":return this.dragLeave(nodeView,event)
case"dragover":return this.dragOver(nodeView,event)
case"dragend":return this.dragEnd(nodeView,event)
case"drop":return this.drop(nodeView,event)}}
JTreeViewController.prototype.dblClick=function(nodeView){return this.toggle(nodeView)}
JTreeViewController.prototype.click=function(nodeView,event){if(/arrow/.test(event.target.className)){this.toggle(nodeView)
return this.selectedItems}this.lastEvent=event;(event.metaKey||event.ctrlKey||event.shiftKey)&&this.getOptions().multipleSelection||this.deselectAllNodes()
null!=nodeView&&(event.shiftKey&&this.selectedNodes.length>0&&this.getOptions().multipleSelection?this.selectNodesByRange(this.selectedNodes[0],nodeView):this.selectNode(nodeView,event))
return this.selectedItems}
JTreeViewController.prototype.contextMenu=function(){}
JTreeViewController.prototype.mouseDown=function(nodeView,event){var _this=this
this.lastEvent=event
if(__indexOf.call(this.selectedNodes,nodeView)<0){this.mouseIsDown=!0
this.cancelDrag=!0
this.mouseDownTempItem=nodeView
return this.mouseDownTimer=setTimeout(function(){_this.mouseIsDown=!1
_this.cancelDrag=!1
_this.mouseDownTempItem=null
return _this.selectNode(nodeView,event)},1e3)}this.mouseIsDown=!1
return this.mouseDownTempItem=null}
JTreeViewController.prototype.mouseUp=function(){clearTimeout(this.mouseDownTimer)
this.mouseIsDown=!1
this.cancelDrag=!1
return this.mouseDownTempItem=null}
JTreeViewController.prototype.mouseEnter=function(nodeView,event){clearTimeout(this.mouseDownTimer)
if(this.mouseIsDown&&this.getOptions().multipleSelection){this.cancelDrag=!0;(event.metaKey||event.ctrlKey||event.shiftKey)&&this.getOptions().multipleSelection||this.deselectAllNodes()
return this.selectNodesByRange(this.mouseDownTempItem,nodeView)}}
JTreeViewController.prototype.dragStart=function(nodeView,event){var e,node,transferredData
if(this.cancelDrag){event.preventDefault()
event.stopPropagation()
return!1}this.dragIsActive=!0
e=event.originalEvent
e.dataTransfer.effectAllowed="copyMove"
transferredData=function(){var _i,_len,_ref,_results
_ref=this.selectedNodes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){node=_ref[_i]
_results.push(this.getNodeId(node.getData()))}return _results}.call(this)
e.dataTransfer.setData("Text",transferredData.join())
this.selectedNodes.length>1&&e.dataTransfer.setDragImage(dragHelper,-10,0)
return nodeView.setClass("drag-started")}
JTreeViewController.prototype.dragEnter=function(nodeView,event){return this.emit("dragEnter",nodeView,event)}
JTreeViewController.prototype.dragLeave=function(nodeView,event){this.clearAllDragFeedback()
return this.emit("dragLeave",nodeView,event)}
JTreeViewController.prototype.dragOver=function(nodeView,event){return this.emit("dragOver",nodeView,event)}
JTreeViewController.prototype.dragEnd=function(nodeView,event){this.dragIsActive=!1
nodeView.unsetClass("drag-started")
this.clearAllDragFeedback()
return this.emit("dragEnd",nodeView,event)}
JTreeViewController.prototype.drop=function(nodeView,event){this.dragIsActive=!1
event.preventDefault()
event.stopPropagation()
this.emit("drop",nodeView,event)
return!1}
JTreeViewController.prototype.setKeyView=function(){return this.listControllers[0]?KD.getSingleton("windowController").setKeyView(this.listControllers[0].getListView()):void 0}
JTreeViewController.prototype.keyEventHappened=function(event){var key,nextNode,nodeView,_base
key=keyMap()[event.which]
nodeView=this.selectedNodes[0]
this.emit("keyEventPerformedOnTreeView",event)
if(nodeView)switch(key){case"down":case"up":event.preventDefault()
nextNode=this["perform"+key.capitalize()+"Key"](nodeView,event)
if(nextNode)return"function"==typeof(_base=this.getView()).scrollToSubView?_base.scrollToSubView(nextNode):void 0
break
case"left":return this.performLeftKey(nodeView,event)
case"right":return this.performRightKey(nodeView,event)
case"backspace":return this.performBackspaceKey(nodeView,event)
case"enter":return this.performEnterKey(nodeView,event)
case"escape":return this.performEscapeKey(nodeView,event)
case"tab":return!1}}
JTreeViewController.prototype.performDownKey=function(nodeView,event){var nextIndex,nextNode,nodeData
if(this.selectedNodes.length>1){nodeView=this.selectedNodes[this.selectedNodes.length-1]
if(!(event.metaKey||event.ctrlKey||event.shiftKey)||!this.getOptions().multipleSelection){this.deselectAllNodes()
this.selectNode(nodeView)}}nodeData=nodeView.getData()
nextIndex=this.indexedNodes.indexOf(nodeData)+1
if(this.indexedNodes[nextIndex]){nextNode=this.nodes[this.getNodeId(this.indexedNodes[nextIndex])]
if(this.isNodeVisible(nextNode)){if(__indexOf.call(this.selectedNodes,nextNode)>=0)return this.deselectNode(this.nodes[this.getNodeId(nodeData)])
this.selectNode(nextNode,event)
return nextNode}return this.performDownKey(nextNode,event)}}
JTreeViewController.prototype.performUpKey=function(nodeView,event){var nextIndex,nextNode,nodeData
if(this.selectedNodes.length>1){nodeView=this.selectedNodes[this.selectedNodes.length-1]
if(!(event.metaKey||event.ctrlKey||event.shiftKey)||!this.getOptions().multipleSelection){this.deselectAllNodes()
this.selectNode(nodeView)}}nodeData=nodeView.getData()
nextIndex=this.indexedNodes.indexOf(nodeData)-1
if(this.indexedNodes[nextIndex]){nextNode=this.nodes[this.getNodeId(this.indexedNodes[nextIndex])]
this.isNodeVisible(nextNode)?__indexOf.call(this.selectedNodes,nextNode)>=0?this.deselectNode(this.nodes[this.getNodeId(nodeData)]):this.selectNode(nextNode,event):this.performUpKey(nextNode,event)}return nextNode}
JTreeViewController.prototype.performRightKey=function(nodeView){return this.expand(nodeView)}
JTreeViewController.prototype.performLeftKey=function(nodeView){var nodeData,parentNode
nodeData=nodeView.getData()
if(this.nodes[this.getNodePId(nodeData)]){parentNode=this.nodes[this.getNodePId(nodeData)]
this.selectNode(parentNode)}return parentNode}
JTreeViewController.prototype.performBackspaceKey=function(){}
JTreeViewController.prototype.performEnterKey=function(){}
JTreeViewController.prototype.performEscapeKey=function(){}
return JTreeViewController}(KDViewController)

var JTreeView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JTreeView=function(_super){function JTreeView(options,data){null==options&&(options={})
null==options.animated&&(options.animated=!1)
JTreeView.__super__.constructor.call(this,options,data)
this.setClass("jtreeview expanded")}__extends(JTreeView,_super)
JTreeView.prototype.toggle=function(callback){return this.expanded?this.collapse(callback):this.expand(callback)}
JTreeView.prototype.expand=function(callback){var _this=this
if(this.getOptions().animated)return this.$().slideDown(150,function(){_this.setClass("expanded")
return"function"==typeof callback?callback():void 0})
this.show()
this.setClass("expanded")
return"function"==typeof callback?callback():void 0}
JTreeView.prototype.collapse=function(callback){var _this=this
if(this.getOptions().animated)return this.$().slideUp(100,function(){_this.unsetClass("expanded")
return"function"==typeof callback?callback():void 0})
this.hide()
this.unsetClass("expanded")
return"function"==typeof callback?callback():void 0}
JTreeView.prototype.mouseDown=function(){KD.getSingleton("windowController").setKeyView(this)
return!1}
JTreeView.prototype.keyDown=function(event){return this.emit("KeyDownOnTreeView",event)}
JTreeView.prototype.destroy=function(){KD.getSingleton("windowController").revertKeyView(this)
return JTreeView.__super__.destroy.apply(this,arguments)}
JTreeView.prototype.appendItemAtIndex=function(itemInstance,index){var added,_ref
itemInstance.setParent(this)
added=!0
if(0>=index)this.$().prepend(itemInstance.$())
else if(index>0)if(null!=(_ref=this.items[index-1])?_ref.$().hasClass("has-sub-items"):void 0)this.items[index-1].$().next().after(itemInstance.$())
else if(null!=this.items[index-1])this.items[index-1].$().after(itemInstance.$())
else{warn("Out of bound")
added=!1}this.parentIsInDom&&added&&itemInstance.emit("viewAppended")
return null}
return JTreeView}(KDListView)

var JTreeItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JTreeItemView=function(_super){function JTreeItemView(options,data){var childClass,childOptions,_ref
null==options&&(options={})
null==data&&(data={})
options.tagName||(options.tagName="li")
options.type||(options.type="jtreeitem")
options.bind||(options.bind="mouseenter contextmenu dragstart dragenter dragleave dragend dragover drop")
options.childClass||(options.childClass=null)
options.childOptions||(options.childOptions={})
JTreeItemView.__super__.constructor.call(this,options,data)
this.setClass("jtreeitem")
this.expanded=!1
_ref=this.getOptions(),childClass=_ref.childClass,childOptions=_ref.childOptions
childClass&&(this.child=new childClass(childOptions,this.getData()))}__extends(JTreeItemView,_super)
JTreeItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
JTreeItemView.prototype.pistachio=function(){return this.getOptions().childClass?"{{> this.child}}":"<span class='arrow'></span>\n{{#(title)}}"}
JTreeItemView.prototype.toggle=function(){return this.expanded?this.collapse():this.expand()}
JTreeItemView.prototype.expand=function(){this.expanded=!0
return this.setClass("expanded")}
JTreeItemView.prototype.collapse=function(){this.expanded=!1
return this.unsetClass("expanded")}
JTreeItemView.prototype.decorateSubItemsState=function(state){null==state&&(state=!0)
return state?this.setClass("has-sub-items"):this.unsetClass("has-sub-items")}
return JTreeItemView}(KDListItemView)

var KDTabHandleView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTabHandleView=function(_super){function KDTabHandleView(options,data){var _this=this
null==options&&(options={})
null==options.hidden&&(options.hidden=!1)
null==options.title&&(options.title="Title")
null==options.pane&&(options.pane=null)
null==options.view&&(options.view=null)
null==options.sortable&&(options.sortable=!1)
null==options.closable&&(options.closable=!0)
if(options.sortable){options.draggable={axis:"x"}
this.dragStartPosX=null}KDTabHandleView.__super__.constructor.call(this,options,data)
this.on("DragStarted",function(event,dragState){_this.startedDragFromCloseElement=$(event.target).hasClass("close-tab")
return _this.handleDragStart(event,dragState)})
this.on("DragInAction",function(x,y){_this.startedDragFromCloseElement&&(_this.dragIsAllowed=!1)
return _this.handleDragInAction(x,y)})
this.on("DragFinished",function(event){_this.handleDragFinished(event)
return _this.getDelegate().showPaneByIndex(_this.index)})}__extends(KDTabHandleView,_super)
KDTabHandleView.prototype.setDomElement=function(cssClass){var closable,closeHandle,hidden,tagName,title,_ref
null==cssClass&&(cssClass="")
_ref=this.getOptions(),hidden=_ref.hidden,closable=_ref.closable,tagName=_ref.tagName,title=_ref.title
cssClass=hidden?""+cssClass+" hidden":cssClass
closeHandle=closable?"<span class='close-tab'></span>":""
return this.domElement=$("<"+tagName+" title='"+title+"' class='kdtabhandle "+cssClass+"'>"+closeHandle+"</"+tagName+">")}
KDTabHandleView.prototype.viewAppended=function(){var view
view=this.getOptions().view
return view&&view instanceof KDView?this.addSubView(view):this.setPartial(this.partial())}
KDTabHandleView.prototype.partial=function(){return"<b>"+(this.getOptions().title||"Default Title")+"</b>"}
KDTabHandleView.prototype.makeActive=function(){return this.getDomElement().addClass("active")}
KDTabHandleView.prototype.makeInactive=function(){return this.getDomElement().removeClass("active")}
KDTabHandleView.prototype.setTitle=function(title){return this.setAttribute("title",title)}
KDTabHandleView.prototype.isHidden=function(){return this.getOptions().hidden}
KDTabHandleView.prototype.getWidth=function(){return this.$().outerWidth(!1)||0}
KDTabHandleView.prototype.cloneElement=function(){var holder,pane,tabView
if(!this.$cloned){pane=this.getOptions().pane
tabView=pane.getDelegate()
holder=tabView.tabHandleContainer
this.$cloned=this.$().clone()
holder.$().append(this.$cloned)
return this.$cloned.css({marginLeft:-(tabView.handles.length-this.index)*this.getWidth()})}}
KDTabHandleView.prototype.updateClonedElementPosition=function(x){return this.$cloned.css({left:x})}
KDTabHandleView.prototype.reorderTabHandles=function(x){var dragDir,targetDiff,targetIndex,width
dragDir=this.dragState.direction
width=this.getWidth()
if("left"===dragDir.current.x){targetIndex=this.index-1
targetDiff=-(width*this.draggedItemIndex-width*targetIndex-width/2)
if(targetDiff>x){this.emit("HandleIndexHasChanged",this.index,"left")
return this.index--}}else{targetIndex=this.index+1
targetDiff=width*targetIndex-width*this.draggedItemIndex-width/2
if(x>targetDiff){this.emit("HandleIndexHasChanged",this.index,"right")
return this.index++}}}
KDTabHandleView.prototype.handleDragStart=function(){var handles,pane,tabView
pane=this.getOptions().pane
tabView=pane.getDelegate()
handles=tabView.handles
this.index=handles.indexOf(this)
return this.draggedItemIndex=this.index}
KDTabHandleView.prototype.handleDragInAction=function(x){if(this.dragIsAllowed){if(-(this.draggedItemIndex*this.getWidth())>x)return this.$().css({left:0})
this.unsetClass("first")
this.cloneElement(x)
this.$().css({opacity:.01})
this.updateClonedElementPosition(x)
return this.reorderTabHandles(x)}}
KDTabHandleView.prototype.handleDragFinished=function(){if(this.$cloned){this.$cloned.remove()
this.$().css({left:"",opacity:1,marginLeft:""})
this.targetTabHandle||0!==this.draggedItemIndex||this.$().css({left:0})
this.targetTabHandle=null
return this.$cloned=null}}
return KDTabHandleView}(KDView)

var KDTabView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTabView=function(_super){function KDTabView(options,data){var _ref,_this=this
null==options&&(options={})
null==options.resizeTabHandles&&(options.resizeTabHandles=!1)
null==options.maxHandleWidth&&(options.maxHandleWidth=128)
null==options.minHandleWidth&&(options.minHandleWidth=30)
null==options.lastTabHandleMargin&&(options.lastTabHandleMargin=0)
null==options.sortable&&(options.sortable=!1)
null==options.hideHandleContainer&&(options.hideHandleContainer=!1)
null==options.hideHandleCloseIcons&&(options.hideHandleCloseIcons=!1)
null==options.tabHandleContainer&&(options.tabHandleContainer=null)
options.tabHandleClass||(options.tabHandleClass=KDTabHandleView)
options.paneData||(options.paneData=[])
options.cssClass=KD.utils.curry("kdtabview",options.cssClass)
this.handles=[]
this.panes=[]
this.selectedIndex=[]
this.tabConstructor=null!=(_ref=options.tabClass)?_ref:KDTabPaneView
this.lastOpenPaneIndex=0
KDTabView.__super__.constructor.call(this,options,data)
this.activePane=null
this.handlesHidden=!1
this.blockTabHandleResize=!1
this.setTabHandleContainer(options.tabHandleContainer)
options.hideHandleCloseIcons&&this.hideHandleCloseIcons()
options.hideHandleContainer&&this.hideHandleContainer()
this.on("PaneRemoved",function(){return _this.resizeTabHandles({type:"PaneRemoved"})})
this.on("PaneAdded",function(pane){return _this.resizeTabHandles({type:"PaneAdded",pane:pane})})
this.on("PaneDidShow",this.bound("setActivePane"))
options.paneData.length>0&&this.on("viewAppended",function(){return _this.createPanes(options.paneData)})
this.tabHandleContainer.on("mouseenter",function(){return _this.blockTabHandleResize=!0})
this.tabHandleContainer.on("mouseleave",function(){_this.blockTabHandleResize=!1
return _this.resizeTabHandles()})}__extends(KDTabView,_super)
KDTabView.prototype.createPanes=function(paneData){var paneOptions,_i,_len,_results
null==paneData&&(paneData=this.getOptions().paneData)
_results=[]
for(_i=0,_len=paneData.length;_len>_i;_i++){paneOptions=paneData[_i]
_results.push(this.addPane(new this.tabConstructor(paneOptions,null)))}return _results}
KDTabView.prototype.addPane=function(paneInstance,shouldShow){var newTabHandle,paneOptions,tabHandleClass,_ref,_this=this
null==shouldShow&&(shouldShow=!0)
if(paneInstance instanceof KDTabPaneView){this.panes.push(paneInstance)
tabHandleClass=this.getOptions().tabHandleClass
paneOptions=paneInstance.getOptions()
this.addHandle(newTabHandle=new tabHandleClass({pane:paneInstance,title:paneOptions.name||paneOptions.title,hidden:paneOptions.hiddenHandle,view:paneOptions.tabHandleView,closable:paneOptions.closable,sortable:this.getOptions().sortable,click:function(event){return _this.handleMouseDownDefaultAction(newTabHandle,event)}}))
paneInstance.tabHandle=newTabHandle
this.appendPane(paneInstance)
shouldShow&&!paneInstance.getOption("lazy")&&this.showPane(paneInstance)
this.emit("PaneAdded",paneInstance)
newTabHandle.$().css({maxWidth:this.getOptions().maxHandleWidth})
newTabHandle.on("HandleIndexHasChanged",this.bound("resortTabHandles"))
return paneInstance}warn("You can't add "+(null!=(null!=paneInstance?null!=(_ref=paneInstance.constructor)?_ref.name:void 0:void 0)?paneInstance.constructor.name:void 0)+" as a pane, use KDTabPaneView instead.")
return!1}
KDTabView.prototype.resortTabHandles=function(index,dir){var methodName,newIndex,splicedHandle,splicedPane,targetIndex
if(!(0===index&&"left"===dir||index===this.handles.length-1&&"right"===dir||index>=this.handles.length||0>index)){this.handles[0].unsetClass("first")
if("right"===dir){methodName="insertAfter"
targetIndex=index+1}else{methodName="insertBefore"
targetIndex=index-1}this.handles[index].$()[methodName](this.handles[targetIndex].$())
newIndex="left"===dir?index-1:index+1
splicedHandle=this.handles.splice(index,1)
splicedPane=this.panes.splice(index,1)
this.handles.splice(newIndex,0,splicedHandle[0])
this.panes.splice(newIndex,0,splicedPane[0])
return this.handles[0].setClass("first")}}
KDTabView.prototype.removePane=function(pane){var firstPane,handle,index,isActivePane,prevPane
pane.emit("KDTabPaneDestroy")
index=this.getPaneIndex(pane)
isActivePane=this.getActivePane()===pane
this.panes.splice(index,1)
pane.destroy()
handle=this.getHandleByIndex(index)
this.handles.splice(index,1)
handle.destroy()
isActivePane&&((prevPane=this.getPaneByIndex(this.lastOpenPaneIndex))?this.showPane(prevPane):(firstPane=this.getPaneByIndex(0))&&this.showPane(firstPane))
return this.emit("PaneRemoved")}
KDTabView.prototype.removePaneByName=function(name){var pane,_i,_len,_ref,_results
_ref=this.panes
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
if(pane.name===name){this.removePane(pane)
break}_results.push(void 0)}return _results}
KDTabView.prototype.appendHandleContainer=function(){return this.addSubView(this.tabHandleContainer)}
KDTabView.prototype.appendPane=function(pane){pane.setDelegate(this)
return this.addSubView(pane)}
KDTabView.prototype.appendHandle=function(tabHandle){this.handleHeight||(this.handleHeight=this.tabHandleContainer.getHeight())
tabHandle.setDelegate(this)
return this.tabHandleContainer.addSubView(tabHandle)}
KDTabView.prototype.addHandle=function(handle){var _ref
if(handle instanceof KDTabHandleView){this.handles.push(handle)
this.appendHandle(handle)
handle.getOptions().hidden&&handle.setClass("hidden")
return handle}return warn("You can't add "+(null!=(null!=handle?null!=(_ref=handle.constructor)?_ref.name:void 0:void 0)?handle.constructor.name:void 0)+" as a pane, use KDTabHandleView instead.")}
KDTabView.prototype.removeHandle=function(){}
KDTabView.prototype.showPane=function(pane){var handle,index
if(pane){this.lastOpenPaneIndex=this.getPaneIndex(this.getActivePane())
this.hideAllPanes()
pane.show()
index=this.getPaneIndex(pane)
handle=this.getHandleByIndex(index)
handle.makeActive()
pane.emit("PaneDidShow")
this.emit("PaneDidShow",pane)
return pane}}
KDTabView.prototype.hideAllPanes=function(){var handle,pane,_i,_j,_len,_len1,_ref,_ref1,_results
_ref=this.panes
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
pane.hide()}_ref1=this.handles
_results=[]
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){handle=_ref1[_j]
_results.push(handle.makeInactive())}return _results}
KDTabView.prototype.hideHandleContainer=function(){this.tabHandleContainer.hide()
return this.handlesHidden=!0}
KDTabView.prototype.showHandleContainer=function(){this.tabHandleContainer.show()
return this.handlesHidden=!1}
KDTabView.prototype.toggleHandleContainer=function(duration){null==duration&&(duration=0)
return this.tabHandleContainer.$().toggle(duration)}
KDTabView.prototype.hideHandleCloseIcons=function(){return this.tabHandleContainer.$().addClass("hide-close-icons")}
KDTabView.prototype.showHandleCloseIcons=function(){return this.tabHandleContainer.$().removeClass("hide-close-icons")}
KDTabView.prototype.handleMouseDownDefaultAction=function(clickedTabHandle,event){var handle,index,_i,_len,_ref,_results
_ref=this.handles
_results=[]
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){handle=_ref[index]
clickedTabHandle===handle&&_results.push(this.handleClicked(index,event))}return _results}
KDTabView.prototype.handleClicked=function(index,event){var pane
pane=this.getPaneByIndex(index)
if($(event.target).hasClass("close-tab")){this.removePane(pane)
return!1}return this.showPane(pane)}
KDTabView.prototype.setTabHandleContainer=function(aViewInstance){if(null!=aViewInstance){null!=this.tabHandleContainer&&this.tabHandleContainer.destroy()
this.tabHandleContainer=aViewInstance}else{this.tabHandleContainer=new KDView
this.appendHandleContainer()}return this.tabHandleContainer.setClass("kdtabhandlecontainer")}
KDTabView.prototype.getTabHandleContainer=function(){return this.tabHandleContainer}
KDTabView.prototype.checkPaneExistenceById=function(id){var pane,result,_i,_len,_ref
result=!1
_ref=this.panes
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
pane.id===id&&(result=!0)}return result}
KDTabView.prototype.getPaneByName=function(name){var pane,result,_i,_len,_ref
result=!1
_ref=this.panes
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
pane.name===name&&(result=pane)}return result}
KDTabView.prototype.getPaneById=function(id){var pane,paneInstance,_i,_len,_ref
paneInstance=null
_ref=this.panes
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
pane.id===id&&(paneInstance=pane)}return paneInstance}
KDTabView.prototype.getActivePane=function(){return this.activePane}
KDTabView.prototype.setActivePane=function(activePane){this.activePane=activePane}
KDTabView.prototype.getPaneByIndex=function(index){return this.panes[index]}
KDTabView.prototype.getHandleByIndex=function(index){return this.handles[index]}
KDTabView.prototype.getPaneIndex=function(aPane){var index,pane,result,_i,_len,_ref
if(aPane){result=0
_ref=this.panes
for(index=_i=0,_len=_ref.length;_len>_i;index=++_i){pane=_ref[index]
pane===aPane&&(result=index)}return result}}
KDTabView.prototype.showPaneByIndex=function(index){return this.showPane(this.getPaneByIndex(index))}
KDTabView.prototype.showPaneByName=function(name){return this.showPane(this.getPaneByName(name))}
KDTabView.prototype.showNextPane=function(){var activeIndex,activePane
activePane=this.getActivePane()
activeIndex=this.getPaneIndex(activePane)
return this.showPane(this.getPaneByIndex(activeIndex+1))}
KDTabView.prototype.showPreviousPane=function(){var activeIndex,activePane
activePane=this.getActivePane()
activeIndex=this.getPaneIndex(activePane)
return this.showPane(this.getPaneByIndex(activeIndex-1))}
KDTabView.prototype.setPaneTitle=function(pane,title){var handle
handle=this.getHandleByPane(pane)
handle.getDomElement().find("b").text(title)
return handle.setAttribute("title",title)}
KDTabView.prototype.getHandleByPane=function(pane){var handle,index
index=this.getPaneIndex(pane)
return handle=this.getHandleByIndex(index)}
KDTabView.prototype.hideCloseIcon=function(pane){var handle,index
index=this.getPaneIndex(pane)
handle=this.getHandleByIndex(index)
return handle.getDomElement().addClass("hide-close-icon")}
KDTabView.prototype.getVisibleHandles=function(){return this.handles.filter(function(handle){return handle.isHidden()===!1})}
KDTabView.prototype.getVisibleTabs=function(){return this.panes.filter(function(pane){return pane.tabHandle.isHidden()===!1})}
KDTabView.prototype.resizeTabHandles=KD.utils.throttle(function(){var containerMarginInPercent,containerSize,handle,options,possiblePercent,visibleHandles,visibleTotalSize,_i,_j,_len,_len1,_ref,_results
if(this.getOptions().resizeTabHandles&&!this._tabHandleContainerHidden&&!this.blockTabHandleResize){visibleHandles=[]
visibleTotalSize=0
options=this.getOptions()
containerSize=this.tabHandleContainer.$().outerWidth(!1)-options.lastTabHandleMargin
containerMarginInPercent=100*options.lastTabHandleMargin/containerSize
_ref=this.handles
for(_i=0,_len=_ref.length;_len>_i;_i++){handle=_ref[_i]
if(!handle.isHidden()){visibleHandles.push(handle)
visibleTotalSize+=handle.$().outerWidth(!1)}}possiblePercent=((100-containerMarginInPercent)/visibleHandles.length).toFixed(2)
_results=[]
for(_j=0,_len1=visibleHandles.length;_len1>_j;_j++){handle=visibleHandles[_j]
_results.push(handle.setWidth(possiblePercent,"%"))}return _results}},300)
return KDTabView}(KDScrollView)

var KDTabPaneView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTabPaneView=function(_super){function KDTabPaneView(options,data){var defaultCssClass
null==options&&(options={})
null==options.hiddenHandle&&(options.hiddenHandle=!1)
options.name||(options.name="")
defaultCssClass="kdtabpaneview kdhiddentab "+KD.utils.slugify(options.name.toLowerCase())+" clearfix"
options.cssClass=KD.utils.curry(defaultCssClass,options.cssClass)
KDTabPaneView.__super__.constructor.call(this,options,data)
this.name=options.name
this.on("KDTabPaneActive",this.bound("setMainView"))
this.on("KDTabPaneLazyViewAdded",this.bound("fireLazyCallback"))}__extends(KDTabPaneView,_super)
KDTabPaneView.prototype.show=function(){this.unsetClass("kdhiddentab")
this.setClass("active")
this.active=!0
return this.emit("KDTabPaneActive")}
KDTabPaneView.prototype.hide=function(){this.unsetClass("active")
this.setClass("kdhiddentab")
this.active=!1
return this.emit("KDTabPaneInactive")}
KDTabPaneView.prototype.setTitle=function(title){this.getDelegate().setPaneTitle(this,title)
return this.name=title}
KDTabPaneView.prototype.getHandle=function(){return this.getDelegate().getHandleByPane(this)}
KDTabPaneView.prototype.hideTabCloseIcon=function(){return this.getDelegate().hideCloseIcon(this)}
KDTabPaneView.prototype.setMainView=function(view){var data,options,viewClass,viewOptions,_ref
view||(_ref=this.getOptions(),view=_ref.view,viewOptions=_ref.viewOptions)
if(!this.mainView&&(view||viewOptions)){if(view instanceof KDView)this.mainView=this.addSubView(view)
else{if(!viewOptions)return warn("probably you set a weird lazy view!")
viewClass=viewOptions.viewClass,options=viewOptions.options,data=viewOptions.data
this.mainView=this.addSubView(new viewClass(options,data))}this.emit("KDTabPaneLazyViewAdded",this,this.mainView)
return this.mainView}}
KDTabPaneView.prototype.getMainView=function(){return this.mainView}
KDTabPaneView.prototype.destroyMainView=function(){this.mainView.destroy()
return delete this.mainView}
KDTabPaneView.prototype.fireLazyCallback=function(pane,view){var callback,viewOptions
viewOptions=this.getOptions().viewOptions
if(viewOptions){callback=viewOptions.callback
if(callback)return callback.call(this,pane,view)}}
return KDTabPaneView}(KDView)

var KDTabViewWithForms,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTabViewWithForms=function(_super){function KDTabViewWithForms(options,data){var forms
null==options&&(options={})
null==options.navigable&&(options.navigable=!0)
null==options.goToNextFormOnSubmit&&(options.goToNextFormOnSubmit=!0)
KDTabViewWithForms.__super__.constructor.call(this,options,data)
this.forms={}
this.hideHandleCloseIcons()
forms=this.getOptions().forms
if(forms){this.createTabs(forms=this.utils.objectToArray(forms))
this.showPane(this.panes[0])}1===forms.length&&this.hideHandleContainer()}__extends(KDTabViewWithForms,_super)
KDTabViewWithForms.prototype.handleClicked=function(){return this.getOptions().navigable?KDTabViewWithForms.__super__.handleClicked.apply(this,arguments):void 0}
KDTabViewWithForms.prototype.createTab=function(formData,index){var oldCallback,tab,_this=this
this.addPane(tab=new KDTabPaneView({name:formData.title}),formData.shouldShow)
oldCallback=formData.callback
formData.callback=function(formData){var forms
_this.getOptions().goToNextFormOnSubmit&&_this.showNextPane()
"function"==typeof oldCallback&&oldCallback(formData)
forms=_this.getOptions().forms
return forms&&index===Object.keys(forms).length-1?_this.fireFinalCallback():void 0}
this.createForm(formData,tab)
return tab}
KDTabViewWithForms.prototype.createTabs=function(forms){var _this=this
return forms.forEach(function(formData,i){return _this.createTab(formData,i)})}
KDTabViewWithForms.prototype.createForm=function(formData,parentTab){var form
parentTab.addSubView(form=new KDFormViewWithFields(formData))
this.forms[formData.title]=parentTab.form=form
return form}
KDTabViewWithForms.prototype.getFinalData=function(){var finalData,pane,_i,_len,_ref
finalData={}
_ref=this.panes
for(_i=0,_len=_ref.length;_len>_i;_i++){pane=_ref[_i]
finalData=$.extend(pane.form.getData(),finalData)}return finalData}
KDTabViewWithForms.prototype.fireFinalCallback=function(){var finalData,_base
finalData=this.getFinalData()
return"function"==typeof(_base=this.getOptions()).callback?_base.callback(finalData):void 0}
return KDTabViewWithForms}(KDTabView)

var JContextMenu,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JContextMenu=function(_super){function JContextMenu(options,data){var o,_base,_base1,_ref,_this=this
null==options&&(options={})
options.cssClass=this.utils.curry("jcontextmenu",options.cssClass)
options.menuWidth||(options.menuWidth=172)
options.offset||(options.offset={});(_base=options.offset).left||(_base.left=0);(_base1=options.offset).top||(_base1.top=0)
null==options.arrow&&(options.arrow=!1)
null==options.sticky&&(options.sticky=!1)
JContextMenu.__super__.constructor.call(this,options,data)
this.topMargin=0
this.leftMargin=0
o=this.getOptions()
this.sticky=o.sticky
KD.getSingleton("windowController").addLayer(this)
this.on("ReceivedClickElsewhere",function(){return _this.sticky?void 0:_this.destroy()})
if(data){this.treeController=new JContextMenuTreeViewController({type:o.type,view:o.view,delegate:this,treeItemClass:o.treeItemClass,listViewClass:o.listViewClass,itemChildClass:o.itemChildClass,itemChildOptions:o.itemChildOptions,addListsCollapsed:o.addListsCollapsed,putDepthInfo:o.putDepthInfo,lazyLoad:null!=(_ref=o.lazyLoad)?_ref:!1},data)
this.addSubView(this.treeController.getView())
this.treeController.getView().on("ReceivedClickElsewhere",function(){return _this.sticky?void 0:_this.destroy()})
this.treeController.on("NodeExpanded",this.bound("positionSubMenu"))}options.arrow&&this.on("viewAppended",this.bound("addArrow"))
this.appendToDomBody()}__extends(JContextMenu,_super)
JContextMenu.prototype.changeStickyState=function(state){return this.sticky=state}
JContextMenu.prototype.childAppended=function(){this.positionContextMenu()
return JContextMenu.__super__.childAppended.apply(this,arguments)}
JContextMenu.prototype.addArrow=function(){var o,rule,_ref
o=this.getOptions().arrow
o.placement||(o.placement="top")
null==o.margin&&(o.margin=0)
o.margin+="top"===(_ref=o.placement)||"bottom"===_ref?this.leftMargin:this.topMargin
this.arrow=new KDCustomHTMLView({tagName:"span",cssClass:"arrow "+o.placement})
this.arrow.$().css(function(){switch(o.placement){case"top":rule={top:-7}
o.margin>0?rule.left=o.margin:rule.right=-o.margin
return rule
case"bottom":rule={bottom:0}
o.margin>0?rule.left=o.margin:rule.right=-o.margin
return rule
case"right":rule={right:-7}
o.margin>0?rule.top=o.margin:rule.bottom=-o.margin
return rule
case"left":rule={left:-11}
o.margin>0?rule.top=o.margin:rule.bottom=-o.margin
return rule
default:return{}}}())
return this.addSubView(this.arrow)}
JContextMenu.prototype.positionContextMenu=function(){var event,expectedLeft,expectedTop,left,mainHeight,mainView,mainWidth,menuHeight,menuWidth,options,top
options=this.getOptions()
event=options.event||{}
mainView=KD.getSingleton("mainView")
mainHeight=mainView.getHeight()
mainWidth=mainView.getWidth()
menuHeight=this.getHeight()
menuWidth=this.getWidth()
top=(options.y||event.pageY||0)+options.offset.top
left=(options.x||event.pageX||0)+options.offset.left
expectedTop=top
expectedLeft=left
top+menuHeight>mainHeight&&(top=mainHeight-menuHeight+options.offset.top)
left+menuWidth>mainWidth&&(left=mainWidth-menuWidth+options.offset.left)
this.topMargin=expectedTop-top
this.leftMargin=expectedLeft-left
return this.getDomElement().css({width:""+options.menuWidth+"px",top:top,left:left})}
JContextMenu.prototype.positionSubMenu=function(nodeView){var children,expandView,fullViewHeight,fullViewWidth,id,_ref
_ref=nodeView.getData(),children=_ref.children,id=_ref.id
if(children){expandView=this.treeController.listControllers[id].getView()
fullViewHeight=expandView.getY()+expandView.getHeight()
fullViewHeight>window.innerHeight&&expandView.$().css("bottom",0)
fullViewWidth=expandView.getX()+expandView.getWidth()
if(fullViewWidth>window.innerWidth){expandView.$().css("left",-expandView.getWidth())
return expandView.setClass("left-aligned")}}}
return JContextMenu}(KDView)

var JContextMenuTreeViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JContextMenuTreeViewController=function(_super){function JContextMenuTreeViewController(options,data){var o
null==options&&(options={})
o=options
o.view||(o.view=new KDView({cssClass:"context-list-wrapper"}))
o.type||(o.type="contextmenu")
o.treeItemClass||(o.treeItemClass=JContextMenuItem)
o.listViewClass||(o.listViewClass=JContextMenuTreeView)
null==o.addListsCollapsed&&(o.addListsCollapsed=!0)
null==o.putDepthInfo&&(o.putDepthInfo=!0)
JContextMenuTreeViewController.__super__.constructor.call(this,o,data)
this.expandedNodes=[]}var convertToArray,getUId,uId
__extends(JContextMenuTreeViewController,_super)
uId=0
getUId=function(){return++uId}
convertToArray=JContextMenuTreeViewController.convertToArray=function(items,pId){var childrenArr,divider,id,newItem,options,results,title
null==pId&&(pId=null)
results=[]
for(title in items)if(__hasProp.call(items,title)){options=items[title]
id=null
if(0!==title.indexOf("customView"))if(options.children){id=getUId()
options.title=title
options.id=id
options.parentId=pId
results.push(options)
childrenArr=convertToArray(options.children,id)
results=results.concat(childrenArr)
if(options.separator){divider={type:"separator",parentId:pId}
results.push(divider)}}else{options.title=title
options.parentId=pId
results.push(options)
if(options.separator){divider={type:"separator",parentId:pId}
results.push(divider)}}else{newItem={type:"customView",parentId:pId,view:options}
results.push(newItem)}}return results}
JContextMenuTreeViewController.prototype.loadView=function(){JContextMenuTreeViewController.__super__.loadView.apply(this,arguments)
return this.getOptions().lazyLoad?void 0:this.selectFirstNode()}
JContextMenuTreeViewController.prototype.initTree=function(nodes){nodes.length||this.setData(nodes=convertToArray(nodes))
return JContextMenuTreeViewController.__super__.initTree.call(this,nodes)}
JContextMenuTreeViewController.prototype.repairIds=function(nodeData){"divider"===nodeData.type&&(nodeData.type="separator")
return JContextMenuTreeViewController.__super__.repairIds.apply(this,arguments)}
JContextMenuTreeViewController.prototype.expand=function(nodeView){JContextMenuTreeViewController.__super__.expand.apply(this,arguments)
this.emit("NodeExpanded",nodeView)
return nodeView.expanded?this.expandedNodes.push(nodeView):void 0}
JContextMenuTreeViewController.prototype.organizeSelectedNodes=function(listController,nodes,event){var depth1,nodeView,_this=this
null==event&&(event={})
nodeView=nodes[0]
if(this.expandedNodes.length){depth1=nodeView.getData().depth
this.expandedNodes.forEach(function(expandedNode){var depth2
depth2=expandedNode.getData().depth
return depth2>=depth1?_this.collapse(expandedNode):void 0})}return JContextMenuTreeViewController.__super__.organizeSelectedNodes.apply(this,arguments)}
JContextMenuTreeViewController.prototype.dblClick=function(){}
JContextMenuTreeViewController.prototype.mouseEnter=function(nodeView,event){var nodeData,_this=this
this.mouseEnterTimeOut&&clearTimeout(this.mouseEnterTimeOut)
nodeData=nodeView.getData()
if("separator"!==nodeData.type){this.selectNode(nodeView,event)
return this.mouseEnterTimeOut=setTimeout(function(){return _this.expand(nodeView)},150)}}
JContextMenuTreeViewController.prototype.click=function(nodeView,event){var contextMenu,nodeData
nodeData=nodeView.getData()
if("separator"!==nodeData.type&&!nodeData.disabled){this.toggle(nodeView)
contextMenu=this.getDelegate()
nodeData.callback&&"function"==typeof nodeData.callback&&nodeData.callback.call(contextMenu,nodeView,event)
contextMenu.emit("ContextMenuItemReceivedClick",nodeView)
event.stopPropagation()
return!1}}
JContextMenuTreeViewController.prototype.performDownKey=function(nodeView,event){var nextNode,nodeData
nextNode=JContextMenuTreeViewController.__super__.performDownKey.call(this,nodeView,event)
if(nextNode){nodeData=nextNode.getData()
if("separator"===nodeData.type)return this.performDownKey(nextNode,event)}}
JContextMenuTreeViewController.prototype.performUpKey=function(nodeView,event){var nextNode,nodeData
nextNode=JContextMenuTreeViewController.__super__.performUpKey.call(this,nodeView,event)
if(nextNode){nodeData=nextNode.getData()
"separator"===nodeData.type&&this.performUpKey(nextNode,event)}return nextNode}
JContextMenuTreeViewController.prototype.performRightKey=function(nodeView,event){JContextMenuTreeViewController.__super__.performRightKey.apply(this,arguments)
return this.performDownKey(nodeView,event)}
JContextMenuTreeViewController.prototype.performLeftKey=function(nodeView,event){var parentNode
parentNode=JContextMenuTreeViewController.__super__.performLeftKey.call(this,nodeView,event)
parentNode&&this.collapse(parentNode)
return parentNode}
JContextMenuTreeViewController.prototype.performEscapeKey=function(){KD.getSingleton("windowController").revertKeyView()
return this.getDelegate().destroy()}
JContextMenuTreeViewController.prototype.performEnterKey=function(nodeView,event){var contextMenu
KD.getSingleton("windowController").revertKeyView()
contextMenu=this.getDelegate()
contextMenu.emit("ContextMenuItemReceivedClick",nodeView)
contextMenu.destroy()
event.stopPropagation()
event.preventDefault()
return!1}
return JContextMenuTreeViewController}(JTreeViewController)

var JContextMenuTreeView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JContextMenuTreeView=function(_super){function JContextMenuTreeView(options,data){null==options&&(options={})
null==data&&(data={})
options.type||(options.type="contextmenu")
null==options.animated&&(options.animated=!1)
options.cssClass||(options.cssClass="default")
JContextMenuTreeView.__super__.constructor.call(this,options,data)
this.unsetClass("jtreeview")}__extends(JContextMenuTreeView,_super)
return JContextMenuTreeView}(JTreeView)

var JContextMenuItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JContextMenuItem=function(_super){function JContextMenuItem(options,data){null==options&&(options={})
null==data&&(data={})
options.type="contextitem"
options.cssClass||(options.cssClass="default")
JContextMenuItem.__super__.constructor.call(this,options,data)
this.unsetClass("jtreeitem")
if(data){("divider"===data.type||"separator"===data.type)&&this.setClass("separator")
data.cssClass&&this.setClass(data.cssClass)
if("customView"===data.type){this.setTemplate("")
this.addCustomView(data)}data.disabled&&this.setClass("disabled")}}__extends(JContextMenuItem,_super)
JContextMenuItem.prototype.viewAppended=function(){if(!this.customView){this.setTemplate(this.pistachio())
return this.template.update()}}
JContextMenuItem.prototype.mouseDown=function(){return!0}
JContextMenuItem.prototype.addCustomView=function(data){this.setClass("custom-view")
this.unsetClass("default")
this.customView=data.view||new KDView
delete data.view
return this.addSubView(this.customView)}
return JContextMenuItem}(JTreeItemView)

var KDDiaJoint,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDDiaJoint=function(_super){function KDDiaJoint(options,data){var _ref
null==options&&(options={})
options.type||(options.type="left")
if(_ref=options.type,__indexOf.call(types,_ref)<0){warn("Unknown joint type '"+options.type+"', falling back to 'left'")
options.type="left"}null==options.size&&(options.size=10)
options.cssClass=KD.utils.curry("kddia-joint "+options.type,options.cssClass)
KDDiaJoint.__super__.constructor.call(this,options,data)
this.connections={}
this.type=this.getOption("type")
this.size=this.getOption("size")}var types
__extends(KDDiaJoint,_super)
types=["left","right","top","bottom"]
KDDiaJoint.prototype.viewAppended=function(){KDDiaJoint.__super__.viewAppended.apply(this,arguments)
return this.domElement.attr("dia-id",this.getDiaId())}
KDDiaJoint.prototype.getDiaId=function(){return"dia-"+this.parent.getId()+"-joint-"+this.type}
KDDiaJoint.prototype.getPos=function(){return this.parent.getJointPos(this)}
KDDiaJoint.prototype.click=function(e){this.inDeleteMode()&&this.emit("DeleteRequested",this.parent,this.type)
return this.utils.stopDOMEvent(e)}
KDDiaJoint.prototype.mouseDown=function(e){if(!this.inDeleteMode()){this.utils.stopDOMEvent(e)
this.parent.emit("JointRequestsLine",this)
return!1}}
KDDiaJoint.prototype.inDeleteMode=function(){return this.hasClass("deleteMode")}
KDDiaJoint.prototype.showDeleteButton=function(){return this.setClass("deleteMode")}
KDDiaJoint.prototype.hideDeleteButton=function(){return this.unsetClass("deleteMode")}
return KDDiaJoint}(JView)

var KDDiaObject,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDDiaObject=function(_super){function KDDiaObject(options,data){var _base,_base1,_base2,_this=this
options.cssClass=KD.utils.curry("kddia-object",options.cssClass)
if(null==options.draggable){"object"!=typeof options.draggable&&(options.draggable={});(_base=options.draggable).containment||(_base.containment={});(_base1=options.draggable.containment).view||(_base1.view="parent")
null==(_base2=options.draggable.containment).padding&&(_base2.padding={top:1,right:1,bottom:1,left:1})}options.bind=KD.utils.curry("mouseleave",options.bind)
null==options.joints&&(options.joints=["left","right"])
null==options.jointItemClass&&(options.jointItemClass=KDDiaJoint)
options.allowedConnections||(options.allowedConnections={})
KDDiaObject.__super__.constructor.call(this,options,data)
this.joints={}
this.allowedConnections=this.getOption("allowedConnections")
this.domElement.attr("dia-id","dia-"+this.getId())
this.wc=KD.getSingleton("windowController")
this.on("KDObjectWillBeDestroyed",function(){return _this.emit("RemoveMyConnections")})}__extends(KDDiaObject,_super)
KDDiaObject.prototype.mouseDown=function(e){var _this=this
this.emit("DiaObjectClicked")
this._mouseDown=!0
this.wc.once("ReceivedMouseUpElsewhere",function(){return _this._mouseDown=!1})
return this.getOption("draggable")?void 0:this.utils.stopDOMEvent(e)}
KDDiaObject.prototype.mouseLeave=function(e){var bounds,joint
if(this._mouseDown){bounds=this.getBounds()
joint=null
bounds.w=bounds.w*this.parent.scale
bounds.h=bounds.h*this.parent.scale
e.pageX>=bounds.x+bounds.w&&(joint=this.joints.right)
e.pageX<=bounds.x&&(joint=this.joints.left)
e.pageY>=bounds.y+bounds.h&&(joint=this.joints.bottom)
e.pageY<=bounds.y&&(joint=this.joints.top)
return joint?this.emit("JointRequestsLine",joint):void 0}}
KDDiaObject.prototype.addJoint=function(type){var joint,jointItemClass,_base
if(null!=this.joints[type]){warn("KDDiaObject: Tried to add same joint! Destroying old one. ")
"function"==typeof(_base=this.joints[type]).destroy&&_base.destroy()}jointItemClass=this.getOption("jointItemClass")
this.addSubView(joint=new jointItemClass({type:type}))
return this.joints[type]=joint}
KDDiaObject.prototype.getJointPos=function(joint){var dx,dy,jx,jy,x,y,_ref,_ref1,_ref2,_ref3
"string"==typeof joint&&(joint=this.joints[joint])
if(!joint)return{x:0,y:0}
_ref=[this.parent.getRelativeX()+this.getRelativeX(),this.parent.getRelativeY()+this.getRelativeY()],x=_ref[0],y=_ref[1]
_ref1=[joint.getRelativeX(),joint.getRelativeY()],jx=_ref1[0],jy=_ref1[1]
_ref3="left"===(_ref2=joint.type)||"right"===_ref2?[10,2]:[2,10],dx=_ref3[0],dy=_ref3[1]
return{x:x+jx+dx,y:y+jy+dy}}
KDDiaObject.prototype.viewAppended=function(){var joint,_i,_len,_ref,_this=this
KDDiaObject.__super__.viewAppended.apply(this,arguments)
_ref=this.getOption("joints")
for(_i=0,_len=_ref.length;_len>_i;_i++){joint=_ref[_i]
this.addJoint(joint)}return this.parent.on("UnhighlightDias",function(){var key,_ref1,_results
_this.unsetClass("highlight")
_ref1=_this.joints
_results=[]
for(key in _ref1){joint=_ref1[key]
_results.push(joint.hideDeleteButton())}return _results})}
KDDiaObject.prototype.getDiaId=function(){return this.domElement.attr("dia-id")}
return KDDiaObject}(JView)

var KDDiaContainer,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDDiaContainer=function(_super){function KDDiaContainer(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("kddia-container",options.cssClass)
options.draggable&&"object"!=typeof options.draggable&&(options.draggable={})
null==options.itemClass&&(options.itemClass=KDDiaObject)
KDDiaContainer.__super__.constructor.call(this,options,data)
this.scale=1
this.dias={}}__extends(KDDiaContainer,_super)
KDDiaContainer.prototype.mouseDown=function(){var dia,key
KDDiaContainer.__super__.mouseDown.apply(this,arguments)
return this.emit("HighlightDia",function(){var _ref,_results
_ref=this.dias
_results=[]
for(key in _ref){dia=_ref[key]
_results.push(dia)}return _results}.call(this))}
KDDiaContainer.prototype.addDia=function(diaObj,pos){var _this=this
null==pos&&(pos={})
this.addSubView(diaObj)
diaObj.on("DiaObjectClicked",function(){return _this.emit("HighlightDia",diaObj)})
diaObj.on("RemoveMyConnections",function(){return delete _this.dias[diaObj.getId()]})
this.dias[diaObj.getId()]=diaObj
this.emit("NewDiaObjectAdded",this,diaObj)
null!=pos.x&&diaObj.setX(pos.x)
null!=pos.y&&diaObj.setY(pos.y)
return diaObj}
KDDiaContainer.prototype.addItem=function(data,options){var itemClass
null==options&&(options={})
itemClass=this.getOption("itemClass")
return this.addDia(new itemClass(options,data))}
KDDiaContainer.prototype.removeAllItems=function(){var dia,_key,_ref,_results
_ref=this.dias
_results=[]
for(_key in _ref){dia=_ref[_key]
_results.push("function"==typeof dia.destroy?dia.destroy():void 0)}return _results}
KDDiaContainer.prototype.setScale=function(scale){var css,prop,props,_i,_len
null==scale&&(scale=1)
if(scale!==this.scale){props=["webkitTransform","MozTransform","transform"]
css={}
for(_i=0,_len=props.length;_len>_i;_i++){prop=props[_i]
css[prop]="scale("+scale+")"}this.setStyle(css)
return this.scale=scale}}
return KDDiaContainer}(JView)

var KDDiaScene,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDDiaScene=function(_super){function KDDiaScene(options){null==options&&(options={})
options.cssClass=KD.utils.curry("kddia-scene",options.cssClass)
options.bind=KD.utils.curry("mousemove",options.bind)
options.lineCap||(options.lineCap="round")
null==options.lineWidth&&(options.lineWidth=2)
options.lineColor||(options.lineColor="#ccc")
options.lineColorActive||(options.lineColorActive="orange")
null==options.lineDashes&&(options.lineDashes=[])
options.fakeLineColor||(options.fakeLineColor="green")
null==options.fakeLineDashes&&(options.fakeLineDashes=[])
null==options.curveDistance&&(options.curveDistance=50)
KDDiaScene.__super__.constructor.apply(this,arguments)
this.containers=[]
this.connections=[]
this.activeDias=[]
this.activeJoints=[]
this.fakeConnections=[]}__extends(KDDiaScene,_super)
KDDiaScene.prototype.diaAdded=function(container,diaObj){var _this=this
diaObj.on("JointRequestsLine",this.bound("handleLineRequest"))
diaObj.on("DragInAction",function(){return _this.highlightLines(diaObj)})
return diaObj.on("RemoveMyConnections",function(){return _this.disconnectAllConnections(diaObj)})}
KDDiaScene.prototype.addContainer=function(container,pos){var padding,_ref,_ref1,_ref2,_ref3
null==pos&&(pos={})
this.addSubView(container)
container.on("NewDiaObjectAdded",this.bound("diaAdded"))
container.on("DragInAction",this.bound("updateScene"))
container.on("UpdateScene",this.bound("updateScene"))
container.on("HighlightDia",this.bound("highlightLines"))
this.containers.push(container)
padding=null!=(_ref=container.getOption("draggable"))?null!=(_ref1=_ref.containment)?_ref1.padding:void 0:void 0
if(padding){pos.x=Math.max(padding,null!=(_ref2=pos.x)?_ref2:0)
pos.y=Math.max(padding,null!=(_ref3=pos.y)?_ref3:0)}null!=pos.x&&container.setX(pos.x)
null!=pos.y&&container.setY(pos.y)
return this.createCanvas()}
KDDiaScene.prototype.drawFakeLine=function(options){var ex,ey,lineDashes,sx,sy
null==options&&(options={})
sx=options.sx,sy=options.sy,ex=options.ex,ey=options.ey
this.cleanup(this.fakeCanvas)
this.fakeContext.beginPath()
this.fakeContext.moveTo(sx,sy)
this.fakeContext.lineTo(ex,ey)
this.fakeContext.lineCap=this.getOption("lineCap")
this.fakeContext.lineWidth=this.getOption("lineWidth")
this.fakeContext.strokeStyle=this._trackJoint.parent.getOption("colorTag")||this.getOption("fakeLineColor")
lineDashes=this.getOption("fakeLineDashes")
lineDashes.length>0&&this.fakeContext.setLineDash(lineDashes)
return this.fakeContext.stroke()}
KDDiaScene.prototype.click=function(e){return e.target===e.currentTarget?this.highlightLines():void 0}
KDDiaScene.prototype.mouseMove=function(e){var ex,ey,x,y,_ref
if(this._trackJoint){_ref=this._trackJoint.getPos(),x=_ref.x,y=_ref.y
ex=x+(e.clientX-this._trackJoint.getX())
ey=y+(e.clientY-this._trackJoint.getY())
return this.drawFakeLine({sx:x,sy:y,ex:ex,ey:ey})}}
KDDiaScene.prototype.mouseUp=function(e){var source,sourceId,target,targetId
if(this._trackJoint){targetId=$(e.target).closest(".kddia-object").attr("dia-id")
sourceId=this._trackJoint.getDiaId()
delete this._trackJoint
this.cleanup(this.fakeCanvas)
if(targetId){source=this.getDia(sourceId)
target=this.getDia(targetId)
target.joint||(target.joint=this.guessJoint(target,source))
return target.joint?this.connect(source,target):void 0}}}
KDDiaScene.prototype.guessJoint=function(target,source){return"right"===source.joint&&null!=target.dia.joints.left?"left":"left"===source.joint&&null!=target.dia.joints.right?"right":void 0}
KDDiaScene.prototype.getDia=function(id){var container,dia,joint,objId,parts,_i,_len,_ref,_ref1
parts=id.match(/dia\-((.*)\-joint\-(.*)|(.*))/).filter(function(m){return!!m})
if(!parts)return null
_ref=parts.slice(-2),objId=_ref[0],joint=_ref[1]
objId===joint&&(joint=null)
_ref1=this.containers
for(_i=0,_len=_ref1.length;_len>_i;_i++){container=_ref1[_i]
if(dia=container.dias[objId])break}return{dia:dia,joint:joint,container:container}}
KDDiaScene.prototype.highlightLines=function(dia,update){var connection,container,joint,source,target,_i,_j,_k,_len,_len1,_len2,_ref,_ref1,_ref2,_results,_this=this
null==dia&&(dia=[])
null==update&&(update=!0)
Array.isArray(dia)||(dia=[dia])
this.activeDias=dia
_ref=this.activeJoints
for(_i=0,_len=_ref.length;_len>_i;_i++){joint=_ref[_i]
joint.off("DeleteRequested")}_ref1=this.containers
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){container=_ref1[_j]
container.emit("UnhighlightDias")}this.activeJoints=[]
update&&this.updateScene()
if(1===this.activeDias.length){dia=dia.first
_ref2=this.connections
_results=[]
for(_k=0,_len2=_ref2.length;_len2>_k;_k++){connection=_ref2[_k]
source=connection.source,target=connection.target
source.dia===dia||target.dia===dia?_results.push([source,target].forEach(function(conn){conn.dia.setClass("highlight")
if(conn.dia!==dia){joint=conn.dia.joints[conn.joint]
if(__indexOf.call(_this.activeJoints,joint)<0){joint.showDeleteButton()
joint.on("DeleteRequested",_this.bound("disconnect"))
return _this.activeJoints.push(joint)}}})):_results.push(void 0)}return _results}}
KDDiaScene.prototype.handleLineRequest=function(joint){return this._trackJoint=joint}
KDDiaScene.prototype.findTargetConnection=function(dia,joint){var activeDia,conn,isEqual,_i,_len,_ref
isEqual=function(connection){return dia===connection.dia&&joint===connection.joint}
activeDia=this.activeDias.first
_ref=this.connections
for(_i=0,_len=_ref.length;_len>_i;_i++){conn=_ref[_i]
if((isEqual(conn.source)||isEqual(conn.target))&&(conn.source.dia===activeDia||conn.target.dia===activeDia))return conn}}
KDDiaScene.prototype.disconnect=function(dia,joint){var c,connectionsToDelete
if(1===this.activeDias.length){connectionsToDelete=this.findTargetConnection(dia,joint)
this.connections=function(){var _i,_len,_ref,_results
_ref=this.connections
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){c=_ref[_i]
c!==connectionsToDelete&&_results.push(c)}return _results}.call(this)
return this.highlightLines(this.activeDias)}}
KDDiaScene.prototype.disconnectAllConnections=function(dia){var connection,newConnections,source,target,_i,_len,_ref,_ref1
newConnections=[]
_ref=this.connections
for(_i=0,_len=_ref.length;_len>_i;_i++){connection=_ref[_i]
source=connection.source,target=connection.target;(_ref1=dia.getDiaId())!==source.dia.getDiaId()&&_ref1!==target.dia.getDiaId()&&newConnections.push(connection)}this.connections=newConnections
return this.highlightLines()}
KDDiaScene.prototype.allowedToConnect=function(source,target){var allowList,i,restrictions,_i,_ref,_ref1,_ref2,_ref3
if(!source||!target)return!1
if((null!=(_ref=source.dia)?_ref.id:void 0)===(null!=(_ref1=target.dia)?_ref1.id:void 0))return!1
for(i=_i=0;1>=_i;i=++_i){if(null!=source.dia.allowedConnections&&Object.keys(source.dia.allowedConnections).length>0){allowList=source.dia.allowedConnections
restrictions=allowList[target.dia.constructor.name]
if(!restrictions)return!1
if(_ref2=source.joint,__indexOf.call(restrictions,_ref2)>=0)return!1}_ref3=[target,source],source=_ref3[0],target=_ref3[1]}return!0}
KDDiaScene.prototype.connect=function(source,target){if(this.allowedToConnect(source,target)){this.emit("ConnectionCreated",source,target)
this.connections.push({source:source,target:target})
return this.highlightLines(target.dia)}}
KDDiaScene.prototype.resetScene=function(){this.fakeConnections=[]
return this.updateScene()}
KDDiaScene.prototype.updateScene=function(){var connection,_i,_j,_len,_len1,_ref,_ref1,_results
this.cleanup(this.realCanvas)
_ref=this.connections
for(_i=0,_len=_ref.length;_len>_i;_i++){connection=_ref[_i]
this.drawConnectionLine(connection)}_ref1=this.fakeConnections
_results=[]
for(_j=0,_len1=_ref1.length;_len1>_j;_j++){connection=_ref1[_j]
_results.push(this.drawConnectionLine(connection))}return _results}
KDDiaScene.prototype.drawConnectionLine=function(_arg){var activeColor,activeDia,cd,lineColor,lineDashes,options,sJoint,source,sx,sy,tJoint,target,tx,ty,_ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6
source=_arg.source,target=_arg.target,options=_arg.options
if(source||target){options||(options={})
activeColor=this.getOption("lineColorActive")
lineDashes=this.getOption("lineDashes")
lineColor=this.getOption("lineColor")
this.realContext.beginPath()
activeDia=(_ref=source.dia,__indexOf.call(this.activeDias,_ref)>=0?source:(_ref1=target.dia,__indexOf.call(this.activeDias,_ref1)>=0?target:void 0))
if(activeDia){lineColor=options.lineColor||activeDia.dia.getOption("colorTag")||activeColor
lineDashes=options.lineDashes||activeDia.dia.getOption("lineDashes")||lineDashes}sJoint=source.dia.getJointPos(source.joint)
tJoint=target.dia.getJointPos(target.joint)
this.realContext.strokeStyle=lineColor
lineDashes.length>0&&this.realContext.setLineDash(lineDashes)
this.realContext.moveTo(sJoint.x,sJoint.y)
cd=this.getOption("curveDistance")
_ref2=[0,0,0,0],sx=_ref2[0],sy=_ref2[1],tx=_ref2[2],ty=_ref2[3]
"top"===(_ref3=source.joint)||"bottom"===_ref3?sy="top"===source.joint?-cd:cd:("left"===(_ref4=source.joint)||"right"===_ref4)&&(sx="left"===source.joint?-cd:cd)
"top"===(_ref5=target.joint)||"bottom"===_ref5?ty="top"===target.joint?-cd:cd:("left"===(_ref6=target.joint)||"right"===_ref6)&&(tx="left"===target.joint?-cd:cd)
this.realContext.bezierCurveTo(sJoint.x+sx,sJoint.y+sy,tJoint.x+tx,tJoint.y+ty,tJoint.x,tJoint.y)
this.realContext.lineWidth=this.getOption("lineWidth")
return this.realContext.stroke()}}
KDDiaScene.prototype.addFakeConnection=function(connection){this.drawConnectionLine(connection)
return this.fakeConnections.push(connection)}
KDDiaScene.prototype.createCanvas=function(){var _ref,_ref1
null!=(_ref=this.realCanvas)&&_ref.destroy()
null!=(_ref1=this.fakeCanvas)&&_ref1.destroy()
this.addSubView(this.realCanvas=new KDCustomHTMLView({tagName:"canvas",attributes:this.getSceneSize()}))
this.realContext=this.realCanvas.getElement().getContext("2d")
null==this.realContext.setLineDash&&(this.realContext.setLineDash=noop)
this.addSubView(this.fakeCanvas=new KDCustomHTMLView({tagName:"canvas",cssClass:"fakeCanvas",attributes:this.getSceneSize()}))
return this.fakeContext=this.fakeCanvas.getElement().getContext("2d")}
KDDiaScene.prototype.setScale=function(scale){var container,_i,_len,_ref
null==scale&&(scale=1)
_ref=this.containers
for(_i=0,_len=_ref.length;_len>_i;_i++){container=_ref[_i]
container.setScale(scale)}return this.updateScene()}
KDDiaScene.prototype.cleanup=function(canvas){return canvas.setAttributes(this.getSceneSize())}
KDDiaScene.prototype.parentDidResize=function(){var _this=this
KDDiaScene.__super__.parentDidResize.apply(this,arguments)
return _.throttle(function(){return _this.updateScene()})()}
KDDiaScene.prototype.getSceneSize=function(){return{width:this.getWidth(),height:this.getHeight()}}
KDDiaScene.prototype.dumpScene=function(){return log(this.containers,this.connections)}
return KDDiaScene}(JView)

var KDInputValidator
KDInputValidator=function(){function KDInputValidator(){}KDInputValidator.ruleRequired=function(input,event){var doesValidate,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
doesValidate=value.length>0
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.required:void 0)||"Field is required"}}
KDInputValidator.ruleEmail=function(input,event){var doesValidate,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
doesValidate=/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value)
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.email:void 0)||"Please enter a valid email address"}}
KDInputValidator.ruleMinLength=function(input,event){var doesValidate,minLength,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
minLength=ruleSet.rules.minLength
doesValidate=value.length>=minLength
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.minLength:void 0)||"Please enter a value that has "+minLength+" characters or more"}}
KDInputValidator.ruleMaxLength=function(input,event){var doesValidate,maxLength,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
maxLength=ruleSet.rules.maxLength
doesValidate=value.length<=maxLength
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.maxLength:void 0)||"Please enter a value that has "+maxLength+" characters or less"}}
KDInputValidator.ruleRangeLength=function(input,event){var doesValidate,rangeLength,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
rangeLength=ruleSet.rules.rangeLength
doesValidate=value.length<=rangeLength[1]&&value.length>=rangeLength[0]
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.rangeLength:void 0)||"Please enter a value that has more than "+rangeLength[0]+" and less than "+rangeLength[1]+" characters"}}
KDInputValidator.ruleMatch=function(input,event){var doesValidate,matchView,matchViewVal,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
matchView=ruleSet.rules.match
matchViewVal=$.trim(matchView.getValue())
doesValidate=value===matchViewVal
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.match:void 0)||"Values do not match"}}
KDInputValidator.ruleCreditCard=function(input,event){var doesValidate,ruleSet,type,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue().replace(/-|\s/g,""))
ruleSet=input.getOptions().validate
doesValidate=/(^4[0-9]{12}(?:[0-9]{3})?$)|(^5[1-5][0-9]{14}$)|(^3[47][0-9]{13}$)|(^3(?:0[0-5]|[68][0-9])[0-9]{11}$)|(^6(?:011|5[0-9]{2})[0-9]{12}$)|(^(?:2131|1800|35\d{3})\d{11}$)/.test(value)
if(doesValidate){type=/^4[0-9]{12}(?:[0-9]{3})?$/.test(value)?"Visa":/^5[1-5][0-9]{14}$/.test(value)?"MasterCard":/^3[47][0-9]{13}$/.test(value)?"Amex":/^3(?:0[0-5]|[68][0-9])[0-9]{11}$/.test(value)?"Diners":/^6(?:011|5[0-9]{2})[0-9]{12}$/.test(value)?"Discover":/^(?:2131|1800|35\d{3})\d{11}$/.test(value)?"JCB":!1
input.emit("CreditCardTypeIdentified",type)
return null}return(null!=(_ref=ruleSet.messages)?_ref.creditCard:void 0)||"Please enter a valid credit card number"}}
KDInputValidator.ruleJSON=function(input,event){var doesValidate,err,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
doesValidate=!0
try{value&&JSON.parse(value)}catch(_error){err=_error
error(err,doesValidate)
doesValidate=!1}return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.JSON:void 0)||"a valid JSON is required"}}
KDInputValidator.ruleRegExp=function(input,event){var doesValidate,regExp,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
regExp=ruleSet.rules.regExp
doesValidate=regExp.test(value)
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.regExp:void 0)||"Validation failed"}}
KDInputValidator.ruleUri=function(input,event){var doesValidate,regExp,ruleSet,value,_ref
if(9!==(null!=event?event.which:void 0)){regExp=/^([a-z0-9+.-]+):(?:\/\/(?:((?:[a-z0-9-._~!$&'()*+,;=:]|%[0-9A-F]{2})*)@)?((?:[a-z0-9-._~!$&'()*+,;=]|%[0-9A-F]{2})*)(?::(\d*))?(\/(?:[a-z0-9-._~!$&'()*+,;=:@\/]|%[0-9A-F]{2})*)?|(\/?(?:[a-z0-9-._~!$&'()*+,;=:@]|%[0-9A-F]{2})+(?:[a-z0-9-._~!$&'()*+,;=:@\/]|%[0-9A-F]{2})*)?)(?:\?((?:[a-z0-9-._~!$&'()*+,;=:\/?@]|%[0-9A-F]{2})*))?(?:)?$/i
value=$.trim(input.getValue())
ruleSet=input.getOptions().validate
doesValidate=regExp.test(value)
return doesValidate?null:(null!=(_ref=ruleSet.messages)?_ref.uri:void 0)||"Not a valid URI"}}
return KDInputValidator}()

var KDLabelView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDLabelView=function(_super){function KDLabelView(options){null!=(null!=options?options.title:void 0)&&this.setTitle(options.title)
KDLabelView.__super__.constructor.call(this,options)}__extends(KDLabelView,_super)
KDLabelView.prototype.setDomElement=function(cssClass){return this.domElement=$("<label class='kdlabel "+cssClass+"'>"+this.getTitle()+"</label>")}
KDLabelView.prototype.setTitle=function(title){return this.labelTitle=title||""}
KDLabelView.prototype.updateTitle=function(title){this.setTitle(title)
return this.$().html(title)}
KDLabelView.prototype.getTitle=function(){return this.labelTitle}
return KDLabelView}(KDView)

var KDInputView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDInputView=function(_super){function KDInputView(o,data){var options,_this=this
null==o&&(o={})
o.type||(o.type="text")
o.name||(o.name="")
o.label||(o.label=null)
o.cssClass||(o.cssClass="")
o.callback||(o.callback=null)
null==o.defaultValue&&(o.defaultValue="")
o.placeholder||(o.placeholder="")
null==o.disabled&&(o.disabled=!1)
o.selectOptions||(o.selectOptions=null)
o.validate||(o.validate=null)
o.hint||(o.hint=null)
null==o.autogrow&&(o.autogrow=!1)
null==o.enableTabKey&&(o.enableTabKey=!1)
o.bind||(o.bind="")
o.forceCase||(o.forceCase=null)
o.bind+=" blur change focus"
this.setType(o.type)
KDInputView.__super__.constructor.call(this,o,data)
options=this.getOptions()
this.validationNotifications={}
this.valid=!0
this.inputCallback=null
this.setName(options.name)
this.setLabel()
this.setCallback()
this.setDefaultValue(options.defaultValue)
this.setPlaceHolder(options.placeholder)
options.disabled&&this.makeDisabled()
null!=options.selectOptions&&"function"!=typeof options.selectOptions&&this.setSelectOptions(options.selectOptions)
options.autogrow&&this.setAutoGrow()
options.enableTabKey&&this.enableTabKey()
options.forceCase&&this.setCase(options.forceCase)
options.required&&function(v){null==v.rules&&(v.rules={})
null==v.messages&&(v.messages={})
v.rules.required=!0
return v.messages.required=options.required}(null!=options.validate?options.validate:options.validate={})
options.validate&&this.setValidation(options.validate)
this.bindValidationEvents()
"select"===options.type&&options.selectOptions&&this.on("viewAppended",function(){var kallback
o=_this.getOptions()
if("function"==typeof o.selectOptions){kallback=_this.bound("setSelectOptions")
return o.selectOptions.call(_this,kallback)}if(o.selectOptions.length){if(!o.defaultValue)return _this.setValue(o.selectOptions[0].value)}else if(!o.defaultValue)return _this.setValue(o.selectOptions[Object.keys(o.selectOptions)[0]][0].value)})}var _prevVal
__extends(KDInputView,_super)
KDInputView.prototype.setDomElement=function(cssClass){var name
null==cssClass&&(cssClass="")
name="name='"+this.options.name+"'"
return this.domElement=function(){switch(this.getType()){case"text":return $("<input "+name+" type='text' class='kdinput text "+cssClass+"'/>")
case"password":return $("<input "+name+" type='password' class='kdinput text "+cssClass+"'/>")
case"hidden":return $("<input "+name+" type='hidden' class='kdinput hidden "+cssClass+"'/>")
case"checkbox":return $("<input "+name+" type='checkbox' class='kdinput checkbox "+cssClass+"'/>")
case"textarea":return $("<textarea "+name+" class='kdinput text "+cssClass+"'></textarea>")
case"select":return $("<select "+name+" class='kdinput select "+cssClass+"'/>")
case"range":return $("<input "+name+" type='range' class='kdinput range "+cssClass+"'/>")
default:return $("<input "+name+" type='"+this.getType()+"' class='kdinput "+this.getType()+" "+cssClass+"'/>")}}.call(this)}
KDInputView.prototype.bindValidationEvents=function(){this.on("ValidationError",this.bound("giveValidationFeedback"))
this.on("ValidationPassed",this.bound("giveValidationFeedback"))
return this.on("focus",this.bound("clearValidationFeedback"))}
KDInputView.prototype.setLabel=function(label){var _this=this
null==label&&(label=this.getOptions().label)
if(label){this.inputLabel=label
this.inputLabel.$()[0].setAttribute("for",this.getName())
return this.inputLabel.$().bind("click",function(){_this.$().trigger("focus")
return _this.$().trigger("click")})}}
KDInputView.prototype.getLabel=function(){return this.inputLabel}
KDInputView.prototype.setCallback=function(){return this.inputCallback=this.getOptions().callback}
KDInputView.prototype.getCallback=function(){return this.inputCallback}
KDInputView.prototype.setType=function(inputType){this.inputType=null!=inputType?inputType:"text"}
KDInputView.prototype.getType=function(){return this.inputType}
KDInputView.prototype.setName=function(inputName){this.inputName=inputName}
KDInputView.prototype.getName=function(){return this.inputName}
KDInputView.prototype.setFocus=function(){KD.getSingleton("windowController").setKeyView(this)
return this.$().trigger("focus")}
KDInputView.prototype.setBlur=function(){KD.getSingleton("windowController").setKeyView(null)
return this.$().trigger("blur")}
KDInputView.prototype.setSelectOptions=function(options){var $optGroup,optGroup,option,subOptions,_i,_j,_len,_len1
if(options.length)if(options.length)for(_j=0,_len1=options.length;_len1>_j;_j++){option=options[_j]
this.$().append("<option value='"+option.value+"'>"+option.title+"</option>")}else warn("no valid options specified for the input:",this)
else for(optGroup in options)if(__hasProp.call(options,optGroup)){subOptions=options[optGroup]
$optGroup=$("<optgroup label='"+optGroup+"'/>")
this.$().append($optGroup)
for(_i=0,_len=subOptions.length;_len>_i;_i++){option=subOptions[_i]
$optGroup.append("<option value='"+option.value+"'>"+option.title+"</option>")}}return this.$().val(this.getDefaultValue())}
KDInputView.prototype.setDefaultValue=function(value){if(null!=value||""===value){KDInputView.prototype.setValue.call(this,value)
return this.inputDefaultValue=value}}
KDInputView.prototype.getDefaultValue=function(){return this.inputDefaultValue}
KDInputView.prototype.setPlaceHolder=function(value){if(this.$().is("input")||this.$().is("textarea")){this.$().attr("placeholder",value)
return this.options.placeholder=value}}
KDInputView.prototype.makeDisabled=function(){return this.getDomElement().attr("disabled","disabled")}
KDInputView.prototype.makeEnabled=function(){return this.getDomElement().removeAttr("disabled")}
KDInputView.prototype.getValue=function(){var forceCase,value
if("checkbox"===this.getOption("type"))value=this.$().is(":checked")
else{value=this.getDomElement().val()
forceCase=this.getOptions().forceCase
forceCase&&(value="uppercase"===forceCase.toLowerCase()?value.toUpperCase():value.toLowerCase())}return value}
KDInputView.prototype.setValue=function(value){var $el,el,_ref
$el=this.$()
el=$el[0]
return"checkbox"===(_ref=this.getOption("type"))||"radio"===_ref?value?el.setAttribute("checked","checked"):el.removeAttribute("checked"):$el.val(value)}
_prevVal=null
KDInputView.prototype.setCase=function(){var cb,_this=this
cb=function(){var val
val=_this.getValue()
return val!==_prevVal?_this.setValue(_prevVal=val):void 0}
this.on("keyup",cb.bind(this))
return this.on("blur",cb.bind(this))}
KDInputView.prototype.unsetValidation=function(){return this.setValidation({})}
KDInputView.prototype.setValidation=function(ruleSet){var oldCallback,oldCallbacks,oldEventName,_i,_len,_ref,_this=this
this.valid=!1
this.currentRuleset=ruleSet
this.validationCallbacks||(this.validationCallbacks={})
this.createRuleChain(ruleSet)
_ref=this.validationCallbacks
for(oldEventName in _ref)if(__hasProp.call(_ref,oldEventName)){oldCallbacks=_ref[oldEventName]
for(_i=0,_len=oldCallbacks.length;_len>_i;_i++){oldCallback=oldCallbacks[_i]
this.off(oldEventName,oldCallback)}}return this.ruleChain.forEach(function(rule){var cb,eventName,_base
eventName=ruleSet.events?ruleSet.events[rule]?ruleSet.events[rule]:ruleSet.event?ruleSet.event:void 0:ruleSet.event?ruleSet.event:void 0
if(eventName){(_base=_this.validationCallbacks)[eventName]||(_base[eventName]=[])
_this.validationCallbacks[eventName].push(cb=function(event){return __indexOf.call(_this.ruleChain,rule)>=0?_this.validate(rule,event):void 0})
return _this.on(eventName,cb)}})}
KDInputView.prototype.validate=function(rule,event){var allClear,errMsg,result,ruleSet,rulesToBeValidated,_ref,_this=this
null==event&&(event={})
this.ruleChain||(this.ruleChain=[])
this.validationResults||(this.validationResults={})
rulesToBeValidated=rule?[rule]:this.ruleChain
ruleSet=this.currentRuleset||this.getOptions().validate
this.ruleChain.length>0?rulesToBeValidated.forEach(function(rule){var result
if(null!=KDInputValidator["rule"+rule.capitalize()]){result=KDInputValidator["rule"+rule.capitalize()](_this,event)
return _this.setValidationResult(rule,result)}return"function"==typeof ruleSet.rules[rule]?ruleSet.rules[rule](_this,event):void 0}):this.valid=!0
allClear=!0
_ref=this.validationResults
for(result in _ref)if(__hasProp.call(_ref,result)){errMsg=_ref[result]
errMsg&&(allClear=!1)}this.valid=allClear?!0:!1
this.valid&&this.emit("ValidationPassed")
this.emit("ValidationResult",this.valid)
return this.valid}
KDInputView.prototype.createRuleChain=function(ruleSet){var rule,rules,value,_i,_len,_ref,_results
rules=ruleSet.rules
this.validationResults||(this.validationResults={})
this.ruleChain="object"==typeof rules?function(){var _results
_results=[]
for(rule in rules)if(__hasProp.call(rules,rule)){value=rules[rule]
_results.push(rule)}return _results}():[rules]
_ref=this.ruleChain
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){rule=_ref[_i]
_results.push(this.validationResults[rule]=null)}return _results}
KDInputView.prototype.setValidationResult=function(rule,err,showNotification){null==showNotification&&(showNotification=!0)
if(err){this.validationResults[rule]=err
this.getOptions().validate.notifications&&showNotification&&this.showValidationError(err)
this.emit("ValidationError",err)
return this.valid=!1}this.validationResults[rule]=null
return this.valid=!_.values(this.validationResults).map(function(result){return Boolean(result)}).indexOf(!0)>-1}
KDInputView.prototype.showValidationError=function(message){var container,notice,notifications,str,_ref,_ref1,_this=this
null!=(_ref=this.validationNotifications[message])&&_ref.destroy()
_ref1=this.getOption("validate"),container=_ref1.container,notifications=_ref1.notifications
if("tooltip"===(null!=notifications?notifications.type:void 0)){this.tooltip&&(str="- "+message+"<br>"+this.tooltip.getOption("title"))
this.unsetTooltip()
notifications={cssClass:notifications.cssClass||"input-validation",delegate:notifications.delegate||this,title:notifications.title||str||message,placement:notifications.placement||"right",direction:notifications.direction||"left",forcePosition:!0}
this.validationNotifications[message]=notice=this.setTooltip(notifications)
notice.show()}else notifications&&(this.validationNotifications[message]=notice=new KDNotificationView({container:container?container:void 0,title:message,type:"growl",cssClass:"mini",duration:2500}))
return notice.on("KDObjectWillBeDestroyed",function(){message=notice.getOptions().title
return delete _this.validationNotifications[message]})}
KDInputView.prototype.clearValidationFeedback=function(){this.unsetClass("validation-error validation-passed")
return this.emit("ValidationFeedbackCleared")}
KDInputView.prototype.giveValidationFeedback=function(err){if(err)return this.setClass("validation-error")
this.setClass("validation-passed")
return this.unsetClass("validation-error")}
KDInputView.prototype.setCaretPosition=function(pos){return this.selectRange(pos,pos)}
KDInputView.prototype.getCaretPosition=function(){var el,r,rc,re
el=this.$()[0]
if(el.selectionStart)return el.selectionStart
if(document.selection){el.focus()
r=document.selection.createRange()
if(!r)return 0
re=el.createTextRange()
rc=re.duplicate()
re.moveToBookmark(r.getBookmark())
rc.setEndPoint("EndToStart",re)
return rc.text.length}return 0}
KDInputView.prototype.selectAll=function(){return this.getDomElement().select()}
KDInputView.prototype.selectRange=function(selectionStart,selectionEnd){var input,range
input=this.$()[0]
if(input.setSelectionRange){input.focus()
return input.setSelectionRange(selectionStart,selectionEnd)}if(input.createTextRange){range=input.createTextRange()
range.collapse(!0)
range.moveEnd("character",selectionEnd)
range.moveStart("character",selectionStart)
return range.select()}}
KDInputView.prototype.setAutoGrow=function(){var $input,_this=this
$input=this.$()
$input.css("overflow","hidden")
this.setClass("autogrow")
this._clone=$("<div/>",{"class":"invisible"})
this.on("focus",function(){return _this.utils.defer(function(){_this._clone.appendTo("body")
return _this._clone.css({height:"auto",zIndex:1e5,width:$input.width(),border:$input.css("border"),padding:$input.css("padding"),wordBreak:$input.css("wordBreak"),fontSize:$input.css("fontSize"),lineHeight:$input.css("lineHeight"),whiteSpace:"pre-line"})})})
this.on("blur",function(){_this._clone.detach()
return _this.$()[0].style.height="none"})
return this.on("keyup",function(){return _this.resize()})}
KDInputView.prototype.resize=function(){var border,height,padding
if(this._clone){document.body.contains(this._clone[0])||this._clone.appendTo("body")
this._clone.html(Encoder.XSSEncode(this.getValue()))
this._clone.append(document.createElement("br"))
height=this._clone.height()
if("border-box"===this.$().css("boxSizing")){padding=parseInt(this._clone.css("paddingTop"),10)+parseInt(this._clone.css("paddingBottom"),10)
border=parseInt(this._clone.css("borderTopWidth"),10)+parseInt(this._clone.css("borderBottomWidth"),10)
height=height+border+padding}return this.setHeight(Math.max(this.initialHeight,height))}}
KDInputView.prototype.enableTabKey=function(){return this.inputTabKeyEnabled=!0}
KDInputView.prototype.disableTabKey=function(){return this.inputTabKeyEnabled=!1}
KDInputView.prototype.change=function(){}
KDInputView.prototype.keyUp=function(){return!0}
KDInputView.prototype.keyDown=function(event){this.inputTabKeyEnabled&&this.checkTabKey(event)
return!0}
KDInputView.prototype.focus=function(){this.setKeyView()
return!0}
KDInputView.prototype.blur=function(){KD.getSingleton("windowController").revertKeyView(this)
return!0}
KDInputView.prototype.mouseDown=function(){this.setFocus()
return!1}
KDInputView.prototype.checkTabKey=function(event){var post,pre,se,sel,ss,t,tab,tabLength
tab="  "
tabLength=tab.length
t=event.target
ss=t.selectionStart
se=t.selectionEnd
if(9===event.which){event.preventDefault()
if(ss!==se&&-1!==t.value.slice(ss,se).indexOf("n")){pre=t.value.slice(0,ss)
sel=t.value.slice(ss,se).replace(/n/g,"n"+tab)
post=t.value.slice(se,t.value.length)
t.value=pre.concat(tab).concat(sel).concat(post)
t.selectionStart=ss+tab.length
return t.selectionEnd=se+tab.length}t.value=t.value.slice(0,ss).concat(tab).concat(t.value.slice(ss,t.value.length))
if(ss===se)return t.selectionStart=t.selectionEnd=ss+tab.length
t.selectionStart=ss+tab.length
return t.selectionEnd=se+tab.length}if(8===event.which&&t.value.slice(ss-tabLength,ss)===tab){event.preventDefault()
t.value=t.value.slice(0,ss-tabLength).concat(t.value.slice(ss,t.value.length))
return t.selectionStart=t.selectionEnd=ss-tab.length}if(46===event.which&&t.value.slice(se,se+tabLength)===tab){event.preventDefault()
t.value=t.value.slice(0,ss).concat(t.value.slice(ss+tabLength,t.value.length))
return t.selectionStart=t.selectionEnd=ss}if(37===event.which&&t.value.slice(ss-tabLength,ss)===tab){event.preventDefault()
return t.selectionStart=t.selectionEnd=ss-tabLength}if(39===event.which&&t.value.slice(ss,ss+tabLength)===tab){event.preventDefault()
return t.selectionStart=t.selectionEnd=ss+tabLength}}
KDInputView.prototype.viewAppended=function(){return this.initialHeight=this.$().height()}
return KDInputView}(KDView)

var KDDelimitedInputView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDDelimitedInputView=function(_super){function KDDelimitedInputView(options,data){var defaultValue
null==options&&(options={})
null==options.delimiter&&(options.delimiter=",")
null==options.usePadding&&(options.usePadding=!0)
defaultValue=options.defaultValue
null!=(null!=defaultValue?defaultValue.join:void 0)&&(options.defaultValue=this.join(defaultValue,options))
KDDelimitedInputView.__super__.constructor.call(this,options,data)}__extends(KDDelimitedInputView,_super)
KDDelimitedInputView.prototype.change=function(){return this.setValue(this.getValue())}
KDDelimitedInputView.prototype.getPadding=function(options){null==options&&(options=this.getOptions())
return options.usePadding?" ":""}
KDDelimitedInputView.prototype.split=function(value,options){null==options&&(options=this.getOptions())
return this.utils.splitTrim(value,options.delimiter)}
KDDelimitedInputView.prototype.join=function(value,options){null==options&&(options=this.getOptions())
return value.join(""+options.delimiter+this.getPadding(options))}
KDDelimitedInputView.prototype.getValue=function(){return this.split(KDDelimitedInputView.__super__.getValue.apply(this,arguments))}
KDDelimitedInputView.prototype.setValue=function(value){return KDDelimitedInputView.__super__.setValue.call(this,null!=value.join?this.join(value):value)}
return KDDelimitedInputView}(KDInputView)

var KDInputViewWithPreview,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDInputViewWithPreview=function(_super){function KDInputViewWithPreview(options,data){var _base,_base1,_base2,_base3,_this=this
null==options&&(options={})
options.preview||(options.preview={})
null==(_base=options.preview).autoUpdate&&(_base.autoUpdate=!0);(_base1=options.preview).language||(_base1.language="markdown")
null==(_base2=options.preview).showInitially&&(_base2.showInitially=!0)
null==(_base3=options.preview).mirrorScroll&&(_base3.mirrorScroll=!0)
null==options.allowMaximized&&(options.allowMaximized=!0)
null==options.openMaximized&&(options.openMaximized=!1)
null==options.showHelperModal&&(options.showHelperModal=!0)
null==options.keyup&&(options.keyup=function(){_this.options.preview.autoUpdate&&_this.generatePreview()
return!0})
null==options.focus&&(options.focus=function(){_this.options.preview.autoUpdate&&_this.generatePreview()
return!0})
KDInputViewWithPreview.__super__.constructor.call(this,options,data)
this.setClass("kdinputwithpreview")
this.showPreview=options.preview.showInitially||!1
this.previewOnOffLabel=new KDLabelView({cssClass:"preview_switch_label unselectable",title:"Preview",tooltip:{title:"Show/hide the Text Preview Box"},click:function(){_this.previewOnOffSwitch.setValue(!_this.previewOnOffSwitch.getValue())
return!1}})
this.previewOnOffSwitch=new KDOnOffSwitch({label:this.previewOnOffLabel,size:"tiny",defaultValue:this.showPreview?!0:!1,callback:function(state){if(state){_this.showPreview=!0
_this.generatePreview()
_this.$("div.preview_content").removeClass("hidden")
_this.$("div.preview_switch").removeClass("content-hidden")
_this.$().removeClass("content-hidden")
return _this.emit("PreviewShown")}_this.$("div.preview_content").addClass("hidden")
_this.$("div.preview_switch").addClass("content-hidden")
_this.$().addClass("content-hidden")
return _this.emit("PreviewHidden")}})
this.previewOnOffContainer=new KDView({cssClass:"preview_switch"})
if(this.options.showHelperModal){this.markdownLink=this.getMarkdownLink()
this.previewOnOffContainer.addSubView(this.markdownLink)}if(this.options.allowMaximized){this.fullscreenEditButton=this.getFullscreenEditButton()
this.previewOnOffContainer.addSubView(this.fullscreenEditButton)}this.previewOnOffContainer.addSubView(this.previewOnOffLabel)
this.previewOnOffContainer.addSubView(this.previewOnOffSwitch)
this.addSubView(this.previewOnOffContainer)
this.listenWindowResize()}__extends(KDInputViewWithPreview,_super)
KDInputViewWithPreview.prototype.setPaneSizes=function(opt_setWidths){var contentWidth,fullscreenData,halfWidth,inputPreview,kdmodalContent,kdmodalContentHeight
null==opt_setWidths&&(opt_setWidths=!0)
if(this.modal){kdmodalContent=this.modal.$(".kdmodal-content")
fullscreenData=this.modal.$(".fullscreen-data")
inputPreview=this.modal.$(".input_preview")
kdmodalContent.height(this.modal.$(".kdmodal-inner").height()-this.modal.$(".kdmodal-buttons").height()-this.modal.$(".kdmodal-title").height())
kdmodalContentHeight=kdmodalContent.height()
fullscreenData.height(kdmodalContentHeight-30-23+10)
inputPreview.height(kdmodalContentHeight-0-21+10)
this.modal.$(".input_preview div.preview_content").css("maxHeight",kdmodalContentHeight-0-21)
contentWidth=kdmodalContent.width()-40
halfWidth=contentWidth/2
this.text.on("PreviewHidden",function(){return fullscreenData.width(contentWidth)})
this.text.on("PreviewShown",function(){return fullscreenData.width(contentWidth-halfWidth-5)})
if(opt_setWidths){fullscreenData.width(contentWidth-halfWidth-5)
inputPreview.width(halfWidth-5)}return this.modal.$().height(window.innerHeight-55)}}
KDInputViewWithPreview.prototype.getMarkdownLink=function(){return new KDCustomHTMLView({tagName:"a",cssClass:"markdown-link unselectable",partial:"What is Markdown?",tooltip:{title:"Show available Markdown formatting syntax"},click:function(){return new MarkdownModal}})}
KDInputViewWithPreview.prototype.getFullscreenEditButton=function(){var _this=this
return new KDButtonView({style:"clean-gray small",cssClass:"fullscreen-button",title:"Fullscreen Edit",icon:!1,tooltip:{title:"Open a Fullscreen Editor"},callback:function(){_this.textContainer=new KDView({cssClass:"modal-fullscreen-text"})
_this.text=new KDInputViewWithPreview({type:"textarea",cssClass:"fullscreen-data kdinput text",allowMaximized:!1,defaultValue:_this.getValue()})
_this.textContainer.addSubView(_this.text)
_this.modal=new KDModalView({title:"Please enter your content here.",cssClass:"modal-fullscreen",width:window.innerWidth-100,height:window.innerHeight-55,overlay:!0,view:_this.textContainer,buttons:{Apply:{title:"Apply changes",style:"modal-clean-gray",callback:function(){_this.setValue(_this.text.getValue())
_this.generatePreview()
return _this.modal.destroy()}},Cancel:{title:"cancel",style:"modal-cancel",callback:function(){return _this.modal.destroy()}}}})
return _this.utils.defer(function(){return _this.setPaneSizes()})}})}
KDInputViewWithPreview.prototype.getEditScrollPercentage=function(){var scrollHeight,scrollMaxheight,scrollPosition
scrollPosition=this.$().scrollTop()
scrollHeight=this.$().height()
scrollMaxheight=this.getDomElement()[0].scrollHeight
return 100*(scrollPosition/(scrollMaxheight-scrollHeight))}
KDInputViewWithPreview.prototype.setPreviewScrollPercentage=function(percentage){var s
s=this.$("div.preview_content")
return s.animate({scrollTop:(s[0].scrollHeight-s.height())*percentage/100},50,"linear")}
KDInputViewWithPreview.prototype.setDomElement=function(cssClass){var name
null==cssClass&&(cssClass="")
this.inputName=this.getOptions().name
name="name='"+this.inputName+"'"
return this.domElement=$("<textarea "+name+" class='kdinput text "+cssClass+"'></textarea>\n<div class='input_preview kdinputwithpreview preview-"+this.options.preview.language+'\'>\n  <div class="preview_content"><span class="data"></span></div>\n</div>')}
KDInputViewWithPreview.prototype.viewAppended=function(){var _this=this
KDInputViewWithPreview.__super__.viewAppended.apply(this,arguments)
this.$("div.preview_content").addClass("has-"+this.options.preview.language)
if(this.showPreview){this.generatePreview()
this.previewOnOffSwitch.setValue(!0)}else{this.$("div.preview_content").addClass("hidden")
this.$("div.preview_switch").addClass("content-hidden")
this.$().addClass("content-hidden")
this.previewOnOffSwitch.setValue(!1)}this.$("label").on("click",function(){return _this.$("input.checkbox").get(0).click()})
this.utils.defer(function(){return _this.$("span.data").css({display:"block"})})
return this.options.preview.mirrorScroll?this.$().scroll(function(){return _this.setPreviewScrollPercentage(_this.getEditScrollPercentage())}):void 0}
KDInputViewWithPreview.prototype.setValue=function(value){var _ref
KDInputViewWithPreview.__super__.setValue.call(this,value)
null!=(_ref=this.text)&&_ref.setValue(value)
return this.generatePreview()}
KDInputViewWithPreview.prototype.generatePreview=function(){if(this.showPreview&&"markdown"===this.options.preview.language){this.$("div.preview_content span.data").html(this.utils.applyMarkdown(this.getValue()))
return this.$("div.preview_content span.data pre").each(function(i,element){return hljs.highlightBlock(element)})}}
KDInputViewWithPreview.prototype._windowDidResize=function(){var _this=this
return this.utils.defer(function(){var opt_setWidths
opt_setWidths=_this.previewOnOffSwitch.defaultValue===!0
return _this.setPaneSizes(opt_setWidths)})}
return KDInputViewWithPreview}(KDInputView)

var KDHitEnterInputView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDHitEnterInputView=function(_super){function KDHitEnterInputView(options,data){var _ref,_this=this
null==options&&(options={})
options.type||(options.type="textarea")
options.button||(options.button=null)
null==options.showButton&&(options.showButton=!1)
options.label||(options.label=null)
options.placeholder||(options.placeholder="")
options.callback||(options.callback=null)
options.togglerPartials||(options.togglerPartials=["quick update disabled","quick update enabled"])
KDHitEnterInputView.__super__.constructor.call(this,options,data)
this.setClass("hitenterview")
this.button=null!=(_ref=this.getOptions().button)?_ref:null
this.enableEnterKey()
null!=options.label&&this.setToggler()
this.getOptions().showButton&&this.disableEnterKey()
this.on("ValidationPassed",function(){var _ref1
_this.blur()
return null!=(_ref1=_this.getOptions().callback)?_ref1.call(_this,_this.getValue()):void 0})}__extends(KDHitEnterInputView,_super)
KDHitEnterInputView.prototype.enableEnterKey=function(){this.setClass("active")
this.button&&this.hideButton()
null!=this.inputEnterToggler&&this.inputEnterToggler.$().html(this.getOptions().togglerPartials[1])
return this.enterKeyEnabled=!0}
KDHitEnterInputView.prototype.disableEnterKey=function(){this.unsetClass("active")
this.button&&this.showButton()
null!=this.inputEnterToggler&&this.inputEnterToggler.$().html(this.getOptions().togglerPartials[0])
return this.enterKeyEnabled=!1}
KDHitEnterInputView.prototype.setToggler=function(){var o
o=this.getOptions()
this.inputEnterToggler=new KDCustomHTMLView({tagName:"a",cssClass:"hitenterview-toggle",partial:o.showButton?o.togglerPartials[0]:o.togglerPartials[1],click:this.bound("toggleEnterKey")})
return this.inputLabel.addSubView(this.inputEnterToggler)}
KDHitEnterInputView.prototype.hideButton=function(){return this.button.hide()}
KDHitEnterInputView.prototype.showButton=function(){return this.button.show()}
KDHitEnterInputView.prototype.toggleEnterKey=function(){return this.enterKeyEnabled?this.disableEnterKey():this.enableEnterKey()}
KDHitEnterInputView.prototype.keyDown=function(event){if(13===event.which&&(event.altKey||event.shiftKey)!==!0&&this.enterKeyEnabled){this.emit("EnterPerformed")
this.validate()
return!1}}
return KDHitEnterInputView}(KDInputView)

var KDInputRadioGroup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDInputRadioGroup=function(_super){function KDInputRadioGroup(options){options.type||(options.type="radio")
null==options.hideRadios&&(options.hideRadios=!1)
null==options.showIcons&&(options.showIcons=!1)
options.cssClassPrefix||(options.cssClassPrefix="")
KDInputRadioGroup.__super__.constructor.call(this,options)
this._currentValue=this.getOption("defaultValue")}__extends(KDInputRadioGroup,_super)
KDInputRadioGroup.prototype.setDomElement=function(){var disabledClass,div,i,label,options,radio,radioOptions,_i,_len,_ref
options=this.getOptions()
this.domElement=$("<fieldset class='"+this.utils.curry("radiogroup kdinput",options.cssClass)+"'></fieldset>")
_ref=options.radios
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){radioOptions=_ref[i]
null==radioOptions.visible&&(radioOptions.visible=!0)
radioOptions.callback||(radioOptions.callback=function(){})
disabledClass=radioOptions.disabled?"disabled ":""
div=$("<div/>",{"class":"kd-"+this.getType()+"-holder "+disabledClass+options.cssClassPrefix+this.utils.slugify(radioOptions.value)})
radio=$("<input/>",{type:this.getType(),name:options.name,value:radioOptions.value,"class":"no-kdinput"+(options.hideRadios?" hidden":""),id:""+this.getId()+"_"+this.getType()+"_"+i,change:radioOptions.callback})
radioOptions.disabled&&radio[0].setAttribute("disabled","disabled")
label=$("<label/>",{"for":""+this.getId()+"_"+this.getType()+"_"+i,html:radioOptions.title,"class":options.cssClassPrefix+this.utils.slugify(radioOptions.value)})
div.append(radio)
options.showIcons&&div.append($("<span/>",{"class":"icon"}))
div.append(label)
this.domElement.append(div)
radioOptions.visible||div.hide()}return this.domElement}
KDInputRadioGroup.prototype.click=function(event){var input
input=$(event.target).closest(".kd-"+this.getType()+"-holder").find("input")
return input.length<1?void 0:"disabled"===input[0].getAttribute("disabled")?!1:this.setValue(input[0].getAttribute("value"))}
KDInputRadioGroup.prototype.setDefaultValue=function(value){this.inputDefaultValue=value
return this.setValue(value,!0)}
KDInputRadioGroup.prototype.getValue=function(){return this.$("input[checked=checked]").val()}
KDInputRadioGroup.prototype.setValue=function(value,isDefault){var inputElement
null==isDefault&&(isDefault=!1)
this.$("input").attr("checked",!1)
inputElement=this.$("input[value='"+value+"']")
inputElement.attr("checked","checked")
inputElement.prop("checked",!0)
null==value||value===this._currentValue||isDefault||this.emit("change",value)
this._currentValue=value
this.$(".kd-radio-holder").removeClass("active")
return null!=value&&""!==value?this.$(".kd-radio-holder."+value).addClass("active"):void 0}
KDInputRadioGroup.prototype.getInputElements=function(){return this.getDomElement().find("input")}
return KDInputRadioGroup}(KDInputView)

var KDInputCheckboxGroup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDInputCheckboxGroup=function(_super){function KDInputCheckboxGroup(options,data){null==options&&(options={})
options.checkboxes||(options.checkboxes=[])
options.radios||(options.radios=options.checkboxes)
options.type||(options.type="checkbox")
KDInputCheckboxGroup.__super__.constructor.call(this,options,data)}__extends(KDInputCheckboxGroup,_super)
KDInputCheckboxGroup.prototype.click=function(event){return"LABEL"!==event.target.tagName?this.setValue(this.getValue()):void 0}
KDInputCheckboxGroup.prototype.getValue=function(){var el,values,_i,_len,_ref
values=[]
_ref=this.getDomElement().find("input:checked")
for(_i=0,_len=_ref.length;_len>_i;_i++){el=_ref[_i]
values.push($(el).val())}return values}
KDInputCheckboxGroup.prototype.setValue=function(value){var v,_i,_len,_results
this.$("input").prop("checked",!1)
this.$(".kd-radio-holder").removeClass("active")
if(value instanceof Array){_results=[]
for(_i=0,_len=value.length;_len>_i;_i++){v=value[_i]
_results.push(this._setValue(v))}return _results}return this._setValue(value)}
KDInputCheckboxGroup.prototype._setValue=function(value){this.$("input[value='"+value+"']").prop("checked",!0)
return value?this.$(".kd-radio-holder.role-"+value).addClass("active"):void 0}
return KDInputCheckboxGroup}(KDInputRadioGroup)

var KDInputSwitch,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDInputSwitch=function(_super){function KDInputSwitch(options){null==options&&(options={})
options.type="switch"
KDInputSwitch.__super__.constructor.call(this,options)
this.setPartial("<input class='checkbox hidden no-kdinput' type='checkbox' name='"+this.getName()+"'/>")}__extends(KDInputSwitch,_super)
KDInputSwitch.prototype.setDomElement=function(){return this.domElement=$("<span class='kdinput kdinputswitch off'></span>")}
KDInputSwitch.prototype.setDefaultValue=function(value){switch(value){case!0:case"on":case"true":case"yes":case 1:return this._setDefaultValue(!0)
default:return this._setDefaultValue(!1)}}
KDInputSwitch.prototype.getDefaultValue=function(){return this.inputDefaultValue}
KDInputSwitch.prototype.getValue=function(){return this.getDomElement().find("input").eq(0).is(":checked")}
KDInputSwitch.prototype.setValue=function(value){switch(value){case!0:return this.switchAnimateOn()
case!1:return this.switchAnimateOff()}}
KDInputSwitch.prototype._setDefaultValue=function(val){var _this=this
return setTimeout(function(){val=!!val
if(val){_this.inputDefaultValue=!0
_this.getDomElement().find("input").eq(0).attr("checked",!0)
return _this.getDomElement().removeClass("off").addClass("on")}_this.inputDefaultValue=!1
_this.getDomElement().find("input").eq(0).attr("checked",!1)
return _this.getDomElement().removeClass("on").addClass("off")},0)}
KDInputSwitch.prototype.switchAnimateOff=function(){var counter,timer,_this=this
if(this.getValue()){counter=0
return timer=setInterval(function(){_this.getDomElement().css("background-position","left -"+20*counter+"px")
if(6===counter){clearInterval(timer)
_this.getDomElement().find("input").eq(0).attr("checked",!1)
_this.getDomElement().removeClass("on").addClass("off")
_this.switchStateChanged()}return counter++},20)}}
KDInputSwitch.prototype.switchAnimateOn=function(){var counter,timer,_this=this
if(!this.getValue()){counter=6
return timer=setInterval(function(){_this.getDomElement().css("background-position","left -"+20*counter+"px")
if(0===counter){clearInterval(timer)
_this.getDomElement().find("input").eq(0).attr("checked",!0)
_this.getDomElement().removeClass("off").addClass("on")
_this.switchStateChanged()}return counter--},20)}}
KDInputSwitch.prototype.switchStateChanged=function(){return null!=this.getCallback()?this.getCallback().call(this,this.getValue()):void 0}
KDInputSwitch.prototype.mouseDown=function(){switch(this.getValue()){case!0:this.setValue(!1)
break
case!1:this.setValue(!0)}return!1}
return KDInputSwitch}(KDInputView)

var KDCheckBox,KDOnOffSwitch,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDOnOffSwitch=function(_super){function KDOnOffSwitch(options,data){null==options&&(options={})
options.type="switch"
options.title||(options.title="")
options.size||(options.size="small")
options.labels||(options.labels=["ON","OFF"])
null==options.defaultValue&&(options.defaultValue=!1)
KDOnOffSwitch.__super__.constructor.call(this,options,data)
this.setClass(options.size)
this.setPartial("<input class='checkbox hidden no-kdinput' type='checkbox' name='"+this.getName()+"'/>")
this.setDefaultValue(options.defaultValue)}__extends(KDOnOffSwitch,_super)
KDOnOffSwitch.prototype.setDomElement=function(cssClass){var labels,name,title,_ref
_ref=this.getOptions(),title=_ref.title,labels=_ref.labels,name=_ref.name
title&&(title="<span>"+title+"</span>")
this.inputName=name
return this.domElement=$("<div class='kdinput on-off off "+cssClass+"'>\n  "+title+"\n  <a href='#' class='on' title='turn on'>"+labels[0]+"</a><a href='#' class='off' title='turn off'>"+labels[1]+"</a>\n</div> ")}
KDOnOffSwitch.prototype.getValue=function(){return"checked"===this.$("input").attr("checked")}
KDOnOffSwitch.prototype.setValue=function(value,wCallback){null==wCallback&&(wCallback=!0)
switch(value){case!0:return this.setOn(wCallback)
case!1:return this.setOff(wCallback)}}
KDOnOffSwitch.prototype.setDefaultValue=function(value){switch(value){case!0:case"on":case"true":case"yes":case 1:return this.setValue(!0,!1)
default:return this.setValue(!1,!1)}}
KDOnOffSwitch.prototype.setOff=function(wCallback){null==wCallback&&(wCallback=!0)
if(this.getValue()||!wCallback){this.$("input").attr("checked",!1)
this.$("a.on").removeClass("active")
this.$("a.off").addClass("active")
return wCallback?this.switchStateChanged():void 0}}
KDOnOffSwitch.prototype.setOn=function(wCallback){null==wCallback&&(wCallback=!0)
if(!this.getValue()||!wCallback){this.$("input").attr("checked",!0)
this.$("a.off").removeClass("active")
this.$("a.on").addClass("active")
return wCallback?this.switchStateChanged():void 0}}
KDOnOffSwitch.prototype.switchStateChanged=function(){this.emit("SwitchStateChanged",this.getValue())
return null!=this.getCallback()?this.getCallback().call(this,this.getValue()):void 0}
KDOnOffSwitch.prototype.mouseDown=function(event){return $(event.target).is("a.on")?this.setValue(!0):$(event.target).is("a.off")?this.setValue(!1):void 0}
return KDOnOffSwitch}(KDInputView)
KDCheckBox=function(_super){function KDCheckBox(options,data){var _base
null==options&&(options={})
options.type||(options.type="checkbox")
null==options.attributes&&(options.attributes={})
null==(_base=options.attributes).checked&&(_base.checked=options.defaultValue||!1)
KDCheckBox.__super__.constructor.call(this,options,data)}__extends(KDCheckBox,_super)
return KDCheckBox}(KDInputView)

var KDMultipleChoice,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDMultipleChoice=function(_super){function KDMultipleChoice(options,data){null==options&&(options={})
options.size||(options.size="small")
options.labels||(options.labels=["ON","OFF"])
null==options.multiple&&(options.multiple=!1)
options.defaultValue||(options.defaultValue=options.multiple?options.labels[0]:void 0)
!options.multiple&&Array.isArray(options.defaultValue)&&(options.defaultValue=options.defaultValue[0])
KDMultipleChoice.__super__.constructor.call(this,options,data)
this.setClass(options.size)
this.setPartial("<input class='hidden no-kdinput' name='"+this.getName()+"'/>")
this.oldValue=null
options.multiple&&(this.currentValue=[])}var setCurrent
__extends(KDMultipleChoice,_super)
KDMultipleChoice.prototype.setDomElement=function(cssClass){var activeClass,clsName,defaultValue,label,labelItems,labels,name,_i,_len,_ref
_ref=this.getOptions(),labels=_ref.labels,name=_ref.name,defaultValue=_ref.defaultValue
this.inputName=name
labelItems=""
for(_i=0,_len=labels.length;_len>_i;_i++){label=labels[_i]
activeClass=label===defaultValue?" active":""
clsName="multiple-choice-"+label+activeClass
labelItems+="<a href='#' name='"+label+"' class='"+clsName+"' title='Select "+label+"'>"+label+"</a>"}return this.domElement=$("<div class='kdinput on-off multiple-choice "+cssClass+"'>\n  "+labelItems+"\n</div> ")}
KDMultipleChoice.prototype.getDefaultValue=function(){return this.getOptions().defaultValue}
KDMultipleChoice.prototype.getValue=function(){return this.currentValue}
setCurrent=function(view,label){if(__indexOf.call(view.currentValue,label)>=0){view.$("a[name$='"+label+"']").removeClass("active")
return view.currentValue.splice(view.currentValue.indexOf(label),1)}view.$("a[name$='"+label+"']").addClass("active")
return view.currentValue.push(label)}
KDMultipleChoice.prototype.setValue=function(label,wCallback){var multiple,obj,val,_ref
null==wCallback&&(wCallback=!0)
multiple=this.getOptions().multiple
if(multiple){this.oldValue=null!=(_ref=[function(){var _i,_len,_ref1,_results
_ref1=this.currentValue
_results=[]
for(_i=0,_len=_ref1.length;_len>_i;_i++){obj=_ref1[_i]
_results.push(obj)}return _results}.call(this)])?_ref.first:void 0
Array.isArray(label)?[function(){var _i,_len,_results
_results=[]
for(_i=0,_len=label.length;_len>_i;_i++){val=label[_i]
_results.push(setCurrent(this,val))}return _results}.call(this)]:setCurrent(this,label)
if(wCallback)return this.switchStateChanged()}else{this.$("a").removeClass("active")
this.$("a[name$='"+label+"']").addClass("active")
this.oldValue=this.currentValue
this.currentValue=label
if(this.currentValue!==this.oldValue&&wCallback)return this.switchStateChanged()}}
KDMultipleChoice.prototype.switchStateChanged=function(){return null!=this.getCallback()?this.getCallback().call(this,this.getValue()):void 0}
KDMultipleChoice.prototype.fallBackToOldState=function(){var multiple
multiple=this.getOptions().multiple
if(multiple){this.currentValue=[]
this.$("a").removeClass("active")}return this.setValue(this.oldValue,!1)}
KDMultipleChoice.prototype.mouseDown=function(event){return $(event.target).is("a")?this.setValue(event.target.name):void 0}
return KDMultipleChoice}.call(this,KDInputView)

var KDSelectBox,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSelectBox=function(_super){function KDSelectBox(options){null==options&&(options={})
options.type="select"
KDSelectBox.__super__.constructor.call(this,options)}__extends(KDSelectBox,_super)
KDSelectBox.prototype.setDomElement=function(cssClass){var name
this.inputName=this.getOption("name")
name="name='"+this.options.name+"'"
this.domElement=$("<div class='kdselectbox "+cssClass+"'>\n  <select "+name+"></select>\n  <span class='title'></span>\n  <span class='arrows'></span>\n</div>\"")
this._$select=this.$("select").eq(0)
this._$title=this.$("span.title").eq(0)
return this.domElement}
KDSelectBox.prototype.bindEvents=function(){var _this=this
this._$select.bind("blur change focus",function(event){var _base
"change"===event.type&&"function"==typeof(_base=_this.getCallback())&&_base(_this.getValue())
_this.emit(event.type,event,_this.getValue())
return _this.handleEvent(event)})
return KDSelectBox.__super__.bindEvents.apply(this,arguments)}
KDSelectBox.prototype.setDefaultValue=function(value){""!==value&&this.getDomElement().val(value)
this._$select.val(value)
this._$title.text(this._$select.find('option[value="'+value+'"]').text())
return this.inputDefaultValue=value}
KDSelectBox.prototype.getDefaultValue=function(){return this.inputDefaultValue}
KDSelectBox.prototype.getValue=function(){return this._$select.val()}
KDSelectBox.prototype.setValue=function(value){this._$select.val(value)
return this.change()}
KDSelectBox.prototype.makeDisabled=function(){this.setClass("disabled")
return this._$select.attr("disabled","disabled")}
KDSelectBox.prototype.makeEnabled=function(){this.unsetClass("disabled")
return this._$select.removeAttr("disabled")}
KDSelectBox.prototype.setSelectOptions=function(options){var $optGroup,firstOption,optGroup,option,subOptions,value,_i,_j,_len,_len1
firstOption=null
if(options.length)if(options.length)for(_j=0,_len1=options.length;_len1>_j;_j++){option=options[_j]
this._$select.append("<option value='"+option.value+"'>"+option.title+"</option>")
firstOption||(firstOption=option)}else warn("no valid options specified for the input:",this)
else for(optGroup in options)if(__hasProp.call(options,optGroup)){subOptions=options[optGroup]
$optGroup=$("<optgroup label='"+optGroup+"'/>")
this._$select.append($optGroup)
for(_i=0,_len=subOptions.length;_len>_i;_i++){option=subOptions[_i]
firstOption||(firstOption=option)
$optGroup.append("<option value='"+option.value+"'>"+option.title+"</option>")}}value=this.getDefaultValue()||(null!=firstOption?firstOption.value:void 0)||""
this._$select.val(value+"")
return this._$title.text(this._$select.find('option[value="'+value+'"]').text())}
KDSelectBox.prototype.removeSelectOptions=function(){return this._$select.find("option").remove()}
KDSelectBox.prototype.change=function(){return this._$title.text(this._$select.find('option[value="'+this.getValue()+'"]').text())}
KDSelectBox.prototype.focus=function(){return this.setClass("focus")}
KDSelectBox.prototype.blur=function(){return this.unsetClass("focus")}
return KDSelectBox}(KDInputView)

var KDWmdInput,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDWmdInput=function(_super){function KDWmdInput(options,data){var _ref
options=null!=options?options:{}
options.type="textarea"
options.preview=null!=(_ref=options.preview)?_ref:!1
KDWmdInput.__super__.constructor.call(this,options,data)
this.setClass("monospace")}__extends(KDWmdInput,_super)
KDWmdInput.prototype.setWMD=function(){var preview
preview=this.getOptions().preview
this.getDomElement().wmd({preview:preview})
return preview?this.getDomElement().after("<h3 class='wmd-preview-title'>Preview:</h3>"):void 0}
return KDWmdInput}(KDInputView)

var KDContentEditableView,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDContentEditableView=function(_super){function KDContentEditableView(options,data){var _ref,_this=this
null==options&&(options={})
this.keyDown=__bind(this.keyDown,this)
this.input=__bind(this.input,this)
this.click=__bind(this.click,this)
options.cssClass=KD.utils.curry("kdcontenteditableview",options.cssClass)
options.bind=KD.utils.curry("click input keydown paste drop",options.bind)
options.type||(options.type="text")
null==options.multiline&&(options.multiline=!1)
options.placeholder||(options.placeholder="")
KDContentEditableView.__super__.constructor.call(this,options,data)
null!=(_ref=this.getDelegate())&&_ref.on("EditingModeToggled",function(state){return _this.setEditingMode(state)})
this.validationNotifications={}}__extends(KDContentEditableView,_super)
KDContentEditableView.prototype.viewAppended=function(){this.setEditingMode(!1)
return KDContentEditableView.__super__.viewAppended.apply(this,arguments)}
KDContentEditableView.prototype.getEditableElement=function(){if(!this.editableElement)if(this.getData())this.editableElement=this.getElement().children[0]
else{this.editableElement=document.createElement("div")
this.getDomElement().append(this.editableElement)}return this.editableElement}
KDContentEditableView.prototype.getEditableDomElement=function(){this.editableDomElement||(this.editableDomElement=$(this.getEditableElement()))
return this.editableDomElement}
KDContentEditableView.prototype.setEditingMode=function(state){this.editingMode=state
this.getEditableElement().setAttribute("contenteditable",state)
return""===this.getValue()?this.editingMode&&this.getOptions().placeholder?this.setPlaceholder():this.unsetPlaceholder():void 0}
KDContentEditableView.prototype.getValue=function(forceType){var element,placeholder,type,value,_ref
_ref=this.getOptions(),type=_ref.type,placeholder=_ref.placeholder
element=this.getEditableElement()
forceType&&(type=forceType)
switch(type){case"text":value=element.textContent
break
case"html":value=element.innerHTML}return value===placeholder?"":value}
KDContentEditableView.prototype.setContent=function(content){var element,textExpansion,type,_ref
_ref=this.getOptions(),type=_ref.type,textExpansion=_ref.textExpansion
!this.editingMode&&textExpansion&&(content=this.utils.applyTextExpansions(content,!0))
element=this.getEditableElement()
if(content)switch(type){case"text":return element.textContent=content
case"html":return element.innerHTML=content}else if(this.editingMode&&""===content)return this.setPlaceholder()}
KDContentEditableView.prototype.focus=function(){var windowController,_base
0===this.getValue().length&&this.unsetPlaceholder()
this.focused||this.getEditableDomElement().trigger("focus")
windowController=KD.getSingleton("windowController")
windowController.addLayer(this)
this.focused||this.once("ReceivedClickElsewhere",this.bound("blur"))
this.focused=!0
return"function"==typeof(_base=this.getOptions()).focus?_base.focus():void 0}
KDContentEditableView.prototype.blur=function(){this.focused=!1
return 0===this.getValue("text").length?this.setPlaceholder():"html"!==this.getOptions().type?this.setContent(this.getValue()):void 0}
KDContentEditableView.prototype.click=function(){return this.editingMode?this.focus():void 0}
KDContentEditableView.prototype.input=function(event){return this.emit("ValueChanged",event)}
KDContentEditableView.prototype.keyDown=function(event){var maxLength,value,_ref,_ref1
switch(event.which){case 9:case 13:event.preventDefault()
this.utils.stopDOMEvent(event)}switch(event.which){case 9:this.blur()
event.shiftKey?this.emit("PreviousTabStop"):this.emit("NextTabStop")
break
case 13:this.getOptions().multiline?this.appendNewline():this.emit("Enter")}value=this.getValue()
maxLength=(null!=(_ref=this.getOptions().validate)?null!=(_ref1=_ref.rules)?_ref1.maxLength:void 0:void 0)||0
if(13===event.which||maxLength>0&&value.length===maxLength)return event.preventDefault()
if(0===value.length){this.unsetPlaceholder()
return this.focus()}}
KDContentEditableView.prototype.paste=function(event){var commonAncestorContainer,endOffset,startOffset,text,_ref
event.preventDefault()
text=this.getClipboardTextNode(event.originalEvent.clipboardData)
_ref=this.utils.getSelectionRange(),commonAncestorContainer=_ref.commonAncestorContainer,startOffset=_ref.startOffset,endOffset=_ref.endOffset
return this.utils.replaceRange(commonAncestorContainer,text,startOffset,endOffset)}
KDContentEditableView.prototype.drop=function(event){var clientX,clientY,commonAncestorContainer,endOffset,startOffset,text,_ref,_ref1
event.preventDefault()
text=this.getClipboardTextNode(event.originalEvent.dataTransfer)
_ref=event.originalEvent,clientX=_ref.clientX,clientY=_ref.clientY
if(""===this.getValue()){startOffset=0
this.unsetPlaceholder()}_ref1=document.caretRangeFromPoint(clientX,clientY),commonAncestorContainer=_ref1.commonAncestorContainer,startOffset=_ref1.startOffset,endOffset=_ref1.endOffset
return this.utils.replaceRange(commonAncestorContainer,text,startOffset)}
KDContentEditableView.prototype.getClipboardTextNode=function(clipboard){var data
data=clipboard.getData("text/plain")
return document.createTextNode(data)}
KDContentEditableView.prototype.setPlaceholder=function(){var placeholder
this.setClass("placeholder")
placeholder=this.getOptions().placeholder
return placeholder?this.setContent(placeholder):void 0}
KDContentEditableView.prototype.unsetPlaceholder=function(){var content,defaultValue,element,value
this.unsetClass("placeholder")
content=""
defaultValue=this.getOptions()["default"]
value=this.getValue()
content=this.editingMode?value||"":value||defaultValue||""
element=this.getEditableDomElement()
element.text("")
return element.append(document.createTextNode(content))}
KDContentEditableView.prototype.validate=function(event){var message,name,rule,valid,validator,_ref,_ref1
valid=!0
_ref1=(null!=(_ref=this.getOptions().validate)?_ref.rules:void 0)||{}
for(name in _ref1)if(__hasProp.call(_ref1,name)){rule=_ref1[name]
validator=KDInputValidator["rule"+name.capitalize()]
if(validator&&(message=validator(this,event))){valid=!1
this.notify(message,{title:message,type:"mini",cssClass:"error",duration:2500})
break}}return valid}
KDContentEditableView.prototype.notify=function(message,options){var notice,_this=this
this.validationNotifications[message]=notice=new KDNotificationView(options)
return notice.on("KDObjectWillBeDestroyed",function(){message=notice.getOptions().title
return delete _this.validationNotifications[message]})}
KDContentEditableView.prototype.appendNewline=function(){var count,i,newline,range,selection,_i
selection=window.getSelection()
count=selection.baseNode.length===selection.focusOffset?1:0
range=selection.getRangeAt(0)
for(i=_i=0;count>=0?count>=_i:_i>=count;i=count>=0?++_i:--_i)range.insertNode(newline=document.createElement("br"))
return this.utils.selectEnd(newline)}
KDContentEditableView.prototype.viewAppended=function(){KDContentEditableView.__super__.viewAppended.apply(this,arguments)
return this.editingMode||0!==this.getValue().length?void 0:this.unsetPlaceholder()}
return KDContentEditableView}(KDView)

var KDTokenizedInput,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTokenizedInput=function(_super){function KDTokenizedInput(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("kdtokenizedinputview",options.cssClass)
options.bind=KD.utils.curry("keyup",options.bind)
options.rules||(options.rules={})
options.layer||(options.layer={})
KDTokenizedInput.__super__.constructor.call(this,options,data)
this.tokenViews={}}__extends(KDTokenizedInput,_super)
KDTokenizedInput.prototype.getValue=function(options){var node,tokenValue,value,_i,_len,_ref,_ref1
null==options&&(options={})
value=""
_ref=this.getEditableElement().childNodes
for(_i=0,_len=_ref.length;_len>_i;_i++){node=_ref[_i]
switch(node.nodeType){case Node.TEXT_NODE:""!==node.textContent&&(value+=node.textContent)
break
case Node.ELEMENT_NODE:if("br"===node.tagName.toLowerCase())value+="\n"
else{if(options.onlyText===!0)continue
tokenValue=null!=(_ref1=this.getTokenView(node.dataset.key))?"function"==typeof _ref1.encodeValue?_ref1.encodeValue():void 0:void 0
tokenValue&&(value+=tokenValue)}}}return value===this.getOptions().placeholder?"":value}
KDTokenizedInput.prototype.getTokens=function(){var data,node,tokens,type,view,_i,_len,_ref
tokens=[]
_ref=this.getEditableElement().childNodes
for(_i=0,_len=_ref.length;_len>_i;_i++){node=_ref[_i]
if(node.nodeType===Node.ELEMENT_NODE){view=this.getTokenView(node.dataset.key)
if(!view)continue
type=view.getOptions().type
data=view.getData()
tokens.push({type:type,data:data})}}return tokens}
KDTokenizedInput.prototype.getTokenView=function(key){return this.tokenViews[key]}
KDTokenizedInput.prototype.matchPrefix=function(){var char,name,node,range,rule,start,_ref,_results
if(!this.tokenInput){range=this.utils.getSelectionRange()
node=range.commonAncestorContainer
start=range.startOffset-1
char=node.textContent[start]
_ref=this.getOptions().rules
_results=[]
for(name in _ref){rule=_ref[name]
if(char===rule.prefix){this.activeRule=rule
this.tokenInput=document.createElement("span")
this.tokenInput.textContent=rule.prefix
this.utils.replaceRange(node,this.tokenInput,start,start+rule.prefix.length)
_results.push(this.utils.selectText(this.tokenInput,rule.prefix.length))}else _results.push(void 0)}return _results}}
KDTokenizedInput.prototype.matchToken=function(){var dataSource,token
token=this.tokenInput.textContent.substring(this.activeRule.prefix.length)
if(token){dataSource=this.activeRule.dataSource
return dataSource(token,this.bound("showMenu"))}}
KDTokenizedInput.prototype.showMenu=function(options,data){var pos,_ref,_this=this
null!=(_ref=this.menu)&&_ref.destroy()
this.blur()
pos=this.tokenInput.getBoundingClientRect()
options.x=pos.left
options.y=pos.top+parseInt(window.getComputedStyle(this.tokenInput).lineHeight,10)
this.menu=new JContextMenu(options,data)
return this.menu.on("ContextMenuItemReceivedClick",function(item){_this.addToken(item.data)
return _this.hideMenu()})}
KDTokenizedInput.prototype.hideMenu=function(){var _ref
null!=(_ref=this.menu)&&_ref.destroy()
this.menu=null
this.activeRule=null
return this.tokenInput=null}
KDTokenizedInput.prototype.addToken=function(item){var pistachio,prefix,tokenKey,tokenView,tokenViewClass,type,_ref
_ref=this.activeRule,type=_ref.type,prefix=_ref.prefix,pistachio=_ref.pistachio
tokenViewClass=this.getOptions().tokenViewClass||TokenView
tokenView=new tokenViewClass({type:type,prefix:prefix,pistachio:pistachio},item)
tokenKey=""+tokenView.getId()+"-"+tokenView.getKey()
this.tokenViews[tokenKey]=tokenView
tokenView.setAttributes({"data-key":tokenKey})
this.getEditableElement().insertBefore(tokenView.getElement(),this.tokenInput)
tokenView.emit("viewAppended")
this.utils.selectText(this.tokenInput.nextSibling,1)
return this.tokenInput.remove()}
KDTokenizedInput.prototype.keyDown=function(event){KDTokenizedInput.__super__.keyDown.apply(this,arguments)
switch(event.which){case 9:case 13:case 27:case 38:case 40:if(this.menu){this.menu.treeController.keyEventHappened(event)
this.utils.stopDOMEvent(event)}}switch(event.which){case 27:if(this.tokenInput)return this.cancel()}}
KDTokenizedInput.prototype.keyUp=function(event){KDTokenizedInput.__super__.keyUp.apply(this,arguments)
switch(event.which){case 9:case 13:case 27:case 38:case 40:break
default:return this.activeRule?this.matchToken():this.matchPrefix()}}
KDTokenizedInput.prototype.cancel=function(){var text
text=document.createTextNode(this.tokenInput.textContent)
this.getEditableElement().insertBefore(text,this.tokenInput)
this.tokenInput.nextSibling.remove()
this.tokenInput.remove()
this.utils.selectEnd(text)
return this.hideMenu()}
KDTokenizedInput.prototype.reset=function(){var id,view,_ref,_results
this.setPlaceholder()
this.blur()
_ref=this.tokenViews
_results=[]
for(id in _ref)if(__hasProp.call(_ref,id)){view=_ref[id]
view.destroy()
_results.push(delete this.tokenViews[id])}return _results}
KDTokenizedInput.prototype.viewAppended=function(){KDTokenizedInput.__super__.viewAppended.apply(this,arguments)
return this.setEditingMode(!0)}
return KDTokenizedInput}(KDContentEditableView)

var KDButtonView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDButtonView=function(_super){function KDButtonView(options,data){null==options&&(options={})
options.callback||(options.callback=noop)
options.title||(options.title="")
options.type||(options.type="button")
options.cssClass||(options.cssClass=options.style||(options.style="clean-gray"))
null==options.icon&&(options.icon=!1)
null==options.iconOnly&&(options.iconOnly=!1)
options.iconClass||(options.iconClass="")
null==options.disabled&&(options.disabled=!1)
options.hint||(options.hint=null)
null==options.loader&&(options.loader=!1)
KDButtonView.__super__.constructor.call(this,options,data)
this.setClass(options.style)
this.setCallback(options.callback)
this.setTitle(options.title)
options.iconClass&&this.setIconClass(options.iconClass);(options.icon||options.iconOnly)&&this.showIcon()
options.iconOnly&&this.setIconOnly(options.iconOnly)
options.disabled&&this.disable()
options.focus&&this.once("viewAppended",this.bound("setFocus"))
options.loader&&this.once("viewAppended",this.bound("setLoader"))}__extends(KDButtonView,_super)
KDButtonView.prototype.setFocus=function(){return this.$().trigger("focus")}
KDButtonView.prototype.setDomElement=function(cssClass){var el,klass,lazyDomId,tagName,_i,_len,_ref,_ref1
_ref=this.getOptions(),lazyDomId=_ref.lazyDomId,tagName=_ref.tagName
if(lazyDomId){el=document.getElementById(lazyDomId)
_ref1=("kdview "+cssClass).split(" ")
for(_i=0,_len=_ref1.length;_len>_i;_i++){klass=_ref1[_i]
klass.length&&el.classList.add(klass)}}if(null==el){lazyDomId&&warn("No lazy DOM Element found with given id "+lazyDomId+".")
el="<button type='"+this.getOptions().type+"' class='kdbutton "+cssClass+"' id='"+this.getId()+"'>\n  <span class='icon hidden'></span>\n  <span class='button-title'>Title</span>\n</button>"}return this.domElement=$(el)}
KDButtonView.prototype.setTitle=function(title){this.buttonTitle=title
return this.$(".button-title").html(title)}
KDButtonView.prototype.getTitle=function(){return this.buttonTitle}
KDButtonView.prototype.setCallback=function(callback){return this.buttonCallback=callback}
KDButtonView.prototype.getCallback=function(){return this.buttonCallback}
KDButtonView.prototype.showIcon=function(){this.setClass("with-icon")
return this.$("span.icon").removeClass("hidden")}
KDButtonView.prototype.hideIcon=function(){this.unsetClass("with-icon")
return this.$("span.icon").addClass("hidden")}
KDButtonView.prototype.setIconClass=function(iconClass){this.$(".icon").attr("class","icon")
return this.$(".icon").addClass(iconClass)}
KDButtonView.prototype.setIconOnly=function(){var $icon
this.unsetClass("with-icon")
this.$().addClass("icon-only")
$icon=this.$("span.icon")
return this.$().html($icon)}
KDButtonView.prototype.setLoader=function(){var loader,loaderSize,_ref,_ref1,_ref2,_ref3,_ref4,_ref5
this.setClass("w-loader")
loader=this.getOptions().loader
loaderSize=this.getHeight()
this.loader=new KDLoaderView({size:{width:null!=(_ref=loader.diameter)?_ref:loaderSize},loaderOptions:{color:loader.color||"#222222",shape:loader.shape||"spiral",diameter:null!=(_ref1=loader.diameter)?_ref1:loaderSize,density:null!=(_ref2=loader.density)?_ref2:30,range:null!=(_ref3=loader.range)?_ref3:.4,speed:null!=(_ref4=loader.speed)?_ref4:1.5,FPS:null!=(_ref5=loader.FPS)?_ref5:24}})
this.addSubView(this.loader,null,!0)
this.loader.$().css({position:"absolute",left:loader.left||"50%",top:loader.top||"50%",marginTop:-(loader.diameter/2),marginLeft:-(loader.diameter/2)})
return this.loader.hide()}
KDButtonView.prototype.showLoader=function(){var icon,iconOnly,_ref
_ref=this.getOptions(),icon=_ref.icon,iconOnly=_ref.iconOnly
this.setClass("loading")
this.loader.show()
return icon&&!iconOnly?this.hideIcon():void 0}
KDButtonView.prototype.hideLoader=function(){var icon,iconOnly,_ref,_ref1
_ref=this.getOptions(),icon=_ref.icon,iconOnly=_ref.iconOnly
this.unsetClass("loading")
null!=(_ref1=this.loader)&&_ref1.hide()
return icon&&!iconOnly?this.showIcon():void 0}
KDButtonView.prototype.disable=function(){return this.$().attr("disabled",!0)}
KDButtonView.prototype.enable=function(){return this.$().attr("disabled",!1)}
KDButtonView.prototype.focus=function(){return this.$().trigger("focus")}
KDButtonView.prototype.blur=function(){return this.$().trigger("blur")}
KDButtonView.prototype.click=function(event){var _ref
if(null!=(_ref=this.loader)?_ref.active:void 0)return this.utils.stopDOMEvent()
this.loader&&!this.loader.active&&this.showLoader()
"button"===this.getOption("type")&&this.utils.stopDOMEvent()
this.getCallback().call(this,event)
return!1}
KDButtonView.prototype.triggerClick=function(){return this.doOnSubmit()}
return KDButtonView}(KDView)

var KDButtonViewWithMenu,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDButtonViewWithMenu=function(_super){function KDButtonViewWithMenu(){_ref=KDButtonViewWithMenu.__super__.constructor.apply(this,arguments)
return _ref}__extends(KDButtonViewWithMenu,_super)
KDButtonViewWithMenu.prototype.setDomElement=function(cssClass){null==cssClass&&(cssClass="")
this.domElement=$("<div class='kdbuttonwithmenu-wrapper "+cssClass+"'>\n  <button class='kdbutton "+cssClass+" with-icon with-menu' id='"+this.getId()+"'>\n    <span class='icon hidden'></span>\n  </button>\n  <span class='chevron-separator'></span>\n  <span class='chevron'></span>\n</div>")
this.$button=this.$("button").first()
return this.domElement}
KDButtonViewWithMenu.prototype.setIconOnly=function(){var $icons
this.$().addClass("icon-only").removeClass("with-icon")
$icons=this.$("span.icon,span.chevron")
return this.$().html($icons)}
KDButtonViewWithMenu.prototype.click=function(event){if($(event.target).is(".chevron")){this.contextMenu(event)
return!1}return this.getCallback().call(this,event)}
KDButtonViewWithMenu.prototype.contextMenu=function(event){this.createContextMenu(event)
return!1}
KDButtonViewWithMenu.prototype.createContextMenu=function(event){var menuArrayToObj,menuObject,menuObjectProperty,menuObjectValue,o,_this=this
o=this.getOptions()
this.buttonMenu=new(o.buttonMenuClass||JButtonMenu)({cssClass:o.style,ghost:this.$(".chevron").clone(),event:event,delegate:this,treeItemClass:o.treeItemClass,itemChildClass:o.itemChildClass,itemChildOptions:o.itemChildOptions},function(){var _i,_len,_ref1
if("function"==typeof o.menu)return o.menu()
if(o.menu instanceof Array){menuArrayToObj={}
_ref1=o.menu
for(_i=0,_len=_ref1.length;_len>_i;_i++){menuObject=_ref1[_i]
for(menuObjectProperty in menuObject)if(__hasProp.call(menuObject,menuObjectProperty)){menuObjectValue=menuObject[menuObjectProperty]
null!=menuObjectProperty&&null!=menuObjectValue&&(menuArrayToObj[menuObjectProperty]=menuObjectValue)}}return menuArrayToObj}return o.menu}())
return this.buttonMenu.on("ContextMenuItemReceivedClick",function(){return _this.buttonMenu.destroy()})}
KDButtonViewWithMenu.prototype.setTitle=function(title){return this.$button.append(title)}
KDButtonViewWithMenu.prototype.setButtonStyle=function(newStyle){var style,styles,_i,_len
styles=this.constructor.styles
for(_i=0,_len=styles.length;_len>_i;_i++){style=styles[_i]
this.$().removeClass(style)
this.$button.removeClass(style)}this.$button.addClass(newStyle)
return this.$().addClass(newStyle)}
KDButtonViewWithMenu.prototype.setIconOnly=function(){var $icon
this.$button.addClass("icon-only").removeClass("with-icon")
$icon=this.$("span.icon")
return this.$button.html($icon)}
KDButtonViewWithMenu.prototype.disable=function(){return this.$button.attr("disabled",!0)}
KDButtonViewWithMenu.prototype.enable=function(){return this.$button.attr("disabled",!1)}
return KDButtonViewWithMenu}(KDButtonView)

var JButtonMenu,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
JButtonMenu=function(_super){function JButtonMenu(options,data){null==options&&(options={})
options.cssClass=this.utils.curry("kdbuttonmenu",options.cssClass)
options.listViewClass||(options.listViewClass=JContextMenuTreeView)
JButtonMenu.__super__.constructor.call(this,options,data)}__extends(JButtonMenu,_super)
JButtonMenu.prototype.viewAppended=function(){JButtonMenu.__super__.viewAppended.apply(this,arguments)
this.setPartial("<div class='chevron-ghost-wrapper'><span class='chevron-ghost'></span></div>")
return this.positionContextMenu()}
JButtonMenu.prototype.positionContextMenu=function(){var button,buttonHeight,buttonWidth,ghostCss,mainHeight,menuHeight,menuWidth,top
button=this.getDelegate()
mainHeight=$(window).height()
buttonHeight=button.getHeight()
buttonWidth=button.getWidth()
top=button.getY()+buttonHeight
menuHeight=this.getHeight()
menuWidth=this.getWidth()
ghostCss=top+menuHeight>mainHeight?(top=button.getY()-menuHeight,this.setClass("top-menu"),{top:"100%",height:buttonHeight}):{top:-(buttonHeight+1),height:buttonHeight}
this.$(".chevron-ghost-wrapper").css(ghostCss)
return this.$().css({top:top,left:button.getX()+buttonWidth-menuWidth})}
return JButtonMenu}(JContextMenu)

var KDButtonGroupView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDButtonGroupView=function(_super){function KDButtonGroupView(options,data){var cssClass
null==options&&(options={})
cssClass=options.cssClass
cssClass=cssClass?" "+cssClass:""
options.cssClass="kdbuttongroup"+cssClass
options.buttons||(options.buttons={})
KDButtonGroupView.__super__.constructor.call(this,options,data)
this.buttons={}
this.createButtons(options.buttons)}__extends(KDButtonGroupView,_super)
KDButtonGroupView.prototype.createButtons=function(allButtonOptions){var buttonClass,buttonOptions,buttonTitle,_results,_this=this
_results=[]
for(buttonTitle in allButtonOptions)if(__hasProp.call(allButtonOptions,buttonTitle)){buttonOptions=allButtonOptions[buttonTitle]
buttonClass=buttonOptions.buttonClass||KDButtonView
buttonOptions.title=buttonTitle
buttonOptions.style=""
this.addSubView(this.buttons[buttonTitle]=new buttonClass(buttonOptions))
_results.push(this.buttons[buttonTitle].on("click",function(event){return _this.buttonReceivedClick(_this.buttons[buttonTitle],event)}))}return _results}
KDButtonGroupView.prototype.buttonReceivedClick=function(button){var otherButton,title,_ref
_ref=this.buttons
for(title in _ref)if(__hasProp.call(_ref,title)){otherButton=_ref[title]
otherButton.unsetClass("toggle")}return button.setClass("toggle")}
return KDButtonGroupView}(KDView)

var KDToggleButton,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDToggleButton=function(_super){function KDToggleButton(options,data){null==options&&(options={})
options=$.extend({dataPath:null,defaultState:null,states:[]},options)
KDToggleButton.__super__.constructor.call(this,options,data)
this.setState(options.defaultState)}__extends(KDToggleButton,_super)
KDToggleButton.prototype.getStateIndex=function(name){var index,state,states,_i,_len
states=this.getOptions().states
if(!name)return 0
for(index=_i=0,_len=states.length;_len>_i;index=++_i){state=states[index]
if(name===state.title)return index}}
KDToggleButton.prototype.decorateState=function(){this.setTitle(this.state.title)
null!=this.state.iconClass&&this.setIconClass(this.state.iconClass)
if(null!=this.state.cssClass||null!=this.lastUsedCssClass){null!=this.lastUsedCssClass&&this.unsetClass(this.lastUsedCssClass)
this.setClass(this.state.cssClass)
return this.lastUsedCssClass=this.state.cssClass}return delete this.lastUsedCssClass}
KDToggleButton.prototype.getState=function(){return this.state}
KDToggleButton.prototype.setState=function(name){var index,states
states=this.getOptions().states
this.stateIndex=index=this.getStateIndex(name)
this.state=states[index]
this.decorateState(name)
return this.setCallback(states[index].callback.bind(this,this.toggleState.bind(this)))}
KDToggleButton.prototype.toggleState=function(err){var nextState,states
states=this.getOptions().states
nextState=states[this.stateIndex+1]||states[0]
err?"AccessDenied"!==err.name&&warn(err.message||"There was an error, couldn't switch to "+nextState.title+" state!"):this.setState(nextState.title)
return"function"==typeof this.hideLoader?this.hideLoader():void 0}
return KDToggleButton}(KDButtonView)

var KDButtonBar,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDButtonBar=function(_super){function KDButtonBar(options,data){var button,buttonOptions,buttons,_i,_len,_ref
null==options&&(options={})
options.cssClass=KD.utils.curry("formline button-field clearfix",options.cssClass)
KDButtonBar.__super__.constructor.call(this,options,data)
this.buttons={}
buttons=options.buttons
_ref=this.utils.objectToArray(buttons)
for(_i=0,_len=_ref.length;_len>_i;_i++){buttonOptions=_ref[_i]
button=this.createButton(buttonOptions)
this.addSubView(button)
this.buttons[buttonOptions.key]=button}}__extends(KDButtonBar,_super)
KDButtonBar.prototype.createButton=function(options){var button,o
options.itemClass||(options.itemClass=KDButtonView)
o=$.extend({},options)
delete o.itemClass
return button=new options.itemClass(o)}
return KDButtonBar}(KDView)

var KDFormView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
KDFormView=function(_super){function KDFormView(options,data){null==options&&(options={})
options.tagName="form"
options.cssClass=KD.utils.curry("kdformview",options.cssClass)
options.callback||(options.callback=noop)
options.customData||(options.customData={})
options.bind||(options.bind="submit")
KDFormView.__super__.constructor.call(this,options,data)
this.unsetClass("kdview")
this.valid=null
this.setCallback(options.callback)
this.customData={}}__extends(KDFormView,_super)
KDFormView.findChildInputs=function(parent){var inputs,subViews
inputs=[]
subViews=parent.getSubViews()
subViews.length>0&&subViews.forEach(function(subView){subView instanceof KDInputView&&inputs.push(subView)
return inputs=inputs.concat(KDFormView.findChildInputs(subView))})
return inputs}
KDFormView.prototype.childAppended=function(child){"function"==typeof child.associateForm&&child.associateForm(this)
child instanceof KDInputView&&this.emit("inputWasAdded",child)
return KDFormView.__super__.childAppended.apply(this,arguments)}
KDFormView.prototype.getCustomData=function(path){return path?JsPath.getAt(this.customData,path):this.customData}
KDFormView.prototype.addCustomData=function(path,value){var key,_results
if("string"==typeof path)return JsPath.setAt(this.customData,path,value)
_results=[]
for(key in path)if(__hasProp.call(path,key)){value=path[key]
_results.push(JsPath.setAt(this.customData,key,value))}return _results}
KDFormView.prototype.removeCustomData=function(path){var isArrayElement,last,pathUntil,_i
"string"==typeof path&&(path=path.split("."))
pathUntil=2<=path.length?__slice.call(path,0,_i=path.length-1):(_i=0,[]),last=path[_i++]
isArrayElement=!isNaN(+last)
return isArrayElement?JsPath.spliceAt(this.customData,pathUntil,last):JsPath.deleteAt(this.customData,path)}
KDFormView.prototype.serializeFormData=function(data){var inputData,_i,_len,_ref
null==data&&(data={})
_ref=this.getDomElement().serializeArray()
for(_i=0,_len=_ref.length;_len>_i;_i++){inputData=_ref[_i]
data[inputData.name]=inputData.value}return data}
KDFormView.prototype.getData=function(){var formData
formData=$.extend({},this.getCustomData())
this.serializeFormData(formData)
return formData}
KDFormView.prototype.getFormData=function(){var formData,inputs
inputs=KDFormView.findChildInputs(this)
formData=this.getCustomData()||{}
inputs.forEach(function(input){return input.getName()?formData[input.getName()]=input.getValue():void 0})
return formData}
KDFormView.prototype.focusFirstElement=function(){return KDFormView.findChildInputs(this)[0].$().trigger("focus")}
KDFormView.prototype.setCallback=function(callback){return this.formCallback=callback}
KDFormView.prototype.getCallback=function(){return this.formCallback}
KDFormView.prototype.reset=function(){return this.getElement().reset()}
KDFormView.prototype.submit=function(event){var form,formData,inputs,toBeValidatedInputs,validInputs,validationCount
if(event){event.stopPropagation()
event.preventDefault()}form=this
inputs=KDFormView.findChildInputs(form)
validationCount=0
toBeValidatedInputs=[]
validInputs=[]
formData=this.getCustomData()||{}
this.once("FormValidationFinished",function(isValid){var _ref
null==isValid&&(isValid=!0)
form.valid=isValid
if(isValid){null!=(_ref=form.getCallback())&&_ref.call(form,formData,event)
return form.emit("FormValidationPassed")}return form.emit("FormValidationFailed")})
inputs.forEach(function(input){var inputOptions,name,value
inputOptions=input.getOptions()
if(inputOptions.validate||inputOptions.required)return toBeValidatedInputs.push(input)
name=input.getName()
value=input.getValue()
return name?formData[name]=value:void 0})
toBeValidatedInputs.forEach(function(inputToBeValidated){!function(){return inputToBeValidated.once("ValidationResult",function(result){var input,valid,_i,_len
validationCount++
result&&validInputs.push(inputToBeValidated)
if(toBeValidatedInputs.length===validationCount){if(validInputs.length===toBeValidatedInputs.length)for(_i=0,_len=validInputs.length;_len>_i;_i++){input=validInputs[_i]
formData[input.getName()]=input.getValue()}else valid=!1
return form.emit("FormValidationFinished",valid)}})}()
return inputToBeValidated.validate(null,event)})
return 0===toBeValidatedInputs.length?form.emit("FormValidationFinished"):void 0}
return KDFormView}(KDView)

var KDFormViewWithFields,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDFormViewWithFields=function(_super){function KDFormViewWithFields(){var buttons,fields,_ref
KDFormViewWithFields.__super__.constructor.apply(this,arguments)
this.setClass("with-fields")
this.inputs={}
this.fields={}
_ref=this.getOptions(),fields=_ref.fields,buttons=_ref.buttons
fields&&this.createFields(this.utils.objectToArray(fields))
if(buttons){this.createButtons(buttons)
this.buttons=this.buttonField.buttons}}__extends(KDFormViewWithFields,_super)
KDFormViewWithFields.prototype.createFields=function(fields){var fieldData,_i,_len,_results
_results=[]
for(_i=0,_len=fields.length;_len>_i;_i++){fieldData=fields[_i]
_results.push(this.addSubView(this.createField(fieldData)))}return _results}
KDFormViewWithFields.prototype.createButtons=function(buttons){return this.addSubView(this.buttonField=new KDButtonBar({buttons:buttons}))}
KDFormViewWithFields.prototype.createField=function(fieldData,field,isNextElement){var hint,input,inputWrapper,itemClass,key,label,next,title,_ref,_ref1
null==isNextElement&&(isNextElement=!1)
itemClass=fieldData.itemClass,title=fieldData.title
itemClass||(itemClass=KDInputView)
fieldData.cssClass||(fieldData.cssClass="")
fieldData.name||(fieldData.name=title)
field||(field=new KDView({cssClass:"formline "+KD.utils.slugify(fieldData.name)+" "+fieldData.cssClass}))
fieldData.label&&field.addSubView(label=fieldData.label=this.createLabel(fieldData))
if(isNextElement)field.addSubView(input=this.createInput(itemClass,fieldData))
else{field.addSubView(inputWrapper=new KDCustomHTMLView({cssClass:"input-wrapper"}))
inputWrapper.addSubView(input=this.createInput(itemClass,fieldData))}fieldData.hint&&inputWrapper.addSubView(hint=new KDCustomHTMLView({partial:fieldData.hint,tagName:"cite",cssClass:"hint"}))
this.fields[title]=field
if(fieldData.nextElement){_ref=fieldData.nextElement
for(key in _ref){next=_ref[key]
next.title||(next.title=key)
this.createField(next,inputWrapper||field,!0)}}if(fieldData.nextElementFlat){_ref1=fieldData.nextElementFlat
for(key in _ref1)if(__hasProp.call(_ref1,key)){next=_ref1[key]
next.title||(next.title=key)
this.createField(next,field)}}return field}
KDFormViewWithFields.prototype.createLabel=function(data){return new KDLabelView({title:data.label,cssClass:this.utils.slugify(data.label)})}
KDFormViewWithFields.prototype.createInput=function(itemClass,options){var data,input
data=options.data
data&&delete options.data
this.inputs[options.title]=input=new itemClass(options,data)
return input}
return KDFormViewWithFields}(KDFormView)

var KDModalView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDModalView=function(_super){function KDModalView(options,data){var modalButtonsInnerWidth,_this=this
null==options&&(options={})
null==options.overlay&&(options.overlay=!1)
null==options.overlayClick&&(options.overlayClick=!0)
options.height||(options.height="auto")
null==options.width&&(options.width=400)
options.position||(options.position={})
options.title||(options.title=null)
options.subtitle||(options.subtitle=null)
options.content||(options.content=null)
options.cssClass||(options.cssClass="")
options.buttons||(options.buttons=null)
null==options.fx&&(options.fx=!1)
options.view||(options.view=null)
null==options.draggable&&(options.draggable={handle:".kdmodal-title"})
null==options.resizable&&(options.resizable=!1)
null==options.appendToDomBody&&(options.appendToDomBody=!0)
options.helpContent||(options.helpContent=null)
options.helpTitle||(options.helpTitle="Need help?")
KDModalView.__super__.constructor.call(this,options,data)
this.setClass("initial")
options.overlay&&this.putOverlay(options.overlay)
options.fx&&this.setClass("fx")
options.title&&this.setTitle(options.title)
options.subtitle&&this.setSubtitle(options.subtitle)
options.content&&this.setContent(options.content)
options.view&&this.addSubView(options.view)
options.cancel&&this.on("ModalCancelled",options.cancel)
this.on("viewAppended",function(){return _this.utils.wait(500,function(){return _this.unsetClass("initial")})})
this.getOptions().appendToDomBody&&this.appendToDomBody()
this.setModalWidth(options.width)
options.height&&this.setModalHeight(options.height)
if(options.buttons){this.buttonHolder=new KDView({cssClass:"kdmodal-buttons clearfix"})
this.addSubView(this.buttonHolder,".kdmodal-inner")
this.setButtons(options.buttons)
modalButtonsInnerWidth=this.$(".kdmodal-inner").width()
this.buttonHolder.setWidth(modalButtonsInnerWidth)}this.display()
this._windowDidResize()
$(window).one("keydown.modal",function(e){return 27===e.which?_this.cancel():void 0})
this.on("childAppended",this.setPositions.bind(this))
this.listenWindowResize()}__extends(KDModalView,_super)
KDModalView.prototype.setDomElement=function(cssClass){var helpButton,helpContent,helpTitle,_ref
_ref=this.getOptions(),helpContent=_ref.helpContent,helpTitle=_ref.helpTitle
helpButton=helpContent?"<span class='showHelp'>"+helpTitle+"</span>":""
return this.domElement=$("<div class='kdmodal "+cssClass+"'>\n  <div class='kdmodal-inner'>\n    "+helpButton+"\n    <span class='close-icon closeModal' title='Close [ESC]'></span>\n    <div class='kdmodal-title hidden'></div>\n    <div class='kdmodal-content'></div>\n  </div>\n</div>")}
KDModalView.prototype.addSubView=function(view,selector){null==selector&&(selector=".kdmodal-content")
0===this.$(selector).length&&(selector=null)
return KDModalView.__super__.addSubView.call(this,view,selector)}
KDModalView.prototype.setButtons=function(buttonDataSet,destroyExists){var button,buttonOptions,buttonTitle,defaultFocusTitle,focused
null==destroyExists&&(destroyExists=!1)
this.buttons||(this.buttons={})
this.setClass("with-buttons")
defaultFocusTitle=null
destroyExists&&this.destroyButtons()
for(buttonTitle in buttonDataSet)if(__hasProp.call(buttonDataSet,buttonTitle)){buttonOptions=buttonDataSet[buttonTitle]
null==defaultFocusTitle&&(defaultFocusTitle=buttonTitle)
button=this.createButton(buttonOptions.title||buttonTitle,buttonOptions)
this.buttons[buttonTitle]=button
buttonOptions.focus&&(focused=!0)}return focused?void 0:this.buttons[defaultFocusTitle].setFocus()}
KDModalView.prototype.destroyButtons=function(){var button,_key,_ref,_results
_ref=this.buttons
_results=[]
for(_key in _ref)if(__hasProp.call(_ref,_key)){button=_ref[_key]
_results.push(button.destroy())}return _results}
KDModalView.prototype.click=function(e){var helpContent
$(e.target).is(".closeModal")&&this.destroy()
if($(e.target).is(".showHelp")){helpContent=this.getOptions().helpContent
if(helpContent){helpContent=KD.utils.applyMarkdown(helpContent)
return new KDModalView({cssClass:"help-dialog",overlay:!0,content:"<div class='modalformline'><p>"+helpContent+"</p></div>"})}}}
KDModalView.prototype.setTitle=function(title){this.$().find(".kdmodal-title").removeClass("hidden").html("<span class='title'>"+title+"</span>")
return this.modalTitle=title}
KDModalView.prototype.setSubtitle=function(subtitle){this.$().find(".kdmodal-title").append("<span class='subtitle'>"+subtitle+"</span>")
return this.modalSubtitle=subtitle}
KDModalView.prototype.setModalHeight=function(value){if("auto"===value){this.$().css("height","auto")
return this.modalHeight=this.getHeight()}this.$().height(value)
return this.modalHeight=value}
KDModalView.prototype.setModalWidth=function(value){this.modalWidth=value
return this.$().width(value)}
KDModalView.prototype.setPositions=function(){var _this=this
return this.utils.defer(function(){var bottom,height,left,newRules,right,top,width,_ref
_ref=_this.getOptions().position,top=_ref.top,right=_ref.right,bottom=_ref.bottom,left=_ref.left
newRules={}
height=$(window).height()
width=$(window).width()
newRules.top=null!=top?top:height/2-_this.getHeight()/2
newRules.left=null!=left?left:width/2-_this.modalWidth/2
right&&(newRules.left=width-_this.modalWidth-right-20)
newRules.opacity=1
return _this.$().css(newRules)})}
KDModalView.prototype._windowDidResize=function(){var winHeight
this.setPositions()
winHeight=KD.getSingleton("windowController").winHeight
this.$(".kdmodal-content").css({maxHeight:winHeight-120,overflow:"auto"})
return this.getOptions().position.top?void 0:this.setY((winHeight-this.getHeight())/2)}
KDModalView.prototype.putOverlay=function(){var _this=this
this.$overlay=$("<div/>",{"class":"kdoverlay"})
this.$overlay.hide()
this.$overlay.appendTo("body")
this.$overlay.fadeIn(200)
return this.getOptions().overlayClick?this.$overlay.bind("click",function(){return _this.destroy()}):void 0}
KDModalView.prototype.createButton=function(title,buttonOptions){var button,itemClass,_this=this
buttonOptions.title=title
buttonOptions.delegate=this
itemClass=buttonOptions.itemClass
delete buttonOptions.itemClass
this.buttonHolder.addSubView(button=new(itemClass||KDButtonView)(buttonOptions))
button.on("KDModalShouldClose",function(){return _this.emit("KDModalShouldClose")})
return button}
KDModalView.prototype.setContent=function(content){this.modalContent=content
return this.getDomElement().find(".kdmodal-content").html(content)}
KDModalView.prototype.display=function(){var _this=this
return this.getOptions().fx?this.utils.defer(function(){return _this.setClass("active")}):void 0}
KDModalView.prototype.cancel=function(){this.emit("ModalCancelled")
return this.destroy()}
KDModalView.prototype.destroy=function(){var uber
$(window).off("keydown.modal")
uber=KDView.prototype.destroy.bind(this)
if(this.options.fx){this.unsetClass("active")
setTimeout(uber,300)}else{this.getDomElement().hide()
uber()}return this.emit("KDModalViewDestroyed",this)}
KDModalView.createStack=function(options){return this.stack||(this.stack=new KDModalViewStack(options))}
KDModalView.addToStack=function(modal){return this.stack.addModal(modal)}
KDModalView.destroyStack=function(){this.stack.destroy()
return delete this.stack}
KDModalView.confirm=function(options){var cancel,content,description,modal,noop,ok,title
noop=function(){return modal.destroy()}
ok=options.ok,cancel=options.cancel,title=options.title,content=options.content,description=options.description
ok&&"function"!=typeof ok||(ok={callback:ok})
cancel&&"function"!=typeof cancel||(cancel={callback:cancel})
modal=new this({title:title||"You must confirm this action",content:content||(description?"<div class='modalformline'>\n  <p>"+description+"</p>\n</div>":void 0),overlay:!0,buttons:{OK:{title:ok.title,style:ok.style||"modal-clean-red",callback:ok.callback||noop},cancel:{title:cancel.title,style:cancel.style||"modal-cancel",callback:cancel.callback||noop}}})
options.subView&&modal.addSubView(options.subView)
return modal}
return KDModalView}(KDView)

var KDBlockingModalView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDBlockingModalView=function(_super){function KDBlockingModalView(){KDBlockingModalView.__super__.constructor.apply(this,arguments)
$(window).off("keydown.modal")}__extends(KDBlockingModalView,_super)
KDBlockingModalView.prototype.putOverlay=function(){var _this=this
this.$overlay=$("<div/>",{"class":"kdoverlay"})
this.$overlay.hide()
this.$overlay.appendTo("body")
this.$overlay.fadeIn(200)
return this.$overlay.bind("click",function(){return _this.doBlockingAnimation()})}
KDBlockingModalView.prototype.doBlockingAnimation=function(){var _this=this
this.unsetClass("blocking-animation")
this.setClass("blocking-animation")
this.$overlay.off("click")
return KD.utils.wait(200,function(){_this.unsetClass("blocking-animation")
return _this.$overlay.bind("click",function(){return _this.doBlockingAnimation()})})}
KDBlockingModalView.prototype.setDomElement=function(cssClass){return this.domElement=$("<div class='kdmodal "+cssClass+"'>\n  <div class='kdmodal-shadow'>\n    <div class='kdmodal-inner'>\n      <div class='kdmodal-title'></div>\n      <div class='kdmodal-content'></div>\n    </div>\n  </div>\n</div>")}
KDBlockingModalView.prototype.click=function(){}
return KDBlockingModalView}(KDModalView)

var KDModalViewWithForms,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDModalViewWithForms=function(_super){function KDModalViewWithForms(options,data){this.modalButtons=[]
KDModalViewWithForms.__super__.constructor.call(this,options,data)
this.addSubView(this.modalTabs=new KDTabViewWithForms(options.tabs))}__extends(KDModalViewWithForms,_super)
KDModalViewWithForms.prototype.aggregateFormData=function(){var data,form,formName
data=function(){var _ref,_results
_ref=this.modalTabs.forms
_results=[]
for(formName in _ref)if(__hasProp.call(_ref,formName)){form=_ref[formName]
_results.push({name:formName,data:form.getData()})}return _results}.call(this)
return data.reduce(function(acc,form){var key,val,_ref
_ref=form.data
for(key in _ref)if(__hasProp.call(_ref,key)){val=_ref[key]
key in acc&&console.warn("Property "+key+" will be overwitten!")
acc[key]=val}return acc},{})}
return KDModalViewWithForms}(KDModalView)

var KDModalViewStack,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDModalViewStack=function(_super){function KDModalViewStack(options,data){null==options&&(options={})
null==options.lastToFirst&&(options.lastToFirst=!1)
KDModalViewStack.__super__.constructor.call(this,options,data)
this.modals=[]}__extends(KDModalViewStack,_super)
KDModalViewStack.prototype.addModal=function(modal){var lastToFirst,_this=this
if(!(modal instanceof KDModalView))return warn("You can only add KDModalView instances to the modal stack.")
modal.on("KDObjectWillBeDestroyed",function(){return _this.next()})
lastToFirst=this.getOptions().lastToFirst
this.modals.push(modal)
KD.utils.defer(function(){modal.hide()
if(lastToFirst){_this.modals.forEach(function(modal){return modal.hide()})
return _this.modals.last.show()}return _this.modals.first.show()})
return modal}
KDModalViewStack.prototype.next=function(){var lastToFirst,_ref,_ref1
lastToFirst=this.getOptions().lastToFirst
if(lastToFirst){this.modals.pop()
return null!=(_ref=this.modals.last)?_ref.show():void 0}this.modals.shift()
return null!=(_ref1=this.modals.first)?_ref1.show():void 0}
KDModalViewStack.prototype.destroy=function(){this.modals.forEach(function(modal){return KD.utils.defer(function(){return modal.destroy()})})
this.modals=[]
return KDModalViewStack.__super__.destroy.apply(this,arguments)}
return KDModalViewStack}(KDObject)

var KDNotificationView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDNotificationView=function(_super){function KDNotificationView(options){KDNotificationView.__super__.constructor.call(this,options)
options=this.notificationSetDefaults(options)
this.notificationSetType(options.type)
null!=options.title&&this.notificationSetTitle(options.title)
null!=options.content&&this.notificationSetContent(options.content)
null!=options.duration&&this.notificationSetTimer(options.duration)
null!=options.overlay&&this.notificationSetOverlay(options.overlay)
null!=options.followUps&&this.notificationSetFollowUps(options.followUps)
null!=options.showTimer&&this.notificationShowTimer()
this.notificationSetCloseHandle(options.closeManually)
options.loader&&this.once("viewAppended",this.bound("setLoader"))
this.notificationDisplay()}__extends(KDNotificationView,_super)
KDNotificationView.prototype.setDomElement=function(cssClass){null==cssClass&&(cssClass="")
return this.domElement=$("<div class='kdnotification "+cssClass+"'>        <a class='kdnotification-close hidden'></a>        <div class='kdnotification-timer hidden'></div>        <div class='kdnotification-title'></div>        <div class='kdnotification-content hidden'></div>      </div>")}
KDNotificationView.prototype.destroy=function(){this.notificationCloseHandle.unbind(".notification")
null!=this.notificationOverlay&&this.notificationOverlay.remove()
KDNotificationView.__super__.destroy.call(this)
this.notificationStopTimer()
return this.notificationRepositionOtherNotifications()}
KDNotificationView.prototype.viewAppended=function(){return this.notificationSetPositions()}
KDNotificationView.prototype.notificationSetDefaults=function(options){null==options.duration&&(options.duration=1500);(options.duration>2999||0===options.duration)&&null==options.closeManually&&(options.closeManually=!0)
return options}
KDNotificationView.prototype.notificationSetTitle=function(title){if(title instanceof KDView){this.notificationTitle&&this.notificationTitle instanceof KDView&&this.notificationTitle.destroy()
this.addSubView(title,".kdnotification-title")}else this.$().find(".kdnotification-title").html(title)
return this.notificationTitle=title}
KDNotificationView.prototype.notificationSetType=function(type){null==type&&(type="main")
return this.notificationType=type}
KDNotificationView.prototype.notificationSetPositions=function(){var bottomMargin,i,notification,sameTypeNotifications,styles,topMargin,winHeight,winWidth,_i,_j,_len,_len1,_ref
this.setClass(this.notificationType)
sameTypeNotifications=$("body").find(".kdnotification."+this.notificationType)
if(this.getOptions().container){winHeight=this.getOptions().container.getHeight()
winWidth=this.getOptions().container.getWidth()}else _ref=KD.getSingleton("windowController"),winWidth=_ref.winWidth,winHeight=_ref.winHeight
switch(this.notificationType){case"tray":bottomMargin=8
for(i=_i=0,_len=sameTypeNotifications.length;_len>_i;i=++_i){notification=sameTypeNotifications[i]
0!==i&&(bottomMargin+=$(notification).outerHeight(!1)+8)}styles={bottom:bottomMargin,right:8,paddingRight:this.options.content&&this.options.title?10:25}
break
case"growl":topMargin=8
for(i=_j=0,_len1=sameTypeNotifications.length;_len1>_j;i=++_j){notification=sameTypeNotifications[i]
0!==i&&(topMargin+=$(notification).outerHeight(!1)+8)}styles={top:topMargin,right:8}
break
case"mini":styles={top:0,left:winWidth/2-this.getDomElement().width()/2}
break
case"sticky":styles={top:0,left:winWidth/2-this.getDomElement().width()/2}
break
default:styles={top:winHeight/2-this.getDomElement().height()/2,left:winWidth/2-this.getDomElement().width()/2}}return this.getDomElement().css(styles)}
KDNotificationView.prototype.notificationRepositionOtherNotifications=function(){var elm,h,heights,i,j,newValue,options,position,sameTypeNotifications,_i,_j,_len,_len1,_ref,_results
sameTypeNotifications=$("body").find(".kdnotification."+this.notificationType)
heights=function(){var _i,_len,_results
_results=[]
for(i=_i=0,_len=sameTypeNotifications.length;_len>_i;i=++_i){elm=sameTypeNotifications[i]
_results.push($(elm).outerHeight(!1))}return _results}()
_results=[]
for(i=_i=0,_len=sameTypeNotifications.length;_len>_i;i=++_i){elm=sameTypeNotifications[i]
switch(this.notificationType){case"tray":case"growl":newValue=0
position="tray"===this.notificationType?"bottom":"top"
_ref=heights.slice(0,+i+1||9e9)
for(j=_j=0,_len1=_ref.length;_len1>_j;j=++_j){h=_ref[j]
0!==j?newValue+=h:newValue=8}options={}
options[position]=newValue+8*i
_results.push($(elm).css(options))
break
default:_results.push(void 0)}}return _results}
KDNotificationView.prototype.notificationSetCloseHandle=function(closeManually){var _this=this
null==closeManually&&(closeManually=!1)
this.notificationCloseHandle=this.getDomElement().find(".kdnotification-close")
closeManually&&this.notificationCloseHandle.removeClass("hidden")
this.notificationCloseHandle.bind("click.notification",function(){return _this.destroy()})
return $(window).bind("keydown.notification",function(e){return 27===e.which?_this.destroy():void 0})}
KDNotificationView.prototype.notificationSetTimer=function(duration){var _this=this
if(0!==duration){this.notificationTimerDiv=this.getDomElement().find(".kdnotification-timer")
this.notificationTimerDiv.text(Math.floor(duration/1e3))
this.notificationTimeout=setTimeout(function(){return _this.getDomElement().fadeOut(200,function(){return _this.destroy()})},duration)
return this.notificationInterval=setInterval(function(){var next
next=parseInt(_this.notificationTimerDiv.text(),10)-1
return _this.notificationTimerDiv.text(next)},1e3)}}
KDNotificationView.prototype.notificationSetFollowUps=function(followUps){var chainDuration,_this=this
Array.isArray(followUps)||(followUps=[followUps])
chainDuration=0
return followUps.forEach(function(followUp){var _ref
chainDuration+=null!=(_ref=followUp.duration)?_ref:1e4
return _this.utils.wait(chainDuration,function(){followUp.title&&_this.notificationSetTitle(followUp.title)
followUp.content&&_this.notificationSetContent(followUp.content)
return _this.notificationSetPositions()})})}
KDNotificationView.prototype.notificationShowTimer=function(){var _this=this
this.notificationTimerDiv.removeClass("hidden")
this.getDomElement().bind("mouseenter",function(){return _this.notificationStopTimer()})
return this.getDomElement().bind("mouseleave",function(){var newDuration
newDuration=1e3*parseInt(_this.notificationTimerDiv.text(),10)
return _this.notificationSetTimer(newDuration)})}
KDNotificationView.prototype.notificationStopTimer=function(){clearTimeout(this.notificationTimeout)
return clearInterval(this.notificationInterval)}
KDNotificationView.prototype.notificationSetOverlay=function(options){var _this=this
null==options.transparent&&(options.transparent=!0)
null==options.destroyOnClick&&(options.destroyOnClick=!0)
this.notificationOverlay=$("<div/>",{"class":"kdoverlay transparent"})
this.notificationOverlay.hide()
options.transparent||this.notificationOverlay.removeClass("transparent")
this.notificationOverlay.appendTo("body")
this.notificationOverlay.fadeIn(200)
return this.notificationOverlay.bind("click",function(){return options.destroyOnClick?_this.destroy():void 0})}
KDNotificationView.prototype.notificationGetOverlay=function(){return this.notificationOverlay}
KDNotificationView.prototype.setLoader=function(){var diameters,loader,_ref,_ref1,_ref2,_ref3
this.setClass("w-loader")
loader=this.getOptions().loader
diameters={tray:25,growl:30,mini:18,sticky:25}
loader.diameter=diameters[this.notificationType]||30
this.loader=new KDLoaderView({size:{width:loader.diameter},loaderOptions:{color:loader.color||"#ffffff",shape:loader.shape||"spiral",diameter:loader.diameter,density:null!=(_ref=loader.density)?_ref:30,range:null!=(_ref1=loader.range)?_ref1:.4,speed:null!=(_ref2=loader.speed)?_ref2:1.5,FPS:null!=(_ref3=loader.FPS)?_ref3:24}})
this.addSubView(this.loader,null,!0)
this.setCss("paddingLeft",2*loader.diameter)
this.loader.setStyle({position:"absolute",left:loader.left||Math.floor(loader.diameter/2),top:loader.top||"50%",marginTop:-(loader.diameter/2)})
return this.loader.show()}
KDNotificationView.prototype.showLoader=function(){this.setClass("loading")
return this.loader.show()}
KDNotificationView.prototype.hideLoader=function(){this.unsetClass("loading")
return this.loader.hide()}
KDNotificationView.prototype.notificationSetContent=function(content){this.notificationContent=content
return this.getDomElement().find(".kdnotification-content").removeClass("hidden").html(content)}
KDNotificationView.prototype.notificationDisplay=function(){return this.getOptions().container?this.getOptions().container.addSubView(this):this.appendToDomBody()}
return KDNotificationView}(KDView)

var KDProgressBarView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDProgressBarView=function(_super){function KDProgressBarView(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("progressbar-container",options.cssClass)
null==options.determinate&&(options.determinate=!0)
null==options.initial&&(options.initial=!1)
null==options.title&&(options.title="")
KDProgressBarView.__super__.constructor.call(this,options,data)}__extends(KDProgressBarView,_super)
KDProgressBarView.prototype.viewAppended=function(){var initial,title,_ref
_ref=this.getOptions(),initial=_ref.initial,title=_ref.title
this.createBar()
return this.updateBar(initial||1,"%",title)}
KDProgressBarView.prototype.createBar=function(){this.addSubView(this.bar=new KDCustomHTMLView({cssClass:"bar"}))
this.addSubView(this.spinner=new KDCustomHTMLView({cssClass:"bar spinner hidden"}))
this.addSubView(this.darkLabel=new KDCustomHTMLView({tagName:"span",cssClass:"dark-label"}))
this.bar.addSubView(this.lightLabel=new KDCustomHTMLView({tagName:"span",cssClass:"light-label"}))
return this.lightLabel.setWidth(this.getWidth())}
KDProgressBarView.prototype.updateBar=function(value,unit,label){var determinate
determinate=this.getOptions().determinate
if(determinate){this.bar.show()
this.spinner.hide()
this.bar.setWidth(value,unit)
this.darkLabel.updatePartial(""+label+"&nbsp;")
return this.lightLabel.updatePartial(""+label+"&nbsp;")}this.bar.hide()
return this.spinner.show()}
return KDProgressBarView}(KDCustomHTMLView)

var KDSliderBarView,__bind=function(fn,me){return function(){return fn.apply(me,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSliderBarView=function(_super){function KDSliderBarView(options,data){null==options&&(options={})
null==data&&(data={})
this._createLabel=__bind(this._createLabel,this)
options.cssClass=KD.utils.curry("sliderbar-container",options.cssClass)
null==options.minValue&&(options.minValue=0)
null==options.maxValue&&(options.maxValue=100)
null==options.interval&&(options.interval=!1)
null==options.drawBar&&(options.drawBar=!0)
null==options.showLabels&&(options.showLabels=!0)
null==options.snap&&(options.snap=!0)
null==options.snapOnDrag&&(options.snapOnDrag=!1)
options.width||(options.width=300)
KDSliderBarView.__super__.constructor.call(this,options,data)
this.handles=[]
this.labels=[]}__extends(KDSliderBarView,_super)
KDSliderBarView.prototype.createHandles=function(){var handle,sortRef,value,_i,_len,_ref
_ref=this.getOption("handles")
for(_i=0,_len=_ref.length;_len>_i;_i++){value=_ref[_i]
this.handles.push(this.addSubView(handle=new KDSliderBarHandleView({value:value})))}sortRef=function(a,b){return a.options.value<b.options.value?-1:a.options.value>b.options.value?1:0}
this.handles.sort(sortRef)
return this.setClass("labeled")}
KDSliderBarView.prototype.drawBar=function(){var diff,handle,left,len,positions,right,_i,_len,_ref
positions=[]
_ref=this.handles
for(_i=0,_len=_ref.length;_len>_i;_i++){handle=_ref[_i]
positions.push(handle.getRelativeX())}len=positions.length
left=(len>1?parseInt(positions.first):void 0)||0
right=parseInt(positions.last)
diff=right-left
this.bar||this.addSubView(this.bar=new KDCustomHTMLView({cssClass:"bar"}))
this.bar.setWidth(diff)
return this.bar.setX(""+left+"px")}
KDSliderBarView.prototype._createLabel=function(value){var interval,label,maxValue,minValue,pos,showLabels,_ref
_ref=this.getOptions(),maxValue=_ref.maxValue,minValue=_ref.minValue,interval=_ref.interval,showLabels=_ref.showLabels
pos=100*(value-minValue)/(maxValue-minValue)
this.labels.push(this.addSubView(label=new KDCustomHTMLView({cssClass:"sliderbar-label",partial:""+value})))
return label.setX(""+pos+"%")}
KDSliderBarView.prototype.addLabels=function(){var interval,maxValue,minValue,showLabels,value,_i,_j,_len,_ref,_results,_results1
_ref=this.getOptions(),maxValue=_ref.maxValue,minValue=_ref.minValue,interval=_ref.interval,showLabels=_ref.showLabels
if(Array.isArray(showLabels)){_results=[]
for(_i=0,_len=showLabels.length;_len>_i;_i++){value=showLabels[_i]
_results.push(this._createLabel(value))}return _results}_results1=[]
for(value=_j=minValue;interval>0?maxValue>=_j:_j>=maxValue;value=_j+=interval)_results1.push(this._createLabel(value))
return _results1}
KDSliderBarView.prototype.getValues=function(){var handle,_i,_len,_ref,_results
_ref=this.handles
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){handle=_ref[_i]
_results.push(handle.getOptions().value)}return _results}
KDSliderBarView.prototype.setValue=function(value,handle){null==handle&&(handle=this.handles.first)
handle.setValue(value)
return this.emit("ValueChanged",handle)}
KDSliderBarView.prototype.setLimits=function(){var handle,i,interval,maxValue,minValue,options,_i,_len,_ref,_ref1,_ref2,_ref3,_results
_ref=this.getOptions(),maxValue=_ref.maxValue,minValue=_ref.minValue,interval=_ref.interval
if(1===this.handles.length){this.handles.first.options.leftLimit=minValue
return this.handles.first.options.rightLimit=maxValue}_ref1=this.handles
_results=[]
for(i=_i=0,_len=_ref1.length;_len>_i;i=++_i){handle=_ref1[i]
options=handle.getOptions()
options.leftLimit=(null!=(_ref2=this.handles[i-1])?_ref2.value:void 0)+interval||minValue
_results.push(options.rightLimit=(null!=(_ref3=this.handles[i+1])?_ref3.value:void 0)-interval||maxValue)}return _results}
KDSliderBarView.prototype.attachEvents=function(){return this.on("click",function(event){var clickedPos,clickedValue,closestHandle,diff,handle,maxValue,minValue,mindiff,sliderWidth,snappedValue,value,_i,_len,_ref,_ref1
_ref=this.getOptions(),maxValue=_ref.maxValue,minValue=_ref.minValue
sliderWidth=this.getWidth()
clickedPos=event.pageX-this.getBounds().x
clickedValue=(maxValue-minValue)*clickedPos/sliderWidth+minValue
snappedValue=this.handles.first.getSnappedValue(clickedValue)
closestHandle=null
mindiff=null
_ref1=this.handles
for(_i=0,_len=_ref1.length;_len>_i;_i++){handle=_ref1[_i]
value=handle.value
diff=Math.abs(clickedValue-value)
if(mindiff>diff||!mindiff){mindiff=diff
closestHandle=handle}}return closestHandle.setValue(snappedValue)})}
KDSliderBarView.prototype.viewAppended=function(){this.setWidth(this.getOption("width"))
this.createHandles()
this.setLimits()
this.getOption("drawBar")&&this.drawBar()
this.getOption("showLabels")&&this.addLabels()
return this.attachEvents()}
return KDSliderBarView}(KDCustomHTMLView)

var KDSliderBarHandleView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSliderBarHandleView=function(_super){function KDSliderBarHandleView(options){null==options&&(options={})
options.tagName="a"
options.cssClass="handle"
null==options.value&&(options.value=0)
options.draggable={axis:"x"}
KDSliderBarHandleView.__super__.constructor.call(this,options)
this.value=this.getOption("value")}__extends(KDSliderBarHandleView,_super)
KDSliderBarHandleView.prototype.attachEvents=function(){var currentValue,maxValue,minValue,width,_ref
_ref=this.parent.getOptions(),maxValue=_ref.maxValue,minValue=_ref.minValue,width=_ref.width
currentValue=this.value
this.on("DragStarted",function(){return currentValue=this.value})
this.on("DragInAction",function(){var relPos,valueChange
relPos=this.dragState.position.relative.x
valueChange=(maxValue-minValue)*relPos/width
this.setValue(currentValue+valueChange)
return this.parent.getOption("snapOnDrag")?this.snap():void 0})
return this.on("DragFinished",function(){this.parent.getOption("snap")&&this.snap()
if(currentValue!==this.value){this.emit("ValueChanged")
return this.parent.emit("ValueChanged",this)}})}
KDSliderBarHandleView.prototype.getPosition=function(){var maxValue,minValue,percentage,position,sliderWidth,_ref
_ref=this.parent.getOptions(),maxValue=_ref.maxValue,minValue=_ref.minValue
sliderWidth=this.parent.getWidth()
percentage=100*(this.value-minValue)/(maxValue-minValue)
position=sliderWidth/100*percentage
return""+position+"px"}
KDSliderBarHandleView.prototype.setValue=function(value){var leftLimit,rightLimit,_ref
_ref=this.getOptions(),leftLimit=_ref.leftLimit,rightLimit=_ref.rightLimit
"number"==typeof rightLimit&&(value=Math.min(value,rightLimit))
"number"==typeof leftLimit&&(value=Math.max(value,leftLimit))
this.value=value
this.setX(""+this.getPosition())
this.parent.getOption("drawBar")&&this.parent.drawBar()
this.parent.setLimits()
return this.parent.emit("ValueIsChanging",this.value)}
KDSliderBarHandleView.prototype.getSnappedValue=function(value){var interval,mid,mod
interval=this.parent.getOptions().interval
value||(value=this.value)
if(interval){mod=value%interval
mid=interval/2
return value=function(){switch(!1){case!(mid>=mod):return value-mod
case!(mod>mid):return value+(interval-mod)
default:return value}}()}}
KDSliderBarHandleView.prototype.snap=function(){var interval,value
interval=this.parent.getOptions().interval
value=this.getSnappedValue()
if(interval&&this.parent.getOption("snap")){this.setValue(value)
if(this.parent.getOption("drawBar"))return this.parent.drawBar()}}
KDSliderBarHandleView.prototype.viewAppended=function(){this.setX(""+this.getPosition())
this.attachEvents()
return this.parent.getOption("snap")?this.snap():void 0}
return KDSliderBarHandleView}(KDCustomHTMLView)

var KDSlideShowView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSlideShowView=function(_super){function KDSlideShowView(options,data){var animation,direction,hammer,leftToRight,topToBottom,touchCallbacks,touchEnabled,_ref1
null==options&&(options={})
options.cssClass=KD.utils.curry("kd-slide",options.cssClass)
null==options.animation&&(options.animation="move")
null==options.direction&&(options.direction="leftToRight")
null==options.touchEnabled&&(options.touchEnabled=!0)
KDSlideShowView.__super__.constructor.call(this,options,data)
this.pages=[]
this._coordsY=[]
this._currentX=0
_ref1=this.getOptions(),animation=_ref1.animation,direction=_ref1.direction,touchEnabled=_ref1.touchEnabled
topToBottom=[[""+animation+"FromTop",""+animation+"FromBottom"],[""+animation+"ToBottom",""+animation+"ToTop"]]
leftToRight=[[""+animation+"FromLeft",""+animation+"FromRight"],[""+animation+"ToRight",""+animation+"ToLeft"]]
if("topToBottom"===direction){this.xcoordAnimations=topToBottom
this.ycoordAnimations=leftToRight
touchCallbacks=["nextSubPage","previousSubPage","nextPage","previousPage"]}else{this.xcoordAnimations=leftToRight
this.ycoordAnimations=topToBottom
touchCallbacks=["nextPage","previousPage","nextSubPage","previousSubPage"]}if(touchEnabled){hammer=Hammer(this.getElement())
hammer.on("swipeleft",this.bound(touchCallbacks[0]))
hammer.on("swiperight",this.bound(touchCallbacks[1]))
hammer.on("swipeup",this.bound(touchCallbacks[2]))
hammer.on("swipedown",this.bound(touchCallbacks[3]))
hammer.on("touchmove",function(e){return e.preventDefault()})}}var X_COORD,Y_COORD,_ref
__extends(KDSlideShowView,_super)
_ref=[1,2],X_COORD=_ref[0],Y_COORD=_ref[1]
KDSlideShowView.prototype.addPage=function(page){this.addSubView(page)
if(0===this.pages.length){page.setClass("current")
this.currentPage=page}this.pages.push([page])
return this._coordsY.push(0)}
KDSlideShowView.prototype.addSubPage=function(page){var lastAddedPage
this.addSubView(page)
lastAddedPage=this.pages.last
return lastAddedPage.push(page)}
KDSlideShowView.prototype.nextPage=function(){return this.jump(this._currentX+1,X_COORD)}
KDSlideShowView.prototype.previousPage=function(){return this.jump(this._currentX-1,X_COORD)}
KDSlideShowView.prototype.nextSubPage=function(){return this.jump(this._coordsY[this._currentX]+1,Y_COORD)}
KDSlideShowView.prototype.previousSubPage=function(){return this.jump(this._coordsY[this._currentX]-1,Y_COORD)}
KDSlideShowView.prototype.jump=function(pageIndex,coord,callback){var current,currentPage,direction,index,newPage,pages,_ref1,_ref2
null==coord&&(coord=1)
null==callback&&(callback=noop)
coord===X_COORD?(_ref1=[this.pages,this._currentX],pages=_ref1[0],current=_ref1[1]):(_ref2=[this.pages[this._currentX],this._coordsY[this._currentX]],pages=_ref2[0],current=_ref2[1])
if(!(pages.length<=1)){index=Math.min(pages.length-1,Math.max(0,pageIndex))
if(current!==index){direction=current>index?0:1
if(coord===X_COORD){currentPage=pages[current][this._coordsY[current]]
newPage=pages[index][this._coordsY[index]]
this._currentX=index
newPage.move(this.xcoordAnimations[0][direction])
currentPage.move(this.xcoordAnimations[1][direction])}else{currentPage=pages[current]
newPage=pages[index]
this._coordsY[this._currentX]=index
newPage.move(this.ycoordAnimations[0][direction])
currentPage.move(this.ycoordAnimations[1][direction])}this.emit("CurrentPageChanged",{x:this._currentX,y:this._coordsY[this._currentX]})
newPage.setClass("current")
this.currentPage=newPage
return this.utils.wait(600,function(){currentPage.unsetClass("current")
return callback()})}}}
return KDSlideShowView}(JView)

var KDSlidePageView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDSlidePageView=function(_super){function KDSlidePageView(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("kd-page",options.cssClass)
KDSlidePageView.__super__.constructor.call(this,options,data)
this._currentCssClass=null}__extends(KDSlidePageView,_super)
KDSlidePageView.prototype.move=function(cssClass){if(cssClass){this.unsetClass(this._currentCssClass)
this._currentCssClass=cssClass
return this.setClass(cssClass)}}
return KDSlidePageView}(JView)

var KDDialogView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDDialogView=function(_super){function KDDialogView(options){var defaultOptions,_this=this
defaultOptions={duration:200,topOffset:0,overlay:!0,buttons:{Cancel:{style:"clean-red",callback:function(){return _this.hide()}}}}
options=$.extend(defaultOptions,options)
KDDialogView.__super__.constructor.apply(this,arguments)
this.setClass("kddialogview")
this.$().hide()
this.setButtons()
this.setTopOffset()}__extends(KDDialogView,_super)
KDDialogView.prototype.show=function(){var duration,overlay,_ref
_ref=this.getOptions(),duration=_ref.duration,overlay=_ref.overlay
overlay&&this.putOverlay()
return this.$().slideDown(duration)}
KDDialogView.prototype.hide=function(){var duration,_this=this
duration=this.getOptions().duration
this.$overlay.fadeOut(duration,function(){return _this.$overlay.remove()})
return this.$().slideUp(duration,function(){return _this.destroy()})}
KDDialogView.prototype.setButtons=function(){var buttonOptions,buttonTitle,buttons,_results
buttons=this.getOptions().buttons
this.buttons={}
this.buttonHolder=new KDView({cssClass:"kddialog-buttons clearfix"})
this.addSubView(this.buttonHolder)
_results=[]
for(buttonTitle in buttons)if(__hasProp.call(buttons,buttonTitle)){buttonOptions=buttons[buttonTitle]
_results.push(this.createButton(buttonTitle,buttonOptions))}return _results}
KDDialogView.prototype.createButton=function(title,buttonOptions){var button
this.buttonHolder.addSubView(button=new KDButtonView({title:title,loader:null!=buttonOptions.loader?buttonOptions.loader:void 0,style:null!=buttonOptions.style?buttonOptions.style:void 0,callback:null!=buttonOptions.callback?buttonOptions.callback:void 0}))
return this.buttons[title]=button}
KDDialogView.prototype.setTopOffset=function(){var topOffset
topOffset=this.getOptions().topOffset
return this.$().css("top",topOffset)}
KDDialogView.prototype.putOverlay=function(){var topOffset,_this=this
topOffset=this.getOptions().topOffset
this.$overlay=$("<div/>",{"class":"kdoverlay",css:{height:this.$().parent().height()-topOffset,top:topOffset}})
this.$overlay.hide()
this.$overlay.appendTo(this.$().parent())
this.$overlay.fadeIn(200)
return this.$overlay.bind("click",function(){return _this.hide()})}
return KDDialogView}(KDView)

var KDTooltip,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTooltip=function(_super){function KDTooltip(options,data){var _this=this
options.bind||(options.bind="mouseenter mouseleave")
null==options.sticky&&(options.sticky=!1)
options.cssClass=KD.utils.curry("kdtooltip",options.cssClass)
KDTooltip.__super__.constructor.call(this,options,data)
this.visible=!0
this.parentView=this.getDelegate()
this.wrapper=new KDView({cssClass:"wrapper"})
this.arrow=new KDView({cssClass:"arrow"})
this.getOptions().animate?this.setClass("out"):this.hide()
this.addListeners()
this.getSingleton("windowController").on("ScrollHappened",this.bound("hide"))
this.once("viewAppended",function(){var o
o=_this.getOptions()
if(null!=o.view)_this.setView(o.view)
else{_this.setClass("just-text")
_this.setTitle(o.title,o)}_this.parentView.emit("TooltipReady")
_this.addSubView(_this.arrow)
return _this.addSubView(_this.wrapper)})}var directionMap,getBoundaryViolations,getCoordsDiff,getCoordsFromPlacement,placementMap
__extends(KDTooltip,_super)
KDTooltip.prototype.show=function(){var selector
selector=this.getOptions().selector
if(!selector){this.display()
return KDTooltip.__super__.show.apply(this,arguments)}}
KDTooltip.prototype.hide=function(){KDTooltip.__super__.hide.apply(this,arguments)
this.getDomElement().remove()
return this.getSingleton("windowController").removeLayer(this)}
KDTooltip.prototype.update=function(o,view){null==o&&(o=this.getOptions())
null==view&&(view=null)
if(view)return this.setView(view)
o.selector||(o.selector=null)
o.title||(o.title="")
this.getOptions().title=o.title
this.setTitle(o.title)
return this.display(this.getOptions())}
KDTooltip.prototype.addListeners=function(){var events,intentTimer,name,_hide,_i,_len,_show,_this=this
intentTimer=null
events=this.getOptions().events
_show=function(){return intentTimer?void 0:intentTimer=KD.utils.wait(77,function(){intentTimer=null
return _this.show()})}
_hide=function(){return intentTimer?intentTimer=KD.utils.killWait(intentTimer):KD.utils.wait(77,_this.bound("hide"))}
for(_i=0,_len=events.length;_len>_i;_i++){name=events[_i]
this.parentView.bindEvent(name)}this.parentView.on("mouseenter",_show)
this.parentView.on("mouseleave",_hide)
this.on("ReceivedClickElsewhere",this.bound("hide"))
return this.once("KDObjectWillBeDestroyed",function(){_this.parentView.off("mouseenter",_show)
return _this.parentView.off("mouseleave",_hide)})}
KDTooltip.prototype.setView=function(childView){var constructorName,data,options
if(childView){null!=this.wrapper.view&&this.wrapper.view.destroy()
if(childView.constructorName){options=childView.options,data=childView.data,constructorName=childView.constructorName
return this.childView=new constructorName(options,data)}return this.wrapper.addSubView(childView)}}
KDTooltip.prototype.getView=function(){return this.childView}
KDTooltip.prototype.destroy=function(){this.parentView.tooltip=null
delete this.parentView.tooltip
return KDTooltip.__super__.destroy.apply(this,arguments)}
KDTooltip.prototype.translateCompassDirections=function(o){var gravity,placement
placement=o.placement,gravity=o.gravity
o.placement=placementMap[placement]
o.direction=directionMap(o.placement,gravity)
return o}
KDTooltip.prototype.display=function(o){var _this=this
null==o&&(o=this.getOptions())
this.appendToDomBody()
this.getSingleton("windowController").addLayer(this)
o.gravity&&(o=this.translateCompassDirections(o))
o.gravity=null
o.animate&&this.setClass("in")
return this.utils.defer(function(){return _this.setPositions(o)})}
KDTooltip.prototype.getCorrectPositionCoordinates=function(o,positionValues,callback){var container,correctValues,d,direction,forcePosition,placement,selector,variant,variants,violations,_i,_len
null==o&&(o={})
null==callback&&(callback=noop)
container=this.$()
selector=this.parentView.$(o.selector)
d={container:{height:container.height(),width:container.width()},selector:{offset:selector.offset(),height:selector.height(),width:selector.width()}}
placement=positionValues.placement,direction=positionValues.direction
forcePosition=this.getOptions().forcePosition
violations=getBoundaryViolations(getCoordsFromPlacement(d,placement,direction),d.container.width,d.container.height)
if(!forcePosition&&Object.keys(violations).length>0){variants=[["top","right"],["right","top"],["right","bottom"],["bottom","right"],["top","left"],["top","center"],["right","center"],["bottom","center"],["bottom","left"],["left","bottom"],["left","center"],["left","top"]]
for(_i=0,_len=variants.length;_len>_i;_i++){variant=variants[_i]
if(0===Object.keys(getBoundaryViolations(getCoordsFromPlacement(d,variant[0],variant[1]),d.container.width,d.container.height)).length){placement=variant[0],direction=variant[1]
break}}}correctValues={coords:getCoordsFromPlacement(d,placement,direction),placement:placement,direction:direction}
callback(correctValues)
return correctValues}
KDTooltip.prototype.setPositions=function(o,animate){var coords,direction,direction_,offset,placement,placement_,_i,_j,_len,_len1,_ref,_ref1,_ref2,_this=this
null==o&&(o=this.getOptions())
null==animate&&(animate=!1)
animate&&this.setClass("animate-movement")
placement=o.placement||"top"
direction=o.direction||"right"
offset=Number===typeof o.offset?{top:o.offset,left:0}:o.offset
direction="top"!==placement&&"bottom"!==placement||"top"!==direction&&"bottom"!==direction?"left"!==placement&&"right"!==placement||"left"!==direction&&"right"!==direction?direction:"center":"center"
_ref=this.getCorrectPositionCoordinates(o,{placement:placement,direction:direction}),coords=_ref.coords,placement=_ref.placement,direction=_ref.direction
_ref1=["top","bottom","left","right"]
for(_i=0,_len=_ref1.length;_len>_i;_i++){placement_=_ref1[_i]
placement===placement_?this.setClass("placement-"+placement_):this.unsetClass("placement-"+placement_)}_ref2=["top","bottom","left","right","center"]
for(_j=0,_len1=_ref2.length;_len1>_j;_j++){direction_=_ref2[_j]
direction===direction_?this.setClass("direction-"+direction_):this.unsetClass("direction-"+direction_)}this.$().css({left:coords.left+offset.left,top:coords.top+offset.top})
return this.utils.wait(500,function(){return _this.unsetClass("animate-movement")})}
KDTooltip.prototype.setTitle=function(title,o){null==o&&(o={})
return o.html!==!1?this.wrapper.updatePartial(title):this.wrapper.updatePartial(Encoder.htmlEncode(title))}
directionMap=function(placement,gravity){return"top"===placement||"bottom"===placement?/e/.test(gravity)?"left":/w/.test(gravity)?"right":"center":"left"===placement||"right"===placement?/n/.test(gravity)?"top":/s/.test(gravity)?"bottom":placement:void 0}
placementMap={top:"top",above:"top",below:"bottom",bottom:"bottom",left:"left",right:"right"}
getBoundaryViolations=function(coordinates,width,height){var violations
violations={}
coordinates.left<0&&(violations.left=-coordinates.left)
coordinates.top<0&&(violations.top=-coordinates.top)
coordinates.left+width>window.innerWidth&&(violations.right=coordinates.left+width-window.innerWidth)
coordinates.top+height>window.innerHeight&&(violations.bottom=coordinates.top+height-window.innerHeight)
return violations}
getCoordsDiff=function(dimensions,type,center){var diff
null==center&&(center=!1)
diff=dimensions.selector[type]-dimensions.container[type]
return center?diff/2:diff}
getCoordsFromPlacement=function(dimensions,placement,direction){var coordinates,dynamicAxis,dynamicC,exclusion,staticAxis,staticC,_ref
coordinates={top:dimensions.selector.offset.top,left:dimensions.selector.offset.left}
_ref=/o/.test(placement)?["height","width","top","left","right"]:["width","height","left","top","bottom"],staticAxis=_ref[0],dynamicAxis=_ref[1],staticC=_ref[2],dynamicC=_ref[3],exclusion=_ref[4]
coordinates[staticC]+=placement.length<5?-(dimensions.container[staticAxis]+10):dimensions.selector[staticAxis]+10
direction!==exclusion&&(coordinates[dynamicC]+=getCoordsDiff(dimensions,dynamicAxis,"center"===direction))
return coordinates}
return KDTooltip}.call(this,KDView)

var KDAutoCompleteController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__slice=[].slice
KDAutoCompleteController=function(_super){function KDAutoCompleteController(options,data){var mainView
null==options&&(options={})
options=$.extend({view:mainView=options.view||new KDAutoComplete({name:options.name,label:options.label||new KDLabelView({title:options.name})}),itemClass:KDAutoCompleteListItemView,selectedItemClass:KDAutoCompletedItem,nothingFoundItemClass:KDAutoCompleteNothingFoundItem,fetchingItemClass:KDAutoCompleteFetchingItem,listWrapperCssClass:"",minSuggestionLength:2,selectedItemsLimit:null,itemDataPath:"",separator:",",wrapper:"parent",submitValuesAsText:!1,defaultValue:[]},options)
KDAutoCompleteController.__super__.constructor.call(this,options,data)
mainView.on("focus",this.bound("updateDropdownContents"))
this.lastPrefix=null
this.selectedItemData=[]
this.hiddenInputs={}
this.selectedItemCounter=0
this.readyToShowDropDown=!0}__extends(KDAutoCompleteController,_super)
KDAutoCompleteController.prototype.reset=function(){var item,subViews,_i,_len,_results
subViews=this.itemWrapper.getSubViews().slice()
_results=[]
for(_i=0,_len=subViews.length;_len>_i;_i++){item=subViews[_i]
_results.push(this.removeFromSubmitQueue(item))}return _results}
KDAutoCompleteController.prototype.loadView=function(mainView){var _this=this
this.createDropDown()
this.getAutoCompletedItemParent()
this.setDefaultValue()
mainView.on("keyup",this.utils.throttle(this.bound("keyUpOnInputView")),300)
return mainView.on("keydown",function(event){return _this.keyDownOnInputView(event)})}
KDAutoCompleteController.prototype.setDefaultValue=function(defaultItems){var defaultValue,item,itemDataPath,_i,_len,_ref,_results
_ref=this.getOptions(),defaultValue=_ref.defaultValue,itemDataPath=_ref.itemDataPath
defaultItems||(defaultItems=defaultValue)
_results=[]
for(_i=0,_len=defaultItems.length;_len>_i;_i++){item=defaultItems[_i]
_results.push(this.addItemToSubmitQueue(this.getView(),item))}return _results}
KDAutoCompleteController.prototype.keyDownOnInputView=function(event){var autoCompleteView
autoCompleteView=this.getView()
switch(event.which){case 13:case 9:if(""!==autoCompleteView.getValue()&&event.shiftKey!==!0){this.submitAutoComplete(autoCompleteView.getValue())
event.stopPropagation()
event.preventDefault()
this.readyToShowDropDown=!1
return!1}return!0
case 27:this.hideDropdown()
break
case 38:if(this.dropdown.getView().$().is(":visible")){this.dropdown.getListView().goUp()
event.stopPropagation()
event.preventDefault()
return!1}break
case 40:if(this.dropdown.getView().$().is(":visible")){this.dropdown.getListView().goDown()
event.stopPropagation()
event.preventDefault()
return!1}break
default:this.readyToShowDropDown=!0}return!1}
KDAutoCompleteController.prototype.getPrefix=function(){var items,prefix,separator
separator=this.getOptions().separator
items=this.getView().getValue().split(separator)
prefix=items[items.length-1]
return prefix}
KDAutoCompleteController.prototype.createDropDown=function(data){var dropdownListView,dropdownWrapper,windowController,_this=this
null==data&&(data=[])
this.dropdownPrefix=""
this.dropdownListView=dropdownListView=new KDAutoCompleteListView({itemClass:this.getOptions().itemClass},{items:data})
dropdownListView.on("ItemsDeselected",function(){var view
view=_this.getView()
return view.$input().trigger("focus")})
dropdownListView.on("KDAutoCompleteSubmit",this.bound("submitAutoComplete"))
windowController=KD.getSingleton("windowController")
this.dropdown=new KDListViewController({view:dropdownListView})
dropdownWrapper=this.dropdown.getView()
dropdownWrapper.on("ReceivedClickElsewhere",function(){return _this.hideDropdown()})
dropdownWrapper.setClass("kdautocomplete hidden "+this.getOptions().listWrapperCssClass)
return dropdownWrapper.appendToDomBody()}
KDAutoCompleteController.prototype.hideDropdown=function(){var dropdownWrapper
dropdownWrapper=this.dropdown.getView()
return dropdownWrapper.$().fadeOut(75)}
KDAutoCompleteController.prototype.showDropdown=function(){var dropdownWrapper,input,offset,windowController
if(this.readyToShowDropDown){windowController=KD.getSingleton("windowController")
dropdownWrapper=this.dropdown.getView()
dropdownWrapper.unsetClass("hidden")
input=this.getView()
offset=input.$().offset()
offset.top+=input.getHeight()
dropdownWrapper.$().css(offset)
dropdownWrapper.$().fadeIn(75)
return windowController.addLayer(dropdownWrapper)}}
KDAutoCompleteController.prototype.refreshDropDown=function(data){var allowNewSuggestions,exactMatches,exactPattern,inexactMatches,itemDataPath,listView,minSuggestionLength,_ref,_this=this
null==data&&(data=[])
listView=this.dropdown.getListView()
this.dropdown.removeAllItems()
listView.userInput=this.dropdownPrefix
exactPattern=RegExp("^"+this.dropdownPrefix.replace(/[^\s\w]/,"")+"$","i")
exactMatches=[]
inexactMatches=[]
_ref=this.getOptions(),itemDataPath=_ref.itemDataPath,allowNewSuggestions=_ref.allowNewSuggestions,minSuggestionLength=_ref.minSuggestionLength
data.forEach(function(datum){var match
if(!_this.isItemAlreadySelected(datum)){match=JsPath.getAt(datum,itemDataPath)
return exactPattern.test(match)?exactMatches.push(datum):inexactMatches.push(datum)}})
this.dropdownPrefix.length>=minSuggestionLength&&allowNewSuggestions&&!exactMatches.length&&this.dropdown.getListView().addItemView(this.getNoItemFoundView())
data=exactMatches.concat(inexactMatches)
this.dropdown.instantiateListItems(data)
return this.dropdown.getListView().goDown()}
KDAutoCompleteController.prototype.submitAutoComplete=function(){var activeItem,inputView
inputView=this.getView()
if(null===this.getOptions().selectedItemsLimit||this.getOptions().selectedItemsLimit>this.selectedItemCounter){activeItem=this.dropdown.getListView().getActiveItem()
activeItem.item&&this.appendAutoCompletedItem()
this.addItemToSubmitQueue(activeItem.item)
this.emit("ItemListChanged",this.selectedItemCounter)}else{inputView.setValue("")
KD.getSingleton("windowController").setKeyView(null)
new KDNotificationView({type:"mini",title:"You can add up to "+this.getOptions().selectedItemsLimit+" items!",duration:4e3})}return this.hideDropdown()}
KDAutoCompleteController.prototype.getAutoCompletedItemParent=function(){var outputWrapper
outputWrapper=this.getOptions().outputWrapper
return this.itemWrapper=outputWrapper instanceof KDView?outputWrapper:this.getView()}
KDAutoCompleteController.prototype.isItemAlreadySelected=function(data){var alreadySelected,customCompare,isCaseSensitive,itemDataPath,selected,selectedData,suggested,_i,_len,_ref,_ref1
_ref=this.getOptions(),itemDataPath=_ref.itemDataPath,customCompare=_ref.customCompare,isCaseSensitive=_ref.isCaseSensitive
suggested=JsPath.getAt(data,itemDataPath)
_ref1=this.getSelectedItemData()
for(_i=0,_len=_ref1.length;_len>_i;_i++){selectedData=_ref1[_i]
if(null!=customCompare){alreadySelected=customCompare(data,selectedData)
if(alreadySelected)return!0}else{selected=JsPath.getAt(selectedData,itemDataPath)
if(!isCaseSensitive){suggested=suggested.toLowerCase()
selected=selected.toLowerCase()}if(suggested===selected)return!0}}return!1}
KDAutoCompleteController.prototype.addHiddenInputItem=function(name,value){return this.itemWrapper.addSubView(this.hiddenInputs[name]=new KDInputView({type:"hidden",name:name,defaultValue:value}))}
KDAutoCompleteController.prototype.removeHiddenInputItem=function(name){return delete this.hiddenInputs[name]}
KDAutoCompleteController.prototype.addSelectedItem=function(name,data){var itemView,selectedItemClass
selectedItemClass=this.getOptions().selectedItemClass
this.itemWrapper.addSubView(itemView=new selectedItemClass({cssClass:"kdautocompletedlistitem",delegate:this,name:name},data))
return itemView.setPartial("<span class='close-icon'></span>")}
KDAutoCompleteController.prototype.getSelectedItemData=function(){return this.selectedItemData}
KDAutoCompleteController.prototype.addSelectedItemData=function(data){return this.getSelectedItemData().push(data)}
KDAutoCompleteController.prototype.removeSelectedItemData=function(data){var i,selectedData,selectedItemData,_i,_len
selectedItemData=this.getSelectedItemData()
for(i=_i=0,_len=selectedItemData.length;_len>_i;i=++_i){selectedData=selectedItemData[i]
if(selectedData===data){selectedItemData.splice(i,1)
return}}}
KDAutoCompleteController.prototype.getCollectionPath=function(){var collectionName,leaf,name,path,_i,_ref
name=this.getOptions().name
if(!name)throw new Error("No name!")
_ref=name.split("."),path=2<=_ref.length?__slice.call(_ref,0,_i=_ref.length-1):(_i=0,[]),leaf=_ref[_i++]
collectionName=Inflector.pluralize(leaf)
path.push(collectionName)
return path.join(".")}
KDAutoCompleteController.prototype.addSuggestion=function(title){return this.emit("AutocompleteSuggestionWasAdded",title)}
KDAutoCompleteController.prototype.addItemToSubmitQueue=function(item,data){var collection,form,itemDataPath,itemName,itemValue,name,path,submitValuesAsText,_ref
data||(data=null!=item?item.getData():void 0)
if(data||(null!=item?item.getOptions().userInput:void 0)){_ref=this.getOptions(),name=_ref.name,itemDataPath=_ref.itemDataPath,form=_ref.form,submitValuesAsText=_ref.submitValuesAsText
if(data)itemValue=submitValuesAsText?JsPath.getAt(data,itemDataPath):data
else{itemValue=item.getOptions().userInput
data=JsPath(itemDataPath,itemValue)}if(this.isItemAlreadySelected(data))return!1
path=this.getCollectionPath()
itemName=""+name+"-"+this.selectedItemCounter++
if(form){collection=form.getCustomData(path)||[]
collection.push(submitValuesAsText?itemValue:("function"==typeof itemValue.getId?itemValue.getId():void 0)?{constructorName:itemValue.constructor.name,id:itemValue.getId(),title:itemValue.title}:{$suggest:itemValue})
form.addCustomData(path,collection)
item.getOptions().userInput===!0&&this.selectedItemCounter++}else this.addHiddenInputItem(path,itemValue)
this.addSelectedItemData(data)
this.addSelectedItem(itemName,data)
return this.getView().setValue(this.dropdownPrefix="")}}
KDAutoCompleteController.prototype.removeFromSubmitQueue=function(item,data){var collection,form,itemDataPath,path,_ref
_ref=this.getOptions(),itemDataPath=_ref.itemDataPath,form=_ref.form
data||(data=item.getData())
path=this.getCollectionPath()
if(form){collection=JsPath.getAt(form.getCustomData(),path)
collection=collection.filter(function(sibling){var id
id="function"==typeof data.getId?data.getId():void 0
return null==id?sibling.$suggest!==data.title:sibling.id!==id})
JsPath.setAt(form.getCustomData(),path,collection)}else this.removeHiddenInputItem(path)
this.removeSelectedItemData(data)
this.selectedItemCounter--
item.destroy()
return this.emit("ItemListChanged",this.selectedItemCounter)}
KDAutoCompleteController.prototype.appendAutoCompletedItem=function(){this.getView().setValue("")
return this.getView().$input().trigger("focus")}
KDAutoCompleteController.prototype.updateDropdownContents=function(){var inputView,_this=this
inputView=this.getView()
""===inputView.getValue()&&this.hideDropdown()
if(""!==inputView.getValue()&&this.dropdownPrefix!==inputView.getValue()&&this.dropdown.getView().$().not(":visible")){this.dropdownPrefix=inputView.getValue()
return this.fetch(function(data){_this.refreshDropDown(data)
return _this.showDropdown()})}}
KDAutoCompleteController.prototype.keyUpOnInputView=function(event){var _ref
if(9!==(_ref=event.keyCode)&&38!==_ref&&40!==_ref){this.updateDropdownContents()
return!1}}
KDAutoCompleteController.prototype.fetch=function(callback){var args,source
args={}
this.getOptions().fetchInputName?args[this.getOptions().fetchInputName]=this.getView().getValue():args={inputValue:this.getView().getValue()}
this.dropdownPrefix=this.getView().getValue()
source=this.getOptions().dataSource
return source(args,callback)}
KDAutoCompleteController.prototype.showFetching=function(){var fetchingItemClass,view,_ref
fetchingItemClass=this.getOptions().fetchingItemClass
if(!((null!=(_ref=this.dropdown.getListView().items)?_ref[0]:void 0)instanceof KDAutoCompleteFetchingItem)){view=new fetchingItemClass
return this.dropdown.getListView().items.length?this.dropdown.getListView().addItemView(view,0):this.dropdown.getListView().addItemView(view)}}
KDAutoCompleteController.prototype.getNoItemFoundView=function(suggestion){var nothingFoundItemClass,view
nothingFoundItemClass=this.getOptions().nothingFoundItemClass
return view=new nothingFoundItemClass({delegate:this.dropdown.getListView(),userInput:suggestion||this.getView().getValue()})}
KDAutoCompleteController.prototype.showNoDataFound=function(){var noItemFoundView
noItemFoundView=this.getNoItemFoundView()
this.dropdown.removeAllItems()
this.dropdown.getListView().addItemView(noItemFoundView)
return this.showDropdown()}
KDAutoCompleteController.prototype.destroy=function(){this.dropdown.getView().destroy()
return KDAutoCompleteController.__super__.destroy.apply(this,arguments)}
return KDAutoCompleteController}(KDViewController)

var KDAutoComplete,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDAutoComplete=function(_super){function KDAutoComplete(){_ref=KDAutoComplete.__super__.constructor.apply(this,arguments)
return _ref}__extends(KDAutoComplete,_super)
KDAutoComplete.prototype.mouseDown=function(){return this.focus()}
KDAutoComplete.prototype.setDomElement=function(){return this.domElement=$("<div class='kdautocompletewrapper clearfix'><input type='text' class='kdinput text'/></div>")}
KDAutoComplete.prototype.setDomId=function(){this.$input().attr("id",this.getDomId())
this.$input().attr("name",this.getName())
return this.$input().data("data-id",this.getId())}
KDAutoComplete.prototype.setDefaultValue=function(value){this.inputDefaultValue=value
return this.setValue(value)}
KDAutoComplete.prototype.$input=function(){return this.$("input").eq(0)}
KDAutoComplete.prototype.getValue=function(){return this.$input().val()}
KDAutoComplete.prototype.setValue=function(value){return this.$input().val(value)}
KDAutoComplete.prototype.bindEvents=function(){return KDAutoComplete.__super__.bindEvents.call(this,this.$input())}
KDAutoComplete.prototype.blur=function(){this.unsetClass("focus")
return!0}
KDAutoComplete.prototype.focus=function(){this.setClass("focus")
return KDAutoComplete.__super__.focus.apply(this,arguments)}
KDAutoComplete.prototype.keyDown=function(){KD.getSingleton("windowController").setKeyView(this)
return!0}
KDAutoComplete.prototype.getLeftOffset=function(){return this.$input().prev().width()}
KDAutoComplete.prototype.destroyDropdown=function(){null!=this.dropdown&&this.dropdown.destroy()
this.dropdownPrefix=""
return this.dropdown=null}
KDAutoComplete.prototype.setPlaceHolder=function(value){return this.$input()[0].setAttribute("placeholder",value)}
KDAutoComplete.prototype.setFocus=function(){KDAutoComplete.__super__.setFocus.apply(this,arguments)
return this.$input().trigger("focus")}
KDAutoComplete.prototype.setBlur=function(){KDAutoComplete.__super__.setBlur.apply(this,arguments)
return this.$input().trigger("blur")}
return KDAutoComplete}(KDInputView)

var KDAutoCompleteListView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDAutoCompleteListView=function(_super){function KDAutoCompleteListView(options,data){KDAutoCompleteListView.__super__.constructor.call(this,options,data)
this.setClass("kdautocompletelist")}__extends(KDAutoCompleteListView,_super)
KDAutoCompleteListView.prototype.goDown=function(){var activeItem,nextItem,_ref
activeItem=this.getActiveItem()
if(null==activeItem.index)return null!=(_ref=this.items[0])?_ref.makeItemActive():void 0
nextItem=this.items[activeItem.index+1]
return null!=nextItem?nextItem.makeItemActive():void 0}
KDAutoCompleteListView.prototype.goUp=function(){var activeItem
activeItem=this.getActiveItem()
return null!=activeItem.index?null!=this.items[activeItem.index-1]?this.items[activeItem.index-1].makeItemActive():this.emit("ItemsDeselected"):this.items[0].makeItemActive()}
KDAutoCompleteListView.prototype.getActiveItem=function(){var active,i,item,_i,_len,_ref
active={index:null,item:null}
_ref=this.items
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){item=_ref[i]
if(item.active){active.item=item
active.index=i
break}}return active}
return KDAutoCompleteListView}(KDListView)

var KDAutoCompleteListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDAutoCompleteListItemView=function(_super){function KDAutoCompleteListItemView(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("kdautocompletelistitem",options.cssClass)
options.bind="mouseenter mouseleave"
KDAutoCompleteListItemView.__super__.constructor.call(this,options,data)
this.active=!1}__extends(KDAutoCompleteListItemView,_super)
KDAutoCompleteListItemView.prototype.viewAppended=function(){return this.updatePartial(this.partial(this.data))}
KDAutoCompleteListItemView.prototype.mouseEnter=function(){return this.makeItemActive()}
KDAutoCompleteListItemView.prototype.mouseLeave=function(){return this.makeItemInactive()}
KDAutoCompleteListItemView.prototype.makeItemActive=function(){var item,_i,_len,_ref
_ref=this.getDelegate().items
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
item.makeItemInactive()}this.active=!0
return this.setClass("active")}
KDAutoCompleteListItemView.prototype.makeItemInactive=function(){this.active=!1
return this.unsetClass("active")}
KDAutoCompleteListItemView.prototype.click=function(){var list
list=this.getDelegate()
list.emit("KDAutoCompleteSubmit",this,this.data)
return!1}
KDAutoCompleteListItemView.prototype.partial=function(){return"<div class='autocomplete-item clearfix'>Default item</div>"}
return KDAutoCompleteListItemView}(KDListItemView)

var KDMultipleInputView,KDSimpleAutocomplete,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
KDSimpleAutocomplete=function(_super){function KDSimpleAutocomplete(){_ref=KDSimpleAutocomplete.__super__.constructor.apply(this,arguments)
return _ref}__extends(KDSimpleAutocomplete,_super)
KDSimpleAutocomplete.prototype.addItemToSubmitQueue=function(item){var itemValue
itemValue=JsPath.getAt(item.getData(),this.getOptions().itemDataPath)
return this.setValue(itemValue)}
KDSimpleAutocomplete.prototype.keyUp=function(event){return 13!==event.keyCode?KDSimpleAutocomplete.__super__.keyUp.apply(this,arguments):void 0}
KDSimpleAutocomplete.prototype.showNoDataFound=function(){this.dropdown.removeAllItems()
return this.hideDropdown()}
return KDSimpleAutocomplete}(KDAutoComplete)
KDMultipleInputView=function(_super){function KDMultipleInputView(options){this._values=[]
options=$.extend({icon:"noicon",title:""},options)
KDMultipleInputView.__super__.constructor.call(this,options)}__extends(KDMultipleInputView,_super)
KDMultipleInputView.prototype.focus=function(){return KD.getSingleton("windowController").setKeyView(this)}
KDMultipleInputView.prototype.viewAppended=function(){this.list=new MultipleInputListView({delegate:this})
return this.addSubView(this.list)}
KDMultipleInputView.prototype.$input=function(){return this.$().find("input.main").eq(0)}
KDMultipleInputView.prototype.getValues=function(){return this._values}
KDMultipleInputView.prototype.addItemToSubmitQueue=function(){KDMultipleInputView.__super__.addItemToSubmitQueue.apply(this,arguments)
return this.inputAddCurrentValue()}
KDMultipleInputView.prototype.keyUp=function(event){13===event.keyCode&&this.inputAddCurrentValue()
return KDMultipleInputView.__super__.keyUp.apply(this,arguments)}
KDMultipleInputView.prototype.inputRemoveValue=function(value){var index
index=this._values.indexOf(value)
index>-1&&this._values.splice(index,1)
return this._inputChanged()}
KDMultipleInputView.prototype.clear=function(){this._values=[]
this.removeAllItems()
return this._inputChanged()}
KDMultipleInputView.prototype.inputAddCurrentValue=function(){var value
value=this.$input().val()
value=$.trim(value)
if(!(__indexOf.call(this._values,value)>=0||""===value)){this._values.push(value)
this.$input().val("")
this.list.addItems([value])
return this._inputChanged()}}
KDMultipleInputView.prototype._inputChanged=function(){var index,input,inputName,newInput,value,_i,_j,_len,_len1,_ref1,_ref2
this._hiddenInputs||(this._hiddenInputs=[])
_ref1=this._hiddenInputs
for(_i=0,_len=_ref1.length;_len>_i;_i++){input=_ref1[_i]
input.destroy()}inputName=this.getOptions().name
_ref2=this._values
for(index=_j=0,_len1=_ref2.length;_len1>_j;index=++_j){value=_ref2[index]
newInput=new KDInputView({type:"hidden",name:inputName+("["+index+"]"),defaultValue:value})
this._hiddenInputs.push(newInput)
this.addSubView(newInput)}return this.emit("MultipleInputChanged",{values:this.getValue()})}
KDMultipleInputView.prototype.click=function(event){return $(event.target).hasClass("addNewItem")?this.inputAddCurrentValue():void 0}
KDMultipleInputView.prototype.setDomId=function(){this.$input().attr("id",this.getDomId())
return this.$input().data("data-id",this.getId())}
KDMultipleInputView.prototype.setDomElement=function(){return this.domElement=$("<div class='filter kdview'>      <h2>"+this.getOptions().title+"</h2>      <div class='clearfix'>        <span class='"+this.getOptions().icon+"'></span>        <input type='text' class='main'>        <a href='#' class='addNewItem'>+</a>      </div>    </div>")}
return KDMultipleInputView}(KDSimpleAutocomplete)

var MultipleInputListView,MultipleListItemView,NoAutocompleteMultipleListView,_ref,_ref1,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NoAutocompleteMultipleListView=function(_super){function NoAutocompleteMultipleListView(options,data){var defaults
null==options&&(options={})
defaults={cssClass:"common-view input-with-extras"}
options=$.extend(defaults,options)
NoAutocompleteMultipleListView.__super__.constructor.call(this,options,data)}__extends(NoAutocompleteMultipleListView,_super)
NoAutocompleteMultipleListView.prototype.viewAppended=function(){var button,defaults,icon,input,options,_ref,_this=this
_ref=this.options,icon=_ref.icon,input=_ref.input,button=_ref.button
if(icon){this.setClass("with-icon")
options={tagName:"span",cssClass:"icon "+icon}
this.addSubView(this.icon=new KDCustomHTMLView(options))}input&&this.addSubView(this.input=new NoAutocompleteInputView(input))
if(button){defaults={callback:function(event){event.preventDefault()
event.stopPropagation()
return _this.input.inputAddCurrentValue()}}
button=$.extend(defaults,button)
return this.addSubView(this.button=new KDButtonView(button))}}
return NoAutocompleteMultipleListView}(KDView)
MultipleInputListView=function(_super){function MultipleInputListView(){_ref=MultipleInputListView.__super__.constructor.apply(this,arguments)
return _ref}__extends(MultipleInputListView,_super)
MultipleInputListView.prototype.setDomElement=function(){return this.domElement=$("<p class='search-tags clearfix'></p>")}
MultipleInputListView.prototype.addItems=function(items){var item,newItem,_i,_len,_results
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
newItem=new MultipleListItemView({delegate:this},item)
_results.push(this.addItemView(newItem))}return _results}
MultipleInputListView.prototype.removeListItem=function(instance){MultipleInputListView.__super__.removeListItem.call(this,instance)
return this.getDelegate().inputRemoveValue(instance.getData())}
return MultipleInputListView}(KDListView)
MultipleListItemView=function(_super){function MultipleListItemView(){_ref1=MultipleListItemView.__super__.constructor.apply(this,arguments)
return _ref1}__extends(MultipleListItemView,_super)
MultipleListItemView.prototype.click=function(event){return $(event.target).hasClass("removeIcon")?this.getDelegate().removeListItem(this):void 0}
MultipleListItemView.prototype.setDomElement=function(){return this.domElement=$("<span />")}
MultipleListItemView.prototype.partial=function(){return""+this.getData()+" <cite class='removeIcon'>x</cite>"}
return MultipleListItemView}(KDListItemView)

var KDAutoCompleteFetchingItem,KDAutoCompleteNothingFoundItem,KDAutoCompletedItem,KDAutocompleteUnselecteableItem,NoAutocompleteInputView,_ref,_ref1,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDAutoCompletedItem=function(_super){function KDAutoCompletedItem(options){null==options&&(options={})
options.cssClass=this.utils.curry("kdautocompletedlistitem",options.cssClass)
KDAutoCompletedItem.__super__.constructor.apply(this,arguments)}__extends(KDAutoCompletedItem,_super)
KDAutoCompletedItem.prototype.click=function(event){$(event.target).is("span.close-icon")&&this.getDelegate().removeFromSubmitQueue(this)
return this.getDelegate().getView().$input().trigger("focus")}
KDAutoCompletedItem.prototype.viewAppended=function(){return this.setPartial(this.partial())}
KDAutoCompletedItem.prototype.partial=function(){return this.getDelegate().getOptions().itemClass.prototype.partial(this.getData())}
return KDAutoCompletedItem}(KDView)
KDAutocompleteUnselecteableItem=function(_super){function KDAutocompleteUnselecteableItem(){_ref=KDAutocompleteUnselecteableItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(KDAutocompleteUnselecteableItem,_super)
KDAutocompleteUnselecteableItem.prototype.click=function(){return!1}
KDAutocompleteUnselecteableItem.prototype.keyUp=function(){return!1}
KDAutocompleteUnselecteableItem.prototype.keyDown=function(){return!1}
KDAutocompleteUnselecteableItem.prototype.makeItemActive=function(){}
KDAutocompleteUnselecteableItem.prototype.destroy=function(){return KDAutocompleteUnselecteableItem.__super__.destroy.call(this,!1)}
return KDAutocompleteUnselecteableItem}(KDListItemView)
KDAutoCompleteNothingFoundItem=function(_super){function KDAutoCompleteNothingFoundItem(options){null==options&&(options={})
options.cssClass=this.utils.curry("kdautocompletelistitem no-result",options.cssClass)
KDAutoCompleteNothingFoundItem.__super__.constructor.apply(this,arguments)}__extends(KDAutoCompleteNothingFoundItem,_super)
KDAutoCompleteNothingFoundItem.prototype.partial=function(){return"Nothing found"}
return KDAutoCompleteNothingFoundItem}(KDAutocompleteUnselecteableItem)
KDAutoCompleteFetchingItem=function(_super){function KDAutoCompleteFetchingItem(options){null==options&&(options={})
options.cssClass=this.utils.curry("kdautocompletelistitem fetching",options.cssClass)
KDAutoCompleteFetchingItem.__super__.constructor.apply(this,arguments)}__extends(KDAutoCompleteFetchingItem,_super)
KDAutoCompleteFetchingItem.prototype.partial=function(){return"Fetching in process..."}
return KDAutoCompleteFetchingItem}(KDAutocompleteUnselecteableItem)
NoAutocompleteInputView=function(_super){function NoAutocompleteInputView(){_ref1=NoAutocompleteInputView.__super__.constructor.apply(this,arguments)
return _ref1}__extends(NoAutocompleteInputView,_super)
NoAutocompleteInputView.prototype.keyUp=function(event){return 13===event.keyCode?this.inputAddCurrentValue():void 0}
NoAutocompleteInputView.prototype.setDomElement=function(cssClass){var placeholder
placeholder=this.getOptions().placeholder
return this.domElement=$("<div class='"+cssClass+"'><input type='text' class='main' placeholder='"+(placeholder||"")+"' /></div>")}
NoAutocompleteInputView.prototype.addItemToSubmitQueue=function(){return!1}
return NoAutocompleteInputView}(KDMultipleInputView)

var KDTimeAgoView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDTimeAgoView=function(_super){function KDTimeAgoView(options,data){var _this=this
null==options&&(options={})
options.tagName="time"
KDTimeAgoView.__super__.constructor.call(this,options,data)
KDTimeAgoView.on("OneMinutePassed",function(){return _this.updatePartial($.timeago(_this.getData()))})}__extends(KDTimeAgoView,_super)
KDTimeAgoView.registerStaticEmitter()
KD.utils.repeat(6e4,function(){return KDTimeAgoView.emit("OneMinutePassed")})
KDTimeAgoView.prototype.setData=function(){KDTimeAgoView.__super__.setData.apply(this,arguments)
return this.parent?this.updatePartial($.timeago(this.getData())):void 0}
KDTimeAgoView.prototype.viewAppended=function(){return this.setPartial($.timeago(this.getData()))}
return KDTimeAgoView}.call(this,KDView)

var KDWebcamView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
KDWebcamView=function(_super){function KDWebcamView(options,data){var _this=this
null==options&&(options={})
options.cssClass||(options.cssClass="kdwebcamview")
null==options.screenFlash&&(options.screenFlash=!0)
null==options.hideControls&&(options.hideControls=!1)
options.snapTitle||(options.snapTitle="Snap Photo")
options.resnapTitle||(options.resnapTitle="Resnap")
options.saveTitle||(options.saveTitle="Save")
null==options.countdown&&(options.countdown=3)
KDWebcamView.__super__.constructor.call(this,options,data)
this.attachEvents()
this.video=new KDCustomHTMLView({tagName:"video",attributes:{autoplay:!0}})
this.picture=new KDCustomHTMLView({tagName:"canvas"})
this.button=options.hideControls?new KDView({cssClass:"hidden"}):new KDButtonView({title:options.snapTitle,cssClass:"snap-button hidden",callback:this.bound("countDown")})
this.retake=options.hideControls?new KDView({cssClass:"hidden"}):new KDButtonView({title:options.resnapTitle,cssClass:"snap-button retake hidden",callback:function(){return _this.resetView()}})
this.save=options.hideControls?new KDView({cssClass:"hidden"}):new KDButtonView({title:options.saveTitle,cssClass:"snap-button save hidden",callback:function(){_this.resetView()
_this.video.setClass("invisible")
_this.button.hide()
return _this.emit("save")}})}__extends(KDWebcamView,_super)
KDWebcamView.prototype.attachEvents=function(){var snapTitle,_this=this
snapTitle=this.getOptions().snapTitle
this.on("KDObjectWillBeDestroyed",function(){return _this.unsetVideoStream()})
this.on("viewAppended",function(){_this.context=_this.picture.getElement().getContext("2d")
return _this.getUserMedia()})
this.on("error",function(){return this.emit("forbidden")})
this.on("snap",function(){return _this.video.setClass("invisible")})
return this.on("countDownEnd",function(){_this.button.hide()
_this.retake.show()
_this.save.show()
_this.takePicture()
return _this.button.setTitle(snapTitle)})}
KDWebcamView.prototype.resetView=function(){this.button.show()
this.retake.hide()
this.save.hide()
return this.reset()}
KDWebcamView.prototype.reset=function(){return this.video.unsetClass("invisible")}
KDWebcamView.prototype.countDown=function(){var count,countdown,counter,timer,_this=this
countdown=this.getOptions().countdown
if(countdown>0){counter=function(){_this.button.setTitle(countdown)
return countdown--}
count=this.utils.repeat(1e3,counter)
counter()
return timer=this.utils.wait(1e3*(countdown+1),function(){_this.utils.killRepeat(count)
_this.utils.killWait(timer)
return _this.emit("countDownEnd")})}return this.emit("countDownEnd")}
KDWebcamView.prototype.autoResize=function(){var size,video
video=this.video.getElement()
size={width:video.clientWidth,height:video.clientHeight}
this.picture.setAttributes(size)
return this.setSize(size)}
KDWebcamView.prototype.unsetVideoStream=function(){var video,_ref
video=this.video.getElement()
video.pause()
KDWebcamView.setVideoStreamVendor(video,"")
return null!=(_ref=this.localMediaStream)?_ref.stop():void 0}
KDWebcamView.prototype.setVideoStream=function(stream){var video,_this=this
video=this.video.getElement()
KDWebcamView.setVideoStreamVendor(video,stream)
video.play()
return video.addEventListener("playing",function(){_this.show()
_this.button.show()
_this.autoResize()
return _this.emit("allowed")})}
KDWebcamView.setVideoStreamVendor=function(video,stream){return void 0!==video.mozSrcObject?video.mozSrcObject=stream:video.src=stream}
KDWebcamView.getUserMediaVendor=function(){return navigator.getUserMedia||navigator.webkitGetUserMedia||navigator.mozGetUserMedia}
KDWebcamView.getURLVendor=function(){return window.URL||window.webkitURL||window.mozURL}
KDWebcamView.prototype.getUserMedia=function(){var _onError,_this=this
_onError=function(error){return _this.emit("error",error)}
navigator.getUserMedia=KDWebcamView.getUserMediaVendor()
window.URL=KDWebcamView.getURLVendor()
return navigator.getUserMedia?navigator.getUserMedia({video:!0},function(stream){_this.localMediaStream=stream
return _this.setVideoStream(window.URL&&window.URL.createObjectURL(stream)||stream)},_onError):_onError({notSupported:!0})}
KDWebcamView.prototype.flash=function(){var flash
flash=new KDView({cssClass:"kdwebcamview-flash"})
flash.appendToDomBody()
return KD.utils.defer(function(){flash.setClass("flashed")
return KD.utils.wait(500,function(){return flash.destroy()})})}
KDWebcamView.prototype.takePicture=function(){var picture,screenFlash,video
video=this.video.getElement()
picture=this.picture.getElement()
screenFlash=this.getOptions().screenFlash
screenFlash&&this.flash()
this.autoResize()
this.context.drawImage(video,0,0,video.clientWidth,video.clientHeight)
return this.emit("snap",picture.toDataURL(),picture)}
KDWebcamView.prototype.pistachio=function(){return"{{> this.button}}\n{{> this.save}}\n{{> this.retake}}\n{{> this.video}}\n{{> this.picture}}"}
return KDWebcamView}(JView)

KD.registerSingleton("windowController",new KDWindowController)
console.timeEnd("Framework loaded")

//@ sourceMappingURL=/js/__kd.0.0.1.js.map