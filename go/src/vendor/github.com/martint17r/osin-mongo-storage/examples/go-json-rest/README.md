go-json-rest
============

This Example shows how to use [OSIN](https://github.com/RangelReale/osin), [osing-mongo-storage](http://github.com/martint17r/osin-mongo-storage) and [go-json-rest](https://github.com/ant0ine/go-json-rest)

[![baby-gopher](https://raw2.github.com/drnic/babygopher-site/gh-pages/images/babygopher-badge.png)](http://www.babygopher.org)

This package is based on the [complete example from the OSIN package](https://github.com/RangelReale/osin/tree/master/example/complete): Copyright (c) 2013, Rangel Reale All rights reserved.

start the web server with ```go build && ./go-json-rest```

then curl your token:
      
      ACCESSTOKEN=$(curl -s -D - -d login=test -d password=test "http://localhost:3000/oauth2/authorize?response_type=token&client_id=1234&redirect_uri=http:%2F%2Flocalhost:14000%2Fappauth%2Ftoken" | perl -ne '/access_token=([^&]+)/ and print "$1"')
      
and use the API with the token (extract the access_token path fragment from the previous step):

      curl -D - -H "Authorization: Bearer $ACCESSTOKEN" http://localhost:3000/api/me
      
If you curl without the correct token, a 401 response message is returned:
      
      curl -D - http://localhost:3000/api/me

You could also call the info endpoint

      curl -D - http://localhost:3000/oauth2/info?code=$ACCESSTOKEN

