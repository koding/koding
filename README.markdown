# Koding (the repository)

[![wercker status](https://app.wercker.com/status/8da42fd35762f3883b96b6d85b3f0c46/m "wercker status")](https://app.wercker.com/project/bykey/8da42fd35762f3883b96b6d85b3f0c46)

Welcome! This is the main Koding repository. Below you can find some
information about the folder structure.

* client:  contains all our client based code. Like our KDFramework, css
           assets, our Koding.com mainpage, apps and so on

* config:  contains all our configurations files. All our apps in the codebase
           is reading from this folder to set certain things, like mongdob credentials,
           ports to be bind, number of instances to be run and so on.

* docs:    contains docs about some of our core technologies. Once created,
           they never did get an update for a long time. So don't except
           anything new there (it's needs love)

* go:      contains code that was written in Go language. It contains lot's of our
           core backend technologies. If you write something in Go it goes here.

* migrate: contains migration scripts. These scripts are usually used whenever
           we introduce something new and mongdob needs a major update or if change
           something very deeply.

* node_modules: contains all standard node modules use by our node.js apps and
                symlinks from the node_modules_koding folder. This is populated via the
                package.json file.

* node_modules_koding: contains node modules that were written by Koding developers.
                       If you execute "npm install" a symlink for every folders
                       is created to node_modules folder.

* scripts: contains several handy scripts for certains tasks. please refer to
           scripts/Readme.md for more information

* server:  contains our webserver written in express.js.

* team:    a folder for our remote working developers. You can find the working
           hours of every remote working developers here.

* tests:   PLEASE FILL HERE

* vagrant: PLEASE FILL HERE

* website: assets used by the webserver for our koding.com homepage

* workers: contains all our backend based code. Like authWorker, socialWorker
           and so on. All these workers also carry the associated bongo models.
