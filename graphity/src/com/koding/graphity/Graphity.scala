package com.koding.graphity

import scala.collection.JavaConversions.iterableAsScalaIterable
import org.neo4j.graphdb.Direction
import org.neo4j.graphdb.GraphDatabaseService
import org.neo4j.graphdb.Node
import org.neo4j.graphdb.RelationshipType
import com.google.gson.Gson
import javax.ws.rs.GET
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.QueryParam
import javax.ws.rs.core.Context
import javax.ws.rs.core.Response
import scala.collection.mutable.ListBuffer

// Graphity algorithm implementation.
// 
// External node types: source, stream, event.
// Internal node types: source, stream, event, subscription.
// 
// Internal architecture:
// - External nodes point to corresponding internal nodes.
// - Stream node is tail of a linked list of subscription nodes.
// - Subscription node points to source node.
// - Source node is tail of a linked list of event nodes.
@Path("/")
class Graphity(@Context db: GraphDatabaseService) {

  // Points from one external stream node to one internal stream node.
  object GRAPHITY_STREAM extends RelationshipType { def name(): String = "GRAPHITY_STREAM" }
  
  // Points from one external source node to one internal source node.
  object GRAPHITY_SOURCE extends RelationshipType { def name(): String = "GRAPHITY_SOURCE" }

  // Points from one external event node to MULTIPLE internal event nodes.
  object GRAPHITY_EVENT extends RelationshipType { def name(): String = "GRAPHITY_EVENT" }

  // Points from MULTIPLE internal subscription nodes to one internal source node.
  object GRAPHITY_SUBSCRIBED_TO extends RelationshipType { def name(): String = "GRAPHITY_SUBSCRIBED_TO" }

  // Subscribes stream to source so it will return events added to source.
  @POST
  @Path("/subscriptions")
  def addSubscription(@QueryParam("stream") streamUrl: String, @QueryParam("source") sourceUrl: String) = {
    val tx = db.beginTx()
    try {
      val stream = getInternalNode(streamUrl, GRAPHITY_STREAM)
      val source = getInternalNode(sourceUrl, GRAPHITY_SOURCE)

      val subscription = db.createNode()
      subscription.createRelationshipTo(source, GRAPHITY_SUBSCRIBED_TO)
      insertSubscription(stream, subscription)

      tx.success()
    } finally {
      tx.finish()
    }
  }

  // Adds event to source at the given timestamp. An event is more recent if it has a higher timestamp value.
  @POST
  @Path("/events")
  def addEvent(@QueryParam("source") sourceUrl: String, @QueryParam("event") eventUrl: String, @QueryParam("timestamp") timestamp: Long) = {
    val tx = db.beginTx()
    try {
      val source = getInternalNode(sourceUrl, GRAPHITY_SOURCE)
      val eventExternalNode = getNodeFromUrl(eventUrl)

      val eventNode = db.createNode()
      eventNode.setProperty("timestamp", timestamp)
      eventExternalNode.createRelationshipTo(eventNode, GRAPHITY_EVENT)
      LinkedList.insertFromTail(source, { previous => getEventTimestamp(previous) <= timestamp }, eventNode)

      updateSource(source)

      tx.success()
    } finally {
      tx.finish()
    }
  }

  // Gets most recent events from stream. Those are the most recent events of all sources that this stream is subscribed to.
  @GET
  @Path("/events")
  def getEvents(@QueryParam("stream") streamUrl: String, @QueryParam("count") count: Int): Response = {
    val tx = db.beginTx()
    try {
      val stream = getInternalNode(streamUrl, GRAPHITY_STREAM)
      val events = getEventNodes(stream, count)
      tx.success()

      Response.ok(events.reverseMap(e => {
        val externalNode = e.getSingleRelationship(GRAPHITY_EVENT, Direction.INCOMING).getStartNode()
        "\"" + getUrlFromNode(externalNode) + "\""
      }).mkString("[", ", ", "]")).build()
    } finally {
      tx.finish()
    }
  }
  
  // Helper for getEvents.
  def getEventNodes(stream: Node, count: Int): List[Node] = {
    var results: List[Node] = Nil
    var previousSubscription = LinkedList.getPrevious(stream)
    var previousSubscriptionTimestamp = getSubscriptionTimestamp(previousSubscription)

    val candidates = new ListBuffer[Node]()
    val insertCandidate: (Node) => Unit = event => {
      val timestamp = getEventTimestamp(event)
      if (timestamp != 0) {
        val index = candidates.indexWhere(c => getEventTimestamp(c) < timestamp)
        if (index == -1) {
          candidates.append(event)
        } else {
          candidates.insert(index, event)
        }
      }
    }

    for (_ <- 1 to count) {
      val event = if (candidates.length == 0 || getEventTimestamp(candidates.head) < previousSubscriptionTimestamp) {
        if (previousSubscriptionTimestamp == 0) {
          return results
        }
        val source = previousSubscription.getSingleRelationship(GRAPHITY_SUBSCRIBED_TO, Direction.OUTGOING).getEndNode()
        previousSubscription = LinkedList.getPrevious(previousSubscription)
        previousSubscriptionTimestamp = getSubscriptionTimestamp(previousSubscription)
        LinkedList.getPrevious(source)
      } else {
        val first = candidates.head
        candidates.trimStart(1)
        first
      }
      results ::= event
      insertCandidate(LinkedList.getPrevious(event))
    }

    return results
  }

  // Inserts the subscription at the correct position of the stream's subscription list.
  def insertSubscription(stream: Node, subscription: Node) = {
    val timestamp = getSubscriptionTimestamp(subscription)
    LinkedList.insertFromTail(stream, { previous => getSubscriptionTimestamp(previous) <= timestamp }, subscription)
  }

  // Updates all subscription lists which have a subscription to source.
  def updateSource(source: Node) = {
    source.getRelationships(GRAPHITY_SUBSCRIBED_TO, Direction.INCOMING).foreach({ rel =>
      val subscription = rel.getStartNode()
      val stream = LinkedList.remove(subscription)
      insertSubscription(stream, subscription)
    })
  }

  // Gets timestamp from event node.
  def getEventTimestamp(event: Node): Long = {
    event.getProperty("timestamp") match {
      case v: java.lang.Integer => v.longValue()
      case v: java.lang.Long => v.longValue()
    }
  }

  // Gets timestamp from most recent event node of subscription.
  def getSubscriptionTimestamp(subscription: Node): Long = {
    val subRel = subscription.getSingleRelationship(GRAPHITY_SUBSCRIBED_TO, Direction.OUTGOING)
    if (subRel == null) {
      return 0
    }
    getEventTimestamp(LinkedList.getPrevious(subRel.getEndNode()))
  }

  def getNodeFromUrl(url: String): Node = {
    val parts = url.split("/")
    db.getNodeById(parts(parts.length - 1).toLong)
  }

  def getUrlFromNode(node: Node): String = {
    return "http://localhost:7474/db/data/node/" + node.getId()
  }

  def getInternalNode(externalNodeUrl: String, relType: RelationshipType): Node = {
    val externalNode = getNodeFromUrl(externalNodeUrl)

    val rel = externalNode.getSingleRelationship(relType, Direction.OUTGOING)
    if (rel != null) {
      return rel.getEndNode()
    }

    val internalNode = db.createNode()
    externalNode.createRelationshipTo(internalNode, relType)

    relType match {
      case GRAPHITY_SOURCE =>
        val headEvent = db.createNode()
        headEvent.setProperty("timestamp", 0)
        LinkedList.init(headEvent, internalNode)
      case GRAPHITY_STREAM =>
        LinkedList.init(db.createNode(), internalNode)
    }

    internalNode
  }

}