OS Kite
=======

## Methods
- vm.start
- vm.shutdown
- vm.stop
- vm.reinitialize
- vm.info
- vm.createSnapshot
- spawn [array of strings]
- exec [string]
- fs.readDirectory { path: [string], onChange: [function] }
- fs.readFile { path: [string] }
- fs.writeFile { path: [string], content: [base64], doNotOverwrite: [bool] }
- fs.ensureNonexistentPath { path: [string] }
- fs.getInfo { path: [string] }
- fs.setPermissions { path: [string], mode: [integer], recursive: [bool] }
- fs.remove { path: [string], recursive: [bool] }
- fs.rename { oldPath: [string], newPath: [string] }
- fs.createDirectory { path: [string], recursive: [bool] }
- app.install { owner: [string], identifier: [string], version: [string], appPath: [string] }
- app.download { owner: [string], identifier: [string], version: [string], appPath: [string] }
- app.publish { appPath: [string] }
- app.skeleton { type: [string], appPath: [string] }
- webterm.getSessions
- webterm.createSession { remote: [object], name: [string], sizeX: [integer], sizeY: [integer] }
- webterm.joinSession { remote: [object], sessionId: [integer], sizeX: [integer], sizeY: [integer] }
