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
 PUBLIC_IP=$(curl -s ifconfig.me)
 sudo docker run --rm -v vol_ovpn:/etc/openvpn buildtovpn ovpn_genconfig -u udp://$PUBLIC_IP
 sudo docker run -it --rm -v vol_ovpn:/etc/openvpn buildtovpn ovpn_initpki
fi

cd ~
sudo rm -rf docker.automation.openvpn

echo "services:
 ovpn:
  image: buildtovpn
  ports:
   - 1194:1194/udp
  volumes:
   - vol_ovpn:/etc/openvpn
  cap_add:
   - NET_ADMIN
  restart: unless-stopped

volumes:
 vol_ovpn:
  external: true" > docker-compose.yaml

echo "echo You are about to create a client to access this server, please provide name for client:
read CLIENTNAME
sudo docker run -v vol_ovpn:/etc/openvpn --rm -it buildtovpn easyrsa build-client-full $CLIENTNAME nopass
sudo docker run -v vol_ovpn:/etc/openvpn --rm -it buildtovpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn" > keycreation.sh
sudo chmod +x keycreation.sh

sudo docker compose up -d