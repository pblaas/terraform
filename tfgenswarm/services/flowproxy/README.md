For more info checkout the project URL at http://proxy.dockerflow.com/swarm-mode-stack/

To deploy this stack:
```
swarm stack deploy -c docker-compose-stack.yml proxy
```

```
curl -o docker-compose-stack.yml \
    https://raw.githubusercontent.com/\
vfarcic/docker-flow-proxy/master/docker-compose-stack.yml
```

!note only use the 'swarm' command if you set it as alias. Otherwhise use 'docker'.
