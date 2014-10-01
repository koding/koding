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
        set $backend $ip:3000/$rest;

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

      auth = if KONFIG.configName is "load" then no else options.nginx.auth
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
  worker_processes #{if environment is "dev" then 5 else 16};

  #error_log  logs/error.log;
  #error_log  logs/error.log  notice;
  #error_log  logs/error.log  info;

  #{if environment is 'dev' then '' else 'pid /var/run/nginx.pid;'}

  events { worker_connections  1024; }

  # start http
  http {
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

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;

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

      # no need to send static file serving requests to webserver
      # serve static content from nginx
      location /a/ {
        root  #{KONFIG.projectRoot}/website/;
        # no need to send those requests to nginx access_log
        access_log off;
      }

      #{createStubLocation(environment)}

      # temporary exception for kloud to reach webserver without auth
      location /-/subscriptions {
        proxy_pass            http://webserver;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      # special case for ELB here, for now
      location /-/healthCheck {
        proxy_pass            http://webserver;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }

      #{createLocations(KONFIG)}

      #{createUserMachineLocation("userproxy")}
    # close server
    }
  # close http
  }
  """
  fs.writeFileSync "./deployment/generated_files/nginx.conf", config
  return config
