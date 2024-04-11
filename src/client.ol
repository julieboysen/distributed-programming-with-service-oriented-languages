from server import Server, ServerParams
from console import Console
from runtime import Runtime
from server import ExternalServerInterface, InternalServerInterface

service Client() {
  execution: single
  embed Console as Console
  embed Runtime as Runtime

  outputPort S0 {
    location: "socket://localhost:8000"
    protocol: sodep
    interfaces: ExternalServerInterface
  }
  
  outputPort S1 {
    location: "socket://localhost:8001"
    protocol: sodep
    interfaces: ExternalServerInterface
  }

  outputPort S2 {
    location: "socket://localhost:8002"
    protocol: sodep
    interfaces: ExternalServerInterface
  }

  main {   
    println@Console("Client started\n")()
    
    println@Console( "Put operation on S0, key = Testing, value = GC" )( )
    put@S0( { key = "Testing", value = "GC"} )( )
    put@S1( { key = "Test2", value = "GC"} )( )
    put@S2( { key = "Test3", value = "GC"} )( )
    get@S0( "Testing" )( response )
    println@Console( "Response from S0: " + response )( )
    get@S1( "Testing" )( response )
    println@Console( "Response from S1: " + response )( )
    get@S2( "Testing" )( response )
    println@Console( "Response from S2: " + response + "\n" )( )

    println@Console( "Delete operation on S0, key = Testing" )( )
    delete@S0( "Testing" )( )
    get@S0( "Testing" )( response )
    println@Console( "Response from S0: " + response )( )
    get@S1( "Testing" )( response )
    println@Console( "Response from S1: " + response )( )
    get@S2( "Testing" )( response )
    println@Console( "Response from S2: " + response )( )
  }
}

