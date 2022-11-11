#!/bin/bash

#A tabela em príncipio ja está correta
#Falta só fazer as condiçoes de entrada que estão no guião

PID=$(ps -o pid | grep -v PID); #Vai buscar os valores dos PIDs dos processos em execução
arrPID=(); #array vazio

COMM=$(ps -o comm | grep -v COMMAND); #Vai buscar o COMM dos processos em execução
arrCOMM=(); #array vazio

USER=$(ps -o user | grep -v USER); #Vai buscar os users dos processos em execução

LSTART=$(ps -o lstart | grep -v STARTED); #Vai buscar a data de inicio dos processos em execução
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


#Print do cabeçalho da tabela
printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE";

for (( i=0; i<${#arrPID[@]}; i++ ))
   do
     #só dá print se o ficheiro existir
      if [ -f /proc/${arrPID[$i]}/io ]; then
          #Vai para cada PID buscar os valores do rchar e do wchar
         arrREAD1[$i]=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
         arrWRITE1[$i]=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');


      fi
done

sleep $1


for (( i=0; i<${#arrPID[@]}; i++ ))
   do
     #só dá print se o diretório existir existir
      if [ -f /proc/${arrPID[$i]}/io ]; then
         READB2=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
         WRITEB2=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');
         LSTART=${arrLSTART[$i]};
         DATE=$(date -d "$LSTART" +"%b %d %H:%M");
         READB=$(echo "($READB2 - ${arrREAD1[$i]})" | bc);
         WRITEB=$(echo "($WRITEB2 - ${arrWRITE1[$i]})" | bc);
         RATER=$(echo "scale=2; $READB/$1" | bc);
         RATEW=$(echo "scale=2; $WRITEB/$1" | bc);
         
         printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s \n" "${arrCOMM[$i]}" "${arrUSER[$i]}" "${arrPID[$i]}" "$READB" "$WRITEB" "$RATER" "$RATEW" "$DATE";
      fi
done