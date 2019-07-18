#!/bin/bash

cd ../terraform/stage

app_ip=$(terraform output app_external_ip)
db_ip=$(terraform output db_external_ip)

cd ../../ansible

inventory_template () {
cat <<EOF > inventory.json
{
    "_meta": {
      "hostvars": {}
    },
    "app": {
      "hosts": ["$app_ip"]
    },
    "db": {
      "hosts": ["$db_ip"]
    }
}
EOF
}

inventory_template
cat inventory.json
