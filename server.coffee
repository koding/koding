{OAuth} = require "oauth"

key     = "aFVoHwffzThRszhMo2IQQ"
secret  = "QsTgIITMwo2yBJtpcp9sUETSHqEZ2Fh7qEQtRtOi2E"

token   = "42704386-gc8lqwwqkcmSOIpxtKFtFqF0aoilaFUiopv8QKOEK"
osecret = "v3Pk7Xa4LRMRy1AABY9odu6aU1Rrxc0Qkkaf4biIJcaQc"

oauth   = new OAuth "https://twitter.com/oauth/request_token",
  "https://twitter.com/oauth/access_token", key, secret,
  "1.1", "http://127.0.0.1:3020/-/oauth/twitter/callback", "HMAC-SHA1"

oauth.get 'https://api.twitter.com/1.1/account/verify_credentials.json',
  token, osecret, (e, data, res)->
    console.log e
