# ShardManager

一个用于计算数据库分片表名的Web应用，支持MySQL和MongoDB分片计算，并提供历史记录存储功能。

## 功能特性

- ✨ **分片计算**：基于Java String.hashCode()算法计算分片索引
- 🗄️ **多数据库支持**：同时支持MySQL和MongoDB分片计算
- 📋 **历史记录**：自动保存所有计算历史，方便查询和复用
- 🐳 **容器化部署**：提供完整的Podman/Docker容器化方案
- 💾 **数据持久化**：使用SQLite数据库持久化存储历史记录
- 🎨 **美观界面**：现代化的响应式UI设计

## 快速开始

### 使用 Podman Compose 部署

1. **克隆或准备项目文件**

确保您有以下文件：
- `index.html` - 前端页面
- `app.py` - Flask后端服务
- `Dockerfile` - 容器构建文件
- `podman-compose.yaml` - 容器编排配置
- `requirements.txt` - Python依赖

2. **构建并启动服务**

```bash
# 使用 podman-compose 启动服务
podman-compose up -d

# 或者使用 docker-compose
docker-compose up -d
```

3. **访问应用**

在浏览器中打开：`http://localhost:8080`

4. **查看日志**

```bash
podman-compose logs -f
```

5. **停止服务**

```bash
podman-compose down
```

### 使用 Podman 手动部署

```bash
# 构建镜像
podman build -t shardmanager:latest .

# 创建数据卷
podman volume create shardmanager-data

# 运行容器
podman run -d \
  --name shardmanager \
  -p 8080:5000 \
  -v shardmanager-data:/data \
  -e DB_PATH=/data/shardmanager.db \
  --restart unless-stopped \
  shardmanager:latest

# 查看日志
podman logs -f shardmanager
```

## 配置说明

### 端口配置

默认端口映射为 `8080:5000`，您可以在 `podman-compose.yaml` 中修改：

```yaml
ports:
  - "你的端口:5000"
```

### 数据持久化

历史记录数据保存在命名卷 `shardmanager-data` 中，即使容器删除，数据也不会丢失。

如果需要备份数据：

```bash
# 查找卷的实际位置
podman volume inspect shardmanager-data

# 或直接复制数据库文件
podman cp shardmanager:/data/shardmanager.db ./backup.db
```

## API 接口

### 获取历史记录
```
GET /api/history?limit=100
```

### 创建历史记录
```
POST /api/history
Content-Type: application/json

{
  "user_id": "test_user_001",
  "hash_code": 123456,
  "mysql_prefix": "table_",
  "mysql_shard_count": 10,
  "mysql_shard_index": 6,
  "mysql_table_name": "table_6",
  "mongo_prefix": "collection_",
  "mongo_shard_count": 50,
  "mongo_shard_index": 36,
  "mongo_table_name": "collection_36"
}
```

### 删除历史记录
```
DELETE /api/history/{id}
```

### 清空所有历史记录
```
DELETE /api/history/clear
```

### 健康检查
```
GET /api/health
```

## 本地开发

如果不使用容器，可以直接运行：

```bash
# 安装依赖
pip install -r requirements.txt

# 启动服务
python app.py

# 访问 http://localhost:5000
```

## 技术栈

- **前端**：原生HTML + CSS + JavaScript
- **后端**：Python Flask
- **数据库**：SQLite
- **容器化**：Podman/Docker

## 算法说明

分片索引计算公式：
```
shard_index = Math.abs(userId.hashCode() % shard_count)
```

其中 `hashCode()` 使用 Java String.hashCode() 算法实现。

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v2.0.0 (2025-01-30)
- ✨ 新增历史记录存储功能
- 🐳 添加 Podman/Docker 容器化支持
- 🔧 后端API服务实现
- 💾 SQLite数据库持久化

### v1.0.0
- 🎉 初始版本
- ✨ 基础分片计算功能

