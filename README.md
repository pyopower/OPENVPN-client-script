# OPENVPN-client-script
Openvpn client installation script for debian servers.
A simple interactive script to install OPENVPN client on your server and add your client.ovpn configuration file to the connection.
You must have the client.ovpn file already generated on your server.The script will install all the necessary files and ask you for the path to your file,for example /home/server/client.ovpn

Copy and paste this into your terminal:

wget https://raw.githubusercontent.com/pyopower/OPENVPN-client-script/main/openvpn_client.sh && chmod +x openvpn_client.sh && sudo ./openvpn_client.sh

