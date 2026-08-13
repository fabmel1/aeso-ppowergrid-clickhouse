#Install docker image
docker-compose -f docker/docker-compose.yml up -d

#Open ClickHouse client
docker exec -it local-clickhouse clickhouse-client --password password