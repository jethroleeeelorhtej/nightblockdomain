#!/bin/bash
clear
readonly locate=$(dirname "$0")
readonly opApi='You API'
readonly now=`date +%Y%m%d_%H%M%S`
readonly day=`date +%Y%m%d`
var="Your directory"
log="Your Log directory"

vim $var/api_list.txt
echo -e "\E[1;5;33m 撈取全域名中．．． \E[0m "
curl -d "Your API參數" -s "${opApi}" > $var/PDNS_All_Domain.txt

for apiname in `cat $var/api_list.txt |awk '{print $1}'`; do
    aip_1=`cat $var/api_list.txt |grep -w $apiname |awk '{print $2}'`
    aip_2=`cat $var/api_list.txt |grep -w $apiname |awk '{print $3}'`
    suData="${locate}/data/${apiname}"
    suUrlData="${locate}/data/${apiname}_UrlData"
    suUrl="${locate}/data/${apiname}_Url"
    resLog="${locate}/log/${now}_${apiname}_res"
    errorLog="${locate}/log/${now}_${apiname}_error"

    # 存放資料目錄不存在則建立
    [ ! -d "${locate}/data/" ] && mkdir "${locate}/data/"
    [ ! -d "${locate}/log/" ] && mkdir "${locate}/log/"

    # 告警並離開
    function showErrorAndExit(){
        clear
        echo "${1}" > ${errorLog}
        echo -e "\E[1;5;31m \n程式終止： \E[0m "
        cat ${errorLog}
        echo ""
        exit
    }

    # 取得租網域名資訊
    cat $var/PDNS_All_Domain.txt |grep -w $apiname > $suUrlData
    cat $suUrlData |jq -r .domain_name > $suUrl

    # 整理租網域名
    for domain in `cat $suUrl`; do
    statusid=`cat $suUrlData |grep -w "\"domain_name\":\"$domain\"" |jq -r .status_id`
    noteid=`cat $suUrlData |grep -w "\"domain_name\":\"$domain\"" |jq -r .note_id`
    permission=`cat $suUrlData |grep -w "\"domain_name\":\"$domain\"" |jq -r .permission`
    aip=`cat $suUrlData |grep -w "\"domain_name\":\"$domain\"" |jq -r .aip`
    echo -ne "$domain \033[33m資料撈取完畢\033[0m\n"
    echo -ne "$apiname $domain $permission $statusid $noteid $aip \n" >> $log/domainall_${apiname}_${now}.txt
    done

    # 檢查狀態為D-移動封鎖的網址，是否有抗封鎖TAG
    echo -ne "\033[33mChecking是否要ON抗封鎖\033[0m \n"
    cat $log/domainall_${apiname}_${now}.txt |grep -v "廳主管" |grep -v "一對一" |grep -v "簡易版" |grep -w "D-移動封鎖" > $log/grep_${apiname}_${now}.txt

    for name in `cat $log/grep_${apiname}_${now}.txt |awk '{print $2}'`; do
        listcheck=`cat $log/grep_${apiname}_${now}.txt |grep -w $name |grep -w "抗封鎖"`
            if [[ -n "$listcheck" ]]; then
                echo -ne "$apiname $name \033[32m有ON抗封鎖\033[0m \n"
                echo -ne "$apiname $name \n" >> $log/listok_$now.txt
            else
                echo -ne "$apiname $name \033[31m沒有ON抗封鎖\033[0m\n"
                echo -ne "$apiname $name \n" >> $log/listerror_$now.txt
            fi
    done

    # 檢查有抗封鎖TAG的域名，@紀錄是否為抗封鎖IP
    cat $log/domainall_${apiname}_${now}.txt |grep -w "抗封鎖" > $log/grep2_${apiname}_${now}.txt
    for namee in `cat $log/grep2_${apiname}_${now}.txt |awk '{print $2}'`; do
        ipcheck=`cat $log/grep2_${apiname}_${now}.txt |grep -w $namee |awk '{print $6}'`
            if [[ "${ipcheck}" == "${aip_1}" ]] || [[ "${url}" == "${aip_2}" ]]; then
                echo -ne "$apiname $namee \033[32m有設定抗封鎖IP\033[0m \n"
                echo -ne "$apiname $namee \n" >> $log/ipok_$now.txt
            else
                echo -ne "$apiname $namee \033[31m沒有設定抗封鎖IP\033[0m\n"
                echo -ne "$apiname $namee \n" >> $log/iperror_$now.txt
            fi
    done
done

echo -ne "\n"
echo -ne "\n"
echo -ne "\033[33m檢查結束\033[0m \n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\033[33m↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓\033[0m     需ON上抗封鎖之網址   若無檔案代表無符合資料  \033[33m↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓\033[0m\n"
cat $log/listerror_$now.txt
echo -ne "\033[33m↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑\033[0m     需ON上抗封鎖之網址   若無檔案代表無符合資料  \033[33m↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑\033[0m\n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\033[33m↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓\033[0m     有ON上抗封鎖TAG，但@紀錄不是抗封鎖IP   若無檔案代表皆正常  \033[33m↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓\033[0m\n"
cat $log/iperror_$now.txt
echo -ne "\033[33m↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑\033[0m     有ON上抗封鎖TAG，但@紀錄不是抗封鎖IP   若無檔案代表皆正常  \033[33m↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑\033[0m\n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\n"
echo -ne "\033[33m==========\033[0m 需ON上抗封鎖之網址，檔案請查看 $log/listerror_$now.txt   若無檔案代表皆正常               \033[33m==========\033[0m\n"
echo -ne "\033[33m==========\033[0m 有ON上抗封鎖TAG，但@紀錄不是抗封鎖IP，檔案請查看 $log/iperror_$now.txt 若無檔案代表皆正常 \033[33m==========\033[0m\n"

