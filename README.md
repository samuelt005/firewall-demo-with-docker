### Diagrama do Cenário

```
          +------------------+
          |  Máquina Cliente |
          |  (172.20.0.10)   |
          +------------------+
                   |
                   | (rede_interna)
                   v
+------------------------------------------------------+
|                   Firewall/Gateway                   |
|              (eth0: 172.20.0.2 - interna)            |
|              (eth1: 172.21.0.2 - dmz)                |
|              (eth2: 172.22.0.2 - servicos)           |
+------------------------------------------------------+
         | (rede_dmz)              | (rede_servicos)
         v                         v
+------------------+        +---------------------+
|  Servidor Web    |        |  Banco de Dados     |
|  (172.21.0.10)   |------->|  (172.22.0.10)      |
+------------------+        +---------------------+
```
### Demonstração Prática

**1. Subir o Ambiente**

No Terminal 1, na raiz do projeto:
```bash
# Constrói as imagens e inicia os containers
docker-compose up --build -d

# Comece a seguir os logs do firewall. É aqui que a mágica acontece!
docker logs -f firewall
```
Você verá a saída do script `setup_firewall.sh`. Deixe este terminal visível.

**2. Entrar nos Containers**

No Terminal 2:
```bash
docker exec -it client /bin/sh
```

No Terminal 3:
```bash
docker exec -it web /bin/sh
```

**3. Iniciar os Testes (a parte divertida!)**

Agora, execute os comandos e explique o que está acontecendo, apontando para os logs no Terminal 1.

**Cenário de Teste 1: Acesso PERMITIDO (Cliente -> Web)**

*   No Terminal 2 (dentro do `client`):
    ```sh
    # Teste de conectividade (ICMP/Ping)
    # Deve funcionar, pois liberamos na REGRA 3 do firewall.
    ping -c 3 172.21.0.10

    # Teste de acesso ao serviço web (HTTP)
    # Deve funcionar e retornar o HTML, pois liberamos na REGRA 1.
    curl http://172.21.0.10
    ```
*   **O que mostrar:** O sucesso dos comandos no Terminal 2. No Terminal 1 (logs do firewall), você **não** verá logs de bloqueio para esses acessos.

**Cenário de Teste 2: Acesso PERMITIDO (Web -> DB)**

*   No Terminal 3 (dentro do `web`):
    ```sh
    # Instale o cliente netcat para testar a porta
    apk update && apk add netcat-openbsd

    # Testa se a porta 5432 do banco de dados está aberta.
    # A opção -z faz o nc apenas escanear a porta, sem enviar dados.
    # Deve retornar "Connection to 172.22.0.10 5432 port [tcp/postgresql] succeeded!"
    nc -z -v 172.22.0.10 5432
    ```
*   **O que mostrar:** O sucesso da conexão no Terminal 3. Novamente, sem logs de bloqueio no firewall.

**Cenário de Teste 3: Acesso BLOQUEADO (Cliente -> DB) - O MAIS IMPORTANTE**

*   No Terminal 2 (dentro do `client`):
    ```sh
    # Tenta pingar o banco de dados.
    # Vai falhar (timeout), pois não há regra permitindo ICMP do cliente para o DB.
    ping -c 3 172.22.0.10

    # Tenta acessar a porta do banco de dados.
    # Vai falhar (timeout), pois não há regra permitindo tráfego do cliente para o DB.
    nc -z -v 172.22.0.10 5432
    ```
*   **O que mostrar:**
    1.  Os comandos no Terminal 2 falhando com `Operation timed out`.
    2.  **O GRANDE MOMENTO:** No Terminal 1 (logs do firewall), você verá novas linhas aparecendo, algo como:
        ```
        [FW-BLOCKED-FORWARD] IN=eth0 OUT=eth2 SRC=172.20.0.10 DST=172.22.0.10 ... PROTO=ICMP ...
        [FW-BLOCKED-FORWARD] IN=eth0 OUT=eth2 SRC=172.20.0.10 DST=172.22.0.10 ... PROTO=TCP DPT=5432 ...
        ```
    Isto é a prova visual de que o firewall identificou, bloqueou e logou a tentativa de acesso indevido.

**4. Finalizando a Apresentação**

*   Recapitule o que foi demonstrado:
    *   A política "Default Deny" bloqueou tudo por padrão.
    *   Criamos regras específicas para liberar apenas a comunicação essencial e segura (Princípio do Menor Privilégio).
    *   O firewall impediu com sucesso um acesso não autorizado (Cliente -> DB).
    *   Os logs foram a ferramenta para visualizar e auditar a atividade do firewall.

**Para derrubar o ambiente:**
```bash
docker-compose down
```

Este setup completo lhe dará uma base sólida para uma apresentação prática, clara e impressionante. Boa sorte
