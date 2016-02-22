fs                     = require 'fs'
{ isAllowed, isProxy } = require './grouptoenvmapping'

createUpstreams = (KONFIG) ->

  upstreams = "# add global upstreams\n"
  for name, options of KONFIG.workers when options.ports?.incoming?

    servers = ""
    { incoming: port } = options.ports
    options.instances or= 1
    for index in [0...options.instances]
      servers += "\n" if servers isnt ""
      port = parseInt(port, 10)

      servers += "\tserver 127.0.0.1:#{port + index} max_fails=3 fail_timeout=10s;"

    upstreams += """
      upstream #{name} {
    #{servers}
      }\n\n"""

  return upstreams


basicAuth = """
auth_basic            "Restricted";
      auth_basic_user_file  /etc/nginx/conf.d/.htpasswd;"""

allowInternal = """
  allow                 127.0.0.0/8;
        allow                 192.168.0.0/16;
        allow                 172.16.0.0/12;
        deny                  all;
"""

createWebLocation = ({name, locationConf}) ->
  { location, proxyPass, internalOnly, auth, extraParams } = locationConf
    # 3 tabs are just for style
  extraParamsStr = extraParams?.join("\n\t\t\t") or ""
  return """\n
      location #{location} {
        proxy_pass            #{proxyPass};
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header      X-Host          $host; # for customisation
        proxy_set_header      Host            $host;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
        #{if internalOnly then allowInternal else ''}
        #{if auth then basicAuth else ''}
        #{extraParamsStr}
      }
  \n"""

createWebsocketLocation = ({name, locationConf, proxyPass}) ->
  {location, proxyPass} = locationConf
  # 3 tabs are just for style
  extraParamsStr = locationConf.extraParams?.join("\n\t\t\t") or ""
  return """\n
      location #{location} {
        proxy_pass            #{proxyPass};

        # needed for websocket handshake
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      $connection_upgrade;

        proxy_set_header      Host            $host;
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

createLocations = (KONFIG) ->
  workers = KONFIG.workers

  locations = ""
  for name, options of workers
    # don't add those who whish not to be generated, probably because those are
    # using manually written locations
    continue unless options.nginx?.locations

    continue if options.nginx?.disableLocation?

    # some of the locations can be limited to some environments, while creating
    # nginx locations filter with this info
    unless isAllowed options.group, KONFIG.ebEnvName
      continue

    for location in options.nginx.locations
      location.proxyPass or= "http://#{name}"
      # if this is a websocket proxy, add required configs
      fn = if options.nginx.websocket
        createWebsocketLocation
      else
        createWebLocation

      auth = no
      if KONFIG.configName in ["load", "prod"]
        auth = no
      else
        auth = options.nginx.auth

      locations += fn {name, locationConf: location, auth}

  return locations

createStubLocation = (env)->
  stub = """\n
      # nginx status location, it retuns info about connections and requests
      location /nginx_status {
          # Turn on nginx status page
          stub_status on;
          # only allow requests coming from localhost
          allow 127.0.0.1;
          # Deny the rest of the connections
          deny all;
      }
  \n"""

  if env is "dev"
    stub = ""

  return stub

createRootLocation = (KONFIG) ->
  return "" if isProxy KONFIG.ebEnvName

  proxy = KONFIG.hubspotPageURL
  if KONFIG.environment in ["dev", "sandbox"]
    proxy = "http://gowebserver"

  return """
      location ~*(^(\/(Pricing|About|Legal|Features|Blog|Docs))) {
          proxy_set_header      Host            $host;
          proxy_set_header      X-Host          $host; # for customisation
          proxy_set_header      X-Real-IP       $remote_addr;
          proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_next_upstream   error timeout   invalid_header http_500;
          proxy_connect_timeout 30;

          if ($host !~* ^(dev|sandbox|latest|www)) {
             return 301 /;
          }

          proxy_pass #{proxy};
      }
      """

module.exports.create = (KONFIG, environment)->
  workers = KONFIG.workers

  event_mechanism = switch process.platform
    when 'darwin' then 'use kqueue;'
    when 'linux'  then 'use epoll;'
    else ''

  for path in ['/etc/nginx/mime.types', '/usr/local/etc/nginx/mime.types']
    continue  unless fs.existsSync path
    mime_types = "include #{path};"
    break

  config = """
  worker_processes #{if environment is "dev" then 1 else 16};
  master_process #{if environment is "dev" then "off" else "on"};


  #error_log  logs/error.log;
  #error_log  logs/error.log  notice;
  #error_log  logs/error.log  info;

  #{if environment is 'dev' then '' else 'pid /var/run/nginx.pid;'}

  events {
    worker_connections  1024;
    multi_accept on;
    #{event_mechanism}
  }

  # start http
  http {

    access_log off;

    # log how long requests take
    log_format timed_combined 'RA: $remote_addr H: $host R: "$request" S: $status RS: $body_bytes_sent R: "$http_referer" UA: "$http_user_agent" RT: $request_time URT: $upstream_response_time';
    #{if environment is 'dev' then '' else 'access_log /var/log/nginx/access.log timed_combined;'}

    # batch response body
    client_body_in_single_buffer on;
    client_header_buffer_size 4k;
    client_max_body_size 10m;

    #{if environment is 'dev' then 'client_body_temp_path /tmp;' else ''}

    sendfile on;

    # for proper content type setting, include mime.types
    #{mime_types}

    #{createUpstreams(KONFIG)}

    # we're in the http context here
    map $http_upgrade $connection_upgrade {
      default upgrade;
      ''      close;
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

    # start server
    server {
      # we should not timeout on proxy connections
      #{if isProxy KONFIG.ebEnvName then "" else "
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
      listen #{if isProxy KONFIG.ebEnvName then 79 else KONFIG.publicPort};
      # root /usr/share/nginx/html;
      index index.html index.htm;
      location = /healthcheck {
        return 200;
        access_log off;
      }

      location @assets {
        proxy_pass            http://s3.amazonaws.com/koding-assets$uri;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 1;

        resolver 8.8.8.8;
      }

      # no need to send static file serving requests to webserver
      # serve static content from nginx
      location /a/ {

        #{if environment is 'dev' then '' else "
          location ~* \.(map)$ {
            return 404;
            access_log off;
          }"}

        root #{KONFIG.projectRoot}/website/;
        try_files $uri @assets;
        # no need to send those requests to nginx access_log
        access_log off;
      }

      #{createStubLocation(environment)}

      # special case for ELB here, for now
      location /-/healthCheck {
        proxy_pass            http://webserver;
        proxy_set_header      Host            $host;
        proxy_set_header      X-Host          $host; # for customisation
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      # redirect /d/* to koding-dl S3 bucket; used to distributed
      # // kd/klient installers
      location ~^/d/(.*)$ {
        proxy_pass            "https://s3.amazonaws.com/koding-dl/$1";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Host          $host; # for customisation
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 1;

        resolver 8.8.8.8;
      }

      # Hackathon2014 is the old hackathon page and served via webserver
      # todo(cihangir) remove after hubspot integration
      location = /Hackathon2014 {
        proxy_set_header      Host            $host;
        proxy_set_header      X-Host          $host; # for customisation
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;

        resolver 8.8.8.8;
        proxy_connect_timeout 10;
        proxy_pass http://webserver;
      }

      # mac and windows are case insensitive, redirect lowercased hackathon to
      # Uppercase Hackathon
      location ~ "(?-i)/hackathon" {
        return 301 /Hackathon ;
      }

      # proxy all Hackathon subpages to hubspot
      location ~^/Hackathon(.*) {
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;

        resolver 8.8.8.8;
        proxy_connect_timeout 10;
        proxy_pass https://teams-koding.hs-sites.com/Hackathon$1$is_args$args;
      }


      #{createRootLocation(KONFIG)}
      #{createLocations(KONFIG)}

    # close server
    }

    #{createRedirections(KONFIG)}

  # close http
  }
  """
  return config


createRedirections = (KONFIG) ->
  return "" if isProxy KONFIG.ebEnvName

  return """
  \t\t\t
    # redirect www to non-www
    server {
       server_name "~^www.(.*)$" ;
       return 301 $scheme://$1$request_uri ;
    }

    # redirect old.koding.com to koding.com
    server {
       server_name "~^old.koding.com" ;
       return 301 $scheme://koding.com$request_uri ;
    }"""

createHttpsRedirector = (KONFIG) ->
  return "" if isProxy KONFIG.ebEnvName

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
