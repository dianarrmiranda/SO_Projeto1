#!/bin/bash

PID=$(ps -a -o pid | grep -v PID); #Vai buscar os valores dos PIDs dos processos em execução
arrPID=(); #array vazio

COMM=$(ps -a -o comm | grep -v COMMAND); #Vai buscar o COMM dos processos em execução
arrCOMM=(); #array vazio

USER=$(ps -o user | grep -v USER); #Vai buscar os users dos processos em execução
arrUSER=(); #array vazio

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

#Print do cabeçalho da tabela
printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE";

#Sobre o for abaixo: 
#Vai para cada PID buscar os valores do rchar e do wchar
#a parte da data está mal
#não sei o que é suposto colocar no rater e no rateW

for (( i=0; i<${#arrPID[@]}; i++ ))
do
   #só dá print se o ficheiro existir
   if [ -f /proc/${arrPID[$i]}/io ]; then
      READB=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
      WRITEB=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');
      DATE=$(date);
      printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s \n" "${arrCOMM[$i]}" "${arrUSER[$i]}" "${arrPID[$i]}" "$READB" "$WRITEB" "rater" "rateW" "$DATE";
   fi
done




