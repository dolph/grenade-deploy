#!/bin/bash
set -ex

for i in `seq 1 10` do
    apt-get update && break || sleep 15
done
