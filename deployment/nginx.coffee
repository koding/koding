fs                     = require 'fs'
{ isAllowed, isProxy } = require './grouptoenvmapping'
{ createCountlyNginxServer } = require './countly/generateConfig'
_ = require 'lodash'

createUpstreams = (KONFIG) ->

  upstreams = '# add global upstreams\n'
  for name, options of KONFIG.workers when options.ports?.incoming?

    servers = ''
    { incoming: port } = options.ports
    options.instances or= 1
    for index in [0...options.instances]
      servers += '\n' if servers isnt ''
      port = parseInt(port, 10)

      servers += "\tserver 127.0.0.1:#{port + index} max_fails=3 fail_timeout=10s;"

    upstreams += """
      upstream #{name} {
    #{servers}
      }\n\n"""

  return upstreams


basicAuth = '''
satisfy any;
      allow   127.0.0.1/32;
      deny    all;

      auth_basic            "Restricted";
      auth_basic_user_file  /etc/nginx/conf.d/.htpasswd;'''

allowInternal = '''
  allow                 127.0.0.0/8;
        allow                 192.168.0.0/16;
        allow                 172.16.0.0/12;
        deny                  all;
'''

real_ip_options =
  from: '0.0.0.0/0'
  header: 'X-Forwarded-For'
  recursive: 'on'

createWebLocation = ({ name, locationConf, cors }) ->
  { location, proxyPass, internalOnly, auth, extraParams } = locationConf
    # 3 tabs are just for style
  extraParamsStr = extraParams?.join('\n\t\t\t') or ''
  host = locationConf.host or '$host'

  return """\n
      location #{location} {
        proxy_pass            #{proxyPass};

        proxy_set_header      Host            #{host};
        proxy_set_header      X-Host          $host; # for customisation
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;

        # try again with another upstream if there is an error
        proxy_next_upstream   error timeout   invalid_header http_500;

        # proxy should connect in 1 second
        proxy_connect_timeout 5;

        #{if cors then cors else ''}
        #{if internalOnly then allowInternal else ''}
        #{if auth then basicAuth else ''}
        #{extraParamsStr}
      }
  \n"""

createWebsocketLocation = ({ name, locationConf, proxyPass }) ->
  { location, proxyPass } = locationConf
  # 3 tabs are just for style
  extraParamsStr = locationConf.extraParams?.join('\n\t\t\t') or ''
  host = locationConf.host or '$host'
  return """\n
      location #{location} {
        proxy_pass            #{proxyPass};

        # needed for websocket handshake
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      $connection_upgrade;
        proxy_set_header      Host            #{host};
        proxy_set_header      X-Host          $host; # for customisation
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect        off;

        # Don't buffer WebSocket connections
        proxy_buffering       off;

        # try again with another upstream if there is an error
        proxy_next_upstream   error timeout   invalid_header http_500;

        #{extraParamsStr}

      }
  \n"""

createBucketLocation = ({ name, locationConf, proxyPass }) ->
  { location, proxyPass } = locationConf
  # 3 tabs are just for style
  extraParamsStr = locationConf.extraParams?.join('\n\t\t\t') or ''
  host = locationConf.host or '$host'
  return """\n
      location #{location} {
        proxy_cache asset_cache;
        proxy_cache_revalidate on;
        proxy_cache_lock on;
        proxy_cache_valid  200 302  60m;
        proxy_cache_valid  404	  1m;
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;

        proxy_pass            #{proxyPass};
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 5;

        # unset headers
        proxy_hide_header x-amz-id-2;
        proxy_hide_header x-amz-request-id;
        proxy_hide_header x-amz-expiration;
        proxy_hide_header x-amz-meta-s3cmd-attrs;

        # ignore possible future headers that might break caching
        proxy_ignore_headers X-Accel-Expires Expires Cache-Control;

        # finally add status
        add_header X-K-Proxy-Cache $upstream_cache_status;

        resolver 8.8.8.8;

        #{extraParamsStr}

      }
  \n"""

createLocations = (KONFIG) ->
  workers = KONFIG.workers

  locations = ''
  for name, options of workers when not options.disabled
    # don't add those who whish not to be generated, probably because those are
    # using manually written locations
    continue  unless options.nginx?.locations

    continue  if options.nginx?.disableLocation

    # some of the locations can be limited to some environments, while creating
    # nginx locations filter with this info
    unless isAllowed options.group, KONFIG.ebEnvName
      continue

    for location in options.nginx.locations
      location.proxyPass or= "http://#{name}"
      # if this is a websocket proxy, add required configs
      fn = if options.nginx.websocket
        createWebsocketLocation
      else if options.nginx.s3bucket
        createBucketLocation
      else if options.nginx.static
        createAssetLocation
      else
        createWebLocation

      auth = no
      if KONFIG.configName in ['load', 'prod']
        auth = no
      else
        auth = options.nginx.auth

      if KONFIG.configName is 'dev'
        cors = '''\n
              add_header 'Access-Control-Allow-Origin' '*' always;
              add_header 'Access-Control-Allow-Credentials' 'true';
              add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
              add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
        \n'''
      else if location.cors
        cors = '''\n
              add_header 'Access-Control-Allow-Origin' $custom_cors_control always;
              add_header 'Access-Control-Allow-Credentials' 'true';
              add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
              add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
        \n'''
      else
        cors = ''

      locations += fn { name, locationConf: location, auth, cors, KONFIG }

  return locations

createStubLocation = (env) ->
  stub = '''\n
      # nginx status location, it retuns info about connections and requests
      location /nginx_status {
          # Turn on nginx status page
          stub_status on;
          # only allow requests coming from localhost
          allow 127.0.0.1;
          # Deny the rest of the connections
          deny all;
      }
  \n'''

  if env in ['dev', 'default']
    stub = ''

  return stub

createAssetLocation = ({ locationConf, KONFIG }) ->
  { expires, relativePath, proxyPass,
    location, extraParamsStr } = locationConf

  expires or= '1M'
  relativePath or= '/website/'
  proxyPass or= '$uri @assets'
  return throw new Error 'location required'  unless location
  extraParamsStr or= ''

  return """\n
      location #{location} {
          root #{KONFIG.projectRoot}#{relativePath};
          try_files #{proxyPass};
          expires #{expires};
          add_header Cache-Control \"public\";
          # no need to send those requests to nginx access_log
          access_log off;

          #{extraParamsStr}
      }
  \n"""


module.exports.create = (KONFIG, environment) ->
  workers = KONFIG.workers

  event_mechanism = switch process.platform
    when 'darwin' then 'use kqueue;'
    when 'linux'  then 'use epoll;'
    else ''

  inDevEnvironment = environment in ['dev', 'default']

  for path in ['/etc/nginx/mime.types', '/usr/local/etc/nginx/mime.types']
    continue  unless fs.existsSync path
    mime_types = "include #{path};"
    break

  if isProxy KONFIG.ebEnvName
    KONFIG.nginx =
      real_ip:
        from: '10.0.0.0/16'
        header: 'proxy_protocol'
        recursive: 'off'

  config = """
  worker_processes #{if inDevEnvironment then 1 else 16};
  master_process #{if inDevEnvironment then 'off' else 'on'};

  daemon off;

  #error_log  logs/error.log;
  #error_log  logs/error.log  notice;
  #error_log  logs/error.log  info;

  #{if inDevEnvironment then '' else 'pid /var/run/nginx.pid;'}

  events {
    worker_connections 20000;
    multi_accept on;
    #{event_mechanism}
  }

  # start http
  http {

    access_log off;

    # log how long requests take
    log_format timed_combined 'RA: $remote_addr H: $host R: "$request" S: $status RS: $body_bytes_sent R: "$http_referer" UA: "$http_user_agent" RT: $request_time URT: $upstream_response_time';
    #{if inDevEnvironment then '' else 'access_log /var/log/nginx/access.log timed_combined;'}

    proxy_buffer_size  128k; # default 8k;
    proxy_buffers   4 256k; # default 8 8k;
    proxy_busy_buffers_size   256k; # default 16k;

    # batch response body
    client_body_in_single_buffer on;
    client_header_buffer_size 4k;
    client_max_body_size 10m;

    #{if inDevEnvironment then 'client_body_temp_path /tmp;' else ''}

    sendfile on;

    # for proper content type setting, include mime.types
    #{mime_types}

    #{createUpstreams(KONFIG)}

    # we're in the http context here
    map $http_upgrade $connection_upgrade {
      default upgrade;
      ''      close;
    }

    map $http_origin $custom_cors_control {
      "~*\.koding\.com(:[0-9]+)?"   $http_origin;
      "~*\.koding\.team(:[0-9]+)?"  $http_origin;
      "~*\.koding\.me(:[0-9]+)?"    $http_origin;
      "~*\.oud\.cc(:[0-9]+)?"       $http_origin;
      default                       "koding.com";
    }

    gzip on;
    gzip_disable "msie6";
    gzip_static on;

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript image/jpeg image/jpg image/png;

    #{createHttpsRedirector(KONFIG)}

    #{createHealthcheck(KONFIG)}

    # this keys are used for internal caching purposes.
    proxy_cache_path /tmp/nginx levels=1:2 keys_zone=asset_cache:10m max_size=10g inactive=60m;
    proxy_cache_key "$scheme$request_method$host$request_uri";

    #{createRealIpDirectives(KONFIG)}

    # start server
    server {
      # we should not timeout on proxy connections
      #{if isProxy KONFIG.ebEnvName then '' else "
      # close alive connections after 20 seconds
      # http://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_timeout\n
      \t\tkeepalive_timeout 20s;
      "}

      # do not add hostname here!
      #
      # ELB listens on 80+443 and proxies those
      # requests to our instance, our instance listens on port 79
      #
      # There is another service listening on 80, tunnelserver, that one is
      # reached from outside directly, not over ELB
      #

      #{createListenDirective(KONFIG, environment)}

      #{createIPRoutes(KONFIG)}

      # root /usr/share/nginx/html;
      index index.html index.htm;
      location = /healthcheck {
        return 200;
        access_log off;
      }

      #{createStubLocation(environment)}

      # redirect /s3/:bucket/:key to :bucket.s3.amazonaws.com/:key
      location ~^/s3/([^/]*)/(.*)$ {
        return 302 https://$1.s3.amazonaws.com/$2;
      }

      location ~ ^/(blog|docs)(.*) {
        return 301 https://www.koding.com/$1$2$is_args$args;
      }

      #{createLocations(KONFIG)}

    # close server
    }

    #{createRedirections(KONFIG)}

    #{createCountlyNginxServer(KONFIG)}

  # close http
  }
  """
  return config


createRedirections = (KONFIG, environment) ->
  return '' if isProxy KONFIG.ebEnvName

  return """
  \t\t\t
    # redirect www to non-www
    server {
       #{createListenDirective(KONFIG, environment)}
       server_name "~^www.(.*)$" ;
       return 301 $scheme://$1$request_uri ;
    }

    # redirect old.koding.com to koding.com
    server {
       #{createListenDirective(KONFIG, environment)}
       server_name "~^old.koding.com" ;
       return 301 $scheme://koding.com$request_uri ;
    }"""

createHealthcheck = (KONFIG) ->
  return '' if not isProxy KONFIG.ebEnvName

  return '''
    # ELB healthcheck with proxy_protocol disabled
    server {
        listen 78;

        # proxy healthcheck requests to tunnelserver, if nginx is down,
        # healthcheck does its job, if tunnelserver is down, healthcheck again
        # does its job, two bird, one stone

        location = /healthcheck {
          proxy_pass http://tunnelserver/healthCheck;
          proxy_set_header	  Host            $host;
          proxy_set_header	  X-Host          $host;
          proxy_set_header	  X-Real-IP	  $remote_addr;
          proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_next_upstream   error timeout   invalid_header http_500;
          proxy_connect_timeout 1;

          # in need of a fallback, uncomment followings
          #return 200;
          #access_log off;
        }
    }
  '''

createIPRoutes = (KONFIG) ->
  unless KONFIG.environment in ['default', 'dev']
    if not isProxy KONFIG.ebEnvName
      return ''

  return '''
    location ~^/-/ip$ {
      return 200 $remote_addr;
    }

    location ~ /-/ipcheck/(.*) {
      proxy_pass http://$remote_addr:$1/;
      proxy_connect_timeout 5s;
      proxy_read_timeout 5s;
      proxy_send_timeout 5s;
      proxy_next_upstream error timeout invalid_header;
    }
   '''

createListenDirective = (KONFIG, env) ->
  if isProxy KONFIG.ebEnvName
    return 'listen 79 proxy_protocol;'
  else
    return "listen #{KONFIG.publicPort};"

createHttpsRedirector = (KONFIG) ->
  return '' if isProxy KONFIG.ebEnvName

  return """
  \t\t\t
    # listen for http requests at port 81
    # this port will be only used for http->https redirection
    #
    # do not forget to allow communication via port 81 at security groups(ELB SecGroup)
    # like : koding-latest,
    server {
      # just a random port

      listen #{parseInt(KONFIG.publicPort)+1+''};

      # use generic names, do not hardcode values
      return 301 https://$host$request_uri;
    }"""

createRealIpDirectives = (KONFIG) ->
  return ''  unless KONFIG.nginx?.real_ip

  options = _.assign real_ip_options, KONFIG.nginx.real_ip

  return """
  \t\t\t
    set_real_ip_from #{options.from};
    real_ip_header #{options.header};
    real_ip_recursive #{options.recursive};
  """
