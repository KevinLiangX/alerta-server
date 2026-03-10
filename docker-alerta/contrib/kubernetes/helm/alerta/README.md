# Alerta Helm Chart（本仓库定制说明）

> 适用仓库：`KevinLiangX/alerta-server`  
> 适用日期：2026-03-07

## 1. 代码来源（来自哪里）

本仓库为多项目聚合与本地定制，主要来源如下：

- `alerta/`：Alerta 后端（Flask API）
- `alert-webui/`：Alerta Web UI（Vue）
- `alerta-contrib/`：插件与集成
- `docker-alerta/`：容器与 Helm 部署模板

本 README 仅描述 **本次在 Helm/容器部署链路上的定制改动**，用于团队排障和交接。

---

## 2. 本次关键改动总览

### A. Python 运行时兼容（Python 3.9）

#### 问题
- 容器内报错：`ModuleNotFoundError: No module named 'pkg_resources'`
- 改为 `importlib.metadata` 后，又出现：`entry_points() got an unexpected keyword argument 'group'`

#### 处理
- 将运行时代码中的 `pkg_resources` 全部改为 `importlib.metadata`
- `entry_points(group=...)` 改为 Python 3.9 兼容写法：`entry_points().get('group.name', [])`

#### 涉及文件
- `alerta/alerta/database/base.py`
- `alerta/alerta/utils/plugin.py`
- `alerta/alerta/utils/webhook.py`

---

### B. 插件与路由稳定性修复

#### 问题
- `plugin.py` 中局部变量名 `entry_points` 与导入函数同名，产生遮蔽风险
- `ROUTING_DIST` 直接索引可能触发 `KeyError`

#### 处理
- 局部变量重命名（避免遮蔽）
- 改为 `config.get('ROUTING_DIST')`

#### 涉及文件
- `alerta/alerta/utils/plugin.py`

---

### C. Helm/探针修复

#### 问题
- Chart `appVersion` 与实际镜像版本不一致
- readiness 探针只打 `/`，无法真实反映 API 健康状态

#### 处理
- `appVersion` 更新为 `9.0.4`
- readiness probe 改为 `/api/health`

#### 涉及文件
- `docker-alerta/contrib/kubernetes/helm/alerta/Chart.yaml`
- `docker-alerta/contrib/kubernetes/helm/alerta/templates/deployment.yaml`

---

### D. uWSGI 崩溃与超时修复（本次重点）

#### 问题 1（已解决）
- 开启线程后出现 uWSGI Segmentation fault（prefork + threads）

#### 处理
- 增加：
  - `enable-threads = true`
  - `py-call-uwsgi-fork-hooks = true`
  - `lazy-apps = true`

#### 涉及文件
- `docker-alerta/config/templates/app/uwsgi.ini.j2`

#### 问题 2（已解决）
- API 请求大量 `499/504`
- 日志可见 worker 每 30~40 秒被轮换（`worker lifetime reached`），在 `lazy-apps=true` 下导致频繁冷启动，触发上游超时

#### 处理
- 将默认 worker 生命周期从 30 秒提升到 3600 秒
- 生命周期抖动从 3 提升到 300
- 同时在 Helm values 显式下发，保证部署覆盖镜像默认值

#### 涉及文件
- `docker-alerta/Dockerfile`
  - `UWSGI_MAX_WORKER_LIFETIME=3600`
  - `UWSGI_WORKER_LIFETIME_DELTA=300`
- `docker-alerta/contrib/kubernetes/helm/alerta/values.yaml`
  - `extraEnvVars.UWSGI_MAX_WORKER_LIFETIME: "3600"`
  - `extraEnvVars.UWSGI_WORKER_LIFETIME_DELTA: "300"`

---

## 3. 当前推荐部署方式

### 3.1 临时热修（无需重建镜像）

```bash
kubectl set env deployment/alerta \
  UWSGI_MAX_WORKER_LIFETIME=3600 \
  UWSGI_WORKER_LIFETIME_DELTA=300
```

### 3.2 正式发布（推荐）

1. CI 构建新镜像（包含上述代码与模板修复）
2. Helm 升级发布：

```bash
helm upgrade alerta ./docker-alerta/contrib/kubernetes/helm/alerta \
  --set image.repository=<your-registry>/alerta/alerta-web \
  --set image.tag=<new-tag> \
  --set image.pullPolicy=Always
```

---

## 4. 验证清单

- Pod 启动后不再出现频繁 `worker lifetime reached`（秒级）日志
- `/api/config`、`/api/alerts`、`/api/environments` 正常返回（非 499/504）
- nginx 错误日志不再出现 `upstream timed out (110)`
- readiness 使用 `/api/health` 通过

---

## 5. 已知遗留（非阻塞）

- `alerta/tests/test_zrouting.py` 仍使用 `pkg_resources`（仅测试代码，当前不影响生产运行）

---

## 6. 维护建议

- 若后续继续使用 `lazy-apps=true`，避免将 `UWSGI_MAX_WORKER_LIFETIME` 设为过小值（如 30s）
- Python 3.9 环境统一使用 `entry_points().get(...)` 风格
- Helm values 中保留关键 uWSGI 环境变量显式配置，避免被镜像默认值覆盖
