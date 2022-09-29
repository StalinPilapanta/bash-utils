#! /bin/bash

function unsetawsenv() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}
function loginaccount(){
    #! /bin/bash
    accountrole="$@"
    #Environment Variables set
    set +x
    #AWS LOGIN - CHILDACCONT
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    #910122598348
    #arn:aws:iam::910122598348:role/DevOpsRole
    #aws_credentials_json=$(aws sts assume-role --role-arn arn:aws:iam::001734306234:role/DevOpsRole --role-session-name DevOps-CrossAccountSession --region us-east-1)
    #aws_credentials_json=$(aws sts assume-role --role-arn arn:aws:iam::703085461864:role/DevOpsRole --role-session-name DevOps-CrossAccountSession --region us-east-1)
    #aws_credentials_json=$(aws sts assume-role --role-arn arn:aws:iam::401326641090:role/DevOpsRole --role-session-name DevOps-CrossAccountSession --region us-east-1)
    #aws_credentials_json=$(aws sts assume-role --role-arn arn:aws:iam::910122598348:role/DevOpsRole --role-session-name DevOps-CrossAccountSession --region us-east-1)
    aws_credentials_json=$(aws sts assume-role --role-arn $accountrole --role-session-name DevOps-CrossAccountSession --region us-east-1)
            if [ "$aws_credentials_json" == "" ]; then

            echo -e "\n###############################################################################################################"
            echo "Unable to assume AWS permissions for this operation. Validate the following:"
            echo "- Check any typo in this structure:    (User remediation)"
            echo "  {$accountrole}   ".
            echo "- Make sure you have set AWS Crossaccount permissions. (Administrators)"
            echo -e "#################################################################################################################\n"
            # exit 1
            else
 
            export AWS_ACCESS_KEY_ID=$(echo "$aws_credentials_json" | jq --exit-status --raw-output .Credentials.AccessKeyId)
            export AWS_SECRET_ACCESS_KEY=$(echo "$aws_credentials_json" | jq --exit-status --raw-output .Credentials.SecretAccessKey)
            export AWS_SESSION_TOKEN=$(echo "$aws_credentials_json" | jq --exit-status --raw-output .Credentials.SessionToken)
            #Get the current account Alias.
            AccountAlias=$(aws iam list-account-aliases --region $AWSREGION | jq .AccountAliases[] --raw-output)

            fi    
}

#ENV SET
#AWS region
while [ "$AWSREGION" == "" ]; do
    AWSREGION=us-east-1
done

#ALL AWS ORG Accouns
export dtvlaweb="910122598348" # ORGANIZATION ACCOUNT DTVLAWEB
export regionalopsmaster="648412842827" # ORGANIZATION ACCOUNT REGIONAL OPS
export engineeringmaster="544285083990" #ORGANIZATION ACCOUNT ENGINEERING MASTER
export dtvlamaster="737349677596" #ORGANIZATION ACCOUNT DTVLA MASTER
export ottmaster="783452324098"  #ORGANIZATION ACCOUNT OTT MASTER
export orgaccounts=("$dtvlaweb" "$ottmaster" "$regionalopsmaster" "$engineeringmaster" "$dtvlamaster")
#export orgaccounts=("$ottmaster")
#export orgaccounts=("$dtvlaweb")

################# LOG INTO EVERY ORG ACC AND PUT ALTERNATE CONTACTS ON their Child Accounts ##############

len=${#orgaccounts[@]}
for (( i=0; i<$len; i++ )); do
    
    loginaccount "arn:aws:iam::${orgaccounts[$i]}:role/DevOpsRole"
    echo -e "Processing Master Organization $AccountAlias ${orgaccounts[$i]}"

    
    accounts=$(aws organizations list-accounts --region us-east-1 | jq -r .Accounts[].Id)
    

    #echo "$AccountAlias" > ./$AccountAlias.txt
    #aws sts get-caller-identity | jq -rc '.Account' >> ./$AccountAlias.txt

    for acc in `echo $accounts`; do  

    loginaccount "arn:aws:iam::$acc:role/DevOpsRole"
    echo -e "------------------------------ Bucket in Account $AccountAlias ------------------------------" 
    export AWS_PROFILE=default

    aws iam list-account-aliases | jq -r '.AccountAliases[]' >> ./$AccountAlias.txt
    aws sts get-caller-identity | jq -rc '.Account' >> ./$AccountAlias.txt

#    aws apigateway get-domain-names | jq -r '.items | map([.domainName, .distributionDomainName, .regionalDomainName], .endpointConfiguration.types | join(", ")) | join("\n")' >> ./$AccountAlias.txt

        aws s3 ls | cut -d " " -f3 >> ./$AccountAlias.txt
        archivo=$AccountAlias.txt
        while IFS= read -r linea
        do
            echo "$linea"
            bucket=$(echo "$linea")

            echo "$linea" >> ./$AccountAlias-evidence.txt
            aws s3api get-public-access-block --bucket $linea >> ./$AccountAlias-evidence.txt

            if aws s3api get-public-access-block --bucket $linea; then
             state=$(aws s3api get-public-access-block --bucket $bucket | jq '.[]| .BlockPublicAcls')
             echo $state
             if test $state = 'false'; then 
                echo "Es falso"
                echo "------------------------------------------- "                   
                echo "-------- Bucket PUBLICO with False -------- "                 
                echo "-------- Bucket $bucket "                     
                echo "------------------------------------------- "                 
                echo "PUBLICO,     $bucket " >> ./$AccountAlias-report.txt
             else 
                echo "no es Falso"
                echo "------------------------------------------- "
                echo "-------- Bucket PRIVADO ------------------- "
                echo "-------- $bucket "                           
                echo "------------------------------------------- "
                echo "PRIVADO,     $bucket" >> ./$AccountAlias-report.txt
             fi
            else 
              
                echo "------------------------------------------- "
                echo "-------- Bucket PUBLICO unless False ------ "
                echo "-------- Bucket $bucket "                    
                echo "------------------------------------------- "
                echo "PUBLICO,     $bucket " >> ./$AccountAlias-report.txt
            fi

        done < "$archivo"
    done
done
unsetawsenv

#if [ "$failure" != "" ]; then
#echo -e "ISSUES: \n$failure"
#fi
