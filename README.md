# Grafana Alloy Deployment on Debian

This project provides an automated solution for deploying Grafana Alloy on a Debian VM using Docker Compose.
Key features include:
- Automated configuration generation (`config.alloy`)
- Integration with Prometheus (Metrics) and Loki (Logs)
- Host resource monitoring (CPU, RAM, Disk, Network)
- Docker container resource and log monitoring

## Quick Start

### 1. Generate Configuration

Run the `gen_alloy_config.sh` script and follow the prompts to enter your Prometheus and Loki connection details.
The script will automatically check the connection health and generate `config.alloy` only if verification passes.

```bash
chmod +x gen_alloy_config.sh
./gen_alloy_config.sh
```

### 2. Start Services

Once the configuration is generated, start the services using Docker Compose.

```bash
docker-compose up -d
```

### 3. Verify Status

- **Alloy UI**: Visit `http://<YOUR_IP>:12345` in your browser to see the Alloy status.
- **Logs**: Check the Alloy container logs to verify there are no errors.
  ```bash
  docker-compose logs -f alloy
  ```

## File Descriptions

- `docker-compose.yml`: Defines the Alloy service and necessary volume mounts (including host filesystem and docker socket).
- `alloy_templates/config_template.alloy`: The configuration template file.
- `gen_alloy_config.sh`: The configuration generator script with health checks.
