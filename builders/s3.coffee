{nox,mox} = require "noxmox"
fs = require "fs"
log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log
gzip        = require "gzip"



class S3
  
  constructor:(s3Credentials)->  
    @client = nox.createClient
      key     : s3Credentials.key
      secret  : s3Credentials.secret
      bucket  : s3Credentials.bucket
  
  getFile:(path,callback)->
    @client.get(path).on("response", (res) ->
      res.setEncoding "utf8"
      res.on "data", (chunk) ->
        callback null,chunk
    ).end()
        
  putFile:(localPath,s3Path,callback)->
    fs.readFile localPath, (err, buf) =>
        gzip buf,(err,buf)=>
        req = @client.put s3Path,
          "Content-Length" : buf.length
          "Content-Type"   : "application/x-gzip"
          # "x-amz-acl"      : "public-read"

      
        req.on "response", (res) ->
          if 200 is res.statusCode
            res =  "saved from #{localPath} to s3://#{s3Path}"
            log.info res
            callback null,res
          else
            err = "save failed to s3://#{s3Path}"
            log.error err
            callback err
          #fs.unlink "./#{filename}",(err)->
          #  log.info "temp file #{filename} is deleted."
      
        req.end buf    

module.exports = S3
