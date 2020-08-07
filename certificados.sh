#======================================================================================================================
#=============================================LEIA COM ATENCAO=========================================================
# Configuracoes do(s) certificados auto assinado(s)
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Antes de tudo, parem o(s) produto(s)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Necessário:
# Opennsl e JDK >= 1.8 instalados
# JAVA_HOME 
# Crie diretórios com onome do dominio da qual pretende gerar os certificados, Ex:
# www.api.newbare.com.br mkdir api.newbare.com.br
# copie os arquivos client-truststore.jks e wso2carbon.jks para os respectivos diretórios, Ex:
# cd api.newbare.com.br
# cp <API_HOME>/repository/resource/security/client-truststore.jks .
# cp <API_HOME>/repository/resource/security/wso2carbon.jks .
#=====================================================================================================================
JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_172.jdk/Contents/Home"
STORE_PASS="wso2carbon" #keystore/senha do truststore  (armazenamento confiável do cliente)
VALIDITY="3650"		      #validade do certificado
OU="Services" 		      #Unidade Organizacional
O="My Company" 	      #Nome da Organização
L="Colombo" 		        #Localizacao ou cidade
S="Western" 		        #Estado
C="LK" 			            #Código do país com duas letras ex.: BR
#=======================================================================================================================
#=======================================================================================================================
#=======================================================================================================================
echo $JAVA_HOME
echo "\n\nLendo subdiretórios para extrair nomes de domínio ...."
DOMAIN_ARRAY=()
#leia os nomes das subpastas e adicione a uma matriz
for d in ../*; do
  if [ -d "$d" ]; then
 	DOMAIN=`echo $d | sed 's/\..\///g'`
   echo $DOMAIN
	DOMAIN_ARRAY+=($DOMAIN)
  fi
done

echo "\n\nLinhas do Array\n"
echo ${#DOMAIN_ARRAY[@]:1}


for domain in "${DOMAIN_ARRAY[@]}"
do  
  echo "${var}"
 ##DELATANDO ALIAS wso2carbon de ambos os certificados.
  $JAVA_HOME/bin/keytool -delete -trustcacerts -alias wso2carbon -keystore client-truststore.jks -storepass $STORE_PASS
  $JAVA_HOME/bin/keytool -delete -trustcacerts -alias wso2carbon -keystore wso2carbon.jks -storepass $STORE_PASS
##Criando certificado
  openssl req -x509 -newkey rsa:4096 -sha256 -keyout certificado.key -out certificado.crt -subj "/CN=$domain" -days 3650 -passin env:$STORE_PASS
  openssl pkcs12 -export -in certificado.crt -inkey certificado.key -name "certificado" -certfile certificado.crt -out certificado.pfx -passin env:$STORE_PASS #-password pass:$STORE_PASS
##Importe o PFX para o wso2carbon.jks
  $JAVA_HOME/bin/keytool -importkeystore -srckeystore certificado.pfx -srcstoretype pkcs12 -destkeystore wso2carbon.jks -deststoretype JKS -storepass $STORE_PASS
##Verifique se o certficado foi importado
  $JAVA_HOME/bin/keytool -v -list -keystore wso2carbon.jks -alias certificado -storepass $STORE_PASS
##Modifique o alias de certificado para wso2carbon  
  $JAVA_HOME/bin/keytool -changealias -alias certificado -destalias wso2carbon -keypass wso2carbon -keystore wso2carbon.jks  -storepass $STORE_PASS

#Importe o arquivo certificado.pem para wso2carbon.jks e client-truststore.jks
  for trustoredomain in "${DOMAIN_ARRAY[@]}"
  do
    echo "Importing $domain public cert to $trustoredomain client truststore"
     $JAVA_HOME/bin/keytool -export -alias wso2carbon -keystore wso2carbon.jks -file certificado.pem  -storepass $STORE_PASS
     $JAVA_HOME/bin/keytool -import -alias wso2carbon -file certificado.pem -keystore client-truststore.jks   -storepass $STORE_PASS
    done
done

echo "\n\n Certificado(s) Gerado(s)!!!"
echo "Agora copie os certificados no diretorio security\n"
echo "Inicie o(s) produto(s)\n"
