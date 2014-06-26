/**
* Copyright (c) Microsoft.  All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/*
How to create SSH cert on linux/mac

// create pem file and key file
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout myPrivateKey.key -out mycert.pem

//Change the permissions on the private key to secure it.
chmod 600 mycert.pem
chmod 600 myPrivateKey.key

// convert pem to pfx
openssl pkcs12 -export -out mycert.pfx -in mycert.pem -inkey myPrivateKey.key -name "My Certificate"

// how to create a .cer file
openssl x509 -inform pem -in mycert.pem -outform der -out mycert.cer

*/

/*

How to create Service Management  cert on linux/mac

// create rsa private key
openssl genrsa -out management.key 2048

// create self signed certificate
openssl req -new -key management.key -out management.csr

// create temp pem file from rsa key and self signed certificate
openssl x509 -req -days 3650 -in management.csr -signkey management.key -out temp.pem

// create management pem from temp pem file and rsa key file
cat management.key temp.pem > management.pem

// create management pfx
openssl pkcs12 -export -out management.pfx -in temp.pem -inkey management.key -name "My Certificate"

// create management cer
openssl x509 -inform pem -in management.pem -outform der -out management.cer

// secure files
chmod 600 *.*
 */

var crypto = require('crypto');

var BEGIN_CERT = '-----BEGIN CERTIFICATE-----';
var END_CERT   = '-----END CERTIFICATE-----';

var getFingerPrint = function (pem) {
  // Extract the base64 encoded cert out of pem file
  var beginCert = pem.indexOf(BEGIN_CERT) + BEGIN_CERT.length;
  if (pem[beginCert] === '\n') {
    beginCert = beginCert + 1;
  } else if (pem[beginCert] === '\r' && pem[beginCert + 1] === '\n') {
    beginCert = beginCert + 2;
  }

  var endCert = '\n' + pem.indexOf(END_CERT);
  if (endCert === -1) {
    endCert = '\r\n' + pem.indexOf(END_CERT);
  }

  var certBase64 = pem.substring(beginCert, endCert);

  // Calculate sha1 hash of the cert
  var cert = new Buffer(certBase64, 'base64');
  var sha1 = crypto.createHash('sha1');
  sha1.update(cert);
  return sha1.digest('hex').toUpperCase();
};

var getAzureCertInfo = exports.getAzureCertInfo = function (cert) {
  return {
    cert: cert,
    fingerprint: getFingerPrint(cert.toString())
  };
};
