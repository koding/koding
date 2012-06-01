// common/html.cc
// This file is part of Anyterm; see http://anyterm.org/
// (C) 2005 Philip Endecott

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


#include "html.hh"

#include <string>

using namespace std;

namespace KFM{namespace Terminal{

    // Screen to HTML conversion:

    static bool gen_style(ucs4_string& h, Attributes attrs)
    {
      if (attrs!=Attributes()) {
        unsigned int fg = attrs.fg;
        unsigned int bg = attrs.bg;
        if (attrs.inverse) {
          swap(fg,bg);
        }
        ucs4_string classes;
        if (attrs.bold) {
          classes += L'z';
        }
        if (bg!=Attributes().bg) {
          if (!classes.empty()) {
            classes += L' ';
          }
          classes += L'a'+bg;
        }
        if (fg!=Attributes().fg) {
          if (!classes.empty()) {
            classes += L' ';
          }
          classes += L'i'+fg;
        }
        h += L"<span class=\"" + classes + L"\">";
        return true;
      }
      return false;
    }

    static const ucs4_char* attr_end    = L"</span>";

    static const ucs4_char* cursor_start = L"<span class=\"cursor\">";
    static const ucs4_char* cursor_end   = L"</span>";


    ucs4_string htmlify_screen( CScreen& screen)
    {
      // Convert screen into HTML.
      // Slightly optimised to reduce spaces at right end of lines.

      ucs4_string h;

      for (int r=0; r<screen.numRows(); r++) {
        int sp=0;
        bool styled=false;
        Attributes prev_attrs;
        for (int c=0; c<screen.numCols(); c++) {
          bool cursor = (r==screen.getCursorRow() && c==screen.getCursorCol()) && screen.isCursorVisible();
          Cell & cell = screen.getCell(r,c);
          ucs4_char ch = cell.c;
          Attributes attrs = cell.attrs;

          if (ch==' ' && attrs==Attributes() && !styled && c>0 && r>0 && !cursor) {
            sp++;
          } else {
            while (sp>0) {
              h+=L'\u00A0';
              sp--;
            }
            if (styled && attrs!=prev_attrs) {
              h+=attr_end;
            }
            if (c==0 || attrs!=prev_attrs) {
              styled = gen_style(h,attrs);
              prev_attrs=attrs;
            }
            if (cursor) {
              h+=cursor_start;
            }
            switch (ch) {
              case '<':  h+=L"&lt;"; break;
              case '>':  h+=L"&gt;"; break;
              case '&':  h+=L"&amp;"; break;
              case ' ':  h+=L'\u00A0'; break;
              default:   h+=ch; break;
            }
            if (cursor) {
              h+=cursor_end;
            }
          }
        }
        if (styled) {
          h+=attr_end;
        }
        h+=L"<br>";
      }

      return h;
    }


}}//end of namespace KFM::Terminal