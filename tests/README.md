### Running tests in local development environment


To run Nightwatch tests in your local development environment you need to set `startProcess` to `true` in `nightwatch.json` at line 9.

Then you need to go tests folder and run tests.

```
cd tests
./test activity post
```

`./test` takes 2 parameters. First one suite name which is a folder name under `tests/src` folder. Second one is optional. If you don’t pass second parameter all tests in that folder will be run. Second parameter should be file name in that folder. Here is the examples.


- `./test activity` this will run all tests for activity
- `./test activity editdelete` this will just run edit delete tests
- `./test ide` run all tests for IDE
- `./test ide workspace` run workspace related tests for IDE.
