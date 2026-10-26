# system-monitoring 미션 수행 내역서

## 1. SSH 포트 변경 및 Root 원격 접속 차단

#### 수행 내용

SSH 접속 포트를 기본 포트에서 `20022`로 변경하고, Root 계정의 원격 SSH 접속을 차단하였다.

#### 설정 파일

```text
/etc/ssh/sshd_config
```

#### 수행 명령어

```bash
sudo nano /etc/ssh/sshd_config
```

SSH 설정에서 다음과 같이 수정하였다.

```text
Port 20022
PermitRootLogin no
```

설정 적용 후 SSH 서비스를 재시작하였다.

```bash
sudo systemctl restart ssh
```

#### 확인 명령어

```bash
sudo systemctl status ssh
```

```bash
ss -tulnp | grep 20022
```

#### 확인 내역

* SSH 서비스가 정상적으로 실행 중임을 확인하였다.
* `20022/tcp` 포트가 LISTEN 상태임을 확인하였다.
* Root 원격 접속 차단 설정을 확인하였다.

#### 증거자료

![pics](증거자료1.png)
![pics](증거자료2.png)
![pics](증거자료3.png)

---

## 2. 방화벽(UFW) 활성화 및 허용 포트 설정

#### 수행 내용

UFW 방화벽을 활성화하고 외부에서 허용되는 포트를 `20022/tcp`와 `15034/tcp`로 설정하였다.

#### 수행 명령어

```bash
sudo ufw enable
```

```bash
sudo ufw allow 20022/tcp
```

```bash
sudo ufw allow 15034/tcp
```

#### 확인 명령어

```bash
sudo ufw status
```

또는

```bash
sudo ufw status numbered
```

#### 확인 내역

UFW가 활성화(`Status: active`)되어 있는지 확인하고 다음 포트의 허용 규칙을 확인하였다.

```text
20022/tcp
15034/tcp
```

실제 확인 결과 UFW가 `active` 상태임을 확인하였다.

#### 증거자료

![pics](증거자료4.png)


---

## 3. 계정 및 그룹 생성

### 3.1 사용자 계정

#### 수행 내용

미션에서 요구하는 다음 계정을 생성하였다.

```text
agent-admin
agent-dev
agent-test
```

#### 수행 명령어

```bash
sudo useradd -m agent-admin
sudo useradd -m agent-dev
sudo useradd -m agent-test
```

필요한 경우 비밀번호를 설정하였다.

```bash
sudo passwd agent-admin
sudo passwd agent-dev
sudo passwd agent-test
```

#### 확인 명령어

```bash
id agent-admin
id agent-dev
id agent-test
```

### 3.2 그룹 생성

#### 수행 내용

다음 그룹을 생성하였다.

```text
agent-common
agent-core
```

#### 수행 명령어

```bash
sudo groupadd agent-common
sudo groupadd agent-core
```

계정별 그룹을 구성하였다.

```bash
sudo usermod -aG agent-common agent-admin
sudo usermod -aG agent-common agent-dev
sudo usermod -aG agent-common agent-test

sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev
```

#### 확인 명령어

```bash
id agent-admin
id agent-dev
id agent-test
```

#### 확인 내역

실제 `agent-admin` 계정 확인 결과:

```text
uid=1001(agent-admin) gid=1001(agent-admin)
groups=1001(agent-admin),1004(agent-common),1005(agent-core)
```

따라서 `agent-admin`이 `agent-common`, `agent-core` 그룹에 정상적으로 포함되어 있음을 확인하였다.

#### 증거자료

![pics](증거자료5.png)


---

## 4. 디렉터리 구조 및 권한 설정

#### 수행 내용

Agent 애플리케이션의 디렉터리 구조를 구성하고 사용자 및 그룹별 접근 권한을 설정하였다.

주요 디렉터리:

```text
/home/agent-dev/agent-app/
├── upload_files/
├── api_keys/
└── bin/
    └── monitor.sh

/var/log/agent-app/
└── monitor.log
```

#### 권한 설정

`monitor.sh`는 `agent-dev`가 작성하고 `agent-core` 그룹에서 실행할 수 있도록 설정하였다.

#### 확인 명령어

```bash
ls -l /home/agent-dev/agent-app/bin/monitor.sh
```

#### 확인 결과

```text
-rwxr-x--- 1 agent-dev agent-core 1556 monitor.sh
```

따라서:

* 소유자: `agent-dev`
* 그룹: `agent-core`
* 권한: `750`

으로 설정되어 있음을 확인하였다.

---

## 5. 환경변수 설정

#### 수행 내용

Agent 애플리케이션 실행에 필요한 환경변수를 설정하였다.

주요 환경변수:

```text
AGENT_HOME
AGENT_PORT
AGENT_UPLOAD_DIR
AGENT_KEY_PATH
AGENT_LOG_DIR
```

#### 설정 예시

```bash
export AGENT_HOME=/home/agent-dev/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
```

#### 확인 명령어

```bash
echo $AGENT_HOME
echo $AGENT_PORT
echo $AGENT_UPLOAD_DIR
echo $AGENT_KEY_PATH
echo $AGENT_LOG_DIR
```

---

## 6. 앱 Boot Sequence 5단계 확인

#### 수행 내용

Agent 애플리케이션을 실행하여 Boot Sequence 5단계의 상태를 확인하였다.

#### 확인 항목

```text
[1/5] ...
[2/5] ...
[3/5] ...
[4/5] ...
[5/5] ...
```

모든 단계가 `[OK]` 상태인지 확인하였다.

#### 증거자료

![pics](증거자료6.png)

---

## 7. monitor.sh 실행 결과

#### 수행 내용

시스템 상태를 점검하는 `monitor.sh`를 실행하여 프로세스, 포트, CPU, 메모리, 디스크 및 경고 상태를 확인하였다.

#### 실행 경로

```bash
/home/agent-dev/agent-app/bin/monitor.sh
```

#### 프로세스 확인 결과

```text
[HEALTH CHECK]
Checking process 'agent_app.py'. [OK]
```

Agent 애플리케이션 프로세스가 정상적으로 실행 중임을 확인하였다.

#### 포트 확인 결과

```text
Checking port 15034. [OK]
```

15034 포트가 정상적으로 사용 중임을 확인하였다.

#### 리소스 확인 결과

```text
[RESOURCE MONITORING]
CPU Usage : 6.9%
MEM Usage : 7.2%
DISK Used : 17%
```

CPU, 메모리, 디스크 사용량이 정상적으로 출력되는 것을 확인하였다.

#### 경고 확인

UFW 상태 확인 과정에서 일반 사용자 권한으로 확인할 수 없는 경우에도 스크립트가 종료되지 않고 경고를 출력하도록 구성하였다.

#### 증거자료

![pics](증거자료9.png)

---

## 8. monitor.log 누적 기록 확인

#### 로그 파일

```text
/var/log/agent-app/monitor.log
```

#### 확인 명령어

```bash
tail -n 5 /var/log/agent-app/monitor.log
```

#### 확인 결과

최근 로그에 다음과 같이 시간, PID, CPU, MEM, DISK 사용량이 기록되어 있음을 확인하였다.

```text
[2026-07-30 13:41:48] PID:1112 1113 CPU:6.7% MEM:10.6% DISK_USED:16%
[2026-07-30 13:51:15] PID:1112 1113 CPU:6.9% MEM:8.7% DISK_USED:16%
```

#### 실시간 확인

```bash
tail -f /var/log/agent-app/monitor.log
```

`monitor.log`에 새로운 로그가 추가되는 과정을 실시간으로 확인하였다.

#### 확인 내역

`monitor.sh` 실행 결과가 `/var/log/agent-app/monitor.log`에 시간순으로 누적 기록되는 것을 확인하였다.

#### 증거자료

![pics](증거자료7.png)


---

## 9. cron 등록 설정

#### 수행 내용

`agent-admin` 계정의 crontab에 `monitor.sh`를 매분 실행하도록 등록하였다.

#### 실행 계정

```text
agent-admin
```

#### 등록 명령어

```bash
crontab -e
```

#### 등록 내용

```cron
* * * * * /home/agent-dev/agent-app/bin/monitor.sh
```

#### 등록 확인

```bash
crontab -l
```

---

## 10. cron 자동 실행 및 로그 증가 확인

#### 수행 내용

cron 등록 이후 `monitor.sh`가 실제로 매분 자동 실행되는지 확인하였다.

#### 실시간 로그 확인

```bash
tail -f /var/log/agent-app/monitor.log
```

cron 등록 후 1분 이상 대기하여 새로운 로그 라인이 자동으로 추가되는지 확인하였다.

#### 증거자료

![pics](증거자료8.png)


---

#### 자동화 스크립트 소스코드

```text

#!/usr/bin/env bash
set -u

LOG_FILE="/var/log/agent-app/monitor.log"
APP_NAME="agent-app-linux-arm64"
PORT=15034
MAX_LOG_SIZE=10485760  # 10 MiB

# 프로세스 또는 포트 이상 여부를 저장한다.
STATUS=0

log() {
    printf '%s [%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" \
        | tee -a "$LOG_FILE"
}

# 로그 파일이 10 MiB 이상이면 회전한다.
# 보관 로그는 monitor.log.1 ~ monitor.log.10까지 최대 10개.
if [[ -f "$LOG_FILE" ]]; then
    LOG_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)

    if (( LOG_SIZE >= MAX_LOG_SIZE )); then
        rm -f "${LOG_FILE}.10"

        for i in {9..1}; do
            if [[ -f "${LOG_FILE}.${i}" ]]; then
                mv -f "${LOG_FILE}.${i}" \
                    "${LOG_FILE}.$((i+1))"
            fi
        done

        mv -f "$LOG_FILE" "${LOG_FILE}.1"
    fi
fi

# 1. 애플리케이션 프로세스 확인
if pgrep -u agent-admin -f "$APP_NAME" >/dev/null; then
    log INFO "Agent process is running."
else
    log WARN "Agent process is NOT running."
    STATUS=1
fi

# 2. TCP 포트 확인
if ss -ltnH "sport = :$PORT" | grep -q .; then
    log INFO "TCP port $PORT is listening."
else
    log WARN "TCP port $PORT is NOT listening."
    STATUS=1
fi

# 3. 방화벽 확인: 경고만 기록하고 STATUS는 변경하지 않는다.
if command -v ufw >/dev/null 2>&1; then
    if sudo -n /usr/sbin/ufw status 2>/dev/null \
        | grep -q "Status: active"; then
        log INFO "UFW firewall is active."
    else
        log WARN "UFW firewall is inactive or status unavailable."
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state 2>/dev/null | grep -q running; then
        log INFO "firewalld is active."
    else
        log WARN "firewalld is inactive."
    fi
else
    log WARN "No supported firewall command found."
fi

# 4. CPU, 메모리, 디스크 사용량 확인
CPU=$(LC_ALL=C top -bn1 |
    awk -F'[, ]+' '/Cpu\(s\)/ {
        for (i=1; i<=NF; i++)
            if ($i ~ /id/) {
                print 100-$(i-1)
                exit
            }
    }')

MEM=$(free | awk '/Mem:/ {
    if ($2 > 0)
        printf "%.1f", $3/$2*100
    else
        print "0"
}')

DISK_USED=$(df -P / |
    awk 'NR==2 {gsub("%","",$5); print $5}')

log INFO "CPU=${CPU:-unknown}% MEM=${MEM:-unknown}% DISK_USED=${DISK_USED:-unknown}%"

# 임계치 초과는 경고만 기록한다.
if [[ ${CPU:-} =~ ^[0-9]+([.][0-9]+)?$ ]] &&
    awk "BEGIN {exit !($CPU > 20)}"; then
    log WARN "CPU usage exceeds 20%."
fi

if [[ ${MEM:-} =~ ^[0-9]+([.][0-9]+)?$ ]] &&
    awk "BEGIN {exit !($MEM > 10)}"; then
    log WARN "Memory usage exceeds 10%."
fi

if [[ ${DISK_USED:-} =~ ^[0-9]+$ ]] &&
    (( DISK_USED > 80 )); then
    log WARN "Disk usage exceeds 80%."
fi

# 5. 모든 점검 후 최종 종료 코드 반환
if (( STATUS != 0 )); then
    log WARN "Monitoring completed with process/port errors."
else
    log INFO "Monitoring completed successfully."
fi

exit "$STATUS"

```
