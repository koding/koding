module.exports = (options, credentials) ->
  environment    : options.environment
  buckets        :
    publicLogs   :
      name       : options.publicLogsS3BucketName
      region     : 'us-east-1'
  endpoints      :
    ip           : "https://#{options.proxySubdomain}.koding.com/-/ip"
    ipCheck      : "https://#{options.proxySubdomain}.koding.com/-/ipcheck"
    kdLatest     : "https://koding-kd.s3.amazonaws.com/{{.Group}}/latest-version.txt"
    klientLatest : "https://koding-klient.s3.amazonaws.com/{{.Environment}}/latest-version.txt"
    kloud        : "#{options.publicHostname}/kloud/kite",
    kontrol      : "#{options.publicHostname}/kontrol/kite",
    tunnelServer : "#{options.tunnelUrl}/kite"
  routes         :
    {
      'dev.koding.com': '127.0.0.1'
    }
