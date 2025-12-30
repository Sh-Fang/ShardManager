FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/python:3.11-slim

WORKDIR /app

# 安装依赖
COPY ../requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用文件
COPY ../src/app.py .
COPY ../src/static ./static

# 创建数据目录
RUN mkdir -p /data

# 暴露端口
EXPOSE 5000

# 设置环境变量
ENV DB_PATH=/data/shardmanager.db
ENV PORT=8765
ENV PYTHONUNBUFFERED=1

# 运行应用
CMD ["python", "app.py"]

