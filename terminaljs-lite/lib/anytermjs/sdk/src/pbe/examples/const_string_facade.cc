// This is an example of the const_string_facade class.
//
// We have a file containing names of countries and their capital cities:
//
// England,London
// Scotland,Edinburgh
// Wales,Cardiff
// etc. etc.
// 
// We want to read this in and to store it in a std::map from country name to
// capital city name.  This is simple enough to do, but the normal approach has
// the disadvantage that the data is copied out of the buffer into strings
// which are stored in the map.  Avoiding this extra copy could be a useful
// thing to do.  So instead of using std::strings we'll invent a new class,
// stringref, which just contains a pair of pointers; these point into the
// buffer containing the raw data which is never copied.
//
// const_string_facade is used to make the pair-of-pointers class behave like
// a const std::string: it provides implementations of all the normal member
// and free functions.  So we can store them in a map output them and so on.


#include "const_string_facade.hh"

#include <iostream>
#include <string>
#include <map>
#include <algorithm>

#include "FileDescriptor.hh"

using namespace std;
using namespace pbe;


class stringref: public const_string_facade<stringref,char,false> {
// The template parameters are:
//   - The derived class (this the the "CRTP").
//   - The character type.
//   - A bool indicating that the strings are not null-terminated.

public:
  stringref(): begin_ptr(NULL), end_ptr(NULL) {}
  stringref(const char* b, const char* e): begin_ptr(b), end_ptr(e) {}

private:
  const char* begin_ptr;
  const char* end_ptr;

  // Here are the accessors that const_string_facade needs.  Since these
  // are private we need to make it a friend.
  friend class const_string_facade<stringref,char,false>;
  const char* get_begin() const { return begin_ptr; }
  const char* get_end()   const { return end_ptr; }
};



int main(int argc, char* argv[])
{
  if (argc!=3) {
    cerr << "Usage: " << argv[0] << " csv-file some-string\n";
    exit(1);
  }
  string fn = argv[1];
  string some_string = argv[2];

  FileDescriptor f(fn, FileDescriptor::read_only);

  char buf[4096];
  char* buf_end = buf + f.readmax(buf,sizeof(buf));

  typedef map<stringref,stringref> capitals_t;
  capitals_t capitals;

  char* ptr = buf;
  while (ptr<buf_end) {

    char* comma_pos = find(ptr,buf_end,',');
    char* newline_pos = find(comma_pos,buf_end,'\n');

    stringref country(ptr,comma_pos);
    stringref city(comma_pos+1,newline_pos);
    capitals[country] = city;

    ptr = newline_pos+1;
  }

  for (capitals_t::const_iterator i = capitals.begin();
       i != capitals.end(); ++i) {
    cout << "The capital of " << i->first << " is " << i->second << "\n";
  }

  const char* vowels = "aeiouAEIOU";

  for (capitals_t::const_iterator i = capitals.begin();
       i != capitals.end(); ++i) {
    const stringref country = i->first;
    size_t first_vowel_pos = country.find_first_of(vowels);
    size_t last_consonant_pos = country.find_last_not_of(vowels);
    cout << "The first vowel in " << country << " is " << country[first_vowel_pos]
         << " and the last consonant is " << country[last_consonant_pos] << "\n";
    size_t ss_pos = country.find(some_string);
    if (ss_pos != stringref::npos) {
      cout << "   '" << country << "' contains '" << some_string << "' at position " << ss_pos << "\n";
    }
  }


  // Hopefully, a stringref has no overhead on top of the two pointers:
  cout << "sizeof(stringref) = " << sizeof(stringref) << "\n";

  return 0;
}

