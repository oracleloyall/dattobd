#!/bin/bash
#
# create by zhaoxi for Automated Testing!
#
echo "-----Automated Testing running!----"
#bytes
cache_size=1
#M
fallocate=30
#Block device 
block_device=/dev/loop0
#cow device 
cow_device=/dev/loop1
#cow file   mode1：备文件在原始卷上 mode2：备文件在任意其他卷上
mode2_cow_file=/cbt1/cow.
mode1_cow_file=/cbt/cow.
#snap file ID
Id=0
#minor
minor=0
#cbtctl cmd path
cbtctl_cmd=/home/oracle/eclipse-workspace/cbtcl-any/Debug/./cbtcl-any
#command dmesg clear
clear_dmesg="dmesg -C"
#color read for not pass case 
# echo -e "\e[1;33;41m test content \e[0m"
#show test cbt version 
#driver path 
driver=/home/oracle/eclipse-workspace/seek_tool/cbt-cow-any-device/./cbt.ko
#dirct path
workdir=$(cd $(dirname $0); pwd)
#echo ${workdir}

#loop times 
loop=10
dmesg -C
function repair()
{
    echo 
}
function test_init()
{
   insmod ${driver} debug=1
   echo "----Running test_init----"
   if [ ! -f "device_file1.img" ]; then
     dd if=/dev/zero of=device_file1.img bs=10240 count=60000
     mkfs.ext4 device_file1.img
   fi

   if [ ! -f "device_file1.img" ]; then
    dd if=/dev/zero of=device_file2.img bs=10240 count=60000
    mkfs.ext4 device_file2.img
   fi
   
   if [ ! -d "/cbt" ]; then
     mkdir /cbt
   fi
   if [ ! -d "/cbt1" ]; then
     mkdir /cbt1
   fi
   if [  -b block_device ]; then
    mount device_file1.img /cbt
   fi
   if [  -b cow_device ]; then
    mount device_file2.img /cbt1
   fi
   if [ ! -d "/cbt/zhaoxi" ]; then
      mkdir /cbt/zhaoxi
   fi
   if [ ! -f "/cbt/zhaoxi/read.md" ]; then
     touch /cbt/zhaoxi/read.md
   fi
  
#get base dev name 
df -h >> .devices
awk '{print $1,$6}' .devices  |grep -w "/cbt" >> .base_buff
block_device=`awk '{print $1}' .base_buff`
`\rm .devices .base_buff`
   echo "block_device: ${block_device}" 

#get cow dev name 
df -h >> .devices
awk '{print $1,$6}' .devices  |grep -w "/cbt1" >> .base_buff
cow_device=`awk '{print $1}' .base_buff`
`\rm .devices .base_buff`
   echo "cow_device: ${cow_device}" 

   echo "First Line ">> /cbt/zhaoxi/read.md
   echo "----Ending test_init----"
   echo
}
function test_setup_snap_mode1()
{
   echo "----Runing test_setup_snap_mode1----"
   ${clear_dmesg}
   ${cbtctl_cmd} setup-snapshot -c ${cache_size} -f  ${fallocate} ${block_device} ${mode1_cow_file}${Id} ${minor} ${block_device}
   Id=`expr $Id + 1`
   dmesg >> test_setup_snap_mode1.dmesg
   echo "----Ending test_setup_snap_mode1----"
   echo
}

function test_setup_snap_mode2()
{
   echo "----Runing test_setup_snap_mode2----"
   ${clear_dmesg}
   ${cbtctl_cmd} setup-snapshot -c ${cache_size} -f  ${fallocate} ${block_device} ${mode2_cow_file}${Id} ${minor} ${cow_device}
   Id=`expr $Id + 1`
   dmesg >> test_setup_snap_mode2.dmesg
   echo "----Ending test_setup_snap_mode2----"
   echo
}
function  test_trans_inc()
{
   echo "----Runing test_trans_inc----"
   ${clear_dmesg}
#check state
   cat /proc/cbt-info |grep -w "state" >>.state
   ret=`awk '{print $2}' .state`
   if [ ${ret} -ne 3 ];then
       echo -e "\e[1;33;41m test_trans_inc error \e[0m"
       echo -e "\e[1;33;41m device specified is not in active snapshot mode \e[0m"
      `\rm .state`
      echo "----Ending test_trans_inc----"
      echo 
      return $?
   fi 
   ${cbtctl_cmd} transition-to-incremental  ${minor}
 #  Id=`expr $Id + 1`
   dmesg >> test_trans_inc.dmesg
   `\rm .state`
   echo "----Ending test_trans_inc----"
   echo
}


function test_destroy_minor()
{
   echo "----Runing test_destroy_minor----"
   ${clear_dmesg}
   ${cbtctl_cmd} destroy  ${minor} 
   Id=0
   dmesg >> test_destroy_minor.dmesg
   echo "----Ending test_destroy_minor----"
   echo
}
function test_trans_snap_mode1()
{
   echo "----Runing test_trans_snap_mode1----"
   ${clear_dmesg}
   #check state
   cat /proc/cbt-info |grep -w "state" >>.state
   ret=`awk '{print $2}' .state`
   if [ ${ret} -ne 2 ];then
      echo -e "\e[1;33;41m test_trans_snap_mode1 error \e[0m"
      echo -e "\e[1;33;41m  device specified is not in active inc mode \e[0m"
      `\rm .state`
      echo "----Ending test_trans_snap_mode1----"
      echo 
      return $?
   fi 
   ${cbtctl_cmd}  transition-to-snapshot -f ${fallocate}  ${mode1_cow_file}${Id} ${minor} ${block_device}
   Id=`expr $Id + 1`
   dmesg >> test_trans_snap_mode1.dmesg
   `\rm .state`
   echo "----Ending test_trans_snap_mode1----"
   echo 
}


function test_trans_snap_mode2()
{
   echo "----Runing test_trans_snap_mode2----"
   ${clear_dmesg}
   #check state
   cat /proc/cbt-info |grep -w "state" >>.state
   ret=`awk '{print $2}' .state`
   if [ ${ret} -ne 2 ];then
      echo -e "\e[1;33;41m test_trans_snap_mode2 error \e[0m"
      echo -e "\e[1;33;41m  device specified is not in active inc mode \e[0m"
      `\rm .state`
      echo "----Ending test_trans_snap_mode2----"
      echo 
      return $?
   fi 
   ${cbtctl_cmd}  transition-to-snapshot -f ${fallocate}  ${mode2_cow_file}${Id} ${minor} ${cow_device}
   Id=`expr $Id + 1`
   dmesg >> test_trans_snap_mode1.dmesg
   `\rm .state`
   echo "----Ending test_trans_inc----"
   echo "----Ending test_trans_snap_mode2----"
   echo 
}
#模式一下测试用例
#快照模式（第一次）
# 1：卸载loop0，进入状态1，挂载loop0，进入状态3
function test_mode1_base_snap_first()
{
    echo "----Runing test_mode1_base_snap_first----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode1
    sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
       echo -e "\e[1;33;41m run test_mode1_base_snap_first error for check status more info please check file test_mode1_base_snap_first.dmesg!  \e[0m"
	   dmesg >> test_mode1_base_snap_first.dmesg
       `\rm .state`
       echo "----Ending test_mode1_base_snap_first----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
       echo -e "\e[1;33;41m run test_mode1_base_snap_first error for check status more info please check file test_mode1_base_snap_first.dmesg!  \e[0m"
	  dmesg >> test_mode1_base_snap_first.dmesg
      `\rm .state`
      echo "----Ending test_mode1_base_snap_first----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode1_base_snap_first OK----\e[0m"
   echo
}
#模式一下测试用例
#增量模式（第一次）
# 1：卸载loop0，进入状态0，挂载loop0，进入状态2
function test_mode1_base_inc_first()
{
    echo "----Runing test_mode1_base_inc_first----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode1
    sleep 1
	test_trans_inc
	sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
       echo -e "\e[1;33;41m run test_mode1_base_inc_first error for check status more info please check file test_mode1_base_inc_first.dmesg!  \e[0m"
	   dmesg >> test_mode1_base_inc_first.dmesg
       `\rm .state`
       echo "----Ending test_mode1_base_inc_first----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
       echo -e "\e[1;33;41m run test_mode1_base_inc_first error for check status more info please check file test_mode1_base_inc_first.dmesg!  \e[0m"
	  dmesg >> test_mode1_base_inc_first.dmesg
      `\rm .state`
      echo "----Ending test_mode1_base_inc_first----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode1_base_inc_first OK----\e[0m"
   echo
}

          

#模式一下测试用例
#快照模式（第二次）
# 1：setup->inc->trans->snap 卸载loop0，进入状态1，挂载loop0，进入状态3
function test_mode1_base_snap_second()
{
    echo "----Runing test_mode1_base_snap_second----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode1
    sleep 1
    test_trans_inc
    sleep 1
    test_trans_snap_mode1
    sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
       echo -e "\e[1;33;41m run test_mode1_base_snap_second error for check status more info please check file test_mode1_base_snap_second.dmesg!  \e[0m"
	   dmesg >> test_mode1_base_snap_second.dmesg
       `\rm .state`
       echo "----Ending test_mode1_base_snap_second----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
       echo -e "\e[1;33;41m run test_mode1_base_snap_second error for check status more info please check file test_mode1_base_snap_second.dmesg!  \e[0m"
	  dmesg >> test_mode1_base_snap_second.dmesg
      `\rm .state`
      echo "----Ending test_mode1_base_snap_second----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode1_base_snap_second OK----\e[0m"
   echo
}


#模式一下测试用例
#增量模式（第二次）
# 1：setup-》inc-》trans snap->trans inc, 卸载loop0，进入状态0，挂载loop0，进入状态2
function test_mode1_base_inc_sencond()
{
    echo "----Runing test_mode1_base_inc_sencond----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode1
    sleep 1
	test_trans_inc
	sleep 1
	test_trans_snap_mode1
    sleep 1
	test_trans_inc
	sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode1_base_inc_sencond error for check status more info please check file test_mode1_base_inc_sencond.dmesg!  \e[0m"
	   dmesg >> test_mode1_base_inc_sencond.dmesg
       `\rm .state`
       echo "----Ending test_mode1_base_inc_sencond----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode1_base_inc_sencond error for check status more info please check file test_mode1_base_inc_sencond.dmesg!  \e[0m"
	  dmesg >> test_mode1_base_inc_sencond.dmesg
      `\rm .state`
      echo "----Ending test_mode1_base_inc_sencond----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode1_base_inc_sencond OK----\e[0m"
   echo
}

###############snap mode second start   ###################
#模式二下测试用例
#快照模式（第一次）
# 1 ：卸载 loop0 ,进入状态1，挂载loop0，进入状态3
function test_mode2_base_snap_first_1()
{
    echo "----Runing test_mode2_base_snap_first_1----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_1 error for check status more info please check file test_mode2_base_snap_first_1.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_1.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_1----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_1 error for check status more info please check file test_mode2_base_snap_first_1.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_1.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_1----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_1 OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第一次）
# 2： 卸载loop1，进入状态1，挂载loop1，进入状态3
function test_mode2_base_snap_first_2()
{
    echo "----Runing test_mode2_base_snap_first_2----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_2 error for check status more info please check file test_mode2_base_snap_first_2.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_2.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_2----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_2 error for check status more info please check file test_mode2_base_snap_first_2.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_2.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_2----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_2 OK----\e[0m"
   echo
}

#模式二下测试用例
#快照模式（第一次）
# 3：卸载loop0，卸载loop1，进入状态1，挂载loop0，保持状态1，挂载loop1，进入状态3
function test_mode2_base_snap_first_3()
{
    echo "----Runing test_mode2_base_snap_first_3----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_3 error for check status more info please check file test_mode2_base_snap_first_3.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_3.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_3----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_3 error for check status more info please check file test_mode2_base_snap_first_3.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_3.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_3----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_3 OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第一次）
# 4：卸载loop0，卸载loop1，进入状态1，挂载loop1，保持状态1，挂载loop0，进入状态3
function test_mode2_base_snap_first_4()
{
    echo "----Runing test_mode2_base_snap_first_4----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_4 error for check status more info please check file test_mode2_base_snap_first_4.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_4.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_4----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_4 error for check status more info please check file test_mode2_base_snap_first_4.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_4.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_4----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_4 OK----\e[0m"
   echo
}

  

#模式二下测试用例
#快照模式（第一次）
#5：卸载loop1，卸载loop0，进入状态1，挂载loop0，保持状态1，挂载loop1，进入状态3
function test_mode2_base_snap_first_5()
{
    echo "----Runing test_mode2_base_snap_first_5----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_5 error for check status more info please check file test_mode2_base_snap_first_5.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_5.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_5----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_5 error for check status more info please check file test_mode2_base_snap_first_5.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_5.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_5----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_5 OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第一次）
#  6：卸载loop1，卸载loop0，进入状态1，挂载loop1，保持状态1，挂载loop0，进入状态3
function test_mode2_base_snap_first_6()
{
    echo "----Runing test_mode2_base_snap_first_6----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_6 error for check status more info please check file test_mode2_base_snap_first_6.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_6.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_6----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_6 error for check status more info please check file test_mode2_base_snap_first_6.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_6.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_6----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_6 OK----\e[0m"
   echo
}



###############inc mode first start ###################
#模式二下测试用例
#增量模式（第一次）
#   1： 卸载 loop0 ,进入状态0，挂载loop0，进入状态2
function test_mode2_base_inc_first_1()
{
    echo "----Runing test_mode2_base_inc_first_1----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_1 error for check status more info please check file test_mode2_base_inc_first_1.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_1.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_1----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_1 error for check status more info please check file test_mode2_base_inc_first_1.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_1.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_1----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_1 OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第一次）
# 2：卸载loop1，进入状态0，挂载loop1，进入状态2
function test_mode2_base_inc_first_2()
{
    echo "----Runing test_mode2_base_inc_first_2----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_2 error for check status more info please check file test_mode2_base_inc_first_2.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_2.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_2----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_2 error for check status more info please check file test_mode2_base_inc_first_2.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_2.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_2----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_2 OK----\e[0m"
   echo
}

#模式二下测试用例
#增量模式（第一次）
# 3：卸载loop0，卸载loop1，进入状态0，挂载loop0，保持状态0，挂载loop1，进入状态2
function test_mode2_base_inc_first_3()
{
    echo "----Runing test_mode2_base_inc_first_3----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_3 error for check status more info please check file test_mode2_base_inc_first_3.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_3.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_3----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_3 error for check status more info please check file test_mode2_base_inc_first_3.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_3.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_3----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_3 OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第一次）
#4：卸载loop0，卸载loop1，进入状态0，挂载loop1，保持状态0，挂载loop0，进入状态2
function test_mode2_base_inc_first_4()
{
    echo "----Runing test_mode2_base_inc_first_4----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_4 error for check status more info please check file test_mode2_base_inc_first_4.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_4.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_4----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_4 error for check status more info please check file test_mode2_base_inc_first_4.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_4.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_4----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_4 OK----\e[0m"
   echo
}

  

#模式二下测试用例
#增量模式（第一次）
#5：卸载loop1，卸载loop0，进入状态0，挂载loop0，保持状态0，挂载loop1，进入状态2
function test_mode2_base_inc_first_5()
{
    echo "----Runing test_mode2_base_inc_first_5----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_5 error for check status more info please check file test_mode2_base_inc_first_5.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_5.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_5----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_5 error for check status more info please check file test_mode2_base_inc_first_5.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_5.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_5----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_5 OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第一次）
#6：卸载loop1，卸载loop0，进入状态0，挂载loop1，保持状态0，挂载loop0，进入状态2
function test_mode2_base_inc_first_6()
{
    echo "----Runing test_mode2_base_inc_first_6----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
    test_trans_inc
    sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_6 error for check status more info please check file test_mode2_base_inc_first_6.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_6.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_6----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_6 error for check status more info please check file test_mode2_base_inc_first_6.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_6.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_6----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_6 OK----\e[0m"
   echo
}

###############inc mode first end   ###################




###############snap mode second start   ###################
#模式二下测试用例
#快照模式（第二次）
# 1 ：setup->inc->snap 卸载 loop0 ,进入状态1，挂载loop0，进入状态3
function test_mode2_base_snap_second_1()
{
    echo "----Runing test_mode2_base_snap_second_1----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
    test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_1 error for check status more info please check file test_mode2_base_snap_second_1.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_1.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_1----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_1 error for check status more info please check file test_mode2_base_snap_second_1.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_1.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_1----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_1 OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第二次）
# 2： 卸载loop1，进入状态1，挂载loop1，进入状态3
function test_mode2_base_snap_second_2()
{
    echo "----Runing test_mode2_base_snap_second_2----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_2 error for check status more info please check file test_mode2_base_snap_second_2.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_2.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_2----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_2 error for check status more info please check file test_mode2_base_snap_second_2.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_2.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_2----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_2 OK----\e[0m"
   echo
}

#模式二下测试用例
#快照模式（第二次）
# 3：卸载loop0，卸载loop1，进入状态1，挂载loop0，保持状态1，挂载loop1，进入状态3
function test_mode2_base_snap_second_3()
{
    echo "----Runing test_mode2_base_snap_second_3----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_3 error for check status more info please check file test_mode2_base_snap_second_3.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_3.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_3----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_3 error for check status more info please check file test_mode2_base_snap_second_3.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_3.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_3----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_3 OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第二次）
# 4：卸载loop0，卸载loop1，进入状态1，挂载loop1，保持状态1，挂载loop0，进入状态3
function test_mode2_base_snap_second_4()
{
    echo "----Runing test_mode2_base_snap_first_4----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_4 error for check status more info please check file test_mode2_base_snap_second_4.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_4.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_4----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_4 error for check status more info please check file test_mode2_base_snap_second_4.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_4.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_4----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_4 OK----\e[0m"
   echo
}

  

#模式二下测试用例
#快照模式（第二次）
#5：卸载loop1，卸载loop0，进入状态1，挂载loop0，保持状态1，挂载loop1，进入状态3
function test_mode2_base_snap_second_5()
{
    echo "----Runing test_mode2_base_snap_second_5----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_5 error for check status more info please check file test_mode2_base_snap_second_5.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_5.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_5----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_5 error for check status more info please check file test_mode2_base_snap_second_5.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_5.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_5----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_5 OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第二次）
#  6：卸载loop1，卸载loop0，进入状态1，挂载loop1，保持状态1，挂载loop0，进入状态3
function test_mode2_base_snap_second_6()
{
    echo "----Runing test_mode2_base_snap_second_6----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_6 error for check status more info please check file test_mode2_base_snap_second_6.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_6.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_6----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_6 error for check status more info please check file test_mode2_base_snap_second_6.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_6.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_6----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_6 OK----\e[0m"
   echo
}



###############snap mode second end   #################




###############inc mode second start ###################
#模式二下测试用例
#增量模式（第二次）
#  1： 卸载 loop0 ,进入状态0，挂载loop0，进入状态2
function test_mode2_base_inc_second_1()
{
    echo "----Runing test_mode2_base_inc_second_1----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
    umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_1 error for check status more info please check file test_mode2_base_inc_second_1.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_1.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_1----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device} /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_1 error for check status more info please check file test_mode2_base_inc_second_1.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_1.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_1----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_1 OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第二次）
# 2：卸载loop1，进入状态0，挂载loop1，进入状态2
function test_mode2_base_inc_second_2()
{
    echo "----Runing test_mode2_base_inc_second_2----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_2 error for check status more info please check file test_mode2_base_inc_second_2.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_2.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_2----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_2 error for check status more info please check file test_mode2_base_inc_second_2.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_2.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_2----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_2 OK----\e[0m"
   echo
}

#模式二下测试用例
#增量模式（第二次）
# 3：卸载loop0，卸载loop1，进入状态0，挂载loop0，保持状态0，挂载loop1，进入状态2
function test_mode2_base_inc_second_3()
{
    echo "----Runing test_mode2_base_inc_second_3----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_3 error for check status more info please check file test_mode2_base_inc_second_3.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_3.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_3----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_3 error for check status more info please check file test_mode2_base_inc_second_3.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_3.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_3----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_3 OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第二次）
#4：卸载loop0，卸载loop1，进入状态0，挂载loop1，保持状态0，挂载loop0，进入状态2
function test_mode2_base_inc_second_4()
{
    echo "----Runing test_mode2_base_inc_second_4----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	umount /cbt
	sleep 1
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_4 error for check status more info please check file test_mode2_base_inc_second_4.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_4.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_4----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_4 error for check status more info please check file test_mode2_base_inc_second_4.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_4.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_4----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_4 OK----\e[0m"
   echo
}

  

#模式二下测试用例
#增量模式（第二次）
#5：卸载loop1，卸载loop0，进入状态0，挂载loop0，保持状态0，挂载loop1，进入状态2
function test_mode2_base_inc_second_5()
{
    echo "----Runing test_mode2_base_inc_second_5----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_5 error for check status more info please check file test_mode2_base_inc_second_5.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_5.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_5----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${block_device}  /cbt
   sleep 1
   mount ${cow_device} /cbt1
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_5 error for check status more info please check file test_mode2_base_inc_second_5.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_5.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_5----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_5 OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第二次）
#6：卸载loop1，卸载loop0，进入状态0，挂载loop1，保持状态0，挂载loop0，进入状态2
function test_mode2_base_inc_second_6()
{
    echo "----Runing test_mode2_base_inc_second_6----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
    test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	umount /cbt1
	sleep 1
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_6 error for check status more info please check file test_mode2_base_inc_second_6.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_6.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_6----"
       echo 
       return $?
   fi 
   `\rm .state`
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_6 error for check status more info please check file test_mode2_base_inc_second_6.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_6.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_6----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_6 OK----\e[0m"
   echo
}

###############inc mode first end   ###################


###############snap mode second start except state  ###################
#模式二下测试用例
#快照模式（第一次）
#  1 ：卸载 loop0（中间产生几次失败卸载） ,进入状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_first_1_except()
{
    echo "----Runing test_mode2_base_snap_first_1_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt   2>/dev/null 
    done  
    cd ${workdir}
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_1_except error for check status more info please check file test_mode2_base_snap_first_1_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_1_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_1_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
    cd ${workdir}
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    
    mount ${block_device} /cbt
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_1_except error for check status more info please check file test_mode2_base_snap_first_1_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_1_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_1_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_1_except OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第一次）
# 2： 卸载loop1（中间产生几次失败卸载），进入状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_first_2_except()
{
    echo "----Runing test_mode2_base_snap_first_2_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1   2>/dev/null
    done  
    cd ${workdir}
	umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_2_except error for check status more info please check file test_mode2_base_snap_first_2_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_2_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_2_except----"
       echo 
       return $?
   fi 
   `\rm .state`
    cd ${workdir}
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    mount ${cow_device} /cbt1
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_2_except error for check status more info please check file test_mode2_base_snap_first_2_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_2_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_2_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_2_except OK----\e[0m"
   echo
}

#模式二下测试用例
#快照模式（第一次）
#  3：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态1，挂载loop0，保持状态1，挂载loop1（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_first_3_except()
{
    echo "----Runing test_mode2_base_snap_first_3_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_3_except error for check status more info please check file test_mode2_base_snap_first_3_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_3_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_3_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
    mount ${block_device}  /cbt
    sleep 1
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
	
    mount ${cow_device} /cbt1
    sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_3_except error for check status more info please check file test_mode2_base_snap_first_3_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_3_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_3_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_3_except OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第一次）
# 4：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态1，挂载loop1（中间产生几次失败挂载），保持状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_first_4_except()
{
    echo "----Runing test_mode2_base_snap_first_4_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_4_except error for check status more info please check file test_mode2_base_snap_first_4_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_4_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_4_except----"
       echo 
       return $?
   fi 
   `\rm .state`
     for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
   mount ${cow_device} /cbt1
   sleep 1
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_4_except error for check status more info please check file test_mode2_base_snap_first_4_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_4_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_4_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_4_except OK----\e[0m"
   echo
}

  

#模式二下测试用例
#快照模式（第一次）
#5：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态1，挂载loop0（中间产生几次失败挂载），保持状态1，挂载loop1（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_first_5_except()
{
    echo "----Runing test_mode2_base_snap_first_5_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_5_except error for check status more info please check file test_mode2_base_snap_first_5_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_5_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_5_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   mount ${block_device}  /cbt
   sleep 1
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_5_except error for check status more info please check file test_mode2_base_snap_first_5_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_5_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_5_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_5_except OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第一次）
# 6：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态1，挂载loop1（中间产生几次失败挂载），保持状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_first_6_except()
{
    echo "----Runing test_mode2_base_snap_first_6_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
    cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_6_except error for check status more info please check file test_mode2_base_snap_first_6_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_first_6_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_first_6_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_first_6_except error for check status more info please check file test_mode2_base_snap_first_6_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_first_6_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_first_6_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_first_6_except OK----\e[0m"
   echo
}



###############inc mode second start except state  ###################
#模式二下测试用例
#增量模式（第一次）
#  1 ：卸载 loop0（中间产生几次失败卸载） ,进入状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_first_1_except()
{
    echo "----Runing test_mode2_base_inc_first_1_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt   2>/dev/null 
    done  
    cd ${workdir}
	umount  /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_1_except not status 0 error for check status more info please check file test_mode2_base_inc_first_1_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_1_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_1_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
 
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    
    mount ${block_device} /cbt
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_1_except error for check status more info please check file test_mode2_base_inc_first_1_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_1_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_1_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_1_except OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第一次）
# 2： 卸载loop1（中间产生几次失败卸载），进入状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_first_2_except()
{
    echo "----Runing test_mode2_base_inc_first_2_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1   2>/dev/null
    done  
    cd ${workdir}
	umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_2_except error for check status more info please check file test_mode2_base_inc_first_2_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_2_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_2_except----"
       echo 
       return $?
   fi 
   `\rm .state`
    cd ${workdir}
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    mount ${cow_device} /cbt1
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_2_except error for check status more info please check file test_mode2_base_inc_first_2_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_2_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_2_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_2_except OK----\e[0m"
   echo
}

#模式二下测试用例
#增量模式（第一次）
#  3：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态0，挂载loop0，保持状态0，挂载loop1（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_first_3_except()
{
    echo "----Runing test_mode2_base_inc_first_3_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_3_except error for check status more info please check file test_mode2_base_inc_first_3_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_3_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_3_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
    mount ${block_device}  /cbt
    sleep 1
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
	
    mount ${cow_device} /cbt1
    sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_3_except error for check status more info please check file test_mode2_base_inc_first_3_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_3_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_3_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_3_except OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第一次）
# 4：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态0，挂载loop1（中间产生几次失败挂载），保持状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_first_4_except()
{
    echo "----Runing test_mode2_base_inc_first_4_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_4_except error for check status more info please check file test_mode2_base_inc_first_4_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_4_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_4_except----"
       echo 
       return $?
   fi 
   `\rm .state`
     for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
   mount ${cow_device} /cbt1
   sleep 1
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_4_except error for check status more info please check file test_mode2_base_inc_first_4_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_4_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_4_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_4_except OK----\e[0m"
   echo
}

  

#模式二下测试用例
#增量模式（第一次）
#5：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态0，挂载loop0（中间产生几次失败挂载），保持状态0，挂载loop1（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_first_5_except()
{
    echo "----Runing test_mode2_base_inc_first_5_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_5_except error for check status more info please check file test_mode2_base_inc_first_5_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_5_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_5_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   mount ${block_device}  /cbt
   sleep 1
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_5_except error for check status more info please check file test_mode2_base_inc_first_5_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_5_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_5_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_5_except OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第一次）
# 6：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态0，挂载loop1（中间产生几次失败挂载），保持状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_first_6_except()
{
    echo "----Runing test_mode2_base_inc_first_6_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_6_except error for check status more info please check file test_mode2_base_inc_first_6_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_first_6_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_first_6_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_first_6_except error for check status more info please check file test_mode2_base_inc_first_6_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_first_6_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_first_6_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_first_6_except OK----\e[0m"
   echo
}



###############snap mode second start except state  ###################
#模式二下测试用例
#快照模式（第二次）
#  1 ：卸载 loop0（中间产生几次失败卸载） ,进入状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_second_1_except()
{
    echo "----Runing test_mode2_base_snap_second_1_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt   2>/dev/null 
    done  
    cd ${workdir}
	umount /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_1_except error for check status more info please check file test_mode2_base_snap_second_1_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_1_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_1_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
    cd ${workdir}
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    
    mount ${block_device} /cbt
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_1_except error for check status more info please check file test_mode2_base_snap_second_1_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_1_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_1_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_1_except OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第二次）
# 2： 卸载loop1（中间产生几次失败卸载），进入状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_second_2_except()
{
    echo "----Runing test_mode2_base_snap_second_2_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1   2>/dev/null
    done  
    cd ${workdir}
	umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_2_except error for check status more info please check file test_mode2_base_snap_second_2_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_2_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_2_except----"
       echo 
       return $?
   fi 
   `\rm .state`
    cd ${workdir}
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    mount ${cow_device} /cbt1
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_2_except error for check status more info please check file test_mode2_base_snap_second_2_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_2_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_2_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_2_except OK----\e[0m"
   echo
}

#模式二下测试用例
#快照模式（第二次）
#  3：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态1，挂载loop0，保持状态1，挂载loop1（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_second_3_except()
{
    echo "----Runing test_mode2_base_snap_second_3_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_3_except error for check status more info please check file test_mode2_base_snap_second_3_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_3_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_3_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
    mount ${block_device}  /cbt
    sleep 1
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
	
    mount ${cow_device} /cbt1
    sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_3_except error for check status more info please check file test_mode2_base_snap_second_3_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_3_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_3_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_3_except OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第二次）
# 4：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态1，挂载loop1（中间产生几次失败挂载），保持状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_second_4_except()
{
    echo "----Runing test_mode2_base_snap_second_4_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_4_except error for check status more info please check file test_mode2_base_snap_second_4_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_4_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_4_except----"
       echo 
       return $?
   fi 
   `\rm .state`
     for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
   mount ${cow_device} /cbt1
   sleep 1
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_4_except error for check status more info please check file test_mode2_base_snap_second_4_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_4_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_4_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_4_except OK----\e[0m"
   echo
}

  

#模式二下测试用例
#快照模式（第二次）
#5：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态1，挂载loop0（中间产生几次失败挂载），保持状态1，挂载loop1（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_second_5_except()
{
    echo "----Runing test_mode2_base_snap_second_5_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_5_except error for check status more info please check file test_mode2_base_snap_second_5_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_5_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_5_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   mount ${block_device}  /cbt
   sleep 1
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_5_except error for check status more info please check file test_mode2_base_snap_second_5_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_5_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_5_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_5_except OK----\e[0m"
   echo
}


#模式二下测试用例
#快照模式（第二次）
# 6：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态1，挂载loop1（中间产生几次失败挂载），保持状态1，挂载loop0（中间产生几次失败挂载），进入状态3
function test_mode2_base_snap_second_6_except()
{
    echo "----Runing test_mode2_base_snap_second_6_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
    test_trans_snap_mode2
	sleep 1
    cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 1 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_6_except error for check status more info please check file test_mode2_base_snap_second_6_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_snap_second_6_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_snap_second_6_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 3 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_snap_second_6_except error for check status more info please check file test_mode2_base_snap_second_6_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_snap_second_6_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_snap_second_6_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_snap_second_6_except OK----\e[0m"
   echo
}



###############inc mode second start except state  ###################
#模式二下测试用例
#增量模式（第二次）
#  1 ：卸载 loop0（中间产生几次失败卸载） ,进入状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_second_1_except()
{
    echo "----Runing test_mode2_base_inc_second_1_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt   2>/dev/null 
    done  
    cd ${workdir}
	umount  /cbt
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_1_except not status 0 error for check status more info please check file test_mode2_base_inc_second_1_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_1_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_1_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
 
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    
    mount ${block_device} /cbt
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_1_except error for check status more info please check file test_mode2_base_inc_second_1_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_1_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_1_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_1_except OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第二次）
# 2： 卸载loop1（中间产生几次失败卸载），进入状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_second_2_except()
{
    echo "----Runing test_mode2_base_inc_second_2_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1   2>/dev/null
    done  
    cd ${workdir}
	umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_2_except error for check status more info please check file test_mode2_base_inc_second_2_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_2_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_2_except----"
       echo 
       return $?
   fi 
   `\rm .state`
    cd ${workdir}
	for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
    mount ${cow_device} /cbt1
    sleep 1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_2_except error for check status more info please check file test_mode2_base_inc_second_2_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_2_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_2_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_2_except OK----\e[0m"
   echo
}

#模式二下测试用例
#增量模式（第二次）
#  3：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态0，挂载loop0，保持状态0，挂载loop1（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_second_3_except()
{
    echo "----Runing test_mode2_base_inc_second_3_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_3_except error for check status more info please check file test_mode2_base_inc_second_3_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_3_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_3_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
    mount ${block_device}  /cbt
    sleep 1
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
	
    mount ${cow_device} /cbt1
    sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_3_except error for check status more info please check file test_mode2_base_inc_second_3_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_3_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_3_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_3_except OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第二次）
# 4：卸载loop0（中间产生几次失败卸载），卸载loop1（中间产生几次失败卸载），进入状态0，挂载loop1（中间产生几次失败挂载），保持状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_second_4_except()
{
    echo "----Runing test_mode2_base_inc_second_4_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_4_except error for check status more info please check file test_mode2_base_inc_second_4_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_4_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_4_except----"
       echo 
       return $?
   fi 
   `\rm .state`
     for((i=1;i<=${loop};i++));  
    do   
    mount /cbt1  2>/dev/null
    done  
   mount ${cow_device} /cbt1
   sleep 1
   
    for((i=1;i<=${loop};i++));  
    do   
    mount /cbt  2>/dev/null
    done  
   
   mount ${block_device}  /cbt
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_4_except error for check status more info please check file test_mode2_base_inc_second_4_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_4_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_4_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_4_except OK----\e[0m"
   echo
}

  

#模式二下测试用例
#增量模式（第二次）
#5：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态0，挂载loop0（中间产生几次失败挂载），保持状态0，挂载loop1（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_second_5_except()
{
    echo "----Runing test_mode2_base_inc_second_5_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
	cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_5_except error for check status more info please check file test_mode2_base_inc_second_5_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_5_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_5_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   mount ${block_device}  /cbt
   sleep 1
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_5_except error for check status more info please check file test_mode2_base_inc_second_5_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_5_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_5_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_5_except OK----\e[0m"
   echo
}


#模式二下测试用例
#增量模式（第二次）
# 6：卸载loop1（中间产生几次失败卸载），卸载loop0（中间产生几次失败卸载），进入状态0，挂载loop1（中间产生几次失败挂载），保持状态0，挂载loop0（中间产生几次失败挂载），进入状态2
function test_mode2_base_inc_second_6_except()
{
    echo "----Runing test_mode2_base_inc_second_6_except----"
    ${clear_dmesg}
    #umount base dev;check status 1;mount base dev;check status 3
    #this case make sure umount ok,use umount -fl 
    test_setup_snap_mode2
    sleep 1
	test_trans_inc
    sleep 1
	test_trans_snap_mode2
    sleep 1
	test_trans_inc
	sleep 1
    cd /cbt1
	for((i=1;i<=${loop};i++));  
    do   
    umount /cbt1  2>/dev/null
    done  
    cd ${workdir}
    umount /cbt1
	
	cd /cbt
	for((i=1;i<=${loop};i++));  
    do   
     umount /cbt 2>/dev/null
    done  
    cd ${workdir}
	umount /cbt
	
    cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 0 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_6_except error for check status more info please check file test_mode2_base_inc_second_6_except.dmesg!  \e[0m"
	   dmesg >> test_mode2_base_inc_second_6_except.dmesg
       `\rm .state`
       echo "----Ending test_mode2_base_inc_second_6_except----"
       echo 
       return $?
   fi 
   `\rm .state`
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt1  2>/dev/null
   done 
   mount ${cow_device} /cbt1
   sleep 1
   mount ${block_device}  /cbt
   for((i=1;i<=${loop};i++));  
   do   
   mount /cbt  2>/dev/null
   done 
   sleep 1
   cat /proc/cbt-info |grep -w "state" >>.state
    ret=`awk '{print $2}' .state`
    if [ ${ret} -ne 2 ];then
       test_destroy_minor
	   Id=0
       echo -e "\e[1;33;41m run test_mode2_base_inc_second_6_except error for check status more info please check file test_mode2_base_inc_second_6_except.dmesg!  \e[0m"
	  dmesg >> test_mode2_base_inc_second_6_except.dmesg
      `\rm .state`
      echo "----Ending test_mode2_base_inc_second_6_except----"
      echo 
      return $?
   fi 
   `\rm .state`
   sleep 1
   Id=0
   test_destroy_minor
   echo -e "\e[34m ----Ending test_mode2_base_inc_second_6_except OK----\e[0m"
   echo
}


###############except cases         ###################


#------base function-------
#test_destroy_minor
#test_init
#test_setup_snap_mode1
#test_trans_inc
#test_trans_snap_mode1


#------test cases----------
#------base cases mode one--------
test_mode1_base_snap_first
test_mode1_base_inc_first
test_mode1_base_snap_second
test_mode1_base_inc_sencond

#------base cases mode second--------
test_mode2_base_snap_first_1
test_mode2_base_snap_first_2
test_mode2_base_snap_first_3
test_mode2_base_snap_first_4
test_mode2_base_snap_first_5
test_mode2_base_snap_first_6

test_mode2_base_inc_first_1
test_mode2_base_inc_first_2
test_mode2_base_inc_first_3
test_mode2_base_inc_first_4
test_mode2_base_inc_first_5
test_mode2_base_inc_first_6

test_mode2_base_snap_second_1
test_mode2_base_snap_second_2
test_mode2_base_snap_second_3
test_mode2_base_snap_second_4
test_mode2_base_snap_second_5
test_mode2_base_snap_second_6

test_mode2_base_inc_second_1
test_mode2_base_inc_second_2
test_mode2_base_inc_second_3
test_mode2_base_inc_second_4
test_mode2_base_inc_second_5
test_mode2_base_inc_second_6

test_mode2_base_snap_first_1_except
test_mode2_base_snap_first_2_except
test_mode2_base_snap_first_3_except
test_mode2_base_snap_first_4_except
test_mode2_base_snap_first_5_except
test_mode2_base_snap_first_6_except

test_mode2_base_inc_first_1_except
test_mode2_base_inc_first_2_except
test_mode2_base_inc_first_3_except
test_mode2_base_inc_first_4_except
test_mode2_base_inc_first_5_except
test_mode2_base_inc_first_6_except

test_mode2_base_snap_second_1_except
test_mode2_base_snap_second_2_except
test_mode2_base_snap_second_3_except
test_mode2_base_snap_second_4_except
test_mode2_base_snap_second_5_except
test_mode2_base_snap_second_6_except

test_mode2_base_inc_second_1_except
test_mode2_base_inc_second_2_except
test_mode2_base_inc_second_3_except
test_mode2_base_inc_second_4_except
test_mode2_base_inc_second_5_except
test_mode2_base_inc_second_6_except
exit
