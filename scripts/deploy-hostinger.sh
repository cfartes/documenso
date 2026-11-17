#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
config=docker/hostinger
compose=(docker compose --env-file "$config/.env" -f "$config/compose.yml")

if [[ ! -f "$config/.env" ]]; then
  echo "Copie $config/.env.example para $config/.env e configure os segredos e SMTP." >&2
  exit 1
fi
if [[ ! -f "$config/cert.p12" || ! -r "$config/cert.p12" ]]; then
  echo "Instale um certificado de assinatura legivel em $config/cert.p12 (UID 1001 no container)." >&2
  exit 1
fi

docker compose version >/dev/null
docker info >/dev/null
"${compose[@]}" config --quiet
"${compose[@]}" build documenso
"${compose[@]}" up -d --wait --wait-timeout 120 database

# A failed migration must stop deployment; the upstream start.sh does not enforce this.
"${compose[@]}" run --rm --no-deps documenso npx prisma migrate deploy --schema ../../packages/prisma/schema.prisma
"${compose[@]}" up -d --no-deps documenso
"${compose[@]}" exec -T documenso node --input-type=module -e '
  let isHealthy = false;
  for (let attempt = 0; attempt < 60; attempt++) {
    try {
      const response = await fetch("http://localhost:3000/api/health", { signal: AbortSignal.timeout(3000) });
      if (response.ok) {
        isHealthy = true;
        break;
      }
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }
  if (!isHealthy) {
    console.error("Health check falhou. Consulte docker compose -f docker/hostinger/compose.yml logs documenso.");
    process.exit(1);
  }
'
echo 'Documenso iniciado. Configure o proxy HTTPS para documenso.nexusdataanalytics.tech.'
