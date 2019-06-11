
# docker-compose-cp
Docker compose create the control plane  docker environment:
```
                              +--------+-----------+
                              |                    |
                              |     accel-ppp      |
                              |                    |
                              +--------+-----------+
                                       |
                                       |
                              +--------+-----------+
                              |                    |
                              |    redis pub/sub   |
                              |                    |
                              +--------+-----------+
                                       |
                                       |
                               +-------+------------+
                               |                    |
                               | pdk-ip-pipeline-cli|
                               |                    |
                               +--------+-----------+
                                        |
                                  +-----+--------+
                                  |              |
                       +----------+-----+   +----+-----------+    
                       | telnet_uplink  |   | telnet_uplink  |
                       +----------------+   +----------------+     
```
## Run environment
Update submodule:
```
git submodule update --init
```
Run environment
```
docker-compose run --build
```
Stop environment:
```
docker-compose stop
```
Delete docker container:
```
docker-compose rm
```
