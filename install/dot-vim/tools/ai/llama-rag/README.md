# llama-rag

# How to use it?
## From vide
The pre-requisite is that the embeddings server is working. You can see it by:
```shell
screen -r llamaServerEmbeddings
```

Then, from in vim type ':Askrag', press enter, and you'll be asked from which folder you want to search.

## From the CLI
First launch an embeddings server, e.g.:
```shell
llama-server -hf Snowflake/snowflake-arctic-embed-m-v1.5:Q8_0 --embeddings --host 127.0.0.1 --port 8013 -c 2048 -ngl auto
```

Then launch the query, e.g.:
```shell
./build/local_rag --emb-port 8013 --chat-port 8014 --profile fast ~/Documents/ "Create a table with the mac address list and models?"
```
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

