# 本地开发调试指南

## 环境要求

| 工具 | 实际使用版本 | 说明 |
|------|-------------|------|
| uv | 任意 | Python 包管理器 |
| Python | **3.9.25**（通过 uv 安装） | 与线上容器一致，避免兼容性差异 |
| Node.js | **v16.20.2** | 前端构建 |
| npm | **10.9.2** | 前端依赖管理 |
| libpq | 通过 brew 安装 | psycopg2 编译依赖 |

### 一次性依赖安装（首次）

```bash
# macOS 上编译 psycopg2 需要 libpq（PostgreSQL 客户端头文件）
brew install libpq
brew link libpq --force

# 通过 uv 安装 Python 3.9（与线上容器版本一致）
uv python install 3.9
```

---

## 后端（Flask API）

### 首次初始化

```bash
cd alerta

# 创建 Python 3.9 虚拟环境
uv venv --python 3.9 .venv

# 安装所有依赖（需要 libpq 已安装）
LDFLAGS="-L/opt/homebrew/opt/openssl/lib -L/opt/homebrew/opt/libpq/lib" \
CPPFLAGS="-I/opt/homebrew/opt/openssl/include -I/opt/homebrew/opt/libpq/include" \
uv pip install --python .venv/bin/python -r requirements.txt -r requirements-dev.txt

# 以可编辑模式安装 alerta 包
uv pip install --python .venv/bin/python -e .
```

### 启动

```bash
cd alerta

DATABASE_URL=postgres://postgres:postgres@<远端IP>:<端口>/monitoring \
  SECRET_KEY=dev \
  AUTH_REQUIRED=False \
  .venv/bin/flask --app wsgi.py run --port 5001
```

> **注意**：macOS 的 AirPlay 会占用 5000 端口，使用 **5001**。
>
> `DATABASE_URL` 指向你的远端 PostgreSQL 实例，无需在本地启动数据库服务。

### 验证

```bash
curl http://localhost:5001/config
# 返回 JSON（包含 alarm_model、severity 等字段）即为正常
```

---

## 前端（Vue.js WebUI）

### 首次初始化

```bash
cd alert-webui
npm install
```

### 关键配置文件说明

| 文件 | 优先级 | 作用 |
|------|--------|------|
| `alert-webui/.env.development` | **最高** | 构建时注入，`VUE_APP_ALERTA_ENDPOINT` 指定后端地址 |
| `alert-webui/public/config.json` | 中 | 运行时 fallback，浏览器直接读取 |

当前本地开发配置（已设定好）：
- `.env.development`：`VUE_APP_ALERTA_ENDPOINT=http://localhost:5001`
- `public/config.json`：`{"endpoint": "http://localhost:5001"}`

### 启动

```bash
cd alert-webui
npm run serve
```

前端地址：`http://localhost:8000`  
API 地址：`http://localhost:5001`

> **注意**：修改 `.env.development` 后必须**重启** `npm run serve` 才能生效（不是热重载）。

---

## 完整启动流程

```bash
# 终端 1：后端
cd alerta
DATABASE_URL=postgres://postgres:postgres@<远端IP>:<端口>/monitoring \
  SECRET_KEY=dev AUTH_REQUIRED=False \
  .venv/bin/flask --app wsgi.py run --port 5001

# 终端 2：前端
cd alert-webui
npm run serve
```

浏览器访问：`http://localhost:8000`

---

## 对镜像构建的影响分析

### 结论：以下改动**不影响**镜像构建

| 改动文件 | 是否进入镜像 | 说明 |
|----------|-------------|------|
| `alert-webui/.env.development` | **否** | `vue-cli-service build`（生产构建）不读 `.env.development`，读 `.env.production`（若存在）或无环境变量 |
| `alert-webui/public/config.json` | **是（但运行时覆盖）** | 镜像内 nginx 会提供此文件，但容器启动脚本（`docker-entrypoint.sh`）会根据环境变量重新生成 `config.json`，覆盖构建时的值 |
| `alerta/.venv/` | **否** | `.venv` 已在 `.gitignore` 中，且 Dockerfile 使用自己的 `/venv` |
| `alerta/requirements.txt` | **是** | 但未修改此文件，无影响 |

### 构建时 endpoint 是如何确定的

```
Dockerfile.allinone
  └── npm run build（生产构建，不含 .env.development）
      └── 生成的 dist/ 中不含 endpoint 硬编码
          └── 容器启动时读取环境变量 / Helm values 生成 config.json
```

**结论**：本地调试所做的两项改动（`.env.development` 和 `public/config.json`）均不会影响生产镜像内容，可以安全保留。

---

## 已知注意事项

- macOS 端口 5000 被 AirPlay 占用，后端固定使用 **5001**
- `psycopg2` 编译需要 `brew install libpq`，这是 macOS 特有的步骤；Linux/Docker 环境通过 `apt-get install libpq-dev` 自动处理
- 本地 Python 版本需保持 **3.9**，避免 `importlib.metadata.entry_points` API 差异导致与线上行为不一致
