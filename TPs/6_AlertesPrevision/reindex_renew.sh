#!/bin/bash

# Variables de configuration
ELASTICSEARCH_URL="https://localhost:9200"  # Remplacez par l'URL de votre serveur Elasticsearch
INDEX_DEST="it_ops_kpi2"
INCREMENT_FILE="/tmp/timestamp_increment.txt"  # Fichier pour suivre l'incrément

while true; do
    # Lire l'incrément actuel ou définir un début de valeur
    if [[ -f "$INCREMENT_FILE" ]]; then
    INCREMENT=$(cat "$INCREMENT_FILE")
    else
    INCREMENT=116  # Valeur de départ (116 heures en millisecondes)
    fi

    # Récupérer les documents à indexer depuis l'index source (si nécessaire)
    # Vous pouvez personnaliser cette requête pour obtenir des documents à partir de l'index source.
    # Par exemple, cela récupère tous les documents de l'index source.
    DOCUMENTS=$(curl -k -u elastic:secret -s -X GET "$ELASTICSEARCH_URL/it_ops_kpi/_search" -H "Content-Type: application/json" -d '{
    "query": {
        "match_all": {}
    }
    }' | jq -r '.hits.hits[] | {index: {_index: "it_ops_kpi2"}, doc: ._source}')


    # Construire la requête bulk pour ajouter les documents à l'index de destination
    BULK_BODY=""
    for doc in $(echo "$DOCUMENTS" | jq -r '. | @base64'); do
    _doc=$(echo "$doc" | base64 --decode)
    BULK_BODY+="{ \"create\": { } }"$'\n'
    # echo "1 $BULK_BODY" 
    # BULK_BODY+=$(echo "$_doc" | jq -r '.index | tojson')
    # echo "2 $BULK_BODY" 
    BULK_BODY+=$(echo "$_doc" | jq -r '.doc | .["@timestamp"] = .["@timestamp"] + ('"$INCREMENT"' * 24 * 60 * 60 * 1000) | tojson')$'\n'
    # echo "3 $BULK_BODY" 
    done

    # Indexer les documents dans l'index de destination
    curl -k -u elastic:secret -X POST "$ELASTICSEARCH_URL/it_ops_kpi2/_bulk" -H "Content-Type: application/x-ndjson" -d "$BULK_BODY" | jq

    # Incrémenter la valeur pour la prochaine exécution
    NEW_INCREMENT=$((INCREMENT + 116))  # Ajouter 116 heures à chaque itération
    echo "$NEW_INCREMENT" > "$INCREMENT_FILE"  # Sauvegarder le nouvel incrément pour la prochaine exécution

    # Optionnel: Faire une pause de 1 heure avant la prochaine exécution
    sleep 60  
    curl -k -u elastic:secret -X GET "$ELASTICSEARCH_URL/it_ops_kpi2/_refresh" -H "Content-Type: application/x-ndjson" | jq

done