[![Build Status](https://secure.travis-ci.org/berngp/node-jot.png?branch=master)](http://travis-ci.org/berngp/node-jot)

# Green JWT

  Node.js implementation of JSON Web Token (JWT) with support for signatures (JWS), encryption (JWE) and web keys (JWK). 

  "*JSON Web Token (JWT) is a means of representing claims to be transferred between two parties. The claims in a JWT are encoded as a JSON object that may be digitally signed using JSON Web Signature (JWS) and/or encrypted using JSON Web Encryption (JWE).*"

  The suggested pronunciation of JWT is the same as the English word "jot".

  This package is aimed to implements the following IETF drafts:

  * [JWT](http://tools.ietf.org/html/draft-jones-json-web-token-10) draft-jones-json-web-token-10
  * [JWA](https://www.ietf.org/id/draft-ietf-jose-json-web-algorithms-02.txt) draft-ietf-jose-json-web-algorithms-02
  * [JWS](http://tools.ietf.org/html/draft-ietf-jose-json-web-signature-02) draft-ietf-jose-json-web-signature-02
  * [JWE](http://tools.ietf.org/html/draft-ietf-jose-json-web-encryption-02) draft-ietf-jose-json-web-encryption-02
  * [JWK](http://tools.ietf.org/html/draft-ietf-jose-json-web-key-02) draft-ietf-jose-json-web-key-02


  But currently we only support **JWT** with **JWS** and the following **JWA** signing algorithms

  * NONE 
  * HMAC 
    * HS256
    * HS384
    * HS512
  * RSA 
    * RS256 
    * RS384 
    * RS512


  As we move forward we will add additional **JWA** algorithms and support for **JWE**. Please submit any comments and suggestions.


## Build Tools & Development Dependencies 
The code is implemented using [CoffeeScript](http://jashkenas.github.com/coffee-script)

## Dependencies
We try to keep dependencies to a minimum but pleae refer to the [package.json](package.json) for the full set of dependencies.

## License 

Unless stated elsewhere, file headers or otherwise, the license as stated bellow:

(The MIT License)

Copyright (c) 2012 Bernardo Gomez Palacio &lt;bernardo.gomezpalacio@gmail.com&gt;, Kazuhito Hokamura &lt;k.hokamura@gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
