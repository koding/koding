/^Name:/						{ printf("\n%s",$2); }
/^Alias:/ && $2!="None" &&  /preferred MIME name/	{ printf("\t* %s",$2); }
/^Alias:/ && $2!="None" && !/preferred MIME name/	{ printf("\t%s",$2); }

