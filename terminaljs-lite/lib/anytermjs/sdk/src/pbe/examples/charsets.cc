// Example use of charset.hh in ../include/charset.hh.
//
// To compile, you need to make charset.hh accessible on the include path.
// Also, charset.hh includes my iconv wrapper, which is in ../include/Incover.hh,
// and depends on other things in that directory; those dependencies could be
// made to go away.


// This source file should be viewed using a UTF8 editor, and its output when run should be 
// viewed on a UTF8 terminal.


#include "charset.hh"

#include <iostream>
#include <algorithm>
#include <list>

using namespace pbe;
using namespace std;


void compile_time_tagged_strings_example()
{
  // This example declares strings with compile-time-fixed character sets, converts
  // them to other compile-time-fixed character sets, combines them, and checks for
  // consistency:

  cout << "\ncompile_time_tagged_strings_example:\n";

  utf8_string french = "Le traité simplifié prêt à être soumis "
                       "à l'approbation des gouvernements";
  latin1_string french_fixed = french.recode<latin1>();

  utf8_string icelandic = "Smjörið er brætt og hveitið smátt og smátt hrært út í það";
  latin1_string icelandic_fixed = icelandic.recode<latin1>();

  utf8_string all = french + icelandic;

  latin1_string all_fixed = french_fixed + icelandic_fixed;

  if ((all.recode<latin1>() == all_fixed)
      && (all == all_fixed.recode<utf8>())) {
    cout << "Pass, both strings are '" << all << "'\n";
  }
}


void utf8_const_iterator_example()
{
  // This example shows how a string with a variable-width
  // character set can be iterated over character-at-a-time
  // or "unit"-at-a-time.

  cout << "\nutf8_const_iterator_example:\n";

  utf8_string s = "Théâtre";  // My editor stores UTF8.

  // Iterate "unit" (byte) at a time:
  cout << "Here are the bytes of '" << s << "': " << hex;
  for (utf8_string::const_iterator i = s.begin();
       i != s.end(); ++i) {
    char8_t c = *i;
    cout << static_cast<unsigned int>(static_cast<uint8_t>(c)) << " ";
  }

  // Iterate character at a time:
  cout << "\nHere are the characters of '" << s << "': ";
  for (utf8_string::const_character_iterator i = s.begin();
       i != utf8_string::const_character_iterator( s.end() ); ++i) {
    utf8_char_t c = *i;  // A 32-bit decoded Unicode character
    cout << static_cast<unsigned int>(c) << " ";
  }
  cout << dec << "\n";
}


void utf8_output_iterator_example()
{
  // This example shows how a string with a variable-width
  // character set can be appended to using push_back and
  // an output iterator.

  cout << "\nutf8_output_iterator_example:\n";

  utf8_string s;

  for (utf8_char_t c=64; c<96; ++c) {
    s.push_back(c);
  }

  utf8_string::character_output_iterator i(s);

  for (utf8_char_t c=150; c<200; ++c) {
    *i++ = c;
//    s.push_back(c);
  }

  cout << "Unicode characters 64 to 95 and 150 to 199:\n"
       << s << "\n";
}


void utf8_word_split_example()
{
  // This example demonstrates a case where a "unit" rather than a character iterator for a 
  // UTF8 string is useful: because bytes < 128 can only ever represent single characters in 
  // UTF8, we can treat a UTF8 string as a sequence of bytes when spliting at spaces.

  cout << "\nutf8_word_split_example:\n";

  utf8_string s = "Yo también quemo la Corona española";
  utf8_string::const_iterator i = s.begin();
  utf8_string::const_iterator e = s.end();
  utf8_string::const_iterator j;
  do {
    j = find(i,e,' ');
    utf8_string word(i,j);
    cout << word << "\n";
    i = j+1;
  } while (j != e);
}


void ucs4_line_wrap_example()
{
  // Sometimes a random-access character iterator is needed, but an iso_8859 or similar byte 
  // character set can't be used because the characters in the content are not restricted.  
  // In this case, ucs4 is normally the best choice - though its requirement for 4 bytes per 
  // character may be considered a disadvantage in memory-limited applications.
  // This example uses random access to break a string into lines of <=40 characters each.

  cout << "\nucs4_line_wrap_example:\n";

  utf8_string text_var = "Партия Единая Россия отказалась от формирования первой "
                         "тройки федерального списка - его возглавил только президент "
                         "Владимир Путин.  Такое решение было принято на съезде Единой "
                         "России во вторник.  Накануне президент России дал согласие "
                         "возглавить список Единой России на выборах в Госдуму.";

  ucs4_string text_fixed = text_var.recode<ucs4>();

  for (unsigned int i=39; i<text_fixed.length(); i+=40) {
    while (text_fixed[i]!=' ') {
      --i;
    }
    text_fixed[i] = '\n';
  }

  cout << text_fixed.recode<utf8>() << "\n";
}


// This example shows how a library-user can make a new character set available.
// The example is the KOI8 character set, a fixed-width byte character set containing
// cyrillic and latin characters.

////// This section needs some attention from a preprocessor expert; I want to use
////// a counter of some sort to allocate new charset_t values with a macro:
////// PBE_DEFINE_CHARSET(koi8);
////// But I can't see a good way to do it.  For the time being, I'll choose a value
////// manually:
const charset_t koi8 = static_cast<charset_t>(25);

// Define charset_traits for KOI8:
namespace pbe {
  template <>
  struct charset_traits<koi8> {
    typedef char8_t unit_t;
    typedef char8_t char_t;
  };
};
typedef tagged_string<koi8> koi8_string;

void user_defined_charset_example()
{
  charset_names[koi8] = "koi8";

  cout << "\nuser_defined_charset_example:\n";

  // We'll convert a string back and forth between utf8 and koi8:
  utf8_string u = "Код Обмена Информацией, 8 бит";
  koi8_string k = u.recode<koi8>();
  utf8_string u2 = k.recode<utf8>();

  // KOI8 is a more compact encoiding than UTF8 for cyrillic:
  cout << "Length of UTF8 string = " << u2.length()
       << ", length of KOI8 string = " << k.length() << "\n";
}


void runtime_tagged_example()
{
  // This example shows how character sets known only at run-time can be used.
  // This is motivated by multipart MIME email, where each part can have a different
  // character set.  But since MIME is rather complex to parse, this example uses
  // the following simpler format: the input byte sequence consists of a character
  // set name (in ascii) followed by data using that character set enclosed in {},
  // followed by further content in another character set, and so on.
  // This example first creates such a message and then decomposes it.

  cout << "\nruntime_tagged_example:\n";

  // We'll store the hybrid message in a std::string.
  string message =
    string("utf8{")  + "El catalán, moneda lingüística" + "}"
         + "iso-8859-1{" + utf8_string("får årets Nobelpris i litteratur.").recode<latin1>() + "}";
//       + "ucs2{"   + utf8_string("Директором СВР назначен Михаил Фрадков").recode<ucs2>() + "}";

  // Now parse it into a list of run-time-tagged strings:
  typedef list<rt_tagged_string> strings_t;
  strings_t strings;
  string::const_iterator i = message.begin();
  string::const_iterator e = message.end();
  while (i != e) {
    string::const_iterator j = find(i,e,'{');
    string charset_name(i,j);
    string::const_iterator k = find(j,e,'}');
    string content(j+1,k);
    rt_tagged_string s(lookup_charset(charset_name),content);
    strings.push_back(s);
    i = k+1;
  }

  // Output the parsed strings, converting to UTF8 to do so:
  for (strings_t::const_iterator a = strings.begin();
       a != strings.end(); ++a) {
    utf8_string u = a->recode<utf8>();
    cout << u << "\n";
  }

}



// The following examples illustrate planned functionality that's not yet implemented:

#if 1

#endif



int main()
{
  // These examples work:
  compile_time_tagged_strings_example();
  utf8_const_iterator_example();
  utf8_output_iterator_example();
  utf8_word_split_example();
  ucs4_line_wrap_example();

  runtime_tagged_example();

  // These examples don't yet work:
#if 1
  user_defined_charset_example();
#endif

  return 0;
}

