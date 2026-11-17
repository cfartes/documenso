# Publicacao na VPS Hostinger

Dominio: `documenso.nexusdataanalytics.tech`. Execute na VPS Linux com Git, Bash e Docker Engine com Compose v2 ou superior. O build usa o codigo deste repositorio e pode consumir bastante memoria; verifique a capacidade livre antes de executa-lo junto dos outros apps.

1. Clone o repositorio em um diretorio exclusivo:

   ```bash
   git clone https://github.com/cfartes/documenso.git /opt/nexus-documenso
   cd /opt/nexus-documenso
   cp docker/hostinger/.env.example docker/hostinger/.env
   chmod 600 docker/hostinger/.env
   ```

2. Preencha `docker/hostinger/.env`: gere quatro valores diferentes com `openssl rand -hex 32` para banco, autenticacao e as duas chaves de criptografia. Configure o SMTP real e o remetente autorizado. Nao altere as chaves de criptografia depois de armazenar dados. Para a senha do banco use apenas hexadecimal, pois ela tambem compoe a URL de conexao.

3. Instale o certificado de assinatura PKCS#12 em `docker/hostinger/cert.p12`, configure sua senha no `.env` e permita leitura pelo UID 1001 do container (por exemplo, `sudo chown 1001:1001 docker/hostinger/cert.p12` e `sudo chmod 400 docker/hostinger/cert.p12`). O certificado de assinatura e diferente do certificado HTTPS.

4. Execute a publicacao:

   ```bash
   bash scripts/deploy-hostinger.sh
   ```

5. Crie um registro DNS A para `documenso` apontando ao IPv4 da VPS. Configure o proxy existente para encaminhar esse dominio a `http://127.0.0.1:3100` e emitir o certificado HTTPS. A porta e local e nao deve ser aberta no firewall. Se 3100 estiver ocupada, altere `DOCUMENSO_PORT` e o destino no proxy.

   Para Nginx instalado diretamente na VPS, use `nginx.conf.example` como um novo virtual host, valide com `sudo nginx -t` e recarregue com `sudo systemctl reload nginx`. Em uma instalacao que ja usa Certbot, emita HTTPS com `sudo certbot --nginx -d documenso.nexusdataanalytics.tech`. Se o proxy estiver em container, `127.0.0.1` aponta ao proprio container: adapte a rede externa do proxy antes de publicar. Nao substitua a configuracao dos outros apps.

6. Verifique `https://documenso.nexusdataanalytics.tech/api/health` e teste envio de email e assinatura de um documento.

Para atualizar, faca backup antes e execute `git pull --ff-only` seguido de `bash scripts/deploy-hostinger.sh`. O script valida a configuracao, constroi a imagem antes de alterar containers, executa migracoes e verifica a saude HTTP. Migracoes podem impedir rollback para uma versao antiga.

O projeto Compose `nexus-documenso` tem rede e volume proprios; o PostgreSQL nao expoe portas. Nao execute `down -v`: isso apaga o banco e os documentos armazenados nele. Nao execute duas publicacoes simultaneamente.

Backup do banco (mantenha tambem copias protegidas do `.env` e certificado, fora do Git):

```bash
umask 077
docker compose --env-file docker/hostinger/.env -f docker/hostinger/compose.yml exec -T database pg_dump -U documenso -Fc documenso > /caminho/seguro/documenso.dump
```

O script nao instala Docker, altera DNS, firewall ou proxy automaticamente. Esses ajustes dependem da configuracao dos outros apps na VPS.
