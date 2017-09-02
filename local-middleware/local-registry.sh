#!/bin/sh

docker run -d -p 5000:5000 -v `pwd`/docker-registry:/var/lib/registry registry:2.6
