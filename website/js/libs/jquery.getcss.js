/**
 * jQuery.getCSS plugin
 * http://github.com/furf/jquery-getCSS
 *
 * Copyright 2010, Dave Furfero
 * Dual licensed under the MIT or GPL Version 2 licenses.
 *
 * Inspired by Julian Aubourg's Dominoes
 * http://code.google.com/p/javascript-dominoes/
 */
(function(f,b,g){var d=b.getElementsByTagName("head")[0],a=/loaded|complete/,e={},c=0,h;g.getCSS=function(j,i,l){if(g.isFunction(i)){l=i;i={};}var k=b.createElement("link");k.rel="stylesheet";k.type="text/css";k.media=i.media||"screen";k.href=j;if(i.charset){k.charset=i.charset;}if(i.title){l=(function(m){return function(){k.title=i.title;m(k,"success");};})(l);}if(k.readyState){k.onreadystatechange=function(){if(a.test(k.readyState)){k.onreadystatechange=null;l(k,"success");}};}else{if(k.onload===null&&k.all){k.onload=function(){k.onload=null;l(k,"success");};}else{e[k.href]=function(){l(k,"success");};if(!c++){h=f.setInterval(function(){var r,o,q=b.styleSheets,m,n=q.length;while(n--){o=q[n];if((m=o.href)&&(r=e[m])){try{r.r=o.cssRules;throw"SECURITY";}catch(p){if(/SECURITY/.test(p)){r(k,"success");delete e[m];if(!--c){h=f.clearInterval(h);}}}}}},13);}}}d.appendChild(k);};})(this,this.document,this.jQuery);