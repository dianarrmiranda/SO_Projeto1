#!/bin/bash

declare -A final_info=()

#A tabela em príncipio ja está correta
#Falta só fazer as condiçoes de entrada que estão no guião

PID=$(ps -e -o pid | grep -v PID); #Vai buscar os valores dos PIDs dos processos em execução
arrPID=(); #array vazio

COMM=$(ps -e -o comm | grep -v COMMAND); #Vai buscar o COMM dos processos em execução
arrCOMM=(); #array vazio

USER=$(ps -e -o user | grep -v USER); #Vai buscar os users dos processos em execução

LSTART=$(ps -e -o lstart | grep -v STARTED); #Vai buscar a data de inicio dos processos em execução
arrUSER=(); #array vazio
arrREAD1=(); #array vazio
arrWRITE1=(); #array vazio

#Cria o array com os PIDs
while read line 
do
   [[ "$line" != '' ]] && arrPID+=("$line")
done <<< "$PID"

#Cria o array com os COMM
while read line
do
   [[ "$line" != '' ]] && arrCOMM+=("$line")
done <<< "$COMM"

#Cria o array com os Users
while read line
do
   [[ "$line" != '' ]] && arrUSER+=("$line")
done <<< "$USER"

#Cria o array com as datas de inicio
while read line
do
   [[ "$line" != '' ]] && arrLSTART+=("$line")
done <<< "$LSTART"
nprocessos="${#arrPID[@]}"; # número de processos existentes. É a length do array do PID

w=0 # incializa a flag do w para não dar erro se não for passado nenhum w como argumento

#Print do cabeçalho da tabela
printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE";

for (( i=0; i<${#arrPID[@]}; i++ ))
   do
     #só dá print se o ficheiro existir
      if [ -r /proc/${arrPID[$i]}/io  ]; then
          #Vai para cada PID buscar os valores do rchar e do wchar
         arrREAD1[$i]=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
         arrWRITE1[$i]=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');
      fi
done

sleep ${@: -1} # argumento do tempo. É sempre o ultimo a ser passado independentemente do nº de argumentos

# iniciei para ser uma variavel local se quisermos depois passar isto para dentro de uma função
while getopts "rwp:" opt; do
   case $opt in
   r) r=1;;
   w) w=1;;
   p) nprocessos="${OPTARG}";; # set nprocessos to value passed as argument in OPTARG
   ?) help;; 
   esac
done

for (( i=0; i <= ${#arrPID[@]}; i++ ))
   do
   #echo "bacalhoa $j";
   #echo ${#arrPID[@]};
      #Verifica se tem permissões de leitura, se não tiver ignora
      if [ -r /proc/${arrPID[$i]}/io ]; then
         READB2=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
         WRITEB2=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');
         LSTART=${arrLSTART[$i]};
         #echo "já lasca $nprocessos";
         DATE=$(date -d "$LSTART" +"%b %d %H:%M" | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1'); #O awk é para colocar a primeira letra do Mẽs maiúscula!
         READB=$(echo "($READB2 - ${arrREAD1[$i]})" | bc);
         WRITEB=$(echo "($WRITEB2 - ${arrWRITE1[$i]})" | bc);
         RATER=$(echo "scale=2; $READB/${@: -1}" | bc);
         RATEW=$(echo "scale=2; $WRITEB/${@: -1}" | bc);
         
         final_info[${arrPID[$i]}]=$(printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s" "${arrCOMM[$i]}" "${arrUSER[$i]}" "${arrPID[$i]}" "$READB" "$WRITEB" "$RATER" "$RATEW" "$DATE");
      fi
done

#final_infoSorted=$(echo $final_info[${arrPID[$@]}] | sort -k 6 -n -r);
#echo ${#final_infoSorted[@]}
if [ $w -eq 1 ]; then
   if [ $r -eq 1 ]; then
      printf "%s\n" "${final_info[@]}" | sort -k 7 -n # ordena por RATEW em ordem crescente funciona
   else
      printf "%s\n" "${final_info[@]}" | sort -k 7 -n -r # ordena por RATEW em forma reversa funciona
   fi
else
   COMO='printf "%s\n" "${final_info[@]}" | sort -k 6 -n -r' # ordena por RATER em forma reversa funciona, Como dar manter o que damos print numa varivavel?
   echo $COMO
   for (( i=0; i <= $nprocessos; i++ ))
   do
      printf "%s\n" "${COMO[i]}"
   done
fi