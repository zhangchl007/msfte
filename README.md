I wrote a small tool to manage thousand linux servers including RHEL/SUSE(a testing done on RHEL4/5/6/SUSE10) like pssh , you must make sure ssh pub key authentication and sudo setting are ready .  Please see the source code below. 

I will continue to make it better . It's a first version .Please keep the original writer if you forward it.




1. Build ssh key trust and work it with SUDO

2. Execute the commands and the script and capture the output  to the result file on the router 

3.Log audit for user and commands

4.Damn Health check

5.Subsystem deployment . ...........

.......  net::openssh .......module

用perl openssh::net 写了个类似psshd的多线程工具，完善后把代码贴给大家参考，
目前我没有把ssh交互放进去，建立互信，生成ssh passprhase ,然后直接交给ssh-agent去处理。
目前基本功能:
并发跑ssh 命令
平发跑脚本
传文件到远端/远端到本地
计划加日志和审计功能
回写结果到当前目录下的result.txt
