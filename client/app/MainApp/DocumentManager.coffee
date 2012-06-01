class DocumentManager extends KDObject
  
  untitledNumber = 0

  constructor:->

    super
    @openDocuments = []
  
  getOpenDocuments:->
    
    return @openDocuments

  addOpenDocument:(doc)->

    @openDocuments.push doc

  removeOpenDocument:(doc)->

    @openDocuments.splice (@openDocuments.indexOf doc), 1

  createEmptyDocument:->

    docs    = @getOpenDocuments()
    postfix = if untitledNumber is 0 then "" else "_#{untitledNumber}"
    doc     = FSHelper.createFileFromPath "localfile:/Untitled#{postfix}.txt"
    
    return doc
    
    