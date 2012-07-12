/*
  termlib_parser.js  v.1.1 (source compacted using jsmin.php)
  command line parser for termlib.js
  (c) Norbert Landsteiner 2005-2010
  mass:werk - media environments
  <http://www.masswerk.at>

  you are free to use this parser under the "termlib.js" license:
  http://www.masswerk.at/termlib/
*/
function Parser(){this.whiteSpace={' ':true,'\t':true};this.quoteChars={'"':true,"'":true,'`':true};this.singleEscapes={'\\':true};this.optionChars={'-':true};this.escapeExpressions={'%':Parser.prototype.plugins.hexExpression};}
Parser.prototype={version:'1.1',plugins:{hexExpression:function(termref,charindex,escapechar,quotelevel){if(termref.lineBuffer.length>charindex+2){var hi=termref.lineBuffer.charAt(charindex+1);var lo=termref.lineBuffer.charAt(charindex+2);lo=lo.toUpperCase();hi=hi.toUpperCase();if((((hi>='0')&&(hi<='9'))||((hi>='A')&&((hi<='F'))))&&(((lo>='0')&&(lo<='9'))||((lo>='A')&&((lo<='F'))))){Parser.prototype.plugins._escExprStrip(termref,charindex+1,charindex+3);return String.fromCharCode(parseInt(hi+lo,16));}}
return escapechar;},_escExprStrip:function(termref,from,to){termref.lineBuffer=termref.lineBuffer.substring(0,from)+
termref.lineBuffer.substring(to);}},getopt:function(termref,optsstring){var opts={'illegals':[]};while((termref.argc<termref.argv.length)&&(termref.argQL[termref.argc]=='')){var a=termref.argv[termref.argc];if((a.length>0)&&(this.optionChars[a.charAt(0)])){var i=1;while(i<a.length){var c=a.charAt(i);var v='';while(i<a.length-1){var nc=a.charAt(i+1);if((nc=='.')||((nc>='0')&&(nc<='9'))){v+=nc;i++;}
else{break;}}
if(optsstring.indexOf(c)>=0){opts[c]=(v=='')?{value:-1}:(isNaN(v))?{value:0}:{value:parseFloat(v)};}
else{opts.illegals[opts.illegals.length]=c;}
i++;}
termref.argc++;}
else{break;}}
return opts;},parseLine:function(termref){var argv=[''];var argQL=[''];var argc=0;var escape=false;for(var i=0;i<termref.lineBuffer.length;i++){var ch=termref.lineBuffer.charAt(i);if(escape){argv[argc]+=ch;escape=false;}
else if(this.escapeExpressions[ch]){var v=this.escapeExpressions[ch](termref,i,ch,argQL[argc]);if(typeof v!='undefined')argv[argc]+=v;}
else if(this.quoteChars[ch]){if(argQL[argc]){if(argQL[argc]==ch){argc++;argv[argc]=argQL[argc]='';}
else{argv[argc]+=ch;}}
else{if(argv[argc]!=''){argc++;argv[argc]='';argQL[argc]=ch;}
else{argQL[argc]=ch;}}}
else if(this.whiteSpace[ch]){if(argQL[argc]){argv[argc]+=ch;}
else if(argv[argc]!=''){argc++;argv[argc]=argQL[argc]='';}}
else if(this.singleEscapes[ch]){escape=true;}
else{argv[argc]+=ch;}}
if((argv[argc]=='')&&(!argQL[argc])){argv.length--;argQL.length--;}
termref.argv=argv;termref.argQL=argQL;termref.argc=0;}}
// eof