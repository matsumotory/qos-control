## Get stated

### 1. build qos-control docker image

```
$ make build
```

### 2. run qos-control (need privileged, ephemeral container)

```
$ make tty
```

### 3. set ether adapter (opt)

```
// if not eth[1-3]
$ ./set-ether.sh enp0s25
```

