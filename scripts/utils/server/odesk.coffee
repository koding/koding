{OAuth}           = require "oauth"

requestUrl        = 'https://www.odesk.com/api/auth/v1/oauth/token/request'
accessUrl         = 'https://www.odesk.com/api/auth/v1/oauth/token/access'
key               = '639ec9419bc6500a64a2d5c3c29c2cf8'
secret            = '549b7635e1e4385e'
version           = '1.0'
request_uri       = 'http://localhost:3020/-/oauth/odesk/callback'
signature         = 'HMAC-SHA1'

accessToken       = '87a8f29c0c01f7b69564f6c3cddbca21'
accessTokenSecret = 'c8cfa040a1d57585'

customHeaders =
  'Accept' : 'application/json',
  'Connection' : 'close',
  'User-Agent': 'Node-oDesk'

client = new OAuth requestUrl, accessUrl, key, secret, version, request_uri, signature, 0, customHeaders

client.get 'https://www.odesk.com/api/auth/v1/info',
  accessToken, accessTokenSecret, (err, data)->

    console.log data
