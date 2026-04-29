# Pre-requisites

```shell
sudo apt-get install nlohmann-json3-dev
```

# building

```shell
cmake -S . -B build
cmake --build build -j
```

## Running
./build/local_rag --emb-port 8013 --chat-port 8014 --profile fast ~/Documents/kb "Create a table with the mac address list and models?"

