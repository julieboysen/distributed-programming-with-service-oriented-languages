from console import Console
from runtime import Runtime
from groupCommunication import GC, ExternalGroupCommunicationInterface

// parameters for servers
type ServerParams { 
    // external AP (where clients can find this server)
    location: string
    gcparams: void {
      id: int
      location: string
      others: void {"_"*:string}
    }
}

// type for put requests
type putRequest: void {
  key : string
  value : any
}

// interface for clients on servers
interface ExternalServerInterface {
  RequestResponse: 
    put( putRequest )( void ),
    delete( string )( void ),
    get( string )( any )
}

// type for update requests
type updateRequest: void {
  operation : string
  data : undefined
}

// interface for GC to communicate with server
interface InternalServerInterface {
  RequestResponse: 
    update( updateRequest )( void )
}

service Server( p : ServerParams ) {
  execution: concurrent

  embed Console as Console
  embed Runtime as Runtime

  // input port exposing the 'InternalServerInterface' to GC service
  inputPort InternalLogicInput {
      location: "local"
      protocol: sodep
      interfaces: InternalServerInterface
  }
  
  // input port exposing the 'ExternalServerInterface' to client service
  inputPort ExternalLogicInput {
      location: p.location
      protocol: sodep
      interfaces: ExternalServerInterface
  }

  // output port for GC
  outputPort GC { 
    location: "local"
    protocol: sodep
    interfaces: ExternalGroupCommunicationInterface
  }

  init {
    println@Console("INFO: [ Server@" + p.location + "] starting...")() 
    getLocalLocation@Runtime()( location ) 

    // embedding GC
    loadEmbeddedService@Runtime( { 
        filepath = "groupCommunication.ol"
        params << { 
            logic << location
            id << p.gcparams.id
            others << p.gcparams.others._, // unwrap JSON '_'
            location << p.gcparams.location
        } } )( GC.location )

    // global db for instance of this service
    global.db = {}
    
    println@Console("INFO: [ Server@" + p.location + "] started")() 
  }

  main {
    // put for adding/updating element to db 
    [ put( request )( ) {
      println@Console("INFO: [ Server@" + p.location + "] put")() 
      global.db.(request.key) = request.value
      sendRequest << { .operation << "put"
                        .data << { key << request.key, value << request.value } }
      send@GC( sendRequest )( response )
    } ]
    // get for getting element based on key 
    [ get( request )( response ) {
      println@Console("INFO: [ Server@" + p.location + "] get")() 
      response = global.db.(request)
    } ]
    // delete for deleting element based on key
    [ delete( request )( ) {
      println@Console("INFO: [ Server@" + p.location + "] delete")() 
      undef(global.db.(request))
      sendRequest << { .operation = "delete"
                        .data << request }
      send@GC( sendRequest )( response )
    } ]    
    // for updating the db, to ensure all dbs contain the same data
    [ update( request )( ) {
      println@Console("INFO: [ Server@" + p.location + "] update")() 
      if(request.operation == "put"){
        global.db.(request.data.key) << request.data.value
        
      }else if(request.operation == "delete"){ 
        undef(global.db.(request.data))
      }
    } ]
  }
}