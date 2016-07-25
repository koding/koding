//Package neo4j - simple Neo4J REST API wrapper
/*

Neo4j Package uses Neo4j Graph Database REST API for providing access to go clients.

Apart from standard packages this package uses Batch REST API of Neo4j Graph Database.
For more info about Batch API you can refer to;

	http://docs.neo4j.org/chunked/stable/rest-api-batch-ops.html

This usage not only lets us to execute multiple API calls with a single HTTP call for improving
performance, but also lets us to use a singular way to execute our transactions.
On the other hand, up until now (Neo4j 1.9.1 version) there is not any transaction management for
more than one query. With this package you can send your queries within a transaction.
Since this operations are transactional, if any of the operation fails, whole transaction
will be rolled back and all changes will be undone.

Node Usages:

*/
package neo4j
