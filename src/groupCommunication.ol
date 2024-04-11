from console import Console
from runtime import Runtime
from internalGroupCommunicationInterface import InternalGroupCommunicationInterface
from externalGroupCommunicationInterface import ExternalGroupCommunicationInterface
from server import InternalServerInterface

// type for send 
type sendMessageType: void {
  .data?: undefined
  .operation: string
}

// interface for GC for clients (servers in this case)
interface ExternalGroupCommunicationInterface {
    RequestResponse:
        send( sendMessageType )( any )
}

// type for receive 
type receiveMessageType: void { 
    .operation : string
    .data?: undefined
    .time* : int 
    .id: int 
}

// interface for GC for other GCs
interface InternalGroupCommunicationInterface {
    RequestResponse:
        receive( receiveMessageType )( any )
}

// parameters for GC 
type GCParams {
    id: int
    logic: any
    location: string
    others*: string
}

service GC( p: GCParams ){ 
    execution: concurrent

    embed Console as Console
    embed Runtime as Runtime

    // output port for server (db) service
    outputPort LogicOutput { 
        location: "local" // p.logic
        protocol: sodep
        interfaces: InternalServerInterface
    }

    // output port for other GC services 
    // changed using dynamic rebinding 
    outputPort GCOutput { 
        location: "local" // p.others
        protocol: sodep
        interfaces: InternalGroupCommunicationInterface
    }

    // input port for server
    inputPort ExternalGCInput { 
        location: "local"
        protocol: sodep
        interfaces: ExternalGroupCommunicationInterface
    }

    // input port for other GC services 
    inputPort InternalGCInput { 
        location: p.location
        protocol: sodep
        interfaces: InternalGroupCommunicationInterface
    }

    init{  
        // update locations
        LogicOutput.location << p.logic
        // vector clock 
        global.clock_value[0] = 0
        // message queue 
        global.queue << 0 

        println@Console( "GC [" + p.location + "] started" )()
    }

    main{
        [ send( request )( resultVar ){
            // R1
            global.clock_value[p.id] = global.clock_value[p.id] + 1
            receiveRequest << { operation << request.operation
                                data << request.data
                                time << global.clock_value
                                id << p.id }
             // broadcast message and save all responses in 'resultVar'
            spawn( i over #p.others ) in resultVar {
                GCOutput.location = p.others[i] 
                receive@GCOutput( receiveRequest )( resultVar )
            } 
        } ]

        [ receive( request )( response ){ 
            // add request to message queue 
            global.queue[#global.queue - 1] << request

            // set max of timestamps 
            for( i = 0, i < #p.others + 1, i++ ){ 
                if( request.time[i] > global.clock_value[i] ){ 
                    global.clock_value[i] = request.time[i]
                }
            }
            // R1
            global.clock_value[p.id] = global.clock_value[p.id] + 1

            // delivery of messages 
            for( i = 0, i < #global.queue, i++ ){
                if( global.queue[i].time[p.id] <= global.clock_value[p.id] ){
                    update@LogicOutput( {operation = global.queue[i].operation, data << global.queue[i].data } )( response )
                }
            }
        } ]
    }
}