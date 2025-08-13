sudo docker compose -f openvpn.yaml down
sudo docker compose -f portainer.yaml down
sudo docker compose -f code.yaml down

sudo docker image rm buildtovpn
sudo docker volume rm vol_ovpn
sudo docker network rm ovpn_net

sudo docker volume rm portainer_data