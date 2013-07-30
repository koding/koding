package com.koding.graphity

import org.scalatest.FunSuite
import com.sun.jersey.api.client.Client
import com.sun.jersey.core.util.MultivaluedMapImpl
import com.google.gson.Gson

class GraphityTestSuite extends FunSuite {

  class Node {
    var self = ""
  }

  val gson = new Gson()
  val client = Client.create()
  val db = client.resource("http://localhost:7474/db/data/")
  val graphity = client.resource("http://localhost:7474/graphity/")

  test("inserting and retrieving events") {
    val streamUrl = createNode()
    println("stream", streamUrl)

    val source1Url = createNode()
    println("source1", source1Url)
    graphity.path("subscriptions").queryParam("source", source1Url).queryParam("stream", streamUrl).post()

    val source2Url = createNode()
    println("source1", source2Url)
    graphity.path("subscriptions").queryParam("source", source2Url).queryParam("stream", streamUrl).post()

    val event2Url = createNode()
    println("event2", event2Url)
    graphity.path("events").queryParam("source", source1Url).queryParam("event", event2Url).queryParam("timestamp", "2").post()

    val event3Url = createNode()
    println("event3", event3Url)
    graphity.path("events").queryParam("source", source2Url).queryParam("event", event3Url).queryParam("timestamp", "3").post()

    val event1Url = createNode()
    println("event1", event1Url)
    graphity.path("events").queryParam("source", source1Url).queryParam("event", event1Url).queryParam("timestamp", "1").post()

    val json1 = graphity.path("events").queryParam("stream", streamUrl).queryParam("count", "2").get(classOf[String])
    val list1 = gson.fromJson(json1, classOf[java.util.List[String]])
    assert(list1.size() === 2)
    assert(list1.get(0) === event3Url)
    assert(list1.get(1) === event2Url)

    val json2 = graphity.path("events").queryParam("stream", streamUrl).queryParam("count", "10").get(classOf[String])
    val list2 = gson.fromJson(json2, classOf[java.util.List[String]])
    assert(list2.size() === 3)
    assert(list2.get(0) === event3Url)
    assert(list2.get(1) === event2Url)
    assert(list2.get(2) === event1Url)
  }

  def createNode(): String = {
    val json = db.path("node").accept("application/json").post(classOf[String])
    val node = gson.fromJson(json, classOf[Node])
    return node.self
  }

}