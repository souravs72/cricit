# CRICIT Workspace Development & Deployment Policy

## Strict GitHub-First Production Deployment Protocol
- **Standard Pipeline**:
  1. **Commit Locally**: Commit all verified changes using conventional commit standards (`feat:`, `fix:`, `chore:`, `docs:`, `test:`).
  2. **Push to Remote**: Always push commits to the central GitHub repository (`git push origin main`).
  3. **Deploy on Server**: Trigger or execute deployment on the production server exclusively via Git:
     ```bash
     ssh -i ~/.ssh/cricit_oci.key ubuntu@137.23.51.182 "cd /opt/cricit && git pull origin main && docker compose --env-file /opt/cricit/.env -f infra/docker-compose.oci.yml up -d"
     ```
- **Strict Prohibition**:
  - **NEVER** use `rsync`, raw source `scp`, or ad-hoc file transfers to synchronize application code to the server. Git is the single immutable source of truth for all production state.
