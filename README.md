# OPENVPN-client-script

Script de instalación de cliente OpenVPN para servidores Debian. Un script interactivo simple para instalar el cliente OpenVPN en su servidor y agregar su archivo de configuración client.ovpn a la conexión. Debe tener el archivo client.ovpn ya generado en su servidor. El script instalará todos los archivos necesarios y le solicitará la ruta a su archivo, por ejemplo /home/server/client.ovpn

Copie y pegue esto en su terminal:

wget https://raw.githubusercontent.com/pyopower/OPENVPN-client-script/main/openvpn_client.sh && chmod +x openvpn_client.sh && sudo ./openvpn_client.sh

Tenga en cuenta que una vez iniciado el cliente todos los puertos y conexiones apuntarán a la IP de su servidor OPENVPN incluida la conexión ssh.
Si no ha elegido en el menú interactivo la opción "habilitar inicio automático" el cliente ovpn no se conectará en el próximo reinicio del servidor.
