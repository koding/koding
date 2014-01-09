# Node
crypto  = require "crypto"
# Lib
ju      = require "./utils"


#
# The following is based on [JSON Web Algorithms (JWA) v02](https://www.ietf.org/id/draft-ietf-jose-json-web-algorithms-02.txt):
#
# The JSON Web Algorithms (JWA) specification enumerates cryptographic algorithms and identifiers to be used with the 
# JSON Web Signature (JWS) [JWS] and JSON Web Encryption (JWE) [JWE] specifications.  Enumerating the algorithms and
# identifiers for them in this specification, rather than in the JWS and JWE specifications, is intended to allow them
# to remain unchanged in the face of changes in the set of required, recommended, optional, and deprecated algorithms
# over time. This specification also describes the semantics and operations that are specific to these algorithms and 
# algorithm families.
#
#   +--------------------+----------------------------------------------+
#   | alg Parameter      | Digital Signature or MAC Algorithm           |
#   | Value              |                                              |
#   +--------------------+----------------------------------------------+
#   | HS256              | HMAC using SHA-256 hash algorithm            |
#   | HS384              | HMAC using SHA-384 hash algorithm            |
#   | HS512              | HMAC using SHA-512 hash algorithm            |
#   | RS256              | RSA using SHA-256 hash algorithm             |
#   | RS384              | RSA using SHA-384 hash algorithm             |
#   | RS512              | RSA using SHA-512 hash algorithm             |
#   | ES256              | ECDSA using P-256 curve and SHA-256 hash     |
#   |                    | algorithm                                    |
#   | ES384              | ECDSA using P-384 curve and SHA-384 hash     |
#   |                    | algorithm                                    |
#   | ES512              | ECDSA using P-521 curve and SHA-512 hash     |
#   |                    | algorithm                                    |
#   | none               | No digital signature or MAC value included   |
#   +--------------------+----------------------------------------------+
#
#  Of these algorithms, only HMAC SHA-256 and "none" MUST be implemented by conforming JWS implementations. 
#  It is RECOMMENDED that implementations also support the RSA SHA-256 and ECDSA P-256 SHA-256 algorithms.  
#  Support for other algorithms and key sizes is OPTIONAL.
#
jwa_table =
  NONE :
    TYPE : "SIGNATURE"
    HASH_AL : {}
  HMAC :
    TYPE    : "SIGNATURE"
    HASH_AL :
      HS256 : "SHA256"
      HS384 : "SHA384"
      HS512 : "SHA512"
  RSA :
    TYPE    : "SIGNATURE"
    HASH_AL :
      RS256 : "RSA-SHA256"
      RS384 : "RSA-SHA384"
      RS512 : "RSA-SHA512"


class JwaAlgorithm

  type : () ->
    jwa_table?[@alg]?.TYPE

  hash : (alg) ->
    jwa_table?[@alg]?.HASH_AL[alg]


#
# To support use cases where the content is secured by a means other than a digital signature or MAC value, JWSs MAY also be created
# without them.  These are called "Plaintext JWSs".  Plaintext JWSs MUST use the "alg" value "none", and are formatted identically to
# other JWSs, but with an empty JWS Signature value.
#
class NoneSigner extends JwaAlgorithm

  alg : "NONE"

  update: (data) ->
    @

  digest: () -> ""

  sign: () -> @digest()


NONE_SIGNER = new NoneSigner

newNoneSigner = ( ) -> NONE_SIGNER

class NoneVerifier extends JwaAlgorithm

  alg : "NONE"

  verify: (jwt_req) ->
    jwt_header  = jwt_req?.header
    jwt_claim   = jwt_req?.claim
    jwt_enc_sig = jwt_req?.segments?[2]

    return false unless jwt_header.alg == "none"
    return false if     jwt_enc_sig
    true

newNoneVerifier = () -> new NoneVerifier



# Provides the HMAC implementation of the **HS256**, **HS384** and **HS512** algorithms.
# Cryptographic algorithms are provided by **Node's** [Crypto library](http://nodejs.org/api/crypto.html)
#
# As mentioned in the specification the HMAC (Hash-based Message Authentication Codes) enable the usage
# of a *known secret*, this can be used to demonstrate that the MAC matches the hashed content, 
# in this case the JWS Secured Input, which therefore demonstrates that whoever generated the MAC was in
# possession of the secret. 
#
# To review the specifics of the algorithms please review chapter
# "3.2.  MAC with HMAC SHA-256, HMAC SHA-384, or HMAC SHA-512" of
# the [Specification](https://www.ietf.org/id/draft-ietf-jose-json-web-algorithms-02.txt).
#
class HMACSigner extends JwaAlgorithm

  alg : "HMAC"

  #
  # Creates and returns an HMAC object, a cryptographic HMAC binded to the given algorithm and key.
  # The supported algorithm is dependent on the available algorithms in *OpenSSL* - to get the list
  # type `openssl list-message-digest-algorithms` in the terminal. If you provide an algorithm that is
  # not supported an error will be thrown.
  #
  constructor: (alg = "HS256" , @key) ->
    throw Error "A defined algorithm is required." unless alg

    @osslAlg = @hash(alg.toUpperCase())
    throw Error "Algorithm #{@alg} is not supported by HMAC." unless @osslAlg

    try
      @hmac = crypto.createHmac @osslAlg, @key
    catch error
      throw new Error "HMAC does not support algorithm #{@alg} => #{@osslAlg}! #{error}"

  update: (data) ->
    throw new Error "There is no reference to the hmac object!" unless @hmac
    @hmac.update data
    @

  digest: (encoding = "base64") ->
    throw new Error "There is no reference to the hmac object!" unless @hmac
    ju.base64urlEscape( @hmac.digest(encoding) )

  sign: (encoding) -> @digest(encoding)


# Factory to create *HMAC Algorithm* instances
newHMACSigner = (alg, key) ->
  new HMACSigner(alg, key)

# Todo: Move to JWS
class HMACVerifier extends JwaAlgorithm

  alg: "HMAC"

  verify: (jwt_req, key) ->
    throw new Error "jwt request not specified" unless jwt_req
    throw new Error "key not specified" unless key

    _typ     = jwt_req?.header?.typ
    _alg     = jwt_req?.header?.alg
    _claim   = jwt_req?.claim
    _enc_sig = jwt_req?.segments?[2]

    # is the header a jwt header?
    return false unless _typ == "JWT"
    # is the algorithm supported/available for hmac ?
    throw new Error "Hash #{_alg} is not supported!" unless @hash( _alg)
    # do we have an encoded signature?
    return false unless _enc_sig
    # do we have the implementation of such hmac algorithm?
    algImpl = jwa_provider(_alg)
    return false unless algImpl
    # set the signer
    signer = algImpl key
    # if so we proceed to sign the segments that belong to the header and the claim
    signer.update "#{jwt_req.segments?[0]}.#{jwt_req.segments?[1]}"
    # get signed value form the JWT
    _actual_sign = signer.sign()
    #compare
    _actual_sign == _enc_sig

# Todo: Move to JWS
newHMACVerifier = () -> new HMACVerifier

#  
#  Implementation of digital signature with RSA SHA-256, RSA SHA-384, or RSA SHA-512
#
#  To review the specifics of the algorithms please review chapter
#  "3.3.  Digital Signature with RSA SHA-256, RSA SHA-384, or RSA SHA-512" of
#  the [Specification](https://www.ietf.org/id/draft-ietf-jose-json-web-algorithms-02.txt).
#  
#  Important elements to understand are.
#  * RSASSA-PKCS1-v1_5 digital signature algorithm (commonly known as PKCS#1), 
#  using SHA-256, SHA-384, or SHA-512 as the hash function. 
#  
#  The *"alg"* (algorithm) header parameter values used in the JWS Header to indicate that 
#  the *Encoded JWS Signature* contains a **base64url** encoded **RSA digital signature* using the
#  respective hash function are:
#  * "RS256"
#  * "RS384"
#  * "RS512" 
#
#  **A key of size 2048 bits or larger MUST be used with these algorithms.**
#
#
class RSSigner extends JwaAlgorithm

  alg : "RSA"

  _assertSigner : () ->
    throw Error "Signer is not defined!" unless @signer

  constructor: (alg = "RSA-SHA256", @key_PEM) ->
    throw Error "A defined algorithm is required." unless alg
    
    @osslAlg = @hash( alg.toUpperCase() )
    new Error "Algorithm #{alg} is not supported by the specification." unless @osslAlg

    try
      @signer = crypto.createSign(@osslAlg)
    catch error
      throw new Error "Unable to create a signer with algorithm #{@osslAlg}!"
  
  update: (data) ->
    @_assertSigner()
    @signer.update data
    @

  sign: (format = "base64") ->
    @_assertSigner()
    _signed = @signer.sign(@key_PEM, format)
    _enc_sign = ju.base64urlEscape _signed
    _enc_sign

newRSSigner = (alg, key_PEM) -> new RSSigner( alg, key_PEM )


# TODO move verifier to JWS
#  
#  Implementation of verification of a RSA SHA-256, RSA SHA-384, or RSA SHA-512 signature.
#
#  To review the specifics of the algorithms please review chapter
#  "3.3.  Digital Signature with RSA SHA-256, RSA SHA-384, or RSA SHA-512" of
#  the [Specification](https://www.ietf.org/id/draft-ietf-jose-json-web-algorithms-02.txt).
#  
#  The *Encoded JWS Signature* contains a **base64url** encoded **RSA digital signature*. The
#  following hash functions are available.
#  
#  Per specification the validation should be implemented as follows:
#
#   o.  Take the Encoded JWS Signature and base64url decode it into a
#       byte array.  If decoding fails, the JWS MUST be rejected.
#
#   0.  Submit the bytes of the UTF-8 representation of the JWS Secured
#       Input (which is the same as the ASCII representation) and the
#       public key corresponding to the private key used by the signer to
#       the RSASSA-PKCS1-V1_5-VERIFY algorithm using the corresponding SHA hash function (e.g. SHA-256).
#
#   0.  If the validation fails, the JWS MUST be rejected.
#
#
class RSVerifier extends JwaAlgorithm

  alg : "RSA"
  
  _createVerifier = (alg) ->
    try
      crypto.createVerify(alg)
    catch error
      throw new Error "Unable to create a verifier with algorithm #{alg}! #{error}"
  
  verify: (jwt_req, public_key) ->
    throw new Error "jwt request not specified" unless jwt_req
    throw new Error "public_key not specified" unless public_key

    _typ     = jwt_req?.header?.typ
    _alg     = jwt_req?.header?.alg
    _claim   = jwt_req?.claim
    _enc_sig = jwt_req?.segments?[2]

    # is the header a jwt header?
    return false unless _typ == "JWT"
    # do we have an encoded signature?
    return false unless _enc_sig
    # is the algorithm supported/available for RSA ?
    openSSL = @hash(_alg)
    throw new Error "Hash #{_alg} is not supported for this JWA #{@type}" unless openSSL
    # can we create a verifier for the implementation of such algorithm?
    _verifier = _createVerifier openSSL
    return false unless _verifier
    # update the verifier with the that used to generate the key
    _verifier.update "#{jwt_req.segments[0]}.#{jwt_req.segments[1]}"
    # we un-encode the encoded signature
    _sig = ju.base64urlUnescape _enc_sig
    # finally we verify
    _verifier.verify public_key, _sig, "base64"

newRSVerifier = () -> new RSVerifier


#
# TODO: Implement 
#       3.4.  Digital Signature with ECDSA P-256 SHA-256, ECDSA P-384 SHA-384,
#             or ECDSA P-521 SHA-512


#
# Returns a function that holds an *Encryption Algorithm*, or `undefined` if the algorithm is not supported or not found. 
#
#   +--------------------+----------------------------------------------+
#   | alg Parameter      | Digital Signature or MAC Algorithm           |
#   | Value              |                                              |
#   +--------------------+----------------------------------------------+
#   | HS256              | HMAC using SHA-256 hash algorithm            |
#   | HS384              | HMAC using SHA-384 hash algorithm            |
#   | HS512              | HMAC using SHA-512 hash algorithm            |
#   | RS256              | RSA using SHA-256 hash algorithm             |
#   | RS384              | RSA using SHA-384 hash algorithm             |
#   | RS512              | RSA using SHA-512 hash algorithm             |
#   | ES256              | ECDSA using P-256 curve and SHA-256 hash     |
#   |                    | algorithm                                    |
#   | ES384              | ECDSA using P-384 curve and SHA-384 hash     |
#   |                    | algorithm                                    |
#   | ES512              | ECDSA using P-521 curve and SHA-512 hash     |
#   |                    | algorithm                                    |
#   | none               | No digital signature or MAC value included   |
#   +--------------------+----------------------------------------------+
#
module.exports.provider = jwa_provider = (code) ->
  switch code
    when "none" then () => newNoneSigner()
    
    when "HS256", "HS384", "HS512" then (key) => newHMACSigner code, key
    
    when "RS256", "RS384", "RS512" then (key) => newRSSigner code, key
    
    when "ES256", "ES384", "ES512" then undefined #throw new Error "ECDSA not yet implemented."

    else undefined #throw new Error "There is no JWA Provider for #{code}!"

#
# Provides
#
module.exports.verifier = jwa_verifier = (code) ->
  switch code
    when "none" then newNoneVerifier()
    
    when "HS256", "HS384", "HS512" then newHMACVerifier()
    
    when "RS256", "RS384", "RS512" then newRSVerifier()
    
    when "ES256", "ES384", "ES512" then undefined #throw new Error "ECDSA not yet implemented."

    else undefined #throw new Error "There is no JWA Provider for #{code}!"


