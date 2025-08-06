sudo apt update && sudo apt upgrade -y
git --version >/dev/null 2>&1 || echo "error: git is not installed"
docker --version >/dev/null 2>&1 || echo "error: git is not installed"
ipcalc --version >/dev/null 2>&1 || echo "error: ipcalc is not installed"

if ! docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -wq buildtovpn; then
 git clone https://github.com/kylemanna/docker-openvpn.git
 cd docker-openvpn
 sudo docker buildx build -t buildtovpn .
 cd ..
 rm docker-openvpn.git -rf
fi

if ! docker volume ls --format '{{.Name}}' | grep -wq 'vol_ovpn'; then
 sudo docker volume create vol_ovpn
 PUBLIC_IP=$(curl -s ifconfig.me)
 sudo docker run --rm -v vol_ovpn:/etc/openvpn buildtovpn ovpn_genconfig -u udp://$PUBLIC_IP
 sudo docker run -it --rm -v vol_ovpn:/etc/openvpn buildtovpn ovpn_initpki
 #create method to export docker bridge + redirect net traffic to client network instead of vpn tunnel
 DOCKERNETWORKBRIDGE=$(sudo docker network inspect bridge --format '{{(index .IPAM.Config 0).Subnet}}')
 NETWORK=$(ipcalc $DOCKERNETWORKBRIDGE | awk -F: '/Address/ {print $2}' | awk '{print $1}')
 SUBNET=$(ipcalc $DOCKERNETWORKBRIDGE | awk -F: '/Netmask/ {print $2}' | awk '{print $1}')

CMD='sed -i "/push \"block-outside-dns\"/d" /etc/openvpn/openvpn.conf'
sudo docker run --rm -v vol_ovpn:/etc/openvpn buildtovpn sh -c "$CMD"

CMD='sed -i "/push \"dhcp-option DNS 8.8.4.4\"/d" /etc/openvpn/openvpn.conf'
sudo docker run --rm -v vol_ovpn:/etc/openvpn buildtovpn sh -c "$CMD"

CMD='sed -i "/push \"dhcp-option DNS 8.8.8.8\"/d" /etc/openvpn/openvpn.conf'
sudo docker run --rm -v vol_ovpn:/etc/openvpn buildtovpn sh -c "$CMD"

CMD="echo \"push \\\"route ${NETWORK} ${SUBNET}\\\"\" >> /etc/openvpn/openvpn.conf"

sudo docker run --rm -v vol_ovpn:/etc/openvpn buildtovpn sh -c "$CMD"
fi

sudo chmod +x newclient.sh
sudo chmod +x removeserver.sh
sudo docker compose up -d