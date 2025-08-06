echo You are about to create a client to access this server, please provide name for client:
read CLIENTNAME
sudo docker run -v vol_ovpn:/etc/openvpn --rm -it buildtovpn easyrsa build-client-full $CLIENTNAME nopass
sudo docker run -v vol_ovpn:/etc/openvpn --rm -it buildtovpn ovpn_getclient $CLIENTNAME > ~/$CLIENTNAME.ovpn
~/$CLIENTNAME
sed -i "/redirect-gateway def1/d" "$HOME/$CLIENTNAME"