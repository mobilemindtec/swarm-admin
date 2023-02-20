#!/bin/tclsh


source "./core/httpserver.tcl"
source "./core/socketserver.tcl"
source "./handlers/index_handler.tcl"

set configs [dict create]
set routes [dict create] 

dict set routes "/" IndexGet
dict set routes "/docker/service/ls" DockerServiceList
dict set routes "/docker/service/ps/:id" DockerServicePs
dict set routes "/docker/node/ls" DockerNodeLs
dict set routes "/docker/node/ps/:id" DockerNodePs
dict set routes "/docker/ps" DockerPs


# cmd dockker stats

# dict set routes "/node" IndexGet
# dict set routes "/node/:id" GET
# dict set routes "/node/search?name" GET search service
# dict set routes "/node/metrics/:id" GET (disco,processamento,memória, serviços)
# dict set routes "/node/df/:id" GET 
# dict set routes "/node/df/clean/:id" GET 

# dict set routes "/service/ls" IndexGet

# dict set routes "/service/create/:name" GET
# dict set routes "/service/ps/:id" GET
# dict set routes "/service/logs/tail/:id?lines=100" GET
# dict set routes "/service/update/:id" POST
# dict set routes "/service/force/:id" GET
# dict set routes "/service/stop/:id" GET

# dict set routes "/service/logs/full/:id" GET
# dict set routes "/service/logs/full/download/:id" GET

# dict set routes "/stack" GET
# dict set routes "/stack/deploy/:name" POST
# dict set routes "/stack/rm/:name" # dict set routes "/stack/deploy/:name" POST
# dict set routes "/stack/edit/:name" # dict set routes "/stack/deploy/:name" POST
# dict set routes "/stack/update/:name" # dict set routes "/stack/deploy/:name" POST

# dict set routes "/swarm/token/:type" # dict set routes "/stack/deploy/:name" POST (manager/slave)

# /service/nginx/create/ssl
# /service/nginx/edit/default
# /service/nginx/update/default
# /service/nginx/build/:version



proc handler {chan} {

	set line [gets $chan]
	puts "socket server received: $line"

}

set socketConfigs {}
lappend socketConfigs handler handler 

runSocketApp $socketConfigs

runApp $configs $routes