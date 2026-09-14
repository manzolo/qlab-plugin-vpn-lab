---
kicker: QLab · vpn-lab
title: |
  Un tunnel costruito
  con due chiavi
subtitle: >
  WireGuard configurato da zero su due macchine, alzato, attraversato da un
  ping e poi osservato sul filo — dove l'ICMP è sparito e resta solo UDP.
  Catturato da una coppia accesa.
facts:
  - [Comando, "`qlab run vpn-lab`"]
  - [VM, "`vpn-lab-server` 192.168.100.1 · `vpn-lab-client` 192.168.100.2"]
  - [Tunnel, "10.10.0.1 ↔ 10.10.0.2, UDP 51820"]
  - [Esito, "`qlab test vpn-lab` → 5 esercizi, 28 controlli, tutti superati"]
---

## 1. Due macchine, e niente di configurato

{{evidence:topology}}

{{evidence:before as=shell}}

Il laboratorio fornisce gli strumenti e nessuna configurazione. È voluto:
l'esercizio *è* la configurazione, e ce n'è pochissima. Tutto quello che segue
parte da qui.

## 2. Prima le chiavi, e viaggiano solo le metà pubbliche

{{evidence:build-tunnel as=shell}}

Ecco tutto il modello di identità di WireGuard. Ogni macchina genera una coppia
di chiavi e **tiene la metà privata**; ciò che viene scambiato è la chiave
pubblica, che si può tranquillamente stampare in un documento come questo.

Non ci sono certificati, non c'è un'autorità di certificazione, non c'è una
negoziazione su chi siete. Un peer è una chiave pubblica con l'elenco degli
indirizzi che gli è permesso usare, e il file di configurazione è abbastanza
corto da leggersi per intero.

Tre campi portano il significato:

- **`Address`** — l'indirizzo della macchina *dentro* il tunnel. Non ha niente a
  che vedere con gli indirizzi di LAN della sezione 1.
- **`Endpoint`** — dove mandare l'UDP cifrato. Serve solo al client: il server
  impara l'endpoint del client dal primo pacchetto che arriva, ed è per questo
  che WireGuard regge client che cambiano rete.
- **`AllowedIPs`** — un campo con due mestieri, ed è quello che confonde. Sul
  traffico in uscita è una *rotta*: manda questi indirizzi a questo peer. Sul
  traffico in entrata è un *controllo d'accesso*: un pacchetto decifrato da
  questo peer che dichiara un mittente fuori dai suoi AllowedIPs viene scartato.
  Instradamento e autorizzazione in una riga.

`wg-quick up` fa poi a mano ciò che altrimenti scrivereste: crea l'interfaccia,
carica la configurazione, aggiunge l'indirizzo, imposta un MTU di 1420 — 1500
meno il costo dell'incapsulamento.

## 3. Il tunnel, in piedi

{{evidence:tunnel-up as=shell}}

Tre pacchetti, nessuna perdita, sotto il millisecondo. E `wg show` riferisce ciò
che conta: un **latest handshake** di pochi secondi fa, e un conteggio di byte
nelle due direzioni.

Si guardi l'endpoint che il server si è annotato: `192.168.100.2:36396`. Il
client non ha mai dichiarato una porta — il server l'ha imparata dai pacchetti
arrivati. E non c'è nessuno stato «connesso» da riferire, perché WireGuard non ha
connessioni: è UDP, fra un handshake e l'altro è senza stato, e `latest
handshake` è la cosa più simile a una sessione.

## 4. Cosa vede la rete

{{evidence:on-the-wire as=shell}}

Il filtro di cattura chiedeva `udp port 51820 or icmp`, sull'interfaccia che il
ping attraversa davvero. Ogni singola riga è UDP, tutte della stessa lunghezza.
**Di ICMP non compare nulla** — non perché sia stato filtrato, ma perché su
questo filo non esiste. I ping stanno dentro il carico cifrato.

È la cosa che vale la pena vedere invece che sentirsi raccontare: un osservatore
sulla LAN apprende che due indirizzi si scambiano UDP su una porta nota, quanto e
quando. Non apprende nulla su *cosa* — né il protocollo, né gli indirizzi
interni, né il contenuto.

{{evidence:teardown as=shell}}

## 5. E OpenVPN, per contrasto

Il laboratorio installa anche OpenVPN, e l'esercizio 2 lo configura con una
chiave statica. Il confronto è il senso di averli entrambi: OpenVPN gira su TLS
con cifrari negoziabili, richiede un'autorità di certificazione per qualsiasi
cosa vada oltre una chiave statica condivisa, e la sua configurazione occupa
decine di righe. WireGuard ha una sola suite crittografica e nessuna
negoziazione: per questo non c'è niente da scegliere e niente da sbagliare — e
per lo stesso motivo non potrà essere adattato quando quella suite invecchierà.

## 6. Verifica

{{evidence:qlab-test grep="Exercise [0-9]+:|Exercises |All exercises" as=shell}}

## 7. Cosa portarsi via

- Un peer è una chiave pubblica. Le chiavi private non lasciano mai la macchina
  che le ha generate.
- `Address` sta dentro il tunnel, `Endpoint` fuori. Tenere distinte le due cose
  risolve gran parte della confusione.
- `AllowedIPs` è insieme la rotta in uscita e il filtro in entrata.
- Il server non ha bisogno di sapere dov'è il client: impara l'endpoint dal
  traffico.
- Non esiste una connessione. `latest handshake` è come si capisce se un tunnel
  è vivo.
- Sul filo c'è solo UDP. Quello che viaggia dentro non è visibile da fuori.

`guide.md` del plugin porta gli esercizi: WireGuard a mano, OpenVPN con chiave
statica, analisi del traffico con tcpdump e le regole di firewall attorno.
