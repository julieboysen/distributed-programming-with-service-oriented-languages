
# Distributed programming with service-oriented languages

Implementation of multiple sources single group (MSMG) group communication algorithm in the service-oriented language Jolie.. The system consists of multiple server instances and a client that communicates with these servers to perform basic operations like `PUT`, `GET`, and `DELETE` on stored data.

## Project Structure

- **client.ol**: The client is responsible for interacting with the servers. It performs the operations on the distributed servers and outputs responses to the console.
- **server.ol**: The server contains the implementation of a simple key-value store. 
- **params0.json, params1.json, params2.json**: JSON configuration files specifying server parameters, including server locations and group communication setup.
- **startservers.sh**: A script to start the servers in the background using parameter files.

## How It Works

1. **Servers**:  
   Each server runs an instance of the `server.ol` program with different configurations specified in the `params0.json`, `params1.json`, and `params2.json` files. These configuration files define the socket location of each server and set up group communication for distributed coordination.

   - `params0.json` starts a server on `socket://localhost:8000` with group communication configuration.
   - `params1.json` starts a server on `socket://localhost:8001`.
   - `params2.json` starts a server on `socket://localhost:8002`.

2. **Client**:  
   The `client.ol` program interacts with the servers to perform the following operations:
   - PUT a key-value pair on each server.
   - GET the value associated with a key from each server.
   - DELETE a key from one server and check the status on all servers.
   
   These operations are logged to the console to display the results of each interaction.

## Running the Project

### Prerequisites

- **Jolie Framework**: Install Jolie from [jolie-lang.org](https://jolie-lang.org/).
  
  Ensure that Jolie is installed and accessible from the command line by running:
  ```bash
  jolie --version
  ```

### Steps to Run

1. **Start Servers**:  
   The `startservers.sh` script starts the three server instances with different parameters. Run the script in your terminal:
   ```bash
   ./startservers.sh
   ```
   This will start three server instances listening on `localhost:8000`, `localhost:8001`, and `localhost:8002`.

2. **Run the Client**:  
   After starting the servers, you can run the client to interact with them:
   ```bash
   jolie client.ol
   ```

   The client will perform PUT, GET, and DELETE operations on the servers and log the responses to the console.

### Configuration

Each server's behavior is defined by its parameter file (`params0.json`, `params1.json`, `params2.json`). These files specify:
- `location`: The socket address where the server listens for requests.
- `gcparams`: Group communication parameters that define the server's unique ID and the other servers it can communicate with.

For example, `params0.json` contains:
```json
{
    "location" : "socket://localhost:8000",
    "gcparams": {
        "id": 0,
        "location" : "socket://localhost:9000",
        "others" : [ "socket://localhost:9001", "socket://localhost:9002" ]
    }
}
```
