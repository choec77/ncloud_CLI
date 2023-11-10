#!/bin/bash

## ncloud 파일 경로로 수정
ncloud='/CLI_1.1.16_20230822/cli_linux/ncloud '

## 변수 선언
regionCode=''
vpcName=''
ipv4CidrBlock=''
vpcNo=''
networkAclName=''
regionCode=''
subnetName=''
subnet=''
networkAclNo=''
subnetTypeCode=''


## VPC 생성 스크립트
clear
echo -e "\t\t------VPC 생성 프로그램------"
echo

# 선택 가능한 Region 리스트
while [[ -z "$regionCode" ]]; do
  echo -e " VPC를 생성 할 Region을 아래에서 선택하세요:"
  echo -e "\t1. KR"
  echo -e "\t2. JP"
  echo -e "\t3. US"
  echo -e "\t4. SG"
  read -p " 선택[1-4]: " selection2

  case $selection2 in
    1) regionCode="KR" ;;
    2) regionCode="JP" ;;
    3) regionCode="US" ;;
    4) regionCode="SG" ;;
    *) echo "올바른 선택이 아닙니다. 1,2 중에서 선택해주세요." ;;
  esac
done
echo

while [[ -z "$vpcName" ]]; do
  read -p " 신규 VPC 이름을 입력해주세요 : " vpcName
done
echo

while [[ -z "$ipv4CidrBlock" ]]; do
  echo -e " ipv4CidrBlock을 입력해주세요. 아래에서 선택하세요:"
  echo -e "\t1. 192.168.0.0/16"
  echo -e "\t2. 172.16.0.0/16"
  echo -e "\t3. 10.0.0.0/16"
  read -p " 선택[1-3]: " selection

  case $selection in
    1) ipv4CidrBlock="192.168.0.0/16" ;;
    2) ipv4CidrBlock="172.16.0.0/16" ;;
    3) ipv4CidrBlock="10.0.0.0/16" ;;
    *) echo "올바른 선택이 아닙니다. 1-3 중에서 선택해주세요." ;;
  esac
done
echo


echo "VPC 생성중.. "
createVpcOutput=$($ncloud vpc createVpc --regionCode $regionCode --vpcName $vpcName --ipv4CidrBlock $ipv4CidrBlock 2>&1)

if [ $? -eq 0 ]; then
  echo "VPC 생성 성공 !"
else
  echo " !! VPC 생성에 실패하였습니다. !! "
  echo " !! VPC는 총 3개만 생성 가능합니다. !! "
  echo " !! 프로그램을 종료합니다 !! "
  exit
fi

vpcNo=$(echo "$createVpcOutput" | grep -oE '"vpcNo": "[^"]+"' | awk -F'"' '{print $4}')
sleep 10

echo "VPC 생성 완료 ! "

echo "VPC 번호 : $vpcNo"
echo


#VPC 번호 추출
while [[ -z "$vpcNo" ]]; do
  read -p " NACL을 생성할 VPC 번호를 입력하세요 : " vpcNo
done
echo

## NACL 생성
echo "NACL 생성 시작"
echo

while [[ -z "$naclNum" ]]; do
  read -p "생성할 NACL의 개수를 입력하세요 : " naclNum
done
echo

for (( i=1; i<=$naclNum; i++ )); do
  while [[ -z "${naclNames[$i-1]}" ]]; do
    read -p "생성할 NACL $i 번째 이름을 입력하세요 : " naclName
    naclNames[$i-1]=$naclName
  done

  ## NACL 생성
  $ncloud vpc createNetworkAcl --regionCode $regionCode --vpcNo $vpcNo --networkAclName ${naclNames[$i-1]}
  echo
  sleep 10
done

echo "NACL 생성 완료!"
echo

echo "Subnet 생성 시작"
echo

subnetCount=""
while [[ -z "$subnetCount" ]]; do
  read -p "생성할 서브넷의 개수를 입력하세요: " subnetCount
done

for ((s=1; s<=$subnetCount; s++)); do
  echo "서브넷 $s 생성 중..."

  zoneCode=""
  while [[ -z "$zoneCode" ]]; do
    echo -e " Subnet을 생성 할 Region을 아래에서 선택하세요:"
    echo -e "\t1. KR-1"
    echo -e "\t2. KR-2"
    read -p " 선택[ 1 or 2 ]: " selection3

    case $selection3 in
      1) zoneCode="KR-1" ;;
      2) zoneCode="KR-2" ;;
      *) echo "올바른 선택이 아닙니다. 1,2 중에서 선택해주세요." ;;
    esac
  done
  echo

  while [[ -z "$subnetName" ]]; do
    read -p "생성할 ${s} 번째 Subnet 이름을 입력하세요: " subnetName
  done
  echo

  subnet=""
  while [[ -z "$subnet" ]]; do
    echo -n " Subnet IP 범위를 지정하세요 [ ex) x.x.x.0/24] : "
    read subnet
  done

  # NACL 번호
  echo "NACL 번호 출력"
  $ncloud vpc getNetworkAclList --regionCode $regionCode --networkAclName ${naclNames[$s-1]} --networkAclStatusCode RUN --vpcNo $vpcNo | grep -oE '"networkAclNo": "[^"]+"' | awk -F'"' '{print $4}'
  echo

  while [[ -z "$networkAclNo" ]]; do
    read -p "적용시킬 NACL 번호를 입력하세요: " networkAclNo
  done
  echo

  echo "Subnet Type 선택"
  echo "1. PUBLIC"
  echo "2. PRIVATE"
  echo
  while true; do
    read -p "Enter your choice [1 or 2]: " choice
    case $choice in
      1)
        subnetTypeCode="PUBLIC"
        break
        ;;
      2)
        subnetTypeCode="PRIVATE"
        break
        ;;
      *)
        echo "올바른 선택이 아닙니다. 1,2 중에서 선택해주세요."
        ;;
    esac
  done

  $ncloud vpc createSubnet --regionCode $regionCode --zoneCode $zoneCode --vpcNo $vpcNo --subnetName $subnetName --subnet $subnet --networkAclNo $networkAclNo --subnetTypeCode $subnetTypeCode  --usageTypeCode GEN
  echo

  subnetName=""
  subnet=""
  networkAclNo=""
  subnetTypeCode=""
done

echo "Subnet 생성 완료!"
echo "자동 설치 프로그램을 종료합니다."
