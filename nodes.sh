#!/bin/bash

# Script per sostituire i seed nodes di Monero con IP personalizzati
# Autore: Script generato per sostituire i peer nodes
# Data: $(date)

set -e  # Esci in caso di errore

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# File da modificare
FILE_PATH="src/p2p/net_node.inl"

# Verifica che il file esista
if [ ! -f "$FILE_PATH" ]; then
    echo -e "${RED}ERRORE: File $FILE_PATH non trovato!${NC}"
    echo "Assicurati di eseguire questo script dalla directory principale del progetto Monero"
    exit 1
fi

# Crea un backup
BACKUP_FILE="${FILE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}Creazione backup in: $BACKUP_FILE${NC}"
cp "$FILE_PATH" "$BACKUP_FILE"

echo -e "${GREEN}Applicazione delle modifiche ai seed nodes...${NC}"

# Modifica 1: MAINNET seed nodes
sed -i '/m_nettype == cryptonote::FAKECHAIN/,/else$/{
  /else$/!b
  n
  c\
  else\
  {\
    \/\/ MAINNET - Nodi personalizzati\
    full_addrs.insert("82.165.218.56:18080");\
    full_addrs.insert("87.106.40.193:18080");\
  }
}' "$FILE_PATH"

# Modifica 2: TESTNET seed nodes
sed -i '/if (m_nettype == cryptonote::TESTNET)/,/}/{ 
  /full_addrs.insert/c\
    full_addrs.insert("82.165.218.56:28080");\
    full_addrs.insert("87.106.40.193:28080");
  /full_addrs.insert/!b
  :a
  n
  /full_addrs.insert/ba
}' "$FILE_PATH"

# Modifica 3: STAGENET seed nodes  
sed -i '/else if (m_nettype == cryptonote::STAGENET)/,/}/{ 
  /full_addrs.insert/c\
    full_addrs.insert("82.165.218.56:38080");\
    full_addrs.insert("87.106.40.193:38080");
  /full_addrs.insert/!b
  :a
  n
  /full_addrs.insert/ba
}' "$FILE_PATH"

echo -e "${GREEN}✓ Modifiche applicate con successo!${NC}"
echo -e "${YELLOW}File originale salvato in: $BACKUP_FILE${NC}"
echo ""
echo -e "${GREEN}Prossimi passi:${NC}"
echo "1. Verifica le modifiche con: diff $BACKUP_FILE $FILE_PATH"
echo "2. Ricompila il progetto con: make clean && make"
echo "3. Testa la connettività dei tuoi nodi"
echo ""
echo -e "${YELLOW}IMPORTANTE:${NC} Assicurati che i tuoi nodi (82.165.218.56 e 87.106.40.193)"
echo "siano operativi e sincronizzati prima di distribuire questa versione."
