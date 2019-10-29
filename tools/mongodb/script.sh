#! /bin/sh 
set -e
mongoimport --host localhost --db test --collection people --drop --file /app/data/data.json