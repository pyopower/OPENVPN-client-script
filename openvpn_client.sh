#!/bin/bash

# Detectar el sistema operativo
detectar_so() {
  if [[ -f /etc/debian_version ]]; then
    SO="debian"
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
      SO="ubuntu"
    else
      SO="desconocido"
    fi
  else
    SO="desconocido"
  fi
}

# Función para mostrar el menú
mostrar_menu() {
  detectar_so
  echo "--- Menú OpenVPN (${SO}) ---"
  echo "1. Instalar OpenVPN y configurar conexión"
  echo "2. Iniciar conexión VPN"
  echo "3. Detener conexión VPN"
  echo "4. Habilitar inicio automático"
  echo "5. Deshabilitar inicio automático"
  echo "6. Verificar estado de la conexión"
  echo "7. Gestionar perfiles VPN"
  echo "8. Salir"
  read -p "Seleccione una opción: " opcion
  case "$opcion" in
  1)
    instalar_openvpn
    ;;
  2)
    mostrar_menu_ovpn iniciar_vpn
    ;;
  3)
    mostrar_menu_ovpn detener_vpn
    ;;
  4)
    mostrar_menu_ovpn habilitar_autoinicio
    ;;
  5)
    mostrar_menu_ovpn deshabilitar_autoinicio
    ;;
  6)
    verificar_conexion
    ;;
  7)
    menu_perfiles
    ;;
  8)
    echo "Saliendo..."
    exit 0
    ;;
  *)
    echo "Opción no válida."
    mostrar_menu
    ;;
  esac
}

# Función para mostrar el menú de archivos .ovpn
mostrar_menu_ovpn() {
  local funcion=$1
  local archivos=($(ls /etc/openvpn/client/*.ovpn 2>/dev/null))
  if [[ ${#archivos[@]} -eq 0 ]]; then
    echo "No se encontraron archivos .ovpn en /etc/openvpn/client/."
    return
  fi
  local perfil_activo=$(systemctl list-units --type=service | grep openvpn-client@ | awk '{print $1}' | cut -d '@' -f 2 | cut -d '.service' -f 1)
  if [[ -n "$perfil_activo" && "$funcion" == "detener_vpn" ]]; then
    echo "Perfil activo: $perfil_activo"
    $funcion "$perfil_activo"
    return
  fi
  echo "Seleccione un archivo .ovpn:"
  for ((i=0; i<${#archivos[@]}; i++)); do
    local nombre_archivo=$(basename "${archivos[$i]}" .ovpn)
    local estado=""
    if [[ "$nombre_archivo" == "$perfil_activo" ]]; then
      estado=" (activo)"
    fi
    echo "$((i+1)). $nombre_archivo$estado"
  done
  read -p "Ingrese el número de la opción: " opcion
  if [[ "$opcion" -ge 1 && "$opcion" -le ${#archivos[@]} ]]; then
    local nombre_archivo=$(basename "${archivos[$((opcion-1))]}" .ovpn)
    $funcion "$nombre_archivo"
  else
    echo "Opción no válida."
  fi
}

# Función para instalar OpenVPN
instalar_openvpn() {
  echo "Actualizando repositorios e instalando OpenVPN..."
  sudo apt update
  sudo apt install -y openvpn
  read -e -p "Ingrese la ruta completa del archivo .ovpn: " archivo_ovpn
  if [[ -f "$archivo_ovpn" ]]; then
    sudo cp "$archivo_ovpn" /etc/openvpn/client/
    nombre_archivo=$(basename "$archivo_ovpn" .ovpn)
    cat <<EOF | sudo tee /etc/systemd/system/openvpn-client@${nombre_archivo}.service > /dev/null
[Unit]
Description=OpenVPN client for %i
After=network-online.target
Wants=network-online.target
[Service]
Type=forking
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/client/%i.ovpn
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable openvpn-client@${nombre_archivo}.service
    echo "Conexión OpenVPN configurada."
  else
    echo "El archivo .ovpn no existe."
  fi
}

# Función para iniciar la conexión VPN
iniciar_vpn() {
  sudo systemctl start openvpn-client@$1.service
  echo "Conexión VPN iniciada."
}

# Función para detener la conexión VPN
detener_vpn() {
  sudo systemctl stop openvpn-client@$1.service
  echo "Conexión VPN detenida."
}

# Función para habilitar el inicio automático
habilitar_autoinicio() {
  sudo systemctl enable openvpn-client@$1.service
  echo "Inicio automático habilitado."
}

# Función para deshabilitar el inicio automático
deshabilitar_autoinicio() {
  sudo systemctl disable openvpn-client@$1.service
  echo "Inicio automático deshabilitado."
}

# Función para verificar la conexión
verificar_conexion() {
  if ip a | grep -q tun0; then
    echo "La interfaz tun0 está activa. Conexión VPN establecida."
    echo "Su IP pública es:"
    curl ifconfig.me
  else
    echo "La interfaz tun0 no está activa. La conexión VPN no se ha establecido."
  fi
}

# Función para gestionar perfiles
menu_perfiles() {
  echo "--- Gestión de perfiles VPN ---"
  echo "1. Agregar perfil"
  echo "2. Eliminar perfil"
  echo "3. Volver al menú principal"
  read -p "Seleccione una opción: " opcion
  case "$opcion" in
  1)
    agregar_perfil
    ;;
  2)
    eliminar_perfil
    ;;
  3)
    mostrar_menu
    ;;
  *)
    echo "Opción no válida."
    menu_perfiles
    ;;
  esac
}

# Función para agregar perfil
agregar_perfil() {
  read -e -p "Ingrese la ruta completa del archivo .ovpn: " archivo_ovpn
  if [[ -f "$archivo_ovpn" ]]; then
    sudo cp "$archivo_ovpn" /etc/openvpn/client/
    nombre_archivo=$(basename "$archivo_ovpn" .ovpn)
    cat <<EOF | sudo tee /etc/systemd/system/openvpn-client@${nombre_archivo}.service > /dev/null
[Unit]
Description=OpenVPN client for %i
After=network-online.target
Wants=network-online.target
[Service]
Type=forking
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/client/%i.ovpn
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable openvpn-client@${nombre_archivo}.service
    echo "Perfil VPN agregado."
  else
    echo "El archivo .ovpn no existe."
  fi
}

# Función para eliminar perfil
eliminar_perfil() {
  mostrar_menu_ovpn eliminar_perfil_seleccionado
}

# Función para eliminar perfil seleccionado
eliminar_perfil_seleccionado() {
  sudo rm /etc/openvpn/client/$1.ovpn
  sudo systemctl disable openvpn-client@$1.service
  sudo rm /etc/systemd/system/openvpn-client@$1.service
  sudo systemctl daemon-reload
  echo "Perfil VPN eliminado."
}

# Iniciar el menú
mostrar_menu

