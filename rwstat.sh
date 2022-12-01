#!/bin/bash
#Declarar as variáveis
declare -A final_info=()

export LANG=pt_BR.utf8;

arrPID=(); #array vazio
arrCOMM=(); #array vazio
arrUSER=() #array vazio
arrREAD1=() #array vazio
arrWRITE1=() #array vazio

#Opções disponíveis
help() {
    echo "------------------------------------------------------------------------------------------------"
    echo "| OPÇÕES DISPONÍVEIS!                                                                           |"                                                                                               
    echo "|                                                                                               |"
    echo "| Opções de visualização:                                                                       |"
    echo "|   -c    : Selecionar os processos a visualizar através de uma expressão regular               |"
    echo "|   -s    : Definir data mínima de criação dos processos a visualizar                           |" 
    echo "|   -e    : Definir data máxima de criação dos processos a visualizar                           |"
    echo "|   -u    : Visualizar os processos de um determinado utilizador                                |"
    echo "|   -m    : Definir o PID mínimo dos processos a visualizar                                     |" 
    echo "|   -M    : Definir o PID máximo dos processos a visualizar                                     |"
    echo "|   -p    : Definir o número de processos a visualizar                                          |"
    echo "|                                                                                               |" 
    echo "| Opções de ordenação:                                                                          |"
    echo "|   -r    : Ordem reversa (crescente)                                                           |"
    echo "|   -w    : Ordenar pelo RATEW (descrescente)                                                   |"
    echo "|    A ordenação default é pelo RATER de forma decrescente.                                     |"
    echo "|                                                                                               |"
    echo "| O último argumento tem de corresponder sempre ao número de segundos que pretende analisar.    |"
    echo "------------------------------------------------------------------------------------------------"
    exit 1
}


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
nprocessos="${#arrPID[@]}"; # número de processos existentes (é a length do array)
colOrdena=6; #coluna que vai ser ordenada
procName=(.*); #nome do processo
userName=(.*); #nome do utilizador
minPid=0; #PID minimo
minPidFinal=(.*); #PID minimo final
maxPid=0; #PID maximo
maxPidFinal=(.*); #PID máximo final
sortmethod=(sort -k $colOrdena -n -r) # inicaliza o sort para ordenar por ordem decresecente de RATER. Depois, no swtich case, esta variável é atualizada
minDate=0; #Data mínima
maxDate=0; #Data máxima
minDateFinal=(.*);
maxDateFinal=(.*); #Data máxima final

if ! [[ ${@: -1} =~ ^[0-9]+$ ]]; then #Verifica se o último argumento é um número
   echo "ERRO: O último argumento tem de ser um número!"
   help
fi

# iniciei para ser uma variavel local se quisermos depois passar isto para dentro de uma função
while getopts "c:u:m:M:s:e:rwp:" opt; do
   case $opt in
   c) procName=$OPTARG
      if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      elif [[ $procName =~ ^([0-9]+)$ ]]; then
         echo "ERRO: A opção -c requere um argumento ou um argumento diferente de um número"
         help
      fi
      ;;
   u) if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      elif [[ $OPTARG =~ ^[0-9]*$ ]]; then 
         echo "A opção -u requere um argumento ou um que não seja um número"
      fi
      userName=$OPTARG;;
   m) minPid=$OPTARG
      if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      fi
      minPidFinal=(^[0-9]*$)
      if  [[ ! $minPid =~ ^([0-9]+)$ ]] || [[ $minPid -eq ${@: -1} ]]; then # se o minPidFinal não for um número inteiro, ou se for o valor passado como sleep, então dá erro e vai para a ajuda
         echo "ERRO: o número mínimo do ID do processo a visualizar tem de ser um inteiro positivo, e este não pode ser o valor passado como tempo de sleep." 
         help
     fi;;
   M) maxPid=$OPTARG
      if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      fi
      maxPidFinal=(^[0-9]*$)
      if [[ ! $maxPid =~ ^([0-9]+)$ ]] || [[ $maxPid -eq ${@: -1} ]]; then # se o maxPidFinal não for um número inteiro, então dá erro e vai para a ajuda 
         echo "ERRO: o número máximo do ID do processo a visualizar tem de ser um inteiro positivo, e este não pode ser o valor passado como tempo de sleep." 
         help
     fi;;
   s) minDate=$OPTARG
      minDateFinal=(^[A-Z]*$)
      if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      elif [[ "${#OPTARG}" -ne 12 ]]; then #para ser uma data válida, tem de ter 12 caracteres a contar com os espaços 
         echo "ERRO: a data mínima tem de ter 12 carateres (os espaços também contam)"
         help
      fi;;
   e) maxDate=$OPTARG
      maxDateFinal=(^[A-Z]*$)
      if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      elif [[ "${#OPTARG}" -ne 12 ]]; then #para ser uma data válida, tem de ter 12 caracteres a contar com os espaços 
         echo "ERRO: o número máximo do ID do processo a visualizar tem de ser um inteiro positivo, e este não pode ser o valor passado como tempo de sleep."
         help
      fi;;
      #acrescentar REGEX para validar a data
   r) sortmethod=(sort -k $colOrdena -n);;
   w) colOrdena=7;
      sortmethod=(sort -k $colOrdena -n -r);;
   p) nprocessos=$OPTARG
      if [[ ${OPTARG:0:1} == "-" ]]; then # todos os comandos têm de começar por -
         echo "ERRO: está a passar como argumento outro comando!"
         help
      elif [[ ! $maxPid =~ ^([0-9]+)$ ]] || [[ $maxPid -eq ${@: -1} ]]; then # se o nprocessos não for um número inteiro, ou for o valor passado no sleep então dá erro e vai para a ajuda
         echo "ERRO: o número de processos a visualizar tem de ser um inteiro positivo." 
         help
     fi
      ;;
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

         if [[ -v $procName==c && ! $COMM =~ $procName ]]; then # se o nome do processo não corresponder à condição regex passada como argumento, ignora
            continue
         fi

         if [[ -v $userName==u && ! $USER =~ $userName ]]; then # se o nome do utilizador não corresponder à condição regex passada como argumento, ignora
            continue
         fi
         
         if [[ ${arrPID[$i]} -ge $minPid ]]; then 
            minPidFinal=$(echo $minPidFinal'|'${arrPID[$i]}) #Concatena uma string com os PID para depois fazer o grep
         fi  
         if [[ ${arrPID[$i]} -le $maxPid ]]; then 
            maxPidFinal=$(echo $maxPidFinal'|'${arrPID[$i]})
         fi

         READB2=$(cat /proc/${arrPID[$i]}/io | grep rchar | awk '{print $2}');
         WRITEB2=$(cat /proc/${arrPID[$i]}/io | grep wchar | awk '{print $2}');
         LSTART=${arrLSTART[$i]};

         DATE=$(date -d "$LSTART" +"%b %d %H:%M" | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1'); #O awk é para colocar a primeira letra do Mẽs maiúscula!
         DATE_Segundos=$(date -d "$DATE" +"%b %d %H:%M"+%s | awk -F '[+]' '{print $2}') # data do processo em segundos
 
         inicio=$(date -d "$minDate" +"%b %d %H:%M"+%s | awk -F '[+]' '{print $2}') # dá erro se não cumprir o formato da data

         if [[ $DATE_Segundos -ge $inicio ]]; then 
            minDateFinal=$(echo "$minDateFinal"'|'"$DATE") #Concatena uma string com os PID para depois fazer o grep
         fi  

         fim=$(date -d "$maxDate" +"%b %d %H:%M"+%s | awk -F '[+]' '{print $2}')

         if [[ $DATE_Segundos -le $fim ]]; then 
            maxDateFinal=$(echo "$maxDateFinal"'|'"$DATE") #Concatena uma string com os PID para depois fazer o grep
         fi  

         READB=$(echo "($READB2 - ${arrREAD1[$i]})" | bc);
         WRITEB=$(echo "($WRITEB2 - ${arrWRITE1[$i]})" | bc);
         RATER=$(echo "scale=2; $READB/${@: -1}" | bc);
         RATEW=$(echo "scale=2; $WRITEB/${@: -1}" | bc);

         
         final_info[${arrPID[$i]}]=$(printf "%-20s %-12s %-12s %-12s %-12s %-12s %-12s %-12s" "${arrCOMM[$i]}" "${arrUSER[$i]}" "${arrPID[$i]}" "$READB" "$WRITEB" "$RATER" "$RATEW" "$DATE");
      fi
done

printf "%s\n" "${final_info[@]}" | "${sortmethod[@]}" | awk -v pat="^$userName$" '$2 ~ pat' | awk -v pat=$procName '$1 ~ pat' | grep -E $minPidFinal | grep -E $maxPidFinal | grep -E "$minDateFinal" | grep -E "$maxDateFinal" | head -n $nprocessos # -n a seguir ao head é para limitar o número de linhas

#User march - 
#the ^ stands for the start of the string: nothing can be before the pattern
#the $ stands for the end of the string: nothing can be after

# para o -c mostrar o processos a começar na letra passada, fazemos--> ^ means "the beginning of the annotation", e.g. "^ng" will match "ngabi" but not "bukung"?