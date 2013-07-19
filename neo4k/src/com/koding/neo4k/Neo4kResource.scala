package com.koding.neo4k

import javax.ws.rs.Path
import org.neo4j.graphdb.GraphDatabaseService
import javax.ws.rs.Produces
import javax.ws.rs.PathParam
import javax.ws.rs.GET
import javax.ws.rs.core.Context
import javax.ws.rs.core.Response
import com.google.gson.Gson
import java.io.PipedInputStream
import java.io.OutputStreamWriter
import java.io.PipedOutputStream
import javax.ws.rs.QueryParam

@Path("/")
class Neo4kResource {
  class Request {
    var method = ""
  }

  class ActivityEntry {
    var content = ""
  }

  val gson = new Gson()

  @GET
  @Path("/")
  @Produces(Array("application/json"))
  def endpoint(@Context db: GraphDatabaseService, @QueryParam("request") requestJson: String) = {
    var request = gson.fromJson(requestJson, classOf[Request])

    var entry = new ActivityEntry()
    entry.content = "Hello: " + request.method

    var in = new PipedInputStream()
    var w = new OutputStreamWriter(new PipedOutputStream(in))
    gson.toJson(entry, w)
    w.close()

    Response.ok(in).build()
  }
}