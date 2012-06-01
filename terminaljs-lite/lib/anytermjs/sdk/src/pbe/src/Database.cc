// src/Database.cc
// This file is part of libpbe; see http://decimail.org
// (C) 2004 - 2007 Philip Endecott

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#include "Database.hh"

#include "Exception.hh"
#include "utils.hh"
#include "StringTransformer.hh"

#include <map>
#include <string>

#include <boost/lexical_cast.hpp>
#include <boost/scoped_ptr.hpp>
#include <boost/algorithm/string/predicate.hpp>
#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/trim.hpp>

#include <libpq-fe.h>
#include <postgres.h>
#include <catalog/pg_type.h>

using namespace std;


namespace pbe {


static typecode_t oid_to_typecode(Oid oid)
{
  switch(oid) {
    case TEXTOID:        return text_type;
    case BYTEAOID:       return text_type;
    case INT4OID:        return numeric_type;
    case INT8OID:        return numeric_type;
    case TIMESTAMPTZOID: return timestamptz_type;
    case TIMESTAMPOID:   return timestamptz_type;  // Hmm, should distinguish it is local time
    case FLOAT4OID:      return float_type;
    case FLOAT8OID:      return double_type;
    default:             throw StrException("type error, unrecognised oid "+boost::lexical_cast<string>(oid));
  }
}


static Oid typecode_to_oid(typecode_t typecode)
{
  switch(typecode) {
    case null_type:        return 0;
    case text_type:        return TEXTOID;
    case numeric_type:     return INT4OID;
    case timestamptz_type: return TIMESTAMPTZOID;
    case bytea_type:       return BYTEAOID;
    case float_type:       return FLOAT4OID;
    case double_type:      return FLOAT8OID;
    default:               throw "type error, unrecognised typecode";
  }
}


class DatabaseConnectionFailed: public DatabaseException {
public:
  DatabaseConnectionFailed(PGconn* pgconn):
    DatabaseException(pgconn,"Connecting to database") {}
};


Database::Database(string conninfo):
  pgconn(PQconnectdb(conninfo.c_str())),
  conn_fd(PQsocket(pgconn),false),
  transaction_in_progress(false)
{
  if (PQstatus(pgconn)!=CONNECTION_OK) {
    throw DatabaseConnectionFailed(pgconn);
  }
}


Database::~Database()
{
  PQfinish(pgconn);
}


const FileDescriptor& Database::get_fd(void) const
{
  return conn_fd;
}


string Database::get_any_notification(void)
{
  int rc = PQconsumeInput(pgconn);
  if (rc==0) {
    throw QueryFailed(pgconn,"checking for notifications");
  }
  boost::shared_ptr<PGnotify> p(PQnotifies(pgconn), PQfreemem);
  if (!p) {
    return "";
  }
  return p.get()->relname;
}


void Database::exec_sql(string cmd)
{
  boost::shared_ptr<PGresult> res(PQexec(pgconn, cmd.c_str()), PQclear);
  if (!res || PQresultStatus(res.get()) !=PGRES_COMMAND_OK) {
    throw QueryFailed(pgconn, cmd.c_str());
  }
}


void DatabaseException::report(ostream& s) const
{
  s << "Database exception: " << postgres_error;
  if (doing_what!="") {
    s << " while " << doing_what;
  }
  s << "\n";
}


Transaction::Transaction(Database& database_):
  database(database_),
  committed(false)
{
  if (database.transaction_in_progress) {
    nested=true;
  } else {
    nested=false;
    database.transaction_in_progress=true;
    database.exec_sql("begin");
  }
}


Transaction::~Transaction()
{
  if (!nested) {
    if (!committed) {
      database.transaction_in_progress=false;
      try {
        database.exec_sql("rollback;");
      }
      catch(...) {
        // Mustn't throw an exception from inside a destructor, in case it is being 
        // invoked during exception processing.
        // (TODO is there a better fix for this?)
      }
    }
  }
}


void Transaction::commit(void)
{
  if (!nested) {
    database.transaction_in_progress=false;
    database.exec_sql("commit");
    committed=true;
  }
}


Result::Result(boost::shared_ptr<PGresult> res_):
  rows(PQntuples(res_.get())),
  cols(PQnfields(res_.get())),
  res(res_)
{}


int Result::get_rows_changed(void) const
{
  return boost::lexical_cast<int>(PQcmdTuples(res.get()));
}


class ColumnNotFound: public StrException {
public:
  ColumnNotFound(string colname):
    StrException("Table has no column named " + colname)
  {}
};


int Result::column(std::string name) const
{
  int n = PQfnumber(res.get(),name.c_str());
  if (n==-1) {
    throw ColumnNotFound(name);
  }
  return n;
}


std::string Result::column_name(int col) const
{
  return PQfname(res.get(),col);
}

char* Result::rawget(int row, int col) const
{
  return PQgetvalue(res.get(),row,col);
}

int Result::getlength(int row, int col) const
{
  return PQgetlength(res.get(),row,col);
}


bool Result::is_null(int row, int col) const
{
  return PQgetisnull(res.get(),row,col);
}


typecode_t Result::column_typecode(int col) const
{
  Oid oid = PQftype(res.get(),col);
  return oid_to_typecode(oid);
}


int statement_name_t::counter = 0;


static bool can_use_pqexecparams(string querystr)
{
  boost::algorithm::trim_left_if(querystr,boost::algorithm::is_any_of(" ("));
  return boost::algorithm::istarts_with(querystr,"select")
      || boost::algorithm::istarts_with(querystr,"update")
      || boost::algorithm::istarts_with(querystr,"insert")
      || boost::algorithm::istarts_with(querystr,"delete");
}


QueryCore::QueryCore(Database& database_, std::string querystr_, int nparams_,
                     typecode_t* argtypecodes, int* lengths, int* formats):
  database(database_),
  querystr(querystr_),
  params_ok(can_use_pqexecparams(querystr_)),
  nparams(nparams_),
  param_lengths(lengths),
  param_formats(formats),
  prepared(false)
{
  while (nparams>0 && argtypecodes[nparams-1]==null_type) {
    nparams--;
  }
  argoids = new Oid[nparams];  // hmm, use something smart
  for (int i=0; i<nparams; ++i) {
    argoids[i] = typecode_to_oid(argtypecodes[i]);
  }
}


QueryCore::~QueryCore()
{
  if (prepared) {
    try {
      database.exec_sql("deallocate "+statement_name);
    }
    catch(...) {
      // Mustn't throw an exception from inside a destructor, in case it is being 
      // invoked during exception processing.
      // (TODO is there a better fix for this?)
    }
  }
  delete[] argoids;
}


Result QueryCore::operator()(const char* enc_args[])
{
  if (!params_ok) {
    return runonce(enc_args);
  }

  if (!prepared) {
    prepare();
  }
  boost::shared_ptr<PGresult>
  result(PQexecPrepared(database.pgconn, statement_name.c_str(), nparams,
                        enc_args, param_lengths, param_formats, 1),
         PQclear);
  if (result) {
    ExecStatusType status = PQresultStatus(result.get());
    if (status==PGRES_TUPLES_OK || status==PGRES_COMMAND_OK) {
      return Result(result);
    }
  }
  throw QueryFailed(database.pgconn, querystr);
}


static PGresult* wrap_PQexecParams(PGconn* conn, string command, int nparams,
                                   const Oid* paramTypes, const char* const * paramValues,
                                   const int* paramLengths, const int* paramFormats)
{
  string new_command;
  string::size_type p=0;
  while (p<command.length()) {
    const string::size_type q = command.find('$',p);
    if (q==string::npos) {
      new_command += command.substr(p);
      break;
    }
    new_command += command.substr(p,(q-p));
    string::size_type r = command.find_first_not_of("0123456789",q+1);
    if (r==string::npos) {
      r = command.length();
    }
    int n = boost::lexical_cast<int>(command.substr(q+1,(r-q-1)));
    if (n==0) {
      throw "$0 not allowed";
    }
    if (n>nparams) {
      throw "Not enough parameters";
    }
    --n;
    Oid o = paramTypes[n];
    switch (o) {
      case TEXTOID: {      boost::scoped_array<char> buf(new char[paramLengths[n]*2+1]);
                           PQescapeStringConn(conn,buf.get(),paramValues[n],
                                              paramLengths[n],NULL);
                           new_command += string("\'") + buf.get() + "\'";
                           break; }
      case BYTEAOID: {     boost::shared_ptr<unsigned char> buf (
                             PQescapeByteaConn(conn,
                                               reinterpret_cast<const unsigned char*>(paramValues[n]),
                                               paramLengths[n],NULL),
                             PQfreemem);
                           new_command += string("\'")
                                       + reinterpret_cast<const char*>(buf.get()) + "\'";
                           break; }
      case INT4OID: {      int32_t i = ntohl(*reinterpret_cast<const int32_t*>(paramValues[n]));
                           new_command += boost::lexical_cast<string>(i);
                           break; }
      case INT8OID: {      int64_t i = ntoh64(*reinterpret_cast<const int64_t*>(paramValues[n]));
                           new_command += boost::lexical_cast<string>(i);
                           break; }
      case TIMESTAMPTZOID: throw "timestamptz not implemented";
                           break;
      default:             throw "unrecognised oid";
    }
    p = r;
  }
  //cout << "converted '" << command << "' to '" << new_command << "'\n";
  return PQexec(conn, new_command.c_str());
}


Result QueryCore::runonce(const char* enc_args[])
{
  if (params_ok) {
    boost::shared_ptr<PGresult>
    result(PQexecParams(database.pgconn, querystr.c_str(), nparams,
                        argoids, enc_args, param_lengths, param_formats, 1),
           PQclear);
    if (result) {
      ExecStatusType status = PQresultStatus(result.get());
      if (status==PGRES_TUPLES_OK || status==PGRES_COMMAND_OK) {
        return Result(result);
      }
    }
  } else {
    boost::shared_ptr<PGresult>
    result(wrap_PQexecParams(database.pgconn, querystr, nparams,
                             argoids, enc_args, param_lengths, param_formats),
           PQclear);
    if (result) {
      ExecStatusType status = PQresultStatus(result.get());
      if (status==PGRES_TUPLES_OK) {
        throw StrException("Not expecting tuples in result from "
                           "non-pqexecparams query '"+querystr+"'");
      }
      if (status==PGRES_COMMAND_OK) {
        return Result(result);
      }
    }
  }
  throw QueryFailed(database.pgconn, querystr);
}


void QueryCore::prepare(void)
{
//cout << "Preparing query with nparams=" << nparams << "\n";
  boost::shared_ptr<PGresult>
  result(PQprepare(database.pgconn, statement_name.c_str(),
                   querystr.c_str(), nparams, argoids),
         PQclear);
  if (result) {
    ExecStatusType status = PQresultStatus(result.get());
    if (status==PGRES_COMMAND_OK) {
      prepared=true;
      return;
    }
  }
  throw QueryFailed(database.pgconn, querystr);
}



};

