package js

import (
	"fmt"
	"strings"

	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

// GenerateJSValidator generates the validators for the the given schema
func GenerateJSValidator(si *schema.Schema) (string, error) {
	s := si
	isMultiple := false
	if s.Type == "array" {
		if s.Items[0].Type != "object" {
			s.Properties = make(map[string]*schema.Schema)
			s.Properties["v"] = s.Items[0]
		}
		isMultiple = true
	}

	var validators []string
	schemaFirstChar := stringext.Pointerize(s.Title)

	for _, property := range schema.SortedSchema(s.Properties) {
		k := property.Title
		if k == "" {
			k = "v"
		}

		key := stringext.ToLowerFirst(k)

		switch property.Type {
		case "string":
			if property.MinLength != 0 {
				validator := fmt.Sprintf("%s: iz(%s.%s).required().minLength(%d)", key, schemaFirstChar, key, property.MinLength)
				validators = append(validators, validator)
			}

			if property.MaxLength != 0 {
				validator := fmt.Sprintf("%s: iz(%s.%s).required().maxLength(%d)", key, schemaFirstChar, key, property.MaxLength)
				validators = append(validators, validator)
			}

			if property.Pattern != "" {
				regexStr := `var regexValidator = function(value, regex){
    if(typeof value !=='string'){
        return false;
    }
    return value.match(regex);
};
iz.addValidator('regexValidator', regexValidator);
%s: iz(%s.%s).regexValidator(%s);`

				validator := fmt.Sprintf(regexStr, key, schemaFirstChar, key, property.Pattern)
				validators = append(validators, validator)
			}

			if len(property.Enum) > 0 {
				generatedEnums := make([]string, len(property.Enum))
				for i, enum := range property.Enum {
					generatedEnums[i] = fmt.Sprintf("%q", stringext.ToLowerFirst(enum))
				}
				validator := fmt.Sprintf("%s: iz(%s.%s).required().inArray([%s,])", key, schemaFirstChar, key, strings.Join(generatedEnums, ","))
				validators = append(validators, validator)
			}

			switch property.Format {
			case "date-time":
				// _, err := time.Parse(time.RFC3339, s)
				validator := fmt.Sprintf("%s: iz(%s.%s).required().date()", key, schemaFirstChar, key)
				validators = append(validators, validator)
			}

		case "integer", "number":
			// log.Printf("property number %# v", pretty.Formatter(property))
			if property.Format == "int64" {
				validator := fmt.Sprintf("%s: iz(null).required().minLength(1)", key)
				validators = append(validators, validator)
				continue
			}

			if property.Minimum != 0 {
				validator := fmt.Sprintf("%s: iz(%s.%s).int().between(%f, Number.MAX_SAFE_INTEGER).required()", key, schemaFirstChar, key, property.Minimum)
				validators = append(validators, validator)
			}

			if property.Maximum != 0 {
				validator := fmt.Sprintf("%s: iz(%s.%s).int().between(Number.MIN_SAFE_INTEGER, %f).required()", key, schemaFirstChar, key, property.Maximum)
				validators = append(validators, validator)
			}

			if property.MultipleOf != 0 {
				validator := fmt.Sprintf("%s: iz(%s.%s).int().multiple(%f)", key, schemaFirstChar, key, property.MultipleOf)
				validators = append(validators, validator)
			}
		}
	}

	if len(validators) == 0 {
		return "", nil
	}

	rules := strings.Join(validators, ",\n        ")

	validatorStr := singleValidator
	if isMultiple {
		validatorStr = multiValidator
	}

	return fmt.Sprintf(`rules = {
        %s
      };
      areRules = are(rules);
      %s`, rules, validatorStr), nil
}

const singleValidator = `if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }`

const multiValidator = `for (var i = 0; i < data.length; i++){
        if (!areRules.validFor(data[i])){
          return callback(areRules.getInvalidFields());
        }
      }`
