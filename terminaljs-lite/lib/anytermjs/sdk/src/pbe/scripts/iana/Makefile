default_target: all

iana_character_sets:
	wget -O $@ http://www.iana.org/assignments/character-sets

charsets.dat: iana_character_sets mk_charsets_dat.awk
	awk -f mk_charsets_dat.awk iana_character_sets > charsets.dat

charset_t_enum_body.hh: charsets.dat mk_charset_t_enum_body.awk
	awk -f mk_charset_t_enum_body.awk charsets.dat > charset_t_enum_body.hh

charset_iana_names_body.cc: charsets.dat mk_charset_iana_names_body.awk
	awk -f mk_charset_iana_names_body.awk charsets.dat > charset_iana_names_body.cc

charset_mime_names_body.cc: charsets.dat mk_charset_mime_names_body.awk
	awk -f mk_charset_mime_names_body.awk charsets.dat > charset_mime_names_body.cc

charset_lookup_body.cc: charsets.dat mk_charset_lookup_body.sh
	./mk_charset_lookup_body.sh < charsets.dat > charset_lookup_body.cc

all: iana_character_sets charsets.dat charset_t_enum_body.hh \
     charset_iana_names_body.cc charset_mime_names_body.cc charset_lookup_body.cc

FORCE:

.PHONY: FORCE default_target all

