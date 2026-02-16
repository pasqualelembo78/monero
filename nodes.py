#!/usr/bin/env python3
"""
Script per sostituire i seed nodes nel file net_node.inl di Monero
con IP personalizzati: 82.165.218.56 e 87.106.40.193
"""

import re
import sys
from datetime import datetime
from pathlib import Path

# Configurazione
FILE_PATH = "src/p2p/net_node.inl"
YOUR_IPS = ["82.165.218.56", "87.106.40.193"]

# Porte per le diverse reti
MAINNET_PORT = "18080"
TESTNET_PORT = "28080"
STAGENET_PORT = "38080"

def create_backup(file_path):
    """Crea un backup del file originale"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_{timestamp}"
    
    try:
        with open(file_path, 'r') as original:
            content = original.read()
        with open(backup_path, 'w') as backup:
            backup.write(content)
        print(f"✓ Backup creato: {backup_path}")
        return backup_path
    except Exception as e:
        print(f"✗ Errore nella creazione del backup: {e}")
        sys.exit(1)

def read_file(file_path):
    """Legge il contenuto del file"""
    try:
        with open(file_path, 'r') as f:
            return f.read()
    except FileNotFoundError:
        print(f"✗ ERRORE: File {file_path} non trovato!")
        print("  Assicurati di eseguire questo script dalla directory principale del progetto Monero")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Errore nella lettura del file: {e}")
        sys.exit(1)

def write_file(file_path, content):
    """Scrive il contenuto nel file"""
    try:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"✓ File modificato: {file_path}")
    except Exception as e:
        print(f"✗ Errore nella scrittura del file: {e}")
        sys.exit(1)

def replace_seed_nodes(content, network_type, port):
    """Sostituisce i seed nodes per un tipo di rete specifico"""
    
    # Pattern per trovare la sezione del network type
    if network_type == "TESTNET":
        start_pattern = r'if \(m_nettype == cryptonote::TESTNET\)\s*\{'
    elif network_type == "STAGENET":
        start_pattern = r'else if \(m_nettype == cryptonote::STAGENET\)\s*\{'
    elif network_type == "MAINNET":
        start_pattern = r'else\s*\{[^}]*\/\/ MAINNET|else\s*\{(?=\s*full_addrs\.insert\("(?!82\.165|87\.106))'
    else:
        return content
    
    # Trova la sezione
    pattern = start_pattern + r'(.*?)(?=\s*\}\s*(?:else if|return))'
    
    # Crea i nuovi seed nodes
    new_nodes = ""
    for ip in YOUR_IPS:
        new_nodes += f'    full_addrs.insert("{ip}:{port}");\n'
    
    # Commento esplicativo per MAINNET
    if network_type == "MAINNET":
        replacement_block = f''else
  {{
    // MAINNET - Nodi personalizzati
{new_nodes.rstrip()}
  }}'''
    else:
        replacement_block = f'  {{\n{new_nodes}  }}'
    
    # Sostituisci il blocco
    def replacer(match):
        if network_type == "MAINNET":
            return replacement_block
        else:
            return match.group(0).split('{')[0] + replacement_block
    
    modified_content = re.sub(pattern, replacer, content, flags=re.DOTALL)
    
    return modified_content

def remove_tor_i2p_nodes(content):
    """Rimuove i nodi Tor e I2P predefiniti"""
    
    # Rimuovi nodi Tor
    tor_pattern = r'(case epee::net_utils::zone::tor:.*?if \(m_nettype == cryptonote::MAINNET\)\s*\{)(.*?)(\}\s*return \{\};)'
    tor_replacement = r'\1\n      // Rimossi i nodi Tor predefiniti\n      // Aggiungi qui i tuoi nodi Tor se necessario\n      return {};\n    \3'
    content = re.sub(tor_pattern, tor_replacement, content, flags=re.DOTALL)
    
    # Rimuovi nodi I2P
    i2p_pattern = r'(case epee::net_utils::zone::i2p:.*?if \(m_nettype == cryptonote::MAINNET\)\s*\{)(.*?)(\}\s*return \{\};)'
    i2p_replacement = r'\1\n      // Rimossi i nodi I2P predefiniti\n      // Aggiungi qui i tuoi nodi I2P se necessario\n      return {};\n    \3'
    content = re.sub(i2p_pattern, i2p_replacement, content, flags=re.DOTALL)
    
    return content

def main():
    print("=" * 70)
    print("  Script di modifica Seed Nodes per Monero")
    print("=" * 70)
    print()
    
    # Verifica che il file esista
    if not Path(FILE_PATH).exists():
        print(f"✗ ERRORE: File {FILE_PATH} non trovato!")
        print("  Assicurati di eseguire questo script dalla directory principale")
        print("  del progetto Monero")
        sys.exit(1)
    
    print(f"File da modificare: {FILE_PATH}")
    print(f"Nuovi IP: {', '.join(YOUR_IPS)}")
    print()
    
    # Crea backup
    backup_path = create_backup(FILE_PATH)
    
    # Leggi il file
    print("→ Lettura del file...")
    content = read_file(FILE_PATH)
    
    # Applica le modifiche
    print("→ Applicazione modifiche MAINNET...")
    content = replace_seed_nodes(content, "MAINNET", MAINNET_PORT)
    
    print("→ Applicazione modifiche TESTNET...")
    content = replace_seed_nodes(content, "TESTNET", TESTNET_PORT)
    
    print("→ Applicazione modifiche STAGENET...")
    content = replace_seed_nodes(content, "STAGENET", STAGENET_PORT)
    
    print("→ Rimozione nodi Tor e I2P...")
    content = remove_tor_i2p_nodes(content)
    
    # Scrivi le modifiche
    write_file(FILE_PATH, content)
    
    print()
    print("=" * 70)
    print("  ✓ MODIFICHE COMPLETATE CON SUCCESSO!")
    print("=" * 70)
    print()
    print("Prossimi passi:")
    print(f"  1. Verifica le modifiche: diff {backup_path} {FILE_PATH}")
    print("  2. Ricompila il progetto: make clean && make")
    print("  3. Testa la connettività dei tuoi nodi")
    print()
    print("⚠  IMPORTANTE:")
    print(f"  Assicurati che i nodi {YOUR_IPS[0]} e {YOUR_IPS[1]}")
    print("  siano operativi e sincronizzati prima di distribuire questa versione.")
    print()

if __name__ == "__main__":
    main()
