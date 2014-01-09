# Node
crypto  = require "crypto"
qstring = require "querystring"
# Lib
jwa = require "./jwa"
ju  = require "./utils"

# version of the specification we are based on. 
module.exports.spec_version = "draft-jones-json-web-token-10"

#
# Decodes a given JWT Token.
#
# ## Arguments
# * token : The encoded JWT.
# 
# ## Returns
# * A **JWT Request** that holds the following.
#   * Attributes: header, claim, segments.
#   * Methods: verify( key ) where they key is *alogrithm* dependant. e.g. if RS you should use a valid *public PEM*
#
module.exports.decode = (token) ->
  # check segments
  segments = token.split '.'
  throw new Error 'Not enough or too many segments' if segments.length != 3
  
  # All segment should be base64
  headerSeg     = segments[0]
  payloadSeg    = segments[1]
  signatureSeg  = segments[2]

  # base64 decode and parse JSON
  header    = JSON.parse ju.base64urlDecode(headerSeg)
  claim     = JSON.parse ju.base64urlDecode(payloadSeg)
  # return
  new JwtRequest( header, claim, segments )

#
#
# Creates a *JWT Token* given the *claim*, the *key* and the given *algorithm*. The *algorithm* defaults to 
# `"HS256"` (Which is a *JWS* *HMAC* signature).
#
# # Rules for Creating a JWT
#
#   To create a JWT, one MUST perform these steps.  The order of the
#   steps is not significant in cases where there are no dependencies
#   between the inputs and outputs of the steps.
#
#   1.  Create a JWT Claims Set containing the desired claims.  Note that
#       white space is explicitly allowed in the representation and no
#       canonicalization is performed before encoding.
#
#   2.  Let the Message be the bytes of the UTF-8 representation of the JWT Claims Set.
#
#   3.  Create a JWT Header containing the desired set of header
#       parameters.  The JWT MUST conform to either the [JWS] or [JWE]
#       specifications.  Note that white space is explicitly allowed in
#       the representation and no canonicalization is performed before
#       encoding.
#
#   4.  Base64url encode the bytes of the UTF-8 representation of the JWT
#       Header.  Let this be the Encoded JWT Header.
#
#   5.  Depending upon whether the JWT is a JWS or JWE, there are two
#       cases:
#
#       *  If the JWT is a JWS, create a JWS using the JWT Header as the
#          JWS Header and the Message as the JWS Payload; all steps
#          specified in [JWS] for creating a JWS MUST be followed.
#
#       *  Else, if the JWT is a JWE, create a JWE using the JWT Header
#          as the JWE Header and the Message as the JWE Plaintext; all
#          steps specified in [JWE] for creating a JWE MUST be followed.
#
#   6.  If a nested signing or encryption operation will be performed,
#       let the Message be the JWS or JWE, and return to Step 3, using a
#       "typ" value of either "JWS" or "JWE" respectively in the new JWT
#       Header created in that step.
#
#   7.  Otherwise, let the resulting JWT be the JWS or JWE.
#
# Todo: Refactor to segregate the concerns between JWT and JWS.
# Todo: Include basic support for JWE identification (regardless of having implemented the JWE algorithms).
#
#
#
module.exports.encode = (claim, key, algorithm = "HS256", header_ext = {}) ->

  jwa_provider  = jwa.provider algorithm
  throw new Error "Algorithm #{algorithm} is not yet supported." unless jwa_provider

  jwa_signer = jwa_provider key

  header =
    typ: 'JWT'
    alg: algorithm

  for key, val of header_ext
    header[key] = val

  #create segments, all segment should be base64 string
  segments = []
  segments.push ju.base64urlEncode(JSON.stringify(header))
  segments.push ju.base64urlEncode(JSON.stringify(claim))

  jwa_signer.update( segments.join "." )
  segments.push( jwa_signer.sign() )
  
  segments.join('.')


#
# Abstracts the handling of a JWT Request. 
#
class JwtRequest
  
  constructor: (@header, @claim, @segments) ->
    
  verify: (key) ->
    _alg = @header?.alg
    _alg = "none" unless _alg

    _verifier = jwa.verifier _alg
    throw new Error "Unable to find a verifier for algorithm #{_alg}" unless _verifier

    _verifier.verify @, key
  
