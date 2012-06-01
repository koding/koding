// src/Database.hh
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

#ifndef libpbe_Database_hh
#define libpbe_Database_hh

#include "Exception.hh"
#include "FileDescriptor.hh"
#include "endian.hh"

#include <string>

#include <libpq-fe.h>

#include <boost/lexical_cast.hpp>
#include <boost/type_traits.hpp>
#include <boost/noncopyable.hpp>
#include <boost/static_assert.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/preprocessor/repetition/enum.hpp>
#include <boost/iterator/iterator_facade.hpp>


namespace pbe {

// The maximum number of query parameters is set by this macro, which user code can 
// define before #including this file.
#ifndef PBE_DB_MAX_QUERY_PARAMS
#define PBE_DB_MAX_QUERY_PARAMS 7
#endif

// Making it too large has the disadvantage that error messages become even more 
// incomprehensible, and may also increase compile times.


// private:

// We support queries with variable numbers of parameters by means of 
// sentinel default paramter values.  The sentinel is of a special empty type 
// null_t.
// ? Could we just use void for this ?

struct null_t {};
static const null_t nullval = null_t();


// We need to map between C++ types and PostgreSQL types in query parameters.
// This enum lists all of the PostgreSQL types that we map to, plus two 
// sentinels: unknown_type indicates that no PostgreSQL type corresponds to the 
// supplied C++ type, and should result in a compile-time error; null_type is used 
// in unused arguments slots in the varargs-like query syntax.

enum typecode_t { /*unknown_type=0,*/ null_type,
                  text_type, numeric_type, timestamptz_type, bytea_type,
                  float_type, double_type,
                  typecode_t_max };

// Now we use template specialisation to get the typecode_t corresponding to a C++ 
// type at compile time.  get_typecode<T>() is the typecode_t for type T.

// The generic template is not implemented anywhere, so it will fail at link 
// time for these unsupported types.
template <typename T> inline typecode_t get_typecode(void);

template <> inline typecode_t get_typecode<null_t>(void)      { return null_type; }
template <> inline typecode_t get_typecode<std::string>(void) { return text_type; }
template <> inline typecode_t get_typecode<int>(void)         { return numeric_type; }
template <> inline typecode_t get_typecode<time_t>(void)      { return timestamptz_type; }
template <> inline typecode_t get_typecode<float>(void)       { return float_type; }
template <> inline typecode_t get_typecode<double>(void)      { return double_type; }

// public:

// class Database represents a connection to the database server.
// It's marked non-copyable because it's not clear what should be done with 
// the underlying libpq connection object in that case.
class Database: public boost::noncopyable {
public:

  // Connect to the database server using the supplied connection info.
  Database(std::string conninfo);

  // Disconnect on destruction.
  ~Database();

  // Get the file descriptor for the connction to the server.
  // This is useful if you want to use select() to wait for asynchronous 
  // notifications from the server.  You obviously mustn't read or write to 
  // it.
  const pbe::FileDescriptor& get_fd(void) const;

  // Return any asynchronous notifications received from the server.
  std::string get_any_notification(void);

private:
  // libpq data structure representing the connection.
  PGconn* pgconn;

  // Connection file descriptor.
  pbe::FileDescriptor conn_fd;

  // This is needed so that we can support nested transactions.
  // (PostgreSQL now has built-in support for this, so it should be reviewed.)
  bool transaction_in_progress;

  // Run arbitary queries
  void exec_sql(std::string cmd);

  friend class QueryCore;
  friend class Transaction;
};


// Exceptions thrown by the Database functions:

class DatabaseException: public Exception {
public:
  DatabaseException(PGconn* pgconn, std::string doing_what_):
    postgres_error(PQerrorMessage(pgconn)),
    doing_what(doing_what_) {}
  void report(std::ostream& s) const;
private:
  std::string postgres_error;
  std::string doing_what;
};

class QueryFailed: public DatabaseException {
public:
  QueryFailed(PGconn* pgconn, std::string query):
    DatabaseException(pgconn,"Executing query " + query) {}
};

class TypeError: public DatabaseException {
public:
  TypeError(PGconn* pgconn):
    DatabaseException(pgconn,"Type error") {}
};


// Transactions.  Typical usage:
// {
//   Transaction t(db);
//   ... run queries ...
//   t.commit();
// }
// If the transaction goes out of scope without commit() having been called, e.g. 
// because an exception was thrown and not caught, the transaction will be rolled 
// back.
// TODO: PostgreSQL now has some sort of built-in support for nested 
// transactions.
class Transaction: public boost::noncopyable {
public:
  Transaction(Database& database_);
  ~Transaction();
  void commit(void);
private:
  Database& database;
  bool nested;
  bool committed;
};
    

// Convert from the representation returned by libpq to a normal C++ type.

template <typename T>
T decode_pq_res(const char* data, int length __attribute__((unused)));

template <>
inline int decode_pq_res<int>(const char* data, int length __attribute__((unused))) {
  const int* valp = reinterpret_cast<const int*>(data);
  return ntohl(*valp);
}

template <>
inline uint64_t decode_pq_res<uint64_t>(const char* data, int length __attribute__((unused))) {
  const uint64_t* valp = reinterpret_cast<const uint64_t*>(data);
  return ntoh64(*valp);
}

template <>
inline int64_t decode_pq_res<int64_t>(const char* data, int length __attribute__((unused))) {
  const int64_t* valp = reinterpret_cast<const int64_t*>(data);
  return ntoh64(*valp);
}

template <>
inline time_t decode_pq_res<time_t>(const char* data, int length __attribute__((unused))) {
  // Timestamp values are returned by PostgreSQL as 64-bit microsecond
  // values.  946684800000000 is a magic number to convert to the Unix
  // 1970 epoch.
  int64_t t = decode_pq_res<int64_t>(data, length);
  return t/1000000 + 946684800;
}

template <>
inline std::string decode_pq_res<std::string>(const char* data, int length __attribute__((unused))) {
  return std::string(data,length);
}

union float_or_int {
  float f;
  int i;
};

template <>
inline float decode_pq_res<float>(const char* data, int length __attribute__((unused))) {
  const float_or_int* uptr = reinterpret_cast<const float_or_int*>(data);
  float_or_int ucopy;
  ucopy.i = ntohl(uptr->i);
  return ucopy.f;
}

union double_or_two_ints {
  double d;
  int i[2];
};

template <>
inline double decode_pq_res<double>(const char* data, int length __attribute__((unused))) {
  const double_or_two_ints* uptr = reinterpret_cast<const double_or_two_ints*>(data);
  double_or_two_ints ucopy;
  ucopy.i[0] = ntohl(uptr->i[0]);
  ucopy.i[1] = ntohl(uptr->i[1]);
  return ucopy.d;
}


// Result of a SELECT query:
class Result {
public:
  // Construct from the result object from libpq
  Result(boost::shared_ptr<PGresult>);

  // For insert, update and delete statements the result tells us how many 
  // rows were inserted, updated or deleted, using the following:
  int get_rows_changed(void) const;

  // Everything below here is for getting at the table returned for a select 
  // statement:

  // The size of the table
  const int rows;
  const int cols;

  // Map between column names and numbers
  int column(std::string name) const ;
  std::string column_name(int pos) const;

  // Get data
  // The pointer returned by rawget is valid for as long as the Result object exists.
  char* rawget(int row, int col) const;

  int getlength(int row, int col) const;

  template <typename T>
  T get_nocheck(int row, int col) const {
    return decode_pq_res<T>(rawget(row,col),getlength(row,col));
  }

  template <typename T>
  T get(int row, int col) const {
    check_column_type<T>(col);
    return get_nocheck<T>(row,col);
  }

  template <typename T>
  T get(int row, std::string colname) const {
    return get<T>(row, column(colname));
  }

#if 0
  // ... does this work?
  template <typename T>
  T operator()(int row, int col) const {
  }

  template <typename T>
  T operator()(int row, std::string colname) const {
    return operator()<T>(row, column(colname));
  }
#endif

  bool is_null(int row, int col) const;

  bool is_null(int row, std::string colname) const {
    return is_null(row, column(colname));
  }

  // Column types
  typecode_t column_typecode(int col) const;

  template <typename T>
  void check_column_type(int col) const {
    if (column_typecode(col)!=get_typecode<T>()) {
      throw StrException("type error for column "
+boost::lexical_cast<std::string>(col)+", expecting typecode "
+boost::lexical_cast<std::string>(get_typecode<T>())+" but got typecode "
+boost::lexical_cast<std::string>(column_typecode(col)));
    }
  }

private:
  boost::shared_ptr<PGresult> res;
};


// Alternative result for a query that generates a single column.
// Values can be accessed using (), e.g. r(i).
template <typename T>
class ColumnResult: public Result {
public:
  ColumnResult(Result r): Result(r) {
    if (cols!=1) {
      throw "Single column expected";
    }
    if (rows>0) {
      check_column_type<T>(0);
    }
  }
  T operator ()(int row) const { return get<T>(row,0); }
  bool is_null (int row) const { return Result::is_null(row,0); }
  class const_iterator:
    public boost::iterator_facade<const_iterator,const T,boost::bidirectional_traversal_tag,T> {
  public:
    const_iterator():
      res(NULL), row(0) {}
    const_iterator(const const_iterator& other):
      res(other.res), row(other.row) {}
  private:
    const ColumnResult& res;
    int row;
    friend class ColumnResult;
    const_iterator(const ColumnResult& res_, int row_):
      res(res_), row(row_) {}
    friend class boost::iterator_core_access;
    void increment() { ++row; }
    void decrement() { --row; }
    void advance(int n) { row+=n; }
    int distance_to(const_iterator other) { return other.row-row; }
    bool equal(const const_iterator& other) const {
      return row==other.row && &res==&(other.res);
    }
    const T dereference() const {
      return res(row);
    }
  };
  const_iterator begin() const {
    return const_iterator(*this,0);
  }
  const_iterator end() const {
    return const_iterator(*this,rows);
  }
};


// Alternative result for a query that generates a single value
// (e.g. a "count(*)" query).
// This is convertable to the type of that value.
template <typename T>
class SingletonResult: public Result {
public:
  SingletonResult(Result r): Result(r) {
    if (rows!=1 || cols!=1) {
      throw "Singleton expected";
    }
    check_column_type<T>(0);
  }
  operator T () const { return get<T>(0,0); }
  bool is_null () const { return Result::is_null(0,0); }
};


// Alternative result for a query that generates a zero or one values.
// This is convertable to the type of that value.
template <typename T>
class OptResult: public Result {
public:
  OptResult(Result r): Result(r) {
    if (rows>1 || cols!=1) {
      throw "Zero or one values expected";
    }
    if (rows==1) {
      check_column_type<T>(0);
    }
  }
  operator T () { return get<T>(0,0); }
  bool is_null () { return Result::is_null(0,0); }
  bool empty() { return rows==0; }
};


// private:

// Generate names for prepared statements
class statement_name_t: public std::string {
public:
  statement_name_t(void):
    std::string("stmt_"+boost::lexical_cast<std::string>(counter++))
  {}
private:
  static int counter;
};


// Most of the work of Query is delagated to QueryCore which is not a template 
// class and so need not be coded inline.
// This is "semi-private": code can use it if it needs to pass more than 
// PBE_DB_MAX_QUERY_PARAMS paramters to a query, but if that's not necessary then it 
// should not be used.

class QueryCore {
public:
  QueryCore(Database& database_, std::string querystr_, int nparams,
            typecode_t* argtypecodes, int* lengths, int* formats);
  ~QueryCore();
  Result operator()(const char* enc_args[]);
  Result runonce(const char* enc_args[]);
private:
  Database& database;
  const std::string querystr;
  const bool params_ok;
  const statement_name_t statement_name;
  int nparams;
  int* param_lengths;
  int* param_formats;
  Oid* argoids;
  bool prepared;
  void prepare(void);
};


// Convert from C++ types to the representation passed to libpq.
// Types are either binary or character.  Binary is used for numeric types and 
// character is used for text types.  Binary types must be in network byte 
// order.
// This uses template specialisation.
// It's OK for these function to modify their paramters in place.

template <typename T>
inline const char* encode_pq_arg(T& t);

template <>
inline const char* encode_pq_arg<null_t>(null_t& i __attribute__((unused)) ) {
  return NULL;
}

template <>
inline const char* encode_pq_arg<int>(int& i) {
  i = htonl(i);
  return reinterpret_cast<const char*>(&i);
}

template <>
inline const char* encode_pq_arg<uint64_t>(uint64_t& i) {
  i = hton64(i);
  return reinterpret_cast<const char*>(&i);
}

template <>
inline const char* encode_pq_arg<int64_t>(int64_t& i) {
  i = hton64(i);
  return reinterpret_cast<const char*>(&i);
}

template <>
inline const char* encode_pq_arg<time_t>(time_t& t) {
// No! This leaks!
  int64_t* iptr = new int64_t;
  *iptr = static_cast<int64_t>(t-946684800)*1000000;
  return encode_pq_arg<int64_t>(*iptr);
}

template <>
inline const char* encode_pq_arg<std::string>(std::string& s) {
  return s.c_str();
}

static inline float htonfloat(float f) {
  uint32_t i;
  memcpy(&i,&f,4);
  i = htonl(i);
  float r;
  memcpy(&r,&i,4);
  return r;
}

template <>
inline const char* encode_pq_arg<float>(float& f) {
  f = htonfloat(f);
  return reinterpret_cast<const char*>(&f);
}

template <>
inline const char* encode_pq_arg<double>(double& d) {
  uint32_t* ptr = reinterpret_cast<uint32_t*>(&d);
  ptr[0] = htonl(ptr[0]);
  ptr[1] = htonl(ptr[1]);
  return reinterpret_cast<const char*>(&d);
}


// We need to know the size of the encoded data.
// In most cases this is sizeof(T), but there are exceptions when the 
// encoding process changes the size.

template <typename T>
inline size_t get_enc_type_size(void) { return sizeof(T); }

template <>
inline size_t get_enc_type_size<time_t>(void) { return 8; }



// The Boost preprocessor library is used to build query parameter lists (etc.) with 
// multiple argumnets.

#define PBE_DB_Q_TEMPLATE_PARAM(z,n,data) typename T##n=null_t
#define PBE_DB_Q_TEMPLATE_PARAMS BOOST_PP_ENUM(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_Q_TEMPLATE_PARAM,)
// Expands to e.g. typename T0=null_t,typename T1=null_t

#define PBE_DB_Q_OP_APPLY_PARAM(z,n,data) T##n arg##n=nullval
#define PBE_DB_Q_OP_APPLY_PARAMS BOOST_PP_ENUM(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_Q_OP_APPLY_PARAM,)
// Expands to e.g. T0 arg0=nullval,T1 arg1=nullval

#define PBE_DB_Q_BASE_TEMPL_PARAM(z,n,data) T##n
#define PBE_DB_Q_BASE_TEMPL_PARAMS BOOST_PP_ENUM(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_Q_BASE_TEMPL_PARAM,)
// Expands to e.g. T0,T1

#define PBE_DB_Q_BASE_OP_APPLY_PARAM(z,n,data) arg##n
#define PBE_DB_Q_BASE_OP_APPLY_PARAMS BOOST_PP_ENUM(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_Q_BASE_OP_APPLY_PARAM,)
// Expands to e.g. arg0,arg1


// This base class is used to form the parameters passed to Query, below, into arrays 
// that can be passed to QueryCore.

template <PBE_DB_Q_TEMPLATE_PARAMS> struct QueryBase {
  typecode_t typecodes[PBE_DB_MAX_QUERY_PARAMS];
  int lengths[PBE_DB_MAX_QUERY_PARAMS];
  int formats[PBE_DB_MAX_QUERY_PARAMS];

  QueryBase() {
#define PBE_DB_QB_INIT_ONE(z,n,data)    \
    typecodes[n]=get_typecode<T##n>();  \
    lengths[n]=get_enc_type_size<T##n>();\
    formats[n]=!boost::is_same<T##n,std::string>::value;
BOOST_PP_REPEAT(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_QB_INIT_ONE,)
  }
};


// Prepare and run a query.  Typical usage:
// Query<std::string,int> insert_item(db,"insert into items(name,qty) values ($1,$2)");
// insert_item("nut",100);
// insert_item("bolt",102);
// The query can have up to PBE_DB_MAX_QUERY_PARAMS parameters.  This limit can be 
// increased at the top of this file.

template <PBE_DB_Q_TEMPLATE_PARAMS> class Query:
  private QueryBase<PBE_DB_Q_BASE_TEMPL_PARAMS> {
public:

  // Create a query.  SQL is supplied in querystr with parameters indicated by 
  // $1, $2 etc.  C++ types of these parameters are the template paramters.
  Query(Database& database, std::string querystr):
    core(database, querystr, PBE_DB_MAX_QUERY_PARAMS,
         QueryBase<PBE_DB_Q_BASE_TEMPL_PARAMS>::typecodes,
         QueryBase<PBE_DB_Q_BASE_TEMPL_PARAMS>::lengths,
         QueryBase<PBE_DB_Q_BASE_TEMPL_PARAMS>::formats)
  {}

  // Run a query.  It is prepared the first time that it is run.
  Result operator()(PBE_DB_Q_OP_APPLY_PARAMS) {
    const char* arg_cs[PBE_DB_MAX_QUERY_PARAMS];
#define PBE_DB_Q_OP_APPLY_ONE(z,n,data) \
    T##n arg##n##_c = arg##n;           \
    arg_cs[n] = encode_pq_arg(arg##n##_c);
BOOST_PP_REPEAT(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_Q_OP_APPLY_ONE,)
    return core(arg_cs);
  }

  // Run a query immediately, without preparation.  Use this for queries that will only be 
  // run once.
  Result runonce(PBE_DB_Q_OP_APPLY_PARAMS) {
    const char* arg_cs[PBE_DB_MAX_QUERY_PARAMS];
#define PBE_DB_Q_RUNONCE_ONE(z,n,data) \
    T##n arg##n##_c = arg##n;          \
    arg_cs[n] = encode_pq_arg(arg##n##_c);
BOOST_PP_REPEAT(PBE_DB_MAX_QUERY_PARAMS,PBE_DB_Q_RUNONCE_ONE,)
    return core.runonce(arg_cs);
  }


private:
  QueryCore core;
};


// A query that returns a ColumnResult.
template <typename RT, PBE_DB_Q_TEMPLATE_PARAMS>
class ColumnQuery: public Query< PBE_DB_Q_BASE_TEMPL_PARAMS> {
public:
  typedef ColumnResult<RT> result_t;

  ColumnQuery(Database& database, std::string querystr):
    Query<PBE_DB_Q_BASE_TEMPL_PARAMS>(database,querystr)
  {}

  result_t operator()(PBE_DB_Q_OP_APPLY_PARAMS) {
    return Query<PBE_DB_Q_BASE_TEMPL_PARAMS>::operator()(PBE_DB_Q_BASE_OP_APPLY_PARAMS);
  }

  result_t runonce(PBE_DB_Q_OP_APPLY_PARAMS) {
    return Query<PBE_DB_Q_BASE_TEMPL_PARAMS>::runonce(PBE_DB_Q_BASE_OP_APPLY_PARAMS);
  }
};


// A query that returns a SingeltonResult.  In this case there's no need to 
// delcare the result object, thanks to implicit type conversion.  For 
// example:  int a = query(param);
template <typename RT, PBE_DB_Q_TEMPLATE_PARAMS>
class SingletonQuery: public Query< PBE_DB_Q_BASE_TEMPL_PARAMS> {
public:
  typedef SingletonResult<RT> result_t;

  SingletonQuery(Database& database, std::string querystr):
    Query<PBE_DB_Q_BASE_TEMPL_PARAMS>(database,querystr)
  {}

  result_t operator()(PBE_DB_Q_OP_APPLY_PARAMS) {
    return Query<PBE_DB_Q_BASE_TEMPL_PARAMS>::operator()(PBE_DB_Q_BASE_OP_APPLY_PARAMS);
  }

  result_t runonce(PBE_DB_Q_OP_APPLY_PARAMS) {
    return Query<PBE_DB_Q_BASE_TEMPL_PARAMS>::runonce(PBE_DB_Q_BASE_OP_APPLY_PARAMS);
  }
};


// A query that returns a OptResult.
template <typename RT, PBE_DB_Q_TEMPLATE_PARAMS>
class OptQuery: public Query< PBE_DB_Q_BASE_TEMPL_PARAMS> {
public:
  typedef OptResult<RT> result_t;

  OptQuery(Database& database, std::string querystr):
    Query<PBE_DB_Q_BASE_TEMPL_PARAMS>(database,querystr)
  {}

  result_t operator()(PBE_DB_Q_OP_APPLY_PARAMS) {
    return Query<PBE_DB_Q_BASE_TEMPL_PARAMS>::operator()(PBE_DB_Q_BASE_OP_APPLY_PARAMS);
  }

  result_t runonce(PBE_DB_Q_OP_APPLY_PARAMS) {
    return Query<PBE_DB_Q_BASE_TEMPL_PARAMS>::runonce(PBE_DB_Q_BASE_OP_APPLY_PARAMS);
  }
};


};

#endif
