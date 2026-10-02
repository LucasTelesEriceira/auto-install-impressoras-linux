#!/bin/bash

# ==============================================================================
# Automatização Completa: Impressoras (Com Configuração Externa JSON)
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "ERRO: Por favor, execute este script como Administrador (sudo)."
  echo "Comando: sudo ./instalador_rede_escola.sh"
  exit
fi

# Verifica se o arquivo JSON existe no mesmo diretório
JSON_FILE="impressoras.json"
if [ ! -f "$JSON_FILE" ]; then
    echo "ERRO: Arquivo '$JSON_FILE' não encontrado no diretório atual!"
    echo "Certifique-se de baixar o repositório completo ou criar o arquivo JSON."
    exit 1
fi

echo "========================================================"
echo "   INSTALADOR AUTOMÁTICO: IMPRESSORAS (VERSÃO JSON)"
echo "========================================================"
echo ""

# Usamos o SUDO_USER para saber qual usuário chamou o sudo, ou caímos pro logname
USUARIO_REAL=${SUDO_USER:-$(logname)}

echo "[1/4] Verificando e Instalando Drivers Base e Utilitários..."
# Instala drivers da Brother e da Epson apenas (Canon GX7010 usa Driverless)
# Substituímos pamac build por yay (que lida melhor com execução não-interativa)
# Corrigido o nome do pacote brother-dcp-l2540dw-cups-bin
sudo -u "$USUARIO_REAL" yay -S --noconfirm --needed brother-dcp-l2540dw-lpr-bin brother-dcp-l2540dw-cups-bin epson-inkjet-printer-escpr jq

echo ""
echo "[2/4] Iniciando Serviço de Impressão (CUPS)..."
systemctl start cups

# Função auxiliar para instalar impressoras
instalar_impressora() {
    NOME=$1
    IP=$2
    MODELO=$3
    PPD=$4
    
    # Validações básicas
    if [ -z "$IP" ] || [ "$IP" == "null" ]; then
        echo " -> ⚠️  Aviso: Impressora '$NOME' ignorada (IP não definido ou nulo)."
        return
    fi
    
    echo " -> Configurando: $NOME ($MODELO) no IP $IP"
    lpadmin -x "$NOME" 2>/dev/null
    
    # Cria a impressora de acordo com o tipo
    if [ "$PPD" == "everywhere" ]; then
        lpadmin -p "$NOME" -E -v "ipp://$IP/ipp/print" -m everywhere -D "$MODELO"
    elif [[ "$PPD" == /* ]]; then
        lpadmin -p "$NOME" -E -v "socket://$IP:9100" -P "$PPD" -D "$MODELO"
    else
        lpadmin -p "$NOME" -E -v "socket://$IP:9100" -m "$PPD" -D "$MODELO"
    fi
    
    # Força a configuração A4 em um comando separado (necessário para IPP Everywhere fixar o valor)
    lpadmin -p "$NOME" -o PageSize=A4 -o media=A4
}

echo ""
echo "[3/4] Instalando e Configurando Impressoras a partir do JSON..."

# Lê o JSON com jq e itera sobre cada impressora do array
jq -c '.impressoras[]' "$JSON_FILE" | while read -r imp; do
    NOME_JSON=$(echo "$imp" | jq -r '.nome')
    IP_JSON=$(echo "$imp" | jq -r '.ip')
    MODELO_JSON=$(echo "$imp" | jq -r '.modelo')
    PPD_JSON=$(echo "$imp" | jq -r '.ppd')
    
    instalar_impressora "$NOME_JSON" "$IP_JSON" "$MODELO_JSON" "$PPD_JSON"
done

echo ""
echo "[4/4] Finalizando Configurações..."
systemctl restart cups

echo "========================================================"
echo "   ✅ Instalação Concluída com Sucesso!"
echo "   Todas as impressoras do JSON foram configuradas."
echo "========================================================"
echo ""
echo "Resumo das impressoras e configuração de folha (A4):"
echo "--------------------------------------------------------"
for printer in $(lpstat -p | awk '{print $2}'); do
    echo "🖨️  Impressora: $printer"
    
    # Extrai a configuração de tamanho do papel dinamicamente do lpoptions
    TAMANHO=$(lpoptions -p "$printer" -l 2>/dev/null | grep -i '^PageSize' | grep -o '\*[a-zA-Z0-9_-]*' | tr -d '*')
    
    # Fallback caso a impressora não reporte PageSize tradicional
    if [ -z "$TAMANHO" ]; then
        TAMANHO="Configuração Padrão do Sistema (A4)"
    fi
    
    echo "    Tamanho do Papel configurado: $TAMANHO"
    echo "--------------------------------------------------------"
done
echo ""
echo "Tudo pronto! Você já pode fechar o terminal."
