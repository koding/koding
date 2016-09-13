
## Rainforest Tests in Koding
Rainforest is a crowdsourced testing platform. You can write functional tests and regression tests for web and mobile apps, integrated with CI/CD workflow on the Rainforest platform.
Rainforest-cli is a command line interface to interact with RainforestQA. It is compatible with all build systems. It's easy to install

## Rainforest Test Cases

All Rainforest test cases are located under ```koding/client/test/rainforest/test``` directory.

## Setup Environment

Follow steps in  https://github.com/koding/koding in order to setup koding environment.

You can install rainforest-cli with the gem utility. Open terminal and execute the following line

```gem install rainforest-cli```


### Running Tests

Execute to following line in order to run all tests

```sh
rainforest run all --token <YOUR API TOKEN>  --fg
```

You can execute test by name 
```sh
rainforest run --token <YOUR API TOKEN> <Test_Name> --fg 
```


You can execute test by ID 
```sh
rainforest run --token <YOUR API TOKEN> <Test_ID> --fg
```

## License

Koding is licensed under [Apache 2.0.](https://github.com/koding/koding/blob/master/LICENSE)
