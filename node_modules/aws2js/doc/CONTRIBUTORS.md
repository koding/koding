## aws2js contributors, in order of first contribution

 * [Dan Tillberg](https://github.com/tillberg) - deprecation of [query.call()](https://github.com/SaltwaterC/aws2js/wiki/query.call%28%29) in favor of [query.request()](https://github.com/SaltwaterC/aws2js/wiki/query.request%28%29).
 * [Andrew Paulin](https://github.com/ConstantineXVI) - [sqs.setQueue()](https://github.com/SaltwaterC/aws2js/wiki/sqs.setQueue%28%29) helper.
 * [Dave Cleal](https://github.com/dcleal)
  * client loader creates a new object on invocation.
  * passing HTTP options to the client loader.
  * attached a parsed XML document when the connection is prematurely closed.
 * [Carlos Guerreiro](http://perceptiveconstructs.com/) - the query argument for the [s3.get()](https://github.com/SaltwaterC/aws2js/wiki/s3.get%28%29) method.
 * [Nikita](https://github.com/nab) - global variable leak fix.
 * [AYUkawa,Yasuyuk](https://github.com/toomore-such) - enabled the multiregion support for DynamoDB.
 * [ske](https://github.com/ske) - corrected URL module's alias from 'url' to 'u'.
 * [Joe Roberts](https://github.com/zefer) - global variables leak fix.
 * [sauvainr](https://github.com/sauvainr) - 307 Redirection host overwritten error.
 * [Thomas Bruyelle](https://github.com/tbruyelle) - The S3 lifecycle management API.
 * [Dan Ordille](https://github.com/dordille) - fixes a double callback calling for the DynamoDB client.
 * [ubert](https://github.com/ubert) - [s3.copyObject()](https://github.com/SaltwaterC/aws2js/wiki/s3.copyObject%28%29).
 * [Jacky Jiang](https://github.com/t83714) - enabled the ?delete S3 subresource.
 * [Alon Burg](http://burg-alon.9folds.com/) - reverted the usage of Stream.pipe() for the Stream Request Body Handler.
 * [Matt Monson](https://github.com/mattmonson) - fixed the inconsistent use of the default 'utf8' encoding for the String Request Body Handler of the s3.put() method.
 * [Stephen Lynn](https://github.com/lynns) - removed the npm purging code that breaks npm rebuild on environments like Heroku.
 * [Dan Ordille](https://github.com/dordille) - fixed the broken header signing for DynamoDB when the request body contains UTF-8 chars.
