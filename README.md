# Auto Instalador de Impressoras Linux (CUPS) 🖨️🐧

Script de automação para instalação em lote de impressoras de rede (Brother, Epson, Canon) em ambientes com Linux, desenvolvido especialmente para escolas e empresas. Ele evita o trabalho manual repetitivo configurando todas as impressoras listadas via um arquivo `.json`.

## ✨ Funcionalidades
- Instalação silenciosa de drivers nativos das marcas mais usadas (via `pamac`).
- Suporte à tecnologia moderna **Driverless (IPP Everywhere)**, ideal para as novas Canon MAXIFY, eliminando compilações lentas de drivers.
- Atribuição automática de PPDs específicos (ex: Brother).
- Configuração automática do papel para **A4** para evitar travamentos de página.
- Geração de relatório ao final da execução.

## ⚙️ Como Usar (Para Profissionais de TI)

Diferente de scripts fechados, este projeto foi criado separando a lógica da configuração. Você pode personalizar as impressoras editando o arquivo JSON.

### Passo 1: Clonar e Preparar
1. Faça o clone deste repositório na máquina que você deseja configurar:
```bash
git clone https://github.com/LucasTelesEriceira/auto-install-impressoras-linux.git
cd auto-install-impressoras-linux
```
2. Abra o arquivo `impressoras.json` em um editor de texto e substitua as informações de acordo com a sua rede:
- **nome**: Nome de exibição no Linux (não use espaços).
- **ip**: Endereço IP fixo da impressora na rede. Se deixar vazio, o script pula a instalação inteligente.
- **modelo**: Descrição livre.
- **ppd**: Se for uma impressora moderna na rede Wi-Fi, coloque `everywhere`. Se for antiga, aponte para o caminho absoluto do PPD (ex: `/opt/brother/...`) ou o nome interno reconhecido pelo `lpinfo -m`.

### Passo 2: Executar
Certifique-se de executar o script com permissões de Administrador:
```bash
chmod +x instalador_rede_escola.sh
sudo ./instalador_rede_escola.sh
```

Pronto! O script vai baixar a ferramenta `jq` para ler o seu JSON, procurar e instalar os drivers, criar as impressoras no CUPS e confirmar a configuração de tamanho A4.

---
**Nota:** O instalador foi desenhado usando o gerenciador de pacotes `pamac` (Arch Linux / Manjaro / BigLinux). Se você estiver usando Debian/Ubuntu, edite a linha 22 do script `.sh` substituindo `pamac build` por `apt install` e altere os nomes dos pacotes de drivers para a versão `.deb` equivalente.