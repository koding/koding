fs = require 'fs'

createUpstreams = (workers={}) ->
  upstreams = "# add global upstreams\n"
  for name, options of workers when options.ports?.incoming?
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
  { location, proxyPass, internalOnly, auth } = locationConf
  return """\n
      location #{location} {
        proxy_pass            #{proxyPass};
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
        #{if internalOnly then allowInternal else ''}
        #{if auth then basicAuth else ''}
      }
  \n"""

createWebsocketLocation = ({name, locationConf, proxyPass}) ->
  {location, proxyPass} = locationConf
  return """\n
      location #{location} {
        proxy_pass            #{proxyPass};

        # needed for websocket handshake
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      $connection_upgrade;

        proxy_set_header      Host $host;
        proxy_set_header      X-Real-IP $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect        off;

        # Don't buffer WebSocket connections
        proxy_buffering off;

        # try again with another upstream if there is an error
        proxy_next_upstream   error timeout   invalid_header http_500;
      }
  \n"""

createUserMachineLocation = (path) ->
  return """\n
      location ~ ^\\/-\\/#{path}\\/(?<ip>.+?)\\/(?<rest>.*) {
        # define our dynamically created backend
        set $backend $ip:56789/$rest;

        # proxy it to the backend
        proxy_pass http://$backend;

        # needed for websocket handshake
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        # be a good proxy :)
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;

        # Don't buffer WebSocket connections
        proxy_buffering off;

        # Default is 60 seconds, means nginx will close it after 60 seconds
        # inactivity which is a bad thing for long standing connections
        # like websocket. Make it 6 hours.
        proxy_read_timeout 21600s;
        proxy_send_timeout 21600s;
      }
  \n"""

createLocations = (KONFIG) ->
  workers = KONFIG.workers

  locations = ""
  for name, options of workers when options.ports?
    # don't add those who whish not to be generated, probably because those are
    # using manually written locations
    continue if options.nginx?.disableLocation?

    options.nginx = {}  unless options.nginx
    location = {}

    options.nginx.locations or= [
      location: "/#{name}"
    ]

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

    #{createUpstreams(workers)}

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

    # listen for http requests at port 81
    # this port will be only used for http->https redirection
    #
    # do not forget to allow communication via port 81 at security groups(ELB SecGroup)
    # like : koding-latest,

    # i have added  to koding-sandbox, koding-load, koding-prod and koding-prod-deployment-sg
    server {
      # just a random port
      listen #{if environment is "dev" then 8091 else 81};

      # why we have 2 different if checks? because www redirector block catches
      # all the requests, we should be more precise with the host

      # redirect http://kodingen.com to https://koding.com
      if ($host = "kodingen.com") {
        return 301 https://koding.com;
      }

      # redirect http://www.kodingen.com to https://koding.com
      if ($host = "www.kodingen.com") {
        return 301 https://koding.com;
      }

      # use generic names, do not hardcode values
      return 301 https://$host$request_uri;
    }

    # start server
    server {

      # close alive connections after 20 seconds
      # http://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_timeout
      keepalive_timeout 20s;

      # do not add hostname here!
      listen #{if environment is "dev" then 8090 else 80};
      # root /usr/share/nginx/html;
      index index.html index.htm;
      location = /healthcheck {
        return 200;
        access_log off;
      }

      # no need to send static file serving requests to webserver
      # serve static content from nginx
      location /a/ {

        #{if environment isnt "dev" then "
          location ~* \.(map)$ {
            return 404;
            access_log off;
          }
        " else ""
        }

        root #{KONFIG.projectRoot}/website/;
        # no need to send those requests to nginx access_log
        access_log off;
      }

      #{createStubLocation(environment)}

      # special case for ELB here, for now
      location /-/healthCheck {
        proxy_pass            http://webserver;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location = / {
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;

        proxy_set_header      X-Prerender-Token #{KONFIG.prerenderToken};

        set $prerender 0;
        if ($http_user_agent ~* "baiduspider|twitterbot|facebookexternalhit|rogerbot|linkedinbot|embedly|quora link preview|showyoubot|outbrain|pinterest|slackbot|vkShare|W3C_Validator") {
          set $prerender 1;
        }
        if ($request_uri !~ "(^(\/)?$)|(\/(Pricing|About|Legal|Features)(\/|$))") {
          set $prerender 0;
        }
        if ($args ~ "_escaped_fragment_=$|(\/(Pricing|About|Legal|Features)(\/|$))") {
          set $prerender 1;
        }
        if ($http_user_agent ~ "Prerender") {
          set $prerender 0;
        }

        if ($arg__escaped_fragment_ !~* 'Pricing|About|Legal|Features') {
          set $prerender 0;
        }

        #resolve using Google's DNS server to force DNS resolution and prevent caching of IPs
        resolver 8.8.8.8;

        if ($prerender = 1) {

          #setting prerender as a variable forces DNS resolution since nginx caches IPs and doesnt play well with load balancing
          set $prerender "service.prerender.io";
          rewrite .* /#{if environment is "dev" then "http" else "https"}://$host#{if KONFIG.publicPort is "80" then "" else ":"+KONFIG.publicPort}?$args? break;
          proxy_pass http://$prerender;
        }

        if ($prerender = 0) {
          proxy_pass http://gowebserver;
        }

        #{if environment is "sandbox" then basicAuth else ""}
      }

      # special case for kontrol to support additional paths, like /kontrol/heartbeat
      location ~^/kontrol/(.*) {
        proxy_pass            http://kontrol/$1$is_args$args;

        # needed for websocket handshake
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      $connection_upgrade;

        proxy_set_header      Host $host;
        proxy_set_header      X-Real-IP $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect        off;

        # Don't buffer WebSocket connections
        proxy_buffering off;

        # try again with another upstream if there is an error
        proxy_next_upstream   error timeout   invalid_header http_500;
      }

      #{createLocations(KONFIG)}

      #{createUserMachineLocation("userproxy")}
      #{createUserMachineLocation("prodproxy")}
      #{createUserMachineLocation("sandboxproxy")}
      #{createUserMachineLocation("latestproxy")}
      #{createUserMachineLocation("devproxy")}
    # close server
    }

    # redirect www to non-www
    server {
       server_name "~^www.(.*)$" ;
       return 301 $scheme://$1$request_uri ;
    }

    # redirect old.koding.com to koding.com
    server {
       server_name "~^old.koding.com" ;
       return 301 $scheme://koding.com$request_uri ;
    }

    # redirect kodingen.com to koding.com
    server {
       server_name "~^kodingen.com" ;
       return 301 $scheme://koding.com$request_uri ;
    }

  # close http
  }
  """
  return config
