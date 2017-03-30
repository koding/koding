module.exports.createCountlyNginxServer = (KONFIG) ->
  # create nginx location for countly if only countly server's folder path is
  # given as option param while configuring, otherwise we dont care and manage
  # it. This will be only useful for local development on countly. Prob you wont
  # need this.
  return ''  unless KONFIG.countlyPath

  """\n
    server {
        listen   #{KONFIG.countly.apiPort};

        access_log  off;

        location = /countly/i {
            proxy_pass http://127.0.0.1:3001;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;

            proxy_hide_header X-Frame-Options;
            proxy_hide_header X-XSS-Protection;
            proxy_hide_header Strict-Transport-Security;
        }

        location ^~ /countly/i/ {
            proxy_pass http://127.0.0.1:3001;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;

            proxy_hide_header X-Frame-Options;
            proxy_hide_header X-XSS-Protection;
            proxy_hide_header Strict-Transport-Security;
        }

        location = /countly/o {
            proxy_pass http://127.0.0.1:3001;

            proxy_hide_header X-Frame-Options;
            proxy_hide_header X-XSS-Protection;
            proxy_hide_header Strict-Transport-Security;
        }

        location ^~ /countly/o/ {
            proxy_pass http://127.0.0.1:3001;

            proxy_hide_header X-Frame-Options;
            proxy_hide_header X-XSS-Protection;
            proxy_hide_header Strict-Transport-Security;
        }

        location /countly/ {
            proxy_pass http://127.0.0.1:6001;
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;

            proxy_hide_header X-Frame-Options;
            proxy_hide_header X-XSS-Protection;
            proxy_hide_header Strict-Transport-Security;
        }
    }
  """


module.exports.generateCountlySupervisord = (KONFIG) ->
  # see comment in nginx creation method above.
  return ''  unless KONFIG.countlyPath

  """\n
    [program:dashboard]
    environment                     = NODE_ENV=production
    command                         = node ./frontend/express/app.js
    numprocs                        = 1
    numprocs_start                  = 0
    directory                       = #{KONFIG.countlyPath}
    autostart                       = true
    autorestart                     = true
    startsecs                       = 10
    startretries                    = 5
    stopsignal                      = TERM
    stopwaitsecs                    = 10
    stopasgroup                     = true
    killasgroup                     = true
    redirect_stderr                 = true
    stdout_logfile                  = %(ENV_KONFIG_SUPERVISORD_LOGDIR)s/countly_dashboard.log
    stdout_logfile_maxbytes         = 1MB
    stdout_logfile_backups          = 10
    stdout_capture_maxbytes         = 1MB
    stderr_logfile                  = %(ENV_KONFIG_SUPERVISORD_LOGDIR)s/countly_dashboard.log
    stdout_events_enabled           = false
    loglevel                        = warn



    [program:api]
    environment                     = NODE_ENV=production
    command                         = node ./api/api.js
    numprocs                        = 1
    numprocs_start                  = 0
    directory                       = #{KONFIG.countlyPath}
    autostart                       = true
    autorestart                     = true
    startsecs                       = 10
    startretries                    = 5
    stopsignal                      = TERM
    stopwaitsecs                    = 10
    stopasgroup                     = true
    killasgroup                     = true
    redirect_stderr                 = true
    stdout_logfile                  = %(ENV_KONFIG_SUPERVISORD_LOGDIR)s/countly_api.log
    stdout_logfile_maxbytes         = 1MB
    stdout_logfile_backups          = 10
    stdout_capture_maxbytes         = 1MB
    stderr_logfile                  = %(ENV_KONFIG_SUPERVISORD_LOGDIR)s/countly_api.log
    stdout_events_enabled           = false
    loglevel                        = warn


    [group:countly]
    programs=dashboard, api
  """
