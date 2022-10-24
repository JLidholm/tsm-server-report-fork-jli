#!/bin/bash
# Get detailed info for clients using the activity log
# 2022-09-06 / PM
# Department of Computer Science, Lund University

# Currently, it digs through machines that are manually specified in lists in the script. 
# The plan is to instead have the user provide either POLICYDOMAIN och a SCHEDULE and then
# get the client list from those and produce result accoringly.

CS_SERVERS="DOKUWIKI2 COURSEGIT FILEMAKER FORSETE LAGRING3 LGIT945 LMGM778 MONITOR MOODLE2020 PUCCINI ROBOTMIND1 TSM3 VILDE VM67 WEB2020"
#CS_SERVERS="TSM3"
CS_CLIENTS="ABRUCE ALAN ALEXANDER ALEXANDRU ALFREDA ALMAOA ANDRZEJL ANDRZEJLDESK ANDYO ANNAA ANTONA AYESHAJ BIRGER BJORNIX BJORNR BJORNUX BORISM BRUCE CARINAA CHRISTELF CHRISTIN CHRISTOPHR DANIELH DRROBERTZ EBJARNASON ELINAT EMELIEE ERIKH FASEE FLAVIUSG GARETHC GORELH HAMPUSA HEIDIE IDRISS JACEKM JONASW KLANG KONSTANTINM LARSB LUIGI MAIKEK MARCUSK MARTINH MASOUMEH MATHIASH MATTHIAS MICHAELD MICHAELDIMAC MOMINAR NAZILA NIKLAS NORIC PATRIKP PENG PERA PERR PETERMAC PIERREN QUNYINGS REGNELL RIKARDO ROGERH ROYA RSSKNI SANDRAHP SERGIOR SIMONKL SUSANNA THOREH ULFA ULRIKA VOLKER"
CS_KLIENTS="CHRISTIN"
EIT_SERVERS=""
EIT_CLIENTS=""
BME_SERVERS=""
BME_CLIENTS=""

SELECTION=$1
shopt -s nocasematch
case "${SELECTION/-/_}" in
    CS_SERVERS  ) Dept="CS" ;;
    CS_CLIENTS  ) Dept="CS" ;;
    CS_KLIENTS  ) Dept="CS" ;;
    EIT_SERVERS ) Dept="EIT" ;;
    EIT_CLIENTS ) Dept="EIT" ;;
    BME_SERVERS ) Dept="BME" ;;
    BME_CLIENTS ) Dept="BME" ;;
    *           ) 
        echo "No such list. Exiting"
        exit 1;;
esac

CLIENTS="${!SELECTION}"

# Exit if the list is empty
if [ -z "$CLIENTS" ]; then
    echo "Empty list! Exiting"
    exit 1
fi

Today="$(date +%F)"
Now=$(date +%s)      # Ex: Now=1662627432
OutDirPrefix="/tmp/tsm/"
OutDir="$OutDirPrefix${Dept,,}/$(echo "${SELECTION,,}" | sed -e s/[a-z]*_//)"   # Ex: OutDir='/tmp/tsm/cs/servers'
# Create the OutDir if it doesn't exist:
if [ ! -d $OutDir ]; then
    mkdir -p $OutDir
fi
ReportFile="${OutDir}/TSM_status_${Today}"

Client_W="%-13s"
BackedupNumfiles_H="%11s"
BackedupNumfiles_W="%'11d"
TransferredVolume_W="%13s"
BackeupElapsedtime_W="%-10s"
BackupStatus_W="%-23s"
ClientTotalSpaceUseMB_WH="%10s"
ClientTotalSpaceUsedMB_W="%'10d"
ClientTotalNumFile_WH="%11s"
ClientTotalNumFiles_W="%'11d"
ClientNumFilespaces_WH="%6s"
ClientNumFilespaces_W="%'6d"
ClientVersion_W="%-9s"
ClientLastNetWork_W="%-18s"
ClientOS_W="%-23s"
ErrorMsg_W="%-60s"

#FormatStringHeader="%-13s%11s%13s  %-10s%-15s%10s  %-9s%-18s%-23s%-60s"
#FormatString=      "%-13s%11s%13s  %-10s%-15s%'10d  %-9s%-18s%-23s%-60s"
##FormatStringHeader="${Client_W}${BackedupNumfiles_H}${TransferredVolume_W}  ${BackeupElapsedtime_W}${BackupStatus_W}${ClientTotalSpaceUseMB_WH}  ${ClientTotalNumFile_WH}  ${ClientVersion_W}${ClientLastNetWork_W}${ClientOS_W}${ErrorMsg_W}"
##FormatStringConten="${Client_W}${BackedupNumfiles_W}${TransferredVolume_W}  ${BackeupElapsedtime_W}${BackupStatus_W}${ClientTotalSpaceUsedMB_W}${ClientTotalNumFiles_W}  ${ClientVersion_W}${ClientLastNetWork_W}${ClientOS_W}${ErrorMsg_W}"
FormatStringHeader="${Client_W}${BackedupNumfiles_H}${TransferredVolume_W}  ${BackeupElapsedtime_W}${BackupStatus_W}  ${ClientTotalNumFile_WH}  ${ClientTotalSpaceUseMB_WH}  ${ClientNumFilespaces_WH}  ${ClientVersion_W}${ClientLastNetWork_W}${ClientOS_W}${ErrorMsg_W}"
FormatStringConten="${Client_W}${BackedupNumfiles_W}${TransferredVolume_W}  ${BackeupElapsedtime_W}${BackupStatus_W}${ClientTotalNumFiles_W}  ${ClientTotalSpaceUsedMB_W}  ${ClientNumFilespaces_W}  ${ClientVersion_W}${ClientLastNetWork_W}${ClientOS_W}${ErrorMsg_W}"


#   _____   _____    ___   ______   _____       _____  ______      ______   _   _   _   _   _____   _____   _____   _____   _   _   _____ 
#  /  ___| |_   _|  / _ \  | ___ \ |_   _|     |  _  | |  ___|     |  ___| | | | | | \ | | /  __ \ |_   _| |_   _| |  _  | | \ | | /  ___|
#  \ `--.    | |   / /_\ \ | |_/ /   | |       | | | | | |_        | |_    | | | | |  \| | | /  \/   | |     | |   | | | | |  \| | \ `--. 
#   `--. \   | |   |  _  | |    /    | |       | | | | |  _|       |  _|   | | | | | . ` | | |       | |     | |   | | | | | . ` |  `--. \
#  /\__/ /   | |   | | | | | |\ \    | |       \ \_/ / | |         | |     | |_| | | |\  | | \__/\   | |    _| |_  \ \_/ / | |\  | /\__/ /
#  \____/    \_/   \_| |_/ \_| \_|   \_/        \___/  \_|         \_|      \___/  \_| \_/  \____/   \_/    \___/   \___/  \_| \_/ \____/ 


ScriptNameLocation() {
    # Find where the script resides
    # Get the DirName and ScriptName
    if [ -L "${BASH_SOURCE[0]}" ]; then
        # Get the *real* directory of the script
        ScriptDirName="$(dirname "$(readlink "${BASH_SOURCE[0]}")")"   # ScriptDirName='/usr/local/bin'
        # Get the *real* name of the script
        ScriptName="$(basename "$(readlink "${BASH_SOURCE[0]}")")"     # ScriptName='moodle_backup.sh'
    else
        ScriptDirName="$(dirname "${BASH_SOURCE[0]}")"
        # What is the name of the script?
        ScriptName="$(basename "${BASH_SOURCE[0]}")"
    fi
    ScriptFullName="${ScriptDirName}/${ScriptName}"
}

server_info() {
    ServerInfo="$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "query status")"
    #ServerName="$(echo "$ActlogToday" | grep "Session established with server" | cut -d: -f1 | awk '{print $NF}')"
    ServerName="$(echo "$ServerInfo" | grep "Server Name:" | cut -d: -f2 | sed 's/^ //')"                             # Ex: ServerName='TSM3'
    ActLogLength="$(echo "$ServerInfo" | grep "Activity Log Retention:" | cut -d: -f2 | awk '{print $1}')"            # Ex: ActLogLength=30
    EventLogLength="$(echo "$ServerInfo" | grep "Event Record Retention Period:" | cut -d: -f2 | awk '{print $1}')"   # Ex: EventLogLength=14
}

client_info() {
    ClientInfo="$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "q node $client f=d")"
    ClientVersion="$(echo "$ClientInfo" | grep -E "^\s*Client Version:" | cut -d: -f2 | sed -e 's/ Version //' -e 's/, release /./' -e 's/, level /./' | cut -d. -f1-3)"   # Ex: ClientVersion='8.1.13'
    ClientLastNetworkTemp="$(echo "$ClientInfo" | grep -Ei "^\s*TCP/IP Address:" | cut -d: -f2 | sed -e 's/^ //')"                                                         # Ex: ClientLastNetworkTemp='10.7.58.184'
    case "$(echo "$ClientLastNetworkTemp" | cut -d\. -f1-2)" in
        "130.235") ClientLastNetwork="LU" ;;
        "10.4")    ClientLastNetwork="Static VPN" ;;
        "10.7")    ClientLastNetwork="eduroam (staff)" ;;
        "10.8")    ClientLastNetwork="eduroam (stud.)" ;;
        "10.9")    ClientLastNetwork="eduroam (other)" ;;
        "" )       ClientLastNetwork="Unknown" ;; 
        * )        ClientLastNetwork="outside LU" ;;
    esac 
    case "$(echo "$ClientLastNetworkTemp" | cut -d\. -f1-3)" in
        "130.235.16" ) ClientLastNetwork="CS server net" ;;
        "130.235.17" ) ClientLastNetwork="CS server net" ;;
        "10.0.16"    ) ClientLastNetwork="CS client net" ;;
    esac
    ClientOS="$(echo "$ClientInfo" | grep -Ei "^\s*Client OS Name:" | cut -d: -f3 | sed -e 's/Microsoft //' -e 's/ release//' | cut -d\( -f1)"
    # Get some more info about macOS:
    if [ "$ClientOS" = "Macintosh" ]; then
        OSver="$(echo "$ClientInfo" | grep -Ei "^\s*Client OS Level:" | cut -d: -f2)"
        ClientOS="macOS$OSver"
    fi
    # Ex: ClientOS='Macintosh' / 'Ubuntu 20.04.4 LTS' / 'Windows 10 Education' / 'Fedora release 36' / 'Debian GNU/Linux 10' / 'CentOS Linux 7.9.2009'
    ClientLastAccess="$(echo "$ClientInfo" | grep -Ei "^\s*Last Access Date/Time:" | cut -d: -f2-)"     # Ex: ClientLastAccess='2018-11-01   11:39:06'
    ClientTotalSpaceTemp="$(LANG=en_US dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "q occup $client" | grep "Physical Space Occupied" | cut -d: -f2 | sed 's/,//g' | tr '\n' '+' | sed 's/+$//')"  # Ex: ClientTotalSpaceTemp=' 217155.02+ 5.20+ 1285542.38'
    ClientTotalSpaceUsedMB=$(echo "scale=0; $ClientTotalSpaceTemp" | bc | cut -d. -f1)                                                                                                                  # Ex: ClientTotalSpaceUsedMB=1502702
    ClientTotalNumfilesTemp="$(LANG=en_US dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "q occup $client" | grep "Number of Files" | cut -d: -f2 | sed 's/,//g' | tr '\n' '+' | sed 's/+$//')"       # ClientTotalNumfilesTemp=' 1194850+ 8+ 2442899'
    ClientTotalNumFiles=$(echo "scale=0; $ClientTotalNumfilesTemp" | bc | cut -d. -f1)                                                                                                                  # Ex: ClientTotalNumFiles=1502702
    # The following is no longer used since it's A) wrong and B) awk summaries in scientific notation which is not desirable. Kept here for some reason...
    #ClientTotalSpaceUsedMB="$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "q occup $client" | awk '/Physical Space Occupied/ {print $NF}' | sed 's/,//' | awk '{ sum+=$1 } END {print sum}' | cut -d. -f1)"
    #ClientTotalNumFiles="$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "q occup $client" | awk '/Number of Files/ {print $NF}' | sed 's/,//' | awk '{ sum+=$1 } END {print sum}')"
    # Get the number of file spaces on the client
    ClientNumFilespaces=$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "q filespace $client f=d" | grep -cE "^\s*Filespace Name:")
}

backup_result() {
    # Number of files:
    # (note that some client use a unicode 'non breaking space', e280af, as thousands separator. This must be dealt with!)
    # (also, note that some machines will have more than one line of reporting. We only consider the last one)
    BackedupNumfiles="$(grep ANE4954I $ClientFile | sed 's/\xe2\x80\xaf/,/' | grep -Eo "Total number of objects backed up:\s*[0-9,]*" | awk '{print $NF}' | sed -e 's/,//g' | tail -1)"     # Ex: BackedupNumfiles='3483'
    TransferredVolume="$(grep ANE4961I $ClientFile | grep -Eo "Total number of bytes transferred:\s*[0-9,.]*\s[KMG]?B" | tail -1 | cut -d: -f2 | sed -e 's/\ *//' | tail -1)"               # Ex: TransferredVolume='1,010.32 MB'
    BackedupElapsedtime="$(grep ANE4964I $ClientFile | grep -Eo "Elapsed processing time:\s*[0-9:]*" | tail -1 | awk '{print $NF}' | tail -1)"                                               # Ex: BackedupElapsedtime='00:46:10'
    # So, did it end successfully (ANR2507I)?
    if [ -n "$(grep ANR2507I $ClientFile)" ]; then
        BackupStatus="Successful"
    # Did it end, but unsuccessfully (ANR2579E)?
    elif [ -n "$(grep ANR2579E $ClientFile)" ]; then
        BackupStatus="Conflicted!!"
    else
        # OK, so there has been no backup today (successful or not). 
        # We need to get historical information (i.e. NOT look to ClientFile but rather AllConcludedBackups)
        BackupStatus=""
        # No backup the last day; we need to investiage!
        # Look for ANR2507I in the total history
        LastSuccessfulBackup="$(echo "$AllConcludedBackups" | grep -E "\b${client}\b" | grep ANR2507I | tail -1 | awk '{print $1" "$2}')"      # Ex: LastSuccessfulBackup='08/28/2022 20:01:03'
        EpochtimeLastSuccessful=$(date -d "$LastSuccessfulBackup" +"%s")                                                                       # Ex: EpochtimeLastSuccessful=1661709663
        LastSuccessfulNumDays=$(echo "$((Now - EpochtimeLastSuccessful)) / 81400" | bc)                                                      # Ex: LastSuccessfulNumDays=11
        # The same for ANR2579E:
        LastUnsuccessfulBackup="$(echo "$AllConcludedBackups" | grep -E "\b${client}\b" | grep ANR2579E | tail -1 | awk '{print $1" "$2}')"  # Ex: LastUnsuccessfulBackup='10/18/22 14:07:41'
        EpochtimeLastUnsuccessfulBackup=$(date -d "$LastUnsuccessfulBackup" +"%s")                                                           # Ex: EpochtimeLastUnsuccessful=1666094861
        LastUnsuccessfulNumDays=$(echo "$((Now - EpochtimeLastUnsuccessfulBackup)) / 81400" | bc)                                            # Ex: LastSuccessfulNumDays=1
        # If there is a successful backup in the total history, get when that was
        if [ -n "$LastSuccessfulBackup" ]; then
            if [ $LastSuccessfulNumDays -eq 1 ]; then
                BackupStatus="Yesterday"
            else
                BackupStatus="$LastSuccessfulNumDays days ago"
            fi
        elif [ -n "$LastUnsuccessfulBackup" ]; then
            # there was an unsuccessful backup - report it
            if [ $LastUnsuccessfulNumDays -eq 1 ]; then
                BackupStatus="Yesterday (conflicted)"
            else
                BackupStatus="$LastUnsuccessfulNumDays days ago (conflicted)"
            fi
        elif [ -z "$ClientTotalNumFiles" ] && [ -z "$ClientTotalSpaceUsedMB" ]; then
            BackupStatus="NEVER"
            ErrorMsg="Client \"$client\" has never had a backup"
        else
        # So there is no info about backup but still files on the server. 
            # There is no known backup, but there *are* files on the server, it's "complicated"
            BackupStatus=">${ActLogLength} days"
            #ErrorMsg="No backup in $ActLogLength days but files on server; "
            ErrorMsg="Last contact: $(echo "$ClientLastAccess" | awk '{print $1}'); "
            # Get the number of days since the last contact
            LastContactEpoch=$(date +%s -d "$ClientLastAccess")                   # Ex: LastContactEpoch='1541068746'
            DaysSinceLastContact=$(echo "scale=0; $((Now - LastContactEpoch)) / 86400" | bc -l)
            # Update 2022-10-23: I now know how to get the last date of backup: 
            # Do a 'q filespace $client f=d' and look for "Days Since Last Backup Completed:"
            # Note that it will be one day per filespace (file system)
            NumDaysSinceLastBackupTemp="$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt  "q filespace $client f=d" | grep -E "^\s*Days Since Last Backup Completed:" | cut -d: -f2 | sed 's/[, <]//g' | sort -u)"
            # Ex: NumDaysSinceLastBackupTemp='1
            #     298
            #     339'
            # different way of doing this if we have one or more rows
            if [ $(echo "$NumDaysSinceLastBackupTemp" | wc -l) -eq 1 ]; then
                BackupStatus="Last backup: $NumDaysSinceLastBackupTemp days ago"
                ErrorMsg="Backup is not working!!!; "
            else
                BackupStatus="Last backup: $(echo "$NumDaysSinceLastBackupTemp" | head -1) - $(echo "$NumDaysSinceLastBackupTemp" | tail -1) days ago"
                ErrorMsg="Backup is not working!!!; "
            fi
        fi
    fi
}

error_detection() {
    #ErrorMsg=""
    # First: see if there's no schedule associated with the node
    if [ -z "$(dsmadmc -id=$id -password=$pwd -DISPLaymode=LISt "query schedule * node=$client" 2>/dev/null | grep -Ei "^\s*Schedule Name:")" ]; then
        ErrorMsg+="--- NO SCHEDULE ASSOCIATED ---"
    fi
    if [ -n "$(echo "$DualExecutionsToday" | grep -E "\b$client\b")" ]; then
        ErrorMsg+="Dual executions (investigate!); "
    fi
    if [ -n "$(grep ANE4007E "$ClientFile")" ]; then
        ErrorMsg+="ANE4007E (access denied to object); "
    fi
    if [ -n "$(grep ANR2579E "$ClientFile")" ]; then
        ErrorCodes="$(grep ANR2579E "$ClientFile" | grep -Eio "\(return code -?[0-9]*\)" | sed -e 's/(//' -e 's/)//' | sort -u | tr '\n' ',' | sed -e 's/,c/, c/g' -e 's/,$//')"
        ErrorMsg+="ANR2579E ($ErrorCodes); "
    fi
    if [ -n "$(grep ANR0424W "$ClientFile")" ]; then
        ErrorMsg+="ANR0424W (invalid password submitted); "
    fi
    if [ -n "$(grep ANE4042E "$ClientFile")" ]; then
        ErrorMsg+="ANE4042E (unrecognized characters); "
    fi
}

# Print the result
print_line() {
    printf "$FormatStringConten\n" "$client" "$BackedupNumfiles" "$TransferredVolume" "$BackeupElapsedtime" "${BackupStatus/ERROR/- NO BACKUP -}" "$ClientTotalNumFiles" "$ClientTotalSpaceUsedMB" "${ClientNumFilespaces:-0}" "$ClientVersion" "$ClientLastNetwork" "$ClientOS" "${ErrorMsg%; }" >> $ReportFile
}


#   _____   _   _  ______       _____  ______      ______   _   _   _   _   _____   _____   _____   _____   _   _   _____ 
#  |  ___| | \ | | |  _  \     |  _  | |  ___|     |  ___| | | | | | \ | | /  __ \ |_   _| |_   _| |  _  | | \ | | /  ___|
#  | |__   |  \| | | | | |     | | | | | |_        | |_    | | | | |  \| | | /  \/   | |     | |   | | | | |  \| | \ `--. 
#  |  __|  | . ` | | | | |     | | | | |  _|       |  _|   | | | | | . ` | | |       | |     | |   | | | | | . ` |  `--. \
#  | |___  | |\  | | |/ /      \ \_/ / | |         | |     | |_| | | |\  | | \__/\   | |    _| |_  \ \_/ / | |\  | /\__/ /
#  \____/  \_| \_/ |___/        \___/  \_|         \_|      \___/  \_| \_/  \____/   \_/    \___/   \___/  \_| \_/ \____/ 
#


# Find the location of the script
ScriptNameLocation

# Get the secret password, either from the users home-directory or the script-dir
if [ -f ~/.tsm_secrets.env ]; then
    source ~/.tsm_secrets.env
else
    source "$ScriptDirName"/tsm_secrets.env
fi

# Get basic server info
server_info

# Get the activity log for today (saves time to do it only one)
# Do not include 'ANR2017I Administrator ADMIN issued command:'
ActlogToday="$(dsmadmc -id=$id -password=$pwd -TABdelimited "q act begindate=today begintime=00:00:00 enddate=today endtime=now" | grep -v "ANR2017I")"
# Get a notification if a client have more than one 'ANE4961I'; if so, there are two clients executing and that should be rectified
DualExecutionsToday="$(echo "$ActlogToday" | grep ANE4961I | awk '{print $7}' | sed 's/)//' | sort | uniq -d)"  # Ex: DualExecutionsToday=NIKLAS
# Get all concluded executions (ANR2579E or ANR2507I) the last year. This will save a lot of time later on
AllConcludedBackups="$(dsmadmc -id=$id -password=$pwd -TABdelimited "q act begindate=today-$ActLogLength enddate=today" | grep -E "ANR2579E|ANR2507I")"

echo "$Today: Spectrum Protect backup report for $SELECTION on server $ServerName" > $ReportFile
printf "$FormatStringHeader\n" "CLIENT" "NumFiles" "Transferred" "Duration" "Status" " ∑ files" "Total [MB]" "# FS" "Version" "Client network" "Client OS" "Errors" >> $ReportFile
##printf "$FormatStringHeader\n" "CLIENT" "NumFiles" "Transferred" "Time" "Status" "Total [MB]" " ∑ files" "Version" "Client network" "Client OS" "Errors" >> $ReportFile


# Loop through the list of clients
for client in $CLIENTS
do
    ClientFile="${OutDir}/${client}.out"
    ErrorMsg=""

    # Go for the entire act log instead; if not, we will not get the infamous ANR2579E errors or the ANR2507I conclusion
    echo "$ActlogToday" | grep -Ei "\s$client[ \)]" | grep -E "ANE4954I|ANE4961I|ANE4964I|ANR2579E|ANR2507I|ANE4007E|ANR0424W|ANE4042E" > "$ClientFile"

    # Get client info (version, IP-address and such)
    client_info

    # Look for completion of backup
    backup_result

    # Look for errors:
    error_detection

    # Print the result
    print_line
    #rm $ClientFile
done

# Calculate elapsed time
Then=$(date +%s)
ElapsedTime=$(( Then - Now ))

# Print a finish line
echo "END (time: $((ElapsedTime%3600/60))m $((ElapsedTime%60))s)" >> $ReportFile

# Send an email report
mailx -s "Backuprapport $SELECTION" "$Recipient" < "$ReportFile"
