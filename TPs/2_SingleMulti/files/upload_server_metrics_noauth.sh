#!/bin/bash

HOST='localhost'
PORT=9200
INDEX_NAME='server-metrics'
URL="http://${HOST}:${PORT}"
printf "\n== Script for creating index and uploading data == \n \n"
printf "\n== Deleting old index == \n\n"
curl -s -X DELETE ${URL}/${INDEX_NAME}

printf "\n== Creating Index - ${INDEX_NAME} == \n\n"
curl -s -X PUT -H 'Content-Type: application/json' ${URL}/${INDEX_NAME} -d '{  
   "settings":{  
      "number_of_shards":1,
      "number_of_replicas":0
   },
   "mappings":{  
         "properties":{  
            "@timestamp":{  
               "type":"date"
            },
            "accept":{  
               "type":"long"
            },
            "deny":{  
               "type":"long"
            },
            "host":{  
               "type":"keyword"
            },
            "response":{  
               "type":"float"
            },
            "service":{  
               "type":"keyword"
            },
            "total":{  
               "type":"long"
            }
         }
      }
}'

printf "\n== Bulk uploading data to index... \n"
for i in `seq 1 20`;
do
    curl -s -X POST -H "Content-Type: application/json" ${URL}/${INDEX_NAME}/_bulk --data-binary "@server-metrics_${i}.json" > /dev/null 
    
    printf "\nServer-metrics_${i} uploaded"
done

printf "\n done - output to /dev/null"

printf "\n\n== Check upload \n"
curl -s -X GET ${URL}/_cat/indices/${INDEX_NAME}?v

printf "\n Server-metrics uploaded \n "
