/**
 * nowUtil.js
 * 
 * Various utility functions used by both client and server side
 *
 */

var nowUtil = {


  // Creates the serialized form of functions to be sent over the wire
  serializeFunction: function(fqn, func) {
    return {type: "function", fqn: fqn};
  },

  
  // Find all fqns of properties in parentObj and add them to the given blacklist, prepened by parentFqn
  addChildrenToBlacklist: function(blacklist, parentObj, parentFqn){
    for(var prop in parentObj){
      if(Object.hasOwnProperty.call(parentObj, prop)){
        blacklist[(parentFqn+"."+prop)] = true;
        if(parentObj[prop] && typeof parentObj[prop] === 'object'){
          nowUtil.addChildrenToBlacklist(blacklist, parentObj[prop], parentFqn+"."+prop);
        }
      }
    }
  },

  
  // Remove all fqns contained in parentObj from given blacklist
  removeChildrenFromBlacklist: function(blacklist, parentObj, parentFqn){
    for(var prop in parentObj){
      if(Object.hasOwnProperty.call(parentObj, prop)){
        delete blacklist[(parentFqn+"."+prop)];
        if(parentObj[prop] && typeof parentObj[prop] === 'object'){
          nowUtil.removeChildrenFromBlacklist(blacklist, parentObj[prop], parentFqn+"."+prop);
        }
      }
    }
  },
  

  // Return array of all fqns of parentObj, prepended by parentFqn, recursively
  getAllChildFqns: function(parentObj, parentFqn){
    var fqns = [];
    
    function getAllChildFqnsHelper(parentObj, parentFqn){
      for(var prop in parentObj){
        if(Object.hasOwnProperty.call(parentObj, prop)) {
          fqns.push(parentFqn+"."+prop);
          if(parentObj[prop] && typeof parentObj[prop] === 'object'){
            getAllChildFqnsHelper(parentObj[prop], parentFqn+"."+prop);
          }
        }
      }
    }
    getAllChildFqnsHelper(parentObj, parentFqn);
    return fqns; 
  },

  
  // This is the client-side equivalent of the proxy object from wrap.js. 
  // Takes an object and the name of a property, calls the handler function when that property changes
  watch: function (obj, prop, fqn, handler) {
    var val = obj[prop];
    var getter = function () {
      return val;
    };
    var setter = function (newVal) {
      var oldval = val;
      val = newVal;
      handler.call(obj, prop, fqn, oldval, newVal);
      return newVal;
    };
    if (Object.defineProperty) {// ECMAScript 5
      Object.defineProperty(obj, prop, {
        get: getter,
        set: setter
      });
    } else if (Object.prototype.__defineGetter__ && Object.prototype.__defineSetter__) { // legacy
      Object.prototype.__defineGetter__.call(obj, prop, getter);
      Object.prototype.__defineSetter__.call(obj, prop, setter);
    }
  },

  
  // Used in initialization to serialize obj and send it over the given socket
  initializeScope: function(obj, socket) {
    var data = nowUtil.decycle(obj, 'now', [nowUtil.serializeFunction]);
    var scope = data[0];
    nowUtil.debug("initializeScope", JSON.stringify(data));
    nowUtil.print(scope);
    socket.send({type: 'createScope', data: {scope: scope}});
  },

  
  // Cross-browser isArray
  isArray: Array.isArray || function (obj) {
    return  Object.prototype.toString.call(obj) === '[object Array]'; 
  },


  // Attempt to traverse the scope and return the property the fqn represents. Returns false if not found
  getVarFromFqn: function(fqn, scope){
    var path = fqn.split(".");
    path.shift();
    var currVar = scope;
    while(path.length > 0){
      var prop = path.shift();
      if(Object.hasOwnProperty.call(currVar, prop)) {
        currVar = currVar[prop];
      } else {
        return false;
      }
    }
    return currVar;
  },

  
  // Traverse scope to get the parent object of the given fqn
  getVarParentFromFqn: function(fqn, scope){
    var path = fqn.split(".");
    path.shift();
    
    var currVar = scope;
    while(path.length > 1){
      var prop = path.shift();
      currVar = currVar[prop];
    }
    return currVar;
  },
  
  
  // Traverse scope to get the parent object of the given fqn, or create and return it if it does't exist
  forceGetParentVarAtFqn: function(fqn, scope){
    var path = fqn.split(".");
    path.shift();
    
    var currVar = scope;
    while(path.length > 1){
      var prop = path.shift();
      if(!Object.hasOwnProperty.call(currVar, prop)){
        if(!isNaN(path[0])) {
          currVar[prop] = [];
        } else {
          currVar[prop] = {};
        }
      }
      currVar = currVar[prop];
    }
    return currVar;
  },

  
  // Check if is <IE9 by defineProperty feature detection
  isLegacyIE: function(){
    try {
      Object.defineProperty({}, '', {});
      return false;
    } catch (err) {
      return true;
    }
    return true;
  },

  
  // Traverse scope to get parent object of given fqn for multiple scopes simultaneously, creating and returning the object if it doesn't exist
  multiForceGetParentVarAtFqn: function(fqn, scopes){
    var path = fqn.split(".");
    path.shift();
    
    var currVar = scopes.slice(0);
    
    while(path.length > 1){
      var prop = path.shift();
      for(var i in scopes) {
        if(!Object.hasOwnProperty.call(currVar[i], prop)){
          if(!isNaN(path[0])) {
            currVar[i][prop] = [];
          } else {
            currVar[i][prop] = {};
          }
        }
        currVar[i] = currVar[i][prop];
      }
    }
    return currVar;
  },

  
  // Insert the value in the scope at the fqn, creating objects as necessary so the fqn exists
  createVarAtFqn: function(fqn, scope, value){
    var path = fqn.split(".");  

    var currVar = nowUtil.forceGetParentVarAtFqn(fqn, scope);
    currVar[path.pop()] = value;
  },

  
  // createVarAtFqn for multiple scopes
  multiCreateVarAtFqn: function(fqn, scopes, value){
    var path = fqn.split(".");
    var key = path.pop();
    var currVar = nowUtil.multiForceGetParentVarAtFqn(fqn, scopes);
    var i;
    
    if (value && typeof value === "object"){
      if(nowUtil.isArray(value)) {
        for(i in scopes) {
          currVar[i][key] = [];
        }
      } else {
        for(i in scopes) {
          currVar[i][key] = {};
        }
      }
      nowUtil.multiMergeScopes(currVar, key, value);
    } else {
      for(i in scopes) {
        currVar[i][key] = value;
      }    
    }

  },


  // Insert the value in the scope at the fqn, but add objects along the traversal to the blacklist, prepended with blacklistFqn
  createAndBlacklistVarAtFqn: function(fqn, scope, value, blacklist, blacklistFqn){
    var path = fqn.split(".");
    path.shift();
    
    var currVar = scope;
    while(path.length > 1){
      var prop = path.shift();
      blacklistFqn += "."+prop;
      if(!Object.hasOwnProperty.call(currVar, prop)){
        if(!isNaN(path[0])) {
          blacklist[blacklistFqn] = true;
          currVar[prop] = [];
        } else {
          blacklist[blacklistFqn] = true;
          currVar[prop] = {};
        }
      }
      currVar = currVar[prop];
    }
    var finalProp = path.pop();
    blacklist[fqn] = true;
    currVar[finalProp] = value;
  },

  
  // Create var at fqn but instead of simply inserting the value, make a deep copy of the value
  deepCreateVarAtFqn: function(fqn, scope, value){
    var path = fqn.split(".");
    path.shift();
    
    var currVar = nowUtil.getVarParentFromFqn(fqn, scope);
    if (value && typeof value === "object"){
      var prop = path.pop();
      if(nowUtil.isArray(value)) {
        currVar[prop] = [];
      } else {
        currVar[prop] = {};
      }
      nowUtil.mergeScopes(currVar[prop], value);
    } else {
      currVar[path.pop()] = value;
    }
  },

  
  // Deeply copy all children of incoming to current, with overwriting
  mergeScopes: function(current, incoming) {
    for(var prop in incoming){
      if(Object.hasOwnProperty.call(incoming, prop)) {
        if(incoming[prop] && typeof incoming[prop] === "object"){
          if(!Object.hasOwnProperty.call(current, prop)){
            if(nowUtil.isArray(incoming[prop])) {
              current[prop] = [];
            } else {
              current[prop] = {};
            }
          }
          nowUtil.mergeScopes(current[prop], incoming[prop]);
        } else {
          current[prop] = incoming[prop];
        }
      }
    }
  },

  
  // Deeply copy all children of incoming into each scope at current[i][key], with overwriting
  multiMergeScopes: function(current, key, incoming) {
    var i;
    for(var prop in incoming){
      if(Object.hasOwnProperty.call(incoming, prop)){
        if(incoming[prop] && typeof incoming[prop] === "object"){
          
          var newCurrent = [];
          
          for(i in current) {
            if(Object.hasOwnProperty.call(current, i)) {
              var curItem = current[i][key];        
              if(!Object.hasOwnProperty.call(curItem, prop)){
                if(nowUtil.isArray(incoming[prop])) {
                  curItem[prop] = [];
                } else {
                  curItem[prop] = {};
                }
              }
              newCurrent.push(current[i][key]);
            }
          }
          
          nowUtil.multiMergeScopes(newCurrent, prop, incoming[prop]);
        } else {
          for(i in current) {
            if(Object.hasOwnProperty.call(current, i)) {
              current[i][key][prop] = incoming[prop];
            }
          }
        }
      }
    }
  },

  
  // Create a shallow copy of incoming
  shallowCopy: function(incoming) {
    if(nowUtil.isArray(incoming)) {
      return incoming.slice();
    } else if(incoming && typeof incoming === "object") {
      var target = {};
      for(var key in incoming) {
        if(Object.hasOwnProperty.call(incoming, key)) {
          target[key] = incoming[key];
        }
      }
      return target;
    } else {
      return incoming;
    }
  },
  
  
  // Like multiMergeScopes but overwrite along the way with new nested objects
  multiDeepCopy: function(targets, incoming) {
    var i;
    if(incoming && typeof incoming === "object") {
      for(var prop in incoming){
        if(Object.hasOwnProperty.call(incoming, prop)) {
          if(incoming[prop] && typeof incoming[prop] === "object") {
            var next = [];
            for(i = 0; i < targets.length; i++){
              if(nowUtil.isArray(incoming[prop])) {
                targets[i][prop] = [];
              } else {
                targets[i][prop] = {};  
              }
              next[i] = targets[i][prop];
            }
            nowUtil.multiDeepCopy(next, incoming[prop]);
          } else {
            for(i = 0; i < targets.length; i++){
              targets[i][prop] = incoming[prop];
            }
          }
        }
      }
    } else {
      for(i = 0; i < targets.length; i++){
        targets[i] = incoming;
      }
    }
    return targets;
  },

  
  // Take the hash of changes and insert into each give scope
  // Changes is a map of fqn's to new values
  mergeChanges: function(scopes, changes) {
    for(var fqn in changes) {
      nowUtil.multiCreateVarAtFqn(fqn, scopes, changes[fqn]);
    }
  },

  
  // Log errors
  debug: function(func, msg){
    //console.log(func + ": " + msg);
  },

  
  // Log errors
  error: function(err){
    console.log(err);
    if(Object.hasOwnProperty.call(err, 'stack')){
      console.log(err.stack);
    }
  },

  
  // Log errors
  print: function(msg) {
    //console.log(msg);
  },

  
  
  // Pass in an object, a prefix for the fqn, and an array of funcHandlers that take a function and return a modified version
  // Returns an array of objects, each corresponding with one modified by one of the funcHandlers in the parameter array
  // Also change cyclical objects to a representation describing which object it is cyclically pointing to
  decycle: function decycle(object, key, funcHandlers) {
    "use strict";
    var objects = [],
        paths = [];
    return (function derez(value, path, fqn) {
        var i, j, nu = [];
        var output = [];
      
        switch (typeof value) {
        case 'object':
          if (!value) {
            for(i = 0; i < funcHandlers.length; i += 1) {
              nu.push(null);
            }
            return nu;
          }
          for (i = 0; i < objects.length; i += 1) {
            if (objects[i] === value) {                
              for(i = 0; i < funcHandlers.length; i += 1) {
                nu.push({$ref: paths[i]});
              }
              return nu;
            }
          }
          objects.push(value);
          paths.push(path);
          var values;
          if (Object.prototype.toString.apply(value) === '[object Array]') {
            nu = [];
            for(i = 0; i < funcHandlers.length; i += 1) {
              nu.push([]);
            }
            for (i = 0; i < value.length; i += 1) {
              values = derez(value[i], path + '[' + i + ']', fqn+"."+i);
              for(j in values) {
                if (Object.hasOwnProperty.call(values, j)) {
                  nu[j][i] = values[j];
                }
              }
            }
          } else {
            nu = [];
            for(i = 0; i < funcHandlers.length; i += 1) {
              nu.push({});
            }
            for (var name in value) {
              if (Object.prototype.hasOwnProperty.call(value, name)) {
                values = derez(value[name], path + '[' + JSON.stringify(name) + ']', fqn+"."+name);
                for(j in values) {
                  if (Object.hasOwnProperty.call(values, j)) {
                    nu[j][name] = values[j];
                  }
                }
              }
            }
          }
          return nu;
        case 'function':
          for(i = 0; i < funcHandlers.length; i += 1) {
            output[i] = funcHandlers[i](fqn, value);
          }
          return output;
        case 'undefined':
          for(i = 0; i < funcHandlers.length; i += 1) {
            nu.push(undefined);
          }
          return nu;
        case 'number':
        case 'string':
        case 'boolean':
            for(i = 0; i < funcHandlers.length; i += 1) {
              output[i] = value;
            }
            return output;
        }
    }(object, '$', key));
  },


  // Take $ and deserialize by replacing objects with object.type == function with the return value of funcHandlers
  // Restore cyclical structures as serialized by decycle
  retrocycle: function retrocycle($, funcHandler) {
    "use strict";
    var px = /^\$(?:\[(?:\d?|\"(?:[^\\\"\u0000-\u001f]|\\([\\\"\/bfnrt]|u[0-9a-zA-Z]{4}))*\")\])*$/;
    (function rez(value) {
        var i, item, name, path;
        if (value && typeof value === 'object') {
            if (Object.prototype.toString.apply(value) === '[object Array]') {
                for (i = 0; i < value.length; i += 1) {
                    item = value[i];
                    if(Object.hasOwnProperty.call(item, "type") && item.type === 'function') {
                      value[i] = funcHandler(value[i]);
                      item = value[i];
                    }
                    if (item && typeof item === 'object') {
                        path = item.$ref;
                        if (typeof path === 'string' && px.test(path)) {
                            value[i] = eval(path);
                        } else {
                            rez(item);
                        }
                    }
                }
            } else {
                for (name in value) {
                    if (value[name] && typeof value[name] === 'object') {
                        item = value[name];
                        if (item) {
                            if(Object.hasOwnProperty.call(item, "type") && item.type === 'function') {
                              value[name] = funcHandler(value[name]);
                            } else {
                              path = item.$ref;
                              if (typeof path === 'string' && px.test(path)) {
                                  value[name] = eval(path);
                              } else {
                                  rez(item);
                              }
                            }
                        }
                    }
                }
            }
        }
    })($);
    return $;
  },

  
  // Merge incoming into target , without overwriting
  // When a function is encounter, replace with return value of mapFn applied with the function as a parameter
  mapAndMergeFunctionsInScopes: function(target, incoming, mapFn){
    nowUtil.mapAndMergeFunctionsInScopeHelper(target, incoming, mapFn, 'now');
  },

  mapAndMergeFunctionsInScopesHelper: function(target, incoming, mapFn, fqn){
    for(var key in incoming){
      fqn += '.' + key;
      if(target && !Object.hasOwnProperty.call(target, key)){
        if(nowUtil.isArray(incoming[key])){
          target[key] = [];
          nowUtil.mapAndMergeFunctionsInScopeHelper(target[key], incoming[key], mapFn, fqn);
        } else if (typeof incoming[key] == 'object'){
          target[key] = {};
          nowUtil.mapAndMergeFunctionsInScopeHelper(target[key], incoming[key], mapFn, fqn);
        } else if(typeof incoming[key] == 'function'){
          target[key] = mapFn(fqn, func);
        }
      }
    }
  },

  
  // Merge incomingScope into the targetGroups's now object, replacing functions with corresponding multicallers and without overwriting
  multiMergeFunctionsToMulticallers: function(targetGroups, incomingScope){
    
    var targetScopes = {};
    for(var i in targetGroups){
      targetScopes[i] = targetGroups[i].nowScope;
    }

    nowUtil.multiMergeFunctionsToMulticallersHelper(targetGroups, targetScopes, incomingScope, 'now');
  },

  multiMergeFunctionsToMulticallersHelper: function(targetGroups, targetScopes, incomingScope, fqn){
    for(var key in incomingScope){
      var newFqn = fqn + '.' + key;
      for(var i in targetScopes){
        var target = targetScopes[i];
        if(target && !Object.hasOwnProperty.call(target, key)){
          if(nowUtil.isArray(incomingScope[key])){
            target[key] = [];
            targetScopes[i] = target[key];
            nowUtil.multiMergeFunctionsToMulticallersHelper(targetGroups, targetScopes, incomingScope[key], newFqn);
          } else if (typeof incomingScope[key] == 'object'){
            target[key] = {};
            targetScopes[i] = target[key];
            nowUtil.multiMergeFunctionsToMulticallersHelper(targetGroups, targetScopes, incomingScope[key], newFqn);
          } else if(typeof incomingScope[key] == 'function'){
            target[key] = targetGroups[i].generateMultiCaller(newFqn);
          }
        }
      }

    }
  },

  
  // Generate unique ids
  generateRandomString: function(){
    return Math.random().toString().substr(2); 
  }

};




// JSON shim for older IE
if('window' in this) {
  window.nowUtil = nowUtil;
  if(!('JSON' in window)){
    JSON={};
    (function(){"use strict";function f(n){return n<10?'0'+n:n;}
    if(typeof Date.prototype.toJSON!=='function'){Date.prototype.toJSON=function(key){return isFinite(this.valueOf())?this.getUTCFullYear()+'-'+
    f(this.getUTCMonth()+1)+'-'+
    f(this.getUTCDate())+'T'+
    f(this.getUTCHours())+':'+
    f(this.getUTCMinutes())+':'+
    f(this.getUTCSeconds())+'Z':null;};String.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(key){return this.valueOf();};}
    var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={'\b':'\\b','\t':'\\t','\n':'\\n','\f':'\\f','\r':'\\r','"':'\\"','\\':'\\\\'},rep;function quote(string){escapable.lastIndex=0;return escapable.test(string)?'"'+string.replace(escapable,function(a){var c=meta[a];return typeof c==='string'?c:'\\u'+('0000'+a.charCodeAt(0).toString(16)).slice(-4);})+'"':'"'+string+'"';}
    function str(key,holder){var i,k,v,length,mind=gap,partial,value=holder[key];if(value&&typeof value==='object'&&typeof value.toJSON==='function'){value=value.toJSON(key);}
    if(typeof rep==='function'){value=rep.call(holder,key,value);}
    switch(typeof value){case'string':return quote(value);case'number':return isFinite(value)?String(value):'null';case'boolean':case'null':return String(value);case'object':if(!value){return'null';}
    gap+=indent;partial=[];if(Object.prototype.toString.apply(value)==='[object Array]'){length=value.length;for(i=0;i<length;i+=1){partial[i]=str(i,value)||'null';}
    v=partial.length===0?'[]':gap?'[\n'+gap+partial.join(',\n'+gap)+'\n'+mind+']':'['+partial.join(',')+']';gap=mind;return v;}
    if(rep&&typeof rep==='object'){length=rep.length;for(i=0;i<length;i+=1){if(typeof rep[i]==='string'){k=rep[i];v=str(k,value);if(v){partial.push(quote(k)+(gap?': ':':')+v);}}}}else{for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=str(k,value);if(v){partial.push(quote(k)+(gap?': ':':')+v);}}}}
    v=partial.length===0?'{}':gap?'{\n'+gap+partial.join(',\n'+gap)+'\n'+mind+'}':'{'+partial.join(',')+'}';gap=mind;return v;}}
    if(typeof JSON.stringify!=='function'){JSON.stringify=function(value,replacer,space){var i;gap='';indent='';if(typeof space==='number'){for(i=0;i<space;i+=1){indent+=' ';}}else if(typeof space==='string'){indent=space;}
    rep=replacer;if(replacer&&typeof replacer!=='function'&&(typeof replacer!=='object'||typeof replacer.length!=='number')){throw new Error('JSON.stringify');}
    return str('',{'':value});};}
    if(typeof JSON.parse!=='function'){JSON.parse=function(text,reviver){var j;function walk(holder,key){var k,v,value=holder[key];if(value&&typeof value==='object'){for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=walk(value,k);if(v!==undefined){value[k]=v;}else{delete value[k];}}}}
    return reviver.call(holder,key,value);}
    text=String(text);cx.lastIndex=0;if(cx.test(text)){text=text.replace(cx,function(a){return'\\u'+
    ('0000'+a.charCodeAt(0).toString(16)).slice(-4);});}
    if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,''))){j=eval('('+text+')');return typeof reviver==='function'?walk({'':j},''):j;}
    throw new SyntaxError('JSON.parse');};}}());
  }

} else {

  exports.nowUtil = nowUtil;
  
}
var SERVER_ID = 'server';
var isIE = nowUtil.isLegacyIE();
var socket;

var nowCore = {

  // The client scope
  scopes: {},
  
  // Watcher objects for all variables in client
  watchers: {},
  
  // Blacklist of items to not trigger watcher callback for
  watchersBlacklist: {},
  
  
  // Contains references to closures passed in as pararmeters to remote calls
  // (Generated closure id) => reference to closure function
  closures: {},

  
  // All of the different client messages we'll handle
  messageHandlers: {
  
    // A remote function call from client
    remoteCall: function(client, data){
      nowUtil.debug("handleRemoteCall", data.callId);
      var clientScope = nowCore.scopes[client.sessionId];
      
      var theFunction;
      
      // Retrieve the function, either from closures hash or from the now scope
      if(data.fqn.split('_')[0] === 'closure'){
        theFunction = nowCore.closures[data.fqn];
      } else {
        theFunction = nowUtil.getVarFromFqn(data.fqn, clientScope);
      }
      
      var theArgs = data.args;
      
      // Search (only at top level) of args for functions parameters, and replace with wrapper remote call function
      for(var i in theArgs){
        if(Object.hasOwnProperty.call(theArgs[i], 'type') && theArgs[i].type === 'function'){
          theArgs[i] = nowCore.constructRemoteFunction(client, theArgs[i].fqn);
        }
      }
      
      // Call the function with this.now and this.user
      theFunction.apply({now: clientScope, clientId: client.sessionId}, theArgs);
     
      nowUtil.debug("handleRemoteCall" , "completed " + data.callId);
    },

    
    // Called by initializeScope from the client side
    createScope: function(client, data){
      
      // Initialize blacklist object
      nowCore.watchersBlacklist[client.sessionId] = {};
      
      // This is the now object as populated by the client
      // constructHandleFunctionForClientScope returns a function that will generate multicallers and remote call functions for this client
      var scope = nowUtil.retrocycle(data.scope, nowCore.constructHandleFunctionForClientScope(client));
      
      nowUtil.debug("handleCreateScope", "");
      nowUtil.print(scope);
      
      // Blacklist the entire scope so it is not sent back to the client
      nowUtil.addChildrenToBlacklist(nowCore.watchersBlacklist[client.sessionId], scope, "now");
      
      
      // Create the watcher object
      nowCore.watchers[client.sessionId] = new nowLib.NowWatcher("now", scope, {}, function(prop, fqn, oldVal, newVal){
        
        // Handle variable vale changes in this callback
        
        // If not on blacklist do changes
        if(!Object.hasOwnProperty.call(nowCore.watchersBlacklist[client.sessionId], fqn)){
          nowUtil.debug("clientScopeWatcherVariableChanged", fqn + " => " + newVal);
          if(oldVal && typeof oldVal === "object") {
            var oldFqns = nowUtil.getAllChildFqns(oldVal, fqn);
            
            for(var i in oldFqns) {
              delete nowCore.watchers[client.sessionId].data.watchedKeys[oldFqns[i]];  
            }
          }
          
          
          nowUtil.addChildrenToBlacklist(nowCore.watchersBlacklist[client.sessionId], newVal, fqn);
          
          var key = fqn.split(".")[1];
          var data = nowUtil.decycle(scope[key], "now."+key, [nowUtil.serializeFunction]);
          
          client.send({type: 'replaceVar', data: {key: key, value: data[0]}});    
        } else {
          // If on blacklist, remove from blacklist
          nowUtil.debug("clientScopeWatcherVariableChanged", fqn + " change ignored");
          delete nowCore.watchersBlacklist[client.sessionId][fqn];
        }
        
        // In case the object is an array, we delete from hashedArrays to prevent multiple watcher firing
        delete nowCore.watchers[client.sessionId].data.hashedArrays[fqn];
        
      });
      
      
      nowCore.scopes[client.sessionId] = scope;
      nowLib.nowJSReady();
    },

    replaceVar: function(client, data){
      nowUtil.debug("handleReplaceVar", data.key + " => " + data.value);
      
      var scope = nowCore.scopes[client.sessionId];     
      var newVal = nowUtil.retrocycle(data.value, nowCore.constructHandleFunctionForClientScope(client));

      nowCore.watchersBlacklist[client.sessionId]["now."+data.key] = true;
      nowUtil.addChildrenToBlacklist(nowCore.watchersBlacklist[client.sessionId], newVal, "now."+data.key);
      
      for(var key in nowCore.watchers[client.sessionId].data.watchedKeys) {
        if(key.indexOf("now."+data.key+".") === 0) {
          delete nowCore.watchers[client.sessionId].data.watchedKeys[key];
        }
      }
      
      if(Object.hasOwnProperty.call(data.value, "type") && data.value.type === 'function') {
        data.value = nowCore.constructRemoteFunction(client, data.value.fqn);
        newVal = data.value;
      }
      
      scope[data.key] = newVal;
    }
  },

  constructHandleFunctionForClientScope: function(client) {
    return function(funcObj) {
      return nowCore.constructRemoteFunction(client, funcObj.fqn);
    };
  },

  handleDisconnection: function(client) {
    nowUtil.debug("disconnect", "server disconnected");
  },

  constructRemoteFunction: function(client, fqn){
    
    nowUtil.debug("constructRemoteFunction", fqn);
      
    var remoteFn = function(){
      var callId = fqn+ "_"+ nowUtil.generateRandomString(10);
      
      nowUtil.debug("executeRemoteFunction", fqn + ", " + callId);

      var theArgs = Array.prototype.slice.call(arguments);
      
      for(var i in theArgs){
        if(typeof theArgs[i] === 'function' && Object.hasOwnProperty.call(theArgs, i)){
          var closureId = "closure" + "_" + theArgs[i].name + "_" + nowUtil.generateRandomString(10);
          nowCore.closures[closureId] = theArgs[i];
          theArgs[i] = {type: 'function', fqn: closureId};
        }
      }

      client.send({type: 'remoteCall', data: {callId: callId, fqn: fqn, args: theArgs}});
    };
    return remoteFn;
  },
  
  _events: {},
  
  // Event code from socket.io
  on: function(name, fn){
    if (!(name in nowCore._events)) {
      nowCore._events[name] = [];
    }
    nowCore._events[name].push(fn);
    return nowCore;
  },

  emit: function(name, args){
    if (name in nowCore._events){
      var events = nowCore._events[name].concat();
      for (var i = 0, ii = events.length; i < ii; i++) {
        events[i].apply(nowCore, args === undefined ? [] : args);
      }
    }
    return nowCore;
  },
  
  removeEvent: function(name, fn){
    if (name in nowCore._events){
      for (var a = 0, l = nowCore._events[name].length; a < l; a++) {
        if (nowCore._events[name][a] == fn) {
          nowCore._events[name].splice(a, 1);
        }
      }        
    }
    return nowCore;
  }
};

var nowLib = {

  nowJSReady: function(){  
    // client initialized
    var nowOld = now;
    now = nowCore.scopes[SERVER_ID];
    var ready = nowOld.ready;
    var core = nowOld.core;
    
    delete nowOld.ready;
    delete nowOld.core;
    nowUtil.initializeScope(nowOld, socket);

    nowUtil.addChildrenToBlacklist(nowCore.watchersBlacklist[SERVER_ID], nowOld, "now");
    
    for(var key in nowOld) {
      now[key] = nowOld[key];
    }
    now.core = core;
    now.ready = function(func){
      if(func && typeof func === "function") {
        func();
      } else {
        nowCore.emit('ready');
      }
    }
    
    
    setTimeout(function(){
      nowCore.watchers[SERVER_ID].processScope();
    }, 1000);

    // Call the ready handlers
    ready();
  },

  NowWatcher: function(fqnRoot, scopeObj, scopeClone, variableChanged) {
    this.data = {watchedKeys: {}, hashedArrays: {}};
    
    var badNames = {'now.ready': true, 'now.core': true };
    
    this.traverseObject = function(path, obj, arrayBlacklist, objClone) {
      // Prevent new array items from being double counted
      for(var key in obj){
        if(Object.hasOwnProperty.call(obj, key)){
          var fqn = path+"."+key;
          // Ignore ready function
          if(Object.hasOwnProperty.call(badNames, fqn)) {
            continue;
          }
          if(isIE && !nowUtil.isArray(obj) && typeof obj[key] !== "object" && Object.hasOwnProperty.call(objClone, key) && obj[key] !== objClone[key]) {
            this.variableChanged(key, fqn, objClone[key], obj[key]);
            objClone[key] = nowUtil.shallowCopy(obj[key]);
          }
          if(!Object.hasOwnProperty.call(this.data.watchedKeys, fqn)) {
            if(!isIE){
              nowUtil.watch(obj, key, fqn, this.variableChanged);
            } else {
              objClone[key] = nowUtil.shallowCopy(obj[key]);
            }
            if(!Object.hasOwnProperty.call(arrayBlacklist, fqn)) {
              this.variableChanged(key, fqn, "", obj[key]);
            }
            this.data.watchedKeys[fqn] = true;
          }
          
          if(obj[key] && typeof obj[key] === 'object') {
            if(nowUtil.isArray(obj[key])) {
              if(Object.hasOwnProperty.call(this.data.hashedArrays, fqn)){
                var diff = this.compareArray(this.data.hashedArrays[fqn], obj[key]);
                if(diff === false) {
                  // Replace the whole array
                  this.variableChanged(key, fqn, this.data.hashedArrays[fqn], obj[key]);
                } else if(diff !== true) {
                  for(var i in diff) {
                    if(Object.hasOwnProperty.call(diff, i)){
                      arrayBlacklist[fqn+"."+i] = true;
                      this.variableChanged(i, fqn+"."+i, this.data.hashedArrays[fqn][i], diff[i]);
                    }
                  }  
                }
              }
              this.data.hashedArrays[fqn] = obj[key].slice(0); 
            }
            if(isIE && (!Object.hasOwnProperty.call(objClone, key) || !(typeof objClone[key] === "object"))) {
              if(nowUtil.isArray(obj[key])) {
                objClone[key] = [];
              } else {
                objClone[key] = {};
              }
            }
            if(isIE){
              this.traverseObject(fqn, obj[key], arrayBlacklist, objClone[key]);
            } else {
              this.traverseObject(fqn, obj[key], arrayBlacklist);
            }
          }
        }
      }
    };

    this.processScope = function(){
      if(isIE) {
        this.traverseObject(fqnRoot, scopeObj, {}, scopeClone);
      } else {
        this.traverseObject(fqnRoot, scopeObj, {});
      }
      setTimeout(function(){
        nowCore.watchers[SERVER_ID].processScope();
      }, 1000);
    };

    this.variableChanged = variableChanged;

     /** 
     * Returns true if two the two arrays are identical. 
     * Returns an object of differences if keys have been added or the value at a key has changed
     * Returns false if keys have been deleted
     */
    this.compareArray = function(oldArr, newArr) {
      var result = {};
      var modified = false;
      if(newArr.length >= oldArr.length) {
        for(var i in newArr) {
          if(!Object.hasOwnProperty.call(oldArr, i) || newArr[i] !== oldArr[i]) {
            result[i] = newArr[i];
            modified = true;
          }
        }
        return (modified) ? result : true;
      } else {
        return false;
      }
    };
  },

  handleNewConnection: function(client){
    client.on('message', function(message){
      var messageObj = message;
      if(Object.hasOwnProperty.call(messageObj, "type") && Object.hasOwnProperty.call(nowCore.messageHandlers, messageObj.type)) {
          nowCore.messageHandlers[messageObj.type](client, messageObj.data);
      }
    });
    client.on('disconnect', function(){
      nowCore.handleDisconnection(client);
      nowCore.emit('disconnect');
    });
    // Forward planning for socket io 0.7
    client.on('error', function(){
      nowCore.emit('error');
    });
    client.on('retry', function(){
      nowCore.emit('retry');
    });
    client.on('reconnect', function(){
      nowCore.emit('reconnect');
    });
  }
  
};

var now = {
  ready: function(func) {
    if(arguments.length === 0) {
      nowCore.emit('ready');
    } else {
      nowCore.on('ready', func); 
    }    
  },
  core: {
    on: nowCore.on,
    removeEvent: nowCore.removeEvent,
    clientId: undefined
  }
};

(function(){
  var dependencies = ["/socket.io/socket.io.js"];
  var dependenciesLoaded = 0;

  var nowJSScriptLoaded = function(){
    dependenciesLoaded++;
    if(dependenciesLoaded !== dependencies.length) {
      return;
    }
    
    nowUtil.debug("isIE", isIE);
   
    socket = new io.Socket('dev.koding.com', {port: 80}); 
    now.core.socketio = socket;
    socket.connect();
    socket.on('connect', function(){
      var client = socket;
      client.sessionId = SERVER_ID;
      now.core.clientId = socket.transport.sessionid;
      nowLib.handleNewConnection(client);
      nowCore.emit('connect');
    });
  };

  for(var i=0, ii = dependencies.length; i < ii; i++){
    var fileref=document.createElement('script');
    fileref.setAttribute("type","text/javascript");
    fileref.setAttribute("src", "http://dev.koding.com:80"+dependencies[i]);
    fileref.onload = nowJSScriptLoaded;
    if(isIE) {
      fileref.onreadystatechange = function () {
        if(fileref.readyState === "loaded") {
          nowJSScriptLoaded();
        }
      };
    }
    document.getElementsByTagName("head")[0].appendChild(fileref);  
  }
}());
