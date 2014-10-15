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

      servers += "\tserver 127.0.0.1:#{port + index};"

    upstreams += """
      upstream #{name} {
    #{servers}
      }\n\n"""

  return upstreams


basicAuth = """
auth_basic            "Restricted";
      auth_basic_user_file  /etc/nginx/conf.d/.htpasswd;"""

createWebLocation = (name, location, auth = no) ->
  return """\n
      location #{location} {
        proxy_pass            http://#{name};
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
        #{if auth then basicAuth else ''}
      }
  \n"""

createWebsocketLocation = (name, location) ->
  return """\n
      location #{location} {
        proxy_pass            http://#{name};

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

        # Default is 60 seconds, means nginx will close it after 60 seconds
        # inactivity which is a bad thing for long standing connections
        # like websocket. Make it 6 hours.
        proxy_read_timeout 21600s;
        proxy_send_timeout 21600s;
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
    options.nginx = {}  unless options.nginx
    location = ""

    options.nginx.locations or= ["/#{name}"]

    for location in options.nginx.locations
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

      locations += fn name, location, auth

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
    # epoll is only valid for linux environments
    use #{if environment is 'dev' then 'kqueue' else 'epoll'};
  }

  # start http
  http {

    # log how long requests take
    log_format timed_combined '$request $request_time $upstream_response_time $pipe';
    #{if environment is 'dev' then '' else 'access_log /var/log/nginx/access.log timed_combined;'}

    # batch response body
    client_body_in_single_buffer on;
    client_header_buffer_size 4k;
    client_max_body_size 10m;

    sendfile on;

    # for proper content type setting, include mime.types
    include #{if environment is 'dev' then '/usr/local/etc/nginx/mime.types;' else '/etc/nginx/mime.types;'}

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
      # use generic names, do not hardcode values
      return 301 https://$host$request_uri;
    }

    # start server
    server {

      # do not add hostname here!
      listen #{if environment is "dev" then 8090 else 80};
      # root /usr/share/nginx/html;
      index index.html index.htm;
      location = /healthcheck {
        return 200;
        access_log off;
      }

      location = /WFGH {
        proxy_pass http://webserver;
        #{if environment isnt "dev" then basicAuth else ""}
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

      location ~ /api/social/channel/(.*)/history {
        proxy_pass            http://socialapi/channel/$1/history$is_args$args;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      location = / {
        if ($args ~ \"_escaped_fragment_\") {
          proxy_pass http://webserver;
        }

        proxy_pass            http://gowebserver;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;

        #{if environment is "sandbox" then basicAuth else ""}
      }

      #{createLocations(KONFIG)}

      #{createUserMachineLocation("userproxy")}
    # close server
    }

    # redirect www to non-www
    server {
       server_name "~^www.(.*)$" ;
       return 301 $scheme://$1$request_uri ;
    }

  # close http
  }
  """
  fs.writeFileSync "./deployment/generated_files/nginx.conf", config
  return config
