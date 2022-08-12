#!/bin/bash

#verificar permisos de carpetas
 
paquete="inotify-tools" #paquete que se necesita para el uso del script
declare -a acciones
entrada=false
salida=false
compilar=false
publicar=false
pathCompDef="./bin/compilar"
pathMonitoreados="./.monitoreados"

function exit_script() {
    grep -v "#$(pwd $pathEntrada)/$pathEntrada#" "$pathMonitoreados" > ".temp" | echo
    cat .temp > "$pathMonitoreados"
    rm ".temp" 
    trap - SIGINT SIGTERM 
    kill -- -$$ 

}

trap exit_script SIGINT SIGTERM
 
 
function instalar(){
    echo "$(tput setaf 6)Para poder utilizar nuestro script necesesita tener instalado el paquete de inotify-tools para instalarlo puede hacerlo con el siguiente comando:"
    
    echo "$(tput setaf 3)apt install inotify-tools"
    
    echo $(tput setaf 7)
 
}
 
function error(){
    echo -e "\n$(tput setaf 1)Error: $1\n"
    echo -e "$(tput setaf 2)Utilice -h o --help para ver la ayuda\n"
    echo $(tput setaf 7)
    exit 1
}
 
function ayuda(){
    echo -e "$(tput setaf 6)Usted esta viendo la ayuda del script\n"
    
    echo -e "$(tput setaf 2) \t-c <nombre_del_directorio> para indicar la ruta del directorio a monitorear.
            Si el nombre del directorio incluye 'espacios' por favor agregue comillas al inicio y final del nombre del directorio.\n" 
    echo -e "$(tput setaf 2) \t-s <lista_de_acciones> para indicar las acciones a realizar.
            Tienen que estar las mismas separadas por una coma,no pueden incluir espacios."
    echo -e "\n$(tput setaf 2) \t Las acciones son:
            \n\t\t listar: muestra por pantalla los nombres de los archivos que sufrieron cambios 
            (archivos creados, modificados, renombrados, borrados).
            \n\t\t peso: muestra por pantalla el peso de los archivos que sufrieron cambios.
            \n\t\t compilar: compila los archivos dentro del directorio pasado en “-c”. 
            \n\t\t publicar: copia el archivo compilado (el generado con la opción “compilar”) a un
            directorio pasado como parámetro “-s”. Esta opción no se puede usar sin la opción
            'compilar'."
    echo -e "$(tput setaf 2) \n\t-s: ruta del directorio utilizado por la acción 'publicar'. Sólo es obligatorio si se envía
            'publicar' como acción en '-a'.
            Si el nombre del directorio incluye 'espacios' por favor agregue comillas al inicio y final del nombre del directorio.\n"
    echo -e "\nEjemplos:
         \n ./script -c /home -a listar
         \n ./script -c . -a listar
         \n ./script -c . -a listar,compilar
         \n ./script -c . -a compilar,publicar -s ../salida"
    echo $(tput setaf 7)
}
 
function ejecutarAcciones(){
    IFS='
    '
    for i in ${acciones[@]}
    do
        case $i in 
        "listar")
            echo "Nombre del archivo: $2"
            echo "Accion: $3"
        ;;
        "peso")
            res=$(stat --printf="%s" "$1$2" 2>/dev/null)
            if [ ! $res = "" ]
            then
                echo "El peso de $2 es: $res bytes"
            else
                echo "No se pudo calcular el peso porque el archivo fue borrado"
            fi
        ;;
        "compilar")
            echo "esta compilando"
            if [ ! -e "./bin" ]
            then
                mkdir ./bin
            fi
            cp /dev/null $pathCompDef
            find "$pathEntrada" -maxdepth 1 -type f | while read arch;do
            cat "$arch" >> "$pathCompDef"
            done
            if [ $publicar = true ]
            then
                cp $pathCompDef "$pathSalida"
            fi
        ;;
        *)
        ;;
        esac
    done
}

function archivoMonitoreo(){
    if [ "${1:0:2}" = "./" ]
    then
        remplazo=$(echo | awk -v myvar=$1 '{ print substr( myvar, 3 ) }')
    else
        remplazo=$1
    fi
    if [ ! -e $pathMonitoreados ]
    then
        touch $pathMonitoreados
    fi
    observado="$(grep "#$(pwd $remplazo)/$remplazo#" $pathMonitoreados)"
    if [ -z "$observado" ]
    then
        echo "#$(pwd $remplazo)/$remplazo#" >> $pathMonitoreados
    else
        error "ya se esta monitoreando ese directorio"
    fi    
}
 
#Verificacion del paquete extra
dpkg -l $paquete > /dev/null
 
if [ $? -ne 0 ]
then
    instalar
    exit 0 
fi
 
#Verificacion de parametros
if [ $# = 0 ]
then 
    error "no llegaron parametros"
fi
 
if [ $1 = "-?" ]
then
    ayuda
    exit 0
fi
 
 
options=$(getopt -o c:a:s:h --l help,entrada:,acciones:,salida: -- "$@" 2> /dev/null)
 
if [ "$?" -ne 0 ] || [ "$#" -eq 0 ]
then
    error "el uso de parametros o no se recibio ninguno"
fi
 
eval set -- "$options"
while true
do
    case "$1" in
        -c | --entrada)
            declare -a pathEntrada="$2"
            entrada=true
            shift 2 
            ;;
        -s | --salida)
            pathSalida="$2"
            salida=true
            shift 2
            ;;
        -a | --acciones)
            acciones=$(echo $2 | tr "," "\n")
            for i in $acciones
            do
                case "$i" in 
                "listar" | "peso")
                ;;
                "publicar")
                    publicar=true
                ;;
                "compilar")
                    compilar=true
                ;;
                *)
                    error "una accion no permitida"
                ;;
                esac
            done
            shift 2
            ;;
        -h | --help )
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            error "el envio de parametros"
            ;;
    esac
done
 
#validacion de parametros con otros parametros
if [ ! -e "$pathEntrada" ]
then 
    error "no existe la carpeta a observar"
fi
 
if [ $entrada = false ]
then 
    error "el parametro de entrada, se necesita un directorio a observar"
else
    if [ ! -r "$pathEntrada" ]
    then
        error "los permisos del directorio a observar"
    fi
fi

if [ $publicar = true ] && [ $compilar = false ]
then
    error "accion publicar sin accion compilar" 
fi
 
if [ $publicar = false ] && [ $salida = true ] 
then 
    error "el parametro salida, es necesario si se usa la accion publicar y la accion publicar es necesario si se usa el parametro salida"
fi

if [ $publicar = true ] && [ $salida = false ] 
then 
    error "falta la carpeta de salida"
fi
 
if [ $salida = true ] && [ ! -e "$pathSalida" ]
then 
    verificar="${pathSalida%/*}"
    if [ $pathSalida == $verificar ]
    then 
        verificar="./"
    fi
    if [ -w $verificar ]
    then
        mkdir "$pathSalida"
    else
        error "se intento crear la carpeta para la salida pero no se tienen permisos"
    fi
fi
 
#verificacion de carpetas monitoreadas

archivoMonitoreo "$pathEntrada"

#monitoreo de carpeta
inotifywait -r -m --format "%w,%e,%f" "$pathEntrada" -e create,modify,delete,move | while 
IFS=','
read path action file ;do
    case "${action}" in 
    "CREATE")
        ejecutarAcciones "${path}" "${file}" "${action}"
    ;;
    "MODIFY")
        ejecutarAcciones "${path}" "${file}" "${action}"
    ;;
    "DELETE")
        ejecutarAcciones "${path}" "${file}" "${action}"
    ;;
    "MOVED_FROM")
        renombre="${path}"
    ;;
    "MOVED_TO")
        if [ $renombre == ${path} ]
        then
            ejecutarAcciones "${path}" "${file}" "RENAME"
        fi
    ;;
    *)
    ;;
    esac
done