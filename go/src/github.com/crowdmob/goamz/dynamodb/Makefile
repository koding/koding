DYNAMODB_LOCAL_VERSION = 2014-10-07

launch: DynamoDBLocal.jar
	cd dynamodb_local_$(DYNAMODB_LOCAL_VERSION) && java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar

DynamoDBLocal.jar: dynamodb_local_$(DYNAMODB_LOCAL_VERSION).tar.gz
	mkdir -p dynamodb_local_$(DYNAMODB_LOCAL_VERSION)
	[ -f dynamodb_local_$(DYNAMODB_LOCAL_VERSION)/DynamoDBLocal.jar ] || tar -C dynamodb_local_$(DYNAMODB_LOCAL_VERSION) -zxf dynamodb_local_$(DYNAMODB_LOCAL_VERSION).tar.gz

dynamodb_local_$(DYNAMODB_LOCAL_VERSION).tar.gz:
	curl -O https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_$(DYNAMODB_LOCAL_VERSION).tar.gz

clean:
	rm -rf dynamodb_local_$(DYNAMODB_LOCAL_VERSION)*
