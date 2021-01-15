pid=$(ps -ef |grep lotus-miner |grep -v grep |awk '{print $2}')
kill -9 ${pid}
cd /root
nohup ./lotus-miner run --nosync &> miner.log &

