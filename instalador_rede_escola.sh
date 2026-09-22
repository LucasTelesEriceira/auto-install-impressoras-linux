#!/bin/bash

# ==============================================================================
# Automatização Completa: Impressoras da Escola
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "ERRO: Por favor, execute este script como Administrador (sudo)."
  echo "Comando: sudo ./instalador_rede_escola.sh"
  exit
fi

echo "========================================================"
echo "   INSTALADOR AUTOMÁTICO: REDE DE IMPRESSORAS ESCOLA"
echo "========================================================"
echo ""

USUARIO_REAL=$(logname)

echo "[1/4] Verificando e Instalando Drivers Base (Pode demorar alguns minutos)..."
# Instala drivers da Brother e da Epson apenas (Canon GX7010 será instalada via rede Driverless nativa)
su - $USUARIO_REAL -c "pamac build --no-confirm brother-dcpl2540dw-lpr brother-dcpl2540dw-cups-wrapper epson-inkjet-printer-escpr"

echo ""
echo "[2/4] Iniciando Serviço de Impressão (CUPS)..."
systemctl start cups

# Função auxiliar para instalar impressoras
instalar_impressora() {
    NOME=$1
    IP=$2
    MODELO=$3
    PPD=$4
    
    echo " -> Configurando: $NOME ($MODELO) no IP $IP"
    lpadmin -x "$NOME" 2>/dev/null
    
    # Se o PPD for 'everywhere', instalamos via IPP
    if [ "$PPD" == "everywhere" ]; then
        lpadmin -p "$NOME" -E -v "ipp://$IP/ipp/print" -m everywhere -D "$MODELO" -o media=A4 -o PageSize=A4
    elif [[ "$PPD" == /* ]]; then
        # Caminho absoluto para o arquivo PPD (ex: Brother)
        lpadmin -p "$NOME" -E -v "socket://$IP:9100" -P "$PPD" -D "$MODELO" -o media=A4 -o PageSize=A4
    else
        # PPD interno do sistema listado pelo lpinfo
        lpadmin -p "$NOME" -E -v "socket://$IP:9100" -m "$PPD" -D "$MODELO" -o media=A4 -o PageSize=A4
    fi
}

echo ""
echo "[3/4] Instalando e Configurando Impressoras..."

# 1. Secretaria I
instalar_impressora "EFS_SEC_I" "192.168.1.20" "Canon MAXIFY GX7010" "everywhere"

# 2. Secretaria II
instalar_impressora "EFS_SEC_II" "192.168.1.36" "Canon MAXIFY GX7010" "everywhere"

# 3. Administração
instalar_impressora "EFS_ADM" "192.168.1.53" "Canon MAXIFY GX7010" "everywhere"

# 4. Ensino Fundamental (EF)
instalar_impressora "EFS_EF" "192.168.1.80" "EPSON L3250" "lsb/usr/epson-inkjet-printer-escpr/Epson-L3250_Series-epson-escpr-en.ppd"

# 5. Ensino Infantil (EI) BROTHER
instalar_impressora "EFS_EI_BROTHER" "192.168.1.43" "BROTHER DCP-L2540DW" "/opt/brother/Printers/DCPL2540DW/cupswrapper/brother-DCPL2540DW-cups-en.ppd"

# 6. Ensino Infantil (EI) EPSON (IP Desconhecido)
echo ""
echo "Aviso: A impressora 'EFS_EI_EPSON' (EPSON L4260) estava sem IP cadastrado."
read -p "Você já sabe o IP atual dela? (Digite o IP ou deixe em branco para pular): " IP_EPSON_EI

if [ -n "$IP_EPSON_EI" ]; then
    instalar_impressora "EFS_EI_EPSON" "$IP_EPSON_EI" "EPSON L4260" "lsb/usr/epson-inkjet-printer-escpr/Epson-L4260_Series-epson-escpr-en.ppd"
else
    echo " -> Instalação da EFS_EI_EPSON ignorada. Você pode adicioná-la depois."
fi

echo ""
echo "[4/4] Finalizando Configurações..."
systemctl restart cups

echo "========================================================"
echo "   ✅ Instalação Concluída com Sucesso!"
echo "   Todas as impressoras foram configuradas na rede."
echo "========================================================"
echo ""
echo "Resumo das impressoras e configuração de folha (A4):"
echo "--------------------------------------------------------"
for printer in $(lpstat -p | awk '{print $2}'); do
    echo "🖨️  Impressora: $printer"
    
    # Extrai a configuração de tamanho do papel, e pega apenas o valor que vem depois de media=
    TAMANHO=$(lpoptions -p "$printer" | grep -o 'media=[^ ]*' | cut -d'=' -f2)
    echo "    Tamanho do Papel configurado: $TAMANHO"
    echo "--------------------------------------------------------"
done
echo ""
echo "Tudo pronto! Você já pode fechar o terminal."
