;( function( window ) {
  var addFlashFallback = function( pusher, options ) {    
    options = options || {};
    options.connectionTimeout = ( options.connectionTimeout || 15 * 1000 );
    options.fallingBack = options.fallingBack || null;
    
    log( 'adding flash fallback' );
    log( 'options:' + JSON.stringify( options, null, 2 ) );
    
    var connectionTimeout = window.setTimeout( forceFlashFallback, options.connectionTimeout );
    pusher.connection.bind( 'connected', clearConnectionTimeout );
  
    function clearConnectionTimeout() {
      log( 'connection established. cancelling flash fallback' );
      //window.clearTimeout( connectionTimeout );
    }
  
    var cdn = (document.location.protocol == 'http:') ? Pusher.cdn_http : Pusher.cdn_https;
    var root = cdn + Pusher.VERSION;
    
    function forceFlashFallback() {
      log( 'connection not established after ' + options.connectionTimeout + ' milliseconds. forcing flash fallback.' );
      
      if( typeof options.fallingBack === 'function' ) {
        options.fallingBack();
      }
      
      // stop flash fallback occuring on the next connection.
      pusher.connection.unbind( 'connected', forceFlashFallback );
     
      var deps = [];

      window.WEB_SOCKET_DISABLE_AUTO_INITIALIZATION = true;
      window.WEB_SOCKET_FORCE_FLASH = true;
      window.WEB_SOCKET_SUPPRESS_CROSS_DOMAIN_SWF_ERROR = true;
      deps.push(root + '/flashfallback' + Pusher.dependency_suffix + '.js');
      
      log( 'loading flashfallback js' );
      _require(deps, flashFallbackLoaded);
    }

    function flashFallbackLoaded() {
      log( 'flash fallback loaded' );
      
      if (window['WebSocket']) {
        // window['WebSocket'] is a flash emulation of WebSocket
        Pusher.Transport = window['WebSocket'];
        Pusher.TransportType = 'flash';

        window.WEB_SOCKET_SWF_LOCATION = root + "/WebSocketMain.swf";
        WebSocket.__addTask(function() {
          Pusher.ready();
        })
        WebSocket.__initialize();
      } else {
        // Flash must not be installed
        Pusher.Transport = null;
        Pusher.TransportType = 'none';
        Pusher.ready();
      }
    }
    
    function log( msg ) {
      if( window['Pusher'] && window['Pusher'].log ) {
        Pusher.log( msg );
      }
    }
  }; 
  
  window._addFlashFallback = addFlashFallback;
  
  return addFlashFallback;
  
} )( window );