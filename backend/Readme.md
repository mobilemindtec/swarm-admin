
FEATURES
--------

* docker service ls
* docker service ps ${service-name}

TODO
----

#### docker
- docker rm ${image-id}
- docker ls
- docker stats

- aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 125408739825.dkr.ecr.us-east-1.amazonaws.com
- eval "$(aws ecr get-login-password  --region us-east-1)"


### docker service
- docker service rm ${service-name}
- docker service logs --timestamps --follow --tail 100 ${container-name}
- docker service update --force ${service-name}

- docker service logs $service-id
	* (for all services ids to get all logs) 

### docker stack
- docker stack rm ${stack-name}
- docker stack deploy --with-registry-auth -c ${stack-name}.yaml $2

### clean docker disk space
- docker system df
- docker system prune -a

### restart docker service
- sudo service docker restart
- sudo service docker stop
- sudo service docker start

-- auth login
-- responsive, mobile
-- show services, nodes, services by node (ls, ps)
-- show nodes resources
-- find server by node
-- deploy services
-- re-deploy 
-- get all logs service (at all nodes)
-- tail service log / filter
-- execute shell docker commands? like backup
-- node resource monitor, send mail
-- enviar logs diários de determinados serviços para S3
-- sqlite configs

# template 
https://github.com/cyrilthomas/tcl-simple-templater
https://github.com/ianka/mustache.tcl
https://techtinkering.com/articles/introducing-ornament-a-tcl-template-module/
https://wiki.tcl-lang.org/page/Tcl+Tutorial+Lesson+0

Install JSON lib:
$ sudo apt install tcllib

Install ornament

$sudo ./installmodule.tcl ornament_tcl/ornament-0.1.tm

