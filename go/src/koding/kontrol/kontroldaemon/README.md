**Kontrol Server** is a central management server to control various
aspects of processes on remote machines. It has these following features:

* Get basic information from the process. This basically monitors every process,
thus you know if a process is running or not responding
* Start, stop or kill any connected remote process
* Get information about the process (like memory usage, uptime)
* Approval mechanism:
  * Only run processes on certain hostnames. It supports wildcards (like
    sub.*.koding.com, local.foo, etc..)
  * Only run process with the same name (thus if a process is running, another
    one can't run it)
  * Run with force option, which stops and kills all other processes with the same name.
* JSON based api, thus you can write your own tools to communicate with kontrol
  server (more info on this is explained below)

Currently two tools are using the JSON based messaging api. These are:

* kontrol-cli: To run kontrol-cli execute `cake kontrol`. This will show all the
information about all processes in a interactive table. You can remotely change
processes (like stopping them), get process information, do batch actions (like
starting all processes on a spesficif hostname).

* kontrol-api: Please refer to kontrol-api/README.md for more info.

Basically, Kontrol is a gateway that controlls any aspect of a remote process.
It uses a kontrol-helper module, which is used inside our processess module.
Because Kontrol-server uses RabbitMq for sending/receiving messages, it
basically supports all main programming languages (Python, Node.js, Ruby, Go,
Java,etc..). To connect a process to the kontrol server, it basically just have
to agree on a JSON bassed message protocol. However currently application
written in Node can benefit from parent-child communication. This is explained
in more detail below with the "emailWorker" example

## Configure and install Kontrol Server

Kontrol Server is written in Go and residue in the folder:

`/go/src/koding/kontrold`

It's already baked in our internal Go structure. That means a `cake compileGo`
will compile and copy the binary to the `/kites` folder. The rabbitmq
configuration is stored currently in the config/main.dev.coffe  as:

```
kontrold    :
  host        : 'ktl.koding.com'
  port        : '5672'
  login       : 'guest'
  password    : '@-SX7DsD$fvD2&R'
  vhost       : '/'
```

To run just execute the binary:

```
./kites/kontrold -c "dev"
```

to run with verbose mode add `-v`

## How to integrate a process with Kontrol Server?

Previously, a process was started like:

```
cake fooWorker
```

This command is actually a wrapper around our own processes node module. The
code that runs this is:

```
task 'fooWorker',({configFile})->
  processes.fork
    name            : 'fooWorker'
    cmd             : "./workers/fooWorker/index -c #{configFile}"
```

Now, any process that agrees to communicate with kontrol needs a permission to
run (which is given by the Kontrol itself). To communicate with kontrol, we only
have to add the needPermission key:

```
task 'fooWorker',({configFile})->
  processes.fork
    name            : 'fooWorker'
    cmd             : "./workers/fooWorker/index -c #{configFile}"
    kontrol         :
      enabled       : yes
      startMode     : "one"
      
```

This flag basically creates a helper-process inside our processes module, which
communicate with the Kontrol server. Kontrol server first looks if there is any
other process running, if yes it doesn't let the process to be run. To run the
process, one have to stop or kill the other machine. But you have the option to
force start it (via the `force` option):

```
task 'fooWorker',({configFile})->
  processes.fork
    name            : 'fooWorker'
    cmd             : "./workers/fooWorker/index -c #{configFile}"
    kontrol         :
      enabled       : yes
      startMode     : "force"
```

This stops and kills all running process with the same name.

There might be processes that can be run multiple times on the same machine.
Like a webserver. To start multiple workers with the same type, use 'many' as
startmode

```
task 'fooWorker',({configFile})->
  processes.fork
    name            : 'fooWorker'
    cmd             : "./workers/fooWorker/index -c #{configFile}"
    kontrol         :
      enabled       : yes
      startMode     : "many"
```

Kontrol also have the option to communicate directly with the process itself.
What does it mean? Basically, you can programm your process in a way, that when
the process receives a start or stop action, it do certain stuff on the
programming level. Let's give an example:

Assume you have an email-worker that implements a cronjob, which deliveres
emails on certain time intervals. Your programm (written in Node.js) is like:

```
do ->
  instantEmailsCron.start()
  dailyEmailsCron.start()
```

If your process is connected to the Kontrol server, than the Kontrol server can
kill your process or restart it again. However you change this behaviour via the
`nodeProcess` option. Basically you create a process like:

```
task 'emailWorker',({configFile})->
  processes.fork
    name            : 'emailWorker'
    cmd             : "./workers/email/index -c #{configFile}"
    kontrol         :
      enabled       : yes
      nodeProcess   : yes
```

Now you can basically alter the 'start' and 'stop' commands your process is
receiving from the Kontrol server. Just listen to the kontrol-helper messages in
your programm:

```
do ->
  process.on 'message', (msg) ->
    switch msg
      when 'startRequest'
        instantEmailsCron.start()
        dailyEmailsCron.start()
        process.send 'workerStarted'
      when 'stopRequest'
        instantEmailsCron.stop()
        dailyEmailsCron.stop()
        process.send 'workerStopped'
```

Now, a 'start' command from the kontrol-server will send a 'startRequst' message
to your program. You can then start your cron jobs and let the kontrol-server
acknowledging that you have started. But if you receive a 'stop' command, then
you can just simply stop your cron jobs (like in the example above). This is
just a simple example how you can implement these.


## How to communicate with the Kontrol Server

To communicate with the server you have to connect to the rabbitmq server.
Kontrol server uses a 'topic' exchange to consume and publish back the messages.
Your tool basically have to do these things in order:

1. For receiving data
  1. Create an aqmp connection the `ktl.koding.com` rabbit-server
  2. Declare an exchange of name: `infoExchange`, type: `topic` and options of
  `{autoDelete: no, durable : no}`
  3. Declare a queue with name `<yourProgName>-<yourUniqueID>`. Your program
  name can be anything, however your unique_id should be stored in your program.
  The queue-name is useful for debugging rabbitmq (to identify and see how your
  messages are going)
  4. Bind your queue to the `infoExchange`, with the key `output.cli.<yourUniqueID>`.
  This is your queue that consumes the messages.

2. For sending data
  1. Create an aqmp connection the `ktl.koding.com` rabbit-server
  2. Declare an exchange of name: `infoExchange`, type: `topic` and options of
  `{autoDelete: no, durable : no}`
  3. Publish your message to this exchange via the key `input.cli` and property
  `appId: <yourUniqueId>`

For an example how to do this, please have a look at node_modules_koding/kontrol/main.coffee

## JSON based Message Protocol

Kontrol server uses an internal message format to communicate with each process.
Beside that, there is an public interface to get information and control the
processes via a message protocol. After connecting to the the rabbitmq server
(explained above) you can communicate with the format explained below:

#### REQUEST format

```json
{
  "command": "",
  "hostname": "",
  "uuid": ""
}
```

`command` can be

* `status`, to get information about the process
* `delete`, to delete not responding or not started processes from kontrol
* `start`, to start killed or stopped processes
* `stop`, to stop a process
* `kill`, to kill a process

If you send a message like:

```json
{
  "command": "status",
  "hostname": "",
  "uuid": ""
}
```

Then you get the status information of all processes available. However you can
filter it like:

```json
{
  "command": "status",
  "hostname": "foo.example.com",
  "uuid": ""
}
```

This will give you the status information of processes that are available on the
'foo.example.com' domain. If you give the uuid of the process, than you will only
receive the status information of that process:

```json
{
  "command": "status",
  "hostname": "foo.example.com",
  "uuid": "<someuniqueuuid>"
}
```

In order to get the hostname and uuid of the processes, you have to send the basic
status request:

```json
{
  "command": "status",
  "hostname": "foo.example.com",
  "uuid": ""
}
```

This will give you all the information you need in order to do some actions on
the processes.

### RESPONSE format

Currently there is only one response format, which comes for the 'status'
command. Its in the format of:

```json
{
  "status": {
    "<hostname>": [
      {
        "name": "<processname>",
        "uuid": "<someuniqueuuid>",
        "pid": 0,
        "status": 4,
        "timestamp": "2013-03-19T11:18:46.565114224Z",
        "memory": 0,
        "uptime": 0
      }
    ]
  }
}
```

The corresponding keys are:

* hostname : an array of processes. Each process is grouped according to this hostname. Their
           can be several hostnames (each with ther own associated processes)
* name     : a string that defines the process name. This is set in the processes.fork `{name: ""}` option
* uuid     : a string that defines the process uuid. This is unique and is used for request messages
           and intercommunication between kontrol-server and processes
* pid      : an int that defines the pid of the process.
* status   : an int that defines the status of the process. There are currently six types:
  * stopped == 0 , process is stopped
  * running == 1 , process is running
  * pending == 2 , internal usage for kontrol-server (will deprecated in the future)
  * notstarted == 3, process is registered but has not started yet
  * notresponding == 4, process was alive(started or stopped) previously, but is not sending any data more
* timestamp: a string that defines the latest message received from the process
* memory: an int that gives the total memory usage of the process
* uptime: an int that gives the uptime of the process
