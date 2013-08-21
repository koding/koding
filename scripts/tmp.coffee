authenticator.setAccount "gokmen", (err, account)->
  # console.log arguments
  remote(account).fetchStorage {appId:"Finder", version:"1.0a"}, (err, storage)->
    # console.log storage
    storage.update {
        $set: {bucket:{"vm-1.sinan.com":"/asdasd"}}
      }, ->
        console.log "RESS", arguments

