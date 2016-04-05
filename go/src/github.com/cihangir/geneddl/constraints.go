package geneddl

import (
	"fmt"
	"strings"

	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

// DefineConstraints creates constraints definition for tables
func DefineConstraints(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	primaryKeyConstraint := ""
	primaryKey := settings.Get("primaryKey")
	if primaryKey != nil {
		pmi := primaryKey.([]interface{})
		if len(pmi) > 0 {
			sl := make([]string, len(pmi))
			for i, pm := range pmi {
				sl[i] = stringext.ToFieldName(pm.(string))
			}

			primaryKeyConstraint = fmt.Sprintf(
				"ALTER TABLE %q.%q ADD PRIMARY KEY (%q) NOT DEFERRABLE INITIALLY IMMEDIATE;\n",
				settings.Get("schemaName"),
				settings.Get("tableName"),
				strings.Join(sl, ", "),
			)
			primaryKeyConstraint = fmt.Sprintf("-------------------------------\n--  Primary key structure for table %s\n-- ----------------------------\n%s",
				settings.Get("tableName"),
				primaryKeyConstraint,
			)
		}
	}

	uniqueKeyConstraints := ""
	uniqueKeys := settings.Get("uniqueKeys")
	if uniqueKeys != nil {
		ukci := uniqueKeys.([]interface{})
		if len(ukci) > 0 {
			for _, ukc := range ukci {
				ukcs := ukc.([]interface{})
				ukcsps := make([]string, len(ukcs))
				for i, ukc := range ukcs {
					ukcsps[i] = stringext.ToFieldName(ukc.(string))
				}
				keyName := fmt.Sprintf(
					"%s_%s_%s",
					stringext.ToFieldName("key"),
					stringext.ToFieldName(settings.Get("tableName").(string)),
					strings.Join(ukcsps, "_"),
				)
				uniqueKeyConstraints += fmt.Sprintf(
					"ALTER TABLE %q.%q ADD CONSTRAINT %q UNIQUE (\"%s\") NOT DEFERRABLE INITIALLY IMMEDIATE;\n",
					settings.Get("schemaName"),
					settings.Get("tableName"),
					keyName,
					strings.Join(ukcsps, "\", \""),
				)

			}
			uniqueKeyConstraints = fmt.Sprintf("-------------------------------\n--  Unique key structure for table %s\n-- ----------------------------\n%s",
				settings.Get("tableName"),
				uniqueKeyConstraints,
			)

		}
	}

	foreignKeyConstraints := ""
	foreignKeys := settings.Get("foreignKeys")
	if foreignKeys != nil {
		fkci := foreignKeys.([]interface{})
		if len(fkci) > 0 {
			for _, fkc := range fkci {
				fkcs := fkc.([]interface{})
				localField := stringext.ToFieldName(fkcs[0].(string))
				refFields := strings.Split(fkcs[1].(string), ".")
				if len(refFields) != 3 {
					return nil, fmt.Errorf("need schemaName.tableName.fieldName")
				}
				keyName := fmt.Sprintf(
					"%s_%s_%s",
					stringext.ToFieldName("fkey"),
					stringext.ToFieldName(settings.Get("tableName").(string)),
					localField,
				)

				foreignKeyConstraints += fmt.Sprintf(
					"ALTER TABLE %q.%q ADD CONSTRAINT %q FOREIGN KEY (\"%s\") REFERENCES %s.%s (%s) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;\n",
					settings.Get("schemaName"),
					settings.Get("tableName"),
					keyName,
					localField,
					stringext.ToFieldName(refFields[0]), // first item schema name
					stringext.ToFieldName(refFields[1]), // second item table name
					stringext.ToFieldName(refFields[2]), // third item field name

				)

				foreignKeyConstraints = fmt.Sprintf("-------------------------------\n--  Foreign keys structure for table %s\n-- ----------------------------\n%s",
					settings.Get("tableName"),
					foreignKeyConstraints,
				)
			}
		}
	}

	return clean([]byte(primaryKeyConstraint + uniqueKeyConstraints + foreignKeyConstraints)), nil
}
