workdir=/home/lamyrubber

if [ ! -d $workdir ]; then
    mkdir -p $workdir
fi;

function checkspace(){
    part=$1
    needed=$2
    available=$(df $part | tail -n1 | awk '{print $4}');
    let available=$available/1024
    if [ $available -lt $needed ];then
      echo "Less than ${needed}MB free, ${available}MB"
      return 1;
    fi;
}

checkspace / 3 || (echo "Trying to free space..."; journalctl --vacuum-time=1m)
checkspace / 3 || (echo "Aborting..."; exit 10)
checkspace /home 10 || (echo "Not enough space on /home"; exit 10)

echo "Disk space seems to be enough."

trap onexit INT

function onexit(){

    exit 0
}

function purge(){
    echo -n "Remove all traces [Y/n]? "
    read yn
    case $yn in 
        [Nn]* )
            ;;
            * ) 
            rm -fr "$workdir"
            ;;
    esac
    exit 0
}

echo -n "Install Default Version [Y/n]? "
read yn
    case $yn in 
        [Nn]* )
            ;;
            * ) 
            currentVersion = "20210501"
            ;;
    esac
    exit 0

case $currentVersion in
    "20210501" )
        rubber_file_name=lamy-rubber.tar
        version="20210501"
        rubberhash="2126c161f3c8ea26c875c79da2868ceb513a4c89"
        echo "$rubber_file_name - $version"
        ;;
    * )
        echo "The version the device is running is not supported, yet. $currentVersion"
        exit 1
        ;;
esac

if [ $rubber_file_name == "purge" ]; then
    purge
    exit 0
fi

rm -rf $workdir/*

if [ -z "$SKIP_DOWNLOAD" ]; then
    wget "https://github.com/honkaadam/reMarkable-Lamy-Rubber/raw/master/version/$version/$rubber_file_name" -O "$workdir/$rubber_file_name" || exit 1
fi

hash=$(sha1sum $workdir/$rubber_file_name | cut -c 1-40)
if [ "$rubberhash" != "$hash" ]; then
    echo "The $workdir/$rubber_file_name is corrupt, cowardly aborting..."
    exit 1
fi

tar xf $workdir/$rubber_file_name
mv $workdir/rubber/* $workdir
rm -rf rubber
rm -rf $workdir/$rubber_file_name

chmod +x $workdir/rubber.sh
chmod +x $workdir/bin/*
chmod +x $workdir/sbin/*
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/$workdir/lib/