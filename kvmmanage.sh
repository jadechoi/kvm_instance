#!/bin/bash

temp=$(mktemp -t test.XXX)
ans=$(mktemp -t test.XXX) #메뉴에서 선택한 번호담기위한 변수
image=$(mktemp -t test.XXX)
vmname=$(mktemp -t test.XXX)
flavor=$(mktemp -t test.XXX) #cpu,ram set
r_list=$(mktemp -t test.XXX)

vmlist(){
        virsh list --all > $temp
        dialog --textbox $temp 20 50
}
vmnetlist(){
        virsh net-list --all > $temp
        dialog --textbox $temp 20 50
}
vmcreation(){
        dialog --title "이미지 선택하기" --radiolist "베이스 이미지를 선택하세요
" 15 50 5 "CentOS7" "CentOS 7 base image" ON "Ubuntu" "Ubuntu 20.04 base image" OFF "RHEL" "Redhat Enterprise Linux 8.0" 0FF 2> $image


        vmimage=$(cat $image)
        case $vmimage in
        CentOS7)
                os=/cloud/CentOS7-Base.qcow2 ;;
        Ubuntu)
                os=/cloud/Ubuntu20-Base.qcow2 ;;
        RHEL)
                os=/cloud/RHEL-Base.qcow2 ;;
        *)
                dialog --msgbox "잘못된 선택입니다" 10 40 ;;
        esac

        #os선택이 정상처리라면 인스턴스 이름 입력하기로 이동
        if [ $? -eq 0 ]
        then
                dialog --title "인스턴스 이름" --inputbox "인스턴스 이름을 입력>하세요 : " 10 50 2> $vmname
                name=$(cat $vmname)
                cp $os /cloud/${name}.qcow2
                #종료코드가 0인 경우(ok누른경우) flavor선택으로 이동
                if [ $? -eq 0 ]
	   then
                        dialog --title "스펙 선택" --radiolist "필요한 자원을 선
택하세요" 15 50 5 "m1.small" "가상CPU 1개, 가상메모리 1GB" ON "m1.medium" "가상CPU 2개, 가상메모리 2GB" OFF "m1.large" "가상CPU 4개, 가상메모리 8GB" OFF 2> $flavor
                        #flavor에 따라 변수에 cpu개수,메모리 사이즈 입력
                        spec=$(cat $flavor)
                        case $spec in
                        m1.small)
                                vcpus="1"
                                vram="1024"
                                dialog --msgbox "CPU: ${vcpus}core(s), RAM: ${vram}MB" 10 50 ;;
                        m1.medium)
                                vcpus='2'
                                vram='2048'
                                dialog --msgbox "CPU: ${vcpus}core(s), RAM: ${vram}MB" 10 50 ;;
                        m1.large)
                                vcpus='4'
                                vram='8192'
                                dialog --msgbox "CPU: ${vcpus}core(s), RAM: ${vram}MB" 10 50 ;;


                        esac

                        # 종료코드가 0인경우 설치 진행

                        if [ $? -eq 0 ]
                        then
                                virt-install --name $name --vcpus $vcpus --ram $vram --disk /cloud/${name}.qcow2 --import --network network:default,model=virtio --os-type linux --os-variant rhel7.0 --noautoconsole > /dev/null
                        fi
                                dialog --msgbox "설치가 시작되었습니다" 10 50

                fi
        fi
}

vmdelete(){

        remove_list=""
        vmlist=$(virsh list --all | grep -v Id | gawk '{print $2}' | sed '/^$/d')
        i=1
        for vm in $vmlist
        do
                if [ $? -eq 1 ]
                then
                        remove_list="${vm} ${i} ON"
                        i=$[ $i+1 ]
                else
                        remove_list="${remove_list} ${vm} ${i} OFF"
                        i=$[ $i+1 ]
                fi
        done


        dialog --title "가상머신 리스트" --radiolist "삭제할 가상머신을 선택하세
요" 15 50 5 ${remove_list} 2> $r_list

        if [ $? -eq 0 ]
        then
                dialog --title "Check" --yesno "삭제하시겠습니까?" 10 20
                if [ $? -eq 0 ]
                if [ $? -eq 0 ]
                then
                        tr_list=$(cat $r_list)
                        virsh destroy $tr_list
                        virsh undefine $tr_list --remove-all-storage
                fi
        fi

}
#메인코드

while [ 1 ]
do
#메인메뉴 출력
dialog --menu "KVM 관리 시스템" 20 40 8 1 "가상머신 리스트" 2 "가상 네트워크 리>스트" 3 "가상머신 생성" 4 "가상머신 삭제"  0 "종료" 2> $ans

#메뉴에서 esc선택시 프로그램 종료
if [ $? -eq 1 ]
then
        break
fi

#메뉴 선택과 OK선택시 결과에 따라 함수가 실행되도록 설정
selection=$(cat $ans)

case $selection in
1)
        vmlist ;;
2)
        vmnetlist ;;
3)
        vmcreation ;;
4)
        vmdelete ;;
0)
        break ;;
*)
        dialog --msgbox "잘못된 선택입니다" 10 40 ;;
esac

done

#종료 전 임시파일 삭제하기
rm -rf $temp 2> /dev/null
rm -rf $ans 2> /dev/null
rm -rf $image 2> /dev/null
rm -rf $vmname 2> /dev/null
rm -rf $flavor 2> /dev/null
rm -rf $r_list 2> /dev/null


