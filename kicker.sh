#! /bin/bash

startGamePath='/tmp/start.kicker'
stopGamePath='/tmp/stop.kicker'

firstGatePath='/tmp/gate1.kicker'
secondGatePath='/tmp/gate2.kicker'

revertFirstPath='/tmp/revert1.kicker'
revertSecondPath='/tmp/revert2.kicker'

echo "0" > ${startGamePath}
echo "0" > ${stopGamePath}
echo "0" > ${firstGatePath}
echo "0" > ${secondGatePath}
echo "0" > ${revertFirstPath}
echo "0" > ${revertSecondPath}

touch /tmp/kicker.log

api='curl -T /tmp/kicker.log -X PUT -H "Content-Type: application/json" http://kicker.lan:3000/put'

while :; do
    
    echo -ne "Waiting for new game... \033[0K\r"
    
    startGame=$(< ${startGamePath})
    
    firstPlayerScore=0
    secondPlayerScore=0
    
    if [ $startGame -eq 1 ]; then
        
        echo "Game started! GL&HF..."
        
        while [ $firstPlayerScore -lt 10 ] | [ $secondPlayerScore -lt 10 ]; do
            
            firstGate=$(< ${firstGatePath})
            secondGate=$(< ${secondGatePath})
            
            if ! [ $firstGate -eq 0 ]; then
                (( secondPlayerScore++ ))
                $($api -D "{'secondPlayer': ${secondPlayerScore}}")
                echo "sensor value: ${firstGate}"
                echo "0" > ${firstGatePath} # remove on prod
                sleep 2
                elif ! [ $secondGate -eq 0 ]; then
                (( firstPlayerScore++ ))
                $($api -D "{'firstPlayerScore': ${firstPlayerScore}}")
                echo "sensor value: ${secondGate}"
                echo "0" > ${secondGatePath} # remove on prod
                sleep 2
            fi
            unset firstGate
            unset secondGate
            
            echo -ne "Score: ${firstPlayerScore} - ${secondPlayerScore} \033[0K\r"
            
            revertFirst=$(< ${revertFirstPath})
            revertSecond=$(< ${revertSecondPath})
            stopGame=$(< ${stopGamePath})
            
            if ! [ $revertFirst -eq 0 ]; then
                (( firstPlayerScore-- ))
                $($api -D "{'firstPlayerScore': ${firstPlayerScore}}")
                echo "0" > ${revertFirstPath} # remove on prod
                elif ! [ $revertSecond -eq 0 ]; then
                (( secondPlayerScore-- ))
                $($api -D "{'secondPlayer': ${secondPlayerScore}}")
                echo "0" > ${revertSecondPath} # remove on prod
                elif ! [ $stopGame -eq 0 ]; then
                echo "Cancel game!"
                echo "0" > ${stopGamePath}
                break
            fi
            sleep 0.1
        done
        
    fi
    if ! [ $firstPlayerScore -lt 10 ]; then
        echo "Player1: Winner!"
        elif ! [ $secondPlayerScore -lt 10 ]; then
        echo "Player2: Winner!"
    fi
    unset startGame
    echo 0 > $startGamePath
    
    sleep 1
done
exit 0
