createUpstreams = (workers={}) ->
  upstreams = "# add global upstreams\n"
  for name, options of workers when options.nginx?.ports?
    servers = ""
    for port in options.nginx.ports

      servers += "\tserver 127.0.0.1:#{port};\n"

    upstreams += """
      upstream #{name} {
    #{servers}
      }\n"""

  return upstreams



createWebLocation = (name, location) ->
  return """\n
      location #{location} {
        proxy_pass            http://#{name};
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }
  \n"""

createWebsocketLocation = (name, location) ->
  return """\n
      location #{location} {
        proxy_pass            http://#{name};
        proxy_http_version    1.1;
        proxy_set_header      Upgrade         $http_upgrade;
        proxy_set_header      Connection      "upgrade";
        proxy_set_header      Host            $host;
        proxy_set_header      X-Real-IP       $remote_addr;
        proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_next_upstream   error timeout   invalid_header http_500;
        proxy_connect_timeout 1;
      }
  \n"""

createLocations = (workers={}) ->
  locations = ""
  for name, options of workers when options.nginx?.ports?
    location = ""

    options.nginx.locations or= ["/#{name}"]

    for location in options.nginx.locations
      # if this is a websocket proxy, add required configs
      fn = if options.nginx.websocket
        createWebsocketLocation
      else
        createWebLocation

      locations += fn name, location

  return locations

nginxTemplate = (workers)->


module.exports.create = (workers)->
  config = """
  worker_processes  5;

  #error_log  logs/error.log;
  #error_log  logs/error.log  notice;
  #error_log  logs/error.log  info;

  #pid        logs/nginx.pid;

  events { worker_connections  1024; }

  # start http
  http {

    #{createUpstreams(workers)}

    map $http_upgrade $connection_upgrade { default upgrade; '' close; }

    gzip on;
    gzip_disable "msie6";

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    # start server
    server {
      # do not add hostname here!
      listen 8080;
      root /usr/share/nginx/html;
      index index.html index.htm;
      location = /healthcheck {
        return 200;
        #access_log off;
      }
      #{createLocations(workers)}
    # close server
    }
  # close http
  }
  """
  console.log config
  return config
