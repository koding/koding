package com.koding.linkedlist

import javax.ws.rs.Path
import org.neo4j.graphdb.GraphDatabaseService
import javax.ws.rs.core.Context
import javax.ws.rs.POST
import javax.ws.rs.FormParam
import javax.ws.rs.QueryParam
import javax.ws.rs.DELETE
import javax.ws.rs.GET

@Path("/")
class LinkedListExtension(@Context db: GraphDatabaseService) {

  @POST
  @Path("/list")
  def createLinkedList(@FormParam("head") headUrl: String, @FormParam("tail") tailUrl: String) {
  }

  @POST
  @Path("/entry")
  def addEntry(@FormParam("previous") previousUrl: String, @FormParam("entry") entryUrl: String) {
  }

  @DELETE
  @Path("/entry")
  def removeEntry(@QueryParam("entry") entryUrl: String) {
  }
  
  @GET
  @Path("/entry/previous")
  def getPreviousEntry(@QueryParam("entry") entryUrl: String) {
  }
  
  @GET
  @Path("/entry/all")
  def getAllPreviousEntries(@QueryParam("entry") entryUrl: String) {
  }

}