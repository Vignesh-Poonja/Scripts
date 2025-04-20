cgvk62@uvuhanottdb:~> ./status.sh

Sun Apr 20 01:22:21 PM CEST 2025
uvuhanottdb

Status:

Running        Stopped
--------       --------

cst
ott
uft
dst
dsa
uut
srt
dsp
cgvk62@uvuhanottdb:~> ./status.sh

Sun Apr 20 01:24:34 PM CEST 2025
uvuhanottdb

Status:

Database        Status
--------        --------
cst             Stopped
dsa             Stopped
dsp  Stopped
dst             Stopped
ott             Stopped
srt             Stopped
uft             Stopped
uut             Stopped

cgvk62@uvuhanottdb:~> sudo su - uutadm
uutadm@uvuhanottdb:/usr/sap/UUT/HDB50> sapcontrol -nr 50 -function GetProcessList

20.04.2025 13:25:42
GetProcessList
OK
name, description, dispstatus, textstatus, starttime, elapsedtime, pid
hdbdaemon, HDB Daemon, GREEN, Running, 2025 04 04 08:00:27, 389:25:15, 57382
hdbcompileserver, HDB Compileserver, GREEN, Running, 2025 04 04 08:00:35, 389:25:07, 57699
hdbindexserver, HDB Indexserver-UUT, GREEN, Running, 2025 04 04 08:00:36, 389:25:06, 57753
hdbnameserver, HDB Nameserver, GREEN, Running, 2025 04 04 08:00:27, 389:25:15, 57407
hdbpreprocessor, HDB Preprocessor, GREEN, Running, 2025 04 04 08:00:35, 389:25:07, 57702
hdbwebdispatcher, HDB Web Dispatcher, GREEN, Running, 2025 04 04 08:01:08, 389:24:34, 59630
hdbxsengine, HDB XSEngine-UUT, GREEN, Running, 2025 04 04 08:00:36, 389:25:06, 57756
uutadm@uvuhanottdb:/usr/sap/UUT/HDB50>
