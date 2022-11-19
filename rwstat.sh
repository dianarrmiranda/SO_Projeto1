#!/bin/bash

#Declarar as variáveis
declare -A final_info=()
arrPID=(); #array vazio
arrCOMM=(); #array vazio
arrUSER=() #array vazio
arrREAD1=() #array vazio
arrWRITE1=() #array vazio

#Buscar as informações necessárias
PID=$(ps -e -o pid | grep -v PID); #Vai buscar os valores dos PIDs dos processos em execução
COMM=$(ps -e -o comm | grep -v COMMAND); #Vai buscar o COMM dos processos em execução
USER=$(ps -e -o user | grep -v USER); #Vai buscar os users dos processos em execução
LSTART=$(ps -e -o lstart | grep -v STARTED); #Vai buscar a data de inicio dos processos em execução

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

#Inicio das variaveis
nprocessos="${#arrPID[@]}"; # número de processos existentes. É a length do array do 
procName=(.*); #nome do processo
userName=(.*); #nome do utilizador
minPid=0; #PID minimo
minPidFinal=(.*); #PID minimo final
maxPid=0; #PID maximo
maxPidFinal=(.*); #PID máximo final
sortmethod=(sort -k 6 -n -r) # inicaliza o sort para ordenar por ordem decresecente de RATER. Depois, no swtich case, esta variável é atualizada

# iniciei para ser uma variavel local se quisermos depois passar isto para dentro de uma função
while getopts "c:u:m:M:rwp:" opt; do
   case $opt in
   c) procName=$OPTARG;;
   u) userName=$OPTARG;;
   m) minPid=$OPTARG
      minPidFinal=(^[0-9]*$);;
   M) maxPid=$OPTARG
      maxPidFinal=(^[0-9]*$);;
   r) sortmethod=(sort -k 7 -n);;
   w) sortmethod=(sort -k 7 -n -r);;
   p) nprocessos=$OPTARG;; # set nprocessos to value passed as argument in OPTARG
   ?) help;; 
   esac
done

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

for (( i=0; i <= ${#arrPID[@]}; i++ ))
   do
      #Verifica se tem permissões de leitura, se não tiver ignora
      if [ -r /proc/${arrPID[$i]}/io ]; then

         #-v, --invert-match: selecione as linhas que não correspondem aos critérios de pesquisa

         if [[ -v $opt==c && ! $COMM =~ $procName ]]; then # se o nome do processo não corresponder à condição regex passada como argumento, ignora
            continue
         fi

         if [[ -v $opt==u && ! $USER =~ $userName ]]; then # se o nome do utilizador não corresponder à condição regex passada como argumento, ignora
            continue
         fi

         if [[ ${arrPID[$i]} -ge $minPid ]]; then 
            minPidFinal=$(echo $minPidFinal'|'${arrPID[$i]}) #Concatena uma string com os PID para depois fazer o grep
         fi  

         if [[ ${arrPID[$i]} -lt $maxPid ]]; then 
            maxPidFinal=$(echo $maxPidFinal'|'${arrPID[$i]})
         fi

         READB2=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
         WRITEB2=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');
         LSTART=${arrLSTART[$i]};
         DATE=$(date -d "$LSTART" +"%b %d %H:%M" | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1'); #O awk é para colocar a primeira letra do Mẽs maiúscula!
         READB=$(echo "($READB2 - ${arrREAD1[$i]})" | bc);
         WRITEB=$(echo "($WRITEB2 - ${arrWRITE1[$i]})" | bc);
         RATER=$(echo "scale=2; $READB/${@: -1}" | bc);
         RATEW=$(echo "scale=2; $WRITEB/${@: -1}" | bc);

         
         final_info[${arrPID[$i]}]=$(printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s" "${arrCOMM[$i]}" "${arrUSER[$i]}" "${arrPID[$i]}" "$READB" "$WRITEB" "$RATER" "$RATEW" "$DATE");
      fi
done

printf "%s\n" "${final_info[@]}" | "${sortmethod[@]}" | grep $procName | grep $userName | grep -E $minPidFinal | grep -E $maxPidFinal | head -n $nprocessos 


