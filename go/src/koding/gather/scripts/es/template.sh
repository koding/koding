# This scripts create es `gather_metrics` template, which are a kind of
# per index configuration.
curl -XDELETE https://fcd741dd72ad8998000.qbox.io/_template/gather_metrics

curl -XPUT https://fcd741dd72ad8998000.qbox.io/_template/gather_metrics -d '
{
  "template" : "gather_metrics",
  "mappings" : {
      "git_remotes": {
          "properties": {
              "values": {
                  "properties": {
                      "field": {
                          "type": "string",
                          "index" : "not_analyzed"
                      },
                      "value": {
                          "type": "string",
                          "index" : "not_analyzed"
                      }
                  }
              }
          }
      }
  }
}
'
