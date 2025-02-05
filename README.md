## Docker image of Ruby 3.3.5 with Jemalloc, Node 22, PG client, Libsodium, and AWS CLI

[Docker Hub](https://hub.docker.com/repository/docker/pawurb/ruby-jemalloc-node)

## How to release

```bash

docker build .
docker images
docker tag IMAGE_ID pawurb/ruby-jemalloc-node:latest
docker tag IMAGE_ID pawurb/ruby-jemalloc-node:3.3.5
docker push pawurb/ruby-jemalloc-node:latest
docker push pawurb/ruby-jemalloc-node:3.3.5

```
