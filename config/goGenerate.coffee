# goGenerate module generates a JSON object which will be parsed by `go generate`
# tool in order to create static configuration for Go programs. One can put Go's
# template actions into provided strings. Values available:
#
#  {{.Group}} - will be replaced by either `production` or `development` string
#               depending on build environment and provided environment.
#
#  {{.Environment}} - will be replaced by `production`, `managed`, `development`
#                     or `devmanaged` string depending on provided environment.
#
module.exports = (options) ->
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
