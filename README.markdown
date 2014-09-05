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

# Build 

We need to, build (go binaries), transpile (coffee-javascript, stylus-css), generate (sprites), install (npm modules), test the codebase before all kinds of deployment, those are all handled by [Wercker](https://app.wercker.com/#applications/53cd92eedabd120e390b36b). It uses `wercker.yml` file that is located at the root of this repository:

If you want your code to be built, just open merge request to `main branch` (as the time of writing it is `newkoding`, will be replaced by master soon). It will be built automatically, and you will be able to see the result of it under you PR. [e.g](http://note.io/1unWQ7K)

# Deployment

Deployment process is carried out by [Wercker](https://app.wercker.com/#applications/53cd92eedabd120e390b36b) also. It uses `wercker.yml` file that is located at the root of this repository:

Steps that we have in that file:

* create-file      : we are creating a `VERSION` file to store the head commit ID 
* zip              : we are zipping the whole repo excluded `.git .build node_modules go/bin go/pkg`
* s3put            : we are putting created zip file to S3, to be able to reproduce it again.
* eb-deploy        : we are triggering a deploy operation on the EB(Elastic Beanstalk) side, in short we are telling EB to use a zip file to build the current servers
* notify slack     : we are sending a notification to Slack, about we have done with the deployment process on the Wercker side, but it doesnt mean that deployment is done! Only `Wercker` just finished its job, now its EB's turn.  


## Sandbox deployment [sandbox.koding.com](sandbox.koding.com)

### Server Structure 

* Sandbox has its own [EB env](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/dashboard?applicationName=koding&environmentId=e-2cvytmsvqf). All of our `workers` are running in one [server](54.165.12.215). Our `services` for sandbox env are: postgres, mongo, redis, rabbitmq, etcd

### Deployment process

Usual workflow is merging upstream development branch into branch
called `sandbox`. This can be done manually using `git-merge` or by
opening a pull request on GitHub. Merging changes into `sandbox`
branch will start a build job on
[wercker](https://app.wercker.com/#applications/53cd92eedabd120e390b36bd). Build
revision will be deployed to `sandbox` target automatically if build
job succeeds. You can force push the upstream development branch if
`sandbox` is diverged from it.

Alternatively, experimental changes can be pushed to sandbox by
rebasing your changes on top of `sandbox` or upstream development
branch. This is practical if these changes are not breaking or
blocking any other part.
 

## Production deployment [koding.com](https://koding.com)

### Server Structure

* Production has its own EB env [koding-prod](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/dashboard?applicationName=koding&environmentId=e-x2yfycg3tm). 
* Latest has its own EB env  [koding-latest](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/dashboard?applicationName=koding&environmentId=e-3puhn8mma6).
* All of our `workers` are running in every server that we have for prod. They are exposed to the internet via nginx. We are deamonizing workers in servers with supervisord. You can see all the workers that we have in config files. eg: main.prod.coffee
* Mongo         : [ObjectRocket](https://app.objectrocket.com/instances/koding_prod01)
* Postgres      : [RDS](https://console.aws.amazon.com/rds/home?region=us-east-1#dbinstances:id=prod0;sf=all)
* Redis         : [ElasticCache](https://console.aws.amazon.com/elasticache/home?region=us-east-1#)
 
### Deployment process  [latest.koding.com](https://latest.koding.com)

Main purpose of this step is to see that our app works in production environment.

After getting acceptance on [sandbox env](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/dashboard?applicationName=koding&environmentId=e-2cvytmsvqf) Next step will be deploying it to latest, for this purpose:
* Go to the build, that you want to deploy to prod. [e.g](http://note.io/1vUrhFI)
* Click `Deploy to`, you will see env listed there [e.g](http://note.io/1vUuOnn) 
* If you click any of them, it will start deployment, when it is done -> [e.g](http://note.io/1wb9Fm2)


### Deployment process  [koding.com](https://koding.com)
Same rules applies with production deployment


## Logging 

Our server logs are aggregated at [PaperTrail](https://papertrailapp.com/) You can easily see the the creation time of the log, app name and the host name in the [logs](http://note.io/1oNcu6Z) 

## Debugging / Troubleshooting

Worker/service configurations are in usual configuration
directory. All configurations contain the necessary information to
find out/traceback how a worker is set up and where (external)
services are located.


When you feel something is wrong, first of all just notify others that you realized a problem and started working on it. Then check the aggregated logs. If you see an error there you  can find the server name from the logs [e.g.](http://note.io/1oNcu6Z) There can be options about fixing the problem, even one of them can be `destroying` the machine, auto scaling will create a new one for us. 

