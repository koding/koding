package com.koding.linkedlist

import javax.ws.rs.Path
import org.neo4j.graphdb.GraphDatabaseService
import javax.ws.rs.core.Context
import javax.ws.rs.POST
import javax.ws.rs.FormParam
import javax.ws.rs.QueryParam
import javax.ws.rs.DELETE
import javax.ws.rs.GET
import org.neo4j.graphdb.Node
import javax.ws.rs.core.Response

@Path("/")
class LinkedListExtension(@Context db: GraphDatabaseService) {

  @POST
  @Path("/list")
  def createList(@FormParam("head") headUrl: String, @FormParam("tail") tailUrl: String) {
    val tx = db.beginTx
    try {
      LinkedList.init(getNodeFromUrl(headUrl), getNodeFromUrl(tailUrl))
      tx.success
    } finally {
      tx.finish
    }
  }

  @DELETE
  @Path("/list")
  def destroyList(@QueryParam("entry") entryUrl: String) {
    val tx = db.beginTx
    try {
      LinkedList.destroy(getNodeFromUrl(entryUrl))
      tx.success
    } finally {
      tx.finish
    }
  }

  @POST
  @Path("/entry")
  def addEntry(@FormParam("previous") previousUrl: String, @FormParam("next") nextUrl: String, @FormParam("entry") entryUrl: String) {
    val tx = db.beginTx
    try {
      if (previousUrl != null) {
        val previous = if (previousUrl.endsWith(":head")) {
          LinkedList.getHead(getNodeFromUrl(previousUrl.substring(0, previousUrl.length() - 5)))
        } else {
          getNodeFromUrl(previousUrl)
        }
        LinkedList.insertAfter(previous, getNodeFromUrl(entryUrl))
      } else {
        val next = if (nextUrl.endsWith(":tail")) {
          LinkedList.getTail(getNodeFromUrl(nextUrl.substring(0, nextUrl.length() - 5)))
        } else {
          getNodeFromUrl(nextUrl)
        }
        LinkedList.insertBefore(next, getNodeFromUrl(entryUrl))
      }
      tx.success
    } finally {
      tx.finish
    }
  }

  @DELETE
  @Path("/entry")
  def removeEntry(@QueryParam("entry") entryUrl: String) {
    val tx = db.beginTx
    try {
      LinkedList.remove(getNodeFromUrl(entryUrl))
      tx.success
    } finally {
      tx.finish
    }
  }

  @GET
  @Path("/entry/previous")
  def getPreviousEntry(@QueryParam("entry") entryUrl: String) = {
    val tx = db.beginTx
    try {
      val previous = LinkedList.getPrevious(getNodeFromUrl(entryUrl))
      val response = Response.ok(getUrlFromNode(previous)).build
      tx.success
      response
    } finally {
      tx.finish
    }
  }

  @GET
  @Path("/entry/all")
  def getAllEntries(@QueryParam("entry") entryUrl: String) = {
    val tx = db.beginTx
    try {
      val tail = LinkedList.getTail(getNodeFromUrl(entryUrl))
      val response = Response.ok(LinkedList.getAll(tail).tail.reverseMap(e => {
        "\"" + getUrlFromNode(e) + "\""
      }).mkString("[", ", ", "]")).build

      tx.success
      response
    } finally {
      tx.finish
    }
  }

  def getNodeFromUrl(url: String) = {
    val parts = url.split("/")
    db.getNodeById(parts(parts.length - 1).toLong)
  }

  def getUrlFromNode(node: Node) = {
    "/node/" + node.getId
  }

}