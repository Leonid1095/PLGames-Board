# PLGames Board - Installation Test Scenarios

**For QA/Testing:** This document describes test scenarios for the `install.sh` script.

---

## Prerequisites Check

Before testing, ensure:
- [ ] Fresh Ubuntu/Debian/CentOS server
- [ ] Docker and Docker Compose installed
- [ ] Internet connection (100+ Mbps recommended for Russia)
- [ ] At least 8GB RAM and 20GB free disk space
- [ ] Ports 80 and 443 available (or custom ports)

---

## Test Scenario 1: Fresh Installation (Localhost)

**Purpose:** Test fresh installation for local development

### Steps:

```bash
# 1. Run installer
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)

# When prompted:
# - Domain: localhost (just press Enter)
# - Ports: Use defaults (80/443)
# - Firewall: n
# - Confirm: y
```

### Expected Results:

1. **Repository cloning:**
   - ✅ Clones to `~/plgames-board`
   - ✅ Shows progress

2. **Configuration:**
   - ✅ Creates `.env` file with auto-generated DB password
   - ✅ Sets `DOMAIN=localhost`
   - ✅ Sets `BASE_URL=http://localhost`

3. **Docker build (20-30 minutes):**
   - ✅ Shows build progress messages
   - ✅ **Rust installation:** Should try mirrors and succeed:
     ```
     Trying Rust installation from: https://rsproxy.cn/rustup-init.sh
     ✓ Successfully installed Rust from https://rsproxy.cn/rustup-init.sh
     ```
   - ✅ **Prisma engines:** Should download and generate:
     ```
     Trying to download Prisma engine from https://binaries.prisma.sh/...
     ✓ Successfully downloaded Prisma engine from ...
     Attempting Prisma generate (attempt 1/5)...
     ✓ Prisma client generated successfully
     ```
   - ✅ Completes without errors

4. **Service startup:**
   - ✅ Shows "Waiting for services to start..."
   - ✅ Backend healthcheck passes
   - ✅ Shows all 5 services running (gateway, frontend, backend, postgres, redis)

5. **Final output:**
   - ✅ Shows success message
   - ✅ Shows access URL: `http://localhost`
   - ✅ Mentions "first user to register will become admin"

### Verification:

```bash
# Check services
cd ~/plgames-board
docker compose ps

# Expected output: All containers "Up" and healthy
# - gateway
# - frontend
# - backend (healthy)
# - postgres (healthy)
# - redis (healthy)

# Test backend health
curl http://localhost:3010/api/healthz
# Expected: HTTP 200 OK

# Test frontend access
curl -I http://localhost
# Expected: HTTP 200 OK

# Open in browser
# Navigate to: http://localhost
# Expected: PLGames Board login/registration page
```

---

## Test Scenario 2: Fresh Installation (Production Domain)

**Purpose:** Test production installation with real domain

### Steps:

```bash
# 1. Ensure DNS A record points to server IP
# 2. Run installer
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)

# When prompted:
# - Domain: yourdomain.com
# - HTTP port: 80 (or custom if needed)
# - HTTPS port: 443 (or custom if needed)
# - Firewall: y
# - Confirm: y
```

### Expected Results:

Same as Scenario 1, plus:
- ✅ Firewall rules added for ports 80 and 443
- ✅ `BASE_URL=https://yourdomain.com`
- ✅ Caddy gateway gets Let's Encrypt certificate automatically
- ✅ HTTPS redirect works

### Verification:

```bash
# Test HTTPS
curl -I https://yourdomain.com
# Expected: HTTP 200 OK with valid SSL certificate

# Check certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com | grep "Verify return code"
# Expected: Verify return code: 0 (ok)
```

---

## Test Scenario 3: Update Existing Installation

**Purpose:** Test updating existing installation without losing data

### Steps:

```bash
# 1. After Scenario 1 or 2, run installer again
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)

# When prompted about existing directory:
# - Remove and reinstall: n
# - Continue with existing domain/ports or change them
# - Confirm: y
```

### Expected Results:

1. **Update check:**
   - ✅ Detects existing `~/plgames-board`
   - ✅ Asks whether to remove or update
   - ✅ Runs `git pull origin main`
   - ✅ Shows "Repository updated to latest version"

2. **Configuration:**
   - ✅ Overwrites `.env` with new configuration
   - ⚠️ **Note:** Database password changes, but data persists in volumes

3. **Docker rebuild:**
   - ✅ Runs `docker compose up -d --build`
   - ✅ Uses Docker cache for unchanged layers (faster build)
   - ✅ Only rebuilds changed parts

4. **Data preservation:**
   - ✅ PostgreSQL data persists in `postgres_data` volume
   - ✅ Redis data persists in `redis_data` volume
   - ✅ User files persist in `storage_data` volume
   - ✅ Existing users can still log in

### Verification:

```bash
# Check volumes
docker volume ls | grep plgames
# Expected: All volumes still exist

# Check data
docker compose exec postgres psql -U plgames -d plgames -c "SELECT COUNT(*) FROM \"User\";"
# Expected: User count matches before update
```

---

## Test Scenario 4: Clean Reinstallation

**Purpose:** Test complete removal and fresh installation

### Steps:

```bash
# 1. Run installer on existing installation
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)

# When prompted about existing directory:
# - Remove and reinstall: y
# - Configure as needed
# - Confirm: y
```

### Expected Results:

1. **Cleanup:**
   - ✅ Runs `docker compose down`
   - ✅ Removes `~/plgames-board` directory
   - ⚠️ **Volumes are NOT removed** (manual step needed for complete wipe)

2. **Fresh installation:**
   - ✅ Clones repository fresh
   - ✅ Builds from scratch
   - ✅ Creates new containers

### Complete Data Wipe (Optional):

```bash
# To completely remove all data:
cd ~/plgames-board
docker compose down -v  # Remove volumes too
cd ~
rm -rf ~/plgames-board
```

---

## Test Scenario 5: Installation Failure Recovery

**Purpose:** Test how installer handles failures

### Test 5a: Network Timeout During Rust Installation

**Simulate:** Temporarily block rsproxy.cn during build

**Expected:**
- ✅ Tries rsproxy.cn (fails)
- ✅ Tries sh.rustup.rs (fallback)
- ✅ Tries mirrors.tuna.tsinghua.edu.cn (fallback)
- ✅ Shows clear error if all fail
- ✅ Shows retry command

### Test 5b: Docker Build Failure

**Simulate:** Fill disk during build

**Expected:**
- ✅ Shows "Docker build failed!"
- ✅ Shows last 50 lines of logs
- ✅ Lists common issues
- ✅ Shows retry command
- ✅ Exit code 1

### Test 5c: Service Startup Timeout

**Simulate:** Backend doesn't start within 120s

**Expected:**
- ✅ Waits up to 120 seconds
- ✅ Shows progress every 10 seconds
- ✅ Shows service status even if unhealthy
- ✅ Provides debug commands

---

## Test Scenario 6: Regional Access (Russia)

**Purpose:** Test that mirrors work from Russia

### Prerequisites:
- Server located in Russia OR VPN to Russia

### Steps:

Same as Scenario 1, but monitor specifically:

```bash
# During build, watch for mirror usage
docker compose logs -f backend 2>&1 | grep -E "Trying|Successfully|Failed"
```

### Expected Results:

**Rust installation:**
- ✅ `rsproxy.cn` should succeed (first mirror)
- ✅ Shows: `Successfully installed Rust from https://rsproxy.cn/rustup-init.sh`
- ✅ No timeouts or retries needed

**Cargo crates download:**
- ✅ Uses USTC mirror: `mirrors.ustc.edu.cn/crates.io-index/`
- ✅ No git timeout errors
- ✅ Fast download speed

**Prisma engines:**
- ✅ One of the 3 sources succeeds
- ✅ No connection timeouts

**Total build time:**
- ✅ 20-30 minutes (acceptable)
- ❌ NOT 60+ minutes or hanging

---

## Checklist for Release

Before releasing install.sh to production:

- [ ] Test Scenario 1 passes on Ubuntu 22.04
- [ ] Test Scenario 1 passes on Debian 12
- [ ] Test Scenario 2 passes with real domain
- [ ] Test Scenario 3 preserves user data
- [ ] Test Scenario 6 passes from Russia-based server
- [ ] README.md has correct installation URL
- [ ] ROADMAP.md documents installation process
- [ ] All error messages are clear and actionable
- [ ] Health checks work correctly
- [ ] First user registration creates admin

---

## Known Issues

### Issue 1: Port Conflicts
**Symptom:** Gateway fails to start - ports 80/443 already in use
**Solution:** Either:
1. Stop conflicting service (systemctl stop caddy/nginx)
2. Use custom ports in installer

### Issue 2: Low Memory During Build
**Symptom:** Build crashes with "JavaScript heap out of memory"
**Solution:**
- Close other applications
- Add swap space temporarily
- Use server with 8GB+ RAM

### Issue 3: Slow Build in Russia
**Symptom:** Build takes 60+ minutes
**Solution:**
- Check which mirror is being used
- May need to wait for npm/yarn downloads
- Consider using VPN for faster mirrors

---

## Debug Commands

```bash
# View all logs
cd ~/plgames-board
docker compose logs

# View specific service logs
docker compose logs backend -f
docker compose logs frontend -f

# Check build stage logs
docker compose logs builder

# Restart specific service
docker compose restart backend

# Rebuild specific service
docker compose up -d --build backend

# Check resource usage
docker stats

# Check volumes
docker volume ls
docker volume inspect plgames-board_postgres_data

# Connect to database
docker compose exec postgres psql -U plgames -d plgames

# Check backend health
docker compose exec backend curl http://localhost:3010/api/healthz

# Check environment variables
docker compose exec backend env | grep AFFINE
```

---

**Last Updated:** 2024-12-14
**Tested On:** Ubuntu 22.04, Debian 12, CentOS Stream 9
