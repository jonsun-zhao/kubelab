# Postgres

## Prerequisites

* Setup a Postgres CloudSQL instance/database `memegen-db` following this [Codelab](https://codelabs.developers.google.com/codelabs/cloud-postgresql-gke-memegen)
* Run the `memegen` application locally with `cloud_sql_proxy`
* Create a meme in the app which will populate the `meme` table in the DB
* Allow workloads in the mesh to reach google domains (required by `cloud_sql_proxy`)

  ```sh
  kubectl apply -f ../egressl_to_google.yaml
  ```

* Allow workloads in the mesh to reach `memegen-db` instance

  ```sh
  kubectl apply -f egress_to_cloudsql.yaml
  ```

## Options

### `cloud_sql_proxy` as a sidecar

```sh
kubectl apply -f sidecar.yaml
```

```sh
→ kiwl exec postgres-toolbox -c toolbox -it bash
[root@postgres-toolbox ~]# psql -h localhost -p 5432 -U postgres memegen
Password for user postgres:
psql (9.2.24, server 9.6.10)
WARNING: psql version 9.2, server version 9.6.
         Some psql features might not work.
Type "help" for help.

memegen=>
```

### `cloud_sql_proxy` as a standalone service

```sh
kubectl apply -f standalone.yaml
```

```sh
→ kiwl exec postgres-toolbox-standalone -c toolbox -it bash
[root@postgres-toolbox-standalone ~]# psql -h postgres-cloudsql-proxy -U postgres memegen
Password for user postgres:
psql (9.2.24, server 9.6.10)
WARNING: psql version 9.2, server version 9.6.
         Some psql features might not work.
Type "help" for help.

memegen=> \l
                                                List of databases
     Name      |       Owner       | Encoding |  Collate   |   Ctype    |            Access privileges
---------------+-------------------+----------+------------+------------+-----------------------------------------
 cloudsqladmin | cloudsqladmin     | UTF8     | en_US.UTF8 | en_US.UTF8 |
 memegen       | cloudsqlsuperuser | UTF8     | en_US.UTF8 | en_US.UTF8 |
 postgres      | cloudsqlsuperuser | UTF8     | en_US.UTF8 | en_US.UTF8 |
 template0     | cloudsqladmin     | UTF8     | en_US.UTF8 | en_US.UTF8 | =c/cloudsqladmin                       +
               |                   |          |            |            | cloudsqladmin=CTc/cloudsqladmin
 template1     | cloudsqlsuperuser | UTF8     | en_US.UTF8 | en_US.UTF8 | =c/cloudsqlsuperuser                   +
               |                   |          |            |            | cloudsqlsuperuser=CTc/cloudsqlsuperuser
(5 rows)

memegen=>
```