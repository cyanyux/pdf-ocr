FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04 AS base

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# Install system dependencies
# 修改 1: 加入 dos2unix
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    pandoc \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# 首先显示构建上下文中的文件（调试）
COPY . .
RUN echo "=== 构建上下文文件列表 ===" && \
    ls -la && \
    echo "=== entrypoint.sh详情 ===" && \
    ls -la entrypoint.sh && \
    echo "=== entrypoint.sh内容（前10行）===" && \
    head -10 entrypoint.sh

# Install PaddlePaddle GPU first (requires special index)
# PaddleOCR-VL-1.5 requires PaddlePaddle 3.2.1+
RUN pip3 install --no-cache-dir --break-system-packages \
    paddlepaddle-gpu==3.3.0 \
    -i https://www.paddlepaddle.org.cn/packages/stable/cu130/

# Install other requirements
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Ensure entrypoint.sh has execute permission
# 修改 2: 執行 dos2unix 轉換格式，並給予執行權限
RUN dos2unix entrypoint.sh && chmod +x entrypoint.sh

# Create output directory
RUN mkdir -p /tmp/pdf_ocr_output

# Expose port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# Use entrypoint to install HPI at runtime (requires GPU)
ENTRYPOINT ["/app/entrypoint.sh"]
