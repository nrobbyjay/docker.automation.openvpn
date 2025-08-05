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

sudo docker compose -d up

#keycreation.sh will be created and the build repo will be deleted
cd ~
sudo rm -rf docker.automation.openvpn

#keycreation.sh
echo "echo You are about to create a client to access this server, please provide name for client:
read CLIENTNAME
sudo docker run -v vol_ovpn:/etc/openvpn --rm -it buildtovpn easyrsa build-client-full $CLIENTNAME nopass
sudo docker run -v vol_ovpn:/etc/openvpn --rm -it buildtovpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn" > keycreation.sh
sudo chmod +x keycreation.sh