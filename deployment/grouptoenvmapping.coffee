proxies =  [
  'koding-proxy-ap-s-e-1'
  'koding-proxy-us-east-1'
  'koding-proxy-eu-west-1'
  'koding-proxy-us-west-2'
  'koding-proxy-dev-us-e-1'
  'koding-proxy-dev-us-e-1-v2'
]

envs =  [
  'dev'
  'default'
  'koding-latest'
  'koding-monitor'
  'koding-prod'
  'koding-sandbox'
]

groupToEnv =
  'webserver'   : envs
  'environment' : envs
  'socialapi'   : envs
  'proxy'       : proxies
  'default'     : [ 'default' ]
  'bucket'      : envs
  'static'      : envs
  'external'    : envs.concat proxies

module.exports.isAllowed = (group, env) ->
  # if group name is not in groupToEnv
  unless groupToEnv[group]
    console.error "#{group} is not defined in groupToEnv map"
    process.exit 1

  return env in groupToEnv[group]

# isProxy returns true if given env is in proxies
module.exports.isProxy = (env) -> return env in proxies
