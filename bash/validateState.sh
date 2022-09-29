#!/bin/bash

aws s3 ls | cut -d " " -f3 >> lista.txt
archivo="lista.txt"
while IFS= read -r linea
do
  echo "$linea"
  bucket=$(echo "$linea")
  if aws s3api get-public-access-block --bucket $linea; then
   state=$(aws s3api get-public-access-block --bucket $bucket | jq '.[]| .BlockPublicAcls')
   echo $state
   if test $state = 'false'; then 
      echo "Es falso"
      echo "------------------------------------------- "
      echo "-------- Bucket PUBLICO with False -------- "
      echo "-------- Bucket $bucket "
      echo "------------------------------------------- "
      echo "PUBLICO,     $bucket " >> report.txt
   else 
      echo "no es Falso"
      echo "------------------------------------------- "
      echo "-------- Bucket PRIVADO ------------------- "
      echo "-------- $bucket "
      echo "------------------------------------------- "
      echo "PRIVADO,     $bucket" >> report.txt
   fi
  else 
    
      echo "------------------------------------------- "
      echo "-------- Bucket PUBLICO unless False ------ "
      echo "-------- Bucket $bucket "
      echo "------------------------------------------- "
      echo "PUBLICO,     $bucket " >> report.txt
  fi

done < "$archivo"