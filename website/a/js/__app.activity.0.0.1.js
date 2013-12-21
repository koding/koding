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

var ActivityAppController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
ActivityAppController=function(_super){function ActivityAppController(options){var _this=this
null==options&&(options={})
options.view=new ActivityAppView({testPath:"activity-feed"})
options.appInfo={name:"Activity"}
ActivityAppController.__super__.constructor.call(this,options)
this.currentFeedFilter="Public"
this.currentActivityFilter="Everything"
this.appStorage=new AppStorage("Activity","1.0")
this.isLoading=!1
this.mainController=KD.getSingleton("mainController")
this.lastTo=null
this.lastFrom=Date.now()
this.status=KD.getSingleton("status")
this.status.on("reconnected",function(conn){return"internetDownForLongTime"===(null!=conn?conn.reason:void 0)?_this.refresh():void 0})
this.on("activitiesCouldntBeFetched",function(){var _ref
return null!=(_ref=_this.listController)?_ref.hideLazyLoader():void 0})}var USEDFEEDS,activityTypes,clearQuotes,dash,newActivitiesArrivedTypes
__extends(ActivityAppController,_super)
KD.registerAppClass(ActivityAppController,{name:"Activity",route:"/:name?/Activity",hiddenHandle:!0})
dash=Bongo.dash
USEDFEEDS=[]
activityTypes=["Everything"]
newActivitiesArrivedTypes=["CStatusActivity","CCodeSnipActivity","CFollowerBucketActivity","CNewMemberBucketActivity","CDiscussionActivity","CTutorialActivity","CInstallerBucketActivity","CBlogPostActivity"]
ActivityAppController.clearQuotes=clearQuotes=function(activities){var activity,activityId
return activities=function(){var _ref,_results
_results=[]
for(activityId in activities)if(__hasProp.call(activities,activityId)){activity=activities[activityId]
activity.snapshot=null!=(_ref=activity.snapshot)?_ref.replace(/&quot;/g,'"'):void 0
_results.push(activity)}return _results}()}
ActivityAppController.prototype.loadView=function(){var _this=this
return this.getView().feedWrapper.ready(function(){_this.attachEvents(_this.getView().feedWrapper.controller)
return _this.emit("ready")})}
ActivityAppController.prototype.resetAll=function(){this.lastTo=null
this.lastFrom=Date.now()
this.isLoading=!1
this.reachedEndOfActivities=!1
this.listController.resetList()
return this.listController.removeAllItems()}
ActivityAppController.prototype.fetchCurrentGroup=function(callback){return callback(this.currentGroupSlug)}
ActivityAppController.prototype.bindLazyLoad=function(){this.once("LazyLoadThresholdReached",this.bound("continueLoadingTeasers"))
return this.listController.once("teasersLoaded",this.bound("teasersLoaded"))}
ActivityAppController.prototype.continueLoadingTeasers=function(){if(!this.isLoading){this.clearPopulateActivityBindings()
KD.mixpanel("Scrolled down feed")
return this.populateActivity({to:this.lastFrom})}}
ActivityAppController.prototype.attachEvents=function(controller){var activityController,appView
activityController=KD.getSingleton("activityController")
appView=this.getView()
activityController.on("ActivitiesArrived",this.bound("activitiesArrived"))
activityController.on("Refresh",this.bound("refresh"))
this.listController=controller
return this.bindLazyLoad()}
ActivityAppController.prototype.setFeedFilter=function(feedType){return this.currentFeedFilter=feedType}
ActivityAppController.prototype.getFeedFilter=function(){return this.currentFeedFilter}
ActivityAppController.prototype.setActivityFilter=function(activityType){return this.currentActivityFilter=activityType}
ActivityAppController.prototype.getActivityFilter=function(){return this.currentActivityFilter}
ActivityAppController.prototype.clearPopulateActivityBindings=function(){var eventSuffix
eventSuffix=""+this.getFeedFilter()+"_"+this.getActivityFilter()
this.off("followingFeedFetched_"+eventSuffix)
return this.off("publicFeedFetched_"+eventSuffix)}
ActivityAppController.prototype.handleQuery=function(query){var options,tag,_this=this
null==query&&(query={})
if(query.tagged){tag=KD.utils.slugify(KD.utils.stripTags(query.tagged))
this.setWarning(tag,!0)
options={filterByTag:tag}}return this.ready(function(){return _this.populateActivity(options)})}
ActivityAppController.prototype.populateActivity=function(options,callback){var currentGroup,fetch,filterByTag,groupsController,isReady,setFeedData,to,view,_this=this
null==options&&(options={})
null==callback&&(callback=noop)
if(!this.isLoading&&!this.reachedEndOfActivities){view=this.getView()
this.listController.showLazyLoader(!1)
view.unsetTopicTag()
this.isLoading=!0
groupsController=KD.getSingleton("groupsController")
isReady=groupsController.isReady
currentGroup=groupsController.getCurrentGroup()
filterByTag=options.filterByTag,to=options.to
setFeedData=function(messages){_this.isLoading=!1
_this.bindLazyLoad()
_this.extractMessageTimeStamps(messages)
_this.listController.listActivities(messages)
return callback(messages)}
fetch=function(){var eventSuffix,group,groupObj,mydate,roles
groupObj=KD.getSingleton("groupsController").getCurrentGroup()
mydate=new Date((new Date).setSeconds(0)+6e4).getTime()
options={to:options.to||mydate,group:{slug:(null!=groupObj?groupObj.slug:void 0)||"koding",id:groupObj.getId()},limit:KD.config.activityFetchCount,facets:_this.getActivityFilter(),withExempt:!1,slug:filterByTag}
options.withExempt=null!=KD.getSingleton("activityController").flags.showExempt
eventSuffix=""+_this.getFeedFilter()+"_"+_this.getActivityFilter()
roles=KD.config.roles
group=null!=groupObj?groupObj.slug:void 0
if(!to&&(filterByTag||_this._wasFilterByTag)){_this.resetAll()
_this.clearPopulateActivityBindings()
_this._wasFilterByTag=filterByTag}if(null!=filterByTag||_this._wasFilterByTag&&to){null==options.slug&&(options.slug=_this._wasFilterByTag)
_this.once("topicFeedFetched_"+eventSuffix,setFeedData)
_this.fetchTopicActivities(options)
_this.setWarning(options.slug)
return view.setTopicTag(options.slug)}if("Public"===_this.getFeedFilter()){_this.once("publicFeedFetched_"+eventSuffix,setFeedData)
_this.fetchPublicActivities(options)
return _this.setWarning()}_this.once("followingFeedFetched_"+eventSuffix,setFeedData)
_this.fetchFollowingActivities(options)
return _this.setWarning()}
return isReady?fetch():groupsController.once("GroupChanged",fetch)}}
ActivityAppController.prototype.fetchTopicActivities=function(options){var JNewStatusUpdate,eventSuffix,_this=this
null==options&&(options={})
options.to=this.lastTo
JNewStatusUpdate=KD.remote.api.JNewStatusUpdate
eventSuffix=""+this.getFeedFilter()+"_"+this.getActivityFilter()
return JNewStatusUpdate.fetchTopicFeed(options,function(err,activities){return err?_this.emit("activitiesCouldntBeFetched",err):_this.emit("topicFeedFetched_"+eventSuffix,activities)})}
ActivityAppController.prototype.fetchPublicActivities=function(options){var JNewStatusUpdate,eventSuffix,messages,prefetchedActivity,_this=this
null==options&&(options={})
options.to=this.lastTo
JNewStatusUpdate=KD.remote.api.JNewStatusUpdate
eventSuffix=""+this.getFeedFilter()+"_"+this.getActivityFilter()
if("Public"===this.getFeedFilter()&&"Everything"===this.getActivityFilter()&&KD.prefetchedFeeds){prefetchedActivity=KD.prefetchedFeeds["activity.main"]
if(prefetchedActivity&&__indexOf.call(USEDFEEDS,"activities.main")<0){log("exhausting feed:","activity.main")
USEDFEEDS.push("activities.main")
messages=this.prepareCacheForListing(prefetchedActivity)
this.emit("publicFeedFetched_"+eventSuffix,messages)
return}}return JNewStatusUpdate.fetchGroupActivity(options,function(err,messages){return err?_this.emit("activitiesCouldntBeFetched",err):_this.emit("publicFeedFetched_"+eventSuffix,messages)})}
ActivityAppController.prototype.prepareCacheForListing=function(cache){return KD.remote.revive(cache)}
ActivityAppController.prototype.fetchFollowingActivities=function(options){var JNewStatusUpdate,eventSuffix,_this=this
null==options&&(options={})
JNewStatusUpdate=KD.remote.api.JNewStatusUpdate
eventSuffix=""+this.getFeedFilter()+"_"+this.getActivityFilter()
return CActivity.fetchFollowingFeed(options,function(err,activities){return err?_this.emit("activitiesCouldntBeFetched",err):_this.emit("followingFeedFetched_"+eventSuffix,activities)})}
ActivityAppController.prototype.setWarning=function(tag,loading){var filterWarning
null==loading&&(loading=!1)
filterWarning=this.getView().filterWarning
if(tag){if(loading){filterWarning.warning.setPartial("Filtering activities by "+tag+"...")
return filterWarning.show()}return filterWarning.showWarning(tag)}return filterWarning.hide()}
ActivityAppController.prototype.setLastTimestamps=function(from,to){if(from){this.lastTo=to
return this.lastFrom=from}return this.reachedEndOfActivities=!0}
ActivityAppController.prototype.extractMessageTimeStamps=function(messages){var from,to
if(0!==messages.length){from=new Date(messages.last.meta.createdAt).getTime()
to=new Date(messages.first.meta.createdAt).getTime()
return this.setLastTimestamps(to,from)}}
ActivityAppController.prototype.extractTeasersTimeStamps=function(teasers){return teasers.first?this.setLastTimestamps(new Date(teasers.last.meta.createdAt).getTime(),new Date(teasers.first.meta.createdAt).getTime()):void 0}
ActivityAppController.prototype.sanitizeCache=function(cache,callback){var activities
activities=clearQuotes(cache.activities)
return KD.remote.reviveFromSnapshots(activities,function(err,instances){var activity,i,_base,_i,_len,_name
for(i=_i=0,_len=activities.length;_len>_i;i=++_i){activity=activities[i];(_base=cache.activities)[_name=activity._id]||(_base[_name]={})
cache.activities[activity._id].teaser=instances[i]}return callback(null,cache)})}
ActivityAppController.prototype.activitiesArrived=function(activities){var activity,_i,_len,_ref,_ref1,_results
_results=[]
for(_i=0,_len=activities.length;_len>_i;_i++){activity=activities[_i];(_ref=activity.bongo_.constructorName,__indexOf.call(newActivitiesArrivedTypes,_ref)>=0)&&_results.push(null!=(_ref1=this.listController)?_ref1.newActivityArrived(activity):void 0)}return _results}
ActivityAppController.prototype.teasersLoaded=function(){}
ActivityAppController.prototype.createContentDisplay=function(activity,callback){var controller
null==callback&&(callback=function(){})
controller=function(){switch(activity.bongo_.constructorName){case"JNewStatusUpdate":return this.createStatusUpdateContentDisplay(activity)}}.call(this)
return this.utils.defer(function(){return callback(controller)})}
ActivityAppController.prototype.showContentDisplay=function(contentDisplay){KD.singleton("display").emit("ContentDisplayWantsToBeShown",contentDisplay)
return contentDisplay}
ActivityAppController.prototype.createStatusUpdateContentDisplay=function(activity){var _this=this
return activity.fetchTags(function(err,tags){if(!err){activity.tags=tags
return _this.showContentDisplay(new ContentDisplayStatusUpdate({title:"Status Update",type:"status"},activity))}})}
ActivityAppController.prototype.streamByIds=function(ids,callback){var selector
selector={_id:{$in:ids}}
return KD.remote.api.CActivity.streamModels(selector,{},function(err,model){return err?callback(err):null!==model?callback(null,model[0]):callback(null,null)})}
ActivityAppController.prototype.fetchActivitiesProfilePage=function(options,callback){var appStorage,originId,_this=this
originId=options.originId
options.to=options.to||this.profileLastTo||Date.now()
if(KD.checkFlag("super-admin")){appStorage=new AppStorage("Activity","1.0")
return appStorage.fetchStorage(function(){options.withExempt=appStorage.getValue("showLowQualityContent")||!1
return _this.fetchActivitiesProfilePageWithExemptOption(options,callback)})}options.withExempt=!1
return this.fetchActivitiesProfilePageWithExemptOption(options,callback)}
ActivityAppController.prototype.fetchActivitiesProfilePageWithExemptOption=function(options,callback){var JNewStatusUpdate,eventSuffix,_this=this
JNewStatusUpdate=KD.remote.api.JNewStatusUpdate
eventSuffix=""+this.getFeedFilter()+"_"+this.getActivityFilter()
return JNewStatusUpdate.fetchProfileFeed(options,function(err,activities){var lastOne
if(err)return _this.emit("activitiesCouldntBeFetched",err)
if((null!=activities?activities.length:void 0)>0){lastOne=activities.last.meta.createdAt
_this.profileLastTo=new Date(lastOne).getTime()}return callback(err,activities)})}
ActivityAppController.prototype.unhideNewItems=function(){var _ref
return null!=(_ref=this.listController)?_ref.activityHeader.updateShowNewItemsLink(!0):void 0}
ActivityAppController.prototype.getNewItemsCount=function(callback){var _ref,_ref1
return"function"==typeof callback?callback((null!=(_ref=this.listController)?null!=(_ref1=_ref.activityHeader)?_ref1.getNewItemsCount():void 0:void 0)||0):void 0}
ActivityAppController.prototype.refresh=function(){if(!this.isLoading){this.resetAll()
this.clearPopulateActivityBindings()
return this.populateActivityWithTimeout()}}
ActivityAppController.prototype.populateActivityWithTimeout=function(){return this.populateActivity({},KD.utils.getTimedOutCallbackOne({name:"populateActivity",onTimeout:this.bound("recover"),timeout:2e4}))}
ActivityAppController.prototype.recover=function(){this.isLoading=!1
this.status.disconnect()
return this.refresh()}
ActivityAppController.prototype.feederBridge=function(options,callback){return KD.getSingleton("appManager").tell("Feeder","createContentFeedController",options,callback)}
ActivityAppController.prototype.resetProfileLastTo=function(){return this.profileLastTo=null}
return ActivityAppController}(AppController)

var ActivityAppView,ActivityListContainer,FilterWarning,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
ActivityAppView=function(_super){function ActivityAppView(options,data){null==options&&(options={})
options.cssClass="content-page activity"
options.domId="content-page-activity"
ActivityAppView.__super__.constructor.call(this,options,data)
this.appStorage=KD.getSingleton("appStorageController").storage("Activity","1.0")
this.appStorage.setValue("liveUpdates",!1)}var headerHeight
__extends(ActivityAppView,_super)
headerHeight=0
ActivityAppView.prototype.viewAppended=function(){var HomeKonstructor,entryPoint,windowController,_this=this
entryPoint=KD.config.entryPoint
windowController=KD.singleton("windowController")
HomeKonstructor=entryPoint&&"profile"!==entryPoint.type?GroupHomeView:KDCustomHTMLView
this.feedWrapper=new ActivityListContainer
this.header=new HomeKonstructor
this.inputWidget=new ActivityInputWidget
this.tickerBox=new ActivityTicker
this.usersBox=new ActiveUsers
this.topicsBox=new ActiveTopics
this.mainBlock=new KDCustomHTMLView({tagName:"main"})
this.sideBlock=new KDCustomHTMLView({tagName:"aside"})
this.mainController=KD.getSingleton("mainController")
this.mainController.on("AccountChanged",this.bound("decorate"))
this.mainController.on("JoinedGroup",function(){return _this.inputWidget.show()})
this.header.bindTransitionEnd()
this.feedWrapper.ready(function(){var _ref
_this.activityHeader=_this.feedWrapper.controller.activityHeader
return _ref=_this.feedWrapper,_this.filterWarning=_ref.filterWarning,_ref})
this.tickerBox.once("viewAppended",function(){var topOffset
topOffset=_this.tickerBox.$().position().top
return windowController.on("ScrollHappened",function(){return document.body.scrollTop>topOffset?_this.tickerBox.setClass("fixed"):_this.tickerBox.unsetClass("fixed")})})
this.decorate()
this.setLazyLoader(200)
$(".kdview.fl.common-inner-nav, .kdview.activity-content.feeder-tabs").remove()
this.addSubView(this.header)
this.addSubView(this.mainBlock)
this.addSubView(this.sideBlock)
this.mainBlock.addSubView(this.inputWidget)
this.mainBlock.addSubView(this.feedWrapper)
this.sideBlock.addSubView(this.topicsBox)
this.sideBlock.addSubView(this.usersBox)
return this.sideBlock.addSubView(this.tickerBox)}
ActivityAppView.prototype.decorate=function(){var entryPoint,roles,_ref
this.unsetClass("guest")
_ref=KD.config,entryPoint=_ref.entryPoint,roles=_ref.roles
__indexOf.call(roles,"member")<0&&this.setClass("guest")
this.setClass("loggedin")
"group"===(null!=entryPoint?entryPoint.type:void 0)&&__indexOf.call(roles,"member")<0?this.inputWidget.hide():this.inputWidget.show()
return this._windowDidResize()}
ActivityAppView.prototype.setTopicTag=function(slug){var _this=this
null==slug&&(slug="")
return KD.remote.api.JTag.one({slug:slug},null,function(err,tag){return _this.inputWidget.input.setDefaultTokens({tags:[tag]})})}
ActivityAppView.prototype.unsetTopicTag=function(){return this.inputWidget.input.setDefaultTokens({tags:[]})}
return ActivityAppView}(KDScrollView)
ActivityListContainer=function(_super){function ActivityListContainer(options,data){var _this=this
null==options&&(options={})
options.cssClass="activity-content feeder-tabs"
ActivityListContainer.__super__.constructor.call(this,options,data)
this.controller=new ActivityListController({delegate:this,itemClass:ActivityListItemView,showHeader:!0})
this.listWrapper=this.controller.getView()
this.filterWarning=new FilterWarning
this.controller.ready(function(){return _this.emit("ready")})}__extends(ActivityListContainer,_super)
ActivityListContainer.prototype.setSize=function(){}
ActivityListContainer.prototype.pistachio=function(){return"{{> this.filterWarning}}\n{{> this.listWrapper}}"}
return ActivityListContainer}(JView)
FilterWarning=function(_super){function FilterWarning(){FilterWarning.__super__.constructor.call(this,{cssClass:"filter-warning hidden"})
this.warning=new KDCustomHTMLView
this.goBack=new KDButtonView({cssClass:"goback-button",callback:function(){return KD.singletons.router.back()}})}__extends(FilterWarning,_super)
FilterWarning.prototype.pistachio=function(){return"{{> this.warning}}\n{{> this.goBack}}"}
FilterWarning.prototype.showWarning=function(tag){this.warning.updatePartial("You are now looking activities tagged with <strong>#"+tag+"</strong> ")
return this.show()}
return FilterWarning}(JView)

var ActivityListController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
ActivityListController=function(_super){function ActivityListController(options,data){var groupController,viewOptions,_this=this
null==options&&(options={})
viewOptions=options.viewOptions||{}
viewOptions.cssClass||(viewOptions.cssClass="activity-related")
null==viewOptions.comments&&(viewOptions.comments=!0)
viewOptions.itemClass||(viewOptions.itemClass=options.itemClass)
options.view||(options.view=new KDListView(viewOptions,data))
options.startWithLazyLoader=!0
options.lazyLoaderOptions={partial:""}
null==options.showHeader&&(options.showHeader=!1)
options.noItemFoundWidget||(options.noItemFoundWidget=new KDCustomHTMLView({cssClass:"lazy-loader hidden",partial:"There is no activity."}))
ActivityListController.__super__.constructor.call(this,options,data)
this.resetList()
this.hiddenItems=[]
this._state="public"
groupController=KD.getSingleton("groupsController")
groupController.on("MemberJoinedGroup",function(member){return _this.updateNewMemberBucket(member.member)})
groupController.on("FollowHappened",function(info){var follower,origin
follower=info.follower,origin=info.origin
return _this.updateFollowerBucket(follower,origin)})
groupController.on("PostIsCreated",function(post){var subject
subject=post.subject
subject=KD.remote.revive(subject)
_this.bindItemEvents(subject)
return _this.addItem(subject,0)})}var dash
__extends(ActivityListController,_super)
dash=Bongo.dash
ActivityListController.prototype.resetList=function(){this.newActivityArrivedList={}
return this.lastItemTimeStamp=null}
ActivityListController.prototype.loadView=function(mainView){var data,_this=this
data=this.getData()
mainView.addSubView(this.activityHeader=new ActivityListHeader({cssClass:"feeder-header clearfix"}))
this.getOptions().showHeader||this.activityHeader.hide()
this.activityHeader.on("UnhideHiddenNewItems",function(){var firstHiddenItem,top
firstHiddenItem=_this.getListView().$(".hidden-item").eq(0)
if(firstHiddenItem.length>0){top=firstHiddenItem.position().top
top||(top=0)
return _this.scrollView.scrollTo({top:top,duration:200},function(){return _this.unhideNewHiddenItems(_this.hiddenItems)})}})
this.emit("ready")
KD.getSingleton("activityController").clearNewItemsCount()
return ActivityListController.__super__.loadView.apply(this,arguments)}
ActivityListController.prototype.isMine=function(activity){var id,_ref
id=KD.whoami().getId()
return null!=id&&(id===activity.originId||id===(null!=(_ref=activity.anchor)?_ref.id:void 0))}
ActivityListController.prototype.listActivities=function(activities){var activityIds,queue,_this=this
this.hideLazyLoader()
if(activities.length>0){activityIds=[]
queue=[]
activities.forEach(function(activity){return queue.push(function(){_this.addItem(activity)
activityIds.push(activity._id)
return queue.fin()})})
return dash(queue,function(){var obj,objectTimestamp,_i,_len
_this.checkIfLikedBefore(activityIds)
_this.lastItemTimeStamp||(_this.lastItemTimeStamp=Date.now())
for(_i=0,_len=activities.length;_len>_i;_i++){obj=activities[_i]
_this.bindItemEvents(obj)
objectTimestamp=new Date(obj.meta.createdAt).getTime()
objectTimestamp<_this.lastItemTimeStamp&&(_this.lastItemTimeStamp=objectTimestamp)}return _this.emit("teasersLoaded")})}}
ActivityListController.prototype.checkIfLikedBefore=function(activityIds){var _this=this
return KD.remote.api.CActivity.checkIfLikedBefore(activityIds,function(err,likedIds){var activity,likeView,_i,_len,_ref,_ref1,_ref2,_results
_ref=_this.getListView().items
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){activity=_ref[_i]
if(_ref1=activity.data.getId().toString(),__indexOf.call(likedIds,_ref1)>=0){likeView=null!=(_ref2=activity.subViews.first.actionLinks)?_ref2.likeView:void 0
if(likeView){likeView.setClass("liked")
_results.push(likeView._currentState=!0)}else _results.push(void 0)}}return _results})}
ActivityListController.prototype.logNewActivityArrived=function(activity){var id
id="function"==typeof activity.getId?activity.getId():void 0
return id?this.newActivityArrivedList[id]?log("duplicate new activity",activity):this.newActivityArrivedList[id]=!0:void 0}
ActivityListController.prototype.newActivityArrived=function(activity){var _this=this
return activity&&"function"==typeof activity.fetchTeaser?activity.fetchTeaser(function(err,teaser){var view,_ref
if(teaser){_this.logNewActivityArrived(activity)
if("public"!==_this._state)return
if(!_this.isMine(activity)){if(activity instanceof KD.remote.api.CNewMemberBucketActivity)return _this.updateNewMemberBucket(activity)
view=_this.addHiddenItem(activity,0)
return null!=(_ref=_this.activityHeader)?_ref.newActivityArrived():void 0}}}):log("discarding activity",activity)}
ActivityListController.prototype.updateNewMemberBucket=function(memberAccount){var item,_i,_len,_ref,_results
_ref=this.itemsOrdered
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
if(item.getData()instanceof NewMemberBucketData){this.updateBucket(item,"JAccount",memberAccount.id)
break}_results.push(void 0)}return _results}
ActivityListController.prototype.updateFollowerBucket=function(follower,followee){var data,item,_i,_len,_ref,_results
_ref=this.itemsOrdered
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){item=_ref[_i]
data=item.getData()
if("string"!=typeof data.group&&data.group&&data.group[0])if(data.group[0].constructorName===followee.bongo_.constructorName){if(data.anchor&&data.anchor.id===follower.id){this.updateBucket(item,followee.bongo_.constructorName,followee._id)
break}_results.push(void 0)}else _results.push(void 0)}return _results}
ActivityListController.prototype.updateBucket=function(item,constructorName,id){var data,group,_this=this
data=item.getData()
group=data.group||data.anchors
group.unshift({bongo_:{constructorName:"ObjectRef"},constructorName:constructorName,id:id})
data.createdAtTimestamps.push((new Date).toJSON())
data.count||(data.count=0)
data.count++
return item.slideOut(function(){var newItem
_this.removeItem(item,data)
newItem=_this.addHiddenItem(data,0)
return _this.utils.wait(500,function(){return newItem.slideIn()})})}
ActivityListController.prototype.addItem=function(activity,index,animation){var dataId,_ref
dataId=("function"==typeof activity.getId?activity.getId():void 0)||activity._id
if(null!=dataId){if(this.itemsIndexed[dataId])return log("duplicate entry",null!=(_ref=activity.bongo_)?_ref.constructorName:void 0,dataId)
this.itemsIndexed[dataId]=activity
return ActivityListController.__super__.addItem.call(this,activity,index,animation)}}
ActivityListController.prototype.addHiddenItem=function(activity,index,animation){var instance
null==animation&&(animation=null)
instance=this.getListView().addHiddenItem(activity,index,animation)
this.hiddenItems.push(instance)
this.lastItemTimeStamp=activity.createdAt
return instance}
ActivityListController.prototype.unhideNewHiddenItems=function(){var repeater,_this=this
return repeater=KD.utils.repeat(177,function(){var item
item=_this.hiddenItems.shift()
if(item)return item.show()
KD.utils.killRepeat(repeater)
return"/Activity"!==KD.getSingleton("router").getCurrentPath()?KD.getSingleton("activityController").clearNewItemsCount():void 0})}
ActivityListController.prototype.instantiateListItems=function(items){var item,newItems
newItems=ActivityListController.__super__.instantiateListItems.apply(this,arguments)
this.checkIfLikedBefore(function(){var _i,_len,_results
_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
_results.push(item.getId())}return _results}())
return newItems}
ActivityListController.prototype.bindItemEvents=function(item){return item.on("TagsUpdated",function(tags){return item.tags=KD.remote.revive(tags)})}
return ActivityListController}(KDListViewController)

var ActivityActionLink,ActivityActionsView,ActivityCommentCount,ActivityCountLink,ActivityLikeCount,ActivityOpinionCount,ActivitySharePopup,_ref,_ref1,_ref2,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivitySharePopup=function(_super){function ActivitySharePopup(options,data){null==options&&(options={})
options.cssClass="share-popup"
options.shortenText=!0
options.twitter=this.getTwitterOptions(options)
options.newTab=this.getNewTabOptions(options)
ActivitySharePopup.__super__.constructor.call(this,options,data)}__extends(ActivitySharePopup,_super)
ActivitySharePopup.prototype.getTwitterOptions=function(options){var body,data,hashTags,itemText,shareText,tag,tags,title,twitter
data=options.delegate.getData()
tags=data.tags
if(tags){hashTags=function(){var _i,_len,_results
_results=[]
for(_i=0,_len=tags.length;_len>_i;_i++){tag=tags[_i];(null!=tag?tag.slug:void 0)&&_results.push("#"+tag.slug)}return _results}()
hashTags=_.unique(hashTags).join(" ")
hashTags+=" "}else hashTags=""
title=data.title,body=data.body
itemText=KD.utils.shortenText(title||body,{maxLength:100,minLength:100})
shareText=""+itemText+" "+hashTags+"- "+options.url
return twitter={enabled:!0,text:shareText}}
ActivitySharePopup.prototype.getNewTabOptions=function(options){return{enabled:!0,url:options.url}}
return ActivitySharePopup}(SharePopup)
ActivityActionsView=function(_super){function ActivityActionsView(){var activity,_this=this
ActivityActionsView.__super__.constructor.apply(this,arguments)
activity=this.getData()
this.commentLink=new ActivityActionLink({partial:"",cssClass:"comment-icon"})
this.commentCount=new ActivityCommentCount({tooltip:{title:"Show all"},click:function(event){event.preventDefault()
return _this.getDelegate().emit("CommentCountClicked",_this)}},activity)
this.shareLink=new ActivityActionLink({partial:"",cssClass:"share-icon",click:function(){var data,shareUrl
data=_this.getData()
shareUrl=null!=(null!=data?data.group:void 0)&&"koding"!==data.group?""+KD.config.mainUri+"/#!/"+data.group+"/Activity/"+data.slug:""+KD.config.mainUri+"/#!/Activity/"+data.slug
contextMenu=new JContextMenu({cssClass:"activity-share-popup",type:"activity-share",delegate:_this,x:_this.getX()+90,y:_this.getY()-7,menuMaxWidth:400,lazyLoad:!0},{customView:new ActivitySharePopup({delegate:_this,url:shareUrl})})
return new KDOverlayView({parent:KD.singletons.mainView.mainTabView.activePane,transparent:!0})}})
this.likeView=new LikeView({cssClass:"logged-in action-container",useTitle:!1},activity)
this.loader=new KDLoaderView({cssClass:"action-container",size:{width:16},loaderOptions:{color:"#6B727B"}})}var contextMenu
__extends(ActivityActionsView,_super)
contextMenu=null
ActivityActionsView.prototype.viewAppended=function(){this.setClass("activity-actions")
this.setTemplate(this.pistachio())
this.template.update()
this.attachListeners()
return this.loader.hide()}
ActivityActionsView.prototype.pistachio=function(){return"{{> this.likeView}}\n<span class='logged-in action-container'>\n  {{> this.commentLink}}{{> this.commentCount}}\n</span>\n<span class='optional action-container'>\n  {{> this.shareLink}}\n</span>\n{{> this.loader}}"}
ActivityActionsView.prototype.attachListeners=function(){var activity,commentList,_this=this
activity=this.getData()
commentList=this.getDelegate()
commentList.on("BackgroundActivityStarted",this.loader.bound("show"))
commentList.on("BackgroundActivityFinished",this.loader.bound("hide"))
return this.commentLink.on("click",function(event){return commentList.emit("CommentLinkReceivedClick",event,_this)})}
return ActivityActionsView}(KDView)
ActivityActionLink=function(_super){function ActivityActionLink(options,data){options=$.extend({tagName:"a",cssClass:"action-link like-icon",attributes:{href:"#"}},options)
ActivityActionLink.__super__.constructor.call(this,options,data)}__extends(ActivityActionLink,_super)
return ActivityActionLink}(KDCustomHTMLView)
ActivityCountLink=function(_super){function ActivityCountLink(options,data){options=$.extend({tagName:"a",cssClass:"count",attributes:{href:"#"}},options)
ActivityCountLink.__super__.constructor.call(this,options,data)}__extends(ActivityCountLink,_super)
ActivityCountLink.prototype.render=function(){ActivityCountLink.__super__.render.apply(this,arguments)
return this.setCount(this.getData())}
ActivityCountLink.prototype.viewAppended=function(){var activity
this.setTemplate(this.pistachio())
this.template.update()
activity=this.getData()
return this.setCount(activity)}
ActivityCountLink.prototype.pistachio=function(){return""}
return ActivityCountLink}(KDCustomHTMLView)
ActivityLikeCount=function(_super){function ActivityLikeCount(){_ref=ActivityLikeCount.__super__.constructor.apply(this,arguments)
return _ref}__extends(ActivityLikeCount,_super)
ActivityLikeCount.oldCount=0
ActivityLikeCount.prototype.setCount=function(activity){activity.meta.likes!==this.oldCount&&this.emit("countChanged",activity.meta.likes)
this.oldCount=activity.meta.likes
return 0===activity.meta.likes?this.hide():this.show()}
ActivityLikeCount.prototype.pistachio=function(){return"{{#(meta.likes)}}"}
return ActivityLikeCount}(ActivityCountLink)
ActivityCommentCount=function(_super){function ActivityCommentCount(){_ref1=ActivityCommentCount.__super__.constructor.apply(this,arguments)
return _ref1}__extends(ActivityCommentCount,_super)
ActivityCommentCount.prototype.setCount=function(activity){0===activity.repliesCount?this.hide():this.show()
return this.emit("countChanged",activity.repliesCount)}
ActivityCommentCount.prototype.pistachio=function(){return"{{#(repliesCount)}}"}
return ActivityCommentCount}(ActivityCountLink)
ActivityOpinionCount=function(_super){function ActivityOpinionCount(){_ref2=ActivityOpinionCount.__super__.constructor.apply(this,arguments)
return _ref2}__extends(ActivityOpinionCount,_super)
ActivityOpinionCount.prototype.setCount=function(activity){0===activity.opinionCount?this.hide():this.show()
return this.emit("countChanged",activity.opinionCount)}
ActivityOpinionCount.prototype.pistachio=function(){return"{{#(opinionCount)}}"}
return ActivityOpinionCount}(ActivityCountLink)

var ActivityInnerNavigation,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityInnerNavigation=function(_super){function ActivityInnerNavigation(){_ref=ActivityInnerNavigation.__super__.constructor.apply(this,arguments)
return _ref}__extends(ActivityInnerNavigation,_super)
ActivityInnerNavigation.prototype.viewAppended=function(){var filterController,helpBox,showMeFilterController
filterController=this.setListController({type:"filterme",itemClass:CommonInnerNavigationListItem},this.filterMenuData)
this.addSubView(filterController.getView())
filterController.selectItem(filterController.getItemsOrdered().first)
showMeFilterController=this.setListController({type:"showme",itemClass:CommonInnerNavigationListItem},this.followerMenuData)
KD.getSingleton("mainController").on("AccountChanged",function(){filterController.reset()
return filterController.selectItem(filterController.getItemsOrdered()[0])})
this.addSubView(showMeFilterController.getView())
showMeFilterController.selectItem(showMeFilterController.getItemsOrdered()[0])
return this.addSubView(helpBox=new HelpBox({subtitle:"About Your Activity Feed",bookIndex:10,tooltip:{title:'<p class="bigtwipsy">The Activity feed displays posts from the people and topics you follow on Koding. It\'s also the central place for sharing updates, code, links, discussions and questions with the community. </p>',placement:"above",offset:0,delayIn:300,html:!0,animate:!0}}))}
ActivityInnerNavigation.prototype.filterMenuData={title:"FILTER",items:[{title:"Public",type:"Public"},{title:"Following",type:"Followed",role:"member"}]}
ActivityInnerNavigation.prototype.followerMenuData={title:"SHOW ME",items:[{title:"Everything",type:"Everything"},{title:"Status Updates",type:"JNewStatusUpdate"}]}
return ActivityInnerNavigation}(CommonInnerNavigation)

var ActivityListHeader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityListHeader=function(_super){function ActivityListHeader(){var mainController,_this=this
ActivityListHeader.__super__.constructor.apply(this,arguments)
mainController=KD.getSingleton("mainController")
this.appStorage=new AppStorage("Activity","1.0")
this._newItemsCount=0
this.showNewItemsInTitle=!1
this.showNewItemsLink=new KDCustomHTMLView({cssClass:"new-updates",partial:"<span>0</span> new items. <a href='#' title='Show new activities'>Update</a>",click:function(){return _this.updateShowNewItemsLink(!0)}})
this.headerTitle=new KDCustomHTMLView({partial:"Latest Activity",tagName:"span"})
this.showNewItemsLink.hide()
this.liveUpdateButton=new KDOnOffSwitch({defaultValue:!1,inputLabel:"Live Updates: ",size:"tiny",callback:function(state){_this._togglePollForUpdates(state)
_this.appStorage.setValue("liveUpdates",state,function(){})
_this.updateShowNewItemsLink()
KD.getSingleton("activityController").flags={liveUpdates:state}
return KD.getSingleton("activityController").emit("LiveStatusUpdateStateChanged",state)}})
mainController.on("AccountChanged",function(){return _this.decorateLiveUpdateButton()})
this.decorateLiveUpdateButton()
if(KD.checkFlag("super-admin")){this.lowQualitySwitch=new KDOnOffSwitch({defaultValue:!1,inputLabel:"Show trolls: ",size:"tiny",callback:function(state){_this.appStorage.setValue("showLowQualityContent",state,function(){})
KD.getSingleton("activityController").flags.showExempt=state
return KD.getSingleton("activityController").emit("Refresh")}})
this.refreshLink=new KDCustomHTMLView({tagName:"a",cssClass:"fr",partial:"Refresh",click:function(){return KD.getSingleton("activityController").emit("Refresh")}})}else{this.lowQualitySwitch=new KDCustomHTMLView
this.refreshLink=new KDCustomHTMLView({tagName:"span"})}this.appStorage.fetchStorage(function(){var flags,lowQualityContent,state,_base
state=_this.appStorage.getValue("liveUpdates")||!1
lowQualityContent=_this.appStorage.getValue("showLowQualityContent")
flags=KD.getSingleton("activityController").flags
flags.liveUpdates=state
flags.showExempt=lowQualityContent||!1
_this.liveUpdateButton.setValue(state)
return"function"==typeof(_base=_this.lowQualitySwitch).setValue?_base.setValue(lowQualityContent||!1):void 0})}var __count
__extends(ActivityListHeader,_super)
__count=0
ActivityListHeader.prototype._checkForUpdates=function(lastTs,lastCount,alreadyWarned){var itFailed
itFailed=function(){if(!alreadyWarned){console.warn("seems like live updates stopped coming")
KD.logToExternal("realtime failure detected")
return alreadyWarned=!0}}
return function(){return KD.remote.api.CActivity.fetchLastActivityTimestamp(function(err,ts){null!=ts&&lastTs!==ts&&lastCount===__count&&itFailed()
lastTs=ts
return lastCount=__count})}}(null,null,!1)
ActivityListHeader.prototype._togglePollForUpdates=function(i){return function(state){return state?i=setInterval(this.bound("_checkForUpdates"),6e4):clearInterval(i)}}(null)
ActivityListHeader.prototype.pistachio=function(){return"<div class='header-wrapper'>{{> this.headerTitle}} {{> this.lowQualitySwitch}} {{> this.liveUpdateButton}} {{> this.showNewItemsLink}}{{> this.refreshLink}}</div>"}
ActivityListHeader.prototype.newActivityArrived=function(){__count++
this._newItemsCount++
return this.updateShowNewItemsLink()}
ActivityListHeader.prototype.decorateLiveUpdateButton=function(){return this.liveUpdateButton.show()}
ActivityListHeader.prototype.updateShowNewItemsLink=function(showNewItems){null==showNewItems&&(showNewItems=!1)
if(this._newItemsCount>0){if(this.liveUpdateButton.getValue()===!0||showNewItems===!0){this.emit("UnhideHiddenNewItems")
this._newItemsCount=0
return this.showNewItemsLink.hide()}this.showNewItemsLink.$("span").text(this._newItemsCount)
return this.showNewItemsLink.show()}return this.showNewItemsLink.hide()}
ActivityListHeader.prototype.getNewItemsCount=function(){return this._newItemsCount}
return ActivityListHeader}(JView)

var ActivitySplitView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivitySplitView=function(_super){function ActivitySplitView(options,data){null==options&&(options={})
options.sizes||(options.sizes=[139,null])
options.minimums||(options.minimums=[10,null])
null==options.resizable&&(options.resizable=!1)
ActivitySplitView.__super__.constructor.call(this,options,data)}__extends(ActivitySplitView,_super)
ActivitySplitView.prototype.viewAppended=ContentPageSplitBelowHeader.prototype.viewAppended
ActivitySplitView.prototype.toggleFirstPanel=ContentPageSplitBelowHeader.prototype.toggleFirstPanel
ActivitySplitView.prototype.setRightColumnClass=ContentPageSplitBelowHeader.prototype.setRightColumnClass
ActivitySplitView.prototype._windowDidResize=function(){var header,parentHeight,updateWidgetHeight,welcomeHeaderHeight,widget,_ref
ActivitySplitView.__super__._windowDidResize.apply(this,arguments)
_ref=this.getDelegate(),header=_ref.header,widget=_ref.widget
parentHeight=this.getDelegate().getHeight()
welcomeHeaderHeight=header.$().is(":visible")?header.getHeight():0
updateWidgetHeight=widget.$().is(":visible")?widget.getHeight():0
null!=widget&&widget.$().css({top:welcomeHeaderHeight})
return this.$().css({marginTop:updateWidgetHeight,height:parentHeight-welcomeHeaderHeight-updateWidgetHeight})}
return ActivitySplitView}(SplitView)

var ActivityItemChild,ActivityItemMenuItem,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityItemChild=function(_super){function ActivityItemChild(options,data){var commentSettings,currentGroup,deleteActivity,getContentGroupLinkPartial,list,origin,_ref,_this=this
currentGroup=KD.getSingleton("groupsController").getCurrentGroup()
getContentGroupLinkPartial=function(groupSlug,groupName){return(null!=currentGroup?currentGroup.slug:void 0)===groupSlug?"":'In <a href="'+groupSlug+'" target="'+groupSlug+'">'+groupName+"</a>"}
this.contentGroupLink=new KDCustomHTMLView({tagName:"span",partial:getContentGroupLinkPartial(data.group,data.group)});(null!=currentGroup?currentGroup.slug:void 0)===data.group?this.contentGroupLink.updatePartial(getContentGroupLinkPartial(currentGroup.slug,currentGroup.title)):KD.remote.api.JGroup.one({slug:data.group},function(err,group){return!err&&group?_this.contentGroupLink.updatePartial(getContentGroupLinkPartial(group.slug,group.title)):void 0})
origin={constructorName:data.originType,id:data.originId}
this.avatar=new AvatarView({size:{width:70,height:70},cssClass:"author-avatar",origin:origin,showStatus:!0})
this.author=new ProfileLinkView({origin:origin})
if("JDiscussion"===(_ref=data.bongo_.constructorName)||"JTutorial"===_ref){this.commentBox=new OpinionView({},data)
list=this.commentBox.opinionList}else{commentSettings=options.commentSettings||null
this.commentBox=new CommentView(commentSettings,data)
list=this.commentBox.commentList}this.actionLinks=new ActivityActionsView({cssClass:"comment-header",delegate:list},data)
this.settingsButton=new ActivitySettingsView({itemView:this},data)
ActivityItemChild.__super__.constructor.call(this,options,data)
data=this.getData()
deleteActivity=function(activityItem){activityItem.destroy()
return _this.emit("ActivityIsDeleted")}
this.settingsButton.on("ActivityIsDeleted",function(){var activityItem
activityItem=_this.getDelegate()
return deleteActivity(activityItem)})
this.settingsButton.on("ActivityEditIsClicked",function(){var reset
if(!_this.editWidget){_this.editWidget=new ActivityEditWidget
reset=function(){_this.editWidget&&(_this.editWidget=null)
return _this.editWidgetWrapper.setClass("hidden")}
_this.editWidget.on("Submit",reset)
_this.editWidget.on("ActivityInputCancelled",reset)
_this.editWidget.edit(_this.getData())
_this.editWidgetWrapper.addSubView(_this.editWidget,null,!0)
return _this.editWidgetWrapper.unsetClass("hidden")}})
data.on("PostIsDeleted",function(){var activityItem
activityItem=_this.getDelegate()
return activityItem.isInDom()?KD.whoami().getId()===data.getAt("originId")?deleteActivity(activityItem):activityItem.destroy():void 0})
data.watch("repliesCount",function(count){return count>=0?_this.commentBox.decorateCommentedState():void 0})
KD.remote.cacheable(data.originType,data.originId,function(err,account){return account&&KD.checkFlag("exempt",account)?_this.setClass("exempt"):void 0})}__extends(ActivityItemChild,_super)
ActivityItemChild.prototype.click=KD.utils.showMoreClickHandler
ActivityItemChild.prototype.viewAppended=function(){ActivityItemChild.__super__.viewAppended.apply(this,arguments)
return this.getData().fake?this.actionLinks.setClass("hidden"):void 0}
return ActivityItemChild}(KDView)
ActivityItemMenuItem=function(_super){function ActivityItemMenuItem(){_ref=ActivityItemMenuItem.__super__.constructor.apply(this,arguments)
return _ref}__extends(ActivityItemMenuItem,_super)
ActivityItemMenuItem.prototype.pistachio=function(){var slugifiedTitle,title
title=this.getData().title
slugifiedTitle=KD.utils.slugify(title)
return'<i class="'+slugifiedTitle+' icon"></i>'+title}
return ActivityItemMenuItem}(JView)

var DiscussionActivityActionsView,OpinionActivityActionsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DiscussionActivityActionsView=function(_super){function DiscussionActivityActionsView(){var activity,view,_i,_len,_ref,_this=this
DiscussionActivityActionsView.__super__.constructor.apply(this,arguments)
activity=this.getData()
this.opinionCountLink=new ActivityActionLink({partial:"Answer",click:function(event){event.preventDefault()
return _this.emit("DiscussionActivityLinkClicked")}})
this.commentLink=new ActivityActionLink({partial:"Comment",click:function(event){event.preventDefault()
return _this.emit("DiscussionActivityCommentLinkClicked")}})
0===activity.opinionCount&&this.opinionCountLink.hide()
this.opinionCount=new ActivityOpinionCount({tooltip:{title:"Take me there!"},click:function(event){event.preventDefault()
return _this.emit("DiscussionActivityLinkClicked")}},activity)
this.commentCount=new ActivityCommentCount({tooltip:{title:"Take me there!"},click:function(event){event.preventDefault()
return _this.emit("DiscussionActivityCommentLinkClicked")}},activity)
_ref=[this.opinionCount,this.commentCount]
for(_i=0,_len=_ref.length;_len>_i;_i++){view=_ref[_i]
view.on("countChanged",function(count){return count>0?this.show():this.hide()})}this.on("DiscussionActivityLinkClicked",function(){var entryPoint
if(_this.parent instanceof ContentDisplayDiscussion)return _this.getDelegate().emit("OpinionLinkReceivedClick")
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+_this.getData().slug,{state:_this.getData(),entryPoint:entryPoint})})
this.on("DiscussionActivityCommentLinkClicked",function(){var entryPoint
if(_this.parent instanceof ContentDisplayDiscussion)return _this.getDelegate().emit("CommentLinkReceivedClick")
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+_this.getData().slug,{state:_this.getData(),entryPoint:entryPoint})})}__extends(DiscussionActivityActionsView,_super)
DiscussionActivityActionsView.prototype.viewAppended=function(){this.setClass("activity-actions")
this.setTemplate(this.pistachio())
this.template.update()
this.attachListeners()
return this.loader.hide()}
DiscussionActivityActionsView.prototype.attachListeners=function(){var activity,opinionList,_this=this
activity=this.getData()
opinionList=this.getDelegate()
opinionList.on("BackgroundActivityStarted",function(){return _this.loader.show()})
return opinionList.on("BackgroundActivityFinished",function(){return _this.loader.hide()})}
DiscussionActivityActionsView.prototype.pistachio=function(){var _ref,_ref1
return"{{> this.loader}}\n{{> this.opinionCountLink}} {{> this.opinionCount}} "+((null!=(_ref=this.getData())?_ref.opinionCount:void 0)>0?" ·":"")+"\n{{> this.commentLink}} {{> this.commentCount}} "+((null!=(_ref1=this.getData())?_ref1.repliesCount:void 0)>0?" ·":" ·")+"\n<span class='optional'>\n{{> this.shareLink}} ·\n</span>\n{{> this.likeView}}"}
return DiscussionActivityActionsView}(ActivityActionsView)
OpinionActivityActionsView=function(_super){function OpinionActivityActionsView(){var activity,_ref,_this=this
OpinionActivityActionsView.__super__.constructor.apply(this,arguments)
activity=this.getData()
this.commentLink=new ActivityActionLink({partial:"Comment"})
null!=(_ref=this.commentCount)&&_ref.destroy()
this.commentCount=new ActivityCommentCount({tooltip:{title:"Take me there!"},click:function(event){event.preventDefault()
return _this.emit("DiscussionActivityLinkClicked")}},activity)
this.on("DiscussionActivityLinkClicked",function(){var entryPoint
if(_this.parent instanceof ContentDisplayDiscussion)return _this.getDelegate().emit("OpinionLinkReceivedClick")
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+_this.getData().slug,{state:_this.getData(),entryPoint:entryPoint})})}__extends(OpinionActivityActionsView,_super)
OpinionActivityActionsView.prototype.viewAppended=function(){this.setClass("activity-actions")
this.setTemplate(this.pistachio())
this.template.update()
this.attachListeners()
return this.loader.hide()}
OpinionActivityActionsView.prototype.attachListeners=function(){var activity
return activity=this.getData()}
OpinionActivityActionsView.prototype.pistachio=function(){return"{{> this.loader}}\n{{> this.commentLink}}{{> this.commentCount}}\n<span class='optional'>\n{{> this.shareLink}} ·\n</span>\n{{> this.likeView}}"}
return OpinionActivityActionsView}(ActivityActionsView)

var TutorialActivityActionsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TutorialActivityActionsView=function(_super){function TutorialActivityActionsView(){var activity,_this=this
TutorialActivityActionsView.__super__.constructor.apply(this,arguments)
activity=this.getData()
this.opinionCountLink=new ActivityActionLink({partial:"Opinions",click:function(event){event.preventDefault()
return _this.emit("TutorialActivityLinkClicked")}})
0===activity.opinionCount&&this.opinionCountLink.hide()
this.opinionCount=new ActivityOpinionCount({click:function(event){return event.preventDefault()}},activity)
this.opinionCount.on("countChanged",function(count){return count>0?_this.opinionCountLink.show():_this.opinionCountLink.hide()})
this.on("TutorialActivityLinkClicked",function(){var entryPoint
if(_this.parent instanceof ContentDisplayTutorial)return _this.getDelegate().emit("OpinionLinkReceivedClick")
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+_this.getData().slug,{state:_this.getData(),entryPoint:entryPoint})})}__extends(TutorialActivityActionsView,_super)
TutorialActivityActionsView.prototype.viewAppended=function(){this.setClass("activity-actions")
this.setTemplate(this.pistachio())
this.template.update()
this.attachListeners()
return this.loader.hide()}
TutorialActivityActionsView.prototype.attachListeners=function(){var activity,opinionList,_this=this
activity=this.getData()
opinionList=this.getDelegate()
opinionList.on("BackgroundActivityStarted",function(){return _this.loader.show()})
return opinionList.on("BackgroundActivityFinished",function(){return _this.loader.hide()})}
TutorialActivityActionsView.prototype.pistachio=function(){var _ref
return"{{> this.loader}}\n{{> this.opinionCountLink}} {{> this.opinionCount}} "+((null!=(_ref=this.getData())?_ref.opinionCount:void 0)>0?" ·":"")+"\n<span class='optional'>\n{{> this.shareLink}} ·\n</span>\n{{> this.likeView}}"}
return TutorialActivityActionsView}(ActivityActionsView)

var NewMemberBucketData,NewMemberBucketItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NewMemberBucketData=function(_super){function NewMemberBucketData(data){var key,val
for(key in data)if(__hasProp.call(data,key)){val=data[key]
this[key]=val}this.bongo_={}
this.bongo_.constructorName="NewMemberBucketData"
NewMemberBucketData.__super__.constructor.apply(this,arguments)}__extends(NewMemberBucketData,_super)
return NewMemberBucketData}(KDObject)
NewMemberBucketItemView=function(_super){function NewMemberBucketItemView(options,data){options=$.extend(options,{cssClass:"new-member"})
NewMemberBucketItemView.__super__.constructor.call(this,options,data)
this.anchor=new ProfileLinkView({origin:data.anchor})}__extends(NewMemberBucketItemView,_super)
NewMemberBucketItemView.prototype.render=function(){}
NewMemberBucketItemView.prototype.addCommentBox=function(){}
NewMemberBucketItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
NewMemberBucketItemView.prototype.pistachio=function(){return"<span class='icon'></span>\n{{> this.anchor}}\n<span class='action'>became a member.</span>"}
return NewMemberBucketItemView}(KDView)

var ActiveTopicItemView,ActiveUserItemView,ActivityTickerAppUserItem,ActivityTickerBaseItem,ActivityTickerCommentItem,ActivityTickerFollowItem,ActivityTickerItem,ActivityTickerLikeItem,ActivityTickerMemberItem,ActivityTickerStatusUpdateItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityTickerBaseItem=function(_super){function ActivityTickerBaseItem(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("action",options.cssClass)
ActivityTickerBaseItem.__super__.constructor.call(this,options,data)}__extends(ActivityTickerBaseItem,_super)
ActivityTickerBaseItem.prototype.pistachio=function(){return""}
ActivityTickerBaseItem.prototype.itemLinkViewClassMap={JAccount:ProfileLinkView,JNewApp:AppLinkView,JTag:TagLinkView,JGroup:GroupLinkView,JNewStatusUpdate:ActivityLinkView,JComment:ActivityLinkView}
return ActivityTickerBaseItem}(JView)
ActivityTickerFollowItem=function(_super){function ActivityTickerFollowItem(options,data){var source,target
null==options&&(options={})
ActivityTickerFollowItem.__super__.constructor.call(this,options,data)
source=data.source,target=data.target
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview"},target)
this.actor=new ProfileLinkView(null,target)
this.object=new this.itemLinkViewClassMap[source.bongo_.constructorName](null,source)}__extends(ActivityTickerFollowItem,_super)
ActivityTickerFollowItem.prototype.pistachio=function(){var target
target=this.getData().target
return target.getId()===KD.whoami().getId()?"{{> this.avatar}} <div class='text-overflow'>You followed {{> this.object}}</div>":"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} followed {{> this.object}}</div>"}
return ActivityTickerFollowItem}(ActivityTickerBaseItem)
ActivityTickerLikeItem=function(_super){function ActivityTickerLikeItem(options,data){var source,subject,target
null==options&&(options={})
ActivityTickerLikeItem.__super__.constructor.call(this,options,data)
source=data.source,target=data.target,subject=data.subject
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview"},source)
this.actor=new ProfileLinkView(null,source)
this.origin=new ProfileLinkView(null,target)
this.subj=new this.itemLinkViewClassMap[subject.bongo_.constructorName](null,subject)}__extends(ActivityTickerLikeItem,_super)
ActivityTickerLikeItem.prototype.pistachio=function(){var activity,source,subject,target,_ref
_ref=this.getData(),source=_ref.source,target=_ref.target,subject=_ref.subject
activity="liked"
return source.getId()===KD.whoami().getId()?source.getId()===target.getId()?"{{> this.avatar}} <div class='text-overflow'>You "+activity+" your {{> this.subj}}</div>":"{{> this.avatar}} <div class='text-overflow'>You "+activity+" {{> this.origin}}'s {{> this.subj}}</div>":target.getId()===KD.whoami().getId()?"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} "+activity+" your {{> this.subj}}</div>":source.getId()===target.getId()?"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} "+activity+" their {{> this.subj}}</div>":"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} "+activity+" {{> this.origin}}'s {{> this.subj}}</div>"}
return ActivityTickerLikeItem}(ActivityTickerBaseItem)
ActivityTickerMemberItem=function(_super){function ActivityTickerMemberItem(options,data){var target
null==options&&(options={})
ActivityTickerMemberItem.__super__.constructor.call(this,options,data)
target=data.target
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview"},target)
this.actor=new ProfileLinkView(null,target)}__extends(ActivityTickerMemberItem,_super)
ActivityTickerMemberItem.prototype.pistachio=function(){var target
target=this.getData().target
return target.getId()===KD.whoami().getId()?"{{> this.avatar}} <div class='text-overflow'>You became a member</div>":"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} became a member</div>"}
return ActivityTickerMemberItem}(ActivityTickerBaseItem)
ActivityTickerAppUserItem=function(_super){function ActivityTickerAppUserItem(options,data){var source,target
null==options&&(options={})
ActivityTickerAppUserItem.__super__.constructor.call(this,options,data)
source=data.source,target=data.target
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview"},target)
this.actor=new ProfileLinkView(null,target)
this.object=new AppLinkView(null,source)}__extends(ActivityTickerAppUserItem,_super)
ActivityTickerAppUserItem.prototype.pistachio=function(){var target
target=this.getData().target
return target.getId()===KD.whoami().getId()?"{{> this.avatar}} <div class='text-overflow'>You installed {{> this.object}}</div>":"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} installed {{> this.object}}</div>"}
return ActivityTickerAppUserItem}(ActivityTickerBaseItem)
ActivityTickerCommentItem=function(_super){function ActivityTickerCommentItem(options,data){var object,source,subject,target
null==options&&(options={})
ActivityTickerCommentItem.__super__.constructor.call(this,options,data)
source=data.source,target=data.target,object=data.object,subject=data.subject
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview"},source)
this.actor=new ProfileLinkView(null,source)
this.origin=new ProfileLinkView(null,target)
this.subj=new ActivityLinkView(null,object)}__extends(ActivityTickerCommentItem,_super)
ActivityTickerCommentItem.prototype.pistachio=function(){var activity,source,subject,target,_ref
_ref=this.getData(),source=_ref.source,target=_ref.target,subject=_ref.subject
activity="commented on"
return source.getId()===KD.whoami().getId()?source.getId()===target.getId()?"{{> this.avatar}} <div class='text-overflow'>You "+activity+" your {{> this.subj}}</div>":"{{> this.avatar}} <div class='text-overflow'>You "+activity+" {{> this.subj}}</div>":target.getId()===KD.whoami().getId()?"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} "+activity+" your {{> this.subj}}</div>":source.getId()===target.getId()?"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} "+activity+" their {{> this.subj}}</div>":"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} "+activity+" {{> this.origin}}'s {{> this.subj}}</div>"}
return ActivityTickerCommentItem}(ActivityTickerBaseItem)
ActivityTickerStatusUpdateItem=function(_super){function ActivityTickerStatusUpdateItem(options,data){var source,target
null==options&&(options={})
ActivityTickerStatusUpdateItem.__super__.constructor.call(this,options,data)
source=data.source,target=data.target
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview"},target)
this.actor=new ProfileLinkView(null,target)
this.subj=new ActivityLinkView(null,source)}__extends(ActivityTickerStatusUpdateItem,_super)
ActivityTickerStatusUpdateItem.prototype.pistachio=function(){var source,target,_ref
_ref=this.getData(),source=_ref.source,target=_ref.target
return target.getId()===KD.whoami().getId()?"{{> this.avatar}} <div class='text-overflow'>You posted {{> this.subj}}</div>":"{{> this.avatar}} <div class='text-overflow'>{{> this.actor}} posted {{> this.subj}}</div>"}
return ActivityTickerStatusUpdateItem}(ActivityTickerBaseItem)
ActivityTickerItem=function(_super){function ActivityTickerItem(options,data){null==options&&(options={})
options.type="activity-ticker-item"
ActivityTickerItem.__super__.constructor.call(this,options,data)}var itemClassMap
__extends(ActivityTickerItem,_super)
itemClassMap={JGroup_member_JAccount:ActivityTickerMemberItem,JAccount_like_JAccount:ActivityTickerLikeItem,JTag_follower_JAccount:ActivityTickerFollowItem,JAccount_follower_JAccount:ActivityTickerFollowItem,JNewApp_user_JAccount:ActivityTickerAppUserItem,JAccount_reply_JAccount:ActivityTickerCommentItem,JNewStatusUpdate_author_JAccount:ActivityTickerStatusUpdateItem}
ActivityTickerItem.prototype.viewAppended=function(){var data,itemClass
data=this.getData()
itemClass=this.getClassName(data)
return itemClass?this.addSubView(new itemClass(null,data)):this.destroy()}
ActivityTickerItem.prototype.getClassName=function(data){var as,classKey,source,target,_ref,_ref1
as=data.as,source=data.source,target=data.target
classKey=""+(null!=source?null!=(_ref=source.bongo_)?_ref.constructorName:void 0:void 0)+"_"+as+"_"+(null!=target?null!=(_ref1=target.bongo_)?_ref1.constructorName:void 0:void 0)
return itemClassMap[classKey]}
return ActivityTickerItem}(KDListItemView)
ActiveUserItemView=function(_super){function ActiveUserItemView(options,data){null==options&&(options={})
options.type="activity-ticker-item"
ActiveUserItemView.__super__.constructor.call(this,options,data)
data=this.getData()
this.avatar=new AvatarView({size:{width:30,height:30},cssClass:"avatarview",showStatus:!0},data)
this.actor=new ProfileLinkView({},data)
this.followersAndFollowing=new JView({cssClass:"user-numbers",pistachio:"{{#(counts.followers)}} followers {{#(counts.following)}} following"},data)
KD.isMine(data)||(this.followButton=new FollowButton({title:"follow",icon:!0,stateOptions:{unfollow:{title:"unfollow",cssClass:"following-account"}},dataType:"JAccount"},data))}__extends(ActiveUserItemView,_super)
ActiveUserItemView.prototype.viewAppended=function(){this.addSubView(this.avatar)
this.followButton&&this.addSubView(this.followButton)
this.addSubView(this.actor)
return this.addSubView(this.followersAndFollowing)}
return ActiveUserItemView}(KDListItemView)
ActiveTopicItemView=function(_super){function ActiveTopicItemView(options,data){null==options&&(options={})
options.type="activity-ticker-item"
ActiveTopicItemView.__super__.constructor.call(this,options,data)
this.tag=new TagLinkView({},data)
this.followButton=new FollowButton({title:"follow",icon:!0,stateOptions:{unfollow:{title:"unfollow",cssClass:"following-topic"}},dataType:"JTag"},data)}__extends(ActiveTopicItemView,_super)
ActiveTopicItemView.prototype.viewAppended=function(){var tagInfo,_this=this
this.addSubView(this.tag)
this.addSubView(this.followButton)
this.addSubView(tagInfo=new KDCustomHTMLView({cssClass:"tag-info clearfix"}))
return this.getData().fetchRandomFollowers({},function(){var randomFollowers,user,_i,_len
randomFollowers=arguments[1]
for(_i=0,_len=randomFollowers.length;_len>_i;_i++){user=randomFollowers[_i]
tagInfo.addSubView(new AvatarView({size:{width:19,height:19}},user))}return tagInfo.addSubView(new KDCustomHTMLView({tagName:"span",cssClass:"total-following",partial:"+"+_this.getData().counts.followers+" is following"}))})}
return ActiveTopicItemView}(KDListItemView)

var EmbedBox,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBox=function(_super){function EmbedBox(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("link-embed-box",options.cssClass)
EmbedBox.__super__.constructor.call(this,options,data)}__extends(EmbedBox,_super)
EmbedBox.prototype.viewAppended=function(){var containerClass,data,embedOptions,embedType,_ref
if(data=this.getData()){embedType=this.utils.getEmbedType(null!=data?null!=(_ref=data.link_embed)?_ref.type:void 0:void 0)||"link"
containerClass=function(){switch(embedType){case"image":return EmbedBoxImageView
case"object":return EmbedBoxObjectView
default:return EmbedBoxLinkDisplayView}}()
embedOptions={cssClass:"link-embed clearfix",delegate:this}
return this.addSubView(new containerClass(embedOptions,data))}}
return EmbedBox}(KDView)

var EmbedBoxWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxWidget=function(_super){function EmbedBoxWidget(options,data){var _ref1,_ref2,_ref3,_ref4,_this=this
null==options&&(options={})
null==data&&(data={})
options.cssClass=KD.utils.curry("link-embed-box",options.cssClass)
EmbedBoxWidget.__super__.constructor.call(this,options,data)
this.oembed=data.link_embed||{}
this.url=null!=(_ref1=data.link_url)?_ref1:""
this.urls=[]
this.locks={}
this.embedCache={}
this.imageIndex=0
this.hasValidContent=!1
this.watchInput()
this.settingsButton=new KDButtonView({cssClass:"hide-embed",icon:!0,iconOnly:!0,iconClass:"hide",title:"hide",callback:this.bound("resetEmbedAndHide")})
this.embedType=(null!=(_ref2=data.link_embed)?null!=(_ref3=_ref2.object)?_ref3.type:void 0:void 0)||(null!=(_ref4=data.link_embed)?_ref4.type:void 0)||"link"
this.embedLinks=new EmbedBoxLinksView({delegate:this})
this.embedLinks.on("LinkAdded",function(_arg){var url
url=_arg.url
_this.show()
return null==_this.getEmbedIndex()?_this.setEmbedIndex(0):void 0})
this.embedLinks.on("LinkRemoved",function(_arg){var index,url
url=_arg.url,index=_arg.index
0===_this.embedLinks.getLinkCount()&&_this.hide()
return index===_this.getEmbedIndex()?console.log("we need to set a new embed index"):void 0})
this.embedLinks.on("LinkSelected",function(_arg){var url
url=_arg.url
return _this.addEmbed(url)})
this.embedLinks.on("LinksCleared",function(){return _this.urls=[]})
this.embedLinks.hide()
this.embedContainer=new KDView(options,data)
this.hide()}var addClass,getDescendantsByClassName,_ref
__extends(EmbedBoxWidget,_super)
_ref=KD.dom,addClass=_ref.addClass,getDescendantsByClassName=_ref.getDescendantsByClassName
EmbedBoxWidget.prototype.watchInput=function(){var input,_this=this
input=this.getDelegate()
input.on("keydown",function(event){var _ref1
return 9===(_ref1=event.which)||13===_ref1||32===_ref1?_this.checkInputForUrls():void 0})
input.on("paste",this.bound("checkInputForUrls"))
return input.on("change",this.bound("checkInputForUrls"))}
EmbedBoxWidget.prototype.checkInputForUrls=function(){var _this=this
return this.utils.defer(function(){var input,newUrl,newUrls,staleUrl,staleUrls,text,urls,_i,_j,_len,_len1
input=_this.getDelegate()
text=input.getValue()
urls=_.uniq(text.match(_this.utils.botchedUrlRegExp)||[])
staleUrls=_.difference(_this.urls,urls)
newUrls=_.difference(urls,_this.urls)
for(_i=0,_len=newUrls.length;_len>_i;_i++){newUrl=newUrls[_i]
_this.embedLinks.addLink(newUrl)}for(_j=0,_len1=staleUrls.length;_len1>_j;_j++){staleUrl=staleUrls[_j]
_this.embedLinks.removeLink(staleUrl)}return _this.urls=urls})}
EmbedBoxWidget.prototype.isLocked=function(url){return url in this.locks}
EmbedBoxWidget.prototype.addLock=function(url){this.locks[url]=!0
return this}
EmbedBoxWidget.prototype.removeLock=function(url){delete this.locks[url]
return this}
EmbedBoxWidget.prototype.addEmbed=function(url){this.loadEmbed(url)
return this}
EmbedBoxWidget.prototype.removeEmbed=function(){return console.log("need to remove this url")}
EmbedBoxWidget.prototype.loadEmbed=function(url){var cached,_this=this
if(this.isLocked(url))return this
this.addLock(url)
cached=this.embedCache[url]
null!=cached?this.utils.defer(function(){_this.removeLock(url)
return _this.handleEmbedlyResponse(url,cached.data,cached.options)}):this.fetchEmbed(url,{},function(data,options){_this.removeLock(url)
_this.handleEmbedlyResponse(url,data,options)
return _this.addToCache(url,data,options)})
return this}
EmbedBoxWidget.prototype.handleEmbedlyResponse=function(url,data,options){if("error"!==data.type){this.populateEmbed(data,options)
return this.show()}this.hide()}
EmbedBoxWidget.prototype.addToCache=function(url,data,options){return this.embedCache[url]={data:data,options:options}}
EmbedBoxWidget.prototype.setImageIndex=function(imageIndex){this.imageIndex=imageIndex}
EmbedBoxWidget.prototype.setEmbedIndex=function(embedIndex){this.embedIndex=embedIndex
return this.embedLinks.setActiveLinkIndex(this.embedIndex)}
EmbedBoxWidget.prototype.getEmbedIndex=function(){return this.embedIndex}
EmbedBoxWidget.prototype.refreshEmbed=function(){return this.populateEmbed(this.oembed,this.url,{})}
EmbedBoxWidget.prototype.resetEmbedAndHide=function(){this.resetEmbed()
this.embedLinks.clearLinks()
this.hasValidContent=!1
this.hide()
return this.emit("EmbedIsHidden")}
EmbedBoxWidget.prototype.resetEmbed=function(){var _ref1
this.oembed={}
this.url=""
null!=(_ref1=this.embedContainer)&&_ref1.destroy()
this.embedIndex=null
return this.imageIndex=0}
EmbedBoxWidget.prototype.getDataForSubmit=function(){var data,desiredFields,embedContent,key,value,wantedData,_i,_len,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_this=this
if(_.isEmpty(this.oembed))return{}
data=this.oembed
embedContent=this.embedContainer.embedContent
wantedData={}
if(null!=embedContent){wantedData.title=(null!=(_ref1=embedContent.embedTitle)?null!=(_ref2=_ref1.titleInput)?"function"==typeof _ref2.getValue?_ref2.getValue():void 0:void 0:void 0)||""
wantedData.description=(null!=(_ref3=embedContent.embedDescription)?null!=(_ref4=_ref3.descriptionInput)?"function"==typeof _ref4.getValue?_ref4.getValue():void 0:void 0:void 0)||""
null==data.original_title&&(wantedData.original_title=(null!=(_ref5=embedContent.embedTitle)?_ref5.getOriginalValue():void 0)||"")
null==data.original_description&&(wantedData.original_description=(null!=(_ref6=embedContent.embedDescription)?_ref6.getOriginalValue():void 0)||"")}data.images=data.images.filter(function(image,i){if(i!==_this.imageIndex)return!1
delete data.images[_this.imageIndex].colors
return!0})
this.imageIndex=0
desiredFields=["url","safe","type","provider_name","error_type","content","error_message","safe_type","safe_message","images"]
for(_i=0,_len=desiredFields.length;_len>_i;_i++){key=desiredFields[_i]
wantedData[key]=data[key]}for(key in wantedData){value=wantedData[key]
"string"==typeof value&&(wantedData[key]=Encoder.htmlDecode(value))}return wantedData}
EmbedBoxWidget.prototype.displayEmbedType=function(embedType,data){var containerClass,embedOptions,_ref1
this.hasValidContent=!0
containerClass=function(){switch(embedType){case"image":return EmbedBoxImageView
case"object":return EmbedBoxObjectView
default:return EmbedBoxLinkView}}()
embedOptions={cssClass:"link-embed clearfix",delegate:this}
null!=(_ref1=this.embedContainer)&&_ref1.destroy()
this.embedContainer=new containerClass(embedOptions,data)
this.addSubView(this.embedContainer)
this.emit("EmbedIsShown")
return this.show()}
EmbedBoxWidget.prototype.populateEmbed=function(data,options){var embedDiv,type
null==data&&(data={})
null==options&&(options={})
if(null!=data){this.oembed=data
this.url=data.url
if(null==data.safe||data.safe===!0||"true"===data.safe){if(!data.error_message){type=data.type||"link"
this.displayEmbedType(this.utils.getEmbedType(type),{link_embed:data,link_url:data.url,link_options:options})
embedDiv=getDescendantsByClassName(this.getElement(),"embed")[0]
return null!=embedDiv?addClass(embedDiv,"custom-"+type):void 0}log("EmbedBoxWidget encountered an error!",data.error_type,data.error_message)
this.hide()}else{log("There was unsafe content.",data,data.safe_type,data.safe_message)
this.hide()}}}
EmbedBoxWidget.prototype.fetchEmbed=function(url,options,callback){var embedlyOptions
null==url&&(url="")
null==options&&(options={})
null==callback&&(callback=noop)
this.utils.webProtocolRegExp.test(url)||(url="http://"+url)
embedlyOptions=this.utils.extend({maxWidth:530,maxHeight:200,wmode:"transparent"},options)
return KD.remote.api.JNewStatusUpdate.fetchDataFromEmbedly(url,embedlyOptions,function(err,oembed){return callback(oembed[0],embedlyOptions)})}
EmbedBoxWidget.prototype.viewAppended=JView.prototype.viewAppended
EmbedBoxWidget.prototype.pistachio=function(){return"{{> this.settingsButton}}"}
return EmbedBoxWidget}(KDView)

var EmbedBoxObjectView,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxObjectView=function(_super){function EmbedBoxObjectView(){_ref=EmbedBoxObjectView.__super__.constructor.apply(this,arguments)
return _ref}__extends(EmbedBoxObjectView,_super)
EmbedBoxObjectView.prototype.viewAppended=JView.prototype.viewAppended
EmbedBoxObjectView.prototype.pistachio=function(){var objectHtml,_ref1,_ref2
objectHtml=null!=(_ref1=this.getData().link_embed)?null!=(_ref2=_ref1.object)?_ref2.html:void 0:void 0
return'<div class="embed embed-object-view custom-object">\n  '+Encoder.htmlDecode(objectHtml||"")+"\n</div>"}
return EmbedBoxObjectView}(KDView)

var EmbedBoxImageView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxImageView=function(_super){function EmbedBoxImageView(options,data){var oembed,srcUrl,_ref,_ref1
null==options&&(options={})
EmbedBoxImageView.__super__.constructor.call(this,data.link_options,data)
oembed=this.getData().link_embed
srcUrl=this.utils.proxifyUrl(null!=(_ref=oembed.images)?null!=(_ref1=_ref[0])?_ref1.url:void 0:void 0,{width:728,height:368,grow:!0,crop:!0})
this.image=new KDCustomHTMLView({tagName:"img",attributes:{src:srcUrl,title:oembed.title||"",width:"100%"}})
this.setClass("embed-image-view")}__extends(EmbedBoxImageView,_super)
EmbedBoxImageView.prototype.pistachio=function(){var link_url
link_url=this.getData().link_url
return'<a href="'+(link_url||"#")+'" target="_blank">\n  {{> this.image}}\n</a>'}
return EmbedBoxImageView}(JView)

var EmbedBoxLinkViewDescription,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewDescription=function(_super){function EmbedBoxLinkViewDescription(options,data){var oembed,_ref1,_this=this
null==options&&(options={})
null==data&&(data={})
options.cssClass=KD.utils.curry("description",options.cssClass)
EmbedBoxLinkViewDescription.__super__.constructor.call(this,options,data)
oembed=data.link_embed;(null!=oembed?null!=(_ref1=oembed.description)?_ref1.trim():void 0:void 0)||this.hide()
this.originalDescription=(null!=oembed?oembed.description:void 0)||""
this.descriptionInput=new KDInputView({type:"textarea",cssClass:"description-input hidden",name:"description_input",defaultValue:this.originalDescription,autogrow:!0,blur:function(){var descriptionEl
_this.descriptionInput.hide()
descriptionEl=_this.getDescriptionEl()
setText(descriptionEl,Encoder.XSSEncode(_this.getValue()))
return _this.utils.elementShow(descriptionEl)}})}var getDescendantsByClassName,setText,_ref
__extends(EmbedBoxLinkViewDescription,_super)
_ref=KD.dom,getDescendantsByClassName=_ref.getDescendantsByClassName,setText=_ref.setText
EmbedBoxLinkViewDescription.prototype.getDescriptionEl=function(){return getDescendantsByClassName(this.getElement(),"description")[0]}
EmbedBoxLinkViewDescription.prototype.getValue=function(){return this.descriptionInput.getValue()}
EmbedBoxLinkViewDescription.prototype.getOriginalValue=function(){return this.originalDescription}
EmbedBoxLinkViewDescription.prototype.viewAppended=function(){var _ref1
JView.prototype.viewAppended.call(this)
return(null!=(_ref1=this.getData().link_embed)?_ref1.descriptionEdited:void 0)?this.editIndicator.show():void 0}
EmbedBoxLinkViewDescription.prototype.click=function(){}
EmbedBoxLinkViewDescription.prototype.getDescription=function(){var value,_ref1
value=(null!=(_ref1=this.getData().link_embed)?_ref1.description:void 0)||this.getData().description
null!=value&&(value=Encoder.XSSEncode(value))
return value}
EmbedBoxLinkViewDescription.prototype.pistachio=function(){return"{{> this.descriptionInput}}\n"+(this.getDescription()||"")}
return EmbedBoxLinkViewDescription}(KDView)

var EmbedBoxLinkDisplayView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkDisplayView=function(_super){function EmbedBoxLinkDisplayView(options,data){var _ref,_ref1
null==options&&(options={})
EmbedBoxLinkDisplayView.__super__.constructor.call(this,options,data)
this.embedImage=null!=(null!=data?null!=(_ref=data.link_embed)?null!=(_ref1=_ref.images)?_ref1[0]:void 0:void 0:void 0)?new EmbedBoxLinkViewImage({cssClass:"preview-image",delegate:this},data):new KDCustomHTMLView("hidden")
this.embedContent=new EmbedBoxLinkViewContent({cssClass:"preview-text",delegate:this},data)}__extends(EmbedBoxLinkDisplayView,_super)
EmbedBoxLinkDisplayView.prototype.pistachio=function(){return'<div class="embed embed-link-view custom-link clearfix">\n  {{> this.embedImage}}\n  {{> this.embedContent}}\n</div>'}
return EmbedBoxLinkDisplayView}(JView)

var EmbedBoxLinkViewImage,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewImage=function(_super){function EmbedBoxLinkViewImage(options,data){var altSuffix,oembed,_ref,_ref1,_ref2
null==options&&(options={})
options.href=data.link_url||(null!=(_ref=data.link_embed)?_ref.url:void 0)
options.target="_blank"
EmbedBoxLinkViewImage.__super__.constructor.call(this,options,data)
oembed=this.getData().link_embed
this.imageLink=this.utils.proxifyUrl(null!=(_ref1=oembed.images)?null!=(_ref2=_ref1[0])?_ref2.url:void 0:void 0,{width:144,height:100,crop:!0,grow:!0})
altSuffix=oembed.author_name?" by "+oembed.author_name:""
this.imageAltText=oembed.title+altSuffix
this.imageView=new KDCustomHTMLView({tagName:"img",cssClass:"thumb",bind:"error",error:this.bound("hide"),attributes:{src:this.imageLink,alt:this.imageAltText,title:this.imageAltText}})}__extends(EmbedBoxLinkViewImage,_super)
EmbedBoxLinkViewImage.prototype.setSrc=function(src){return this.imageView.getElement().src=src}
EmbedBoxLinkViewImage.prototype.viewAppended=function(){var link_embed,_ref,_ref1,_ref2
JView.prototype.viewAppended.call(this)
link_embed=this.getData().link_embed
return null!=link_embed?"video"===(null!=(_ref=link_embed.object)?_ref.type:void 0)?this.videoPopup=new VideoPopup({delegate:this.imageView,title:link_embed.title||"Untitled Video",thumb:null!=(_ref1=link_embed.images)?null!=(_ref2=_ref1[0])?_ref2.url:void 0:void 0},link_embed.object.html):void 0:void 0}
EmbedBoxLinkViewImage.prototype.pistachio=function(){return"{{> this.imageView}}"}
return EmbedBoxLinkViewImage}(CustomLinkView)

var EmbedBoxLinksView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinksView=function(_super){function EmbedBoxLinksView(options,data){var _this=this
null==options&&(options={})
options.cssClass="embed-links-container"
EmbedBoxLinksView.__super__.constructor.call(this,options,data)
this.linkListController=new KDListViewController({viewOptions:{cssClass:"embed-link-list layout-wrapper",delegate:this},itemClass:EmbedBoxLinksViewItem})
this.linkListController.on("ItemSelectionPerformed",function(controller,_arg){var items
items=_arg.items
return items.forEach(function(item){return _this.emit("LinkSelected",item.getData())})})
this.linkList=this.linkListController.getView()
this.hide()}__extends(EmbedBoxLinksView,_super)
EmbedBoxLinksView.prototype.clearLinks=function(){this.linkListController.removeAllItems()
return this.emit("LinksCleared")}
EmbedBoxLinksView.prototype.setActiveLinkIndex=function(index){var item
item=this.linkListController.itemsOrdered[index]
this.linkListController.deselectAllItems()
return this.linkListController.selectSingleItem(item)}
EmbedBoxLinksView.prototype.getLinkCount=function(){return this.linkListController.getItemCount()}
EmbedBoxLinksView.prototype.addLink=function(url){var data
data={url:url}
this.linkListController.addItem(data)
this.linkListController.getItemCount()>0&&this.show()
return this.emit("LinkAdded",url,data)}
EmbedBoxLinksView.prototype.removeLink=function(url){var _this=this
return this.linkListController.itemsOrdered.forEach(function(item,index){var data
data=item.getData()
if(data.url===url){_this.linkListController.removeItem(item)
return _this.emit("LinkRemoved",{url:url,index:index})}})}
EmbedBoxLinksView.prototype.viewAppended=JView.prototype.viewAppended
EmbedBoxLinksView.prototype.pistachio=function(){return"{{> this.linkList}}"}
return EmbedBoxLinksView}(KDView)

var EmbedBoxLinkViewImageSwitch,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewImageSwitch=function(_super){function EmbedBoxLinkViewImageSwitch(options,data){null==options&&(options={})
EmbedBoxLinkViewImageSwitch.__super__.constructor.call(this,options,data);(null==data.link_embed.images||data.link_embed.images.length<2)&&this.hide()
this.imageIndex=0}var addClass,getDescendantsByClassName,hasClass,removeClass,setText,_ref
__extends(EmbedBoxLinkViewImageSwitch,_super)
_ref=KD.dom,hasClass=_ref.hasClass,addClass=_ref.addClass,removeClass=_ref.removeClass,getDescendantsByClassName=_ref.getDescendantsByClassName,setText=_ref.setText
EmbedBoxLinkViewImageSwitch.prototype.getImageIndex=function(){return this.imageIndex}
EmbedBoxLinkViewImageSwitch.prototype.setImageIndex=function(imageIndex){this.imageIndex=imageIndex}
EmbedBoxLinkViewImageSwitch.prototype.getButton=function(dir){return getDescendantsByClassName(this.getElement(),dir)[0]}
EmbedBoxLinkViewImageSwitch.prototype.disableButton=function(dir){return addClass(this.getButton(dir),"disabled")}
EmbedBoxLinkViewImageSwitch.prototype.enableButton=function(dir){return removeClass(this.getButton(dir),"disabled")}
EmbedBoxLinkViewImageSwitch.prototype.click=function(event){var defaultImgSrc,fallBackImgSrc,imageIndex,imgSrc,oembed,pageNumber,proxiedImage,target,_ref1,_ref2
event.preventDefault()
event.stopPropagation()
oembed=this.getData().link_embed
if(null!=(null!=oembed?oembed.images:void 0)){target=event.target
if(hasClass(target,"preview-link-switch")){imageIndex=this.getImageIndex()
if(hasClass(target,"next")&&oembed.images.length-1>imageIndex){imageIndex++
this.setImageIndex(imageIndex)
this.enableButton("previous")}else if(hasClass(target,"previous")&&imageIndex>0){imageIndex--
this.setImageIndex(imageIndex)
this.enableButton("next")}pageNumber=getDescendantsByClassName(this.getElement(),"thumb-nr")[0]
setText(pageNumber,imageIndex+1)
if(imageIndex<oembed.images.length-1){imgSrc=null!=(_ref1=oembed.images[imageIndex])?_ref1.url:void 0
if(imgSrc){proxiedImage=this.utils.proxifyUrl(imgSrc,{width:144,height:100,crop:!0,grow:!0})
this.getDelegate().embedImage.setSrc(proxiedImage)}else{fallBackImgSrc="https://koding.com/images/service_icons/Koding.png"
this.getDelegate().embedImage.setSrc(fallBackImgSrc)}this.getDelegate().getDelegate().setImageIndex(imageIndex)}else{defaultImgSrc=null!=(_ref2=oembed.images[0])?_ref2.url:void 0
this.getDelegate().embedImage.setSrc(defaultImgSrc)}return 0===imageIndex?this.disableButton("previous"):imageIndex===oembed.images.length-1?this.disableButton("next"):void 0}}}
EmbedBoxLinkViewImageSwitch.prototype.viewAppended=JView.prototype.viewAppended
EmbedBoxLinkViewImageSwitch.prototype.pistachio=function(){var imageIndex,images,link_embed
imageIndex=this.getImageIndex()
link_embed=this.getData().link_embed
images=link_embed.images
return'<a class="preview-link-switch previous '+(0===imageIndex?"disabled":"")+'"></a>\n<a class="preview-link-switch next '+(imageIndex===images.length?"disabled":"")+'"></a>\n<div class="thumb-count">\n  <span class="thumb-nr">'+(imageIndex+1||"1")+'</span> of <span class="thumb-all">'+images.length+'</span>\n  <span class="thumb-text">Choose a thumbnail</span>\n</div>'}
return EmbedBoxLinkViewImageSwitch}(KDView)

var EmbedBoxLinksViewItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinksViewItem=function(_super){function EmbedBoxLinksViewItem(options,data){null==options&&(options={})
options=this.utils.extend({},options,{cssClass:"embed-link-item",tooltip:{title:data.url,placement:"above",offset:3,delayIn:300,html:!0,animate:!0}})
EmbedBoxLinksViewItem.__super__.constructor.call(this,options,data)}__extends(EmbedBoxLinksViewItem,_super)
EmbedBoxLinksViewItem.prototype.partial=function(){var linkUrlShort
linkUrlShort=this.getData().url.replace(this.utils.webProtocolRegExp,"").replace(/\/.*/,"")
return'<div class="embed-link-wrapper">\n  '+linkUrlShort+"\n</div>"}
return EmbedBoxLinksViewItem}(KDListItemView)

var EmbedBoxLinkViewProvider,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewProvider=function(_super){function EmbedBoxLinkViewProvider(options,data){var _ref
EmbedBoxLinkViewProvider.__super__.constructor.call(this,options,data)
null==(null!=(_ref=data.link_embed)?_ref.provider_name:void 0)&&this.hide()}__extends(EmbedBoxLinkViewProvider,_super)
EmbedBoxLinkViewProvider.prototype.viewAppended=JView.prototype.viewAppended
EmbedBoxLinkViewProvider.prototype.pistachio=function(){var data,link_embed,provider_display,provider_link,provider_name,provider_url
data=this.getData()
link_embed=data.link_embed,provider_name=data.provider_name,provider_url=data.provider_url,provider_display=data.provider_display
link_embed||(link_embed={})
provider_name||(provider_name=link_embed.provider_name||"")
provider_url||(provider_url=link_embed.provider_url)
provider_display||(provider_display=link_embed.provider_display||"")
provider_link=provider_url?"at <a href='"+provider_url+"' target='_blank'>"+provider_display+"</a>":""
return"<strong>"+provider_name+"</strong>"}
return EmbedBoxLinkViewProvider}(KDView)

var EmbedBoxLinkView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkView=function(_super){function EmbedBoxLinkView(options,data){var _ref,_ref1
null==options&&(options={})
EmbedBoxLinkView.__super__.constructor.call(this,options,data)
this.embedImage=null!=(null!=(_ref=data.link_embed)?null!=(_ref1=_ref.images)?_ref1[0]:void 0:void 0)?new EmbedBoxLinkViewImage({cssClass:"preview-image",delegate:this},data):new KDCustomHTMLView("hidden")
this.embedContent=new EmbedBoxLinkViewContent({cssClass:"preview-text",delegate:this},data)
this.embedImageSwitch=new EmbedBoxLinkViewImageSwitch({cssClass:"preview-link-pager",delegate:this},data)}__extends(EmbedBoxLinkView,_super)
EmbedBoxLinkView.prototype.pistachio=function(){return'<div class="embed embed-link-view custom-link">\n  {{> this.embedImage}}\n  {{> this.embedContent}}\n  {{> this.embedImageSwitch}}\n</div>'}
return EmbedBoxLinkView}(JView)

var EmbedBoxLinkViewTitle,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewTitle=function(_super){function EmbedBoxLinkViewTitle(options,data){var oembed,_this=this
null==options&&(options={})
EmbedBoxLinkViewTitle.__super__.constructor.call(this,options,data)
oembed=data.link_embed
this.originalTitle=null!=oembed?oembed.title:void 0
this.titleInput=new KDInputView({cssClass:"preview-title-input hidden",name:"preview-title-input",defaultValue:oembed.title||"",blur:function(){_this.titleInput.hide()
return _this.$("div.preview-title").html(_this.getValue()).show()}})
this.editIndicator=new KDCustomHTMLView({tagName:"div",cssClass:"edit-indicator title-edit-indicator",pistachio:"edited",tooltip:{title:"Original Content was: "+(oembed.original_title||oembed.title||"")}})
this.editIndicator.hide()}__extends(EmbedBoxLinkViewTitle,_super)
EmbedBoxLinkViewTitle.prototype.hide=function(){EmbedBoxLinkViewTitle.__super__.hide.apply(this,arguments)
return console.trace()}
EmbedBoxLinkViewTitle.prototype.viewAppended=function(){var _ref
JView.prototype.viewAppended.call(this)
return(null!=(_ref=this.getData().link_embed)?_ref.titleEdited:void 0)?this.editIndicator.show():void 0}
EmbedBoxLinkViewTitle.prototype.getValue=function(){return this.titleInput.getValue()}
EmbedBoxLinkViewTitle.prototype.getOriginalValue=function(){return this.originalTitle}
EmbedBoxLinkViewTitle.prototype.click=function(){}
EmbedBoxLinkViewTitle.prototype.pistachio=function(){var title,_ref
title=(null!=(_ref=this.getData().link_embed)?_ref.title:void 0)||this.getData().title||this.getData().link_url
return'{{> this.titleInput}}\n<div class="preview-title">\n  '+title+"\n  {{> this.editIndicator}}\n</div>"}
return EmbedBoxLinkViewTitle}(KDView)

var EmbedBoxLinkViewAuthor,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewAuthor=function(_super){function EmbedBoxLinkViewAuthor(options,data){var _ref
EmbedBoxLinkViewAuthor.__super__.constructor.call(this,options,data)
null==(null!=(_ref=data.link_embed)?_ref.author_name:void 0)&&this.hide()}__extends(EmbedBoxLinkViewAuthor,_super)
EmbedBoxLinkViewAuthor.prototype.viewAppended=JView.prototype.viewAppended
EmbedBoxLinkViewAuthor.prototype.pistachio=function(){var _ref,_ref1
return'written by <a href="'+((null!=(_ref=this.getData().link_embed)?_ref.author_url:void 0)||this.getData().author_url||"#")+'" target="_blank">'+((null!=(_ref1=this.getData().link_embed)?_ref1.author_name:void 0)||this.getData().author_name)+"</a>"}
return EmbedBoxLinkViewAuthor}(KDView)

var EmbedBoxLinkViewContent,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
EmbedBoxLinkViewContent=function(_super){function EmbedBoxLinkViewContent(options,data){var contentOptions
null==options&&(options={})
EmbedBoxLinkViewContent.__super__.constructor.call(this,options,data)
contentOptions={tagName:"a",cssClass:"preview-text-link",attributes:{href:data.link_url,target:"_blank"}}
this.embedTitle=new EmbedBoxLinkViewTitle(contentOptions,data)
this.embedProvider=new EmbedBoxLinkViewProvider({cssClass:"provider-info"},data)
this.embedDescription=new EmbedBoxLinkViewDescription(contentOptions,data)}__extends(EmbedBoxLinkViewContent,_super)
EmbedBoxLinkViewContent.prototype.pistachio=function(){return"{{> this.embedTitle}}\n{{> this.embedDescription}}\n{{> this.embedProvider}}"}
return EmbedBoxLinkViewContent}(JView)

var SkillTagGroup,TagCloudListItemView,TagGroup,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TagGroup=function(_super){function TagGroup(options,data){options=$.extend({cssClass:"tag-group"},options)
TagGroup.__super__.constructor.call(this,options,data)}__extends(TagGroup,_super)
TagGroup.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
TagGroup.prototype.fetchTags=function(stringTags,callback){return this._fetchTags("some",stringTags,callback)}
TagGroup.prototype._fetchTags=function(method,stringTags,callback){return stringTags.length>0?KD.remote.api.JTag[method]({title:{$in:stringTags}},{sort:{title:1}},function(err,tags){if(!err||tags)return callback(null,tags)
callback(err)
return warn("there was a problem fetching default tags!",err,tags)}):warn("no tag info was given!")}
return TagGroup}(KDCustomHTMLView)
SkillTagGroup=function(_super){function SkillTagGroup(options,data){var controller,name,_this=this
SkillTagGroup.__super__.constructor.call(this,options,data)
this.skillTags=(this.getData()||[]).skillTags
name=KD.utils.getFullnameFromAccount(this.getData(),!0)
this.noTags=new KDCustomHTMLView({tagName:"span",cssClass:"noskilltags",partial:""+name+" hasn't entered any skills yet."})
controller=new KDListViewController({view:new KDListView({itemClass:TagCloudListItemView,cssClass:"skilltag-cloud",delegate:this})})
controller.listView.on("TagWasClicked",function(){return _this.emit("TagWasClicked")})
this.listViewWrapper=controller.getView()
0!==this.skillTags.length&&"No Tags"!==this.skillTags[0]&&this.fetchTags(this.skillTags,function(err,tags){return err?void 0:controller.instantiateListItems(tags)})
this.getData().watch("skillTags",function(){return controller.replaceAllItems(this.skillTags)})}__extends(SkillTagGroup,_super)
SkillTagGroup.prototype.fetchTags=function(stringTags,callback){return this._fetchTags("fetchSkillTags",stringTags,callback)}
SkillTagGroup.prototype.pistachio=function(){return this.skillTags.length&&"No Tags"!==this.skillTags[0]?"{{> this.listViewWrapper}}":"{{> this.noTags}}"}
return SkillTagGroup}(TagGroup)
TagCloudListItemView=function(_super){function TagCloudListItemView(options,data){options=$.extend({tagName:"a",attributes:{href:"#"}},options)
TagCloudListItemView.__super__.constructor.call(this,options,data)
this.setClass("ttag")
this.unsetClass("kdview")
this.unsetClass("kdlistitemview")
this.unsetClass("kdlistitemview-default")}__extends(TagCloudListItemView,_super)
TagCloudListItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
TagCloudListItemView.prototype.pistachio=function(){return TagCloudListItemView.__super__.pistachio.call(this,"{{#(title)}}")}
TagCloudListItemView.prototype.click=function(e){null!=e&&e.preventDefault()
null!=e&&e.stopPropagation()
return this.openTag(this.getData())}
TagCloudListItemView.prototype.openTag=function(tag){var entryPoint
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Topics/"+tag.slug,{state:tag,entryPoint:entryPoint})}
return TagCloudListItemView}(KDListItemView)

var SuggestNewTagItem,TagAutoCompleteController,TagAutoCompleteItemView,TagAutoCompletedItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TagAutoCompleteController=function(_super){function TagAutoCompleteController(options){options.nothingFoundItemClass||(options.nothingFoundItemClass=SuggestNewTagItem)
null==options.allowNewSuggestions&&(options.allowNewSuggestions=!0)
TagAutoCompleteController.__super__.constructor.apply(this,arguments)}__extends(TagAutoCompleteController,_super)
return TagAutoCompleteController}(KDAutoCompleteController)
TagAutoCompleteItemView=function(_super){function TagAutoCompleteItemView(options){options.cssClass="clearfix"
TagAutoCompleteItemView.__super__.constructor.apply(this,arguments)}__extends(TagAutoCompleteItemView,_super)
TagAutoCompleteItemView.prototype.pistachio=function(){return"<span class='ttag'>{{#(title)}}</span>"}
TagAutoCompleteItemView.prototype.viewAppended=function(){TagAutoCompleteItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
return this.template.update()}
TagAutoCompleteItemView.prototype.partial=function(){return""}
return TagAutoCompleteItemView}(KDAutoCompleteListItemView)
TagAutoCompletedItemView=function(_super){function TagAutoCompletedItemView(options,data){options.cssClass="clearfix"
TagAutoCompletedItemView.__super__.constructor.apply(this,arguments)
this.tag=new TagLinkView({clickable:!1},data)}__extends(TagAutoCompletedItemView,_super)
TagAutoCompletedItemView.prototype.pistachio=function(){return"{{> this.tag}}"}
TagAutoCompletedItemView.prototype.viewAppended=function(){TagAutoCompletedItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
return this.template.update()}
TagAutoCompletedItemView.prototype.partial=function(){return""}
return TagAutoCompletedItemView}(KDAutoCompletedItem)
SuggestNewTagItem=function(_super){function SuggestNewTagItem(options,data){options.cssClass="suggest clearfix"
SuggestNewTagItem.__super__.constructor.call(this,options,data)}__extends(SuggestNewTagItem,_super)
SuggestNewTagItem.prototype.partial=function(){return"Suggest <span class='ttag'>"+this.getOptions().userInput+"</span> as a new topic?"}
return SuggestNewTagItem}(KDAutoCompleteListItemView)

var CommentView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommentView=function(_super){function CommentView(options,data){var fixedHeight
CommentView.__super__.constructor.apply(this,arguments)
this.setClass("comment-container")
this.createSubViews(data)
this.resetDecoration()
this.attachListeners()
fixedHeight=this.getOptions().fixedHeight
fixedHeight||(fixedHeight=!1)
fixedHeight&&this.setFixedHeight(fixedHeight)}__extends(CommentView,_super)
CommentView.prototype.render=function(){return this.resetDecoration()}
CommentView.prototype.setFixedHeight=function(maxHeight){this.setClass("fixed-height")
return this.commentList.$().css({maxHeight:maxHeight})}
CommentView.prototype.createSubViews=function(data){var reply,showMore,_i,_len,_ref,_this=this
this.commentList=new KDListView({type:"comments",itemClass:CommentListItemView,delegate:this},data)
this.commentController=new CommentListViewController({view:this.commentList})
this.addSubView(showMore=new CommentViewHeader({delegate:this.commentList},data))
this.addSubView(this.commentController.getView())
this.addSubView(this.commentForm=new NewCommentForm({delegate:this.commentList}))
this.commentList.on("ReplyLinkClicked",function(username){var input,value
input=_this.commentForm.commentInput
value=input.getValue()
value=value.indexOf("@"+username)>=0?value:0===value.length?"@"+username+" ":""+value+" @"+username+" "
input.setFocus()
return input.setValue(value)})
this.commentList.on("OwnCommentWasSubmitted",function(){var _ref
return null!=(_ref=this.getDelegate())?_ref.emit("RefreshTeaser"):void 0})
this.commentList.on("OwnCommentHasArrived",function(){var _ref
showMore.ownCommentArrived()
return null!=(_ref=this.getDelegate())?_ref.emit("RefreshTeaser"):void 0})
this.commentList.on("CommentIsDeleted",function(){return showMore.ownCommentDeleted()})
this.on("RefreshTeaser",function(){var _ref
return null!=(_ref=this.parent)?_ref.emit("RefreshTeaser"):void 0})
if(data.replies){_ref=data.replies
for(_i=0,_len=_ref.length;_len>_i;_i++){reply=_ref[_i]
null!=reply&&null!=reply.originId&&null!=reply.originType&&this.commentList.addItem(reply)}}else this.commentController.fetchRelativeComments(null,data.meta.createdAt,!1)
return this.commentList.emit("BackgroundActivityFinished")}
CommentView.prototype.attachListeners=function(){var _this=this
this.commentList.on("commentInputReceivedFocus",this.bound("decorateActiveCommentState"))
this.commentList.on("CommentLinkReceivedClick",function(){_this.commentForm.makeCommentFieldActive()
return _this.commentForm.commentInput.setFocus()})
this.commentList.on("CommentCountClicked",function(){return _this.commentList.emit("AllCommentsLinkWasClicked")})
return this.commentList.on("CommentViewShouldReset",this.bound("resetDecoration"))}
CommentView.prototype.resetDecoration=function(){var post
post=this.getData()
return 0===post.repliesCount?this.decorateNoCommentState():this.decorateCommentedState()}
CommentView.prototype.decorateNoCommentState=function(){this.unsetClass("active-comment")
this.unsetClass("commented")
return this.setClass("no-comment")}
CommentView.prototype.decorateCommentedState=function(){this.unsetClass("active-comment")
this.unsetClass("no-comment")
return this.setClass("commented")}
CommentView.prototype.decorateActiveCommentState=function(){this.unsetClass("no-comment")
return this.setClass("active-comment")}
CommentView.prototype.decorateItemAsLiked=function(likeObj){var _ref;(null!=likeObj?null!=(_ref=likeObj.results)?_ref.likeCount:void 0:void 0)>0?this.setClass("liked"):this.unsetClass("liked")
return this.ActivityActionsView.setLikedCount(likeObj)}
return CommentView}(KDView)

var CommentListViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommentListViewController=function(_super){function CommentListViewController(){CommentListViewController.__super__.constructor.apply(this,arguments)
this._hasBackgrounActivity=!1
this.startListeners()}__extends(CommentListViewController,_super)
CommentListViewController.prototype.instantiateListItems=function(items,keepDeletedComments){var comment,commentView,i,newItems,nextComment,skipComment,_i,_len
null==keepDeletedComments&&(keepDeletedComments=!1)
newItems=[]
items.sort(function(a,b){a=a.meta.createdAt
b=b.meta.createdAt
return b>a?-1:a>b?1:0})
for(i=_i=0,_len=items.length;_len>_i;i=++_i){comment=items[i]
nextComment=items[i+1]
skipComment=!1
null!=nextComment&&comment.deletedAt&&Date.parse(nextComment.meta.createdAt)>Date.parse(comment.deletedAt)&&(skipComment=!0)
!nextComment&&comment.deletedAt&&(skipComment=!0)
keepDeletedComments&&(skipComment=!1)
if(!skipComment){commentView=this.getListView().addItem(comment)
newItems.push(commentView)}}return newItems}
CommentListViewController.prototype.startListeners=function(){var listView,_this=this
listView=this.getListView()
listView.on("ItemWasAdded",function(view){return view.on("CommentIsDeleted",function(){return listView.emit("CommentIsDeleted")})})
listView.on("AllCommentsLinkWasClicked",function(){var meta
if(!_this._hasBackgrounActivity){_this.utils.wait(5e3,function(){return listView.emit("BackgroundActivityFinished")})
meta=listView.getData().meta
listView.emit("BackgroundActivityStarted")
_this._hasBackgrounActivity=!0
_this._removedBefore=!1
return _this.fetchRelativeComments(10,meta.createdAt)}})
return listView.on("CommentSubmitted",function(reply){var model
model=listView.getData()
listView.emit("BackgroundActivityStarted")
model.reply(reply,function(err,reply){var _ref
if(null!=(_ref=KD.getSingleton("activityController").flags)?_ref.liveUpdates:void 0)listView.emit("OwnCommentWasSubmitted")
else{listView.addItem(reply)
listView.emit("OwnCommentHasArrived")}return listView.emit("BackgroundActivityFinished")})
KD.mixpanel("Commented on activity")
return KD.getSingleton("badgeController").checkBadge({property:"comments",relType:"commenter",source:"JNewStatusUpdate",targetSelf:1})})}
CommentListViewController.prototype.fetchCommentsByRange=function(from,to,callback){var message,query,_ref,_this=this
callback||(_ref=[callback,to],to=_ref[0],callback=_ref[1])
query={from:from,to:to}
message=this.getListView().getData()
return message.commentsByRange(query,function(err,comments){_this.getListView().emit("BackgroundActivityFinished")
return callback(err,comments)})}
CommentListViewController.prototype.fetchAllComments=function(skipCount,callback){var listView,message
null==skipCount&&(skipCount=3)
null==callback&&(callback=noop)
listView=this.getListView()
listView.emit("BackgroundActivityStarted")
message=this.getListView().getData()
return message.restComments(skipCount,function(err,comments){listView.emit("BackgroundActivityFinished")
listView.emit("AllCommentsWereAdded")
return callback(err,comments)})}
CommentListViewController.prototype.fetchRelativeComments=function(_limit,_after,continuous){var listView,message,_this=this
null==_limit&&(_limit=10)
null==continuous&&(continuous=!0)
listView=this.getListView()
message=this.getListView().getData()
return message.fetchRelativeComments({limit:_limit,after:_after},function(err,comments){var startTime
if(!_this._removedBefore){_this.removeAllItems()
_this._removedBefore=!0}_this.instantiateListItems(comments.slice(_limit-10),!0)
if(comments.length!==_limit){listView=_this.getListView()
listView.emit("BackgroundActivityFinished")
listView.emit("AllCommentsWereAdded")
return _this._hasBackgrounActivity=!1}startTime=comments[comments.length-1].meta.createdAt
return continuous?_this.fetchRelativeComments(++_limit,startTime,continuous):void 0})}
CommentListViewController.prototype.replaceAllComments=function(comments){this.removeAllItems()
return this.instantiateListItems(comments)}
return CommentListViewController}(KDListViewController)

var CommentViewHeader,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommentViewHeader=function(_super){function CommentViewHeader(options,data){var list,_ref,_this=this
null==options&&(options={})
options.cssClass="show-more-comments in"
options.itemTypeString=options.itemTypeString||"comments"
CommentViewHeader.__super__.constructor.call(this,options,data)
data=this.getData()
this.maxCommentToShow=options.maxCommentToShow||3
this.oldCount=data.repliesCount
this.newCount=0
this.onListCount=data.repliesCount>this.maxCommentToShow?this.maxCommentToShow:data.repliesCount
if(!(null!=data.repliesCount&&data.repliesCount>this.maxCommentToShow)){this.onListCount=data.repliesCount
this.hide()}0===data.repliesCount&&this.hide()
list=this.getDelegate()
list.on("AllCommentsWereAdded",function(){_this.newCount=0
_this.onListCount=_this.getData().repliesCount
_this.updateNewCount()
return _this.hide()})
this.allItemsLink=new KDCustomHTMLView({tagName:"a",cssClass:"all-count",pistachio:"View all {{#(repliesCount)}} "+this.getOptions().itemTypeString+"...",click:function(event){KD.utils.stopDOMEvent(event)
return list.emit("AllCommentsLinkWasClicked",this)}},data)
this.newItemsLink=new KDCustomHTMLView({tagName:"a",cssClass:"new-items",click:function(){return list.emit("AllCommentsLinkWasClicked",_this)}})
this.liveUpdate=(null!=(_ref=KD.getSingleton("activityController").flags)?_ref.liveUpdates:void 0)||!1
KD.getSingleton("activityController").on("LiveStatusUpdateStateChanged",function(newstate){return _this.liveUpdate=newstate})}__extends(CommentViewHeader,_super)
CommentViewHeader.prototype.ownCommentArrived=function(){var _ref
this.onListCount=null!=(_ref=this.parent.commentController)?"function"==typeof _ref.getItemCount?_ref.getItemCount():void 0:void 0
this.newItemsLink.unsetClass("in")
this.newCount>0&&this.newCount--
return this.updateNewCount()}
CommentViewHeader.prototype.ownCommentDeleted=function(){return this.newCount>0?this.newCount++:void 0}
CommentViewHeader.prototype.render=function(){var _newCount,_ref,_ref1,_this=this;(null!=(_ref=this.parent)?null!=(_ref1=_ref.commentController)?"function"==typeof _ref1.getItemCount?_ref1.getItemCount():void 0:void 0:void 0)&&(this.onListCount=this.parent.commentController.getItemCount())
_newCount=this.getData().repliesCount
_newCount>this.maxCommentToShow&&this.onListCount<_newCount&&this.show()
_newCount>this.oldCount?this.newCount++:_newCount<this.oldCount&&this.newCount>0&&this.newCount--
if(_newCount!==this.oldCount){this.oldCount=_newCount
this.utils.defer(function(){return _this.updateNewCount()})}return CommentViewHeader.__super__.render.apply(this,arguments)}
CommentViewHeader.prototype.updateNewCount=function(){0===this.oldCount&&(this.newCount=0)
if(this.newCount>0)if(this.liveUpdate)this.getDelegate().emit("AllCommentsLinkWasClicked")
else{this.setClass("new")
this.allItemsLink.hide()
this.show()
this.newItemsLink.updatePartial(""+this.newCount+" new comment...")
this.newItemsLink.setClass("in")}else{this.unsetClass("new")
this.newItemsLink.unsetClass("in")}this.onListCount>this.oldCount&&(this.onListCount=this.oldCount)
this.onListCount===this.getData().repliesCount&&(this.newCount=0)
return this.onListCount===this.oldCount&&0===this.newCount?this.hide():this.show()}
CommentViewHeader.prototype.hide=function(){this.unsetClass("in")
return CommentViewHeader.__super__.hide.apply(this,arguments)}
CommentViewHeader.prototype.show=function(){this.setClass("in")
return CommentViewHeader.__super__.show.apply(this,arguments)}
CommentViewHeader.prototype.pistachio=function(){return"{{> this.allItemsLink}}\n{{> this.newItemsLink}}"}
return CommentViewHeader}(JView)

var CommentListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CommentListItemView=function(_super){function CommentListItemView(options,data){var activity,deleterId,loggedInId,origin,originId,originType,_ref,_this=this
options.type||(options.type="comment")
options.cssClass||(options.cssClass="kdlistitemview kdlistitemview-comment")
CommentListItemView.__super__.constructor.call(this,options,data)
data=this.getData()
originId=data.getAt("originId")
originType=data.getAt("originType")
deleterId=null!=(_ref=data.getAt("deletedBy"))?"function"==typeof _ref.getId?_ref.getId():void 0:void 0
origin={constructorName:originType,id:originId}
this.avatar=new AvatarView({size:{width:options.avatarWidth||40,height:options.avatarHeight||40},origin:origin,showStatus:!0})
this.author=new ProfileLinkView({origin:origin})
null!=deleterId&&deleterId!==originId&&(this.deleter=new ProfileLinkView({},data.getAt("deletedBy")))
this.deleteLink=new KDCustomHTMLView({tagName:"a",attributes:{href:"#"},cssClass:"delete-link hidden"})
activity=this.getDelegate().getData()
loggedInId=KD.whoami().getId()
if(loggedInId===data.originId||loggedInId===activity.originId||KD.checkFlag("super-admin",KD.whoami())){this.deleteLink.unsetClass("hidden")
this.deleteLink.on("click",function(){return _this.confirmDeleteComment(data)})}this.likeView=new LikeViewClean({tooltipPosition:"sw",checkIfLikedBefore:!0},data)
this.replyView=loggedInId!==data.originId?new ActivityActionLink({cssClass:"action-link reply-link",partial:"Mention",click:function(){return KD.remote.cacheable(data.originType,data.originId,function(err,res){return _this.getDelegate().emit("ReplyLinkClicked",res.profile.nickname)})}}):new KDView({tagName:"span"})
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)
KD.checkFlag("exempt")||data.on("ContentMarkedAsLowQuality",this.bound("hide"))
data.on("ContentUnmarkedAsLowQuality",this.bound("show"))}__extends(CommentListItemView,_super)
CommentListItemView.prototype.applyTooltips=function(){return this.$("p.status-body > span.data > a").each(function(i,element){var href,twOptions
href=$(element).attr("data-original-url")||$(element).attr("href")||""
twOptions=function(title){return{title:title,placement:"above",offset:3,delayIn:300,html:!0,animate:!0,className:"link-expander"}}
return"_blank"===$(element).attr("target")?$(element).twipsy(twOptions("External Link : <span>"+href+"</span>")):void 0})}
CommentListItemView.prototype.render=function(){this.getData().getAt("deletedAt")&&this.emit("CommentIsDeleted")
this.updateTemplate()
this.applyTooltips()
return CommentListItemView.__super__.render.apply(this,arguments)}
CommentListItemView.prototype.viewAppended=function(){this.updateTemplate(!0)
this.template.update()
return this.applyTooltips()}
CommentListItemView.prototype.click=function(event){var originId,originType,_ref
KD.utils.showMoreClickHandler.call(this,event)
if($(event.target).is("span.avatar a, a.user-fullname")){_ref=this.getData(),originType=_ref.originType,originId=_ref.originId
return KD.remote.cacheable(originType,originId,function(err,origin){return err?void 0:KD.getSingleton("router").handleRoute("/"+origin.profile.nickname,{state:origin})})}}
CommentListItemView.prototype.confirmDeleteComment=function(data){var modal,type
type=this.getOptions().type
return modal=new KDModalView({title:"Delete "+type,content:"<div class='modalformline'>Are you sure you want to delete this "+type+"?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return data["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
return err?new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"}):void 0})}},cancel:{style:"modal-cancel",callback:function(){return modal.destroy()}}}})}
CommentListItemView.prototype.updateTemplate=function(force){var pistachio,type
null==force&&(force=!1)
if(this.getData().getAt("deletedAt")){type=this.getOptions().type
this.setClass("deleted")
pistachio=this.deleter?"<div class='item-content-comment clearfix'><span>{{> this.author}}'s "+type+" has been deleted by {{> this.deleter}}.</span></div>":"<div class='item-content-comment clearfix'><span>{{> this.author}}'s "+type+" has been deleted.</span></div>"
return this.setTemplate(pistachio)}return force?this.setTemplate(this.pistachio()):void 0}
CommentListItemView.prototype.pistachio=function(){return"{{> this.avatar}}\n<div class='comment-contents clearfix'>\n  {{> this.author}}\n  <p class='comment-body'>\n    {{this.utils.applyTextExpansions(#(body), true)}}\n  </p>\n  {{> this.deleteLink}}\n  {{> this.likeView}}\n  {{> this.replyView}}\n  {{> this.timeAgoView}}\n</div>"}
return CommentListItemView}(KDListItemView)

var NewCommentForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NewCommentForm=function(_super){function NewCommentForm(options,data){null==options&&(options={})
options.type||(options.type="new-comment")
options.cssClass||(options.cssClass="item-add-comment-box")
options.itemTypeString||(options.itemTypeString="comment")
NewCommentForm.__super__.constructor.call(this,options,data)}__extends(NewCommentForm,_super)
NewCommentForm.prototype.viewAppended=function(){var commentFormWrapper,commenterAvatar,itemTypeString
this.addSubView(commenterAvatar=new AvatarStaticView({size:{width:35,height:35}},KD.whoami()))
this.addSubView(commentFormWrapper=new KDView({cssClass:"item-add-comment-form"}))
itemTypeString=this.getOptions().itemTypeString
commentFormWrapper.addSubView(this.commentInput=new KDHitEnterInputView({type:"textarea",delegate:this,placeholder:"Type your "+itemTypeString+" and hit enter...",autogrow:!0,validate:{rules:{required:!0,maxLength:2e3},messages:{required:"Please type a "+itemTypeString+"..."}},callback:this.bound("commentInputReceivedEnter")}))
return this.attachListeners()}
NewCommentForm.prototype.attachListeners=function(){var _this=this
this.commentInput.on("blur",this.bound("commentInputReceivedBlur"))
return this.commentInput.on("focus",function(){return _this.getDelegate().emit("commentInputReceivedFocus")})}
NewCommentForm.prototype.makeCommentFieldActive=function(){this.getDelegate().emit("commentInputReceivedFocus")
return KD.getSingleton("windowController").setKeyView(this.commentInput)}
NewCommentForm.prototype.resetCommentField=function(){return this.getDelegate().emit("CommentViewShouldReset")}
NewCommentForm.prototype.otherCommentInputReceivedFocus=function(instance){var commentForm
if(instance!==this.commentInput){commentForm=this.commentInput.getDelegate()
if(""===$.trim(this.commentInput.getValue()))return commentForm.resetCommentField()}}
NewCommentForm.prototype.commentInputReceivedBlur=function(){return""===this.commentInput.getValue()?this.resetCommentField():void 0}
NewCommentForm.prototype.commentInputReceivedEnter=function(){var _this=this
return KD.requireMembership({callback:function(){var reply
reply=_this.commentInput.getValue()
_this.commentInput.setValue("")
_this.commentInput.resize()
_this.commentInput.blur()
_this.commentInput.$().blur()
return _this.getDelegate().emit("CommentSubmitted",reply)},onFailMsg:"Login required to post a comment!",tryAgain:!0,groupName:this.getDelegate().getData().group})}
return NewCommentForm}(KDView)

var ReviewView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ReviewView=function(_super){function ReviewView(options,data){ReviewView.__super__.constructor.apply(this,arguments)
this.setClass("review-container")
this.createSubViews(data)
this.decorateCommentedState()
this.attachListeners()}__extends(ReviewView,_super)
ReviewView.prototype.render=function(){return this.decorateCommentedState()}
ReviewView.prototype.createSubViews=function(data){var showMore,_this=this
this.reviewList=new KDListView({type:"comments",itemClass:ReviewListItemView,delegate:this,lastToFirst:!0},data)
this.commentController=new ReviewListViewController({view:this.reviewList})
this.addSubView(this.commentForm=new NewReviewForm({delegate:this.reviewList}))
this.addSubView(this.commentController.getView())
this.addSubView(showMore=new CommentViewHeader({delegate:this.reviewList,itemTypeString:"review"},data))
this.reviewList.on("OwnCommentHasArrived",function(){return showMore.ownCommentArrived()})
this.reviewList.on("ReviewIsDeleted",function(){return showMore.ownCommentDeleted()})
data.fetchRelativeReviews({limit:3,after:"meta.createdAt"},function(err,reviews){var review,_i,_len,_ref,_results
_ref=reviews.reverse()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){review=_ref[_i]
_results.push(_this.reviewList.addItem(review))}return _results})
return this.reviewList.emit("BackgroundActivityFinished")}
ReviewView.prototype.attachListeners=function(){var _this=this
this.reviewList.on("commentInputReceivedFocus",this.bound("decorateActiveCommentState"))
this.reviewList.on("CommentLinkReceivedClick",function(){return _this.commentForm.commentInput.setFocus()})
return this.reviewList.on("CommentCountClicked",function(){return _this.reviewList.emit("AllCommentsLinkWasClicked")})}
ReviewView.prototype.decorateNoCommentState=function(){this.unsetClass("active-comment")
this.unsetClass("commented")
return this.setClass("no-comment")}
ReviewView.prototype.decorateCommentedState=function(){this.unsetClass("active-comment")
this.unsetClass("no-comment")
return this.setClass("commented")}
ReviewView.prototype.decorateActiveCommentState=function(){this.unsetClass("commented")
this.unsetClass("no-comment")
return this.setClass("active-comment")}
ReviewView.prototype.decorateItemAsLiked=function(likeObj){var _ref;(null!=likeObj?null!=(_ref=likeObj.results)?_ref.likeCount:void 0:void 0)>0?this.setClass("liked"):this.unsetClass("liked")
return this.ActivityActionsView.setLikedCount(likeObj)}
return ReviewView}(KDView)

var ReviewListViewController,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ReviewListViewController=function(_super){function ReviewListViewController(){ReviewListViewController.__super__.constructor.apply(this,arguments)
this._hasBackgrounActivity=!1
this.startListeners()}__extends(ReviewListViewController,_super)
ReviewListViewController.prototype.instantiateListItems=function(items,keepDeletedReviews){var i,newItems,nextReview,review,reviewView,skipReview,_i,_len
null==keepDeletedReviews&&(keepDeletedReviews=!1)
newItems=[]
for(i=_i=0,_len=items.length;_len>_i;i=++_i){review=items[i]
nextReview=items[i+1]
skipReview=!1
null!=nextReview&&review.deletedAt&&Date.parse(nextReview.meta.createdAt)>Date.parse(review.deletedAt)&&(skipReview=!0)
!nextReview&&review.deletedAt&&(skipReview=!0)
keepDeletedReviews&&(skipReview=!1)
if(!skipReview){reviewView=this.getListView().addItem(review)
newItems.push(reviewView)}}return newItems}
ReviewListViewController.prototype.startListeners=function(){var listView,_this=this
listView=this.getListView()
listView.on("ItemWasAdded",function(view){return view.on("CommentIsDeleted",function(){return listView.emit("CommentIsDeleted")})})
this.offset=3
listView.on("AllCommentsLinkWasClicked",function(reviewHeader){var loadComments,meta
_this.reviewHeader=reviewHeader
if(!_this._hasBackgrounActivity){_this.utils.wait(5e3,function(){return listView.emit("BackgroundActivityFinished")})
meta=listView.getData().meta
listView.emit("BackgroundActivityStarted")
_this._hasBackgrounActivity=!0
_this._removedBefore=!1
loadComments=10
_this.fetchRelativeReviews(_this.offset,loadComments,meta.createdAt)
return _this.offset+=loadComments}})
return listView.on("ReviewSubmitted",function(review){var model
model=listView.getData()
listView.emit("BackgroundActivityStarted")
return model.review(review,function(err,review){var _ref
if(!(null!=(_ref=KD.getSingleton("activityController").flags)?_ref.liveUpdates:void 0)){listView.addItem(review)
listView.emit("OwnCommentHasArrived")}return listView.emit("BackgroundActivityFinished")})})}
ReviewListViewController.prototype.fetchAllReviews=function(skipCount,callback){var listView,message
null==skipCount&&(skipCount=3)
null==callback&&(callback=noop)
listView=this.getListView()
listView.emit("BackgroundActivityStarted")
message=this.getListView().getData()
return message.restReviews(skipCount,function(err,reivews){listView.emit("BackgroundActivityFinished")
return callback(err,reivews)})}
ReviewListViewController.prototype.fetchRelativeReviews=function(_offset,_limit,_after){var listView,message,_this=this
null==_offset&&(_offset=0)
null==_limit&&(_limit=10)
listView=this.getListView()
message=this.getListView().getData()
listView.setOption("lastToFirst",!1)
return message.fetchRelativeReviews({offset:_offset,limit:_limit,after:_after},function(err,reivews){var allItemsLink,repliesCount
_this._removedBefore||(_this._removedBefore=!0)
_this.instantiateListItems(reivews,!0)
listView=_this.getListView()
listView.emit("BackgroundActivityFinished")
allItemsLink=_this.reviewHeader.allItemsLink
repliesCount=allItemsLink.getData().repliesCount
allItemsLink.setData({repliesCount:repliesCount-_limit})
allItemsLink.render()
_offset+_limit>=_this.reviewHeader.oldCount&&listView.emit("AllCommentsWereAdded")
_this._hasBackgrounActivity=!1
return listView.setOption("lastToFirst",!0)})}
ReviewListViewController.prototype.replaceAllReviews=function(reivews){this.removeAllItems()
return this.instantiateListItems(reivews)}
return ReviewListViewController}(KDListViewController)

var ReviewListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ReviewListItemView=function(_super){function ReviewListItemView(options,data){options=$.extend({type:"review"},options)
ReviewListItemView.__super__.constructor.call(this,options,data)
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(ReviewListItemView,_super)
ReviewListItemView.prototype.pistachio=function(){return"<div class='item-content-review clearfix'>\n  <span class='avatar'>{{> this.avatar}}</span>\n  <div class='review-contents clearfix'>\n    <p class='review-body'>\n      {{this.utils.applyTextExpansions(#(body), true)}}\n    </p>\n    {{> this.deleteLink}}\n    <span class='footer'>\n      {{> this.author}} reviewed {{> this.timeAgoView}}\n      {{> this.likeView}}\n    </span>\n  </div>\n</div>"}
return ReviewListItemView}(CommentListItemView)

var NewReviewForm,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
NewReviewForm=function(_super){function NewReviewForm(options,data){options.itemTypeString="review"
options.cssClass="item-add-review-box"
NewReviewForm.__super__.constructor.call(this,options,data)}__extends(NewReviewForm,_super)
NewReviewForm.prototype.commentInputReceivedEnter=function(){var _this=this
return KD.requireMembership({callback:function(){var review
review=_this.commentInput.getValue()
_this.commentInput.setValue("")
_this.commentInput.blur()
_this.commentInput.$().blur()
return _this.getDelegate().emit("ReviewSubmitted",review)},onFailMsg:"Login required to post a review!",tryAgain:!0,groupName:this.getDelegate().getData().group})}
return NewReviewForm}(NewCommentForm)

var ActivityInputView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityInputView=function(_super){function ActivityInputView(options,data){null==options&&(options={})
options.cssClass=KD.utils.curry("input-view",options.cssClass)
options.type||(options.type="html")
null==options.multiline&&(options.multiline=!0)
options.placeholder||(options.placeholder="What's new "+KD.whoami().profile.firstName+"?")
options.tokenViewClass||(options.tokenViewClass=TokenView)
options.rules||(options.rules={tag:{type:"tag",prefix:"#",pistachio:"#{{#(title)}}",dataSource:this.bound("fetchTopics")}})
ActivityInputView.__super__.constructor.call(this,options,data)
this.defaultTokens=initializeDefaultTokens()}var JTag,fillTokenMap,initializeDefaultTokens
__extends(ActivityInputView,_super)
JTag=KD.remote.api.JTag
ActivityInputView.prototype.fetchTopics=function(inputValue){var _this=this
return KD.getSingleton("appManager").tell("Topics","fetchTopics",{inputValue:inputValue},function(tags){var matches
null==tags&&(tags=[])
matches=[]
if(inputValue.length>1){matches=tags.filter(function(tag){return tag.title===inputValue})
matches.length||(tags=[{$suggest:inputValue}].concat(tags))}return _this.showMenu({suggest:0===matches.length?inputValue:"",itemChildClass:TagContextMenuItem},tags)})}
ActivityInputView.prototype.menuItemClicked=function(item){var tokenViewClass
item.data.$suggest&&(tokenViewClass=SuggestedTokenView)
return ActivityInputView.__super__.menuItemClicked.call(this,item,tokenViewClass)}
ActivityInputView.prototype.setDefaultTokens=function(defaultTokens){null==defaultTokens&&(defaultTokens={})
this.defaultTokens=initializeDefaultTokens()
return fillTokenMap(defaultTokens.tags,this.defaultTokens.tags)}
initializeDefaultTokens=function(){return{tags:{}}}
ActivityInputView.prototype.setContent=function(content,activity){var tokens,_ref
tokens=this.defaultTokens||initializeDefaultTokens();(null!=activity?null!=(_ref=activity.tags)?_ref.length:void 0:void 0)&&fillTokenMap(activity.tags,tokens.tags)
return ActivityInputView.__super__.setContent.call(this,this.renderTokens(content,tokens))}
ActivityInputView.prototype.sanitizeInput=function(){var prefix,value,words
prefix=this.activeRule.prefix
value=this.tokenInput.textContent.substring(prefix.length)
words=value.split(/\W/,3)
this.tokenInput.textContent=prefix+words.join("-")
return this.utils.selectEnd(this.tokenInput)}
ActivityInputView.prototype.selectToken=function(){var prefix,token,tokens,value,_i,_len
if(this.menu){prefix=this.activeRule.prefix
value=this.tokenInput.textContent.substring(prefix.length).toLowerCase()
tokens=this.menu.getData().filter(this.getTokenFilter())
for(_i=0,_len=tokens.length;_len>_i;_i++){token=tokens[_i]
if(value===token.title.toLowerCase()){this.addToken(token,this.getOptions().tokenViewClass)
this.hideMenu()
return!0}}}}
ActivityInputView.prototype.keyDown=function(event){ActivityInputView.__super__.keyDown.apply(this,arguments)
if(!event.isPropagationStopped()){switch(event.which){case 27:this.emit("Escape")}return/\s/.test(String.fromCharCode(event.which))&&this.selectToken()?KD.utils.stopDOMEvent(event):void 0}}
ActivityInputView.prototype.focus=function(){var childNodes,content,value
if(!this.focused){ActivityInputView.__super__.focus.apply(this,arguments)
value=this.getValue()
if(!value){content=this.prefixDefaultTokens()
if(!content)return
this.setContent(content)
childNodes=this.getEditableElement().childNodes
return this.utils.selectEnd(childNodes[childNodes.length-1])}}}
ActivityInputView.prototype.prefixDefaultTokens=function(){var constructorName,content,key,prefix,token,tokens,type,_ref
content=""
_ref=this.defaultTokens
for(type in _ref)if(__hasProp.call(_ref,type)){tokens=_ref[type]
switch(type){case"tags":prefix="#"
constructorName="JTag"
break
default:continue}for(key in tokens){token=tokens[key]
content+="|"+prefix+":"+constructorName+":"+token.getId()+"|&nbsp;"}}return content}
ActivityInputView.prototype.renderTokens=function(content,tokens){var _this=this
null==tokens&&(tokens={})
return content.replace(/\|(.*?):(.*?):(.*?)\|/g,function(match,prefix,constructorName,id){var data,itemClass,pistachio,tokenKey,tokenView,type
switch(prefix){case"#":itemClass=TagLinkView
type="tag"
pistachio=""+prefix+"{{#(title)}}"
data=tokens.tags[id]}tokenView=new TokenView({itemClass:itemClass,prefix:prefix,type:type,pistachio:pistachio},data)
tokenKey=""+tokenView.getId()+"-"+tokenView.getKey()
_this.tokenViews[tokenKey]=tokenView
tokenView.setAttributes({"data-key":tokenKey})
tokenView.emit("viewAppended")
return tokenView.getElement().outerHTML})}
ActivityInputView.prototype.getTokenFilter=function(){switch(this.activeRule.prefix){case"#":return function(token){return token instanceof JTag}
default:return noop}}
fillTokenMap=function(tokens,map){return tokens.forEach(function(token){return map[token.getId()]=token})}
return ActivityInputView}(KDTokenizedInput)

var ActivityEditWidget,ActivityInputWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityInputWidget=function(_super){function ActivityInputWidget(options,data){var _this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("activity-input-widget",options.cssClass)
ActivityInputWidget.__super__.constructor.call(this,options,data)
null==options.destroyOnSubmit&&(options.destroyOnSubmit=!1)
this.input=new ActivityInputView({defaultValue:options.defaultValue})
this.input.on("Escape",this.bound("reset"))
this.notification=new KDView({cssClass:"notification hidden",partial:'This is a sneak peek beta for testing purposes only. If you find any bugs, please post them here on the activity feed with the tag #bug. Beware that your activities could be discarded.<br><br>\n\nPlease take a short survey about <a href="http://bit.ly/1jsjlna">New Koding.</a><br><br>\n\nWith love from the Koding team.<br>'})
this.notification.addSubView(new KDCustomHTMLView({tagName:"span",cssClass:"close-tab",click:function(){return _this.notification.destroy()}}))
this.embedBox=new EmbedBoxWidget({delegate:this.input},data)
this.submit=new KDButtonView({type:"submit",cssClass:"solid green",iconOnly:!0,callback:this.bound("submit")})
this.avatar=new AvatarView({size:{width:35,height:35}},KD.whoami())}var JNewStatusUpdate,JTag,daisy,dash,_ref
__extends(ActivityInputWidget,_super)
daisy=Bongo.daisy,dash=Bongo.dash
_ref=KD.remote.api,JNewStatusUpdate=_ref.JNewStatusUpdate,JTag=_ref.JTag
ActivityInputWidget.prototype.submit=function(callback){var activity,createdTags,data,queue,suggestedTags,tags,token,type,value,_i,_len,_ref1,_this=this
if(value=this.input.getValue().trim()){activity=this.getData()
null!=activity&&(activity.tags=[])
tags=[]
suggestedTags=[]
createdTags={}
if(!KD.checkFlag("exempt")){_ref1=this.input.getTokens()
for(_i=0,_len=_ref1.length;_len>_i;_i++){token=_ref1[_i]
data=token.data,type=token.type
if("tag"===type)if(data instanceof JTag){tags.push({id:data.getId()})
null!=activity&&activity.tags.push(data)}else data.$suggest&&suggestedTags.push(data.$suggest)}}return daisy(queue=[function(){var tagCreateJobs
tagCreateJobs=suggestedTags.map(function(title){return function(){return JTag.create({title:title},function(err,tag){null!=activity&&activity.tags.push(tag)
tags.push({id:tag.getId()})
createdTags[title]=tag
return tagCreateJobs.fin()})}})
return dash(tagCreateJobs,function(){return queue.next()})},function(){var body,fn
body=_this.encodeTagSuggestions(value,createdTags)
data={group:KD.getSingleton("groupsController").getGroupSlug(),body:body,meta:{tags:tags}}
data.link_url=_this.embedBox.url||""
data.link_embed=_this.embedBox.getDataForSubmit()||{}
_this.lockSubmit()
fn=_this.bound(activity?"update":"create")
return fn(data,function(err,activity){_this.reset(!0)
_this.embedBox.resetEmbedAndHide()
_this.emit("Submit",err,activity)
_this.getOptions().destroyOnSubmit&&_this.destroy()
_this.notification.show()
return"function"==typeof callback?callback(err,activity):void 0})}])}}
ActivityInputWidget.prototype.encodeTagSuggestions=function(str,tags){return str.replace(/\|(.*?):\$suggest:(.*?)\|/g,function(match,prefix,title){var tag
tag=tags[title]
return tag?"|"+prefix+":JTag:"+tag.getId()+"|":""})}
ActivityInputWidget.prototype.create=function(data,callback){var _this=this
return JNewStatusUpdate.create(data,function(err,activity){err||_this.reset()
"function"==typeof callback&&callback(err,activity)
err&&KD.showError(err,{AccessDenied:{title:"You are not allowed to post activity",content:"This activity will only be visible to you",duration:5e3},KodingError:"Something went wrong while creating activity"})
return KD.getSingleton("badgeController").checkBadge({property:"statusUpdates",relType:"author",source:"JNewStatusUpdate",targetSelf:1})})}
ActivityInputWidget.prototype.update=function(data,callback){var activity,_this=this
activity=this.getData()
return activity?activity.modify(data,function(err){KD.showError(err)
err||_this.reset()
return"function"==typeof callback?callback(err):void 0}):this.reset()}
ActivityInputWidget.prototype.reset=function(lock){null==lock&&(lock=!0)
this.input.setContent("")
this.input.blur()
this.embedBox.resetEmbedAndHide()
this.submit.focus()
setTimeout(this.bound("unlockSubmit"),8e3)
this.setData(null)
return lock?this.unlockSubmit():void 0}
ActivityInputWidget.prototype.lockSubmit=function(){return this.submit.disable()}
ActivityInputWidget.prototype.unlockSubmit=function(){return this.submit.enable()}
ActivityInputWidget.prototype.viewAppended=function(){this.addSubView(this.avatar)
this.addSubView(this.input)
this.addSubView(this.notification)
this.addSubView(this.embedBox)
this.input.addSubView(this.submit)
return KD.isLoggedIn()?void 0:this.hide()}
return ActivityInputWidget}(KDView)
ActivityEditWidget=function(_super){function ActivityEditWidget(options){null==options&&(options={})
options.cssClass=KD.utils.curry("edit-widget",options.cssClass)
options.destroyOnSubmit=!0
ActivityEditWidget.__super__.constructor.call(this,options)
this.submit=new KDButtonView({type:"submit",cssClass:"solid green",iconOnly:!1,title:"Done editing",callback:this.bound("submit")})
this.cancel=new KDButtonView({cssClass:"solid gray",title:"Cancel",callback:this.bound("cancel")})}__extends(ActivityEditWidget,_super)
ActivityEditWidget.prototype.cancel=function(){this.destroy()
return this.emit("ActivityInputCancelled")}
ActivityEditWidget.prototype.edit=function(activity){var content
this.setData(activity)
content=activity.body.replace(/\n/g,"<br>")
this.input.setContent(content,activity)
return activity.link?this.embedBox.loadEmbed(activity.link.link_url):void 0}
ActivityEditWidget.prototype.viewAppended=function(){this.addSubView(this.input)
this.addSubView(this.embedBox)
this.input.addSubView(this.submit)
return this.input.addSubView(this.cancel)}
return ActivityEditWidget}(ActivityInputWidget)

var ActivitySettingsView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivitySettingsView=function(_super){function ActivitySettingsView(options,data){var account,activityController,button
null==options&&(options={})
null==data&&(data={})
ActivitySettingsView.__super__.constructor.call(this,options,data)
data=this.getData()
account=KD.whoami()
this.settings=data.originId===account.getId()||KD.checkFlag("super-admin")||KD.hasAccess("delete posts")?button=new KDButtonViewWithMenu({cssClass:"activity-settings-menu",itemChildClass:ActivityItemMenuItem,title:"",icon:!0,delegate:this,iconClass:"arrow",menu:this.settingsMenu(data),callback:function(event){return button.contextMenu(event)}}):new KDCustomHTMLView({tagName:"span",cssClass:"hidden"})
activityController=KD.getSingleton("activityController")}__extends(ActivitySettingsView,_super)
ActivitySettingsView.prototype.settingsMenu=function(post){var account,menu,_this=this
account=KD.whoami()
if(post.originId===account.getId()){menu={Edit:{callback:function(){return _this.emit("ActivityEditIsClicked")}},Delete:{callback:function(){return _this.confirmDeletePost(post)}}}
return menu}if(KD.checkFlag("super-admin")||KD.hasAccess("delete posts")){menu=KD.checkFlag("exempt",account)?{"Unmark User as Troll":{callback:function(){return activityController.emit("ActivityItemUnMarkUserAsTrollClicked",post)}}}:{"Mark User as Troll":{callback:function(){return activityController.emit("ActivityItemMarkUserAsTrollClicked",post)}}}
menu["Delete Post"]={callback:function(){return _this.confirmDeletePost(post)}}
menu["Block User"]={callback:function(){return activityController.emit("ActivityItemBlockUserClicked",post.originId)}}
menu["Add System Tag"]={callback:function(){return _this.selectSystemTag(post)}}
return menu}}
ActivitySettingsView.prototype.viewAppended=function(){return this.addSubView(this.settings)}
ActivitySettingsView.prototype.confirmDeletePost=function(post){var modal,_this=this
modal=new KDModalView({title:"Delete post",content:"<div class='modalformline'>Are you sure you want to delete this post?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){if(!post.fake)return post["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
return err?new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"}):_this.emit("ActivityIsDeleted")})
_this.emit("ActivityIsDeleted")
modal.buttons.Delete.hideLoader()
modal.destroy()}},Cancel:{style:"modal-cancel",title:"cancel",callback:function(){return modal.destroy()}}}})
return modal.buttons.Delete.blur()}
ActivitySettingsView.prototype.selectSystemTag=function(){var modal,systemTags
modal=new KDModalView({title:"Add Systen Tag",height:"auto",content:"Coming Soon",overlay:!1,buttons:{Cancel:{style:"modal-cancel",title:"cancel",callback:function(){return modal.destroy()}}}})
systemTags=new KDMultipleChoice({cssClass:"clean-gray editor-button control-button bug",labels:["changelog","fixed"],multiple:!1,size:"tiny",callback:function(value){return log(value)}})
return modal.addSubView(systemTags)}
return ActivitySettingsView}(KDCustomHTMLView)

var ActivityUpdateWidgetController,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityUpdateWidgetController=function(_super){function ActivityUpdateWidgetController(){_ref=ActivityUpdateWidgetController.__super__.constructor.apply(this,arguments)
return _ref}var notifySubmissionStopped,stopSubmission,submissionStopped
__extends(ActivityUpdateWidgetController,_super)
submissionStopped=!1
notifySubmissionStopped=function(){}
stopSubmission=function(){}
ActivityUpdateWidgetController.prototype.loadView=function(mainView){var activityController,paneMap,switchForEditView,widgetController,_this=this
activityController=KD.getSingleton("activityController")
paneMap=[{name:"statusUpdatePane",paneName:"update",cssClass:"status-widget",constructorName:"JNewStatusUpdate",widgetName:"updateWidget",widgetType:ActivityStatusUpdateWidget}]
widgetController=this
paneMap.forEach(function(pane){return _this[pane.name]=mainView.addWidgetPane({paneName:pane.paneName,mainContent:_this[pane.widgetName]=new pane.widgetType({pane:pane,cssClass:pane.cssClass||""+pane.paneName+"-widget",callback:function(formData){var _ref1
if(submissionStopped)return notifySubmissionStopped()
widgetController.widgetSubmit(formData,this.getOptions().pane.constructorName,stopSubmission)
"JNewStatusUpdate"===(_ref1=this.getOptions().pane.constructorName)&&widgetController[this.getOptions().pane.widgetName].switchToSmallView()
return mainView.resetWidgets()}})})})
mainView.showPane("update")
this.codeSnippetPane.on("PaneDidShow",function(){return _this.codeWidget.widgetShown()})
switchForEditView=function(type,data,fake){null==fake&&(fake=!1)
switch(type){case"JNewStatusUpdate":mainView.showPane("update")
return _this.updateWidget.switchToEditView(data,fake)}}
this.on("editFromFakeData",function(fakeData){return switchForEditView(fakeData.fakeType,fakeData,!0)})
return KD.getSingleton("mainController").on("ActivityItemEditLinkClicked",function(activity){KD.getSingleton("appManager").open("Activity")
mainView.setClass("edit-mode")
return switchForEditView(activity.bongo_.constructorName,activity)})}
ActivityUpdateWidgetController.prototype.widgetSubmit=function(data,constructorName,callback){var activity,field,key,updateTimeout,_ref1,_ref2,_this=this
for(key in data)if(__hasProp.call(data,key)){field=data[key]
_.isString(field)&&(data[key]=field.replace(/&quot;/g,'"'))}KD.checkFlag("exempt")&&null!=(_ref1=data.meta)&&(_ref1.tags=[])
if(data.activity){activity=data.activity
delete data.activity
return activity.modify(data,function(err,res){"function"==typeof callback&&callback(err,res)
return err?new KDNotificationView({type:"mini",title:err.message}):new KDNotificationView({type:"mini",title:"Updated successfully"})})}updateTimeout=this.utils.wait(2e4,function(){return _this.emit("OwnActivityHasFailed",data)})
data.group=KD.getSingleton("groupsController").getGroupSlug()
return null!=(_ref2=KD.remote.api[constructorName])?_ref2.create(data,function(err,activity){"function"==typeof callback&&callback(err,activity)
KD.showError(err,{AccessDenied:{title:"You are not allowed to create activities",content:"This activity will only be visible to you",duration:5e3},KodingError:"Something went wrong while creating activity"})
if(err)return _this.emit("OwnActivityHasFailed",data)
_this.utils.killWait(updateTimeout)
return _this.emit("OwnActivityHasArrived",activity)}):void 0}
return ActivityUpdateWidgetController}(KDViewController)

var ActivityUpdateWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityUpdateWidget=function(_super){function ActivityUpdateWidget(options,data){null==options&&(options={})
options.domId="activity-update-widget"
options.cssClass="activity-update-widget-wrapper"
ActivityUpdateWidget.__super__.constructor.call(this,options,data)
this.windowController=KD.getSingleton("windowController")}__extends(ActivityUpdateWidget,_super)
ActivityUpdateWidget.prototype.setMainSections=function(){var widgetWrapper,_this=this
this.updatePartial("")
this.addSubView(widgetWrapper=new KDView({cssClass:"widget-holder clearfix"}))
widgetWrapper.addSubView(this.widgetButton=new WidgetButton(this.widgetOptions()))
widgetWrapper.addSubView(this.mainInputTabs=new KDTabView({height:"auto",cssClass:"update-widget-tabs"}))
this.mainInputTabs.hideHandleContainer()
this.on("WidgetTabChanged",function(){return _this.windowController.addLayer(_this.mainInputTabs)})
this.mainInputTabs.on("ResetWidgets",function(isHardReset){return _this.resetWidgets(isHardReset)})
return this.mainInputTabs.on("ReceivedClickElsewhere",function(event){return $(event.target).closest(".activity-status-context").length>0||$(event.target).closest(".kdmodal").length>0?void 0:_this.resetWidgets()})}
ActivityUpdateWidget.prototype.resetWidgets=function(isHardReset){this.windowController.removeLayer(this.mainInputTabs)
this.unsetClass("edit-mode")
this.changeTab("update","Status Update")
return this.mainInputTabs.emit("MainInputTabsReset",isHardReset)}
ActivityUpdateWidget.prototype.addWidgetPane=function(options){var main,mainContent,paneName
paneName=options.paneName,mainContent=options.mainContent
this.mainInputTabs.addPane(main=new KDTabPaneView({name:paneName}))
null!=mainContent&&main.addSubView(mainContent)
return main}
ActivityUpdateWidget.prototype.changeTab=function(tabName){this.showPane(tabName)
return this.emit("WidgetTabChanged",tabName)}
ActivityUpdateWidget.prototype.showPane=function(paneName){return this.mainInputTabs.showPane(this.mainInputTabs.getPaneByName(paneName))}
ActivityUpdateWidget.prototype.viewAppended=function(){this.setMainSections()
return ActivityUpdateWidget.__super__.viewAppended.apply(this,arguments)}
ActivityUpdateWidget.prototype._windowDidResize=function(){var width
width=this.getWidth()
return this.$(".form-headline, form.status-update-input").width(width-185)}
ActivityUpdateWidget.prototype.widgetOptions=function(){return{delegate:this,items:{"Status Update":{type:"update"},"Blog Post":{type:"blogpost"},"Code Snip":{type:"codesnip"},Discussion:{type:"discussion",disabled:!0},Tutorial:{type:"tutorial",disabled:!0}}}}
return ActivityUpdateWidget}(KDView)

var WidgetButton,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
WidgetButton=function(_super){function WidgetButton(options){options.cssClass="update-type-select-icons"
WidgetButton.__super__.constructor.call(this,options)}__extends(WidgetButton,_super)
WidgetButton.prototype.viewAppended=function(){var content,delegate,icon,items,title,_ref,_results
_ref=this.getOptions(),items=_ref.items,delegate=_ref.delegate
_results=[]
for(title in items)if(__hasProp.call(items,title)){content=items[title]
this.addSubView(icon=new KDCustomHTMLView({cssClass:""+this.utils.slugify(content.type),type:content.type,title:title,click:function(){return delegate.changeTab(this.getOption("type"),this.getOption("title"))}}))
content.disabled?_results.push(icon.setClass("hidden")):_results.push(void 0)}return _results}
return WidgetButton}(KDCustomHTMLView)

var ActivityWidgetFormView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityWidgetFormView=function(_super){function ActivityWidgetFormView(options,data){var _this=this
ActivityWidgetFormView.__super__.constructor.apply(this,arguments)
this.labelAddTags=new KDLabelView({title:"Add Tags:"})
this.selectedItemWrapper=new KDCustomHTMLView({tagName:"div",cssClass:"tags-selected-item-wrapper clearfix"})
this.tagController=new TagAutoCompleteController({name:"meta.tags",type:"tags",itemClass:TagAutoCompleteItemView,selectedItemClass:TagAutoCompletedItemView,outputWrapper:this.selectedItemWrapper,selectedItemsLimit:5,listWrapperCssClass:"tags",itemDataPath:"title",form:this,dataSource:function(args,callback){var blacklist,inputValue,updateWidget
inputValue=args.inputValue
updateWidget=_this.getDelegate()
blacklist=function(){var _i,_len,_ref,_results
_ref=this.tagController.getSelectedItemData()
_results=[]
for(_i=0,_len=_ref.length;_len>_i;_i++){data=_ref[_i]
"function"==typeof data.getId&&_results.push(data.getId())}return _results}.call(_this)
return KD.getSingleton("appManager").tell("Topics","fetchTopics",{inputValue:inputValue,blacklist:blacklist},callback)}})
this.tagAutoComplete=this.tagController.getView()}__extends(ActivityWidgetFormView,_super)
return ActivityWidgetFormView}(KDFormView)

var ActivityStatusUpdateWidget,InfoBox,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
ActivityStatusUpdateWidget=function(_super){function ActivityStatusUpdateWidget(options,data){var decodedName,embedOptions,name,_this=this
ActivityStatusUpdateWidget.__super__.constructor.apply(this,arguments)
name=KD.utils.getFullnameFromAccount(KD.whoami(),!0)
decodedName=Encoder.htmlDecode(name)
this.smallInput=new KDInputView({testPath:"status-update-input",cssClass:"status-update-input warn-on-unsaved-data",placeholder:"What's new "+decodedName+"?",name:"dummy",style:"input-with-extras",focus:this.bound("switchToLargeView"),validate:{rules:{maxLength:2e3}}})
this.previousURL=""
this.requestEmbedLock=!1
this.initialRequest=!0
this.largeInput=new KDInputView({cssClass:"status-update-input warn-on-unsaved-data",type:"textarea",placeholder:"What's new "+decodedName+"?",name:"body",style:"input-with-extras",validate:{rules:{required:!0,maxLength:3e3},messages:{required:"Please type a status message!"}},paste:this.bound("requestEmbed"),blur:function(){return _this.utils.wait(1e3,function(){return _this.requestEmbed()})},keyup:function(event){var which
which=$(event.which)[0]
return 32===which||9===which?_this.requestEmbed():void 0}})
this.cancelBtn=new KDButtonView({title:"Cancel",style:"modal-cancel",callback:function(){_this.reset()
return _this.parent.getDelegate().emit("ResetWidgets",!0)}})
this.submitBtn=new KDButtonView({style:"clean-gray",title:"Submit",type:"submit"})
embedOptions=$.extend({},options,{delegate:this,hasConfig:!0})
this.embedBox=new EmbedBox(embedOptions,data)
this.embedUnhideLinkWrapper=new KDView({cssClass:"unhide-embed"})
this.embedUnhideLinkWrapper.addSubView(this.embedUnhideLink=new KDCustomHTMLView({cssClass:"unhide-embed-link",tagName:"a",partial:"Re-enable embedding URLs",attributes:{href:""},click:function(event){event.preventDefault()
event.stopPropagation()
_this.embedBox.show()
_this.requestEmbedLock=!1
_this.embedUnhideLinkWrapper.hide()
return _this.embedBox.refreshEmbed()}}))
this.embedUnhideLinkWrapper.hide()
this.embedBox.on("EmbedIsHidden",function(){_this.requestEmbedLock=!0
return _this.embedUnhideLinkWrapper.show()})
this.embedBox.on("EmbedIsShown",function(){_this.requestEmbedLock=!1
return _this.embedUnhideLinkWrapper.hide()})
this.heartBox=new HelpBox({subtitle:"About Status Updates",tooltip:{title:"This is a public wall, here you can share anything with the Koding community."}})
this.inputLinkInfoBox=new InfoBox({cssClass:"protocol-info-box",delegate:this})
this.inputLinkInfoBox.hide()
this.appStorage=new AppStorage("Activity","1.0")
this.updateCheckboxFromStorage()
this.lastestStatusMessage=""}__extends(ActivityStatusUpdateWidget,_super)
ActivityStatusUpdateWidget.prototype.updateCheckboxFromStorage=function(){var _this=this
return this.appStorage.fetchValue("UrlSanitizerCheckboxIsChecked",function(checked){return _this.inputLinkInfoBox.setSwitchValue(checked)})}
ActivityStatusUpdateWidget.prototype.sanitizeUrls=function(text){var _this=this
return text.replace(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?[a-zA-Z\d\.-]+\.([a-zA-Z]{2,4}(:\d+)?)([\/\?]\S*)?\b/g,function(url){var test
test=/^([a-zA-Z]+\:\/\/)/.test(url)
if(test===!1){_this.inputLinkInfoBox.inputLinkInfoBoxPermaHide!==!0&&_this.inputLinkInfoBox.show()
return _this.inputLinkInfoBox.getSwitchValue()===!0?"http://"+url:url}return url})}
ActivityStatusUpdateWidget.prototype.requestEmbed=function(){var _this=this
this.largeInput.setValue(this.sanitizeUrls(this.largeInput.getValue()))
if(this.requestEmbedLock!==!0){this.requestEmbedLock=!0
return setTimeout(function(){var firstUrl,_ref
firstUrl=_this.largeInput.getValue().match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?[a-zA-Z\d\.-]+\.([a-zA-Z]{2,4}(:\d+)?)([\/\?]\S*)?\b/g)
if(!firstUrl)return _this.requestEmbedLock=!1
_this.initialRequest=!1
_this.embedBox.embedLinks.setLinks(firstUrl)
_this.embedBox.show()
return _ref=_this.previousURL,__indexOf.call(firstUrl,_ref)>=0?_this.requestEmbedLock=!1:_this.embedBox.embedUrl(firstUrl[0],{maxWidth:525},function(){_this.requestEmbedLock=!1
return _this.previousURL=firstUrl[0]})},50)}}
ActivityStatusUpdateWidget.prototype.switchToSmallView=function(){this.parent&&this.parent.setClass("no-shadow")
this.largeInput.setHeight(68)
this.$(">div.large-input, >div.formline").hide()
this.smallInput.show()
return this.smallInput.setValue(this.lastestStatusMessage)}
ActivityStatusUpdateWidget.prototype.switchToLargeView=function(){var tabView,_this=this
this.parent&&this.parent.unsetClass("no-shadow")
this.smallInput.hide()
this.$(">div.large-input, >div.formline").show()
this.utils.defer(function(){_this.largeInput.$().trigger("focus")
_this.largeInput.setHeight(109)
return _this.largeInput.setValue(_this.lastestStatusMessage)})
tabView=this.parent.getDelegate()
return KD.getSingleton("windowController").addLayer(tabView)}
ActivityStatusUpdateWidget.prototype.switchToEditView=function(activity,fake){var body,bodyUrls,link,selected,tags,_this=this
null==fake&&(fake=!1)
tags=activity.tags,body=activity.body,link=activity.link
this.tagController.reset()
this.tagController.setDefaultValue(tags)
if(fake)this.submitBtn.setTitle("Submit again")
else{this.submitBtn.setTitle("Edit status update")
this.addCustomData("activity",activity)}this.lastestStatusMessage=Encoder.htmlDecode(body)
this.utils.selectText(this.largeInput.$()[0])
if(null!=link&&""!==link.link_url){bodyUrls=this.largeInput.getValue().match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
if(null!=bodyUrls){selected=bodyUrls.splice(bodyUrls.indexOf(link.link_url),1)
bodyUrls.unshift(selected[0])
this.embedBox.embedLinks.setLinks(bodyUrls)}this.previousURL=link.link_url
this.embedBox.oembed=link.link_embed
this.embedBox.url=link.link_url
this.embedBox.embedExistingData(link.link_embed,{},function(){_this.embedBox.show()
return _this.embedUnhideLinkWrapper.hide()})}else this.embedBox.hide()
return this.switchToLargeView()}
ActivityStatusUpdateWidget.prototype.submit=function(){var _this=this
this.addCustomData("link_url",this.embedBox.url||"")
this.addCustomData("link_embed",this.embedBox.getDataForSubmit()||{})
this.once("FormValidationPassed",function(){KD.track("Activity","StatusUpdateSubmitted")
return _this.reset(!0)})
ActivityStatusUpdateWidget.__super__.submit.apply(this,arguments)
this.submitBtn.disable()
return this.utils.wait(5e3,function(){return _this.submitBtn.enable()})}
ActivityStatusUpdateWidget.prototype.reset=function(isHardReset){this.lastestStatusMessage=this.largeInput.getValue()
if(isHardReset){this.tagController.reset()
this.submitBtn.setTitle("Submit")
this.removeCustomData("activity")
this.removeCustomData("link_url")
this.removeCustomData("link_embed")
this.embedBox.resetEmbedAndHide()
this.previousURL=""
this.initialRequest=!0
this.inputLinkInfoBoxPermaHide=!1
this.inputLinkInfoBox.hide()
this.updateCheckboxFromStorage()}ActivityStatusUpdateWidget.__super__.reset.apply(this,arguments)
return this.largeInput.resize()}
ActivityStatusUpdateWidget.prototype.viewAppended=function(){var tabView,_this=this
this.setTemplate(this.pistachio())
this.template.update()
this.switchToSmallView()
tabView=this.parent.getDelegate()
return tabView.on("MainInputTabsReset",function(isHardReset){_this.reset(isHardReset)
return _this.switchToSmallView()})}
ActivityStatusUpdateWidget.prototype.pistachio=function(){return'<div class="small-input">{{> this.smallInput}}</div>\n<div class="large-input">\n  {{> this.largeInput}}\n  {{> this.inputLinkInfoBox}}\n  {{> this.embedUnhideLinkWrapper}}\n</div>\n{{> this.submitBtn}}'}
return ActivityStatusUpdateWidget}(ActivityWidgetFormView)
InfoBox=function(_super){function InfoBox(){var stopSanitizingToolTip,_this=this
InfoBox.__super__.constructor.apply(this,arguments)
this.inputLinkInfoBoxPermaHide=!1
stopSanitizingToolTip={title:"This feature automatically adds protocols to URLs detected in your message."}
this.stopSanitizingLabel=new KDLabelView({title:"URL auto-completion",tooltip:stopSanitizingToolTip})
this.stopSanitizingOnOffSwitch=new KDOnOffSwitch({label:this.stopSanitizingLabel,name:"stop-sanitizing",cssClass:"stop-sanitizing",tooltip:stopSanitizingToolTip,callback:function(state){return _this.getDelegate().appStorage.setValue("UrlSanitizerCheckboxIsChecked",state,function(){return state?_this.getDelegate().largeInput.setValue(_this.getDelegate().sanitizeUrls(_this.getDelegate().largeInput.getValue())):void 0})}})
this.inputLinkInfoBoxCloseButton=new KDButtonView({name:"hide-info-box",cssClass:"hide-info-box",icon:!0,iconOnly:!0,iconClass:"hide",title:"Close",callback:function(){_this.hide()
return _this.inputLinkInfoBoxPermaHide=!0}})}__extends(InfoBox,_super)
InfoBox.prototype.getSwitchValue=function(){return this.stopSanitizingOnOffSwitch.getValue()}
InfoBox.prototype.setSwitchValue=function(value){return this.stopSanitizingOnOffSwitch.setValue(value)}
InfoBox.prototype.viewAppended=function(){InfoBox.__super__.viewAppended.apply(this,arguments)
this.setTemplate(this.pistachio())
return this.template.update()}
InfoBox.prototype.pistachio=function(){return'<p>For links, please provide a protocol such as\n  <abbr title="Hypertext Transfer Protocol">http://</abbr>\n</p>\n<div class="sanitizer-control">\n  {{> this.stopSanitizingLabel}}\n  {{> this.stopSanitizingOnOffSwitch}}\n</div>\n{{> this.inputLinkInfoBoxCloseButton}}'}
return InfoBox}(KDView)

var ActivityCodeSnippetWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityCodeSnippetWidget=function(_super){function ActivityCodeSnippetWidget(){var _this=this
ActivityCodeSnippetWidget.__super__.constructor.apply(this,arguments)
this.labelTitle=new KDLabelView({title:"Title:",cssClass:"first-label"})
this.title=new KDInputView({name:"title",cssClass:"warn-on-unsaved-data",placeholder:"Give a title to your code snippet...",validate:{rules:{required:!0,maxLength:140},messages:{required:"Code snippet title is required!"}}})
this.labelDescription=new KDLabelView({title:"Description:"})
this.description=new KDInputView({label:this.labelDescription,cssClass:"warn-on-unsaved-data",name:"body",placeholder:"What is your code about?",validate:{rules:{maxLength:3e3}}})
this.labelContent=new KDLabelView({title:"Code Snip:"})
this.hiddenAceInputClone=new KDInputView({cssClass:"hidden invisible"})
this.aceWrapper=new KDView
this.cancelBtn=new KDButtonView({title:"Cancel",style:"modal-cancel",callback:function(){_this.reset()
return _this.parent.getDelegate().emit("ResetWidgets")}})
this.submitBtn=new KDButtonView({style:"clean-gray",title:"Share your Code Snippet",type:"submit"})
this.heartBox=new HelpBox({subtitle:"About Code Sharing",tooltip:{title:"Easily share your code with other members of the Koding community. Once you share, user can easily open or save your code to their own environment."}})
this.loader=new KDLoaderView({size:{width:30},loaderOptions:{color:"#ffffff",shape:"spiral",diameter:30,density:30,range:.4,speed:1,FPS:24}})
this.syntaxSelect=new KDSelectBox({name:"syntax",selectOptions:[],defaultValue:"javascript",callback:function(value){return _this.emit("codeSnip.changeSyntax",value)}})
this.on("codeSnip.changeSyntax",function(syntax){_this.updateSyntaxTag(syntax)
return _this.ace.setSyntax(syntax)})}var snippetCount
__extends(ActivityCodeSnippetWidget,_super)
ActivityCodeSnippetWidget.prototype.updateSyntaxTag=function(syntax){var item,oldSyntax,selectedItemsLimit,subViews,_i,_len
oldSyntax=this.ace.getSyntax()
subViews=this.tagController.itemWrapper.getSubViews().slice()
for(_i=0,_len=subViews.length;_len>_i;_i++){item=subViews[_i]
if(item.getData().title===oldSyntax){this.tagController.removeFromSubmitQueue(item)
break}}selectedItemsLimit=this.tagController.getOptions().selectedItemsLimit
return this.tagController.selectedItemCounter<selectedItemsLimit?this.tagController.addItemToSubmitQueue(this.tagController.getNoItemFoundView(syntax)):void 0}
ActivityCodeSnippetWidget.prototype.submit=function(){var _this=this
this.addCustomData("code",this.ace.getContents())
this.once("FormValidationPassed",function(){KD.track("Activity","CodeSnippetSubmitted")
return _this.reset()})
ActivityCodeSnippetWidget.__super__.submit.apply(this,arguments)
this.submitBtn.disable()
return this.utils.wait(8e3,function(){return _this.submitBtn.enable()})}
ActivityCodeSnippetWidget.prototype.reset=function(){var _this=this
this.submitBtn.setTitle("Share your Code Snippet")
this.removeCustomData("activity")
this.title.setValue("")
this.description.setValue("")
this.syntaxSelect.setValue("javascript")
this.updateSyntaxTag("javascript")
this.hiddenAceInputClone.setValue("")
this.hiddenAceInputClone.unsetClass("warn-on-unsaved-data")
return this.utils.defer(function(){_this.tagController.reset()
_this.ace.setContents("//your code snippet goes here...")
return _this.ace.setSyntax("javascript")})}
ActivityCodeSnippetWidget.prototype.switchToEditView=function(activity,fake){var body,content,fillForm,syntax,tags,title,_ref,_ref1,_this=this
null==fake&&(fake=!1)
if(fake)this.submitBtn.setTitle("Submit again")
else{this.submitBtn.setTitle("Edit code snippet")
this.addCustomData("activity",activity)}title=activity.title,body=activity.body,tags=activity.tags
_ref=activity.attachments[0],syntax=_ref.syntax,content=_ref.content
this.tagController.reset()
this.tagController.setDefaultValue(tags||[])
fillForm=function(){_this.title.setValue(Encoder.htmlDecode(title))
_this.description.setValue(Encoder.htmlDecode(body))
_this.ace.setContents(Encoder.htmlDecode(Encoder.XSSEncode(content)))
_this.hiddenAceInputClone.setValue(Encoder.htmlDecode(Encoder.XSSEncode(content)))
_this.hiddenAceInputClone.setClass("warn-on-unsaved-data")
return _this.syntaxSelect.setValue(Encoder.htmlDecode(syntax))}
return(null!=(_ref1=this.ace)?_ref1.editor:void 0)?fillForm():this.once("codeSnip.aceLoaded",function(){return fillForm()})}
ActivityCodeSnippetWidget.prototype.widgetShown=function(){return this.ace?this.refreshEditorView():this.loadAce()}
snippetCount=0
ActivityCodeSnippetWidget.prototype.loadAce=function(){var _this=this
this.loader.show()
this.aceWrapper.addSubView(this.ace=new Ace({},FSHelper.createFileFromPath("localfile:/codesnippet"+snippetCount++ +".txt")))
this.aceDefaultContent="//your code snippet goes here..."
return this.ace.on("ace.ready",function(){_this.loader.destroy()
_this.ace.setShowGutter(!1)
_this.ace.setContents(_this.aceDefaultContent)
_this.ace.setTheme()
_this.ace.setFontSize(12,!1)
_this.ace.setSyntax("javascript")
_this.ace.editor.getSession().on("change",function(){var _ref
_this.hiddenAceInputClone.setValue(Encoder.XSSEncode(_this.ace.getContents()))
""!==(_ref=_this.hiddenAceInputClone.getValue())&&_ref!==_this.aceDefaultContent?_this.hiddenAceInputClone.setClass("warn-on-unsaved-data"):_this.hiddenAceInputClone.unsetClass("warn-on-unsaved-data")
return _this.refreshEditorView()})
return _this.emit("codeSnip.aceLoaded")})}
ActivityCodeSnippetWidget.prototype.refreshEditorView=function(){var lineAmount,lines
lines=this.ace.editor.selection.doc.$lines
lineAmount=lines.length>15?15:lines.length<5?5:lines.length
return this.setAceHeightByLines(lineAmount)}
ActivityCodeSnippetWidget.prototype.setAceHeightByLines=function(lineAmount){var container,height,lineHeight
lineHeight=this.ace.editor.renderer.lineHeight
container=this.ace.editor.container
height=lineAmount*lineHeight
this.$(".code-snip-holder").height(height+20)
return this.ace.editor.resize()}
ActivityCodeSnippetWidget.prototype.viewAppended=function(){this.setClass("update-options codesnip")
this.setTemplate(this.pistachio())
return this.template.update()}
ActivityCodeSnippetWidget.prototype.pistachio=function(){return'<div class="form-actions-mask">\n  <div class="form-actions-holder">\n    <div class="formline">\n      {{> this.labelTitle}}\n      <div>\n        {{> this.title}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelDescription}}\n      <div>\n        {{> this.description}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelContent}}\n      <div class="code-snip-holder">\n        {{> this.loader}}\n        {{> this.aceWrapper}}\n        {{> this.hiddenAceInputClone}}\n        {{> this.syntaxSelect}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelAddTags}}\n      <div>\n        {{> this.tagAutoComplete}}\n        {{> this.selectedItemWrapper}}\n      </div>\n    </div>\n    <div class="formline submit">\n      <div class=\'formline-wrapper\'>\n        <div class="submit-box fr">\n          {{> this.submitBtn}}\n          {{> this.cancelBtn}}\n        </div>\n        {{> this.heartBox}}\n      </div>\n    </div>\n  </div>\n</div>'}
return ActivityCodeSnippetWidget}(ActivityWidgetFormView)

var ActivityTutorialWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityTutorialWidget=function(_super){function ActivityTutorialWidget(options,data){var embedOptions,_this=this
ActivityTutorialWidget.__super__.constructor.call(this,options,data)
this.preview=options.preview||{}
this.labelTitle=new KDLabelView({title:"New Tutorial",cssClass:"first-label"})
this.labelEmbedLink=new KDLabelView({title:"Video URL:"})
this.labelContent=new KDLabelView({title:"Content:"})
this.inputDiscussionTitle=new KDInputView({name:"title",label:this.labelTitle,cssClass:"warn-on-unsaved-data",placeholder:"Give a title to your Tutorial...",validate:{rules:{required:!0},messages:{required:"Tutorial title is required!"}}})
this.inputTutorialEmbedShowLink=new KDOnOffSwitch({cssClass:"show-tutorial-embed",defaultState:!1,callback:function(state){if(!state)return _this.embedBox.$().animate({top:"-400px"},300,function(){return _this.embedBox.hide()})
if(_this.embedBox.hasValidContent){_this.embedBox.show()
return _this.embedBox.$().animate({top:"0px"},300)}}})
this.inputTutorialEmbedLink=new KDInputView({name:"embed",label:this.labelEmbedLink,cssClass:"warn-on-unsaved-data tutorial-embed-link",placeholder:"Please enter a URL to a video...",keyup:function(){return""===_this.inputTutorialEmbedLink.getValue()?_this.embedBox.resetEmbedAndHide():void 0},paste:function(){return _this.utils.defer(function(){var embedOptions,url
_this.inputTutorialEmbedLink.setValue(_this.sanitizeUrls(_this.inputTutorialEmbedLink.getValue()))
url=_this.inputTutorialEmbedLink.getValue().trim()
if(/^((http(s)?\:)?\/\/)/.test(url)){embedOptions={maxWidth:540,maxHeight:200}
return _this.embedBox.embedUrl(url,embedOptions,function(){return _this.inputTutorialEmbedShowLink.getValue()===!1?_this.embedBox.hide():void 0})}})}})
embedOptions=$.extend({},options,{delegate:this,hasConfig:!0,forceType:"object"})
this.embedBox=new EmbedBox(embedOptions,data)
this.inputContent=new KDInputViewWithPreview({label:this.labelContent,preview:this.preview,name:"body",cssClass:"discussion-body warn-on-unsaved-data",type:"textarea",autogrow:!0,placeholder:"Please enter your Tutorial content. (You can use markdown here)",validate:{rules:{required:!0},messages:{required:"Tutorial content is required!"}}})
this.cancelBtn=new KDButtonView({title:"Cancel",style:"modal-cancel",callback:function(){_this.reset()
return _this.parent.getDelegate().emit("ResetWidgets")}})
this.submitBtn=new KDButtonView({style:"clean-gray",title:"Post your Tutorial",type:"submit"})
this.heartBox=new HelpBox({subtitle:"About Tutorials",tooltip:{title:"This is a public wall, here you can share your tutorials with the Koding community."}})}__extends(ActivityTutorialWidget,_super)
ActivityTutorialWidget.prototype.sanitizeUrls=function(text){return text.replace(/(([a-zA-Z]+\:)\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g,function(url){var test
test=/^([a-zA-Z]+\:\/\/)/.test(url)
return test?url:"http://"+url})}
ActivityTutorialWidget.prototype.submit=function(){var _this=this
this.once("FormValidationPassed",function(){KD.track("Activity","TutorialSubmitted")
return _this.reset()})
this.embedBox.hasValidContent&&this.addCustomData("link",{link_url:this.embedBox.url,link_embed:this.embedBox.getDataForSubmit()})
ActivityTutorialWidget.__super__.submit.apply(this,arguments)
this.submitBtn.disable()
return this.utils.wait(8e3,function(){return _this.submitBtn.enable()})}
ActivityTutorialWidget.prototype.reset=function(){var _this=this
this.submitBtn.setTitle("Post your Tutorial")
this.removeCustomData("activity")
this.inputDiscussionTitle.setValue("")
this.inputContent.setValue("")
this.inputContent.resize()
this.inputTutorialEmbedShowLink.setValue(!1)
this.embedBox.resetEmbedAndHide()
this.utils.wait(2e3,function(){return _this.tagController.reset()})
return ActivityTutorialWidget.__super__.reset.apply(this,arguments)}
ActivityTutorialWidget.prototype.viewAppended=function(){this.setClass("update-options discussion")
this.setTemplate(this.pistachio())
return this.template.update()}
ActivityTutorialWidget.prototype.switchToEditView=function(activity,fake){var body,fillForm,link,tags,title,_this=this
null==fake&&(fake=!1)
if(fake)this.submitBtn.setTitle("Submit again")
else{this.submitBtn.setTitle("Edit Tutorial")
this.addCustomData("activity",activity)}title=activity.title,body=activity.body,tags=activity.tags,link=activity.link
this.tagController.reset()
this.tagController.setDefaultValue(tags||[])
fillForm=function(){_this.inputDiscussionTitle.setValue(Encoder.htmlDecode(title))
_this.inputContent.setValue(Encoder.htmlDecode(body))
_this.inputTutorialEmbedLink.setValue(Encoder.htmlDecode(null!=link?link.link_url:void 0))
return _this.inputContent.generatePreview()}
return fillForm()}
ActivityTutorialWidget.prototype.pistachio=function(){return'<div class="form-actions-mask">\n  <div class="form-actions-holder">\n    <div class="formline">\n      {{> this.labelTitle}}\n      <div>\n        {{> this.inputDiscussionTitle}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelEmbedLink}}\n      <div>\n        {{> this.inputTutorialEmbedLink}}\n        {{> this.inputTutorialEmbedShowLink}}\n        {{> this.embedBox}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelContent}}\n      <div>\n        {{> this.inputContent}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelAddTags}}\n      <div>\n        {{> this.tagAutoComplete}}\n        {{> this.selectedItemWrapper}}\n      </div>\n    </div>\n    <div class="formline submit">\n      <div class=\'formline-wrapper\'>\n        <div class="submit-box fr">\n          {{> this.submitBtn}}\n          {{> this.cancelBtn}}\n        </div>\n        {{> this.heartBox}}\n      </div>\n    </div>\n  </div>\n</div>'}
return ActivityTutorialWidget}(ActivityWidgetFormView)

var ActivityDiscussionWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityDiscussionWidget=function(_super){function ActivityDiscussionWidget(options,data){var _this=this
ActivityDiscussionWidget.__super__.constructor.call(this,options,data)
this.preview=options.preview||{}
this.labelTitle=new KDLabelView({title:"New Discussion",cssClass:"first-label"})
this.labelContent=new KDLabelView({title:"Content:"})
this.inputDiscussionTitle=new KDInputView({name:"title",label:this.labelTitle,cssClass:"warn-on-unsaved-data",placeholder:"Give a title to what you want to start discussing...",validate:{rules:{required:!0},messages:{required:"Discussion title is required!"}}})
this.inputContent=new KDInputViewWithPreview({label:this.labelContent,preview:this.preview,name:"body",cssClass:"discussion-body warn-on-unsaved-data",type:"textarea",autogrow:!0,placeholder:"What do you want to talk about? (You can use markdown here)",validate:{rules:{required:!0},messages:{required:"Discussion content is required!"}}})
this.cancelBtn=new KDButtonView({title:"Cancel",style:"modal-cancel",callback:function(){_this.reset()
return _this.parent.getDelegate().emit("ResetWidgets")}})
this.submitBtn=new KDButtonView({style:"clean-gray",title:"Start your discussion",type:"submit"})
this.heartBox=new HelpBox({subtitle:"About Discussions",tooltip:{title:"This is a public wall, here you can discuss anything with the Koding community."}})}__extends(ActivityDiscussionWidget,_super)
ActivityDiscussionWidget.prototype.submit=function(){var _this=this
this.once("FormValidationPassed",function(){KD.track("Activity","DiscussionSubmitted")
return _this.reset()})
ActivityDiscussionWidget.__super__.submit.apply(this,arguments)
this.submitBtn.disable()
return this.utils.wait(8e3,function(){return _this.submitBtn.enable()})}
ActivityDiscussionWidget.prototype.reset=function(){var _this=this
this.submitBtn.setTitle("Start your discussion")
this.removeCustomData("activity")
this.inputDiscussionTitle.setValue("")
this.inputContent.setValue("")
this.inputContent.resize()
this.utils.defer(function(){return _this.tagController.reset()})
return ActivityDiscussionWidget.__super__.reset.apply(this,arguments)}
ActivityDiscussionWidget.prototype.viewAppended=function(){this.setClass("update-options discussion")
this.setTemplate(this.pistachio())
return this.template.update()}
ActivityDiscussionWidget.prototype.switchToEditView=function(activity,fake){var body,fillForm,tags,title,_this=this
null==fake&&(fake=!1)
if(fake)this.submitBtn.setTitle("Submit again")
else{this.submitBtn.setTitle("Edit Discussion")
this.addCustomData("activity",activity)}title=activity.title,body=activity.body,tags=activity.tags
this.tagController.reset()
this.tagController.setDefaultValue(tags||[])
fillForm=function(){_this.inputDiscussionTitle.setValue(Encoder.htmlDecode(title))
return _this.inputContent.setValue(Encoder.htmlDecode(body))}
return fillForm()}
ActivityDiscussionWidget.prototype.pistachio=function(){return'<div class="form-actions-mask">\n  <div class="form-actions-holder">\n    <div class="formline">\n      {{> this.labelTitle}}\n      <div>\n        {{> this.inputDiscussionTitle}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelContent}}\n      <div>\n        {{> this.inputContent}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelAddTags}}\n      <div>\n        {{> this.tagAutoComplete}}\n        {{> this.selectedItemWrapper}}\n      </div>\n    </div>\n    <div class="formline submit">\n      <div class=\'formline-wrapper\'>\n        <div class="submit-box fr">\n          {{> this.submitBtn}}\n          {{> this.cancelBtn}}\n        </div>\n        {{> this.heartBox}}\n      </div>\n    </div>\n  </div>\n</div>'}
return ActivityDiscussionWidget}(ActivityWidgetFormView)

var ActivityBlogPostWidget,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityBlogPostWidget=function(_super){function ActivityBlogPostWidget(options,data){var _this=this
ActivityBlogPostWidget.__super__.constructor.call(this,options,data)
this.preview=options.preview||{}
this.labelTitle=new KDLabelView({title:"New Blog Post",cssClass:"first-label"})
this.labelContent=new KDLabelView({title:"Content:"})
this.inputDiscussionTitle=new KDInputView({name:"title",label:this.labelTitle,cssClass:"warn-on-unsaved-data",placeholder:"Give a title to what you want to your Blog Post...",validate:{rules:{required:!0},messages:{required:"Blog Post title is required!"}}})
this.inputContent=new KDInputViewWithPreview({label:this.labelContent,preview:this.preview,name:"body",cssClass:"discussion-body warn-on-unsaved-data",type:"textarea",autogrow:!0,placeholder:"What do you want to talk about? (You can use markdown here)",validate:{rules:{required:!0},messages:{required:"Blog Post body is required!"}}})
this.cancelBtn=new KDButtonView({title:"Cancel",style:"modal-cancel",callback:function(){_this.reset()
return _this.parent.getDelegate().emit("ResetWidgets")}})
this.submitBtn=new KDButtonView({style:"clean-gray",title:"Post to your Blog",type:"submit"})
this.heartBox=new HelpBox({subtitle:"About Blog Posts",tooltip:{title:"This is a public wall, here you can discuss anything with the Koding community."}})}__extends(ActivityBlogPostWidget,_super)
ActivityBlogPostWidget.prototype.submit=function(){var _this=this
this.once("FormValidationPassed",function(){KD.track("Activity","BlogPostSubmitted")
return _this.reset()})
ActivityBlogPostWidget.__super__.submit.apply(this,arguments)
this.submitBtn.disable()
return this.utils.wait(8e3,function(){return _this.submitBtn.enable()})}
ActivityBlogPostWidget.prototype.reset=function(){var _this=this
this.submitBtn.setTitle("Start your Blog Post")
this.removeCustomData("activity")
this.inputDiscussionTitle.setValue("")
this.inputContent.setValue("")
this.inputContent.resize()
this.utils.defer(function(){return _this.tagController.reset()})
return ActivityBlogPostWidget.__super__.reset.apply(this,arguments)}
ActivityBlogPostWidget.prototype.viewAppended=function(){this.setClass("update-options discussion")
this.setTemplate(this.pistachio())
return this.template.update()}
ActivityBlogPostWidget.prototype.switchToEditView=function(activity,fake){var body,fillForm,tags,title,_this=this
null==fake&&(fake=!1)
if(fake)this.submitBtn.setTitle("Submit again")
else{this.submitBtn.setTitle("Edit Blog Post")
this.addCustomData("activity",activity)}title=activity.title,body=activity.body,tags=activity.tags
this.tagController.reset()
this.tagController.setDefaultValue(tags||[])
fillForm=function(){_this.inputDiscussionTitle.setValue(Encoder.htmlDecode(title))
return _this.inputContent.setValue(Encoder.htmlDecode(body))}
return fillForm()}
ActivityBlogPostWidget.prototype.pistachio=function(){return'<div class="form-actions-mask">\n  <div class="form-actions-holder">\n    <div class="formline">\n      {{> this.labelTitle}}\n      <div>\n        {{> this.inputDiscussionTitle}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelContent}}\n      <div>\n        {{> this.inputContent}}\n      </div>\n    </div>\n    <div class="formline">\n      {{> this.labelAddTags}}\n      <div>\n        {{> this.tagAutoComplete}}\n        {{> this.selectedItemWrapper}}\n      </div>\n    </div>\n    <div class="formline submit">\n      <div class=\'formline-wrapper\'>\n        <div class="submit-box fr">\n          {{> this.submitBtn}}\n          {{> this.cancelBtn}}\n        </div>\n        {{> this.heartBox}}\n      </div>\n    </div>\n  </div>\n</div>'}
return ActivityBlogPostWidget}(ActivityWidgetFormView)

var ActivityContentDisplay,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityContentDisplay=function(_super){function ActivityContentDisplay(options,data){var currentGroup,getContentGroupLinkPartial,_this=this
null==options&&(options={})
options.cssClass||(options.cssClass="content-display activity-related "+options.type)
ActivityContentDisplay.__super__.constructor.call(this,options,data)
currentGroup=KD.getSingleton("groupsController").getCurrentGroup()
getContentGroupLinkPartial=function(groupSlug,groupName){return(null!=currentGroup?currentGroup.slug:void 0)===groupSlug?"":'In <a href="'+groupSlug+'" target="'+groupSlug+'">'+groupName+"</a>"}
this.contentGroupLink=new KDCustomHTMLView({tagName:"span",partial:getContentGroupLinkPartial(data.group,data.group)});(null!=currentGroup?currentGroup.slug:void 0)===data.group?this.contentGroupLink.updatePartial(getContentGroupLinkPartial(currentGroup.slug,currentGroup.title)):KD.remote.api.JGroup.one({slug:data.group},function(err,group){return!err&&group?_this.contentGroupLink.updatePartial(getContentGroupLinkPartial(group.slug,group.title)):void 0})
this.header=new HeaderViewSection({type:"big",title:this.getOptions().title})
this.back=new KDCustomHTMLView({tagName:"a",partial:"<span>&laquo;</span> Back",click:function(event){event.stopPropagation()
event.preventDefault()
KD.singleton("display").emit("ContentDisplayWantsToBeHidden",_this)
return KD.singleton("router").back()}})
KD.isLoggedIn()||(this.back=new KDCustomHTMLView)}__extends(ActivityContentDisplay,_super)
return ActivityContentDisplay}(KDScrollView)

var ContentDisplayStatusUpdate,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayStatusUpdate=function(_super){function ContentDisplayStatusUpdate(options,data){null==options&&(options={})
null==data&&(data={})
options.tooltip||(options.tooltip={title:"Status Update",offset:3,selector:"span.type-icon"})
ContentDisplayStatusUpdate.__super__.constructor.call(this,options,data)
this.activityItem=new StatusActivityItemView({delegate:this},this.getData())
this.activityItem.on("ActivityIsDeleted",function(){return KD.singleton("router").back()})}__extends(ContentDisplayStatusUpdate,_super)
ContentDisplayStatusUpdate.prototype.viewAppended=JView.prototype.viewAppended
ContentDisplayStatusUpdate.prototype.pistachio=function(){return'<h2 class="sub-header">{{> this.back}}</h2>\n{{> this.activityItem}}'}
return ContentDisplayStatusUpdate}(ActivityContentDisplay)

var ContentDisplayCodeSnippet,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayCodeSnippet=function(_super){function ContentDisplayCodeSnippet(options,data){null==options&&(options={})
options.tooltip||(options.tooltip={title:"Code Snippet",offset:3,selector:"span.type-icon"})
ContentDisplayCodeSnippet.__super__.constructor.call(this,options,data)
this.codeSnippetView=new CodeSnippetView({},this.getData().attachments[0])
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(ContentDisplayCodeSnippet,_super)
ContentDisplayCodeSnippet.prototype.pistachio=function(){return"{{> this.header}}\n<h2 class=\"sub-header\">{{> this.back}}</h2>\n<div class='kdview content-display-main-section activity-item codesnip'>\n  <span>\n    {{> this.avatar}}\n    <span class=\"author\">AUTHOR</span>\n  </span>\n  <div class='activity-item-right-col'>\n    <h3>{{#(title)}}</h3>\n    <p class='context'>{{this.utils.applyTextExpansions(#(body))}}</p>\n    {{> this.codeSnippetView}}\n    <footer class='clearfix'>\n      <div class='type-and-time'>\n        <span class='type-icon'></span>{{> this.contentGroupLink}} by {{> this.author}}\n        {{> this.timeAgoView}}\n        {{> this.tags}}\n      </div>\n      {{> this.actionLinks}}\n    </footer>\n    {{> this.commentBox}}\n  </div>\n</div>"}
return ContentDisplayCodeSnippet}(ContentDisplayStatusUpdate)

var ContentDisplayDiscussion,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayDiscussion=function(_super){function ContentDisplayDiscussion(options,data){var activity,loggedInId,origin,_this=this
null==options&&(options={})
if(null==data.opinionCount){data.opinionCount=data.repliesCount||0
data.repliesCount=0}options.tooltip||(options.tooltip={title:"Discussion",offset:3,selector:"span.type-icon"})
ContentDisplayDiscussion.__super__.constructor.call(this,options,data)
origin={constructorName:data.originType,id:data.originId}
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)
this.avatar=new AvatarStaticView({tagName:"span",size:{width:50,height:50},origin:origin})
this.author=new ProfileLinkView({origin:origin})
this.commentBox=new CommentView({},data)
this.opinionBox=new OpinionView({},data)
this.opinionBoxHeader=new KDCustomHTMLView({tagName:"div",cssClass:"opinion-box-header",partial:this.opinionHeaderCountString(data.opinionCount)})
this.opinionBox.opinionList.on("OwnOpinionHasArrived",function(data){_this.resetHeaderCount(data)
return _this.opinionBox.resetDecoration()})
this.opinionBox.opinionList.on("OpinionIsDeleted",function(data){return _this.resetHeaderCount(data)})
this.opinionForm=new OpinionFormView({preview:{language:"markdown",autoUpdate:!0,showInitially:!1},cssClass:"opinion-container",callback:function(data){return _this.getData().replyOpinion(data,function(err,opinion){"function"==typeof callback&&callback(err,opinion)
_this.opinionForm.reset()
_this.opinionForm.submitOpinionBtn.hideLoader()
return err?new KDNotificationView({type:"mini",title:"There was an error, try again later!"}):_this.opinionBox.opinionList.emit("OwnOpinionHasArrived",opinion)})}},data)
this.newAnswers=0
this.actionLinks=new DiscussionActivityActionsView({delegate:this.commentBox.commentList,cssClass:"comment-header"},data)
this.tags=new ActivityChildViewTagGroup({itemsToShow:3,itemClass:TagLinkView},data.tags)
this.deleteDiscussionLink=new KDCustomHTMLView({tagName:"a",attributes:{title:"Delete your discussion",href:"#"},cssClass:"delete-link hidden"})
this.editDiscussionLink=new KDCustomHTMLView({tagName:"a",attributes:{title:"Edit your discussion",href:"#"},cssClass:"edit-link hidden"})
activity=this.getData()
loggedInId=KD.whoami().getId()
if(loggedInId===data.originId||loggedInId===activity.originId||KD.checkFlag("super-admin",KD.whoami())){this.editDiscussionLink.on("click",function(){var _ref
if(null!=_this.editDiscussionForm){null!=(_ref=_this.editDiscussionForm)&&_ref.destroy()
delete _this.editDiscussionForm
return _this.$(".discussion-body .data").show()}_this.editDiscussionForm=new DiscussionFormView({preview:{language:"markdown",autoUpdate:!0,showInitially:!0},title:"edit-discussion",cssClass:"edit-discussion-form",callback:function(data){return _this.getData().modify(data,function(err){"function"==typeof callback&&callback(err,opinion)
_this.editDiscussionForm.reset()
if(err)return new KDNotificationView({title:"Your changes weren't saved.",type:"mini"})
_this.editDiscussionForm.setClass("hidden")
return _this.$(".discussion-body .data").show()})}},data)
_this.addSubView(_this.editDiscussionForm,"p.discussion-body",!0)
return _this.$(".discussion-body .data").hide()})
this.deleteDiscussionLink.on("click",function(){return _this.confirmDeleteDiscussion(data)})
this.editDiscussionLink.unsetClass("hidden")
this.deleteDiscussionLink.unsetClass("hidden")}activity.on("CommentIsAdded",function(reply){activity.repliesCount=reply.repliesCount
return _this.commentBox.setData(activity)})
activity.on("ReplyIsAdded",function(reply){if("JDiscussion"===data.bongo_.constructorName){if(reply.replier.id!==KD.whoami().getId()){_this.newAnswers++
_this.opinionBox.opinionList.emit("NewOpinionHasArrived")}return _this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(reply.opinionCount))}})
activity.on("OpinionWasRemoved",function(){return _this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(_this.getData().opinionCount))})
activity.on("ReplyIsRemoved",function(replyId){var i,item,_i,_len,_ref,_results
_this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(_this.getData().opinionCount))
_ref=_this.opinionBox.opinionList.items
_results=[]
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){item=_ref[i]
if(item.getData()._id===replyId){item.hide()
_results.push(item.destroy())}else _results.push(void 0)}return _results})
activity.repliesCount>0&&null==activity.replies&&activity.commentsByRange({from:0,to:5},function(err,comments){var comment,_i,_len,_results
if(err)return log(err)
comments=comments.reverse()
activity.replies=comments
_this.commentBox.setData(comments)
_results=[]
for(_i=0,_len=comments.length;_len>_i;_i++){comment=comments[_i]
_results.push(_this.commentBox.commentList.addItem(comment))}return _results})}__extends(ContentDisplayDiscussion,_super)
ContentDisplayDiscussion.prototype.resetHeaderCount=function(){var opinionCount
opinionCount=this.opinionBox.opinionList.items&&this.opinionBox.opinionList.items.length||0
return this.opinionBoxHeader.updatePartial(this.opinionHeaderCountString(opinionCount))}
ContentDisplayDiscussion.prototype.opinionHeaderCountString=function(count){var countString
countString=0===count?"No Answers yet":1===count?"One Answer":""+count+" Answers"
return'<span class="opinion-count">'+countString+"</span>"}
ContentDisplayDiscussion.prototype.confirmDeleteDiscussion=function(data){var modal,_this=this
return modal=new KDModalView({title:"Delete discussion",content:"<div class='modalformline'>Are you sure you want to delete this discussion and all it's opinions and comments?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return data["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
if(err)return new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"})
KD.singleton("display").emit("ContentDisplayWantsToBeHidden",_this)
return _this.utils.wait(2e3,function(){return _this.destroy()})})}}}})}
ContentDisplayDiscussion.prototype.highlightCode=function(){return this.$("p.discussion-body span.data pre").each(function(i,element){return hljs.highlightBlock(element)})}
ContentDisplayDiscussion.prototype.render=function(){ContentDisplayDiscussion.__super__.render.call(this)
this.highlightCode()
return this.prepareExternalLinks()}
ContentDisplayDiscussion.prototype.viewAppended=function(){ContentDisplayDiscussion.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
this.highlightCode()
return this.prepareExternalLinks()}
ContentDisplayDiscussion.prototype.prepareExternalLinks=function(){return this.$("p.discussion-body a[href^=http]").attr("target","_blank")}
ContentDisplayDiscussion.prototype.pistachio=function(){return"{{> this.header}}\n<h2 class=\"sub-header\">{{> this.back}}</h2>\n<div class='kdview content-display-main-section activity-item discussion'>\n  <div class='discussion-contents'>\n    <div class=\"discussion-content\">\n      <span>\n        {{> this.avatar}}\n        <span class=\"author\">AUTHOR</span>\n      </span>\n      <div class='discussion-main-opinion'>\n        <h3>{{this.utils.expandUsernames(this.utils.applyMarkdown(#(title)))}}</h3>\n        <footer class='discussion-footer clearfix'>\n          <div class='type-and-time'>\n            <span class='type-icon'></span>{{> this.contentGroupLink}} by {{> this.author}} •\n            {{> this.timeAgoView}}\n            {{> this.tags}}\n            {{> this.actionLinks}}\n          </div>\n        </footer>\n        {{> this.editDiscussionLink}}\n        {{> this.deleteDiscussionLink}}\n        <p class='context discussion-body has-markdown'>{{this.utils.expandUsernames(this.utils.applyMarkdown(#(body)), \"pre\")}}</p>\n        {{> this.commentBox}}\n      </div>\n    </div>\n  </div>\n  <div class=\"opinion-content\">\n    {{> this.opinionBoxHeader}}\n    {{> this.opinionBox}}\n    <div class=\"content-display-main-section opinion-form-footer\">\n      {{> this.opinionForm}}\n    </div>\n  </div>\n</div>"}
return ContentDisplayDiscussion}(ActivityContentDisplay)

var ContentDisplayBlogPost,StaticBlogPostListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayBlogPost=function(_super){function ContentDisplayBlogPost(options,data){var origin
null==options&&(options={})
null==data&&(data={})
options.tooltip||(options.tooltip={title:"Blog Post",offset:3,selector:"span.type-icon"})
ContentDisplayBlogPost.__super__.constructor.call(this,options,data)
origin={constructorName:data.originType,id:data.originId}
this.avatar=new AvatarStaticView({tagName:"span",size:{width:50,height:50},origin:origin})
this.author=new ProfileLinkView({origin:origin})
this.commentBox=new CommentView(null,data)
this.actionLinks=new ActivityActionsView({delegate:this.commentBox.commentList,cssClass:"comment-header"},data)
this.tags=new ActivityChildViewTagGroup({itemsToShow:3,itemClass:TagLinkView},data.tags)}__extends(ContentDisplayBlogPost,_super)
ContentDisplayBlogPost.prototype.viewAppended=function(){var commentController
if(this.getData().constructor!==KD.remote.api.CBlogPostActivity){ContentDisplayBlogPost.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
if(null!=this.getData().repliesCount&&this.getData().repliesCount>0){commentController=this.commentBox.commentController
return commentController.fetchAllComments(0,function(err,comments){commentController.removeAllItems()
return commentController.instantiateListItems(comments)})}}}
ContentDisplayBlogPost.prototype.applyTextExpansions=function(str){null==str&&(str="")
return str=this.utils.applyTextExpansions(str,!0)}
ContentDisplayBlogPost.prototype.pistachio=function(){return"{{> this.header}}\n<h2 class=\"sub-header\">{{> this.back}}</h2>\n<div class='kdview content-display-main-section activity-item blog-post'>\n  <span>\n    {{> this.avatar}}\n    <span class=\"author\">AUTHOR</span>\n  </span>\n  <div class='activity-item-right-col'>\n    <h3 class='blog-post-title'>{{this.applyTextExpansions(#(title))}}</h3>\n    <p class=\"blog-post-body has-markdown\">{{KD.utils.applyMarkdown(Encoder.htmlDecode(#(body)))}}</p>\n    <footer class='clearfix'>\n      <div class='type-and-time'>\n        <span class='type-icon'></span> {{> this.contentGroupLink}} by {{> this.author}}\n        <time>{{$.timeago(#(meta.createdAt))}}</time>\n        {{> this.tags}}\n      </div>\n      {{> this.actionLinks}}\n    </footer>\n    {{> this.commentBox}}\n  </div>\n</div>"}
return ContentDisplayBlogPost}(ActivityContentDisplay)
StaticBlogPostListItem=function(_super){function StaticBlogPostListItem(options,data){StaticBlogPostListItem.__super__.constructor.call(this,options,data)
this.postDate=new Date(this.getData().meta.createdAt)
this.postDate=this.postDate.toLocaleString()
this.setClass("content-item")}__extends(StaticBlogPostListItem,_super)
StaticBlogPostListItem.prototype.viewAppended=function(){log("viewAppended")
StaticBlogPostListItem.__super__.viewAppended.apply(this,arguments)
this.setTemplate(this.pistachio())
return this.template.update()}
StaticBlogPostListItem.prototype.pistachio=function(){return'<div class="title"><span class="text">'+this.getData().title+'</span><span class="create-date">'+this.postDate+'</span></div>\n<div class="has-markdown">\n  <span class="data">'+Encoder.htmlDecode(this.getData().html)+"</span>\n</div>"}
return StaticBlogPostListItem}(KDListItemView)

var ContentDisplayTutorial,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayTutorial=function(_super){function ContentDisplayTutorial(options,data){var activity,loggedInId,origin,_ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_ref7,_this=this
null==options&&(options={})
if(null==data.opinionCount){data.opinionCount=data.repliesCount||0
data.repliesCount=0}options.tooltip||(options.tooltip={title:"Tutorial",offset:3,selector:"span.type-icon"})
ContentDisplayTutorial.__super__.constructor.call(this,options,data)
this.setClass("tutorial")
origin={constructorName:data.originType,id:data.originId}
this.avatar=new AvatarStaticView({tagName:"span",size:{width:50,height:50},origin:origin})
this.author=new ProfileLinkView({origin:origin})
this.opinionBox=new OpinionView(null,data)
this.opinionBoxHeader=new KDCustomHTMLView({tagName:"div",cssClass:"opinion-box-header",partial:this.opinionHeaderCountString(data.opinionCount)})
this.embedOptions=$.extend({},options,{delegate:this,hasConfig:!1,forceType:"object"})
this.embedBox=new EmbedBox(this.embedOptions,data)
this.previewImage=new KDCustomHTMLView({tagName:"img",cssClass:"tutorial-preview-image",attributes:{src:this.utils.proxifyUrl((null!=(_ref=data.link)?null!=(_ref1=_ref.link_embed)?null!=(_ref2=_ref1.images)?null!=(_ref3=_ref2[0])?_ref3.url:void 0:void 0:void 0:void 0)||""),title:"View the full Tutorial",alt:"View the full tutorial","data-paths":"preview"}});(null!=(_ref4=data.link)?null!=(_ref5=_ref4.link_embed)?null!=(_ref6=_ref5.images)?null!=(_ref7=_ref6[0])?_ref7.url:void 0:void 0:void 0:void 0)||this.previewImage.hide()
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)
this.opinionBox.opinionList.on("OwnOpinionHasArrived",function(){return _this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(_this.getData().opinionCount))})
this.opinionBox.opinionList.on("OpinionIsDeleted",function(){return _this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(_this.getData().opinionCount))})
this.opinionForm=new OpinionFormView({preview:{language:"markdown",autoUpdate:!0,showInitially:!1},typeLabel:"tutorial",cssClass:"opinion-container",callback:function(data){return _this.getData().reply(data,function(err,opinion){"function"==typeof callback&&callback(err,opinion)
_this.opinionForm.reset()
_this.opinionForm.submitOpinionBtn.hideLoader()
return err?new KDNotificationView({type:"mini",title:"There was an error, try again later!"}):_this.opinionBox.opinionList.emit("OwnOpinionHasArrived",opinion)})}},data)
this.newAnswers=0
this.actionLinks=new TutorialActivityActionsView({delegate:this.opinionBox.opinionList,cssClass:"comment-header"},data)
this.tags=new ActivityChildViewTagGroup({itemsToShow:3,itemClass:TagLinkView},data.tags)
this.deleteDiscussionLink=new KDCustomHTMLView({tagName:"a",attributes:{title:"Delete your tutorial",href:"#"},cssClass:"delete-link hidden"})
this.editDiscussionLink=new KDCustomHTMLView({tagName:"a",attributes:{title:"Edit your tutorial",href:"#"},cssClass:"edit-link hidden"})
activity=this.getData()
loggedInId=KD.whoami().getId()
if(loggedInId===data.originId||loggedInId===activity.originId||KD.checkFlag("super-admin",KD.whoami())){this.editDiscussionLink.on("click",function(){var _ref8
if(null!=_this.editDiscussionForm){null!=(_ref8=_this.editDiscussionForm)&&_ref8.destroy()
delete _this.editDiscussionForm
_this.$(".tutorial-body .data").show()
return _this.utils.defer(function(){return _this.embedBox.show()})}_this.editDiscussionForm=new TutorialFormView({title:"edit-tutorial",cssClass:"edit-tutorial-form",delegate:_this,callback:function(data){return _this.getData().modify(data,function(err){"function"==typeof callback&&callback(err,opinion)
_this.editDiscussionForm.reset()
if(err)return new KDNotificationView({title:"Your changes weren't saved.",type:"mini"})
_this.editDiscussionForm.setClass("hidden")
_this.$(".tutorial-body .data").show()
return _this.utils.defer(function(){return _this.embedBox.hasValidContent?_this.embedBox.show():void 0})})}},data)
_this.addSubView(_this.editDiscussionForm,"p.tutorial-body",!0)
_this.$(".tutorial-body .data").hide()
return _this.embedBox.hide()})
this.deleteDiscussionLink.on("click",function(){return _this.confirmDeleteTutorial(data)})
this.editDiscussionLink.unsetClass("hidden")
this.deleteDiscussionLink.unsetClass("hidden")}activity.on("ReplyIsAdded",function(reply){if("JTutorial"===data.bongo_.constructorName){if(reply.replier.id!==KD.whoami().getId()){_this.newAnswers++
_this.opinionBox.opinionList.emit("NewOpinionHasArrived")}return _this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(data.opinionCount))}})
activity.on("OpinionWasRemoved",function(){return _this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(_this.getData().opinionCount))})
activity.on("ReplyIsRemoved",function(replyId){var i,item,_i,_len,_ref8,_results
_this.opinionBoxHeader.updatePartial(_this.opinionHeaderCountString(_this.getData().opinionCount))
_ref8=_this.opinionBox.opinionList.items
_results=[]
for(i=_i=0,_len=_ref8.length;_len>_i;i=++_i){item=_ref8[i]
if(item.getData()._id===replyId){item.hide()
_results.push(item.destroy())}else _results.push(void 0)}return _results})}__extends(ContentDisplayTutorial,_super)
ContentDisplayTutorial.prototype.opinionHeaderCountString=function(count){var countString
countString=0===count?"No Answers yet":1===count?"One Answer":""+count+" Answers"
return'<span class="opinion-count">'+countString+"</span>"}
ContentDisplayTutorial.prototype.confirmDeleteTutorial=function(data){var modal,_this=this
return modal=new KDModalView({title:"Delete Tutorial",content:"<div class='modalformline'>Are you sure you want to delete this tutorial and all it's opinions and comments?</div>",height:"auto",overlay:!0,buttons:{Delete:{style:"modal-clean-red",loader:{color:"#ffffff",diameter:16},callback:function(){return data["delete"](function(err){modal.buttons.Delete.hideLoader()
modal.destroy()
if(err)return new KDNotificationView({type:"mini",cssClass:"error editor",title:"Error, please try again later!"})
KD.singleton("display").emit("ContentDisplayWantsToBeHidden",_this)
return _this.utils.wait(2e3,function(){return _this.destroy()})})}}}})}
ContentDisplayTutorial.prototype.highlightCode=function(){return this.$("p.tutorial-body span.data pre").each(function(i,element){return hljs.highlightBlock(element)})}
ContentDisplayTutorial.prototype.prepareExternalLinks=function(){return this.$("p.tutorial-body a[href^=http]").attr("target","_blank")}
ContentDisplayTutorial.prototype.render=function(){ContentDisplayTutorial.__super__.render.call(this)
this.highlightCode()
return this.prepareExternalLinks()}
ContentDisplayTutorial.prototype.viewAppended=function(){var _this=this
ContentDisplayTutorial.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
this.highlightCode()
this.prepareExternalLinks()
return null!=this.getData().link?this.embedBox.embedExistingData(this.getData().link.link_embed,this.embedOptions,function(){return _this.embedBox.hasValidContent!==!1?_this.embedBox.show():void 0}):void 0}
ContentDisplayTutorial.prototype.click=function(event){var _ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_ref7,_ref8
if($(event.target).is("[data-paths~=preview]")){this.videoPopup=new VideoPopup({delegate:this.previewImage,title:(null!=(_ref=this.getData().link)?null!=(_ref1=_ref.link_embed)?_ref1.title:void 0:void 0)||"Untitled Video",thumb:null!=(_ref2=this.getData().link)?null!=(_ref3=_ref2.link_embed)?null!=(_ref4=_ref3.images)?null!=(_ref5=_ref4[0])?_ref5.url:void 0:void 0:void 0:void 0},null!=(_ref6=this.getData().link)?null!=(_ref7=_ref6.link_embed)?null!=(_ref8=_ref7.object)?_ref8.html:void 0:void 0:void 0)
return this.videoPopup.openVideoPopup()}}
ContentDisplayTutorial.prototype.pistachio=function(){return"{{> this.header}}\n<h2 class=\"sub-header\">{{> this.back}}</h2>\n<div class='kdview content-display-main-section activity-item tutorial'>\n  <div class='tutorial-contents'>\n    <div class=\"tutorial-content\">\n      <span>\n        {{> this.avatar}}\n        <span class=\"author\">AUTHOR</span>\n      </span>\n      <div class='tutorial-main-opinion'>\n        <h3>{{this.utils.expandUsernames(this.utils.applyMarkdown(#(title)))}}</h3>\n        <footer class='tutorial-footer clearfix'>\n          <div class='type-and-time'>\n            <span class='type-icon'></span>{{> this.contentGroupLink}} by {{> this.author}} •\n            {{> this.timeAgoView}}\n            {{> this.tags}}\n            {{> this.actionLinks}}\n          </div>\n        </footer>\n        {{> this.editDiscussionLink}}\n        {{> this.deleteDiscussionLink}}\n        {{> this.previewImage}}\n        <p class='context tutorial-body has-markdown'>{{this.utils.expandUsernames(this.utils.applyMarkdown(#(body)), \"pre\")}}</p>\n      </div>\n    </div>\n  </div>\n  <div class=\"opinion-content\">\n    {{> this.opinionBoxHeader}}\n    {{> this.opinionBox}}\n    <div class=\"content-display-main-section opinion-form-footer\">\n      {{> this.opinionForm}}\n    </div>\n  </div>\n</div>"}
return ContentDisplayTutorial}(ActivityContentDisplay)

var ContentDisplayBlogPost,StaticBlogPostListItem,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayBlogPost=function(_super){function ContentDisplayBlogPost(options,data){var origin
null==options&&(options={})
null==data&&(data={})
options.tooltip||(options.tooltip={title:"Blog Post",offset:3,selector:"span.type-icon"})
ContentDisplayBlogPost.__super__.constructor.call(this,options,data)
origin={constructorName:data.originType,id:data.originId}
this.avatar=new AvatarStaticView({tagName:"span",size:{width:50,height:50},origin:origin})
this.author=new ProfileLinkView({origin:origin})
this.commentBox=new CommentView(null,data)
this.actionLinks=new ActivityActionsView({delegate:this.commentBox.commentList,cssClass:"comment-header"},data)
this.tags=new ActivityChildViewTagGroup({itemsToShow:3,itemClass:TagLinkView},data.tags)}__extends(ContentDisplayBlogPost,_super)
ContentDisplayBlogPost.prototype.viewAppended=function(){var commentController
if(this.getData().constructor!==KD.remote.api.CBlogPostActivity){ContentDisplayBlogPost.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
if(null!=this.getData().repliesCount&&this.getData().repliesCount>0){commentController=this.commentBox.commentController
return commentController.fetchAllComments(0,function(err,comments){commentController.removeAllItems()
return commentController.instantiateListItems(comments)})}}}
ContentDisplayBlogPost.prototype.applyTextExpansions=function(str){null==str&&(str="")
return str=this.utils.applyTextExpansions(str,!0)}
ContentDisplayBlogPost.prototype.pistachio=function(){return"{{> this.header}}\n<h2 class=\"sub-header\">{{> this.back}}</h2>\n<div class='kdview content-display-main-section activity-item blog-post'>\n  <span>\n    {{> this.avatar}}\n    <span class=\"author\">AUTHOR</span>\n  </span>\n  <div class='activity-item-right-col'>\n    <h3 class='blog-post-title'>{{this.applyTextExpansions(#(title))}}</h3>\n    <p class=\"blog-post-body has-markdown\">{{KD.utils.applyMarkdown(Encoder.htmlDecode(#(body)))}}</p>\n    <footer class='clearfix'>\n      <div class='type-and-time'>\n        <span class='type-icon'></span> {{> this.contentGroupLink}} by {{> this.author}}\n        <time>{{$.timeago(#(meta.createdAt))}}</time>\n        {{> this.tags}}\n      </div>\n      {{> this.actionLinks}}\n    </footer>\n    {{> this.commentBox}}\n  </div>\n</div>"}
return ContentDisplayBlogPost}(ActivityContentDisplay)
StaticBlogPostListItem=function(_super){function StaticBlogPostListItem(options,data){StaticBlogPostListItem.__super__.constructor.call(this,options,data)
this.postDate=new Date(this.getData().meta.createdAt)
this.postDate=this.postDate.toLocaleString()
this.setClass("content-item")}__extends(StaticBlogPostListItem,_super)
StaticBlogPostListItem.prototype.viewAppended=function(){log("viewAppended")
StaticBlogPostListItem.__super__.viewAppended.apply(this,arguments)
this.setTemplate(this.pistachio())
return this.template.update()}
StaticBlogPostListItem.prototype.pistachio=function(){return'<div class="title"><span class="text">'+this.getData().title+'</span><span class="create-date">'+this.postDate+'</span></div>\n<div class="has-markdown">\n  <span class="data">'+Encoder.htmlDecode(this.getData().html)+"</span>\n</div>"}
return StaticBlogPostListItem}(KDListItemView)

var ContentDisplayQuestionTopic,ContentDisplayQuestionUpdate,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayQuestionUpdate=function(_super){function ContentDisplayQuestionUpdate(){ContentDisplayQuestionUpdate.__super__.constructor.apply(this,arguments)
this.setClass("activity-item firstpost postauthor clearfix")}__extends(ContentDisplayQuestionUpdate,_super)
ContentDisplayQuestionUpdate.prototype.viewAppended=function(){var activity,_this=this
activity=this.getData()
return Cacheable.account.id(activity.origin).ready(function(error,account){_this.addSubView(new ContentDisplayAuthorAvatar({},{activity:activity,account:account}))
return _this.addSubView(new ContentDisplayQuestionTopic({cssClass:"topictext"},{activity:activity,account:account}))})}
return ContentDisplayQuestionUpdate}(KDView)
ContentDisplayQuestionTopic=function(_super){function ContentDisplayQuestionTopic(){_ref=ContentDisplayQuestionTopic.__super__.constructor.apply(this,arguments)
return _ref}__extends(ContentDisplayQuestionTopic,_super)
ContentDisplayQuestionTopic.prototype.viewAppended=function(){var account,activity,_ref1
_ref1=this.getData(),activity=_ref1.activity,account=_ref1.account
this.addSubView(new KDCustomHTMLView("p").setPartial("title: "+activity.questionTitle))
this.addSubView(new KDCustomHTMLView("p").setPartial("content: "+activity.questionContent))
this.addSubView(new ContentDisplayMeta({cssClass:"topicmeta"},this.getData()))
return this.addSubView(new ContentDisplayComments({},this.getData()))}
return ContentDisplayQuestionTopic}(KDView)

var ContentDisplayLink,ContentDisplayLinkTopic,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayLink=function(_super){function ContentDisplayLink(){ContentDisplayLink.__super__.constructor.apply(this,arguments)
this.setClass("activity-item firstpost postauthor clearfix")}__extends(ContentDisplayLink,_super)
ContentDisplayLink.prototype.viewAppended=function(){var activity,_this=this
activity=this.getData()
return Cacheable.account.id(activity.origin).ready(function(error,account){_this.addSubView(new ContentDisplayAuthorAvatar({},{activity:activity,account:account}))
return _this.addSubView(new ContentDisplayLinkTopic({cssClass:"topictext"},{activity:activity,account:account}))})}
return ContentDisplayLink}(KDView)
ContentDisplayLinkTopic=function(_super){function ContentDisplayLinkTopic(){_ref=ContentDisplayLinkTopic.__super__.constructor.apply(this,arguments)
return _ref}__extends(ContentDisplayLinkTopic,_super)
ContentDisplayLinkTopic.prototype.viewAppended=function(){var account,activity,_ref1
_ref1=this.getData(),activity=_ref1.activity,account=_ref1.account
this.addSubView(new KDCustomHTMLView("p").setPartial("title: "+activity.link))
this.addSubView(new KDCustomHTMLView("p").setPartial("link: "+activity.body))
this.addSubView(new ContentDisplayMeta({cssClass:"topicmeta"},this.getData()))
return this.addSubView(new ContentDisplayComments({},this.getData()))}
return ContentDisplayLinkTopic}(KDView)

var ActiveTopics,ActiveUsers,ActivityRightBase,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityRightBase=function(_super){function ActivityRightBase(options,data){null==options&&(options={})
ActivityRightBase.__super__.constructor.call(this,options,data)
this.tickerController=new KDListViewController({startWithLazyLoader:!0,lazyLoaderOptions:{partial:""},viewOptions:{type:"activities",cssClass:"activities",itemClass:this.itemClass}})
this.tickerListView=this.tickerController.getView()}__extends(ActivityRightBase,_super)
ActivityRightBase.prototype.renderItems=function(err,items){var item,_i,_len,_results
null==items&&(items=[])
this.tickerController.hideLazyLoader()
if(!err){_results=[]
for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
_results.push(this.tickerController.addItem(item))}return _results}}
ActivityRightBase.prototype.pistachio=function(){return'<div class="right-block-box">\n  <h3>'+this.getOption("title")+"{{> this.showAllLink}}</h3>\n  {{> this.tickerListView}}\n</div>"}
return ActivityRightBase}(JView)
ActiveUsers=function(_super){function ActiveUsers(options,data){null==options&&(options={})
this.itemClass=ActiveUserItemView
options.title="Active Koders"
options.cssClass="active-users"
ActiveUsers.__super__.constructor.call(this,options,data)
this.showAllLink=new KDCustomHTMLView({tagName:"a",partial:"show all",cssClass:"show-all-link hidden",click:function(){return KD.singletons.router.handleRoute("/Members")}},data)
KD.remote.api.ActiveItems.fetchUsers({},this.bound("renderItems"))}__extends(ActiveUsers,_super)
return ActiveUsers}(ActivityRightBase)
ActiveTopics=function(_super){function ActiveTopics(options,data){null==options&&(options={})
this.itemClass=ActiveTopicItemView
options.title="Popular Topics"
options.cssClass="active-topics"
ActiveTopics.__super__.constructor.call(this,options,data)
this.showAllLink=new KDCustomHTMLView({tagName:"a",partial:"show all",cssClass:"show-all-link",click:function(){return KD.singletons.router.handleRoute("/Topics")}},data)
KD.remote.api.ActiveItems.fetchTopics({},this.bound("renderItems"))}__extends(ActiveTopics,_super)
return ActiveTopics}(ActivityRightBase)

var ActivityTicker,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child},__indexOf=[].indexOf||function(item){for(var i=0,l=this.length;l>i;i++)if(i in this&&this[i]===item)return i
return-1}
ActivityTicker=function(_super){function ActivityTicker(options,data){var group,_this=this
null==options&&(options={})
options.cssClass=KD.utils.curry("activity-ticker",options.cssClass)
ActivityTicker.__super__.constructor.call(this,options,data)
this.filters=null
this.listController=new KDListViewController({lazyLoadThreshold:.99,lazyLoaderOptions:{partial:""},viewOptions:{type:"activities",cssClass:"activities",itemClass:ActivityTickerItem}})
this.showAllLink=new KDCustomHTMLView
this.listView=this.listController.getView()
this.listController.on("LazyLoadThresholdReached",this.bound("continueLoading"))
this.settingsButton=new KDButtonViewWithMenu({cssClass:"ticker-settings-menu",title:"",icon:!0,iconClass:"arrow",delegate:this,menu:this.settingsMenu(data),callback:function(event){return _this.settingsButton.contextMenu(event)}})
this.indexedItems={}
group=KD.getSingleton("groupsController")
group.on("MemberJoinedGroup",this.bound("addJoin"))
group.on("LikeIsAdded",this.bound("addLike"))
group.on("FollowHappened",this.bound("addFollow"))
group.on("PostIsCreated",this.bound("addActivity"))
group.on("PostIsDeleted",this.bound("deleteActivity"))
this.listController.listView.on("ItemWasAdded",function(view){var itemId,viewData
if(viewData=view.getData()){itemId=_this.getItemId(viewData)
return _this.indexedItems[itemId]=view}})
this.load({})}__extends(ActivityTicker,_super)
ActivityTicker.prototype.settingsMenu=function(){var filterSelected,menu,_this=this
filterSelected=function(filters){var tryCount
null==filters&&(filters=[])
_this.listController.removeAllItems()
_this.indexedItems={}
tryCount=0
return _this.load({filters:filters,tryCount:tryCount})}
menu={All:{callback:function(){return filterSelected()}},Follower:{callback:function(){return filterSelected(["follower"])}},Like:{callback:function(){return filterSelected(["like"])}},Member:{callback:function(){return filterSelected(["member"])}},App:{callback:function(){return filterSelected(["user"])}}}
return menu}
ActivityTicker.prototype.getConstructorName=function(obj){return obj&&obj.bongo_&&obj.bongo_.constructorName?obj.bongo_.constructorName:null}
ActivityTicker.prototype.fetchTags=function(data,callback){return data?data.tags?callback(null,data.tags):data.fetchTags(callback):callback(null,null)}
ActivityTicker.prototype.addActivity=function(data){var as,origin,source,subject,target,_this=this
origin=data.origin,subject=data.subject
if(!this.isFiltered("activity")){if(!this.getConstructorName(origin)||!this.getConstructorName(subject))return console.warn("data is not valid")
source=KD.remote.revive(subject)
target=KD.remote.revive(origin)
as="author"
return this.fetchTags(source,function(err,tags){if(err)return log("discarding event, invalid data")
source.tags=tags
return _this.addNewItem({source:source,target:target,as:as})})}}
ActivityTicker.prototype.deleteActivity=function(data){var as,origin,source,subject,target
origin=data.origin,subject=data.subject
if(!this.isFiltered("activity")){if(!this.getConstructorName(origin)||!this.getConstructorName(subject))return console.warn("data is not valid")
source=KD.remote.revive(subject)
target=KD.remote.revive(origin)
as="author"
return this.removeItem({source:source,target:target,as:as})}}
ActivityTicker.prototype.addJoin=function(data){var constructorName,id,member,_this=this
member=data.member
if(!this.isFiltered("member")){if(!member)return console.warn("member is not defined in new member event")
constructorName=member.constructorName,id=member.id
return KD.remote.cacheable(constructorName,id,function(err,account){var source
if(err||!account)return console.error("account is not found",err)
source=KD.getSingleton("groupsController").getCurrentGroup()
return _this.addNewItem({as:"member",target:account,source:source})})}}
ActivityTicker.prototype.addFollow=function(data){var constructorName,follower,id,origin,_this=this
follower=data.follower,origin=data.origin
if(!this.isFiltered("follower")){if(!follower||!origin)return console.warn("data is not valid")
constructorName=follower.constructorName,id=follower.id
return KD.remote.cacheable(constructorName,id,function(err,source){var _ref,_ref1
if(err||!source)return console.log("account is not found")
_ref=data.origin,id=_ref._id,_ref1=_ref.bongo_,constructorName=_ref1.constructorName
return KD.remote.cacheable(constructorName,id,function(err,target){var eventObj
if(err||!target)return console.log("account is not found")
eventObj={source:target,target:source,as:"follower"}
"JTag"===constructorName&&(eventObj={source:target,target:source,as:"follower"})
return _this.addNewItem(eventObj)})})}}
ActivityTicker.prototype.addLike=function(data){var constructorName,id,liker,origin,subject,_this=this
liker=data.liker,origin=data.origin,subject=data.subject
if(!this.isFiltered("like")){if(!(liker&&origin&&subject))return console.warn("data is not valid")
constructorName=liker.constructorName,id=liker.id
return KD.remote.cacheable(constructorName,id,function(err,source){if(err||!source)return console.log("account is not found",err,liker)
id=origin._id
return KD.remote.cacheable("JAccount",id,function(err,target){if(err||!target)return console.log("account is not found",err,origin)
constructorName=subject.constructorName,id=subject.id
return KD.remote.cacheable(constructorName,id,function(err,subject){var eventObj
if(err||!subject)return console.log("subject is not found",err,data.subject)
eventObj={source:source,target:target,subject:subject,as:"like"}
return"JNewStatusUpdate"===subject.bongo_.constructorName?_this.fetchTags(subject,function(err,tags){if(err)return log("discarding event, invalid data")
subject.tags=tags
return _this.addNewItem(eventObj)}):_this.addNewItem(eventObj)})})})}}
ActivityTicker.prototype.addComment=function(data){var constructorName,id,origin,replier,reply,subject,_this=this
origin=data.origin,reply=data.reply,subject=data.subject,replier=data.replier
if(!this.isFiltered("comment")){if(!(replier&&origin&&subject&&reply))return console.warn("data is not valid")
constructorName=replier.constructorName,id=replier.id
return KD.remote.cacheable(constructorName,id,function(err,source){if(err||!source)return console.log("account is not found",err,liker)
id=origin._id
return KD.remote.cacheable("JAccount",id,function(err,target){if(err||!target)return console.log("account is not found",err,origin)
constructorName=subject.constructorName,id=subject.id
return KD.remote.cacheable(constructorName,id,function(err,subject){if(err||!subject)return console.log("subject is not found",err,data.subject)
constructorName=reply.constructorName,id=reply.id
return KD.remote.cacheable(constructorName,id,function(err,object){var eventObj
if(err||!object)return console.log("reply is not found",err,data.reply)
eventObj={source:source,target:target,subject:subject,object:object,as:"reply"}
return _this.addNewItem(eventObj)})})})})}}
ActivityTicker.prototype.continueLoading=function(loadOptions){null==loadOptions&&(loadOptions={})
loadOptions["continue"]=this.filters
return this.load(loadOptions)}
ActivityTicker.prototype.filterItem=function(item){var as,source,sourceNickname,target,targetNickname
as=item.as,source=item.source,target=item.target
return source&&target&&as?source.profile&&(sourceNickname=source.profile.nickname)&&/^guest-/.test(sourceNickname)?null:target.profile&&(targetNickname=target.profile.nickname)&&/^guest-/.test(targetNickname)?null:"JNewStatusUpdate"===this.getConstructorName(source)&&"JAccount"===this.getConstructorName(target)&&"follower"===as?null:item:null}
ActivityTicker.prototype.tryLoadingAgain=function(loadOptions){null==loadOptions&&(loadOptions={})
if(null==loadOptions.tryCount)return warn("Current try count is not defined, discarding request")
if(loadOptions.tryCount>=10)return warn("Reached max re-tries for What is Happening widget")
loadOptions.tryCount++
return this.load(loadOptions)}
ActivityTicker.prototype.load=function(loadOptions){var lastItem,lastItemTimestamp,timestamp,_this=this
null==loadOptions&&(loadOptions={})
loadOptions.tryCount=loadOptions.tryCount||0
loadOptions.filters&&(this.filters=loadOptions.filters)
loadOptions["continue"]&&(this.filters=loadOptions.filters=loadOptions["continue"])
lastItem=this.listController.getItemsOrdered().last
if(lastItem&&(timestamp=lastItem.getData().timestamp)){lastItemTimestamp=new Date(timestamp).getTime()
loadOptions.from=lastItemTimestamp}return KD.remote.api.ActivityTicker.fetch(loadOptions,function(err,items){var item,_i,_len
null==items&&(items=[])
_this.listController.hideLazyLoader()
if(err){warn(err)
return _this.tryLoadingAgain(loadOptions)}for(_i=0,_len=items.length;_len>_i;_i++){item=items[_i]
_this.filterItem(item)&&_this.addNewItem(item,_this.listController.getItemCount())}return _this.listController.getItemCount()<15?_this.tryLoadingAgain(loadOptions):void 0})}
ActivityTicker.prototype.pistachio=function(){return'<div class="activity-ticker right-block-box">\n  <h3>What\'s happening on Koding {{> this.settingsButton}}</h3>\n  {{> this.listView}}\n</div>'}
ActivityTicker.prototype.addNewItem=function(newItem,index){var itemId,viewItem
null==index&&(index=0)
itemId=this.getItemId(newItem)
if(this.indexedItems[itemId]){viewItem=this.indexedItems[itemId]
return this.listController.moveItemToIndex(viewItem,0)}return null!=index?this.listController.addItem(newItem,index):this.listController.addItem(newItem)}
ActivityTicker.prototype.removeItem=function(item){var itemId,viewItem
itemId=this.getItemId(item)
if(this.indexedItems[itemId]){viewItem=this.indexedItems[itemId]
return this.listController.removeItem(viewItem)}}
ActivityTicker.prototype.getItemId=function(item){var as,source,subject,target
source=item.source,target=item.target,subject=item.subject,as=item.as
return""+source.getId()+"_"+target.getId()+"_"+as+"_"+(null!=subject?subject.getId():void 0)}
ActivityTicker.prototype.isFiltered=function(filter){return this.filters&&this.filters.length?__indexOf.call(this.filters,filter)<0?!0:!1:!1}
return ActivityTicker}(ActivityRightBase)

var ContentDisplayAuthorAvatar,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayAuthorAvatar=function(_super){function ContentDisplayAuthorAvatar(options){options||(options={})
options.tagName="span"
ContentDisplayAuthorAvatar.__super__.constructor.apply(this,arguments)}__extends(ContentDisplayAuthorAvatar,_super)
ContentDisplayAuthorAvatar.prototype.viewAppended=function(){var account
account=this.getData().account
return this.setPartial(this.partial(account))}
ContentDisplayAuthorAvatar.prototype.click=function(){var account
account=this.getData().account
return KD.getSingleton("appManager").tell("Members","createContentDisplay",account)}
ContentDisplayAuthorAvatar.prototype.partial=function(account){var fallbackUrl,hash,host
hash=account.profile.hash
host="//"+location.host+"/"
fallbackUrl="url(http://www.gravatar.com/avatar/"+hash+"?size=40&d="+encodeURIComponent(host+"/images/defaultavatar/default.avatar.40.png")+")"
return"<span href='' style='background-image:"+fallbackUrl+';\'></span>\n<span class="author">AUTHOR</span>'}
return ContentDisplayAuthorAvatar}(KDCustomHTMLView)

var ContentDisplayMeta,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayMeta=function(_super){function ContentDisplayMeta(){_ref=ContentDisplayMeta.__super__.constructor.apply(this,arguments)
return _ref}__extends(ContentDisplayMeta,_super)
ContentDisplayMeta.prototype.viewAppended=function(){var account,activity,_ref1
this.unsetClass("kdview")
_ref1=this.getData(),activity=_ref1.activity,account=_ref1.account
return this.setPartial(this.partial(activity,account))}
ContentDisplayMeta.prototype.click=function(event){var account
if($(event.target).is("a")){account=this.getData().account
return KD.getSingleton("appManager").tell("Members","createContentDisplay",account)}}
ContentDisplayMeta.prototype.partial=function(activity,account){var dom,name
name=KD.utils.getFullnameFromAccount(account,!0)
dom=$("<div>In "+activity.group+' by <a href="#">'+name+"</a> <time class='timeago' datetime=\""+new Date(activity.meta.createdAt).format("isoUtcDateTime")+'"></time></div>')
dom.find("time.timeago").timeago()
return dom}
return ContentDisplayMeta}(KDView)

var ContentDisplayTags,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayTags=function(_super){function ContentDisplayTags(){_ref=ContentDisplayTags.__super__.constructor.apply(this,arguments)
return _ref}__extends(ContentDisplayTags,_super)
ContentDisplayTags.prototype.tags=["linux","ubuntu","gentoo","arch","debian","distro","macosx","windows"]
ContentDisplayTags.prototype.viewAppended=function(){var data
this.setData(this.tags)
data=this.getData()
return this.setPartial(this.partial(data))}
ContentDisplayTags.prototype.partial=function(data){var index,max,partial,tag,_i,_len
partial=""
max=__utils.getRandomNumber(11)
for(index=_i=0,_len=data.length;_len>_i;index=++_i){tag=data[index]
max>index&&(partial+="<span class='tag'>"+tag+"</span>")}return partial}
return ContentDisplayTags}(KDView)

var ContentDisplayComments,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayComments=function(_super){function ContentDisplayComments(options,data){ContentDisplayComments.__super__.constructor.apply(this,arguments)
this.commentView=new CommentView({},data)
this.activityActions=new ActivityActionsView({delegate:this.commentView.commentList,cssClass:"comment-header"},data)}__extends(ContentDisplayComments,_super)
ContentDisplayComments.prototype.pistachio=function(){return"{{> this.activityActions}}\n{{> this.commentView}}"}
return ContentDisplayComments}(JView)

var ContentDisplayScoreBoard,_ref,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ContentDisplayScoreBoard=function(_super){function ContentDisplayScoreBoard(){_ref=ContentDisplayScoreBoard.__super__.constructor.apply(this,arguments)
return _ref}__extends(ContentDisplayScoreBoard,_super)
ContentDisplayScoreBoard.prototype.viewAppended=function(){return this.setPartial(this.partial(this.getData()))}
ContentDisplayScoreBoard.prototype.partial=function(){return"<p>8 <span>Responses</span></p>\n<p>45 <span>Likes</span></p>\n<p>1234 <span>Views</span></p>"}
return ContentDisplayScoreBoard}(KDView)

var ActivityListItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
ActivityListItemView=function(_super){function ActivityListItemView(options,data){var constructorName
null==options&&(options={})
options.type="activity"
ActivityListItemView.__super__.constructor.call(this,options,data)
constructorName=data.bongo_.constructorName
this.setClass(getActivityChildCssClass()[constructorName])
this.bindTransitionEnd()}var getActivityChildConstructors,getActivityChildCssClass,getBucketMap
__extends(ActivityListItemView,_super)
getActivityChildConstructors=function(){return{JNewStatusUpdate:StatusActivityItemView,NewMemberBucketData:NewMemberBucketView}}
getActivityChildCssClass=function(){return"system-message"}
getBucketMap=function(){return{JAccount:AccountFollowBucketItemView,JTag:TagFollowBucketItemView,JNewApp:AppFollowBucketItemView}}
ActivityListItemView.prototype.viewAppended=function(){return this.addChildView(this.getData())}
ActivityListItemView.prototype.addChildView=function(data,callback){var childConstructor,childView,constructorName
if(null!=data?data.bongo_:void 0){constructorName=data.bongo_.constructorName
childConstructor=/^CNewMemberBucket$/.test(constructorName)?NewMemberBucketItemView:/Bucket$/.test(constructorName)?getBucketMap()[data.sourceName]:getActivityChildConstructors()[constructorName]
if(childConstructor){childView=new childConstructor({delegate:this},data)
this.addSubView(childView)
return"function"==typeof callback?callback():void 0}}}
ActivityListItemView.prototype.partial=function(){return""}
ActivityListItemView.prototype.show=function(){var _base,_this=this
return"function"==typeof(_base=this.getData()).fetchTeaser?_base.fetchTeaser(function(err,teaser){return teaser?_this.addChildView(teaser,function(){return _this.slideIn()}):void 0}):void 0}
ActivityListItemView.prototype.slideIn=function(callback){null==callback&&(callback=noop)
this.once("transitionend",callback.bind(this))
return this.unsetClass("hidden-item")}
ActivityListItemView.prototype.slideOut=function(callback){null==callback&&(callback=noop)
this.once("transitionend",callback.bind(this))
return this.setClass("hidden-item")}
return ActivityListItemView}(KDListItemView)

var StatusActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
StatusActivityItemView=function(_super){function StatusActivityItemView(options,data){var embedOptions
null==options&&(options={})
null==data&&(data={})
options.cssClass||(options.cssClass="activity-item status")
options.tooltip||(options.tooltip={title:"Status Update",selector:"span.type-icon",offset:{top:3,left:-5}})
StatusActivityItemView.__super__.constructor.call(this,options,data)
embedOptions={hasDropdown:!1,delegate:this}
if(null!=data.link){this.embedBox=new EmbedBox(embedOptions,data.link)
this.twoColumns&&this.setClass("two-columns")}else this.embedBox=new KDCustomHTMLView
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)
this.editWidgetWrapper=new KDCustomHTMLView({cssClass:"edit-widget-wrapper hidden"})}__extends(StatusActivityItemView,_super)
StatusActivityItemView.prototype.formatContent=function(str){null==str&&(str="")
str=this.utils.applyMarkdown(str)
str=this.utils.expandTokens(str,this.getData())
return str}
StatusActivityItemView.prototype.viewAppended=function(){var _this=this
if(this.getData().constructor!==KD.remote.api.CStatusActivity){StatusActivityItemView.__super__.viewAppended.apply(this,arguments)
this.setTemplate(this.pistachio())
this.template.update()
return this.utils.defer(function(){var predicate,_ref
predicate=null!=(null!=(_ref=_this.getData().link)?_ref.link_url:void 0)&&""!==_this.getData().link.link_url
return predicate?_this.embedBox.show():_this.embedBox.hide()})}}
StatusActivityItemView.prototype.pistachio=function(){return'{{> this.avatar}}\n{{> this.settingsButton}}\n{{> this.author}}\n{{> this.editWidgetWrapper}}\n<span class="status-body">{{this.formatContent(#(body))}}</span>\n{{> this.embedBox}}\n<footer>\n  {{> this.actionLinks}}\n  {{> this.timeAgoView}}\n</footer>\n{{> this.commentBox}}'}
return StatusActivityItemView}(ActivityItemChild)

var CodeSnippetView,CodesnipActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
CodesnipActivityItemView=function(_super){function CodesnipActivityItemView(options,data){var codeSnippetData,_ref
options=$.extend({cssClass:"activity-item codesnip",tooltip:{title:"Code Snippet",offset:{top:3,left:-5},selector:"span.type-icon"}},options)
CodesnipActivityItemView.__super__.constructor.call(this,options,data)
codeSnippetData=(null!=(_ref=this.getData().attachments)?_ref[0]:void 0)||""
codeSnippetData.title=this.getData().title
this.getData().fake&&(codeSnippetData.content=Encoder.htmlEncode(codeSnippetData.content))
this.codeSnippetView=new CodeSnippetView({},codeSnippetData)}__extends(CodesnipActivityItemView,_super)
CodesnipActivityItemView.prototype.render=function(){var codeSnippetData
CodesnipActivityItemView.__super__.render.call(this)
codeSnippetData=this.getData().attachments[0]
codeSnippetData.title=this.getData().title
this.codeSnippetView.setData(codeSnippetData)
return this.codeSnippetView.render()}
CodesnipActivityItemView.prototype.click=function(event){var entryPoint
CodesnipActivityItemView.__super__.click.apply(this,arguments)
if($(event.target).is(".activity-item-right-col h3")){entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+this.getData().slug,{state:this.getData(),entryPoint:entryPoint})}}
CodesnipActivityItemView.prototype.viewAppended=function(){var _this=this
if(this.getData().constructor!==KD.remote.api.CCodeSnipActivity){CodesnipActivityItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
return this.codeSnippetView.$().hover(function(){return _this.enableScrolling=setTimeout(function(){_this.codeSnippetView.codeView.setClass("scrollable-y")
return _this.codeSnippetView.setClass("scroll-highlight out")},1e3)},function(){clearTimeout(_this.enableScrolling)
_this.codeSnippetView.codeView.unsetClass("scrollable-y")
return _this.codeSnippetView.unsetClass("scroll-highlight out")})}}
CodesnipActivityItemView.prototype.pistachio=function(){return'{{> this.avatar}}\n<div class="activity-item-right-col">\n  <span class="author-name">{{> this.author}}</span>\n  <p class="status-body">{{this.utils.applyTextExpansions(#(body), true)}}</p>\n  {{> this.codeSnippetView}}\n</div>\n<footer>\n  {{> this.actionLinks}}\n  {time{$.timeago(#(meta.createdAt))}}\n</footer>\n{{> this.commentBox}}'}
return CodesnipActivityItemView}(ActivityItemChild)
CodeSnippetView=function(_super){function CodeSnippetView(options,data){var content,hjsSyntax,syntax,title,__aceSettings,_ref,_ref1,_ref2,_this=this
options.tagName="figure"
options.cssClass="code-container"
CodeSnippetView.__super__.constructor.apply(this,arguments)
this.unsetClass("kdcustomhtml")
_ref=data=this.getData(),content=_ref.content,syntax=_ref.syntax,title=_ref.title
hjsSyntax=[]
__aceSettings={syntaxAssociations:{javascript:[]}}
this.codeView=new KDCustomHTMLView({cssClass:"",tagName:"code",pistachio:"{{#(content)}}"},data)
this.syntaxMode=new KDCustomHTMLView({tagName:"strong",partial:null!=(_ref1=(null!=(_ref2=__aceSettings.syntaxAssociations[syntax])?_ref2[0]:void 0)||syntax)?_ref1:"text"})
this.saveButton=new KDButtonView({title:"",style:"dark",icon:!0,iconOnly:!0,iconClass:"save",tooltip:{title:"Save"},callback:function(){var fileName,fullPath,rootPath
rootPath="Documents/CodeSnippets"
fileName=""+this.utils.slugify(title)+"."+__aceSettings.syntaxAssociations[syntax][1].split("|")[0]
fullPath=""+rootPath+"/"+fileName
return FSHelper.createRecursiveFolder({path:rootPath},function(){var file
file=FSHelper.createFileFromPath(""+fullPath)
content=Encoder.htmlDecode(content)
return file.save(content,function(){var link,notificationTitle
notificationTitle=new KDView({partial:"Your file is saved into Documents/CodeSnippets"})
notificationTitle.addSubView(link=new KDCustomHTMLView({tagName:"a",partial:"Click here to open.",cssClass:"code-share-open",click:function(){return KD.getSingleton("appManager").openFile(file)}}))
return new KDNotificationView({title:notificationTitle,type:"mini",cssClass:"success",duration:4e3})})})}})
this.openButton=new KDButtonView({title:"",style:"dark",icon:!0,iconOnly:!0,iconClass:"open",tooltip:{title:"Open"},callback:function(){var file,fileName,_ref3
_ref3=_this.getData(),title=_ref3.title,content=_ref3.content,syntax=_ref3.syntax
fileName="localfile:/"+title
file=FSHelper.createFileFromPath(fileName)
file.contents=Encoder.htmlDecode(content)
file.syntax=syntax
return KD.getSingleton("appManager").openFile(file)}})
this.copyButton=new KDButtonView({title:"",style:"dark",icon:!0,iconOnly:!0,iconClass:"select-all",tooltip:{title:"Select All"},callback:function(){return _this.utils.selectText(_this.codeView.$()[0])}})}var openFileIteration
__extends(CodeSnippetView,_super)
openFileIteration=0
CodeSnippetView.prototype.render=function(){CodeSnippetView.__super__.render.call(this)
this.codeView.setData(this.getData())
this.codeView.render()
return this.applySyntaxColoring()}
CodeSnippetView.prototype.applySyntaxColoring=function(syntax){var err,snipView
null==syntax&&(syntax=this.getData().syntax)
snipView=this
try{return hljs.highlightBlock(snipView.codeView.$()[0],"  ")}catch(_error){err=_error
return warn("Error applying highlightjs syntax "+syntax+":",err)}}
CodeSnippetView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
this.template.update()
return this.applySyntaxColoring()}
CodeSnippetView.prototype.pistachio=function(){return"<div class='kdview'>\n  {pre{> this.codeView}}\n  <div class='button-bar'>{{> this.saveButton}}{{> this.openButton}}{{> this.copyButton}}</div>\n</div>\n{{> this.syntaxMode}}"}
return CodeSnippetView}(KDCustomHTMLView)

var BlogPostActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BlogPostActivityItemView=function(_super){function BlogPostActivityItemView(options,data){var _this=this
null==options&&(options={})
null==data&&(data={})
options.cssClass||(options.cssClass="activity-item blog-post")
options.tooltip||(options.tooltip={title:"Blog Post",selector:"span.type-icon",offset:{top:3,left:-5}})
BlogPostActivityItemView.__super__.constructor.call(this,options,data)
this.readThisLink=new CustomLinkView({title:this.getData().title||"Read this Blog Post",click:function(event){var entryPoint
event.stopPropagation()
event.preventDefault()
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+_this.getData().slug,{state:_this.getData(),entryPoint:entryPoint})}})}__extends(BlogPostActivityItemView,_super)
BlogPostActivityItemView.prototype.viewAppended=function(){if(this.getData().constructor!==KD.remote.api.CBlogPostActivity){BlogPostActivityItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
return this.template.update()}}
BlogPostActivityItemView.prototype.applyTextExpansions=function(str){null==str&&(str="")
return str=this.utils.applyTextExpansions(str,!0)}
BlogPostActivityItemView.prototype.pistachio=function(){return'{{> this.avatar}}\n<div class="activity-item-right-col">\n  <span class="author-name">{{> this.author}}</span>\n  <h3 class="blog-post-title">{{> this.readThisLink}}</h3>\n  <p class="body no-scroll has-markdown force-small-markdown">\n    {{this.utils.shortenText(this.utils.applyMarkdown(Encoder.htmlDecode(#(body))))}}\n  </p>\n</div>\n<footer>\n  {{> this.actionLinks}}\n  <time>{{$.timeago(#(meta.createdAt))}}</time>\n</footer>\n{{> this.commentBox}}'}
return BlogPostActivityItemView}(ActivityItemChild)

var DiscussionActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
DiscussionActivityItemView=function(_super){function DiscussionActivityItemView(options,data){var _this=this
if(null==data.opinionCount){data.opinionCount=data.repliesCount||0
data.repliesCount=0}options=$.extend({cssClass:"activity-item discussion",tooltip:{title:"Discussion",offset:{top:3,left:-5},selector:"span.type-icon"}},options)
DiscussionActivityItemView.__super__.constructor.call(this,options,data)
this.actionLinks=new DiscussionActivityActionsView({delegate:this.commentBox.opinionList,cssClass:"reply-header"},data)
data.on("ReplyIsAdded",function(reply){return"JDiscussion"===data.bongo_.constructorName?_this.opinionBox.opinionList.emit("NewOpinionHasArrived",reply):void 0})
this.opinionBox=new DiscussionActivityOpinionView({cssClass:"activity-opinion-list comment-container"},data)
data.on("ReplyIsRemoved",function(replyId){var i,item,_i,_len,_ref
_ref=_this.opinionBox.opinionList.items
for(i=_i=0,_len=_ref.length;_len>_i;i=++_i){item=_ref[i]
if((null!=item?item.getData()._id:void 0)===replyId){item.hide()
item.destroy()}}return _this.opinionBox.opinionList.emit("OpinionIsDeleted")})
this.scrollAreaOverlay=new KDView({cssClass:"enable-scroll-overlay",partial:""})
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(DiscussionActivityItemView,_super)
DiscussionActivityItemView.prototype.viewAppended=function(){if(this.getData().constructor!==KD.remote.api.CDiscussionActivity){DiscussionActivityItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
this.highlightCode()
this.prepareExternalLinks()
return this.prepareScrollOverlay()}}
DiscussionActivityItemView.prototype.highlightCode=function(){return this.$("div.discussion-body-container span.data pre").each(function(i,element){return hljs.highlightBlock(element)})}
DiscussionActivityItemView.prototype.prepareExternalLinks=function(){return this.$("p.body a[href^=http]").attr("target","_blank")}
DiscussionActivityItemView.prototype.prepareScrollOverlay=function(){var _this=this
this.utils.defer(function(){var body,cachedHeight
body=_this.$("div.activity-content-container.discussion")
if(body.height()<parseInt(body.css("max-height"),10))return _this.scrollAreaOverlay.hide()
body.addClass("scrolling-down")
cachedHeight=body.height()
return body.scroll(function(){var distanceBottom,distanceTop,percentageBottom,percentageTop,triggerValues
percentageTop=100*body.scrollTop()/body[0].scrollHeight
percentageBottom=100*(cachedHeight+body.scrollTop())/body[0].scrollHeight
distanceTop=body.scrollTop()
distanceBottom=body[0].scrollHeight-(cachedHeight+body.scrollTop())
triggerValues={top:{percentage:.5,distance:15},bottom:{percentage:99.5,distance:15}}
if(percentageTop<triggerValues.top.percentage||distanceTop<triggerValues.top.distance){body.addClass("scrolling-down")
body.removeClass("scrolling-both")
body.removeClass("scrolling-up")}if(percentageBottom>triggerValues.bottom.percentage||distanceBottom<triggerValues.bottom.distance){body.addClass("scrolling-up")
body.removeClass("scrolling-both")
body.removeClass("scrolling-down")}if(percentageTop>=triggerValues.top.percentage&&percentageBottom<=triggerValues.bottom.percentage&&distanceBottom>triggerValues.bottom.distance&&distanceTop>triggerValues.top.distance){body.addClass("scrolling-both")
body.removeClass("scrolling-up")
return body.removeClass("scrolling-down")}})})
return this.$("div.activity-content-container").hover(function(){_this.transitionStart=setTimeout(function(){return _this.scrollAreaOverlay.$().css({top:"100%"})},500)
return _this.scrollAreaOverlay.$().hasClass("hidden")?void 0:_this.checkForCompleteAnimationInterval=setInterval(function(){if(parseInt(_this.scrollAreaOverlay.$().css("top"),10)+_this.$("div.discussion").scrollTop()>=_this.scrollAreaOverlay.$().height()){_this.scrollAreaOverlay.hide()
_this.$("div.discussion").addClass("scrollable-y scroll-highlight")
_this.$("div.discussion").removeClass("no-scroll")
if(null!=_this.checkForCompleteAnimationInterval)return clearInterval(_this.checkForCompleteAnimationInterval)}},50)},function(){if(!(parseInt(_this.scrollAreaOverlay.$().css("top"),10)>=_this.scrollAreaOverlay.$().height())){null!=_this.transitionStart&&clearTimeout(_this.transitionStart)
null!=_this.checkForCompleteAnimationInterval&&clearInterval(_this.checkForCompleteAnimationInterval)
_this.scrollAreaOverlay.$().css({top:"0px"})
_this.$("div.discussion").removeClass("scrollable-y scroll-highlight")
_this.$("div.discussion").addClass("no-scroll")
return _this.scrollAreaOverlay.show()}})}
DiscussionActivityItemView.prototype.render=function(){DiscussionActivityItemView.__super__.render.call(this)
this.highlightCode()
this.prepareExternalLinks()
return this.prepareScrollOverlay()}
DiscussionActivityItemView.prototype.click=function(event){var entryPoint
if($(event.target).is("[data-paths~=title]")){entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+this.getData().slug,{state:this.getData(),entryPoint:entryPoint})}}
DiscussionActivityItemView.prototype.applyTextExpansions=function(str){var visiblePart
null==str&&(str="")
str=this.utils.expandUsernames(str)
if((null!=str?str.length:void 0)>500){visiblePart=str.substr(0,500)
str=visiblePart+" ..."}return str}
DiscussionActivityItemView.prototype.pistachio=function(){return"<div class=\"activity-discussion-container\">\n  <span class=\"avatar\">{{> this.avatar}}</span>\n  <div class='activity-item-right-col'>\n    {{> this.settingsButton}}\n    <h3 class='comment-title'>{{this.applyTextExpansions(#(title))}}</h3>\n    <div class=\"activity-content-container discussion\">\n      <p class=\"body no-scroll has-markdown force-small-markdown\">\n        {{this.utils.expandUsernames(this.utils.applyMarkdown(#(body)))}}\n      </p>\n      {{> this.scrollAreaOverlay}}\n    </div>\n    <footer class='clearfix'>\n      <div class='type-and-time'>\n        <span class='type-icon'></span>{{> this.contentGroupLink}} by {{> this.author}}\n        {{> this.timeAgoView}}\n        {{> this.tags}}\n      </div>\n      {{> this.actionLinks}}\n    </footer>\n    {{> this.opinionBox}}\n  </div>\n</div>"}
return DiscussionActivityItemView}(ActivityItemChild)

var AccountFollowBucketItemView,AppFollowBucketItemView,FollowBucketItemView,NewMemberBucketView,TagFollowBucketItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
FollowBucketItemView=function(_super){function FollowBucketItemView(options,data){var _ref,_ref1
null==options&&(options={})
options.cssClass||(options.cssClass="follow bucket "+cssClassMap()[data.sourceName])
FollowBucketItemView.__super__.constructor.call(this,options,data)
this.action="followed"
"JNewApp"===(null!=(_ref=data.group[0])?_ref.constructorName:void 0)&&(this.action="installed")
this.anchor=new ProfileLinkView({origin:data.anchor})
this.group=new LinkGroup({group:data.group,itemClass:options.subItemLinkClass,separator:"JNewApp"===(_ref1=data.sourceName)||"JTag"===_ref1?" ":", "})}var cssClassMap
__extends(FollowBucketItemView,_super)
cssClassMap=function(){return{JTag:"topic",JAccount:"account",JNewApp:"application"}}
FollowBucketItemView.prototype.pistachio=function(){return"<span class='icon'></span>\n{{> this.anchor}}\n<span class='action'>"+this.action+"</span>\n{{> this.group}}"}
FollowBucketItemView.prototype.render=function(){}
FollowBucketItemView.prototype.addCommentBox=function(){}
FollowBucketItemView.prototype.viewAppended=function(){this.setTemplate(this.pistachio())
return this.template.update()}
return FollowBucketItemView}(KDView)
AccountFollowBucketItemView=function(_super){function AccountFollowBucketItemView(options){options.subItemLinkClass||(options.subItemLinkClass=ProfileLinkView)
options.subItemCssClass||(options.subItemCssClass="profile")
AccountFollowBucketItemView.__super__.constructor.apply(this,arguments)}__extends(AccountFollowBucketItemView,_super)
return AccountFollowBucketItemView}(FollowBucketItemView)
TagFollowBucketItemView=function(_super){function TagFollowBucketItemView(options){options.subItemLinkClass||(options.subItemLinkClass=TagLinkView)
options.subItemCssClass||(options.subItemCssClass="topic")
TagFollowBucketItemView.__super__.constructor.apply(this,arguments)}__extends(TagFollowBucketItemView,_super)
return TagFollowBucketItemView}(FollowBucketItemView)
AppFollowBucketItemView=function(_super){function AppFollowBucketItemView(options){options.subItemLinkClass||(options.subItemLinkClass=AppLinkView)
options.subItemCssClass||(options.subItemCssClass="profile")
AppFollowBucketItemView.__super__.constructor.apply(this,arguments)}__extends(AppFollowBucketItemView,_super)
return AppFollowBucketItemView}(FollowBucketItemView)
NewMemberBucketView=function(_super){function NewMemberBucketView(){NewMemberBucketView.__super__.constructor.apply(this,arguments)
this.action="became a member"}__extends(NewMemberBucketView,_super)
NewMemberBucketView.prototype.pistachio=function(){return"<span class='icon'></span>\n{{> this.group}}\n<span class='action'>"+this.action+"</span>"}
return NewMemberBucketView}(FollowBucketItemView)

var LinkActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
LinkActivityItemView=function(_super){function LinkActivityItemView(options,data){var embedOptions
null==options&&(options={})
options.cssClass||(options.cssClass="activity-item link")
options.tooltip||(options.tooltip={title:"Link",selector:"span.type-icon",offset:3})
LinkActivityItemView.__super__.constructor.call(this,options,data)
embedOptions=$.extend({},options,{delegate:this,hasDropdown:!1})
this.embedBox=new EmbedBox(embedOptions,data)
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(LinkActivityItemView,_super)
LinkActivityItemView.prototype.viewAppended=function(){if(this.getData().constructor!==KD.remote.api.CLinkActivity){LinkActivityItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
return null!=this.getData().link_embed?this.embedBox.embedExistingData(this.getData().link_embed):null!=this.getData().link_url?embedBox.embedUrl(this.getData().link_url):log("There is no link information to embed.")}}
LinkActivityItemView.prototype.applyTextExpansions=function(str){null==str&&(str="")
return this.utils.applyTextExpansions(str,!0)}
LinkActivityItemView.prototype.pistachio=function(){return"{{> this.settingsButton}}\n<span class=\"avatar\">{{> this.avatar}}</span>\n<div class='activity-item-right-col'>\n  <h3 class='hidden'></h3>\n  <h3><a href=\""+(this.getData().link_url||"#")+"\" target=\"_blank\">{{this.applyTextExpansions(#(title))}}</a></h3>\n  <p>{{this.applyTextExpansions(#(body))}}</p>\n  {{> this.embedBox}}\n  <footer class='clearfix'>\n    <div class='type-and-time'>\n      <span class='type-icon'></span>{{> this.contentGroupLink}} by {{> this.author}}\n      {{> this.timeAgoView}}\n      {{> this.tags}}\n    </div>\n    {{> this.actionLinks}}\n  </footer>\n  {{> this.commentBox}}\n</div>"}
return LinkActivityItemView}(ActivityItemChild)

var TutorialActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
TutorialActivityItemView=function(_super){function TutorialActivityItemView(options,data){var _ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_ref7,_this=this
if(null==data.opinionCount){data.opinionCount=data.repliesCount||0
data.repliesCount=0}options=$.extend({cssClass:"activity-item tutorial",tooltip:{title:"Tutorial",offset:{top:3,left:-5},selector:"span.type-icon"}},options)
TutorialActivityItemView.__super__.constructor.call(this,options,data)
this.embedOptions=$.extend({},options,{hasDropdown:!1,delegate:this})
this.actionLinks=new TutorialActivityActionsView({delegate:this.commentBox.opinionList,cssClass:"reply-header"},data)
this.previewImage=new KDCustomHTMLView({tagName:"img",cssClass:"tutorial-preview-image",attributes:{src:this.utils.proxifyUrl((null!=(_ref=data.link)?null!=(_ref1=_ref.link_embed)?null!=(_ref2=_ref1.images)?null!=(_ref3=_ref2[0])?_ref3.url:void 0:void 0:void 0:void 0)||""),title:"View the full Tutorial",alt:"View the full tutorial","data-paths":"preview"}});(null!=(_ref4=data.link)?null!=(_ref5=_ref4.link_embed)?null!=(_ref6=_ref5.images)?null!=(_ref7=_ref6[0])?_ref7.url:void 0:void 0:void 0:void 0)||this.previewImage.hide()
data.on("ReplyIsAdded",function(){return"JTutorial"===data.bongo_.constructorName?_this.opinionBox.opinionList.emit("NewOpinionHasArrived"):void 0})
this.opinionBox=new TutorialActivityOpinionView({cssClass:"activity-opinion-list comment-container"},data)
data.on("ReplyIsRemoved",function(replyId){var i,item,_i,_len,_ref8,_results
_ref8=_this.opinionBox.opinionList.items
_results=[]
for(i=_i=0,_len=_ref8.length;_len>_i;i=++_i){item=_ref8[i]
if((null!=item?item.getData()._id:void 0)===replyId){item.hide()
_results.push(item.destroy())}else _results.push(void 0)}return _results})
this.scrollAreaOverlay=new KDView({cssClass:"enable-scroll-overlay",partial:""})
this.timeAgoView=new KDTimeAgoView({},this.getData().meta.createdAt)}__extends(TutorialActivityItemView,_super)
TutorialActivityItemView.prototype.highlightCode=function(){return this.$("div.body span.data pre").each(function(i,element){return hljs.highlightBlock(element)})}
TutorialActivityItemView.prototype.prepareExternalLinks=function(){return this.$("div.body a[href^=http]").attr("target","_blank")}
TutorialActivityItemView.prototype.prepareScrollOverlay=function(){var _this=this
this.utils.defer(function(){var body,cachedHeight,container
body=_this.$("div.activity-content-container.tutorial div.body")
container=_this.$("div.activity-content-container.tutorial")
if(body.height()<parseInt(container.css("max-height"),10))return _this.scrollAreaOverlay.hide()
container.addClass("scrolling-down")
cachedHeight=body.height()
return body.scroll(function(){var distanceBottom,distanceTop,percentageBottom,percentageTop,triggerValues
percentageTop=100*body.scrollTop()/body[0].scrollHeight
percentageBottom=100*(cachedHeight+body.scrollTop())/body[0].scrollHeight
distanceTop=body.scrollTop()
distanceBottom=body[0].scrollHeight-(cachedHeight+body.scrollTop())
triggerValues={top:{percentage:.5,distance:15},bottom:{percentage:99.5,distance:15}}
if(percentageTop<triggerValues.top.percentage||distanceTop<triggerValues.top.distance){container.addClass("scrolling-down")
container.removeClass("scrolling-both")
container.removeClass("scrolling-up")}if(percentageBottom>triggerValues.bottom.percentage||distanceBottom<triggerValues.bottom.distance){container.addClass("scrolling-up")
container.removeClass("scrolling-both")
container.removeClass("scrolling-down")}if(percentageTop>=triggerValues.top.percentage&&percentageBottom<=triggerValues.bottom.percentage&&distanceBottom>triggerValues.bottom.distance&&distanceTop>triggerValues.top.distance){container.addClass("scrolling-both")
container.removeClass("scrolling-up")
return container.removeClass("scrolling-down")}})})
return this.$("div.activity-content-container").hover(function(){_this.transitionStart=setTimeout(function(){return _this.scrollAreaOverlay.$().css({top:"100%"})},500)
return _this.scrollAreaOverlay.$().hasClass("hidden")?void 0:_this.checkForCompleteAnimationInterval=window.setInterval(function(){if(parseInt(_this.scrollAreaOverlay.$().css("top"),10)+_this.$("div.tutorial div.body").scrollTop()>=_this.scrollAreaOverlay.$().height()){_this.scrollAreaOverlay.hide()
_this.$("div.tutorial").addClass("scroll-highlight")
_this.$("div.tutorial div.body").addClass("scrollable-y")
_this.$("div.tutorial div.body").removeClass("no-scroll")
if(null!=_this.checkForCompleteAnimationInterval)return clearInterval(_this.checkForCompleteAnimationInterval)}},50)},function(){if(!(parseInt(_this.scrollAreaOverlay.$().css("top"),10)>=_this.scrollAreaOverlay.$().height())){null!=_this.transitionStart&&clearTimeout(_this.transitionStart)
null!=_this.checkForCompleteAnimationInterval&&clearInterval(_this.checkForCompleteAnimationInterval)
_this.scrollAreaOverlay.$().css({top:"0px"})
_this.$("div.tutorial").removeClass("scroll-highlight")
_this.$("div.tutorial div.body").removeClass("scrollable-y")
_this.$("div.tutorial div.body").addClass("no-scroll")
return _this.scrollAreaOverlay.show()}})}
TutorialActivityItemView.prototype.viewAppended=function(){if(this.getData().constructor!==KD.remote.api.CTutorialActivity){TutorialActivityItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
this.template.update()
this.highlightCode()
this.prepareExternalLinks()
return this.prepareScrollOverlay()}}
TutorialActivityItemView.prototype.render=function(){TutorialActivityItemView.__super__.render.call(this)
this.highlightCode()
this.prepareExternalLinks()
return this.prepareScrollOverlay()}
TutorialActivityItemView.prototype.click=function(event){var entryPoint,_ref,_ref1,_ref2,_ref3,_ref4,_ref5,_ref6,_ref7,_ref8
if($(event.target).is("[data-paths~=title]")){entryPoint=KD.config.entryPoint
KD.getSingleton("router").handleRoute("/Activity/"+this.getData().slug,{state:this.getData(),entryPoint:entryPoint})}if($(event.target).is("[data-paths~=preview]")){this.videoPopup=new VideoPopup({delegate:this.previewImage,title:(null!=(_ref=this.getData().link)?null!=(_ref1=_ref.link_embed)?_ref1.title:void 0:void 0)||"Untitled Video",thumb:null!=(_ref2=this.getData().link)?null!=(_ref3=_ref2.link_embed)?null!=(_ref4=_ref3.images)?null!=(_ref5=_ref4[0])?_ref5.url:void 0:void 0:void 0:void 0},null!=(_ref6=this.getData().link)?null!=(_ref7=_ref6.link_embed)?null!=(_ref8=_ref7.object)?_ref8.html:void 0:void 0:void 0)
return this.videoPopup.openVideoPopup()}}
TutorialActivityItemView.prototype.applyTextExpansions=function(str){var visiblePart
null==str&&(str="")
str=this.utils.expandUsernames(str)
if((null!=str?str.length:void 0)>500){visiblePart=str.substr(0,500)
str=visiblePart+" ..."}return str}
TutorialActivityItemView.prototype.pistachio=function(){return'<div class="activity-tutorial-container">\n  <span class="avatar">{{> this.avatar}}</span>\n  <div class=\'activity-item-right-col\'>\n    {{> this.settingsButton}}\n    <h3 class="comment-title">{{this.applyTextExpansions(#(title))}}</h3>\n    <p class="hidden comment-title"></p>\n    <div class="activity-content-container tutorial">\n      {{> this.previewImage}}\n      <div class="body has-markdown force-small-markdown no-scroll">\n        {{this.utils.applyMarkdown(#(body))}}\n      </div>\n      {{> this.scrollAreaOverlay}}\n    </div>\n    <footer class=\'clearfix\'>\n      <div class=\'type-and-time\'>\n        <span class=\'type-icon\'></span>{{> this.contentGroupLink}} by {{> this.author}}\n        {{> this.timeAgoView}}\n        {{> this.tags}}\n      </div>\n      {{> this.actionLinks}}\n    </footer>\n  </div>\n</div>'}
return TutorialActivityItemView}(ActivityItemChild)

var BlogPostActivityItemView,__hasProp={}.hasOwnProperty,__extends=function(child,parent){function ctor(){this.constructor=child}for(var key in parent)__hasProp.call(parent,key)&&(child[key]=parent[key])
ctor.prototype=parent.prototype
child.prototype=new ctor
child.__super__=parent.prototype
return child}
BlogPostActivityItemView=function(_super){function BlogPostActivityItemView(options,data){var _this=this
null==options&&(options={})
null==data&&(data={})
options.cssClass||(options.cssClass="activity-item blog-post")
options.tooltip||(options.tooltip={title:"Blog Post",selector:"span.type-icon",offset:{top:3,left:-5}})
BlogPostActivityItemView.__super__.constructor.call(this,options,data)
this.readThisLink=new CustomLinkView({title:this.getData().title||"Read this Blog Post",click:function(event){var entryPoint
event.stopPropagation()
event.preventDefault()
entryPoint=KD.config.entryPoint
return KD.getSingleton("router").handleRoute("/Activity/"+_this.getData().slug,{state:_this.getData(),entryPoint:entryPoint})}})}__extends(BlogPostActivityItemView,_super)
BlogPostActivityItemView.prototype.viewAppended=function(){if(this.getData().constructor!==KD.remote.api.CBlogPostActivity){BlogPostActivityItemView.__super__.viewAppended.call(this)
this.setTemplate(this.pistachio())
return this.template.update()}}
BlogPostActivityItemView.prototype.applyTextExpansions=function(str){null==str&&(str="")
return str=this.utils.applyTextExpansions(str,!0)}
BlogPostActivityItemView.prototype.pistachio=function(){return'{{> this.avatar}}\n<div class="activity-item-right-col">\n  <span class="author-name">{{> this.author}}</span>\n  <h3 class="blog-post-title">{{> this.readThisLink}}</h3>\n  <p class="body no-scroll has-markdown force-small-markdown">\n    {{this.utils.shortenText(this.utils.applyMarkdown(Encoder.htmlDecode(#(body))))}}\n  </p>\n</div>\n<footer>\n  {{> this.actionLinks}}\n  <time>{{$.timeago(#(meta.createdAt))}}</time>\n</footer>\n{{> this.commentBox}}'}
return BlogPostActivityItemView}(ActivityItemChild)

//@ sourceMappingURL=/js/__app.activity.0.0.1.js.map