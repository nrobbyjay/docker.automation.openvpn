sudo apt update && sudo apt upgrade -y
git --version >/dev/null 2>&1 || echo "error: git is not installed"
docker --version >/dev/null 2>&1 || echo "error: git is not installed"

if ! docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -wq buildtovpn; then
 git clone https://github.com/kylemanna/docker-openvpn.git
 cd docker-openvpn
 sudo docker buildx build -t buildtovpn .
fi

if ! docker volume ls --format '{{.Name}}' | grep -wq 'vol_ovpn'; then
 sudo docker volume create vol_ovpn
 sudo docker run --rm -v vol_ovpn buildtovpn ovpn_genconfig -u udp://$(curl ifconfig.me)
 sudo docker run --rm -v vol_ovpn buildtovpn ovpn_genconfig ovpn_initpki
fi

sudo docker compose up