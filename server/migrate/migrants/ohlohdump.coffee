class OhlohDump extends Migrant
  
  @sourceDatabase           = 'mongodb://localhost:27017/ohloh'
  @sourceCollectionName     = 'ohloh'
  @targetCollectionName     = 'ohlohImportTest'
  
  @migrate:(instance)->
    
    exportingConnection = new @Connection().open @sourceDatabase, =>
      
      exportingCollection = new @Collection @sourceCollectionName, exportingConnection
      importingCollection = new @Collection @targetCollectionName, exportingConnection
      
      exportingCollection.find {}, [], limit:100, (err, cursor)->
        cursor.toArray (err, arr)->
          unless err
            arr.forEach (record)->
              
              licenses = record.licenses.license
            
              importingCollection.insert
                 Message: [{
                   type:            'App'
                   body:            record.description
                   data:
                     homepageUrl:     record.homepage_url
                     downloadUrls:    [record.download_url]
                     logo:
                       mediumUrl:     record.logo.mediumUrl
                       smallUrl:      record.logo.smallUrl
                     licenses:        if _.isArray licenses then licenses else [licenses]
                     ohlohId:         record.id
                 }]
                 
              , (err) -> throw err if err