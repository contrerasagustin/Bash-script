#!/bin/bash

 function ayuda() {
        echo
        echo "---------------------------------------------------------------------------------------------------"
        echo "El script permite emular el comportamiento del comando rm, pero utilizando el concepto de papelera de reciclaje, es decir que, al borrar un ARCHIVO se tenga la posibilidad de recuperarlo en el futuro."
        echo
        echo "PARAMETROS"
        echo
        echo "--eliminar <RutaArchivo> : path absoluto o relativo del archivo a eliminar (obligatorio)"
        echo
        echo "--listar : lista los archivos que se encuentran en la papelera y sus rutas originales"
        echo
        echo "--recuperar <NombreArchivo> : permite recuperar el archivo pasado por parametro (obligatorio), en el caso que existan dos archivos con el mismo nombre , el usuario tendra la posibilidad de elegir cual recuperar"
        echo
        echo "--vaciar : permite vaciar la papelera de reciclaje, eliminando definitivamente todos los archivos"
        echo
        echo "EJEMPLOS"
        echo "./script.sh --eliminar archivo.txt" 
        echo "./script.sh --eliminar /home/archivo.txt"
        echo "./script.sh --eliminar /../Public/archivo.txt"
        echo "./script.sh --recuperar archivo.txt"
        echo "./script.sh --listar"
        echo "./script.sh --vaciar"
        echo
        echo "CASO DE ARCHIVO CON NOMBRE REPETIDO AL RECUPERAR"
        echo "./script.sh --recuperar Siso"
        echo -e "\t1 - Sisop /home/usuario1/docs"
        echo -e "\t2 - Sisop /home/usuario1/descargas"
        echo -e "\t3 - Sisop /home/usuario1/imágenes"
        echo "¿Qué archivo desea recuperar? ___"
        echo
        echo "ACLARACIÓN"
        echo "En caso de querer eliminar/recuperar archivos con espacios en sus nombres, como requisito se tiene que pasar la ruta o nombre del archivo entre comillas ('archivo con espacio.txt')"
        echo "./script.sh --eliminar 'archivo con espacio.txt'"
        echo "./script.sh --eliminar '/home/Mi Carpeta/archivo.txt'"
        echo "./script.sh --recuperar 'archivo con espacio.txt'"
        echo
        echo "---------------------------------------------------------------------------------------------------"
        echo
        echo
}

if [ $# -lt 1 ]
then
    ayuda
    exit
fi
 
if [ $1 = "-?" ]
then
    ayuda
    exit
fi
 
rutaArchivo=$(pwd)
archivo=""
cd $home
homeUsuario=$(pwd)
DIRECTORIO_PAPELERA_ZIP="$homeUsuario/Papelera.tar.gz"
FICHERO_RUTAS="$homeUsuario/nameFileWithOriginalPath.txt"
 
#verificamos si el archivo .zip esta creado.
function verificarExistenciaArchivoZip()
{
    if [ ! -f "$DIRECTORIO_PAPELERA_ZIP" ]
    then
        tar -uvf $DIRECTORIO_PAPELERA_ZIP
        chmod 777 $DIRECTORIO_PAPELERA_ZIP
    fi
}
 
#verificamos si el fichero de rutas esta creado.
function verificarExistenciaArchivoRutas()
{
    if [ ! -f $FICHERO_RUTAS ]
    then
        >$FICHERO_RUTAS
        chmod 777 $FICHERO_RUTAS
        cd /home
    fi
}
 
function verificarRutaRelativaOAbsoluta()
{ 
 
    rutaPorParametro="$1"
    if [ ! -f "$rutaArchivo/$rutaPorParametro" ]
    then
       if [ -f "$rutaPorParametro" ]
       then
            rutaArchivo=$(echo "$rutaPorParametro" | rev | cut -d '/' -f 2- | rev)
            cd "$rutaArchivo"
            rutaArchivo=$(pwd)
            archivo=$(echo "$rutaPorParametro" | rev | cut -d '/' -f 1 | rev)
          return 0
        else
          return 1
       fi
    else
        IFS="/" read -ra arr <<< "$rutaPorParametro"
        if [ ${#arr[@]} -eq 1 ]
            then
                archivo="$rutaPorParametro"
            else
 
                rut=$(echo "$rutaPorParametro" | rev | cut -d '/' -f 2- | rev)
                subcadena="${rut: 0: 1}"
                if [ $subcadena != "/" ]
                then
                    rut="/$rut"
                fi
                archivo=$(echo "$rutaPorParametro" | rev | cut -d '/' -f 1 | rev)
                rutaArchivo="$rutaArchivo$rut"
                cd "$rutaArchivo"
                rutaArchivo=$(pwd)
        fi
        return 0
    fi
}
 
 
verificarExistenciaArchivoZip
verificarExistenciaArchivoRutas
 
options=$(getopt -o h --l help,listar,vaciar,eliminar:,recuperar: -- "$@" 2> /dev/null)
 
if [ "$?" -ne 0 ]
then
    echo $'\e[1;33mCOMANDOS INCORRECTOS\e[0m'
    ayuda
    exit 1
fi
 
eval set -- "$options"
while true
do
    case "$1" in
        --listar)
            #LISTAR (mostrar archivos Papelera)
 
            if [ -s "$FICHERO_RUTAS" ]
                then  
                    echo $'\e[0;32m--------------------------------------------------------------\e[0m'
                    echo $'\e[0;32mARCHIVOS EN PAPELERA\e[0m'
                    cat $FICHERO_RUTAS | rev | cut -d " " -f 7- | rev 
                    echo $'\e[0;32m--------------------------------------------------------------\e[0m'
                else 
                    echo $'\e[32mLa papelera se encuentra vacia.\e[0m'
            fi
            exit;
            ;;
        --vaciar)
            cd $home
            if [ -s "$FICHERO_RUTAS" ]
                then  
                    #vaciamos papelera y archivo con rutas originales.
                    read -p $'\e[1;33mEstá seguro que desea eliminar toda la papelera? No se podra revertir. [y/N] \e[0m: ' yn && [ "${yn}" = 'y' ] && rm -r Papelera.tar.gz && verificarExistenciaArchivoZip && echo $'\e[32mPAPELERA VACIADA.\e[0m' && cat /dev/null > $FICHERO_RUTAS
                else 
                    echo $'\e[0;32mLa papelera ya se encuentra vacia.\e[0m'
            fi
            exit;
            ;;    
        --recuperar)
            #RECUPERAR (volver archivo a ubic original)
            cd $home
 
            declare -a arrayArchivosARecuperar
            #guardamos en el array las lineas de los archivos que contienen el nombre de archivo a recuperar
            mapfile -t arrayArchivosARecuperar < <(grep -w "$2" nameFileWithOriginalPath.txt)
 
 
            if [ ${#arrayArchivosARecuperar[@]} -eq 0 ]; 
                then 
                    echo $'\e[1;33mLa papelera no contiene el archivo a recuperar.\e[0m'
                    exit
                else 
                    #en el caso que solo exista un archivo con el mismo nombre. Directamente recupera.
                    if [ ${#arrayArchivosARecuperar[@]} -eq 1 ]
                        then
                         #obtenemos la fila donde se encuentra el nombre y ruta original del archivo que eligio el usuario y seleccionamos solo la ruta.
                        declare rutaOriginalArchivo=$(echo ${arrayArchivosARecuperar[$(( $numeroArchivo - 1 ))]} | rev | cut -d " " -f 7 | rev)
                        declare fechaArchivo=$(echo ${arrayArchivosARecuperar[$(( $numeroArchivo - 1 ))]} | rev | cut -d " " -f -6 | rev)
                       
                        #verificamos si el directorio original del archivo sigue existiendo.
                        if [ ! -d "$rutaOriginalArchivo" ]
                            then
                                echo $'\e[1;33mEl directorio original del archivo ya no existe.El archivo no se puede recuperar.\e[0m'
                                exit;
                            else
                                 if [ -f "$rutaOriginalArchivo/$2" ]
                                then
                                    read -p "Ya existe un archivo con el mismo nombre en el directorio, en caso de recuperarlo se sobreescribira, esta seguro de recuperarlo?[y-N]" opcion && recuperar="${opcion}"
                                    if [ "$recuperar" = "y" ]
                                    then
                                        cd $homeUsuario
                                        tar -xf Papelera.tar.gz --wildcards "$2 - $fechaArchivo"
                                        tar --delete -f Papelera.tar.gz  "$2 - $fechaArchivo"
                                        mv "$2 - $fechaArchivo" "$2"
                                        if [ $rutaOriginalArchivo != "/$homeUsuario" ]
                                            then
                                            mv  "$2" $rutaOriginalArchivo
                                        fi
                                        echo "$(grep -v "$2 $rutaOriginalArchivo $fechaArchivo" $FICHERO_RUTAS)" > $FICHERO_RUTAS
                                    else
                                                exit;
                                    fi
                                else
                                 cd $homeUsuario
                                        tar -xf Papelera.tar.gz --wildcards "$2 - $fechaArchivo"
                                        tar --delete -f Papelera.tar.gz  "$2 - $fechaArchivo"
                                        mv "$2 - $fechaArchivo" "$2"
                                        if [ $rutaOriginalArchivo != "/$homeUsuario" ]
                                            then
                                            mv  "$2" $rutaOriginalArchivo
                                        fi
                                        echo "$(grep -v "$2 $rutaOriginalArchivo $fechaArchivo" $FICHERO_RUTAS)" > $FICHERO_RUTAS
                             
                                fi
                                # lo movemos a su ubicacion original y eliminamos del archivo de rutas.
                                
                        fi
                    else #en el caso que existan mas de 1 archivo con el mismo nombre a recuperar.
                        #mostramos el array con el formato solicitado.
                        for ((i = 0; i < ${#arrayArchivosARecuperar[@]}; ++i)); 
                        do
                            position=$(( $i + 1 ))
                            echo -e $position - $(echo ${arrayArchivosARecuperar[$i]} | rev | cut -d " " -f 7- | rev)
                        done
 
                        #preguntamos cual de todos es el que quiere restaurar.
                        declare numeroArchivo=0;
                        read -p $'\e[0;32m¿Qué archivo desea recuperar? : \e[0m' numeroArchivoARecuperar && numeroArchivo="${numeroArchivoARecuperar}"
                        while [[ numeroArchivo -le 0 || numeroArchivo -gt ${#arrayArchivosARecuperar[@]} ]]
                            do 
                                read -p $'\e[1;33mEl numero ingresado no es valido ¿Desea ingresar otro? [y/n] \e[0m: ' respuesta && [ "${respuesta}" != 'y' ] && exit
                                read -p $'\e[0;32m¿Qué archivo desea recuperar? : \e[0m' numeroArchivoARecuperar && numeroArchivo="${numeroArchivoARecuperar}"
                            done
 
                        #obtenemos la fila donde se encuentra el nombre y ruta original del archivo que eligio el usuario y seleccionamos solo la ruta.
                        declare rutaOriginalArchivo=$(echo ${arrayArchivosARecuperar[$(( $numeroArchivo - 1 ))]} | rev | cut -d " " -f 7 | rev)
                        declare fechaArchivo=$(echo ${arrayArchivosARecuperar[$(( $numeroArchivo - 1 ))]} | rev | cut -d " " -f -6 | rev)
 
                        #verificamos si el directorio original del archivo sigue existiendo.
                        if [ ! -d "$rutaOriginalArchivo" ]
                            then
                                echo $'\e[1;33mEl directorio original del archivo ya no existe.El archivo no se puede recuperar.\e[0m'
                                exit;
                            else
                              if [ -f "$rutaOriginalArchivo/$2" ]
                                then
                                    read -p "Ya existe un archivo con el mismo nombre en el directorio, en caso de recuperarlo se sobreescribira, esta seguro de recuperarlo?[y-N]" opcion && recuperar="${opcion}"
                                    if [ "$recuperar" = "y" ]
                                    then
                                        cd $homeUsuario
                                        tar -xf Papelera.tar.gz --wildcards "$2 - $fechaArchivo"
                                        tar --delete -f Papelera.tar.gz  "$2 - $fechaArchivo"
                                        mv "$2 - $fechaArchivo" "$2"
                                        if [ $rutaOriginalArchivo != "/$homeUsuario" ]
                                            then
                                            mv  "$2" $rutaOriginalArchivo
                                        fi
                                        echo "$(grep -v "$2 $rutaOriginalArchivo $fechaArchivo" $FICHERO_RUTAS)" > $FICHERO_RUTAS
                                    else
                                    exit;
                                    fi
                            else
                                        cd $homeUsuario
                                        tar -xf Papelera.tar.gz --wildcards "$2 - $fechaArchivo"
                                        tar --delete -f Papelera.tar.gz  "$2 - $fechaArchivo"
                                        mv "$2 - $fechaArchivo" "$2"
                                        if [ $rutaOriginalArchivo != "/$homeUsuario" ]
                                            then
                                            mv  "$2" $rutaOriginalArchivo
                                        fi
                                        echo "$(grep -v "$2 $rutaOriginalArchivo $fechaArchivo" $FICHERO_RUTAS)" > $FICHERO_RUTAS
                             
                            fi
                        fi
                    fi
 
            fi
 
 
            exit;
            ;;
        --eliminar)
 
            verificarRutaRelativaOAbsoluta "$2"
            if [ $? -eq 0 ]
                then
                        #siempre le concatenamos la fecha para evitar archivos con mismo nombre.
                        fechaCreacionArchivo=$(date -r "$rutaArchivo/$archivo")
 
                          if [ "$rutaArchivo" != "/$homeUsuario" ]
                            then
                                mv "$rutaArchivo/$archivo" $homeUsuario
                        fi
                        mv "/$homeUsuario/$archivo" "/$homeUsuario/$archivo - $fechaCreacionArchivo"
                        cd $homeUsuario
                        tar -rf "Papelera.tar.gz" "$archivo - $fechaCreacionArchivo"
                        rm "$archivo - $fechaCreacionArchivo";
                        #guardamos el nombre del archivo y la ruta original en el archivo.
                        echo "$archivo $rutaArchivo $fechaCreacionArchivo" >> $FICHERO_RUTAS
                else
                    echo $'\e[1;33mEl archivo que quiere eliminar no existe.\e[0m'
 
            fi
 
            exit;
            ;;
        -h | --help)
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "error"
            exit;
            ;;
    esac
done
 
#FIN ARCHIVO
