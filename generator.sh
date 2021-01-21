#!/bin/bash
DIR="${HOME}/generator"
USER_SCRIPT=$USER

# Fonctions
help_list() {
  echo "Usage:

  ${0##*/} [-h][--postgres][--mysql]

Options:

  -h, --help
    can I help you ?

  -i, --ip
    list ip for each container

  -p, --postgres [ID if you want]
    run postgres

  --mysql [ID if you want]
    run mysql

  --mariadb [ID if you want]
    run mariadb

  --clean [container name]
    remove container and datas
  "
}

ip() {
  for i in $(docker ps -q);do docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} - {{.Name}}" $i;done
}

mysql() {
  echo
  echo "Install MySQL"
  echo ""
  [ ! -z $1 ] && echo "Création du conteneur : mysql${1}" && ID_CONTAINER=$1 && echo ""
  echo "1 - Create directories ${DIR}/mysql${ID_CONTAINER}/"
  mkdir -p $DIR/mysql${ID_CONTAINER}/

  echo "
version: '3.0'
services:
  mysql${ID_CONTAINER}:
    image: bitnami/mysql:latest
    container_name: mysql${ID_CONTAINER}
    environment:
    - MYSQL_ROOT_PASSWORD=12345678
    - MYSQL_DATABASE=test
    - MYSQL_USER=user
    - MYSQL_PASSWORD=1234
    - TZ=Europe/Paris
    expose:
    - 3306
    networks:
    - generator
    volumes:
    - mysql_data${ID_CONTAINER}:/var/lib/mysql
volumes:
  mysql_data${ID_CONTAINER}:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/mysql${ID_CONTAINER}
networks:
  generator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.168.0/24
" >$DIR/docker-compose-mysql${ID_CONTAINER}.yml

  echo "2 - Run mysql"
  docker-compose -f $DIR/docker-compose-mysql${ID_CONTAINER}.yml up -d
}

mariadb() {
  echo
  echo "Install Mariadb"
  echo ""
  [ ! -z $1 ] && echo "Création du conteneur : mariadb${1}" && ID_CONTAINER=$1 && echo ""
  echo "1 - Create directories ${DIR}/mariadb${ID_CONTAINER}/"
  mkdir -p $DIR/mariadb${ID_CONTAINER}/

  echo "
version: '3.0'
services:
  mariadb${ID_CONTAINER}:
    image: mariadb
    container_name: mariadb${ID_CONTAINER}
    environment:
    - MYSQL_ROOT_PASSWORD=12345678
    - MYSQL_DATABASE=test
    - MYSQL_USER=user
    - MYSQL_PASSWORD=1234
    - TZ=Europe/Paris
    expose:
    - 3306
    networks:
    - generator
    volumes:
    - mariadb_data${ID_CONTAINER}:/var/lib/mysql
volumes:
  mariadb_data${ID_CONTAINER}:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/mariadb${ID_CONTAINER}
networks:
  generator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.168.0/24
" >$DIR/docker-compose-mariadb${ID_CONTAINER}.yml

  echo "2 - Run mariadb"
  docker-compose -f $DIR/docker-compose-mariadb${ID_CONTAINER}.yml up -d
}

postgres() {
  echo
  echo "Install Postgres"
  echo ""
  [ ! -z $1 ] && echo "Création du conteneur : postgres${1}" && ID_CONTAINER=$1 && echo ""
  echo "1 - Create directories ${DIR}/generator/postgres${ID_CONTAINER}/"
  mkdir -p $DIR/postgres${ID_CONTAINER}/

  echo "
version: '3.0'
services:
  postgres${ID_CONTAINER}:
    image: postgres:latest
    container_name: postgres${ID_CONTAINER}
    environment:
    - POSTGRES_USER=myuser
    - POSTGRES_PASSWORD=password
    - POSTGRES_DB=mydb
    expose:
    - 5432
#    volumes:
#    - postgres_data${ID_CONTAINER}:/var/lib/postgresql/data/
    networks:
    - generator
#volumes:
#  postgres_data${ID_CONTAINER}:
#    driver: local
#    driver_opts:
#      o: bind
#      type: none
#      device: ${DIR}/postgres${ID_CONTAINER}
networks:
  generator:
    driver: bridge
    ipam:
      config:
	    - subnet: 192.168.168.0/24
" >$DIR/docker-compose-postgres${ID_CONTAINER}.yml

  echo "2 - Run postgres"
  docker-compose -f $DIR/docker-compose-postgres${ID_CONTAINER}.yml up -d

  echo "
  Credentials:
      user: myuser
      password: password
      db: mydb
      port: 5432

  command : psql -h <ip> -u myuser mydb
  "
}

clean(){
  NAME_CONTENEUR=$1
  [ -z ${NAME_CONTENEUR} ] && exit 1
  docker-compose -f $DIR/docker-compose-${NAME_CONTENEUR}.yml down
  #[ ! -z ${NAME_CONTENEUR} ] && rm -rf $DIR/${NAME_CONTENEUR}
  rm -f $DIR/docker-compose-${NAME_CONTENEUR}.yml
  docker volume prune -f
}

## Execute ########################################################

optspec=":ihvpm-:"
while getopts "$optspec" optchar; do
  case "${optchar}" in
    -)
      case "${OPTARG}" in
        postgres)
          arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          postgres "$arg"
          ;;
        clean)
          arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          clean "$arg"
          ;;
        mysql)
          arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          mysql "$arg"
          ;;
        mariadb)
          arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          mariadb "$arg"
          ;;
        ip)
          ip
          ;;
        help)
          echo "Erreur reportez-vous à l'aide"
          help_list
          ;;
        *)
          echo "Erreur reportez-vous à l'aide"
          help_list ;;
      esac
      ;;
    i)	ip ;;
    p)	postgres ;;
    h)	help_list ;;
    *)	echo "Erreur reportez-vous à l'aide"
    help_list ;;
  esac
done
