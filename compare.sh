#!/bin/bash

#Carregar configurações
source ./config.sh

MYSQL_BIN_EXISTS=$(which mysql)
if [ "$MYSQL_BIN_EXISTS" == '' ] 
then
	echo
	echo "É necessário ter instalado mysql-client e mysql"
	echo
fi

output_table1=$(mysql -u$DATABASE1_USER -p$DATABASE1_PASS -h$DATABASE1_HOST -P$DATABASE1_PORT $DATABASE1_DATABASE -e "SELECT table_name FROM information_schema.tables WHERE table_schema = '$DATABASE1_DATABASE' AND table_type != 'VIEW';")
ALL_TABLES1=(${output_table1//,/ })

output_table2=$(mysql -u$DATABASE2_USER -p$DATABASE2_PASS -h$DATABASE2_HOST -P$DATABASE2_PORT $DATABASE2_DATABASE -e "SELECT table_name FROM information_schema.tables WHERE table_schema = '$DATABASE2_DATABASE' AND table_type != 'VIEW';")
ALL_TABLES2=(${output_table2//,/ })

rm -rf $DATABASE1_DATABASE
rm -rf $DATABASE2_DATABASE

mkdir -p $DATABASE1_DATABASE
for table in "${ALL_TABLES1[@]}"
do
	echo "database1 ${table} exportado"
	mysql -u$DATABASE1_USER -p$DATABASE1_PASS -h$DATABASE1_HOST -P$DATABASE1_PORT $DATABASE1_DATABASE -e "show create table ${table}\G" > "$DATABASE1_DATABASE/${table}.table" 2>/dev/null
	cat "$DATABASE1_DATABASE/${table}.table" | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' > "$DATABASE1_DATABASE/${table}"
	rm "$DATABASE1_DATABASE/${table}.table"
done

mkdir -p $DATABASE2_DATABASE
for table in "${ALL_TABLES2[@]}"
do
	echo "database2 ${table} exportado"
        mysql -u$DATABASE2_USER -p$DATABASE2_PASS -h$DATABASE2_HOST -P$DATABASE2_PORT $DATABASE2_DATABASE -e "show create table ${table}\G" > "$DATABASE2_DATABASE/${table}.table" 2>/dev/null
	cat "$DATABASE2_DATABASE/${table}.table" | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' > "$DATABASE2_DATABASE/${table}"
	rm "$DATABASE2_DATABASE/${table}.table"
done

find $DATABASE1_DATABASE -size  0 -print0 |xargs -0 rm --
find $DATABASE2_DATABASE -size  0 -print0 |xargs -0 rm --

diff -qr $DATABASE1_DATABASE $DATABASE2_DATABASE | grep -v "Somente em $DATABASE1_DATABASE:" | sort > c.txt

COUNT_DIFF1=$(diff -qr $DATABASE1_DATABASE $DATABASE2_DATABASE | grep "Somente em $DATABASE1_DATABASE:" | sort | wc -l)
COUNT_DIFF2=$(diff -qr $DATABASE1_DATABASE $DATABASE2_DATABASE | grep "Somente em $DATABASE2_DATABASE:" | sort | wc -l)
cc1=$(ls $DATABASE1_DATABASE -1 | wc -l)
cc2=$(ls $DATABASE2_DATABASE -1 | wc -l)
COUNT_SOMENTE1=`expr $cc2 - $cc1`


echo
echo "$cc1 tabelas em $DATABASE1_DATABASE"
echo "$cc2 tabelas em $DATABASE2_DATABASE"
echo
diff -qr $DATABASE1_DATABASE $DATABASE2_DATABASE | grep "Somente em $DATABASE1_DATABASE:" | sort 
echo "$COUNT_DIFF1 tabelas em $DATABASE1_DATABASE não presentes em $DATABASE2_DATABASE"
echo
echo
diff -qr $DATABASE1_DATABASE $DATABASE2_DATABASE | grep "Somente em $DATABASE2_DATABASE:" | sort
echo "$COUNT_DIFF2 tabelas em $DATABASE2_DATABASE não presentes em $DATABASE1_DATABASE"
echo

/usr/bin/diff -r "$DATABASE1_DATABASE" "$DATABASE2_DATABASE"
