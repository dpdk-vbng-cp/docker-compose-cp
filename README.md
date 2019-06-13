
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
                               |dpdk-ip-pipeline-cli|
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
docker-compose up --build
```
Stop environment:
```
docker-compose down
```
Delete docker container:
```
docker-compose rm
```
