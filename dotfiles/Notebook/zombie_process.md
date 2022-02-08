# How to kill a zombie process

## to kill a process with all of its child

> $ killall -singal=KILL name_of_the_app

## find the parent process ID of a running process

> $ ps -o ppid= -p $ppid

## output the parent process children

> $ ps -e | grep $ppid
>
> $ prgrep -laP $ppid

## process tree

> $ pstree $ppid
>
> $ pstree -p $ppid
